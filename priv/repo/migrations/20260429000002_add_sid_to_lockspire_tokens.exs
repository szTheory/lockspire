defmodule Lockspire.Repo.Migrations.AddSidToLockspireTokens do
  use Lockspire.Storage.Ecto.Migration

  def change do
    alter lockspire_table(:lockspire_tokens) do
      add(:sid, :string)
    end

    create(lockspire_index(:lockspire_tokens, [:sid]))
  end
end
