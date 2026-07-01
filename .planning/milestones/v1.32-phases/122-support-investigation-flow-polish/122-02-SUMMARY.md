---
phase: 122-support-investigation-flow-polish
plan: 02
subsystem: ui
tags: [phoenix-liveview, admin-ui, support-workflows, tokens, redaction]

requires:
  - phase: 122-support-investigation-flow-polish
    provides: Token and consent support index decision-first dense-row pattern from Plan 122-01
provides:
  - Token detail decision summary before long metadata panes
  - Explicit revoked, expired, reuse-detected, and no-family action-state predicates
  - Accessible token and refresh-family confirmation errors with locked support copy
affects: [122-support-investigation-flow-polish, 123-operate-queue-flow-polish, 125-browser-proof-docs-adversarial-ratchet]

tech-stack:
  added: []
  patterns:
    - Existing Phoenix LiveView detail route with private presentation helpers
    - AdminComponents.decision_summary before detail panes
    - AdminComponents.confirmation_panel errors with disabled AdminComponents.admin_button controls

key-files:
  created:
    - .planning/phases/122-support-investigation-flow-polish/122-02-SUMMARY.md
  modified:
    - lib/lockspire/web/live/admin/tokens_live/show.ex
    - test/lockspire/web/live/admin/tokens_live_test.exs

key-decisions:
  - "Kept token detail reads and mutations behind existing Lockspire.Admin get/revoke delegations."
  - "Derived token detail closed UI from explicit revoked_at, expires_at, reuse_detected_at, and family-presence predicates instead of status-only checks."
  - "Used existing decision_summary, confirmation_panel, error_list, long_value, timestamp, and disabled admin_button primitives rather than adding shared components or CSS."

patterns-established:
  - "Token detail spine: page hero, entity header, decision summary, then identity, lineage, and corrective-action panes."
  - "Closed destructive actions remain visible but disabled with adjacent consequence copy."
  - "Family revocation copy describes currently unrevoked refresh-family records without implying host logout, account suspension, consent revocation, worker control, or plaintext recovery."

requirements-completed: [SUPPORT-01, SUPPORT-03]

duration: 7m23s
completed: 2026-06-28
status: complete
---

# Phase 122 Plan 02: Token Detail Investigation Flow Summary

**Token detail now leads with health, family lineage, reuse pressure, and smallest safe action before metadata or revocation controls.**

## Performance

- **Duration:** 7m23s
- **Started:** 2026-06-28T21:54:42Z
- **Completed:** 2026-06-28T22:02:05Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- Added RED LiveView coverage for token detail decision-summary labels, missing-checkbox errors, backend failure copy, revoked/expired/no-family/reuse-detected states, and disabled destructive controls.
- Added token detail decision summary immediately after the entity header and before long identity/lineage panes.
- Reworked single-token and refresh-family revocation panels to use locked copy, existing confirmation-panel error rendering, and disabled controls for closed or impossible states.

## Task Commits

Each task was committed atomically:

1. **Task 1: Expand token detail tests for decision and closed states** - `8e72b36` (test)
2. **Task 2: Implement token detail decision summary and confirmation states** - `977281d` (feat)

## Files Created/Modified

- `.planning/phases/122-support-investigation-flow-polish/122-02-SUMMARY.md` - Execution summary and verification evidence.
- `test/lockspire/web/live/admin/tokens_live_test.exs` - RED and GREEN proof for token detail summaries, locked copy, closed states, and rendered error primitives.
- `lib/lockspire/web/live/admin/tokens_live/show.ex` - Token detail decision summary, explicit state predicates, accessible confirmation errors, disabled action states, and precise family consequence copy.

## Decisions Made

- Kept all token detail reads and mutations through `Lockspire.Admin.get_token/1`, `Lockspire.Admin.revoke_token/2`, and `Lockspire.Admin.revoke_token_family/2`.
- Used private LiveView presentation helpers for token health, family lineage, reuse pressure, smallest safe action, and closed-state predicates.
- Reused existing AdminComponents primitives; no new component, CSS, route, schema, storage, package, reveal/export/debug, or bulk-action surface was added.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- The working tree contained unrelated dirty files before execution. Plan-scoped files were staged individually; unrelated changes were preserved and not committed.
- Focused test runs log an existing KeyCache repo lookup message before the ExUnit sandbox starts; the focused token suite still exits successfully with 0 failures.

## Known Stubs

None. Stub-pattern scan found only a real empty-string predicate in a private family-presence helper.

## Threat Flags

None. This plan added no endpoints, auth paths, file access, schemas, migrations, package dependencies, or new trust-boundary surfaces.

## Verification

- `MIX_ENV=test mix test test/lockspire/web/live/admin/tokens_live_test.exs --max-failures 3` - RED failed on planned missing token detail decision summary and closed-state copy before implementation.
- `MIX_ENV=test mix test test/lockspire/web/live/admin/tokens_live_test.exs --max-failures 1` - PASS, 4 tests, 0 failures.
- `mix format --check-formatted lib/lockspire/web/live/admin/tokens_live/show.ex test/lockspire/web/live/admin/tokens_live_test.exs` - PASS.
- Source guard: token detail uses `Admin.get_token/1`, `Admin.revoke_token/2`, `Admin.revoke_token_family/2`, `AdminComponents.decision_summary`, and `AdminComponents.confirmation_panel`; no raw `Repo`/`Repository`, schema, migration, route, package, reveal, export, debug, bulk action, or overbroad family-copy claim was introduced.

## TDD Gate Compliance

- RED commit present: `8e72b36` (`test(122-02): add failing token detail closed-state coverage`)
- GREEN commit present after RED: `977281d` (`feat(122-02): polish token detail investigation actions`)
- REFACTOR commit: not needed; no behavior-neutral cleanup pass was required after GREEN.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 122-03 can apply the same detail-page pattern to consent grants: decision summary first, exact locked confirmation copy, disabled closed states, and existing AdminComponents primitives.

## Self-Check: PASSED

- Found `.planning/phases/122-support-investigation-flow-polish/122-02-SUMMARY.md`.
- Found `lib/lockspire/web/live/admin/tokens_live/show.ex`.
- Found `test/lockspire/web/live/admin/tokens_live_test.exs`.
- Found task commits `8e72b36` and `977281d` in git history.

---
*Phase: 122-support-investigation-flow-polish*
*Completed: 2026-06-28*
