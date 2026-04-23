defmodule Lockspire.Admin.TokensTest do
  use ExUnit.Case, async: false

  import Ecto.Query

  alias Lockspire.Admin.Tokens
  alias Lockspire.Domain.Client
  alias Lockspire.Domain.Token
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
        client_id: "token-client",
        client_secret_hash: "sha256:token:hash",
        client_type: :confidential,
        name: "Token Client",
        redirect_uris: ["https://token.example.com/callback"],
        allowed_scopes: ["openid", "offline_access"],
        allowed_grant_types: ["authorization_code", "refresh_token"],
        allowed_response_types: ["code"],
        token_endpoint_auth_method: :client_secret_basic,
        pkce_required: true,
        subject_type: :public,
        created_at: DateTime.utc_now(),
        metadata: %{}
      })

    now = DateTime.utc_now()

    {:ok, refresh_token} =
      Repository.store_token(%Token{
        token_hash: "refresh-admin-hash",
        token_type: :refresh_token,
        family_id: "family-admin-123",
        generation: 0,
        client_id: "token-client",
        account_id: "account-123",
        scopes: ["openid", "offline_access"],
        issued_at: now,
        expires_at: DateTime.add(now, 86_400, :second)
      })

    {:ok, access_token} =
      Repository.store_token(%Token{
        token_hash: "access-admin-hash",
        token_type: :access_token,
        family_id: "family-admin-123",
        generation: 1,
        parent_token_id: refresh_token.id,
        client_id: "token-client",
        account_id: "account-123",
        scopes: ["openid"],
        issued_at: DateTime.add(now, 5, :second),
        expires_at: DateTime.add(now, 3600, :second)
      })

    on_exit(fn -> :telemetry.detach(handler_id) end)

    %{refresh_token: refresh_token, access_token: access_token, handler_id: handler_id}
  end

  test "list_tokens/1 filters lifecycle tokens and enriches client data", %{
    refresh_token: refresh_token
  } do
    assert {:ok, entries} =
             Tokens.list_tokens(
               account_id: "account-123",
               client_id: "token-client",
               status: :active
             )

    assert Enum.any?(entries, &(&1.token.id == refresh_token.id))
    assert Enum.all?(entries, &(&1.client.name == "Token Client"))
    assert Enum.all?(entries, &(&1.status == :active))
  end

  test "get_token/1 returns family lineage and reuse state", %{refresh_token: refresh_token} do
    now = DateTime.utc_now()

    assert {:ok, _count} = Repository.revoke_token_family("family-admin-123")

    assert {:ok, %Token{}} =
             Repository.store_token(%Token{
               token_hash: "refresh-reuse-admin-hash",
               token_type: :refresh_token,
               family_id: "family-admin-123",
               generation: 2,
               client_id: "token-client",
               account_id: "account-123",
               scopes: ["offline_access"],
               issued_at: now,
               reuse_detected_at: now,
               revoked_at: now,
               expires_at: DateTime.add(now, 86_400, :second)
             })

    assert {:ok, detail} = Tokens.get_token(refresh_token.id)

    assert detail.token.id == refresh_token.id
    assert length(detail.family_tokens) == 3
    assert detail.family_status == :reuse_detected
    assert detail.family_reuse_detected_at == now
  end

  test "revoke_token/2 and revoke_token_family/2 stay idempotent with operator telemetry and audit",
       %{
         access_token: access_token
       } do
    access_token_id = access_token.id

    assert {:ok, detail} =
             Tokens.revoke_token(access_token.id, %{
               actor: %{type: :operator, id: "ops-token", display: "Token Admin"},
               revoked_reason: "incident_response"
             })

    assert detail.token.revoked_at
    assert detail.status == :revoked

    assert_received {:telemetry_event, [:lockspire, :token_revoked],
                     %{token_id: ^access_token_id, actor_id: "ops-token"}}

    assert %AuditEventRecord{} = token_audit = latest_audit!("token_revoked")
    assert token_audit.resource_id == Integer.to_string(access_token_id)
    assert token_audit.actor_id == "ops-token"
    assert token_audit.reason_code == "incident_response"

    assert {:ok, repeated_detail} = Tokens.revoke_token(access_token.id)
    assert repeated_detail.token.revoked_at == detail.token.revoked_at

    assert {:ok, %{count: count, token: family_detail}} =
             Tokens.revoke_token_family(access_token.id, %{
               actor: %{type: :operator, id: "ops-family", display: "Family Admin"},
               revoked_reason: "family_compromise"
             })

    assert count >= 0
    assert family_detail.family_revoked_count >= 1

    assert_received {:telemetry_event, [:lockspire, :token_family_revoked],
                     %{family_id: "family-admin-123", actor_id: "ops-family"}}

    assert %AuditEventRecord{} = family_audit = latest_audit!("token_family_revoked")
    assert family_audit.resource_type == "token_family"
    assert family_audit.resource_id == "family-admin-123"
    assert family_audit.actor_id == "ops-family"
    assert family_audit.reason_code == "family_compromise"

    assert {:ok, %{count: 0, token: repeated_family}} =
             Tokens.revoke_token_family(access_token.id)

    assert repeated_family.family_revoked_count == family_detail.family_revoked_count
  end

  def handle_event(event, _measurements, metadata, pid) do
    send(pid, {:telemetry_event, event, metadata})
  end

  defp attach_events(pid) do
    handler_id = "admin-tokens-test-#{System.unique_integer([:positive])}"

    :ok =
      :telemetry.attach_many(
        handler_id,
        [
          [:lockspire, :token_revoked],
          [:lockspire, :audit, :token_revoked],
          [:lockspire, :token_family_revoked],
          [:lockspire, :audit, :token_family_revoked]
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
