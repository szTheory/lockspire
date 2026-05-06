defmodule Lockspire.Storage.Ecto.Migrations.AddCibaDeliveryMetadata do
  use Ecto.Migration

  def change do
    alter table(:lockspire_clients) do
      add(:backchannel_token_delivery_mode, :string, default: "poll", null: false)
      add(:backchannel_client_notification_endpoint, :string)
    end

    alter table(:lockspire_ciba_authorizations) do
      add(:delivery_mode, :string, default: "poll", null: false)
      add(:client_notification_endpoint, :string)
      add(:client_notification_token_encrypted, :binary)
      add(:auth_req_id_encrypted, :binary)
    end
  end
end
