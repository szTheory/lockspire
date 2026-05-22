defmodule Lockspire.MTLS.CowboyDirectExtractorTest do
  use ExUnit.Case, async: true
  import Plug.Test


  alias Lockspire.MTLS.CowboyDirectExtractor

  describe "extract/2" do
    test "returns the raw DER certificate when present in peer data" do
      der_cert = "fake_der_cert"
      
      conn =
        conn(:get, "/")
        |> put_peer_data(%{ssl_cert: der_cert})
        
      assert {:ok, ^der_cert} = CowboyDirectExtractor.extract(conn, [])
    end

    test "returns error when ssl_cert is nil" do
      conn =
        conn(:get, "/")
        |> put_peer_data(%{ssl_cert: nil})
        
      assert {:error, :no_cert} = CowboyDirectExtractor.extract(conn, [])
    end

    test "returns error when ssl_cert is missing" do
      conn = conn(:get, "/")
      assert {:error, :no_cert} = CowboyDirectExtractor.extract(conn, [])
    end
  end
end
