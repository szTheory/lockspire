---
phase: 111-demo-url-contract-config-unification
plan: 02
subsystem: demo-proof
tags: [phoenix, seeds, smoke, oidc]
requires:
  - phase: 111-01
    provides: Canonical adoption demo base URL config and explicit bind IP contract
provides:
  - Seeded local OAuth/demo URLs derived from config :adoption_demo, :demo_base_url
  - Developer app callback display and authorize params derived from the same base URL
  - Labelled smoke assertions for issuer, endpoint, callback, and verification URI drift
affects: [adoption-demo, smoke-proof, docker-demo]
tech-stack:
  added: []
  patterns:
    - Read Application.fetch_env!(:adoption_demo, :demo_base_url) in local demo consumers.
    - Use labelled expected/actual smoke assertions for base-URL drift.
key-files:
  created: []
  modified:
    - examples/adoption_demo/priv/repo/seeds.exs
    - examples/adoption_demo/lib/adoption_demo_web/controllers/developer_controller.ex
    - scripts/demo/adoption_smoke.py
key-decisions:
  - "Local seed and developer URLs consume the same demo base URL contract created by Plan 111-01."
  - "External partner fixtures remain external and are not rewritten to the local demo base URL."
patterns-established:
  - "Demo consumers derive local URLs with demo_base_url <> path rather than repeating host literals."
  - "Smoke URL drift failures include a label plus expected and actual values."
requirements-completed: [URL-01, URL-02, URL-03, URL-04]
duration: 18 min
completed: 2026-06-04
---

# Phase 111 Plan 02: Demo URL Consumer And Smoke Summary

**Seed data, developer app output, and the adoption smoke now consume the same base URL contract and expose labelled drift diagnostics.**

## Performance

- **Duration:** 18 min
- **Started:** 2026-06-04T17:59:00Z
- **Completed:** 2026-06-04T18:17:26Z
- **Tasks:** 3
- **Files modified:** 3

## Accomplishments

- Replaced local seed URL literals with `Application.fetch_env!(:adoption_demo, :demo_base_url)` derivations.
- Preserved Northstar, legacy reporter, and backend external partner URL fixtures.
- Updated the developer apps page so the displayed callback and authorize `redirect_uri` match the seeded local client callback.
- Normalized `LOCKSPIRE_DEMO_BASE_URL` in the smoke and added labelled expected/actual assertions for discovery, callback, state, and device verification URI drift.

## Task Commits

Each task was committed atomically:

1. **Task 1: Derive local seed URLs from the demo base URL** - `4bf58d9` (feat)
2. **Task 2: Derive developer app callback output from the demo base URL** - `b69b557` (feat)
3. **Task 3: Make smoke drift failures label expected and actual URL values** - `3a58a61` (feat)

## Files Created/Modified

- `examples/adoption_demo/priv/repo/seeds.exs` - Uses the configured demo base URL for local callback, registration, interaction, logout, and printed callback URLs.
- `examples/adoption_demo/lib/adoption_demo_web/controllers/developer_controller.ex` - Uses the configured demo base URL for authorize params and rendered callback copy.
- `scripts/demo/adoption_smoke.py` - Normalizes the base URL and reports labelled expected/actual drift for issuer, endpoint, callback, state, and device verification URI checks.

## Decisions Made

- Kept URL derivation local to seed/controller files instead of adding a helper module because Phase 111 does not need a new adoption-demo API.
- Used `urljoin` plus query stripping in the smoke callback assertion so relative and absolute redirect locations are both checked against the configured callback URL.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Split duplicate logout delivery fixtures across distinct logout events**
- **Found during:** Task 1 (Derive local seed URLs from the demo base URL)
- **Issue:** `mix ecto.setup` failed because two seeded logout deliveries shared the same logout event, client, and channel under the current unique index.
- **Fix:** Added separate pending and discarded logout events and attached the duplicate delivery states to those events.
- **Files modified:** `examples/adoption_demo/priv/repo/seeds.exs`
- **Verification:** `cd examples/adoption_demo && mix ecto.setup` passed.
- **Committed in:** `4bf58d9`

---

**Total deviations:** 1 auto-fixed (1 blocking).
**Impact on plan:** The fix was required to satisfy the plan's seed setup acceptance gate and preserved the existing proof states.

## Issues Encountered

- `mix ecto.setup` emits derived default URLs in SQL/debug output because the default `LOCKSPIRE_DEMO_BASE_URL` is `http://127.0.0.1:4100`; source assertions verified the hard-coded local origin was removed from seed and controller files.

## Verification

- `mix format --check-formatted examples/adoption_demo/priv/repo/seeds.exs examples/adoption_demo/lib/adoption_demo_web/controllers/developer_controller.ex` passed.
- `python3 -m py_compile scripts/demo/adoption_smoke.py` passed.
- `cd examples/adoption_demo && mix compile --warnings-as-errors` passed.
- `cd examples/adoption_demo && mix ecto.setup` passed.
- `test "$(rg -n "http://127\\.0\\.0\\.1:4100" examples/adoption_demo/priv/repo/seeds.exs examples/adoption_demo/lib/adoption_demo_web/controllers/developer_controller.ex | wc -l | tr -d ' ')" = "0"` passed.
- `rg -n "https://partners\\.northstar\\.example\\.com/oauth/callback|https://legacy-reporter\\.example\\.com/oauth/callback|https://backend\\.acme-ledger\\.example\\.com/very/long/oauth/callback/path" examples/adoption_demo/priv/repo/seeds.exs` passed.
- `LOCKSPIRE_DEMO_BASE_URL=http://127.0.0.1:4100 python3 scripts/demo/adoption_smoke.py` passed against a local `mix phx.server`.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Phase 111 is ready for verification. Later Docker, Traefik, startup-output, docs, and hygiene phases can consume one base URL contract without patching around seed, endpoint, issuer, or smoke drift.

---
*Phase: 111-demo-url-contract-config-unification*
*Completed: 2026-06-04*
