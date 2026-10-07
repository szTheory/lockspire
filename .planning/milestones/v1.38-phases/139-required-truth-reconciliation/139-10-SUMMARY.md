---
phase: 139-required-truth-reconciliation
plan: "10"
subsystem: testing
tags: [acceptance-fixtures, exact-sha, gsd-runtime, receipt-validation]
requires:
  - phase: 139-required-truth-reconciliation
    provides: Sealed Phase 139 acceptance and post-transition receipt contracts
provides:
  - Acceptance fixture children bound to one explicit GSD tools runtime root
  - Focused proof-map entry for exact acceptance and receipt selectors
affects: [verification, release-hygiene, phase-140-entry-gate]
actuals:
  tokens: 3611
  tasks: 2
  commits: 2
  plan_head_before: 70bf4b68a12854891082bd31fb6ed66f06b1efe8
tech-stack:
  added: []
  patterns: [explicit fixture runtime propagation, fail-closed GSD tools selection]
key-files:
  created:
    - .planning/phases/139-required-truth-reconciliation/139-10-SUMMARY.md
  modified:
    - scripts/maintainer/baseline_inventory.sh
    - test/support/lockspire/release_proof/package_assertions.ex
    - .planning/phases/139-required-truth-reconciliation/139-VALIDATION.md
key-decisions:
  - "Bind receipt preparation, fixture finalizer children, and relation validation to the same absolute GSD tools file."
  - "Keep stale relations fail-closed and leave live synchronized-main acceptance pending for the supported Phase 140 entry gate."
patterns-established:
  - "Acceptance fixtures resolve one non-symlink regular GSD tools file and pass it explicitly to every writer and validator child."
requirements-completed: [CI-08, QUAL-05, HYGIENE-05, TRUTH-03, TRUTH-04]
coverage:
  - id: D1
    description: Exact acceptance fixture runtime binding preserves successful sealed acceptance and hostile receipt/relation rejection.
    requirement: HYGIENE-05
    verification:
      - kind: integration
        ref: "GSD_TOOLS=tools/gsd-capabilities/lockspire-phase-finalizer/fixtures/gsd-core/bin/gsd-tools.cjs ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.1 MIX_ENV=test mix test test/lockspire/release/repository_hygiene_contract_test.exs --only phase139_final_acceptance --only phase139_acceptance_receipt"
        status: pass
    human_judgment: false
duration: 23min
completed: 2026-09-25
status: complete
---

# Phase 139 Plan 10: Exact Acceptance Fixture Runtime Summary

**Phase 139 acceptance fixtures now use one explicit GSD runtime for receipt creation and validation, while stale or forged evidence remains blocked.**

## Performance

- **Duration:** 23 min
- **Started:** 2026-09-26T01:43:00Z
- **Completed:** 2026-09-26T02:06:00Z
- **Tasks:** 2
- **Files modified:** 3 planned artifacts

## Accomplishments

- Made `baseline_inventory.sh` honor an explicit absolute, non-symlink regular `GSD_TOOLS` path, retaining fallback discovery only when the variable is absent.
- Passed the fixture builder's resolved GSD runtime through receipt creation, finalizer children, and relation validation; copied workflow files preserve source bytes and modes.
- Cleared ambient acceptance-only environment variables in fixture children without weakening production rejection.
- Recorded the repaired exact acceptance and receipt selectors in the validation map while retaining the live receipt and Phase 140 entry evidence as deferred.

## Evidence

- Exact Phase 139 acceptance and receipt selectors: 2 tests, 0 failures.
- Shell syntax: `bash -n scripts/maintainer/baseline_inventory.sh` passed.
- Elixir formatting: targeted `mix format --check-formatted` passed.
- The selector suite exercises the authorized fake-remote path, receipt adversaries, stale relation rejection, and local/advertised ref preservation.

## Task Commits

1. **Task 1: Bind sealed acceptance fixtures and relation checks to one exact GSD runtime root** — `61dec683`.
2. **Task 2: Close the exact-acceptance receipt selectors and record only repository-owned proof** — `82686a23`.

## Files Created/Modified

- `scripts/maintainer/baseline_inventory.sh` — consistent explicit runtime selection for post-transition receipt validation.
- `test/support/lockspire/release_proof/package_assertions.ex` — single-root fixture setup, child environment, workflow-mode preservation, and explicit helper inputs.
- `.planning/phases/139-required-truth-reconciliation/139-VALIDATION.md` — local proof-map entry for the exact acceptance selectors.

## Decisions Made

- Receipt fixture creation and relation validation must use the same absolute GSD tools path so descriptors compare the exact same workflow bytes and modes.
- Fixture success is repository-owned automated proof only; it does not create or imply a live synchronized-main receipt.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Warning cleanup] Removed unused optional fixture-helper defaults**
- **Found during:** Task 1 verification.
- **Issue:** All affected fixture call sites now supply the exact GSD tools path, leaving permissive helper defaults unused and producing compiler warnings.
- **Fix:** Required explicit environment and GSD tools arguments at the private helper boundaries.
- **Files modified:** `test/support/lockspire/release_proof/package_assertions.ex`.
- **Verification:** Both acceptance selectors passed with no compiler warnings.
- **Committed in:** `61dec683`.

**Total deviations:** 1 auto-fixed (1 Rule 1)
**Impact on plan:** The change enforces the plan's explicit-runtime requirement and removes ambiguity from fixture setup.

## Issues Encountered

- The server restart left implementation changes uncommitted. The existing diff was retained and completed; no changes were reverted or duplicated.
- `.planning/config.json` contains the orchestrator's temporary `workflow.use_worktrees=false` setting and remains uncommitted for the orchestrator to restore or retain. No state files were modified.

## User Setup Required

None.

## Next Phase Readiness

- Plan 139-10 is complete and its local selectors are green. Plan 139-11 may proceed according to its dependency.
- Phase 139 canonical verification and state reconciliation remain pending; do not infer completion from these fixtures.
- The live exact-SHA receipt and Phase 140 CI-06/CI-07 entry gate remain unchanged and pending. No human UAT was run.

## Self-Check: PASSED

- Summary file exists at the required phase path.
- Task commits `61dec683` and `82686a23` are present in Git history.
- The temporary `.planning/config.json` change is not included in either task commit.
- No `.planning/STATE.md` or `.planning/state.json` changes were made.

---
*Phase: 139-required-truth-reconciliation*
*Completed: 2026-09-25*
