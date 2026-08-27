defmodule Lockspire.Storage.Ecto.Repository.ReplayStore do
  @moduledoc false

  import Ecto.Query

  alias Lockspire.Domain.DpopReplay
  alias Lockspire.Domain.UsedJti
  alias Lockspire.Storage.Ecto.DpopReplayRecord
  alias Lockspire.Storage.Ecto.Repository.Support
  alias Lockspire.Storage.Ecto.Repository.TransactionStore
  alias Lockspire.Storage.Ecto.UsedJtiRecord

  @spec record_dpop_proof(module(), DpopReplay.t()) ::
          {:ok, :accepted | :replay} | {:error, term()}
  def record_dpop_proof(repo, %DpopReplay{} = replay) do
    TransactionStore.transact(repo, fn ->
      prune_expired_dpop_replay_records(repo, replay.seen_at)
      changeset = DpopReplayRecord.changeset(%DpopReplayRecord{}, replay)

      if changeset.valid? do
        case insert_dpop_replay_record(repo, replay) do
          1 -> :accepted
          0 -> :replay
          _other -> TransactionStore.rollback(repo, :dpop_replay_insert_failed)
        end
      else
        TransactionStore.rollback(repo, changeset)
      end
    end)
  end

  @spec record_used_jti(module(), UsedJti.t()) ::
          {:ok, :accepted | :replay} | {:error, Ecto.Changeset.t()}
  def record_used_jti(repo, %UsedJti{} = used_jti) do
    now = DateTime.utc_now()
    expires_at = DateTime.truncate(used_jti.expires_at, :microsecond)

    changeset =
      UsedJtiRecord.changeset(%UsedJtiRecord{}, %{
        client_id: used_jti.client_id,
        jti: used_jti.jti,
        expires_at: expires_at
      })

    if changeset.valid? do
      {count, _rows} =
        Support.insert_all(
          repo,
          UsedJtiRecord,
          [
            %{
              client_id: used_jti.client_id,
              jti: used_jti.jti,
              expires_at: expires_at,
              inserted_at: now,
              updated_at: now
            }
          ],
          on_conflict: :nothing,
          conflict_target: [:client_id, :jti],
          log: false
        )

      case count do
        1 -> {:ok, :accepted}
        0 -> {:ok, :replay}
      end
    else
      {:error, changeset}
    end
  end

  defp insert_dpop_replay_record(repo, %DpopReplay{} = replay) do
    now = DateTime.utc_now()
    seen_at = DateTime.truncate(replay.seen_at, :microsecond)
    expires_at = DateTime.truncate(replay.expires_at, :microsecond)

    {count, _rows} =
      Support.insert_all(
        repo,
        DpopReplayRecord,
        [
          %{
            replay_key: replay.replay_key,
            jti: replay.jti,
            htm: replay.htm,
            htu: replay.htu,
            jkt: replay.jkt,
            seen_at: seen_at,
            expires_at: expires_at,
            inserted_at: now,
            updated_at: now
          }
        ],
        on_conflict: :nothing,
        conflict_target: [:replay_key],
        log: false
      )

    count
  end

  defp prune_expired_dpop_replay_records(repo, %DateTime{} = seen_at) do
    DpopReplayRecord
    |> where([replay], replay.expires_at <= ^seen_at)
    |> then(&Support.delete_all(repo, &1, log: false))

    :ok
  end
end
