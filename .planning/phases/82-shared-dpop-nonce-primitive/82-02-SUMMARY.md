---
phase: 82-shared-dpop-nonce-primitive
plan: 02
subsystem: testing
tags: [dpop, nonce, exunit, protocol-tests]
requires:
  - phase: 82
    provides: Shared nonce primitive and typed validator outcomes
provides:
  - Dedicated primitive proof for nonce issuance, purpose separation, and expiry
  - Shared validator proof for missing and wrong-purpose nonce failures
  - Adapter proof that both DPoP consumers preserve `use_dpop_nonce` behavior
affects: [phase-83-dpop-endpoint-adoption, phase-84-host-plug-pipeline]
tech-stack:
  added: []
  patterns: [protocol-level-nonce-proof, wrong-purpose-regression-tests]
key-files:
  created: [test/lockspire/protocol/dpop_nonce_test.exs]
  modified: [test/lockspire/protocol/dpop_test.exs, test/lockspire/protocol/token_endpoint_dpop_test.exs, test/lockspire/protocol/protected_resource_dpop_test.exs]
key-decisions:
  - "Nonce proof stays at the protocol layer; controller and plug retry behavior remains for later phases."
  - "Wrong-purpose nonce use is tested directly on both owned surfaces instead of being inferred indirectly."
patterns-established:
  - "Dedicated primitive tests cover issue, validate, expiry, and purpose mismatch cases."
  - "Token and protected-resource suites assert `use_dpop_nonce` for both missing and invalid nonce reasons."
requirements-completed: [NONCE-CORE-01, NONCE-CORE-02, NONCE-CORE-03, NONCE-CORE-04]
duration: 2 min
completed: 2026-05-23
---

# Phase 82: Shared DPoP Nonce Primitive Summary

**Phase 82 now has direct protocol proof that nonce values are purpose-separated, age-bounded, and surfaced through stable typed failures on both Lockspire-owned DPoP consumers.**

## Performance

- **Duration:** 2 min
- **Started:** 2026-05-23T20:48:00Z
- **Completed:** 2026-05-23T20:50:03Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments
- Added a dedicated `DPoPNonce` test module covering issuance, missing nonce, malformed nonce, expiry, and cross-purpose rejection.
- Expanded the shared validator suite to prove wrong-purpose nonces return `:invalid_dpop_nonce`.
- Expanded token-endpoint and protected-resource suites so both surfaces prove `use_dpop_nonce` behavior for missing and invalid nonce paths.

## Task Commits

Each task was intended to be committed atomically, but this run preserved the existing dirty working tree instead of creating mixed-ownership commits.

1. **Task 1: Add dedicated unit proof for nonce issuance, purpose separation, and bounded validity** - `N/A` (verified in working tree)
2. **Task 2: Lock typed nonce failures into the shared validator and both DPoP protocol consumers** - `N/A` (verified in working tree)

**Plan metadata:** `N/A` (summary written without a metadata commit because the repository already contained uncommitted phase edits)

## Files Created/Modified
- `test/lockspire/protocol/dpop_nonce_test.exs` - Direct primitive proof for issue/validate semantics and purpose separation
- `test/lockspire/protocol/dpop_test.exs` - Shared validator assertions for missing and wrong-purpose nonce failures
- `test/lockspire/protocol/token_endpoint_dpop_test.exs` - Token-surface proof for `use_dpop_nonce` on missing and invalid nonce inputs
- `test/lockspire/protocol/protected_resource_dpop_test.exs` - Resource-surface proof for `use_dpop_nonce` on missing and invalid nonce inputs

## Decisions Made
- Added explicit wrong-purpose coverage instead of treating malformed nonce strings as sufficient proof of invalid behavior.
- Kept all Phase 82 proof below the controller and plug layers so later nonce challenge/retry phases stay isolated.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Skipped task commits to avoid mixing new test proof with existing uncommitted phase work**
- **Found during:** Task 1 and Task 2
- **Issue:** The repository already had in-progress DPoP nonce source edits and adjacent test modifications, so task commits would not have represented isolated plan execution.
- **Fix:** Added only the missing proof coverage, reran the phase validation commands, and documented the clean-room limitation in the summary.
- **Files modified:** `test/lockspire/protocol/dpop_nonce_test.exs`, `test/lockspire/protocol/dpop_test.exs`, `test/lockspire/protocol/token_endpoint_dpop_test.exs`, `test/lockspire/protocol/protected_resource_dpop_test.exs`
- **Verification:** `mix test test/lockspire/protocol/dpop_nonce_test.exs test/lockspire/protocol/dpop_test.exs` and `mix test test/lockspire/protocol/token_endpoint_dpop_test.exs test/lockspire/protocol/protected_resource_dpop_test.exs`
- **Committed in:** `N/A`

---

**Total deviations:** 1 auto-fixed (1 blocking/workflow safety)
**Impact on plan:** Functional proof is complete, but clean task-by-task git history for Phase 82 remains deferred until the dirty tree is resolved.

## Issues Encountered
None

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Token and userinfo nonce challenge/retry work can build on stable typed nonce outcomes without reopening the primitive contract.
- Dirty-tree cleanup remains the only blocker to producing the expected per-task commit history.

## Self-Check: PASSED

---
*Phase: 82-shared-dpop-nonce-primitive*
*Completed: 2026-05-23*
