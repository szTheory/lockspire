defmodule Lockspire.Storage.Ecto.Repository.LogoutStore do
  @moduledoc false
  import Ecto.Query
  alias Lockspire.Domain.{LogoutDelivery, LogoutEvent}

  alias Lockspire.Storage.Ecto.{
    ClientRecord,
    LogoutDeliveryRecord,
    LogoutEventRecord,
    TokenRecord
  }

  alias Lockspire.Storage.Ecto.Repository.{Support, TransactionStore}

  def persist(repo, %LogoutEvent{} = event, opts \\ []) do
    fun = fn -> persist!(repo, event) end

    if Keyword.get(opts, :transact?, true),
      do: TransactionStore.transact(repo, fun),
      else: {:ok, fun.()}
  rescue
    error -> {:error, error}
  end

  def fetch_event(repo, id),
    do:
      LogoutEventRecord
      |> where([e], e.event_id == ^id)
      |> then(&Support.one(repo, &1))
      |> then(&{:ok, if(&1, do: LogoutEventRecord.to_domain(&1))})

  def list_all(repo),
    do:
      LogoutDeliveryRecord
      |> order_by(desc: :inserted_at)
      |> then(&Support.all(repo, &1))
      |> Enum.map(&LogoutDeliveryRecord.to_domain/1)
      |> then(&{:ok, &1})

  def list(repo, id),
    do:
      LogoutDeliveryRecord
      |> where([d], d.logout_event_id == ^id)
      |> order_by([d], asc: d.id)
      |> then(&Support.all(repo, &1))
      |> Enum.map(&LogoutDeliveryRecord.to_domain/1)
      |> then(&{:ok, &1})

  def enqueue(repo, id, job) do
    case LogoutDeliveryRecord
         |> where([d], d.id == ^id)
         |> lock("FOR UPDATE")
         |> then(&Support.one(repo, &1)) do
      nil ->
        {:error, :not_found}

      record ->
        record
        |> Ecto.Changeset.change(
          status: :enqueued,
          oban_job_id: job,
          updated_at: DateTime.utc_now()
        )
        |> then(&Support.update(repo, &1))
        |> map_delivery()
    end
  end

  defp persist!(repo, %LogoutEvent{} = event) do
    event = %LogoutEvent{
      event
      | event_id: event.event_id || Ecto.UUID.generate(),
        completed_at: event.completed_at || DateTime.utc_now()
    }

    case LogoutEventRecord
         |> where([e], e.event_id == ^event.event_id)
         |> lock("FOR UPDATE")
         |> then(&Support.one(repo, &1)) do
      existing when not is_nil(existing) ->
        %{
          event: LogoutEventRecord.to_domain(existing),
          deliveries: list!(repo, existing.id),
          inserted?: false
        }

      nil ->
        case %LogoutEventRecord{}
             |> LogoutEventRecord.changeset(event)
             |> then(&Support.insert(repo, &1)) do
          {:ok, stored} ->
            stored = LogoutEventRecord.to_domain(stored)

            deliveries =
              snapshot_clients(repo, event.sid)
              |> build(stored.id)
              |> Enum.map(fn d ->
                %LogoutDeliveryRecord{}
                |> LogoutDeliveryRecord.changeset(d)
                |> then(&Support.insert(repo, &1))
                |> unwrap(repo)
              end)

            %{event: stored, deliveries: deliveries, inserted?: true}

          {:error, changeset} ->
            TransactionStore.rollback(repo, changeset)
        end
    end
  end

  defp list!(repo, id) do
    {:ok, values} = list(repo, id)
    values
  end

  defp snapshot_clients(_repo, nil), do: []

  defp snapshot_clients(repo, sid) do
    ids =
      TokenRecord
      |> where(
        [t],
        t.sid == ^sid and t.token_type in [:access_token, :refresh_token] and is_nil(t.revoked_at)
      )
      |> select([t], t.client_id)
      |> distinct(true)
      |> then(&Support.all(repo, &1, sensitive: true))

    ClientRecord
    |> where([c], c.client_id in ^ids)
    |> where([c], not is_nil(c.backchannel_logout_uri) or not is_nil(c.frontchannel_logout_uri))
    |> order_by([c], asc: c.client_id)
    |> then(&Support.all(repo, &1))
  end

  defp build(records, event_id),
    do:
      Enum.flat_map(records, fn c ->
        Enum.reject(
          [
            delivery(
              c,
              event_id,
              :backchannel,
              c.backchannel_logout_uri,
              c.backchannel_logout_session_required
            ),
            delivery(
              c,
              event_id,
              :frontchannel,
              c.frontchannel_logout_uri,
              c.frontchannel_logout_session_required
            )
          ],
          &is_nil/1
        )
      end)

  defp delivery(_c, _id, _channel, nil, _required), do: nil

  defp delivery(c, id, channel, uri, required),
    do: %LogoutDelivery{
      delivery_id: Ecto.UUID.generate(),
      logout_event_id: id,
      client_id: c.client_id,
      channel: channel,
      target_uri: uri,
      session_required: required
    }

  defp unwrap({:ok, r}, _repo), do: LogoutDeliveryRecord.to_domain(r)
  defp unwrap({:error, e}, repo), do: TransactionStore.rollback(repo, e)
  defp map_delivery({:ok, r}), do: {:ok, LogoutDeliveryRecord.to_domain(r)}
  defp map_delivery({:error, e}), do: {:error, e}
end
