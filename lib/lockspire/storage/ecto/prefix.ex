defmodule Lockspire.Storage.Ecto.Prefix do
  @moduledoc false

  @identifier ~r/^[A-Za-z_][A-Za-z0-9_]*$/

  @spec normalize(String.t() | atom() | nil) :: String.t() | nil
  def normalize(nil), do: nil
  def normalize(false), do: nil
  def normalize(:public), do: "public"
  def normalize(prefix) when is_atom(prefix), do: prefix |> Atom.to_string() |> normalize()

  def normalize(prefix) when is_binary(prefix) do
    prefix
    |> String.trim()
    |> case do
      "" ->
        nil

      prefix ->
        if Regex.match?(@identifier, prefix) do
          prefix
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

  @spec repo_opts(keyword()) :: keyword()
  def repo_opts(opts \\ []) do
    opts
    |> Keyword.drop([:sensitive])
    |> Keyword.merge(prefix_opts())
  end

  @spec prefix_opts() :: keyword()
  def prefix_opts do
    case Lockspire.Config.storage_prefix() do
      nil -> []
      prefix -> [prefix: prefix]
    end
  end

  @spec oban_opts() :: keyword()
  def oban_opts do
    case Lockspire.Config.oban_prefix() do
      nil -> []
      prefix -> [prefix: prefix]
    end
  end

  @spec quoted_identifier(String.t() | atom() | nil) :: String.t() | nil
  def quoted_identifier(prefix) do
    case normalize(prefix) do
      nil -> nil
      prefix -> ~s("#{prefix}")
    end
  end
end
