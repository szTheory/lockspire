defmodule Lockspire.TestRepo.Migrations.AddClientSecretJwtVerifierMaterialToLockspireClients do
  use Lockspire.Storage.Ecto.Migration

  def change do
    alter lockspire_table(:lockspire_clients) do
      add(:client_secret_jwt_verifier_encrypted, :text)
    end
  end
end
