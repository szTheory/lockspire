defmodule Lockspire.TestRepo.Migrations.CreateLockspireLogoutDeliveries do
  use Ecto.Migration

  def change do
    create table(:lockspire_logout_deliveries) do
      add :delivery_id, :text, null: false
      add :logout_event_id, references(:lockspire_logout_events, on_delete: :delete_all), null: false
      add :client_id, :text, null: false
      add :channel, :text, null: false
      add :target_uri, :text, null: false
      add :session_required, :boolean, null: false, default: false
      add :status, :text, null: false, default: "pending"
      add :attempt_count, :integer, null: false, default: 0
      add :last_attempted_at, :utc_datetime_usec
      add :delivered_at, :utc_datetime_usec
      add :rendered_at, :utc_datetime_usec
      add :finalized_at, :utc_datetime_usec
      add :http_status, :integer
      add :failure_reason, :text
      add :logout_token_jti, :text
      add :oban_job_id, :bigint

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:lockspire_logout_deliveries, [:delivery_id])
    create unique_index(:lockspire_logout_deliveries, [:logout_event_id, :client_id, :channel])
    create index(:lockspire_logout_deliveries, [:logout_event_id])
    create index(:lockspire_logout_deliveries, [:client_id])
    create index(:lockspire_logout_deliveries, [:status])
  end
end
