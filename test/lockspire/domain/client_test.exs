defmodule Lockspire.Domain.ClientTest do
  use ExUnit.Case, async: true
  alias Lockspire.Domain.Client

  test "Client struct supports authorization_signed_response_alg" do
    client = %Client{authorization_signed_response_alg: :RS256}
    assert client.authorization_signed_response_alg == :RS256
  end

  test "Client struct supports RFC 8705 MTLS PKI attributes" do
    client = %Client{
      tls_client_auth_subject_dn: "CN=client.example.com",
      tls_client_auth_san_dns: "client.example.com",
      tls_client_auth_san_uri: "https://client.example.com",
      tls_client_auth_san_ip: "192.168.1.1",
      tls_client_auth_san_email: "admin@example.com"
    }

    assert client.tls_client_auth_subject_dn == "CN=client.example.com"
    assert client.tls_client_auth_san_dns == "client.example.com"
    assert client.tls_client_auth_san_uri == "https://client.example.com"
    assert client.tls_client_auth_san_ip == "192.168.1.1"
    assert client.tls_client_auth_san_email == "admin@example.com"
  end
end
