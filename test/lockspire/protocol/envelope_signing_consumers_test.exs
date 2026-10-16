defmodule Lockspire.Protocol.EnvelopeSigningConsumersTest do
  use ExUnit.Case, async: false

  alias Lockspire.Domain.Client
  alias Lockspire.Domain.LogoutDelivery
  alias Lockspire.Domain.LogoutEvent
  alias Lockspire.Domain.ServerPolicy
  alias Lockspire.Domain.Token
  alias Lockspire.Host.Claims
  alias Lockspire.JarTestHelpers
  alias Lockspire.KeyEncryptionHelpers
  alias Lockspire.Protocol.AccessTokenSigner
  alias Lockspire.Protocol.IdToken
  alias Lockspire.Protocol.IntrospectionJwt
  alias Lockspire.Protocol.Jar
  alias Lockspire.Protocol.Jarm
  alias Lockspire.Protocol.LogoutToken
  alias Lockspire.Protocol.TokenExchange.Error

  @issued_at ~U[2026-04-28 15:00:00Z]

  defp sealed_key(keys, kid, alg \\ "RS256") do
    jwk = Map.put(keys.priv_jwk_map, "kid", kid)

    %{
      kid: kid,
      alg: alg,
      private_jwk_encrypted: KeyEncryptionHelpers.seal_private_jwk(kid, jwk)
    }
  end

  defp malformed_sealed_key(kid, alg \\ "EdDSA") do
    {_meta, map} = {:okp, :Ed25519} |> JOSE.JWK.generate_key() |> JOSE.JWK.to_map()

    jwk =
      map
      |> Map.put("kid", kid)
      |> Map.put("d", Base.url_encode64("not-thirty-two-bytes", padding: false))

    %{
      kid: kid,
      alg: alg,
      private_jwk_encrypted: KeyEncryptionHelpers.seal_private_jwk(kid, jwk)
    }
  end

  defp tamper(%{private_jwk_encrypted: bin} = key) do
    size = byte_size(bin) - 1
    <<head::binary-size(size), last>> = bin
    %{key | private_jwk_encrypted: <<head::binary, Bitwise.bxor(last, 1)>>}
  end

  defp legacy_key(keys, kid, alg \\ "RS256") do
    %{
      kid: kid,
      alg: alg,
      private_jwk_encrypted: Jason.encode!(Map.put(keys.priv_jwk_map, "kid", kid))
    }
  end

  defp reject_mode do
    KeyEncryptionHelpers.put_key_encryption(
      keys: KeyEncryptionHelpers.config_keys(),
      current: "test-1",
      legacy_plaintext: :reject
    )
  end

  defmodule KeyStore do
    @moduledoc false
    def fetch_active_signing_key(opts) do
      case Process.get(:envelope_key) do
        nil -> {:ok, nil}
        key -> {:ok, %{key | alg: Keyword.get(opts, :alg, key.alg)}}
      end
    end
  end

  defmodule PolicyStore do
    @moduledoc false
    def get_server_policy, do: {:ok, %ServerPolicy{access_token_format: :jwt}}
  end

  defp verify(jwt, keys, algs \\ ["RS256"]) do
    {_m, pub} = JOSE.JWK.to_public_map(keys.private_jwk)

    {valid?, %JOSE.JWT{fields: claims}, _} =
      JOSE.JWT.verify_strict(JOSE.JWK.from_map(pub), algs, jwt)

    assert valid?
    claims
  end

  describe "ID token" do
    defp id_token_params(key) do
      %{
        client_id: "client-123",
        issuer: "https://example.test/lockspire",
        host_claims: %Claims{subject: "sub-1", id_token: %{}, userinfo: %{}},
        interaction_nonce: "nonce-123",
        access_token: "access-token-123",
        issued_at: @issued_at,
        signing_key: key
      }
    end

    test "sealed row signs a verifiable token" do
      keys = JarTestHelpers.generate_keys()
      key = sealed_key(keys, "kid-env")

      assert {:ok, jwt} = IdToken.sign(id_token_params(key))
      {_m, pub} = JOSE.JWK.to_public_map(keys.private_jwk)

      assert {true, %JOSE.JWT{fields: %{"iss" => "https://example.test/lockspire"}}, _} =
               JOSE.JWT.verify_strict(JOSE.JWK.from_map(pub), ["RS256"], jwt)
    end

    test "legacy JSON row still signs" do
      keys = JarTestHelpers.generate_keys()

      key = %{
        kid: "kid-legacy",
        alg: "RS256",
        private_jwk_encrypted: Jason.encode!(keys.priv_jwk_map)
      }

      assert {:ok, _jwt} = IdToken.sign(id_token_params(key))
    end

    test "tampered envelope returns invalid_signing_key" do
      key = JarTestHelpers.generate_keys() |> sealed_key("kid-env") |> tamper()
      assert {:error, :invalid_signing_key} = IdToken.sign(id_token_params(key))
    end

    test "malformed sealed key returns invalid_signing_key without raising" do
      key = malformed_sealed_key("kid-env")
      assert {:error, :invalid_signing_key} = IdToken.sign(id_token_params(key))
    end

    test "under :reject a legacy row returns invalid_signing_key and an envelope row signs" do
      keys = JarTestHelpers.generate_keys()

      legacy = %{
        kid: "kid-legacy",
        alg: "RS256",
        private_jwk_encrypted: Jason.encode!(keys.priv_jwk_map)
      }

      sealed = sealed_key(keys, "kid-env")

      KeyEncryptionHelpers.put_key_encryption(
        keys: KeyEncryptionHelpers.config_keys(),
        current: "test-1",
        legacy_plaintext: :reject
      )

      assert {:error, :invalid_signing_key} = IdToken.sign(id_token_params(legacy))
      assert {:ok, _jwt} = IdToken.sign(id_token_params(sealed))
    end
  end

  describe "logout token" do
    defp logout_params(key) do
      %{
        issuer: "https://example.test/lockspire",
        logout_event: %LogoutEvent{event_id: "evt-1", sid: "sid-1", subject: "sub-1"},
        delivery: %LogoutDelivery{
          delivery_id: "d-1",
          client_id: "client-1",
          channel: :backchannel,
          target_uri: "https://snapshot.example.com/backchannel-logout",
          session_required: true
        },
        issued_at: @issued_at,
        signing_key: key
      }
    end

    test "sealed row signs a verifiable token" do
      keys = JarTestHelpers.generate_keys()
      assert {:ok, jwt, _jti} = LogoutToken.sign(logout_params(sealed_key(keys, "kid-lo")))
      assert verify(jwt, keys)["aud"] == "client-1"
    end

    test "tampered envelope returns invalid_signing_key" do
      key = JarTestHelpers.generate_keys() |> sealed_key("kid-lo") |> tamper()
      assert {:error, :invalid_signing_key} = LogoutToken.sign(logout_params(key))
    end

    test "under :reject a legacy row returns invalid_signing_key" do
      keys = JarTestHelpers.generate_keys()
      reject_mode()

      assert {:error, :invalid_signing_key} =
               LogoutToken.sign(logout_params(legacy_key(keys, "kid-lo")))
    end

    test "unconfigured KEK returns invalid_signing_key" do
      key = JarTestHelpers.generate_keys() |> sealed_key("kid-lo")
      KeyEncryptionHelpers.put_key_encryption(nil)
      assert {:error, :invalid_signing_key} = LogoutToken.sign(logout_params(key))
    end
  end

  describe "JARM" do
    defp jarm_sign(key) do
      Process.put(:envelope_key, struct(Lockspire.Domain.SigningKey, key))

      Jarm.sign(%{code: "c1"}, %{
        client: %Client{
          client_id: "client-1",
          authorization_signed_response_alg: :RS256,
          security_profile: :none
        },
        issuer: "https://auth.example.com",
        key_store: KeyStore
      })
    end

    test "sealed row signs a verifiable response" do
      keys = JarTestHelpers.generate_keys()
      assert {:ok, jwt} = jarm_sign(sealed_key(keys, "kid-jarm"))
      assert verify(jwt, keys)["code"] == "c1"
    end

    test "tampered envelope returns invalid_signing_key" do
      key = JarTestHelpers.generate_keys() |> sealed_key("kid-jarm") |> tamper()
      assert {:error, :invalid_signing_key} = jarm_sign(key)
    end

    test "under :reject a legacy row returns invalid_signing_key" do
      keys = JarTestHelpers.generate_keys()
      reject_mode()
      assert {:error, :invalid_signing_key} = jarm_sign(legacy_key(keys, "kid-jarm"))
    end

    test "unconfigured KEK returns invalid_signing_key" do
      key = JarTestHelpers.generate_keys() |> sealed_key("kid-jarm")
      KeyEncryptionHelpers.put_key_encryption(nil)
      assert {:error, :invalid_signing_key} = jarm_sign(key)
    end
  end

  describe "introspection JWT" do
    defp introspection_sign(key) do
      Process.put(:envelope_key, struct(Lockspire.Domain.SigningKey, key))

      IntrospectionJwt.sign(%{
        issuer: "https://auth.example.com",
        issued_at: ~U[2026-05-08 10:00:00Z],
        success: %{
          payload: %{active: true, client_id: "tc", token_type: "access_token", sub: "a"},
          caller: %Client{client_id: "rs-client", security_profile: :none},
          security_profile: :none
        },
        key_store: KeyStore
      })
    end

    test "sealed row signs a verifiable token" do
      keys = JarTestHelpers.generate_keys()
      assert {:ok, jwt} = introspection_sign(sealed_key(keys, "kid-intro"))
      assert verify(jwt, keys)["aud"] == "rs-client"
    end

    test "tampered envelope returns invalid_signing_key" do
      key = JarTestHelpers.generate_keys() |> sealed_key("kid-intro") |> tamper()
      assert {:error, :invalid_signing_key} = introspection_sign(key)
    end

    test "under :reject a legacy row returns invalid_signing_key" do
      keys = JarTestHelpers.generate_keys()
      reject_mode()
      assert {:error, :invalid_signing_key} = introspection_sign(legacy_key(keys, "kid-intro"))
    end

    test "unconfigured KEK returns invalid_signing_key" do
      key = JarTestHelpers.generate_keys() |> sealed_key("kid-intro")
      KeyEncryptionHelpers.put_key_encryption(nil)
      assert {:error, :invalid_signing_key} = introspection_sign(key)
    end
  end

  describe "access-token signer" do
    defp issue(key) do
      Process.put(:envelope_key, struct(Lockspire.Domain.SigningKey, key))

      token = %Token{
        token_hash: "placeholder",
        token_type: :access_token,
        client_id: "test_client",
        account_id: "account-123",
        scopes: ["read"],
        audience: [],
        expires_at: DateTime.add(DateTime.utc_now(), 3600, :second)
      }

      client = %Client{client_id: "test_client", allowed_grant_types: ["authorization_code"]}

      AccessTokenSigner.issue(token, client, %{
        opts: [key_store: KeyStore, server_policy_store: PolicyStore]
      })
    end

    test "sealed row issues a verifiable JWT (single signer for every grant)" do
      keys = JarTestHelpers.generate_keys()
      assert {:ok, jwt, _hash} = issue(sealed_key(keys, "kid-at"))
      assert verify(jwt, keys)["client_id"] == "test_client"
    end

    test "tampered envelope returns the existing server_error" do
      key = JarTestHelpers.generate_keys() |> sealed_key("kid-at") |> tamper()

      assert {:error,
              %Error{status: 500, error: "server_error", reason_code: :token_signing_failed}} =
               issue(key)
    end

    test "under :reject a legacy row returns the existing server_error (token exchange signer)" do
      keys = JarTestHelpers.generate_keys()
      reject_mode()

      assert {:error,
              %Error{status: 500, error: "server_error", reason_code: :token_signing_failed}} =
               issue(legacy_key(keys, "kid-at"))
    end

    test "unconfigured KEK returns the existing server_error" do
      key = JarTestHelpers.generate_keys() |> sealed_key("kid-at")
      KeyEncryptionHelpers.put_key_encryption(nil)

      assert {:error,
              %Error{status: 500, error: "server_error", reason_code: :token_signing_failed}} =
               issue(key)
    end
  end

  describe "JAR" do
    defp jar_fixture do
      enc = JOSE.JWK.generate_key({:rsa, 2048})
      {_, map} = JOSE.JWK.to_map(enc)
      jwe = JOSE.JWE.block_encrypt(enc, "payload", %{"alg" => "RSA-OAEP", "enc" => "A256GCM"})
      {_, compact} = JOSE.JWE.compact(jwe)

      key = %Lockspire.Domain.SigningKey{
        kid: "kid-jar",
        alg: "RSA-OAEP",
        private_jwk_encrypted:
          KeyEncryptionHelpers.seal_private_jwk("kid-jar", Map.put(map, "kid", "kid-jar"))
      }

      {compact, key}
    end

    test "decrypts a JWE with a sealed key" do
      {compact, key} = jar_fixture()
      assert {:ok, "payload"} = Jar.decrypt(compact, [key])
    end

    test "tampered envelope collapses to decryption_failed" do
      {compact, key} = jar_fixture()
      assert {:error, :decryption_failed} = Jar.decrypt(compact, [tamper(key)])
    end

    test "unconfigured KEK collapses to decryption_failed" do
      {compact, key} = jar_fixture()
      KeyEncryptionHelpers.put_key_encryption(nil)
      assert {:error, :decryption_failed} = Jar.decrypt(compact, [key])
    end

    defp jar_key(kid, map, opts \\ []) do
      jwk = Map.put(map, "kid", kid)

      stored =
        if Keyword.get(opts, :legacy, false),
          do: Jason.encode!(jwk),
          else: KeyEncryptionHelpers.seal_private_jwk(kid, jwk)

      %Lockspire.Domain.SigningKey{kid: kid, alg: "RSA-OAEP", private_jwk_encrypted: stored}
    end

    defp jar_encrypt(enc) do
      jwe = JOSE.JWE.block_encrypt(enc, "payload", %{"alg" => "RSA-OAEP", "enc" => "A256GCM"})
      {_, compact} = JOSE.JWE.compact(jwe)
      compact
    end

    test "under :reject a legacy enc key fails and JAR moves on to an envelope key" do
      enc_a = JOSE.JWK.generate_key({:rsa, 2048})
      enc_b = JOSE.JWK.generate_key({:rsa, 2048})
      {_, map_a} = JOSE.JWK.to_map(enc_a)
      {_, map_b} = JOSE.JWK.to_map(enc_b)
      legacy = jar_key("kid-a", map_a, legacy: true)
      sealed = jar_key("kid-b", map_b)

      reject_mode()
      assert {:error, :decryption_failed} = Jar.decrypt(jar_encrypt(enc_a), [legacy])
      assert {:ok, "payload"} = Jar.decrypt(jar_encrypt(enc_b), [legacy, sealed])
    end

    test "a JWE addressed to another key emits no decode_failed for a readable key" do
      enc_a = JOSE.JWK.generate_key({:rsa, 2048})
      other = JOSE.JWK.generate_key({:rsa, 2048})
      {_, map_a} = JOSE.JWK.to_map(enc_a)
      sealed = jar_key("kid-a", map_a)

      Lockspire.TestSupport.TelemetryCapture.attach([:lockspire, :key, :decode_failed])
      assert {:error, :decryption_failed} = Jar.decrypt(jar_encrypt(other), [sealed])
      refute_received {:telemetry_event, _, _, _}
    end
  end
end
