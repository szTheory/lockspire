defmodule Lockspire.ClientLifecycleTest do
  use Lockspire.DataCase, async: false

  alias Lockspire.ClientLifecycle
  alias Lockspire.Domain.Client
  alias Lockspire.Storage.Ecto.AuditEventRecord

  import Ecto.Query

  setup_all do
    Application.put_env(:lockspire, :repo, Lockspire.TestRepo)
    start_supervised!(Lockspire.TestRepo)
    Ecto.Adapters.SQL.Sandbox.mode(Lockspire.TestRepo, :manual)
    :ok
  end

  test "DCR creation persists the client and its DCR audit attribution together" do
    client_id = "lifecycle-dcr-#{System.unique_integer([:positive])}"
    actor_id = "iat-#{client_id}"

    client = %Client{
      client_id: client_id,
      client_type: :public,
      redirect_uris: ["https://client.example.test/callback"],
      allowed_scopes: [],
      allowed_grant_types: ["authorization_code"],
      allowed_response_types: ["code"],
      token_endpoint_auth_method: :none,
      pkce_required: true,
      subject_type: :public,
      active: true
    }

    assert {:ok, persisted} =
             ClientLifecycle.create_dcr(%{
               client: client,
               actor: %{type: :dcr, id: actor_id}
             })

    assert persisted.client_id == client_id

    assert %AuditEventRecord{
             action: "dcr_client_created",
             actor_type: "dcr",
             actor_id: ^actor_id,
             resource_type: "client",
             resource_id: ^client_id,
             metadata: %{"client_id" => ^client_id, "provenance" => "operator"}
           } =
             Lockspire.TestRepo.one!(
               from(audit in AuditEventRecord,
                 where: audit.action == "dcr_client_created" and audit.resource_id == ^client_id
               )
             )
  end

  test "operator and RAT lifecycle writes preserve persistence and audit atomicity" do
    client_id = "lifecycle-operator-#{System.unique_integer([:positive])}"

    client = %Client{
      client_id: client_id,
      client_type: :confidential,
      client_secret_hash: "old-secret-hash",
      redirect_uris: ["https://client.example.test/callback"],
      allowed_scopes: [],
      allowed_grant_types: ["authorization_code"],
      allowed_response_types: ["code"],
      token_endpoint_auth_method: :client_secret_basic,
      pkce_required: true,
      subject_type: :public,
      active: true
    }

    assert {:ok, persisted} = ClientLifecycle.persist_direct(client)
    assert {:ok, updated} = ClientLifecycle.update_operator(persisted, %{name: "Updated"})
    assert updated.name == "Updated"

    rotated_at = DateTime.utc_now() |> DateTime.truncate(:microsecond)

    secret_material = %{
      client_secret_hash: "new-secret-hash",
      client_secret_jwt_verifier_encrypted: "encrypted-secret"
    }

    assert {:ok, rotated} =
             ClientLifecycle.rotate_operator_secret(
               updated,
               secret_material,
               rotated_at,
               audit_event(:client_secret_rotated, updated, %{rotated_at: rotated_at})
             )

    assert rotated.client_secret_hash == "new-secret-hash"
    assert rotated.last_secret_rotated_at == rotated_at

    disabled_at = DateTime.utc_now() |> DateTime.truncate(:microsecond)

    assert {:ok, disabled} =
             ClientLifecycle.disable_operator(
               rotated,
               disabled_at,
               "ops@example.test",
               audit_event(:client_disabled, rotated, %{disabled_by: "ops@example.test"})
             )

    refute disabled.active
    assert {:ok, enabled} = ClientLifecycle.enable_operator(disabled)
    assert enabled.active
    assert is_nil(enabled.disabled_at)

    assert {:ok, rat_rotated} =
             ClientLifecycle.rotate_registration_access_token(
               enabled,
               "new-rat-hash",
               audit_event(:dcr_management_rat_rotated, enabled, %{})
             )

    assert rat_rotated.registration_access_token_hash == "new-rat-hash"

    for action <- ["client_secret_rotated", "client_disabled", "dcr_management_rat_rotated"] do
      assert %AuditEventRecord{resource_id: ^client_id} =
               Lockspire.TestRepo.one!(
                 from(audit in AuditEventRecord,
                   where: audit.action == ^action and audit.resource_id == ^client_id
                 )
               )
    end
  end

  defp audit_event(action, %Client{} = client, metadata) do
    %{
      action: action,
      outcome: :succeeded,
      reason_code: action,
      actor: %{type: :operator, id: "lifecycle-test"},
      resource: %{type: :client, id: client.client_id},
      metadata: metadata
    }
  end
end
