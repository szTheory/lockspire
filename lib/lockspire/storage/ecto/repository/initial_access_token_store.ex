defmodule Lockspire.Storage.Ecto.Repository.InitialAccessTokenStore do
  @moduledoc false
  import Ecto.Query
  alias Lockspire.Domain.InitialAccessToken
  alias Lockspire.Storage.Ecto.InitialAccessTokenRecord
  alias Lockspire.Storage.Ecto.Repository.{Support, TransactionStore}

  def redeem(repo, hash, at) do
    TransactionStore.transact(repo, fn ->
      case InitialAccessTokenRecord
           |> where([iat], iat.token_hash == ^hash)
           |> lock("FOR UPDATE")
           |> then(&Support.one(repo, &1, sensitive: true)) do
        nil ->
          TransactionStore.rollback(repo, :not_found)

        %{revoked_at: value} when not is_nil(value) ->
          TransactionStore.rollback(repo, :revoked)

        %{expires_at: expires} when not is_nil(expires) and expires <= at ->
          TransactionStore.rollback(repo, :expired)

        %{used_at: value} when not is_nil(value) ->
          TransactionStore.rollback(repo, :already_used)

        record ->
          record
          |> Ecto.Changeset.change(used_at: at, updated_at: DateTime.utc_now())
          |> then(&Support.update(repo, &1, sensitive: true))
          |> map_one(repo)
      end
    end)
  end

  def list(repo, _opts \\ []),
    do:
      InitialAccessTokenRecord
      |> order_by([iat], desc: iat.inserted_at)
      |> then(&Support.all(repo, &1))
      |> Enum.map(&InitialAccessTokenRecord.to_domain/1)
      |> then(&{:ok, &1})

  def save(repo, %InitialAccessToken{} = iat),
    do:
      %InitialAccessTokenRecord{}
      |> InitialAccessTokenRecord.changeset(iat)
      |> then(&Support.insert(repo, &1))
      |> map_one(repo)

  def revoke(repo, id, at) do
    InitialAccessTokenRecord
    |> where([iat], iat.id == ^id)
    |> then(&Support.update_all(repo, &1, set: [revoked_at: at, updated_at: DateTime.utc_now()]))
    |> case do
      {1, _} -> :ok
      {0, _} -> {:error, :not_found}
    end
  end

  defp map_one({:ok, record}, _repo), do: {:ok, InitialAccessTokenRecord.to_domain(record)}
  defp map_one({:error, reason}, repo), do: TransactionStore.rollback(repo, reason)
end
