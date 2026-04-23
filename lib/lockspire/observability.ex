defmodule Lockspire.Observability do
  @moduledoc """
  Shared audit and telemetry emission helpers.
  """

  @type event_name :: atom()
  @type measurements :: map()
  @type metadata :: map()

  @audit_prefix [:lockspire, :audit]
  @telemetry_prefix [:lockspire]

  @spec emit(event_name(), measurements(), metadata()) :: :ok
  def emit(event_name, measurements \\ %{}, metadata \\ %{}) when is_atom(event_name) do
    redacted_metadata = redact(metadata)
    normalized_measurements = Map.put_new(measurements, :count, 1)

    :telemetry.execute(@audit_prefix ++ [event_name], normalized_measurements, redacted_metadata)

    :telemetry.execute(
      @telemetry_prefix ++ [event_name],
      normalized_measurements,
      redacted_metadata
    )

    :ok
  end

  @spec redact(metadata()) :: metadata()
  def redact(metadata) when is_map(metadata) do
    Map.drop(metadata, [
      :access_token,
      :authorization,
      :authorization_header,
      :authorization_code,
      :client_secret,
      :client_secret_hash,
      :code,
      :code_challenge,
      :code_verifier,
      :state,
      :token_hash
    ])
  end
end
