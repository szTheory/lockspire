---
phase: 121-route-scorecards-judgment-contract
plan: 01
subsystem: admin-ia
tags: [admin-ui, route-scorecards, planning, oauth-oidc, phoenix]

requires:
  - phase: 107-admin-journey-contract-ia-audit
    provides: route journey contract and operator journey vocabulary
  - phase: 116-inventory-rubric-lab-contract
    provides: route workflow inventory, visual rubric, lab boundary, and component inventory
  - phase: 120-browser-proof-docs-regression-audit
    provides: source-derived route proof boundary and maintainer-only browser evidence contract
provides:
  - Canonical Phase 121 route scorecard artifact with 29 parseable scorecards.
  - Judgment rubric for Page, Section, Action, and Component Group scopes.
  - Baseline candidate classification separating dirty admin evidence from excluded Docker/demo/repo-hygiene work.
affects: [122-support-investigation-flow-polish, 123-operate-queue-flow-polish, 124-configure-onboarding-propagation-pass, 125-browser-proof-docs-adversarial-ratchet]

tech-stack:
  added: []
  patterns:
    - AdminRouter-derived route scorecards plus one explicitly documented query workflow exception.
    - Maintainer-only planning proof with public support boundary repeated per scorecard.

key-files:
  created:
    - .planning/phases/121-route-scorecards-judgment-contract/121-ROUTE-SCORECARDS.md
    - .planning/phases/121-route-scorecards-judgment-contract/121-01-SUMMARY.md
  modified: []

key-decisions:
  - "Plan 121-01 route truth is Lockspire.Web.AdminRouter plus exactly /admin/clients/:client_id/edit?workflow=logout-propagation."
  - "Dirty admin UI/proof files are candidate evidence only; Docker/demo/Traefik/repo-hygiene dirty files are excluded from Phase 121 truth."
  - "Every scorecard repeats the maintainer-only lab/support boundary and has no runtime or package impact."

patterns-established:
  - "Scorecard headings use ### Scorecard: `ROUTE` for deterministic parsing."
  - "Each scorecard uses exact D-03 bullet labels and allowed evidence classes."

requirements-completed: [IA-01, IA-02, IA-03]

duration: 10 min
completed: 2026-06-28
status: complete
---

# Phase 121 Plan 01: Route Scorecards Summary

**Admin route scorecard contract for 28 AdminRouter routes plus the single logout-propagation query workflow**

## Performance

- **Duration:** 10 min
- **Started:** 2026-06-28T17:19:05Z
- **Completed:** 2026-06-28T17:29:25Z
- **Tasks:** 2
- **Files modified:** 1 task artifact, plus this summary

## Accomplishments

- Created `121-ROUTE-SCORECARDS.md` with exactly 29 scorecards grouped by Orient, Configure, Support, and Operate.
- Added the required Page, Section, Action, and Component Group judgment rubric with the five required questions in order.
- Recorded baseline candidate classification so dirty admin files can inform later judgment without accepting unrelated Docker/demo/Traefik/repo-hygiene work as Phase 121 truth.

## Task Commits

1. **Task 1: Create canonical route scorecards** - `c0dd5c0` (docs)
2. **Task 2: Record baseline candidate classification** - `cc7636b` (docs)

**Plan metadata:** committed after summary creation.

## Files Created/Modified

- `.planning/phases/121-route-scorecards-judgment-contract/121-ROUTE-SCORECARDS.md` - Canonical route scorecard artifact and baseline candidate classification.
- `.planning/phases/121-route-scorecards-judgment-contract/121-01-SUMMARY.md` - This execution summary.

## Verification

- `test "$(rg -c '^### Scorecard: `' .planning/phases/121-route-scorecards-judgment-contract/121-ROUTE-SCORECARDS.md)" = "29"` - passed.
- `MIX_ENV=test mix run -e 'routes = Lockspire.Web.AdminRouter |> Phoenix.Router.routes() |> Enum.map(& &1.path); unless length(routes) == 28, do: raise("route count drift")'` - passed.
- `rg -n 'Baseline Candidate Classification|Excluded dirty work|This scorecard may reference maintainer-only lab/stress proof' .planning/phases/121-route-scorecards-judgment-contract/121-ROUTE-SCORECARDS.md` - passed.
- Supplemental route-set comparison against `AdminRouter` plus `/admin/clients/:client_id/edit?workflow=logout-propagation` - passed.
- Supplemental Node parser for required labels, allowed evidence classes, rubric scopes/questions, and support promise equality - passed.

## Decisions Made

- Followed the plan's source-truth boundary: operator-readable `/admin...` paths only, derived from `Lockspire.Web.AdminRouter` plus the one logout-propagation query workflow.
- Kept Phase 121 Plan 01 docs-only; no product source, operator docs, tests, package files, browser tooling, or public support surface changed.
- Treated current dirty admin work as candidate evidence only and explicitly excluded dirty Docker/demo/Traefik/repo-hygiene paths.

## Deviations from Plan

None - plan executed exactly as written.

**Total deviations:** 0 auto-fixed.
**Impact on plan:** No scope expansion.

## Issues Encountered

- A supplemental Ruby parser check could not run because local Ruby has no configured version for this repository. The same supplemental validation was rerun successfully with Node. The required plan verification commands were unaffected.

## Known Stubs

None. Stub scan found only `copy-once placeholder` wording in redaction guidance; those references describe safe placeholder language and are not unwired UI/data stubs.

## Authentication Gates

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 121-02 can now add deterministic guardrails against the canonical route scorecard artifact. Existing unrelated dirty changes remain outside this plan's commits.

## Self-Check: PASSED

- Found `121-ROUTE-SCORECARDS.md`.
- Found `121-01-SUMMARY.md`.
- Found task commits `c0dd5c0` and `cc7636b`.
- Confirmed 29 scorecard blocks after summary creation.

---
*Phase: 121-route-scorecards-judgment-contract*
*Completed: 2026-06-28*
