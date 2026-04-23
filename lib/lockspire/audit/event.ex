defmodule Lockspire.Audit.Event do
  @moduledoc """
  Normalized durable audit event payload for append-only incident evidence.
  """

  @enforce_keys [:action, :outcome, :resource_type, :resource_id]
  defstruct [
    :id,
    :action,
    :outcome,
    :reason_code,
    :actor_type,
    :actor_id,
    :actor_display,
    :resource_type,
    :resource_id,
    metadata: %{},
    inserted_at: nil,
    updated_at: nil
  ]

  @type t :: %__MODULE__{
          id: integer() | nil,
          action: String.t(),
          outcome: String.t(),
          reason_code: String.t() | nil,
          actor_type: String.t() | nil,
          actor_id: String.t() | nil,
          actor_display: String.t() | nil,
          resource_type: String.t(),
          resource_id: String.t(),
          metadata: map(),
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  @spec normalize(t() | map()) :: t()
  def normalize(%__MODULE__{} = event) do
    %__MODULE__{
      event
      | action: normalize_optional_value(event.action),
        outcome: normalize_optional_value(event.outcome),
        reason_code: normalize_optional_value(event.reason_code),
        actor_type: normalize_optional_value(event.actor_type),
        actor_id: normalize_optional_value(event.actor_id),
        actor_display: normalize_optional_value(event.actor_display),
        resource_type: normalize_optional_value(event.resource_type),
        resource_id: normalize_optional_value(event.resource_id),
        metadata: compact_metadata(event.metadata)
    }
  end

  def normalize(attrs) when is_map(attrs) do
    actor = Map.get(attrs, :actor) || Map.get(attrs, "actor") || %{}
    resource = Map.get(attrs, :resource) || Map.get(attrs, "resource") || %{}

    %__MODULE__{
      id: Map.get(attrs, :id) || Map.get(attrs, "id"),
      action: attrs |> get_value(:action) |> normalize_required_value(),
      outcome: attrs |> get_value(:outcome) |> normalize_required_value(),
      reason_code: attrs |> get_value(:reason_code) |> normalize_optional_value(),
      actor_type: actor |> get_value(:type) |> normalize_optional_value(),
      actor_id: actor |> get_value(:id) |> normalize_optional_value(),
      actor_display: actor |> get_value(:display) |> normalize_optional_value(),
      resource_type: resource |> get_value(:type) |> normalize_required_value(),
      resource_id: resource |> get_value(:id) |> normalize_required_value(),
      metadata:
        attrs
        |> get_value(:metadata, %{})
        |> compact_metadata(),
      inserted_at: Map.get(attrs, :inserted_at) || Map.get(attrs, "inserted_at"),
      updated_at: Map.get(attrs, :updated_at) || Map.get(attrs, "updated_at")
    }
  end

  defp get_value(map, key, default \\ nil) when is_map(map) do
    Map.get(map, key, Map.get(map, Atom.to_string(key), default))
  end

  defp normalize_required_value(value) do
    value
    |> normalize_optional_value()
    |> case do
      nil -> raise ArgumentError, "audit event field is required"
      normalized -> normalized
    end
  end

  defp normalize_optional_value(nil), do: nil
  defp normalize_optional_value(""), do: nil
  defp normalize_optional_value(value) when is_atom(value), do: Atom.to_string(value)
  defp normalize_optional_value(value) when is_binary(value), do: value
  defp normalize_optional_value(value), do: to_string(value)

  defp compact_metadata(metadata) when is_map(metadata) do
    metadata
    |> Enum.reduce(%{}, fn {key, value}, acc ->
      case compact_metadata_value(value) do
        :drop -> acc
        compacted -> Map.put(acc, normalize_metadata_key(key), compacted)
      end
    end)
  end

  defp compact_metadata(_metadata), do: %{}

  defp compact_metadata_value(nil), do: :drop
  defp compact_metadata_value(%DateTime{} = value), do: DateTime.to_iso8601(value)
  defp compact_metadata_value(%NaiveDateTime{} = value), do: NaiveDateTime.to_iso8601(value)
  defp compact_metadata_value(%Date{} = value), do: Date.to_iso8601(value)
  defp compact_metadata_value(%Time{} = value), do: Time.to_iso8601(value)
  defp compact_metadata_value(%_{} = value), do: inspect(value)
  defp compact_metadata_value(%{} = value) do
    case compact_metadata(value) do
      map when map == %{} -> :drop
      map -> map
    end
  end

  defp compact_metadata_value(value) when is_list(value) do
    compacted =
      value
      |> Enum.map(&compact_metadata_value/1)
      |> Enum.reject(&(&1 == :drop))

    if compacted == [], do: :drop, else: compacted
  end

  defp compact_metadata_value(value), do: value

  defp normalize_metadata_key(key) when is_atom(key), do: Atom.to_string(key)
  defp normalize_metadata_key(key) when is_binary(key), do: key
  defp normalize_metadata_key(key), do: to_string(key)
end
