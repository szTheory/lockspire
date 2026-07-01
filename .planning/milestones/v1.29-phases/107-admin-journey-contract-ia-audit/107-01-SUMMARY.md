---
phase: 107-admin-journey-contract-ia-audit
plan: 01
subsystem: ui
tags: [admin-ui, journey-contract, ia-audit, docs]
requires: []
provides:
  - Phase-local route journey contract and IA audit matrix for every admin route
  - Weak-spot priority set for later v1.29 admin polish phases
  - Locked DCR/logout vocabulary for docs and deterministic tests
affects: [phase-108, phase-109, phase-110, admin-ui, operator-docs]
tech-stack:
  added: []
  patterns:
    - Phase-local markdown contract sourced from AdminRouter, UI-SPEC, docs, route code, and screenshot evidence
key-files:
  created:
    - .planning/phases/107-admin-journey-contract-ia-audit/107-ROUTE-JOURNEY-CONTRACT.md
  modified: []
key-decisions:
  - "Keep the locked UI-SPEC route contract columns unchanged and place desktop/mobile strength ratings in a separate IA audit matrix."
  - "Treat /admin/clients/:client_id/edit?workflow=logout-propagation as a contract workflow even though it is query-driven rather than a separate Phoenix route."
  - "Preserve strong v1.28 overview, DCR, policy, client workspace, and key lifecycle evidence while prioritizing support, operations, IAT, mobile, and client action grouping weak spots."
patterns-established:
  - "Route contracts publish mounted /admin paths while sourcing route truth from Lockspire.Web.AdminRouter."
  - "Audit evidence uses code, docs, and screenshot paths without copying secrets, raw tokens, or registration access token values."
requirements-completed:
  - JOURNEY-01
  - JOURNEY-02
  - JOURNEY-03
  - JOURNEY-05
  - JOURNEY-06
duration: 20 min
completed: 2026-06-04
---

# Phase 107 Plan 01: Route Journey Contract And IA Audit Summary

**Route-by-route admin journey contract with evidence-backed IA strength ratings and locked DCR/logout vocabulary**

## Performance

- **Duration:** 20 min
- **Started:** 2026-06-04T01:06:00Z
- **Completed:** 2026-06-04T01:26:22Z
- **Tasks:** 1
- **Files modified:** 1

## Accomplishments

- Created the phase-local route journey contract covering every mounted `/admin...` route plus the logout-propagation query workflow.
- Assigned every route exactly one Orient/Configure/Support/Operate journey, persona, JTBD, primary decision, primary action, empty state, risk state, follow-up route, and evidence source.
- Added a separate IA audit matrix with desktop/mobile `strong`, `adequate`, and `weak` ratings, preserving strong baselines while prioritizing support, operations, IAT, mobile, and client action grouping work.
- Locked the vocabulary split between `DCR onboarding` and `DCR policy`, and between `post-logout redirect URIs` and `logout propagation URIs`.

## Task Commits

Each task was committed atomically:

1. **Task 1: Create the route journey contract and IA audit matrix** - `2deb015` (docs)

**Plan metadata:** committed with this SUMMARY closeout.

## Files Created/Modified

- `.planning/phases/107-admin-journey-contract-ia-audit/107-ROUTE-JOURNEY-CONTRACT.md` - Route journey contract, IA audit matrix, weak-spot priority set, vocabulary lock, and requirement coverage.

## Decisions Made

- Kept the locked route contract fields exactly as specified by `107-UI-SPEC.md`, with desktop/mobile audit ratings in a separate table.
- Published mounted `/admin...` paths even though route truth comes from `Lockspire.Web.AdminRouter`, because the contract describes operator-visible routes.
- Included `/admin/clients/:client_id/edit?workflow=logout-propagation` as an explicit workflow row because it is a required operator journey even though it is resolved by query params.

## Deviations from Plan

None - plan executed exactly as written.

---

**Total deviations:** 0 auto-fixed.
**Impact on plan:** No scope change.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 107-02 can align `docs/operator-admin.md` to the same journey labels, route ownership model, and DCR/logout vocabulary. Plan 107-03 can then read this contract and add deterministic drift tests.

---
*Phase: 107-admin-journey-contract-ia-audit*
*Completed: 2026-06-04*
