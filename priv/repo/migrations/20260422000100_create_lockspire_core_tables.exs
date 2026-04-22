defmodule Lockspire.TestRepo.Migrations.CreateLockspireCoreTables do
  use Ecto.Migration

  def change do
    create table(:lockspire_clients) do
      add :client_id, :text, null: false
      add :client_secret_hash, :text
      add :client_type, :text, null: false
      add :name, :text
      add :redirect_uris, {:array, :text}, null: false, default: []
      add :post_logout_redirect_uris, {:array, :text}, null: false, default: []
      add :allowed_scopes, {:array, :text}, null: false, default: []
      add :allowed_grant_types, {:array, :text}, null: false, default: []
      add :allowed_response_types, {:array, :text}, null: false, default: []
      add :token_endpoint_auth_method, :text, null: false
      add :pkce_required, :boolean, null: false, default: true
      add :subject_type, :text, null: false
      add :sector_identifier_uri, :text
      add :id_token_signed_response_alg, :text
      add :jwks, :map
      add :jwks_uri, :text
      add :logo_uri, :text
      add :tos_uri, :text
      add :policy_uri, :text
      add :contacts, {:array, :text}, null: false, default: []
      add :tenant_id, :text
      add :created_by, :text
      add :created_at, :utc_datetime_usec
      add :metadata, :map, null: false, default: %{}

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:lockspire_clients, [:client_id])

    create table(:lockspire_interactions) do
      add :interaction_id, :text, null: false
      add :client_id, :text, null: false
      add :account_id, :text
      add :scopes_requested, {:array, :text}, null: false, default: []
      add :prompt, {:array, :text}, null: false, default: []
      add :nonce, :text
      add :redirect_uri, :text
      add :return_to, :text, null: false
      add :state, :text
      add :code_challenge, :text
      add :code_challenge_method, :text
      add :expires_at, :utc_datetime_usec, null: false
      add :tenant_id, :text

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:lockspire_interactions, [:interaction_id])
    create index(:lockspire_interactions, [:client_id])
    create index(:lockspire_interactions, [:expires_at])

    create table(:lockspire_consent_grants) do
      add :account_id, :text, null: false
      add :client_id, :text, null: false
      add :scopes, {:array, :text}, null: false, default: []
      add :granted_at, :utc_datetime_usec, null: false
      add :revoked_at, :utc_datetime_usec
      add :tenant_id, :text
      add :metadata, :map, null: false, default: %{}

      timestamps(type: :utc_datetime_usec)
    end

    create index(:lockspire_consent_grants, [:account_id])
    create index(:lockspire_consent_grants, [:client_id])

    create table(:lockspire_tokens) do
      add :token_hash, :text, null: false
      add :token_type, :text, null: false
      add :jti, :text
      add :family_id, :text
      add :generation, :integer, null: false, default: 0
      add :parent_token_id, :bigint
      add :client_id, :text, null: false
      add :account_id, :text
      add :scopes, {:array, :text}, null: false, default: []
      add :audience, {:array, :text}, null: false, default: []
      add :cnf, :map
      add :expires_at, :utc_datetime_usec, null: false
      add :revoked_at, :utc_datetime_usec
      add :reuse_detected_at, :utc_datetime_usec

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:lockspire_tokens, [:token_hash])
    create index(:lockspire_tokens, [:family_id])
    create index(:lockspire_tokens, [:client_id])

    create table(:lockspire_signing_keys) do
      add :kid, :text, null: false
      add :kty, :text, null: false
      add :alg, :text, null: false
      add :use, :text, null: false
      add :public_jwk, :map, null: false
      add :private_jwk_encrypted, :binary
      add :status, :text, null: false
      add :published_at, :utc_datetime_usec
      add :activated_at, :utc_datetime_usec
      add :retiring_at, :utc_datetime_usec
      add :retired_at, :utc_datetime_usec
      add :tenant_id, :text
      add :metadata, :map, null: false, default: %{}

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:lockspire_signing_keys, [:kid])
    create index(:lockspire_signing_keys, [:status])
  end
end
