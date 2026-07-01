---
phase: 109-weak-spot-page-polish
plan: 01
subsystem: ui
tags: [phoenix-liveview, admin-ui, tokens, support, redaction]
requires:
  - phase: 108-design-system-token-component-upgrade
    provides: Phase 108 admin primitives and long-value/resource-row treatment
provides:
  - Support token investigation index with URL filters, metrics, redacted pivots, and resource rows
  - Token detail health decision surface with separate single-token and family revocation confirmations
  - Focused LiveView proof for labels, long values, pivots, redaction, and revoke guards
affects: [phase-109, phase-110, admin-support-ui]
tech-stack:
  added: []
  patterns: [AdminComponents.page_hero, AdminComponents.resource_item, AdminComponents.long_value, AdminComponents.confirmation_panel]
key-files:
  created: []
  modified:
    - lib/lockspire/web/live/admin/tokens_live/index.ex
    - lib/lockspire/web/live/admin/tokens_live/show.ex
    - test/lockspire/web/live/admin/tokens_live_test.exs
key-decisions:
  - "Token list rows derive account/client/family handles through Lockspire.Redaction instead of rendering raw durable identifiers."
  - "Single-token revocation and token-family revocation remain separate danger confirmation panels and preserve existing LiveView event/API seams."
patterns-established:
  - "Support indexes should lead with journey/job copy, selected filter context, status metrics, resource rows, and verb-plus-noun review actions."
  - "Support risky actions should name non-secret durable context and consequence inside the checkbox confirmation copy."
requirements-completed: [OPS-01, OPS-03, OPS-04, OPS-05]
duration: 8 min
completed: 2026-06-04
---

# Phase 109 Plan 01: Token Support Investigation Summary

**Support token investigation pages with redacted pivots, status metrics, mobile-safe resource rows, and separate guarded token/family revocation actions**

## Performance

- **Duration:** 8 min
- **Started:** 2026-06-04T08:09:00Z
- **Completed:** 2026-06-04T08:17:17Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments

- Reworked `/admin/tokens` around the Support journey, selected account/client/status context, status metrics, `Filter tokens`, and `Review token` resource rows.
- Added redacted client/account/family long-value pivots on token rows while preserving existing URL filters and `Admin.list_tokens/1`.
- Strengthened `/admin/tokens/:id` with a token health hero, long-value metadata, family resource rows, and separate consequence-specific `Revoke token` and `Revoke token family` confirmations.
- Extended focused token LiveView tests for journey labels, verb-plus-noun actions, long-value treatment, redaction, successful revocation, and missing-checkbox guards.

## Task Commits

1. **Task 1: Recompose the token index as a Support investigation surface** - `bcb7853` (feat)
2. **Task 2: Strengthen token detail health and revocation context** - `bcb7853` (feat)

**Plan metadata:** pending summary commit

## Files Created/Modified

- `lib/lockspire/web/live/admin/tokens_live/index.ex` - Adds Support hero, selected filters, metrics, redacted long-value pivots, and resource-row review actions.
- `lib/lockspire/web/live/admin/tokens_live/show.ex` - Adds token health hero, long-value detail/family context, and stronger separate revocation confirmations.
- `test/lockspire/web/live/admin/tokens_live_test.exs` - Proves Support labels, action copy, redaction, long values, and revoke guard behavior.

## Decisions Made

- Used `Lockspire.Redaction.handle/2` on the token index because list entries expose raw domain tokens while token detail already receives redacted display handles from `Lockspire.Admin`.
- Kept both revoke event names and Admin APIs unchanged to preserve protocol/storage behavior.

## Deviations from Plan

None - plan executed exactly as written.

**Total deviations:** 0 auto-fixed.
**Impact on plan:** No scope creep.

## Issues Encountered

- The first focused test run exposed a list/detail shape mismatch: token index rows assumed detail-only `client_handle`, `account_handle`, and `family_handle` fields. Fixed by deriving redacted handles in the index through `Lockspire.Redaction`.

## Verification

- `mix test test/lockspire/web/live/admin/tokens_live_test.exs test/lockspire/web/live/admin/design_system_contract_test.exs --max-failures 1` - passed, 16 tests, 0 failures.
- `MIX_ENV=test mix compile --warnings-as-errors` - passed.
- Source acceptance checks for required labels, primitives, filter fields, `Admin.list_tokens/1`, separate revoke forms, and family consequence copy - passed.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Ready for Plan 109-02. The token Support pattern is now available as the nearest analog for consent grant investigation.

---
*Phase: 109-weak-spot-page-polish*
*Completed: 2026-06-04*
