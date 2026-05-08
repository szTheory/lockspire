defmodule Lockspire.Protocol.IntrospectionJwtTest do
  use ExUnit.Case, async: true

  alias Lockspire.Domain.Client
  alias Lockspire.Domain.SigningKey
  alias Lockspire.JarTestHelpers
  alias Lockspire.Protocol.IntrospectionJwt
  alias Lockspire.Protocol.SecurityProfile

  defmodule MockKeyStore do
    def fetch_active_signing_key(opts) do
      key = Process.get(:mock_signing_key)

      if key do
        {:ok, %{key | alg: Keyword.get(opts, :alg, key.alg)}}
      else
        {:ok, nil}
      end
    end
  end

  setup do
    keys = JarTestHelpers.generate_keys()
    {_modules, private_jwk_map} = JOSE.JWK.to_map(keys.private_jwk)

    Process.put(
      :mock_signing_key,
      %SigningKey{
        kid: "introspection-kid",
        alg: "RS256",
        private_jwk_encrypted: Jason.encode!(private_jwk_map)
      }
    )

    success = %{
      payload: %{
        active: true,
        client_id: "token-client",
        token_type: "access_token",
        scope: "email profile",
        sub: "account-123",
        aud: ["api.example.com"],
        cnf: %{"jkt" => "thumbprint"}
      },
      caller: %Client{client_id: "rs-client", security_profile: :none},
      security_profile: :none
    }

    %{keys: keys, success: success}
  end

  test "sign/1 returns a compact JWS with RFC 9701 protected headers", %{
    keys: keys,
    success: success
  } do
    assert {:ok, jwt} =
             IntrospectionJwt.sign(%{
               issuer: "https://auth.example.com",
               issued_at: ~U[2026-05-08 10:00:00Z],
               success: success,
               key_store: MockKeyStore
             })

    assert header(jwt)["alg"] == "RS256"
    assert header(jwt)["kid"] == "introspection-kid"
    assert header(jwt)["typ"] == "token-introspection+jwt"

    claims = decode_claims(jwt, keys, ["RS256"])
    assert claims["aud"] == "rs-client"
  end

  test "sign/1 wraps only the RFC 9701 envelope and preserves nested string-key semantics", %{
    keys: keys,
    success: success
  } do
    issued_at = ~U[2026-05-08 10:00:00Z]

    assert {:ok, jwt} =
             IntrospectionJwt.sign(%{
               issuer: "https://auth.example.com",
               issued_at: issued_at,
               success: success,
               key_store: MockKeyStore
             })

    claims = decode_claims(jwt, keys, ["RS256"])

    assert Map.keys(claims) |> Enum.sort() == ["aud", "iat", "iss", "token_introspection"]
    assert claims["iss"] == "https://auth.example.com"
    assert claims["aud"] == "rs-client"
    assert claims["iat"] == DateTime.to_unix(issued_at)

    assert claims["token_introspection"] == %{
             "active" => true,
             "aud" => ["api.example.com"],
             "client_id" => "token-client",
             "cnf" => %{"jkt" => "thumbprint"},
             "scope" => "email profile",
             "sub" => "account-123",
             "token_type" => "access_token"
           }
  end

  test "sign/1 preserves the narrow inactive payload shape", %{keys: keys, success: success} do
    inactive_success = %{success | payload: %{active: false}}

    assert {:ok, jwt} =
             IntrospectionJwt.sign(%{
               issuer: "https://auth.example.com",
               issued_at: ~U[2026-05-08 10:00:00Z],
               success: inactive_success,
               key_store: MockKeyStore
             })

    claims = decode_claims(jwt, keys, ["RS256"])
    assert claims["token_introspection"] == %{"active" => false}
  end

  test "sign/1 returns stable errors when signing posture cannot produce a truthful JWT", %{
    success: success
  } do
    Process.put(:mock_signing_key, nil)

    assert {:error, :invalid_signing_key} =
             IntrospectionJwt.sign(%{
               issuer: "https://auth.example.com",
               issued_at: ~U[2026-05-08 10:00:00Z],
               success: success,
               key_store: MockKeyStore
             })

    Process.put(
      :mock_signing_key,
      %SigningKey{
        kid: "introspection-kid",
        alg: "RS256",
        private_jwk_encrypted: Jason.encode!(elem(JOSE.JWK.to_map(JarTestHelpers.generate_keys().private_jwk), 1))
      }
    )

    assert {:error, :unsupported_signing_algorithm} =
             IntrospectionJwt.sign(%{
               issuer: "https://auth.example.com",
               issued_at: ~U[2026-05-08 10:00:00Z],
               success: %{success | security_profile: %SecurityProfile.Resolved{effective_profile: :fapi_2_0_security}},
               key_store: MockKeyStore
             })
  end

  defp decode_claims(jwt, keys, allowed_algs) do
    {_modules, public_jwk_map} = JOSE.JWK.to_public_map(keys.private_jwk)
    public_jwk = JOSE.JWK.from_map(public_jwk_map)

    assert {true, %JOSE.JWT{fields: claims}, _jws} =
             JOSE.JWT.verify_strict(public_jwk, allowed_algs, jwt)

    claims
  end

  defp header(jwt) do
    [protected_header, _claims, _signature] = String.split(jwt, ".")

    protected_header
    |> Base.url_decode64!(padding: false)
    |> Jason.decode!()
  end
end
