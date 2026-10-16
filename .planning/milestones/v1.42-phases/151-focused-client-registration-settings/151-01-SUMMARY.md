---
phase: focused-client-registration-settings
plan: "01"
subsystem: ui
tags: [phoenix, liveview, admin, clients]

requires: []
provides:
  - Dedicated `/admin/clients/new` route ahead of the dynamic client-detail route.
  - Focused client-registration page with normalized filter-preserving return navigation.
  - Primary create actions and secondary return navigation.
affects: [151-02, admin-routing, client-registration]

actuals:
  tokens: 5513
  tasks: 2
  commits: 0

tech-stack:
  added: []
  patterns:
    - Reuse the existing client LiveView and form component for a dedicated route.
    - Build return paths only from normalized local inventory filters.

key-files:
  created: []
  modified:
    - lib/lockspire/web/admin_router.ex
    - lib/lockspire/web/live/admin/clients_live/index.ex
    - lib/lockspire/web/live/admin/clients_live/form_component.ex
    - test/lockspire/web/admin_router_test.exs
    - test/lockspire/web/live/admin/clients_live_test.exs
    - test/support/endpoint.ex

key-decisions:
  - Keep the existing client-create handler and copy-once secret result on the new route.
  - Let the shell page heading provide the sole registration title; hide the form component's redundant heading on this route.
  - Treat test/support/endpoint.ex as a route mirror and add only the new static route there.

patterns-established:
  - The main safe task on the client inventory and registration page uses primary styling; return navigation stays secondary.

requirements-completed: [UI-04, UI-05]

coverage:
  - id: D1
    description: Client creation opens in a standalone route and returns to normalized inventory filters.
    requirement: UI-04
    verification:
      - kind: integration
        ref: test/lockspire/web/admin_router_test.exs
        status: pass
      - kind: automated_ui
        ref: test/lockspire/web/live/admin/clients_live_test.exs#clients index links to a focused registration route that preserves normalized filters
        status: pass
    human_judgment: false
  - id: D2
    description: Registration has one page title and one concise explanation, with one focused form.
    requirement: UI-04
    verification:
      - kind: automated_ui
        ref: test/lockspire/web/live/admin/clients_live_test.exs#clients index links to a focused registration route that preserves normalized filters
        status: pass
    human_judgment: false
  - id: D3
    description: Validation recovery and copy-once credential acknowledgement and route departure remain safe.
    requirement: UI-04
    verification:
      - kind: automated_ui
        ref: test/lockspire/web/live/admin/clients_live_test.exs#rejected client creation retains safe input and associates actionable field errors
        status: pass
      - kind: automated_ui
        ref: test/lockspire/web/live/admin/clients_live_test.exs#created client secret is cleared on acknowledgement and inventory filter change
        status: pass
    human_judgment: false
  - id: D4
    description: Create and submit actions use primary styling while back navigation uses secondary styling.
    requirement: UI-05
    verification:
      - kind: automated_ui
        ref: test/lockspire/web/live/admin/clients_live_test.exs#client registration reserves primary styling for creation and keeps return navigation secondary
        status: pass
    human_judgment: false

commits: 0
plan_head_before: 067235ab818c957b72446eca75c8965581ea7b45
plan_head_after: 067235ab818c957b72446eca75c8965581ea7b45
duration: 10min
completed: 2026-10-12
status: complete
---

# Phase 151 Plan 01: Focused Client Registration Summary

Client registration now has a dedicated route, a single title and explanation, and a direct return to the filtered client inventory while retaining the existing one-time credential flow.

## Performance

- **Duration:** 10 minutes
- **Started:** 2026-10-12T13:27:45Z
- **Completed:** 2026-10-12T13:37:45Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments

- Added `/admin/clients/new` before `/admin/clients/:client_id` in the public admin router and the test host route mirror.
- Moved client creation out of the inventory page and removed the redundant selected-client-context panel.
- Preserved normalized search, status, registration-source, and page filters in the return link.
- Kept validation recovery, successful creation, copy-once secret display, acknowledgement clearing, and route-departure clearing on the same LiveView.
- Made client creation the primary action and return navigation secondary.

## Files Created/Modified

- `lib/lockspire/web/admin_router.ex` - Registers the static registration route before the dynamic client route.
- `lib/lockspire/web/live/admin/clients_live/index.ex` - Renders the dedicated route, normalized return path, and inventory action.
- `lib/lockspire/web/live/admin/clients_live/form_component.ex` - Allows the route to omit the form heading when the shell already supplies the page title.
- `test/lockspire/web/admin_router_test.exs` - Verifies `/clients/new` resolves to the registration LiveView action.
- `test/lockspire/web/live/admin/clients_live_test.exs` - Covers route copy, filter preservation, create/error/secret lifecycle, and action hierarchy.
- `test/support/endpoint.ex` - Mirrors only the new route for host-mounted LiveView tests.

## Decisions Made

- Reused the existing create handler and result panel so generated credentials remain only in the response that handles creation.
- Used the shell's H1 as the sole page title and kept the explanation concise.
- Kept the test-host route mirror synchronized with the production route so integration tests exercise the intended static route.

## Deviations from Plan

### Auto-added blocking test-harness route mirror

The LiveView test endpoint duplicates the admin route table. Without adding `/clients/new` to that table, requests resolved to `Show` with `client_id: new`, even though `AdminRouter` was correct. Added the matching static route to `test/support/endpoint.ex` so the planned route and lifecycle tests exercise the actual new view.

## Verification

- `mix format` on all six modified files - passed.
- `mix test test/lockspire/web/admin_router_test.exs test/lockspire/web/live/admin/clients_live_test.exs` - 26 passed.
- Elixir and Erlang were selected via `ASDF_ELIXIR_VERSION=1.20.4-otp-29` and `ASDF_ERLANG_VERSION=29.1.1`; repository `.tool-versions` does not select these values.
- No screenshot or retained artifact contains a generated client secret.

## Commit Recording

No commits were recorded in this executor. The initial plan-head ledger write under `.git` was rejected by the workspace's read-only Git boundary; source and test changes remain available in the shared working tree for the parent executor to finalize.

## Self-Check: PASSED

- All six modified source/test files exist.
- Both focused test files pass: 26 tests total.
- Commit count is recorded as zero with unchanged plan-head hashes; the shared changes remain uncommitted.
