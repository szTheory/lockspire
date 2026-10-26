defmodule Lockspire.Admin.ClientVerifierMaintenanceTest do
  use ExUnit.Case, async: false

  alias Ecto.Adapters.SQL.Sandbox
  alias Lockspire.Domain.Client
  alias Lockspire.Storage.Ecto.Repository
  alias Lockspire.Storage.Ecto.ClientRecord

  setup_all do
    Application.put_env(:lockspire, :repo, Lockspire.TestRepo)

    unless Process.whereis(Lockspire.TestRepo) do
      start_supervised!(Lockspire.TestRepo)
    end

    Sandbox.mode(Lockspire.TestRepo, :manual)
    :ok
  end

  setup do
    :ok = Sandbox.checkout(Lockspire.TestRepo)
    previous_client_store = Application.fetch_env(:lockspire, :client_store)
    previous_transaction_store = Application.fetch_env(:lockspire, :transaction_store)

    Application.put_env(
      :lockspire,
      :client_store,
      Lockspire.TestSupport.DelegatedVerifierMaintenanceStore
    )

    Application.put_env(
      :lockspire,
      :transaction_store,
      Lockspire.TestSupport.DelegatedVerifierMaintenanceStore
    )

    cache_key = Lockspire.Config.client_secret_verifier_cache_key()
    previous_context = Application.fetch_env(:lockspire, Lockspire.Security.ClientSecretVerifier)
    previous_cache = :persistent_term.get(cache_key, :missing)

    Application.put_env(:lockspire, Lockspire.Security.ClientSecretVerifier,
      keys: [
        {"maintenance-test", :crypto.hash(:sha256, "phase 177 admin test") |> Base.encode64()}
      ],
      current: "maintenance-test",
      write_mode: :dedicated,
      legacy_read: :allow
    )

    {:ok, %Lockspire.Security.ClientSecretVerifier.Context{state: :valid}} =
      Lockspire.Application.resolve_client_secret_verifier()

    on_exit(fn ->
      case previous_context do
        {:ok, config} ->
          Application.put_env(:lockspire, Lockspire.Security.ClientSecretVerifier, config)

        :error ->
          Application.delete_env(:lockspire, Lockspire.Security.ClientSecretVerifier)
      end

      case previous_cache do
        :missing -> :persistent_term.erase(cache_key)
        context -> :persistent_term.put(cache_key, context)
      end

      restore_env(:client_store, previous_client_store)
      restore_env(:transaction_store, previous_transaction_store)
    end)

    :ok
  end

  @tag :integration
  @tag :admin_maintenance
  test "fresh check accepts inspected public clients with no secret material" do
    client_id = "admin-verifier-no-material-#{System.unique_integer([:positive])}"

    client = %Client{
      lifetime_version: 0,
      client_id: client_id,
      client_type: :public,
      name: "Public test client",
      redirect_uris: [],
      allowed_scopes: [],
      allowed_grant_types: [],
      allowed_response_types: [],
      token_endpoint_auth_method: :none,
      pkce_required: true,
      subject_type: :public,
      created_at: DateTime.utc_now()
    }

    assert {:ok, %Client{}} = Repository.register_client(client)
    assert {:ok, before} = Repository.fetch_client_by_id(client_id)

    assert {:ok, report} = Lockspire.Admin.ClientVerifierMaintenance.run(mode: :check)

    assert report.mode == :check
    assert report.scan_complete?
    assert report.custody_condition_met?
    assert report.no_material >= 1
    assert report.committed_changed == 0
    assert report.context_source == :serving_node_startup

    assert {:ok, after_check} = Repository.fetch_client_by_id(client_id)
    assert after_check == before

    assert %ClientRecord{} =
             record = Lockspire.TestRepo.get_by(ClientRecord, client_id: client_id)

    assert record.client_secret_hash == nil
    assert record.client_secret_jwt_verifier_encrypted == nil
  end

  defp restore_env(key, {:ok, value}), do: Application.put_env(:lockspire, key, value)
  defp restore_env(key, :error), do: Application.delete_env(:lockspire, key)
end
