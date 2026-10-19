# Phase 158: Mix Task Repo Start - Research

**Researched:** 2026-10-18
**Domain:** Elixir Mix tasks, Ecto repo lifecycle (`Ecto.Migrator.with_repo`), ExUnit cold-start integration tests, Python clean-room harness
**Confidence:** HIGH (every claim below was checked against live code or an executed experiment this session)

<user_constraints>
## User Constraints (from CONTEXT.md)

CONTEXT.md D-01..D-19 are LOCKED. The full text is in `/Users/jon/projects/lockspire/.planning/phases/158-mix-task-repo-start/158-CONTEXT.md`; the planner MUST read it. Summary of the locked shape:

- D-01..D-04: each of the three tasks resolves `Lockspire.Config.repo!()` outside the runner, keeps `@requirements ["app.config"]`, and wraps ONLY its DB work in `Lockspire.Install.RepoRunner.run/2` (client.create: `build_attrs |> Clients.register_client()`; token_format: the whole `with`; remote_jwks: only `Clients.get_client/1`). No `app.start`, no raw `with_repo`, ecto_sql defaults (`pool_size: 2`, `mode: :temporary`), no new deps.
- D-02: the fun only computes tagged tuples; all printing, `Mix.raise`, exit decisions happen after `RepoRunner.run/2` returns.
- D-05..D-08: `RepoRunner` behaviorally unchanged (moduledoc only); a shared helper maps DB failures to fixed safe phrases (never raw exception text); validation errors render one per line; exit semantics preserved (token_format never non-zero).
- D-09..D-12: secret printed once to stdout only after `{:ok, {:ok, result}}`; `@derive {Inspect, except: [:client_secret]}` on `RegistrationResult`; `Logger.put_process_level(self(), :info)` around the fun; crash-after-write documented in help.
- D-13..D-15: one `async: false`, `@moduletag :integration` cold-path module per task; pool-untouched checks in default suite; shared helper `test/support/mix_repo_helpers.ex`.
- D-16..D-19: clean-room steps added after `doctor key_encryption`, output-capturing `run_child_command` variant, reproduce-first commit, telemetry-under-`app.config` check.

### Claude's Discretion
Helper names/locations (D-06, D-15); exact non-`undefined_table` Postgres phrasing; whether to also pass an Ecto sensitive/log option in `client_store.ex:16`.

### Deferred Ideas (OUT OF SCOPE)
Release `bin/app eval` entry point; custom-named / dynamic repos; moving `keys.reencrypt` to RepoRunner; `--format json`; DCR default lifetime audit.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| TASK-01 | three tasks start/stop the repo via RepoRunner; failure reproduced in clean-room first | Reproduced bare (see Bare-Run Evidence); RepoRunner semantics verified; clean-room command + 47 s runtime |
| TASK-02 | real failure reason; secret printed at most once after successful write | Exception-shape table; "reads return `{:error, exception}`, writes raise" finding; log-level experiment |
| TASK-03 | cold-start test per task + pool-untouched check + clean-room invokes all three | Test patterns, helper design, run commands |
| SAFE-02 (constraint) | no secret/key material in output, errors, logs | Logger experiment; `:base` detail leak risk; connection-process log leak |
</phase_requirements>

## Summary

CONTEXT.md's design is sound and every code reference checked out, with three corrections the planner must carry (below). The three tasks fail bare today because `Lockspire.Config.repo!()`'s repo is not started when only `app.config` has run. I reproduced all three on this machine (`MIX_ENV=test mix lockspire.doctor token_format` prints `Could not inspect token formats: %RuntimeError{message: "could not lookup Ecto repo Lockspire.TestRepo because it was not started or it does not exist"}` and exits 0; `remote-jwks` raises `Could not inspect client: %RuntimeError{...}`; `client.create` crashes with a stack trace out of `Lockspire.TestRepo.insert/2`). `RepoRunner.run/2` already does the right thing: direct call if `Process.whereis(repo)` is a pid, otherwise `ensure_all_started(:ecto_sql)` + `with_repo(mode: :temporary)`.

Key new fact for D-06: DB failures reach the tasks in TWO shapes. Read stores (`list_clients`, `fetch_client_by_id`, server-policy read) rescue and RETURN `{:error, exception_struct}`; the write path (`Support.insert`) RAISES. The shared helper therefore needs a classifier that accepts either a returned `{:error, exception}` or a rescued exception, not only a rescue.

**Primary recommendation:** Implement one pure classifier `Lockspire.Install.TaskError` (or similar) with `classify(term) :: String.t()` plus a `run/2` wrapper that (a) rescues inside the fun and returns `{:error, {:db, phrase}}`, (b) is called from each task around `RepoRunner.run/2`; print/raise only after return. Ship the reproduce-first clean-room commit before touching the tasks.

