---
phase: 107-admin-journey-contract-ia-audit
plan: 02
subsystem: docs
tags: [operator-docs, admin-ui, journey-vocabulary, host-boundary]
requires:
  - phase: 107-01
    provides: Phase 107 route journey contract and locked vocabulary
provides:
  - Operator guide aligned to Orient/Configure/Support/Operate journey vocabulary
  - Documentation split between DCR onboarding and DCR policy
  - Documentation split between post-logout redirect URIs and logout propagation URIs
affects: [phase-107-03, phase-110, operator-docs, admin-ui]
tech-stack:
  added: []
  patterns:
    - Operator docs stay subordinate to docs/supported-surface.md and preserve host-owned admin boundary wording
key-files:
  created: []
  modified:
    - docs/operator-admin.md
key-decisions:
  - "Use Orient, Configure, Support, and Operate as the top-level operator journey model in docs."
  - "Keep existing route group names as subordinate mapping entries so route/docs alignment remains deterministic without reintroducing a competing taxonomy."
  - "Document DCR onboarding separately from DCR policy and post-logout redirect URIs separately from logout propagation URIs."
patterns-established:
  - "Operator docs explain journey intent first, then map concrete route groups underneath that model."
requirements-completed:
  - JOURNEY-04
  - JOURNEY-05
  - JOURNEY-06
duration: 8 min
completed: 2026-06-04
---

# Phase 107 Plan 02: Operator Guide Journey Vocabulary Summary

**Operator guide aligned to the Phase 107 journey model and host-owned admin boundary**

## Performance

- **Duration:** 8 min
- **Started:** 2026-06-04T01:20:30Z
- **Completed:** 2026-06-04T01:28:34Z
- **Tasks:** 1
- **Files modified:** 1

## Accomplishments

- Reworked `docs/operator-admin.md` around the Orient, Configure, Support, and Operate journey model.
- Preserved the subordinate link to `docs/supported-surface.md` and expanded host-owned boundary wording for staff auth, MFA, role checks, tenant policy, layouts, branding, and operator authorization.
- Added explicit DCR onboarding versus DCR policy guidance for `/admin/dcr`, `/admin/iats`, `/admin/iats/new`, self-registered clients, RAT rotation, and `/admin/policies/dcr`.
- Added explicit post-logout redirect URIs versus logout propagation URIs guidance for client logout routes.

## Task Commits

Each task was committed atomically:

1. **Task 1: Rewrite the operator guide to the Phase 107 journey vocabulary** - `b701eb9` (docs)

**Plan metadata:** committed with this SUMMARY closeout.

## Files Created/Modified

- `docs/operator-admin.md` - Operator journey vocabulary, route-group mapping, host-owned boundary, DCR split, and logout split.

## Decisions Made

- Kept the concrete route group labels as subordinate mapping entries under the four journey labels because existing deterministic docs alignment already asserts those strings.
- Used exact Phase 107 vocabulary strings so Plan 107-03 can source-assert the guide without special casing.

## Deviations from Plan

None - plan executed exactly as written.

---

**Total deviations:** 0 auto-fixed.
**Impact on plan:** No scope change.

## Issues Encountered

- The first focused test run failed because the old route group names were removed entirely. The guide now keeps them as subordinate route-group mapping entries while preserving Orient/Configure/Support/Operate as the top-level journey model.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 107-03 can extend `design_system_contract_test.exs` to enforce the route contract, exact journey labels, and DCR/logout vocabulary across the contract and operator guide.

---
*Phase: 107-admin-journey-contract-ia-audit*
*Completed: 2026-06-04*
