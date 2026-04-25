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

    test "returns {:error, :invalid_typ} for JWT with typ=JWT-bearer (cross-JWT confusion)", %{
      private_jwk: private_jwk,
      pub_jwk_map: pub_jwk_map
    } do
      claims = %{"iss" => "client_id", "aud" => "https://server.example.com"}
      jwt = sign_jwt(private_jwk, claims, "RS256", %{"typ" => "JWT-bearer"})
      client = client_with_single_jwk(pub_jwk_map)

      assert {:error, :invalid_typ} = Jar.verify_signature(jwt, client)
    end

    test "returns {:ok, %Jar{}} for JWT with typ=oauth-authz-req+jwt (canonical RFC 9101 typ)", %{
      private_jwk: private_jwk,
      pub_jwk_map: pub_jwk_map
    } do
      claims = %{"iss" => "client_id", "aud" => "https://server.example.com"}
      jwt = sign_jwt(private_jwk, claims, "RS256", %{"typ" => "oauth-authz-req+jwt"})
      client = client_with_single_jwk(pub_jwk_map)

      assert {:ok, %Jar{}} = Jar.verify_signature(jwt, client)
    end

    test "returns {:ok, %Jar{}} for JWT with typ=jwt (lowercase legacy)", %{
      private_jwk: private_jwk,
      pub_jwk_map: pub_jwk_map
    } do
      claims = %{"iss" => "client_id"}
      jwt = sign_jwt(private_jwk, claims, "RS256", %{"typ" => "jwt"})
      client = client_with_single_jwk(pub_jwk_map)

      assert {:ok, %Jar{}} = Jar.verify_signature(jwt, client)
    end

    test "returns {:ok, %Jar{}} for JWT with no typ header (permissive default per RFC 9101 SHOULD)", %{
      private_jwk: private_jwk,
      pub_jwk_map: pub_jwk_map
    } do
      claims = %{"iss" => "client_id"}
      jwt = sign_jwt(private_jwk, claims)
      client = client_with_single_jwk(pub_jwk_map)

      assert {:ok, %Jar{}} = Jar.verify_signature(jwt, client)
    end
  end

  describe "validate_claims/2" do
    # Use a fixed reference time so tests are deterministic regardless of clock.
    @reference_time ~U[2026-04-25 12:00:00Z]
    @reference_unix DateTime.to_unix(@reference_time)
    @client_id "client-123"
    @audience "https://server.example.com"

    defp valid_claims do
      %{
        "iss" => @client_id,
        "aud" => @audience,
        "exp" => @reference_unix + 300,
        "nbf" => @reference_unix - 10,
        "iat" => @reference_unix - 20,
        "response_type" => "code"
      }
    end

    defp validate_opts(extra \\ []) do
      Keyword.merge(
        [
          expected_client_id: @client_id,
          expected_audience: @audience,
          now: @reference_time
        ],
        extra
      )
    end

    defp jar_with(claims), do: %Jar{claims: claims, header: %{"alg" => "RS256"}}

    test "returns :ok when all claims are valid (string audience)" do
      assert :ok = Jar.validate_claims(jar_with(valid_claims()), validate_opts())
    end

    test "returns :ok when audience is a list containing the expected value" do
      claims = Map.put(valid_claims(), "aud", ["other", @audience])
      assert :ok = Jar.validate_claims(jar_with(claims), validate_opts())
    end

    test "returns :ok when nbf and iat are absent (they are optional)" do
      claims =
        valid_claims()
        |> Map.delete("nbf")
        |> Map.delete("iat")

      assert :ok = Jar.validate_claims(jar_with(claims), validate_opts())
    end

    # iss
    test "returns {:error, :missing_issuer} when iss is missing" do
      claims = Map.delete(valid_claims(), "iss")
      assert {:error, :missing_issuer} = Jar.validate_claims(jar_with(claims), validate_opts())
    end

    test "returns {:error, :invalid_issuer} when iss does not match expected_client_id" do
      claims = Map.put(valid_claims(), "iss", "attacker-client")
      assert {:error, :invalid_issuer} = Jar.validate_claims(jar_with(claims), validate_opts())
    end

    test "returns {:error, :invalid_issuer} when iss is not a string" do
      claims = Map.put(valid_claims(), "iss", 12_345)
      assert {:error, :invalid_issuer} = Jar.validate_claims(jar_with(claims), validate_opts())
    end

    # aud
    test "returns {:error, :missing_audience} when aud is missing" do
      claims = Map.delete(valid_claims(), "aud")
      assert {:error, :missing_audience} = Jar.validate_claims(jar_with(claims), validate_opts())
    end

    test "returns {:error, :invalid_audience} when aud does not match expected_audience" do
      claims = Map.put(valid_claims(), "aud", "https://other.example.com")
      assert {:error, :invalid_audience} = Jar.validate_claims(jar_with(claims), validate_opts())
    end

    test "returns {:error, :invalid_audience} when aud list does not contain expected_audience" do
      claims = Map.put(valid_claims(), "aud", ["a", "b"])
      assert {:error, :invalid_audience} = Jar.validate_claims(jar_with(claims), validate_opts())
    end

    test "returns {:error, :invalid_audience} when aud is an unsupported type" do
      claims = Map.put(valid_claims(), "aud", 42)
      assert {:error, :invalid_audience} = Jar.validate_claims(jar_with(claims), validate_opts())
    end

    # exp
    test "returns {:error, :missing_expiration} when exp is missing" do
      claims = Map.delete(valid_claims(), "exp")
      assert {:error, :missing_expiration} = Jar.validate_claims(jar_with(claims), validate_opts())
    end

    test "returns {:error, :expired_token} when exp is in the past" do
      claims = Map.put(valid_claims(), "exp", @reference_unix - 1)
      assert {:error, :expired_token} = Jar.validate_claims(jar_with(claims), validate_opts())
    end

    test "returns {:error, :expired_token} when exp equals now (boundary, strictly future required)" do
      claims = Map.put(valid_claims(), "exp", @reference_unix)
      assert {:error, :expired_token} = Jar.validate_claims(jar_with(claims), validate_opts())
    end

    test "returns {:error, :invalid_expiration} when exp is not an integer" do
      claims = Map.put(valid_claims(), "exp", "tomorrow")

      assert {:error, :invalid_expiration} =
               Jar.validate_claims(jar_with(claims), validate_opts())
    end

    # nbf
    test "returns {:error, :invalid_not_before} when nbf is in the future" do
      claims = Map.put(valid_claims(), "nbf", @reference_unix + 60)

      assert {:error, :invalid_not_before} =
               Jar.validate_claims(jar_with(claims), validate_opts())
    end

    test "returns :ok when nbf equals now (boundary)" do
      claims = Map.put(valid_claims(), "nbf", @reference_unix)
      assert :ok = Jar.validate_claims(jar_with(claims), validate_opts())
    end

    test "returns {:error, :invalid_not_before} when nbf is not an integer" do
      claims = Map.put(valid_claims(), "nbf", "soon")

      assert {:error, :invalid_not_before} =
               Jar.validate_claims(jar_with(claims), validate_opts())
    end

    # iat
    test "returns {:error, :invalid_issued_at} when iat is in the future" do
      claims = Map.put(valid_claims(), "iat", @reference_unix + 60)

      assert {:error, :invalid_issued_at} =
               Jar.validate_claims(jar_with(claims), validate_opts())
    end

    test "returns :ok when iat equals now (boundary)" do
      claims = Map.put(valid_claims(), "iat", @reference_unix)
      assert :ok = Jar.validate_claims(jar_with(claims), validate_opts())
    end

    test "returns {:error, :invalid_issued_at} when iat is not an integer" do
      claims = Map.put(valid_claims(), "iat", "now")

      assert {:error, :invalid_issued_at} =
               Jar.validate_claims(jar_with(claims), validate_opts())
    end

    # leeway
    test "leeway allows exp slightly in the past (clock skew tolerance)" do
      claims = Map.put(valid_claims(), "exp", @reference_unix - 3)
      assert :ok = Jar.validate_claims(jar_with(claims), validate_opts(leeway: 5))
    end

    test "leeway allows nbf slightly in the future (clock skew tolerance)" do
      claims = Map.put(valid_claims(), "nbf", @reference_unix + 3)
      assert :ok = Jar.validate_claims(jar_with(claims), validate_opts(leeway: 5))
    end

    # opts validation
    test "returns {:error, :invalid_claims_options} when expected_client_id is missing" do
      opts = Keyword.delete(validate_opts(), :expected_client_id)

      assert {:error, :invalid_claims_options} =
               Jar.validate_claims(jar_with(valid_claims()), opts)
    end

    test "returns {:error, :invalid_claims_options} when expected_audience is missing" do
      opts = Keyword.delete(validate_opts(), :expected_audience)

      assert {:error, :invalid_claims_options} =
               Jar.validate_claims(jar_with(valid_claims()), opts)
    end

    test "returns {:error, :invalid_claims_options} when expected_client_id is empty" do
      opts = Keyword.put(validate_opts(), :expected_client_id, "")

      assert {:error, :invalid_claims_options} =
               Jar.validate_claims(jar_with(valid_claims()), opts)
    end

    test "returns {:error, :invalid_claims_options} when expected_audience is not a binary" do
      opts = Keyword.put(validate_opts(), :expected_audience, 123)

      assert {:error, :invalid_claims_options} =
               Jar.validate_claims(jar_with(valid_claims()), opts)
    end

    test "returns {:error, :invalid_claims_options} when leeway is negative" do
      opts = Keyword.put(validate_opts(), :leeway, -5)

      assert {:error, :invalid_claims_options} =
               Jar.validate_claims(jar_with(valid_claims()), opts)
    end

    test "uses DateTime.utc_now/0 when :now is not provided" do
      # exp far in the future so this is safe regardless of when the test runs.
      far_future = DateTime.utc_now() |> DateTime.add(3600, :second) |> DateTime.to_unix()
      claims = Map.put(valid_claims(), "exp", far_future)

      opts = [
        expected_client_id: @client_id,
        expected_audience: @audience
      ]

      assert :ok = Jar.validate_claims(jar_with(claims), opts)
    end
  end
end
