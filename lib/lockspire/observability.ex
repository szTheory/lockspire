defmodule Lockspire.Observability do
  @moduledoc """
  Shared audit and telemetry emission helpers.
  """

  alias Lockspire.Diagnostics.RemoteJwks
  alias Lockspire.Redaction

  @type entity :: atom()
  @type action :: atom()
  @type measurements :: map()
  @type metadata :: map()

  @audit_prefix [:lockspire, :audit]
  @telemetry_prefix [:lockspire]
  @logout_lifecycle %{
    requested: :logout_requested,
    delivery_enqueued: :logout_delivery_enqueued,
    delivery_attempted: :logout_delivery_attempted,
    delivery_succeeded: :logout_delivery_succeeded,
    delivery_failed: :logout_delivery_failed,
    delivery_discarded: :logout_delivery_discarded
  }

  @spec emit(entity(), action(), measurements(), metadata()) :: :ok
  def emit(entity, action, measurements, metadata)
      when is_atom(entity) and is_atom(action) and is_map(measurements) and is_map(metadata) do
    redacted_metadata = redact(metadata)
    normalized_measurements = Map.put_new(measurements, :count, 1)

    :telemetry.execute(
      @audit_prefix ++ [entity, action],
      normalized_measurements,
      redacted_metadata
    )

    :telemetry.execute(
      @telemetry_prefix ++ [entity, action],
      normalized_measurements,
      redacted_metadata
    )

    :ok
  end

  @spec emit(action(), measurements(), metadata()) :: :ok
  def emit(event, measurements, metadata)
      when is_atom(event) and is_map(measurements) and is_map(metadata) do
    redacted_metadata = redact(metadata)
    normalized_measurements = Map.put_new(measurements, :count, 1)

    :telemetry.execute(
      @audit_prefix ++ [event],
      normalized_measurements,
      redacted_metadata
    )

    :telemetry.execute(
      @telemetry_prefix ++ [event],
      normalized_measurements,
      redacted_metadata
    )

    :ok
  end

  @spec emit_logout(atom(), measurements(), metadata()) :: :ok
  def emit_logout(stage, measurements \\ %{}, metadata \\ %{}) when is_atom(stage) do
    emit(logout_event_name!(stage), measurements, metadata)
  end

  @spec logout_event_name!(atom()) :: atom()
  def logout_event_name!(stage) when is_atom(stage) do
    Map.fetch!(@logout_lifecycle, stage)
  end

  @spec logout_lifecycle_events() :: [atom()]
  def logout_lifecycle_events do
    Map.values(@logout_lifecycle)
  end

  @spec redact(metadata()) :: metadata()
  def redact(metadata) when is_map(metadata) do
    Redaction.for_telemetry(metadata)
  end

  @spec remote_jwks_metadata(RemoteJwks.t() | nil) :: metadata()
  def remote_jwks_metadata(%RemoteJwks{} = incident), do: RemoteJwks.metadata(incident)
  def remote_jwks_metadata(_incident), do: %{}
end
