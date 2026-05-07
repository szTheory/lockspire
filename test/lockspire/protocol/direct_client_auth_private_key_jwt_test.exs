defmodule Lockspire.Protocol.DirectClientAuthPrivateKeyJwtTest do
  use ExUnit.Case, async: false

  alias Lockspire.Domain.Client
  alias Lockspire.Domain.ServerPolicy
  alias Lockspire.Domain.Token
  alias Lockspire.Domain.UsedJti
  alias Lockspire.JarTestHelpers
  alias Lockspire.Protocol.BackchannelAuthentication
  alias Lockspire.Protocol.DeviceAuthorization
  alias Lockspire.Protocol.Introspection
  alias Lockspire.Protocol.Revocation
  alias Lockspire.Protocol.TokenFormatter

  setup do
    keys = JarTestHelpers.generate_keys()
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    Process.put(:direct_client_auth_client, %Client{
      client_id: "direct-client",
      client_type: :confidential,
      token_endpoint_auth_method: :private_key_jwt,
      jwks: keys.pub_jwk_map,
      backchannel_token_delivery_mode: :poll
    })

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

    %{keys: keys, now: now}
  end

  test "introspection accepts verified private_key_jwt callers", %{keys: keys, now: now} do
    assert {:ok, response} =
             Introspection.introspect(%{
               params:
                 private_key_jwt_params(
                   signed_assertion(keys.private_jwk, "direct-client",
                     now: now,
                     jti: "introspect-jti"
                   )
                 )
                 |> Map.put("token", "introspect-token"),
               opts: [
                 client_store: __MODULE__.SharedStore,
                 token_store: __MODULE__.TokenStore,
                 now: fn -> now end
               ]
             })

    assert response.active == true
    assert response.client_id == "direct-client"
  end

  test "revocation accepts verified private_key_jwt callers", %{keys: keys, now: now} do
    assert :ok =
             Revocation.revoke(%{
               params:
                 private_key_jwt_params(
                   signed_assertion(keys.private_jwk, "direct-client",
                     now: now,
                     jti: "revoke-jti"
                   )
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
  end

  test "device authorization accepts verified private_key_jwt callers", %{keys: keys, now: now} do
    assert {:ok, success} =
             DeviceAuthorization.authorize(%{
               params:
                 private_key_jwt_params(
                   signed_assertion(keys.private_jwk, "direct-client",
                     now: now,
                     jti: "device-jti"
                   )
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
  end

  test "backchannel authentication accepts verified private_key_jwt callers", %{
    keys: keys,
    now: now
  } do
    assert {:ok, success} =
             BackchannelAuthentication.authorize(%{
               params:
                 private_key_jwt_params(
                   signed_assertion(keys.private_jwk, "direct-client", now: now, jti: "ciba-jti")
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

  test "attacker-signed assertions fail consistently across representative direct-client surfaces",
       %{
         now: now
       } do
    attacker_assertion =
      signed_assertion(JOSE.JWK.generate_key({:rsa, 2048}), "direct-client",
        now: now,
        jti: "bad-jti"
      )

    requests = [
      fn ->
        Introspection.introspect(%{
          params:
            private_key_jwt_params(attacker_assertion) |> Map.put("token", "introspect-token"),
          opts: [
            client_store: __MODULE__.SharedStore,
            token_store: __MODULE__.TokenStore,
            now: fn -> now end
          ]
        })
      end,
      fn ->
        Revocation.revoke(%{
          params: private_key_jwt_params(attacker_assertion) |> Map.put("token", "revoke-token"),
          opts: [
            client_store: __MODULE__.SharedStore,
            token_store: __MODULE__.TokenStore,
            now: fn -> now end
          ]
        })
      end,
      fn ->
        DeviceAuthorization.authorize(%{
          params: private_key_jwt_params(attacker_assertion) |> Map.put("scope", "openid"),
          opts: [
            client_store: __MODULE__.SharedStore,
            device_authorization_store: __MODULE__.DeviceAuthorizationStore,
            verification_uri: "https://example.test/device",
            now: now
          ]
        })
      end,
      fn ->
        BackchannelAuthentication.authorize(%{
          params:
            private_key_jwt_params(attacker_assertion)
            |> Map.merge(%{"scope" => "openid", "login_hint" => "valid-user"}),
          opts: [
            client_store: __MODULE__.SharedStore,
            ciba_authorization_store: __MODULE__.CibaAuthorizationStore,
            account_resolver: __MODULE__.AccountResolver,
            now: now
          ]
        })
      end
    ]

    Enum.each(requests, fn request ->
      assert {:error,
              %{error: "invalid_client", reason_code: :client_assertion_signature_invalid}} =
               request.()
    end)
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
    def put_device_authorization(device_authorization), do: {:ok, device_authorization}
  end

  defmodule CibaAuthorizationStore do
    def put_ciba_authorization(ciba_authorization), do: {:ok, ciba_authorization}
  end

  defmodule AccountResolver do
    def resolve_account("valid-user", _context), do: {:ok, "subject-123"}
  end

  defp private_key_jwt_params(assertion) do
    %{
      "client_assertion_type" => "urn:ietf:params:oauth:client-assertion-type:jwt-bearer",
      "client_assertion" => assertion
    }
  end

  defp signed_assertion(private_jwk, client_id, opts) do
    now = Keyword.fetch!(opts, :now)

    JarTestHelpers.sign_jar(
      private_jwk,
      %{
        "iss" => client_id,
        "sub" => client_id,
        "aud" => Lockspire.Config.issuer!(),
        "jti" => Keyword.fetch!(opts, :jti),
        "iat" => DateTime.to_unix(now),
        "exp" => DateTime.add(now, 300, :second) |> DateTime.to_unix()
      },
      alg: "RS256"
    )
  end
end
