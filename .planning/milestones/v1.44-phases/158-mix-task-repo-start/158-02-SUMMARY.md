---
phase: 158-mix-task-repo-start
plan: 02
subsystem: mix-tasks
tags: [mix, repo-runner, doctor, clean-room]
requires: [158-01]
provides:
  - mix lockspire.doctor token_format works in a bare mix process
  - mix lockspire.doctor remote-jwks works in a bare mix process
  - cold and pool-untouched tests for both doctor tasks
affects: [158-03]
tech-stack:
  added: []
  patterns: [compute-then-print, classify-inside-runner]
key-files:
  created:
    - test/mix/tasks/lockspire_doctor_token_format_cold_test.exs
    - test/mix/tasks/lockspire_doctor_remote_jwks_cold_test.exs
  modified:
    - lib/mix/tasks/lockspire.doctor.token_format.ex
    - lib/mix/tasks/lockspire.doctor.remote_jwks.ex
    - test/mix/tasks/lockspire_doctor_token_format_test.exs
    - test/mix/tasks/lockspire_doctor_remote_jwks_test.exs
key-decisions:
  - "Doctor tasks resolve Lockspire.Config.repo!() outside the runner and print or raise only after TaskError.run/2 returns"
requirements-completed: []
status: complete
duration: 15 min
completed: 2026-10-19
actuals:
  tokens: 9000
  tasks: 3
  commits: 2
plan_head_before: ddf278b6ff4eb70e3761ac9977ea83aae6049c0f
plan_head_after: 52d254881f1bcb867196cac900ef5fbe1d91f2f4
commits: 2
---

# Phase 158 Plan 02: Doctor tasks start their own repo Summary

`mix lockspire.doctor token_format` and `remote-jwks` now start and stop the host repo through `TaskError.run/2`, keep their exit semantics, and print fixed safe phrases instead of inspected exception structs. The clean-room journey passes with all three bare-mix steps.

## Accomplishments

- token_format reads policy and clients in one runner call. It never exits non-zero on inspection failures and prints `Could not inspect token formats: <phrase>`.
- remote-jwks fetches the client in the runner. It keeps `Client not found.` and raises `Could not inspect client: <phrase>` for other failures.
- Two cold `:integration` modules (3 tests each: seeded, empty or unknown, RaisingRepo) with prefix cleanup and the foreign-row guard.
- Existing doctor modules now check pool-untouched and no longer set the redundant repo env.
- Clean-room `--only happy_path` exits 0, "readiness complete" present, no `client_secret=` in its output. No edit to the journey script was needed.
- Suite `test/lockspire test/mix test/integration`: 2098 tests, 0 failures.

## D-19 telemetry

Final finding from the green clean-room run: no telemetry warning, crash or `Failed to lookup telemetry handlers` appeared in the journey log across all three bare tasks. No `:telemetry.attach` exists in lib or the clean-room scripts, so no audit handler runs in a bare task.

## Notes for Phase 161 docs

- Audit telemetry is not delivered from bare tasks. `created_by` on the client row is the CLI audit trail.

## Deviations from Plan

None - plan executed exactly as written. The doctor tasks needed no `:plug_crypto` start (they do not use Plug.Crypto).

## Known Stubs

None.

## Self-Check: PASSED

- Files exist: both lib tasks, both cold modules, both updated test modules.
- Commits f22654f4 and 52d25488 are ancestors of HEAD.
- Acceptance greps: no `inspect(` in either task; token_format has exactly 1 `Mix.raise` (unknown options guard); 1 `TaskError.run(` in each; no `put_env(:lockspire, :repo, Lockspire.TestRepo)` in the two warm modules; expected-failure grep count 0, same as at 26fd8936.
