defmodule Lockspire.Storage.ClientVerifierMaintenanceTest do
  use ExUnit.Case, async: false

  alias Lockspire.Storage.ClientVerifierMaintenance
  alias Lockspire.Storage.Ecto.Repository

  setup do
    Application.put_env(:lockspire, :client_store, Lockspire.TestSupport.DelegatedVerifierMaintenanceStore)
    Application.put_env(:lockspire, :transaction_store, Lockspire.TestSupport.DelegatedVerifierMaintenanceStore)

    on_exit(fn ->
      Application.delete_env(:lockspire, :client_store)
      Application.delete_env(:lockspire, :transaction_store)
      Application.delete_env(:lockspire, :maintenance_declaration_mode)
    end)

    :ok
  end

  test "preserves the adapter's explicit unsupported capability result" do
    Application.put_env(:lockspire, :maintenance_declaration_mode, :unsupported)

    assert {:error, :client_secret_verifier_maintenance_unsupported} =
             ClientVerifierMaintenance.configured()

    assert_received :maintenance_declaration_called
    refute_received {:client_fetch, _}
    refute_received {:inventory_page, _}
  end

  test "rejects a mismatched maintenance declaration before inventory or client access" do
    Application.put_env(:lockspire, :maintenance_declaration_mode, :mismatch)

    assert {:error, :client_secret_verifier_maintenance_authority_mismatch} =
             ClientVerifierMaintenance.configured()

    assert_received :maintenance_declaration_called
    refute_received {:client_fetch, _}
    refute_received {:inventory_page, _}
  end

  test "rejects declaration participants that disagree with the selected composition" do
    Application.put_env(:lockspire, :maintenance_declaration_mode, :participant_mismatch)

    assert {:error, :client_secret_verifier_maintenance_authority_mismatch} =
             ClientVerifierMaintenance.configured()

    refute_received {:client_fetch, _}
    refute_received {:inventory_page, _}
  end

  test "accepts the declared shared PostgreSQL delegation" do
    Application.put_env(:lockspire, :maintenance_declaration_mode, :valid)

    assert {:ok, config} = ClientVerifierMaintenance.configured()
    assert config.client_store == Lockspire.TestSupport.DelegatedVerifierMaintenanceStore
    assert config.transaction_store == Lockspire.TestSupport.DelegatedVerifierMaintenanceStore
    assert config.audit_store == Repository
  end
end

defmodule Lockspire.TestSupport.DelegatedVerifierMaintenanceStore do
  @behaviour Lockspire.Storage.ClientStore
  @behaviour Lockspire.Storage.TransactionStore
  @behaviour Lockspire.Storage.ClientVerifierMaintenance

  alias Lockspire.Storage.Ecto.Repository

  def lifetime_contract, do: %{version: 1, transaction_authority: transaction_authority()}

  def transaction_authority do
    authority = Repository.transaction_authority()

    %{
      authority
      | participants:
          authority.participants
          |> Map.put(:client_store, __MODULE__)
          |> Map.put(:transaction_store, __MODULE__)
    }
  end

  def verifier_maintenance_contract do
    send(self(), :maintenance_declaration_called)
    authority = transaction_authority()

    case Application.get_env(:lockspire, :maintenance_declaration_mode, :valid) do
      :unsupported ->
        {:error, :client_secret_verifier_maintenance_unsupported}

      :mismatch ->
        {:ok, declaration(authority |> Map.put(:identity, :other_postgres_authority))}

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
  end

  def verifier_inventory_page(after_client_id, limit) do
    send(self(), {:inventory_page, {after_client_id, limit}})
    Repository.verifier_inventory_page(after_client_id, limit)
  end

  def compare_and_rewrap(client_id, hash, expected, replacement, audit) do
    Repository.compare_and_rewrap(client_id, hash, expected, replacement, audit)
  end

  def fetch_client_by_id(client_id) do
    send(self(), {:client_fetch, client_id})
    Repository.fetch_client_by_id(client_id)
  end

  defdelegate lock_clients(ids), to: Repository
  defdelegate register_client(client), to: Repository
  defdelegate list_clients(opts \\ []), to: Repository
  defdelegate get_client_by_registration_access_token_hash(hash), to: Repository
  defdelegate update_client(client, attrs), to: Repository
  defdelegate replace_client_registration(client, replacement, hash, audit), to: Repository
  defdelegate rotate_registration_access_token(client, hash, audit), to: Repository
  defdelegate rotate_client_secret(client, hash, verifier, rotated_at), to: Repository
  defdelegate set_client_active(client, active, attrs), to: Repository
  defdelegate transact(fun), to: Repository
  defdelegate rollback(reason), to: Repository

  defp declaration(authority, participants \\ %{
         client_store: __MODULE__,
         transaction_store: __MODULE__,
         audit_store: Repository
       }) do
    %{
      version: 1,
      transaction_authority: authority,
      participants: participants
    }
  end
end