## Verified Corrections to CONTEXT.md

| CONTEXT reference | Reality | Tag |
|---|---|---|
| `policy.ex:190-192,255` | The file is `lib/lockspire/security/policy.ex` (not `lib/lockspire/policy.ex`). `seal_client_secret_jwt_verifier(secret, opts)` list clause is at 190-193; `required_secret_key_base!/1` raise `"missing Lockspire endpoint secret_key_base required for client_secret_jwt verifier material"` is at ~250-256. | [VERIFIED: lib/lockspire/security/policy.ex:178-193, 250-256] |
| `ecto_sql migrator.ex:817-852` | `ensure_repo_started` is at 817-827 returning `{:ok, :restart}` on `{:error, {:already_started, _pid}}`; `after_action(repo, :restart)` does `Supervisor.restart_child(repo, pid)` at ~846-850. `with_repo` default `pool_size = Keyword.get(opts, :pool_size, 2)` at line 162. | [VERIFIED: deps/ecto_sql/lib/ecto/migrator.ex:149-171, 817-852] |
| `keys.reencrypt.ex:159` wording | Actual: `defp repo_failure, do: "could not start the repo; check database connectivity and config"` (no `:lockspire, :repo` suffix in the source). D-06 wording adds the suffix; fine, it is a new string. | [VERIFIED: lib/mix/tasks/lockspire.keys.reencrypt.ex:~159] |
| "existing tests for client.create" | There is no dedicated task test file. The only coverage is `test/lockspire/clients_test.exs:299-324` ("prints the plaintext secret once and persists only the hash"), which calls `Mix.Tasks.Lockspire.Client.Create.run([...])` directly with a sandbox-owned running repo. It will keep passing via RepoRunner's direct path (the fun runs in the test process, so sandbox ownership holds). | [VERIFIED: test/lockspire/clients_test.exs:299-324] |

## Current Code Shape (verified by Read this session)

- `lib/mix/tasks/lockspire.client.create.ex`: `run/1` -> `opts |> build_attrs() |> Clients.register_client() |> print_result()`; `print_result({:error, errors})` builds `"#{field}:#{reason}(#{detail})"` joined by `"; "` and `Mix.raise("client registration failed: ...")`. Secret printed as `Mix.shell().info("client_secret=#{result.client_secret}")` guarded by `if result.client_secret`. Help text has no crash-after-write note (D-12 adds it).
- `lockspire.doctor.token_format.ex`: `report/0` is `with {:ok, policy} <- ServerPolicy.get_server_policy(), {:ok, clients} <- Clients.list_clients()`; `else {:error, reason} -> Mix.shell().info("Could not inspect token formats: #{inspect(reason)}")` (line 64). Alias is `Lockspire.Admin.Clients` and `Lockspire.Admin.ServerPolicy`.
- `lockspire.doctor.remote_jwks.ex`: `Clients.get_client()` (Admin) piped to `print_result/1`; `{:error, :not_found}` -> `Mix.raise("Client not found.")`; `{:error, reason}` -> `Mix.raise("Could not inspect client: #{inspect(reason)}")` (line 80). `Clients.remote_jwks_summary/1` is pure.
- `lib/lockspire/install/repo_runner.ex` (33 lines): the whole `run/2` body is wrapped in `rescue _error -> {:error, :repo_unavailable}` and `catch _kind, _reason -> {:error, :repo_unavailable}`. So anything raised in the fun, including `Mix.Error` and DB exceptions, becomes `:repo_unavailable` (this is the root of TASK-02). Moduledoc says "read-only" (to update, D-05). Existing callers: `doctor.key_encryption.ex:143`, `install/verify.ex:376,411`.
- `Lockspire.Clients.RegistrationResult` is `defstruct [:client, :client_secret]` with no Inspect derive. Precedent for the derive: `@derive {Inspect, except: [:private_jwk_encrypted]}` at `lib/lockspire/domain/signing_key.ex:29`.
- Admin facade: `Lockspire.Admin.Clients.get_client/1` maps `{:ok, nil} -> {:error, :not_found}`, `{:error, reason} -> {:error, reason}` (lib/lockspire/admin/clients.ex:70-77).
- `Clients.register_client/1` (lib/lockspire/clients.ex:113-137): `normalize` -> `persist_client` -> `ClientLifecycle.persist_direct` -> `Repository.register_client` -> `ClientStore.register_client` (client_store.ex:14-19) -> `Support.insert` which is bare `repo.insert(changeset, repo_options(opts))` and does NOT rescue. `persist_client` maps `{:error, %Ecto.Changeset{}}` to `changeset_errors/1` and ANY other `{:error, error}` to `[%{field: :base, reason: :persistence_failed, detail: inspect(error)}]` (clients.ex:176-187). Duplicate `client_id` is `unique_constraint(:client_id)` at `client_record.ex:187`, i.e. a changeset error, not a raise.
- `Clients.changeset_errors/1` (clients.ex:515-525) yields `%{field:, reason: :persistence_failed, detail: message}` with `%{key}` interpolation already applied via `to_string(value)`.

