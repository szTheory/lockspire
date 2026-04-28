defmodule Lockspire.TestRepo.Migrations.ExtendLockspireDeviceAuthorizationsVerificationState do
  use Ecto.Migration

  def change do
    alter table(:lockspire_device_authorizations) do
      add :verification_handle, :text
      add :status, :text, null: false, default: "pending"
      add :subject_id, :text
      add :approved_at, :utc_datetime_usec
      add :denied_at, :utc_datetime_usec
      add :consumed_at, :utc_datetime_usec
      add :expired_at, :utc_datetime_usec
    end

    create index(:lockspire_device_authorizations, [:status])
    create unique_index(:lockspire_device_authorizations, [:verification_handle])
  end
end
