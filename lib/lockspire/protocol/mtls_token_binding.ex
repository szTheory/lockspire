defmodule Lockspire.Protocol.MTLSTokenBinding do
  @moduledoc """
  Shared helpers for MTLS `x5t#S256` sender-constraining metadata.
  """

  @spec thumbprint(String.t()) :: {:ok, String.t()} | {:error, :invalid_client_certificate}
  def thumbprint(cert) when is_binary(cert) do
    cert
    |> String.trim()
    |> case do
      "" ->
        {:error, :invalid_client_certificate}

      trimmed ->
        {:ok, :crypto.hash(:sha256, trimmed) |> Base.url_encode64(padding: false)}
    end
  end

  def thumbprint(_cert), do: {:error, :invalid_client_certificate}

  @spec confirmation_matches?(String.t(), String.t()) :: boolean()
  def confirmation_matches?(expected_thumbprint, cert) when is_binary(expected_thumbprint) do
    case thumbprint(cert) do
      {:ok, actual_thumbprint} -> actual_thumbprint == expected_thumbprint
      {:error, _reason} -> false
    end
  end

  def confirmation_matches?(_expected_thumbprint, _cert), do: false

  @spec maybe_put_confirmation(map() | nil, String.t() | nil) :: map() | nil
  def maybe_put_confirmation(cnf, cert) do
    case thumbprint(cert) do
      {:ok, thumbprint} -> (cnf || %{}) |> Map.put("x5t#S256", thumbprint)
      {:error, _reason} -> cnf
    end
  end
end
