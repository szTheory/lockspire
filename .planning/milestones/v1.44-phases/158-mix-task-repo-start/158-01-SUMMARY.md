---
phase: 158-mix-task-repo-start
plan: 01
subsystem: mix-tasks
tags: [mix, repo-runner, clean-room, secrets]
requires: []
provides:
  - Lockspire.Install.TaskError (classify/1, run/2, repo_unavailable_phrase/0, unexpected_phrase/0)
  - mix lockspire.client.create works in a bare mix process
  - Lockspire.MixRepoHelpers cold/warm repo test helpers
  - clean-room assert_bare_mix_tasks step
affects: [158-02, 158-03]
tech-stack:
  added: []
  patterns: [compute-then-print, classify-inside-runner]
key-files:
  created:
    - lib/lockspire/install/task_error.ex
    - test/support/mix_repo_helpers.ex
    - test/mix/tasks/lockspire_client_create_cold_test.exs
  modified:
    - lib/mix/tasks/lockspire.client.create.ex
    - scripts/acceptance/clean_room/build_provider.py
    - scripts/acceptance/clean_room_saas_journey.py
key-decisions:
  - "TaskError.run/2 classifies exceptions, exits and throws inside the RepoRunner fun so :repo_unavailable only means the repo did not start"
  - "client.create starts :plug_crypto itself because app.config starts no applications"
requirements-completed: [TASK-01, TASK-02, TASK-03]
status: complete
duration: 25 min
completed: 2026-10-19
actuals:
  tokens: 14000
  tasks: 2
  commits: 3
plan_head_before: 310a20586f0efb39f45a79378b041db8e215f39a
plan_head_after: cbb64ab2f83a62cd1d571a56a4be536a3b6086c2
commits: 3
---

# Phase 158 Plan 01: Mix task repo start (client.create tracer) Summary

`mix lockspire.client.create` now starts and stops the host repo through RepoRunner via a new shared `Lockspire.Install.TaskError`, reports fixed safe failure phrases, and prints the secret once, only after a committed write.

## Accomplishments

- Clean-room journey reproduces the bare-mix failure first (D-18), then client.create passes bare in the real clean-room host.
- `Lockspire.Install.TaskError` maps Postgrex, DBConnection, Lockspire config ArgumentError, and everything else to fixed phrases; lowers the process log level to :info while the fun runs.
- Shared test helpers and a cold `:integration` test (secret exactly once, repo stopped before and after, duplicate id gives a domain error with no secret).

## Reproduction evidence

- Reproduce commit: `cc33e5bfac6037142d5eff27cde28bec01bc319b` (only the two Python harness files).
- Failing command: `provider lockspire.client.create --client-type confidential --client-id clean-room-cli-96b3ac6b --name Clean Room CLI --redirect-uri https://clean-room-cli.example/callback --scope openid --grant-type authorization_code failed:`
- Redacted error tail: `** (ArgumentError) errors were found at the given arguments: * 1st argument: the table identifier does not refer to an existing ETS table (stdlib 7.3) :ets.lookup/2 (plug_crypto 2.2.0) lib/plug/crypto/key_generator.ex:62 ... (lockspire 1.5.1) lib/lockspire/clients.ex:103: Lockspire.Clients.rotate_secret_material/1 ... Lockspire.Clients.register_client/1`

Note: the plan predicted `could not lookup Ecto repo`; the first failure in a bare process is actually earlier, the plug_crypto key cache not being started (see Deviations). The repo lookup failure would have followed.

## Expected-red checkpoint (token_format, before plan 02)

After the fix the client.create step passes bare and the journey stops, as declared, at:
`bare mix step failed: lockspire.doctor token_format output Could not inspect token formats: %RuntimeError{message: "could not lookup Ecto repo CleanRoomProvider.Repo because it was not started or it does not exist"}`
The journey is still red here (exit 1) and goes green only in plan 02 Task 3. This proves the output assertion catches token_format's exit-0 failure.

## A2 contingency

Not needed: the provider environment already exports SECRET_KEY_BASE; no harness environment adjustment was made.

## D-19 telemetry

The bare client.create run under `app.config` only completed with no telemetry warning or crash visible in the journey log (no `Failed to lookup telemetry handlers`). `Observability.emit` calls `:telemetry.execute`, which is a no-op without handlers. There are no `:telemetry.attach` calls in `lib/`, the clean-room scripts or priv, so no audit handler runs in a bare task either. `created_by` is stored in the row. No code change (D-19).

## Deviations from Plan

**1. [Rule 3 - Blocking] plug_crypto not started under app.config**
- **Found during:** Task 1 reproduction and rerun
- **Issue:** `Plug.Crypto.encrypt` in `Clients.rotate_secret_material/1` needs the plug_crypto key-generator ETS cache, which only exists when the `:plug_crypto` application is started; `app.config` starts no applications.
- **Fix:** `client.create` calls `Application.ensure_all_started(:plug_crypto)` before `TaskError.run/2`. No library or dependency change.
- **Files modified:** lib/mix/tasks/lockspire.client.create.ex
- **Commit:** a2fa96b1
- **Follow-up for plan 02/03:** doctor tasks that touch Plug.Crypto should do the same if they hit the same error.

**Total deviations:** 1 auto-fixed (1 blocking). **Impact:** none on scope.

## Known Stubs

None.

## Self-Check: PASSED

- Files exist: task_error.ex, mix_repo_helpers.ex, cold test, SUMMARY.
- Commits cc33e5bf, a2fa96b1, cbb64ab2 are ancestors of HEAD.
- Cold test, clients_test, repo_runner_test: 17 tests, 0 failures; `mix compile --warnings-as-errors` and `mix format` clean; repo_runner.ex, mix.exs, mix.lock unchanged; no leftover `mix-cold-create-` rows.
