defmodule Lockspire.MTLS.Plug do
  @moduledoc """
  Plug middleware to extract Mutual TLS (mTLS) client certificates.
  """

  @behaviour Plug

  import Plug.Conn

  @impl Plug
  def init(opts) do
    unless Keyword.has_key?(opts, :extractor) do
      raise ArgumentError, "expected :extractor option to be provided"
    end

    {module, _extractor_opts} = Keyword.fetch!(opts, :extractor)

    unless is_atom(module) do
      raise ArgumentError, "expected :extractor module to be an atom, got: #{inspect(module)}"
    end

    opts
  end

  @impl Plug
  def call(conn, opts) do
    {module, extractor_opts} = Keyword.fetch!(opts, :extractor)

    case module.extract(conn, extractor_opts) do
      {:ok, cert} ->
        put_private(conn, :lockspire_mtls_cert, cert)

      {:error, _reason} ->
        reject_request(conn)
    end
  end

  defp reject_request(conn) do
    body = %{
      "error" => "invalid_request",
      "error_description" => "Valid client certificate required"
    }

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(400, Jason.encode!(body))
    |> halt()
  end
end
