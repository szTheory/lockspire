defmodule Lockspire.TestRepo.Migrations.AddTokenEndpointAuthSigningAlgToLockspireClients do
  use Lockspire.Storage.Ecto.Migration

  def change do
    alter lockspire_table(:lockspire_clients) do
      add(:token_endpoint_auth_signing_alg, :text)
    end
  end
end
