defmodule Lockspire.Protocol.PrivateJwk do
  @moduledoc false

  alias Lockspire.Config
  alias Lockspire.Security.KeyEncryption

  @type reason ::
          :invalid_signing_key
          | :kek_not_configured
          | :unknown_kek
          | :malformed_envelope
          | :decryption_failed
          | :kid_mismatch

  @spec decode(term()) :: {:ok, map()} | {:error, :invalid_signing_key}
  def decode(%{kid: kid, private_jwk_encrypted: bin}) when is_binary(kid) and is_binary(bin) do
    case decode_with_reason(%{kid: kid, private_jwk_encrypted: bin}) do
      {:ok, jwk} -> {:ok, jwk}
      {:error, _reason} -> {:error, :invalid_signing_key}
    end
  end

  def decode(_value), do: {:error, :invalid_signing_key}

  @doc false
  @spec decode_with_reason(term()) :: {:ok, map()} | {:error, reason()}
  def decode_with_reason(%{kid: kid, private_jwk_encrypted: bin})
      when is_binary(kid) and is_binary(bin) do
    case KeyEncryption.classify(bin) do
      :envelope -> decode_envelope(kid, bin)
      :legacy -> decode_legacy(bin)
      :invalid -> {:error, :invalid_signing_key}
    end
  rescue
    _exception -> {:error, :invalid_signing_key}
  catch
    _kind, _reason -> {:error, :invalid_signing_key}
  end

  def decode_with_reason(_value), do: {:error, :invalid_signing_key}

  defp decode_envelope(kid, bin) do
    with {:ok, plaintext} <- KeyEncryption.open(Config.key_encryption_keyset(), kid, bin),
         {:ok, %{} = jwk} <- Jason.decode(plaintext) do
      if Map.get(jwk, "kid") == kid, do: {:ok, jwk}, else: {:error, :kid_mismatch}
    else
      {:error, reason} when is_atom(reason) -> {:error, reason}
      _other -> {:error, :invalid_signing_key}
    end
  end

  defp decode_legacy(binary) do
    case Jason.decode(binary) do
      {:ok, %{} = jwk} -> {:ok, jwk}
      _other -> decode_safe_term(binary)
    end
  end

  defp decode_safe_term(binary) do
    case Plug.Crypto.non_executable_binary_to_term(binary, [:safe]) do
      %{} = jwk -> {:ok, jwk}
      _other -> {:error, :invalid_signing_key}
    end
  end
end
