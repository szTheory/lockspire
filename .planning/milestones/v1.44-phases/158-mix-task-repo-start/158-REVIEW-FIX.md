---
phase: 158-mix-task-repo-start
fixed_at: 2026-10-18T00:00:00Z
review_path: .planning/phases/158-mix-task-repo-start/158-REVIEW.md
iteration: 1
findings_in_scope: 7
fixed: 7
skipped: 0
status: all_fixed
---

# Phase 158: Code Review Fix Report

**Fixed at:** 2026-10-18
**Source review:** .planning/phases/158-mix-task-repo-start/158-REVIEW.md
**Iteration:** 1

**Summary:**
- Findings in scope: 7
- Fixed: 7
- Skipped: 0

Verification ran in the main checkout (`workflow.use_worktrees=false`), Elixir 1.19.5-otp-28 / Erlang 28.5.

## Fixed Issues

### WR-01: Generic Postgrex and connection phrases misclassify unrelated failures

**Files modified:** `lib/lockspire/install/task_error.ex`, `test/lockspire/install/task_error_test.exs`
**Commit:** 38bdf94f
**Applied fix:** `undefined_table` and `undefined_column` map to the migrate hint. Other Postgrex codes print only the fixed code name plus "check the application logs" (no migrate advice, no message text). `DBConnection.ConnectionError{reason: :queue_timeout}` gets its own pool-timeout phrase; other connection errors say "could not reach the database or it timed out". Tests pin all phrases.

### WR-02: Python harness can put client.create stdout into an exception message

**Files modified:** `scripts/acceptance/clean_room/build_provider.py`
**Commit:** 4b171cc2
**Applied fix:** `_run_mix` redacts `client_secret=...` on every captured line before building the failure message. The success path still returns raw output because the caller must parse the secret, and it never logs it. The existing "bare mix step failed" marker is unchanged. Python syntax and the regex were checked; the clean-room harness itself was not run.

### WR-03: The log-level guard is weaker than the module comments claim

**Files modified:** `lib/lockspire/install/task_error.ex`, `test/lockspire/install/task_error_test.exs`, `test/mix/tasks/lockspire_client_create_cold_test.exs`
**Commit:** 380e5026
**Applied fix:** The guard now raises the process level to `:warning`. A comment documents that logs from other processes (DBConnection/Postgrex) are not covered. The cold log test now runs for both `log: :debug` and `log: :info`.

### WR-04: Cold tests fail every module if any module leaves rows behind

**Files modified:** `test/support/mix_repo_helpers.ex`, three cold test files
**Commit:** fd4163ae
**Applied fix:** Added `sweep_stale_cold_clients!/0`, which deletes rows under the shared `mix-cold-` root. `setup` calls it before asserting. `foreign_client_count/0` now counts only rows outside that root, so genuinely foreign rows still fail the guard and are never deleted.

### IN-01: token_format moduledoc claims it never raises

**Files modified:** `lib/mix/tasks/lockspire.doctor.token_format.ex`, `test/mix/tasks/lockspire_doctor_token_format_cold_test.exs`
**Commit:** a0c14691
**Applied fix:** `Lockspire.Config.repo!()` now runs inside a rescued helper, and the error is classified through TaskError and printed as the usual "Could not inspect token formats" line. Added a test with `:repo` unset.

### IN-02: Debug-log redaction test has no positive control

**Files modified:** `test/mix/tasks/lockspire_client_create_cold_test.exs`
**Commit:** 99f5d5f6
**Applied fix:** Added a control test that registers a client directly (no guard) with `log: :debug` and asserts the INSERT appears in the captured log.

### IN-03: client.create case has no fallback for an unexpected outcome

**Files modified:** `lib/mix/tasks/lockspire.client.create.ex`
**Commit:** 7b02e7d5
**Applied fix:** Added a `{:ok, _other}` clause that raises with the fixed unexpected phrase and never inspects the term. No test was added for it, because reaching it needs a stubbed `register_client`.

## Verification

- `mix format --check-formatted`: pass
- `mix compile --warnings-as-errors --force`: pass
- `mix test test/lockspire/install test/mix test/lockspire/clients_test.exs --include integration`: 138 tests, 0 failures
- `mix test --only integration test/mix`: 29 tests, 0 failures
- Not run: the Python clean-room acceptance harness, and the full `mix test --only integration` suite beyond `test/mix`.

---

_Fixed: 2026-10-18_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
