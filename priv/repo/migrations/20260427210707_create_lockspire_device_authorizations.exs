defmodule Lockspire.Repo.Migrations.CreateLockspireDeviceAuthorizations do
  use Lockspire.Storage.Ecto.Migration

  def change do
    create lockspire_table(:lockspire_device_authorizations) do
      add(:device_code_hash, :string, null: false)
      add(:user_code_hash, :string, null: false)
      add(:client_id, :string, null: false)
      add(:scopes, {:array, :string}, default: [])
      add(:expires_at, :utc_datetime_usec, null: false)

      timestamps(type: :utc_datetime_usec)
    end

    create(lockspire_unique_index(:lockspire_device_authorizations, [:device_code_hash]))
    create(lockspire_unique_index(:lockspire_device_authorizations, [:user_code_hash]))
  end
end
