---
phase: 167-host-expanded-admin-routing
plan: "02"
subsystem: auth
tags: [phoenix, liveview, host-router, admin-routing, mount-path]

requires:
  - phase: 167-host-expanded-admin-routing
    provides: Native host route macro, fixed admin live session, and mount alignment guard
provides:
  - Connected route/action coverage for all 29 admin routes at default, nested, and root mounts
  - Fresh rejoin proof with a reused signed host session and host authorization hooks
  - Prefix-safe native navigation, query patches, task routes, and missing-record recovery links
affects: [168, 169, 170]

actuals:
  tokens: 7433
  tasks: 2
  commits: 4
commits: 4
plan_head_before: 43a838b1cdbd710fb734f5033c864789b37b8c4a
plan_head_after: 55f2f7ff1d48edbcd90609b130365339031133fa

tech-stack:
  added: []
  patterns:
    - Separate compiled host router and endpoint fixtures for each supported mount
    - Choose the longest matching admin route suffix when deriving the compiled mount base

key-files:
  created: []
  modified:
    - lib/lockspire/web/admin_routes.ex
    - test/support/lockspire/web/admin_route_host.ex
    - test/lockspire/web/live/admin/admin_route_integration_test.exs
    - .planning/phases/167-host-expanded-admin-routing/167-02-PLAN.md

key-decisions:
  - "Use the longest matching preserved route suffix to derive the admin base, so nested paths such as /policies/dcr cannot truncate the configured host mount."
  - "Keep existing missing-record pages and verify their prefixed recovery links instead of adding redirects that current behavior does not provide."
  - "Treat lifecycle tests as server-side evidence; browser transport, package adoption, and exact-floor claims remain with Phase 170."

requirements-completed: [MNT-01, MNT-02, MNT-03]
coverage:
  - id: D1
    description: All 29 preserved admin route/action entries connect through default, nested, and root host routers with real parameterized records.
    requirement: MNT-01
    verification:
      - kind: integration
        ref: test/lockspire/web/live/admin/admin_route_integration_test.exs#connected route/action matrix at each mount
        status: pass
    human_judgment: false
  - id: D2
    description: Native navigation, filter patches, task URLs, logout workflow query, and missing-record recovery links retain the configured prefix.
    requirement: MNT-03
    verification:
      - kind: integration
        ref: test/lockspire/web/live/admin/admin_route_integration_test.exs#rendered navigation and filters keep the configured prefix at every mount
        status: pass
    human_judgment: false
  - id: D3
    description: A fresh connected rejoin uses the signed host session, starts a distinct process, and runs the host current-identity hook again.
    requirement: MNT-02
    verification:
      - kind: integration
        ref: test/lockspire/web/live/admin/admin_route_integration_test.exs#fresh host hook rejoin at each mount
        status: pass
    human_judgment: false

duration: 12min
completed: 2026-10-22
status: complete
---

# Phase 167 Plan 02: Host-Expanded Admin Routing Summary

**All 29 existing admin actions now connect through default, nested, and root host routers, with prefix-safe navigation and fresh host-session rejoin evidence.**

## Performance

- **Duration:** 12 min
- **Started:** 2026-10-22T21:54:00Z
- **Completed:** 2026-10-22T22:06:00Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments

- Added separately compiled synthetic host routers and endpoints for `/lockspire/admin`, `/teams/ops/identity/admin`, and `/admin`; both `""` and `"/"` use the same root router, and a trailing slash normalizes to the same nested mount.
- Connected all 29 independently listed route/action cases at all three effective mounts, using real client, consent, token, and signing-key records for parameterized routes.
- Exercised native navigation, client and token filter patches, task URLs, the logout-propagation workflow query, missing-record recovery links, and two concurrent views with independent filter state.
- Stopped connected views and rejoined through the same signed host session cookie; the new process invoked the host identity hook again.
- Fixed prefix inference to select the longest matching admin route suffix, preserving the full base for overlapping routes such as `/policies/dcr` and `/dcr`.

## Task Commits

1. **Task 1: Open and reconnect the same native admin path at default, nested and root mounts** — `b8c101c2` (`feat`)
2. **Task 2 RED: Traverse every existing admin action with prefixed links, tasks, queries and redirects** — `2305106b` (`test`)
3. **Task 2 GREEN: Infer the longest matching admin route prefix** — `680d33c3` (`fix`)
4. **Task 2 formatting:** `55f2f7ff` (`style`)

## Files Modified

- `lib/lockspire/web/admin_routes.ex` — identifies the admin base from the longest matching route suffix.
- `test/support/lockspire/web/admin_route_host.ex` — provides default, nested, and root host routers/endpoints plus disposable domain fixtures.
- `test/lockspire/web/live/admin/admin_route_integration_test.exs` — covers connected actions, navigation, queries, recovery links, rejoin, and concurrent state.
- `.planning/phases/167-host-expanded-admin-routing/167-02-PLAN.md` — records the production source adjustment and preserves current missing-record behavior.

