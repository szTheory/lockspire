defmodule Lockspire.TestRepo.Migrations.AddMaxDelegationDepth do
  use Lockspire.Storage.Ecto.Migration

  def change do
    alter lockspire_table(:lockspire_server_policies) do
      add(:max_delegation_depth, :integer, default: 3, null: false)
    end

    alter lockspire_table(:lockspire_clients) do
      add(:max_delegation_depth, :integer, null: true)
    end
  end
end
