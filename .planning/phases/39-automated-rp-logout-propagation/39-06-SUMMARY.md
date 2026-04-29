---
phase: 39-automated-rp-logout-propagation
plan: "06"
subsystem: auth
tags: [oidc, logout, discovery, liveview, oban, req, docs]
requires:
  - phase: "39-02"
    provides: operator-managed logout propagation fields and validation
  - phase: "39-03"
    provides: durable logout event and delivery storage
  - phase: "39-04"
    provides: Oban and Req back-channel delivery runtime
  - phase: "39-05"
    provides: replay-safe `/end_session/complete` orchestration
provides:
  - truthful front-channel logout completion UX
  - all four logout discovery booleans published together
  - dedicated admin logout propagation workflow distinct from post-logout redirects
  - support docs aligned with shipped logout reliability model
affects: [logout, discovery, admin, docs, support-truth]
tech-stack:
  added: []
  patterns:
    - controller-rendered HEEx front-channel completion page with bounded auto-continue
    - query-param workflow split for admin client edit surfaces
key-files:
  created:
    - lib/lockspire/web/controllers/end_session_html.ex
    - lib/lockspire/web/controllers/end_session_html/frontchannel_logout.html.heex
  modified:
    - lib/lockspire/web/controllers/end_session_controller.ex
    - lib/lockspire/protocol/discovery.ex
    - lib/lockspire/web/live/admin/clients_live/show.ex
    - lib/lockspire/web/live/admin/clients_live/form_component.ex
    - docs/install-and-onboard.md
    - docs/operator-admin.md
    - docs/supported-surface.md
    - test/integration/phase39_logout_propagation_e2e_test.exs
    - test/lockspire/protocol/discovery_test.exs
    - test/lockspire/web/discovery_controller_test.exs
    - test/lockspire/web/live/admin/clients_live_test.exs
key-decisions:
  - "Front-channel completion now renders only local browser dispatch truth and marks front-channel rows as `rendered`, never `succeeded`."
  - "Admin logout propagation uses a dedicated workflow on the existing client edit route so propagation settings stay separate from post-logout redirect editing without widening router scope."
patterns-established:
  - "Logout discovery booleans must flip together as one truthful shipped surface."
  - "Operator logout settings and post-logout redirects stay in separate UI workflows."
requirements-completed: [SLO-03, SLO-04]
duration: 10min
completed: 2026-04-29
---

# Phase 39 Plan 06: Public logout truth surface with best-effort front-channel UX, four discovery booleans, and dedicated admin workflow

**Truthful front-channel logout completion with iframe choreography, synchronized logout discovery metadata, and a dedicated operator workflow separated from post-logout redirects**

## Performance

- **Duration:** 10 min
- **Started:** 2026-04-29T20:00:48Z
- **Completed:** 2026-04-29T20:10:00Z
- **Tasks:** 3
- **Files modified:** 13

## Accomplishments
- Replaced the old logged-out completion response with a dedicated HEEx page that renders one hidden iframe per front-channel target, states the best-effort truth explicitly, and offers a visible continue fallback.
- Published `backchannel_logout_supported`, `backchannel_logout_session_supported`, `frontchannel_logout_supported`, and `frontchannel_logout_session_supported` together and aligned the admin client UI to the same shipped logout semantics.
- Updated the install, operator, and supported-surface docs to describe the exact `/end_session/complete`, Oban, Req, DCR, and front-channel reliability model now in the repo.

## Task Commits

1. **Task 1: Render truthful best-effort front-channel completion** - `851fbe9` (test), `bd4a0dc` (feat)
2. **Task 2: Publish truthful discovery and dedicated admin workflow** - `1ca89f3` (test), `41f9ee5` (feat)
3. **Task 3: Update support docs to match the shipped slice** - `5057590` (docs)

## Files Created/Modified
- `lib/lockspire/web/controllers/end_session_controller.ex` - switches `/end_session/complete` to render front-channel best-effort logout when iframe deliveries exist and marks those deliveries as locally rendered.
- `lib/lockspire/web/controllers/end_session_html.ex` and `lib/lockspire/web/controllers/end_session_html/frontchannel_logout.html.heex` - add the controller-rendered completion page with bounded auto-continue and honest copy.
- `lib/lockspire/protocol/discovery.ex` - publishes the full shipped logout discovery boolean set together.
- `lib/lockspire/web/live/admin/clients_live/show.ex` and `lib/lockspire/web/live/admin/clients_live/form_component.ex` - add the dedicated logout propagation workflow and operator-facing separation from post-logout redirects.
- `test/integration/phase39_logout_propagation_e2e_test.exs` - proves the full Phase 39 completion path, replay safety, and worker-side back-channel success without changing front-channel truth.
- `test/lockspire/protocol/discovery_test.exs`, `test/lockspire/web/discovery_controller_test.exs`, and `test/lockspire/web/live/admin/clients_live_test.exs` - lock discovery and admin truth to the shipped slice.
- `docs/install-and-onboard.md`, `docs/operator-admin.md`, and `docs/supported-surface.md` - document Oban/Req requirements, `/end_session/complete`, DCR logout metadata limits, and front-channel best-effort language.

## Decisions Made
- Front-channel logout now renders if iframe deliveries exist even when a `post_logout_redirect_uri` is present; the page auto-continues after a short delay instead of claiming immediate completion.
- The admin client surface keeps logout propagation off the post-logout redirect workflow and exposes separate operator copy for back-channel reliability versus front-channel best effort.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- The plan’s listed command `MIX_ENV=test mix test ... -x` is not accepted by the current Mix CLI. Verification used the same file set without `-x`.
- Test runs emitted transient Postgres `too_many_connections` noise from extra repo/Oban connection attempts, but the targeted integration and LiveView/discovery suites still completed successfully.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Phase 39 now has truthful public logout behavior across controller UX, discovery, admin, docs, and end-to-end proof.
- Remaining repo work is outside this plan’s scope and unchanged.

## Self-Check: PASSED

- Summary file exists at `.planning/phases/39-automated-rp-logout-propagation/39-06-SUMMARY.md`
- Task commits found: `851fbe9`, `bd4a0dc`, `1ca89f3`, `41f9ee5`, `5057590`
