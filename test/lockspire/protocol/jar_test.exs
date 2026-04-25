defmodule Lockspire.Protocol.JarTest do
  use ExUnit.Case, async: true
  alias Lockspire.Protocol.Jar
  alias Lockspire.Domain.Client

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

  describe "verify_signature/2" do
    # Generate a fresh RSA key pair shared across tests in this describe block
    setup do
      private_jwk = JOSE.JWK.generate_key({:rsa, 2048})
      {_, pub_jwk_map} = JOSE.JWK.to_public_map(private_jwk)
      {_, priv_jwk_map} = JOSE.JWK.to_map(private_jwk)
      %{private_jwk: private_jwk, pub_jwk_map: pub_jwk_map, priv_jwk_map: priv_jwk_map}
    end

    defp sign_jwt(private_jwk, claims, alg \\ "RS256", extra_header \\ %{}) do
      header = Map.merge(%{"alg" => alg}, extra_header)
      JOSE.JWT.sign(private_jwk, header, claims) |> JOSE.JWS.compact() |> elem(1)
    end

    defp client_with_single_jwk(pub_jwk_map) do
      %Client{jwks: pub_jwk_map}
    end

    defp client_with_jwks_set(pub_jwk_map) do
      %Client{jwks: %{"keys" => [pub_jwk_map]}}
    end

    test "returns {:ok, %Jar{}} for a validly signed JWT with matching client JWK", %{
      private_jwk: private_jwk,
      pub_jwk_map: pub_jwk_map
    } do
      claims = %{"iss" => "client_id", "aud" => "https://server.example.com", "response_type" => "code"}
      jwt = sign_jwt(private_jwk, claims)
      client = client_with_single_jwk(pub_jwk_map)

      assert {:ok, %Jar{claims: verified_claims, header: header}} =
               Jar.verify_signature(jwt, client)

      assert verified_claims == claims
      assert header["alg"] == "RS256"
    end

    test "returns {:ok, %Jar{}} when client JWKS is a JWK Set with matching key", %{
      private_jwk: private_jwk,
      pub_jwk_map: pub_jwk_map
    } do
      claims = %{"iss" => "client_id", "sub" => "user"}
      jwt = sign_jwt(private_jwk, claims)
      client = client_with_jwks_set(pub_jwk_map)

      assert {:ok, %Jar{claims: verified_claims}} = Jar.verify_signature(jwt, client)
      assert verified_claims == claims
    end

    test "returns {:error, :invalid_signature} when JWT is signed with a different key", %{
      pub_jwk_map: pub_jwk_map
    } do
      # Sign with a different private key
      other_private_jwk = JOSE.JWK.generate_key({:rsa, 2048})
      claims = %{"iss" => "client_id"}
      jwt = sign_jwt(other_private_jwk, claims)

      # But client has the original key — mismatch
      client = client_with_single_jwk(pub_jwk_map)

      assert {:error, :invalid_signature} = Jar.verify_signature(jwt, client)
    end

    test "returns {:error, :invalid_signature} for JWT with alg=none (unsigned)", %{
      pub_jwk_map: pub_jwk_map
    } do
      # Craft an alg=none JWT manually (JOSE will not sign with none)
      none_header = Base.url_encode64(Jason.encode!(%{"alg" => "none", "typ" => "JWT"}), padding: false)
      none_payload = Base.url_encode64(Jason.encode!(%{"iss" => "client_id"}), padding: false)
      none_jwt = none_header <> "." <> none_payload <> "."

      client = client_with_single_jwk(pub_jwk_map)

      assert {:error, :invalid_signature} = Jar.verify_signature(none_jwt, client)
    end

    test "returns {:error, :invalid_client_keys} when client has nil jwks" do
      jwk = JOSE.JWK.generate_key({:rsa, 2048})
      jwt = sign_jwt(jwk, %{"iss" => "client_id"})
      client = %Client{jwks: nil}

      assert {:error, :invalid_client_keys} = Jar.verify_signature(jwt, client)
    end

    test "returns {:error, :invalid_client_keys} when client jwks is not a map" do
      jwk = JOSE.JWK.generate_key({:rsa, 2048})
      jwt = sign_jwt(jwk, %{"iss" => "client_id"})
      client = %Client{jwks: "not_a_map"}

      assert {:error, :invalid_client_keys} = Jar.verify_signature(jwt, client)
    end

    test "returns {:error, :invalid_client_keys} when client jwks is an empty map" do
      jwk = JOSE.JWK.generate_key({:rsa, 2048})
      jwt = sign_jwt(jwk, %{"iss" => "client_id"})
      client = %Client{jwks: %{}}

      assert {:error, :invalid_client_keys} = Jar.verify_signature(jwt, client)
    end

    test "returns {:error, :invalid_client_keys} when client jwks has invalid structure", %{
      private_jwk: private_jwk
    } do
      jwt = sign_jwt(private_jwk, %{"iss" => "client_id"})
      # A map that looks like JSON but is not a valid JWK
      client = %Client{jwks: %{"foo" => "bar", "baz" => 123}}

      assert {:error, :invalid_client_keys} = Jar.verify_signature(jwt, client)
    end

    test "returns {:error, :invalid_signature} for a tampered JWT payload", %{
      private_jwk: private_jwk,
      pub_jwk_map: pub_jwk_map
    } do
      claims = %{"iss" => "client_id", "response_type" => "code"}
      jwt = sign_jwt(private_jwk, claims)

      # Tamper: replace the payload segment with different data
      [header_seg, _payload_seg, sig_seg] = String.split(jwt, ".")
      tampered_payload = Base.url_encode64(Jason.encode!(%{"iss" => "attacker", "response_type" => "code token"}), padding: false)
      tampered_jwt = header_seg <> "." <> tampered_payload <> "." <> sig_seg

      client = client_with_single_jwk(pub_jwk_map)
      assert {:error, :invalid_signature} = Jar.verify_signature(tampered_jwt, client)
    end
  end
end
