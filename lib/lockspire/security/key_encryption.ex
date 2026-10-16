defmodule Lockspire.Security.KeyEncryption do
  @moduledoc false

  # AES-256-GCM envelope: <<"LSK", 1, id_len, kek_id, iv(12), tag(16), ciphertext>>.
  # Pure: callers hand in a resolved KeySet; this module never reads app env.

  alias Lockspire.Security.KeyEncryption.KeySet

  @magic "LSK"
  @version 1
  @aad_label "lockspire.signing_key.v1"
  @iv_bytes 12
  @tag_bytes 16

  @spec classify(term()) :: :envelope | :legacy | :invalid
  def classify(<<@magic, _::binary>>), do: :envelope
  def classify(bin) when is_binary(bin), do: :legacy
  def classify(_other), do: :invalid

  @spec seal(KeySet.t() | nil, term(), term()) ::
          {:ok, binary()} | {:error, :kek_not_configured | :invalid_input}
  def seal(nil, _kid, _plaintext), do: {:error, :kek_not_configured}

  def seal(%KeySet{} = keyset, kid, plaintext) when is_binary(kid) and is_binary(plaintext) do
    {id, key} = KeySet.current(keyset)

    if byte_size(id) > 255 do
      {:error, :invalid_input}
    else
      header = <<@magic, @version, byte_size(id)::8, id::binary>>
      iv = :crypto.strong_rand_bytes(@iv_bytes)

      {ct, tag} =
        :crypto.crypto_one_time_aead(
          :aes_256_gcm,
          key,
          iv,
          plaintext,
          aad(header, kid),
          @tag_bytes,
          true
        )

      {:ok, header <> iv <> tag <> ct}
    end
  end

  def seal(_keyset, _kid, _plaintext), do: {:error, :invalid_input}

  @spec open(KeySet.t() | nil, term(), term()) ::
          {:ok, binary()}
          | {:error,
             :kek_not_configured | :malformed_envelope | :unknown_kek | :decryption_failed}
  def open(nil, _kid, _envelope), do: {:error, :kek_not_configured}

  def open(%KeySet{} = keyset, kid, envelope) when is_binary(kid) and is_binary(envelope) do
    with {:ok, parsed} <- parse(envelope),
         {:ok, key} <- KeySet.fetch_key(keyset, parsed.kek_id) do
      decrypt(key, parsed.iv, parsed.ct, aad(parsed.header, kid), parsed.tag)
    end
  end

  def open(_keyset, _kid, _envelope), do: {:error, :malformed_envelope}

  @spec envelope_kek_id(term()) :: {:ok, String.t()} | {:error, :malformed_envelope}
  def envelope_kek_id(envelope) when is_binary(envelope) do
    case parse(envelope) do
      {:ok, %{kek_id: id}} -> {:ok, id}
      {:error, _} = error -> error
    end
  end

  def envelope_kek_id(_other), do: {:error, :malformed_envelope}

  defp parse(
         <<@magic, @version, id_len::8, kek_id::binary-size(id_len), iv::binary-size(12),
           tag::binary-size(16), ct::binary>> = bin
       ) do
    {:ok,
     %{
       kek_id: kek_id,
       iv: iv,
       tag: tag,
       ct: ct,
       header: binary_part(bin, 0, 5 + id_len)
     }}
  end

  defp parse(_other), do: {:error, :malformed_envelope}

  defp aad(header, kid), do: @aad_label <> <<0>> <> header <> <<0>> <> kid

  defp decrypt(key, iv, ct, aad, tag)
       when is_binary(key) and byte_size(key) == 32 and byte_size(iv) == @iv_bytes and
              byte_size(tag) == @tag_bytes do
    case :crypto.crypto_one_time_aead(:aes_256_gcm, key, iv, ct, aad, tag, false) do
      plaintext when is_binary(plaintext) -> {:ok, plaintext}
      _other -> {:error, :decryption_failed}
    end
  rescue
    _exception -> {:error, :decryption_failed}
  end

  defp decrypt(_key, _iv, _ct, _aad, _tag), do: {:error, :decryption_failed}
end
