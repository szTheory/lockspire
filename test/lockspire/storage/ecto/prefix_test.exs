defmodule Lockspire.Storage.Ecto.PrefixTest do
  use ExUnit.Case, async: false

  setup do
    original_storage_prefix = Application.get_env(:lockspire, :storage_prefix)
    original_oban_prefix = Application.get_env(:lockspire, :oban_prefix)

    on_exit(fn ->
      restore_env(:storage_prefix, original_storage_prefix)
      restore_env(:oban_prefix, original_oban_prefix)
    end)

    :ok
  end

  test "prefix options stay empty for legacy missing config" do
    Application.delete_env(:lockspire, :storage_prefix)
    Application.delete_env(:lockspire, :oban_prefix)

    assert Lockspire.Storage.Ecto.Prefix.prefix_opts() == []
    assert Lockspire.Storage.Ecto.Prefix.oban_opts() == []

    assert Lockspire.Storage.Ecto.Migration.qualified_lockspire_table(:lockspire_clients) ==
             ~s("lockspire_clients")
  end

  test "prefix options and qualified table names honor explicit schema config" do
    Application.put_env(:lockspire, :storage_prefix, "lockspire")
    Application.put_env(:lockspire, :oban_prefix, "lockspire_jobs")

    assert Lockspire.Storage.Ecto.Prefix.prefix_opts() == [prefix: "lockspire"]
    assert Lockspire.Storage.Ecto.Prefix.oban_opts() == [prefix: "lockspire_jobs"]

    assert Lockspire.Storage.Ecto.Migration.qualified_lockspire_table(:lockspire_clients) ==
             ~s("lockspire"."lockspire_clients")
  end

  test "invalid prefixes fail before SQL is built" do
    Application.put_env(:lockspire, :storage_prefix, "bad-prefix")

    assert_raise ArgumentError, ~r/invalid :storage_prefix/, fn ->
      Lockspire.Storage.Ecto.Prefix.prefix_opts()
    end
  end

  test "explicit option builders do not read application configuration" do
    Application.put_env(:lockspire, :storage_prefix, "configured_elsewhere")
    Application.put_env(:lockspire, :oban_prefix, "configured_jobs")

    assert Lockspire.Storage.Ecto.Prefix.prefix_opts("explicit_schema") ==
             [prefix: "explicit_schema"]

    assert Lockspire.Storage.Ecto.Prefix.oban_opts(:public) == [prefix: "public"]
  end

  defp restore_env(key, nil), do: Application.delete_env(:lockspire, key)
  defp restore_env(key, value), do: Application.put_env(:lockspire, key, value)
end
