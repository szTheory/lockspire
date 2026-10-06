---
phase: 140-bounded-operational-loose-end-triage
plan: "12"
subsystem: release-proof
tags: [release-contracts, git-lineage, fixtures]
requires: [140-10]
provides:
  - Precise legacy planning-file read detection in release proof contracts
  - Phase 139 synthetic acceptance history based on its actual historical source blobs
affects: [140-08, CI-06, LOOSE-03]
actuals:
  tasks: 2
  commits: 3
tech-stack:
  added: []
  patterns: [synthetic history fixtures read source files from the exact historical lineage commit]
key-files:
  created: [.planning/phases/140-bounded-operational-loose-end-triage/140-12-PLAN.md]
  modified:
    - test/lockspire/release_readiness_contract_test.exs
    - test/support/lockspire/release_proof/package_assertions.ex
key-decisions:
  - "Match direct File.read calls to .planning paths instead of rejecting every planning-path string in contract source."
  - "Construct historical Phase 139 fixture commits from the lineage-base blobs so present-day edits cannot rewrite their modeled past."
requirements-completed: [LOOSE-03]
coverage:
  - id: D1
    description: Release-readiness rejects direct planning-file reads while allowing literal planning-path contract assertions.
    verification:
      - kind: unit
        ref: "mix test test/lockspire/release_readiness_contract_test.exs:10"
        status: pass
    human_judgment: false
  - id: D2
    description: Phase 138/139 receipt and lineage selectors pass using exact historical source blobs.
    verification:
      - kind: integration
        ref: "mix test test/lockspire/release/repository_hygiene_contract_test.exs:343 test/lockspire/release/repository_hygiene_contract_test.exs:362 test/lockspire/release/repository_hygiene_contract_test.exs:404"
        status: pass
    human_judgment: false
duration: 13min
completed: 2026-10-01
status: complete
---

# Phase 140 Plan 12: Release Proof Fixture Summary

**Release contract scans now distinguish real planning-file reads from literal path assertions, and Phase 139 fixture history is reconstructed from its actual source lineage.**

## Performance

- **Duration:** 13 min
- **Started:** 2026-10-01T02:04:00Z
- **Completed:** 2026-10-01T02:17:00Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- Narrowed the legacy-pattern test to reject direct `File.read` access to `.planning/` paths while retaining its negative test.
- Rebuilt synthetic Phase 139 acceptance commits from the lineage-base blobs instead of current source files, keeping later Phase 140 edits out of historical snapshots.
- Verified the three exact receipt and merged-lineage selectors.

## Task Commits

1. **Task 1: Align release-readiness pattern scanning with proof contracts** - `02a3ecc8` (fix)
2. **Task 2: Refresh Phase 138 and 139 synthetic release receipts** - `550d5ad4` (fix)

**Plan metadata:** `e7823657` (docs: plan release proof contract repairs)

## Files Created/Modified

- `140-12-PLAN.md` - Exact release proof failure scope and selectors.
- `test/lockspire/release_readiness_contract_test.exs` - Checks actual planning-file reads rather than all path literals.
- `test/support/lockspire/release_proof/package_assertions.ex` - Seeds Phase 139 modeled commits from historical lineage blobs.

## Decisions Made

- Kept the direct-file-access guard and its negative input instead of permitting `.planning/` broadly.
- Used the fixture's exact Phase 139 lineage base for the historical commits.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Keep restrictive log permissions from changing fixture file modes**
- **Found during:** Task 2
- **Issue:** An initial focused run inherited `umask 077`; the release receipt tests correctly rejected synthetic files created with mode `0600` instead of the expected tracked-file mode.
- **Fix:** Captured subsequent logs with `mktemp`'s private file mode without changing the test process umask.
- **Files modified:** None.
- **Verification:** The three selectors passed with the standard process umask.
- **Committed in:** No file commit required.

**Total deviations:** 1 auto-fixed (Rule 3)
**Impact on plan:** Corrected the verification environment; receipt mode checks stayed unchanged.

## Issues Encountered

The Phase 139 sealed-candidate selector also showed that the fixture was rebuilding historical acceptance commits from current files, which had changed during Phase 140. Reading those files from the exact lineage-base commit restored the expected historical classes without weakening the lineage classifier.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 140-08 can resume its census reconciliation. Remaining reported CI failures are concentrated in protocol token signing and require their own exact-scope plan.

## Self-Check: PASSED

- The plan artifact exists and commits `e7823657`, `02a3ecc8`, and `550d5ad4` are present.
- The release-readiness selector passed; all three release receipt selectors passed.
- `package_assertions.ex` passes its formatter check and `git diff --check`.

---
*Phase: 140-bounded-operational-loose-end-triage*
*Completed: 2026-10-01*
