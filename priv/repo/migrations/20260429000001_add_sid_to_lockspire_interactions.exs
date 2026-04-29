defmodule Lockspire.Repo.Migrations.AddSidToLockspireInteractions do
  use Ecto.Migration

  def change do
    alter table(:lockspire_interactions) do
      add :sid, :string
    end

    create index(:lockspire_interactions, [:sid])
  end
end
