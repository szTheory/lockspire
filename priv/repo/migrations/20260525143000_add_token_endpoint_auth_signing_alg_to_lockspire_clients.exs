defmodule Lockspire.TestRepo.Migrations.AddTokenEndpointAuthSigningAlgToLockspireClients do
  use Ecto.Migration

  def change do
    alter table(:lockspire_clients) do
      add :token_endpoint_auth_signing_alg, :text
    end
  end
end
