defmodule Lockspire.TestRepo.Migrations.AddAuthorizationResponseEncryptionFieldsToLockspireClients do
  use Lockspire.Storage.Ecto.Migration

  def change do
    alter lockspire_table(:lockspire_clients) do
      add(:authorization_encrypted_response_alg, :string)
      add(:authorization_encrypted_response_enc, :string)
    end
  end
end
