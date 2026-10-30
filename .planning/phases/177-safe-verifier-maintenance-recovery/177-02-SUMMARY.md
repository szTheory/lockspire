---
phase: 177-safe-verifier-maintenance-recovery
plan: "02"
subsystem: auth-storage
tags: [elixir, ecto, postgresql, verifier-custody, tdd]

requires:
  - phase: 177-safe-verifier-maintenance-recovery
    provides: Selected-store authority and native verifier-only maintenance from Plan 01.
provides:
  - Authenticated custody inspection for native, migrated, old-key, current-key, and qualified legacy verifier material.
  - Dedicated rewrap that preserves migrated age kind and exact timestamps after expiry without restoring authentication eligibility.
  - Qualified finite-age legacy promotion with original deadlines and hash agreement.
affects: [177-03, 177-05, 177-07]

actuals:
  tokens: 10255
  tasks: 2
  commits: 4
commits: 4
plan_head_before: 886aba97a50d481e72e0c78e9edf51417a981b68
plan_head_after: 51d0cfaca4fd1247e92557343c93b0f19f86b08e

tech-stack:
  added: []
  patterns: [shared authenticated envelope decoder, custody inspection separate from authentication expiry, qualified legacy promotion]

key-files:
  created:
    - test/lockspire/security/client_secret_verifier_maintenance_test.exs
    - test/support/delegated_verifier_maintenance_store.ex
  modified:
    - lib/lockspire/security/client_secret_verifier.ex
    - lib/lockspire/storage/client_verifier_maintenance.ex
    - test/integration/client_secret_verifier_maintenance_test.exs
    - test/lockspire/storage/client_verifier_maintenance_test.exs

key-decisions:
  - "Use one internal authenticated decoder for format, AAD, bounds, and hash checks; apply migrated expiry only on the authentication path."
  - "Promote legacy material only through Legacy.authenticated_metadata/3, preserving the qualified signed timestamp and finite deadline."

patterns-established:
  - "Custody status carries safe authenticated age metadata while never returning verifier plaintext or ciphertext."
  - "Maintenance test adapters used by isolated integration targets belong in test/support rather than another test module."

requirements-completed: [VUP-03, VOPS-02, VOPS-03]
coverage:
  - id: D1
    description: "Dedicated migrated custody rewrap preserves authenticated timestamps after expiry and authentication continues to reject the expired verifier."
    requirement: VUP-03
    verification:
      - kind: unit
        ref: "test/lockspire/security/client_secret_verifier_maintenance_test.exs#authenticated migrated custody inspection retains age metadata after expiry"
        status: pass
      - kind: integration
        ref: "test/integration/client_secret_verifier_maintenance_test.exs#persisted expired migrated verifier rewrap preserves authentication expiry"
        status: pass
    human_judgment: false
  - id: D2
    description: "Only qualified finite-age legacy material with a matching hash is promoted; rejected inputs remain unchanged."
    requirement: VOPS-02
    verification:
      - kind: unit
        ref: "test/lockspire/security/client_secret_verifier_maintenance_test.exs#qualified tuple-three tuple-two and map legacy metadata keep their original deadline"
        status: pass
      - kind: integration
        ref: "test/integration/client_secret_verifier_maintenance_test.exs#qualified legacy verifier promotion preserves age and independent client deadlines"
        status: pass
    human_judgment: false
  - id: D3
    description: "Current-key material is a no-op, while tampered, malformed, unknown-key, future, oversized, or hash-divergent material cannot establish custody."
    requirement: VOPS-03
    verification:
      - kind: unit
        ref: "test/lockspire/security/client_secret_verifier_maintenance_test.exs"
        status: pass
      - kind: integration
        ref: "test/integration/client_secret_verifier_maintenance_test.exs#current key custody is a no-op and creates no maintenance audit"
        status: pass
    human_judgment: false

duration: 9min
completed: 2026-10-26
status: complete
---

# Phase 177 Plan 02: Authenticated Verifier Custody Summary

**Verifier custody rewrap now preserves authenticated age metadata and promotes only qualified legacy material without extending credential eligibility.**

## Performance

- **Duration:** 9 min
- **Started:** 2026-10-26T01:10:50Z
- **Completed:** 2026-10-26T01:19:30Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments

- Factored dedicated envelope authentication so custody inspection and authentication share AEAD, AAD, identity, key, canonical encoding, and structural validation.
- Rewrapped expired but structurally valid migrated material with a fresh IV while preserving its discriminator, `signed_at_ms`, and `deadline_ms`; `open/4` continues to reject it strictly after its deadline.
- Promoted tuple-three, tuple-two, and map legacy metadata only after finite-age qualification and secret-hash agreement; retained independent client and secret expiry fields.
- Added adversarial custody checks, current-key no-op/audit coverage, and a persisted legacy promotion path.

