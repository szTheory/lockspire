defmodule Lockspire.TestRepo.Migrations.AddSecurityProfileToClientsAndPolicies do
  use Lockspire.Storage.Ecto.Migration

  def change do
    alter lockspire_table(:lockspire_clients) do
      add(:security_profile, :text, null: false, default: "inherit")
    end

    alter lockspire_table(:lockspire_server_policies) do
      add(:security_profile, :text, null: false, default: "none")
    end
  end
end
