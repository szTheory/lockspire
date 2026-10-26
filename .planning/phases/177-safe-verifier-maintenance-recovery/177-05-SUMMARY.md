---
phase: 177-safe-verifier-maintenance-recovery
plan: "05"
subsystem: storage
tags: [ecto, postgresql, concurrency, client-verifier, transactions]

requires:
  - phase: 177-03
    provides: selected verifier maintenance capability and compare-and-rewrap callback
provides:
  - Independent PostgreSQL evidence for both rotation/maintenance serialization orders
  - Commit-boundary rejection for a reporting rewrap invoked inside an open selected transaction
  - Rollback, overlap, partial-progress, retry, and uncertain-commit reconciliation evidence
affects: [177-06, 177-08, 177-09]

actuals:
  tokens: 9088
  tasks: 2
  commits: 4
plan_head_before: d780948277cb4fce6f6df504011d457debcae0ad
plan_head_after: a81069c660cce35006e410b984d8baee865146ac

tech-stack:
  added: []
  patterns:
    - Independent SQL Sandbox unboxed connections with committed test-owned fixtures
    - Exact pg_blocking_pids checks tied to captured contender and blocker backend PIDs
    - Reporting maintenance must establish ownership of the outer commit boundary

key-files:
  created:
    - test/support/client_verifier_maintenance_concurrency.ex
    - test/integration/client_secret_verifier_maintenance_concurrency_test.exs
    - .planning/phases/177-safe-verifier-maintenance-recovery/177-05-02-red-evidence.json
  modified:
    - lib/lockspire/storage/client_verifier_maintenance.ex

key-decisions:
  - "Reject a reporting rewrap when its selected Ecto repository is already in a transaction; preserve the low-level callback for caller-owned transactions."
  - "Treat a lost commit response as uncertain and require a fresh complete inventory before reconciliation."
  - "Keep hash rotation authoritative and update verifier ciphertext without touching unrelated client fields."

patterns-established:
  - "Prove lock order by holding a transaction with explicit messages and observing the exact blocker PID from a third connection."
  - "Use real committed client rows for concurrency and partial-progress tests; clean only rows and audit events owned by each fixture."

requirements-completed: ["VOPS-01","VOPS-02"]
coverage:
  - id: D1
    description: "Real PostgreSQL lock-order and unrelated-metadata tests preserve authoritative rotation and verifier-only updates."
    requirement: VOPS-02
    verification:
      - kind: integration
        ref: test/integration/client_secret_verifier_maintenance_concurrency_test.exs#test stale maintenance conflicts after authorized rotation commits
        status: pass
      - kind: integration
        ref: test/integration/client_secret_verifier_maintenance_concurrency_test.exs#test rotation waits for maintenance then writes coherent credential fields
        status: pass
      - kind: integration
        ref: test/integration/client_secret_verifier_maintenance_concurrency_test.exs#test metadata edit blocked behind maintenance preserves both committed changes
        status: pass
    human_judgment: false
  - id: D2
    description: "Audit rejection, caller rollback, exact repeats, and randomized overlapping replacements preserve atomicity and truthful outcomes."
    requirement: VOPS-02
    verification:
      - kind: integration
        ref: test/integration/client_secret_verifier_maintenance_concurrency_test.exs#test maintenance does not report success before its selected transaction commits
        status: pass
      - kind: integration
        ref: test/integration/client_secret_verifier_maintenance_concurrency_test.exs#test provisional changed callback leaves no row or audit after selected outer rollback
        status: pass
      - kind: integration
        ref: test/integration/client_secret_verifier_maintenance_concurrency_test.exs#test rejected maintenance audit rolls back the verifier replacement
        status: pass
      - kind: integration
        ref: test/integration/client_secret_verifier_maintenance_concurrency_test.exs#test randomized overlapping replacements serialize and stale contender conflicts
        status: pass
    human_judgment: false
  - id: D3
    description: "Committed partial progress survives failure; authorized recovery and a fresh scan converge, including after an uncertain commit response."
    requirement: VOPS-01
    verification:
      - kind: integration
        ref: test/integration/client_secret_verifier_maintenance_concurrency_test.exs#test partial maintenance progress persists and a fresh retry converges
        status: pass
      - kind: integration
        ref: test/integration/client_secret_verifier_maintenance_concurrency_test.exs#test lost commit response remains uncertain until a fresh complete inventory
        status: pass
    human_judgment: false

duration: 11 min
completed: 2026-10-26
status: complete
---

# Phase 177 Plan 05: Safe Verifier Maintenance Concurrency Summary

**Independent PostgreSQL races now prove maintenance preserves host rotation and metadata, while reporting calls fail closed when an enclosing transaction owns the real commit.**

## Performance

- **Duration:** 11 min
- **Started:** 2026-10-26T02:12:00Z
- **Completed:** 2026-10-26T02:23:17Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments

- Added a barrier-based PostgreSQL harness that records distinct contender and blocker backend PIDs and confirms their exact relationship through `pg_blocking_pids`.
- Proved rotation-first conflicts without replacing the new hash, verifier, deadlines, or timestamps; proved maintenance-first waits before authorized rotation writes coherent new credential material.
- Proved metadata edits made before maintenance reload and while maintenance holds the row survive the verifier-only change.
- Rejected the reporting rewrap operation when the selected Ecto repository is already in a transaction, preventing provisional `:changed` from being mistaken for a committed outcome.
- Covered audit rejection, outer rollback, exact-repeat idempotence, randomized overlapping replacements, committed partial progress, fresh retry, and a lost commit response reconciled by a fresh complete inventory.

## Task Commits

