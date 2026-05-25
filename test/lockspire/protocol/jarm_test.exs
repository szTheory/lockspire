defmodule Lockspire.Protocol.JarmTest do
  use ExUnit.Case, async: true

  alias Lockspire.JarTestHelpers
  alias Lockspire.Protocol.Jarm
  alias Lockspire.Protocol.Jarm.ClientKeyResolver
  alias Lockspire.Domain.Client
  alias Lockspire.Domain.SigningKey

  defmodule MockKeyStore do
    def fetch_active_signing_key(opts) do
      key = Process.get(:mock_signing_key)

      if key do
        {:ok, %{key | alg: Keyword.get(opts, :alg, "RS256")}}
      else
        {:ok, nil}
      end
    end
  end

  defmodule MockJwksFetcher do
    def get_keys(uri, _opts) do
      send(self(), {:jwks_get_keys, uri})
      Process.get({__MODULE__, :get_keys_result}, {:error, {:jwks_fetch_failed, :missing}})
    end

    def refresh_keys(uri, _opts) do
      send(self(), {:jwks_refresh_keys, uri})
      Process.get({__MODULE__, :refresh_keys_result}, {:error, {:jwks_fetch_failed, :missing}})
    end
  end

  setup do
    keys = JarTestHelpers.generate_keys()
    {_modules, private_jwk_map} = JOSE.JWK.to_map(keys.private_jwk)

    key = %SigningKey{
      kid: "mock-kid",
      alg: "RS256",
      private_jwk_encrypted: Jason.encode!(private_jwk_map)
    }

    Process.put(:mock_signing_key, key)

    %{keys: keys}
  end

  test "client key resolver prefers use=enc and matching kid for inline jwks" do
    rsa_enc_jwk = JOSE.JWK.generate_key({:rsa, 2048})
    rsa_sig_jwk = JOSE.JWK.generate_key({:rsa, 2048})

    {_rsa_enc_kty, rsa_enc_map} =
      rsa_enc_jwk
      |> JOSE.JWK.to_public_map()

    {_rsa_sig_kty, rsa_sig_map} =
      rsa_sig_jwk
      |> JOSE.JWK.to_public_map()

    client = %Client{
      client_id: "client-inline",
      jwks: %{
        "keys" => [
          Map.merge(rsa_sig_map, %{"kid" => "sig", "use" => "sig"}),
          Map.merge(rsa_enc_map, %{"kid" => "enc", "use" => "enc"})
        ]
      }
    }

    assert {:ok, %JOSE.JWK{} = jwk, :inline_jwks} =
             ClientKeyResolver.resolve(
               client,
               %{alg: "RSA-OAEP-256", enc: "A256GCM", kid: "enc"},
               jwks_fetcher: MockJwksFetcher
             )

    {_kty, resolved_map} = JOSE.JWK.to_public_map(jwk)
    assert resolved_map["kid"] == "enc"
    assert resolved_map["use"] == "enc"
  end

  test "client key resolver refreshes guarded jwks_uri at most once on stale cached keys" do
    cached_jwk =
      public_jwk_map(JOSE.JWK.generate_key({:rsa, 2048}), %{"kid" => "stale", "use" => "enc"})

    fresh_jwk =
      public_jwk_map(JOSE.JWK.generate_key({:rsa, 2048}), %{"kid" => "fresh", "use" => "enc"})

    Process.put(
      {MockJwksFetcher, :get_keys_result},
      {:ok, JOSE.JWK.from_map(%{"keys" => [cached_jwk]})}
    )

    Process.put(
      {MockJwksFetcher, :refresh_keys_result},
      {:ok, JOSE.JWK.from_map(%{"keys" => [fresh_jwk]})}
    )

    client = %Client{
      client_id: "client-remote",
      jwks_uri: "https://client.example.com/jwks.json"
    }

    assert {:ok, %JOSE.JWK{} = jwk, :jwks_uri} =
             ClientKeyResolver.resolve(
               client,
               %{alg: "RSA-OAEP-256", enc: "A256GCM", kid: "fresh"},
               jwks_fetcher: MockJwksFetcher
             )

    {_kty, resolved_map} = JOSE.JWK.to_public_map(jwk)
    assert resolved_map["kid"] == "fresh"
    assert_received {:jwks_get_keys, "https://client.example.com/jwks.json"}
    assert_received {:jwks_refresh_keys, "https://client.example.com/jwks.json"}
    refute_received {:jwks_refresh_keys, "https://client.example.com/jwks.json"}
  end

  test "client key resolver returns stable errors for unsupported key shape and algorithm pairs" do
    ec_jwk =
      public_jwk_map(JOSE.JWK.generate_key({:ec, "P-256"}), %{"kid" => "ec-enc", "use" => "enc"})

    client = %Client{
      client_id: "client-inline-bad-key",
      jwks: %{"keys" => [ec_jwk]}
    }

    assert {:error, :unsupported_jarm_encryption_alg} =
             ClientKeyResolver.resolve(
               client,
               %{alg: "RSA1_5", enc: "A256GCM"},
               jwks_fetcher: MockJwksFetcher
             )

    assert {:error, :jarm_encryption_key_unavailable} =
             ClientKeyResolver.resolve(
               client,
               %{alg: "RSA-OAEP-256", enc: "A256GCM"},
               jwks_fetcher: MockJwksFetcher
             )
  end

  test "client key resolver emits shared remote jwks metadata for post-refresh key unavailability" do
    cached_jwk =
      public_jwk_map(JOSE.JWK.generate_key({:rsa, 2048}), %{"kid" => "stale", "use" => "enc"})

    refreshed_jwk =
      public_jwk_map(JOSE.JWK.generate_key({:rsa, 2048}), %{"kid" => "other", "use" => "enc"})

    Process.put(
      {MockJwksFetcher, :get_keys_result},
      {:ok, JOSE.JWK.from_map(%{"keys" => [cached_jwk]})}
    )

    Process.put(
      {MockJwksFetcher, :refresh_keys_result},
      {:ok, JOSE.JWK.from_map(%{"keys" => [refreshed_jwk]})}
    )

    parent = self()
    handler_id = "jarm-remote-key-unavailable-#{System.unique_integer([:positive])}"

    :telemetry.attach(
      handler_id,
      [:lockspire, :jarm, :failed],
      fn event, _measurements, metadata, pid -> send(pid, {event, metadata}) end,
      parent
    )

    on_exit(fn -> :telemetry.detach(handler_id) end)

    client = %Client{
      client_id: "client-remote",
      jwks_uri: "https://client.example.com/jwks.json"
    }

    assert {:error, :jarm_encryption_key_unavailable} =
             ClientKeyResolver.resolve(
               client,
               %{alg: "RSA-OAEP-256", enc: "A256GCM", kid: "fresh"},
               jwks_fetcher: MockJwksFetcher
             )

    assert_receive {[:lockspire, :jarm, :failed],
                    %{
                      reason_code: :jarm_encryption_key_unavailable,
                      remote_jwks_incident_class: :remote_jwks_key_unavailable,
                      remote_jwks_consumer: :jarm,
                      remote_jwks_stage: :select_key,
                      remote_jwks_subreason: :post_refresh_key_still_missing,
                      remote_jwks_forced_refresh_attempted?: true,
                      remote_jwks_requested_kid_present_in_cached_set?: false
                    }}
  end

  test "client key resolver emits shared remote jwks metadata for fetch failures" do
    Process.put(
      {MockJwksFetcher, :get_keys_result},
      {:error, {:jwks_fetch_failed, {:http_status, 503}}}
    )

    parent = self()
    handler_id = "jarm-remote-fetch-failure-#{System.unique_integer([:positive])}"

    :telemetry.attach(
      handler_id,
      [:lockspire, :jarm, :failed],
      fn event, _measurements, metadata, pid -> send(pid, {event, metadata}) end,
      parent
    )

    on_exit(fn -> :telemetry.detach(handler_id) end)

    client = %Client{
      client_id: "client-remote",
      jwks_uri: "https://client.example.com/jwks.json"
    }

    assert {:error, :jarm_encryption_key_fetch_failed} =
             ClientKeyResolver.resolve(
               client,
               %{alg: "RSA-OAEP-256", enc: "A256GCM", kid: "fresh"},
               jwks_fetcher: MockJwksFetcher
             )

    assert_receive {[:lockspire, :jarm, :failed],
                    %{
                      reason_code: :jarm_encryption_key_fetch_failed,
                      remote_jwks_incident_class: :remote_jwks_fetch_failed,
                      remote_jwks_consumer: :jarm,
                      remote_jwks_stage: :network,
                      remote_jwks_subreason: :http_status,
                      remote_jwks_fetch_status: 503,
                      remote_jwks_forced_refresh_attempted?: false
                    }}
  end

  test "sign/2 successfully signs a map into JWS and injects standard claims", %{keys: keys} do
    params = %{code: "auth_code_123", state: "abc"}

    client = %Client{
      client_id: "client-123",
      authorization_signed_response_alg: :RS256,
      security_profile: :none
    }

    context = %{
      client: client,
      issuer: "https://auth.example.com",
      key_store: MockKeyStore
    }

    assert {:ok, jwt} = Jarm.sign(params, context)

    claims = decode_claims(jwt, keys, ["RS256"])

    assert claims["iss"] == "https://auth.example.com"
    assert claims["aud"] == "client-123"
    assert is_integer(claims["exp"])
    assert claims["code"] == "auth_code_123"
    assert claims["state"] == "abc"
  end

  test "sign/2 returns error when key is missing" do
    Process.put(:mock_signing_key, nil)
    params = %{}
    client = %Client{client_id: "client-123"}
    context = %{client: client, issuer: "iss", key_store: MockKeyStore}

    assert {:error, :invalid_signing_key} = Jarm.sign(params, context)
  end

  test "sign/2 rejects none algorithm" do
    params = %{}
    client = %Client{client_id: "client-123", authorization_signed_response_alg: :none}
    context = %{client: client, issuer: "iss", key_store: MockKeyStore}

    assert {:error, :invalid_algorithm} = Jarm.sign(params, context)
  end

  test "sign/2 rejects strict message-signing clients without an explicit compliant JARM algorithm" do
    params = %{}

    client = %Client{
      client_id: "client-123",
      authorization_signed_response_alg: nil,
      security_profile: :inherit
    }

    context = %{
      client: client,
      issuer: "iss",
      key_store: MockKeyStore,
      security_profile: :fapi_2_0_message_signing
    }

    assert {:error, :invalid_jarm_client_metadata} = Jarm.sign(params, context)
  end

  test "encode/2 returns signed JWS when encryption metadata is absent", %{keys: keys} do
    client = %Client{
      client_id: "client-signed-only",
      authorization_signed_response_alg: :RS256,
      security_profile: :none
    }

    context = %{
      client: client,
      issuer: "https://auth.example.com",
      key_store: MockKeyStore,
      jwks_fetcher: MockJwksFetcher
    }

    assert {:ok, jwt} = Jarm.encode(%{code: "signed-only-code", state: "abc"}, context)
    assert length(String.split(jwt, ".")) == 3

    claims = decode_claims(jwt, keys, ["RS256"])
    assert claims["code"] == "signed-only-code"
  end

  test "encode/2 signs first and then encrypts into a nested JWE", %{keys: keys} do
    enc_private_jwk = JOSE.JWK.generate_key({:rsa, 2048})

    client = %Client{
      client_id: "client-nested",
      authorization_signed_response_alg: :RS256,
      authorization_encrypted_response_alg: :RSA_OAEP_256,
      authorization_encrypted_response_enc: :A256GCM,
      jwks: %{"keys" => [public_jwk_map(enc_private_jwk, %{"kid" => "enc-1", "use" => "enc"})]},
      security_profile: :none
    }

    context = %{
      client: client,
      issuer: "https://auth.example.com",
      key_store: MockKeyStore,
      jwks_fetcher: MockJwksFetcher
    }

    assert {:ok, jwt} = Jarm.encode(%{code: "nested-code", state: "xyz"}, context)
    assert length(String.split(jwt, ".")) == 5

    inner_jws = decrypt_nested_jwe(jwt, enc_private_jwk)
    assert length(String.split(inner_jws, ".")) == 3

    claims = decode_claims(inner_jws, keys, ["RS256"])
    assert claims["code"] == "nested-code"
    assert claims["state"] == "xyz"
  end

  defp decode_claims(jwt, keys, allowed_algs) do
    {_modules, public_jwk_map} = JOSE.JWK.to_public_map(keys.private_jwk)
    public_jwk = JOSE.JWK.from_map(public_jwk_map)

    assert {true, %JOSE.JWT{fields: claims}, _jws} =
             JOSE.JWT.verify_strict(public_jwk, allowed_algs, jwt)

    claims
  end

  defp public_jwk_map(jwk, overrides) do
    {_kty, jwk_map} = JOSE.JWK.to_public_map(jwk)
    Map.merge(jwk_map, overrides)
  end

  defp decrypt_nested_jwe(jwt, private_jwk) do
    assert {inner_jws, %JOSE.JWE{}} = JOSE.JWK.block_decrypt(jwt, private_jwk)
    inner_jws
  end
end
