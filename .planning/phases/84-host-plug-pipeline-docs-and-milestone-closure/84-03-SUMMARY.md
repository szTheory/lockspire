---
phase: 84-host-plug-pipeline-docs-and-milestone-closure
plan: 03
subsystem: testing
tags: [integration, dpop, phoenix, e2e]
requires:
  - phase: 84-host-plug-pipeline-docs-and-milestone-closure
    provides: nonce-aware host plug challenge transport and docs truth
provides:
  - generated-host protected-route nonce challenge and retry proof
  - exact expose-header assertion on the host-route retry path
affects: [integration, host-routes, milestone-closeout]
tech-stack:
  added: []
  patterns:
    - generated-host Phoenix route tests close milestone claims about the shipped host seam
key-files:
  created: []
  modified:
    - test/integration/phase81_generated_host_route_protection_e2e_test.exs
key-decisions:
  - "Kept the E2E proof narrow: one nonce challenge and successful retry path on the canonical protected route pipeline."
patterns-established:
  - "Milestone-closing host-route claims are backed by generated-host router proof rather than plug-only tests."
requirements-completed: [NONCE-RS-02, NONCE-TRUTH-03]
duration: 8m
completed: 2026-05-24
---

# Phase 84 Plan 03: Generated-Host Proof Summary

**The generated-host billing route now proves nonce-less DPoP requests receive the documented `401` retry challenge and succeed after replaying with the issued nonce on the canonical Lockspire plug pipeline.**

## Performance

- **Duration:** 8m
- **Started:** 2026-05-24T15:25:00Z
- **Completed:** 2026-05-24T15:33:00Z
- **Tasks:** 1
- **Files modified:** 1

## Accomplishments

- Strengthened the generated-host DPoP E2E to assert `error="use_dpop_nonce"` and `DPoP-Nonce` on the first nonce-less proof.
- Added exact `Access-Control-Expose-Headers: DPoP-Nonce, WWW-Authenticate` coverage on the host-route retry challenge.
- Verified the same route returns `200` when a fresh proof echoes the issued nonce.

## Task Commits

This run executed in a dirty working tree and did not create phase-specific commits.

## Files Created/Modified

- `test/integration/phase81_generated_host_route_protection_e2e_test.exs` - generated-host nonce challenge and retry proof on the canonical plug pipeline

## Decisions Made

- Reused the existing generated-host billing route instead of adding broader negative-path duplication at the E2E layer.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Phase 84 is complete and ready for milestone verification/closeout.

## Self-Check: PASSED

- `MIX_ENV=test mix test test/lockspire/web/token_controller_test.exs test/lockspire/web/userinfo_controller_test.exs test/integration/phase81_generated_host_route_protection_e2e_test.exs`

