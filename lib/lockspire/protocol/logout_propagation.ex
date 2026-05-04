defmodule Lockspire.Protocol.LogoutPropagation do
  @moduledoc """
  Owns `/end_session/complete` logout propagation orchestration.
  """

  alias Lockspire.Audit.Event
  alias Lockspire.Config
  alias Lockspire.Domain.LogoutDelivery
  alias Lockspire.Domain.LogoutEvent
  alias Lockspire.Observability
  alias Lockspire.Storage.Ecto.Repository
  alias Lockspire.Workers.BackchannelLogoutDeliveryWorker

  defmodule Result do
    @moduledoc false

    @type t :: %__MODULE__{
            event: LogoutEvent.t(),
            deliveries: [LogoutDelivery.t()],
            frontchannel_deliveries: [LogoutDelivery.t()],
            post_logout_redirect_uri: String.t() | nil,
            state: String.t() | nil,
            frontchannel_continue_to: String.t() | nil
          }

    defstruct [
      :event,
      :post_logout_redirect_uri,
      :state,
      :frontchannel_continue_to,
      deliveries: [],
      frontchannel_deliveries: []
    ]
  end

  @type complete_result :: {:ok, struct()} | {:error, term()}

  @spec complete(map()) :: complete_result()
  def complete(attrs) when is_map(attrs) do
    event = build_logout_event(attrs)

    with {:ok, transaction_result} <- complete_transaction(event),
         :ok <- emit_post_commit_lifecycle(transaction_result) do
      {:ok, build_result(transaction_result, attrs)}
    end
  end

  defp complete_transaction(%LogoutEvent{} = event) do
    Repository.transact(fn ->
      with {:ok, %{event: stored_event, deliveries: deliveries, inserted?: inserted?}} <-
             Repository.persist_logout_propagation(event, transact?: false),
           {:ok, enqueued_deliveries, enqueued_metadata} <-
             maybe_enqueue_backchannel_deliveries(stored_event, deliveries, inserted?),
           :ok <- maybe_append_requested_audit(stored_event, inserted?),
           :ok <- maybe_append_enqueued_audits(enqueued_metadata, inserted?),
           :ok <- maybe_revoke_sid(event.sid, inserted?) do
        %{
          event: stored_event,
          deliveries: enqueued_deliveries,
          inserted?: inserted?,
          requested_metadata: %{logout_event_id: stored_event.id},
          enqueued_metadata: enqueued_metadata
        }
      else
        {:error, reason} -> Config.repo!().rollback(reason)
      end
    end)
  end

  defp maybe_enqueue_backchannel_deliveries(_event, deliveries, false) do
    {:ok, deliveries, []}
  end

  defp maybe_enqueue_backchannel_deliveries(%LogoutEvent{id: logout_event_id}, deliveries, true) do
    deliveries
    |> Enum.reduce_while({[], []}, fn delivery, {acc_deliveries, acc_metadata} ->
      case maybe_enqueue_backchannel_delivery(delivery, logout_event_id) do
        {:ok, updated_delivery, metadata} ->
          {:cont, {acc_deliveries ++ [updated_delivery], acc_metadata ++ List.wrap(metadata)}}

        {:error, reason} ->
          {:halt, {:error, reason}}
      end
    end)
    |> case do
      {:error, reason} -> {:error, reason}
      {updated_deliveries, metadata} -> {:ok, updated_deliveries, metadata}
    end
  end

  defp maybe_enqueue_backchannel_delivery(
         %LogoutDelivery{channel: :backchannel} = delivery,
         logout_event_id
       ) do
    case insert_backchannel_job(delivery.id) do
      {:ok, %Oban.Job{id: job_id}} when is_integer(job_id) ->
        case Repository.mark_logout_delivery_enqueued(delivery.id, job_id) do
          {:ok, updated_delivery} ->
            metadata = %{
              channel: updated_delivery.channel,
              client_id: updated_delivery.client_id,
              logout_delivery_id: updated_delivery.id,
              logout_event_id: logout_event_id,
              session_required: updated_delivery.session_required,
              target_uri: updated_delivery.target_uri
            }

            {:ok, updated_delivery, metadata}

          {:error, reason} ->
            {:error, reason}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp maybe_enqueue_backchannel_delivery(%LogoutDelivery{} = delivery, _logout_event_id) do
    {:ok, delivery, nil}
  end

  defp maybe_append_requested_audit(_stored_event, false), do: :ok

  defp maybe_append_requested_audit(%LogoutEvent{id: logout_event_id}, true) do
    Event.logout_lifecycle(:requested, %{logout_event_id: logout_event_id})
    |> append_audit_event()
  end

  defp maybe_append_enqueued_audits(_metadata, false), do: :ok

  defp maybe_append_enqueued_audits(metadata, true) when is_list(metadata) do
    Enum.reduce_while(metadata, :ok, fn entry, :ok ->
      case Event.logout_lifecycle(:delivery_enqueued, entry) |> append_audit_event() do
        :ok -> {:cont, :ok}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end

  defp maybe_revoke_sid(_sid, false), do: :ok
  defp maybe_revoke_sid(nil, true), do: :ok

  defp maybe_revoke_sid(sid, true) when is_binary(sid) do
    case Repository.revoke_by_sid(sid) do
      {:ok, _count} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  defp emit_post_commit_lifecycle(%{inserted?: false}), do: :ok

  defp emit_post_commit_lifecycle(%{
         inserted?: true,
         requested_metadata: requested_metadata,
         enqueued_metadata: enqueued_metadata
       }) do
    Observability.emit_logout(:requested, %{}, requested_metadata)

    Enum.each(enqueued_metadata, fn metadata ->
      Observability.emit_logout(:delivery_enqueued, %{}, metadata)
    end)

    :ok
  end

  defp build_result(%{event: event, deliveries: deliveries}, attrs) do
    %Result{
      event: event,
      deliveries: deliveries,
      frontchannel_deliveries: Enum.filter(deliveries, &(&1.channel == :frontchannel)),
      post_logout_redirect_uri:
        normalize_optional_string(
          attrs[:post_logout_redirect_uri] || attrs["post_logout_redirect_uri"]
        ),
      state: normalize_optional_string(attrs[:state] || attrs["state"]),
      frontchannel_continue_to: event.frontchannel_continue_to
    }
  end

  defp build_logout_event(attrs) do
    %LogoutEvent{
      event_id:
        normalize_optional_string(attrs[:event_id] || attrs["event_id"]) || Ecto.UUID.generate(),
      sid: normalize_optional_string(attrs[:sid] || attrs["sid"]),
      account_id: normalize_optional_string(attrs[:account_id] || attrs["account_id"]),
      subject: normalize_optional_string(attrs[:subject] || attrs["subject"]),
      post_logout_redirect_uri:
        normalize_optional_string(
          attrs[:post_logout_redirect_uri] || attrs["post_logout_redirect_uri"]
        ),
      frontchannel_continue_to:
        normalize_optional_string(
          attrs[:frontchannel_continue_to] || attrs["frontchannel_continue_to"]
        )
    }
  end

  defp append_audit_event(%Event{} = audit_event) do
    case Repository.append_audit_event(audit_event) do
      {:ok, _event} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  defp normalize_optional_string(value) when is_binary(value) do
    case String.trim(value) do
      "" -> nil
      normalized -> normalized
    end
  end

  defp normalize_optional_string(_value), do: nil

  defp insert_backchannel_job(logout_delivery_id) when is_integer(logout_delivery_id) do
    changeset = BackchannelLogoutDeliveryWorker.new(%{logout_delivery_id: logout_delivery_id})

    Config.repo!().insert(changeset)
  end
end
