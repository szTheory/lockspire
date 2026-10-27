defmodule CleanRoomProvider.VerifierDisclosure do
  @moduledoc false

  alias CleanRoomProvider.Repo
  alias Lockspire.Admin.ClientVerifierMaintenance
  alias Lockspire.Admin.Clients
  alias Lockspire.Clients.RegistrationResult
  alias Lockspire.Domain.Client
  alias Lockspire.Security.ClientSecretVerifier
  alias Lockspire.Security.ClientSecretVerifier.Context

  require Logger

  @logger_handler :clean_room_verifier_disclosure
  @query_event [:clean_room_provider, :repo, :query]

  def seed(client_ids, handoff_path) do
    clients =
      Map.new(client_ids, fn client_id ->
        Process.put(:verifier_disclosure_stage, :registration)

        {:ok, %RegistrationResult{client: client, client_secret: secret}} =
          Lockspire.Clients.register_client(%{
            client_id: client_id,
            client_type: "confidential",
            name: "Installed disclosure proof",
            redirect_uris: ["https://client.example/callback"],
            allowed_scopes: ["openid"],
            allowed_grant_types: ["authorization_code"],
            token_endpoint_auth_method: "client_secret_jwt",
            token_endpoint_auth_signing_alg: "HS256"
          })

        Process.put(:verifier_disclosure_stage, :nested_inspection)
        inspection = inspect(%{registration: %{client: client}})
        Process.put(:verifier_disclosure_stage, :audit_projection)

        {client_id,
         %{
           "client_id" => client_id,
           "secret" => secret,
           "ciphertext" => client.client_secret_jwt_verifier_encrypted,
           "nested_inspection_redacted" => not String.contains?(inspection, secret),
           "audit_before" => audit_count(client_id)
         }}
      end)

    write_private(handoff_path, %{clients: clients})
    IO.puts("VERIFIER_DISCLOSURE_SEEDED=true")
  rescue
    _error ->
      stage = Process.get(:verifier_disclosure_stage, :host_setup)

      safe_stage =
        if stage in [:registration, :nested_inspection, :audit_projection],
          do: stage,
          else: :host_setup

      write_private(handoff_path, %{failure_stage: safe_stage})
      IO.puts("VERIFIER_DISCLOSURE_SEED_FAILURE=" <> Atom.to_string(safe_stage))
  end

  def rotate(client_id, handoff_path) do
    {:ok, %{client: %Client{} = client, client_secret: secret}} =
      Clients.rotate_client_secret(client_id,
        actor: %{type: :operator, id: "phase178-disclosure"}
      )

    inspection = inspect(%{rotated_client: client, stored: %{client: client}})

    write_private(handoff_path, %{
      "client_id" => client_id,
      "secret" => secret,
      "ciphertext" => client.client_secret_jwt_verifier_encrypted,
      "nested_inspection_redacted" => not String.contains?(inspection, secret)
    })

    IO.puts("VERIFIER_DISCLOSURE_ROTATED=true")
  end

  def capture_success_from_file(path, sentinels) do
    handoff = read_private(path)
    capture(handoff["client_id"], handoff["ciphertext"], sentinels)
  end

  def audit_projection_from_file(path) do
    handoff = read_private(path)

    payload =
      audit_projection(
        handoff["client_id"],
        handoff["audit_before"],
        handoff["ciphertext"]
      )

    IO.puts("VERIFIER_DISCLOSURE_AUDIT_JSON=" <> Jason.encode!(payload))
    payload
  end

  def seed_failure_from_file(path) do
    input = read_private(path)
    scenario = input["scenario"]
    client_id = input["client_id"]

    {:ok, %RegistrationResult{client: client, client_secret: secret}} =
      Lockspire.Clients.register_client(%{
        client_id: client_id,
        client_type: "confidential",
        name: "Installed disclosure failure proof",
        redirect_uris: ["https://client.example/callback"],
        allowed_scopes: ["openid"],
        allowed_grant_types: ["authorization_code"],
        token_endpoint_auth_method: "client_secret_jwt",
        token_endpoint_auth_signing_alg: "HS256"
      })

    ciphertext = failure_ciphertext(scenario, client_id, secret)
    replace_verifier(client_id, ciphertext)

    write_private(input["handoff_path"], %{
      "scenario" => scenario,
      "client_id" => client_id,
      "secret" => secret,
      "ciphertext" => ciphertext,
      "audit_before" => audit_count(client_id)
    })

    IO.puts("VERIFIER_DISCLOSURE_FAILURE_SEEDED=true")
  end

  def capture_failure_from_file(path, sentinels) do
    handoff = read_private(path)
    trigger = if handoff["scenario"] == "storage_failure", do: install_storage_failure()

    try do
      payload = capture_failure(handoff, sentinels, trigger)
      IO.puts("VERIFIER_DISCLOSURE_FAILURE_CAPTURE_JSON=" <> Jason.encode!(payload))
      payload
    after
      if trigger, do: remove_storage_failure(trigger)
    end
  end

  def capture(client_id, expected_ciphertext, sentinels) do
    capture(sentinels, client_id, expected_ciphertext, fn ->
      Mix.Task.reenable("lockspire.clients.verifier.rewrap")
      Mix.Task.run("lockspire.clients.verifier.rewrap", ["--limit", "100"])
    end)
  end

  def audit_projection(client_id, before_count, expected_ciphertext) do
    {:ok, client} = Clients.get_client(client_id)
    inspection = inspect(%{client: client, stored: %{client: client}})
    audits = audit_rows(client_id)
    sentinels = decode_sentinels()
    after_count = audit_count(client_id)

    %{
      "audit_projection_safe" =>
        not Enum.any?(sentinels, &String.contains?(inspection <> inspect(audits), &1)),
      "audit_inserted" => after_count > before_count,
      "ciphertext_changed" => client.client_secret_jwt_verifier_encrypted != expected_ciphertext
    }
  end

  defp failure_ciphertext("malformed_crypto", _client_id, _secret), do: "LSCV1.malformed"

  defp failure_ciphertext("unknown_key_crypto", client_id, secret) do
    context = context("disclosure-unknown", System.fetch_env!("LOCKSPIRE_DISCLOSURE_UNKNOWN_KEY"))
    {:ok, ciphertext} = ClientSecretVerifier.seal(context, client_id, secret)
    ciphertext
  end

  defp failure_ciphertext("storage_failure", client_id, secret) do
    context = context("verifier-old", System.fetch_env!("LOCKSPIRE_CLIENT_SECRET_VERIFIER_KEY"))
    {:ok, ciphertext} = ClientSecretVerifier.seal(context, client_id, secret)
    ciphertext
  end

  defp failure_ciphertext(_scenario, _client_id, _secret),
    do: raise("unknown installed disclosure failure scenario")

  defp context(key_id, encoded_key) do
    {:ok, context} =
      Context.resolve(
        {:present,
         [
           keys: [{key_id, encoded_key}],
           current: key_id,
           write_mode: :dedicated,
           legacy_read: :reject
         ]},
        []
      )

    context
  end

  defp replace_verifier(client_id, ciphertext) do
    table = table_name()

    {:ok, %{num_rows: 1}} =
      Repo.query(
        "UPDATE #{table}.lockspire_clients SET client_secret_jwt_verifier_encrypted = $1 WHERE client_id = $2",
        [ciphertext, client_id],
        log: false,
        telemetry_event: nil
      )
  end

  defp capture_failure(handoff, sentinels, trigger) do
    scenario = handoff["scenario"]
    client_id = handoff["client_id"]
    expected_ciphertext = handoff["ciphertext"]
    table = table_name()
    capture_table = :ets.new(:clean_room_verifier_disclosure_failure_capture, [:set, :public])

    :ets.insert(capture_table, [
      {:logger_count, 0},
      {:query_count, 0},
      {:logger_leaks, 0},
      {:query_leaks, 0}
    ])

    ack_ref = make_ref()

    :ok =
      :logger.add_handler(@logger_handler, CleanRoomProvider.VerifierDisclosure.LoggerHandler, %{
        table: capture_table,
        sentinels: sentinels,
        ack: {self(), ack_ref}
      })

    handler_id = {__MODULE__, System.unique_integer([:positive, :monotonic])}

    :ok =
      :telemetry.attach(
        handler_id,
        @query_event,
        &CleanRoomProvider.VerifierDisclosure.QueryHandler.handle_event/4,
        %{table: capture_table, sentinels: sentinels}
      )

    try do
      Logger.info("clean_room_verifier_disclosure_control_start")
      await_logger_ack(ack_ref, :start)

      _ =
        Ecto.Adapters.SQL.query!(
          Repo,
          "SELECT $1::text",
          ["clean-room-disclosure-failure-control"],
          log: :debug
        )

      before_operation = count(capture_table, :logger_count)
      api_result = ClientVerifierMaintenance.run(mode: :apply, limit: 100)
      report = failure_report(api_result)

      cli_failed =
        try do
          Mix.Task.reenable("lockspire.clients.verifier.rewrap")
          Mix.Task.run("lockspire.clients.verifier.rewrap", ["--limit", "100"])
          false
        rescue
          error -> error.__struct__ == Mix.Error
        catch
          _kind, _reason -> false
        end

      Logger.info("clean_room_verifier_disclosure_control_end")
      await_logger_ack(ack_ref, :end)
      after_operation = count(capture_table, :logger_count)

      {:ok, client} = Clients.get_client(client_id)
      audits = audit_rows(client_id)
      inspection = inspect(%{client: client, stored: %{client: client}})
      diagnostic = inspect({report, audits, inspection})
      expected = expected_failure_witness(scenario)

      report_witness =
        Enum.any?(report.details, fn detail ->
          detail.classification == expected.classification and detail.reason == expected.reason
        end)

      payload = %{
        "scenario" => scenario,
        "reason" => expected.reason_text,
        "forced_failure_observed" =>
          match?({:error, _}, api_result) and report.failed > 0 and report_witness and cli_failed,
        "operation_result" =>
          if(match?({:error, _}, api_result), do: "failed", else: "unexpected_success"),
        "failure_detail_count" => report.failed,
        "storage_failure_witness" => storage_failure_reached?(trigger),
        "logger_event_count" => count(capture_table, :logger_count),
        "logger_control_event_count" => 2,
        "logger_operation_event_count" => max(after_operation - before_operation - 1, 0),
        "logger_leak_count" => count(capture_table, :logger_leaks),
        "query_control_event_count" => 1,
        "query_operation_event_count" => max(count(capture_table, :query_count) - 1, 0),
        "query_event_count" => count(capture_table, :query_count),
        "query_leak_count" => count(capture_table, :query_leaks),
        "cli_output_checked" => cli_failed,
        "report_redacted" => no_sentinels?(inspect(report), sentinels),
        "audit_projection_safe" => no_sentinels?(diagnostic, sentinels),
        "audit_unchanged" => audit_count(client_id) == handoff["audit_before"],
        "ciphertext_unchanged" =>
          client.client_secret_jwt_verifier_encrypted == expected_ciphertext,
        "http_status" => 0,
        "http_error_code" => "",
        "http_outcome_safe" => false,
        "output_leak_count" => 0
      }

      payload
    after
      :telemetry.detach(handler_id)
      :logger.remove_handler(@logger_handler)
      :ets.delete(capture_table)
    end
  end

  defp expected_failure_witness("malformed_crypto"),
    do: %{
      classification: :malformed,
      reason: :malformed_verifier,
      reason_text: "malformed_verifier"
    }

  defp expected_failure_witness("unknown_key_crypto"),
    do: %{classification: :unknown_key, reason: :unknown_key, reason_text: "unknown_key"}

  defp expected_failure_witness("storage_failure"),
    do: %{classification: :failed, reason: :maintenance_failed, reason_text: "maintenance_failed"}

  defp failure_report({:error, report}) when is_map(report), do: report
  defp failure_report(_), do: %{failed: 0, details: []}

  defp no_sentinels?(value, sentinels),
    do: not Enum.any?(sentinels, &String.contains?(value, &1))

  defp install_storage_failure do
    suffix = Integer.to_string(System.unique_integer([:positive, :monotonic]))
    table = table_name()
    sequence = "disclosure_failure_sequence_" <> suffix
    function = "disclosure_failure_function_" <> suffix
    trigger = "disclosure_failure_trigger_" <> suffix

    {:ok, _} =
      Repo.query("CREATE SEQUENCE #{table}.#{sequence} AS bigint START WITH 1", [],
        log: false,
        telemetry_event: nil
      )

    {:ok, _} =
      Repo.query(
        "CREATE FUNCTION #{table}.#{function}() RETURNS trigger LANGUAGE plpgsql AS $fn$ BEGIN PERFORM nextval('#{table}.#{sequence}'); RAISE EXCEPTION USING MESSAGE = 'run-owned verifier disclosure storage failure'; END; $fn$",
        [],
        log: false,
        telemetry_event: nil
      )

    {:ok, _} =
      Repo.query(
        "CREATE TRIGGER #{trigger} BEFORE INSERT ON #{table}.lockspire_audit_events FOR EACH ROW EXECUTE FUNCTION #{table}.#{function}()",
        [],
        log: false,
        telemetry_event: nil
      )

    %{table: table, sequence: sequence, function: function, trigger: trigger}
  end

  defp storage_failure_reached?(nil), do: false

  defp storage_failure_reached?(trigger) do
    {:ok, %{rows: [[last_value, is_called]]}} =
      Repo.query("SELECT last_value, is_called FROM #{trigger.table}.#{trigger.sequence}", [],
        log: false,
        telemetry_event: nil
      )

    last_value >= 1 and is_called
  end

  defp remove_storage_failure(nil), do: :ok

  defp remove_storage_failure(trigger) do
    {:ok, _} =
      Repo.query(
        "DROP TRIGGER IF EXISTS #{trigger.trigger} ON #{trigger.table}.lockspire_audit_events",
        [],
        log: false,
        telemetry_event: nil
      )

    {:ok, _} =
      Repo.query("DROP FUNCTION IF EXISTS #{trigger.table}.#{trigger.function}()", [],
        log: false,
        telemetry_event: nil
      )

    {:ok, _} =
      Repo.query("DROP SEQUENCE IF EXISTS #{trigger.table}.#{trigger.sequence}", [],
        log: false,
        telemetry_event: nil
      )

    :ok
  end

  defp capture(sentinels, client_id, expected_ciphertext, operation) do
    table = :ets.new(:clean_room_verifier_disclosure_capture, [:set, :public])

    :ets.insert(table, [
      {:logger_count, 0},
      {:query_count, 0},
      {:logger_leaks, 0},
      {:query_leaks, 0}
    ])

    ack_ref = make_ref()

    :ok =
      :logger.add_handler(@logger_handler, CleanRoomProvider.VerifierDisclosure.LoggerHandler, %{
        table: table,
        sentinels: sentinels,
        ack: {self(), ack_ref}
      })

    handler_id = {__MODULE__, System.unique_integer([:positive, :monotonic])}

    :ok =
      :telemetry.attach(
        handler_id,
        @query_event,
        &CleanRoomProvider.VerifierDisclosure.QueryHandler.handle_event/4,
        %{table: table, sentinels: sentinels}
      )

    try do
      Logger.info("clean_room_verifier_disclosure_control_start")
      await_logger_ack(ack_ref, :start)

      _ =
        Ecto.Adapters.SQL.query!(Repo, "SELECT $1::text", ["clean-room-disclosure-control"],
          log: :debug
        )

      before_operation = count(table, :logger_count)
      operation_result = safe_operation(operation)
      Logger.info("clean_room_verifier_disclosure_control_end")
      await_logger_ack(ack_ref, :end)
      after_operation = count(table, :logger_count)

      {:ok, client} = Clients.get_client(client_id)
      inspection = inspect(%{client: client, stored: %{client: client}})

      payload = %{
        "operation_result" => operation_result,
        "logger_control_event_count" => 2,
        "logger_operation_event_count" => max(after_operation - before_operation - 1, 0),
        "logger_event_count" => count(table, :logger_count),
        "query_control_event_count" => 1,
        "query_operation_event_count" => max(count(table, :query_count) - 1, 0),
        "query_event_count" => count(table, :query_count),
        "logger_leak_count" => count(table, :logger_leaks),
        "query_leak_count" => count(table, :query_leaks),
        "nested_inspection_redacted" =>
          not Enum.any?(sentinels, &String.contains?(inspection, &1)),
        "audit_after_count" => audit_count(client_id),
        "ciphertext_changed" => client.client_secret_jwt_verifier_encrypted != expected_ciphertext
      }

      IO.puts("VERIFIER_DISCLOSURE_CAPTURE_JSON=" <> Jason.encode!(payload))
      payload
    after
      :telemetry.detach(handler_id)
      :logger.remove_handler(@logger_handler)
      :ets.delete(table)
    end
  end

  defp await_logger_ack(reference, phase) do
    receive do
      {:verifier_disclosure_logger_ack, ^reference, ^phase} -> :ok
    after
      5_000 -> raise "owned Logger capture acknowledgment timed out"
    end
  end

  defp safe_operation(operation) do
    case operation.() do
      :ok -> "ok"
      _ -> "operation_failed"
    end
  rescue
    _error -> "operation_failed"
  catch
    _kind, _reason -> "operation_failed"
  end

  defp audit_count(client_id) do
    table = table_name()

    {:ok, %{rows: [[count]]}} =
      Repo.query(
        "SELECT count(*) FROM #{table}.lockspire_audit_events WHERE resource_type = 'client' AND resource_id = $1 AND action = 'client_secret_verifier_rewrapped'",
        [client_id],
        log: false,
        telemetry_event: nil
      )

    count
  end

  defp audit_rows(client_id) do
    table = table_name()

    {:ok, %{rows: rows}} =
      Repo.query(
        "SELECT action, outcome, metadata::text FROM #{table}.lockspire_audit_events WHERE resource_type = 'client' AND resource_id = $1",
        [client_id],
        log: false,
        telemetry_event: nil
      )

    rows
  end

  defp count(table, key) do
    case :ets.lookup(table, key) do
      [{^key, value}] -> value
      [] -> 0
    end
  end

  defp decode_sentinels,
    do: System.fetch_env!("LOCKSPIRE_DISCLOSURE_SENTINELS") |> Jason.decode!()

  defp table_name, do: System.fetch_env!("LOCKSPIRE_STORAGE_PREFIX")

  defp write_private(path, value) do
    File.write!(path, Jason.encode!(value), [:binary])
    File.chmod!(path, 0o600)
  end

  defp read_private(path) do
    value = path |> File.read!() |> Jason.decode!()
    File.rm!(path)
    value
  end
