defmodule Lockspire.Storage.Ecto.Repository.DeviceAuthorizationStore do
  @moduledoc false

  import Ecto.Query

  alias Lockspire.Domain.DeviceAuthorization
  alias Lockspire.Storage.Ecto.DeviceAuthorizationRecord
  alias Lockspire.Storage.Ecto.Repository.Support
  alias Lockspire.Storage.Ecto.Repository.TransactionStore

  @spec list_device_authorizations(module(), keyword()) ::
          {:ok, [DeviceAuthorization.t()]} | {:error, term()}
  def list_device_authorizations(repo, _opts \\ []) do
    DeviceAuthorizationRecord
    |> order_by([authorization], desc: authorization.inserted_at)
    |> then(&Support.all(repo, &1))
    |> then(fn records -> {:ok, Enum.map(records, &DeviceAuthorizationRecord.to_domain/1)} end)
  rescue
    error -> {:error, error}
  end

  @spec put_device_authorization(module(), DeviceAuthorization.t()) ::
          {:ok, DeviceAuthorization.t()} | {:error, term()}
  def put_device_authorization(repo, %DeviceAuthorization{} = auth) do
    %DeviceAuthorizationRecord{}
    |> DeviceAuthorizationRecord.changeset(auth)
    |> then(&Support.insert(repo, &1))
    |> map_one(&DeviceAuthorizationRecord.to_domain/1)
  end

  @spec fetch_device_authorization_by_user_code_hash(module(), String.t()) ::
          {:ok, DeviceAuthorization.t() | nil} | {:error, term()}
  def fetch_device_authorization_by_user_code_hash(repo, user_code_hash)
      when is_binary(user_code_hash) do
    DeviceAuthorizationRecord
    |> where([authorization], authorization.user_code_hash == ^user_code_hash)
    |> then(&Support.one(repo, &1, sensitive: true))
    |> then(fn record -> {:ok, maybe_map(record, &DeviceAuthorizationRecord.to_domain/1)} end)
  rescue
    error -> {:error, error}
  end

  @spec fetch_device_authorization_by_device_code_hash(module(), String.t()) ::
          {:ok, DeviceAuthorization.t() | nil} | {:error, term()}
  def fetch_device_authorization_by_device_code_hash(repo, device_code_hash)
      when is_binary(device_code_hash) do
    DeviceAuthorizationRecord
    |> where([authorization], authorization.device_code_hash == ^device_code_hash)
    |> then(&Support.one(repo, &1, sensitive: true))
    |> then(fn record -> {:ok, maybe_map(record, &DeviceAuthorizationRecord.to_domain/1)} end)
  rescue
    error -> {:error, error}
  end

  @spec fetch_device_authorization_by_verification_handle(module(), String.t()) ::
          {:ok, DeviceAuthorization.t() | nil} | {:error, term()}
  def fetch_device_authorization_by_verification_handle(repo, verification_handle)
      when is_binary(verification_handle) do
    DeviceAuthorizationRecord
    |> where([authorization], authorization.verification_handle == ^verification_handle)
    |> then(&Support.one(repo, &1, sensitive: true))
    |> then(fn record -> {:ok, maybe_map(record, &DeviceAuthorizationRecord.to_domain/1)} end)
  rescue
    error -> {:error, error}
  end

  @spec record_device_poll(module(), String.t(), String.t(), DateTime.t()) ::
          {:ok, map()} | {:error, term()}
  def record_device_poll(repo, device_code_hash, client_id, now)
      when is_binary(device_code_hash) and is_binary(client_id) and is_struct(now, DateTime) do
    TransactionStore.transact(repo, fn ->
      device_code_hash
      |> locked_by_device_code_query()
      |> then(&Support.one(repo, &1, sensitive: true))
      |> evaluate_poll(repo, client_id, now)
    end)
  end

  @spec consume_device_authorization(module(), String.t(), String.t(), DateTime.t()) ::
          {:ok, DeviceAuthorization.t()} | {:error, term()}
  def consume_device_authorization(repo, verification_handle, client_id, now)
      when is_binary(verification_handle) and is_binary(client_id) and is_struct(now, DateTime) do
    TransactionStore.transact(repo, fn ->
      verification_handle
      |> locked_query()
      |> then(&Support.one(repo, &1))
      |> consume_record(repo, client_id, now)
    end)
  end

  @spec transition_device_authorization(module(), String.t(), [atom()], map()) ::
          {:ok, DeviceAuthorization.t()} | {:error, term()}
  def transition_device_authorization(repo, verification_handle, expected_statuses, attrs)
      when is_binary(verification_handle) and is_list(expected_statuses) and is_map(attrs) do
    TransactionStore.transact(repo, fn ->
      verification_handle
      |> locked_query()
      |> then(&Support.one(repo, &1))
      |> transition_record(repo, expected_statuses, attrs)
    end)
  end

  defp locked_query(verification_handle) do
    DeviceAuthorizationRecord
    |> where([authorization], authorization.verification_handle == ^verification_handle)
    |> lock("FOR UPDATE")
  end

  defp locked_by_device_code_query(device_code_hash) do
    DeviceAuthorizationRecord
    |> where([authorization], authorization.device_code_hash == ^device_code_hash)
    |> lock("FOR UPDATE")
  end

  defp transition_record(nil, repo, _expected_statuses, _attrs),
    do: TransactionStore.rollback(repo, :not_found)

  defp transition_record(%DeviceAuthorizationRecord{} = record, repo, expected_statuses, attrs) do
    if record.status in expected_statuses do
      record
      |> DeviceAuthorizationRecord.update_changeset(
        Map.put(attrs, :updated_at, DateTime.utc_now())
      )
      |> then(&Support.update(repo, &1))
      |> map_one(&DeviceAuthorizationRecord.to_domain/1)
      |> unwrap_or_rollback(repo)
    else
      TransactionStore.rollback(repo, :invalid_state)
    end
  end

  defp evaluate_poll(nil, _repo, _client_id, _now), do: %{result: :invalid_grant}

  defp evaluate_poll(
         %DeviceAuthorizationRecord{client_id: stored_client_id},
         _repo,
         client_id,
         _now
       )
       when stored_client_id != client_id,
       do: %{result: :client_mismatch}

  defp evaluate_poll(
         %DeviceAuthorizationRecord{status: :denied} = record,
         _repo,
         _client_id,
         _now
       ),
       do: outcome(:denied, record)

  defp evaluate_poll(
         %DeviceAuthorizationRecord{status: :expired} = record,
         _repo,
         _client_id,
         _now
       ),
       do: outcome(:expired, record)

  defp evaluate_poll(
         %DeviceAuthorizationRecord{status: :consumed} = record,
         _repo,
         _client_id,
         _now
       ),
       do: outcome(:consumed, record)

  defp evaluate_poll(
         %DeviceAuthorizationRecord{status: :approved} = record,
         repo,
         _client_id,
         now
       ) do
    if DateTime.compare(record.expires_at, now) != :gt,
      do: expire(record, repo, now),
      else: outcome(:approved_ready, record)
  end

  defp evaluate_poll(%DeviceAuthorizationRecord{status: :pending} = record, repo, _client_id, now) do
    cond do
      DateTime.compare(record.expires_at, now) != :gt -> expire(record, repo, now)
      DateTime.compare(now, record.next_poll_allowed_at) == :lt -> slow_down(record, repo)
      true -> continue_pending(record, repo, now)
    end
  end

  defp evaluate_poll(%DeviceAuthorizationRecord{status: status}, _repo, client_id, _now),
    do: %{result: :invalid_grant, reason: {:unexpected_status, status, client_id}}

  defp expire(record, repo, now) do
    record
    |> DeviceAuthorizationRecord.update_changeset(%{
      status: :expired,
      expired_at: now,
      updated_at: DateTime.utc_now()
    })
    |> then(&Support.update(repo, &1, sensitive: true))
    |> map_one(&DeviceAuthorizationRecord.to_domain/1)
    |> unwrap_or_rollback(repo)
    |> then(&outcome(:expired, &1))
  end

  defp slow_down(record, repo) do
    next_interval = record.effective_poll_interval_seconds + 5
    next_poll_allowed_at = DateTime.add(record.next_poll_allowed_at, next_interval, :second)

    record
    |> DeviceAuthorizationRecord.update_changeset(%{
      effective_poll_interval_seconds: next_interval,
      next_poll_allowed_at: next_poll_allowed_at,
      updated_at: DateTime.utc_now()
    })
    |> then(&Support.update(repo, &1, sensitive: true))
    |> map_one(&DeviceAuthorizationRecord.to_domain/1)
    |> unwrap_or_rollback(repo)
    |> then(&outcome(:slow_down, &1))
  end

  defp continue_pending(record, repo, now) do
    next_poll_allowed_at = DateTime.add(now, record.effective_poll_interval_seconds, :second)

    record
    |> DeviceAuthorizationRecord.update_changeset(%{
      next_poll_allowed_at: next_poll_allowed_at,
      updated_at: DateTime.utc_now()
    })
    |> then(&Support.update(repo, &1, sensitive: true))
    |> map_one(&DeviceAuthorizationRecord.to_domain/1)
    |> unwrap_or_rollback(repo)
    |> then(&outcome(:pending, &1))
  end

  defp consume_record(nil, repo, _client_id, _now),
    do: TransactionStore.rollback(repo, :invalid_state)

  defp consume_record(
         %DeviceAuthorizationRecord{client_id: stored_client_id},
         repo,
         client_id,
         _now
       )
       when stored_client_id != client_id, do: TransactionStore.rollback(repo, :invalid_state)

  defp consume_record(
         %DeviceAuthorizationRecord{status: :approved} = record,
         repo,
         _client_id,
         now
       ) do
    if DateTime.compare(record.expires_at, now) == :gt do
      record
      |> DeviceAuthorizationRecord.update_changeset(%{
        status: :consumed,
        consumed_at: now,
        updated_at: DateTime.utc_now()
      })
      |> then(&Support.update(repo, &1, sensitive: true))
      |> map_one(&DeviceAuthorizationRecord.to_domain/1)
      |> unwrap_or_rollback(repo)
    else
      TransactionStore.rollback(repo, :invalid_state)
    end
  end

  defp consume_record(%DeviceAuthorizationRecord{}, repo, _client_id, _now),
    do: TransactionStore.rollback(repo, :invalid_state)

  defp outcome(result, %DeviceAuthorizationRecord{} = record),
    do: outcome(result, DeviceAuthorizationRecord.to_domain(record))

  defp outcome(result, %DeviceAuthorization{} = authorization),
    do: %{
      result: result,
      device_authorization: authorization,
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
