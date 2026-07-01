---
phase: 121-route-scorecards-judgment-contract
plan: 02
subsystem: admin-ia-testing
tags: [admin-ui, route-scorecards, exunit, phoenix-router, support-boundary]

requires:
  - phase: 121-route-scorecards-judgment-contract
    provides: canonical route scorecard artifact from Plan 01
provides:
  - Test-only scorecard parser deriving route truth from Lockspire.Web.AdminRouter.
  - Deterministic ExUnit guardrails for scorecard fields, rubric shape, follow-up routes, boundary text, secret evidence, and Operate read-only truth.
  - Reusable route-scorecard helper for later v1.32 Support, Operate, Configure, and proof phases.
affects: [122-support-investigation-flow-polish, 123-operate-queue-flow-polish, 124-configure-onboarding-propagation-pass, 125-browser-proof-docs-adversarial-ratchet]

tech-stack:
  added: []
  patterns:
    - Test support parser for markdown scorecards with Phoenix.Router.routes-derived route truth.
    - Contract tests reuse Lockspire.Web.AdminProof.HtmlAssertions for generic CTA proof.

key-files:
  created:
    - test/support/lockspire/web/admin_proof/route_scorecards.ex
    - .planning/phases/121-route-scorecards-judgment-contract/121-02-SUMMARY.md
  modified:
    - test/lockspire/web/live/admin/design_system_contract_test.exs

key-decisions:
  - "Phase 121 scorecard route truth is derived from Phoenix.Router.routes(Lockspire.Web.AdminRouter) plus exactly /admin/clients/:client_id/edit?workflow=logout-propagation."
  - "Scorecard proof remains test-only; no runtime routes, package files, browser tooling, public theming API, or supported-surface claims were added."
  - "Operate queue scorecards are guarded as read-only support truth unless a backed domain API exists."

patterns-established:
  - "RouteScorecards.parse!/1 strictly parses ### Scorecard: `ROUTE` blocks and - **Field:** value bullets."
  - "Phase 121 contract tests validate support-boundary and secret-evidence drift across scorecards, docs, mix package metadata, router source, and test proof helpers."

requirements-completed: [IA-01, IA-02, IA-03]

duration: 7 min
completed: 2026-06-28
status: complete
---

# Phase 121 Plan 02: Route Scorecard Guardrails Summary

**Phoenix-router-derived scorecard parser and ExUnit guardrails for route truth, judgment fields, follow-up routes, support boundaries, and Operate read-only truth**

## Performance

- **Duration:** 7 min
- **Started:** 2026-06-28T17:34:49Z
- **Completed:** 2026-06-28T17:41:52Z
- **Tasks:** 2
- **Files modified:** 2 plan files, plus this summary

## Accomplishments

- Added `Lockspire.Web.AdminProof.RouteScorecards`, a test-only parser/helper that derives the expected 29 scorecard routes from `Phoenix.Router.routes(Lockspire.Web.AdminRouter)` plus the single logout-propagation workflow exception.
- Added Phase 121 contract tests for route coverage, required D-03 fields, rubric scopes/questions, allowed evidence classes, public support promise text, generic CTA checks, follow-up route bounds, forbidden evidence, public-surface creep, and Operate unsupported-action truth.
- Preserved the pre-existing dirty client-toggle assertion hunk in `design_system_contract_test.exs` and excluded it from every 121-02 commit.

## Task Commits

1. **Task 1 RED: Add failing route scorecard truth test** - `1c53af7` (test)
2. **Task 1 GREEN: Add test-only scorecard parser helper** - `75a8856` (feat)
3. **Task 2: Add Phase 121 scorecard contract tests** - `e7ed300` (test)

**Plan metadata:** committed after summary creation.

## Files Created/Modified

- `test/support/lockspire/web/admin_proof/route_scorecards.ex` - Test-only route scorecard parser and route expectation helper.
- `test/lockspire/web/live/admin/design_system_contract_test.exs` - Phase 121 deterministic scorecard guardrails.
- `.planning/phases/121-route-scorecards-judgment-contract/121-02-SUMMARY.md` - This execution summary.

## Verification

- `MIX_ENV=test mix test test/lockspire/web/live/admin/design_system_contract_test.exs --max-failures 1` - passed, 48 tests / 0 failures.
- `MIX_ENV=test mix test test/lockspire/web/live/admin/design_system_contract_test.exs test/lockspire/web/live/admin/design_system_component_stress_test.exs --max-failures 1` - passed, 54 tests / 0 failures.
- `mix format test/support/lockspire/web/admin_proof/route_scorecards.ex test/lockspire/web/live/admin/design_system_contract_test.exs --check-formatted` - passed.
- Acceptance grep confirmed the helper exports the planned functions and `expected_routes/0` uses `Phoenix.Router.routes(Lockspire.Web.AdminRouter)`.

## Decisions Made

- Followed the plan's source-truth rule: no ad hoc router regex in the new helper, and exactly one explicit query workflow exception.
- Kept all proof in ExUnit and test support; no runtime modules, docs/operator-admin.md edits, package metadata, CSS, browser config, or public support surface changed.
- Used the existing `HtmlAssertions.assert_no_generic_cta_text/1` helper for representative rendered primary-action fragments instead of duplicating HTML parsing vocabulary.

## Deviations from Plan

None - plan executed exactly as written.

**Total deviations:** 0 auto-fixed.
**Impact on plan:** No scope expansion.

## Issues Encountered

- The focused Mix commands emitted the existing KeyCache refresh log about `Lockspire.TestRepo` not being started, but ExUnit completed successfully with 0 failures. No task behavior was blocked.
- The worktree had many unrelated dirty files before execution. Only the plan-owned helper and Phase 121 test hunks were committed; the user-owned client-toggle destructive-action assertion hunk remains dirty and unstaged.

## Known Stubs

None. Stub scan only found sentinel strings inside the Phase 121 guardrail denylist constants and existing assertion variables; no UI/data stubs were introduced.

## Authentication Gates

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 121-03 can update operator-admin documentation against deterministic scorecard guardrails without expanding runtime, package, browser, or public design-system support surface.

## Self-Check: PASSED

- Found `test/support/lockspire/web/admin_proof/route_scorecards.ex`.
- Found `test/lockspire/web/live/admin/design_system_contract_test.exs` Phase 121 tests.
- Found task commits `1c53af7`, `75a8856`, and `e7ed300`.
- Confirmed the pre-existing client-toggle dirty hunk remains unstaged after task commits.
- Confirmed all plan-level verification commands passed after task commits.

---
*Phase: 121-route-scorecards-judgment-contract*
*Completed: 2026-06-28*
