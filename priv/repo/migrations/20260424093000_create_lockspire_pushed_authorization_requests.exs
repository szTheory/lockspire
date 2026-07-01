defmodule Lockspire.TestRepo.Migrations.CreateLockspirePushedAuthorizationRequests do
  use Lockspire.Storage.Ecto.Migration

  def change do
    create lockspire_table(:lockspire_pushed_authorization_requests) do
      add(:request_uri_hash, :text, null: false)
      add(:client_id, :text, null: false)
      add(:redirect_uri, :text, null: false)
      add(:scopes, {:array, :text}, null: false, default: [])
      add(:prompt, {:array, :text}, null: false, default: [])
      add(:nonce, :text)
      add(:state, :text)
      add(:code_challenge, :text, null: false)
      add(:code_challenge_method, :text, null: false)
      add(:expires_at, :utc_datetime_usec, null: false)

      timestamps(type: :utc_datetime_usec)
    end

    create(lockspire_unique_index(:lockspire_pushed_authorization_requests, [:request_uri_hash]))
    create(lockspire_index(:lockspire_pushed_authorization_requests, [:client_id]))
    create(lockspire_index(:lockspire_pushed_authorization_requests, [:expires_at]))
  end
end
