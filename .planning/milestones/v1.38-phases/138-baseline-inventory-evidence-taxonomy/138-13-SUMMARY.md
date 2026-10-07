---
phase: 138-baseline-inventory-evidence-taxonomy
plan: "13"
subsystem: release-maintenance
tags: [git, concurrency, atomic-publication, worktree-provenance, fail-closed]
requires:
  - phase: 138-12
    provides: Complete GitHub evidence pagination and contradiction-aware disposition authority.
provides:
  - Lock-first overwrite authorization that encloses fetch, evidence capture, revalidation, and atomic rename.
  - Exact porcelain-v2 working-tree projection capture and immediate pre-rename equality proof.
  - Synchronized production-process regressions for absent-target races, worktree drift, status failures, and exact owned-path exclusions.
affects: [138-14, phase-138-verification, phase-139, phase-140, baseline-publication]
actuals:
  tokens: 4605
  tasks: 2
  commits: 5
tech-stack:
  added: []
  patterns: [lock-scoped publication authority, exact owned-path registry, fail-closed snapshot equality]
key-files:
  created:
    - .planning/phases/138-baseline-inventory-evidence-taxonomy/138-13-SUMMARY.md
    - .planning/WINDOWS.md
  modified:
    - scripts/maintainer/baseline_inventory.sh
    - test/lockspire/release/repository_hygiene_contract_test.exs
    - test/support/lockspire/release_proof/package_assertions.ex
key-decisions:
  - "A collector acquires the per-target directory lock before checking target existence, replacement authority, fetching metadata, or observing snapshot state."
  - "Working-tree provenance is one normalized porcelain-v2 projection whose only exclusions are exact registered collector-owned paths."
patterns-established:
  - "Publication transaction: resolve parent, acquire target lock, authorize current target state, fetch, capture, collect, recheck, rename, and release."
  - "Worktree equality: require successful identical capture/recheck commands and preserve every non-owned status record byte-for-byte after deterministic ordering."
requirements-completed: [BASE-01, BASE-02]
coverage:
  - id: D1
    description: Two absent-target collectors cannot both publish, and the loser rechecks current target state under lock before any fetch or collection.
    requirement: BASE-02
    verification:
      - kind: integration
        ref: test/lockspire/release/repository_hygiene_contract_test.exs#baseline inventory collector publishes under one lock-stable working-tree snapshot
        status: pass
    human_judgment: false
  - id: D2
    description: Published ledgers require readable, byte-equivalent normalized working-tree projections at capture and immediately before rename.
    requirement: BASE-01
    verification:
      - kind: integration
        ref: test/lockspire/release/repository_hygiene_contract_test.exs#baseline inventory collector publishes under one lock-stable working-tree snapshot
        status: pass
      - kind: integration
        ref: mix test test/lockspire/release_readiness_contract_test.exs
        status: pass
    human_judgment: false
duration: 12min
completed: 2026-08-28
status: complete
---

# Phase 138 Plan 13: Lock-Stable Publication Summary

**Canonical inventory publication now authorizes and executes under one target lock while proving the working tree stayed readable and exactly unchanged through rename.**

## Performance

- **Duration:** 12 min
- **Started:** 2026-08-28T23:13:54Z
- **Completed:** 2026-08-28T23:25:37Z
- **Tasks:** 2/2
- **Files modified:** 3

## Accomplishments

- Moved target existence and `--replace` authorization behind per-target lock acquisition, then retained ownership across fetch, snapshot capture, source collection, final revalidation, atomic rename, and cleanup.
- Added exact normalized `git status --porcelain=v2 --branch` capture and immediate pre-rename recheck with explicit unavailable-evidence failures.
- Added synchronized production-process proof for two absent-target writers, per-writer command counters, tracked modification/deletion, untracked addition, capture/recheck failures, exact owned paths, near-name visibility, prior-byte preservation, cleanup, and stable retry.

## Task Commits

Each task was committed through its RED and GREEN gates:

1. **Task 1 RED: Lock-first publication race contract** — `4b41359a` (test)
2. **Task 1 GREEN: Lock-scoped publication authority** — `39e7fde3` (feat)
3. **Task 2 RED: Unstable worktree publication contract** — `e24d3aea` (test)
4. **Task 2 GREEN: Exact worktree capture and recheck** — `1ff5c4a1` (feat)

## Files Created/Modified