1. **Task 1: Serialize maintenance with real rotation and unrelated edits** — `46d23599` (test; all planned lock and preservation assertions passed against the existing adapter).
2. **Task 2 RED: Prove rollback, overlapping retries and committed progress** — `a49b7737` (test; RED evidence validated by `gsd-tools check tdd-red-evidence`).
3. **Task 2 additional recovery cases** — `dc72d656` (test; provisional rollback and uncertain commit reconciliation).
4. **Task 2 GREEN: Reject nested verifier maintenance transactions** — `a81069c6` (fix).

Measured task commit range: 4 commits, from `d780948277cb4fce6f6df504011d457debcae0ad` through `a81069c660cce35006e410b984d8baee865146ac`.

## Files Created/Modified

- `test/support/client_verifier_maintenance_concurrency.ex` — independent transaction barriers, exact backend blocker observation, and deterministic uncertain-response adapter.
- `test/integration/client_secret_verifier_maintenance_concurrency_test.exs` — PostgreSQL serialization, metadata preservation, rollback, retries, and reconciliation cases.
- `lib/lockspire/storage/client_verifier_maintenance.ex` — fail-closed commit-boundary check for the reporting rewrap operation.
- `.planning/phases/177-safe-verifier-maintenance-recovery/177-05-02-red-evidence.json` — machine-validated assertion-level RED record.

## Decisions Made

- The reporting maintenance API owns its transaction boundary; if the selected Ecto repository is already in a transaction, it returns a safe failure before fetching or mutating a client. The low-level compare-and-rewrap callback remains provisional and callable inside a caller-owned transaction.
- An ambiguous transaction response is not reported as rollback or success. A fresh, complete inventory establishes the stored outcome.
- Tests use committed, uniquely identified fixtures and clean up only their own client and audit rows.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Prevented provisional rewrap success from escaping an enclosing transaction**
- **Found during:** Task 2 (rollback and committed progress)
- **Issue:** The reporting rewrap API returned `{:ok, :changed}` from a nested transaction before its caller’s outer transaction committed. A subsequent outer rollback removed the replacement and audit while the caller had already observed success.
- **Fix:** Check the selected transaction authority’s Ecto repository before the reporting operation; return the fixed safe maintenance failure when the repository is already in a transaction or the boundary cannot be established.
- **Files modified:** `lib/lockspire/storage/client_verifier_maintenance.ex`
- **Verification:** Focused PostgreSQL test confirms the API returns an error inside the outer transaction and the forced rollback leaves the verifier and audit count unchanged; final focused suite passed.
- **Commit:** `a81069c6`

**2. Task 1 behavior already passed before production changes**
- The newly added independent-backend lock and preservation assertions passed against the existing adapter, so no production edit was needed for Task 1. No failing assertion was fabricated; the test-only commit records the additional acceptance evidence.

**Total deviations:** 1 auto-fixed bug; 1 TDD scope adjustment because Task 1 behavior already existed. **Impact:** The only production change closes the false-success transaction boundary; the remaining work adds PostgreSQL evidence in the planned scope.

## Verification

- `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 ERL_FLAGS='+S 4' MIX_ENV=test LOCKSPIRE_TEST_DB_NAME=lockspire_phase177_20261026_owned mix format --check-formatted lib/lockspire/storage/client_verifier_maintenance.ex test/support/client_verifier_maintenance_concurrency.ex test/integration/client_secret_verifier_maintenance_concurrency_test.exs` — passed.
- `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 ERL_FLAGS='+S 4' MIX_ENV=test LOCKSPIRE_TEST_DB_NAME=lockspire_phase177_20261026_owned mix test --include integration test/integration/client_secret_verifier_maintenance_concurrency_test.exs test/integration/client_secret_verifier_maintenance_test.exs` — 18 tests, 0 failures.
- `node /Users/jon/.codex/gsd-core/bin/gsd-tools.cjs check tdd-red-evidence .planning/phases/177-safe-verifier-maintenance-recovery/177-05-02-red-evidence.json --raw` — `RED_EVIDENCE_OK`; the target assertion failed because the nested operation prematurely returned `{:ok, :changed}`.
- `git diff --check` — passed.

## TDD Gate Compliance

- **Task 177-05-01:** The new lock-order behavior already passed with the existing adapter before production edits. The test commit is retained; no implementation change or artificial RED was added.
- **Task 177-05-02:** RED commit `a49b7737` precedes GREEN commit `a81069c6`; the RED record passed the machine classifier and semantic inspection. Commit `dc72d656` adds further passing rollback and reconciliation assertions before GREEN.

## Issues Encountered

- The first precondition probe attempted to use `Sandbox.unboxed_run/2` before starting `TestRepo`; after explicitly starting the repo, three simultaneous connections returned three distinct PostgreSQL backend PIDs.
- The managed sandbox intermittently denied Git index writes. Authorized staging was retried with the scoped elevated Git permission; all commits used normal hooks.

## User Setup Required

None.

## Next Phase Readiness

The phase now has real lock-order and rollback evidence for the selected PostgreSQL authority. Requirement IDs remain shared with unfinished plans, so the project requirements checklist stays unchanged until the other declaring plans finish. Phase 177 and Phase 178 completion are not claimed.

## Self-Check: PASSED

- All four listed created/modified files exist.
- Task commits `46d23599`, `a49b7737`, `dc72d656`, and `a81069c6` are ancestors of the recorded plan head.
- The plan commit ledger measures 4 commits from `d780948277cb4fce6f6df504011d457debcae0ad` to `a81069c660cce35006e410b984d8baee865146ac`.

---
*Phase: 177-safe-verifier-maintenance-recovery*
*Completed: 2026-10-26*
