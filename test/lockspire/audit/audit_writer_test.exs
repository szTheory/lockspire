defmodule Lockspire.Audit.AuditWriterTest do
  use ExUnit.Case, async: false

  @moduletag :integration

  alias Lockspire.Audit.Event
  alias Lockspire.Domain.Client
  alias Lockspire.Storage.Ecto.ClientRecord
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
  end

  test "normalizes actor identity and compacts metadata for durable audit events" do
    event =
      Event.normalize(%{
        action: :token_family_revoked,
        outcome: :succeeded,
        reason_code: :reuse_detected,
        actor: %{
          type: :operator,
          id: "ops_123",
          display: "Ops User"
        },
        resource: %{
          type: :token_family,
          id: "family_456"
        },
        metadata: %{
          "tenant_id" => "tenant_789",
          "count" => 2,
          "empty_map" => %{},
          "empty_list" => [],
          "nil_value" => nil
        }
      })

    assert %Event{} = event
    assert event.actor_type == "operator"
    assert event.actor_id == "ops_123"
    assert event.actor_display == "Ops User"
    assert event.resource_type == "token_family"
    assert event.resource_id == "family_456"
    assert event.action == "token_family_revoked"
    assert event.outcome == "succeeded"
    assert event.reason_code == "reuse_detected"
    assert event.metadata == %{"count" => 2, "tenant_id" => "tenant_789"}
  end

  test "stores action, outcome, reason, resource refs, and compact metadata without snapshots" do
    event =
      Event.normalize(%{
        action: "client_disabled",
        outcome: :succeeded,
        reason_code: "operator_request",
        actor: %{type: :system, id: "scheduler", display: "Scheduler"},
        resource: %{type: :client, id: "client_123"},
        metadata: %{
          changed_fields: ["active", "disabled_at"],
          before: nil,
          after: %{}
        }
      })

    assert {:ok, record} =
             %AuditEventRecord{}
             |> AuditEventRecord.changeset(event)
             |> Lockspire.TestRepo.insert()

    assert record.action == "client_disabled"
    assert record.outcome == "succeeded"
    assert record.reason_code == "operator_request"
    assert record.actor_type == "system"
    assert record.actor_id == "scheduler"
    assert record.actor_display == "Scheduler"
    assert record.resource_type == "client"
    assert record.resource_id == "client_123"
    assert record.metadata == %{"changed_fields" => ["active", "disabled_at"]}

    refute Map.has_key?(record.metadata, "before")
    refute Map.has_key?(record.metadata, "after")
    refute Map.has_key?(record, :snapshot)
    refute Map.has_key?(record, :before_state)
    refute Map.has_key?(record, :after_state)
  end

  test "repository transaction wrapper commits the durable mutation and audit row together" do
    client = %Client{
      client_id: "client_with_audit",
      client_secret_hash: "argon2id$hash",
      client_type: :confidential,
      redirect_uris: ["https://client.example.com/callback"],
      allowed_scopes: ["openid"],
      allowed_grant_types: ["authorization_code"],
      allowed_response_types: ["code"],
      token_endpoint_auth_method: :client_secret_basic,
      pkce_required: true,
      subject_type: :public,
      created_at: DateTime.utc_now()
    }

    audit_event = %{
      action: :client_created,
      outcome: :succeeded,
      actor: %{type: :operator, id: "ops_123", display: "Ops User"},
      resource: %{type: :client, id: client.client_id},
      metadata: %{channel: "test"}
    }

    assert {:ok, %ClientRecord{} = record} =
             Repository.transact_with_audit(audit_event, fn ->
               %ClientRecord{}
               |> ClientRecord.changeset(client)
               |> Lockspire.TestRepo.insert()
             end)

    assert record.client_id == client.client_id

    assert [%AuditEventRecord{} = stored_audit] = Lockspire.TestRepo.all(AuditEventRecord)
    assert stored_audit.action == "client_created"
    assert stored_audit.resource_id == client.client_id
  end
end
