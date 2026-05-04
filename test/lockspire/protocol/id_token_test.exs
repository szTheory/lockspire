defmodule Lockspire.Protocol.IdTokenTest do
  use ExUnit.Case, async: true

  alias Lockspire.Host.Claims
  alias Lockspire.JarTestHelpers
  alias Lockspire.Protocol.IdToken

  @issued_at ~U[2026-04-28 15:00:00Z]
  @auth_time ~U[2026-04-28 14:45:00Z]

  test "sign/1 emits integer iat and exp claims" do
    %{jwt: jwt, keys: keys} = sign_id_token()

    claims = decode_claims(jwt, keys, ["RS256"])

    assert is_integer(claims["iat"])
    assert claims["iat"] == DateTime.to_unix(@issued_at)
    assert is_integer(claims["exp"])
    assert claims["exp"] == DateTime.add(@issued_at, 3600, :second) |> DateTime.to_unix()
    refute Map.has_key?(claims, "auth_time")
  end

  test "sign/1 includes auth_time only when the caller supplies a DateTime" do
    %{jwt: jwt, keys: keys} = sign_id_token(auth_time: @auth_time)

    claims = decode_claims(jwt, keys, ["RS256"])

    assert is_integer(claims["auth_time"])
    assert claims["auth_time"] == DateTime.to_unix(@auth_time)
  end

  test "sign/1 rejects invalid auth_time input before signing" do
    assert {:error, :invalid_auth_time} = IdToken.sign(signing_params(auth_time: "1714315500"))
  end

  test "sign/1 includes sid claim when caller supplies a sid string" do
    %{jwt: jwt, keys: keys} = sign_id_token(sid: "test-session-id-123")

    claims = decode_claims(jwt, keys, ["RS256"])

    assert claims["sid"] == "test-session-id-123"
  end

  test "sign/1 omits sid claim when sid is nil" do
    %{jwt: jwt, keys: keys} = sign_id_token()

    claims = decode_claims(jwt, keys, ["RS256"])

    refute Map.has_key?(claims, "sid")
  end

  test "sign/1 rejects non-compliant signing algorithms under FAPI-effective behavior" do
    rsa_keys = JarTestHelpers.generate_keys()

    assert {:error, :unsupported_signing_algorithm} =
             IdToken.sign(
               signing_params(
                 [security_profile: :fapi_2_0_security],
                 rsa_keys
               )
             )
  end

  test "sign/1 accepts ES256 and PS256 under FAPI-effective behavior" do
    ec_keys = JarTestHelpers.generate_ec_keys()
    ps256_keys = JarTestHelpers.generate_keys()

    assert {:ok, es256_jwt} =
             IdToken.sign(
               signing_params(
                 [
                   security_profile: :fapi_2_0_security,
                   signing_key: signing_key_params(ec_keys, "ES256")
                 ],
                 ec_keys
               )
             )

    assert decode_claims(es256_jwt, ec_keys, ["ES256"])["iss"] == "https://example.test/lockspire"

    assert {:ok, ps256_jwt} =
             IdToken.sign(
               signing_params(
                 [
                   security_profile: :fapi_2_0_security,
                   signing_key: signing_key_params(ps256_keys, "PS256")
                 ],
                 ps256_keys
               )
             )

    assert decode_claims(ps256_jwt, ps256_keys, ["PS256"])["iss"] ==
             "https://example.test/lockspire"
  end

  defp sign_id_token(overrides \\ []) do
    keys = JarTestHelpers.generate_keys()

    assert {:ok, jwt} = IdToken.sign(signing_params(overrides, keys))

    %{jwt: jwt, keys: keys}
  end

  defp decode_claims(jwt, keys, allowed_algs) do
    {_modules, public_jwk_map} = JOSE.JWK.to_public_map(keys.private_jwk)
    public_jwk = JOSE.JWK.from_map(public_jwk_map)

    assert {true, %JOSE.JWT{fields: claims}, _jws} =
             JOSE.JWT.verify_strict(public_jwk, allowed_algs, jwt)

    claims
  end

  defp signing_params(overrides, keys \\ JarTestHelpers.generate_keys()) do
    %{
      client_id: "client-123",
      issuer: "https://example.test/lockspire",
      host_claims: %Claims{
        subject: "subject-123",
        id_token: %{"email" => "subject@example.test"},
        userinfo: %{}
      },
      interaction_nonce: "nonce-123",
      access_token: "access-token-123",
      issued_at: @issued_at,
      signing_key: signing_key_params(keys, "RS256")
    }
    |> Map.merge(Enum.into(overrides, %{}))
  end

  defp signing_key_params(keys, alg) do
    {_modules, private_jwk_map} = JOSE.JWK.to_map(keys.private_jwk)

    %{
      kid: "kid-123",
      alg: alg,
      private_jwk_encrypted: Jason.encode!(private_jwk_map)
    }
  end
end
