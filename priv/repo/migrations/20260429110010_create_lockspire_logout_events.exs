defmodule Lockspire.TestRepo.Migrations.CreateLockspireLogoutEvents do
  use Lockspire.Storage.Ecto.Migration

  def change do
    create lockspire_table(:lockspire_logout_events) do
      add(:event_id, :text, null: false)
      add(:sid, :text)
      add(:account_id, :text)
      add(:subject, :text)
      add(:initiated_by, :text, null: false)
      add(:post_logout_redirect_uri, :text)
      add(:frontchannel_continue_to, :text)
      add(:completed_at, :utc_datetime_usec)

      timestamps(type: :utc_datetime_usec)
    end

    create(lockspire_unique_index(:lockspire_logout_events, [:event_id]))
    create(lockspire_index(:lockspire_logout_events, [:sid]))
    create(lockspire_index(:lockspire_logout_events, [:account_id]))
  end
end
