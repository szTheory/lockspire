defmodule Lockspire.Integration.ClientSecretVerifierMaintenanceDisclosureTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureLog
  import ExUnit.CaptureIO
  import Ecto.Query
  import Phoenix.ConnTest
  import Plug.Conn

  @moduletag :integration

  alias Lockspire.Domain.Client
  alias Lockspire.Security.ClientSecretVerifier
  alias Lockspire.Security.ClientSecretVerifier.Context
  alias Lockspire.Security.Policy
  alias Lockspire.Storage.Ecto.AuditEventRecord
  alias Lockspire.Storage.Ecto.ClientRecord
  alias Ecto.Adapters.SQL.Sandbox
  alias Lockspire.Storage.Ecto.Repository
  alias Lockspire.TestRepo
  alias Lockspire.TestSupport.ClientSecretVerifierFixtures, as: VerifierFixtures

  defmodule UnavailableConnectionRepo do
    use Ecto.Repo,
      otp_app: :lockspire,
      adapter: Ecto.Adapters.Postgres
  end

  setup_all do
    repo_config = Application.fetch_env!(:lockspire, TestRepo)
    Application.put_env(:lockspire, TestRepo, Keyword.put(repo_config, :log, :debug))
    start_supervised!(TestRepo)
    Ecto.Adapters.SQL.Sandbox.mode(TestRepo, :manual)

    on_exit(fn -> Application.put_env(:lockspire, TestRepo, repo_config) end)

    :ok
  end

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(TestRepo)
    :ok
  end

  @tag :red_disclosure
  test "existing client SQL operations hide credentials from Logger and query telemetry" do
    markers = markers()
    client_id = unique_id()
    client = client(client_id, markers)

    capture_log([level: :debug], fn ->
      assert {:ok, _persisted} = Repository.register_client(client)
    end)

    handler_id = {__MODULE__, System.unique_integer([:positive, :monotonic])}

    assert :ok =
             :telemetry.attach(
               handler_id,
               [:lockspire, :test_repo, :query],
               &__MODULE__.capture_query/4,
               self()
             )

    on_exit(fn -> :telemetry.detach(handler_id) end)

    capture_log([level: :debug], fn ->
      assert {:ok, persisted} = Repository.fetch_client_by_id(client_id)
      send(self(), {:persisted_disclosure_client, persisted})
    end)

    assert_receive {:persisted_disclosure_client, persisted}

    control_log =
      capture_log([level: :debug], fn ->
        Ecto.Adapters.SQL.query!(TestRepo, "SELECT $1::text", [markers.verifier], log: :debug)
      end)

    control_events = drain_query_events([])

    require_marker(
      control_log,
      markers.verifier,
      "Logger positive control did not capture SQL result"
    )

    unless Enum.any?(control_events, fn {_event, _measurements, metadata} ->
             includes_marker?(inspect(metadata), markers.verifier)
           end) do
      flunk("query telemetry positive control did not capture stored verifier material")
    end

    sensitive_log =
      capture_log([level: :debug], fn ->
        register_markers =
          Map.put(markers, :management_hash, markers.second_management_hash)

        register_client(client(client_id <> "-register", register_markers))
        fetch_client(client_id)
        list_clients(client_id)
        lock_client(persisted)
        find_by_registration_hash(markers.management_hash)
        update_client(persisted)
        manage_registration(persisted, markers)
        rotate_secret(persisted, markers)
      end)

    sensitive_events = drain_query_events([])

    for marker <- Map.values(markers) do
      refute_marker(sensitive_log, marker, "sensitive client query reached Logger")

      unless Enum.all?(sensitive_events, fn {_event, _measurements, metadata} ->
               not includes_marker?(inspect(metadata), marker)
             end) do
        flunk("sensitive client query material reached query telemetry")
      end
    end
  end

  test "database exceptions are mapped before returning from client-store updates" do
    marker = marker("hostile-database-error")
    client_id = unique_id()

    suffix = Integer.to_string(System.unique_integer([:positive, :monotonic]))
    function = "lockspire_disclosure_failure_" <> suffix
    trigger = "lockspire_disclosure_failure_trigger_" <> suffix

    assert {:ok, persisted} = Repository.register_client(client(client_id, markers()))

    Ecto.Adapters.SQL.query!(
      TestRepo,
      "CREATE FUNCTION #{function}() RETURNS trigger LANGUAGE plpgsql AS $fn$ BEGIN RAISE EXCEPTION USING MESSAGE = '#{marker}'; END; $fn$",
      [],
      log: false
    )

    Ecto.Adapters.SQL.query!(
      TestRepo,
      "CREATE TRIGGER #{trigger} BEFORE UPDATE ON lockspire_clients FOR EACH ROW EXECUTE FUNCTION #{function}()",
      [],
      log: false
    )

    failure_log =
      capture_log([level: :debug], fn ->
        send(
          self(),
          {:database_update_result,
           Repository.update_client(persisted, %{name: "triggered update"})}
        )
      end)

    assert_receive {:database_update_result, result}

    unless result == {:error, :storage_error} do
      flunk("client-store update returned an unsafe database error")
    end

    refute_marker(inspect(result), marker, "database error marker escaped the client store")
    refute_marker(failure_log, marker, "driver failure log disclosed the database error marker")
  end

  test "malformed verifier sentinels stay out of maintenance reports and nested inspections" do
    ciphertext = "LSCV1." <> Base.url_encode64(marker("ciphertext"), padding: false)
    client_id = unique_id() <> "\n\e]52;c;hostile\a"
    client = client(client_id, Map.put(markers(), :verifier, ciphertext))
    put_context(context([{"disclosure-key", :crypto.strong_rand_bytes(32)}], "disclosure-key"))
    assert {:ok, persisted} = Repository.register_client(client)

    report_log =
      capture_log([level: :debug], fn ->
        send(
          self(),
          {:malformed_maintenance_result,
           Lockspire.Admin.ClientVerifierMaintenance.run(mode: :dry_run, limit: 500)}
        )
      end)

    assert_receive {:malformed_maintenance_result, result}

    assert {:error, report} = result
    assert report.scan_complete?
    assert report.failed >= 1

    assert Enum.any?(report.details, fn detail ->
             detail.client_id.value == Base.url_encode64(client_id, padding: false) and
               detail.reason == :malformed_verifier
           end)

    outputs = [report_log, inspect(result), inspect(report), inspect(persisted)]

    for output <- outputs do
      refute_marker(output, ciphertext, "maintenance diagnostic disclosed verifier material")
      refute_marker(output, client_id, "maintenance diagnostic disclosed raw client identifier")
      refute output =~ <<27>>
      refute output =~ <<7>>
    end

    assert Enum.any?(report.details, fn detail ->
             detail.client_id.value == Base.url_encode64(client_id, padding: false)
           end)
  end

  test "client_secret_jwt verifier failure stays generic in the serialized token response" do
    markers = markers()
    plaintext = marker("http-invalid-client-plaintext")
    key = :crypto.hash(:sha256, marker("http-invalid-client-key"))
    client_id = unique_id()
    unavailable_key_context = context([{"unavailable-key", key}], "unavailable-key")

    active_context =
      context([{"active-key", :crypto.hash(:sha256, marker("other-key"))}], "active-key")

    put_context(active_context)

    assert {:ok, ciphertext} =
             ClientSecretVerifier.seal(unavailable_key_context, client_id, plaintext)

    client = %{
      client(client_id, markers)
      | client_secret_hash: Policy.hash_client_secret(plaintext),
        client_secret_jwt_verifier_encrypted: ciphertext
    }

    assert {:ok, persisted} = Repository.register_client(client)
    on_exit(fn -> cleanup_client(persisted.client_id) end)

    {assertion_params, _jti, _issued_at} = VerifierFixtures.assertion(persisted, plaintext)

    handler_id = {__MODULE__, System.unique_integer([:positive, :monotonic])}

    assert :ok =
             :telemetry.attach(
               handler_id,
               [:lockspire, :test_repo, :query],
               &__MODULE__.capture_query/4,
               self()
             )

    on_exit(fn -> :telemetry.detach(handler_id) end)

    log_output =
      capture_log([level: :debug], fn ->
        conn =
          build_conn(
            :post,
            "/token",
            Map.merge(assertion_params, %{
              "grant_type" => "authorization_code",
              "code" => "unused-code",
              "redirect_uri" => "https://client.example.com/callback",
              "code_verifier" => "unused-verifier"
            })
          )
          |> put_req_header("accept", "application/json")
          |> Lockspire.Web.Router.call(Lockspire.Web.Router.init([]))

        send(self(), {:invalid_client_http_conn, conn})
      end)

    assert_receive {:invalid_client_http_conn, conn}
    query_events = drain_query_events([])
    :ok = :telemetry.detach(handler_id)

    assert conn.status == 401

    assert Jason.decode!(conn.resp_body) == %{
             "error" => "invalid_client",
             "error_description" => "Client authentication failed"
           }

    for sensitive <- [plaintext, key, Base.encode64(key), ciphertext, Base.encode64(ciphertext)] do
      refute_marker(conn.resp_body, sensitive, "token response disclosed verifier material")
      refute_marker(log_output, sensitive, "token endpoint Logger disclosed verifier material")

      for {_event, measurements, metadata} <- query_events do
        refute_marker(
          inspect({measurements, metadata}),
          sensitive,
          "token endpoint query telemetry disclosed verifier material"
        )
      end
    end

    refute conn.resp_body =~ client_id

    for sensitive <- [plaintext, key, ciphertext] do
      refute_marker(
        inspect(conn),
        sensitive,
        "token endpoint connection disclosed verifier material"
      )
    end
  end

  test "maintenance maps a real connection-pool acquisition failure to a fixed report" do
    plaintext = marker("pool-failure-plaintext")
    key = :crypto.hash(:sha256, marker("pool-failure-key"))
    ciphertext = "LSCV1." <> Base.url_encode64(marker("pool-failure-ciphertext"), padding: false)
    put_context(context([{"pool-failure-key", key}], "pool-failure-key"))
    original_repo = Application.fetch_env!(:lockspire, :repo)
    original_repo_config = Application.get_env(:lockspire, UnavailableConnectionRepo)

    Application.put_env(
      :lockspire,
      UnavailableConnectionRepo,
      Application.fetch_env!(:lockspire, TestRepo)
      |> Keyword.merge(
        hostname: "127.0.0.1",
        port: 1,
        pool: DBConnection.ConnectionPool,
        pool_size: 1,
        queue_target: 1,
        queue_interval: 1,
        telemetry_prefix: [:lockspire, :unavailable_connection_repo],
        log: :debug
      )
    )

    start_supervised!(UnavailableConnectionRepo)
    Application.put_env(:lockspire, :repo, UnavailableConnectionRepo)

    on_exit(fn ->
      Application.put_env(:lockspire, :repo, original_repo)

      if is_nil(original_repo_config),
        do: Application.delete_env(:lockspire, UnavailableConnectionRepo),
        else: Application.put_env(:lockspire, UnavailableConnectionRepo, original_repo_config)
    end)

    handler_id = {__MODULE__, :connection_failure, System.unique_integer([:positive, :monotonic])}

    assert :ok =
             :telemetry.attach(
               handler_id,
               [:lockspire, :unavailable_connection_repo, :query],
               &__MODULE__.capture_query/4,
               self()
             )

    on_exit(fn -> :telemetry.detach(handler_id) end)

    log_output =
      capture_log([level: :debug], fn ->
        send(
          self(),
          {:connection_failure_result,
           Lockspire.Admin.ClientVerifierMaintenance.run(mode: :check)}
        )
      end)

    assert_receive {:connection_failure_result, result}
    assert {:error, report} = result
    refute report.scan_complete?
    assert report.uninspected > 0
    assert report.failed == 0
    telemetry_events = drain_query_events([])

    cli_output =
      capture_io(fn ->
        assert_raise Mix.Error, fn ->
          Mix.Tasks.Lockspire.Clients.Verifier.Rewrap.run(["--check"])
        end
      end)

    for sensitive <- [plaintext, key, Base.encode64(key), ciphertext, Base.encode64(ciphertext)] do
      refute_marker(
        inspect(result),
        sensitive,
        "connection failure report disclosed verifier material"
      )

      refute_marker(
        log_output,
        sensitive,
        "connection failure Logger disclosed verifier material"
      )

      refute_marker(cli_output, sensitive, "connection failure CLI disclosed verifier material")

      for {_event, measurements, metadata} <- telemetry_events do
        refute_marker(
          inspect({measurements, metadata}),
          sensitive,
          "connection failure telemetry disclosed verifier material"
        )
      end
    end
  end

  test "missing client schema returns a fixed incomplete report without exposing the identifier" do
    marker =
      "lockspire_clients_missing_" <>
        Integer.to_string(System.unique_integer([:positive, :monotonic]))

    put_context(context([{"schema-key", :crypto.strong_rand_bytes(32)}], "schema-key"))

    Ecto.Adapters.SQL.query!(
      TestRepo,
      "ALTER TABLE lockspire_clients RENAME TO #{marker}",
      [],
      log: false
    )

    {log_output, result} =
      try do
        capture_log([level: :debug], fn ->
          send(
            self(),
            {:missing_schema_result, Lockspire.Admin.ClientVerifierMaintenance.run(mode: :check)}
          )
        end)
        |> then(fn log_output ->
          assert_receive {:missing_schema_result, result}
          {log_output, result}
        end)
      after
        Ecto.Adapters.SQL.query!(
          TestRepo,
          "ALTER TABLE #{marker} RENAME TO lockspire_clients",
          [],
          log: false
        )
      end

    assert {:error, report} = result
    refute report.scan_complete?
    assert report.uninspected > 0
    refute_marker(log_output, marker, "missing-schema Logger disclosed a hostile identifier")
    refute_marker(inspect(report), marker, "missing-schema report disclosed a hostile identifier")
    refute_marker(inspect(result), marker, "missing-schema result disclosed a hostile identifier")
  end

  test "failed audit insertion rolls back maintenance and withholds driver diagnostics" do
    marker = marker("audit-driver-failure")
    client_id = unique_id()
    expected = markers()
    assert {:ok, persisted} = Repository.register_client(client(client_id, expected))
    replacement = marker("replacement-ciphertext")
    suffix = Integer.to_string(System.unique_integer([:positive, :monotonic]))
    function = "lockspire_disclosure_audit_" <> suffix
    trigger = "lockspire_disclosure_audit_trigger_" <> suffix

    Ecto.Adapters.SQL.query!(
      TestRepo,
      "CREATE FUNCTION #{function}() RETURNS trigger LANGUAGE plpgsql AS $fn$ BEGIN RAISE EXCEPTION USING MESSAGE = '#{marker}'; END; $fn$",
      [],
      log: false
    )

    Ecto.Adapters.SQL.query!(
      TestRepo,
      "CREATE TRIGGER #{trigger} BEFORE INSERT ON lockspire_audit_events FOR EACH ROW EXECUTE FUNCTION #{function}()",
      [],
      log: false
    )

    {log_output, result} =
      try do
        {capture_log([level: :debug], fn ->
           send(
             self(),
             {:failed_audit_result,
              Repository.transact(fn ->
                Repository.compare_and_rewrap(
                  client_id,
                  expected.hash,
                  expected.verifier,
                  replacement,
                  audit_attrs(client_id)
                )
              end)}
           )
         end), receive_result(:failed_audit_result)}
      after
        Ecto.Adapters.SQL.query!(
          TestRepo,
          "DROP TRIGGER #{trigger} ON lockspire_audit_events",
          [],
          log: false
        )

        Ecto.Adapters.SQL.query!(TestRepo, "DROP FUNCTION #{function}()", [], log: false)
      end

    assert result == {:error, :client_secret_verifier_maintenance_failed}
    refute_marker(log_output, marker, "failed-audit driver log disclosed its diagnostic marker")
    refute_marker(inspect(result), marker, "failed-audit result disclosed its diagnostic marker")
    assert {:ok, after_failure} = Repository.fetch_client_by_id(client_id)
    assert after_failure.client_secret_jwt_verifier_encrypted == expected.verifier

    assert TestRepo.aggregate(
             from(event in AuditEventRecord, where: event.resource_id == ^client_id),
             :count
           ) == 0

    assert persisted.client_secret_jwt_verifier_encrypted == expected.verifier
  end

  test "successful maintenance keeps real plaintext, key bytes and ciphertext out of owned channels" do
    plaintext = marker("maintenance-plaintext")
    old_key = :crypto.hash(:sha256, marker("maintenance-key-bytes"))
    old_key_encoded = Base.encode64(old_key)
    new_key = :crypto.hash(:sha256, marker("maintenance-next-key-bytes"))
    new_key_encoded = Base.encode64(new_key)
    client_id = unique_id()
    old_context = context([{"disclosure-old", old_key}], "disclosure-old")

    current_context =
      context([{"disclosure-old", old_key}, {"disclosure-new", new_key}], "disclosure-new")

    put_context(current_context)
    assert {:ok, ciphertext} = ClientSecretVerifier.seal(old_context, client_id, plaintext)
    encoded_ciphertext = Base.encode64(ciphertext)

    fixture = %Client{
      client_id: client_id,
      client_secret_hash: Policy.hash_client_secret(plaintext),
      client_secret_jwt_verifier_encrypted: ciphertext,
      client_type: :confidential,
      name: "Disclosure maintenance client",
      redirect_uris: [],
      allowed_scopes: [],
      allowed_grant_types: [],
      allowed_response_types: [],
      token_endpoint_auth_method: :client_secret_jwt,
      pkce_required: true,
      subject_type: :public,
      active: true,
      provenance: :operator,
      lifetime_version: 0
    }

    assert {:ok, _persisted} =
             Sandbox.unboxed_run(TestRepo, fn -> Repository.register_client(fixture) end)

    on_exit(fn -> cleanup_client(client_id) end)

    handler_id = {__MODULE__, System.unique_integer([:positive, :monotonic])}

    assert :ok =
             :telemetry.attach(
               handler_id,
               [:lockspire, :test_repo, :query],
               &__MODULE__.capture_query/4,
               self()
             )

    on_exit(fn -> :telemetry.detach(handler_id) end)

    log_output =
      capture_log([level: :debug], fn ->
        assert {:ok, report} =
                 Sandbox.unboxed_run(TestRepo, fn ->
                   Lockspire.Admin.ClientVerifierMaintenance.run(mode: :apply, limit: 500)
                 end)

        send(self(), {:maintenance_disclosure_report, report})
      end)

    assert_receive {:maintenance_disclosure_report, report}
    assert report.committed_changed >= 1
    assert report.scan_complete?
    query_events = drain_query_events([])
    :ok = :telemetry.detach(handler_id)

    for {_event, measurements, metadata} <- query_events do
      for sensitive <- [
            plaintext,
            old_key,
            old_key_encoded,
            new_key,
            new_key_encoded,
            ciphertext,
            encoded_ciphertext
          ] do
        refute_marker(
          inspect({measurements, metadata}),
          sensitive,
          "query telemetry disclosed maintenance material"
        )
      end
    end

    audits =
      Sandbox.unboxed_run(TestRepo, fn ->
        TestRepo.all(
          from(event in AuditEventRecord,
            where:
              event.resource_id == ^client_id and
                event.action == "client_secret_verifier_rewrapped"
          )
        )
      end)

    assert length(audits) == 1
    [audit] = audits
    assert audit.outcome == "succeeded"

    for sensitive <- [
          plaintext,
          old_key,
          old_key_encoded,
          new_key,
          new_key_encoded,
          ciphertext,
          encoded_ciphertext
        ] do
      refute_marker(inspect(report), sensitive, "maintenance report disclosed secret material")
      refute_marker(inspect(audit), sensitive, "maintenance audit disclosed secret material")
      refute_marker(log_output, sensitive, "maintenance Logger disclosed secret material")
    end
  end

  def capture_query(event, measurements, metadata, owner) do
    send(owner, {:client_query_event, event, measurements, metadata})
  end

  defp register_client(client), do: assert_ok(Repository.register_client(client))

  defp fetch_client(client_id), do: assert_ok(Repository.fetch_client_by_id(client_id))

  defp list_clients(client_id), do: assert_ok(Repository.list_clients(search: client_id))

  defp lock_client(%Client{client_id: client_id}) do
    assert_ok(Repository.transact(fn -> Repository.lock_clients([client_id]) end))
  end

  defp find_by_registration_hash(hash),
    do: assert_ok(Repository.get_client_by_registration_access_token_hash(hash))

  defp update_client(%Client{} = client) do
    assert_ok(Repository.update_client(client, %{name: "updated client"}))
  end

  defp manage_registration(%Client{} = client, markers) do
    audit = audit_attrs(client.client_id)

    assert {:ok, _rotated} =
             Repository.rotate_registration_access_token(
               client,
               markers.replacement_management_hash,
               audit
             )

    assert {:ok, current} = Repository.fetch_client_by_id(client.client_id)
    replacement = %{current | name: "replaced registration"}

    assert {:ok, _replaced} =
             Repository.replace_client_registration(
               current,
               replacement,
               markers.next_management_hash,
               audit
             )

    :ok
  end

  defp rotate_secret(%Client{} = client, markers) do
    assert {:ok, current} = Repository.fetch_client_by_id(client.client_id)

    assert {:ok, _rotated} =
             Repository.rotate_client_secret(
               current,
               markers.rotated_hash,
               markers.rotated_verifier,
               DateTime.utc_now()
             )

    :ok
  end

  defp audit_attrs(client_id) do
    %{
      action: :client_secret_verifier_rewrapped,
      outcome: :succeeded,
      actor: %{type: :system},
      resource: %{type: :client, id: client_id},
      metadata: %{maintenance_at: DateTime.utc_now()}
    }
  end

  defp receive_result(tag) do
    receive do
      {^tag, result} -> result
    after
      1_000 -> flunk("expected captured result message")
    end
  end

  defp client(client_id, markers) do
    %Client{
      client_id: client_id,
      client_secret_hash: markers.hash,
      client_secret_jwt_verifier_encrypted: markers.verifier,
      registration_access_token_hash: markers.management_hash,
      client_type: :confidential,
      name: "Disclosure test client",
      redirect_uris: [],
      allowed_scopes: [],
      allowed_grant_types: [],
      allowed_response_types: [],
      token_endpoint_auth_method: :client_secret_jwt,
      pkce_required: true,
      subject_type: :public,
      active: true,
      provenance: :operator,
      lifetime_version: 0
    }
  end

  defp markers do
    %{
      hash: marker("client-hash"),
      verifier: marker("jwt-verifier"),
      management_hash: marker("registration-hash"),
      second_management_hash: marker("second-registration-hash"),
      replacement_management_hash: marker("replacement-registration-hash"),
      next_management_hash: marker("next-registration-hash"),
      rotated_hash: marker("rotated-client-hash"),
      rotated_verifier: marker("rotated-verifier")
    }
  end

  defp marker(kind), do: "stored-secret-sentinel-" <> kind

  defp context(keys, current) do
    {:ok, resolved} =
      Context.resolve(
        {:present,
         [
           keys: Enum.map(keys, fn {id, key} -> {id, Base.url_encode64(key, padding: false)} end),
           current: current,
           write_mode: :dedicated,
           legacy_read: :allow
         ]},
        []
      )

    {:ok, valid} = Context.validate(resolved)
    valid
  end

  defp put_context(context) do
    cache_key = Lockspire.Config.client_secret_verifier_cache_key()
    previous_context = :persistent_term.get(cache_key, :missing)
    :persistent_term.put(cache_key, context)

    on_exit(fn ->
      if previous_context == :missing,
        do: :persistent_term.erase(cache_key),
        else: :persistent_term.put(cache_key, previous_context)
    end)
  end

  defp cleanup_client(client_id) do
    Sandbox.unboxed_run(TestRepo, fn ->
      TestRepo.delete_all(from(event in AuditEventRecord, where: event.resource_id == ^client_id))
      TestRepo.delete_all(from(client in ClientRecord, where: client.client_id == ^client_id))
    end)
  end

  defp unique_id,
    do: "disclosure-" <> Base.url_encode64(:crypto.strong_rand_bytes(12), padding: false)

  defp drain_query_events(events) do
    receive do
      {:client_query_event, event, measurements, metadata} ->
        drain_query_events([{event, measurements, metadata} | events])
    after
      0 -> Enum.reverse(events)
    end
  end

  defp includes_marker?(value, marker), do: String.contains?(value, marker)

  defp require_marker(value, marker, message) do
    unless includes_marker?(value, marker), do: flunk(message)
  end

  defp refute_marker(value, marker, message) do
    if includes_marker?(value, marker), do: flunk(message)
  end

  defp assert_ok({:ok, _result}), do: :ok

  defp assert_ok({:error, reason}) when is_atom(reason),
    do: flunk("client operation error: #{reason}")

  defp assert_ok({:error, %{__struct__: module}}),
    do: flunk("client operation returned an error struct: #{inspect(module)}")

  defp assert_ok(_result), do: flunk("client repository operation did not succeed")
end
