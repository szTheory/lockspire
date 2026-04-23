defmodule Lockspire.TestRepo.Migrations.ExtendAuthorizationCoreState do
  use Ecto.Migration

  def change do
    alter table(:lockspire_interactions) do
      add :status, :text, null: false, default: "pending_login"
      add :login_required_at, :utc_datetime_usec
      add :consent_requested_at, :utc_datetime_usec
      add :completed_at, :utc_datetime_usec
      add :denied_at, :utc_datetime_usec
      add :expired_at, :utc_datetime_usec
      add :denial_reason, :text
    end

    create index(:lockspire_interactions, [:status])

    alter table(:lockspire_consent_grants) do
      add :status, :text, null: false, default: "active"
      add :kind, :text, null: false, default: "remembered"
      add :revoked_by, :text
      add :revoked_reason, :text
    end

    create index(:lockspire_consent_grants, [:account_id, :client_id, :status, :kind])

    alter table(:lockspire_tokens) do
      add :interaction_id, :text
      add :redirect_uri, :text
      add :code_challenge, :text
      add :code_challenge_method, :text
      add :issued_at, :utc_datetime_usec
      add :redeemed_at, :utc_datetime_usec
    end

    create index(:lockspire_tokens, [:token_type, :redeemed_at])
    create index(:lockspire_tokens, [:interaction_id])
  end
end
