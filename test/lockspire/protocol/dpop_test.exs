defmodule Lockspire.Protocol.DPoPTest do
  use ExUnit.Case, async: true

  alias Lockspire.Protocol.DPoP
  alias Lockspire.JarTestHelpers

  describe "decode/1" do
    setup do
      keys = JarTestHelpers.generate_ec_keys()

      proof =
        JarTestHelpers.sign_dpop_proof(keys.private_jwk, %{
          "htm" => "POST",
          "htu" => "https://server.example.com/token",
          "iat" => DateTime.utc_now() |> DateTime.to_unix(),
          "jti" => Ecto.UUID.generate()
        })

      %{keys: keys, proof: proof}
    end

    test "decodes claims and protected header into maps", %{proof: proof, keys: keys} do
      assert {:ok, %DPoP{claims: claims, header: header}} = DPoP.decode(proof)
      assert claims["htm"] == "POST"
      assert header["typ"] == "dpop+jwt"
      assert header["jwk"] == keys.pub_jwk_map
    end

    test "returns invalid_jwt for malformed proofs" do
      assert {:error, :invalid_jwt} = DPoP.decode("not.a.jwt")
      assert {:error, :invalid_jwt} = DPoP.decode(nil)
    end
  end

  describe "validate_proof/2" do
    setup do
      keys = JarTestHelpers.generate_ec_keys()

      claims = %{
        "htm" => "POST",
        "htu" => "https://server.example.com/token",
        "iat" => DateTime.utc_now() |> DateTime.to_unix(),
        "jti" => Ecto.UUID.generate()
      }

      %{keys: keys, claims: claims}
    end

    test "verifies a valid proof signed by the embedded public jwk", %{keys: keys, claims: claims} do
      proof = JarTestHelpers.sign_dpop_proof(keys.private_jwk, claims)

      assert {:ok, %DPoP{claims: verified_claims, header: header, public_jwk: public_jwk}} =
               DPoP.validate_proof(proof, [])

      assert verified_claims == claims
      assert header["alg"] == "ES256"
      assert %JOSE.JWK{} = public_jwk
    end

    test "rejects alg=none unsigned proofs", %{claims: claims} do
      none_header =
        Base.url_encode64(
          Jason.encode!(%{"alg" => "none", "typ" => "dpop+jwt", "jwk" => %{"kty" => "RSA"}}),
          padding: false
        )

      none_payload = Base.url_encode64(Jason.encode!(claims), padding: false)
      proof = none_header <> "." <> none_payload <> "."

      assert {:error, :invalid_signature} = DPoP.validate_proof(proof, [])
    end

    test "rejects proofs with a non-dpop typ header", %{keys: keys, claims: claims} do
      proof = JarTestHelpers.sign_dpop_proof(keys.private_jwk, claims, typ: "JWT")

      assert {:error, :invalid_typ} = DPoP.validate_proof(proof, [])
    end

    test "rejects proofs missing a public jwk", %{keys: keys, claims: claims} do
      proof =
        JarTestHelpers.sign_dpop_proof(keys.private_jwk, claims, extra_header: %{"jwk" => nil})

      assert {:error, :missing_jwk} = DPoP.validate_proof(proof, [])
    end

    test "rejects proofs that embed private-key material", %{keys: keys, claims: claims} do
      proof = JarTestHelpers.sign_dpop_proof(keys.private_jwk, claims, jwk: keys.priv_jwk_map)

      assert {:error, :invalid_jwk} = DPoP.validate_proof(proof, [])
    end

    test "rejects proofs that embed a symmetric jwk", %{claims: claims} do
      symmetric_jwk = JOSE.JWK.generate_key({:oct, 32})
      {_modules, symmetric_map} = JOSE.JWK.to_map(symmetric_jwk)

      signing_key = JarTestHelpers.generate_ec_keys().private_jwk
      proof = JarTestHelpers.sign_dpop_proof(signing_key, claims, jwk: symmetric_map)

      assert {:error, :invalid_jwk} = DPoP.validate_proof(proof, [])
    end
  end

  describe "thumbprint/1" do
    test "returns a stable RFC 7638 thumbprint for the validated proof key" do
      keys = JarTestHelpers.generate_ec_keys()

      proof =
        JarTestHelpers.sign_dpop_proof(keys.private_jwk, %{
          "htm" => "POST",
          "htu" => "https://server.example.com/token",
          "iat" => DateTime.utc_now() |> DateTime.to_unix(),
          "jti" => Ecto.UUID.generate()
        })

      assert {:ok, %DPoP{public_jwk: public_jwk}} = DPoP.validate_proof(proof, [])
      assert {:ok, thumbprint} = DPoP.thumbprint(public_jwk)
      assert {:ok, ^thumbprint} = DPoP.thumbprint(keys.pub_jwk_map)
      assert is_binary(thumbprint)
      refute thumbprint == ""
    end
  end
end