## Exception Shapes (executed experiments, Elixir 1.19.5-otp-28)

| Scenario | What surfaces | Evidence |
|---|---|---|
| Missing table (migrations not run) inside the fun | `%Postgrex.Error{postgres: %{code: :undefined_table}}`; message starts `ERROR 42P01 (undefined_table) relation "..." does not exist` and appends `query: ...` text | [VERIFIED: experiment] queried `select 1 from nope_table` through cold `RepoRunner.run` -> `{Postgrex.Error, :undefined_table, ...}` |
| DB unreachable (port 1) | `%DBConnection.ConnectionError{}` raised at first query after the 4000 ms queue timeout; message is `"... connection not available and request was dropped from queue after 4000ms ..."`. `with_repo` itself SUCCEEDS (pool start is lazy), so this is NOT `:repo_unavailable`. | [VERIFIED: experiment] |
| Unreachable DB log leak | The Postgrex connection processes log `[error] Postgrex.Protocol (...) failed to connect: ** (DBConnection.ConnectionError) tcp connect (localhost:1): connection refused` repeatedly. That log is emitted by the pool's connection process, so `Logger.put_process_level` on the caller CANNOT suppress it. It exposes host:port. This is pre-existing behavior shared with `mix ecto.migrate` / `keys.reencrypt`; D-06's "never raw exception text" governs what the TASK prints. Document, do not try to fix. | [VERIFIED: experiment] |
| Repo not started, query attempted | `RuntimeError` "could not lookup Ecto repo Lockspire.TestRepo because it was not started or it does not exist" (this is today's bare failure) | [VERIFIED: bare mix runs] |
| Missing endpoint `secret_key_base` during `register_client` | `ArgumentError` raised before any DB write: `"missing Lockspire endpoint secret_key_base required for client_secret_jwt verifier material"` | [VERIFIED: experiment, Endpoint env deleted] |
| Read stores (`list_clients`, `fetch_client_by_id`, token-format policy read) | `rescue error -> {:error, error}`: returned as a VALUE, not raised | [VERIFIED: lib/lockspire/storage/ecto/repository/client_store.ex:30-48] |
| Write (`Support.insert`) | raises | [VERIFIED: lib/lockspire/storage/ecto/repository/support.ex:10-11] |

**Planner consequences**
1. Classifier input must accept a returned `{:error, exception}` as well as a rescued exception. Suggested API: `classify(%Postgrex.Error{postgres: %{code: :undefined_table}})`, `classify(%Postgrex.Error{postgres: %{code: code}})` (use code NAME only, `Atom.to_string/1`), `classify(%DBConnection.ConnectionError{})`, `classify(%ArgumentError{message: m})` (client.create only; message names config keys never values), fallback: a fixed generic phrase for any other exception or term. Never `inspect/1` or `Exception.message/1` on the DB exceptions (`Postgrex.Error` message includes the SQL text).
2. A `:base` / `:persistence_failed` domain error from `persist_client` carries `detail: inspect(error)` of an arbitrary store error (clients.ex:184-185). D-07 renders `to_string(detail)`. To honor SAFE-02, render `:base` persistence errors through the classifier or a fixed phrase, not the raw `detail`. [ASSUMED risk: the store currently only returns changesets or raises, so this branch is probably unreachable today, but it is a latent leak.]
3. `Postgrex.Error` struct pattern: field is `:postgres` map with `:code` atom. [VERIFIED: experiment output `:undefined_table`]

## Logger.put_process_level (Elixir 1.19.5; project requires `~> 1.18`)

- Available since Elixir 1.15; returns `nil` from `Logger.get_process_level(self())` by default; `Logger.delete_process_level(self())` restores. [VERIFIED: experiment: initial `nil`, after delete `nil`]
- Ecto logs from the CALLER process, so the process level suppresses query logs. [VERIFIED: experiment] with `log: :debug` on the repo and `capture_log(level: :debug)`: without the process level, 1444 bytes captured including the `INSERT`; with `put_process_level(self(), :info)`, 120 bytes and no `INSERT`.
- `config/test.exs` sets `log: false` on `Lockspire.TestRepo` (line ~18), so the log-safety test must itself `Application.put_env(:lockspire, Lockspire.TestRepo, Keyword.put(cfg, :log, :debug))` before the cold start and restore in `on_exit` (the repo config is read at `with_repo` start). Use `capture_log([level: :debug], fn -> ... end)`. The plaintext secret was not in the SQL params log (only hash/verifier are), so assert BOTH that the plaintext secret is absent AND that no `INSERT`/`client_secret_hash`/verifier appears (the suppression is what the test proves).
- Restore pattern: capture `prev = Logger.get_process_level(self())` before, then `if prev, do: Logger.put_process_level(self(), prev), else: Logger.delete_process_level(self())` in an `after`. Because the fun runs in the caller (`with_repo` calls `fun.(repo)` in-process, migrator.ex:170) set/restore can live inside the helper wrapper around the fun.
- Beware: the level is process-scoped, so it must be applied in the same process that issues queries. It is (RepoRunner does not spawn). [VERIFIED: migrator.ex:170, repo_runner.ex]

## Test Infrastructure

- Framework: ExUnit, Elixir `~> 1.18`. Run qa on `1.19.5-otp-28` (memory: local 1.20.4 type warnings fail warnings-as-errors). In this shell: `export ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5` (installed versions: 1.17.3, 1.18.4, 1.19.0-otp-28, 1.19.5-otp-27/28, 1.20.2, 1.20.4). `.tool-versions` only pins nodejs. [VERIFIED: asdf list]
- Postgres is running locally (`/tmp:5432 accepting connections`); user `postgres` with no password works on localhost; test DB `lockspire_test`. [VERIFIED: pg_isready, psql]
- `test/test_helper.exs`: excludes `integration: true` unless an argv entry ends in `.exs`, contains the substring `integration`, or `--include integration` is given. Consequences: `mix test` alone SKIPS integration modules; `mix test path/to/file_test.exs` RUNS them; `mix test.fast` (`test test/lockspire test/mix test/integration`) INCLUDES them because `test/integration` contains the substring; `mix test --only integration` runs only them. [VERIFIED: test/test_helper.exs, mix.exs:93-98]
- CI: `scripts/ci/run_test_matrix.sh --integration` runs `mix do test.setup + test --only integration` then `mix test.clean-room.e2e`; fast lane runs `mix test.fast`. [VERIFIED: scripts/ci/run_test_matrix.sh:~126, .github/workflows/ci.yml:258,345]
- Test config: `config/test.exs` sets `repo: Lockspire.TestRepo`, `pool: Ecto.Adapters.SQL.Sandbox`, `pool_size: 10`, `log: false`, key_encryption keys, Endpoint `secret_key_base`. So the doctor tests' `Application.put_env(:lockspire, :repo, Lockspire.TestRepo)` is redundant (D-15). Cold-started repos with the Sandbox pool in `:auto` mode COMMIT for real, hence prefix cleanup. [VERIFIED: config/test.exs; keys_reencrypt and signing_key_upgrade tests cleanup pattern]
- `elixirc_paths(:test)` is `["lib", "test/support"]`, so `test/support/mix_repo_helpers.ex` compiles into test builds. [VERIFIED: mix.exs:79]
- Baseline: `MIX_ENV=test mix test test/lockspire/install/repo_runner_test.exs` -> 3 tests, 0 failures, 0.03 s.

### Existing test patterns to copy

- Cold start: `test/mix/tasks/lockspire_keys_reencrypt_test.exs` E2E module (`@moduletag :integration`, `setup` does `refute Process.whereis(Lockspire.TestRepo)`, foreign-row guard via its own `with_repo`, `on_exit(&cleanup/0)`, `Mix.Task.reenable`) and its `run_task/1` (reenable, `capture_io`, rescue `Mix.Error`). Same in `test/integration/signing_key_upgrade_journey_test.exs:25-44`. The local `with_repo/1` helper there is `Ecto.Migrator.with_repo(Lockspire.TestRepo, fn _ -> fun.() end, mode: :temporary)` (fine in TEST SETUP/cleanup because the repo is deliberately stopped; it is only forbidden in the task code under test).
- Running pool: `repo_runner_test.exs:11-22` uses `start_supervised!(Lockspire.TestRepo)` and `Process.whereis` equality only; D-14 hardens it. `Ecto.Adapter.lookup_meta/1` delegates to `Ecto.Repo.Registry.lookup(repo_name_or_pid)` and returns a map with `:pid`. [VERIFIED: deps/ecto/lib/ecto/adapter.ex:139-141; `%{pid: pid} = Ecto.Adapter.lookup_meta(repo)` used by migrator.ex:848]
- Doctor test modules start the repo in `setup_all` and use per-test sandbox checkout (`lockspire_doctor_token_format_test.exs`, `..._remote_jwks_test.exs`); `lockspire_doctor_key_encryption_test.exs:10-15` reenables BOTH `lockspire.doctor` and the subtask (and `"row counts"` uses `start_supervised!` + `Sandbox.start_owner!(shared: true)`).
- Unavailable repo double: `RepoRunnerTest.RaisingRepo` (`config/0 -> []`, `__adapter__/0`, `start_link/1` raises `DBConnection.ConnectionError`). Prefer this over a real unreachable port for the "repo did not start" task test: it is instant, whereas port-1 takes ~4 s per query and floods `[error] failed to connect` logs. Set `Application.put_env(:lockspire, :repo, RaisingRepo)` and restore in `on_exit`.
- `mix lockspire.doctor` dispatcher translates `"remote-jwks"` -> `lockspire.doctor.remote_jwks`, `"token_format"` -> `lockspire.doctor.token_format` (lib/mix/tasks/lockspire.doctor.ex:11-16). Reenable both names in tests.
- Output assertions: `client_secret=` (with the equals sign) appears exactly once on success; the warning line says `client_secret now` (no `=`), so `length(String.split(output, "client_secret=")) - 1 == 1` works. `Mix.shell().info` goes to stdout (capture_io); `Mix.raise` produces a `Mix.Error` (assert via `assert_raise` or the `run_task` pattern).

## Clean-Room Harness (verified)

- Reproduce/run command (no extra args): `python3 scripts/acceptance/clean_room_saas_journey.py --only happy_path` (also alias `mix test.clean-room.e2e`, which adds boundary/lifecycle/negative/dpop). I ran `--only happy_path` on `1.19.5-otp-28`: exit 0, **47 s wall**, deps cache warm, uses the checkout as package source (`package provenance verified (checkout lockspire-1.5.1 ...)`). [VERIFIED: run this session]
- DB: needs Postgres reachable; `clean_room_database_url(role)` uses `CLEAN_ROOM_DB_USER`/`PASSWORD` (defaults `postgres`/`postgres`), `CLEAN_ROOM_DB_HOST` (default `127.0.0.1`), `CLEAN_ROOM_DB_PORT` (5432), creating a random `lockspire_clean_room_<role>_<uuid>` database per run and dropping it in teardown. Worked unmodified locally. [VERIFIED: scripts/acceptance/clean_room/package_input.py:88-98]
- Insertion point: line 924 is `run_child_command(provider_child, provider_environment, "lockspire.doctor", "key_encryption")`; line 925 is `register_handoff_secrets(handoff)`. The provisioned handoff already created clients via `CleanRoomProvider.Bootstrap.provision!` (so token_format output will list multiple clients). [VERIFIED: scripts/acceptance/clean_room_saas_journey.py:924-925]
- `run_child_command(child, environment, *command)` (build_provider.py:279-292) uses `subprocess.run(("mix", *command), stdout=PIPE, stderr=STDOUT, check=False)` and returns `None`; on nonzero it raises `PackageInputError(f"provider {' '.join(command)} failed: {' '.join(details)}")` with the last 16 lines. It discards stdout on success, hence D-17's capturing variant. Failure tails reach `redactor.text(error)` in `main`'s except (line ~957, `print(redactor.text(error), file=sys.stderr)`). `register_secret(value)` (line 63) -> `ACTIVE_REDACTOR.register`, which replaces every registered value with `[REDACTED]`; register the parsed `client_secret=` value BEFORE any further evidence is written/printed.
- Provider environment already carries `DATABASE_URL`, `SECRET_KEY_BASE`, `LOCKSPIRE_ISSUER`, and `LOCKSPIRE_KEY_ENCRYPTION_KEY` is exported process-wide (set in `main` before the loop), so `client.create`'s verifier sealing (needs endpoint `secret_key_base` via runtime config) should work in the bare process. [ASSUMED: that the host's `config/runtime.exs` maps `SECRET_KEY_BASE` into the Endpoint config the way `Policy` reads it; the clean-room run in D-18 settles it empirically.]
- `lockspire.doctor remote-jwks --client <id>` on a non-jwks client: `RemoteJwks` summary has `:not_applicable` status (lib/lockspire/diagnostics/remote_jwks.ex:24, 223), rendered as `Status: not_applicable`. Exit 0.
- Reproduce-first (D-18): first commit adds the three steps with tasks unchanged. Expected failure, observed in the bare test-env analogue: `client.create` stack trace ending in `could not lookup Ecto repo`; `token_format` exits 0 but prints `Could not inspect token formats: %RuntimeError{...}` (so the harness MUST assert on output, not exit code, to see the failure); `remote-jwks` exits 1 with `Could not inspect client: %RuntimeError{...}`.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---|---|---|---|
| Starting/stopping the repo | custom supervisor / `Application.ensure_all_started(:lockspire)` | `Lockspire.Install.RepoRunner.run/2` | locked D-01; existing, tested; `app.start` would boot Endpoint/Oban |
| Pool-restart safety | own pid juggling in tasks | RepoRunner's `Process.whereis` branch | `with_repo` `:restart` bounces a live pool |
| Error redaction | regex scrubbing of exception text | fixed phrases keyed on exception struct + `postgres.code` | `Postgrex.Error` messages embed SQL |
| Struct redaction | manual `Map.drop` in call sites | `@derive {Inspect, except: [:client_secret]}` | precedent `signing_key.ex:29` |
| Log suppression | changing global Logger level / repo config | `Logger.put_process_level/2` around the fun | process scoped, restorable |
| New deps | any | stdlib + existing ecto_sql/postgrex | user rule: copy-paste over a dep |

