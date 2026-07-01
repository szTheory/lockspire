defmodule Lockspire.TestRepo.Migrations.AddLogoutPropagationFieldsToLockspireClients do
  use Lockspire.Storage.Ecto.Migration

  def change do
    alter lockspire_table(:lockspire_clients) do
      add(:backchannel_logout_uri, :text)
      add(:backchannel_logout_session_required, :boolean, null: false, default: false)
      add(:frontchannel_logout_uri, :text)
      add(:frontchannel_logout_session_required, :boolean, null: false, default: false)
    end
  end
end
