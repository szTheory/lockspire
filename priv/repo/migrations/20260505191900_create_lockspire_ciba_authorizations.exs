defmodule Lockspire.Storage.Ecto.Migrations.CreateLockspireCibaAuthorizations do
  use Ecto.Migration

  def change do
    create table(:lockspire_ciba_authorizations) do
      add(:auth_req_id_hash, :string, null: false)
      add(:client_id, :string, null: false)
      add(:scopes, {:array, :string}, null: false, default: [])
      add(:status, :string, null: false)
      add(:subject_id, :string)
      add(:approved_at, :utc_datetime_usec)
      add(:denied_at, :utc_datetime_usec)
      add(:consumed_at, :utc_datetime_usec)
      add(:expired_at, :utc_datetime_usec)
      add(:effective_poll_interval_seconds, :integer, null: false)
      add(:next_poll_allowed_at, :utc_datetime_usec, null: false)
      add(:expires_at, :utc_datetime_usec, null: false)
      add(:binding_message, :text)

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:lockspire_ciba_authorizations, [:auth_req_id_hash])
    create index(:lockspire_ciba_authorizations, [:client_id])
    create index(:lockspire_ciba_authorizations, [:subject_id])
    create index(:lockspire_ciba_authorizations, [:expires_at])
  end
end