## Common Pitfalls

1. **`Mix.raise` inside the fun is swallowed.** RepoRunner rescues everything and returns `:repo_unavailable`. Compute inside, raise after (D-02). Warning sign: a validation test that sees "could not start the repo".
2. **Read errors are values, write errors are raises.** A helper that only `rescue`s misses the doctor paths (the `with` else branch receives `{:error, %Postgrex.Error{}}`). Classify both.
3. **`token_format` exit 0 hides failure.** Harness and tests must assert output content; never rely on exit status alone for it.
4. **`Process.whereis` alone cannot prove the pool is untouched.** A `with_repo` `:restart` keeps the registered name. Compare `Ecto.Adapter.lookup_meta(repo).pid`, plus a `Process.monitor` on the pool pid (no `:DOWN`), plus a row inserted pre-task still visible post-task (D-14). Do this in the default suite, where the repo is started with `start_supervised!`.
5. **Cold tests commit real rows.** Unique random prefixes, a foreign-row guard on the clients table (default sandbox suites roll back, so an empty/`prefix`-only table is expected), and `on_exit` cleanup through its own `with_repo`. token_format output lists ALL clients, so assert with `=~` on the seeded ids, not equality.
6. **`log: false` in test config.** The log-capture test must raise the repo log level itself or it proves nothing.
7. **Unreachable-port tests are slow and noisy** (~4 s, repeated connection-process `[error]` lines that expose host:port and are not suppressible). Use the `RaisingRepo` double for the "repo did not start" path.
8. **`Mix.Task.reenable` both `lockspire.doctor` and the leaf task** or the second run in a test silently does nothing.
9. **Secret printing order.** Print `client_secret=` only inside the `{:ok, {:ok, result}}` branch after `RepoRunner.run/2` returned; never print the struct; the `:base` detail path must not carry `inspect(error)`.
10. **Telemetry under `app.config` (D-19, MEDIUM).** `Observability.emit` calls `:telemetry.execute` (lib/lockspire/observability.ex:25-44), which is safe with no handlers attached. Whether host handlers (Oban/OpenTelemetry attachers started by `Lockspire.Application`) exist in a bare task is what the clean-room run reveals; no handler changes here.

