---
phase: 109-weak-spot-page-polish
plan: 05
subsystem: ui
tags: [phoenix-liveview, admin-ui, keys, clients, action-grouping]
requires:
  - phase: 108-design-system-token-component-upgrade
    provides: Phase 108 resource rows, long-value, metric, confirmation, and action-group primitives
provides:
  - Key lifecycle inventory with Configure context, posture metrics, resource rows, and long-value key metadata
  - Key detail pages with description-list metadata and confirmation copy that names lifecycle consequences
  - Client detail action groups separated by routine configuration, credential/RAT rotation, DCR context, endpoints/logout, posture, and lifecycle risk
affects: [phase-109, phase-110, admin-configure-ui]
tech-stack:
  added: []
  patterns: [AdminComponents.page_hero, AdminComponents.metric_grid, AdminComponents.resource_item, AdminComponents.long_value, AdminComponents.confirmation_panel, AdminComponents.action_group]
key-files:
  created: []
  modified:
    - lib/lockspire/web/live/admin/keys_live/index.ex
    - lib/lockspire/web/live/admin/keys_live/show.ex
    - lib/lockspire/web/live/admin/keys_live/action_component.ex
    - lib/lockspire/web/live/admin/clients_live/show.ex
    - test/lockspire/web/live/admin/keys_live_test.exs
    - test/lockspire/web/live/admin/clients_live/show_test.exs
key-decisions:
  - "Key lifecycle inventory now presents key posture as an operator review surface rather than a flat key list."
  - "Client RAT rotation lives in the credential/RAT action group; the self-registered DCR card now points operators back to that grouped action instead of duplicating the link."
patterns-established:
  - "Key lifecycle pages should use long-value treatment for public key handles, database handles, kids, and timestamps while keeping private material absent."
  - "Client detail pages should group actions by workflow and risk instead of presenting one dense mixed action strip."
requirements-completed: [CONFIG-01, CONFIG-02, OPS-03, OPS-04]
duration: 6 min
completed: 2026-06-04
---

# Phase 109 Plan 05: Keys And Client Actions Summary

**Key lifecycle and client-detail actions now have clearer Configure context, mobile-safe identifiers, and risk-separated action grouping**

## Performance

- **Duration:** 6 min
- **Started:** 2026-06-04T08:27:45Z
- **Completed:** 2026-06-04T08:33:19Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments

- Reworked `/admin/keys` around Configure journey copy, `Review key lifecycle`, lifecycle posture metrics, shared resource rows, long-value key/timestamp metadata, and JWKS visibility labels.
- Reworked `/admin/keys/:id` to use shared description-list, status, timestamp, and long-value primitives for public key metadata without exposing private key material.
- Tightened key publish/activate/retire confirmation copy so operators see key handle, use, and signing/encryption or publication-overlap consequences before mutation.
- Replaced the client detail flat action strip with action groups for routine configuration, credential/RAT rotation, DCR context, endpoint/logout settings, PAR/security posture, and lifecycle/destructive actions.
- Added focused tests for key lifecycle posture, guarded key confirmations, client action grouping, RAT visibility for self-registered clients, DCR link reachability, and destructive separation.

## Task Commits

1. **Task 1: Tighten key lifecycle posture and safe actions** - `173b7d6` (feat)
2. **Task 2: Group client-detail actions by workflow and risk** - `173b7d6` (feat)

**Plan metadata:** pending summary commit

## Files Created/Modified

- `lib/lockspire/web/live/admin/keys_live/index.ex` - Adds Configure hero, lifecycle metrics, resource rows, long-value metadata, and lifecycle review labels.
- `lib/lockspire/web/live/admin/keys_live/show.ex` - Adds Configure hero and structured public key metadata with long-value/timestamp treatment.
- `lib/lockspire/web/live/admin/keys_live/action_component.ex` - Updates existing confirmation panels with consequence-specific publish, activate, and retire copy.
- `lib/lockspire/web/live/admin/clients_live/show.ex` - Splits client actions into workflow/risk groups and removes duplicate RAT action from the DCR card.
- `test/lockspire/web/live/admin/keys_live_test.exs` - Proves key posture copy, resource rows, long values, and guarded lifecycle confirmations.
- `test/lockspire/web/live/admin/clients_live/show_test.exs` - Proves grouped action labels, DCR reachability, RAT branch visibility, and destructive separation.

## Decisions Made

- Preserved key events `generate`, `publish_key`, `activate_key`, and `retire_key`, and client events `save_client`, `rotate_secret`, `rotate_rat`, `acknowledge_rat`, and `toggle_client`.
- Kept existing `show_path/2` route targets and copy-once secret/RAT flows intact.
- Removed the duplicate self-registered RAT action bar because the same route is now presented in the credential/RAT action group.

## Deviations from Plan

- Added `lib/lockspire/web/live/admin/keys_live/action_component.ex` to the modified file set. The plan required improved publish/activate/retire confirmation copy, and the existing confirmation panels live in this component rather than in `keys_live/show.ex`.

**Total deviations:** 1 auto-fixed.
**Impact on plan:** No scope creep; the edit stayed inside the existing key lifecycle UI boundary and preserved event names/APIs.

## Issues Encountered

- The initial key detail assertion checked activate confirmation copy after activation had already consumed the panel. Moved the assertion to the post-publish, pre-activate render state where the copy is visible.

## Verification

- `mix test test/lockspire/web/live/admin/keys_live_test.exs test/lockspire/web/live/admin/clients_live/show_test.exs test/lockspire/web/live/admin/design_system_contract_test.exs --max-failures 1` - passed, 30 tests, 0 failures.
- `MIX_ENV=test mix compile --warnings-as-errors` - passed.
- Source acceptance checks for key Configure/resource/long-value primitives, key lifecycle confirmation copy, client action groups, route helpers, and preserved event names - passed.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Ready for Plan 109-06. The remaining work is to add deterministic weak-spot regressions to the design-system contract suite so these page-level polish fixes remain fenced.

---
*Phase: 109-weak-spot-page-polish*
*Completed: 2026-06-04*
