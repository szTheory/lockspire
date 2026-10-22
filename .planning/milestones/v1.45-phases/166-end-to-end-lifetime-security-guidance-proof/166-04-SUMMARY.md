---
phase: 166-end-to-end-lifetime-security-guidance-proof
plan: "04"
subsystem: testing
tags: [elixir, postgres, oauth, concurrency, rollback]
requires:
  - phase: 162-lifetime-semantics-upgrade-contract
    provides: Fixed DCR lifetime and concurrency contract cases
  - phase: 164-client-secret-expiry-atomic-rotation
    provides: Shared-secret expiry, rotation and PostgreSQL waits
  - phase: 165-management-token-lifecycle-recovery
    provides: Management-token replacement, recovery and rollback
provides:
  - Candidate-revision-bound measured PostgreSQL lifetime wait and rollback evidence
affects: [phase-166-final-proof, dcr-lifetime-evidence]
actuals:
  tokens: 4366
  tasks: 2
  commits: 1
commits: 1
plan_head_before: 56369d7175db91bb8de733d15b6de0c572f2e30d
plan_head_after: c3b3b97ab3918f3abbf93bdf0d652814c03b7160
tech-stack:
  added: []
  patterns: [unboxed PostgreSQL sessions with observed blockers, bounded evidence receipts]
key-files:
  created:
    - .planning/phases/166-end-to-end-lifetime-security-guidance-proof/166-POSTGRES-EVIDENCE.json
  modified: []
key-decisions:
  - Reuse the existing PostgreSQL race helper and focused suites; add no duplicate schedule or runtime behavior.
  - Keep contention proof distinct from same-transaction rollback assertions and disclose the remaining packaged-adapter observation gate.
requirements-completed: []
duration: 2min
completed: 2026-10-22
status: complete
---

# Phase 166 Plan 04: Observed PostgreSQL Wait and Rollback Proof Summary

**Existing client, grant, secret-rotation and management-token schedules passed against PostgreSQL with distinct backend sessions and observed blockers, and the retained receipt separates those schedules from same-transaction rollback assertions.**

## Performance

- **Duration:** Approximately 2 minutes.
- **Started:** 2026-10-22T00:19:31Z.
- **Completed:** 2026-10-22T00:21:13Z.
- **Tasks:** 2/2.
- **Files modified:** 2 (evidence JSON and this summary).

## Accomplishments

- Ran `mix test.setup`; the dedicated `lockspire_phase165_validation` database already existed and migrations were current.
- Reproduced expiry/current-state checks after app-client and grant/token waits, including authorization-code redemption, refresh-family rotation, device/CIBA polling and exchange requests. The tested helpers use unboxed PostgreSQL sessions with distinct `pg_backend_pid()` values and poll `pg_blocking_pids(contender)` until the expected holder is observed before releasing it. The only sleep in this coordination path polls for a blocker; it does not establish expiry or ordering.
- Verified secret replacements serialize so the last committed secret is current, while same-fingerprint management replacements/recovery have one winner. Focused tests assert current credential hashes/verifier, lifecycle versions and deadlines, enabled state, grant/token transitions and audit effects as applicable.
- Recorded rollback checks for failed client/audit writes, grant consumption and token insertion, refresh/device/CIBA/exchange state, and legacy promotion. The receipt explicitly labels rollback and canonicalization tests without a holder/contender as same-transaction observations and does not claim configured packaged-adapter independent rollback proof.

## Verification

All commands used Elixir 1.18.4 / OTP 27.3.4.15 and the dedicated PostgreSQL test database. The output file contains the full commands and test references.

- Client/grant wait selection — **16 tests, 0 failures, 0 excluded, 0 skipped**; ExUnit runtime 0.7 seconds.
- Management contention/replacement/promotion selection — **34 tests, 0 failures, 0 excluded, 0 skipped**; ExUnit runtime 1.0 second.
- Secret rotation and rollback selection — **13 tests, 0 failures, 0 excluded, 0 skipped**; ExUnit runtime 0.4 seconds.
- Total: **63 test invocations, 0 failures, 0 excluded, 0 skipped, 3 seconds rounded total**. Selections overlap; 63 is not a unique-test count.
- The JSON receipt parsed and reconciled all three run totals and seven schedule records. `git diff --check` passed.

This evidence is local PostgreSQL proof for the named existing suites. It does not establish independent durable rollback observation for the configured packaged adapter, live required CI, scoped security review, packaged fresh/legacy journeys or final adopter guidance; those remain assigned to later Phase 166 plans.

## Task Commits

The two tasks share one final evidence artifact, which was recorded in a single atomic commit after both prescribed selections completed:

1. **166-04-01 and 166-04-02: Reproduce PostgreSQL wait, contention and rollback schedules** — `c3b3b97a` (`test`).

## Deviations from Plan

None in behavior or test scope. The shared evidence artifact was committed once after both task selections so its command/count receipt describes the complete run set.

## Self-Check: PASSED

- `.planning/phases/166-end-to-end-lifetime-security-guidance-proof/166-POSTGRES-EVIDENCE.json` and this summary exist.
- Task commit `c3b3b97a` is an ancestor of the plan head.
- All three prescribed ExUnit selections passed with positive counts; JSON structure and totals were checked after the evidence commit.
- Existing uncommitted `.planning/STATE.md`, `.planning/ROADMAP.md` and `.planning/state.json` edits were left untouched and unstaged.

---
*Phase: 166-end-to-end-lifetime-security-guidance-proof*
*Completed: 2026-10-22*
