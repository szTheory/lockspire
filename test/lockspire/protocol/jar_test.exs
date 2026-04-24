defmodule Lockspire.Protocol.JarTest do
  use ExUnit.Case, async: true
  alias Lockspire.Protocol.Jar

  describe "decode/1" do
    test "successfully decodes a valid JWT string" do
      claims = %{"iss" => "client_id", "aud" => "server", "response_type" => "code"}
      jwk = JOSE.JWK.from_oct("secret")
      jws = %{"alg" => "HS256"}
      jwt = JOSE.JWT.sign(jwk, jws, claims) |> JOSE.JWS.compact() |> elem(1)

      assert {:ok, %Jar{claims: decoded_claims, header: header}} = Jar.decode(jwt)
      assert decoded_claims == claims
      assert header["alg"] == "HS256"
    end

    test "returns error for malformed JWT strings" do
      assert {:error, :invalid_jwt} = Jar.decode("not.a.jwt")
      assert {:error, :invalid_jwt} = Jar.decode("header.payload.signature.extra")
    end

    test "returns error for non-JWT strings" do
      assert {:error, :invalid_jwt} = Jar.decode("totally-random-string")
      assert {:error, :invalid_jwt} = Jar.decode("")
    end

    test "returns error for non-binary input" do
      assert {:error, :invalid_jwt} = Jar.decode(nil)
      assert {:error, :invalid_jwt} = Jar.decode(%{})
    end
  end
end
