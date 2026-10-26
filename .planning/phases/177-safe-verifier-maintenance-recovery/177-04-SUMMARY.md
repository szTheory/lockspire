---
phase: 177-safe-verifier-maintenance-recovery
plan: "04"
subsystem: auth-storage
tags: [elixir, mix, verifier-custody, repo-runner, tdd]

requires:
  - phase: 177-safe-verifier-maintenance-recovery
    provides: Mix-free verifier maintenance and exhaustive safe reports from Plan 03.
provides:
  - Bare Mix task-local verifier context resolution with current endpoint/session and signing-key exclusions.
  - Strict verifier maintenance apply, dry-run, and fresh-check CLI modes with fixed safe errors.
  - Immutable startup context for Admin API calls and explicit task-local context threading through rewrap operations.
  - Repo lifecycle coverage proving temporary Repo cleanup and preservation of a running Repo and pool.
affects: [177-05, 177-06, 177-08, verifier-maintenance, release-operations]

actuals:
  tokens: 7664.5
  tasks: 2
  commits: 4
  plan_head_before: 028906704dbe95556f3c6666fc785b264e2b3e66
  plan_head_after: 8c41df35dc1f6fa68728169d9b0d87d4ef4bb31b

tech-stack:
  added: []
  patterns: [fresh task-local config validation, explicit immutable context handoff, post-cleanup CLI rendering]

key-files:
  created:
    - lib/lockspire/security/client_secret_verifier/operation_context.ex
    - lib/mix/tasks/lockspire.clients.verifier.rewrap.ex
    - test/mix/tasks/lockspire_clients_verifier_rewrap_test.exs
    - .planning/phases/177-safe-verifier-maintenance-recovery/177-04-01-red-evidence.json
    - .planning/phases/177-safe-verifier-maintenance-recovery/177-04-02-red-evidence.json
  modified:
    - lib/lockspire/config.ex
    - lib/lockspire/admin/client_verifier_maintenance.ex
    - lib/lockspire/storage/client_verifier_maintenance.ex
    - test/lockspire/config_client_secret_verifier_test.exs
    - test/lockspire/admin/client_verifier_maintenance_test.exs

key-decisions:
  - "Resolve fresh signing configuration for task-local exclusions, including system environment entries; never populate or replace startup persistent_term caches."
  - "Keep Admin API calls bound to the serving-node startup snapshot and label task-local CLI reports distinctly."
  - "Pass the same complete validated operation context through inspection and storage rewrap so bare Mix does not depend on startup caches."
  - "Reject invalid and repeated CLI arguments before resolving the Repo, and render reports or failures only after RepoRunner cleanup."

patterns-established:
  - "Use fixed safe argument errors; never echo raw cursor, option, or malformed configuration values."
  - "Task-local verifier context is an internal complete-context handoff, not a partial runtime override or hot reload."

requirements-completed: [VOPS-01, VOPS-03]
coverage:
  - id: D1
    description: "Bare Mix resolves validated verifier configuration and uncached signing exclusions without starting Lockspire supervision or mutating serving caches."
    requirement: VOPS-03
    verification:
      - kind: integration
        ref: "test/mix/tasks/lockspire_clients_verifier_rewrap_test.exs#bare config resolves signing and endpoint exclusions without starting Lockspire"
        status: pass
      - kind: unit
        ref: "test/lockspire/config_client_secret_verifier_test.exs#task-local verifier resolution does not replace the serving-node startup snapshot"
        status: pass
    human_judgment: false
  - id: D2
    description: "The dedicated CLI strictly validates arguments, reports task-local source, supports apply/dry-run/check, and preserves Repo ownership."
    requirement: VOPS-01
    verification:
      - kind: integration
        ref: "test/mix/tasks/lockspire_clients_verifier_rewrap_test.exs#bare task previews, applies, and checks while stopping only its temporary Repo"
        status: pass
      - kind: unit
        ref: "test/mix/tasks/lockspire_clients_verifier_rewrap_test.exs#invalid argument errors never echo hostile values"
        status: pass
      - kind: unit
        ref: "test/lockspire/install/repo_runner_test.exs"
        status: pass
      - kind: unit
        ref: "test/lockspire/install/task_error_test.exs"
        status: pass
    human_judgment: false

