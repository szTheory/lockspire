---
phase: 158-mix-task-repo-start
plan: 03
subsystem: mix-tasks
tags: [mix, client-create, task-error, redaction, safe-02]
requires: [158-01, 158-02]
provides:
  - TaskError phrase and exit/throw classification pinned by tests
  - client.create per-field failure format (D-07) and crash-after-write help (D-12)
  - RegistrationResult inspect hides client_secret (D-10)
  - cold-path and log-suppression tests for client.create (D-11, D-13)
affects: []
tech-stack:
  added: []
  patterns: [fixed-phrase-for-base-errors, derive-inspect-except]
key-files:
  created:
    - test/lockspire/install/task_error_test.exs
  modified:
    - lib/lockspire/install/repo_runner.ex
    - lib/mix/tasks/lockspire.client.create.ex
    - lib/lockspire/clients/registration_result.ex
    - test/lockspire/install/repo_runner_test.exs
    - test/mix/tasks/lockspire_client_create_cold_test.exs
    - test/lockspire/clients_test.exs
    - .planning/phases/158-mix-task-repo-start/158-VALIDATION.md
key-decisions:
  - "A :base persistence error renders a fixed phrase and never its inspected detail"
  - "No Ecto log option added to storage code; the D-11 process log level in TaskError.run/2 is the control"
requirements-completed: [TASK-02, TASK-03]
status: complete
duration: 25 min
completed: 2026-10-19
actuals:
  tokens: 14000
  tasks: 3
  commits: 3
plan_head_before: f5139e099f9030b98ed2e6eb46b9836db6071c04
plan_head_after: d78a34c3d6771df0cfb56e4ed7d12d98eae11a86
commits: 3
---

# Phase 158 Plan 03: Real failure reasons and no secret leakage Summary

`mix lockspire.client.create` now reports one `  - <field>: <detail>` line per validation or write failure under "client registration failed; nothing was saved:", `RegistrationResult` no longer inspects its secret, and tests prove each fixed database phrase, exit/throw handling, and debug-log suppression.

## Accomplishments

- `task_error_test.exs` (14 tests): every D-06 phrase, exit and throw inside the fun (repo stopped and running) return `unexpected_phrase()` and never the repo-unavailable phrase, missing-table cold case, RaisingRepo, process log level restored (nil and :warning).
- `repo_runner_test` uses `assert_pool_untouched!/2`; RepoRunner comment rewritten, non-comment code byte-identical to 26fd8936 (verified by diff).
- client.create: D-07 formatter (`format_domain_errors/1`, `error_line/1`, `detail_text/1`), `:base` fixed phrase, D-12 help note using "Apps"/"rotate", D-19 help line (audit telemetry is not delivered in a bare task; `created_by` records who registered the app).
- `@derive {Inspect, except: [:client_secret]}` on `RegistrationResult`.
- Cold module now 7 tests: success, duplicate id, invalid redirect URI (fragment), no options, RaisingRepo, public client, and debug-log capture with a control marker (no INSERT, secret, hash or sealed verifier in the log).
- `clients_test`: CLI test inside `assert_pool_untouched!/2`, `client_secret=` exactly once, inspect refute.
- Phase gate on 1.19.5-otp-28: `mix ci` green (1798 tests, 0 failures), `mix test --only integration` 320 tests 0 failures, clean-room `--only happy_path` exit 0 with "readiness complete" and no `client_secret=` in its output.

## Scope notes

`mix lockspire.keys.reencrypt` stays on raw `Ecto.Migrator.with_repo` (it already works in a bare session) per the CONTEXT deferral; this phase fixed the three broken DB-touching tasks named in TASK-01.

## Deviations from Plan

**1. [Rule 1 - Test bug] Invalid redirect URI fixture**
- **Found during:** Task 2
- **Issue:** The plan's `http://insecure.example/cb` example is accepted by Lockspire's redirect validation, so the run succeeded.
- **Fix:** Test uses `https://client.example.com/cb#frag` (fragment_not_allowed), which is rejected.
- **Files modified:** test/mix/tasks/lockspire_client_create_cold_test.exs
- **Commit:** fcc3a4aa

**2. [Rule 2 - Coverage] Extra public-client cold test** to reach the plan's 7-test floor for the cold module.

**Total deviations:** 2 (1 test fixture fix, 1 added test). **Impact:** none on production code.

## Regressions outside plan 03 scope

None. (The first clean-room attempt failed only because the CI Elixir env was not exported; it passed with it set.)

## Known Stubs

None.

## Self-Check: PASSED

- All created/modified files exist; commits 9e76ec96, fcc3a4aa, d78a34c3 are ancestors of HEAD.
- Acceptance greps: derive 1, "nothing was saved:" 1, no `inspect(` in client.create, "read-only" 0 in repo_runner, `git diff --quiet 26fd8936` on clients.ex/storage/mix.exs/mix.lock/priv clean.
