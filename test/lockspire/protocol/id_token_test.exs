defmodule Lockspire.Protocol.IdTokenTest do
  use ExUnit.Case, async: true

  alias Lockspire.Host.Claims
  alias Lockspire.JarTestHelpers
  alias Lockspire.Protocol.IdToken

  @issued_at ~U[2026-04-28 15:00:00Z]
  @auth_time ~U[2026-04-28 14:45:00Z]

  test "sign/1 emits integer iat and exp claims" do
    %{jwt: jwt, keys: keys} = sign_id_token()

    claims = decode_claims(jwt, keys)

    assert is_integer(claims["iat"])
    assert claims["iat"] == DateTime.to_unix(@issued_at)
    assert is_integer(claims["exp"])
    assert claims["exp"] == DateTime.add(@issued_at, 3600, :second) |> DateTime.to_unix()
    refute Map.has_key?(claims, "auth_time")
  end

  test "sign/1 includes auth_time only when the caller supplies a DateTime" do
    %{jwt: jwt, keys: keys} = sign_id_token(auth_time: @auth_time)

    claims = decode_claims(jwt, keys)

    assert is_integer(claims["auth_time"])
    assert claims["auth_time"] == DateTime.to_unix(@auth_time)
  end

  test "sign/1 rejects invalid auth_time input before signing" do
    assert {:error, :invalid_auth_time} = IdToken.sign(signing_params(auth_time: "1714315500"))
  end

  defp sign_id_token(overrides \\ []) do
    keys = JarTestHelpers.generate_keys()

    assert {:ok, jwt} = IdToken.sign(signing_params(overrides, keys))

    %{jwt: jwt, keys: keys}
  end

  defp decode_claims(jwt, keys) do
    {_modules, public_jwk_map} = JOSE.JWK.to_public_map(keys.private_jwk)
    public_jwk = JOSE.JWK.from_map(public_jwk_map)

    assert {true, %JOSE.JWT{fields: claims}, _jws} = JOSE.JWT.verify_strict(public_jwk, ["RS256"], jwt)

    claims
  end

  defp signing_params(overrides, keys \\ JarTestHelpers.generate_keys()) do
    {_modules, private_jwk_map} = JOSE.JWK.to_map(keys.private_jwk)

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
      signing_key: %{
        kid: "kid-123",
        alg: "RS256",
        private_jwk_encrypted: Jason.encode!(private_jwk_map)
      }
    }
    |> Map.merge(Enum.into(overrides, %{}))
  end
end
