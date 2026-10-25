defmodule Lockspire.Security.ClientSecretVerifier do
  @moduledoc false

  alias Lockspire.Security.ClientSecretVerifier.Context
  alias Lockspire.Security.Policy

  @header "LSCV1"
  @family "LSCV"
  @aad_label "lockspire-client-secret-jwt-verifier"
  @iv_bytes 12
  @tag_bytes 16

  @spec seal(Context.t(), term(), term()) :: {:ok, binary()} | {:error, atom()}
  def seal(context, client_id, secret) do
    with {:ok, %Context{state: :valid, write_mode: :dedicated, current_id: key_id} = context} <-
           Context.validate(context),
         :ok <- validate_identity(client_id),
         :ok <- validate_secret(secret),
         {:ok, key} <- fetch_current_key(context, key_id) do
      iv = :crypto.strong_rand_bytes(@iv_bytes)
      plaintext = <<1, byte_size(secret)::unsigned-big-32, secret::binary, 0>>
      aad = aad(key_id, client_id)

      {ciphertext, tag} =
        :crypto.crypto_one_time_aead(:aes_256_gcm, key, iv, plaintext, aad, @tag_bytes, true)

      payload = Base.url_encode64(iv <> tag <> ciphertext, padding: false)
      {:ok, @header <> "." <> key_id <> "." <> payload}
    else
      {:ok, %Context{state: :invalid, reason: reason}} -> {:error, reason}
      {:ok, %Context{state: :absent}} -> {:error, :client_secret_verifier_configuration_invalid}
      {:ok, %Context{write_mode: :legacy}} -> {:error, :client_secret_verifier_key_missing}
      {:error, reason} -> {:error, reason}
      _ -> {:error, :client_secret_verifier_configuration_invalid}
    end
  rescue
    _ -> {:error, :client_secret_verifier_unavailable}
  end

  @spec open(Context.t(), term(), term(), keyword()) :: {:ok, binary()} | {:error, atom()}
  def open(context, client_id, encrypted, opts) do
    with {:ok, %Context{state: :valid} = context} <- Context.validate(context),
         :ok <- validate_identity(client_id),
         true <- is_binary(encrypted),
         {:ok, secret} <- open_value(context, client_id, encrypted, opts) do
      {:ok, secret}
    else
      {:ok, %Context{state: :invalid, reason: reason}} -> {:error, reason}
      {:ok, _context} -> {:error, :client_secret_verifier_configuration_invalid}
      false -> {:error, :client_secret_verifier_unsupported_format}
      {:error, reason} -> {:error, reason}
      _ -> {:error, :client_secret_verifier_unavailable}
    end
  rescue
    _ -> {:error, :client_secret_verifier_unavailable}
  end

  defp open_value(%Context{legacy_read: legacy_read} = context, client_id, encrypted, opts) do
    if String.starts_with?(encrypted, @family) do
      open_dedicated(context, client_id, encrypted)
    else
      open_legacy(legacy_read, encrypted, opts)
    end
  end

  defp open_dedicated(context, client_id, encrypted) do
    with {:ok, key_id, payload} <- parse_envelope(encrypted),
         {:ok, key} <- Map.fetch(context.keys, key_id),
         {:ok, decoded} <- Base.url_decode64(payload, padding: false),
         true <- byte_size(decoded) >= @iv_bytes + @tag_bytes,
         <<iv::binary-size(@iv_bytes), tag::binary-size(@tag_bytes), ciphertext::binary>> <-
           decoded,
         plaintext when is_binary(plaintext) <-
           :crypto.crypto_one_time_aead(
             :aes_256_gcm,
             key,
             iv,
             ciphertext,
             aad(key_id, client_id),
             tag,
             false
           ),
         {:ok, secret} <- decode_native_plaintext(plaintext) do
      {:ok, secret}
    else
      :error -> {:error, :client_secret_verifier_key_unknown}
      false -> {:error, :client_secret_verifier_unsupported_format}
      {:error, reason} -> {:error, reason}
      _ -> {:error, :client_secret_verifier_unavailable}
    end
  end

  defp open_legacy(:reject, _encrypted, _opts),
    do: {:error, :client_secret_verifier_legacy_rejected}

  defp open_legacy(:allow, encrypted, opts) do
    key = Keyword.get(opts, :legacy_secret_key_base) || Keyword.get(opts, :secret_key_base)

    if is_binary(key) and key != "" do
      Policy.unseal_client_secret_jwt_verifier(encrypted, secret_key_base: key)
    else
      {:error, :client_secret_verifier_unavailable}
    end
  end

  defp open_legacy(_legacy_read, _encrypted, _opts),
    do: {:error, :client_secret_verifier_configuration_invalid}

  defp fetch_current_key(context, key_id) do
    case Map.fetch(context.keys, key_id) do
      {:ok, key} -> {:ok, key}
      :error -> {:error, :client_secret_verifier_key_missing}
    end
  end

  defp parse_envelope(encrypted) do
    case String.split(encrypted, ".", parts: 3) do
      [@header, key_id, payload] when key_id != "" and payload != "" -> {:ok, key_id, payload}
      _ -> {:error, :client_secret_verifier_unsupported_format}
    end
  end

  defp decode_native_plaintext(
         <<1, secret_length::unsigned-big-32, secret::binary-size(secret_length), 0>>
       )
       when secret_length > 0,
       do: {:ok, secret}

  defp decode_native_plaintext(_plaintext), do: {:error, :client_secret_verifier_unavailable}

  defp validate_identity(client_id)
       when is_binary(client_id) and byte_size(client_id) > 0 and
              byte_size(client_id) <= 1_048_576 do
    if String.valid?(client_id), do: :ok, else: {:error, :client_secret_verifier_identity_missing}
  end

  defp validate_identity(_client_id), do: {:error, :client_secret_verifier_identity_missing}

  defp validate_secret(secret)
       when is_binary(secret) and byte_size(secret) > 0 and byte_size(secret) <= 1_048_576,
       do: :ok

  defp validate_secret(_secret), do: {:error, :client_secret_verifier_unavailable}

  defp aad(key_id, client_id),
    do: @aad_label <> <<0>> <> @header <> <<0>> <> key_id <> <<0>> <> client_id
end
