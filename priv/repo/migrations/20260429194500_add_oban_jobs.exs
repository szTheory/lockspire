defmodule Lockspire.TestRepo.Migrations.AddObanJobs do
  use Lockspire.Storage.Ecto.Migration

  def up do
    Oban.Migrations.up(oban_migration_opts(version: 14))
  end

  def down do
    Oban.Migrations.down(oban_migration_opts(version: 1))
  end

  defp oban_migration_opts(opts) do
    case Lockspire.Config.oban_prefix() do
      nil -> opts
      prefix -> Keyword.put(opts, :prefix, prefix)
    end
  end
end
