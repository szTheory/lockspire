defmodule Lockspire.Storage.Ecto.AuditEventRecord do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset

  alias Lockspire.Audit.Event

  @timestamps_opts [type: :utc_datetime_usec]

  schema "lockspire_audit_events" do
    field(:action, :string)
    field(:outcome, :string)
    field(:reason_code, :string)
    field(:actor_type, :string)
    field(:actor_id, :string)
    field(:actor_display, :string)
    field(:resource_type, :string)
    field(:resource_id, :string)
    field(:metadata, :map, default: %{})

    timestamps()
  end

  def changeset(record, %Event{} = event) do
    event = Event.normalize(event)

    record
    |> cast(Map.from_struct(event), [
      :action,
      :outcome,
      :reason_code,
      :actor_type,
      :actor_id,
      :actor_display,
      :resource_type,
      :resource_id,
      :metadata
    ])
    |> validate_required([
      :action,
      :outcome,
      :resource_type,
      :resource_id
    ])
  end

  def to_domain(%__MODULE__{} = record) do
    Event.normalize(%{
      id: record.id,
      action: record.action,
      outcome: record.outcome,
      reason_code: record.reason_code,
      actor: %{
        type: record.actor_type,
        id: record.actor_id,
        display: record.actor_display
      },
      resource: %{
        type: record.resource_type,
        id: record.resource_id
      },
      metadata: record.metadata || %{},
      inserted_at: record.inserted_at,
      updated_at: record.updated_at
    })
  end
end
