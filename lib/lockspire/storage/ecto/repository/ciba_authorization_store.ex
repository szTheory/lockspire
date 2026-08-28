defmodule Lockspire.Storage.Ecto.Repository.CibaAuthorizationStore do
  @moduledoc false

  import Ecto.Query

  alias Lockspire.Domain.CibaAuthorization
  alias Lockspire.Storage.Ecto.CibaAuthorizationRecord
  alias Lockspire.Storage.Ecto.Repository.Support
  alias Lockspire.Storage.Ecto.Repository.TransactionStore

  @spec put_ciba_authorization(module(), CibaAuthorization.t()) ::
          {:ok, CibaAuthorization.t()} | {:error, term()}
  def put_ciba_authorization(repo, %CibaAuthorization{} = auth) do
    %CibaAuthorizationRecord{}
    |> CibaAuthorizationRecord.changeset(auth)
    |> then(&Support.insert(repo, &1))
    |> map_one(&CibaAuthorizationRecord.to_domain/1)
  end

  @spec fetch_ciba_authorization_by_auth_req_id_hash(module(), String.t()) ::
          {:ok, CibaAuthorization.t() | nil} | {:error, term()}
  def fetch_ciba_authorization_by_auth_req_id_hash(repo, auth_req_id_hash)
      when is_binary(auth_req_id_hash) do
    CibaAuthorizationRecord
    |> where([authorization], authorization.auth_req_id_hash == ^auth_req_id_hash)
    |> then(&Support.one(repo, &1, sensitive: true))
    |> then(fn record -> {:ok, maybe_map(record, &CibaAuthorizationRecord.to_domain/1)} end)
  rescue
    error -> {:error, error}
  end

  @spec record_ciba_poll(module(), String.t(), String.t(), DateTime.t()) ::
          {:ok, map()} | {:error, term()}
  def record_ciba_poll(repo, auth_req_id_hash, client_id, now)
      when is_binary(auth_req_id_hash) and is_binary(client_id) and is_struct(now, DateTime) do
    TransactionStore.transact(repo, fn ->
      auth_req_id_hash
      |> locked_query()
      |> then(&Support.one(repo, &1, sensitive: true))
      |> evaluate_poll(repo, client_id, now)
    end)
  end

  @spec transition_ciba_authorization(module(), String.t(), [atom()], map()) ::
          {:ok, CibaAuthorization.t()} | {:error, term()}
  def transition_ciba_authorization(repo, auth_req_id_hash, expected_statuses, attrs)
      when is_binary(auth_req_id_hash) and is_list(expected_statuses) and is_map(attrs) do
    TransactionStore.transact(repo, fn ->
      auth_req_id_hash
      |> locked_query()
      |> then(&Support.one(repo, &1))
      |> transition_record(repo, expected_statuses, attrs)
    end)
  end

  defp locked_query(auth_req_id_hash) do
    CibaAuthorizationRecord
    |> where([authorization], authorization.auth_req_id_hash == ^auth_req_id_hash)
    |> lock("FOR UPDATE")
  end

  defp transition_record(nil, repo, _expected_statuses, _attrs),
    do: TransactionStore.rollback(repo, :not_found)

  defp transition_record(%CibaAuthorizationRecord{} = record, repo, expected_statuses, attrs) do
    if record.status in expected_statuses do
      record
      |> CibaAuthorizationRecord.update_changeset(Map.put(attrs, :updated_at, DateTime.utc_now()))
      |> then(&Support.update(repo, &1))
      |> map_one(&CibaAuthorizationRecord.to_domain/1)
      |> unwrap_or_rollback(repo)
    else
      TransactionStore.rollback(repo, :invalid_state)
    end
  end

  defp evaluate_poll(nil, _repo, _client_id, _now), do: %{result: :invalid_grant}

  defp evaluate_poll(
         %CibaAuthorizationRecord{client_id: stored_client_id},
         _repo,
         client_id,
         _now
       )
       when stored_client_id != client_id, do: %{result: :client_mismatch}

  defp evaluate_poll(%CibaAuthorizationRecord{status: :denied} = record, _repo, _client_id, _now),
    do: outcome(:denied, record)

  defp evaluate_poll(
         %CibaAuthorizationRecord{status: :expired} = record,
         _repo,
         _client_id,
         _now
       ),
       do: outcome(:expired, record)

  defp evaluate_poll(
         %CibaAuthorizationRecord{status: :consumed} = record,
         _repo,
         _client_id,
         _now
       ),
       do: outcome(:consumed, record)

  defp evaluate_poll(%CibaAuthorizationRecord{status: :approved} = record, repo, _client_id, now) do
    if DateTime.compare(record.expires_at, now) != :gt,
      do: expire(record, repo, now),
      else: outcome(:approved_ready, record)
  end

  defp evaluate_poll(%CibaAuthorizationRecord{status: :pending} = record, repo, _client_id, now) do
    cond do
      DateTime.compare(record.expires_at, now) != :gt -> expire(record, repo, now)
      DateTime.compare(now, record.next_poll_allowed_at) == :lt -> slow_down(record, repo)
      true -> continue_pending(record, repo, now)
    end
  end

  defp evaluate_poll(%CibaAuthorizationRecord{status: status}, _repo, client_id, _now),
    do: %{result: :invalid_grant, reason: {:unexpected_status, status, client_id}}

  defp expire(record, repo, now) do
    record
    |> CibaAuthorizationRecord.update_changeset(%{
      status: :expired,
      expired_at: now,
      updated_at: DateTime.utc_now()
    })
    |> then(&Support.update(repo, &1, sensitive: true))
    |> map_one(&CibaAuthorizationRecord.to_domain/1)
    |> unwrap_or_rollback(repo)
    |> then(&outcome(:expired, &1))
  end

  defp slow_down(record, repo) do
    next_interval = record.effective_poll_interval_seconds + 5
    next_poll_allowed_at = DateTime.add(record.next_poll_allowed_at, next_interval, :second)

    record
    |> CibaAuthorizationRecord.update_changeset(%{
      effective_poll_interval_seconds: next_interval,
      next_poll_allowed_at: next_poll_allowed_at,
      updated_at: DateTime.utc_now()
    })
    |> then(&Support.update(repo, &1, sensitive: true))
    |> map_one(&CibaAuthorizationRecord.to_domain/1)
    |> unwrap_or_rollback(repo)
    |> then(&outcome(:slow_down, &1))
  end

  defp continue_pending(record, repo, now) do
    next_poll_allowed_at = DateTime.add(now, record.effective_poll_interval_seconds, :second)

    record
    |> CibaAuthorizationRecord.update_changeset(%{
      next_poll_allowed_at: next_poll_allowed_at,
      updated_at: DateTime.utc_now()
    })
    |> then(&Support.update(repo, &1, sensitive: true))
    |> map_one(&CibaAuthorizationRecord.to_domain/1)
    |> unwrap_or_rollback(repo)
    |> then(&outcome(:pending, &1))
  end

  defp outcome(result, %CibaAuthorizationRecord{} = record),
    do: outcome(result, CibaAuthorizationRecord.to_domain(record))

  defp outcome(result, %CibaAuthorization{} = authorization),
    do: %{
      result: result,
      ciba_authorization: authorization,
      effective_poll_interval_seconds: authorization.effective_poll_interval_seconds,
      next_poll_allowed_at: authorization.next_poll_allowed_at
    }

  defp unwrap_or_rollback({:ok, result}, _repo), do: result
  defp unwrap_or_rollback({:error, reason}, repo), do: TransactionStore.rollback(repo, reason)
  defp map_one({:ok, record}, mapper), do: {:ok, mapper.(record)}
  defp map_one({:error, error}, _mapper), do: {:error, error}
  defp maybe_map(nil, _mapper), do: nil
  defp maybe_map(record, mapper), do: mapper.(record)
end
