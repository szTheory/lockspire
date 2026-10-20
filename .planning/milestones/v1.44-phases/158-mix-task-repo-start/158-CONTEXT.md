# Phase 158: Mix Task Repo Start - Context

**Gathered:** 2026-10-18 (assumptions mode, with 3 parallel research fan-outs)
**Status:** Ready for planning

<domain>
## Phase Boundary

Make `mix lockspire.client.create`, `mix lockspire.doctor.token_format`, and `mix lockspire.doctor.remote_jwks` start and stop the host repo themselves in a bare `mix` session, report the real failure reason, print a client secret at most once and only after a committed write, and prove it with tests plus the clean-room SaaS journey (TASK-01..03; constrained by SAFE-02). These are the only broken DB-touching tasks: `doctor.key_encryption` and `verify` already use RepoRunner, `keys.reencrypt` uses raw `with_repo` (works bare), `upgrade`/`install`/`oidf_conformance` do not touch the DB, `test.setup` is dev/test only.

No protocol, schema, security-default, or dependency changes.
</domain>

<decisions>
## Implementation Decisions

### Repo start
- **D-01:** Each task resolves `Lockspire.Config.repo!()` outside the runner (let it raise if unset) and wraps ONLY its DB work in `Lockspire.Install.RepoRunner.run/2`. Keep `@requirements ["app.config"]`. Not `app.start` (would boot host Endpoint, Oban, schedulers, `Lockspire.Application` children); not raw `Ecto.Migrator.with_repo` (its `:restart` branch bounces a live pool, `deps/ecto_sql/lib/ecto/migrator.ex:817-852`).
- **D-02:** The fun only computes and returns tagged tuples. All printing, `Mix.raise`, and exit decisions happen after `RepoRunner.run/2` returns (same rule as `lockspire.keys.reencrypt.ex:108-124`). Reason: RepoRunner's rescue/catch (`repo_runner.ex:19-22`) converts anything raised inside the fun — including `Mix.raise` — into `{:error, :repo_unavailable}`.
- **D-03:** Use ecto_sql defaults (`pool_size: 2`, `mode: :temporary`). Do not start `:lockspire`; the tasks need only app env (loaded by `app.config`, including runtime.exs) plus the repo. No new deps.
- **D-04:** Per task scope of the wrapped section:
  - `client.create`: `build_attrs |> Clients.register_client()`.
  - `doctor.token_format`: the whole `with` (both reads) in one RepoRunner call.
  - `doctor.remote_jwks`: only `Clients.get_client/1` (the summary is pure, no DB/HTTP).

### Real failure reasons
- **D-05:** `RepoRunner` stays behaviorally unchanged (zero blast radius for `verify.ex` and `doctor.key_encryption`); only update its moduledoc ("read-only" is no longer accurate since client.create writes). After this phase `{:error, :repo_unavailable}` means only "the repo could not start".
- **D-06:** A small shared helper used by the three tasks rescues DB exceptions inside the fun and maps them to fixed, safe reasons — never raw exception text (it can carry host/port):
  - `Postgrex.Error` `undefined_table` → `the Lockspire tables are missing; run mix ecto.migrate, then rerun`
  - other `Postgrex.Error` → fixed phrase with the Postgres error code name only
  - `DBConnection.ConnectionError` → `could not reach the database; check database connectivity and config :lockspire, :repo`
  - config `ArgumentError` (e.g. missing endpoint `secret_key_base` from `Policy.seal_client_secret_jwt_verifier`, `policy.ex:190-192,255`) → `client registration failed: <config message>` (message names config keys, never values)
  - Repo did not start → `could not start the repo; check database connectivity and config :lockspire, :repo` (match `keys.reencrypt.ex:159` wording style)
  Helper name/location is Claude's discretion (e.g. under `Lockspire.Install`).
- **D-07:** Domain/validation errors render one per line:
  ```
  client registration failed; nothing was saved:
    - client_id: has already been taken
    - redirect_uris: must be an absolute https URI
  ```
  Built from `field` + `to_string(detail)`; drop the reason atom when it is `:persistence_failed`. Interpolation stays in `Clients.changeset_errors` (`clients.ex:515-525`). Duplicate `client_id` arrives as a changeset error via `unique_constraint` (`client_record.ex:187`), not a raise.
- **D-08:** Exit semantics preserved: `client.create` and `doctor.remote_jwks` fail via `Mix.raise` (stderr, exit 1). `doctor.token_format` never exits non-zero: each failure is one calm `Could not inspect token formats: <cause phrase>` info line, exit 0. No `inspect(reason)` of exception structs on any failure path (today `token_format.ex:64-65` and `remote_jwks.ex:80` do this).

