---
phase: 122-support-investigation-flow-polish
plan: 01
subsystem: ui
tags: [phoenix-liveview, admin-ui, support-workflows, tokens, consents, redaction]

requires:
  - phase: 121-route-scorecards-judgment-contract
    provides: Route scorecards and judgment contracts for admin support surfaces
provides:
  - Token investigation index with decision summary before filters and dense redaction-safe rows
  - Consent investigation index with decision summary before filters and dense redaction-safe rows
  - Route/source contract coverage requiring dense rows for token and consent support indexes
affects: [122-support-investigation-flow-polish, 123-support-detail-polish, 124-admin-support-uat]

tech-stack:
  added: []
  patterns:
    - Existing Phoenix LiveView modules with private presentation helpers
    - AdminComponents.decision_summary for support workflow decisions
    - AdminComponents.dense_resource_row with long_value for redaction-safe dense lists

key-files:
  created:
    - .planning/phases/122-support-investigation-flow-polish/122-01-SUMMARY.md
  modified:
    - lib/lockspire/web/live/admin/tokens_live/index.ex
    - lib/lockspire/web/live/admin/consents_live/index.ex
    - test/lockspire/web/live/admin/tokens_live_test.exs
    - test/lockspire/web/live/admin/consents_live_test.exs
    - test/lockspire/web/live/admin/design_system_contract_test.exs

key-decisions:
  - "Kept token and consent index behavior inside the existing LiveViews and existing Lockspire.Admin list APIs."
  - "Used decision_summary and dense_resource_row instead of adding a new support-row component or table primitive."
  - "Kept raw filter values editable in filter inputs while summaries and rows render redacted account/client/family handles."

patterns-established:
  - "Support index spine: page hero, decision summary, filters, then dense rows."
  - "Index rows lead with operator decision state, then redacted pivots and timestamps."
  - "Source contracts assert dense_resource_row for token and consent support indexes."

requirements-completed: [SUPPORT-01, SUPPORT-02, SUPPORT-03]

duration: 11m45s
completed: 2026-06-28
status: complete
---

# Phase 122 Plan 01: Support Index Flow Summary

**Token and consent Support indexes now lead with decision summaries and redaction-safe dense rows before investigation actions.**

## Performance

- **Duration:** 11m45s
- **Started:** 2026-06-28T21:36:39Z
- **Completed:** 2026-06-28T21:48:24Z
- **Tasks:** 3
- **Files modified:** 5

## Accomplishments

- Added RED route/source coverage for token and consent index decision labels, dense row classes, long-value wrapping, empty states, and forbidden secret material.
- Converted `/admin/tokens` to a support workflow spine: hero, decision summary, filters, and dense token rows using redacted account/client/family handles.
- Converted `/admin/consents` to the same decision-first structure with grant status, scope context, and dense stored-grant rows.
- Updated the design-system source contract so token and consent support indexes require `AdminComponents.dense_resource_row`.

## Task Commits

Each task was committed atomically:

1. **Task 1: Expand Support index tests and dense-row source contract** - `f445e46` (test)
2. **Task 2: Convert token index to decision-first dense rows** - `7f15950` (feat)
3. **Task 3: Convert consent index and update dense-row source contract** - `13149b1` (feat)

## Files Created/Modified

- `.planning/phases/122-support-investigation-flow-polish/122-01-SUMMARY.md` - Execution summary and verification evidence.
- `lib/lockspire/web/live/admin/tokens_live/index.ex` - Token decision summary helpers, redacted selected filter display, dense token rows, and Support empty-state copy.
- `lib/lockspire/web/live/admin/consents_live/index.ex` - Consent decision summary helpers, redacted selected filter display, dense consent rows, and Support empty-state copy.
- `test/lockspire/web/live/admin/tokens_live_test.exs` - Token index rendered proof for summary labels, dense rows, redaction, long values, and no-match state.
- `test/lockspire/web/live/admin/consents_live_test.exs` - Consent index rendered proof for summary labels, dense rows, redaction, long values, and no-match state.
- `test/lockspire/web/live/admin/design_system_contract_test.exs` - Source contract requiring dense rows for token and consent indexes.

