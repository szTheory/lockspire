defmodule Lockspire.Repo.Migrations.AddSidToLockspireTokens do
  use Ecto.Migration

  def change do
    alter table(:lockspire_tokens) do
      add :sid, :string
    end

    create index(:lockspire_tokens, [:sid])
  end
end