### Secret and log safety (SAFE-02)
- **D-09:** The client secret prints once, to stdout, only after `RepoRunner.run/2` returns `{:ok, {:ok, result}}` (write committed). Keep today's `client_secret=` key=value line and "Store this client_secret now; Lockspire will not show it again." warning. Read `result.client_secret` directly; never interpolate the struct.
- **D-10:** Add `@derive {Inspect, except: [:client_secret]}` to `Lockspire.Clients.RegistrationResult` (`registration_result.ex:13`).
- **D-11:** While the fun runs, lower the calling process log level with `Logger.put_process_level(self(), :info)` and restore after (Ecto logs in the caller), so dev-host `:debug` query logs never print the secret hash or sealed verifier. A test captures logs and asserts secret, hash, and verifier are absent.
- **D-12:** Crash-after-write is accepted and documented in the task's help: the client exists; rotate the secret from the admin Apps page instead of rerunning (a rerun creates a second client).

### Tests (TASK-03)
- **D-13:** Cold-path tests: one new `async: false`, `@moduletag :integration` module per task (pattern: `test/mix/tasks/lockspire_keys_reencrypt_test.exs` E2E module, `test/integration/signing_key_upgrade_journey_test.exs:25-44`). Setup `refute Process.whereis(Lockspire.TestRepo)`, never `start_supervised!`; assert stopped again after the task; random-suffixed prefixes + foreign-row guard + `on_exit` cleanup in its own `with_repo`. `client.create` module covers: confidential success (secret line exactly once), invalid redirect URI and duplicate `--client-id` (output names field/reason, not repo; no `client_secret=` line), and log capture with no secret material. Doctor modules cover seeded happy output plus unavailable-repo shape. Reenable both `lockspire.doctor` and the subtask (`lockspire_doctor_key_encryption_test.exs:10-15` precedent).
- **D-14:** Already-running-pool check (default suite, existing modules): assert pool untouched via `Process.whereis` pid AND `Ecto.Adapter.lookup_meta(repo).pid` unchanged, no `:DOWN` from a monitor taken before, and a row inserted under a sandbox checkout before the task still visible after. `whereis` alone cannot detect a `with_repo` `:restart`.
- **D-15:** Shared helper `test/support/mix_repo_helpers.ex` (e.g. `assert_repo_stopped!/0`, `with_temp_repo/1`, `pool_fingerprint/1`, `assert_pool_untouched!/2`, `run_task/2`, cleanup by prefix). Harden `test/lockspire/install/repo_runner_test.exs:22` with `assert_pool_untouched!`. Drop the redundant `Application.put_env(:lockspire, :repo, ...)` in the doctor test modules (`config/test.exs:31` already sets it).

### Clean-room reproduction
- **D-16:** In `scripts/acceptance/clean_room_saas_journey.py`, after `lockspire.doctor key_encryption` (~`:924`), add: `lockspire.client.create` (confidential, `clean-room-cli-` id), `lockspire.doctor token_format` (assert the new client id appears), `lockspire.doctor remote-jwks --client <id>` (expect `not_applicable`, exit 0). Each runs in its own bare `mix` process.
- **D-17:** Add an output-capturing variant of `run_child_command` in `scripts/acceptance/clean_room/build_provider.py:279-292`; exit codes alone cannot detect `token_format`'s exit-0 failure. Pass the captured client secret to `register_secret` (`clean_room_saas_journey.py:63`) before any evidence is written. Failure tails cannot contain the secret because it prints only after success.
- **D-18:** Reproduce first: the first plan's first commit adds the clean-room steps with tasks unchanged; record the failing command line, redacted error tail, and SHA in the phase SUMMARY; then the fix makes them green. Keep the steps permanently as success assertions — no "expect failure" assertion.
- **D-19:** The clean-room `client.create` run also settles empirically whether `Observability.emit` telemetry works under `app.config` only (ARCHITECTURE.md:82, MEDIUM confidence). No telemetry handler changes in this phase; lost CLI audit telemetry is acceptable (`created_by` is stored in the row) and should be noted in docs if confirmed.

### Claude's Discretion
- Helper module names/locations and exact function names (D-06, D-15).
- Exact non-`undefined_table` Postgres error phrasing.
- Whether to pass Ecto's sensitive/log option in `client_store.ex:16` in addition to D-11 (optional belt-and-braces).

