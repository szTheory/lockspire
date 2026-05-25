defmodule Lockspire.MTLS.Extractor do
  @moduledoc """
  Behaviour for extracting Mutual TLS (mTLS) client certificates.
  """

  @doc """
  Extracts the raw DER-encoded certificate from the connection.
  """
  @callback extract(Plug.Conn.t(), keyword()) :: {:ok, binary()} | {:error, atom()}
end
