---
phase: 124-configure-onboarding-propagation-pass
plan: "01"
subsystem: ui
tags:
  - phoenix-liveview
  - admin-ui
  - oauth-clients
  - copy-once-credentials

requires:
  - phase: 121-route-scorecards-judgment-contract
    provides: Configure route scorecards and decision contract
  - phase: 122-support-investigation-flow-polish
    provides: Support route hierarchy and action semantics
  - phase: 123-operate-queue-flow-polish
    provides: Operate route hierarchy and copy discipline patterns
provides:
  - Client inventory Configure hierarchy with selected context and matching/total counts
  - Client detail posture, grouped action, lifecycle confirmation, and redacted RAT posture
  - Copy-once consequence copy for client creation, secret rotation, and RAT rotation
affects:
  - configure-onboarding-propagation
  - admin-client-liveviews
  - plan-124-06-cross-route-contracts

tech-stack:
  added: []
  patterns:
    - Existing Phoenix LiveView route-local rendering
    - Existing Lockspire.Admin and protocol mutation APIs only
    - AdminComponents page_hero, section_card, action_group, confirmation_panel, and copy_once_secret_panel

key-files:
  created:
    - .planning/phases/124-configure-onboarding-propagation-pass/124-01-SUMMARY.md
  modified:
    - lib/lockspire/web/live/admin/clients_live/index.ex
    - lib/lockspire/web/live/admin/clients_live/form_component.ex
    - lib/lockspire/web/live/admin/clients_live/show.ex
    - lib/lockspire/web/live/admin/clients_live/rotate_secret_component.ex
    - test/lockspire/web/live/admin/clients_live_test.exs
    - test/lockspire/web/live/admin/clients_live/show_test.exs

key-decisions:
  - "Kept client Configure propagation inside existing LiveViews, Lockspire.Admin calls, and protocol rotation calls."
  - "Used immediate copy-once panels for plaintext client secret/RAT values while durable inventory/detail surfaces remain redacted."
  - "Rendered selected filter context and inventory counts before dense client rows so operators see the current decision frame first."

patterns-established:
  - "Configure client inventory starts with page_hero plus selected context before table density."
  - "Credential rotation copy names the concrete consequence: prior credential stops being current and plaintext is shown once."
  - "Durable self-registered client detail shows RAT posture as redacted state, never a hash or plaintext value."

requirements-completed:
  - CONFIG-01
  - CONFIG-02
  - CONFIG-03

duration: 10m
completed: 2026-06-30
status: complete
---

# Phase 124 Plan 01: Client Configure Propagation Summary

**Client Configure inventory/detail hierarchy with selected context, grouped lifecycle actions, redacted durable credential posture, and copy-once secret/RAT handoff copy**

## Performance

- **Duration:** 10 min
- **Started:** 2026-06-29T23:59:43Z
- **Completed:** 2026-06-30T00:09:10Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments

- Added RED coverage for client inventory Configure hierarchy, selected context, filter copy, create copy-once handoff, client detail action grouping, lifecycle confirmation, RAT redaction, and credential/RAT rotation copy.
- Updated client inventory to lead with Configure context, matching/total client counts, `Filter clients`, and `Create client` copy while preserving `Lockspire.Admin.create_client/1`.
- Updated client detail and rotation surfaces to preserve existing mutation paths while rendering grouped actions, inline lifecycle confirmation, redacted durable RAT posture, and copy-once consequence copy.

## Task Commits

| Task | Name | Commit | Files |
| --- | --- | --- | --- |
| 124-01-01 | Add client Configure hierarchy and handoff proof | `551999c` | `test/lockspire/web/live/admin/clients_live_test.exs`, `test/lockspire/web/live/admin/clients_live/show_test.exs` |
| 124-01-02 | Implement client Configure hierarchy, labels, and copy-once consequences | `a90336e` | `lib/lockspire/web/live/admin/clients_live/index.ex`, `lib/lockspire/web/live/admin/clients_live/form_component.ex`, `lib/lockspire/web/live/admin/clients_live/show.ex`, `lib/lockspire/web/live/admin/clients_live/rotate_secret_component.ex`, `test/lockspire/web/live/admin/clients_live_test.exs` |

## Files Created/Modified

- `.planning/phases/124-configure-onboarding-propagation-pass/124-01-SUMMARY.md` - Execution record, verification evidence, deviations, and self-check.
- `lib/lockspire/web/live/admin/clients_live/index.ex` - Client inventory Configure hero/context, matching/total counts, `Filter clients`, `Create client`, and copy-once create handoff copy.
- `lib/lockspire/web/live/admin/clients_live/form_component.ex` - Route-specific create form title changed to `Create client`; unrelated dirty form-field hunk preserved unstaged.
- `lib/lockspire/web/live/admin/clients_live/show.ex` - Client detail lifecycle confirmation, redacted RAT posture, grouped action semantics, and RAT copy-once consequence copy.
- `lib/lockspire/web/live/admin/clients_live/rotate_secret_component.ex` - Client secret rotation consequence copy and `Rotate client secret` submit label.
- `test/lockspire/web/live/admin/clients_live_test.exs` - Inventory/create assertions for Configure context and copy-once handoff.
- `test/lockspire/web/live/admin/clients_live/show_test.exs` - Detail/lifecycle/RAT/credential assertions for redaction and consequence copy.

