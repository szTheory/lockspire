defmodule Lockspire.Protocol.JarmTest do
  use ExUnit.Case, async: true

  alias Lockspire.Protocol.Jarm
  alias Lockspire.JarTestHelpers

  test "sign/2 generates valid JWS with code, state, and iss" do
    keys = JarTestHelpers.generate_keys()
    signing_key = signing_key_params(keys, "RS256")
    
    params = %{"code" => "123", "state" => "xyz"}
    context = %{
      client_id: "client_id",
      issuer: "https://example.test/lockspire",
      signing_key: signing_key
    }

    assert {:ok, jwt} = Jarm.sign(params, context)
    
    claims = decode_claims(jwt, keys, ["RS256"])
    assert claims["code"] == "123"
    assert claims["state"] == "xyz"
    assert claims["iss"] == "https://example.test/lockspire"
    assert claims["aud"] == "client_id"
    assert is_integer(claims["exp"])
  end

  defp signing_key_params(keys, alg) do
    {_modules, private_jwk_map} = JOSE.JWK.to_map(keys.private_jwk)

    %{
      kid: "kid-123",
      alg: alg,
      private_jwk_encrypted: Jason.encode!(private_jwk_map)
    }
  end

  defp decode_claims(jwt, keys, allowed_algs) do
    {_modules, public_jwk_map} = JOSE.JWK.to_public_map(keys.private_jwk)
    public_jwk = JOSE.JWK.from_map(public_jwk_map)

    assert {true, %JOSE.JWT{fields: claims}, _jws} =
             JOSE.JWT.verify_strict(public_jwk, allowed_algs, jwt)

    claims
  end
end
