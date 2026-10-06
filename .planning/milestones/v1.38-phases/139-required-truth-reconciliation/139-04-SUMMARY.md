---
phase: 139-required-truth-reconciliation
plan: "04"
subsystem: maintained-release-truth
tags: [release-please, github-actions, exact-sha, repository-hygiene, oidf]

requires:
  - phase: 139-required-truth-reconciliation
    plan: "01"
    provides: Exact-SHA repository acceptance and explicit WARN disposition vocabulary
  - phase: 139-required-truth-reconciliation
    plan: "03"
    provides: Executable push/no-publish and protected-dispatch publication graph proof
provides:
  - Maintained release guidance aligned to push-owned Release Please maintenance and protected exact-current-main dispatch publication
  - Byte-preserved historical 1.5.0 release receipts with package-before-matching-GitHub-release ordering for future publication
  - Coherent active-v1.38 versus latest-shipped-1.5.0 planning and hygiene language with supplemental OIDF explicitly outside acceptance
affects: [139-05, 139-06, 139-07, phase-140, phase-141]

actuals:
  tokens: 4595
  tasks: 2
  commits: 4
plan_head_before: 53686b27693ec6b7d0315f77b210ae58da3c8193

tech-stack:
  added: []
  patterns: [executable-workflow authority, active-versus-shipped truth classes, immutable historical receipt block]

key-files:
  created: []
  modified:
    - .planning/PROJECT.md
    - .planning/RELEASE-TRAIN.md
    - .planning/REPO-HYGIENE-CHECKLIST.md
    - docs/maintainer-release.md
    - test/support/lockspire/release_proof/workflow_assertions.ex

key-decisions:
  - "Treat maintained release prose as a checked projection of executable workflow authority: push maintains Release Please state, while only protected workflow_dispatch may publish an exact lowercase current-main commit after matching CI proof."
  - "Represent v1.38/Phase 139 as active planning and v1.37/Lockspire 1.5.0 as latest shipped history; coherence preserves both truth classes instead of rewriting either one."

patterns-established:
  - "Release guidance contracts compare stable maintained statements to executable job regions, the exact mix ci alias, and immutable receipt identities."
  - "Exact-SHA hygiene guidance names complete WARN disposition semantics and keeps redacted supplemental OIDF evidence non-certifying and outside required acceptance."

requirements-completed: [CI-08, TRUTH-03, TRUTH-04, TRUTH-05]

coverage:
  - id: D1
    description: Maintained release guidance now matches push-only Release Please ownership, exact-current-main dispatch eligibility, and package-before-matching-GitHub-release ordering.
    requirement: TRUTH-05
    verification:
      - kind: unit
        ref: "test/lockspire/release/release_automation_contract_test.exs#release workflow preserves the protected publish boundary"
        status: pass
      - kind: integration
        ref: "mix test test/lockspire/release_readiness_contract_test.exs test/lockspire/release_ci_evidence_contract_test.exs"
        status: pass
    human_judgment: false
  - id: D2
    description: Current records distinguish active v1.38/Phase 139 planning from latest-shipped v1.37/1.5.0 history while preserving the complete historical release receipt block byte-for-byte.
    requirement: TRUTH-04
    verification:
      - kind: unit
        ref: "test/lockspire/release/release_automation_contract_test.exs#release metadata and maintainer guidance agree on the current release"
        status: pass
      - kind: integration
        ref: "cmp pre-edit-current-baseline post-edit-current-baseline"
        status: pass
    human_judgment: false
  - id: D3
    description: The hygiene checklist names exact-SHA acceptance and complete WARN dispositions while retaining OIDF/FAPI as redacted, supplemental, non-certifying evidence outside required acceptance.
    requirement: CI-08
    verification:
      - kind: integration
        ref: "mix test test/lockspire/conformance_workflow_contract_test.exs test/lockspire/conformance_redacted_evidence_contract_test.exs"
        status: pass
    human_judgment: false

duration: 7 min
completed: 2026-09-11
status: complete
---

# Phase 139 Plan 04: Maintained Release and Planning Truth Summary

**Current guidance now follows the executable exact-SHA release lane, distinguishes active v1.38 planning from shipped Lockspire 1.5.0 history, and keeps supplemental OIDF evidence outside required acceptance.**

## Performance

- **Duration:** 7 min
- **Started:** 2026-09-11T23:23:31Z
- **Completed:** 2026-09-11T23:30:35Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments

- Corrected push/publication ownership, exact lowercase current-main dispatch input, exact candidate CI eligibility, package-before-GitHub-release ordering, and the documented `mix ci` membership.
- Reframed only PROJECT's stale next-goal paragraph and the research-enumerated hygiene statements so active v1.38/Phase 139 and latest-shipped v1.37/1.5.0 remain distinct coherent facts.
- Added focused source contracts for workflow-backed release guidance, immutable 1.5.0 identities, exact-SHA/WARN hygiene semantics, and redacted non-certifying supplemental OIDF evidence.

