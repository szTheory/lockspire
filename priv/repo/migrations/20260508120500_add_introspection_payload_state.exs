defmodule Lockspire.Storage.Ecto.Repository.Migrations.AddIntrospectionPayloadState do
  use Ecto.Migration

  def change do
    alter table(:lockspire_consent_grants) do
      add(:authorization_details, {:array, :map}, default: [])
    end

    alter table(:lockspire_tokens) do
      add(:consent_grant_id, :bigint)
    end

    create(index(:lockspire_tokens, [:consent_grant_id]))
  end
end
