defmodule Lockspire.Admin.ConsentsTest do
  use ExUnit.Case, async: false

  import Ecto.Query

  alias Lockspire.Admin.Consents
  alias Lockspire.Domain.Client
  alias Lockspire.Domain.ConsentGrant
  alias Lockspire.Storage.Ecto.AuditEventRecord
  alias Lockspire.Storage.Ecto.Repository

  setup_all do
    Application.put_env(:lockspire, :repo, Lockspire.TestRepo)

    start_supervised!(Lockspire.TestRepo)
    Ecto.Adapters.SQL.Sandbox.mode(Lockspire.TestRepo, :manual)

    :ok
  end

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Lockspire.TestRepo)
    handler_id = attach_events(self())

    {:ok, _client} =
      Repository.register_client(%Client{
        client_id: "consent-client",
        client_secret_hash: "sha256:consent:hash",
        client_type: :confidential,
        name: "Consent Client",
        redirect_uris: ["https://consent.example.com/callback"],
        allowed_scopes: ["openid", "email"],
        allowed_grant_types: ["authorization_code", "refresh_token"],
        allowed_response_types: ["code"],
        token_endpoint_auth_method: :client_secret_basic,
        pkce_required: true,
        subject_type: :public,
        created_at: DateTime.utc_now(),
        metadata: %{}
      })

    {:ok, grant} =
      Repository.grant_consent(%ConsentGrant{
        account_id: "account-123",
        client_id: "consent-client",
        scopes: ["openid", "email"],
        granted_at: DateTime.utc_now(),
        metadata: %{"source" => "seed"}
      })

    on_exit(fn -> :telemetry.detach(handler_id) end)

    %{grant: grant, handler_id: handler_id}
  end

  test "list_consents_for_account/1 enriches durable grants with client detail" do
    assert {:ok, [consent]} = Consents.list_consents_for_account("account-123")

    assert consent.grant.account_id == "account-123"
    assert consent.grant.client_id == "consent-client"
    assert consent.client.name == "Consent Client"
  end

  test "list_consents/1 filters by durable consent status", %{grant: grant} do
    grant_id = grant.id

    assert {:ok, [%{grant: %{id: ^grant_id}}]} = Consents.list_consents(status: :active)

    assert {:ok, _revoked} =
             Consents.revoke_consent(grant.id, %{
               revoked_by: "ops@example.com",
               revoked_reason: "support_request"
             })

    assert {:ok, [%{grant: %{id: ^grant_id, status: :revoked}}]} =
             Consents.list_consents(status: :revoked)
  end

  test "revoke_consent/2 is durable, idempotent, emits telemetry, and appends operator audit",
       %{grant: grant} do
    assert {:ok, revoked} =
             Consents.revoke_consent(grant.id, %{
               revoked_by: "account-123",
               revoked_reason: "account_revoked",
               actor: %{type: :operator, id: "ops-consent", display: "Consent Admin"}
             })

    assert revoked.grant.status == :revoked
    assert revoked.grant.revoked_by == "account-123"
    assert revoked.grant.revoked_reason == "account_revoked"
    assert revoked.grant.revoked_at

    assert_received {:telemetry_event, [:lockspire, :consent, :revoked],
                     %{grant_id: grant_id, actor_id: "ops-consent"}}

    assert grant_id == grant.id

    assert %AuditEventRecord{} = audit = latest_audit!("consent_revoked")
    assert audit.resource_type == "consent_grant"
    assert audit.resource_id == Integer.to_string(grant.id)
    assert audit.actor_type == "operator"
    assert audit.actor_id == "ops-consent"
    assert audit.reason_code == "account_revoked"
    assert audit.metadata["client_id"] == "consent-client"

    assert {:ok, repeated} =
             Consents.revoke_consent(grant.id, %{
               revoked_by: "ops@example.com",
               revoked_reason: "second_attempt"
             })

    assert repeated.grant.status == :revoked
    assert repeated.grant.revoked_at == revoked.grant.revoked_at
    assert repeated.grant.revoked_by == revoked.grant.revoked_by
    assert repeated.grant.revoked_reason == revoked.grant.revoked_reason
  end

  def handle_event(event, _measurements, metadata, pid) do
    send(pid, {:telemetry_event, event, metadata})
  end

  defp attach_events(pid) do
    handler_id = "admin-consents-test-#{System.unique_integer([:positive])}"

    :ok =
      :telemetry.attach_many(
        handler_id,
        [
          [:lockspire, :consent, :revoked],
          [:lockspire, :audit, :consent, :revoked]
        ],
        &__MODULE__.handle_event/4,
        pid
      )

    handler_id
  end

  defp latest_audit!(action) do
    Lockspire.TestRepo.one!(
      from(audit in AuditEventRecord,
        where: audit.action == ^to_string(action),
        order_by: [desc: audit.id],
        limit: 1
      )
    )
  end
end
