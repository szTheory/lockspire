---
phase: 142-merge-the-corrected-main-baseline
plan: "01"
subsystem: release-hygiene
tags: [markdown-links, exunit, contributor-ci, release-train]
requires:
  - phase: 141-maintenance-baseline-closure
    provides: archived Phase 141 baseline and release-train record
provides:
  - corrected Phase 141 links in the maintained release-train ledger
  - focused ExUnit contract for local links in the release-train ledger
  - archived-path release fixtures and a passing full contributor gate
affects: [phase-142, release-train, contributor-ci]
actuals:
  tokens: 4028
  tasks: 2
  commits: 4
tech-stack:
  added: []
  patterns: [focused-static-document-contract, TAP-backed-red-evidence]
key-files:
  created:
    - .planning/phases/142-merge-the-corrected-main-baseline/142-01-red-evidence.json
    - .planning/phases/142-merge-the-corrected-main-baseline/142-01-red.tap
  modified:
    - .planning/RELEASE-TRAIN.md
    - test/lockspire/release/repository_hygiene_contract_test.exs
    - test/lockspire/quality/phase_138_prohibition_consistency_test.exs
    - test/lockspire/quality/phase_139_planning_consistency_test.exs
    - test/lockspire/release/phase140_read_only_closure_contract_test.exs
    - test/support/lockspire/release_proof/package_assertions.ex
    - .planning/phases/142-merge-the-corrected-main-baseline/142-01-PLAN.md
    - .planning/phases/142-merge-the-corrected-main-baseline/142-02-PLAN.md
    - .planning/phases/142-merge-the-corrected-main-baseline/142-VALIDATION.md
    - .planning/STATE.md
    - .planning/state.json
key-decisions:
  - "Run the full contributor gate before opening the review PR; Plan 02 owns remote PR creation and live release-timing checks."
  - "Keep automated verification as the acceptance path; no manual UAT is needed for deterministic local-link behavior."
patterns-established:
  - "A focused ExUnit contract checks local links in the maintained release-train ledger."
requirements-completed: [TRUTH-06, CI-09]
coverage:
  - id: D1
    description: "The Phase 141 ledger links resolve, and the focused contract catches unresolved local destinations."
    requirement: TRUTH-06
    verification:
      - kind: unit
        ref: "test/lockspire/release/repository_hygiene_contract_test.exs#local release train Markdown destinations resolve"
        status: pass
    human_judgment: false
  - id: D2
    description: "The corrected branch passes the full contributor gate with archive-aware release fixtures."
    requirement: CI-09
    verification:
      - kind: integration
        ref: "mix ci on Elixir 1.19.5 / OTP 28; full command exited 0, including test.fast and 102 integration tests"
        status: pass
    human_judgment: false
status: complete
metrics:
  duration: 190min
  completed: 2026-10-06
  tasks: 2
  files: 12
  commits: 4
---

# Phase 142 Plan 01: Contributor Gate Passed

**The release-train link repair, archived-path fixture repairs, focused checks, and full local contributor gate pass. Plan 02 is next for PR creation and live release-timing review.**

## Performance

- **Duration:** 190 minutes, including the failed gate run, fixture repair, and final full gate
- **Started:** 2026-10-06T16:34:57Z
- **Completed:** 2026-10-06T19:45:01Z
- **Tasks:** 2 of 2 completed
- **Files modified or recorded:** 12

## Accomplishments

- Corrected the two Phase 141 baseline destinations in `.planning/RELEASE-TRAIN.md`.
- Added a tagged ExUnit contract that checks local Markdown links in that ledger. The focused test failed on the old destination, then passed after the repair (one selected test).
- Updated Phase 138/139 current-source references to the v1.38 archive while preserving old paths only inside historical fixtures.
- Rebuilt the Phase 139 historical planning snapshot from its exact parent commit and kept the historical byte-digest check unchanged.
- Ran the affected Phase 138/139 and Phase 140 tests, formatting, and the full `mix ci` gate successfully. The gate included 102 integration tests; all completed with zero failures.
- The full gate ran against this fixture-repair source tree before it was committed unchanged as `cfcb73ad01907e8d8d1aff5891791af1ba6a0937`; Plan 02 will obtain hosted checks for the final PR head.

## Task Commits

1. **Task 1: Repair the archived link through its CI contract** — `66d19c44` (red test), `020f5933` (link repair), and `fffee440` (formatting).

2. **Task 2: Repair archived-path fixtures and pass the contributor gate** — `cfcb73ad`.

**Plan metadata:** `5b14374e`.

No PR was opened or pushed as part of this preparation. Plan 02 owns that next step.

## Files Created/Modified

- `.planning/RELEASE-TRAIN.md` — corrected two links to the archived Phase 141 baseline.
- `test/lockspire/release/repository_hygiene_contract_test.exs` — added the focused local-link contract.
- Phase 138/139/140 quality and release tests plus `package_assertions.ex` — now read archive-backed source paths and preserve historical fixture paths.
- `142-01-red-evidence.json` and `142-01-red.tap` — retained the valid failing-before-fix test evidence.
- `142-VALIDATION.md`, `STATE.md`, and this summary — record the passing full contributor gate and exact next action.

## Decisions Made

- Complete the local contributor gate before starting the hosted PR review and timing checks in Plan 02.
- Keep verification automated. The link contract is deterministic and does not need manual UAT.

## Issues Encountered

- The first full run exposed stale current-source paths and a Phase 139 historical fixture built from later planning files. Both issues were repaired; focused checks and a final full `mix ci` run passed.
- The dependency audit printed `error: cannot open '.git/FETCH_HEAD': Operation not permitted` in this sandbox, then completed with `No vulnerabilities found`; `mix ci` exited successfully.

## User Setup Required

None.

## Next Phase Readiness

- Plan 01 is complete. Plan 02 is ready to create or update the review PR, confirm its exact head and required checks, and inspect live release timing. Plan 03 remains dependent on Plan 02's explicit merge authorization.
- The verified fixture-repair commit is `cfcb73ad01907e8d8d1aff5891791af1ba6a0937` on `gsd/phase-141-maintenance-baseline-closure`. No PR was opened and no remote update occurred during this preparation.
- Lockspire 1.5.0 remains the latest public package. No publication action occurred.

---
*Phase: 142-merge-the-corrected-main-baseline*
*Completed: 2026-10-06*
