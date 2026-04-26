defmodule Lockspire.TestRepo.Migrations.CreateLockspireInitialAccessTokens do
  use Ecto.Migration

  def change do
    create table(:lockspire_initial_access_tokens) do
      # D-11: hash-at-rest (sha256 lowercase hex via Security.Policy.hash_token/1 in Plan 04 fixtures);
      # plaintext is NEVER stored.
      add(:token_hash, :text, null: false)

      # D-11: hard expiry; checked by Phase 26 redeem/1
      add(:expires_at, :utc_datetime_usec, null: false)

      # D-13: boolean (NOT uses_remaining int); v1.5 mints single-use IATs only.
      # Default true matches the most-common admin path.
      add(:single_use, :boolean, null: false, default: true)

      # D-11: nullable lifecycle timestamps. used_at = registrant consumed; revoked_at = operator soft-deleted.
      # D-12: soft-delete only; no hard-delete pathway.
      add(:used_at, :utc_datetime_usec)
      add(:revoked_at, :utc_datetime_usec)

      # D-11: opaque jsonb — Phase 28 mint-time path narrows to ⊆ server allowlist;
      # Phase 25 ships the column as opaque storage. T-25-05 documented: untyped jsonb,
      # intake validation is Phase 26's job.
      add(:policy_overrides, :map)

      # D-11: nullable operator id of the IAT minter (audit attribution).
      add(:created_by, :text)

      timestamps(type: :utc_datetime_usec)
    end

    # D-03: REQUIRED — Phase 26 atomic redemption depends on this index existing.
    # Lookup-by-hash MUST be unique (collision-free) for the UPDATE ... WHERE used_at IS NULL pattern.
    create(unique_index(:lockspire_initial_access_tokens, [:token_hash]))
  end
end
