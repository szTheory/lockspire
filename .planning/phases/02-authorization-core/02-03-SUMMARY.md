---
phase: 02-authorization-core
plan: 03
subsystem: auth
tags: [oauth, consent, liveview, phoenix, generator]
requires:
  - phase: 02-authorization-core
    provides: durable interactions, consent policy, and authorization-code issuance
provides:
  - end-to-end authorize browser wiring through login handoff, consent review, and finalize redirects
  - lockspire-owned consent finalization endpoint and consent review surface
  - generated host templates aligned to the executable consent and finalize contract
affects: [02-04, AUTH-02, AUTH-04, INTE-03, INTE-04]
tech-stack:
  added: []
  patterns:
    - current-account resolution stays in controllers and LiveViews, not protocol core
    - pending-login interactions resume through protocol orchestration before consent rendering
    - generated host templates point back to Lockspire consent and finalize routes instead of protocol internals
key-files:
  created:
    - test/lockspire/web/interaction_controller_test.exs
    - test/lockspire/web/live/consent_live_test.exs
  modified:
    - lib/lockspire/protocol/authorization_flow.ex
    - lib/lockspire/web/controllers/authorize_controller.ex
    - lib/lockspire/web/controllers/interaction_controller.ex
    - lib/lockspire/web/live/consent_live.ex
    - priv/templates/lockspire.install/interaction_handler.ex
    - priv/templates/lockspire.install/consent_live.ex
    - test/lockspire/web/authorize_controller_test.exs
    - test/integration/install_generator_test.exs
key-decisions:
  - "AuthorizeController resolves the current account through the host seam, builds explicit subject context from host claims, and passes only that context into AuthorizationFlow."
  - "Pending login interactions resume through a protocol-owned resume entrypoint before consent review or consent reuse decisions are exposed."
  - "Generated host templates stay brandable but always post approve and deny decisions back to Lockspire's finalize endpoint."
duration: 31min
completed: 2026-04-23
---

# Phase 2 Plan 3: Authorization Core Summary

**Authorize happy-path delivery, consent review and finalization, and generated host templates aligned with Lockspire-owned protocol surfaces**

## Performance

- **Duration:** 31 min
- **Completed:** 2026-04-23T01:51:20Z
- **Tasks:** 3

## Accomplishments

- Replaced the temporary `/authorize` success JSON with real browser flow wiring that validates first, resolves the current account in the web layer, and then routes to login handoff, consent review, or client redirect outcomes from `AuthorizationFlow`.
- Turned the interaction controller and consent LiveView stubs into real delivery adapters: pending-login interactions now resume through protocol-owned logic, consent review renders durable client and scope context, and approve or deny posts finalize through Lockspire-owned protocol transitions.
- Updated the generated host interaction and consent templates so fresh installs point at Lockspire's consent and finalize routes while still leaving host branding, copy, and product framing editable in the host app.

## Task Commits

1. **Task 1: Wire `/authorize` into explicit web-layer account resolution and interaction outcomes** - `a6cd155` (feat)
2. **Task 2: Wire consent rendering and finalize approval or denial through Lockspire-owned surfaces** - `1f4b520` (feat)
3. **Task 3: Align generated host interaction and consent surfaces with the executable Phase 2 flow** - `71d5d4c` (feat)

## Decisions Made

- Used host `build_claims/2` output as the source of explicit subject context so controllers and LiveViews can hand protocol-safe identifiers into the core without leaking account/session ownership.
- Added `AuthorizationFlow.resume_interaction/3` instead of re-implementing pending-login resume logic in Phoenix delivery code, keeping consent reuse and interaction validity inside the protocol boundary.
- Kept generated host helpers focused on route building and UX framing so the host owns copy and layout while Lockspire remains authoritative for final redirect correctness and interaction durability.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed the web-layer protocol-store wiring**
- **Found during:** Task 1
- **Issue:** `AuthorizationFlow` defaulted to the configured raw Ecto repo, which does not implement the interaction, consent, and token store callbacks expected by the protocol service.
- **Fix:** Passed `Lockspire.Storage.Ecto.Repository` explicitly from the web adapters so the browser flow uses the intended storage seam instead of the raw repo module.
- **Files modified:** `lib/lockspire/web/controllers/authorize_controller.ex`, `lib/lockspire/web/controllers/interaction_controller.ex`, `lib/lockspire/web/live/consent_live.ex`
- **Verification:** `mix test test/lockspire/web/authorize_controller_test.exs`, `mix test test/lockspire/web/interaction_controller_test.exs`, `mix test test/lockspire/web/live/consent_live_test.exs`

**2. [Rule 2 - Missing Critical] Added a protocol resume path for pending-login interactions**
- **Found during:** Task 2
- **Issue:** The 02-02 protocol contract could create `pending_login` interactions but had no way to resume them after the host authenticated the account, which blocked the real `/authorize` happy path from reaching consent or consent reuse.
- **Fix:** Added `AuthorizationFlow.resume_interaction/3` and used it from the interaction controller and consent LiveView so resume decisions stay protocol-owned and replay-safe.
- **Files modified:** `lib/lockspire/protocol/authorization_flow.ex`, `lib/lockspire/web/controllers/interaction_controller.ex`, `lib/lockspire/web/live/consent_live.ex`
- **Verification:** `mix test test/lockspire/web/interaction_controller_test.exs`, `mix test test/lockspire/web/live/consent_live_test.exs`

## Known Stubs

None.

## Threat Flags

None.

## Self-Check: PASSED

- Verified `.planning/phases/02-authorization-core/02-03-SUMMARY.md` exists.
- Verified task commits `a6cd155`, `1f4b520`, and `71d5d4c` exist in git history.
