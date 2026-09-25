---
phase: 138-baseline-inventory-evidence-taxonomy
plan: "06"
subsystem: release-maintenance
tags: [git, github, evidence-ledger, concurrency, verification]
requires:
  - phase: 138-05
    provides: Maintained-record taxonomy, bounded source-family receipts, and sanitization contracts.
provides:
  - Deterministic same-target writer lifecycle proof with interruption-safe cleanup.
  - Current canonical Git, GitHub, and maintained-record evidence ledger bound to its code/test evidence base.
affects: [phase-139, phase-140, phase-141, release-readiness]
tech-stack:
  added: []
  patterns: [target-level collector lock, same-directory atomic publish, evidence-base parent relation]
key-files:
  created: [".planning/phases/138-baseline-inventory-evidence-taxonomy/138-06-SUMMARY.md"]
  modified:
    - scripts/maintainer/baseline_inventory.sh
    - test/support/lockspire/release_proof/package_assertions.ex
    - .planning/phases/138-baseline-inventory-evidence-taxonomy/baseline-inventory-2026-08-28.md
key-decisions:
  - "Capture worktree provenance before collector-owned temporary files exist."
  - "Record an explicit evidence_base_sha and commit the refreshed ledger as its direct child."
requirements-completed: [BASE-01, BASE-02, TRIAGE-01, TRIAGE-02, LOOSE-01]
coverage:
  - id: D1
    description: Deterministic same-target contention, interruption, cleanup, retry, and independent-target collector behavior.
    requirement: BASE-02
    verification:
      - kind: integration
        ref: mix test test/lockspire/release/repository_hygiene_contract_test.exs
        status: pass
    human_judgment: false
  - id: D2
    description: Fresh canonical evidence ledger with complete receipts, bounded maintained records, authenticated GitHub queue counts, and evidence-base commit relation.
    requirement: TRIAGE-01
    verification:
      - kind: other
        ref: authenticated GraphQL/Git ledger audit
        status: pass
    human_judgment: false
duration: 19min
completed: 2026-08-28
status: complete
---

# Phase 138 Plan 06: Canonical Ledger Lifecycle Summary

**Interruption-safe collector publishing and a complete, self-reference-safe live ledger for the Phase 139–141 revalidation handoff.**

## Performance

- **Duration:** 19 min
- **Completed:** 2026-08-28T17:08:45Z
- **Tasks:** 2/2
- **Files modified:** 3

## Accomplishments

- Proved target-level collector locking, signal cleanup, retry behavior, GitHub pagination contention, and ledger-parent freshness with deterministic process-level contracts.
- Corrected provenance so collector-owned render files never appear as user working-tree changes, and added an explicit `evidence_base_sha` field.
- Refreshed the canonical dated ledger only after a definitive green aggregate gate; it contains six complete receipts, 67 Git rows, six open PR rows, zero issue rows, and nine bounded maintained records.

## Task Commits

1. **Task 1: Exercise same-target contention and interruption end to end** — `da5f227c`, `d295ccdd`, `bd3d347d`, `0a2962f9`, `dcff5263`
2. **Task 2: Regenerate and audit the canonical dated live ledger last** — `3425f1d0`

## Files Created/Modified

- `scripts/maintainer/baseline_inventory.sh` — snapshots user-visible porcelain before collector-owned artifacts and emits `evidence_base_sha`.
- `test/support/lockspire/release_proof/package_assertions.ex` — guards the provenance lifecycle boundary.
- `.planning/phases/138-baseline-inventory-evidence-taxonomy/baseline-inventory-2026-08-28.md` — current complete, proposal-only evidence snapshot.

## Decisions Made

- The live ledger’s evidence base is the corrected code/test head `dcff52639270601cfe22a05c1d88b2735990739d`; ledger commit `3425f1d0` has that SHA as its direct parent and changes only the ledger.
- Live receipts remain proposal-only and require the recorded Phase 139, 140, and 141 revalidation points before action.

## Verification

- `bash -n scripts/maintainer/baseline_inventory.sh` and `mix test test/lockspire/release/repository_hygiene_contract_test.exs` — passed, 10 tests and 0 failures.
- `mix test test/lockspire/release_readiness_contract_test.exs` — passed, 2 tests and 0 failures.
- `mix ci` — passed, including 1,379 non-integration tests and 102 integration tests with 0 failures.
- `node /Users/jon/.codex/gsd-core/bin/gsd-tools.cjs check api-coverage.verify-pre .planning/phases/138-baseline-inventory-evidence-taxonomy` — passed.
- Fresh Git and authenticated GraphQL audit — passed: all six receipts complete, 6 PRs/0 issues matched, REC taxonomy valid, no control/credential payload, and provenance contains no collector temp paths.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Provenance accuracy] Excluded collector-owned render files from the captured working-tree state.**

- **Found during:** Task 2
- **Issue:** The first live audit showed collector-created temporary files in the ledger’s porcelain receipt.
- **Fix:** Captured porcelain before lock and temporary-render creation, emitted an explicit evidence-base field, and added a regression assertion.
- **Files modified:** `scripts/maintainer/baseline_inventory.sh`, `test/support/lockspire/release_proof/package_assertions.ex`
- **Verification:** Focused lifecycle contract passed; final live ledger contains no collector temporary paths.
- **Committed in:** `0a2962f9`, `dcff5263`

**Total deviations:** 1 auto-fixed (Rule 1).

## Issues Encountered

- The first aggregate rerun caught a formatter violation in the added ExUnit assertion; `mix format` corrected it before the final green gate.

## Known Stubs

None.

## Next Phase Readiness

Phase 139–141 can cite the canonical ledger, but must follow its stated current-state, authority, recovery, and final-receipt revalidation triggers before taking action.

## Self-Check: PASSED

- Confirmed the canonical ledger and this summary exist.
- Confirmed all Task 1/Task 2 commits exist.
- Confirmed `3425f1d0` changes only the canonical ledger and has evidence-base parent `dcff5263`.