## Code Examples (shape only; verified building blocks, not final code)

```elixir
# Source: lib/mix/tasks/lockspire.keys.reencrypt.ex:108-124 pattern + CONTEXT D-01/D-02/D-11
repo = Lockspire.Config.repo!()   # raises if unset, outside the runner

outcome =
  RepoRunner.run(repo, fn _repo ->
    prev = Logger.get_process_level(self())
    Logger.put_process_level(self(), :info)
    try do
      attrs |> Clients.register_client()      # {:ok, %RegistrationResult{}} | {:error, [detail]}
    rescue
      error -> {:error, {:db, TaskError.classify(error)}}   # fixed phrase only
    after
      if prev, do: Logger.put_process_level(self(), prev), else: Logger.delete_process_level(self())
    end
  end)

case outcome do
  {:ok, {:ok, result}}            -> print_success(result)          # secret printed here only
  {:ok, {:error, errors}} when is_list(errors) -> Mix.raise(format_domain_errors(errors))
  {:ok, {:error, {:db, phrase}}}  -> Mix.raise("client registration failed: " <> phrase)
  {:error, :repo_unavailable}     -> Mix.raise("could not start the repo; check database connectivity and config :lockspire, :repo")
end
```

```elixir
# Pool fingerprint for D-14 (test/support/mix_repo_helpers.ex)
def pool_fingerprint(repo) do
  %{name_pid: Process.whereis(repo), pool_pid: Ecto.Adapter.lookup_meta(repo).pid}
end
```

