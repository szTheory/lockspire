defmodule CleanRoomProvider.LifetimeClientStore do
  @moduledoc false

  @behaviour Lockspire.Storage.ClientStore
  @behaviour Lockspire.Storage.TransactionStore
  @behaviour Lockspire.Storage.ClientVerifierMaintenance
  @behaviour Lockspire.Storage.UsedJtiStore

  alias Lockspire.Domain.Client
  alias Lockspire.Domain.UsedJti
  alias Lockspire.Storage.Ecto.Repository

  @table __MODULE__
  @public_storage_refs [
    "Lockspire.Storage.ClientStore",
    "Lockspire.Storage.TransactionStore",
    "Lockspire.Storage.ClientVerifierMaintenance",
    "Lockspire.Storage.UsedJtiStore",
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

  @impl Lockspire.Storage.ClientVerifierMaintenance
  def verifier_maintenance_contract do
    invoke(:verifier_maintenance_contract, fn ->
      authority = transaction_authority()

      case Application.get_env(:clean_room_provider, :maintenance_declaration_mode, :valid) do
        :unsupported ->
          {:error, :client_secret_verifier_maintenance_unsupported}

        :mismatch ->
          {:ok, declaration(%{authority | identity: :other_postgres_authority})}

        :participant_mismatch ->
          {:ok,
           declaration(authority, %{
             client_store: Repository,
             transaction_store: __MODULE__,
             audit_store: Repository
           })}

        :valid ->
          {:ok, declaration(authority)}
      end
    end)
  end

  @impl Lockspire.Storage.ClientVerifierMaintenance
  def verifier_inventory_page(after_client_id, limit) do
    invoke(:verifier_inventory_page, fn ->
      wait_for_run_control(:authenticated_read)

      case {System.get_env("LOCKSPIRE_CORE_INVENTORY_MODE"),
            Process.get({__MODULE__, :inventory_page_index}, 0)} do
        {"partial", 0} ->
          Process.put({__MODULE__, :inventory_page_index}, 1)

          case Repository.verifier_inventory_page(after_client_id, 1) do
            {:ok, %{clients: [_ | _] = clients}} ->
              {:ok,
               %{clients: clients, next_cursor: List.last(clients).client_id, complete?: false}}

            _ ->
              {:error, :inventory_unavailable}
          end

        {"partial", _index} ->
          {:error, :inventory_unavailable}

        {nil, _index} ->
          Repository.verifier_inventory_page(after_client_id, limit)

        {_unsupported, _index} ->
          {:error, :inventory_unavailable}
      end
    end)
  end

  @impl Lockspire.Storage.ClientVerifierMaintenance
  def compare_and_rewrap(client_id, hash, expected, replacement, audit) do
    invoke(:compare_and_rewrap, fn ->
      wait_for_run_control(:current_row_guard)
      result = Repository.compare_and_rewrap(client_id, hash, expected, replacement, audit)
      wait_for_run_control(:commit_response)
      result
    end)
  end

  @impl Lockspire.Storage.UsedJtiStore
  def record_used_jti(%UsedJti{} = used_jti),
    do: invoke(:record_used_jti, fn -> Repository.record_used_jti(used_jti) end)

  def set_run_control(name, controller)
      when name in [:authenticated_read, :current_row_guard, :commit_response] and
             is_pid(controller) do
    Application.put_env(:clean_room_provider, {__MODULE__, :run_controls}, %{
      name => %{controller: controller, reference: make_ref()}
    })
  end

  def clear_run_controls do
    Application.delete_env(:clean_room_provider, {__MODULE__, :run_controls})
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

  defp declaration(
         authority,
         participants \\ %{
           client_store: __MODULE__,
           transaction_store: __MODULE__,
           audit_store: Repository
         }
       ) do
    %{version: 1, transaction_authority: authority, participants: participants}
  end

  defp wait_for_run_control(name) do
    controls = Application.get_env(:clean_room_provider, {__MODULE__, :run_controls}, %{})

    case Map.get(controls, name) do
      %{controller: controller, reference: reference} when is_pid(controller) ->
        send(controller, {:lifetime_client_store_barrier, name, self(), reference})

        receive do
          {:release_lifetime_client_store_barrier, ^reference} -> :ok
        after
          30_000 -> raise "clean-room verifier callback control timed out"
        end

      _ ->
        :ok
    end
  end

  defp invoke(callback, fun) do
    ensure_table()
    :ets.update_counter(@table, callback, {2, 1}, {callback, 0})
    IO.puts(:stdio, "LIFETIME_ADAPTER_CALLBACK " <> Atom.to_string(callback))
    fun.()
  end
end
