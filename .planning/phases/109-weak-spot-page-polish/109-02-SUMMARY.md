---
phase: 109-weak-spot-page-polish
plan: 02
subsystem: ui
tags: [phoenix-liveview, admin-ui, consents, support, redaction]
requires:
  - phase: 109-weak-spot-page-polish
    provides: Plan 109-01 token Support investigation pattern
provides:
  - Support consent grant investigation index with URL filters, metrics, redacted pivots, and resource rows
  - Consent detail decision surface with guarded remembered-grant revocation copy
  - Focused LiveView proof for labels, scopes, long values, redaction, and revoke guards
affects: [phase-109, phase-110, admin-support-ui]
tech-stack:
  added: []
  patterns: [AdminComponents.page_hero, AdminComponents.resource_item, AdminComponents.long_value, AdminComponents.confirmation_panel]
key-files:
  created: []
  modified:
    - lib/lockspire/web/live/admin/consents_live/index.ex
    - lib/lockspire/web/live/admin/consents_live/show.ex
    - test/lockspire/web/live/admin/consents_live_test.exs
key-decisions:
  - "Consent list/detail pages use Lockspire.Redaction for durable account, client, and grant handles while still echoing selected URL filter values on the index."
  - "Consent revocation remains a single existing revoke_consent event with stronger non-secret consequence copy."
patterns-established:
  - "Support consent rows follow the token Support pattern: journey hero, selected filters, status metrics, resource rows, long values, and verb-plus-noun review actions."
  - "Remembered-grant revocation copy names client, subject, scopes, and future consent reuse consequence."
requirements-completed: [OPS-01, OPS-03, OPS-04, OPS-05]
duration: 5 min
completed: 2026-06-04
---

# Phase 109 Plan 02: Consent Support Investigation Summary

**Support consent grant investigation pages with filtered context, redacted pivots, scope visibility, and guarded remembered-grant revocation copy**

## Performance

- **Duration:** 5 min
- **Started:** 2026-06-04T08:17:50Z
- **Completed:** 2026-06-04T08:20:30Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments

- Reworked `/admin/consents` around Support journey copy, selected account/client/status context, active/revoked/matching metrics, `Filter consent grants`, and `Review stored grant` rows.
- Added redacted long-value account/client pivots, scope context, and relevant grant timestamp context while preserving existing URL filters and `Admin.list_consents/1`.
- Strengthened `/admin/consents/:id` with a stored-grant decision hero, long-value grant/account/client metadata, scope context, and consequence-specific `Revoke consent grant` confirmation copy.
- Extended focused consent LiveView tests for journey labels, verb-plus-noun actions, scope/status pivots, long values, secret absence, successful revoke, and missing-checkbox guard behavior.

## Task Commits

1. **Task 1: Recompose the consent index as a Support grant investigation surface** - `a72ed2f` (feat)
2. **Task 2: Strengthen consent detail grant decision and revoke context** - `a72ed2f` (feat)

**Plan metadata:** pending summary commit

## Files Created/Modified

- `lib/lockspire/web/live/admin/consents_live/index.ex` - Adds Support hero, selected filters, metrics, redacted long-value pivots, and resource-row review actions.
- `lib/lockspire/web/live/admin/consents_live/show.ex` - Adds stored-grant decision hero, long-value detail context, and stronger revoke confirmation copy.
- `test/lockspire/web/live/admin/consents_live_test.exs` - Proves Support labels, action copy, scopes, long values, redaction, and revoke guard behavior.

## Decisions Made

- Preserved raw selected URL filter values in the index hero because the plan requires selected filter context, while row/detail durable identifiers use redacted handles.
- Kept `revoke_consent` and `Admin.revoke_consent/2` unchanged; the work is presentation/copy only.

## Deviations from Plan

None - plan executed exactly as written.

**Total deviations:** 0 auto-fixed.
**Impact on plan:** No scope creep.

## Issues Encountered

- The first focused test over-constrained index redaction by refuting the selected account filter value that the page is required to display. Narrowed that assertion to secret/token material while keeping detail content redacted.

## Verification

- `mix test test/lockspire/web/live/admin/consents_live_test.exs test/lockspire/web/live/admin/design_system_contract_test.exs --max-failures 1` - passed, 16 tests, 0 failures.
- `MIX_ENV=test mix compile --warnings-as-errors` - passed.
- Source acceptance checks for required labels, primitives, filter fields, `Admin.list_consents/1`, `revoke_consent`, and remembered-grant consequence copy - passed.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Ready for Plan 109-03. Token and consent Support pages now share the intended investigation pattern for Phase 109 contract fencing.

---
*Phase: 109-weak-spot-page-polish*
*Completed: 2026-06-04*
