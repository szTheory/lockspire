---
phase: 139-required-truth-reconciliation
plan: "16"
subsystem: testing
tags: [exunit, git-fixtures, phase-history]

# Dependency graph
requires:
  - phase: 139-required-truth-reconciliation
    provides: Exact-SHA acceptance, release-train, and planning contracts
provides:
  - Phase 140 closure tests use the committed pre-terminal planning records
  - Phase 139 relation tests rebuild the original 13-plan completion history
affects: [phase-139-local-ci, release-proof-fixtures]

# Actuals
actuals:
  tokens: 2655
  tasks: 2
  commits: 5

# Tech tracking
tech-stack:
  added: []
  patterns:
    - Historical fixtures read exact regular blobs from their pinned Git boundary

key-files:
  created: []
  modified:
    - test/lockspire/release/phase140_read_only_closure_contract_test.exs
    - test/support/lockspire/release_proof/package_assertions.ex

key-decisions:
  - "Build historical test repositories from the exact committed records for the time boundary under test."
  - "Keep the Phase 139 merged-release fixture on its historical release-train wording; the maintained current record remains unchanged."

patterns-established:
  - "Temporary Git histories use sorted tracked regular blobs and exact git-show contents."

requirements-completed: [QUAL-05, HYGIENE-06, TRUTH-03]
coverage:
  - id: D1
    description: Phase 140 closure fixture models pending CI-06/CI-07 records and rejects a forged completion.
    requirement: QUAL-05
    verification:
      - kind: unit
        ref: test/lockspire/release/phase140_read_only_closure_contract_test.exs#phase140_closure_tracer
        status: pass
    human_judgment: false
  - id: D2
    description: Phase 139 inventory fixture contains only its original 13 plan and summary pairs and retains hostile-case rejection.
    requirement: HYGIENE-06
    verification:
      - kind: unit
        ref: test/lockspire/release/repository_hygiene_contract_test.exs#phase139_inventory_relation
        status: pass
    human_judgment: false

# Metrics
duration: 39min
completed: 2026-10-05
status: complete
---

# Phase 139 Plan 16: Historical fixture boundaries restored

**Historical Phase 140 and Phase 139 Git fixtures now use the planning records committed at their original boundaries.**

## Performance

- **Duration:** 39 min
- **Started:** 2026-10-06T01:28:17Z
- **Completed:** 2026-10-06T02:07:38Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- The Phase 140 closure fixture now reads its five conditional planning records from the accepted pre-terminal commit and checks their pending/open/verifying state before invoking the verifier.
- The Phase 139 completion fixture now rebuilds its phase directory from regular tracked blobs at the parent of the fixed 13-plan completion commit. It checks exact plan and summary identities and preserves hostile extra-plan rejection.
- The focused historical relation suites pass without changing maintained planning records, the production verifier, or the production relation classifier.

## Task Commits

1. **Task 1: Prove the Phase 140 private result against its committed pre-terminal records**
   - `14be4f4d` — test Phase 140 fixture boundary records
   - `13d5cf26` — pin Phase 140 historical fixture records
   - `1b974ba1` — isolate fixture directories across test runs
2. **Task 2: Keep Phase 139 completion fixtures pinned to their original 13-plan tree**
   - `0f447fdd` — pin Phase 139 fixture plan identities
   - `d1845e0c` — rebuild Phase 139 history fixtures

## Files Created/Modified

- `test/lockspire/release/phase140_read_only_closure_contract_test.exs` — pins the five historical planning inputs, checks their state, and uses a fixture name that remains unique across test VM restarts.
- `test/support/lockspire/release_proof/package_assertions.ex` — rebuilds the fixed 13-plan tree from Git and supplies the merged-release test with its historical release-train document.

## Decisions Made

- Historical tests use records from the exact commit they model. The separate current release-train test remains aligned with the actual public package version.
- Temporary fixture names combine the OS process ID and VM-local counter so stale directories from an earlier run cannot collide.

## Deviations from Plan

### Auto-fixed Issues

**1. Make the temporary Phase 140 fixture unique across separate test runs**
- **Found during:** Task 1
- **Issue:** `System.unique_integer/1` resets when a new test VM starts, so an abandoned temporary repository from an earlier run could reuse the same path.
- **Fix:** Include the OS process ID in the temporary directory name.
- **Files modified:** `test/lockspire/release/phase140_read_only_closure_contract_test.exs`
- **Verification:** The focused Phase 140 closure selector passed after removing the two stale test-owned directories.
- **Committed in:** `1b974ba1`

**2. Keep the merged-release fixture at its historical record boundary**
- **Found during:** Task 2
- **Issue:** The test mixed the current release-train document with the historical Phase 139 classifier, which treated `1.5.1` as the released-version marker.
- **Fix:** Source the fixture's release-train, manifest, changelog, and Mix version from its pinned lineage commit. Current maintained release truth remains untouched.
- **Files modified:** `test/support/lockspire/release_proof/package_assertions.ex`
- **Verification:** All three `phase139_inventory_relation` tests passed.
- **Committed in:** `d1845e0c`

**Total deviations:** 2 auto-fixed
**Impact on plan:** Both corrections keep the private fixtures isolated and historically coherent; no production behavior or maintained current record changed.

## Issues Encountered

- The Phase 140 focused suite initially encountered two leftover temporary test directories from earlier failed runs. Those test-owned directories were removed, and the fixture naming was hardened against recurrence.

## User Setup Required

None.

## Next Phase Readiness

Plan 139-16 is complete. Plan 139-15 remains; its task commits already exist without a summary. Its focused checks and full local `mix ci` gate must pass before closing it out and refreshing the Phase 139 verification. No manual UAT is needed for these fixture properties.

---
*Phase: 139-required-truth-reconciliation*
*Completed: 2026-10-05*
