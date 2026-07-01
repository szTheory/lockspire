defmodule Lockspire.Repo.Migrations.AddSidToLockspireInteractions do
  use Lockspire.Storage.Ecto.Migration

  def change do
    alter lockspire_table(:lockspire_interactions) do
      add(:sid, :string)
    end

    create(lockspire_index(:lockspire_interactions, [:sid]))
  end
end
