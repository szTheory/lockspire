---
phase: 177-safe-verifier-maintenance-recovery
plan: "01"
subsystem: auth-storage
tags: [elixir, ecto, postgresql, verifier-custody, tdd]

requires:
  - phase: 176-dedicated-verifier-custody-compatible-runtime
    provides: Dedicated verifier envelope, immutable key context, guarded secret hash agreement, and approved native lifetime policy.
provides:
  - Optional selected-store verifier maintenance behavior with exact client/transaction/audit participant preflight.
  - Single-client authenticated native rewrap using verifier-only conditional update and atomic audit.
  - Ecto inventory and compare-and-rewrap callbacks with bounded typed outcomes.
  - Persisted proof for preservation, unchanged partner secret, authority rejection, exact retry, conflicts, and shared-PostgreSQL delegation.
affects: [177-02, 177-03, 177-05, 177-07]

actuals:
  tokens: 9517
  tasks: 2
  commits: 4
commits: 4
plan_head_before: 75e55d8017bf68fc473a121ac9aa66205ae05ada
plan_head_after: d30b3c93f2707d58c0d0205fe3408dd8eebf3fcf

tech-stack:
  added: []
  patterns: [selected-store authority preflight, verifier-only SQL CAS, outer-transaction audit, authenticated native custody rewrap]

key-files:
  created:
    - lib/lockspire/storage/client_verifier_maintenance.ex
    - lib/lockspire/storage/ecto/repository/client_verifier_maintenance.ex
    - test/integration/client_secret_verifier_maintenance_test.exs
    - test/lockspire/storage/client_verifier_maintenance_test.exs
  modified:
    - lib/lockspire/security/client_secret_verifier.ex
    - lib/lockspire/storage/ecto/repository.ex

key-decisions:
  - "Require the optional declaration's complete participant map to match the selected client, transaction, and audit stores and the same authority participants."
  - "Keep native custody decoding separate from partner-secret authentication and only report changed after the selected outer transaction returns committed success."

patterns-established:
  - "Maintenance SQL reads and writes use sensitive repository options; verifier replacement updates only the verifier column."
  - "Exact already-installed replacement is idempotent and does not append a second audit event."

requirements-completed: [VUP-03, VOPS-02]
coverage:
  - id: D1
    description: "Rewraps one persisted native verifier through selected authority while preserving client fields, secret hash, and partner authentication."
    requirement: VUP-03
    verification:
      - kind: integration
        ref: "test/integration/client_secret_verifier_maintenance_test.exs"
        status: pass
    human_judgment: false
  - id: D2
    description: "Rejects incompatible declarations before client access and supports exact retry, conflict, and declared shared-PostgreSQL delegation."
    requirement: VOPS-02
    verification:
      - kind: unit
        ref: "test/lockspire/storage/client_verifier_maintenance_test.exs"
        status: pass
      - kind: integration
        ref: "test/integration/client_secret_verifier_maintenance_test.exs"
        status: pass
    human_judgment: false

duration: 9min
completed: 2026-10-26
status: complete
---

# Phase 177 Plan 01: Native Verifier Maintenance Summary

**Authenticated native verifier rewrap now uses the selected storage authority, verifier-only CAS, and one audit event in the same committed transaction.**

## Performance

- **Duration:** 9 min
- **Started:** 2026-10-26T01:00:54Z
- **Completed:** 2026-10-26T01:09:38Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments

- Added the frozen optional maintenance callbacks and validated their version, authority identity, and exact selected client, transaction, and audit participants before any client read.
- Added authenticated native rewrap that verifies stored secret-hash agreement, keeps current-key rows untouched, and exposes `:changed` only after the selected outer transaction commits.
- Added Ecto inventory and locked compare-and-rewrap callbacks. The write sets only verifier ciphertext, preserves all other columns, and appends the allowlisted audit event in that transaction.
- Proved persisted field preservation, unchanged partner-secret authentication, typed authority failure, idempotent stale-material retry, conflict handling, and supported delegated PostgreSQL composition.

## Task Commits

