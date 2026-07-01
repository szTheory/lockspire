---
phase: 122-support-investigation-flow-polish
plan: 03
subsystem: ui
tags: [phoenix-liveview, admin-ui, support-workflows, consents, redaction]

requires:
  - phase: 122-support-investigation-flow-polish
    provides: Token/consent support index pattern from Plan 122-01 and token detail closed-state pattern from Plan 122-02
provides:
  - Consent detail decision summary before long metadata panes
  - Locked consent revocation confirmation, failure, and already-revoked copy
  - Accessible confirmation-panel errors and disabled closed-state controls
affects: [122-support-investigation-flow-polish, 123-operate-queue-flow-polish, 125-browser-proof-docs-adversarial-ratchet]

tech-stack:
  added: []
  patterns:
    - Existing Phoenix LiveView detail route with private presentation helpers
    - AdminComponents.decision_summary before detail panes
    - AdminComponents.confirmation_panel errors with disabled AdminComponents.admin_button controls

key-files:
  created:
    - .planning/phases/122-support-investigation-flow-polish/122-03-SUMMARY.md
    - .planning/phases/122-support-investigation-flow-polish/deferred-items.md
  modified:
    - lib/lockspire/web/live/admin/consents_live/show.ex
    - test/lockspire/web/live/admin/consents_live_test.exs

key-decisions:
  - "Kept consent detail reads and mutation behind existing Lockspire.Admin get/revoke delegations."
  - "Derived consent closed-state UI from the remembered grant status with locked copy and disabled controls."
  - "Limited revocation consequence copy to future remembered-consent reuse without implying host account, session, token, plaintext, worker, or broader protocol effects."

patterns-established:
  - "Consent detail spine: page hero, entity header, decision summary, durable grant panes, then inline confirmation."
  - "Already-revoked remembered grants remain visible but closed with disabled checkbox/button semantics."
  - "Consent detail summaries use redacted client/account pivots and long_value wrapping for scope context."

requirements-completed: [SUPPORT-02, SUPPORT-03]

duration: 5m
completed: 2026-06-28
status: complete
---

# Phase 122 Plan 03: Consent Detail Investigation Flow Summary

**Consent detail now leads with grant status, scope context, redacted pivots, and remembered-grant revocation consequence before metadata or actions.**

## Performance

- **Duration:** 5m
- **Started:** 2026-06-28T22:09:37Z
- **Completed:** 2026-06-28T22:14:23Z
- **Tasks:** 2
- **Files modified:** 2 source/test files plus 2 planning artifacts

## Accomplishments

- Added RED coverage for consent detail decision-summary labels, source order, locked confirmation/failure copy, long scopes, redacted pivots, and disabled already-revoked controls.
- Added a consent detail decision summary immediately after the entity header and before long durable-grant metadata panes.
- Reworked the revoke panel to use existing confirmation-panel error rendering and disabled closed-state semantics with exact remembered-consent copy.

## Task Commits

Each task was committed atomically:

1. **Task 1: Expand consent detail tests for decision and revoked states** - `cd31178` (test)
2. **Task 2: Implement consent detail decision summary and revoke panel states** - `ce8fcf0` (feat)

## Files Created/Modified

- `.planning/phases/122-support-investigation-flow-polish/122-03-SUMMARY.md` - Execution summary and verification evidence.
- `.planning/phases/122-support-investigation-flow-polish/deferred-items.md` - Out-of-scope full-suite failure note for pre-existing Phase 115 adoption-demo dirty work.
- `test/lockspire/web/live/admin/consents_live_test.exs` - RED and GREEN proof for consent detail summaries, locked copy, redaction, long scopes, accessible errors, and disabled closed states.
- `lib/lockspire/web/live/admin/consents_live/show.ex` - Consent detail decision summary, exact revoke copy, confirmation-panel errors, redacted pivots, and already-revoked disabled controls.

## Decisions Made

- Kept all consent detail reads and mutations through `Lockspire.Admin.get_consent/1` and `Lockspire.Admin.revoke_consent/2`.
- Used private LiveView presentation helpers for grant status, scope context, client/account pivot, revocation consequence, and closed-state predicates.
- Reused existing AdminComponents primitives; no new component, CSS, route, schema, storage, package, reveal/export/debug, or bulk-action surface was added.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- The working tree contained unrelated dirty files before execution. Plan-scoped files were staged individually; unrelated changes were preserved and not committed.
- `MIX_ENV=test mix test.fast --max-failures 5` still fails in `Lockspire.ReleaseReadinessContractTest` against Phase 115 adoption-demo documentation and lifecycle script contracts. Those files were already dirty before this plan and are outside 122-03 scope; details are recorded in `deferred-items.md`.
- Focused test runs log an existing KeyCache repo lookup message before the ExUnit sandbox starts; the focused consent and Phase 122 gate suites still exit successfully with 0 failures.

## Known Stubs

None. Stub-pattern scan found only a real no-scopes empty-list branch in a private summary helper.

## Threat Flags

None. This plan added no endpoints, auth paths, file access, schemas, migrations, package dependencies, or new trust-boundary surfaces.

## Verification

- `MIX_ENV=test mix test test/lockspire/web/live/admin/consents_live_test.exs --max-failures 3` - RED failed on planned missing consent detail decision summary before implementation.
- `MIX_ENV=test mix test test/lockspire/web/live/admin/consents_live_test.exs --max-failures 1` - PASS, 3 tests, 0 failures.
- `mix format --check-formatted lib/lockspire/web/live/admin/consents_live/show.ex test/lockspire/web/live/admin/consents_live_test.exs` - PASS.
- `MIX_ENV=test mix test test/lockspire/web/live/admin/tokens_live_test.exs test/lockspire/web/live/admin/consents_live_test.exs test/lockspire/web/live/admin/design_system_contract_test.exs test/lockspire/web/live/admin/design_system_component_stress_test.exs --max-failures 1` - PASS, 63 tests, 0 failures.
- `MIX_ENV=test mix test.fast --max-failures 5` - FAIL, 1156 tests, 4 failures, 287 excluded. Failures are out of scope in `Lockspire.ReleaseReadinessContractTest` against pre-existing dirty adoption-demo docs/scripts.
- Source guard: consent detail uses `Admin.get_consent/1`, `Admin.revoke_consent/2`, `AdminComponents.decision_summary`, and `AdminComponents.confirmation_panel`; no raw `Repo`/`Repository`, schema, migration, route, package, reveal, export, debug, or bulk action was introduced in the LiveView.

## TDD Gate Compliance

- RED commit present: `cd31178` (`test(122-03): add failing consent detail closed-state coverage`)
- GREEN commit present after RED: `ce8fcf0` (`feat(122-03): polish consent detail investigation actions`)
- REFACTOR commit: not needed; no behavior-neutral cleanup pass was required after GREEN.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Phase 122 Support investigation polish is complete for token and consent indexes/details. Phase 123 can apply the same decision-first, redaction-safe, closed-state-aware pattern to Operate queue surfaces.

## Self-Check: PASSED

- Found `lib/lockspire/web/live/admin/consents_live/show.ex`.
- Found `test/lockspire/web/live/admin/consents_live_test.exs`.
- Found task commits `cd31178` and `ce8fcf0` in git history.

---
*Phase: 122-support-investigation-flow-polish*
*Completed: 2026-06-28*
