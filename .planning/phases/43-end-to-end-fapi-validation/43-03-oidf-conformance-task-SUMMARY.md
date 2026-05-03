---
phase: 43-end-to-end-fapi-validation
plan: 03
subsystem: testing
tags: [fapi, oidf, mix-task, conformance, docs]
requires:
  - phase: 42-fapi-2-0-advanced-cryptography-and-oidf-test-suite-prep
    provides: OIDF harness assets and maintainer conformance workflow precedent
provides:
  - Deterministic Mix preflight for OIDF FAPI 2.0 conformance setup
  - Pinned Phase 43 FAPI 2.0 suite plan artifact and maintainer docs contract
affects: [phase-43-plan-07, release-readiness, maintainer-conformance]
tech-stack:
  added: []
  patterns: [read-only Mix preflight task, pinned conformance artifact]
key-files:
  created:
    - lib/mix/tasks/lockspire.oidf_conformance.ex
    - scripts/conformance/fapi2-plan.json
    - test/mix/tasks/lockspire/oidf_conformance_test.exs
    - .planning/phases/43-end-to-end-fapi-validation/43-03-oidf-conformance-task-SUMMARY.md
  modified:
    - docs/maintainer-conformance.md
key-decisions:
  - "The Mix task validates env, commands, and artifacts only; it does not invoke the live suite."
  - "Task configuration uses a narrow Application env override seam so missing-command and missing-artifact paths are testable without external side effects."
patterns-established:
  - "Pin OIDF suite inputs in both JSON and maintainer docs so conformance claims stay repo-truthful."
  - "Use Mix tasks as deterministic maintainer preflights, not orchestration wrappers around privileged external tooling."
requirements-completed: [FAPI-06]
duration: 3min
completed: 2026-05-03
---

# Phase 43 Plan 03: OIDF Conformance Task Summary

**Deterministic OIDF FAPI 2.0 preflight task with pinned suite inputs and maintainer docs that match the repo-truth harness.**

## Performance

- **Duration:** 3 min
- **Started:** 2026-05-03T12:44:27Z
- **Completed:** 2026-05-03T12:46:57Z
- **Tasks:** 3
- **Files modified:** 4

## Accomplishments

- Added `mix lockspire.oidf_conformance` as a read-only preflight that validates required env vars, commands, and artifact paths.
- Pinned the canonical Phase 43 OIDF FAPI 2.0 plan and variants in `scripts/conformance/fapi2-plan.json`.
- Updated maintainer docs to reference the same pinned plan contract and the new Mix preflight task.

## Task Commits

Each task was committed atomically:

1. **Task 1: Create scripts/conformance/fapi2-plan.json with pinned plan + variants (D-15)** - `87e7cdd` (feat)
2. **Task 2: Implement Mix.Tasks.Lockspire.OidfConformance with --validate-env (D-13, D-14, D-16)** - `57ec2ea` (test), `a1f1591` (feat)
3. **Task 3: Pin canonical OIDF plan + variants in docs/maintainer-conformance.md (D-15)** - `60c6f77` (docs)

## Files Created/Modified

- `lib/mix/tasks/lockspire.oidf_conformance.ex` - Mix task that validates env, artifact, and PATH prerequisites without running the suite.
- `scripts/conformance/fapi2-plan.json` - Canonical Phase 43 FAPI 2.0 OIDF plan artifact with locked variants.
- `test/mix/tasks/lockspire/oidf_conformance_test.exs` - TDD coverage for success, help, default invocation, and failure modes.
- `docs/maintainer-conformance.md` - Maintainer workflow doc pinned to the same suite plan and env contract as the task.

## Decisions Made

- Kept the task read-only and stdout-only so it remains a deterministic maintainer preflight instead of a hidden suite runner.
- Added a tiny Application env override seam for required commands and artifacts so negative-path tests stay local and deterministic.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Corrected the missing-env predicate from the plan snippet**
- **Found during:** Task 2 (Implement Mix.Tasks.Lockspire.OidfConformance with --validate-env)
- **Issue:** The plan’s sample `Enum.reject(@required_envs, &(System.get_env(&1) not in [nil, ""]))` would have reported present env vars as missing and let absent ones pass.
- **Fix:** Implemented the preflight with `Enum.filter(required_envs(), &(System.get_env(&1) in [nil, ""]))` so only missing env names are reported.
- **Files modified:** `lib/mix/tasks/lockspire.oidf_conformance.ex`
- **Verification:** `mix test test/mix/tasks/lockspire/oidf_conformance_test.exs`; `LOCKSPIRE_TEST_DB_HOST=localhost OIDF_CONFORMANCE_SERVER=https://x mix lockspire.oidf_conformance --validate-env`
- **Committed in:** `a1f1591`

---

**Total deviations:** 1 auto-fixed (Rule 1)
**Impact on plan:** Correctness-only fix. No scope change.

## Issues Encountered

- Concurrent work caused a brief compile lock on `_build`; `mix compile --warnings-as-errors` completed successfully once the lock cleared.

## Known Stubs

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Phase 43 Plan 07 can now assert repo-truth strings for the Mix task, plan JSON, and maintainer docs.
- Live OIDF suite execution remains manual by design and is still tracked outside this plan.

## Self-Check: PASSED
