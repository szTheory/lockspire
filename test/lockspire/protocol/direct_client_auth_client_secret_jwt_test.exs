defmodule Lockspire.Protocol.DirectClientAuthClientSecretJwtTest do
  use ExUnit.Case, async: false

  alias Lockspire.Domain.CibaAuthorization
  alias Lockspire.Domain.Client
  alias Lockspire.Domain.DeviceAuthorization
  alias Lockspire.Domain.ServerPolicy
  alias Lockspire.Domain.Token
  alias Lockspire.Domain.UsedJti
  alias Lockspire.Protocol.BackchannelAuthentication
  alias Lockspire.Protocol.DeviceAuthorization, as: DeviceAuthorizationProtocol
  alias Lockspire.Protocol.Introspection
  alias Lockspire.Protocol.Introspection.Success
  alias Lockspire.Protocol.PushedAuthorizationRequest
  alias Lockspire.Protocol.Revocation
  alias Lockspire.Protocol.TokenFormatter
  alias Lockspire.Security.Policy

  setup do
    now = DateTime.utc_now() |> DateTime.truncate(:second)
    secret = "direct-client-secret"

    Process.put(:direct_client_auth_secret, secret)
    Process.put(:direct_client_auth_client, direct_client(secret))
    Process.put(:direct_client_auth_server_policy, %ServerPolicy{security_profile: :none})
    Process.put(:direct_client_auth_used_jtis, MapSet.new())
    Process.put(:direct_client_auth_tokens, %{
      TokenFormatter.hash_token("introspect-token") => %Token{
        id: 1,
        token_hash: TokenFormatter.hash_token("introspect-token"),
        token_type: :access_token,
        client_id: "direct-client",
        account_id: "subject-123",
        scopes: ["openid"],
        issued_at: now,
        expires_at: DateTime.add(now, 3600, :second)
      },
      TokenFormatter.hash_token("revoke-token") => %Token{
        id: 2,
        token_hash: TokenFormatter.hash_token("revoke-token"),
        token_type: :refresh_token,
        client_id: "direct-client",
        account_id: "subject-123",
        scopes: ["openid"],
        issued_at: now,
        expires_at: DateTime.add(now, 3600, :second)
      }
    })

    %{secret: secret, now: now}
  end

  test "representative direct-client surfaces accept verified client_secret_jwt callers", %{
    secret: secret,
    now: now
  } do
    assert {:ok, %Success{} = response} =
             Introspection.introspect(%{
               params:
                 client_secret_jwt_params(
                   signed_assertion(secret, "direct-client", now: now, jti: "introspect-jti")
                 )
                 |> Map.put("token", "introspect-token"),
               opts: [
                 client_store: __MODULE__.SharedStore,
                 token_store: __MODULE__.TokenStore,
                 now: fn -> now end
               ]
             })

    assert response.payload.active == true
    assert response.payload.client_id == "direct-client"

    assert :ok =
             Revocation.revoke(%{
               params:
                 client_secret_jwt_params(
                   signed_assertion(secret, "direct-client", now: now, jti: "revoke-jti")
                 )
                 |> Map.put("token", "revoke-token"),
               opts: [
                 client_store: __MODULE__.SharedStore,
                 token_store: __MODULE__.TokenStore,
                 now: fn -> now end
               ]
             })

    revoked =
      Process.get(:direct_client_auth_tokens)
      |> Map.fetch!(TokenFormatter.hash_token("revoke-token"))

    assert %DateTime{} = revoked.revoked_at

    assert {:ok, success} =
             DeviceAuthorizationProtocol.authorize(%{
               params:
                 client_secret_jwt_params(
                   signed_assertion(secret, "direct-client", now: now, jti: "device-jti")
                 )
                 |> Map.put("scope", "openid profile"),
               opts: [
                 client_store: __MODULE__.SharedStore,
                 device_authorization_store: __MODULE__.DeviceAuthorizationStore,
                 verification_uri: "https://example.test/device",
                 now: now
               ]
             })

    assert is_binary(success.device_code)
    assert is_binary(success.user_code)

    assert {:ok, success} =
             BackchannelAuthentication.authorize(%{
               params:
                 client_secret_jwt_params(
                   signed_assertion(secret, "direct-client", now: now, jti: "ciba-jti")
                 )
                 |> Map.merge(%{"scope" => "openid profile", "login_hint" => "valid-user"}),
               opts: [
                 client_store: __MODULE__.SharedStore,
                 ciba_authorization_store: __MODULE__.CibaAuthorizationStore,
                 account_resolver: __MODULE__.AccountResolver,
                 now: now
               ]
             })

    assert is_binary(success.auth_req_id)
  end

  test "invalid signature, audience, replay, algorithm, and method mismatch fail closed across the representative surfaces",
       %{
         secret: secret,
         now: now
       } do
    invalid_signature_assertion = signed_assertion("wrong-secret", "direct-client", now: now)
    bad_audience_assertion = signed_assertion(secret, "direct-client", aud: "https://example.test/token", now: now)
    replay_assertion = signed_assertion(secret, "direct-client", now: now, jti: "replay-jti")
    bad_alg_assertion = signed_assertion(secret, "direct-client", alg: "HS512", now: now)

    assert {:error, %{error: "invalid_client", reason_code: :client_assertion_signature_invalid}} =
             run_introspection(invalid_signature_assertion, now)

    assert {:error, %{error: "invalid_client", reason_code: :client_assertion_audience_invalid}} =
             run_revocation(bad_audience_assertion, now)

    assert {:ok, %Success{}} = run_introspection(replay_assertion, now)

    assert {:error, %{error: "invalid_client", reason_code: :client_assertion_replayed}} =
             run_device_authorization(replay_assertion, now)

    assert {:error, %{error: "invalid_client", reason_code: :client_assertion_algorithm_not_allowed}} =
             run_backchannel(bad_alg_assertion, now)

    Process.put(
      :direct_client_auth_client,
      %Client{
        direct_client(secret)
        | token_endpoint_auth_method: :client_secret_post,
          client_secret_hash: Policy.hash_client_secret(secret)
      }
    )

    mismatch_assertion = signed_assertion(secret, "direct-client", now: now)

    assert {:error,
            %{error: "invalid_client", reason_code: :unsupported_token_endpoint_auth_method}} =
             run_introspection(mismatch_assertion, now)
  end

  test "PAR remains outside the shipped client_secret_jwt surface", %{secret: secret, now: now} do
    assert {:error,
            %{error: "invalid_client", reason_code: :unsupported_token_endpoint_auth_method}} =
             PushedAuthorizationRequest.push(%{
               params:
                 client_secret_jwt_params(
                   signed_assertion(secret, "direct-client", now: now, jti: "par-jti")
                 )
                 |> Map.put("response_type", "code")
                 |> Map.put("redirect_uri", "https://client.example.test/callback"),
               opts: [client_store: __MODULE__.SharedStore]
             })
  end

  test "shared direct-client slice stays outside FAPI posture", %{secret: secret, now: now} do
    Process.put(
      :direct_client_auth_server_policy,
      %ServerPolicy{security_profile: :fapi_2_0_security}
    )

    assertion = signed_assertion(secret, "direct-client", now: now, jti: "fapi-jti")

    assert {:error,
            %{error: "invalid_client", reason_code: :client_assertion_auth_method_not_allowed}} =
             run_introspection(assertion, now)
  end

  defmodule SharedStore do
    def fetch_client_by_id(client_id) do
      client = Process.get(:direct_client_auth_client)
      {:ok, if(client.client_id == client_id, do: client, else: nil)}
    end

    def record_used_jti(%UsedJti{} = used_jti) do
      used_jtis = Process.get(:direct_client_auth_used_jtis, MapSet.new())
      key = {used_jti.client_id, used_jti.jti}

      if MapSet.member?(used_jtis, key) do
        {:ok, :replay}
      else
        Process.put(:direct_client_auth_used_jtis, MapSet.put(used_jtis, key))
        {:ok, :accepted}
      end
    end

    def get_server_policy do
      {:ok, Process.get(:direct_client_auth_server_policy)}
    end
  end

  defmodule TokenStore do
    def fetch_lifecycle_token(token_hash) do
      {:ok, Map.get(Process.get(:direct_client_auth_tokens, %{}), token_hash)}
    end

    def revoke_lifecycle_token(token_hash, client_id, revoked_at) do
      tokens = Process.get(:direct_client_auth_tokens, %{})

      case Map.get(tokens, token_hash) do
        %Token{client_id: ^client_id} = token ->
          updated = %Token{token | revoked_at: revoked_at}
          Process.put(:direct_client_auth_tokens, Map.put(tokens, token_hash, updated))
          {:ok, updated}

        _other ->
          {:ok, nil}
      end
    end

    def transact(fun) do
      case fun.() do
        {:error, _reason} = error -> error
        result -> {:ok, result}
      end
    end

    def append_audit_event(_event), do: {:ok, :ignored}
  end

  defmodule DeviceAuthorizationStore do
    def put_device_authorization(%DeviceAuthorization{} = authorization) do
      {:ok, authorization}
    end
  end

  defmodule CibaAuthorizationStore do
    def put_ciba_authorization(%CibaAuthorization{} = authorization) do
      {:ok, authorization}
    end
  end

  defmodule AccountResolver do
    def resolve_account("valid-user", _context), do: {:ok, "subject-123"}
  end

  defp run_introspection(assertion, now) do
    Introspection.introspect(%{
      params: client_secret_jwt_params(assertion) |> Map.put("token", "introspect-token"),
      opts: [client_store: __MODULE__.SharedStore, token_store: __MODULE__.TokenStore, now: fn -> now end]
    })
  end

  defp run_revocation(assertion, now) do
    Revocation.revoke(%{
      params: client_secret_jwt_params(assertion) |> Map.put("token", "revoke-token"),
      opts: [client_store: __MODULE__.SharedStore, token_store: __MODULE__.TokenStore, now: fn -> now end]
    })
  end

  defp run_device_authorization(assertion, now) do
    DeviceAuthorizationProtocol.authorize(%{
      params: client_secret_jwt_params(assertion) |> Map.put("scope", "openid"),
      opts: [
        client_store: __MODULE__.SharedStore,
        device_authorization_store: __MODULE__.DeviceAuthorizationStore,
        verification_uri: "https://example.test/device",
        now: now
      ]
    })
  end

  defp run_backchannel(assertion, now) do
    BackchannelAuthentication.authorize(%{
      params:
        client_secret_jwt_params(assertion)
        |> Map.merge(%{"scope" => "openid", "login_hint" => "valid-user"}),
      opts: [
        client_store: __MODULE__.SharedStore,
        ciba_authorization_store: __MODULE__.CibaAuthorizationStore,
        account_resolver: __MODULE__.AccountResolver,
        now: now
      ]
    })
  end

  defp direct_client(secret) do
    %Client{
      client_id: "direct-client",
      client_type: :confidential,
      token_endpoint_auth_method: :client_secret_jwt,
      client_secret_jwt_verifier_encrypted: Policy.seal_client_secret_jwt_verifier(secret),
      backchannel_token_delivery_mode: :poll
    }
  end

  defp client_secret_jwt_params(assertion) do
    %{
      "client_assertion_type" => "urn:ietf:params:oauth:client-assertion-type:jwt-bearer",
      "client_assertion" => assertion
    }
  end

  defp signed_assertion(secret, client_id, opts) do
    now = Keyword.get(opts, :now, DateTime.utc_now() |> DateTime.truncate(:second))

    JOSE.JWK.from_oct(secret)
    |> JOSE.JWT.sign(
      %{"alg" => Keyword.get(opts, :alg, "HS256")},
      %{
        "iss" => client_id,
        "sub" => client_id,
        "aud" => Keyword.get(opts, :aud, Lockspire.Config.issuer!()),
        "jti" => Keyword.get(opts, :jti, "jti-#{System.unique_integer([:positive])}"),
        "iat" => DateTime.to_unix(now),
        "exp" => DateTime.add(now, 300, :second) |> DateTime.to_unix()
      }
    )
    |> JOSE.JWS.compact()
    |> elem(1)
  end
end
