defmodule Lockspire.Storage.Ecto.Migrations.AddCibaUserCodeToClients do
  use Lockspire.Storage.Ecto.Migration

  def change do
    alter lockspire_table(:lockspire_clients) do
      add(:backchannel_user_code_parameter, :boolean, default: false, null: false)
    end
  end
end
