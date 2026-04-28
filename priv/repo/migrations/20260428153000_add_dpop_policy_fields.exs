defmodule Lockspire.TestRepo.Migrations.AddDpopPolicyFields do
  use Ecto.Migration

  def change do
    alter table(:lockspire_server_policies) do
      add :dpop_policy, :text, null: false, default: "bearer"
    end

    alter table(:lockspire_clients) do
      add :dpop_policy, :text, null: false, default: "inherit"
    end
  end
end
