defmodule Lockspire.Protocol.ClientAuthTest do
  use ExUnit.Case, async: false

  alias Lockspire.Domain.Client
  alias Lockspire.Domain.ServerPolicy
  alias Lockspire.Protocol.ClientAuth
  alias Lockspire.Protocol.ClientAuth.Error
  alias Lockspire.JarTestHelpers

  setup do
    Process.delete(:fetched_jwks_uri)
    Process.delete(:inline_pub_jwk_map)
    Process.delete(:remote_jwks)
    Process.delete(:used_jtis)
    Process.delete(:recorded_jtis)
    Process.delete(:recorded_audit_events)
    Process.delete(:force_replay_store_error)
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
      {:ok, Process.get(:remote_jwks)}
    end

    def refresh_keys(uri, _opts) do
      Process.put(:refreshed_jwks_uri, uri)
      {:ok, Process.get(:refreshed_remote_jwks)}
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

  defp private_key_jwt_params(assertion) do
    %{
      "client_assertion_type" => "urn:ietf:params:oauth:client-assertion-type:jwt-bearer",
      "client_assertion" => assertion
    }
  end

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
end
