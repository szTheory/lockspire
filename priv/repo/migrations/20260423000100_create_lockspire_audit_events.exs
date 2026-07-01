defmodule Lockspire.TestRepo.Migrations.CreateLockspireAuditEvents do
  use Lockspire.Storage.Ecto.Migration

  def change do
    create lockspire_table(:lockspire_audit_events) do
      add(:action, :text, null: false)
      add(:outcome, :text, null: false)
      add(:reason_code, :text)
      add(:actor_type, :text)
      add(:actor_id, :text)
      add(:actor_display, :text)
      add(:resource_type, :text, null: false)
      add(:resource_id, :text, null: false)
      add(:metadata, :map, null: false, default: %{})

      timestamps(type: :utc_datetime_usec)
    end

    create(lockspire_index(:lockspire_audit_events, [:action]))
    create(lockspire_index(:lockspire_audit_events, [:resource_type, :resource_id]))
    create(lockspire_index(:lockspire_audit_events, [:inserted_at]))
    create(lockspire_index(:lockspire_audit_events, [:actor_type, :actor_id]))
  end
end
