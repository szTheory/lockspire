defmodule Lockspire.Protocol.DPoPTest do
  use ExUnit.Case, async: true

  alias Lockspire.Protocol.DPoP
  alias Lockspire.Protocol.SecurityProfile
  alias Lockspire.JarTestHelpers

  @reference_time ~U[2026-04-28 15:00:00Z]
  @reference_unix DateTime.to_unix(@reference_time)
  @target_uri "https://server.example.com/token"

  defp valid_claims(overrides \\ %{}) do
    Map.merge(
      %{
        "htm" => "POST",
        "htu" => @target_uri,
        "iat" => @reference_unix,
        "jti" => Ecto.UUID.generate()
      },
      overrides
    )
  end

  defp validation_opts(overrides \\ []) do
    Keyword.merge(
      [
        method: "POST",
        target_uri: @target_uri,
        now: @reference_time,
        max_age: 300,
        clock_skew: 30
      ],
      overrides
    )
  end

  describe "decode/1" do
    setup do
      keys = JarTestHelpers.generate_ec_keys()

      proof = JarTestHelpers.sign_dpop_proof(keys.private_jwk, valid_claims())

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

  describe "signing_alg_values_supported" do
    test "returns ES256 and PS256 for FAPI profile" do
      assert ["ES256", "PS256"] =
               DPoP.signing_alg_values_supported(%SecurityProfile.Resolved{
                 effective_profile: :fapi_2_0_security
               })
    end

    test "returns broader list for :none profile" do
      assert ["RS256", "ES256", "PS256", "EdDSA"] =
               DPoP.signing_alg_values_supported(%SecurityProfile.Resolved{
                 effective_profile: :none
               })
    end

    test "signing_alg_values_supported/0 returns the legacy list" do
      assert ["RS256", "ES256", "PS256", "EdDSA"] = DPoP.signing_alg_values_supported()
    end
  end

  describe "validate_proof/2" do
    setup do
      keys = JarTestHelpers.generate_ec_keys()
      claims = valid_claims()

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

    test "rejects RS256 proofs under FAPI-effective behavior", %{claims: claims} do
      keys = JarTestHelpers.generate_keys()
      proof = JarTestHelpers.sign_dpop_proof(keys.private_jwk, claims, alg: "RS256")

      fapi_profile = %SecurityProfile.Resolved{effective_profile: :fapi_2_0_security}

      assert {:error, :unsupported_signing_algorithm} =
               DPoP.validate_proof(proof, validation_opts(security_profile: fapi_profile))
    end

    test "allows RS256 proofs under legacy :none profile", %{claims: claims} do
      keys = JarTestHelpers.generate_keys()
      proof = JarTestHelpers.sign_dpop_proof(keys.private_jwk, claims, alg: "RS256")

      none_profile = %SecurityProfile.Resolved{effective_profile: :none}

      assert {:ok, %DPoP{}} = DPoP.validate_proof(proof, validation_opts(security_profile: none_profile))
    end

    test "rejects alg=none unsigned proofs", %{claims: claims, keys: keys} do
      none_header =
        Base.url_encode64(
          Jason.encode!(%{"alg" => "none", "typ" => "dpop+jwt", "jwk" => keys.pub_jwk_map}),
          padding: false
        )

      none_payload = Base.url_encode64(Jason.encode!(claims), padding: false)
      proof = none_header <> "." <> none_payload <> "."

      assert {:error, :unsupported_signing_algorithm} = DPoP.validate_proof(proof, [])
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

  describe "validate_proof/2 claim checks" do
    setup do
      keys = JarTestHelpers.generate_ec_keys()
      %{keys: keys}
    end

    test "accepts a proof whose htm, htu, iat, and jti match the request context", %{keys: keys} do
      proof = JarTestHelpers.sign_dpop_proof(keys.private_jwk, valid_claims())

      assert {:ok, %DPoP{claims: claims, jkt: jkt}} = DPoP.validate_proof(proof, validation_opts())
      assert claims["htm"] == "POST"
      assert claims["htu"] == @target_uri
      assert claims["iat"] == @reference_unix
      assert is_binary(jkt)
    end

    test "returns a typed reason for later invalid_dpop_proof mapping when htm mismatches", %{
      keys: keys
    } do
      proof = JarTestHelpers.sign_dpop_proof(keys.private_jwk, valid_claims(%{"htm" => "GET"}))

      assert {:error, :invalid_htm} = DPoP.validate_proof(proof, validation_opts())
    end

    test "returns a typed reason for later invalid_dpop_proof mapping when htu mismatches", %{
      keys: keys
    } do
      proof =
        JarTestHelpers.sign_dpop_proof(
          keys.private_jwk,
          valid_claims(%{"htu" => "https://server.example.com/userinfo"})
        )

      assert {:error, :invalid_htu} = DPoP.validate_proof(proof, validation_opts())
    end

    test "returns a typed reason for later invalid_dpop_proof mapping when iat is stale", %{
      keys: keys
    } do
      proof =
        JarTestHelpers.sign_dpop_proof(
          keys.private_jwk,
          valid_claims(%{"iat" => @reference_unix - 301})
        )

      assert {:error, :stale_iat} = DPoP.validate_proof(proof, validation_opts())
    end

    test "returns a typed reason for later invalid_dpop_proof mapping when iat is a string", %{
      keys: keys
    } do
      proof =
        JarTestHelpers.sign_dpop_proof(
          keys.private_jwk,
          valid_claims(%{"iat" => Integer.to_string(@reference_unix)})
        )

      assert {:error, :invalid_iat} = DPoP.validate_proof(proof, validation_opts())
    end

    test "returns a typed reason for later invalid_dpop_proof mapping when iat is too far in the future",
         %{keys: keys} do
      proof =
        JarTestHelpers.sign_dpop_proof(
          keys.private_jwk,
          valid_claims(%{"iat" => @reference_unix + 31})
        )

      assert {:error, :future_iat} = DPoP.validate_proof(proof, validation_opts())
    end

    test "returns a typed reason for later invalid_dpop_proof mapping when jti is missing", %{
      keys: keys
    } do
      proof =
        JarTestHelpers.sign_dpop_proof(
          keys.private_jwk,
          Map.delete(valid_claims(), "jti")
        )

      assert {:error, :missing_jti} = DPoP.validate_proof(proof, validation_opts())
    end

    test "returns a typed reason when the proof signature is invalid", %{keys: keys} do
      other_keys = JarTestHelpers.generate_ec_keys()
      proof = JarTestHelpers.sign_dpop_proof(other_keys.private_jwk, valid_claims(), jwk: keys.pub_jwk_map)

      assert {:error, :invalid_signature} = DPoP.validate_proof(proof, validation_opts())
    end

    test "returns a typed reason when the proof header omits jwk", %{keys: keys} do
      proof = JarTestHelpers.sign_dpop_proof(keys.private_jwk, valid_claims(), extra_header: %{"jwk" => nil})

      assert {:error, :missing_jwk} = DPoP.validate_proof(proof, validation_opts())
    end
  end
end