### Folded Todos
- `.planning/todos/pending/2026-10-16-mix-tasks-start-repo.md` — this phase resolves it. Its suggested raw `with_repo` approach is superseded by D-01.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Scope and research
- `.planning/ROADMAP.md` — Phase 158 goal and success criteria
- `.planning/REQUIREMENTS.md` — TASK-01..03, SAFE-02
- `.planning/research/v1.44-adopter-polish/ARCHITECTURE.md` — Item 1 (lines ~27-89)
- `.planning/research/v1.44-adopter-polish/PITFALLS.md` — C1, C2, C4, M7, m1, m2 (note: its pool_size 10 claim is wrong; ecto_sql 3.13.5 default is 2)
- `.planning/research/v1.44-adopter-polish/SUMMARY.md`
- `.planning/todos/pending/2026-10-16-mix-tasks-start-repo.md`

### Code
- `lib/lockspire/install/repo_runner.ex`
- `lib/mix/tasks/lockspire.client.create.ex`
- `lib/mix/tasks/lockspire.doctor.token_format.ex`
- `lib/mix/tasks/lockspire.doctor.remote_jwks.ex`
- `lib/mix/tasks/lockspire.doctor.key_encryption.ex` (RepoRunner caller pattern, :140-149)
- `lib/mix/tasks/lockspire.keys.reencrypt.ex` (compute-then-print, :108-159)
- `lib/lockspire/clients.ex` (:113-187, :515-525)
- `lib/lockspire/clients/registration_result.ex`
- `lib/lockspire/storage/ecto/repository/support.ex`, `client_store.ex`, `server_policy_store.ex`
- `lib/lockspire/admin/clients.ex` (:66-82)
- `deps/ecto_sql/lib/ecto/migrator.ex` (:149-184, :817-860)

### Tests and harness
- `test/lockspire/install/repo_runner_test.exs`
- `test/mix/tasks/lockspire_keys_reencrypt_test.exs`
- `test/integration/signing_key_upgrade_journey_test.exs`
- `test/mix/tasks/lockspire_doctor_token_format_test.exs`, `lockspire_doctor_remote_jwks_test.exs`, `lockspire_doctor_key_encryption_test.exs`
- `test/lockspire/clients_test.exs` (:299-324)
- `test/test_helper.exs`, `config/test.exs`, `.github/workflows/ci.yml` (integration lane)
- `scripts/acceptance/clean_room_saas_journey.py`, `scripts/acceptance/clean_room/build_provider.py`

### External
- https://hexdocs.pm/ecto_sql/Ecto.Migrator.html#with_repo/3
- https://hexdocs.pm/phoenix/releases.html (Release.migrate pattern)
- https://hexdocs.pm/logger/Logger.html#put_process_level/2
- https://www.ory.com/docs/hydra/cli/hydra-create-client (one-time secret precedent)
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `RepoRunner.run/2`: direct call if `Process.whereis(repo)` is alive, else `ensure_all_started(:ecto_sql)` + `with_repo(mode: :temporary)`; returns `{:ok, result} | {:error, :repo_unavailable}`.
- `keys.reencrypt` compute-then-print structure and repo-failure wording.
- Cold-start test pattern with prefix cleanup in `signing_key_upgrade_journey_test.exs` and reencrypt E2E tests.
- Clean-room harness runs real `mix` subprocesses against the packaged tarball and has a secret redaction guard (`register_secret`).

### Established Patterns
- Every Lockspire Mix task fails through `Mix.raise` with lowercase "cause; next step" copy.
- Read stores already rescue and return `{:error, exception}`; `Support.insert` does not rescue (write path raises).
- `test_helper.exs` excludes `:integration` by default; CI runs the integration lane.
- Run qa on Elixir 1.19.5-otp-28 (local 1.20 type warnings fail warnings-as-errors).

### Integration Points
- Three task files, one new shared task-error helper, `RegistrationResult` Inspect derive, RepoRunner moduledoc, new test modules + test support helper, two clean-room harness files.
</code_context>

<specifics>
## Specific Ideas

- User asked for a research fan-out per decision point (ecosystem precedent, adversarial pass, DX, no new deps — "another copy and paste is better than another dep"). Precedents adopted: Ecto `ecto.migrate`/Phoenix `Release.migrate` (`with_repo`), Ory Hydra / GitHub / AWS IAM one-time secret display, ecto_sql's own mix-task tests (never stop a repo you didn't start).
</specifics>

<deferred>
## Deferred Ideas

- Running these tasks from a release (`bin/app eval` Release-module entry point built on RepoRunner) — future.
- Repos started with a custom `name:` or dynamic repos (missed by `Process.whereis(module)`) — rare, future.
- Moving `keys.reencrypt` from raw `with_repo` to RepoRunner (pool bounce only when repo already running) — out of the three-task scope.
- `--format json` task output — already listed in Future Requirements.

### Reviewed Todos (not folded)
- `2026-10-13-audit-dcr-default-lifetime-semantics.md` — protocol work, deferred to its own milestone (DCR-01).
</deferred>
