---
phase: 158-mix-task-repo-start
reviewed: 2026-10-18T00:00:00Z
depth: standard
files_reviewed: 17
files_reviewed_list:
  - lib/lockspire/clients/registration_result.ex
  - lib/lockspire/install/repo_runner.ex
  - lib/lockspire/install/task_error.ex
  - lib/mix/tasks/lockspire.client.create.ex
  - lib/mix/tasks/lockspire.doctor.remote_jwks.ex
  - lib/mix/tasks/lockspire.doctor.token_format.ex
  - scripts/acceptance/clean_room/build_provider.py
  - scripts/acceptance/clean_room_saas_journey.py
  - test/lockspire/clients_test.exs
  - test/lockspire/install/repo_runner_test.exs
  - test/lockspire/install/task_error_test.exs
  - test/mix/tasks/lockspire_client_create_cold_test.exs
  - test/mix/tasks/lockspire_doctor_remote_jwks_cold_test.exs
  - test/mix/tasks/lockspire_doctor_remote_jwks_test.exs
  - test/mix/tasks/lockspire_doctor_token_format_cold_test.exs
  - test/mix/tasks/lockspire_doctor_token_format_test.exs
  - test/support/mix_repo_helpers.ex
findings:
  critical: 0
  warning: 4
  info: 3
  total: 7
status: issues_found
---

# Phase 158: Code Review Report

**Reviewed:** 2026-10-18
**Depth:** standard
**Files Reviewed:** 17
**Status:** issues_found

## Summary

The design holds up. RepoRunner only restarts the pool when no process owns the repo name. TaskError classifies exceptions into fixed phrases. The client secret is printed only on the `{:ok, {:ok, result}}` path, and `RegistrationResult` no longer inspects the secret. I found no blocker-level leaks of the secret in the Elixir code. The findings below cover misleading classification, a leak path in the acceptance harness, a log-redaction guard weaker than its comments imply, and test fragility. I did not run the integration tests, which need a database.

## Warnings

### WR-01: Generic Postgrex and connection phrases misclassify unrelated failures

**File:** `lib/lockspire/install/task_error.ex:47-54`
**Issue:** Any `Postgrex.Error` other than `undefined_table` yields "the database rejected the request (CODE); check that mix ecto.migrate has run". Codes such as `unique_violation`, `insufficient_privilege`, `check_violation`, and `query_canceled` have nothing to do with migrations, so the advice sends the operator the wrong way. Every `DBConnection.ConnectionError` becomes "could not reach the database", but it is also raised for pool checkout and queue timeouts ("connection not available and request was dropped from queue"). Those are not connectivity failures.
**Fix:** Add a classifier clause for `:undefined_column` and `:undefined_function` that suggests migrating. For other codes, say only "the database rejected the request (code)" and drop the migrate advice. Match `%DBConnection.ConnectionError{reason: :queue_timeout}` separately, or use neutral wording such as "the database connection failed or timed out".

### WR-02: Python harness can put client.create stdout, including the secret, into an exception message

**File:** `scripts/acceptance/clean_room/build_provider.py:290-292`
**Issue:** `_run_mix` merges stderr into stdout. On a nonzero exit it joins the last 16 lines into `PackageInputError`. `run_child_command_output` is now used for `lockspire.client.create`, which prints `client_secret=...`. If the process exits nonzero after printing (a late crash, a halt, or a warnings-as-errors hook), the secret goes into the raised message and the CI log. `assert_bare_mix_tasks` registers the secret with the redactor only after a successful return, so the failure path is unprotected.
**Fix:** Redact `client_secret=\S+` lines before building `details`:
```python
details = [re.sub(r"client_secret=\S+", "client_secret=[REDACTED]", l) for l in lines]
```
Also pass the output through the active redactor, as the other failure paths do.

### WR-03: The log-level guard is weaker than the module comments claim

**File:** `lib/lockspire/install/task_error.ex:71-84`
**Issue:** `Logger.put_process_level(self(), :info)` only suppresses `:debug` events emitted by the calling process. Ecto's query log, which includes INSERT params and sealed secret material, is also emitted at `:info` if the host sets `log: :info`. Logs from the DBConnection and Postgrex processes are unaffected. The guard also does nothing against error-level logs. The cold test proves redaction only for the default `:debug` setting.
**Fix:** Raise the process level to `:warning`, or document that the guarantee holds only for the default Ecto log level. For the client.create write, consider passing `log: false` as a per-call option.

### WR-04: Cold tests fail every module if any module leaves rows behind

**File:** `test/support/mix_repo_helpers.ex:89-98`, plus the three cold test `setup` blocks
**Issue:** `foreign_client_count(prefix_root)` counts every client row that does not match this module's own prefix. These tests commit real rows. If any run crashes before `on_exit` runs (kill, timeout, VM halt), the leftover `mix-cold-create-*` rows make the tokfmt and rjwks cold modules fail, and the reverse. The failure message tells the user to reset the DB manually. The empty-registry token_format test depends on the same zero-row state.
**Fix:** Have `setup` sweep all known cold prefixes before asserting. Alternatively, run the cold suite against a dedicated database or schema, and have `cleanup_clients_by_prefix!` accept a list of prefixes.

## Info

### IN-01: token_format moduledoc claims it never raises

**File:** `lib/mix/tasks/lockspire.doctor.token_format.ex:6-8, 61`
**Issue:** `Lockspire.Config.repo!()` runs outside TaskError and raises when `:repo` is unset, so the docs overstate the guarantee ("never raises"/"never exits non-zero").
**Fix:** Rescue it and print a calm message, or narrow the wording.

### IN-02: Debug-log redaction test has no positive control

**File:** `test/mix/tasks/lockspire_client_create_cold_test.exs:127-167`
**Issue:** `refute log =~ "INSERT"` passes vacuously if debug query logging never fires in this setup. The only control is a manual `Logger.debug` call. The test does not show that the INSERT would be logged without the guard, for example by running a warm-repo variant that logs through Ecto.
**Fix:** Add a control that runs `Repo.insert` directly with the same config and asserts the INSERT is visible. This shows the guard is what removes it.

### IN-03: client.create case has no fallback for an unexpected outcome

**File:** `lib/mix/tasks/lockspire.client.create.ex:49-53`
**Issue:** If `Clients.register_client` ever returns `{:error, non_list}`, the case raises `CaseClauseError`, whose message inspects the term. That term is outside TaskError's classification and could leak error details.
**Fix:** Add `{:ok, {:error, _other}} -> Mix.raise("client registration failed: " <> TaskError.unexpected_phrase())`.

---

_Reviewed: 2026-10-18_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
