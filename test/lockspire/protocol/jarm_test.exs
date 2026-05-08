defmodule Lockspire.Protocol.JarmTest do
  use ExUnit.Case, async: true

  alias Lockspire.JarTestHelpers
  alias Lockspire.Protocol.Jarm
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

  defp decode_claims(jwt, keys, allowed_algs) do
    {_modules, public_jwk_map} = JOSE.JWK.to_public_map(keys.private_jwk)
    public_jwk = JOSE.JWK.from_map(public_jwk_map)

    assert {true, %JOSE.JWT{fields: claims}, _jws} =
             JOSE.JWT.verify_strict(public_jwk, allowed_algs, jwt)

    claims
  end
end
