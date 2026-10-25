defmodule Lockspire.Protocol.ClientSecretVerifierEndpointsTest do
  use ExUnit.Case, async: false

  alias Lockspire.Domain.CibaAuthorization
  alias Lockspire.Domain.Client
  alias Lockspire.Domain.DeviceAuthorization
  alias Lockspire.Domain.ServerPolicy
  alias Lockspire.Domain.Token
  alias Lockspire.Domain.UsedJti
  alias Lockspire.Protocol.BackchannelAuthentication
  alias Lockspire.Protocol.DeviceAuthorization, as: DeviceProtocol
  alias Lockspire.Protocol.Introspection
  alias Lockspire.Protocol.Introspection.Success
  alias Lockspire.Protocol.PushedAuthorizationRequest
  alias Lockspire.Protocol.Revocation
  alias Lockspire.Protocol.TokenFormatter
  alias Lockspire.Security.ClientSecretVerifier
  alias Lockspire.Security.ClientSecretVerifier.Context
  alias Lockspire.Security.Policy

  setup do
    now = DateTime.utc_now() |> DateTime.truncate(:second)
    secret = "endpoint-secret-#{Ecto.UUID.generate()}"
    context = verifier_context(:crypto.strong_rand_bytes(32), :allow)
    cache_key = Lockspire.Config.client_secret_verifier_cache_key()
    previous_context = :persistent_term.get(cache_key, :missing)
    :persistent_term.put(cache_key, context)

    on_exit(fn ->
      if previous_context == :missing,
        do: :persistent_term.erase(cache_key),
        else: :persistent_term.put(cache_key, previous_context)
    end)

    Process.put(:verifier_endpoint_context, context)
    Process.put(:verifier_endpoint_secret, secret)
    Process.put(:verifier_endpoint_policy, %ServerPolicy{security_profile: :none})
    Process.put(:verifier_endpoint_client, client("endpoint-client", secret, context))
    Process.put(:verifier_endpoint_jtis, MapSet.new())
    Process.put(:verifier_endpoint_devices, [])
    Process.put(:verifier_endpoint_ciba, [])

    Process.put(:verifier_endpoint_tokens, %{
      TokenFormatter.hash_token("inspect-target") => %Token{
        id: 1,
        token_hash: TokenFormatter.hash_token("inspect-target"),
        token_type: :access_token,
        client_id: "endpoint-client",
        account_id: "subject-123",
        scopes: ["openid"],
        issued_at: now,
        expires_at: DateTime.add(now, 3600, :second)
      },
      TokenFormatter.hash_token("revoke-target") => %Token{
        id: 2,
        token_hash: TokenFormatter.hash_token("revoke-target"),
        token_type: :refresh_token,
        client_id: "endpoint-client",
        account_id: "subject-123",
        scopes: ["openid"],
        issued_at: now,
        expires_at: DateTime.add(now, 3600, :second)
      }
    })

    %{secret: secret, context: context, now: now}
  end

  test "READER-INTROSPECTION-REVOCATION and READER-PAR-DEVICE-CIBA preserve dedicated endpoint support",
       %{secret: secret, now: now} do
    assert {:ok, %Success{payload: %{active: true, client_id: "endpoint-client"}}} =
             run_introspection(
               signed_assertion(secret, "endpoint-client", now, "introspect"),
               now
             )

    assert :ok =
             run_revocation(signed_assertion(secret, "endpoint-client", now, "revoke"), now)

    assert %DateTime{} =
             Process.get(:verifier_endpoint_tokens)
             |> Map.fetch!(TokenFormatter.hash_token("revoke-target"))
             |> Map.fetch!(:revoked_at)

    assert {:ok, device} =
             run_device(signed_assertion(secret, "endpoint-client", now, "device"), now)

    assert is_binary(device.device_code)
    assert is_binary(device.user_code)
    assert [%DeviceAuthorization{}] = Process.get(:verifier_endpoint_devices)

    assert {:ok, ciba} =
             run_ciba(signed_assertion(secret, "endpoint-client", now, "ciba"), now)

    assert is_binary(ciba.auth_req_id)
    assert [%CibaAuthorization{}] = Process.get(:verifier_endpoint_ciba)

    assert {:error,
            %{error: "invalid_client", reason_code: :unsupported_token_endpoint_auth_method}} =
             PushedAuthorizationRequest.push(%{
               params:
                 auth_params(signed_assertion(secret, "endpoint-client", now, "par"))
                 |> Map.merge(%{
                   "response_type" => "code",
                   "redirect_uri" => "https://client.example.test/callback"
                 }),
               opts: [client_store: __MODULE__.ClientStore]
             })
  end

  test "READER-LEGACY-ALLOW and READER-LEGACY-REJECT use explicit verifier policy", %{
    secret: secret,
    now: now
  } do
    legacy = Policy.seal_client_secret_jwt_verifier(secret)

    client = %Client{
      client("endpoint-client", secret, nil)
      | client_secret_jwt_verifier_encrypted: legacy
    }

    Process.put(:verifier_endpoint_client, client)

    assert {:ok, %Success{payload: %{active: true}}} =
             run_introspection(
               signed_assertion(secret, "endpoint-client", now, "legacy-allow"),
               now
             )

    rejecting = verifier_context(:crypto.strong_rand_bytes(32), :reject)
    Process.put(:verifier_endpoint_context, rejecting)

    result =
      run_introspection(signed_assertion(secret, "endpoint-client", now, "legacy-reject"), now)

    assert {:error, %{error: "invalid_client", reason_code: :client_secret_verifier_unavailable}} =
             result

    assert endpoint_effects() == %{jtis: 1, revoked: false, devices: 0, ciba: 0}
  end

  test "READER-UNAVAILABLE distinguishes missing verifier and redacts bad verifier material", %{
    secret: secret,
    now: now,
    context: context
  } do
    assertion = fn suffix -> signed_assertion(secret, "endpoint-client", now, suffix) end
    %Client{} = original = Process.get(:verifier_endpoint_client)

    cases = [
      {:missing, nil, :client_secret_verifier_missing},
      {:empty, "", :client_secret_verifier_missing},
      {:wrong_identity, elem(seal(context, "other-client", secret), 1),
       :client_secret_verifier_unavailable},
      {:wrong_key,
       elem(
         seal(verifier_context(:crypto.strong_rand_bytes(32), :allow), "endpoint-client", secret),
         1
       ), :client_secret_verifier_unavailable},
      {:tampered, tamper(original.client_secret_jwt_verifier_encrypted),
       :client_secret_verifier_unavailable},
      {:invalid_present, original.client_secret_jwt_verifier_encrypted,
       :client_secret_verifier_unavailable}
    ]

    for {case_id, encrypted, reason} <- cases do
      case_context =
        if case_id == :invalid_present,
          do: %Context{state: :invalid, reason: :invalid_options},
          else: context

      :persistent_term.put(Lockspire.Config.client_secret_verifier_cache_key(), case_context)
      Process.put(:verifier_endpoint_context, case_context)

      Process.put(:verifier_endpoint_client, %Client{
        original
        | client_secret_jwt_verifier_encrypted: encrypted
      })

      before = endpoint_effects()
      result = run_introspection(assertion.("unavailable-#{case_id}"), now)

      assert {:error, %{error: "invalid_client", reason_code: ^reason}} = result,
             "#{case_id} returned #{inspect(result)}"

      assert endpoint_effects() == before
      refute inspect(result) =~ secret
      if is_binary(encrypted) and encrypted != "", do: refute(inspect(result) =~ encrypted)
    end
  end

  test "READER-HS256-AUDIENCE-JTI-EXCLUSIONS preserves assertion validation and replay ordering",
       %{secret: secret, now: now} do
    cases = [
      {"wrong issuer",
       signed_assertion(secret, "endpoint-client", now, "wrong-issuer", iss: "other-client"),
       :client_assertion_issuer_invalid},
      {"wrong audience",
       signed_assertion(secret, "endpoint-client", now, "wrong-audience",
         aud: "https://example.test/introspect"
       ), :client_assertion_audience_invalid},
      {"wrong key", signed_assertion("wrong-secret", "endpoint-client", now, "wrong-key"),
       :client_assertion_signature_invalid},
      {"HS512", signed_assertion(secret, "endpoint-client", now, "wrong-alg", alg: "HS512"),
       :client_assertion_algorithm_not_allowed},
      {"empty JTI", signed_assertion(secret, "endpoint-client", now, "", jti: ""),
       :client_assertion_jti_missing},
      {"expired",
       signed_assertion(secret, "endpoint-client", DateTime.add(now, -700, :second), "expired"),
       :client_assertion_expired},
      {"overlong",
       signed_assertion(secret, "endpoint-client", now, "overlong",
         exp: DateTime.add(now, 700, :second)
       ), :client_assertion_lifetime_too_long}
    ]

    for {label, jwt, reason} <- cases do
      before = endpoint_effects()
      result = run_introspection(jwt, now)
      assert {:error, %{error: "invalid_client", reason_code: ^reason}} = result, label
      assert endpoint_effects() == before, label
      refute inspect(result) =~ secret
    end

    replay = signed_assertion(secret, "endpoint-client", now, "same-jti")
    assert {:ok, %Success{}} = run_introspection(replay, now)

    assert {:error, %{error: "invalid_client", reason_code: :client_assertion_replayed}} =
             run_introspection(replay, now)

    assert endpoint_effects().jtis == 1
  end

  test "READER-FAPI remains excluded under both FAPI profiles", %{secret: secret, now: now} do
    for profile <- [:fapi_2_0_security, :fapi_2_0_message_signing] do
      Process.put(:verifier_endpoint_policy, %ServerPolicy{security_profile: profile})
      before = endpoint_effects()

      result =
        run_introspection(
          signed_assertion(secret, "endpoint-client", now, "fapi-#{profile}"),
          now
        )

      assert {:error,
              %{error: "invalid_client", reason_code: :client_assertion_auth_method_not_allowed}} =
               result

      assert endpoint_effects() == before
      refute inspect(result) =~ secret
    end
  end

  defmodule ClientStore do
    def lifetime_contract do
      %{
        version: 1,
        transaction_authority:
          Lockspire.Protocol.ClientSecretVerifierEndpointsTest.TransactionStore.transaction_authority()
      }
    end

    def lock_clients(ids) do
      client = Process.get(:verifier_endpoint_client)
      {:ok, Enum.filter([client], &(&1.client_id in ids))}
    end

    def fetch_client_by_id(id) do
      client = Process.get(:verifier_endpoint_client)
      {:ok, if(client.client_id == id, do: client, else: nil)}
    end

    def record_used_jti(%UsedJti{} = jti) do
      used = Process.get(:verifier_endpoint_jtis, MapSet.new())
      key = {jti.client_id, jti.jti}

      if MapSet.member?(used, key) do
        {:ok, :replay}
      else
        Process.put(:verifier_endpoint_jtis, MapSet.put(used, key))
        {:ok, :accepted}
      end
    end

    def get_server_policy, do: {:ok, Process.get(:verifier_endpoint_policy)}
  end

  defmodule TokenStore do
    def fetch_lifecycle_token(hash),
      do: {:ok, Map.get(Process.get(:verifier_endpoint_tokens, %{}), hash)}

    def revoke_lifecycle_token(hash, client_id, at) do
      tokens = Process.get(:verifier_endpoint_tokens, %{})

      case Map.get(tokens, hash) do
        %Token{client_id: ^client_id} = token ->
          updated = %Token{token | revoked_at: at}
          Process.put(:verifier_endpoint_tokens, Map.put(tokens, hash, updated))
          {:ok, updated}

        _ ->
          {:ok, nil}
      end
    end

    def transact(fun) do
      case fun.() do
        {:error, _} = error -> error
        result -> {:ok, result}
      end
    end

    def append_audit_event(_), do: {:ok, :ignored}
  end

  defmodule DeviceStore do
    def put_device_authorization(%DeviceAuthorization{} = item) do
      Process.put(:verifier_endpoint_devices, [item | Process.get(:verifier_endpoint_devices, [])])

      {:ok, item}
    end
  end

  defmodule CibaStore do
    def put_ciba_authorization(%CibaAuthorization{} = item) do
      Process.put(:verifier_endpoint_ciba, [item | Process.get(:verifier_endpoint_ciba, [])])
      {:ok, item}
    end
  end

  defmodule TransactionStore do
    def transaction_authority do
      base = Lockspire.Storage.Ecto.Repository.transaction_authority()

      %{
        base
        | identity: :verifier_endpoint_test,
          participants:
            base.participants
            |> Map.put(
              :client_store,
              Lockspire.Protocol.ClientSecretVerifierEndpointsTest.ClientStore
            )
            |> Map.put(:transaction_store, __MODULE__)
            |> Map.put(
              :device_authorization_store,
              Lockspire.Protocol.ClientSecretVerifierEndpointsTest.DeviceStore
            )
            |> Map.put(
              :ciba_authorization_store,
              Lockspire.Protocol.ClientSecretVerifierEndpointsTest.CibaStore
            )
      }
    end

    def transact(fun) do
      case fun.() do
        {:ok, value} -> {:ok, value}
        {:error, _reason} = error -> error
        result -> {:ok, result}
      end
    end
  end

  defmodule AccountResolver do
    def resolve_account("valid-user", _), do: {:ok, "subject-123"}
  end

  defp run_introspection(jwt, now),
    do:
      Introspection.introspect(%{
        params: auth_params(jwt) |> Map.put("token", "inspect-target"),
        opts: endpoint_opts(now)
      })

  defp run_revocation(jwt, now),
    do:
      Revocation.revoke(%{
        params: auth_params(jwt) |> Map.put("token", "revoke-target"),
        opts: endpoint_opts(now)
      })

  defp run_device(jwt, now),
    do:
      DeviceProtocol.authorize(%{
        params: auth_params(jwt) |> Map.put("scope", "openid profile"),
        opts:
          endpoint_opts(now) ++
            [
              device_authorization_store: DeviceStore,
              verification_uri: "https://example.test/device"
            ]
      })

  defp run_ciba(jwt, now),
    do:
      BackchannelAuthentication.authorize(%{
        params:
          auth_params(jwt)
          |> Map.merge(%{"scope" => "openid profile", "login_hint" => "valid-user"}),
        opts:
          endpoint_opts(now) ++
            [ciba_authorization_store: CibaStore, account_resolver: AccountResolver]
      })

  defp endpoint_opts(now),
    do: [
      client_store: ClientStore,
      token_store: TokenStore,
      transaction_store: TransactionStore,
      now: fn -> now end,
      client_secret_verifier_context: Process.get(:verifier_endpoint_context)
    ]

  defp auth_params(jwt),
    do: %{
      "client_assertion_type" => "urn:ietf:params:oauth:client-assertion-type:jwt-bearer",
      "client_assertion" => jwt
    }

  defp client(id, _secret, nil),
    do: %Client{
      client_id: id,
      lifetime_version: 0,
      client_type: :confidential,
      token_endpoint_auth_method: :client_secret_jwt,
      client_secret_jwt_verifier_encrypted: nil,
      backchannel_token_delivery_mode: :poll
    }

  defp client(id, secret, context) do
    {:ok, encrypted} = seal(context, id, secret)

    %Client{
      client_id: id,
      lifetime_version: 0,
      client_type: :confidential,
      token_endpoint_auth_method: :client_secret_jwt,
      client_secret_hash: Policy.hash_client_secret(secret),
      client_secret_jwt_verifier_encrypted: encrypted,
      backchannel_token_delivery_mode: :poll
    }
  end

  defp seal(context, id, secret), do: ClientSecretVerifier.seal(context, id, secret)

  defp verifier_context(key, legacy_read) do
    {:ok, context} =
      Context.resolve(
        {:present,
         [
           keys: [{"endpoint", Base.url_encode64(key, padding: false)}],
           current: "endpoint",
           write_mode: :dedicated,
           legacy_read: legacy_read
         ]},
        []
      )

    {:ok, validated} = Context.validate(context)
    validated
  end

  defp signed_assertion(key, client_id, now, jti, opts \\ []) do
    issuer = Keyword.get(opts, :iss, client_id)
    subject = Keyword.get(opts, :sub, client_id)

    claims = %{
      "iss" => issuer,
      "sub" => subject,
      "aud" => Keyword.get(opts, :aud, Lockspire.Config.issuer!()),
      "jti" => jti,
      "iat" => DateTime.to_unix(now),
      "exp" => DateTime.to_unix(Keyword.get(opts, :exp, DateTime.add(now, 300, :second)))
    }

    JOSE.JWK.from_oct(key)
    |> JOSE.JWT.sign(%{"alg" => Keyword.get(opts, :alg, "HS256")}, claims)
    |> JOSE.JWS.compact()
    |> elem(1)
  end

  defp tamper("LSCV1." <> rest),
    do:
      "LSCV1." <>
        String.slice(rest, 0..-2//1) <> if(String.ends_with?(rest, "A"), do: "B", else: "A")

  defp endpoint_effects do
    tokens = Process.get(:verifier_endpoint_tokens, %{})

    revoked =
      tokens |> Map.fetch!(TokenFormatter.hash_token("revoke-target")) |> Map.fetch!(:revoked_at)

    %{
      jtis: MapSet.size(Process.get(:verifier_endpoint_jtis, MapSet.new())),
      revoked: not is_nil(revoked),
      devices: length(Process.get(:verifier_endpoint_devices, [])),
      ciba: length(Process.get(:verifier_endpoint_ciba, []))
    }
  end
end
