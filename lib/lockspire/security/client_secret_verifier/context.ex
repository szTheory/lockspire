defmodule Lockspire.Security.ClientSecretVerifier.Context do
  @moduledoc false

  @enforce_keys [:state]
  defstruct state: :absent,
            keys: %{},
            key_ids: [],
            current_id: nil,
            write_mode: :legacy,
            legacy_read: :allow,
            reason: nil

  @type t :: %__MODULE__{}

  @allowed_options [:keys, :current, :write_mode, :legacy_read]
  @key_id_pattern ~r/\A[A-Za-z0-9._-]{1,32}\z/

  @spec resolve(term(), term()) :: {:ok, t()}
  def resolve(:absent, _forbidden_key_bytes), do: {:ok, %__MODULE__{state: :absent}}

  def resolve({:present, config}, forbidden_key_bytes) do
    case validate_config(config, forbidden_key_bytes) do
      {:ok, values} -> {:ok, struct!(__MODULE__, Map.put(values, :state, :valid))}
      {:error, reason} -> {:ok, %__MODULE__{state: :invalid, reason: reason}}
    end
  end

  def resolve(_presence, _forbidden_key_bytes),
    do: {:ok, %__MODULE__{state: :invalid, reason: :client_secret_verifier_configuration_invalid}}

  @spec validate(term()) :: {:ok, t()} | {:error, atom()}
  def validate(%__MODULE__{state: :absent} = context), do: {:ok, context}

  def validate(%__MODULE__{
        state: :invalid,
        reason: :client_secret_verifier_configuration_invalid
      }),
      do: {:error, :client_secret_verifier_configuration_invalid}

  def validate(%__MODULE__{state: :valid} = context), do: validate_complete(context)

  def validate(_context), do: {:error, :client_secret_verifier_configuration_invalid}

  defp validate_complete(context) do
    config = [
      keys:
        Enum.map(
          context.key_ids,
          &{&1, Base.url_encode64(Map.fetch!(context.keys, &1), padding: false)}
        ),
      current: context.current_id,
      write_mode: context.write_mode,
      legacy_read: context.legacy_read
    ]

    case validate_config(config, []) do
      {:ok, _values} -> {:ok, context}
      {:error, reason} -> {:error, reason}
    end
  rescue
    _ -> {:error, :client_secret_verifier_configuration_invalid}
  end

  defp validate_config(config, forbidden_key_bytes) do
    with :ok <- validate_options(config),
         {:ok, entries} <- decode_keys(Keyword.fetch!(config, :keys), forbidden_key_bytes),
         {:ok, current_id} <- validate_current(Keyword.get(config, :current), entries),
         :ok <-
           validate_modes(
             Keyword.fetch!(config, :write_mode),
             Keyword.fetch!(config, :legacy_read),
             current_id
           ) do
      {:ok,
       %{
         keys: Map.new(entries),
         key_ids: Enum.map(entries, &elem(&1, 0)),
         current_id: current_id,
         write_mode: Keyword.fetch!(config, :write_mode),
         legacy_read: Keyword.fetch!(config, :legacy_read),
         reason: nil
       }}
    else
      _ -> {:error, :client_secret_verifier_configuration_invalid}
    end
  end

  defp validate_options(config) when is_list(config) do
    if Keyword.keyword?(config) do
      keys = Keyword.keys(config)

      if length(keys) == length(Enum.uniq(keys)) and
           Enum.sort(keys) == Enum.sort(@allowed_options),
         do: :ok,
         else: {:error, :invalid_options}
    else
      {:error, :invalid_options}
    end
  end

  defp validate_options(_config), do: {:error, :invalid_options}

  defp decode_keys([_ | _] = entries, forbidden_key_bytes) when is_list(forbidden_key_bytes) do
    Enum.reduce_while(entries, {:ok, []}, fn
      {id, encoded}, {:ok, acc} when is_binary(id) and is_binary(encoded) ->
        with true <- Regex.match?(@key_id_pattern, id),
             false <- List.keymember?(acc, id, 0),
             {:ok, key} <- decode_key(encoded),
             true <- byte_size(key) == 32,
             false <- weak_key?(key),
             false <- Enum.any?(acc, fn {_other_id, other} -> other == key end),
             false <- Enum.any?(forbidden_key_bytes, &(&1 == key)) do
          {:cont, {:ok, [{id, key} | acc]}}
        else
          _ -> {:halt, {:error, :invalid_key}}
        end

      _entry, _acc ->
        {:halt, {:error, :invalid_key}}
    end)
    |> case do
      {:ok, entries} -> {:ok, Enum.reverse(entries)}
      error -> error
    end
  end

  defp decode_keys(_entries, _forbidden_key_bytes), do: {:error, :invalid_key}

  defp decode_key(encoded) do
    case Base.decode64(encoded, padding: false) do
      {:ok, key} ->
        {:ok, key}

      :error ->
        case Base.url_decode64(encoded, padding: false) do
          {:ok, key} -> {:ok, key}
          :error -> decode_padded_key(encoded)
        end
    end
  end

  defp decode_padded_key(encoded) do
    trimmed = String.trim_trailing(encoded, "=")

    with :error <- Base.decode64(trimmed, padding: false),
         :error <- Base.url_decode64(trimmed, padding: false) do
      :error
    end
  end

  defp weak_key?(<<first, _::binary>> = key), do: key == :binary.copy(<<first>>, byte_size(key))
  defp weak_key?(_key), do: true

  defp validate_current(nil, _entries), do: {:ok, nil}

  defp validate_current(current, entries) when is_binary(current) do
    if List.keymember?(entries, current, 0), do: {:ok, current}, else: {:error, :unknown_current}
  end

  defp validate_current(_current, _entries), do: {:error, :invalid_current}

  defp validate_modes(:legacy, :allow, _current), do: :ok
  defp validate_modes(:legacy, :reject, _current), do: {:error, :invalid_mode_pair}

  defp validate_modes(:dedicated, legacy_read, current)
       when legacy_read in [:allow, :reject] and is_binary(current), do: :ok

  defp validate_modes(_write_mode, _legacy_read, _current), do: {:error, :invalid_mode}
end

defimpl Inspect, for: Lockspire.Security.ClientSecretVerifier.Context do
  import Inspect.Algebra

  def inspect(context, _opts) do
    concat([
      "#ClientSecretVerifier.Context<",
      inspect(%{
        state: context.state,
        key_ids: context.key_ids,
        current_id: context.current_id,
        write_mode: context.write_mode,
        legacy_read: context.legacy_read,
        reason: context.reason
      }),
      ">"
    ])
  end
end
