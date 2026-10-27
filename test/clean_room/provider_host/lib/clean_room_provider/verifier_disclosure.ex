defmodule CleanRoomProvider.VerifierDisclosure do
  @moduledoc false

  alias CleanRoomProvider.Repo
  alias Lockspire.Admin.Clients
  alias Lockspire.Clients.RegistrationResult
  alias Lockspire.Domain.Client

  require Logger

  @logger_handler :clean_room_verifier_disclosure
  @query_event [:clean_room_provider, :repo, :query]

  def seed(client_ids, handoff_path) do
    try do
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
    try do
      case operation.() do
        :ok -> "ok"
        _ -> "operation_failed"
      end
    rescue
      _error -> "operation_failed"
    catch
      _kind, _reason -> "operation_failed"
    end
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
