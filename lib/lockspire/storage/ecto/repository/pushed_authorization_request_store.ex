defmodule Lockspire.Storage.Ecto.Repository.PushedAuthorizationRequestStore do
  @moduledoc false

  import Ecto.Query

  alias Lockspire.Domain.PushedAuthorizationRequest
  alias Lockspire.Storage.Ecto.PushedAuthorizationRequestRecord
  alias Lockspire.Storage.Ecto.Repository.Support
  alias Lockspire.Storage.Ecto.Repository.TransactionStore

  @spec put_pushed_authorization_request(module(), PushedAuthorizationRequest.t()) ::
          {:ok, PushedAuthorizationRequest.t()} | {:error, term()}
  def put_pushed_authorization_request(repo, %PushedAuthorizationRequest{} = request) do
    %PushedAuthorizationRequestRecord{}
    |> PushedAuthorizationRequestRecord.changeset(request)
    |> then(
      &Support.insert(repo, &1,
        on_conflict: {:replace_all_except, [:id, :inserted_at]},
        conflict_target: [:request_uri_hash]
      )
    )
    |> map_one(&PushedAuthorizationRequestRecord.to_domain(&1, request_uri: request.request_uri))
  end

  @spec fetch_active_pushed_authorization_request(module(), String.t()) ::
          {:ok, PushedAuthorizationRequest.t() | nil} | {:error, term()}
  def fetch_active_pushed_authorization_request(repo, request_uri_hash)
      when is_binary(request_uri_hash) do
    now = DateTime.utc_now()

    PushedAuthorizationRequestRecord
    |> where([request], request.request_uri_hash == ^request_uri_hash)
    |> where([request], request.expires_at > ^now)
    |> then(&Support.one(repo, &1, sensitive: true))
    |> then(fn record ->
      {:ok, maybe_map(record, &PushedAuthorizationRequestRecord.to_domain/1)}
    end)
  rescue
    error -> {:error, error}
  end

  @spec consume_pushed_authorization_request(module(), String.t(), String.t()) ::
          {:ok, PushedAuthorizationRequest.t() | nil} | {:error, term()}
  def consume_pushed_authorization_request(repo, request_uri_hash, client_id)
      when is_binary(request_uri_hash) and is_binary(client_id) do
    TransactionStore.transact(repo, fn ->
      now = DateTime.utc_now()

      PushedAuthorizationRequestRecord
      |> where([request], request.request_uri_hash == ^request_uri_hash)
      |> lock("FOR UPDATE")
      |> then(&Support.one(repo, &1, sensitive: true))
      |> consume_record(repo, client_id, now)
    end)
    |> normalize_consume_result()
  end

  defp consume_record(nil, repo, _client_id, _now),
    do: TransactionStore.rollback(repo, :not_found)

  defp consume_record(%PushedAuthorizationRequestRecord{} = record, repo, client_id, now) do
    case record
         |> then(&Support.delete(repo, &1, sensitive: true))
         |> map_one(&PushedAuthorizationRequestRecord.to_domain/1) do
      {:ok, %PushedAuthorizationRequest{} = consumed} ->
        cond do
          not active?(consumed, now) -> nil
          consumed.client_id != client_id -> nil
          true -> consumed
        end

      {:error, reason} ->
        TransactionStore.rollback(repo, reason)
    end
  end

  defp normalize_consume_result({:ok, %PushedAuthorizationRequest{} = request}),
    do: {:ok, request}

  defp normalize_consume_result({:ok, nil}), do: {:ok, nil}
  defp normalize_consume_result({:error, :not_found}), do: {:ok, nil}
  defp normalize_consume_result({:error, :invalid_client_binding}), do: {:ok, nil}
  defp normalize_consume_result({:error, reason}), do: {:error, reason}

  defp active?(%PushedAuthorizationRequest{expires_at: %DateTime{} = expires_at}, now),
    do: DateTime.compare(expires_at, now) == :gt

  defp map_one({:ok, record}, mapper), do: {:ok, mapper.(record)}
  defp map_one({:error, error}, _mapper), do: {:error, error}
  defp maybe_map(nil, _mapper), do: nil
  defp maybe_map(record, mapper), do: mapper.(record)
end
