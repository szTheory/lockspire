---
phase: 109-weak-spot-page-polish
plan: 06
subsystem: test
tags: [phoenix-liveview, admin-ui, contract-tests, release-readiness]
requires:
  - phase: 109-weak-spot-page-polish
    provides: Completed weak-spot route polish across Support, Operate, and Configure journeys
provides:
  - Deterministic Phase 109 contract assertions for journey labels, shared primitives, redaction, risky actions, and style fences
  - Client detail Configure journey marker and noun-specific RAT submit label
  - Updated stale route/docs assertions for DCR onboarding, RAT rotation, and PAR policy routes
affects: [phase-109, phase-110, admin-ui-contracts]
tech-stack:
  added: []
  patterns: [source-contract-test, no-inline-style-fence, generic-cta-fence, redaction-proof]
key-files:
  created: []
  modified:
    - test/lockspire/web/live/admin/design_system_contract_test.exs
    - lib/lockspire/web/live/admin/clients_live/show.ex
    - test/lockspire/web/live/admin/clients_live_test.exs
    - test/lockspire/web/live/admin/overview_live_test.exs
    - docs/operator-admin.md
key-decisions:
  - "Phase 109 proof stays source-based and deterministic; screenshot inventory, browser automation, docs regression proof expansion, and demo seeds remain Phase 110 scope."
  - "Client detail is now explicitly marked as a Configure journey route because the phase contract included client detail in Configure posture proof."
patterns-established:
  - "Future weak-spot contracts should define touched source lists once, then assert journey labels and primitive usage by route group."
  - "Generic CTA fences should inspect visible standalone label patterns instead of raw grep counts."
requirements-completed: [OPS-01, OPS-02, OPS-03, OPS-04, OPS-05, CONFIG-01, CONFIG-02]
duration: 6 min
completed: 2026-06-04
---

# Phase 109 Plan 06: Contract Fence Summary

**Phase 109 now has deterministic contract coverage for journey labels, shared primitives, redaction, risky actions, and style discipline**

## Performance

- **Duration:** 6 min
- **Started:** 2026-06-04T08:33:19Z
- **Completed:** 2026-06-04T08:38:43Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments

- Added Phase 109 source lists and contract tests for Support, Operate, and Configure route groups.
- Asserted shared primitive usage across the touched routes: filter bars, metrics, summary stats, resource rows, long values, confirmation panels, copy-once secret panel, and action groups.
- Added deterministic fences for inline styles, unnamespaced admin classes, generic standalone CTA labels, redaction coverage, risky-action consequence copy, destructive separation, and absence of Phase 110 screenshot/demo/visual-regression scope.
- Fixed the remaining generic `Rotate RAT` submit label to `Rotate registration access token`.
- Added a Configure hero to client detail so the client detail route participates in the Configure posture contract.
- Updated stale tests/docs for DCR onboarding vocabulary, RAT action label changes, and global/client PAR policy routes.

## Task Commits

1. **Task 1: Fence Phase 109 journey labels, primitives, and mobile wrapping proxies** - `9597cf7` (test)
2. **Task 2: Fence generic CTAs, redaction, and risky-action copy** - `9597cf7` (test)

**Plan metadata:** pending summary commit

## Files Created/Modified

- `test/lockspire/web/live/admin/design_system_contract_test.exs` - Adds Phase 109 route-group source contracts and copy/security/style fences.
- `lib/lockspire/web/live/admin/clients_live/show.ex` - Adds Configure hero and noun-specific RAT submit label exposed by the contract.
- `test/lockspire/web/live/admin/clients_live_test.exs` - Updates RAT action assertions for the new noun-specific label.
- `test/lockspire/web/live/admin/overview_live_test.exs` - Updates DCR landing copy assertions to `DCR onboarding` and `Mint initial access token`.
- `docs/operator-admin.md` - Restores explicit global and per-client PAR policy route strings required by release readiness.

## Decisions Made

- Kept contract assertions source-based and deterministic instead of adding screenshots, Playwright, visual regression tooling, docs proof expansion, or demo seed work.
- Used visible standalone label regexes for generic CTA detection to avoid comment-only or grep-count false confidence.

## Deviations from Plan

- Updated `lib/lockspire/web/live/admin/clients_live/show.ex` because the new contract exposed a generic `Rotate RAT` button and missing Configure journey marker on client detail.
- Updated stale focused/release tests and `docs/operator-admin.md` because the full verification suite exposed old RAT/DCR labels and missing PAR route strings.

**Total deviations:** 2 auto-fixed.
**Impact on plan:** No scope creep; fixes were directly exposed by deterministic contract or required verification and stayed inside Phase 109 UI/docs/test boundaries.

## Issues Encountered

- The first redaction contract asserted invented wording (`raw credentials`). Tightened it to actual source/test proof strings such as `current credential`, `token material`, and `token-ui-refresh-hash`.
- The first Configure contract treated helper modules and templates identically. Adjusted the assertion to check rendered source files for the journey label while still keeping helper sources in primitive/redaction coverage.

## Verification

- `mix test test/lockspire/web/live/admin/design_system_contract_test.exs --max-failures 1` - passed, 15 tests, 0 failures.
- `mix test test/lockspire/web/live/admin/tokens_live_test.exs test/lockspire/web/live/admin/consents_live_test.exs test/lockspire/web/live/admin/logout_deliveries_live_test.exs test/lockspire/web/live/admin/device_authorizations_live_test.exs test/lockspire/web/live/admin/interactions_live_test.exs test/lockspire/web/live/admin/iat_live_test.exs test/lockspire/web/live/admin/keys_live_test.exs test/lockspire/web/live/admin/clients_live/show_test.exs --max-failures 1` - passed, 32 tests, 0 failures.
- `MIX_ENV=test mix compile --warnings-as-errors` - passed.
- `mix test` - passed, 1067 tests, 0 failures, 287 excluded.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Phase 109 is ready for phase-level verification and completion. Phase 110 can own the broader screenshot inventory, docs regression proof expansion, and demo seed work that Plan 109-06 intentionally kept out of scope.

---
*Phase: 109-weak-spot-page-polish*
*Completed: 2026-06-04*
