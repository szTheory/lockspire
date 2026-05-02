defmodule Lockspire.Protocol.SecurityPolicyTest do
  use ExUnit.Case, async: true

  alias Lockspire.Domain.SigningKey
  alias Lockspire.Security.Policy

  test "boot-time helpers validate required values and issuer alignment" do
    assert_raise ArgumentError,
                 "missing required config :repo for :lockspire. Set it in config/runtime.exs or config/*.exs.",
                 fn ->
                   Policy.fetch_required_config!(:repo, nil)
                 end

    assert_raise ArgumentError,
                 "invalid :issuer for :lockspire. Expected an absolute URL with scheme and host.",
                 fn ->
                   Policy.validate_issuer_and_mount_path!("oauth", "/oauth")
                 end

    assert_raise ArgumentError,
                 "invalid :issuer for :lockspire. Query parameters are not allowed.",
                 fn ->
                   Policy.validate_issuer_and_mount_path!(
                     "https://example.test/oauth?foo=bar",
                     "/oauth"
                   )
                 end

    assert_raise ArgumentError,
                 "invalid :issuer for :lockspire. Issuer path \"/other\" must match mount_path \"/oauth\".",
                 fn ->
                   Policy.validate_issuer_and_mount_path!("https://example.test/other", "/oauth")
                 end

    assert Policy.validate_issuer_and_mount_path!("https://example.test/oauth", "/oauth") ==
             "https://example.test/oauth"
  end

  test "reject helpers return stable reason atoms for unsupported runtime posture" do
    assert {:error, :unsupported_response_type} =
             Policy.ensure_supported_response_type("token")

    assert :ok = Policy.ensure_supported_response_type("code")

    assert {:error, :unsupported_token_endpoint_auth_method} =
             Policy.ensure_supported_token_endpoint_auth_method(:private_key_jwt)

    assert :ok = Policy.ensure_supported_token_endpoint_auth_method(:client_secret_basic)

    assert {:error, :invalid_signing_alg} = Policy.ensure_signing_alg("none")
    assert :ok = Policy.ensure_signing_alg(:ES256)
    assert :ok = Policy.ensure_signing_alg("RS256")
    assert :ok = Policy.ensure_signing_alg(:RS256)
  end

  describe "validate_key_compliance/2" do
    test "accepts ES256 and PS256 keys with FAPI-compliant strength" do
      assert :ok = Policy.validate_key_compliance(ec_signing_key(), :fapi_2_0_security)
      assert :ok = Policy.validate_key_compliance(rsa_signing_key(), :fapi_2_0_security)
    end

    test "rejects non-FAPI algorithms with typed errors" do
      assert {:error, {:non_compliant_algorithm, "RS256"}} =
               Policy.validate_key_compliance(
                 %SigningKey{rsa_signing_key() | alg: "RS256"},
                 :fapi_2_0_security
               )

      assert {:error, {:non_compliant_algorithm, "EdDSA"}} =
               Policy.validate_key_compliance(
                 %SigningKey{okp_signing_key() | alg: "EdDSA"},
                 :fapi_2_0_security
               )
    end

    test "rejects weak RSA and unsupported curves with typed errors" do
      assert {:error, :insufficient_rsa_key_size} =
               Policy.validate_key_compliance(weak_rsa_signing_key(), :fapi_2_0_security)

      assert {:error, {:unsupported_curve, "P-224"}} =
               Policy.validate_key_compliance(
                 %SigningKey{ec_signing_key() | public_jwk: %{"crv" => "P-224"}},
                 :fapi_2_0_security
               )
    end
  end

  defp ec_signing_key do
    %SigningKey{
      kty: :EC,
      alg: "ES256",
      public_jwk: %{"crv" => "P-256"}
    }
  end

  defp rsa_signing_key do
    modulus = :binary.copy(<<1>>, 256)

    %SigningKey{
      kty: :RSA,
      alg: "PS256",
      public_jwk: %{"n" => Base.url_encode64(modulus, padding: false)}
    }
  end

  defp weak_rsa_signing_key do
    modulus = :binary.copy(<<1>>, 128)

    %SigningKey{
      kty: :RSA,
      alg: "PS256",
      public_jwk: %{"n" => Base.url_encode64(modulus, padding: false)}
    }
  end

  defp okp_signing_key do
    %SigningKey{
      kty: :OKP,
      alg: "EdDSA",
      public_jwk: %{"crv" => "Ed25519"}
    }
  end
end
