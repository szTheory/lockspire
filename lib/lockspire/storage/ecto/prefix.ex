defmodule Lockspire.Storage.Ecto.Prefix do
  @moduledoc false

  alias Lockspire.Storage.Prefix, as: StoragePrefix

  @spec normalize(String.t() | atom() | nil) :: String.t() | nil
  defdelegate normalize(prefix), to: StoragePrefix

  @spec repo_opts(keyword()) :: keyword()
  def repo_opts(opts \\ []) do
    opts
    |> Keyword.drop([:sensitive])
    |> Keyword.merge(prefix_opts())
  end

  @spec prefix_opts() :: keyword()
  def prefix_opts do
    Lockspire.Config.storage_prefix() |> prefix_opts()
  end

  @spec prefix_opts(String.t() | atom() | false | nil) :: keyword()
  defdelegate prefix_opts(prefix), to: StoragePrefix

  @spec oban_opts() :: keyword()
  def oban_opts do
    Lockspire.Config.oban_prefix() |> oban_opts()
  end

  @spec oban_opts(String.t() | atom() | false | nil) :: keyword()
  defdelegate oban_opts(prefix), to: StoragePrefix

  @spec quoted_identifier(String.t() | atom() | nil) :: String.t() | nil
  def quoted_identifier(prefix) do
    case normalize(prefix) do
      nil -> nil
      prefix -> ~s("#{prefix}")
    end
  end
end