end

defmodule CleanRoomProvider.VerifierDisclosure.LoggerHandler do
  @moduledoc false

  def adding_handler(config), do: {:ok, config}
  def changing_config(_set_or_update, _old_config, new_config), do: {:ok, new_config}
  def removing_handler(_config), do: :ok

  def log(event, config) do
    record(config.table, :logger_count, :logger_leaks, event, config.sentinels)
    rendered = inspect(event, limit: :infinity, printable_limit: :infinity)

    if String.contains?(rendered, "clean_room_verifier_disclosure_control_start") do
      send(elem(config.ack, 0), {:verifier_disclosure_logger_ack, elem(config.ack, 1), :start})
    end

    if String.contains?(rendered, "clean_room_verifier_disclosure_control_end") do
      send(elem(config.ack, 0), {:verifier_disclosure_logger_ack, elem(config.ack, 1), :end})
    end

    :ok
  end

  defp record(table, count_key, leak_key, event, sentinels) do
    rendered = inspect(event, limit: :infinity, printable_limit: :infinity)
    :ets.update_counter(table, count_key, {2, 1})

    if Enum.any?(sentinels, &String.contains?(rendered, &1)) do
      :ets.update_counter(table, leak_key, {2, 1})
    end
  end
end

defmodule CleanRoomProvider.VerifierDisclosure.QueryHandler do
  @moduledoc false

  def handle_event(_event, _measurements, metadata, config) do
    rendered = inspect(metadata, limit: :infinity, printable_limit: :infinity)
    :ets.update_counter(config.table, :query_count, {2, 1})

    if Enum.any?(config.sentinels, &String.contains?(rendered, &1)) do
      :ets.update_counter(config.table, :query_leaks, {2, 1})
    end
  end
end