## Task Commits

Each task followed RED then GREEN and was committed atomically:

1. **Task 1: Align release guidance with executable ownership and ordering**
   - `761aff2e` — `test(139-04): add failing release guidance contract`
   - `a371b905` — `feat(139-04): align release guidance with protected workflow`
2. **Task 2: Encode coherent active, shipped, hygiene, and supplemental truth**
   - `90e9a1e8` — `test(139-04): add failing maintained truth contract`
   - `0108baaf` — `feat(139-04): reconcile active and shipped repository truth`

## Files Created/Modified

- `.planning/PROJECT.md` — Replaced only the stale next-milestone paragraph with active v1.38 completion language and preserved latest-shipped 1.5.0 truth.
- `.planning/RELEASE-TRAIN.md` — Corrected push/dispatch ownership, exact-current-main eligibility, publication order, and exact-CI next-cut language without changing the historical baseline block.
- `.planning/REPO-HYGIENE-CHECKLIST.md` — Added the exact-SHA acceptance command, complete WARN disposition rule, active-versus-shipped explanation, and supplemental OIDF boundary.
- `docs/maintainer-release.md` — Removed the nonexistent `mix test.phase3` membership and aligned exact dispatch, CI eligibility, and package-before-release guidance to executable behavior.
- `test/support/lockspire/release_proof/workflow_assertions.ex` — Added focused maintained-source assertions against workflow authority, exact `mix ci` membership, immutable receipts, and supplemental evidence boundaries.

## Evidence

- Combined release, readiness, CI-evidence, and conformance gate — 16 tests passed.
- The pre-edit and post-edit `.planning/RELEASE-TRAIN.md` `Current Baseline` sections compare byte-for-byte equal.
- The realized diff contains exactly the five plan-owned files; no workflow, release manifest/config, changelog, version, milestone archive, or OIDF receipt changed.
- All enumerated old push-publish, tag-input, recency, reversed-order, and extra contributor-gate claims are absent.

## TDD Gate Compliance

- Task 1 RED: `release workflow preserves the protected publish boundary` failed on the missing exact-dispatch maintained statement; `tdd-red-evidence` returned `RED_EVIDENCE_OK`.
- Task 1 GREEN: release automation, readiness, and CI-evidence contracts passed with the immutable 1.5.0 block unchanged.
- Task 2 RED: `release metadata and maintainer guidance agree on the current release` failed on PROJECT's stale next-goal paragraph; `tdd-red-evidence` returned `RED_EVIDENCE_OK`.
- Task 2 GREEN: release metadata and both conformance contract suites passed with only PROJECT and the hygiene checklist added to the task diff.
- No separate REFACTOR commit was needed; the GREEN edits are the minimal research-enumerated prose corrections.

## Decisions Made

- Prose cannot expand release authority: stable guide statements are tested against the workflow's event split, exact ref validator, needs chain, and step order.
- Active planning and shipped release truth are deliberately separate. v1.38/Phase 139 is active; v1.37/Lockspire 1.5.0 remains latest shipped until the normal release train changes it.
- A supplemental OIDF result is retained as redacted, non-certifying context and can neither satisfy nor block required repository acceptance.

## Assumption Delta

`no-change` — research's eight enumerated prose contradictions reproduced exactly, while the historical 1.5.0 chain and existing OIDF taxonomy were already coherent and required no executable or historical mutation.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## Known Stubs

None. No placeholder, skipped assertion, or unwired data source was introduced.

## Threat Flags

None. The changes stay within the planned executable-workflow-to-prose, active-planning-to-shipped-history, and supplemental-to-required-evidence trust boundaries; no endpoint, authentication, schema, network, or new file-access surface was added.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Maintained current prose is ready for Plan 139-05's inventory refresh and Phase 139 lifecycle/currentness binding.
- Immutable shipped history, release-owned files, executable workflows, and retained supplemental evidence remain untouched.

## Self-Check: PASSED

- All five plan-owned files and this summary exist.
- Task commits `761aff2e`, `a371b905`, `90e9a1e8`, and `0108baaf` resolve in repository history.
- The persisted plan ledger measures four task commits from `53686b27693ec6b7d0315f77b210ae58da3c8193` through the current task HEAD.
- Fresh combined verification completed with all 16 tests passing; the historical block comparison, exact file allowlist, coverage classifier, `git diff --check`, and summary validator also passed.

---
*Phase: 139-required-truth-reconciliation*
*Completed: 2026-09-11*
