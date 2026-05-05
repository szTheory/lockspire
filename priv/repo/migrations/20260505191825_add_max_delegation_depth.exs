defmodule Lockspire.TestRepo.Migrations.AddMaxDelegationDepth do
  use Ecto.Migration

  def change do
    alter table(:lockspire_server_policies) do
      add :max_delegation_depth, :integer, default: 3, null: false
    end

    alter table(:lockspire_clients) do
      add :max_delegation_depth, :integer, null: true
    end
  end
end
