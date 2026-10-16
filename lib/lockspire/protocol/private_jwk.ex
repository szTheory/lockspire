defmodule Lockspire.Protocol.PrivateJwk do
  @moduledoc false

  alias Lockspire.Config
  alias Lockspire.Redaction
  alias Lockspire.Security.KeyEncryption
  alias Lockspire.Security.KeyEncryption.KeySet

  @type reason ::
          :invalid_signing_key
          | :kek_not_configured
          | :unknown_kek
          | :malformed_envelope
          | :decryption_failed
          | :kid_mismatch
          | :plaintext_key_refused

  @spec decode(term()) :: {:ok, map()} | {:error, :invalid_signing_key}
  def decode(%{kid: kid, private_jwk_encrypted: bin} = row)
      when is_binary(kid) and is_binary(bin) do
    case decode_stored(row, Config.key_encryption_keyset()) do
      {:ok, jwk, _source} ->
        {:ok, jwk}

      {:error, reason} ->
        emit_decode_failed(kid, bin, reason)
        {:error, :invalid_signing_key}
    end
  end

  def decode(_value), do: {:error, :invalid_signing_key}

  @doc false
  @spec decode_with_reason(term()) :: {:ok, map()} | {:error, reason()}
  def decode_with_reason(%{kid: kid, private_jwk_encrypted: bin} = row)
      when is_binary(kid) and is_binary(bin) do
    case decode_stored(row, Config.key_encryption_keyset()) do
      {:ok, jwk, _source} -> {:ok, jwk}
      {:error, reason} -> {:error, reason}
    end
  end

  def decode_with_reason(_value), do: {:error, :invalid_signing_key}

  # Under legacy_plaintext: :reject a non-envelope value is refused before any parser
  # runs, so a hostile or malformed legacy payload never reaches Jason or the term decoder.
  defp decode_stored(%{private_jwk_encrypted: bin} = row, keyset) do
    if refuse_plaintext?(keyset, bin),
      do: {:error, :plaintext_key_refused},
      else: read_stored(row, keyset)
  end

  defp refuse_plaintext?(%KeySet{legacy_plaintext: :reject}, bin),
    do: KeyEncryption.classify(bin) == :legacy

  defp refuse_plaintext?(_keyset, _bin), do: false

  # Signing-path event: it must not go through the shared operator emit helper, because
  # the signing path writes no audit record and must not double-emit an audit-prefixed copy.
  defp emit_decode_failed(kid, bin, reason) do
    metadata =
      case KeyEncryption.envelope_kek_id(bin) do
        {:ok, kek_id} -> %{kid: kid, reason: reason, kek_id: kek_id}
        _other -> %{kid: kid, reason: reason}
      end

    :telemetry.execute(
      [:lockspire, :key, :decode_failed],
      %{count: 1},
      Redaction.for_telemetry(metadata)
    )
  end

  # Only the protocol decoder and the admin re-encryption engine may call this reader.
  # It takes the key set explicitly, applies no legacy-plaintext policy and emits no
  # telemetry or logs, so a migration can read rows that request paths would refuse.
  @doc false
  @spec read_stored(term(), KeySet.t() | nil) ::
          {:ok, map(), :legacy | {:envelope, String.t()}} | {:error, reason()}
  def read_stored(row, keyset), do: read_row(row, keyset)

  defp read_row(%{kid: kid, private_jwk_encrypted: bin}, keyset)
       when is_binary(kid) and is_binary(bin) do
    case KeyEncryption.classify(bin) do
      :envelope -> read_envelope(keyset, kid, bin)
      :legacy -> read_legacy(bin)
      :invalid -> {:error, :invalid_signing_key}
    end
  rescue
    _exception -> {:error, :invalid_signing_key}
  catch
    _kind, _reason -> {:error, :invalid_signing_key}
  end

  defp read_row(_value, _keyset), do: {:error, :invalid_signing_key}

  defp read_envelope(keyset, kid, bin) do
    with {:ok, plaintext} <- KeyEncryption.open(keyset, kid, bin),
         {:ok, %{} = jwk} <- Jason.decode(plaintext),
         {:ok, kek_id} <- KeyEncryption.envelope_kek_id(bin) do
      if Map.get(jwk, "kid") == kid,
        do: {:ok, jwk, {:envelope, kek_id}},
        else: {:error, :kid_mismatch}
    else
      {:error, reason} when is_atom(reason) -> {:error, reason}
      _other -> {:error, :invalid_signing_key}
    end
  end

  defp read_legacy(binary) do
    case decode_legacy(binary) do
      {:ok, jwk} -> {:ok, jwk, :legacy}
      {:error, reason} -> {:error, reason}
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
