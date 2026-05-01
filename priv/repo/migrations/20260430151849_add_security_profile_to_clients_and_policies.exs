defmodule Lockspire.TestRepo.Migrations.AddSecurityProfileToClientsAndPolicies do
  use Ecto.Migration

  def change do
    alter table(:lockspire_clients) do
      add :security_profile, :text, null: false, default: "inherit"
    end

    alter table(:lockspire_server_policies) do
      add :security_profile, :text, null: false, default: "none"
    end
  end
end
