defmodule Lockspire.TestSupport.TelemetryCapture do
  @moduledoc false

  @doc false
  def attach(event, test_pid \\ self()) when is_list(event) and is_pid(test_pid) do
    handler_id = handler_id()
    :ok = :telemetry.attach(handler_id, event, &__MODULE__.handle_event/4, test_pid)
    register_detach(handler_id)
    handler_id
  end

  @doc false
  def attach_many(events, test_pid \\ self()) when is_list(events) and is_pid(test_pid) do
    handler_id = handler_id()
    :ok = :telemetry.attach_many(handler_id, events, &__MODULE__.handle_event/4, test_pid)
    register_detach(handler_id)
    handler_id
  end

  @doc false
  def handle_event(event, measurements, metadata, test_pid) do
    send(test_pid, {:telemetry_event, event, measurements, metadata})
  end

  defp handler_id do
    {__MODULE__, System.unique_integer([:positive, :monotonic])}
  end

  defp register_detach(handler_id) do
    ExUnit.Callbacks.on_exit({__MODULE__, handler_id}, fn ->
      :ok = :telemetry.detach(handler_id)
    end)
  end
end