## Task Commits

1. **Task 1: Preserve authenticated dedicated age through custody rewrap** — `8816add6` (RED tests), `5f223b70` (GREEN implementation).
2. **Task 2: Promote only qualified legacy material** — `7e31f6d5` (RED tests), `51d0cfac` (GREEN implementation).

Measured plan commit count: 4, from `plan_head_before` to `plan_head_after` above.

## Files Created/Modified

- `lib/lockspire/security/client_secret_verifier.ex` — Shared authenticated custody parsing, safe classification, metadata-preserving dedicated rewrap, and qualified legacy promotion.
- `lib/lockspire/storage/client_verifier_maintenance.ex` — Routes the persisted operation through the internal rewrap preparation.
- `test/lockspire/security/client_secret_verifier_maintenance_test.exs` — Current/old-key, expiry, metadata, corruption, and legacy qualification tests.
- `test/integration/client_secret_verifier_maintenance_test.exs` — Persisted expired rewrap, current no-op, and qualified/rejected legacy scenarios.
- `test/lockspire/storage/client_verifier_maintenance_test.exs` — Removes the adapter fixture definition now shared from test support.
- `test/support/delegated_verifier_maintenance_store.ex` — Test-only selected-store adapter available to independently selected test targets.

## TDD Evidence

| Task | RED evidence | GREEN evidence |
|---|---|---|
| 177-02-01 | `mix test --include integration test/lockspire/security/client_secret_verifier_maintenance_test.exs test/integration/client_secret_verifier_maintenance_test.exs --trace` exited 2. The isolated persisted test failed because expired migrated custody returned `:client_secret_verifier_maintenance_failed` instead of `:changed`. | Focused custody, age, and maintenance tests passed: 21 tests, 0 failures. The persisted expired verifier rewrapped and remained rejected after its deadline. |
| 177-02-02 | `mix test test/lockspire/security/client_secret_verifier_maintenance_test.exs --trace` exited 2 on the qualified tuple-three promotion assertion; the isolated persisted eligible-legacy test also exited 2 because the operation returned `:client_secret_verifier_maintenance_failed`. | Legacy maintenance, legacy caller, custody age, and selected-store suites passed: 36 tests, 0 failures. Exact legacy timestamps/deadlines and independent client deadlines were preserved. |

The RED targets executed and failed on the intended behavior assertions. The final post-commit focused run passed with 36 tests and 0 failures; `mix format --check-formatted` and `git diff --check` also passed.

## Decisions Made

- Kept dedicated custody decoding internal and shared with authentication, separating authentication eligibility from custody rewrapping.
- Reused the existing finite-age `Legacy.authenticated_metadata/3` qualification rather than introducing another legacy decoder or changing the legacy caller contract.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Moved the selected maintenance test adapter into shared test support**
- **Found during:** Task 1 (Persisted expired verifier rewrap)
- **Issue:** The plan's isolated integration command did not load a delegated PostgreSQL adapter defined inside a separate storage test file, so that integration case reported maintenance as unsupported.
- **Fix:** Moved the test-only adapter module to `test/support/delegated_verifier_maintenance_store.ex`, where independently selected tests can load it.
- **Files modified:** `test/support/delegated_verifier_maintenance_store.ex`, `test/lockspire/storage/client_verifier_maintenance_test.exs`
- **Verification:** Ran the plan's focused maintenance command with the storage contract suite; 36 tests passed with 0 failures.
- **Committed in:** `5f223b70` (Task 1 GREEN commit)

**Total deviations:** 1 auto-fixed (Rule 3)
**Impact on plan:** Required test support relocation only; production scope and public contracts are unchanged.

## Issues Encountered

- An initial mixed-target run exposed the test adapter loading dependency described above. The isolated RED was rerun and recorded against the migrated verifier assertion after the test fixture was made independently loadable.
- No package installation, schema change, or external service setup was required.

## User Setup Required

None - no external service configuration was required.

## Next Phase Readiness

Plan 03 can build status classification on authenticated safe custody metadata and distinguish expired migrated custody from authentication eligibility. This summary completes Plan 02 only; no Phase 177 or Phase 178 completion is claimed.

## Self-Check: PASSED

- Created and modified implementation/test files listed above exist.
- All four task commits are ancestors of the measured plan head.
- The plan ledger records four commits from `886aba97a50d481e72e0c78e9edf51417a981b68` through `51d0cfaca4fd1247e92557343c93b0f19f86b08e`.

---
*Phase: 177-safe-verifier-maintenance-recovery*
*Completed: 2026-10-26*
