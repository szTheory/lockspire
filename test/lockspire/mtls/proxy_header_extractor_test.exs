defmodule Lockspire.MTLS.ProxyHeaderExtractorTest do
  use ExUnit.Case, async: true
  import Plug.Test
  import Plug.Conn

  alias Lockspire.MTLS.ProxyHeaderExtractor

  setup do
    der = "dummy_der_content"
    pem = :public_key.pem_encode([{:Certificate, der, :not_encrypted}])
    {:ok, der: der, pem: pem}
  end

  describe "extract/2 with url_encoded_pem" do
    test "decodes and extracts DER", %{der: der, pem: pem} do
      encoded_pem = URI.encode_www_form(pem)

      conn =
        conn(:get, "/")
        |> put_req_header("ssl-client-cert", encoded_pem)

      opts = [header: "ssl-client-cert", format: :url_encoded_pem]
      assert {:ok, ^der} = ProxyHeaderExtractor.extract(conn, opts)
    end
  end

  describe "extract/2 with envoy_xfcc" do
    test "decodes and extracts DER from Cert parameter", %{der: der, pem: pem} do
      encoded_pem = URI.encode_www_form(pem)

      xfcc =
        "By=http://frontend.lyft.com;Hash=468ed33c74;Cert=\"#{encoded_pem}\";Subject=\"/C=US/ST=CA/L=San Francisco/O=Lyft/OU=Test Client/CN=test.lyft.com\""

      conn =
        conn(:get, "/")
        |> put_req_header("x-forwarded-client-cert", xfcc)

      opts = [header: "x-forwarded-client-cert", format: :envoy_xfcc]
      assert {:ok, ^der} = ProxyHeaderExtractor.extract(conn, opts)
    end
  end

  describe "errors" do
    test "returns :missing_header when absent" do
      conn = conn(:get, "/")
      opts = [header: "x-forwarded-client-cert", format: :url_encoded_pem]
      assert {:error, :missing_header} = ProxyHeaderExtractor.extract(conn, opts)
    end

    test "returns :invalid_format when PEM decode fails" do
      conn =
        conn(:get, "/")
        |> put_req_header("ssl-client-cert", URI.encode_www_form("not_a_pem"))

      opts = [header: "ssl-client-cert", format: :url_encoded_pem]
      assert {:error, :invalid_format} = ProxyHeaderExtractor.extract(conn, opts)
    end

    test "returns :invalid_format when Cert parameter is missing in envoy_xfcc" do
      xfcc = "By=http://frontend.lyft.com;Hash=468ed33c74"

      conn =
        conn(:get, "/")
        |> put_req_header("x-forwarded-client-cert", xfcc)

      opts = [header: "x-forwarded-client-cert", format: :envoy_xfcc]
      assert {:error, :invalid_format} = ProxyHeaderExtractor.extract(conn, opts)
    end
  end
end
