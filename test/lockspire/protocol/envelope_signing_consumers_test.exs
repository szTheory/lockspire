defmodule Lockspire.Protocol.EnvelopeSigningConsumersTest do
  use ExUnit.Case, async: false

  alias Lockspire.Host.Claims
  alias Lockspire.JarTestHelpers
  alias Lockspire.KeyEncryptionHelpers
  alias Lockspire.Protocol.IdToken

  @issued_at ~U[2026-04-28 15:00:00Z]

  defp sealed_key(keys, kid, alg \\ "RS256") do
    jwk = Map.put(keys.priv_jwk_map, "kid", kid)

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
  end
end
