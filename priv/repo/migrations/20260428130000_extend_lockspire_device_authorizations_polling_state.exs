defmodule Lockspire.TestRepo.Migrations.ExtendLockspireDeviceAuthorizationsPollingState do
  use Ecto.Migration

  def up do
    alter table(:lockspire_device_authorizations) do
      add :effective_poll_interval_seconds, :integer, null: false, default: 5
      add :next_poll_allowed_at, :utc_datetime_usec
    end

    execute("""
    UPDATE lockspire_device_authorizations
    SET effective_poll_interval_seconds = 5,
        next_poll_allowed_at = inserted_at + interval '5 seconds'
    WHERE next_poll_allowed_at IS NULL
    """)

    alter table(:lockspire_device_authorizations) do
      modify :next_poll_allowed_at, :utc_datetime_usec, null: false
    end

    create index(:lockspire_device_authorizations, [:next_poll_allowed_at])
  end

  def down do
    drop index(:lockspire_device_authorizations, [:next_poll_allowed_at])

    alter table(:lockspire_device_authorizations) do
      remove :next_poll_allowed_at
      remove :effective_poll_interval_seconds
    end
  end
end
