defmodule CleanRoomProvider.LifetimeClientStore do
  @moduledoc false

  @behaviour Lockspire.Storage.ClientStore
  @behaviour Lockspire.Storage.TransactionStore

  alias Lockspire.Domain.Client
  alias Lockspire.Storage.Ecto.Repository

  @table __MODULE__
  @public_storage_refs [
    "Lockspire.Storage.ClientStore",
    "Lockspire.Storage.TransactionStore",
    "Lockspire.Storage.Ecto.Repository",
    "Lockspire.Domain.Client"
  ]

  @on_load :ensure_table
  def ensure_table do
    case :ets.whereis(@table) do
      :undefined ->
        try do
          :ets.new(@table, [
            :named_table,
            :public,
            :set,
            read_concurrency: true,
            write_concurrency: true
          ])
        rescue
          ArgumentError -> @table
        end

      _table ->
        :ok
    end

    :ok
  end

  def public_storage_refs, do: @public_storage_refs

  def callback_counts do
    ensure_table()

    @table
    |> :ets.tab2list()
    |> Map.new()
  end

  @impl Lockspire.Storage.ClientStore
  def lifetime_contract do
    invoke(:lifetime_contract, fn ->
      %{version: 1, transaction_authority: transaction_authority()}
    end)
  end

  @impl Lockspire.Storage.TransactionStore
  def transaction_authority do
    invoke(:transaction_authority, fn ->
      authority = Repository.transaction_authority()

      %{
        authority
        | participants:
            authority.participants
            |> Map.put(:client_store, __MODULE__)
            |> Map.put(:transaction_store, __MODULE__)
      }
    end)
  end

  @impl Lockspire.Storage.ClientStore
  def lock_clients(ids), do: invoke(:lock_clients, fn -> Repository.lock_clients(ids) end)
  @impl Lockspire.Storage.ClientStore
  def register_client(%Client{} = client),
    do: invoke(:register_client, fn -> Repository.register_client(client) end)

  @impl Lockspire.Storage.ClientStore
  def list_clients(opts \\ []), do: invoke(:list_clients, fn -> Repository.list_clients(opts) end)
  @impl Lockspire.Storage.ClientStore
  def fetch_client_by_id(id),
    do: invoke(:fetch_client_by_id, fn -> Repository.fetch_client_by_id(id) end)

  @impl Lockspire.Storage.ClientStore
  def get_client_by_registration_access_token_hash(hash),
    do:
      invoke(:get_client_by_registration_access_token_hash, fn ->
        Repository.get_client_by_registration_access_token_hash(hash)
      end)

  @impl Lockspire.Storage.ClientStore
  def update_client(client, attrs),
    do: invoke(:update_client, fn -> Repository.update_client(client, attrs) end)

  @impl Lockspire.Storage.ClientStore
  def replace_client_registration(client, replacement, hash, audit),
    do:
      invoke(:replace_client_registration, fn ->
        Repository.replace_client_registration(client, replacement, hash, audit)
      end)

  @impl Lockspire.Storage.ClientStore
  def rotate_registration_access_token(client, hash, audit),
    do:
      invoke(:rotate_registration_access_token, fn ->
        Repository.rotate_registration_access_token(client, hash, audit)
      end)

  @impl Lockspire.Storage.ClientStore
  def rotate_client_secret(client, hash, verifier, rotated_at),
    do:
      invoke(:rotate_client_secret, fn ->
        Repository.rotate_client_secret(client, hash, verifier, rotated_at)
      end)

  @impl Lockspire.Storage.ClientStore
  def set_client_active(client, active, attrs),
    do: invoke(:set_client_active, fn -> Repository.set_client_active(client, active, attrs) end)

  @impl Lockspire.Storage.TransactionStore
  def transact(fun), do: invoke(:transact, fn -> Repository.transact(fun) end)
  @impl Lockspire.Storage.TransactionStore
  def rollback(reason), do: invoke(:rollback, fn -> Repository.rollback(reason) end)

  defp invoke(callback, fun) do
    ensure_table()
    :ets.update_counter(@table, callback, {2, 1}, {callback, 0})
    IO.puts(:stdio, "LIFETIME_ADAPTER_CALLBACK " <> Atom.to_string(callback))
    fun.()
  end
end
