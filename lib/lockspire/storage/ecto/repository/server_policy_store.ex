defmodule Lockspire.Storage.Ecto.Repository.ServerPolicyStore do
  @moduledoc false

  import Ecto.Query

  alias Lockspire.Domain.ServerPolicy
  alias Lockspire.Storage.Ecto.Repository.Support
  alias Lockspire.Storage.Ecto.Repository.TransactionStore
  alias Lockspire.Storage.Ecto.ServerPolicyRecord

  @spec get_server_policy(module()) :: {:ok, ServerPolicy.t()} | {:error, term()}
  def get_server_policy(repo) do
    ServerPolicyRecord
    |> where([policy], policy.id == ^ServerPolicyRecord.singleton_id())
    |> then(&Support.one(repo, &1))
    |> then(fn
      nil -> {:ok, %ServerPolicy{}}
      %ServerPolicyRecord{} = record -> {:ok, ServerPolicyRecord.to_domain(record)}
    end)
  rescue
    error -> {:error, error}
  end

  @spec put_server_policy(module(), ServerPolicy.t()) ::
          {:ok, ServerPolicy.t()} | {:error, term()}
  def put_server_policy(repo, %ServerPolicy{} = policy),
    do: update_server_policy(repo, fn _current -> policy end)

  @spec update_server_policy(module(), (ServerPolicy.t() -> ServerPolicy.t())) ::
          {:ok, ServerPolicy.t()} | {:error, term()}
  def update_server_policy(repo, mutator) when is_function(mutator, 1) do
    TransactionStore.transact(repo, fn ->
      singleton_id = ServerPolicyRecord.singleton_id()

      current_record =
        ServerPolicyRecord
        |> where([stored_policy], stored_policy.id == ^singleton_id)
        |> lock("FOR UPDATE")
        |> then(&Support.one(repo, &1))

      current =
        case current_record do
          nil -> %ServerPolicy{id: singleton_id}
          %ServerPolicyRecord{} = record -> ServerPolicyRecord.to_domain(record)
        end

      %ServerPolicy{} = new_policy = mutator.(current)

      case current_record do
        nil ->
          %ServerPolicyRecord{}
          |> ServerPolicyRecord.changeset(%ServerPolicy{new_policy | id: singleton_id})
          |> then(&Support.insert(repo, &1))
          |> map_one(&ServerPolicyRecord.to_domain/1)
          |> unwrap_or_rollback(repo)

        %ServerPolicyRecord{} = record ->
          record
          |> ServerPolicyRecord.changeset(%ServerPolicy{new_policy | id: singleton_id})
          |> then(&Support.update(repo, &1))
          |> map_one(&ServerPolicyRecord.to_domain/1)
          |> unwrap_or_rollback(repo)
      end
    end)
  end

  defp map_one({:ok, record}, mapper), do: {:ok, mapper.(record)}
  defp map_one({:error, error}, _mapper), do: {:error, error}
  defp unwrap_or_rollback({:ok, result}, _repo), do: result
  defp unwrap_or_rollback({:error, reason}, repo), do: TransactionStore.rollback(repo, reason)
end