duration: 14min
completed: 2026-10-26
status: complete
---

# Phase 177 Plan 04: Task-Local Verifier Maintenance Summary

**Bare Mix now runs verifier custody apply, preview, and fresh checks with validated task-local keys, fixed safe errors, and Repo ownership preserved.**

## Performance

- **Duration:** 14 min
- **Started:** 2026-10-26T01:56:30Z
- **Completed:** 2026-10-26T02:09:55Z
- **Tasks:** 2
- **Files modified:** 8 source and test files (plus two RED evidence records)

## Accomplishments

- Added `OperationContext.resolve/0`, which freshly validates verifier and signing-key configuration, includes endpoint/session secret exclusions, handles signing system environment entries, and fails closed without exposing key material.
- Kept serving-node `persistent_term` context immutable while allowing the Mix-free Admin core to label startup versus task-local configuration.
- Added `mix lockspire.clients.verifier.rewrap` with strict `--dry-run`, `--check`, `--limit`, `--after-client-id`, and `--help` handling. Default mode applies eligible work; check rejects resumed cursors and only passes a fresh complete custody scan.
- Verified both Repo paths: a temporary Repo stops before task output/error, and an already-running Repo and pool retain their original PIDs.
- Recorded validated TDD RED evidence for both tasks; both RED targets failed on their planned missing API assertions before the corresponding implementation commits.

## Task Commits

1. **177-04-01: Resolve bare-task configuration without mutating serving context** — `4f435cea` (RED), `ec0104cb` (GREEN).
2. **177-04-02: Wire strict CLI modes and Repo ownership to safe outcome rendering** — `620f9b5d` (RED), `8c41df35` (GREEN).

Measured production/task commit count: 4, from `028906704dbe95556f3c6666fc785b264e2b3e66` through `8c41df35dc1f6fa68728169d9b0d87d4ef4bb31b`. The plan metadata commit is separate.

## Files Created/Modified

- `lib/lockspire/security/client_secret_verifier/operation_context.ex` — resolves a complete validated task-local context with fresh signing exclusions and no cache writes.
- `lib/mix/tasks/lockspire.clients.verifier.rewrap.ex` — thin verifier-specific CLI with strict pre-Repo argument validation and safe post-cleanup report rendering.
- `lib/lockspire/config.ex` — shares endpoint/session exclusion discovery and adds fresh signing-key exclusion projection.
- `lib/lockspire/admin/client_verifier_maintenance.ex` — accepts an explicit complete internal task-local context and labels report source.
- `lib/lockspire/storage/client_verifier_maintenance.ex` — consumes the same validated operation context during selected-store rewrap.
- `test/lockspire/config_client_secret_verifier_test.exs` — startup immutability and task-local isolation coverage.
- `test/lockspire/admin/client_verifier_maintenance_test.exs` — expects the explicit `:startup` source label.
- `test/mix/tasks/lockspire_clients_verifier_rewrap_test.exs` — bare subprocess, signing exclusion, argument safety, CLI mode, and Repo ownership coverage.
- `177-04-01-red-evidence.json`, `177-04-02-red-evidence.json` — machine-validated RED records.

## Verification

All runtime tests used the plan-owned `lockspire_phase177_20261026_owned` database and the required Elixir/OTP toolchain. The shared `lockspire_test` database was not used.

| Command | Result |
|---|---|
| `MIX_ENV=test mix test test/lockspire/config_client_secret_verifier_test.exs test/mix/tasks/lockspire_clients_verifier_rewrap_test.exs` | Exit 0; 30 tests, 0 failures. |
| `MIX_ENV=test mix test test/mix/tasks/lockspire_clients_verifier_rewrap_test.exs test/lockspire/install/repo_runner_test.exs test/lockspire/install/task_error_test.exs` | Exit 0; 33 tests, 0 failures. |
| Combined focused run including Admin maintenance tests | Exit 0; 59 tests, 0 failures. |
| `mix format --check-formatted` on all changed Elixir files | Passed. |
| `git diff --check` | Passed. |
| `gsd_run check tdd-red-evidence` for both RED records | Both returned `RED_EVIDENCE_OK`. |
| `gsd_run check evaluation-scope --plan 177-04 --commits-only --raw` | Resolved exactly four task commits; no out-of-scope commits. |