## Decisions Made

- A root overview entry identifies the base only at `/admin`; child routes use the longest matching preserved relative path.
- Missing client, consent, token, and key details render their existing not-found state with a prefixed recovery link. No redirect behavior was added.
- The connected rejoin proves server-side mount and host-hook behavior. It does not establish browser WebSocket transport, package adoption, or exact supported-floor compatibility.
- Assumption `A-167-MNT-02` remains unresolved; the concrete lifecycle checks do not classify the original unclassified probe.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Root route selection misidentified child routes as the admin base**
- **Found during:** Task 1
- **Issue:** The preserved `/` overview entry matched every compiled route before its route suffix, so child requests were compared against their own path rather than the configured admin base.
- **Fix:** Restrict the root entry to the compiled `/admin` route and derive child bases from their matching suffix.
- **Files modified:** `lib/lockspire/web/admin_routes.ex`, `test/lockspire/web/live/admin/admin_route_integration_test.exs`
- **Verification:** The focused integration file passed across default, nested, and root mounts.
- **Committed in:** `b8c101c2`

**2. [Rule 1 - Bug] Overlapping route suffixes truncated `/policies/dcr` to `/policies`**
- **Found during:** Task 2
- **Issue:** First-match suffix selection chose the shorter `/dcr` entry before `/policies/dcr`.
- **Fix:** Select the longest matching suffix; the regression test failed with `/admin/policies` before the fix and passed with `/admin` afterward.
- **Files modified:** `lib/lockspire/web/admin_routes.ex`, `test/lockspire/web/live/admin/admin_route_integration_test.exs`
- **Verification:** Focused route/lifecycle tests and the compile/config/runtime contract group passed.
- **Committed in:** `2305106b` (RED), `680d33c3` (GREEN)

**3. Plan wording corrected to match the existing missing-record contract**
- **Found during:** Task 2
- **Issue:** The plan expected redirects, while the existing LiveViews render in-place not-found states and prefixed recovery links.
- **Fix:** Updated the plan and tests to preserve and prove current behavior without changing product semantics.
- **Files modified:** `.planning/phases/167-host-expanded-admin-routing/167-02-PLAN.md`, `test/lockspire/web/live/admin/admin_route_integration_test.exs`
- **Verification:** Missing client, consent, token, and key routes rendered their current not-found state and prefixed recovery link at each mount.
- **Committed in:** `2305106b`

**Total deviations:** 3 handled (2 routing bugs, 1 plan/behavior clarification). **Impact:** Required for correct prefix alignment and faithful evidence; no protocol, authorization, or UI-copy changes.

## Verification

- `LOCKSPIRE_TEST_DB_NAME=lockspire_phase167_20261022_1754 ASDF_ELIXIR_VERSION=1.20.4-otp-29 ASDF_ERLANG_VERSION=29.1.1 asdf exec mix test test/lockspire/web/live/admin/admin_route_integration_test.exs` — **12 passed**.
- `LOCKSPIRE_TEST_DB_NAME=lockspire_phase167_20261022_1754 ASDF_ELIXIR_VERSION=1.20.4-otp-29 ASDF_ERLANG_VERSION=29.1.1 asdf exec mix test test/lockspire/web/admin_routes_compile_test.exs test/lockspire/config_test.exs test/lockspire/web/live/admin/admin_route_integration_test.exs test/lockspire/web/live/admin/admin_liveview_runtime_contract_test.exs` — **34 passed**.
- `mix format --check-formatted test/support/lockspire/web/admin_route_host.ex` — passed. The changed Elixir files were formatted before the focused and wave checks.
- All test commands used the isolated Phase 167 database. The original `.planning/state.json` bytes remain identical to `/tmp/lockspire-167-original-state.json`.
- No full `mix test.fast`, browser transport, package install/adoption, or exact-floor runtime result is claimed here; Phase 170 owns the latter evidence.

## Issues Encountered

None beyond the routing defects and existing missing-record behavior described above.

## User Setup Required

None.

## Next Phase Readiness

Plan 03 can now add the independent frozen route inventory and host/public surface separation checks. Phase 168 retains the full authorization denial matrix; Phases 169 and 170 retain installation convergence and real transport/package/runtime compatibility evidence.

## Self-Check: PASSED

- Summary file exists and contains the measured task commit ledger (`4` task commits from `43a838b1` through `55f2f7ff`).
- All four task commits are ancestors of the current branch head.
- The original `.planning/state.json` remains byte-identical to `/tmp/lockspire-167-original-state.json`.

---
*Phase: 167-host-expanded-admin-routing*
*Completed: 2026-10-22*
