defmodule Lockspire.Security.ClientSecretVerifier.Legacy do
  @moduledoc false

  @salt "lockspire client_secret_jwt verifier"
  @default_max_age_seconds 86_400
  @min_i64 -9_223_372_036_854_775_808
  @max_i64 9_223_372_036_854_775_807

  @spec authenticated_metadata(term(), term(), term()) ::
          {:ok, %{data: binary(), signed_at_ms: integer(), deadline_ms: integer()}}
          | {:error, :client_secret_verifier_unsupported_format}
  def authenticated_metadata(encrypted, secret_key_base, now_ms)
      when is_binary(encrypted) and is_binary(secret_key_base) and byte_size(secret_key_base) > 0 and
             is_integer(now_ms) do
    key = Plug.Crypto.KeyGenerator.generate(secret_key_base, @salt)

    with {:ok, payload} <- Plug.Crypto.MessageEncryptor.decrypt(encrypted, key, ""),
         term when not is_nil(term) <- safe_decode(payload),
         {:ok, data, signed_at_ms, max_age_seconds} <- normalize(term),
         {:ok, deadline_ms} <- finite_deadline(signed_at_ms, max_age_seconds),
         true <- signed_at_ms <= now_ms,
         true <- deadline_ms >= now_ms do
      {:ok, %{data: data, signed_at_ms: signed_at_ms, deadline_ms: deadline_ms}}
    else
      _ -> unsupported()
    end
  rescue
    _ -> unsupported()
  end

  def authenticated_metadata(_encrypted, _secret_key_base, _now_ms), do: unsupported()

  defp normalize({data, signed_at_ms, max_age_seconds})
       when is_binary(data) and byte_size(data) > 0 and is_integer(signed_at_ms) do
    {:ok, data, signed_at_ms, max_age_seconds}
  end

  defp normalize({data, signed_at_ms})
       when is_binary(data) and byte_size(data) > 0 and is_integer(signed_at_ms) do
    {:ok, data, signed_at_ms, @default_max_age_seconds}
  end

  defp normalize(%{data: data, signed: signed_at_ms})
       when is_binary(data) and byte_size(data) > 0 and is_integer(signed_at_ms) do
    {:ok, data, signed_at_ms, @default_max_age_seconds}
  end

  defp normalize(_term), do: unsupported()

  defp finite_deadline(signed_at_ms, age_seconds)
       when is_integer(signed_at_ms) and is_number(age_seconds) and age_seconds > 0 do
    age_ms = trunc(age_seconds * 1000)
    deadline_ms = signed_at_ms + age_ms

    if age_ms > 0 and signed_i64?(signed_at_ms) and signed_i64?(deadline_ms) do
      {:ok, deadline_ms}
    else
      unsupported()
    end
  end

  defp finite_deadline(_signed_at_ms, _age_seconds), do: unsupported()

  defp signed_i64?(value), do: value >= @min_i64 and value <= @max_i64

  defp safe_decode(payload) do
    Plug.Crypto.non_executable_binary_to_term(payload, [:safe])
  rescue
    _ -> nil
  end

  defp unsupported, do: {:error, :client_secret_verifier_unsupported_format}
end
