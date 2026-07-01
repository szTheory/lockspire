defmodule Lockspire.Storage.Ecto.Repository.Migrations.AddIntrospectionPayloadState do
  use Lockspire.Storage.Ecto.Migration

  def change do
    alter lockspire_table(:lockspire_consent_grants) do
      add(:authorization_details, {:array, :map}, default: [])
    end

    alter lockspire_table(:lockspire_tokens) do
      add(:consent_grant_id, :bigint)
    end

    create(lockspire_index(:lockspire_tokens, [:consent_grant_id]))
  end
end
