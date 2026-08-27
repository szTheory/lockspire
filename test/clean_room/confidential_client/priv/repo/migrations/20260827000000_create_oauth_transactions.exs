defmodule CleanRoomClient.Repo.Migrations.CreateOauthTransactions do
  use Ecto.Migration

  def change do
    create table(:clean_room_oauth_transactions) do
      add(:state, :string, null: false)
      add(:nonce, :string, null: false)
      add(:verifier, :string, null: false)
      add(:challenge, :string, null: false)
      add(:issuer, :string, null: false)
      add(:client_id, :string, null: false)
      add(:callback_uri, :string, null: false)
      add(:profile, :string, null: false)
      add(:status, :string, null: false, default: "pending")
      add(:expires_at, :utc_datetime_usec, null: false)
      add(:encrypted_dpop_key, :binary)
      add(:dpop_jkt, :string)
      timestamps(type: :utc_datetime_usec)
    end

    create(unique_index(:clean_room_oauth_transactions, [:state]))

    create table(:clean_room_dpop_sessions) do
      add(:handle, :string, null: false)
      add(:encrypted_key, :binary, null: false)
      add(:encrypted_access_token, :binary, null: false)
      add(:encrypted_resource_nonce, :binary)
      add(:encrypted_accepted_resource_proof, :binary)
      add(:subject, :string, null: false)
      add(:jkt, :string, null: false)
      add(:expires_at, :utc_datetime_usec, null: false)
      add(:closed_at, :utc_datetime_usec)
      timestamps(type: :utc_datetime_usec)
    end

    create(unique_index(:clean_room_dpop_sessions, [:handle]))
  end
end
