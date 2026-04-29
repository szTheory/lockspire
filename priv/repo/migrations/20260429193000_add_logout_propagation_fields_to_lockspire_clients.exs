defmodule Lockspire.TestRepo.Migrations.AddLogoutPropagationFieldsToLockspireClients do
  use Ecto.Migration

  def change do
    alter table(:lockspire_clients) do
      add :backchannel_logout_uri, :text
      add :backchannel_logout_session_required, :boolean, null: false, default: false
      add :frontchannel_logout_uri, :text
      add :frontchannel_logout_session_required, :boolean, null: false, default: false
    end
  end
end
