defmodule Lockspire.MTLS.CowboyDirectExtractor do
  @moduledoc """
  Extracts the raw DER-encoded mTLS client certificate natively unwrapped by Cowboy.
  """

  @behaviour Lockspire.MTLS.Extractor

  @impl true
  def extract(conn, _opts) do
    case Plug.Conn.get_peer_data(conn) do
      %{ssl_cert: cert} when is_binary(cert) -> {:ok, cert}
      _ -> {:error, :no_cert}
    end
  end
end