## Standard Stack

No new packages. Everything used is already in the lockfile: ecto_sql 3.13.5 (`Ecto.Migrator.with_repo/3`), postgrex (`Postgrex.Error`), db_connection (`DBConnection.ConnectionError`), stdlib `Logger`. Python harness uses stdlib only.

## Package Legitimacy Audit

No external packages are installed by this phase. Packages removed: none. Packages flagged: none.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary | Rationale |
|---|---|---|---|
| Repo start/stop for CLI | Mix task layer (`Lockspire.Install.RepoRunner`) | host `config :lockspire, :repo` | embedded library; host owns the repo |
| DB failure classification | Install/task helper (pure) | — | keeps protocol core and storage untouched |
| Client registration & validation | `Lockspire.Clients` (unchanged) | storage | no protocol/schema change |
| Secret redaction on structs/logs | `RegistrationResult` Inspect derive + process log level | — | SAFE-02 |
| End-to-end proof | clean-room harness (Python, real `mix` subprocesses) | ExUnit integration tests | real host, bare VM |

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|---|---|---|---|---|
| Elixir/OTP 1.19.5-otp-28 | qa/tests | yes (asdf) | 1.19.5 / OTP 28.5 | 1.18.4 acceptable; avoid local 1.20.x |
| PostgreSQL | tests, clean-room | yes | accepting on :5432, `postgres` user trusts localhost | — |
| python3 | clean-room | yes | ran successfully | — |
| Hex/deps cache for clean-room | clean-room | yes (warm, 47 s run) | — | first cold run is slower |

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (Elixir 1.19.5-otp-28 for qa) |
| Config file | `config/test.exs`, `test/test_helper.exs` (integration excluded by default) |
| Quick run command | `MIX_ENV=test mix test test/lockspire/install/repo_runner_test.exs test/lockspire/clients_test.exs` |
| Full suite command | `MIX_ENV=test mix test.fast` (includes integration modules) ; CI also `mix test --only integration` + `mix test.clean-room.e2e` |
| Env prefix | `export ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5` |

