defmodule Lockspire.Storage.Ecto.Repository.Migrations.AddRarDurableStorage do
  use Ecto.Migration

  def change do
    alter table(:lockspire_consent_grants) do
      add(:authorization_details, {:array, :map}, default: [])
      add(:authorization_details_fingerprint, :binary)
    end

    alter table(:lockspire_tokens) do
      add(:consent_grant_id, references(:lockspire_consent_grants, on_delete: :nilify_all))
    end

    create(index(:lockspire_tokens, [:consent_grant_id]))

    create(
      index(
        :lockspire_consent_grants,
        [:account_id, :client_id, :authorization_details_fingerprint],
        where: "status = 'active'",
        name: :lockspire_consent_grants_reuse_idx
      )
    )
  end
end
