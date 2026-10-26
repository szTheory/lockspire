defmodule CleanRoomProvider.VerifierRecovery do
  @moduledoc false

  alias CleanRoomProvider.LifetimeClientStore, as: Store
  alias CleanRoomProvider.Repo
  alias Lockspire.Admin.ClientVerifierMaintenance
  alias Lockspire.Config
  alias Lockspire.Security.ClientSecretVerifier
  alias Lockspire.Security.ClientSecretVerifier.Context
  alias Lockspire.Security.Policy

  @timeout 15_000
  @native_cases [
    "VPROOF-02-RECOVERY-PRESERVATION",
    "VPROOF-02-RECOVERY-RETRY-RECONCILIATION",
    "VPROOF-02-RECOVERY-RESTORE-ROTATE",
    "VPROOF-02-RECOVERY-EXPIRED-MIGRATION"
  ]

  def run_recovery(store, issuer) when store in [:builtin, :delegated] do
    mark_stage(:recovery_seed)
    native = seed_jwt_client!("phase178-recovery-native")
    before = fetch_row!(native.client_id)
    old_ciphertext = before.ciphertext
    old_audits = audit_count(native.client_id)

    mark_stage(:recovery_apply)
    {:ok, %{committed_changed: changed}} = ClientVerifierMaintenance.run(mode: :apply, limit: 100)
    maintained = fetch_row!(native.client_id)

    preserve =
      %{
        "outcome" => "pass",
        "executed" => true,
        "hash_preserved" => maintained.hash == before.hash,
        "partner_secret_preserved" => Policy.verify_client_secret(maintained.hash, native.secret),
        "client_fields_preserved" => same_client_except_verifier?(before, maintained),
        "age_metadata_preserved" =>
          native_age_preserved?(native.client_id, maintained.ciphertext),
        "ciphertext_changed" => maintained.ciphertext != old_ciphertext,
        "audit_inserted" => audit_count(native.client_id) == old_audits + 1 and changed >= 1
      }

    mark_stage(:recovery_repeat)
    repeat_report = ClientVerifierMaintenance.run(mode: :apply, limit: 100)
    repeated = fetch_row!(native.client_id)
    interrupted = seed_jwt_client!("phase178-interrupted")
    mark_stage(:recovery_interrupt)
    interruption_not_ready = interrupt_before_rewrap!(interrupted, store)
    indeterminate = seed_jwt_client!("phase178-indeterminate")
    mark_stage(:recovery_indeterminate)
    indeterminate_not_claimed_rollback = simulated_unavailable_reconciles?(indeterminate)

    repeat = %{
      "outcome" => "pass",
      "executed" => true,
      "repeat_no_change" => match?({:ok, %{committed_changed: 0}}, repeat_report),
      "partial_not_ready" => partial_is_not_ready?(store),
      "interruption_not_ready" => interruption_not_ready,
      "indeterminate_not_claimed_rollback" => indeterminate_not_claimed_rollback,
      "fresh_complete_check_ready" => complete_check_ready?(),
      "ciphertext_still_stable" => repeated.ciphertext == maintained.ciphertext
    }

    mark_stage(:recovery_restore_rotation)
    recovery = stage_restore_rotation!(native)
    mark_stage(:recovery_expired_migration)
    expired = expired_migration!(store)

    result = %{
      List.first(@native_cases) => preserve,
      Enum.at(@native_cases, 1) => Map.delete(repeat, "ciphertext_still_stable"),
      Enum.at(@native_cases, 2) => recovery,
      List.last(@native_cases) => expired
    }

    unless issuer == System.fetch_env!("LOCKSPIRE_ISSUER"),
      do: raise("installed issuer does not match configured issuer")

    result
  rescue
    _error -> raise "SAFE_FAILURE_STAGE=#{Process.get({__MODULE__, :stage}, :recovery_unknown)}"
  end

  def run_issuance(store, issuer) when store == :delegated do
    mark_stage(:issuance_seed)
    client = seed_jwt_client!("phase178-issuance")
    code = seed_authorization_code!(client.client_id)
    before = effects(client.client_id)
    first_jti = "issuance-stale-" <> Ecto.UUID.generate()
    Store.set_issuance_control(self(), client.client_id, first_jti)
    Store.set_maintenance_observer(self(), client.client_id)

    try do
      mark_stage(:issuance_auth_barrier)
      stale_request = Task.async(fn -> token_request(issuer, client, code, first_jti) end)
      {request_pid, _auth_backend} = await_barrier!(:authenticated, first_jti)
      durable_jti = jti_present?(client.client_id, first_jti)

      send(
        request_pid,
        {:release_client_verifier_issuance_barrier, issuance_reference(), :authenticated}
      )

      {guard_pid, request_backend} = await_barrier!(:current_row_guard, first_jti)

      unless request_pid == guard_pid,
        do: raise("installed token request changed process between barriers")

      before_maintenance = effects(client.client_id)

      unless durable_jti and before_maintenance.jtis == before.jtis + 1 and
               before_maintenance.tokens == before.tokens and
               before_maintenance.grants == before.grants and
               before_maintenance.code_redeemed_at == before.code_redeemed_at do
        raise "JWT/JTI authentication barrier was reached before durable JTI observation"
      end

      mark_stage(:issuance_maintenance)
      maintenance = Task.async(fn -> ClientVerifierMaintenance.run(mode: :apply, limit: 100) end)
      maintenance_backend = await_maintenance_backend!(client.client_id)
      {:ok, %{committed_changed: changed}} = Task.await(maintenance, @timeout)

      unless changed >= 1,
        do: raise("independent installed maintenance did not commit a verifier change")

      # The authentication/JTI transaction has completed before the guard
      # transaction starts, so PostgreSQL may legitimately reuse that PID.
      # Only the held current-row guard and the concurrent maintenance
      # transaction must have distinct backends.
      distinct_backends = request_backend != maintenance_backend

      send(
        request_pid,
        {:release_client_verifier_issuance_barrier, issuance_reference(), :current_row_guard}
      )

      stale_status = Task.await(stale_request, @timeout)
      after_stale = effects(client.client_id)

      mark_stage(:issuance_replay_fresh)
      replay_status = token_request(issuer, client, code, first_jti)
      after_replay = effects(client.client_id)
      fresh_jti = "issuance-fresh-" <> Ecto.UUID.generate()
      fresh_status = token_request(issuer, client, code, fresh_jti)
      after_fresh = effects(client.client_id)
      Store.clear_issuance_control()
      Store.clear_maintenance_observer()

      %{
        "VPROOF-02-ISSUANCE-#{System.fetch_env!("LOCKSPIRE_PROOF_PAIR")}-STALE-IDENTITY" => %{
          "outcome" => "pass",
          "executed" => true,
          "auth_barrier_reached" => durable_jti,
          "jti_consumption_observed" => durable_jti,
          "pre_guard_barrier_reached" => true,
          "maintenance_committed" => true,
          "backend_pids_distinct" => distinct_backends,
          "stale_identity_rejected" => stale_status == 400,
          "stale_http_status" => stale_status,
          "no_token_issued" => after_stale.tokens == before.tokens,
          "no_grant_created" => after_stale.grants == before.grants,
          "no_code_redemption" => after_stale.code_redeemed_at == before.code_redeemed_at,
          "same_jti_replay_rejected" => replay_status == 400 and after_replay == after_stale,
          "fresh_jti_succeeded" =>
            fresh_status == 200 and after_fresh.tokens == after_stale.tokens + 1,
          "fresh_http_status" => fresh_status
        }
      }
    after
      Store.clear_issuance_control()
      Store.clear_maintenance_observer()
    end
  rescue
    _error -> raise "SAFE_FAILURE_STAGE=#{Process.get({__MODULE__, :stage}, :issuance_unknown)}"
  end

  def run_issuance(_store, _issuer),
    do: raise("installed issuance requires the declared delegated storage composition")

  defp seed_jwt_client!(prefix) do
    client_id = prefix <> "-" <> Ecto.UUID.generate()

    {:ok, %{client: client, client_secret: secret}} =
      Lockspire.Clients.register_client(%{
        client_id: client_id,
        client_type: :confidential,
        name: "Installed verifier recovery witness",
        redirect_uris: ["https://client.example/callback"],
        allowed_scopes: ["openid"],
        allowed_grant_types: ["authorization_code"],
        token_endpoint_auth_method: :client_secret_jwt,
        token_endpoint_auth_signing_alg: :HS256
      })

    old_context = verifier_context("LOCKSPIRE_CLIENT_SECRET_VERIFIER_KEY", "verifier-old")
    {:ok, ciphertext} = ClientSecretVerifier.seal(old_context, client_id, secret)

    %{num_rows: 1} =
      Repo.query!(
        "UPDATE #{table(:lockspire_clients)} SET client_secret_jwt_verifier_encrypted = $1 WHERE client_id = $2",
        [ciphertext, client_id],
        log: false,
        telemetry_event: nil
      )

    %{client: client, client_id: client_id, secret: secret, old_context: old_context}
  end

  defp verifier_context(env_key, key_id) do
    key = System.fetch_env!(env_key)

    {:ok, context} =
      Context.resolve(
        {:present,
         [keys: [{key_id, key}], current: key_id, write_mode: :dedicated, legacy_read: :allow]},
        []
      )

    {:ok, validated} = Context.validate(context)
    validated
  end

  defp fetch_row!(client_id) do
    result =
      Repo.query!(
        "SELECT (to_jsonb(client) - 'client_secret_jwt_verifier_encrypted')::text, client_secret_hash, client_secret_jwt_verifier_encrypted FROM #{table(:lockspire_clients)} AS client WHERE client_id = $1",
        [client_id],
        log: false,
        telemetry_event: nil
      )

    case result.rows do
      [[fields_json, hash, ciphertext]] ->
        %{fields: Jason.decode!(fields_json), hash: hash, ciphertext: ciphertext}

      _ ->
        raise "installed client projection unavailable"
    end
  end

  defp same_client_except_verifier?(before, after_row) do
    before.fields == after_row.fields
  end

  defp native_age_preserved?(client_id, ciphertext) do
    context = Config.client_secret_verifier_context([])

    case ClientSecretVerifier.inspect_custody(
           context,
           client_id,
           ciphertext,
           fetch_row!(client_id).hash,
           []
         ) do
      {:ok, %{age_kind: :native}} -> true
      _ -> false
    end
  end

  defp partial_is_not_ready?(:delegated) do
    System.put_env("LOCKSPIRE_CORE_INVENTORY_MODE", "partial")
    result = ClientVerifierMaintenance.run(mode: :check, limit: 100)
    System.delete_env("LOCKSPIRE_CORE_INVENTORY_MODE")
    match?({:error, _}, result)
  end

  defp partial_is_not_ready?(:builtin) do
    cursor = "phase178-zzzz"

    case ClientVerifierMaintenance.run(mode: :check, after_client_id: cursor, limit: 1) do
      {:error,
       %{
         initial_cursor: ^cursor,
         scan_complete?: true,
         custody_condition_met?: false
       }} ->
        true

      _ ->
        false
    end
  end

  defp interrupt_before_rewrap!(client, :delegated) do
    before = fetch_row!(client.client_id)
    Store.set_run_control(:current_row_guard, self())
    task = Task.async(fn -> ClientVerifierMaintenance.run(mode: :apply, limit: 100) end)

    interrupted =
      receive do
        {:lifetime_client_store_barrier, :current_row_guard, callback_pid, _reference} ->
          callback_pid == task.pid and Process.exit(callback_pid, :kill)
      after
        @timeout -> false
      end

    _ = Task.yield(task, @timeout) || Task.shutdown(task, :brutal_kill)
    Store.clear_run_controls()
    after_row = fetch_row!(client.client_id)

    complete_check_ready?() == false and interrupted and
      after_row.ciphertext == before.ciphertext and
      audit_count(client.client_id) == 0
  after
    Store.clear_run_controls()
  end

  defp interrupt_before_rewrap!(client, :builtin) do
    before = fetch_row!(client.client_id)
    owner = self()
    Process.put({__MODULE__, :previous_trap_exit}, Process.flag(:trap_exit, true))
    mark_stage(:recovery_interrupt_lock_start)

    lock_task =
      Task.async(fn ->
        Repo.transaction(fn ->
          %{rows: [[backend_pid]]} = Repo.query!("SELECT pg_backend_pid()")

          Repo.query!(
            "SELECT client_id FROM #{table(:lockspire_clients)} WHERE client_id = $1 FOR UPDATE",
            [client.client_id],
            log: false,
            telemetry_event: nil
          )

          send(owner, {:recovery_lock_held, self(), backend_pid})

          receive do
            :release_recovery_lock -> :released
          after
            @timeout -> :lock_timeout
          end
        end)
      end)

    Process.put({__MODULE__, :recovery_lock_task}, lock_task.pid)

    {lock_pid, lock_backend} =
      receive do
        {:recovery_lock_held, task_pid, backend_pid} -> {task_pid, backend_pid}
      after
        @timeout -> raise "built-in interruption row lock was not acquired"
      end

    mark_stage(:recovery_interrupt_lock_held)
    apply_task = Task.async(fn -> ClientVerifierMaintenance.run(mode: :apply, limit: 100) end)
    mark_stage(:recovery_interrupt_apply_start)

    blocked =
      await_blocked_maintenance(lock_backend, System.monotonic_time(:millisecond) + @timeout)

    mark_stage(
      if(blocked, do: :recovery_interrupt_blocked, else: :recovery_interrupt_not_blocked)
    )

    mark_stage(:recovery_interrupt_kill)

    if blocked do
      Process.exit(apply_task.pid, :kill)
      _ = Task.yield(apply_task, @timeout) || Task.shutdown(apply_task, :brutal_kill)
    else
      Process.exit(apply_task.pid, :kill)
      _ = Task.yield(apply_task, @timeout) || Task.shutdown(apply_task, :brutal_kill)
    end

    send(lock_pid, :release_recovery_lock)
    mark_stage(:recovery_interrupt_lock_release)
    _ = Task.await(lock_task, @timeout)

    mark_stage(:recovery_interrupt_observe)
    after_row = fetch_row!(client.client_id)

    blocked and complete_check_ready?() == false and
      after_row.ciphertext == before.ciphertext and audit_count(client.client_id) == 0
  after
    mark_stage(:recovery_interrupt_cleanup)

    if is_pid(Process.get({__MODULE__, :recovery_lock_task})),
      do: Process.exit(Process.get({__MODULE__, :recovery_lock_task}), :kill)

    Process.delete({__MODULE__, :recovery_lock_task})

    receive do
      {:EXIT, _linked_task, _reason} -> :ok
    after
      0 -> :ok
    end

    Process.flag(:trap_exit, Process.delete({__MODULE__, :previous_trap_exit}) || false)
  end

  defp await_blocked_maintenance(lock_backend, deadline) do
    %{rows: rows} =
      Repo.query!(
        "SELECT pid FROM pg_stat_activity WHERE wait_event_type = 'Lock' AND $1 = ANY(pg_blocking_pids(pid))",
        [lock_backend],
        log: false,
        telemetry_event: nil
      )

    case rows do
      [[pid] | _] when is_integer(pid) ->
        true

      _ ->
        if System.monotonic_time(:millisecond) < deadline do
          Process.sleep(25)
          await_blocked_maintenance(lock_backend, deadline)
        else
          false
        end
    end
  end

  defp simulated_unavailable_reconciles?(client) do
    before = fetch_row!(client.client_id)

    unavailable_wrapper = fn ->
      result = ClientVerifierMaintenance.run(mode: :apply, limit: 100)

      case result do
        {:ok, %{committed_changed: changed}} when changed > 0 ->
          {:error, :simulated_committed_then_unavailable}

        other ->
          other
      end
    end

    {:error, :simulated_committed_then_unavailable} = unavailable_wrapper.()

    fetch_row!(client.client_id).ciphertext != before.ciphertext and complete_check_ready?()
  end

  defp complete_check_ready? do
    case ClientVerifierMaintenance.run(mode: :check, limit: 100) do
      {:ok,
       %{
         scan_complete?: true,
         custody_condition_met?: true,
         failed: 0,
         pending: 0,
         uninspected: 0
       }} ->
        true

      _ ->
        false
    end
  end

  defp stage_restore_rotation!(native) do
    basic = seed_control_client!(:client_secret_basic)
    post = seed_control_client!(:client_secret_post)

    handoff = %{
      "jwt" => %{"client_id" => native.client_id, "secret" => native.secret},
      "basic" => %{
        "client_id" => basic.client.client_id,
        "secret" => basic.secret
      },
      "post" => %{
        "client_id" => post.client.client_id,
        "secret" => post.secret
      }
    }

    path = System.fetch_env!("LOCKSPIRE_RECOVERY_HANDOFF_PATH")
    :ok = File.write(path, Jason.encode!(handoff), [:binary])
    :ok = File.chmod(path, 0o600)

    %{
      "outcome" => "pending_http_startup_context",
      "executed" => true
    }
  end

  defp seed_control_client!(method) do
    client_id = "phase178-control-" <> Atom.to_string(method) <> "-" <> Ecto.UUID.generate()

    {:ok, %{client: client, client_secret: secret}} =
      Lockspire.Clients.register_client(%{
        client_id: client_id,
        client_type: :confidential,
        name: "Installed auth control",
        redirect_uris: ["https://client.example/callback"],
        allowed_scopes: ["openid"],
        allowed_grant_types: ["authorization_code"],
        token_endpoint_auth_method: method
      })

    %{client: client, secret: secret}
  end

  defp expired_migration!(_store) do
    mark_stage(:expired_seed)
    migrated = seed_jwt_client!("phase178-expired-migrated")
    mark_stage(:expired_migrated_ciphertext)
    now_ms = System.os_time(:millisecond)
    signed_at_ms = now_ms - 120_000
    deadline_ms = signed_at_ms + 60_000

    expired_ciphertext =
      seal_migrated(
        migrated.old_context,
        migrated.client_id,
        migrated.secret,
        signed_at_ms,
        deadline_ms
      )

    mark_stage(:expired_install_migrated)

    %{num_rows: 1} =
      Repo.query!(
        "UPDATE #{table(:lockspire_clients)} SET client_secret_jwt_verifier_encrypted = $1 WHERE client_id = $2",
        [expired_ciphertext, migrated.client_id],
        log: false,
        telemetry_event: nil
      )

    before = fetch_row!(migrated.client_id)
    mark_stage(:expired_apply)
    {:ok, %{committed_changed: changed}} = ClientVerifierMaintenance.run(mode: :apply, limit: 100)
    after_row = fetch_row!(migrated.client_id)
    mark_stage(:expired_http)
    code = seed_authorization_code!(migrated.client_id)

    http_status =
      token_request(
        System.fetch_env!("LOCKSPIRE_ISSUER"),
        migrated,
        code,
        "expired-migrated-" <> Ecto.UUID.generate()
      )

    mark_stage(:expired_metadata)

    metadata_before =
      ClientSecretVerifier.inspect_custody(
        Config.client_secret_verifier_context([]),
        migrated.client_id,
        expired_ciphertext,
        before.hash,
        []
      )

    metadata_after =
      ClientSecretVerifier.inspect_custody(
        Config.client_secret_verifier_context([]),
        migrated.client_id,
        after_row.ciphertext,
        after_row.hash,
        []
      )

    %{
      "outcome" => "pass",
      "executed" => true,
      "expired_rewrap_committed" =>
        changed >= 1 and
          after_row.ciphertext != before.ciphertext,
      "expired_http_auth_rejected" => http_status == 400,
      "deadline_preserved" => same_authenticated_age?(metadata_before, metadata_after)
    }
  end

  defp same_authenticated_age?(
         {:ok,
          %{age_kind: before_kind, signed_at_ms: before_signed, deadline_ms: before_deadline}},
         {:ok, %{age_kind: after_kind, signed_at_ms: after_signed, deadline_ms: after_deadline}}
       ) do
    before_kind == after_kind and before_signed == after_signed and
      before_deadline == after_deadline
  end

  defp same_authenticated_age?(_before, _after), do: false

  defp seal_migrated(context, client_id, secret, signed_at_ms, deadline_ms) do
    key = context.keys[context.current_id]
    iv = :crypto.strong_rand_bytes(12)

    plaintext =
      <<1, byte_size(secret)::unsigned-big-32, secret::binary, 1, signed_at_ms::signed-big-64,
        deadline_ms::signed-big-64>>

    aad =
      "lockspire-client-secret-jwt-verifier" <>
        <<0>> <> "LSCV1" <> <<0>> <> context.current_id <> <<0>> <> client_id

    {ciphertext, tag} =
      :crypto.crypto_one_time_aead(:aes_256_gcm, key, iv, plaintext, aad, 16, true)

    "LSCV1." <>
      context.current_id <>
      "." <> Base.url_encode64(iv <> tag <> ciphertext, padding: false)
  end

  defp seed_authorization_code!(client_id) do
    verifier = "phase178-pkce-" <> Ecto.UUID.generate()
    raw_code = "phase178-code-" <> Ecto.UUID.generate()
    challenge = Base.url_encode64(:crypto.hash(:sha256, verifier), padding: false)
    now = DateTime.utc_now() |> DateTime.truncate(:microsecond)
    interaction_id = "phase178-interaction-" <> Ecto.UUID.generate()

    expires_at = DateTime.add(now, 300, :second)

    mark_stage(:expired_code_interaction)

    %{num_rows: 1} =
      Repo.query!(
        "INSERT INTO #{table(:lockspire_interactions)} (interaction_id, client_id, account_id, scopes_requested, redirect_uri, return_to, state, code_challenge, code_challenge_method, expires_at, status, completed_at, inserted_at, updated_at) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,'S256',$9,'completed',$10,$10,$10)",
        [
          interaction_id,
          client_id,
          "phase178-account",
          ["openid"],
          "https://client.example/callback",
          "/authorize",
          "phase178-state",
          challenge,
          expires_at,
          now
        ],
        log: false,
        telemetry_event: nil
      )

    mark_stage(:expired_code_token)

    %{num_rows: 1} =
      Repo.query!(
        "INSERT INTO #{table(:lockspire_tokens)} (token_hash, token_type, client_id, account_id, interaction_id, redirect_uri, scopes, code_challenge, code_challenge_method, issued_at, expires_at, inserted_at, updated_at) VALUES ($1,'authorization_code',$2,$3,$4,$5,$6,$7,'S256',$8,$9,$8,$8)",
        [
          hash_token(raw_code),
          client_id,
          "phase178-account",
          interaction_id,
          "https://client.example/callback",
          ["openid"],
          challenge,
          now,
          expires_at
        ],
        log: false,
        telemetry_event: nil
      )

    %{raw_code: raw_code, verifier: verifier}
  end

  defp token_request(issuer, client, code, jti) do
    mark_stage(:expired_assertion)

    case Application.ensure_all_started(:inets) do
      {:ok, _started_apps} -> :ok
      {:error, _safe_reason} -> raise "mounted token HTTP client unavailable"
    end

    assertion = signed_assertion(client.client_id, client.secret, issuer, jti)

    body =
      URI.encode_query(%{
        "grant_type" => "authorization_code",
        "code" => code.raw_code,
        "redirect_uri" => "https://client.example/callback",
        "code_verifier" => code.verifier,
        "client_assertion_type" => "urn:ietf:params:oauth:client-assertion-type:jwt-bearer",
        "client_assertion" => assertion
      })

    request =
      {String.to_charlist(issuer <> "/token"), [], ~c"application/x-www-form-urlencoded",
       String.to_charlist(body)}

    mark_stage(:expired_request)

    case :httpc.request(:post, request, [{:timeout, @timeout}], []) do
      {:ok, {{_version, status, _reason}, _headers, _response}} ->
        status

      {:error, {:failed_connect, _details}} ->
        mark_stage(:expired_http_connect)
        raise "mounted token endpoint request failed"

      {:error, :timeout} ->
        mark_stage(:expired_http_timeout)
        raise "mounted token endpoint request failed"

      {:error, _safe_reason} ->
        mark_stage(:expired_http_transport)
        raise "mounted token endpoint request failed"
    end
  rescue
    error ->
      if Process.get({__MODULE__, :stage}) == :expired_request do
        mark_stage(
          case error do
            %ArgumentError{} ->
              :expired_request_argument

            %CaseClauseError{} ->
              :expired_request_case

            %FunctionClauseError{} ->
              :expired_request_function_clause

            %MatchError{} ->
              :expired_request_match

            %ErlangError{} ->
              :expired_request_erlang

            %UndefinedFunctionError{module: :httpc, function: :request, arity: 4} ->
              :expired_request_undefined_httpc

            %UndefinedFunctionError{} ->
              :expired_request_undefined

            %RuntimeError{} ->
              :expired_request_runtime

            %KeyError{} ->
              :expired_request_key

            %BadMapError{} ->
              :expired_request_bad_map

            %BadArityError{} ->
              :expired_request_bad_arity

            %SystemLimitError{} ->
              :expired_request_system_limit

            _ ->
              :expired_request_error
          end
        )
      end

      raise "mounted token endpoint request failed"
  end

  defp signed_assertion(client_id, secret, issuer, jti) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    JOSE.JWK.from_oct(secret)
    |> JOSE.JWT.sign(%{"alg" => "HS256"}, %{
      "iss" => client_id,
      "sub" => client_id,
      "aud" => issuer,
      "jti" => jti,
      "iat" => DateTime.to_unix(now),
      "exp" => DateTime.to_unix(DateTime.add(now, 300, :second))
    })
    |> JOSE.JWS.compact()
    |> elem(1)
  end

  defp effects(client_id) do
    jtis =
      query_count!("SELECT count(*) FROM #{table(:lockspire_used_jtis)} WHERE client_id = $1", [
        client_id
      ])

    tokens =
      query_count!(
        "SELECT count(*) FROM #{table(:lockspire_tokens)} WHERE client_id = $1 AND token_type <> 'authorization_code'",
        [client_id]
      )

    grants =
      query_count!(
        "SELECT count(*) FROM #{table(:lockspire_consent_grants)} WHERE client_id = $1",
        [client_id]
      )

    %{rows: rows} =
      Repo.query!(
        "SELECT redeemed_at FROM #{table(:lockspire_tokens)} WHERE client_id = $1 AND token_type = 'authorization_code'",
        [client_id],
        log: false,
        telemetry_event: nil
      )

    %{
      jtis: jtis,
      tokens: tokens,
      grants: grants,
      code_redeemed_at:
        case rows do
          [[at]] -> at
          _ -> nil
        end
    }
  end

  defp jti_present?(client_id, jti) do
    query_count!(
      "SELECT count(*) FROM #{table(:lockspire_used_jtis)} WHERE client_id = $1 AND jti = $2",
      [client_id, jti]
    ) == 1
  end

  defp audit_count(client_id),
    do:
      query_count!(
        "SELECT count(*) FROM #{table(:lockspire_audit_events)} WHERE resource_id = $1 AND action = 'client_secret_verifier_rewrapped'",
        [client_id]
      )

  defp query_count!(sql, params) do
    %{rows: [[count]]} = Repo.query!(sql, params, log: false, telemetry_event: nil)
    count
  end

  defp table(name) do
    case Config.storage_prefix() do
      prefix when is_binary(prefix) -> "#{prefix}.#{name}"
      _ -> Atom.to_string(name)
    end
  end

  defp await_barrier!(stage, jti) do
    receive do
      {:client_verifier_issuance_barrier, reference, ^stage, client_id, ^jti, backend_pid,
       request_pid}
      when is_binary(client_id) and is_integer(backend_pid) and is_pid(request_pid) ->
        Process.put({__MODULE__, :issuance_reference}, reference)
        {request_pid, backend_pid}
    after
      @timeout ->
        raise "installed mounted token request did not reach the required issuance barrier"
    end
  end

  defp await_maintenance_backend!(client_id) do
    receive do
      {:client_verifier_maintenance_backend, reference, ^client_id, backend_pid}
      when is_reference(reference) and is_integer(backend_pid) ->
        backend_pid
    after
      @timeout -> raise "installed maintenance transaction backend was not observed"
    end
  end

  defp issuance_reference, do: Process.get({__MODULE__, :issuance_reference})

  defp hash_token(token), do: :crypto.hash(:sha256, token) |> Base.encode16(case: :lower)

  defp mark_stage(stage), do: Process.put({__MODULE__, :stage}, stage)
end