## Decisions Made

- Kept all behavior within existing client LiveViews and existing `Lockspire.Admin` / protocol functions; no public route, Admin API, schema, migration, package, lab, or host-owned seam was added.
- Treated the existing dirty lifecycle confirmation work in `clients_live/show.ex` and `show_test.exs` as plan-relevant because Plan 124 explicitly required inline confirmation and `name="toggle[confirm]"` proof.
- Left the pre-existing `form_component.ex` form-field refactor hunk unstaged because it was unrelated to the Phase 124 title/copy requirement.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Test correctness] Removed selector-class absence assertion**
- **Found during:** Task 124-01-02
- **Issue:** The RED test asserted `lockspire-admin-copy-once-secret__value` was absent before creation, but the class appears in inline admin CSS even when the copy-once panel is not rendered.
- **Fix:** Removed the class-string absence check and retained visible-content assertions that deny `Client secret` before create and assert copy-once output only after create.
- **Files modified:** `test/lockspire/web/live/admin/clients_live_test.exs`
- **Verification:** Focused client LiveView suite passed.
- **Committed in:** `a90336e`

**2. [Rule 1 - Test fixture correctness] Used a valid DCR scope in create-client proof**
- **Found during:** Task 124-01-02
- **Issue:** The create-client proof submitted `openid email`, but the existing DCR policy in this fixture accepts `email`; the test failed before exercising the copy-once success path.
- **Fix:** Changed the submitted allowed scope to `email` so the test validates the planned copy-once behavior through the existing Admin API.
- **Files modified:** `test/lockspire/web/live/admin/clients_live_test.exs`
- **Verification:** Focused client LiveView suite passed.
- **Committed in:** `a90336e`

---

**Total deviations:** 2 auto-fixed Rule 1 issues.
**Impact on plan:** No scope expansion. Both fixes corrected test shape/fixture setup so the planned behavior was exercised through existing boundaries.

## Issues Encountered

- The repo had many pre-existing dirty and untracked files. Only Phase 124 hunks were staged; unrelated dirty work was preserved.
- `lib/lockspire/web/live/admin/clients_live/form_component.ex` remains dirty after this plan because a pre-existing `AdminComponents.form_field` refactor hunk was intentionally left unstaged.
- The focused test command emits a pre-existing KeyCache startup log about `Lockspire.TestRepo` not being started before the suite initializes. The test command exits successfully.

## Known Stubs

None. Stub scan only found an existing empty select option value used for a normal form choice.

## Threat Flags

None. The diff is limited to existing client LiveViews/components/tests and does not add routes, public APIs, schema changes, migrations, packages, file access, auth paths, or host-owned seams.

## Verification Results

- `MIX_ENV=test mix test test/lockspire/web/live/admin/clients_live_test.exs test/lockspire/web/live/admin/clients_live/show_test.exs --max-failures 1` failed in RED on the newly asserted `Selected client context` expectation.
- `mix format --check-formatted test/lockspire/web/live/admin/clients_live_test.exs test/lockspire/web/live/admin/clients_live/show_test.exs` passed after RED formatting.
- `MIX_ENV=test mix test test/lockspire/web/live/admin/clients_live_test.exs test/lockspire/web/live/admin/clients_live/show_test.exs --max-failures 1` passed after implementation: 30 tests, 0 failures.
- `mix format --check-formatted lib/lockspire/web/live/admin/clients_live/index.ex lib/lockspire/web/live/admin/clients_live/form_component.ex lib/lockspire/web/live/admin/clients_live/show.ex lib/lockspire/web/live/admin/clients_live/rotate_secret_component.ex test/lockspire/web/live/admin/clients_live_test.exs test/lockspire/web/live/admin/clients_live/show_test.exs` passed.

## TDD Gate Compliance

- RED gate commit present: `551999c test(124-01): add failing client configure coverage`
- GREEN gate commit present after RED: `a90336e feat(124-01): implement client configure hierarchy`
- Refactor gate: not needed.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 124-01 is ready for later Phase 124 route-local propagation plans and Plan 124-06 cross-route contract verification. The client route keeps existing Admin/protocol boundaries and provides focused tests for Configure hierarchy, action semantics, and copy-once handoff.

## Self-Check: PASSED

- Found summary file: `.planning/phases/124-configure-onboarding-propagation-pass/124-01-SUMMARY.md`
- Found key modified files: `lib/lockspire/web/live/admin/clients_live/index.ex`, `lib/lockspire/web/live/admin/clients_live/show.ex`
- Found task commits: `551999c`, `a90336e`

---

*Phase: 124-configure-onboarding-propagation-pass*
*Completed: 2026-06-30*
