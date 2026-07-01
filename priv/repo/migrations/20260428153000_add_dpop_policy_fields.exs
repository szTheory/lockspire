defmodule Lockspire.TestRepo.Migrations.AddDpopPolicyFields do
  use Lockspire.Storage.Ecto.Migration

  def change do
    alter lockspire_table(:lockspire_server_policies) do
      add(:dpop_policy, :text, null: false, default: "bearer")
    end

    alter lockspire_table(:lockspire_clients) do
      add(:dpop_policy, :text, null: false, default: "inherit")
    end
  end
end