### Phase Requirements -> Test Map
| Req / Criterion | Behavior | Test Type | Automated Command | File Exists? |
|---|---|---|---|---|
| TASK-01 / SC1 | bare-VM `client.create` succeeds, stops repo again | integration (cold) | `MIX_ENV=test mix test test/mix/tasks/lockspire_client_create_cold_test.exs` | Wave 0 (new) |
| TASK-01 / SC1 | bare-VM `doctor token_format` seeded output | integration (cold) | `MIX_ENV=test mix test test/mix/tasks/lockspire_doctor_token_format_cold_test.exs` | Wave 0 (new) |
| TASK-01 / SC1 | bare-VM `doctor remote-jwks --client` output | integration (cold) | `MIX_ENV=test mix test test/mix/tasks/lockspire_doctor_remote_jwks_cold_test.exs` | Wave 0 (new) |
| TASK-01 / SC1 | clean-room: reproduce failure then green for all three | acceptance | `python3 scripts/acceptance/clean_room_saas_journey.py --only happy_path` (~47 s) | extend existing script |
| TASK-03 / SC2 | running pool pid, `lookup_meta` pid, no `:DOWN`, pre-inserted row visible | unit (default suite) | `MIX_ENV=test mix test test/lockspire/install/repo_runner_test.exs` plus doctor test modules | extend existing |
| TASK-02 / SC3 | validation failure (bad redirect URI, duplicate `--client-id`) names field/reason, no `client_secret=` | integration (cold) + default suite via sandbox | cold client.create module | Wave 0 |
| TASK-02 / SC3 | DB phrases: `undefined_table`, unreachable (RaisingRepo), missing `secret_key_base`; no `repo unavailable` for domain errors | unit on classifier + task tests | `MIX_ENV=test mix test test/lockspire/install/task_error_test.exs` | Wave 0 (new) |
| TASK-02 / SC3 | secret printed exactly once, only after write; `inspect(%RegistrationResult{})` hides secret | unit | `mix test test/lockspire/clients_test.exs` (+ new Inspect assertion) | extend |
| SAFE-02 / SC4 | no secret/hash/verifier in captured log at `:debug` with repo `log: :debug` | integration (cold) | cold client.create module with `capture_log(level: :debug)` | Wave 0 |
| SC4 | doctor exit codes/output shape unchanged | unit | existing `lockspire_doctor_token_format_test.exs`, `..._remote_jwks_test.exs` | exist (drop redundant put_env) |
| D-19 | telemetry under `app.config` | acceptance (observation) | clean-room `client.create` step; record result in SUMMARY | — |

### Sampling Rate
- **Per task commit:** the single new/changed test file via `MIX_ENV=test mix test <file>` (explicit `.exs` path includes integration-tagged modules).
- **Per wave merge:** `MIX_ENV=test mix test test/lockspire test/mix test/integration` (that is `mix test.fast` without `test.setup`; run `mix test.setup` once if the DB needs preparing) and `mix format --check-formatted`, `mix compile --warnings-as-errors`.
- **Phase gate:** `mix test.fast` green, `mix test --only integration`, `python3 scripts/acceptance/clean_room_saas_journey.py --only happy_path` green (and ideally the full `mix test.clean-room.e2e`), plus `mix credo`/`mix dialyzer` if part of `mix ci` (check `mix.exs` aliases before the gate; `mix ci` was not exercised in this research).

