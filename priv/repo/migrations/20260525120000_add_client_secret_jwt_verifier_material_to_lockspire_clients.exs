defmodule Lockspire.TestRepo.Migrations.AddClientSecretJwtVerifierMaterialToLockspireClients do
  use Ecto.Migration

  def change do
    alter table(:lockspire_clients) do
      add :client_secret_jwt_verifier_encrypted, :text
    end
  end
end
