---
phase: 158-mix-task-repo-start
verified: 2026-10-18T00:00:00Z
status: passed
score: 4/4 must-haves verified
behavior_unverified: 0
overrides_applied: 0
---

# Phase 158: Mix Task Repo Start Verification Report

**Phase Goal:** A host developer can run every DB-touching Lockspire Mix task in a bare `mix` session and get either the intended result or the real failure reason.
**Status:** passed
**Re-verification:** No (initial verification)

## Observable Truths (ROADMAP success criteria)

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Clean-room journey first reproduces the failure, then runs the three tasks against a repo-not-running host and all succeed | VERIFIED | Commit cc33e5bf (journey step `assert_bare_mix_tasks`) precedes fix commits a2fa96b1, f22654f4 and 52d25488. The step runs `client.create`, `doctor token_format` and `doctor remote-jwks` in bare mix processes. Orchestrator gate: `--only happy_path` exit 0. |
| 2 | Each task has a no-pre-started-repo test and a running-pool-pid-unchanged check, via RepoRunner (not raw `with_repo`, not `app.start`) | VERIFIED | Cold tests: `client_create_cold` (8), `doctor_token_format_cold` (4), `doctor_remote_jwks_cold` (3). `assert_pool_untouched!` (in `test/support/mix_repo_helpers.ex`) compares the registered-name pid and the pool pid before and after, with DOWN monitors. It is used in `clients_test.exs`, `token_format_test` and `remote_jwks_test`. All three tasks call `TaskError.run`, which wraps `RepoRunner.run`. `RepoRunner` calls the fun directly when `Process.whereis(repo)` is a pid. I ran `mix test test/mix/tasks test/lockspire/install --include integration`: 125 tests, 0 failures. |
| 3 | A `client.create` validation or write failure shows the real reason, and a secret is printed at most once, only after a successful write | VERIFIED | `client.create` prints only after `register_client` returns `{:ok, ...}`. Domain errors go through `format_domain_errors`, which prints "nothing was saved" plus a per-field reason. Config, DB and unexpected failures use the fixed `TaskError.classify` phrases. `:repo_unavailable` appears only when the repo itself did not start, because `TaskError.guarded` classifies raises inside the fun first. The cold tests assert `refute output =~ "client_secret="` on the duplicate, invalid and failure paths, and exactly one occurrence on success. |
| 4 | Doctor tasks keep exit codes and output shape; no output, error or log carries secret or key material | VERIFIED | Pre-existing doctor tests pass. `TaskError` never passes exception text through; only the Lockspire-authored config prefixes do. Cold tests assert the log carries no insert statement or secret (positive control included), and the clean-room run reported 0 lines containing `client_secret=` (orchestrator gate). |

**Score:** 4/4

## Required Artifacts

| Artifact | Status | Details |
|----------|--------|---------|
| `lib/lockspire/install/task_error.ex` | VERIFIED | Substantive and wired from all three tasks. |
| `lib/lockspire/install/repo_runner.ex` | VERIFIED | Runs the fun directly when the repo is running; otherwise uses `with_repo(mode: :temporary)`. |
| `lib/mix/tasks/lockspire.client.create.ex` | VERIFIED | Uses `TaskError.run`; no raw `with_repo`. |
| `lib/mix/tasks/lockspire.doctor.token_format.ex` | VERIFIED | Uses `TaskError.run`. |
| `lib/mix/tasks/lockspire.doctor.remote_jwks.ex` | VERIFIED | Uses `TaskError.run`. |
| `test/support/mix_repo_helpers.ex` | VERIFIED | Pool fingerprint helper in use. |
| `scripts/acceptance/clean_room_saas_journey.py` | VERIFIED | `assert_bare_mix_tasks` covers all three tasks and redacts secrets. |

## Requirements Coverage

| Requirement | Source Plans | Status | Evidence |
|-------------|--------------|--------|----------|
| TASK-01 | 158-01, 158-02 | SATISFIED | The three tasks start and stop the repo via `RepoRunner` through `TaskError`. Reproduction commit precedes the fixes. |
| TASK-02 | 158-01, 158-03 | SATISFIED | Real failure reasons and at-most-once secret printing, as shown under criterion 3. Doctor exit semantics are unchanged. |
| TASK-03 | 158-01, 158-02, 158-03 | SATISFIED | Cold and pool-untouched tests for all three tasks; the journey invokes all three. |

All three IDs appear in PLAN frontmatter and in REQUIREMENTS.md. No orphans. The REQUIREMENTS.md traceability table still shows "Pending" and the ROADMAP phase checkbox is unchecked; the orchestrator should update both on completion (bookkeeping only).

## Scope note: `mix lockspire.keys.reencrypt`

`lockspire.keys.reencrypt` and `lockspire.test.setup` still use raw `Ecto.Migrator.with_repo` (`reencrypt` at lib/mix/tasks/lockspire.keys.reencrypt.ex:112). The goal sentence says "every DB-touching task", which this literally leaves open. However, REQUIREMENTS TASK-01 through TASK-03 and the ROADMAP success criteria name exactly three tasks. `reencrypt` uses `with_repo` deliberately and was recorded as a CONTEXT deferral. `with_repo` is safe in the bare-mix cold path it targets: it only restarts a pool when the repo is already running. `lockspire.test.setup` is a test-support task. I judge this not a blocker for the phase's contract, but a **WARNING (advisory)**: the goal wording is broader than the delivered scope. The `reencrypt` repo-start behavior is not covered by any requirement. Consider a follow-up item so the goal wording does not overpromise.

## Anti-Patterns

No TBD, FIXME or XXX markers or stubs found in the phase's changed lib files. The review findings WR-01 through WR-04 and IN-01 through IN-03 were fixed (commits 38bdf94f through 7b02e7d5), and the gate evidence is on HEAD after those fixes.

## Gate Evidence (orchestrator-reported, spot-checked)

- `mix ci` exit 0
- `mix test --only integration`: 323 tests, 0 failures
- Clean-room `--only happy_path`: exit 0, 0 `client_secret=` lines
- My targeted re-run (task and install tests): 125 tests, 0 failures

## Human Verification

None required.

## Gaps Summary

No gaps. The phase goal is achieved for the three named tasks. The one advisory is the `keys.reencrypt` scope wording above.

_Verifier: Claude (gsd-verifier)_
