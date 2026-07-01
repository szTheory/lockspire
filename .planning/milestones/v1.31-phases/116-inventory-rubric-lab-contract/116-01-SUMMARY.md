---
phase: 116-inventory-rubric-lab-contract
plan: 01
subsystem: ui
tags: [admin-ui, design-system, route-inventory, brandbook, exunit]
requires:
  - phase: 107-admin-journey-contract-ia-audit
    provides: route journey vocabulary and logout-propagation workflow truth
provides:
  - source-derived admin route/workflow inventory
  - brandbook-derived visual and UX rubric
affects: [phase-117, phase-118, phase-119, phase-120, admin-ui]
tech-stack:
  added: []
  patterns: [source-derived markdown contracts, tagged ExUnit source-contract tests]
key-files:
  created:
    - .planning/phases/116-inventory-rubric-lab-contract/116-ROUTE-WORKFLOW-INVENTORY.md
    - .planning/phases/116-inventory-rubric-lab-contract/116-VISUAL-UX-RUBRIC.md
  modified:
    - test/lockspire/web/live/admin/design_system_contract_test.exs
key-decisions:
  - "Admin route inventory derives from Lockspire.Web.AdminRouter and appends only the logout-propagation query workflow exception."
  - "The visual rubric treats brandbook/ as canonical and keeps PhoenixStorybook rejected/default-deferred for Phase 116."
patterns-established:
  - "Phase 116 contracts use tagged ExUnit tests for narrow proof slices."
requirements-completed:
  - LAB-03
duration: 3 min
completed: 2026-06-25
status: complete
---

# Phase 116 Plan 01: Source-Derived Route Workflow Inventory And Brandbook Rubric Summary

**Admin route/workflow inventory from `AdminRouter` plus a brandbook-derived visual rubric with tagged ExUnit contract proof.**

## Performance

- **Duration:** 3 min
- **Started:** 2026-06-25T15:55:00Z
- **Completed:** 2026-06-25T15:58:00Z
- **Tasks:** 3
- **Files modified:** 3

## Accomplishments

- Created `116-ROUTE-WORKFLOW-INVENTORY.md` with every normal `/admin...` route derived from `Lockspire.Web.AdminRouter`.
- Added the required `/admin/clients/:client_id/edit?workflow=logout-propagation` query workflow as URL/query truth, not router truth.
- Created `116-VISUAL-UX-RUBRIC.md` from `brandbook/` gates covering Signal Cyan, Deep Cyan, dark semantic aliases, accessibility, redaction, motion, and no generic security tropes.
- Added tagged `:phase_116_route_inventory` and `:phase_116_visual_rubric` ExUnit contract tests.

## Task Commits

Executed in the main checkout with `workflow.use_worktrees=false`. No isolated per-task commits were created because the checkout already contained unrelated dirty admin UI changes in shared files; the executor preserved them and kept the Phase 116 changes scoped.

## Files Created/Modified

- `.planning/phases/116-inventory-rubric-lab-contract/116-ROUTE-WORKFLOW-INVENTORY.md` - Source-derived route/workflow inventory and classification contract.
- `.planning/phases/116-inventory-rubric-lab-contract/116-VISUAL-UX-RUBRIC.md` - Brandbook-derived pass/fail visual and UX rubric.
- `test/lockspire/web/live/admin/design_system_contract_test.exs` - Tagged Phase 116 route inventory and rubric tests.

## Decisions Made

- The route inventory uses `/admin...` operator paths and keeps host mount prefixes out of canonical route truth.
- Operation queue routes record read-only support truth and do not add retry, discard, logout, or other unbacked controls.
- PhoenixStorybook remains rejected/default-deferred for Phase 116.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- Rubric test initially failed on exact lower-case gate phrase matching; resolved by adding a contract keyword line without changing scope.

## Verification

- `mix test test/lockspire/web/live/admin/design_system_contract_test.exs --only phase_116_route_inventory --max-failures 1` - passed.
- `mix test test/lockspire/web/live/admin/design_system_contract_test.exs --only phase_116_visual_rubric --max-failures 1` - passed.
- `rg -n "workflow=logout-propagation|Surface classification|admin_supported" .planning/phases/116-inventory-rubric-lab-contract/116-ROUTE-WORKFLOW-INVENTORY.md` - passed.
- `rg -n "PhoenixStorybook|storybook" .planning/phases/116-inventory-rubric-lab-contract/116-VISUAL-UX-RUBRIC.md` - passed.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Ready for Plan 02 component/group inventory and maintainer-only lab contract.

---
*Phase: 116-inventory-rubric-lab-contract*
*Completed: 2026-06-25*
