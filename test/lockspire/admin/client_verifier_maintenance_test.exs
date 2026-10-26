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
    Application.delete_env(:lockspire, :test_verifier_inventory_page)

    Process.delete(
      {Lockspire.TestSupport.DelegatedVerifierMaintenanceStore, :inventory_page_index}
    )

    Application.put_env(:lockspire, Lockspire.Security.ClientSecretVerifier,
      keys: [
        {"old-maintenance-test",
         :crypto.hash(:sha256, "phase 177 old admin test") |> Base.encode64()},
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
      Application.delete_env(:lockspire, :test_verifier_inventory_page)

      Process.delete(
        {Lockspire.TestSupport.DelegatedVerifierMaintenanceStore, :inventory_page_index}
      )
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
    assert report.context_source == :startup

    assert {:ok, after_check} = Repository.fetch_client_by_id(client_id)
    assert after_check == before

    assert %ClientRecord{} =
             record = Lockspire.TestRepo.get_by(ClientRecord, client_id: client_id)

    assert record.client_secret_hash == nil
    assert record.client_secret_jwt_verifier_encrypted == nil
  end

  @tag :integration
  test "dry-run reports pending old-key material without changing ciphertext" do
    client_id = "admin-verifier-old-key-#{System.unique_integer([:positive])}"
    {hash, secret} = Lockspire.Clients.rotate_secret_hash()

    assert {:ok, verifier} =
             Lockspire.Security.ClientSecretVerifier.seal(old_context(), client_id, secret)

    assert {:ok, %Client{}} = Repository.register_client(secret_client(client_id, hash, verifier))
    assert {:ok, before} = Repository.fetch_client_by_id(client_id)

    assert {:ok, report} = Lockspire.Admin.ClientVerifierMaintenance.run(mode: :dry_run)

    assert report.scan_complete?
    assert report.pending >= 1
    assert report.committed_changed == 0
    refute report.custody_condition_met?
    assert {:ok, after_preview} = Repository.fetch_client_by_id(client_id)

    assert after_preview.client_secret_jwt_verifier_encrypted ==
             before.client_secret_jwt_verifier_encrypted
  end

  @tag :integration
  test "apply counts committed rewraps and readiness requires a fresh check" do
    client_id = "admin-verifier-apply-#{System.unique_integer([:positive])}"
    {hash, secret} = Lockspire.Clients.rotate_secret_hash()

    assert {:ok, verifier} =
             Lockspire.Security.ClientSecretVerifier.seal(old_context(), client_id, secret)

    assert {:ok, %Client{}} = Repository.register_client(secret_client(client_id, hash, verifier))

    assert {:ok, applied} = Lockspire.Admin.ClientVerifierMaintenance.run(mode: :apply)
    assert applied.committed_changed >= 1
    refute applied.custody_condition_met?
    assert Enum.any?(applied.details, &(&1.classification == :old_key and &1.outcome == :changed))

    assert {:ok, checked} = Lockspire.Admin.ClientVerifierMaintenance.run(mode: :check)
    assert checked.scan_complete?
    assert checked.custody_condition_met?
    assert checked.committed_changed == 0
  end

  @tag :integration
  test "partial apply preserves committed progress when a later page is malformed" do
    client_id = "admin-verifier-partial-#{System.unique_integer([:positive])}"
    {hash, secret} = Lockspire.Clients.rotate_secret_hash()

    assert {:ok, verifier} =
             Lockspire.Security.ClientSecretVerifier.seal(old_context(), client_id, secret)

    assert {:ok, %Client{}} = Repository.register_client(secret_client(client_id, hash, verifier))
    assert {:ok, persisted} = Repository.fetch_client_by_id(client_id)

    Application.put_env(
      :lockspire,
      :test_verifier_inventory_page,
      {:pages,
       [
         %{clients: [persisted], next_cursor: client_id, complete?: false},
         %{
           clients: [fixture_client("duplicate"), fixture_client("duplicate")],
           next_cursor: nil,
           complete?: true
         }
       ]}
    )

    assert {:error, report} =
             Lockspire.Admin.ClientVerifierMaintenance.run(mode: :apply, limit: 1)

    assert report.committed_changed == 1
    refute report.scan_complete?
    refute report.custody_condition_met?
    assert report.uninspected == 2
  end

  test "malformed duplicate pages remain incomplete and cannot establish readiness" do
    duplicate = fixture_client("duplicate-page-client")

    Application.put_env(
      :lockspire,
      :test_verifier_inventory_page,
      {:fixed, %{clients: [duplicate, duplicate], next_cursor: nil, complete?: true}}
    )

    assert {:error, report} = Lockspire.Admin.ClientVerifierMaintenance.run(mode: :check)
    refute report.scan_complete?
    refute report.custody_condition_met?
    assert report.uninspected == 2

    Application.put_env(
      :lockspire,
      :test_verifier_inventory_page,
      {:fixed,
       %{
         clients: [fixture_client("zz-ordered-client")],
         next_cursor: "resume-cursor",
         complete?: false
       }}
    )

    assert {:error, resumed} =
             Lockspire.Admin.ClientVerifierMaintenance.run(
               mode: :dry_run,
               after_client_id: "resume-cursor"
             )

    refute resumed.scan_complete?
    assert resumed.uninspected == 1
  end

  test "missing expected material, orphan ciphertext, and malformed custody stay distinct" do
    clients = [
      %Client{
        fixture_client("a-missing-hash")
        | client_type: :confidential,
          token_endpoint_auth_method: :client_secret_jwt
      },
      %Client{
        fixture_client("b-orphan-verifier")
        | client_secret_jwt_verifier_encrypted: "malformed-envelope"
      },
      %Client{
        fixture_client("c-malformed-custody")
        | client_type: :confidential,
          token_endpoint_auth_method: :client_secret_jwt,
          client_secret_hash: "stored-hash",
          client_secret_jwt_verifier_encrypted: "malformed-envelope"
      }
    ]

    Application.put_env(:lockspire, :test_verifier_inventory_page, {:clients, clients})

    assert {:error, report} = Lockspire.Admin.ClientVerifierMaintenance.run(mode: :check)
    assert report.failed == 3
    refute report.custody_condition_met?
    assert Map.get(report.detail_counts, :missing_material) == 1
    assert Map.get(report.detail_counts, :orphan_verifier) == 1
    assert Map.get(report.detail_counts, :malformed) == 1
    refute inspect(report) =~ "stored-hash"
    refute inspect(report) =~ "malformed-envelope"
  end

  test "an unauthenticated foreign key header is reported as unknown without a key ID" do
    client_id = "unknown-key-client"
    {hash, secret} = Lockspire.Clients.rotate_secret_hash()
    foreign_key = :crypto.hash(:sha256, "foreign custody key") |> Base.encode64()

    {:ok, foreign_context} =
      Lockspire.Security.ClientSecretVerifier.Context.resolve(
        {:present,
         [
           keys: [{"foreign", foreign_key}],
           current: "foreign",
           write_mode: :dedicated,
           legacy_read: :allow
         ]},
        []
      )

    assert {:ok, verifier} =
             Lockspire.Security.ClientSecretVerifier.seal(foreign_context, client_id, secret)

    Application.put_env(
      :lockspire,
      :test_verifier_inventory_page,
      {:clients, [secret_client(client_id, hash, verifier)]}
    )

    assert {:error, report} = Lockspire.Admin.ClientVerifierMaintenance.run(mode: :check)
    assert report.failed == 1
    [entry] = report.details
    assert entry.classification == :unknown_key
    assert entry.key_id == nil
    refute report.custody_condition_met?
    refute inspect(report) =~ "foreign"
  end

  test "inventory detail retention is capped and explicitly reports truncation" do
    clients =
      for n <- 1..101,
          do: fixture_client("bounded-detail-#{String.pad_leading(to_string(n), 3, "0")}")

    Application.put_env(:lockspire, :test_verifier_inventory_page, {:clients, clients})

    assert {:ok, report} = Lockspire.Admin.ClientVerifierMaintenance.run(mode: :check, limit: 200)
    assert report.scanned == 101
    assert report.no_material == 101
    assert length(report.details) == 100
    assert report.details_truncated?
  end

  test "invalid check cursor is rejected before inventory access" do
    assert {:error, :client_secret_verifier_maintenance_check_requires_fresh_scan} =
             Lockspire.Admin.ClientVerifierMaintenance.run(
               mode: :check,
               after_client_id: "resume"
             )

    refute_received {:inventory_page, _}

    assert {:error, :client_secret_verifier_maintenance_invalid_options} =
             Lockspire.Admin.ClientVerifierMaintenance.run([:not_a_keyword])

    assert {:error, :client_secret_verifier_maintenance_invalid_options} =
             Lockspire.Admin.ClientVerifierMaintenance.run(mode: :check, mode: :apply)

    refute_received {:inventory_page, _}
  end

  test "report identities safely encode control and oversized client IDs" do
    control_id = "safe\nINJECT"
    oversized_id = String.duplicate("x", 600)

    Application.put_env(
      :lockspire,
      :test_verifier_inventory_page,
      {:clients, [fixture_client(control_id), fixture_client(oversized_id)]}
    )

    assert {:ok, report} = Lockspire.Admin.ClientVerifierMaintenance.run(mode: :check)
    [control_entry, oversized_entry] = report.details
    assert control_entry.client_id.value == Base.url_encode64(control_id, padding: false)
    assert oversized_entry.client_id.encoding == :sha256_prefix
    assert oversized_entry.client_id.truncated?
    refute inspect(report.details) =~ control_id
    refute inspect(report.details) =~ oversized_id
  end

  defp old_context do
    keys = [
      {"old-maintenance-test",
       :crypto.hash(:sha256, "phase 177 old admin test") |> Base.encode64()},
      {"maintenance-test", :crypto.hash(:sha256, "phase 177 admin test") |> Base.encode64()}
    ]

    {:ok, context} =
      Lockspire.Security.ClientSecretVerifier.Context.resolve(
        {:present,
         [
           keys: keys,
           current: "old-maintenance-test",
           write_mode: :dedicated,
           legacy_read: :allow
         ]},
        []
      )

    context
  end

  defp secret_client(client_id, hash, verifier) do
    %Client{
      lifetime_version: 0,
      client_id: client_id,
      client_secret_hash: hash,
      client_secret_jwt_verifier_encrypted: verifier,
      client_type: :confidential,
      name: "Confidential test client",
      redirect_uris: [],
      allowed_scopes: [],
      allowed_grant_types: [],
      allowed_response_types: [],
      token_endpoint_auth_method: :client_secret_jwt,
      pkce_required: true,
      subject_type: :public,
      created_at: DateTime.utc_now()
    }
  end

  defp fixture_client(client_id) do
    %Client{
      client_id: client_id,
      client_type: :public,
      redirect_uris: [],
      allowed_scopes: [],
      allowed_grant_types: [],
      allowed_response_types: [],
      token_endpoint_auth_method: :none,
      subject_type: :public
    }
  end

  defp restore_env(key, {:ok, value}), do: Application.put_env(:lockspire, key, value)
  defp restore_env(key, :error), do: Application.delete_env(:lockspire, key)
end
