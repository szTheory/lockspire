defmodule Lockspire.Security.ClientSecretVerifier do
  @moduledoc false

  alias Lockspire.Security.ClientSecretVerifier.Context
  alias Lockspire.Security.ClientSecretVerifier.Legacy
  alias Lockspire.Security.Policy

  @header "LSCV1"
  @family "LSCV"
  @aad_label "lockspire-client-secret-jwt-verifier"
  @iv_bytes 12
  @tag_bytes 16
  @max_identity_or_secret_bytes 1_048_576
  @max_payload_bytes 1_048_626
  @max_payload_encoded_bytes 1_398_168
  @max_envelope_bytes 1_398_207
  @key_id_pattern ~r/\A[A-Za-z0-9._-]{1,32}\z/

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
      {:ok, %Context{state: :invalid}} ->
        {:error, :client_secret_verifier_configuration_invalid}

      {:ok, %Context{state: :absent}} ->
        {:error, :client_secret_verifier_configuration_invalid}

      {:ok, %Context{write_mode: :legacy}} ->
        {:error, :client_secret_verifier_key_missing}

      {:error, reason}
      when reason in [
             :client_secret_verifier_identity_missing,
             :client_secret_verifier_unavailable,
             :client_secret_verifier_key_missing
           ] ->
        {:error, reason}

      {:error, _reason} ->
        {:error, :client_secret_verifier_configuration_invalid}

      _ ->
        {:error, :client_secret_verifier_configuration_invalid}
    end
  rescue
    _ -> {:error, :client_secret_verifier_unavailable}
  end

  @spec open(Context.t(), term(), term(), keyword()) :: {:ok, binary()} | {:error, atom()}
  def open(context, client_id, encrypted, opts) do
    with {:ok, %Context{} = context} <- Context.validate(context),
         :ok <- validate_identity(client_id),
         true <- is_binary(encrypted),
         {:ok, secret} <- open_value(context, client_id, encrypted, opts) do
      {:ok, secret}
    else
      {:ok, %Context{state: :invalid}} ->
        {:error, :client_secret_verifier_configuration_invalid}

      {:ok, _context} ->
        {:error, :client_secret_verifier_configuration_invalid}

      false ->
        {:error, :client_secret_verifier_unsupported_format}

      {:error, reason}
      when reason in [
             :client_secret_verifier_identity_missing,
             :client_secret_verifier_unavailable,
             :client_secret_verifier_unsupported_format,
             :client_secret_verifier_key_unknown,
             :client_secret_verifier_legacy_rejected
           ] ->
        {:error, reason}

      {:error, _reason} ->
        {:error, :client_secret_verifier_configuration_invalid}

      _ ->
        {:error, :client_secret_verifier_unavailable}
    end
  rescue
    _ -> {:error, :client_secret_verifier_unavailable}
  end

  @spec prepare_migrated(Context.t(), term(), term(), term(), keyword()) ::
          {:ok, binary()} | {:error, atom()}
  def prepare_migrated(context, client_id, legacy_text, expected_hash, opts) when is_list(opts) do
    with {:ok, %Context{state: :valid, write_mode: :dedicated} = context} <-
           Context.validate(context),
         :ok <- validate_identity(client_id),
         true <- is_binary(legacy_text) and not String.starts_with?(legacy_text, @family),
         now_ms when is_integer(now_ms) <-
           Keyword.get(opts, :now_ms, System.os_time(:millisecond)),
         legacy_key when is_binary(legacy_key) and legacy_key != "" <-
           legacy_key(opts),
         {:ok, %{data: secret, signed_at_ms: signed_at_ms, deadline_ms: deadline_ms}} <-
           Legacy.authenticated_metadata(legacy_text, legacy_key, now_ms),
         :ok <- validate_secret(secret),
         :ok <- verify_expected_hash(expected_hash, secret),
         {:ok, key} <- fetch_current_key(context, context.current_id) do
      seal_migrated(context.current_id, key, client_id, secret, signed_at_ms, deadline_ms)
    else
      {:ok, %Context{state: :invalid}} ->
        {:error, :client_secret_verifier_configuration_invalid}

      {:ok, %Context{state: :absent}} ->
        {:error, :client_secret_verifier_configuration_invalid}

      {:ok, %Context{write_mode: :legacy}} ->
        {:error, :client_secret_verifier_key_missing}

      {:error, reason}
      when reason in [
             :client_secret_verifier_configuration_invalid,
             :client_secret_verifier_identity_missing,
             :client_secret_verifier_unsupported_format,
             :client_secret_verifier_unavailable,
             :client_secret_verifier_key_missing
           ] ->
        {:error, reason}

      false ->
        {:error, :client_secret_verifier_unsupported_format}

      _ ->
        {:error, :client_secret_verifier_unsupported_format}
    end
  rescue
    _ -> {:error, :client_secret_verifier_unsupported_format}
  end

  @doc false
  @spec rewrap_native(Context.t(), term(), term(), term()) ::
          {:ok, :already_current, String.t(), String.t()}
          | {:ok, String.t(), String.t(), String.t()}
          | {:error, atom()}
  def rewrap_native(context, client_id, expected_hash, encrypted) do
    prepare_rewrap(context, client_id, encrypted, expected_hash, [])
  end

  @doc false
  @spec inspect_custody(Context.t(), term(), term(), term(), keyword()) ::
          {:ok, map()} | {:error, atom()}
  def inspect_custody(context, client_id, encrypted, expected_hash, opts) when is_list(opts) do
    with {:ok, %Context{state: :valid, write_mode: :dedicated} = context} <-
           Context.validate(context),
         :ok <- validate_identity(client_id),
         now_ms when is_integer(now_ms) <- custody_now_ms(opts),
         {:ok, secret, age, key_id} <- authenticated_material(context, client_id, encrypted),
         :ok <- verify_expected_hash(expected_hash, secret),
         :ok <- validate_custody_age(age, now_ms) do
      classification = if key_id == context.current_id, do: :current_key, else: :old_key

      {:ok,
       Map.merge(
         %{classification: classification, authenticated?: true, key_id: key_id},
         age_metadata(age, now_ms)
       )}
    else
      {:ok, %Context{}} -> {:error, :client_secret_verifier_configuration_invalid}
      {:error, reason} -> {:error, reason}
      _ -> {:error, :client_secret_verifier_unavailable}
    end
  rescue
    _ -> {:error, :client_secret_verifier_unavailable}
  end

  def inspect_custody(_context, _client_id, _encrypted, _expected_hash, _opts),
    do: {:error, :client_secret_verifier_unavailable}

  @doc false
  @spec prepare_rewrap(Context.t(), term(), term(), term(), keyword()) ::
          {:ok, :already_current, String.t(), String.t()}
          | {:ok, String.t(), String.t(), String.t()}
          | {:error, atom()}
  def prepare_rewrap(context, client_id, encrypted, expected_hash, opts) when is_list(opts) do
    with {:ok, %Context{state: :valid, write_mode: :dedicated} = context} <-
           Context.validate(context),
         :ok <- validate_identity(client_id),
         now_ms when is_integer(now_ms) <- custody_now_ms(opts),
         {:ok, secret, age, old_key_id} <- authenticated_material(context, client_id, encrypted),
         :ok <- validate_custody_age(age, now_ms),
         :ok <- verify_expected_hash(expected_hash, secret),
         {:ok, new_key} <- fetch_current_key(context, context.current_id) do
      if old_key_id == context.current_id do
        {:ok, :already_current, old_key_id, context.current_id}
      else
        seal_with_age(context.current_id, new_key, client_id, secret, age)
        |> case do
          {:ok, replacement} -> {:ok, replacement, old_key_id, context.current_id}
          {:error, reason} -> {:error, reason}
        end
      end
    else
      {:ok, %Context{}} -> {:error, :client_secret_verifier_configuration_invalid}
      {:error, reason} -> {:error, reason}
      _ -> {:error, :client_secret_verifier_unavailable}
    end
  rescue
    _ -> {:error, :client_secret_verifier_unavailable}
  end

  def prepare_rewrap(_context, _client_id, _encrypted, _expected_hash, _opts),
    do: {:error, :client_secret_verifier_unavailable}

  defp open_value(
         %Context{state: :valid, legacy_read: legacy_read} = context,
         client_id,
         encrypted,
         opts
       ) do
    if String.starts_with?(encrypted, @family) do
      open_dedicated(context, client_id, encrypted, opts)
    else
      open_legacy(legacy_read, encrypted, opts)
    end
  end

  defp open_value(%Context{state: :absent}, _client_id, encrypted, opts),
    do: open_legacy(:allow, encrypted, opts)

  defp open_dedicated(context, client_id, encrypted, opts) do
    with {:ok, secret, age, _key_id} <- authenticated_material(context, client_id, encrypted),
         :ok <-
           validate_stored_age(age, Keyword.get(opts, :verifier_now_ms, System.os_time(:millisecond))) do
      {:ok, secret}
    else
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

  defp legacy_key(opts) do
    Keyword.get(opts, :legacy_secret_key_base) || Keyword.get(opts, :secret_key_base)
  end

  defp verify_expected_hash(hash, secret)
       when is_binary(hash) do
    if Policy.verify_client_secret(hash, secret),
      do: :ok,
      else: {:error, :client_secret_verifier_unavailable}
  end

  defp verify_expected_hash(_hash, _secret),
    do: {:error, :client_secret_verifier_unavailable}

  defp seal_migrated(key_id, key, client_id, secret, signed_at_ms, deadline_ms) do
    iv = :crypto.strong_rand_bytes(@iv_bytes)

    plaintext =
      <<1, byte_size(secret)::unsigned-big-32, secret::binary, 1, signed_at_ms::signed-big-64,
        deadline_ms::signed-big-64>>

    {ciphertext, tag} =
      :crypto.crypto_one_time_aead(
        :aes_256_gcm,
        key,
        iv,
        plaintext,
        aad(key_id, client_id),
        @tag_bytes,
        true
      )

    payload = Base.url_encode64(iv <> tag <> ciphertext, padding: false)
    {:ok, @header <> "." <> key_id <> "." <> payload}
  end

  defp seal_with_age(key_id, key, client_id, secret, :native),
    do: seal_with_key(key_id, key, client_id, secret)

  defp seal_with_age(key_id, key, client_id, secret, {:migrated, signed_at_ms, deadline_ms}),
    do: seal_migrated(key_id, key, client_id, secret, signed_at_ms, deadline_ms)

  defp seal_with_key(key_id, key, client_id, secret) do
    iv = :crypto.strong_rand_bytes(@iv_bytes)
    plaintext = <<1, byte_size(secret)::unsigned-big-32, secret::binary, 0>>

    {ciphertext, tag} =
      :crypto.crypto_one_time_aead(
        :aes_256_gcm,
        key,
        iv,
        plaintext,
        aad(key_id, client_id),
        @tag_bytes,
        true
      )

    payload = Base.url_encode64(iv <> tag <> ciphertext, padding: false)
    {:ok, @header <> "." <> key_id <> "." <> payload}
  rescue
    _ -> {:error, :client_secret_verifier_unavailable}
  end

  defp authenticated_material(context, client_id, encrypted)
       when is_binary(encrypted) do
    with :ok <- validate_encoded_envelope(encrypted),
         {:ok, key_id, payload} <- parse_envelope(encrypted),
         {:ok, key} <- fetch_envelope_key(context, key_id),
         {:ok, decoded} <- Base.url_decode64(payload, padding: false),
         true <-
           byte_size(decoded) >= @iv_bytes + @tag_bytes and
             byte_size(decoded) <= @max_payload_bytes,
         true <- Base.url_encode64(decoded, padding: false) == payload,
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
         {:ok, secret, age} <- decode_plaintext(plaintext) do
      {:ok, secret, age, key_id}
    else
      false -> {:error, :client_secret_verifier_unsupported_format}
      {:error, reason} -> {:error, reason}
      _ -> {:error, :client_secret_verifier_unavailable}
    end
  rescue
    _ -> {:error, :client_secret_verifier_unavailable}
  end

  defp authenticated_material(_context, _client_id, _encrypted),
    do: {:error, :client_secret_verifier_unsupported_format}

  defp fetch_current_key(context, key_id) do
    case Map.fetch(context.keys, key_id) do
      {:ok, key} -> {:ok, key}
      :error -> {:error, :client_secret_verifier_key_missing}
    end
  end

  defp parse_envelope(encrypted) do
    case String.split(encrypted, ".") do
      [@header | pieces] when length(pieces) >= 2 ->
        payload = List.last(pieces)
        key_id = pieces |> Enum.drop(-1) |> Enum.join(".")

        if Regex.match?(@key_id_pattern, key_id) and payload != "" and
             byte_size(payload) <= @max_payload_encoded_bytes do
          {:ok, key_id, payload}
        else
          {:error, :client_secret_verifier_unsupported_format}
        end

      _ ->
        {:error, :client_secret_verifier_unsupported_format}
    end
  end

  defp validate_encoded_envelope(encrypted) do
    if byte_size(encrypted) <= @max_envelope_bytes and String.valid?(encrypted) and
         Enum.all?(:binary.bin_to_list(encrypted), &(&1 < 128)) do
      :ok
    else
      {:error, :client_secret_verifier_unsupported_format}
    end
  end

  defp fetch_envelope_key(context, key_id) do
    case Map.fetch(context.keys, key_id) do
      {:ok, key} -> {:ok, key}
      :error -> {:error, :client_secret_verifier_key_unknown}
    end
  end

  defp decode_plaintext(
         <<1, secret_length::unsigned-big-32, secret::binary-size(secret_length), 0>>
       )
       when secret_length > 0 and secret_length <= @max_identity_or_secret_bytes,
       do: {:ok, secret, :native}

  defp decode_plaintext(
         <<1, secret_length::unsigned-big-32, secret::binary-size(secret_length), 1,
           signed_at_ms::signed-big-64, deadline_ms::signed-big-64>>
       )
       when secret_length > 0 and secret_length <= @max_identity_or_secret_bytes and
              deadline_ms >= signed_at_ms,
       do: {:ok, secret, {:migrated, signed_at_ms, deadline_ms}}

  defp decode_plaintext(_plaintext), do: {:error, :client_secret_verifier_unavailable}

  defp validate_stored_age(:native, _now_ms), do: :ok

  defp validate_stored_age({:migrated, signed_at_ms, deadline_ms}, now_ms)
       when is_integer(now_ms) and signed_at_ms <= now_ms and deadline_ms >= now_ms,
       do: :ok

  defp validate_stored_age(_age, _now_ms), do: {:error, :client_secret_verifier_unavailable}

  defp validate_custody_age(:native, now_ms) when is_integer(now_ms), do: :ok

  defp validate_custody_age({:migrated, signed_at_ms, deadline_ms}, now_ms)
       when is_integer(now_ms) and signed_at_ms <= now_ms and deadline_ms >= signed_at_ms,
       do: :ok

  defp validate_custody_age(_age, _now_ms), do: {:error, :client_secret_verifier_unavailable}

  defp custody_now_ms(opts),
    do: Keyword.get(opts, :now_ms, Keyword.get(opts, :verifier_now_ms, System.os_time(:millisecond)))

  defp age_metadata(:native, _now_ms),
    do: %{age_kind: :native, signed_at_ms: nil, deadline_ms: nil, authentication_eligible?: true}

  defp age_metadata({:migrated, signed_at_ms, deadline_ms}, now_ms),
    do: %{
      age_kind: :migrated,
      signed_at_ms: signed_at_ms,
      deadline_ms: deadline_ms,
      authentication_eligible?: deadline_ms >= now_ms
    }

  defp validate_identity(client_id)
       when is_binary(client_id) and byte_size(client_id) > 0 and
              byte_size(client_id) <= @max_identity_or_secret_bytes do
    if String.valid?(client_id), do: :ok, else: {:error, :client_secret_verifier_identity_missing}
  end

  defp validate_identity(_client_id), do: {:error, :client_secret_verifier_identity_missing}

  defp validate_secret(secret)
       when is_binary(secret) and byte_size(secret) > 0 and
              byte_size(secret) <= @max_identity_or_secret_bytes,
       do: :ok

  defp validate_secret(_secret), do: {:error, :client_secret_verifier_unavailable}

  defp aad(key_id, client_id),
    do: @aad_label <> <<0>> <> @header <> <<0>> <> key_id <> <<0>> <> client_id
end
