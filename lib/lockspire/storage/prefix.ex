defmodule Lockspire.Storage.Prefix do
  @moduledoc false

  @identifier ~r/^[A-Za-z_][A-Za-z0-9_]*$/

  @spec normalize(String.t() | atom() | false | nil) :: String.t() | nil
  def normalize(nil), do: nil
  def normalize(false), do: nil
  def normalize(:public), do: "public"
  def normalize(prefix) when is_atom(prefix), do: prefix |> Atom.to_string() |> normalize()

  def normalize(prefix) when is_binary(prefix) do
    case String.trim(prefix) do
      "" -> nil
      normalized ->
        if Regex.match?(@identifier, normalized) do
          normalized
        else
          raise ArgumentError,
                "invalid :storage_prefix for :lockspire. Use a PostgreSQL identifier such as \"lockspire\" or \"public\"."
        end
    end
  end

  def normalize(prefix) do
    raise ArgumentError,
          "invalid :storage_prefix for :lockspire. Expected a string, atom, nil, or false; got #{inspect(prefix)}."
  end

  @spec prefix_opts(String.t() | atom() | false | nil) :: keyword()
  def prefix_opts(prefix) do
    case normalize(prefix) do
      nil -> []
      normalized -> [prefix: normalized]
    end
  end

  @spec oban_opts(String.t() | atom() | false | nil) :: keyword()
  def oban_opts(prefix), do: prefix_opts(prefix)
end
