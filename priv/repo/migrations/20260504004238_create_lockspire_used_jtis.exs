defmodule Lockspire.Repo.Migrations.CreateLockspireUsedJtis do
  use Lockspire.Storage.Ecto.Migration

  def change do
    create lockspire_table(:lockspire_used_jtis) do
      add(:client_id, :string, null: false)
      add(:jti, :string, null: false)
      add(:expires_at, :utc_datetime_usec, null: false)

      timestamps(type: :utc_datetime_usec)
    end

    create(lockspire_unique_index(:lockspire_used_jtis, [:client_id, :jti]))
    create(lockspire_index(:lockspire_used_jtis, [:expires_at]))
  end
end