## Decisions Made

- Kept all data access through the existing `Admin.list_tokens/1` and `Admin.list_consents/1` delegations.
- Reused existing AdminComponents primitives rather than adding public component API or CSS.
- Redacted account, client, and family pivots in summaries and rows while preserving raw filter values inside editable form controls.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Decision summary slots needed explicit bodies**
- **Found during:** Task 2 (Convert token index to decision-first dense rows)
- **Issue:** Self-closing `decision_summary` item slots tripped the existing component's inner-block handling.
- **Fix:** Rendered each summary item with explicit opening and closing slot tags.
- **Files modified:** `lib/lockspire/web/live/admin/tokens_live/index.ex`, `lib/lockspire/web/live/admin/consents_live/index.ex`
- **Verification:** Focused token/consent/design-system tests passed.
- **Committed in:** `7f15950` and `13149b1`

**2. [Rule 1 - Bug] Source-order assertions matched CSS before rendered markup**
- **Found during:** Task 2 (Convert token index to decision-first dense rows)
- **Issue:** The initial test looked for class names globally, which could match CSS before rendered DOM order.
- **Fix:** Asserted source order using concrete rendered `<dl>` and `<form>` fragments.
- **Files modified:** `test/lockspire/web/live/admin/tokens_live_test.exs`, `test/lockspire/web/live/admin/consents_live_test.exs`
- **Verification:** Focused token/consent/design-system tests passed.
- **Committed in:** `7f15950` and `13149b1`

---

**Total deviations:** 2 auto-fixed Rule 1 issues
**Impact on plan:** Both fixes were local correctness adjustments for the planned support index behavior. No new routes, storage, CSS, public component APIs, package installs, or unsupported capabilities were added.

## Issues Encountered

- The working tree contained unrelated dirty files before execution. Plan-scoped files were staged individually; unrelated changes were preserved and not committed.

## Known Stubs

None. Stub-pattern matches in the touched design-system contract are existing guard-value constants; empty-list branches in the LiveViews are real no-result states, not placeholder data.

## Threat Flags

None. This plan added no endpoints, auth paths, file access, schemas, migrations, or trust-boundary changes.

## Verification

- `MIX_ENV=test mix test test/lockspire/web/live/admin/tokens_live_test.exs test/lockspire/web/live/admin/consents_live_test.exs test/lockspire/web/live/admin/design_system_contract_test.exs --max-failures 3` - RED failed on planned missing dense-row/decision-summary assertions before implementation.
- `MIX_ENV=test mix test test/lockspire/web/live/admin/tokens_live_test.exs --max-failures 1` - PASS after token implementation.
- `MIX_ENV=test mix test test/lockspire/web/live/admin/tokens_live_test.exs test/lockspire/web/live/admin/consents_live_test.exs test/lockspire/web/live/admin/design_system_contract_test.exs --max-failures 1` - PASS, 56 tests, 0 failures.
- `mix format --check-formatted lib/lockspire/web/live/admin/tokens_live/index.ex lib/lockspire/web/live/admin/consents_live/index.ex test/lockspire/web/live/admin/tokens_live_test.exs test/lockspire/web/live/admin/consents_live_test.exs test/lockspire/web/live/admin/design_system_contract_test.exs` - PASS.
- Source guard: token and consent indexes contain `Admin.list_tokens/1`/`Admin.list_consents/1` and `AdminComponents.dense_resource_row`; they contain no `AdminComponents.resource_item`, raw `Repo`, schema/migration, bulk, reveal, export, debug, or index revoke controls.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plans 122-02 and 122-03 can build on the established support index spine for token and consent detail surfaces. The route/source contracts now enforce the dense-row primitive for these indexes.

## Self-Check: PASSED

- Found `.planning/phases/122-support-investigation-flow-polish/122-01-SUMMARY.md`.
- Found task commits `f445e46`, `7f15950`, and `13149b1` in git history.

---
*Phase: 122-support-investigation-flow-polish*
*Completed: 2026-06-28*
