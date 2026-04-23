defmodule Lockspire.Audit.AuditWriterTest do
  use ExUnit.Case, async: false

  @moduletag :integration

  alias Lockspire.Audit.Event
  alias Lockspire.Storage.Ecto.AuditEventRecord

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
end
