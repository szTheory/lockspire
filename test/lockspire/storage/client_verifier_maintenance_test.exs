defmodule Lockspire.Storage.ClientVerifierMaintenanceTest do
  use ExUnit.Case, async: false

  alias Lockspire.Storage.ClientVerifierMaintenance
  alias Lockspire.Storage.Ecto.Repository

  setup do
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
