defmodule Lockspire.Protocol.PrivateJwk do
  @moduledoc false

  @spec decode(term()) :: {:ok, map()} | {:error, :invalid_signing_key}
  def decode(binary) when is_binary(binary) do
    case Jason.decode(binary) do
      {:ok, %{} = jwk} -> {:ok, jwk}
      _other -> decode_safe_term(binary)
    end
  rescue
    _exception -> {:error, :invalid_signing_key}
  catch
    _kind, _reason -> {:error, :invalid_signing_key}
  end

  def decode(_value), do: {:error, :invalid_signing_key}

  defp decode_safe_term(binary) do
    case Plug.Crypto.non_executable_binary_to_term(binary, [:safe]) do
      %{} = jwk -> {:ok, jwk}
      _other -> {:error, :invalid_signing_key}
    end
  end
end
