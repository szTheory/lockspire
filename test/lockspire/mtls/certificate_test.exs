defmodule Lockspire.Mtls.CertificateTest do
  use ExUnit.Case, async: true
  alias Lockspire.Mtls.Certificate

  @der_cert Base.decode64!(
              "MIIDlzCCAn+gAwIBAgIUf9kmQnJK500+Nv0BWu0gM48zcgIwDQYJKoZIhvcNAQELBQAwNjEUMBIGA1UEAwwLZXhhbXBsZS5jb20xETAPBgNVBAoMCFRlc3QgT3JnMQswCQYDVQQGEwJVUzAeFw0yNjA1MjIyMjI0MzhaFw0zNjA1MTkyMjI0MzhaMDYxFDASBgNVBAMMC2V4YW1wbGUuY29tMREwDwYDVQQKDAhUZXN0IE9yZzELMAkGA1UEBhMCVVMwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCnzGcJzq614Cz9AN6axBrGwnx0odNBZJjdQ0VODx+WxDWepf5B9+B0qNEyMBg6eMzRWNSXPs5VaglfJUte35OTXtIh+Rz84PyPw7a8Yg+4EOasw2zqsxN+9uH/VYpV3dcrEJdA9Xx0x0ksLWV0vClTCSWNnJbJ8caftyp6fUL2kBPxv0nX/MVjNJxcm5QAmHXh+dSZ2CgZr6bdzN3JzNdc9JeYVJ9/7sMi7mbjSwLZElBBLIlPtJX7jVVTxLKR5UTnY9kYdxF3VaF42P/YPrcYJQ5LH8iilBxYL/qnct+ZwzvYgKACB8CEzNqIhTbDXzFh6J97OFDUnm+5XWIFMt+fAgMBAAGjgZwwgZkwHQYDVR0OBBYEFPEcpeN1EnkmQ7VbwOCyeUCfhwTmMB8GA1UdIwQYMBaAFPEcpeN1EnkmQ7VbwOCyeUCfhwTmMA8GA1UdEwEB/wQFMAMBAf8wRgYDVR0RBD8wPYILZXhhbXBsZS5jb22GFmh0dHBzOi8vZXhhbXBsZS5jb20vaWSHBMCoAQGBEHRlc3RAZXhhbXBsZS5jb20wDQYJKoZIhvcNAQELBQADggEBAJtQ86lCGy/Y+7SRx/sFWYhC9UaeRJix84ZBnqVEMA37uvZQ4N3AHP+XDhuhSe++ZMqkp9sZHsWQCIZkmqqLUtRUKGiFbe9DcSvbn9PuSN56EbLM0ZCNIt41lEpAYVOogeakehvU0YsSPA4p/MxQ7ZkizWqY9iqnZC93RX43FFLVlpR0YTnq4tiTo4Eln5kLdqhMJdBM/PUUjQAsKK4tUrxRI5u7ycKzI04/M8mo5tbg3UsIiZ4WiFaUENCMcI4RxQca2Kn5mN3gJyaE/NNM2E1fRhZQThVIGZOXO+BIvf1McaOBGbLeRdr2pP3/CORqljaH+kapJnOFVFw+N1daB8g="
            )

  describe "parse/1" do
    test "parses a valid DER-encoded certificate" do
      assert {:ok, %Certificate{} = cert} = Certificate.parse(@der_cert)

      assert cert.subject_dn == "C=US,O=Test Org,CN=example.com"

      assert %{
               dns: ["example.com"],
               uri: ["https://example.com/id"],
               ip: ["192.168.1.1"],
               email: ["test@example.com"]
             } == cert.sans

      assert {:RSAPublicKey, _n, _e} = cert.public_key
    end

    test "returns error for invalid DER" do
      assert {:error, :invalid_certificate} = Certificate.parse(<<"not a cert">>)
    end
  end
end