## TDD Gate Compliance

- **177-04-01 RED:** The target assertion failed because `OperationContext` was absent; TAP recorded one target failure and the evidence checker returned `RED_EVIDENCE_OK`.
- **177-04-01 GREEN:** Bare subprocess, cross-purpose signing-key reuse, invalid signing environment, and unchanged startup snapshot tests passed.
- **177-04-02 RED:** The target assertion failed because the dedicated Mix task was absent; TAP recorded one target failure and the evidence checker returned `RED_EVIDENCE_OK`.
- **177-04-02 GREEN:** Strict CLI, apply/dry-run/check outcomes, safe errors, temporary cleanup, and live Repo/pool preservation tests passed.
- **REFACTOR:** No separate refactor commit was needed.

## Decisions Made

- Freshly decode and validate signing configuration for task-local verifier exclusions, including `{ :system, env_name }` entries; malformed signing configuration blocks maintenance.
- Keep the public Admin default on the immutable serving-node startup snapshot. The CLI resolves one task-local context and threads it through both report inspection and storage rewrap.
- Print and raise only after the RepoRunner operation returns, so temporary Repo cleanup completes before terminal output while a live Repo remains untouched.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Threaded task-local context through the existing storage rewrap path**
- **Found during:** Task 2 (CLI apply integration)
- **Issue:** Bare CLI preview used the task-local context, but apply delegated to `rewrap_client/2`, which required the serving-node persistent context and returned `maintenance_failed` when no startup cache existed.
- **Fix:** Added a narrow internal `:operation_context` option, validates the complete context before selected-store access, and passes the same context from Admin into rewrap. The default API path still resolves the startup snapshot.
- **Files modified:** `lib/lockspire/admin/client_verifier_maintenance.ex`, `lib/lockspire/storage/client_verifier_maintenance.ex`
- **Verification:** Focused CLI apply and fresh-check integration passed; storage, Admin, RepoRunner, and TaskError suites passed.
- **Committed in:** `8c41df35`

**2. [Rule 1 - Bug] Detect duplicate options from original argv**
- **Found during:** Task 2 (CLI argument tests)
- **Issue:** `OptionParser` kept only the last repeated boolean switch, so inspecting parsed options could not reject duplicate flags.
- **Fix:** Count option names from the original argv (normalizing `--name=value`) before configuration or database work.
- **Files modified:** `lib/mix/tasks/lockspire.clients.verifier.rewrap.ex`
- **Verification:** The duplicate `--dry-run` test now fails safely before Repo startup; all CLI tests pass.
- **Committed in:** `8c41df35`

**Total deviations:** 2 auto-fixed (Rule 1: 2)
**Impact on plan:** Both changes were required for the planned bare-Mix apply path and strict duplicate-argument contract. No dependency, schema, protocol, or public report shape changed.

## Issues Encountered

- The first apply integration run exposed the cached-context dependency described above; the operation context is now shared across inspection and mutation.
- The first duplicate-option assertion exposed `OptionParser`'s repeated-switch behavior; validation now checks original argv before proceeding.

## User Setup Required

None.

## Next Phase Readiness

The CLI and task-local configuration seam are ready for the remaining Phase 177 recovery and disclosure work. Bare Mix does not start Lockspire supervision, and release RPC uses the serving node's startup context. Phase 177 and Phase 178 remain in progress.

---
*Phase: 177-safe-verifier-maintenance-recovery*
*Completed: 2026-10-26*

## Self-Check: PASSED

- All created implementation files, RED evidence, and this SUMMARY exist.
- All four task commits are ancestors of the current plan head.
- `evaluation-scope` resolves exactly the four task commits and reports no missing, outside-union, or unreachable commits.
