---
phase: 120-browser-proof-docs-regression-audit
plan: "01"
subsystem: ui
tags: [phoenix, liveview, admin-ui, browser-proof, route-proof]
requires:
  - phase: 116-inventory-rubric-lab-contract
    provides: source-derived route/workflow inventory, visual rubric, and lab boundary
  - phase: 119-weak-page-application-ia-copy-pass
    provides: client detail support pivots and Phase 119 weak-surface polish
provides:
  - Source-derived browser proof matrix for representative admin routes
  - Mounted route/link guardrails for the supported `/admin/logouts` queue route
  - Maintainer-only manual browser evidence contract with Node/browser tooling boundary
affects: [phase-120-browser-proof, proof-02, proof-03, admin-client-detail]
tech-stack:
  added: []
  patterns:
    - Admin route truth from `Lockspire.Web.AdminRouter` plus one query workflow
    - Maintainer-only manual browser evidence under `tmp/admin-ui-polish/phase-120/`
key-files:
  created:
    - .planning/phases/120-browser-proof-docs-regression-audit/120-BROWSER-PROOF.md
    - .planning/phases/120-browser-proof-docs-regression-audit/120-01-SUMMARY.md
  modified:
    - lib/lockspire/web/live/admin/clients_live/show.ex
    - test/lockspire/web/admin_router_test.exs
    - test/lockspire/web/live/admin/clients_live/show_test.exs
key-decisions:
  - "Phase 120 route proof derives from AdminRouter and appends only `/admin/clients/:client_id/edit?workflow=logout-propagation` as query-workflow evidence."
  - "Client detail support pivots use `/admin/logouts`; the stale logout-deliveries path is rejected by mounted tests."
  - "Browser evidence remains maintainer-only manual proof unless Playwright/axe tooling is later human-verified behind `checkpoint:human-verify`."
patterns-established:
  - "Browser proof artifacts record route, JTBD, viewport/theme/motion risk, seeded state, evidence path, accessibility note, sensitive-evidence check, and gap note."
requirements-completed: [PROOF-02, PROOF-03]
duration: 7 min
completed: 2026-06-26
status: complete
---

# Phase 120 Plan 01: Browser Proof Route Matrix Summary

**Source-derived admin route proof with `/admin/logouts` drift guard and a maintainer-only browser evidence matrix.**

## Performance

- **Duration:** 7 min
- **Started:** 2026-06-26T12:40:04Z
- **Completed:** 2026-06-26T12:46:54Z
- **Tasks:** 3
- **Files modified:** 5

## Accomplishments

- Added TDD route/link proof that derives admin browser route truth from `Lockspire.Web.AdminRouter`, appends only the logout-propagation query workflow, and rejects stale logout route drift.
- Updated the client detail support pivot from the stale logout deliveries path to the supported `/admin/logouts` route.
- Created `120-BROWSER-PROOF.md` with representative Orient, Configure, Support, Operate, and internal lab rows covering `320px`, `390px`, `768px`, `1024px`, `1440px`, light, dark, system, and reduced-motion evidence.
- Locked browser tooling boundaries: no `package.json`, Playwright config, browser install, axe dependency, public docs, runtime browser-test behavior, or CI browser gate was added.

## Task Commits

1. **Task 120-01-01 RED: route/link drift proof** - `7012033` (`test`)
2. **Task 120-01-01 GREEN: logout support pivot route** - `be9a328` (`fix`)
3. **Task 120-01-02: maintainer browser proof matrix** - `16b5544` (`docs`)
4. **Task 120-01-03: browser tooling boundary** - `e6c7f0d` (`docs`)

**Plan metadata:** committed with this summary.

## Files Created/Modified

- `lib/lockspire/web/live/admin/clients_live/show.ex` - Support pivot now links to `Lockspire.mount_path() <> "/admin/logouts"`.
- `test/lockspire/web/admin_router_test.exs` - Adds source-derived route matrix proof and pins logout propagation as query workflow evidence.
- `test/lockspire/web/live/admin/clients_live/show_test.exs` - Adds mounted client-detail proof for `/admin/logouts` and stale path rejection.
- `.planning/phases/120-browser-proof-docs-regression-audit/120-BROWSER-PROOF.md` - Maintainer-only route/JTBD/browser evidence matrix and tooling boundary.
- `.planning/phases/120-browser-proof-docs-regression-audit/120-01-SUMMARY.md` - This execution summary.

## Decisions Made

- Route truth is source-derived from `AdminRouter`; Phase 110 screenshot filenames stay historical evidence only.
- `/admin/logouts` is the supported logout propagation queue route operators should be sent to from client detail.
- Manual browser evidence is the active fallback path for Plan 120-01; `@playwright/test` and `@axe-core/playwright` remain conditional maintainer tooling behind human package verification.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- During RED setup, the first route helper filtered Phoenix route verbs as `"GET"` instead of `:get`; this was corrected before the RED commit so the failing test targeted the stale rendered logout link.
- The focused test command emits an existing startup KeyCache warning before `Lockspire.TestRepo` is started, then exits successfully.

## User Setup Required

None - no external service configuration required.

## Verification

- `MIX_ENV=test mix test test/lockspire/web/admin_router_test.exs test/lockspire/web/live/admin/clients_live/show_test.exs --max-failures 1` - 17 tests, 0 failures.
- `rg -n "320px|390px|768px|1024px|1440px|manual browser evidence|checkpoint:human-verify|/admin/logouts" .planning/phases/120-browser-proof-docs-regression-audit/120-BROWSER-PROOF.md` - passed with required proof markers.
- `sh -c 'test ! -f package.json && test ! -f playwright.config.ts && rg -n "checkpoint:human-verify|manual browser evidence|maintainer-only|conditional maintainer proof" .planning/phases/120-browser-proof-docs-regression-audit/120-BROWSER-PROOF.md'` - passed.

## Known Stubs

None. The proof artifact intentionally records manual evidence gaps and evidence-note paths for the maintainer browser pass; Plan 120-01's deliverable is the route matrix and tooling boundary, not committed screenshots or browser reports.

## Threat Flags

None. The plan introduced no new network endpoint, auth path, file access pattern, schema change, supported admin route, package dependency, or runtime browser-test surface.

## Next Phase Readiness

Ready for Phase 120 Plan 02. Route truth, the stale logout support pivot, and maintainer-only browser evidence boundaries are now in place for the automated guardrail expansion.

## Self-Check: PASSED

- Found `lib/lockspire/web/live/admin/clients_live/show.ex`
- Found `test/lockspire/web/admin_router_test.exs`
- Found `test/lockspire/web/live/admin/clients_live/show_test.exs`
- Found `.planning/phases/120-browser-proof-docs-regression-audit/120-BROWSER-PROOF.md`
- Found `.planning/phases/120-browser-proof-docs-regression-audit/120-01-SUMMARY.md`
- Verified task commits exist: `7012033`, `be9a328`, `16b5544`, `e6c7f0d`

---
*Phase: 120-browser-proof-docs-regression-audit*
*Completed: 2026-06-26*
