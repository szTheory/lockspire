defmodule Lockspire.Protocol.ClientAuth.MtlsTest do
  use ExUnit.Case, async: true

  alias Lockspire.Protocol.ClientAuth.MTLS
  alias Lockspire.Domain.Client
  alias Lockspire.Mtls.Certificate

  @der_cert Base.decode64!(
              "MIIDlzCCAn+gAwIBAgIUf9kmQnJK500+Nv0BWu0gM48zcgIwDQYJKoZIhvcNAQELBQAwNjEUMBIGA1UEAwwLZXhhbXBsZS5jb20xETAPBgNVBAoMCFRlc3QgT3JnMQswCQYDVQQGEwJVUzAeFw0yNjA1MjIyMjI0MzhaFw0zNjA1MTkyMjI0MzhaMDYxFDASBgNVBAMMC2V4YW1wbGUuY29tMREwDwYDVQQKDAhUZXN0IE9yZzELMAkGA1UEBhMCVVMwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCnzGcJzq614Cz9AN6axBrGwnx0odNBZJjdQ0VODx+WxDWepf5B9+B0qNEyMBg6eMzRWNSXPs5VaglfJUte35OTXtIh+Rz84PyPw7a8Yg+4EOasw2zqsxN+9uH/VYpV3dcrEJdA9Xx0x0ksLWV0vClTCSWNnJbJ8caftyp6fUL2kBPxv0nX/MVjNJxcm5QAmHXh+dSZ2CgZr6bdzN3JzNdc9JeYVJ9/7sMi7mbjSwLZElBBLIlPtJX7jVVTxLKR5UTnY9kYdxF3VaF42P/YPrcYJQ5LH8iilBxYL/qnct+ZwzvYgKACB8CEzNqIhTbDXzFh6J97OFDUnm+5XWIFMt+fAgMBAAGjgZwwgZkwHQYDVR0OBBYEFPEcpeN1EnkmQ7VbwOCyeUCfhwTmMB8GA1UdIwQYMBaAFPEcpeN1EnkmQ7VbwOCyeUCfhwTmMA8GA1UdEwEB/wQFMAMBAf8wRgYDVR0RBD8wPYILZXhhbXBsZS5jb22GFmh0dHBzOi8vZXhhbXBsZS5jb20vaWSHBMCoAQGBEHRlc3RAZXhhbXBsZS5jb20wDQYJKoZIhvcNAQELBQADggEBAJtQ86lCGy/Y+7SRx/sFWYhC9UaeRJix84ZBnqVEMA37uvZQ4N3AHP+XDhuhSe++ZMqkp9sZHsWQCIZkmqqLUtRUKGiFbe9DcSvbn9PuSN56EbLM0ZCNIt41lEpAYVOogeakehvU0YsSPA4p/MxQ7ZkizWqY9iqnZC93RX43FFLVlpR0YTnq4tiTo4Eln5kLdqhMJdBM/PUUjQAsKK4tUrxRI5u7ycKzI04/M8mo5tbg3UsIiZ4WiFaUENCMcI4RxQca2Kn5mN3gJyaE/NNM2E1fRhZQThVIGZOXO+BIvf1McaOBGbLeRdr2pP3/CORqljaH+kapJnOFVFw+N1daB8g="
            )

  setup do
    client = %Client{
      client_id: "client_id",
      tls_client_auth_subject_dn: nil,
      tls_client_auth_san_dns: nil,
      tls_client_auth_san_uri: nil,
      tls_client_auth_san_ip: nil,
      tls_client_auth_san_email: nil,
      jwks: nil,
      jwks_uri: nil
    }

    {:ok, %{client: %Client{} = client}}
  end

  describe "verify/4 with :tls_client_auth" do
    test "returns error when certificate is missing", %{client: %Client{} = client} do
      assert {:error, :missing_certificate} = MTLS.verify(client, nil, :tls_client_auth, [])
    end

    test "returns error when certificate is invalid", %{client: %Client{} = client} do
      assert {:error, :invalid_certificate} = MTLS.verify(client, "invalid der", :tls_client_auth, [])
    end

    test "returns :ok when subject_dn matches exactly", %{client: %Client{} = client} do
      client = %Client{client | tls_client_auth_subject_dn: "C=US,O=Test Org,CN=example.com"}
      assert :ok = MTLS.verify(client, @der_cert, :tls_client_auth, [])
    end

    test "returns error when subject_dn does not match", %{client: %Client{} = client} do
      client = %Client{client | tls_client_auth_subject_dn: "C=US,O=Test Org,CN=wrong.com"}
      assert {:error, :certificate_attribute_mismatch} = MTLS.verify(client, @der_cert, :tls_client_auth, [])
    end

    test "returns :ok when san_dns matches exactly", %{client: %Client{} = client} do
      client = %Client{client | tls_client_auth_san_dns: "example.com"}
      assert :ok = MTLS.verify(client, @der_cert, :tls_client_auth, [])
    end

    test "returns error when san_dns does not match", %{client: %Client{} = client} do
      client = %Client{client | tls_client_auth_san_dns: "wrong.com"}
      assert {:error, :certificate_attribute_mismatch} = MTLS.verify(client, @der_cert, :tls_client_auth, [])
    end

    test "returns :ok when san_uri matches exactly", %{client: %Client{} = client} do
      client = %Client{client | tls_client_auth_san_uri: "https://example.com/id"}
      assert :ok = MTLS.verify(client, @der_cert, :tls_client_auth, [])
    end

    test "returns error when san_uri does not match", %{client: %Client{} = client} do
      client = %Client{client | tls_client_auth_san_uri: "https://wrong.com/id"}
      assert {:error, :certificate_attribute_mismatch} = MTLS.verify(client, @der_cert, :tls_client_auth, [])
    end

    test "returns :ok when san_ip matches exactly", %{client: %Client{} = client} do
      client = %Client{client | tls_client_auth_san_ip: "192.168.1.1"}
      assert :ok = MTLS.verify(client, @der_cert, :tls_client_auth, [])
    end

    test "returns error when san_ip does not match", %{client: %Client{} = client} do
      client = %Client{client | tls_client_auth_san_ip: "10.0.0.1"}
      assert {:error, :certificate_attribute_mismatch} = MTLS.verify(client, @der_cert, :tls_client_auth, [])
    end

    test "returns :ok when san_email matches exactly", %{client: %Client{} = client} do
      client = %Client{client | tls_client_auth_san_email: "test@example.com"}
      assert :ok = MTLS.verify(client, @der_cert, :tls_client_auth, [])
    end

    test "returns error when san_email does not match", %{client: %Client{} = client} do
      client = %Client{client | tls_client_auth_san_email: "wrong@example.com"}
      assert {:error, :certificate_attribute_mismatch} = MTLS.verify(client, @der_cert, :tls_client_auth, [])
    end

    test "returns error if client has no attributes configured for pki", %{client: %Client{} = client} do
      assert {:error, :certificate_attribute_mismatch} = MTLS.verify(client, @der_cert, :tls_client_auth, [])
    end
  end

  describe "verify/4 with :self_signed_tls_client_auth" do
    setup do
      # Extract public key from @der_cert to JWK mapping for exact match setup
      {:ok, parsed} = Certificate.parse(@der_cert)
      jwk = JOSE.JWK.from_key(parsed.public_key)
      {_modules, jwk_map} = JOSE.JWK.to_map(jwk)

      %{jwk: jwk_map, jwks: %{"keys" => [jwk_map]}}
    end

    test "returns error when certificate is missing", %{client: %Client{} = client} do
      assert {:error, :missing_certificate} = MTLS.verify(client, nil, :self_signed_tls_client_auth, [])
    end

    test "returns :ok when cert public key matches registered JWKS", %{client: %Client{} = client, jwks: jwks} do
      client = %Client{client | jwks: jwks}
      assert :ok = MTLS.verify(client, @der_cert, :self_signed_tls_client_auth, [])
    end

    test "returns error when cert public key does not match JWKS", %{client: %Client{} = client} do
      other_jwk = JOSE.JWK.generate_key({:rsa, 2048})
      {_modules, other_jwk_map} = JOSE.JWK.to_map(other_jwk)
      client = %Client{client | jwks: %{"keys" => [other_jwk_map]}}

      assert {:error, :no_matching_key} = MTLS.verify(client, @der_cert, :self_signed_tls_client_auth, [])
    end

    test "returns error if client has no keys registered", %{client: %Client{} = client} do
      assert {:error, :client_jwks_missing} = MTLS.verify(client, @der_cert, :self_signed_tls_client_auth, [])
    end

    test "retrieves jwks_uri on demand and matches", %{client: %Client{} = client, jwks: jwks} do
      client = %Client{client | jwks_uri: "https://example.com/jwks"}

      fetcher_opts = [
        jwks_fetcher: __MODULE__.MockFetcher,
        jwks_fetcher_opts: [test_jwks: jwks]
      ]

      assert :ok = MTLS.verify(client, @der_cert, :self_signed_tls_client_auth, fetcher_opts)
    end
  end

  defmodule MockFetcher do
    def get_keys("https://example.com/jwks", opts) do
      jwks = Keyword.get(opts, :test_jwks)
      {:ok, JOSE.JWK.from_map(jwks)}
    end

    def get_keys(_, _opts), do: {:error, :not_found}
  end
end