### Wave 0 Gaps
- [ ] `test/support/mix_repo_helpers.ex` (`assert_repo_stopped!/0`, `with_temp_repo/1`, `pool_fingerprint/1`, `assert_pool_untouched!/2`, `run_task/2`, prefix cleanup)
- [ ] `test/mix/tasks/lockspire_client_create_cold_test.exs`, `lockspire_doctor_token_format_cold_test.exs`, `lockspire_doctor_remote_jwks_cold_test.exs` (each `async: false`, `@moduletag :integration`)
- [ ] classifier unit test (`test/lockspire/install/task_error_test.exs` or wherever the helper lands)
- [ ] clean-room: output-capturing `run_child_command` variant + three new steps (first commit, tasks unchanged)
- No framework install needed.

## Security Domain

ASVS applicability (`security_enforcement` not disabled in config assumptions):

| ASVS Category | Applies | Control |
|---|---|---|
| V2/V3/V4 | no | CLI task; host owns accounts |
| V5 Input Validation | yes | existing `Clients.register_client` validation; `OptionParser strict:` unchanged |
| V6 Cryptography | yes (no change) | secret hashing/sealing stays in `Lockspire.Security.Policy`; no hand-rolled crypto |
| V7 Logging/Error handling | yes | fixed-phrase errors, `@derive Inspect except`, process log level, no `inspect(reason)` |

| Threat | STRIDE | Mitigation |
|---|---|---|
| Client secret/hash/verifier in query debug logs | Information disclosure | `Logger.put_process_level(self(), :info)` around the DB work + test with repo `log: :debug` |
| Host/port/SQL in error text | Information disclosure | classifier emits fixed phrases keyed on struct + postgres code name |
| Secret leaked via `inspect(result)` in crash reports | Information disclosure | Inspect derive on `RegistrationResult` |
| Secret printed but write rolled back | Integrity/Repudiation | print only after `{:ok, {:ok, result}}` |
| Connection-process logs expose host:port when DB unreachable | Information disclosure | not controllable from the task (pre-existing, same as `ecto.migrate`); document only |
| Secret in clean-room evidence | Information disclosure | `register_secret` before any evidence write; secret prints only on success so failure tails are clean |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|---|---|---|
| A1 | `persist_client`'s `:base`/`inspect(error)` branch is currently unreachable (store returns changeset or raises) | Exception Shapes | Low: leak only if reachable; mitigation (fixed phrase) is cheap either way |
| A2 | Clean-room host `runtime.exs` maps `SECRET_KEY_BASE` so `client.create` can seal the verifier in a bare process | Clean-Room Harness | Medium: `client.create` would fail with the config ArgumentError phrase; the reproduce/fix run exposes it and may need a harness env tweak |
| A3 | `mix ci` composition (credo/dialyzer) not inspected; gate commands listed from `test.fast`/CI matrix only | Validation | Low: planner should read `mix.exs` aliases for the exact gate |

## Open Questions

1. **Does `Observability.emit` produce audit telemetry in a bare task?** `:telemetry.execute` is safe with no handlers, but handlers are attached by `Lockspire.Application`, which `app.config` does not start. Resolve via the clean-room run (D-19); no code change in this phase.
2. **Where should the classifier live?** Recommend `lib/lockspire/install/task_error.ex` (`@moduledoc false`), beside `RepoRunner`, so `verify.ex`/future tasks can reuse it. Discretion item.

## Sources

### Primary (HIGH)
- Live code Read this session: the five target files, `clients.ex`, `registration_result.ex`, `client_store.ex`, `support.ex`, `security/policy.ex`, `admin/clients.ex`, `observability.ex`, `deps/ecto_sql/lib/ecto/migrator.ex`, `deps/ecto/lib/ecto/adapter.ex`, existing tests, `test_helper.exs`, `config/test.exs`, `mix.exs`, clean-room scripts, `scripts/ci/run_test_matrix.sh`.
- Executed experiments: cold `RepoRunner` with undefined table and unreachable port; process-level log suppression under `capture_log`; bare `mix` runs of all three tasks; clean-room `--only happy_path` (exit 0, 47 s).

### Secondary / Tertiary
- None needed; no web sources were used.

## Metadata

**Confidence:** Standard stack HIGH (no new deps); architecture HIGH (CONTEXT verified); pitfalls HIGH (experiment-backed); clean-room timings HIGH for happy_path only (full e2e not timed).
**Research date:** 2026-10-18 **Valid until:** ~30 days (stable; re-check if ecto_sql is bumped)
