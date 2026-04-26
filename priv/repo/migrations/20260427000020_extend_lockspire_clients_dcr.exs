defmodule Lockspire.TestRepo.Migrations.ExtendLockspireClientsDcr do
  use Ecto.Migration

  def change do
    alter table(:lockspire_clients) do
      # D-08 / D-09 / D-02: provenance text column with in-place default-backfill.
      # Postgres ADD COLUMN ... NOT NULL DEFAULT is atomic; no separate UPDATE step.
      # Two-value enum (:operator | :self_registered); the 3-value form is deferred.
      add(:provenance, :text, null: false, default: "operator")

      # D-08: RFC 7591 §3.2.1 timestamps (nullable on operator-created rows).
      add(:client_id_issued_at, :utc_datetime_usec)
      add(:client_secret_expires_at, :utc_datetime_usec)

      # D-08: RFC 7592 management credential (hash-at-rest; plaintext returned once at issuance).
      add(:registration_access_token_hash, :text)
      add(:registration_client_uri, :text)

      # D-08 + D-10: FK to IAT table. on_delete: :restrict — operator cannot delete an IAT
      # that minted a still-existing client (Pitfall 3). Soft-delete via revoked_at is the
      # only retirement path (D-12).
      add(
        :initial_access_token_id,
        references(:lockspire_initial_access_tokens, on_delete: :restrict),
        null: true
      )
    end
  end
end
