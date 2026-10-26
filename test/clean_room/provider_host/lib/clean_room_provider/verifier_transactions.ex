defmodule CleanRoomProvider.VerifierTransactions do
  @moduledoc false

  alias CleanRoomProvider.LifetimeClientStore, as: Store
  alias CleanRoomProvider.Repo
  alias Lockspire.Admin.Clients
  alias Lockspire.Config
  alias Lockspire.Security.ClientSecretVerifier

  @timeout 15_000

  def run_contention do
    rotation_first = rotation_first()
    maintenance_first = maintenance_first()

    %{
      "VPROOF-02-CONTENTION-ROTATION-FIRST" => rotation_first,
      "VPROOF-02-CONTENTION-MAINTENANCE-FIRST" => maintenance_first
    }
  end

  def run_atomicity do
    audit_insert_rollback = audit_insert_rollback()
    outer_rollback = outer_rollback()
    nested_report_and_commit_order = nested_report_and_commit_order()

    %{
      "VPROOF-02-ATOMICITY-AUDIT-INSERT-ROLLBACK" => audit_insert_rollback,
      "VPROOF-02-ATOMICITY-OUTER-ROLLBACK" => outer_rollback,
      "VPROOF-02-ATOMICITY-NESTED-REPORT-AND-COMMIT-ORDER" =>
        nested_report_and_commit_order
    }
  end

  defp rotation_first do
    client_id = seed_client()
    before = row_map!(client_id)
    replacement = replacement!(client_id, before)
    parent = self()

    holder =
      Task.async(fn ->
        Repo.transaction(fn ->
          pid = backend_pid!()
          send(parent, {:holder, :rotation, pid})

          result =
            Clients.rotate_client_secret(client_id, %{
              actor: %{type: :operator, id: "phase178-transaction-proof"}
            })

          case result do
            {:ok, %{client: client}} ->
              expected = {client.client_secret_hash, client.client_secret_jwt_verifier_encrypted}
              send(parent, {:holder_result, :rotation, expected})
              receive do
                {:release_holder, :commit} -> expected
              after
                @timeout -> Repo.rollback(:holder_release_timeout)
              end
            _ -> Repo.rollback(:rotation_failed)
          end
        end)
      end)

    holder_pid = await_holder!(:rotation)
    expected_rotation = await_rotation_result!()
    contender = start_contender(client_id, before, replacement)
    contender_pid = await_contender!(contender)
    require_distinct_pids!(holder_pid, contender_pid)
    await_blocker!(contender_pid, holder_pid)
    send(holder.pid, {:release_holder, :commit})
    {:ok, ^expected_rotation} = Task.await(holder, @timeout)
    {:ok, :material_conflict} = Task.await(contender, @timeout)
    after_row = row_map!(client_id)

    %{
      "outcome" => "pass",
      "executed" => true,
      "holder_backend_pid" => holder_pid,
      "contender_backend_pid" => contender_pid,
      "blocker_observed" => true,
      "material_conflict" => {after_row.hash, after_row.verifier} == expected_rotation and expected_rotation != {before.hash, before.verifier},
      "credential_pair_coherent" => coherent?(after_row),
      "durable_state_verified" => {after_row.hash, after_row.verifier} == expected_rotation
    }
  end

  defp maintenance_first do
    client_id = seed_client()
    before = row_map!(client_id)
    replacement = replacement!(client_id, before)
    parent = self()

    holder =
      Task.async(fn ->
        Repo.transaction(fn ->
          pid = backend_pid!()
          send(parent, {:holder, :maintenance, pid})
          result = Store.compare_and_rewrap(client_id, before.hash, before.verifier, replacement, audit_attrs(client_id))
          {:ok, :changed} = result
          provisional = row_map!(client_id)
          send(parent, {:provisional, provisional.verifier == replacement and provisional.hash == before.hash})
          receive do
            {:release_holder, :commit} -> result
          after
            @timeout -> Repo.rollback(:holder_release_timeout)
          end
        end)
      end)

    holder_pid = await_holder!(:maintenance)
    receive do
      {:provisional, true} -> :ok
    after
      @timeout -> raise "maintenance transaction did not become provisional"
    end
    contender = Task.async(fn ->
      send(parent, {:contender, backend_pid!()})
      Clients.rotate_client_secret(client_id, %{
        actor: %{type: :operator, id: "phase178-transaction-proof"}
      })
    end)
    contender_pid = await_contender!(contender)
    require_distinct_pids!(holder_pid, contender_pid)
    await_blocker!(contender_pid, holder_pid)
    send(holder.pid, {:release_holder, :commit})
    {:ok, {:ok, :changed}} = Task.await(holder, @timeout)
    {:ok, %{client: rotated}} = Task.await(contender, @timeout)
    after_row = row_map!(client_id)

    %{
      "outcome" => "pass",
      "executed" => true,
      "holder_backend_pid" => holder_pid,
      "contender_backend_pid" => contender_pid,
      "blocker_observed" => true,
      "material_conflict" => false,
      "credential_pair_coherent" => coherent?(after_row),
      "durable_state_verified" => {after_row.hash, after_row.verifier} == {rotated.client_secret_hash, rotated.client_secret_jwt_verifier_encrypted}
    }
  end

  defp audit_insert_rollback do
    client_id = seed_client()
    before = row_map!(client_id)
    replacement = replacement!(client_id, before)
    names = install_audit_insert_failure!()

    try do
      result = Store.transact(fn ->
        Store.compare_and_rewrap(client_id, before.hash, before.verifier, replacement, audit_attrs(client_id))
      end)
      reached_insert = sequence_value!(names.sequence) > 0
      after_row = row_map!(client_id)
      absent_audit = audit_count(client_id) == 0

      %{
        "outcome" => "pass",
        "executed" => true,
        "reached_insert" => reached_insert and match?({:error, :client_secret_verifier_maintenance_failed}, result),
        "unchanged_ciphertext" => after_row.verifier == before.verifier,
        "absent_committed_audit" => absent_audit
      }
    after
      drop_audit_insert_failure!(names)
    end
  end

  defp outer_rollback do
    client_id = seed_client()
    before = row_map!(client_id)
    replacement = replacement!(client_id, before)

    result = Store.transact(fn ->
      {:ok, :changed} = Store.compare_and_rewrap(client_id, before.hash, before.verifier, replacement, audit_attrs(client_id))
      provisional = row_map!(client_id)
      if provisional.verifier != replacement or provisional.hash != before.hash, do: Store.rollback(:provisional_state_missing)
      {:error, :phase178_forced_outer_rollback}
    end)

    after_row = row_map!(client_id)
    %{
      "outcome" => "pass",
      "executed" => true,
      "provisional_change_observed" => match?({:error, :phase178_forced_outer_rollback}, result),
      "outer_rollback_observed" => match?({:error, :phase178_forced_outer_rollback}, result),
      "unchanged_ciphertext" => after_row.verifier == before.verifier,
      "absent_committed_audit" => audit_count(client_id) == 0
    }
  end

  defp nested_report_and_commit_order do
    client_id = seed_client()
    before = row_map!(client_id)
    nested = Repo.transaction(fn ->
      result = Lockspire.Admin.ClientVerifierMaintenance.run(mode: :apply, limit: 100)
      after_row = row_map!(client_id)
      {result, after_row == before, Repo.in_transaction?()}
    end)
    {:ok, {report, unchanged_inside, still_in_transaction}} = nested
    nested_rejected = match?({:error, :client_secret_verifier_maintenance_failed}, report)
    after_nested = row_map!(client_id)
    committed_report = Lockspire.Admin.ClientVerifierMaintenance.run(mode: :dry_run, limit: 100)
    report_after_commit = not Repo.in_transaction?() and match?({:ok, _}, committed_report)

    %{
      "outcome" => "pass",
      "executed" => true,
      "nested_report_rejected" => nested_rejected and still_in_transaction,
      "mutation_absent" => unchanged_inside and after_nested == before,
      "success_report_after_commit" => report_after_commit,
      "report_absent_before_commit" => nested_rejected
    }
  end

  defp start_contender(client_id, before, replacement) do
    parent = self()
    Task.async(fn ->
      send(parent, {:contender, backend_pid!()})
      Store.transact(fn ->
        Store.compare_and_rewrap(client_id, before.hash, before.verifier, replacement, audit_attrs(client_id))
      end)
    end)
  end

  defp seed_client do
    client_id = "phase178-transaction-" <> random_suffix()
    attrs = %{
      client_id: client_id,
      client_type: "confidential",
      name: "Installed verifier transaction witness",
      redirect_uris: ["https://client.example/callback"],
      allowed_scopes: ["openid"],
      allowed_grant_types: ["authorization_code"],
      token_endpoint_auth_method: "client_secret_jwt",
      token_endpoint_auth_signing_alg: "HS256"
    }

    {:ok, %{client: %{client_secret_hash: hash, client_secret_jwt_verifier_encrypted: verifier}}} =
      Lockspire.Clients.register_client(attrs)

    if is_binary(hash) and is_binary(verifier), do: client_id, else: raise("seed material missing")
  end

  defp replacement!(client_id, %{hash: hash, verifier: verifier}) do
    context = Config.client_secret_verifier_context([])
    case ClientSecretVerifier.prepare_rewrap(context, client_id, verifier, hash, []) do
      {:ok, replacement, _old_key_id, _new_key_id} when is_binary(replacement) -> replacement
      other -> raise "replacement unavailable: #{inspect(safe_tag(other))}"
    end
  end

  defp row_map!(client_id) do
    prefix = Config.storage_prefix()
    table = if is_binary(prefix), do: "#{prefix}.lockspire_clients", else: "lockspire_clients"
    result = Repo.query!("SELECT client_secret_hash, client_secret_jwt_verifier_encrypted FROM #{table} WHERE client_id = $1", [client_id], log: false, telemetry_event: nil)
    case result.rows do
      [[hash, verifier]] when is_binary(hash) and is_binary(verifier) -> %{hash: hash, verifier: verifier}
      _ -> raise "client state unavailable"
    end
  end

  defp coherent?({hash, verifier}), do: is_binary(hash) and hash != "" and is_binary(verifier) and verifier != ""
  defp coherent?(%{hash: hash, verifier: verifier}), do: coherent?({hash, verifier})

  defp audit_attrs(client_id) do
    now = DateTime.utc_now() |> DateTime.truncate(:microsecond)
    %{
      action: :client_secret_verifier_rewrapped,
      outcome: :succeeded,
      actor: %{type: :system},
      resource: %{type: :client, id: client_id},
      metadata: %{old_key_id: "verifier-old", new_key_id: "verifier-new", maintenance_at: now}
    }
  end

  defp backend_pid! do
    %{rows: [[pid]]} = Repo.query!("SELECT pg_backend_pid()", [], log: false, telemetry_event: nil)
    pid
  end

  defp await_holder!(name) do
    receive do
      {:holder, ^name, pid} -> pid
    after
      @timeout -> raise "transaction holder did not start"
    end
  end

  defp await_rotation_result! do
    receive do
      {:holder_result, :rotation, pair} -> pair
    after
      @timeout -> raise "rotation did not reach the held transaction"
    end
  end

  defp await_contender!(_task) do
    receive do
      {:contender, pid} when is_pid(pid) -> pid
    after
      @timeout -> raise "transaction contender did not start"
    end
  end

  defp require_distinct_pids!(holder, contender) when is_integer(holder) and is_integer(contender) and holder != contender, do: :ok
  defp require_distinct_pids!(_holder, _contender), do: raise("transaction backends were not independent")

  defp await_blocker!(contender_pid, holder_pid, remaining \\ 100)
  defp await_blocker!(_contender, _holder, 0), do: raise("expected PostgreSQL blocker relation was unavailable")
  defp await_blocker!(contender_pid, holder_pid, remaining) do
    %{rows: [[blockers]]} = Repo.query!("SELECT pg_blocking_pids($1)", [contender_pid], log: false, telemetry_event: nil)
    if holder_pid in blockers do
      :ok
    else
      Process.sleep(25)
      await_blocker!(contender_pid, holder_pid, remaining - 1)
    end
  end

  defp install_audit_insert_failure! do
    prefix = Config.storage_prefix()
    schema = if is_binary(prefix), do: prefix, else: "public"
    suffix = random_suffix()
    sequence = "phase178_audit_" <> suffix
    function = "phase178_reject_audit_" <> suffix
    trigger = "phase178_reject_audit_" <> suffix
    Repo.query!("CREATE SEQUENCE #{schema}.#{sequence}", [], log: false, telemetry_event: nil)
    Repo.query!("CREATE FUNCTION #{schema}.#{function}() RETURNS trigger AS $$ BEGIN PERFORM nextval('#{schema}.#{sequence}'); RAISE EXCEPTION 'phase178 audit insert witness'; END; $$ LANGUAGE plpgsql", [], log: false, telemetry_event: nil)
    Repo.query!("CREATE TRIGGER #{trigger} BEFORE INSERT ON #{schema}.lockspire_audit_events FOR EACH ROW EXECUTE FUNCTION #{schema}.#{function}()", [], log: false, telemetry_event: nil)
    %{schema: schema, sequence: sequence, function: function, trigger: trigger}
  end

  defp sequence_value!(sequence) do
    prefix = Config.storage_prefix()
    schema = if is_binary(prefix), do: prefix, else: "public"
    %{rows: [[value]]} = Repo.query!("SELECT last_value FROM #{schema}.#{sequence}", [], log: false, telemetry_event: nil)
    value
  end

  defp drop_audit_insert_failure!(%{schema: schema, sequence: sequence, function: function, trigger: trigger}) do
    Repo.query!("DROP TRIGGER IF EXISTS #{trigger} ON #{schema}.lockspire_audit_events", [], log: false, telemetry_event: nil)
    Repo.query!("DROP FUNCTION IF EXISTS #{schema}.#{function}()", [], log: false, telemetry_event: nil)
    Repo.query!("DROP SEQUENCE IF EXISTS #{schema}.#{sequence}", [], log: false, telemetry_event: nil)
  end

  defp audit_count(client_id) do
    prefix = Config.storage_prefix()
    table = if is_binary(prefix), do: "#{prefix}.lockspire_audit_events", else: "lockspire_audit_events"
    %{rows: [[count]]} = Repo.query!("SELECT count(*) FROM #{table} WHERE resource_type = 'client' AND resource_id = $1 AND action = 'client_secret_verifier_rewrapped'", [client_id], log: false, telemetry_event: nil)
    count
  end

  defp random_suffix, do: Base.encode16(:crypto.strong_rand_bytes(8), case: :lower)
  defp safe_tag({:error, reason}) when is_atom(reason), do: reason
  defp safe_tag(_), do: :unavailable
end
