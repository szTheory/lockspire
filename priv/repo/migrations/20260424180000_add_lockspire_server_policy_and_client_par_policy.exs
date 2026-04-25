defmodule Lockspire.TestRepo.Migrations.AddLockspireServerPolicyAndClientParPolicy do
  use Ecto.Migration

  def change do
    create table(:lockspire_server_policies) do
      add :par_policy, :text, null: false, default: "optional"

      timestamps(type: :utc_datetime_usec)
    end

    alter table(:lockspire_clients) do
      add :par_policy, :text, null: false, default: "inherit"
    end
  end
end
