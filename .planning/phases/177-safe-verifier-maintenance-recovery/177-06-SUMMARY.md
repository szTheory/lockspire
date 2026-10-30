---
phase: 177-safe-verifier-maintenance-recovery
plan: "06"
subsystem: testing
tags: [elixir, postgres, oauth, client-secret-jwt, recovery]

requires:
  - phase: 177-safe-verifier-maintenance-recovery
    provides: Guarded JWT issuance and the selected verifier maintenance and storage paths from Plans 03–05.
provides:
  - Real PostgreSQL maintenance between JWT authentication and the issuance current-row guard, with replay and fresh-JTI recovery evidence.
  - Reader-first verifier key activation, idempotent rewrap and fresh local custody check coverage.
  - Lost-key status, original-key restoration and existing authorized secret-rotation recovery coverage.
affects: [verifier-maintenance, guarded-issuance, client-secret-recovery, phase-178-delivery]

actuals:
  tokens: 8194
  tasks: 2
  commits: 2

commits: 2
plan_head_before: be6faa47f0916826bc65353b9e59fe3f8636918c
plan_head_after: dcedc2389c4191ac2849a8c7fe31337a25c03a27

tech-stack:
  added: []
  patterns: [independent PostgreSQL test backends, persisted recovery journeys, explicit authentication and guard barriers]

key-files:
  created:
    - test/integration/client_secret_verifier_maintenance_issuance_test.exs
    - test/integration/client_secret_verifier_maintenance_recovery_test.exs
  modified:
    - test/support/client_verifier_maintenance_concurrency.ex

key-decisions:
  - "Use independent committed database connections to place real verifier maintenance between JWT authentication and the issuance row guard."
  - "Treat original-key restoration and authorized secret replacement as distinct recovery paths with different partner-secret consequences."

patterns-established:
  - "Test adapters signal after JTI consumption and before current-row locking; maintenance commits through a second PostgreSQL backend."
  - "Recovery reports are checked for bounded identities and reasons, while tests keep plaintext and ciphertext out of reporter output."

requirements-completed: [VUP-03, VOPS-02, VOPS-04]
coverage:
  - id: D1
    description: Real maintenance invalidates an authenticated JWT client identity before authorization-code issuance.
    requirement: VOPS-02
    verification:
      - kind: integration
        ref: test/integration/client_secret_verifier_maintenance_issuance_test.exs
        status: pass
    human_judgment: false
  - id: D2
    description: Reader-first rewrap and fresh complete local custody checks preserve partner credentials and unrelated authentication.
    requirement: VUP-03
    verification:
      - kind: integration
        ref: test/integration/client_secret_verifier_maintenance_recovery_test.exs
        status: pass
    human_judgment: false
  - id: D3
    description: Missing-key status fails JWT authentication closed and proves original-key restoration and authorized rotation recovery.
    requirement: VOPS-04
    verification:
      - kind: integration
        ref: test/integration/client_secret_verifier_maintenance_recovery_test.exs
        status: pass
    human_judgment: false

duration: 6min
completed: 2026-10-26
status: complete
---

# Phase 177 Plan 06: Issuance and Recovery Summary

**Persisted PostgreSQL races and recovery journeys prove stale JWT issuance fails safely, while staged keys, restoration, and authorized rotation preserve the established credential and lifecycle contracts.**

## Performance

- **Duration:** 6 min
- **Started:** 2026-10-26T02:37:00Z
- **Completed:** 2026-10-26T02:43:08Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments

- Added authentication-complete and current-row-guard barriers to the existing independent-connection test support.
- Committed real verifier maintenance on a second PostgreSQL backend after JWT authentication and before the issuance guard. The exchange rejects the changed ciphertext identity without redeeming the authorization code or creating grants or tokens; the consumed JTI stays consumed and a fresh JTI succeeds.
- Added persisted reader-first journeys for old and new keys, preview, apply, idempotent retry, and a fresh nil-cursor local custody check. Partner secret hashes remain stable; Basic and post authentication, endpoint/session secrets, signing-key ciphertext, and public no-material clients remain intact.
- Added lost-key reporting and fail-closed JWT evidence, verified Basic and post authentication continues, restored the original key without replacing the partner secret, and exercised the existing one-time authorized rotation handoff under valid new-key configuration.
- Confirmed expiry and inactive-client decisions remain enforced through recovery. Safe reports do not contain partner plaintext or verifier ciphertext.

## Task Commits

1. **177-06-01: Race real maintenance against guarded JWT issuance** — 9181d2f7 (test).
2. **177-06-02: Exercise key introduction, local retirement check and key-loss recovery** — dcedc238 (test).

Measured task commit count: 2 from be6faa47f0916826bc65353b9e59fe3f8636918c through dcedc2389c4191ac2849a8c7fe31337a25c03a27.

## Files Created and Modified

- test/integration/client_secret_verifier_maintenance_issuance_test.exs — independent-backend maintenance race and guarded issuance side-effect proof.
- test/integration/client_secret_verifier_maintenance_recovery_test.exs — staged key rollout, rewrap, fresh check, lost-key status and both recovery paths.
- test/support/client_verifier_maintenance_concurrency.ex — reusable current-row barrier with backend PID capture.

## Verification

- Focused issuance command with the existing guarded-issuance regression — passed, 3 tests, 0 failures.
- Focused recovery command with the existing client secret rotation regression — passed, 5 tests, 0 failures.
- mix format --check-formatted on all three changed Elixir files — passed.
- git diff --check — passed.
- All runtime commands used Elixir 1.19.5 / OTP 28.5 and the plan-owned lockspire_phase177_20261026_owned database. No full-suite rerun was performed.

## TDD Gate Compliance

Both tasks add integration proof for behavior that already passed against the existing production guard and maintenance implementation. The tests were run without changing production code; no failing RED assertion was manufactured. Task commits are test-only evidence commits, consistent with the established Plan 05 precedent for behavior already present.

## Decisions Made

- The test pauses the exchange at the two observable lifecycle boundaries and runs the real maintenance service on an independent committed connection; no direct mutation stand-in is used.
- Key restoration preserves the existing partner secret, while authorized rotation deliberately returns a replacement through the established client and secret map.
- The check result is treated as local custody evidence only; it does not certify fleet key parity, deployment readiness, backups, or rollback.

## Deviations from Plan

None. The planned scope remained integration tests and concurrency support; no protocol, schema, dependency, or public API changes were introduced.

## Issues Encountered

- The first test attempt exposed an interaction fixture cleanup query using the UUID primary key instead of the string interaction identifier. Cleanup now uses the exact owned interaction IDs. Two test rows left by that failed run were removed from the plan-owned database by exact client and signing-key fixture identifiers.
- The lifecycle fixture initially combined an expired application with a later secret deadline, which Lockspire correctly classifies as invalid lifetime state. The fixture now models an expired secret with valid independent application lifetime metadata.

## Next Plan Readiness

Source-level issuance, local rotation and restoration behavior is covered for Plan 177. Fleet rollout, package-installed journeys, and final delivery/main acceptance remain outside this plan; no Phase 177 or Phase 178 completion is claimed.

---
*Phase: 177-safe-verifier-maintenance-recovery*
*Completed: 2026-10-26*

## Self-Check: PASSED

- All three plan files exist.
- Task commits 9181d2f7 and dcedc238 are ancestors of the current plan head.
- The plan ledger measures two task commits from be6faa47f0916826bc65353b9e59fe3f8636918c to dcedc2389c4191ac2849a8c7fe31337a25c03a27.
