defmodule Lockspire.Admin.ClientsTest do
  use ExUnit.Case, async: false

  import Ecto.Query

  alias Lockspire.Admin.Clients
  alias Lockspire.Clients.RegistrationResult
  alias Lockspire.Domain.Client
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
        client_id: "admin-client",
        client_secret_hash: "sha256:old-salt:old-hash",
        client_type: :confidential,
        name: "Admin Client",
        redirect_uris: ["https://admin.example.com/callback"],
        allowed_scopes: ["email"],
        allowed_grant_types: ["authorization_code", "refresh_token"],
        allowed_response_types: ["code"],
        token_endpoint_auth_method: :client_secret_basic,
        pkce_required: true,
        subject_type: :public,
        created_at: DateTime.utc_now(),
        metadata: %{"tier" => "sandbox"}
      })

    on_exit(fn -> :telemetry.detach(handler_id) end)

    %{handler_id: handler_id}
  end

  test "create_client/1 reuses canonical registration, emits telemetry, and appends operator audit" do
    assert {:ok, %RegistrationResult{client: client, client_secret: secret}} =
             Clients.create_client(%{
               client_id: "new-client",
               name: "New Client",
               client_type: :confidential,
               redirect_uris: ["https://new.example.com/callback"],
               allowed_scopes: ["profile"],
               allowed_grant_types: ["authorization_code"],
               token_endpoint_auth_method: :client_secret_basic,
               actor: %{
                 type: :operator,
                 id: "ops-123",
                 display: "Ops User"
               }
             })

    assert client.client_id == "new-client"
    assert is_binary(secret)
    assert client.client_secret_hash

    assert_received {:telemetry_event, [:lockspire, :client_created],
                     %{client_id: "new-client", actor_type: :operator, actor_id: "ops-123"}}

    assert_received {:telemetry_event, [:lockspire, :audit, :client_created],
                     %{client_id: "new-client", actor_type: :operator, actor_id: "ops-123"}}

    assert %AuditEventRecord{} = audit = latest_audit!("client_created")
    assert audit.resource_type == "client"
    assert audit.resource_id == "new-client"
    assert audit.actor_type == "operator"
    assert audit.actor_id == "ops-123"
    assert audit.actor_display == "Ops User"
    assert audit.outcome == "succeeded"
    assert audit.reason_code == "client_created"
    assert audit.metadata["client_type"] == "confidential"
  end

  test "update_client/2 allows safe metadata changes and rejects immutable fields" do
    assert {:ok, %Client{} = client} =
             Clients.update_client("admin-client", %{
               name: "Admin Client Updated",
               redirect_uris: ["https://admin.example.com/oidc/callback"],
               allowed_scopes: ["email", "profile"],
               contacts: ["ops@example.com"],
               metadata: %{"tier" => "production"}
             })

    assert client.name == "Admin Client Updated"
    assert client.redirect_uris == ["https://admin.example.com/oidc/callback"]
    assert client.allowed_scopes == ["email", "profile"]
    assert client.contacts == ["ops@example.com"]
    assert client.metadata == %{"tier" => "production"}

    assert {:error, errors} =
             Clients.update_client("admin-client", %{
               client_id: "renamed",
               token_endpoint_auth_method: :client_secret_post
             })

    assert Enum.any?(errors, &(&1.field == :client_id and &1.reason == :immutable_field))

    assert Enum.any?(
             errors,
             &(&1.field == :token_endpoint_auth_method and &1.reason == :immutable_field)
           )
  end

  test "update_client/2 preserves redirect validation discipline" do
    assert {:error, errors} =
             Clients.update_client("admin-client", %{
               redirect_uris: ["https://*.example.com/callback"]
             })

    assert Enum.any?(errors, &(&1.field == :redirect_uris and &1.reason == :invalid_redirect_uri))
  end

  test "update_client/2 accepts only inherit, required, and optional for par_policy" do
    assert {:ok, %Client{} = client} =
             Clients.update_client("admin-client", %{
               par_policy: "required"
             })

    assert client.par_policy == :required

    assert {:ok, %Client{} = fetched_client} = Repository.fetch_client_by_id("admin-client")
    assert fetched_client.par_policy == :required

    assert {:ok, %Client{} = optional_client} =
             Clients.update_client("admin-client", %{
               par_policy: :optional
             })

    assert optional_client.par_policy == :optional

    assert {:ok, %Client{} = inherited_client} =
             Clients.update_client("admin-client", %{
               par_policy: :inherit
             })

    assert inherited_client.par_policy == :inherit

    assert {:error, [%{field: :par_policy, reason: :invalid_par_policy, detail: "strict"}]} =
             Clients.update_client("admin-client", %{
               par_policy: "strict"
             })
  end

  test "rotate_client_secret/2 returns a plaintext secret once, emits telemetry, and appends operator audit" do
    assert {:ok, %{client: %Client{} = client, client_secret: secret}} =
             Clients.rotate_client_secret("admin-client", %{
               rotated_at: DateTime.utc_now(),
               actor: %{type: :operator, id: "ops-rotate", display: "Rotate User"}
             })

    assert is_binary(secret)
    refute secret == client.client_secret_hash
    assert client.last_secret_rotated_at

    assert {:ok, %Client{} = stored_client} = Repository.fetch_client_by_id("admin-client")
    assert stored_client.client_secret_hash == client.client_secret_hash
    refute stored_client.client_secret_hash == secret

    assert_received {:telemetry_event, [:lockspire, :client_secret_rotated],
                     %{client_id: "admin-client", actor_id: "ops-rotate"}}

    assert %AuditEventRecord{} = audit = latest_audit!("client_secret_rotated")
    assert audit.resource_id == "admin-client"
    assert audit.actor_id == "ops-rotate"
    assert audit.reason_code == "client_secret_rotated"
  end

  test "disable_client/2 and enable_client/2 expose queryable lifecycle state with operator evidence" do
    assert {:ok, %Client{} = disabled_client} =
             Clients.disable_client("admin-client", %{
               disabled_by: "ops@example.com",
               actor: %{type: :operator, id: "ops-disable", display: "Disable User"}
             })

    refute disabled_client.active
    assert disabled_client.disabled_by == "ops@example.com"
    assert disabled_client.disabled_at

    assert {:ok, disabled_clients} = Clients.list_clients(active: false)
    assert Enum.any?(disabled_clients, &(&1.client_id == "admin-client"))

    assert {:ok, %Client{} = enabled_client} = Clients.enable_client("admin-client")
    assert enabled_client.active
    assert is_nil(enabled_client.disabled_at)
    assert is_nil(enabled_client.disabled_by)

    assert_received {:telemetry_event, [:lockspire, :client_disabled],
                     %{client_id: "admin-client", actor_id: "ops-disable"}}

    assert %AuditEventRecord{} = audit = latest_audit!("client_disabled")
    assert audit.resource_id == "admin-client"
    assert audit.actor_id == "ops-disable"
    assert audit.metadata["disabled_by"] == "ops@example.com"
  end

  def handle_event(event, _measurements, metadata, pid) do
    send(pid, {:telemetry_event, event, metadata})
  end

  defp attach_events(pid) do
    handler_id = "admin-clients-test-#{System.unique_integer([:positive])}"

    :ok =
      :telemetry.attach_many(
        handler_id,
        [
          [:lockspire, :client_created],
          [:lockspire, :audit, :client_created],
          [:lockspire, :client_secret_rotated],
          [:lockspire, :audit, :client_secret_rotated],
          [:lockspire, :client_disabled],
          [:lockspire, :audit, :client_disabled]
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
