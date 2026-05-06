defmodule Lockspire.RAR.DispatcherTest do
  use ExUnit.Case, async: false

  alias Lockspire.RAR.Dispatcher

  setup do
    Application.put_env(:lockspire, :rar_validators, %{
      "payment_initiation" => Lockspire.Test.Rar.PassthroughValidator,
      "normalize_me" => Lockspire.Test.Rar.NormalizingValidator,
      "changeset_error" => Lockspire.Test.Rar.ChangesetErrorValidator,
      "string_error" => Lockspire.Test.Rar.StringErrorValidator,
      "raising" => Lockspire.Test.Rar.RaisingValidator
    })

    handler_id = "rar-dispatcher-test-#{System.unique_integer([:positive])}"

    :ok =
      :telemetry.attach_many(
        handler_id,
        [
          [:lockspire, :rar, :validation, :start],
          [:lockspire, :rar, :validation, :stop],
          [:lockspire, :rar, :validation, :exception],
          [:lockspire, :rar, :unknown_type],
          [:lockspire, :audit, :rar, :unknown_type]
        ],
        &__MODULE__.handle_event/4,
        self()
      )

    on_exit(fn ->
      Application.delete_env(:lockspire, :rar_validators)
      :telemetry.detach(handler_id)
    end)

    :ok
  end

  test "dispatches validator output" do
    details = [%{"type" => "normalize_me", "actions" => ["read"], "ignored" => true}]

    assert {:ok, [%{"type" => "normalize_me", "actions" => ["read"], "validated" => true}]} =
             Dispatcher.dispatch_each(details, %{client_id: "client-123"})

    assert_received {:telemetry_event, [:lockspire, :rar, :validation, :start], _measurements,
                     %{client_id: "client-123", type: "normalize_me"}}

    assert_received {:telemetry_event, [:lockspire, :rar, :validation, :stop], measurements,
                     %{client_id: "client-123", outcome: :ok, type: "normalize_me"}}

    assert is_integer(measurements.duration)
  end

  test "short-circuits already validated details" do
    details = [%{"type" => "raising"}]

    assert {:ok, ^details} =
             Dispatcher.dispatch_each(details, %{client_id: "client-123", pre_validated?: true})

    refute_received {:telemetry_event, [:lockspire, :rar, :validation, :start], _, _}
  end

  test "rejects unknown types and emits telemetry" do
    assert {:error,
            {"authorization_details contains an unsupported type",
             :unknown_authorization_details_type}} =
             Dispatcher.dispatch_each([%{"type" => "missing"}], %{client_id: "client-123"})

    assert_received {:telemetry_event, [:lockspire, :rar, :unknown_type], %{count: 1},
                     %{client_id: "client-123", type: "missing"}}

    assert_received {:telemetry_event, [:lockspire, :audit, :rar, :unknown_type], %{count: 1},
                     %{client_id: "client-123", type: "missing"}}
  end

  test "formats changeset errors" do
    assert {:error, {description, :invalid_authorization_details}} =
             Dispatcher.dispatch_each(
               [%{"type" => "changeset_error", "amount" => 0}],
               %{client_id: "client-123"}
             )

    assert description =~ "amount"
  end

  test "passes through string errors" do
    assert {:error, {"validation failed for test", :invalid_authorization_details}} =
             Dispatcher.dispatch_each([%{"type" => "string_error"}], %{client_id: "client-123"})
  end

  test "emits exception telemetry when validator raises" do
    assert_raise RuntimeError, "validator exploded", fn ->
      Dispatcher.dispatch_each([%{"type" => "raising"}], %{client_id: "client-123"})
    end

    assert_received {:telemetry_event, [:lockspire, :rar, :validation, :exception], measurements,
                     metadata}

    assert is_integer(measurements.duration)
    assert metadata.client_id == "client-123"
    assert metadata.type == "raising"
  end

  def handle_event(event, measurements, metadata, pid) do
    send(pid, {:telemetry_event, event, measurements, metadata})
  end
end
