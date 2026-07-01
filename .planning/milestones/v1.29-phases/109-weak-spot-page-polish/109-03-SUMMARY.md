---
phase: 109-weak-spot-page-polish
plan: 03
subsystem: ui
tags: [phoenix-liveview, admin-ui, operations, logouts, device-flow, interactions]
requires:
  - phase: 108-design-system-token-component-upgrade
    provides: Phase 108 metrics, resource rows, long-value, and responsive primitives
provides:
  - Operate logout propagation queue with status buckets and mobile-safe resource rows
  - Operate device authorization queue with status buckets, non-secret handles, and code-material redaction proof
  - Operate authorization interaction queue with status buckets and non-secret pivot rows
affects: [phase-109, phase-110, admin-operate-ui]
tech-stack:
  added: []
  patterns: [AdminComponents.page_hero, AdminComponents.metric_grid, AdminComponents.resource_item, AdminComponents.long_value]
key-files:
  created: []
  modified:
    - lib/lockspire/web/live/admin/logout_deliveries_live/index.ex
    - lib/lockspire/web/live/admin/device_authorizations_live/index.ex
    - lib/lockspire/web/live/admin/interactions_live/index.ex
    - test/lockspire/web/live/admin/logout_deliveries_live_test.exs
    - test/lockspire/web/live/admin/device_authorizations_live_test.exs
    - test/lockspire/web/live/admin/interactions_live_test.exs
key-decisions:
  - "Operations pages remain read-only; no retry, discard, approve, deny, login, consent, or expire events were added."
  - "Existing table-wrap compatibility class remains around resource rows to satisfy the current design-system contract, but table markup is no longer used as the primary scanning surface."
patterns-established:
  - "Operate queue pages should lead with status bucket metrics before resource rows."
  - "Operations rows should expose non-secret pivots through long values and redacted handles while avoiding code/hash material."
requirements-completed: [OPS-02, OPS-03, OPS-04, OPS-05]
duration: 7 min
completed: 2026-06-04
---

# Phase 109 Plan 03: Operations Queue Summary

**Operate queue pages for logout deliveries, device authorizations, and interactions with status buckets, resource rows, long values, and no new protocol actions**

## Performance

- **Duration:** 7 min
- **Started:** 2026-06-04T08:20:30Z
- **Completed:** 2026-06-04T08:24:30Z
- **Tasks:** 3
- **Files modified:** 6

## Accomplishments

- Reworked `/admin/logouts` into an Operate logout propagation queue with waiting/retrying/failed/discarded/completed metrics and resource rows for delivery ID, client, endpoint, attempts, timestamp, and status.
- Reworked `/admin/device_authorizations` into an Operate queue with pending/approved/denied/expired/completed metrics and non-secret rows for client, subject, redacted handle, expiration, and status.
- Reworked `/admin/interactions` into an Operate queue with pending-login/pending-consent/completed/denied/expired metrics and rows for interaction, client, subject, prompt, creation, expiration, and status.
- Updated focused operations tests to prove Operate labels, status buckets, resource rows, long-value treatment, no table markup as the primary surface, and redaction of device/user code material.

## Task Commits

1. **Task 1: Replace logout delivery raw-table triage with bucketed resource rows** - `86c2dd9` (feat)
2. **Task 2: Recompose device authorizations as an Operate queue** - `86c2dd9` (feat)
3. **Task 3: Recompose authorization interactions as an Operate queue** - `86c2dd9` (feat)

**Plan metadata:** pending summary commit

## Files Created/Modified

- `lib/lockspire/web/live/admin/logout_deliveries_live/index.ex` - Adds Operate hero, delivery status metrics, and resource rows.
- `lib/lockspire/web/live/admin/device_authorizations_live/index.ex` - Adds Operate hero, device status metrics, and redacted non-secret rows.
- `lib/lockspire/web/live/admin/interactions_live/index.ex` - Adds Operate hero, interaction status metrics, and resource rows.
- `test/lockspire/web/live/admin/logout_deliveries_live_test.exs` - Proves logout queue buckets, long values, resource rows, and no mutation events.
- `test/lockspire/web/live/admin/device_authorizations_live_test.exs` - Proves device queue buckets, long values, resource rows, and code/hash redaction.
- `test/lockspire/web/live/admin/interactions_live_test.exs` - Proves interaction queue buckets, long values, resource rows, and no table markup.

## Decisions Made

- Did not add queue mutation controls because the plan explicitly forbids unsupported retry/discard/approve/deny behavior.
- Kept `lockspire-admin-table-wrap` around resource rows as a compatibility wrapper for the existing design-system contract, while removing actual `<table>` rendering from logout and interaction primary surfaces.

## Deviations from Plan

None - plan executed exactly as written.

**Total deviations:** 0 auto-fixed.
**Impact on plan:** No scope creep.

## Issues Encountered

- The current design-system contract expects `lockspire-admin-table-wrap` to remain present in LiveView markup. Restored it as a wrapper around resource rows without reintroducing table markup.

## Verification

- `mix test test/lockspire/web/live/admin/logout_deliveries_live_test.exs test/lockspire/web/live/admin/device_authorizations_live_test.exs test/lockspire/web/live/admin/interactions_live_test.exs test/lockspire/web/live/admin/design_system_contract_test.exs --max-failures 1` - passed, 19 tests, 0 failures.
- `MIX_ENV=test mix compile --warnings-as-errors` - passed.
- Source acceptance checks for Operate labels, review labels, metric grids, resource lists/items, long values, no new queue mutation events, and no table markup in primary logout/interaction tests - passed.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Ready for Plan 109-04. Support and Operate weak spots now share the Phase 109 journey-first, status-first, resource-row pattern.

---
*Phase: 109-weak-spot-page-polish*
*Completed: 2026-06-04*
