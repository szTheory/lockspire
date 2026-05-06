defmodule Lockspire.Storage.Ecto.Migrations.AddCibaUserCodeToClients do
  use Ecto.Migration

  def change do
    alter table(:lockspire_clients) do
      add(:backchannel_user_code_parameter, :boolean, default: false, null: false)
    end
  end
end
