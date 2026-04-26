defmodule Lockspire.TestRepo.Migrations.ExtendLockspireServerPoliciesDcr do
  use Ecto.Migration

  def change do
    alter table(:lockspire_server_policies) do
      # D-05: tri-state enum stored as text, default :disabled
      add :registration_policy, :text, null: false, default: "disabled"

      # D-06: 6 array allowlists; empty-array defaults so operator must explicitly populate
      add :dcr_allowed_scopes, {:array, :text}, null: false, default: []
      add :dcr_allowed_grant_types, {:array, :text}, null: false, default: []
      add :dcr_allowed_response_types, {:array, :text}, null: false, default: []
      add :dcr_allowed_redirect_uri_schemes, {:array, :text}, null: false, default: []
      add :dcr_allowed_redirect_uri_hosts, {:array, :text}, null: false, default: []
      add :dcr_allowed_token_endpoint_auth_methods, {:array, :text}, null: false, default: []

      # D-06: 3 nullable lifetime integers (operator default = "use Lockspire global default")
      add :dcr_default_client_lifetime_seconds, :integer
      add :dcr_default_client_secret_lifetime_seconds, :integer
      add :dcr_default_registration_access_token_lifetime_seconds, :integer
    end
  end
end
