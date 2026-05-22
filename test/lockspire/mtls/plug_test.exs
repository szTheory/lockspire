defmodule Lockspire.MTLS.PlugTest do
  use ExUnit.Case, async: true

  import Phoenix.ConnTest, only: [build_conn: 0]

  alias Lockspire.MTLS.Plug

  defmodule MockExtractor do
    @behaviour Lockspire.MTLS.Extractor

    @impl true
    def extract(_conn, opts) do
      case opts[:scenario] do
        :success -> {:ok, "mock_der_cert"}
        :error -> {:error, :invalid_cert}
      end
    end
  end

  setup do
    %{conn: build_conn()}
  end

  test "success: extracts cert, puts in private, and continues", %{conn: conn} do
    opts = Plug.init(extractor: {MockExtractor, scenario: :success})
    conn = Plug.call(conn, opts)

    refute conn.halted
    assert conn.private[:lockspire_mtls_cert] == "mock_der_cert"
  end

  test "error: halts pipeline and returns 400 when extraction fails", %{conn: conn} do
    opts = Plug.init(extractor: {MockExtractor, scenario: :error})
    conn = Plug.call(conn, opts)

    assert conn.halted
    assert conn.status == 400

    body = Jason.decode!(conn.resp_body)
    assert body["error"] == "invalid_request"
    assert body["error_description"] == "Valid client certificate required"
  end
end
