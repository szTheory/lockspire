defmodule Lockspire.Security.KeyEncryption.KeySet do
  @moduledoc false

  @type t :: %__MODULE__{
          current_id: String.t() | nil,
          ids: [String.t()],
          keys: %{optional(String.t()) => binary()},
          legacy_plaintext: :allow | :reject
        }

  defstruct [:current_id, ids: [], keys: %{}, legacy_plaintext: :allow]

  @spec current(t()) :: {String.t(), binary()}
  def current(%__MODULE__{current_id: id, keys: keys}), do: {id, Map.fetch!(keys, id)}

  @spec fetch_key(t(), term()) :: {:ok, binary()} | {:error, :unknown_kek}
  def fetch_key(%__MODULE__{keys: keys}, id) when is_binary(id) do
    case Map.fetch(keys, id) do
      {:ok, key} -> {:ok, key}
      :error -> {:error, :unknown_kek}
    end
  end

  def fetch_key(_keyset, _id), do: {:error, :unknown_kek}

  @id_pattern ~r/\A[A-Za-z0-9._-]{1,32}\z/

  @doc "Returns true when `id` satisfies the key id rule enforced by `new/1`."
  @spec valid_id?(term()) :: boolean()
  def valid_id?(id) when is_binary(id), do: Regex.match?(@id_pattern, id)
  def valid_id?(_id), do: false

  @spec new(term()) :: {:ok, t()} | {:error, {atom(), atom()}}
  def new(config) do
    # Validators return tagged errors only and never carry the configured value.
    with {:ok, opts} <- check_options(config),
         {:ok, entries} <- fetch_keys(opts),
         {:ok, keys} <- decode_entries(entries),
         {:ok, current} <- fetch_current(opts, keys),
         {:ok, mode} <- fetch_mode(opts, keys) do
      {:ok,
       %__MODULE__{
         current_id: current,
         ids: Enum.map(keys, &elem(&1, 0)),
         keys: Map.new(keys),
         legacy_plaintext: mode
       }}
    else
      {:error, {_key, _reason}} = error -> error
      _other -> {:error, {:key_encryption, :invalid_shape}}
    end
  end

  @allowed_options [:keys, :current, :legacy_plaintext]

  defp check_options(config) when is_list(config) do
    cond do
      not Keyword.keyword?(config) ->
        {:error, {:key_encryption, :invalid_shape}}

      Enum.any?(config, fn {k, _v} -> k not in @allowed_options end) ->
        {:error, {:key_encryption, :unknown_option}}

      true ->
        {:ok, config}
    end
  end

  defp check_options(_config), do: {:error, {:key_encryption, :invalid_shape}}

  defp fetch_keys(opts) do
    case Keyword.get(opts, :keys) do
      [_ | _] = entries -> {:ok, entries}
      _other -> {:error, {:keys, :missing_keys}}
    end
  end

  defp decode_entries(entries) do
    entries
    |> Enum.reduce_while({:ok, []}, fn entry, {:ok, acc} ->
      case decode_entry(entry, acc) do
        {:ok, decoded} -> {:cont, {:ok, [decoded | acc]}}
        {:error, _} = error -> {:halt, error}
      end
    end)
    |> case do
      {:ok, acc} -> {:ok, Enum.reverse(acc)}
      error -> error
    end
  end

  defp decode_entry({id, b64}, acc) when is_binary(id) and is_binary(b64) do
    with :ok <- check_id(id),
         :ok <- check_unique_id(id, acc),
         {:ok, key} <- decode_base64(b64),
         :ok <- check_length(key),
         :ok <- check_strength(key),
         :ok <- check_unique_material(key, acc) do
      {:ok, {id, key}}
    end
  end

  defp decode_entry(_entry, _acc), do: {:error, {:keys, :invalid_key_entry}}

  defp check_id(id) do
    if valid_id?(id), do: :ok, else: {:error, {:keys, :invalid_key_id}}
  end

  defp check_unique_id(id, acc) do
    if List.keymember?(acc, id, 0), do: {:error, {:keys, :duplicate_key_id}}, else: :ok
  end

  defp decode_base64(b64) do
    case Base.decode64(b64, padding: false) do
      {:ok, key} ->
        {:ok, key}

      :error ->
        case Base.url_decode64(b64, padding: false) do
          {:ok, key} -> {:ok, key}
          :error -> decode_padded(b64)
        end
    end
  end

  # Padded input: strip trailing "=" and retry unpadded decoders.
  defp decode_padded(b64) do
    trimmed = String.trim_trailing(b64, "=")

    with :error <- Base.decode64(trimmed, padding: false),
         :error <- Base.url_decode64(trimmed, padding: false) do
      {:error, {:keys, :invalid_base64}}
    end
  end

  defp check_length(key) when byte_size(key) == 32, do: :ok
  defp check_length(_key), do: {:error, {:keys, :invalid_key_length}}

  defp check_strength(<<first, _::binary>> = key) do
    if key == :binary.copy(<<first>>, byte_size(key)),
      do: {:error, {:keys, :weak_key_material}},
      else: :ok
  end

  defp check_unique_material(key, acc) do
    if Enum.any?(acc, fn {_id, other} -> other == key end),
      do: {:error, {:keys, :duplicate_key_material}},
      else: :ok
  end

  defp fetch_current(opts, keys) do
    case Keyword.get(opts, :current) do
      current when is_binary(current) ->
        if List.keymember?(keys, current, 0),
          do: {:ok, current},
          else: {:error, {:current, :unknown_current}}

      _other ->
        {:error, {:current, :missing_current}}
    end
  end

  defp fetch_mode(opts, _keys) do
    case Keyword.get(opts, :legacy_plaintext, :allow) do
      mode when mode in [:allow, :reject] -> {:ok, mode}
      _other -> {:error, {:legacy_plaintext, :invalid_legacy_plaintext}}
    end
  end
end
