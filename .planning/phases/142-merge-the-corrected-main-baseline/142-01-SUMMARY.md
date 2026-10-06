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
  - recorded contributor-gate blocker and exact resume point
affects: [phase-142, release-train, contributor-ci]
actuals:
  tokens: 1175
  tasks: 1
  commits: 3
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
    - .planning/phases/142-merge-the-corrected-main-baseline/142-VALIDATION.md
key-decisions:
  - "Halt before PR creation when the contributor gate fails on archived-path assumptions; record the repair needed before resuming."
  - "Keep automated verification as the acceptance path; no manual UAT is needed for deterministic local-link behavior."
patterns-established:
  - "A focused ExUnit contract checks local links in the maintained release-train ledger."
requirements-completed: []
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
    description: "The corrected branch passes the contributor gate and is available in a review PR."
    requirement: CI-09
    verification:
      - kind: integration
        ref: "mix ci on Elixir 1.19.5 / OTP 28; stopped after archived-path fixture failures appeared during mix test.fast"
        status: fail
    human_judgment: false
metrics:
  duration: 34min
  completed: 2026-10-06
  tasks: 1
  files: 8
  commits: 3
  status: halted
---

# Phase 142 Plan 01: Contributor Gate Halted

**The release-train link repair and its focused CI contract pass; the broader contributor gate exposed stale archived-path fixtures before a PR could be opened.**

## Performance

- **Duration:** 34 minutes
- **Started:** 2026-10-06T16:34:57Z
- **Completed:** 2026-10-06T17:08:33Z
- **Tasks:** 1 of 2 completed
- **Files modified or recorded:** 8

## Accomplishments

- Corrected the two Phase 141 baseline destinations in `.planning/RELEASE-TRAIN.md`.
- Added a tagged ExUnit contract that checks local Markdown links in that ledger. The focused test failed on the old destination, then passed after the repair (one selected test).
- Preserved structured red evidence and recorded the full-gate failure below.

## Task Commits

1. **Task 1: Repair the archived link through its CI contract** — `66d19c44` (red test), `020f5933` (link repair), and `fffee440` (formatting).

**Plan metadata:** `5b14374e`.

Task 2 did not complete. No PR was opened, no branch was pushed, and no review or merge authorization was requested.

## Files Created/Modified

- `.planning/RELEASE-TRAIN.md` — corrected two links to the archived Phase 141 baseline.
- `test/lockspire/release/repository_hygiene_contract_test.exs` — added the focused local-link contract.
- `142-01-red-evidence.json` and `142-01-red.tap` — retained the valid failing-before-fix test evidence.
- `142-VALIDATION.md`, `STATE.md`, and `ROADMAP.md` — recorded the passed focused test and halted contributor gate.

## Decisions Made

- Stop at the contributor gate because it emitted deterministic failures for archived planning paths. Do not create a PR until the gate is repaired and passes.
- Keep verification automated. The link contract is deterministic and does not need manual UAT.

## Issues Encountered

- The focused command passed with one selected test.
- `mix ci` progressed through compile and QA into `mix test.fast`, then emitted failures because existing Phase 140 recovery/planning checks still look under `.planning/phases/` for Phase 138/139 artifacts that are archived under `.planning/milestones/v1.38-phases/`. One observed recovery fixture failed while copying `.planning/phases/138-baseline-inventory-evidence-taxonomy` because that source path no longer exists. Other observed missing paths included Phase 139 `139-VERIFICATION.md` and `139-VALIDATION.md`, and Phase 138 `138-PROHIBITION-VALIDATION.md` and `138-01-PLAN.md`.
- The run also emitted `error: cannot open '.git/FETCH_HEAD': Operation not permitted`; this was not diagnosed because the archived-path failures already stopped the gate.
- The suite was stopped after those failures appeared, so there is no complete test count or final `mix ci` exit summary. The contributor gate is not passing evidence.

## User Setup Required

None.

## Next Phase Readiness

- Plan 01 is halted. Plan 02 and Plan 03 must remain blocked until the stale archived-path fixtures are corrected, Plan 01 is rerun, and the contributor gate passes.
- The local branch remains `gsd/phase-141-maintenance-baseline-closure`. No PR or remote update exists from this plan.
- Lockspire 1.5.0 remains the latest public package. No publication action occurred.

---
*Phase: 142-merge-the-corrected-main-baseline*
*Completed: 2026-10-06*
