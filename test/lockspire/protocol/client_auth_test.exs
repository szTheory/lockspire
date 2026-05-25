defmodule Lockspire.Protocol.ClientAuthTest do
  use ExUnit.Case, async: false

  alias Lockspire.Domain.Client
  alias Lockspire.Domain.ServerPolicy
  alias Lockspire.Protocol.ClientAuth
  alias Lockspire.Protocol.ClientAuth.Error
  alias Lockspire.JarTestHelpers

  setup do
    Process.delete(:fetched_jwks_uri)
    Process.delete(:refreshed_jwks_uri)
    Process.delete(:inline_pub_jwk_map)
    Process.delete(:remote_jwks)
    Process.delete(:refreshed_remote_jwks)
    Process.delete(:remote_jwks_get_error)
    Process.delete(:remote_jwks_refresh_error)
    Process.delete(:used_jtis)
    Process.delete(:recorded_jtis)
    Process.delete(:recorded_audit_events)
    Process.delete(:force_replay_store_error)
    Process.delete(:client_secret_jwt_secret)
    :ok
  end

  describe "authenticate/3 with private_key_jwt" do
    test "rejects unsigned assertions after tentative lookup" do
      keys = JarTestHelpers.generate_keys()
      Process.put(:inline_pub_jwk_map, keys.pub_jwk_map)
      assertion = unsigned_assertion(%{"iss" => "test_client", "sub" => "test_client"})

      assert {:error, %Error{reason_code: :client_assertion_algorithm_not_allowed}} =
               ClientAuth.authenticate(
                 private_key_jwt_params(assertion),
                 nil,
                 client_store: __MODULE__.MockStore,
                 server_policy_store: __MODULE__.ServerPolicyStore
               )
    end

    test "accepts a signed assertion for a client with inline jwks and rejects an attacker-signed one" do
      keys = JarTestHelpers.generate_keys()
      Process.put(:inline_pub_jwk_map, keys.pub_jwk_map)

      now = DateTime.utc_now() |> DateTime.truncate(:second)

      assertion =
        signed_assertion(keys.private_jwk, "test_client", now: now, jti: "inline-success")

      attacker_assertion = signed_assertion(JOSE.JWK.generate_key({:rsa, 2048}), "test_client")

      assert {:ok, %Client{client_id: "test_client"}} =
               ClientAuth.authenticate(
                 private_key_jwt_params(assertion),
                 nil,
                 client_store: __MODULE__.MockStore,
                 jti_store: __MODULE__.ReplayStore,
                 server_policy_store: __MODULE__.ServerPolicyStore,
                 now: now
               )

      assert {:error, %Error{reason_code: :client_assertion_signature_invalid}} =
               ClientAuth.authenticate(
                 private_key_jwt_params(attacker_assertion),
                 nil,
                 client_store: __MODULE__.MockStore,
                 jti_store: __MODULE__.ReplayStore,
                 server_policy_store: __MODULE__.ServerPolicyStore,
                 now: now
               )
    end

    test "resolves remote jwks before signature verification" do
      keys = JarTestHelpers.generate_keys()
      Process.put(:remote_jwks, JOSE.JWK.from_map(%{"keys" => [keys.pub_jwk_map]}))

      now = DateTime.utc_now() |> DateTime.truncate(:second)

      assertion =
        signed_assertion(keys.private_jwk, "remote_client", now: now, jti: "remote-success")

      assert {:ok, %Client{client_id: "remote_client"}} =
               ClientAuth.authenticate(
                 private_key_jwt_params(assertion),
                 nil,
                 client_store: __MODULE__.RemoteClientStore,
                 jti_store: __MODULE__.ReplayStore,
                 jwks_fetcher: __MODULE__.RemoteJwksFetcher,
                 server_policy_store: __MODULE__.ServerPolicyStore,
                 now: now
               )

      assert Process.get(:fetched_jwks_uri) == "https://keys.example.test/client.jwks.json"
    end

    test "refreshes remote jwks once on key mismatch and retries verification" do
      stale_keys = JarTestHelpers.generate_keys()
      fresh_keys = JarTestHelpers.generate_keys()
      stale_pub = Map.put(stale_keys.pub_jwk_map, "kid", "stale-kid")
      fresh_pub = Map.put(fresh_keys.pub_jwk_map, "kid", "fresh-kid")
      Process.put(:remote_jwks, JOSE.JWK.from_map(%{"keys" => [stale_pub]}))
      Process.put(:refreshed_remote_jwks, JOSE.JWK.from_map(%{"keys" => [fresh_pub]}))

      now = DateTime.utc_now() |> DateTime.truncate(:second)

      assertion =
        signed_assertion(fresh_keys.private_jwk, "remote_client",
          now: now,
          jti: "remote-rotate",
          kid: "fresh-kid"
        )

      assert {:ok, %Client{client_id: "remote_client"}} =
               ClientAuth.authenticate(
                 private_key_jwt_params(assertion),
                 nil,
                 client_store: __MODULE__.RemoteClientStore,
                 jti_store: __MODULE__.ReplayStore,
                 jwks_fetcher: __MODULE__.RemoteJwksFetcher,
                 server_policy_store: __MODULE__.ServerPolicyStore,
                 now: now
               )

      assert Process.get(:fetched_jwks_uri) == "https://keys.example.test/client.jwks.json"
      assert Process.get(:refreshed_jwks_uri) == "https://keys.example.test/client.jwks.json"
    end

    test "rejects algorithms outside the effective issuer allowlist" do
      keys = JarTestHelpers.generate_keys()
      Process.put(:inline_pub_jwk_map, keys.pub_jwk_map)
      now = DateTime.utc_now() |> DateTime.truncate(:second)

      assertion = signed_assertion(keys.private_jwk, "test_client", alg: "RS256", now: now)

      assert {:error, %Error{reason_code: :client_assertion_algorithm_not_allowed}} =
               ClientAuth.authenticate(
                 private_key_jwt_params(assertion),
                 nil,
                 client_store: __MODULE__.MockStore,
                 jti_store: __MODULE__.ReplayStore,
                 server_policy_store: __MODULE__.FapiServerPolicyStore,
                 now: now
               )
    end

    test "rejects issuer-bound audience mismatches" do
      keys = JarTestHelpers.generate_keys()
      Process.put(:inline_pub_jwk_map, keys.pub_jwk_map)
      now = DateTime.utc_now() |> DateTime.truncate(:second)

      assertion =
        signed_assertion(keys.private_jwk, "test_client",
          aud: Lockspire.Config.issuer!() <> "/token",
          now: now
        )

      assert {:error, %Error{reason_code: :client_assertion_audience_invalid}} =
               ClientAuth.authenticate(
                 private_key_jwt_params(assertion),
                 nil,
                 client_store: __MODULE__.MockStore,
                 jti_store: __MODULE__.ReplayStore,
                 server_policy_store: __MODULE__.ServerPolicyStore,
                 now: now
               )
    end

    test "records replay only after verified claims and fails closed on replay-store errors" do
      keys = JarTestHelpers.generate_keys()
      Process.put(:inline_pub_jwk_map, keys.pub_jwk_map)
      now = DateTime.utc_now() |> DateTime.truncate(:second)

      bad_audience_assertion =
        signed_assertion(keys.private_jwk, "test_client",
          aud: Lockspire.Config.issuer!() <> "/token",
          now: now,
          jti: "bad-audience"
        )

      assert {:error, %Error{reason_code: :client_assertion_audience_invalid}} =
               ClientAuth.authenticate(
                 private_key_jwt_params(bad_audience_assertion),
                 nil,
                 client_store: __MODULE__.MockStore,
                 jti_store: __MODULE__.ReplayStore,
                 server_policy_store: __MODULE__.ServerPolicyStore,
                 now: now
               )

      assert Process.get(:recorded_jtis, []) == []

      assertion = signed_assertion(keys.private_jwk, "test_client", now: now, jti: "replay-me")

      assert {:ok, %Client{client_id: "test_client"}} =
               ClientAuth.authenticate(
                 private_key_jwt_params(assertion),
                 nil,
                 client_store: __MODULE__.MockStore,
                 jti_store: __MODULE__.ReplayStore,
                 server_policy_store: __MODULE__.ServerPolicyStore,
                 now: now
               )

      assert {:error, %Error{reason_code: :client_assertion_replayed}} =
               ClientAuth.authenticate(
                 private_key_jwt_params(assertion),
                 nil,
                 client_store: __MODULE__.MockStore,
                 jti_store: __MODULE__.ReplayStore,
                 server_policy_store: __MODULE__.ServerPolicyStore,
                 now: now
               )

      Process.put(:force_replay_store_error, true)

      fresh_assertion =
        signed_assertion(keys.private_jwk, "test_client", now: now, jti: "store-down")

      assert {:error, %Error{reason_code: :client_assertion_replay_store_failed}} =
               ClientAuth.authenticate(
                 private_key_jwt_params(fresh_assertion),
                 nil,
                 client_store: __MODULE__.MockStore,
                 jti_store: __MODULE__.ReplayStore,
                 server_policy_store: __MODULE__.ServerPolicyStore,
                 now: now
               )
    end

    test "emits stable telemetry and durable audit for verifier failures and replay outcomes" do
      keys = JarTestHelpers.generate_keys()
      Process.put(:inline_pub_jwk_map, keys.pub_jwk_map)
      now = DateTime.utc_now() |> DateTime.truncate(:second)
      parent = self()
      handler_id = "client-auth-test-#{System.unique_integer([:positive])}"

      :telemetry.attach_many(
        handler_id,
        [
          [:lockspire, :client_auth, :failed],
          [:lockspire, :client_auth, :replay_detected]
        ],
        fn event, _measurements, metadata, pid -> send(pid, {event, metadata}) end,
        parent
      )

      on_exit(fn -> :telemetry.detach(handler_id) end)

      attacker_assertion =
        signed_assertion(JOSE.JWK.generate_key({:rsa, 2048}), "test_client", now: now)

      assert {:error, %Error{reason_code: :client_assertion_signature_invalid}} =
               ClientAuth.authenticate(
                 private_key_jwt_params(attacker_assertion),
                 nil,
                 client_store: __MODULE__.MockStore,
                 jti_store: __MODULE__.ReplayStore,
                 server_policy_store: __MODULE__.ServerPolicyStore,
                 now: now
               )

      valid_assertion =
        signed_assertion(keys.private_jwk, "test_client", now: now, jti: "audit-replay")

      assert {:ok, %Client{client_id: "test_client"}} =
               ClientAuth.authenticate(
                 private_key_jwt_params(valid_assertion),
                 nil,
                 client_store: __MODULE__.MockStore,
                 jti_store: __MODULE__.ReplayStore,
                 server_policy_store: __MODULE__.ServerPolicyStore,
                 now: now
               )

      assert {:error, %Error{reason_code: :client_assertion_replayed}} =
               ClientAuth.authenticate(
                 private_key_jwt_params(valid_assertion),
                 nil,
                 client_store: __MODULE__.MockStore,
                 jti_store: __MODULE__.ReplayStore,
                 server_policy_store: __MODULE__.ServerPolicyStore,
                 now: now
               )

      assert_receive {[:lockspire, :client_auth, :failed],
                      %{reason_code: :client_assertion_signature_invalid}}

      assert_receive {[:lockspire, :client_auth, :replay_detected],
                      %{reason_code: :client_assertion_replayed}}

      audits = Process.get(:recorded_audit_events, [])

      assert Enum.any?(audits, &(&1.reason_code == "client_assertion_signature_invalid"))
      assert Enum.any?(audits, &(&1.reason_code == "client_assertion_replayed"))
      refute Enum.any?(audits, &Map.has_key?(&1.metadata, "client_assertion"))
      refute Enum.any?(audits, &Map.has_key?(&1.metadata, "jwks_body"))
    end

    test "emits shared remote jwks incident metadata for refresh miss failures" do
      stale_keys = JarTestHelpers.generate_keys()
      missing_keys = JarTestHelpers.generate_keys()
      fresh_keys = JarTestHelpers.generate_keys()
      stale_pub = Map.put(stale_keys.pub_jwk_map, "kid", "stale-kid")
      wrong_pub = Map.put(fresh_keys.pub_jwk_map, "kid", "wrong-kid")
      Process.put(:remote_jwks, JOSE.JWK.from_map(%{"keys" => [stale_pub]}))
      Process.put(:refreshed_remote_jwks, JOSE.JWK.from_map(%{"keys" => [wrong_pub]}))

      now = DateTime.utc_now() |> DateTime.truncate(:second)
      parent = self()
      handler_id = "client-auth-remote-jwks-#{System.unique_integer([:positive])}"

      :telemetry.attach(
        handler_id,
        [:lockspire, :client_auth, :failed],
        fn event, _measurements, metadata, pid -> send(pid, {event, metadata}) end,
        parent
      )

      on_exit(fn -> :telemetry.detach(handler_id) end)

      assertion =
        signed_assertion(missing_keys.private_jwk, "remote_client",
          now: now,
          jti: "remote-miss",
          kid: "fresh-kid"
        )

      assert {:error, %Error{reason_code: :client_assertion_signature_invalid}} =
               ClientAuth.authenticate(
                 private_key_jwt_params(assertion),
                 nil,
                 client_store: __MODULE__.RemoteClientStore,
                 jti_store: __MODULE__.ReplayStore,
                 jwks_fetcher: __MODULE__.RemoteJwksFetcher,
                 server_policy_store: __MODULE__.ServerPolicyStore,
                 now: now
               )

      assert_receive {[:lockspire, :client_auth, :failed],
                      %{
                        remote_jwks_incident_class: :remote_jwks_key_unavailable,
                        remote_jwks_consumer: :private_key_jwt,
                        remote_jwks_stage: :select_key,
                        remote_jwks_subreason: :post_refresh_key_still_missing,
                        remote_jwks_forced_refresh_attempted?: true,
                        remote_jwks_requested_kid_present_in_cached_set?: false
                      }}
    end

    test "emits shared remote jwks incident metadata for guarded fetch failures" do
      Process.put(:remote_jwks_get_error, {:jwks_fetch_failed, {:http_status, 503}})
      now = DateTime.utc_now() |> DateTime.truncate(:second)
      parent = self()
      handler_id = "client-auth-remote-fetch-#{System.unique_integer([:positive])}"

      :telemetry.attach(
        handler_id,
        [:lockspire, :client_auth, :failed],
        fn event, _measurements, metadata, pid -> send(pid, {event, metadata}) end,
        parent
      )

      on_exit(fn -> :telemetry.detach(handler_id) end)

      assertion =
        signed_assertion(JOSE.JWK.generate_key({:rsa, 2048}), "remote_client",
          now: now,
          jti: "remote-fetch-fail"
        )

      assert {:error, %Error{reason_code: :client_jwks_fetch_failed}} =
               ClientAuth.authenticate(
                 private_key_jwt_params(assertion),
                 nil,
                 client_store: __MODULE__.RemoteClientStore,
                 jti_store: __MODULE__.ReplayStore,
                 jwks_fetcher: __MODULE__.RemoteJwksFetcher,
                 server_policy_store: __MODULE__.ServerPolicyStore,
                 now: now
               )

      assert_receive {[:lockspire, :client_auth, :failed],
                      %{
                        remote_jwks_incident_class: :remote_jwks_fetch_failed,
                        remote_jwks_consumer: :private_key_jwt,
                        remote_jwks_stage: :network,
                        remote_jwks_subreason: :http_status,
                        remote_jwks_fetch_status: 503,
                        remote_jwks_forced_refresh_attempted?: false
                      }}
    end

    test "emits shared remote jwks signature-invalid metadata when the refreshed kid exists" do
      stale_keys = JarTestHelpers.generate_keys()
      missing_keys = JarTestHelpers.generate_keys()
      wrong_keys = JarTestHelpers.generate_keys()
      stale_pub = Map.put(stale_keys.pub_jwk_map, "kid", "stale-kid")
      wrong_pub = Map.put(wrong_keys.pub_jwk_map, "kid", "fresh-kid")
      Process.put(:remote_jwks, JOSE.JWK.from_map(%{"keys" => [stale_pub]}))
      Process.put(:refreshed_remote_jwks, JOSE.JWK.from_map(%{"keys" => [wrong_pub]}))

      now = DateTime.utc_now() |> DateTime.truncate(:second)
      parent = self()
      handler_id = "client-auth-remote-signature-#{System.unique_integer([:positive])}"

      :telemetry.attach(
        handler_id,
        [:lockspire, :client_auth, :failed],
        fn event, _measurements, metadata, pid -> send(pid, {event, metadata}) end,
        parent
      )

      on_exit(fn -> :telemetry.detach(handler_id) end)

      assertion =
        signed_assertion(missing_keys.private_jwk, "remote_client",
          now: now,
          jti: "remote-signature-invalid",
          kid: "fresh-kid"
        )

      assert {:error, %Error{reason_code: :client_assertion_signature_invalid}} =
               ClientAuth.authenticate(
                 private_key_jwt_params(assertion),
                 nil,
                 client_store: __MODULE__.RemoteClientStore,
                 jti_store: __MODULE__.ReplayStore,
                 jwks_fetcher: __MODULE__.RemoteJwksFetcher,
                 server_policy_store: __MODULE__.ServerPolicyStore,
                 now: now
               )

      assert_receive {[:lockspire, :client_auth, :failed],
                      %{
                        remote_jwks_incident_class: :remote_jwks_signature_invalid,
                        remote_jwks_consumer: :private_key_jwt,
                        remote_jwks_stage: :verify_signature,
                        remote_jwks_subreason: :post_refresh_signature_invalid,
                        remote_jwks_forced_refresh_attempted?: true,
                        remote_jwks_requested_kid_present_in_cached_set?: true
                      }}
    end
  end

  describe "authenticate/3 with client_secret_jwt" do
    test "accepts a valid HS256 assertion for a registered client_secret_jwt client" do
      secret = "phase88-client-secret"
      Process.put(:client_secret_jwt_secret, secret)
      now = DateTime.utc_now() |> DateTime.truncate(:second)

      assertion = client_secret_signed_assertion(secret, "secret_client", now: now)

      assert {:ok, %Client{client_id: "secret_client"}} =
               ClientAuth.authenticate(
                 jwt_client_assertion_params(assertion),
                 nil,
                 client_store: __MODULE__.ClientSecretJwtStore,
                 jti_store: __MODULE__.ReplayStore,
                 server_policy_store: __MODULE__.ServerPolicyStore,
                 supported_jwt_auth_methods: [:private_key_jwt, :client_secret_jwt],
                 now: now
               )
    end

    test "fails closed on auth-method mismatch without fallback to another auth method" do
      secret = "phase88-client-secret"
      Process.put(:client_secret_jwt_secret, secret)
      now = DateTime.utc_now() |> DateTime.truncate(:second)

      assertion = client_secret_signed_assertion(secret, "basic_client", now: now)

      assert {:error, %Error{reason_code: :unsupported_token_endpoint_auth_method}} =
               ClientAuth.authenticate(
                 jwt_client_assertion_params(assertion),
                 nil,
                 client_store: __MODULE__.ClientSecretJwtStore,
                 jti_store: __MODULE__.ReplayStore,
                 server_policy_store: __MODULE__.ServerPolicyStore,
                 supported_jwt_auth_methods: [:private_key_jwt, :client_secret_jwt],
                 now: now
               )
    end

    test "rejects HS256 assertions on surfaces that do not enable client_secret_jwt" do
      secret = "phase88-client-secret"
      Process.put(:client_secret_jwt_secret, secret)
      now = DateTime.utc_now() |> DateTime.truncate(:second)

      assertion = client_secret_signed_assertion(secret, "secret_client", now: now)

      assert {:error, %Error{reason_code: :unsupported_token_endpoint_auth_method}} =
               ClientAuth.authenticate(
                 jwt_client_assertion_params(assertion),
                 nil,
                 client_store: __MODULE__.ClientSecretJwtStore,
                 jti_store: __MODULE__.ReplayStore,
                 server_policy_store: __MODULE__.ServerPolicyStore,
                 now: now
               )
    end

    test "rejects disallowed algorithms, audience mismatches, replay, and FAPI-effective profiles" do
      secret = "phase88-client-secret"
      Process.put(:client_secret_jwt_secret, secret)
      now = DateTime.utc_now() |> DateTime.truncate(:second)

      bad_alg_assertion =
        client_secret_signed_assertion(secret, "secret_client", alg: "HS512", now: now)

      assert {:error, %Error{reason_code: :client_assertion_algorithm_not_allowed}} =
               ClientAuth.authenticate(
                 jwt_client_assertion_params(bad_alg_assertion),
                 nil,
                 client_store: __MODULE__.ClientSecretJwtStore,
                 jti_store: __MODULE__.ReplayStore,
                 server_policy_store: __MODULE__.ServerPolicyStore,
                 supported_jwt_auth_methods: [:private_key_jwt, :client_secret_jwt],
                 now: now
               )

      bad_audience_assertion =
        client_secret_signed_assertion(secret, "secret_client",
          aud: Lockspire.Config.issuer!() <> "/token",
          now: now,
          jti: "bad-audience"
        )

      assert {:error, %Error{reason_code: :client_assertion_audience_invalid}} =
               ClientAuth.authenticate(
                 jwt_client_assertion_params(bad_audience_assertion),
                 nil,
                 client_store: __MODULE__.ClientSecretJwtStore,
                 jti_store: __MODULE__.ReplayStore,
                 server_policy_store: __MODULE__.ServerPolicyStore,
                 supported_jwt_auth_methods: [:private_key_jwt, :client_secret_jwt],
                 now: now
               )

      valid_assertion =
        client_secret_signed_assertion(secret, "secret_client",
          now: now,
          jti: "client-secret-replay"
        )

      assert {:ok, %Client{client_id: "secret_client"}} =
               ClientAuth.authenticate(
                 jwt_client_assertion_params(valid_assertion),
                 nil,
                 client_store: __MODULE__.ClientSecretJwtStore,
                 jti_store: __MODULE__.ReplayStore,
                 server_policy_store: __MODULE__.ServerPolicyStore,
                 supported_jwt_auth_methods: [:private_key_jwt, :client_secret_jwt],
                 now: now
               )

      assert {:error, %Error{reason_code: :client_assertion_replayed}} =
               ClientAuth.authenticate(
                 jwt_client_assertion_params(valid_assertion),
                 nil,
                 client_store: __MODULE__.ClientSecretJwtStore,
                 jti_store: __MODULE__.ReplayStore,
                 server_policy_store: __MODULE__.ServerPolicyStore,
                 supported_jwt_auth_methods: [:private_key_jwt, :client_secret_jwt],
                 now: now
               )

      fapi_assertion = client_secret_signed_assertion(secret, "secret_client", now: now)

      assert {:error, %Error{reason_code: :client_assertion_auth_method_not_allowed}} =
               ClientAuth.authenticate(
                 jwt_client_assertion_params(fapi_assertion),
                 nil,
                 client_store: __MODULE__.ClientSecretJwtStore,
                 jti_store: __MODULE__.ReplayStore,
                 server_policy_store: __MODULE__.FapiServerPolicyStore,
                 supported_jwt_auth_methods: [:private_key_jwt, :client_secret_jwt],
                 now: now
               )
    end

    test "emits stable telemetry and redacted audit metadata for symmetric verifier failures" do
      secret = "phase88-client-secret"
      Process.put(:client_secret_jwt_secret, secret)
      now = DateTime.utc_now() |> DateTime.truncate(:second)
      parent = self()
      handler_id = "client-secret-jwt-test-#{System.unique_integer([:positive])}"

      :telemetry.attach_many(
        handler_id,
        [
          [:lockspire, :client_auth, :failed],
          [:lockspire, :client_auth, :replay_detected]
        ],
        fn event, _measurements, metadata, pid -> send(pid, {event, metadata}) end,
        parent
      )

      on_exit(fn -> :telemetry.detach(handler_id) end)

      invalid_signature_assertion =
        client_secret_signed_assertion("wrong-secret", "secret_client", now: now)

      assert {:error, %Error{reason_code: :client_assertion_signature_invalid}} =
               ClientAuth.authenticate(
                 jwt_client_assertion_params(invalid_signature_assertion),
                 nil,
                 client_store: __MODULE__.ClientSecretJwtStore,
                 jti_store: __MODULE__.ReplayStore,
                 server_policy_store: __MODULE__.ServerPolicyStore,
                 supported_jwt_auth_methods: [:private_key_jwt, :client_secret_jwt],
                 now: now
               )

      valid_assertion =
        client_secret_signed_assertion(secret, "secret_client", now: now, jti: "audit-replay")

      assert {:ok, %Client{client_id: "secret_client"}} =
               ClientAuth.authenticate(
                 jwt_client_assertion_params(valid_assertion),
                 nil,
                 client_store: __MODULE__.ClientSecretJwtStore,
                 jti_store: __MODULE__.ReplayStore,
                 server_policy_store: __MODULE__.ServerPolicyStore,
                 supported_jwt_auth_methods: [:private_key_jwt, :client_secret_jwt],
                 now: now
               )

      assert {:error, %Error{reason_code: :client_assertion_replayed}} =
               ClientAuth.authenticate(
                 jwt_client_assertion_params(valid_assertion),
                 nil,
                 client_store: __MODULE__.ClientSecretJwtStore,
                 jti_store: __MODULE__.ReplayStore,
                 server_policy_store: __MODULE__.ServerPolicyStore,
                 supported_jwt_auth_methods: [:private_key_jwt, :client_secret_jwt],
                 now: now
               )

      assert_receive {[:lockspire, :client_auth, :failed],
                      %{
                        reason_code: :client_assertion_signature_invalid,
                        auth_method: :client_secret_jwt
                      }}

      assert_receive {[:lockspire, :client_auth, :replay_detected],
                      %{reason_code: :client_assertion_replayed, auth_method: :client_secret_jwt}}

      audits = Process.get(:recorded_audit_events, [])

      assert Enum.any?(audits, &(&1.reason_code == "client_assertion_signature_invalid"))
      assert Enum.any?(audits, &(&1.reason_code == "client_assertion_replayed"))
      refute Enum.any?(audits, &Map.has_key?(&1.metadata, "client_assertion"))
      refute Enum.any?(audits, &Map.has_key?(&1.metadata, "jwt_claims"))
      refute Enum.any?(audits, &Map.has_key?(&1.metadata, "client_secret_jwt_verifier_encrypted"))
    end
  end

  @der_cert Base.decode64!(
              "MIIDlzCCAn+gAwIBAgIUf9kmQnJK500+Nv0BWu0gM48zcgIwDQYJKoZIhvcNAQELBQAwNjEUMBIGA1UEAwwLZXhhbXBsZS5jb20xETAPBgNVBAoMCFRlc3QgT3JnMQswCQYDVQQGEwJVUzAeFw0yNjA1MjIyMjI0MzhaFw0zNjA1MTkyMjI0MzhaMDYxFDASBgNVBAMMC2V4YW1wbGUuY29tMREwDwYDVQQKDAhUZXN0IE9yZzELMAkGA1UEBhMCVVMwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCnzGcJzq614Cz9AN6axBrGwnx0odNBZJjdQ0VODx+WxDWepf5B9+B0qNEyMBg6eMzRWNSXPs5VaglfJUte35OTXtIh+Rz84PyPw7a8Yg+4EOasw2zqsxN+9uH/VYpV3dcrEJdA9Xx0x0ksLWV0vClTCSWNnJbJ8caftyp6fUL2kBPxv0nX/MVjNJxcm5QAmHXh+dSZ2CgZr6bdzN3JzNdc9JeYVJ9/7sMi7mbjSwLZElBBLIlPtJX7jVVTxLKR5UTnY9kYdxF3VaF42P/YPrcYJQ5LH8iilBxYL/qnct+ZwzvYgKACB8CEzNqIhTbDXzFh6J97OFDUnm+5XWIFMt+fAgMBAAGjgZwwgZkwHQYDVR0OBBYEFPEcpeN1EnkmQ7VbwOCyeUCfhwTmMB8GA1UdIwQYMBaAFPEcpeN1EnkmQ7VbwOCyeUCfhwTmMA8GA1UdEwEB/wQFMAMBAf8wRgYDVR0RBD8wPYILZXhhbXBsZS5jb22GFmh0dHBzOi8vZXhhbXBsZS5jb20vaWSHBMCoAQGBEHRlc3RAZXhhbXBsZS5jb20wDQYJKoZIhvcNAQELBQADggEBAJtQ86lCGy/Y+7SRx/sFWYhC9UaeRJix84ZBnqVEMA37uvZQ4N3AHP+XDhuhSe++ZMqkp9sZHsWQCIZkmqqLUtRUKGiFbe9DcSvbn9PuSN56EbLM0ZCNIt41lEpAYVOogeakehvU0YsSPA4p/MxQ7ZkizWqY9iqnZC93RX43FFLVlpR0YTnq4tiTo4Eln5kLdqhMJdBM/PUUjQAsKK4tUrxRI5u7ycKzI04/M8mo5tbg3UsIiZ4WiFaUENCMcI4RxQca2Kn5mN3gJyaE/NNM2E1fRhZQThVIGZOXO+BIvf1McaOBGbLeRdr2pP3/CORqljaH+kapJnOFVFw+N1daB8g="
            )

  describe "authenticate/3 with MTLS" do
    test "resolves implicit client id to tls_client_auth and succeeds" do
      assert {:ok, %Client{client_id: "mtls_client"}} =
               ClientAuth.authenticate(
                 %{"client_id" => "mtls_client"},
                 nil,
                 client_store: __MODULE__.MtlsStore,
                 server_policy_store: __MODULE__.ServerPolicyStore,
                 mtls_cert: @der_cert
               )
    end

    test "resolves implicit client id to self_signed_tls_client_auth and succeeds" do
      {:ok, parsed} = Lockspire.Mtls.Certificate.parse(@der_cert)
      jwk = JOSE.JWK.from_key(parsed.public_key)
      {_modules, jwk_map} = JOSE.JWK.to_map(jwk)
      Process.put(:self_signed_jwks, %{"keys" => [jwk_map]})

      assert {:ok, %Client{client_id: "self_signed_client"}} =
               ClientAuth.authenticate(
                 %{"client_id" => "self_signed_client"},
                 nil,
                 client_store: __MODULE__.MtlsStore,
                 server_policy_store: __MODULE__.ServerPolicyStore,
                 mtls_cert: @der_cert
               )
    end

    test "returns error when mtls certificate is invalid" do
      assert {:error, %Error{reason_code: :missing_certificate}} =
               ClientAuth.authenticate(
                 %{"client_id" => "mtls_client"},
                 nil,
                 client_store: __MODULE__.MtlsStore,
                 server_policy_store: __MODULE__.ServerPolicyStore,
                 mtls_cert: nil
               )
    end
  end

  defmodule MockStore do
    def fetch_client_by_id("test_client") do
      {:ok,
       %Client{
         client_id: "test_client",
         token_endpoint_auth_method: :private_key_jwt,
         jwks: Process.get(:inline_pub_jwk_map)
       }}
    end

    def fetch_client_by_id(_), do: {:ok, nil}
  end

  defmodule ClientSecretJwtStore do
    def fetch_client_by_id("secret_client") do
      {:ok,
       %Client{
         client_id: "secret_client",
         client_type: :confidential,
         token_endpoint_auth_method: :client_secret_jwt,
         client_secret_jwt_verifier_encrypted:
           Lockspire.Security.Policy.seal_client_secret_jwt_verifier(
             Process.get(:client_secret_jwt_secret) || raise("missing test secret")
           )
       }}
    end

    def fetch_client_by_id("basic_client") do
      {:ok,
       %Client{
         client_id: "basic_client",
         client_type: :confidential,
         token_endpoint_auth_method: :client_secret_basic,
         client_secret_hash: Lockspire.Security.Policy.hash_client_secret("basic-client-secret")
       }}
    end

    def fetch_client_by_id(_), do: {:ok, nil}
  end

  defmodule RemoteClientStore do
    def fetch_client_by_id("remote_client") do
      {:ok,
       %Client{
         client_id: "remote_client",
         token_endpoint_auth_method: :private_key_jwt,
         jwks_uri: "https://keys.example.test/client.jwks.json"
       }}
    end

    def fetch_client_by_id(_), do: {:ok, nil}
  end

  defmodule RemoteJwksFetcher do
    def get_keys(uri, _opts) do
      Process.put(:fetched_jwks_uri, uri)

      case Process.get(:remote_jwks_get_error) do
        nil -> {:ok, Process.get(:remote_jwks)}
        error -> {:error, error}
      end
    end

    def refresh_keys(uri, _opts) do
      Process.put(:refreshed_jwks_uri, uri)

      case Process.get(:remote_jwks_refresh_error) do
        nil -> {:ok, Process.get(:refreshed_remote_jwks)}
        error -> {:error, error}
      end
    end
  end

  defmodule ReplayStore do
    def record_used_jti(%{jti: jti} = used_jti) do
      if Process.get(:force_replay_store_error) do
        {:error, :store_down}
      else
        Process.put(:recorded_jtis, [used_jti | Process.get(:recorded_jtis, [])])

        used_jtis = Process.get(:used_jtis, MapSet.new())

        if MapSet.member?(used_jtis, {used_jti.client_id, jti}) do
          {:ok, :replay}
        else
          Process.put(:used_jtis, MapSet.put(used_jtis, {used_jti.client_id, jti}))
          {:ok, :accepted}
        end
      end
    end

    def append_audit_event(event) do
      Process.put(:recorded_audit_events, [event | Process.get(:recorded_audit_events, [])])
      {:ok, event}
    end
  end

  defmodule MtlsStore do
    def fetch_client_by_id("mtls_client") do
      {:ok,
       %Client{
         client_id: "mtls_client",
         token_endpoint_auth_method: :tls_client_auth,
         tls_client_auth_subject_dn: "C=US,O=Test Org,CN=example.com"
       }}
    end

    def fetch_client_by_id("self_signed_client") do
      {:ok,
       %Client{
         client_id: "self_signed_client",
         token_endpoint_auth_method: :self_signed_tls_client_auth,
         jwks: Process.get(:self_signed_jwks)
       }}
    end

    def fetch_client_by_id(_), do: {:ok, nil}
  end

  defmodule ServerPolicyStore do
    def get_server_policy do
      {:ok, %ServerPolicy{security_profile: :none}}
    end
  end

  defmodule FapiServerPolicyStore do
    def get_server_policy do
      {:ok, %ServerPolicy{security_profile: :fapi_2_0_security}}
    end
  end

  defp jwt_client_assertion_params(assertion) do
    %{
      "client_assertion_type" => "urn:ietf:params:oauth:client-assertion-type:jwt-bearer",
      "client_assertion" => assertion
    }
  end

  defp private_key_jwt_params(assertion), do: jwt_client_assertion_params(assertion)

  defp signed_assertion(private_jwk, client_id, opts \\ []) do
    now = Keyword.get(opts, :now, DateTime.utc_now() |> DateTime.truncate(:second))

    JarTestHelpers.sign_jar(
      private_jwk,
      %{
        "iss" => client_id,
        "sub" => client_id,
        "aud" => Keyword.get(opts, :aud, Lockspire.Config.issuer!()),
        "jti" => Keyword.get(opts, :jti, "jti-#{System.unique_integer([:positive])}"),
        "iat" => DateTime.to_unix(now),
        "exp" => DateTime.add(now, 300, :second) |> DateTime.to_unix()
      },
      alg: Keyword.get(opts, :alg, "RS256"),
      extra_header:
        case Keyword.get(opts, :kid) do
          kid when is_binary(kid) -> %{"kid" => kid}
          _ -> %{}
        end
    )
  end

  defp unsigned_assertion(payload) do
    header = Base.url_encode64(Jason.encode!(%{"alg" => "none"}), padding: false)
    payload_b64 = Base.url_encode64(Jason.encode!(payload), padding: false)
    "#{header}.#{payload_b64}."
  end

  defp client_secret_signed_assertion(secret, client_id, opts) do
    now = Keyword.get(opts, :now, DateTime.utc_now() |> DateTime.truncate(:second))

    JarTestHelpers.sign_jar(
      JOSE.JWK.from_oct(secret),
      %{
        "iss" => client_id,
        "sub" => client_id,
        "aud" => Keyword.get(opts, :aud, Lockspire.Config.issuer!()),
        "jti" => Keyword.get(opts, :jti, "jti-#{System.unique_integer([:positive])}"),
        "iat" => DateTime.to_unix(now),
        "exp" => DateTime.add(now, 300, :second) |> DateTime.to_unix()
      },
      alg: Keyword.get(opts, :alg, "HS256")
    )
  end
end
