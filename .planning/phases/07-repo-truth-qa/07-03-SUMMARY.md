---
phase: 07-repo-truth-qa
plan: 03
subsystem: testing
tags: [integration, exunit, qa, phase3, release-gates]
requires:
  - phase: 07-02
    provides: truthful green `mix qa` lane and maintained analyzer posture
provides:
  - deterministic green maintained integration and phase3 test lanes
  - a pruned `mix test.phase3` alias centered on the true non-tagged contract files
affects: [release-hardening, testing, contributor-gates, phase3]
tech-stack:
  added: []
  patterns:
    - maintain one canonical Phase 3 e2e proof
    - keep lower-layer ownership tests out of duplicate integration buckets
key-files:
  created: []
  modified:
    - lib/lockspire/storage/ecto/repository.ex
    - mix.exs
key-decisions:
  - "Fixed the transaction wrapper regression first because lane topology changes are meaningless while the maintained tests are failing for infrastructure reasons."
  - "Reduced `mix test.phase3` to the Phase 3 e2e file plus discovery, authorization-request, and userinfo contract tests."
patterns-established:
  - "Release-critical lane work should fix deterministic execution bugs before changing alias membership."
  - "Phase-specific aliases should own only the unique contract files that are not already covered by the broader integration lane."
requirements-completed: [GATE-03]
duration: 3 min
completed: 2026-04-23
---

# Phase 07 Plan 03: Maintained Test Lane Summary

**The maintained integration and Phase 3 lanes are green again, with `test.phase3` trimmed down to one canonical e2e proof plus the three unique Phase 3 contract files**

## Performance

- **Duration:** 3 min
- **Started:** 2026-04-23T20:48:30Z
- **Completed:** 2026-04-23T20:51:32Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments
- Restored deterministic test execution by flattening transaction wrapper results that had been breaking refresh and interaction flows across the maintained lanes.
- Pruned `mix test.phase3` so it no longer reruns a large duplicate set of integration-tagged tests already owned by `mix test.integration`.
- Closed `GATE-03` with green `MIX_ENV=test mix test.integration` and `MIX_ENV=test mix test.phase3`.

## Task Commits

Each task was committed atomically:

1. **Task 1: Make the maintained integration stories deterministic without changing their release-critical scope** - `2f940e6` (fix)
2. **Task 2: Reshape `mix test.phase3` around the true non-tagged contract files per D-05 and D-08** - `10c3308` (test)

**Plan metadata:** `pending`

## Files Created/Modified
- `lib/lockspire/storage/ecto/repository.ex` - flattened nested `{:ok, ...}` transaction results so refresh rotation and interaction transitions return the expected shapes to tests and controllers
- `mix.exs` - reduced `test.phase3` to the canonical Phase 3 e2e file plus `authorization_request`, `discovery`, and `userinfo` contract tests

## Decisions Made
- Treated the broken transaction wrapper as a blocking bug to fix before any lane-topology edits, because it was the actual reason the maintained stories were red.
- Left the canonical Phase 3 and onboarding e2e files intact while shrinking only the duplicate alias membership.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Repaired repository transaction flattening before lane pruning**
- **Found during:** Task 1 (Make the maintained integration stories deterministic without changing their release-critical scope)
- **Issue:** `Repository.transact/1` was preserving nested `{:ok, ...}` tuples, breaking refresh, introspection, token-controller, and interaction-path tests across both maintained lanes.
- **Fix:** Flattened successful inner transaction tuples before they leave the repository wrapper.
- **Files modified:** `lib/lockspire/storage/ecto/repository.ex`
- **Verification:** `MIX_ENV=test mix test.integration`, `MIX_ENV=test mix test.phase3`
- **Committed in:** `2f940e6`

---

**Total deviations:** 1 auto-fixed (1 bug)
**Impact on plan:** Required to restore truthful lane verification before the planned alias cleanup. No scope creep beyond the maintained release-critical test path.

## Issues Encountered

None

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Ready for `07-04`, with both maintained test lanes green and Phase 3 ownership now sharply defined.

## Self-Check: PASSED

---
*Phase: 07-repo-truth-qa*
*Completed: 2026-04-23*
