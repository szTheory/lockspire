---
phase: 162-lifetime-semantics-upgrade-contract
plan: "01"
subsystem: auth
tags: [oauth, oidc, dynamic-registration, lifetimes, compatibility]
requires: []
provides:
  - Selected phase-local lifetime, management, compatibility and deployment contract
  - Structured expected-contract cases and standard-library consistency validator
  - Scope and downstream evidence ownership for Phases 163–166
affects: [163-app-lifetime, 164-shared-secret-lifetime, 165-management-token-lifetime, 166-cross-phase-proof]
actuals:
  tokens: 16838
  tasks: 3
  commits: 3
plan_head_before: e090ed9f7864f151624c26ccf54d1557bfec93af
plan_head_after: facc252b
commits: 3
tech-stack:
  added: []
  patterns: [design-only acceptance fixtures, independent arithmetic and semantic checks]
key-files:
  created:
    - .planning/phases/162-lifetime-semantics-upgrade-contract/162-CONTRACT.md
    - .planning/phases/162-lifetime-semantics-upgrade-contract/162-CASES.json
    - .planning/phases/162-lifetime-semantics-upgrade-contract/validate_contract.py
    - .planning/phases/162-lifetime-semantics-upgrade-contract/162-COVERAGE.md
  modified:
    - .planning/phases/162-lifetime-semantics-upgrade-contract/162-VALIDATION.md
decisions:
  - Preserve the selected D-01 through D-27 semantics and leave implementation proof to later phases.
  - Keep runtime enforcement and DCR requirement completion pending independent verification.
requirements-completed: []
coverage:
  - id: D1
    description: Phase-local lifetime and upgrade contract with typed expected-contract cases
    verification:
      - kind: other
        ref: python3 .planning/phases/162-lifetime-semantics-upgrade-contract/validate_contract.py --stage complete --self-test
        status: pass
    human_judgment: true
    rationale: Independent semantic review is a separate Phase 162 verifier gate.
key-decisions:
  - "Nil and zero remain unlimited; positive lifetimes use issuance snapshots and strict UTC-second boundaries."
  - "Legacy/custom-store compatibility requires explicit authoritative version and guarded whole-row promotion."
metrics:
  duration: 5 min
  completed: "2026-10-20"
status: complete
---

# Phase 162 Plan 01: Lifetime Semantics & Upgrade Contract Summary

**A selected DCR lifetime contract, 69 structured cases and a local validator define policy boundaries, management recovery, legacy promotion and upgrade order without claiming runtime enforcement.**

## Performance

- **Duration:** 5 min
- **Started:** 2026-10-20T22:18:05Z
- **Completed:** 2026-10-20T22:22:52Z
- **Tasks:** 3
- **Files modified:** 5

## Accomplishments

- Defined issuance-relative app, secret and management deadlines, nil/zero unlimited behavior, strict equality boundaries, token caps and endpoint-specific outcomes.
- Added all 18 selected consumer rows, legacy/custom-store cases, guarded concurrency schedules, deployment sequencing and rollback boundaries.
- Added a direct standard-library validator with independent arithmetic checks and 22 named negative mutations, plus a scope and evidence handoff for Phases 163–166.

## Task Commits

1. **Task 1: Trace one issuance policy through the normative contract, cases and validator** — `24da136d` (`docs`)
2. **Task 2: Expand the contract through consumers, management recovery and wire outcomes** — `696e4902` (`docs`)
3. **Task 3: Complete legacy, adapter, concurrency and deployment contracts with bounded handoff** — `facc252b` (`docs`)

## Files Created/Modified

- `.planning/phases/162-lifetime-semantics-upgrade-contract/162-CONTRACT.md` — normative selected contract and traceability maps.
- `.planning/phases/162-lifetime-semantics-upgrade-contract/162-CASES.json` — structured expected outcomes for policy, consumers, management, compatibility and handoff.
- `.planning/phases/162-lifetime-semantics-upgrade-contract/validate_contract.py` — local structural, semantic and arithmetic validation with self-tests.
- `.planning/phases/162-lifetime-semantics-upgrade-contract/162-COVERAGE.md` — scope applicability, seven fallback dispositions and downstream evidence ownership.
- `.planning/phases/162-lifetime-semantics-upgrade-contract/162-VALIDATION.md` — automated checks recorded as passed; independent semantic review remains open.

## Decisions Made

- Followed all 27 user-selected decisions without reopening policy choices.
- Kept DCR-02/03/04 out of `requirements-completed`; the independent Phase 162 verifier and later implementation evidence remain separate gates.

## Deviations from Plan

None. The contract and fixtures remain design-only; no runtime, test suite, public docs, dependency, schema or UI change was made.

## Issues Encountered

Initial validator assertions exposed missing explicit section anchors and incomplete semantic checks; these were corrected before their task commits and verified with the prescribed stage self-tests.

## User Setup Required

None.

## Next Phase Readiness

The contract artifacts are ready for independent semantic review against `162-CONTEXT.md` and `162-VALIDATION.md`. The complete-stage validator establishes internal consistency only. Do not start implementation planning for Phases 163–166 until that independent Phase 162 verification passes. Phase 166 remains the final proof owner for DCR requirements.

## Self-Check: PASSED

All four contract artifacts and this summary exist. Task commits `24da136d`, `696e4902` and `facc252b` are present in the current history. The plan ledger measures 3 commits from `e090ed9f7864f151624c26ccf54d1557bfec93af` through `facc252b`.
