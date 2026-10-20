defmodule Lockspire.TestRepo.Migrations.AddClientLifetimeContract do
  use Lockspire.Storage.Ecto.Migration

  def change do
    alter lockspire_table(:lockspire_clients) do
      # Existing rows are legacy/unlimited. The nullable app deadline is populated only
      # by new authoritative registrations; management expiry is introduced for Phase 165.
      add(:lifetime_version, :integer, null: false, default: 0)
      add(:client_expires_at, :utc_datetime_usec)
      add(:registration_access_token_expires_at, :utc_datetime_usec)
    end
  end
end
