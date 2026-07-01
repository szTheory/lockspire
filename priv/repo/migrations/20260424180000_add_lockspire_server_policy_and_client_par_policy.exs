defmodule Lockspire.TestRepo.Migrations.AddLockspireServerPolicyAndClientParPolicy do
  use Lockspire.Storage.Ecto.Migration

  def change do
    create lockspire_table(:lockspire_server_policies) do
      add(:par_policy, :text, null: false, default: "optional")

      timestamps(type: :utc_datetime_usec)
    end

    alter lockspire_table(:lockspire_clients) do
      add(:par_policy, :text, null: false, default: "inherit")
    end
  end
end