- `scripts/maintainer/baseline_inventory.sh` — lock-first publication transaction, ownership-aware cleanup, exact owned-path registry, and fail-closed worktree projection equality.
- `test/support/lockspire/release_proof/package_assertions.ex` — synchronized double-writer barrier, command counters, stateful worktree/status fixtures, cleanup, and retry assertions.
- `test/lockspire/release/repository_hygiene_contract_test.exs` — focused lock-stable production-process contract entry point.
- `.planning/WINDOWS.md` — fixed deviation ledger entry for the transient test-fixture correction.
- `.planning/phases/138-baseline-inventory-evidence-taxonomy/138-13-SUMMARY.md` — canonical execution evidence for this plan.

## Decisions Made

- Lock contention is resolved before any overwrite authority or evidence work. A waiter that later owns the lock must inspect the current target and cannot reuse an absent-target observation from before the lock.
- Worktree evidence uses one helper for both capture and recheck. Successful output is deterministically ordered, and only the exact output, lock, render, and buffer paths registered by the current collector are filtered.
- A nonzero status command is unavailable evidence, not an empty worktree. Capture and recheck failures therefore abort publication with bounded source-specific diagnostics.

## Verification

- `bash -n scripts/maintainer/baseline_inventory.sh` — passed.
- `mix format --check-formatted test/lockspire/release/repository_hygiene_contract_test.exs test/support/lockspire/release_proof/package_assertions.ex` — passed.
- `mix test test/lockspire/release/repository_hygiene_contract_test.exs` — passed, 21 tests and 0 failures.
- `mix test test/lockspire/release_readiness_contract_test.exs` — passed, 2 tests and 0 failures.
- Source mutation scan found only the permitted `git fetch --prune --tags "$REMOTE"`; output writes remain scoped to the requested target, lock, registered temporary files, and atomic rename.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Kept the owned-path fake Git status command successful under `set -e`**

- **Found during:** Task 2 GREEN verification
- **Issue:** An unmatched final owned-path glob left the fake `git status` case with status 1, falsely exercising the unavailable-status branch instead of worktree drift.
- **Fix:** Added an explicit successful no-op after the exact-path enumeration so fixture exit status reflects only the requested scenario.
- **Files modified:** `test/support/lockspire/release_proof/package_assertions.ex`
- **Verification:** The focused lock-stable test passed all modification, deletion, untracked, status-failure, owned-path, near-name, cleanup, and retry cases; the full 21-test contract remained green.
- **Committed in:** `1ff5c4a1`

---

**Total deviations:** 1 auto-fixed (1 Rule 1 bug). **Impact on plan:** The correction repaired only the new adversarial fixture and did not alter production scope or weaken an assertion.

## Issues Encountered

- The production-process suite is intentionally synchronization-heavy; the final repository-hygiene run completed in 112.0 seconds with zero failures.

## Known Stubs

None. `TODO`/`FIXME` occurrences in changed files are maintained-record selectors and adversarial fixture literals, not unfinished behavior. No skipped tests or unrun verification steps remain.

## Security and Boundary Notes

- T-138-51 is closed by lock-first current-state authorization plus a two-process absent-target race that proves only the winner reaches fetch and collection.
- T-138-52 and T-138-53 are closed by identical successful porcelain-v2 capture/recheck commands and explicit nonzero-command aborts.
- T-138-54 is closed by exact registered-path filtering and a similarly named unowned path that remains visible and aborts equality.
- No runtime endpoint, authentication path, schema, package dependency, public API, Mix task, Git mutation beyond D-09 fetch, or disposition action was introduced.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Verification gaps 3 and 4 now have deterministic process-level regression coverage through the production collector.
- Plan 138-14 can continue gap closure with publication authority and local working-tree provenance now fail-closed.

## Self-Check: PASSED

- Confirmed the three implementation/test files, fixed broken-windows ledger, and this summary exist.
- Confirmed commits `4b41359a`, `39e7fde3`, `e24d3aea`, and `1ff5c4a1` exist in RED/GREEN order with no tracked-file deletions.
- Re-ran shell syntax, formatting, the 21-test repository-hygiene contract, and the 2-test release-readiness contract successfully.
- Confirmed no goal-blocking stubs, skipped tests, unrun verification commands, unexpected Git mutations, or unmodeled threat surfaces remain.

---
*Phase: 138-baseline-inventory-evidence-taxonomy*
*Completed: 2026-08-28*
