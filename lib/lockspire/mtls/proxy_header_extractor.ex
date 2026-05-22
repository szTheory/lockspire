defmodule Lockspire.MTLS.ProxyHeaderExtractor do
  @moduledoc """
  Extracts the mTLS client certificate from a configured proxy header.
  Supports URL-encoded PEM formats and Envoy XFCC headers.
  """

  @behaviour Lockspire.MTLS.Extractor

  @impl true
  def extract(conn, opts) do
    header = Keyword.fetch!(opts, :header)
    format = Keyword.fetch!(opts, :format)

    case Plug.Conn.get_req_header(conn, header) do
      [value | _] ->
        parse_header(value, format)

      [] ->
        {:error, :missing_header}
    end
  end

  defp parse_header(value, :url_encoded_pem) do
    value
    |> URI.decode_www_form()
    |> decode_pem()
  end

  defp parse_header(value, :envoy_xfcc) do
    cert_part =
      value
      |> String.split(";")
      |> Enum.find_value(fn part ->
        part = String.trim(part)

        case String.split(part, "=", parts: 2) do
          ["Cert", cert_val] ->
            cert_val
            |> String.trim_leading("\"")
            |> String.trim_trailing("\"")

          _ ->
            nil
        end
      end)

    if cert_part do
      cert_part
      |> URI.decode_www_form()
      |> decode_pem()
    else
      {:error, :invalid_format}
    end
  end

  defp decode_pem(pem_string) do
    case :public_key.pem_decode(pem_string) do
      [{:Certificate, der, :not_encrypted} | _] ->
        {:ok, der}

      _ ->
        {:error, :invalid_format}
    end
  rescue
    _ -> {:error, :invalid_format}
  end
end
