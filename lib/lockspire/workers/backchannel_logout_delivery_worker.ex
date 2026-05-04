defmodule Lockspire.Workers.BackchannelLogoutDeliveryWorker do
  @moduledoc """
  Delivers back-channel logout notifications from persisted delivery snapshots.
  """

  use Oban.Worker,
    queue: :logout_backchannel,
    max_attempts: 5,
    unique: [
      period: 300,
      fields: [:args],
      keys: [:logout_delivery_id],
      states: [:available, :scheduled, :executing, :retryable]
    ]

  import Ecto.Query

  alias Ecto.Changeset
  alias Lockspire.Audit.Event
  alias Lockspire.Config
  alias Lockspire.Observability
  alias Lockspire.Protocol.LogoutToken
  alias Lockspire.Storage.Ecto.LogoutDeliveryRecord
  alias Lockspire.Storage.Ecto.LogoutEventRecord
  alias Lockspire.Storage.Ecto.Repository

  @type perform_result :: :ok | {:error, term()} | {:discard, term()}

  @impl Oban.Worker
  @spec perform(Oban.Job.t()) :: perform_result()
  def perform(%Oban.Job{args: %{"logout_delivery_id" => logout_delivery_id}})
      when is_integer(logout_delivery_id) do
    with {:ok, delivery_record} <- fetch_delivery(logout_delivery_id),
         :ok <- ensure_backchannel_delivery(delivery_record),
         attempted_at = DateTime.utc_now(),
         {:ok, attempted_record} <- mark_attempted(delivery_record, attempted_at) do
      emit_lifecycle(:delivery_attempted, attempted_record, %{attempt_count: attempted_record.attempt_count})

      with {:ok, signing_key} <- fetch_signing_key() do
      case LogoutToken.sign(%{
             issuer: Config.issuer!(),
             logout_event: LogoutEventRecord.to_domain(attempted_record.logout_event),
             delivery: LogoutDeliveryRecord.to_domain(attempted_record),
             issued_at: attempted_at,
             signing_key: signing_key
           }) do
        {:ok, logout_token, logout_token_jti} ->
          case deliver_logout_token(attempted_record.target_uri, logout_token) do
            {:ok, response} ->
              finalize_response(
                attempted_record,
                attempted_at,
                logout_token_jti,
                logout_token,
                response
              )

            {:error, %Req.TransportError{reason: reason}} ->
              mark_retryable(
                attempted_record,
                attempted_at,
                nil,
                "request_failed:#{reason}"
              )

              emit_lifecycle(:delivery_failed, attempted_record, %{
                failure_reason: "request_failed:#{reason}",
                logout_token: logout_token
              })

              {:error, {:request_failed, reason}}
          end

        {:error, :invalid_signing_key} ->
          mark_discarded(attempted_record, attempted_at, nil, "invalid_signing_key")
          emit_lifecycle(:delivery_discarded, attempted_record, %{failure_reason: "invalid_signing_key"})
          {:discard, :invalid_signing_key}
      end
      else
        {:error, :missing_signing_key} ->
          mark_discarded(attempted_record, attempted_at, nil, "missing_signing_key")
          emit_lifecycle(:delivery_discarded, attempted_record, %{failure_reason: "missing_signing_key"})
          {:discard, :missing_signing_key}
      end
    else
      {:error, :not_found} ->
        {:discard, :logout_delivery_not_found}

      {:error, :invalid_channel} ->
        {:discard, :invalid_channel}
    end
  end

  def perform(%Oban.Job{}), do: {:discard, :invalid_args}

  defp fetch_delivery(logout_delivery_id) do
    LogoutDeliveryRecord
    |> preload(:logout_event)
    |> where([delivery], delivery.id == ^logout_delivery_id)
    |> repo().one()
    |> case do
      nil -> {:error, :not_found}
      %LogoutDeliveryRecord{} = delivery_record -> {:ok, delivery_record}
    end
  end

  defp ensure_backchannel_delivery(%LogoutDeliveryRecord{channel: :backchannel}), do: :ok
  defp ensure_backchannel_delivery(_delivery_record), do: {:error, :invalid_channel}

  defp fetch_signing_key do
    case Repository.fetch_active_signing_key() do
      {:ok, nil} -> {:error, :missing_signing_key}
      {:ok, signing_key} -> {:ok, signing_key}
      {:error, _reason} -> {:error, :missing_signing_key}
    end
  end

  defp mark_attempted(%LogoutDeliveryRecord{} = delivery_record, attempted_at) do
    delivery_record
    |> Changeset.change(
      status: :attempted,
      attempt_count: delivery_record.attempt_count + 1,
      last_attempted_at: attempted_at,
      failure_reason: nil
    )
    |> repo().update()
  end

  defp deliver_logout_token(target_uri, logout_token) do
    request_opts =
      Application.get_env(:lockspire, :backchannel_logout_req, [])
      |> Keyword.put_new(:retry, false)
      |> Keyword.put(:url, target_uri)
      |> Keyword.put(:form, [logout_token: logout_token])

    case Req.post(request_opts) do
      {:ok, response} -> {:ok, response}
      {:error, %Req.TransportError{} = error} -> {:error, error}
      {:error, error} -> {:error, %Req.TransportError{reason: inspect(error)}}
    end
  end

  defp finalize_response(
         %LogoutDeliveryRecord{} = delivery_record,
         attempted_at,
         logout_token_jti,
         logout_token,
         response
       ) do
    cond do
      response.status in 200..299 ->
        mark_succeeded(delivery_record, attempted_at, logout_token_jti, response.status)
        emit_lifecycle(:delivery_succeeded, delivery_record, %{
          http_status: response.status,
          logout_token: logout_token,
          response_body: response.body,
          logout_token_jti: logout_token_jti
        })
        :ok

      response.status in 400..499 ->
        mark_discarded(delivery_record, attempted_at, response.status, "http_error:#{response.status}")
        emit_lifecycle(:delivery_discarded, delivery_record, %{
          http_status: response.status,
          logout_token: logout_token,
          response_body: response.body,
          failure_reason: "http_error:#{response.status}"
        })
        {:discard, {:http_error, response.status}}

      true ->
        mark_retryable(delivery_record, attempted_at, response.status, "http_error:#{response.status}")
        emit_lifecycle(:delivery_failed, delivery_record, %{
          http_status: response.status,
          logout_token: logout_token,
          response_body: response.body,
          failure_reason: "http_error:#{response.status}"
        })
        {:error, {:http_error, response.status}}
    end
  end

  defp mark_succeeded(%LogoutDeliveryRecord{} = delivery_record, attempted_at, logout_token_jti, http_status) do
    delivery_record
    |> Changeset.change(
      status: :succeeded,
      http_status: http_status,
      delivered_at: attempted_at,
      finalized_at: attempted_at,
      logout_token_jti: logout_token_jti,
      failure_reason: nil
    )
    |> repo().update!()
  end

  defp mark_retryable(%LogoutDeliveryRecord{} = delivery_record, attempted_at, http_status, failure_reason) do
    delivery_record
    |> Changeset.change(
      status: :retryable,
      http_status: http_status,
      finalized_at: nil,
      logout_token_jti: delivery_record.logout_token_jti,
      failure_reason: failure_reason
    )
    |> maybe_put_attempted_at(attempted_at)
    |> repo().update!()
  end

  defp mark_discarded(%LogoutDeliveryRecord{} = delivery_record, attempted_at, http_status, failure_reason) do
    delivery_record
    |> Changeset.change(
      status: :discarded,
      http_status: http_status,
      finalized_at: attempted_at,
      failure_reason: failure_reason
    )
    |> maybe_put_attempted_at(attempted_at)
    |> repo().update!()
  end

  defp maybe_put_attempted_at(changeset, attempted_at) do
    Changeset.put_change(changeset, :last_attempted_at, attempted_at)
  end

  defp repo do
    Config.repo!()
  end

  defp emit_lifecycle(stage, %LogoutDeliveryRecord{} = delivery_record, metadata) when is_map(metadata) do
    event_metadata =
      metadata
      |> Map.merge(%{
        channel: delivery_record.channel,
        client_id: delivery_record.client_id,
        logout_delivery_id: delivery_record.id,
        logout_event_id: delivery_record.logout_event_id,
        session_required: delivery_record.session_required,
        target_uri: delivery_record.target_uri
      })

    Observability.emit_logout(stage, %{}, event_metadata)
    _ = Repository.append_audit_event(Event.logout_lifecycle(stage, event_metadata))
    :ok
  end
end
