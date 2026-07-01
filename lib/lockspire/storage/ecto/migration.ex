defmodule Lockspire.Storage.Ecto.Migration do
  @moduledoc false

  defmacro __using__(_opts) do
    quote do
      use Ecto.Migration

      import Lockspire.Storage.Ecto.Migration,
        only: [
          ensure_lockspire_schema: 0,
          lockspire_index: 2,
          lockspire_index: 3,
          lockspire_references: 1,
          lockspire_references: 2,
          lockspire_table: 1,
          lockspire_table: 2,
          lockspire_unique_index: 2,
          lockspire_unique_index: 3,
          qualified_lockspire_table: 1
        ]
    end
  end

  def ensure_lockspire_schema do
    case Lockspire.Config.storage_prefix() do
      nil ->
        :ok

      prefix ->
        Ecto.Migration.execute(
          "CREATE SCHEMA IF NOT EXISTS #{Lockspire.Storage.Ecto.Prefix.quoted_identifier(prefix)}"
        )
    end
  end

  def lockspire_table(name, opts \\ []) do
    Ecto.Migration.table(name, with_prefix(opts))
  end

  def lockspire_index(table, columns, opts \\ []) do
    Ecto.Migration.index(table, columns, with_prefix(opts))
  end

  def lockspire_unique_index(table, columns, opts \\ []) do
    Ecto.Migration.unique_index(table, columns, with_prefix(opts))
  end

  def lockspire_references(table, opts \\ []) do
    Ecto.Migration.references(table, with_prefix(opts))
  end

  def qualified_lockspire_table(name) when is_atom(name) do
    name
    |> Atom.to_string()
    |> qualified_lockspire_table()
  end

  def qualified_lockspire_table(name) when is_binary(name) do
    case Lockspire.Config.storage_prefix() do
      nil -> ~s("#{name}")
      prefix -> Lockspire.Storage.Ecto.Prefix.quoted_identifier(prefix) <> ~s(."#{name}")
    end
  end

  defp with_prefix(opts) do
    case Lockspire.Config.storage_prefix() do
      nil -> opts
      prefix -> Keyword.put_new(opts, :prefix, prefix)
    end
  end
end