1. **Task 1: Commit one native verifier-only rewrap through selected authority** — `c59b5bbc` (RED test), `8c0fc353` (GREEN implementation).
2. **Task 2: Enforce adapter declaration and exact repeat semantics** — `f4386b08` (RED test), `d30b3c93` (GREEN implementation).

The four plan commits are measured from `plan_head_before` through `plan_head_after` above.

## Files Created/Modified

- `lib/lockspire/storage/client_verifier_maintenance.ex` — Optional adapter behavior, selected authority preflight, and one-client orchestration.
- `lib/lockspire/storage/ecto/repository/client_verifier_maintenance.ex` — Sensitive bytewise inventory query, row lock, verifier-only conditional update, and atomic audit.
- `lib/lockspire/security/client_secret_verifier.ex` — Internal authenticated native custody rewrap while preserving the current verifier envelope contract.
- `lib/lockspire/storage/ecto/repository.ex` — Thin delegates for the three optional maintenance callbacks.
- `test/integration/client_secret_verifier_maintenance_test.exs` — Persisted tracer, preservation assertions, retry/conflict checks, and delegated-store exercise.
- `test/lockspire/storage/client_verifier_maintenance_test.exs` — Declaration result, participant mismatch, and no-access preflight tests.

## Verification

Preconditions were checked before implementation: Phase 176 verification status was `passed`; all frozen inputs listed by `175-FINAL-SOURCE.json` matched their recorded SHA-256 digests; the process-local Elixir/Mix runtime worked; and a read-only `SELECT 1` succeeded through the configured test PostgreSQL connection.

The final combined focused verification used source identity `d30b3c93f2707d58c0d0205fe3408dd8eebf3fcf`. Task 1's standalone integration run preceded task 2 at `8c0fc353`:

| Command | Result |
|---|---|
| `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 MIX_ENV=test mix test --include integration test/integration/client_secret_verifier_maintenance_test.exs` | Exit 0 at `8c0fc353`; 2 tests, 0 failures |
| `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 MIX_ENV=test mix test --include integration test/lockspire/storage/client_verifier_maintenance_test.exs test/integration/client_secret_verifier_maintenance_test.exs` | Exit 0; 7 tests, 0 failures |

## TDD Evidence

| Task | RED evidence | GREEN evidence |
|---|---|---|
| 177-01-01 | The persisted tracer target failed on the expected missing `configured/0` capability assertion: 1 test, 1 failure, exit 2. | The final integration target passed with 3 tests, 0 failures. |
| 177-01-02 | The declaration-participant target failed because `configured/0` accepted a declaration naming a different client store: 4 tests, 1 failure, exit 2. | The combined unit/integration target passed with 7 tests, 0 failures. |

Both RED runs failed on the target behavior assertions, not compilation, loading, fixtures, or zero-test discovery. The corresponding test commits precede their implementation commits.

## Decisions Made

- Enforced exact equality between the declaration participant map and the selected client, transaction, and audit modules, as well as matching each participant to the selected transaction authority.
- Kept authenticated verifier material inside the internal custody helper and returned only bounded result atoms from the maintenance operation.

## Deviations from Plan

None. Implementation corrections found while bringing the planned transaction path to green remained within the planned behavior and file scope.

## Issues Encountered

- The first transaction result was initially unwrapped at the wrong layer, and the sensitive update options were initially passed with the wrong argument shape. The persisted test exposed both; both were corrected before the task's GREEN commit.
- The authority tests exposed that callback presence and transaction-authority equality did not validate the declaration's own client/transaction participant values. Exact participant-map validation now rejects this before fetch or inventory.

## User Setup Required

None - no external service configuration or dependency installation was required.

## Next Phase Readiness

Plan 01's native single-client boundary is ready for the subsequent authenticated custody classifications and exhaustive inventory work in Phase 177. No Phase 177 or Phase 178 completion is claimed.

## Self-Check: PASSED

- All six created or modified implementation/test files exist.
- All four task commits are ancestors of the plan head recorded above.
- The plan commit range contains four commits, measured from the persisted plan ledger.

---
*Phase: 177-safe-verifier-maintenance-recovery*
*Completed: 2026-10-26*
