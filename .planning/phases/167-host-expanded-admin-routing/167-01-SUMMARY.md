---
phase: 167-host-expanded-admin-routing
plan: "01"
subsystem: auth
tags: [phoenix, liveview, oauth, mount-path, admin-routing]

requires: []
provides:
  - Host-native Lockspire admin routes with a fixed `:lockspire_admin` LiveView session.
  - Runtime HTTP and LiveView mount-path alignment guards.
  - Canonical mount-path validation and compile-time route option contracts.
affects: [167-02, 167-03, 168]

actuals:
  tokens: 10512
  tasks: 2
  commits: 2
commits: 2
plan_head_before: 7a154528613873d4c0af04893555e73eb1685fda
plan_head_after: 866baa354835bb06b43cce8ffaf896b5a0fbb6f9

tech-stack:
  added: []
  patterns:
    - Shared route inventory expanded directly inside a host Phoenix router.
    - Host authorization hooks run before Lockspire's mount alignment hook.
key-files:
  created:
    - lib/lockspire/web/admin_routes.ex
    - lib/lockspire/web/admin_mount.ex
    - test/lockspire/web/admin_routes_compile_test.exs
    - test/lockspire/web/live/admin/admin_route_integration_test.exs
    - test/support/lockspire/web/admin_route_host.ex
  modified:
    - lib/lockspire/web/admin_router.ex
    - lib/lockspire/config.ex
    - test/lockspire/config_test.exs
    - test/support/lockspire/web/admin_route_host.ex
    - test/lockspire/web/live/admin/admin_route_integration_test.exs
key-decisions:
  - "Keep `:lockspire_admin` fixed and require host HTTP pipelines plus host current-identity hooks."
  - "Resolve the compiled admin base path from Phoenix route metadata for request and mount checks."
patterns-established:
  - "Host route declarations pass native LiveView options through unchanged after validating the public shapes."
  - "Mount-path normalization is shared by configuration reads and admin alignment checks."
requirements-completed: [MNT-01, MNT-02, MNT-03, MNT-04]
coverage:
  - id: D1
    description: A host router mounts the real Lockspire overview at `/lockspire/admin` through native Phoenix routes and host authorization.
    requirement: MNT-01
    verification:
      - kind: integration
        ref: test/lockspire/web/live/admin/admin_route_integration_test.exs#the native host route connects the actual overview LiveView
        status: pass
    human_judgment: false
  - id: D2
    description: Missing host identity and mismatched runtime mount configuration fail before an admin view mounts.
    requirement: MNT-02
    verification:
      - kind: integration
        ref: test/lockspire/web/live/admin/admin_route_integration_test.exs#host authorization and runtime mount mismatch cases
        status: pass
    human_judgment: false
  - id: D3
    description: Root and nested route declarations preserve the fixed session, host pipeline and ordered hooks.
    requirement: MNT-03
    verification:
      - kind: unit
        ref: test/lockspire/web/admin_routes_compile_test.exs#root and scoped declarations compile to the same ordered native routes
        status: pass
    human_judgment: false
  - id: D4
    description: Mount configuration accepts canonical static prefixes and rejects malformed values without exposing supplied secrets.
    requirement: MNT-04
    verification:
      - kind: unit
        ref: test/lockspire/config_test.exs#mount_path canonicalization and malformed-prefix cases
        status: pass
    human_judgment: false

duration: 14min
completed: 2026-10-22
status: complete
---

# Phase 167 Plan 01: Host-Expanded Admin Routing Summary

**Lockspire admin LiveViews now mount directly in the host Phoenix router with host-owned authorization and runtime path alignment.**

## Performance

- **Duration:** 14 min
- **Started:** 2026-10-22T21:32:07Z
- **Completed:** 2026-10-22T21:45:41Z
- **Tasks:** 2
- **Files modified:** 8

## Accomplishments

- Added `Lockspire.Web.AdminRoutes.lockspire_admin_routes/2`, sharing the existing 29 LiveView routes with the retained `AdminRouter` while defining them natively inside host routers.
- Added a test host proving the real overview connects through the host pipeline, host identity hook, fixed session, and LiveView mount guard. The forward-only negative control continues to reproduce the old join failure.
- Canonicalized mount prefixes and completed route, hook, option, collision, and denial contracts, including native LiveView session/layout behavior.

## Task Commits

1. **Task 1: Add host-expanded admin route tracer** - `f8648603` (`feat`)
2. **Task 2: Validate host admin route contracts** - `866baa35` (`feat`)

## Files Created/Modified

- `lib/lockspire/web/admin_routes.ex` - Public route macro, shared route inventory and compile-time contract validation.
- `lib/lockspire/web/admin_mount.ex` - HTTP and LiveView mount-path alignment guard.
- `lib/lockspire/web/admin_router.ex` - Retained compatibility router consuming the shared inventory.
- `lib/lockspire/config.ex` - Canonical static mount-prefix validation.
- `test/support/lockspire/web/admin_route_host.ex` - Forward-only and canonical host routers, endpoint, and host policy fixtures.
- `test/lockspire/web/live/admin/admin_route_integration_test.exs` - Reproduction, real connected tracer and denial tests.
- `test/lockspire/web/admin_routes_compile_test.exs` - Scope composition, native options, hook order and compile failure contracts.
- `test/lockspire/config_test.exs` - Mount-prefix normalization and rejection tests.

## TDD Evidence

- **Forward-only red:** Under Elixir 1.20.4 / OTP 29.1.1, Phoenix 1.8.13 and LiveView 1.2.10, the old router returned HTTP 200; its signed LiveView session named `Lockspire.Web.AdminRouter`, whose `/` route existed but whose `/lockspire/admin` route did not. The retained exact negative assertion is `{:error, {:redirect, %{to: "http://www.example.com/lockspire/admin"}}}` from `live/2`.
- **Canonical red before routing implementation:** The same `live/2` request against the canonical host route returned that redirect tuple instead of `{:ok, view, html}`.
- **Green tracer:** The host-native route connected the actual `OverviewLive.Index`, rendered “Overview”, preserved the host staff identity, executed the host session callback and host hook, and reported `[:browser, :lockspire_admin_mount]` in route metadata.
- **Verification:** Focused config, compile-contract and integration command passed 25 tests; the unchanged admin runtime contract passed 2 tests. The full `mix test.fast` suite remains assigned to Plan 03.

## Decisions Made

- Host authorization remains owned by the host: its HTTP pipeline and current-identity `on_mount` hooks run before Lockspire's path guard.
- The macro disables inherited route aliases in its internal scope so a host's alias cannot rewrite Lockspire's fully qualified LiveView modules.
- Native root layout, layout and session options stay native Phoenix LiveView options after validation; Lockspire does not wrap or rename them.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Validate the effective route inside the emitted Phoenix scope**
- **Found during:** Task 1
- **Issue:** Calling `Phoenix.Router.scoped_path/2` directly while the macro expands failed with `RuntimeError: Phoenix router scope was not initialized`; Phoenix initializes the scope when it evaluates the generated scope body.
- **Fix:** Validate the composed path from inside the generated scope body, then use compiled Phoenix route metadata to recover the admin base path at HTTP and LiveView mount time.
- **Files modified:** `lib/lockspire/web/admin_routes.ex`, `lib/lockspire/web/admin_mount.ex`
- **Verification:** Root-level `/lockspire/admin` and nested `/lockspire` + `/admin` routers compile to matching paths; both HTTP and LiveView mount mismatch tests fail closed.
- **Committed in:** `866baa35`

**Total deviations:** 1 auto-fixed (blocking compile-time scope timing assumption)
**Impact on plan:** Preserved the planned public API and effective-path behavior without modifying Phoenix internals.

## Issues Encountered

- The initial negative fixture needed the Phoenix LiveView router macro required explicitly; corrected the test fixture and reran the full integration test.
- Compile-time contract tests showed Phoenix accepts map-shaped session ASTs without validating string keys itself; Lockspire now checks string keys and valid MFA shapes before passing options to LiveView.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

The host route macro and mount contract are ready for Plans 02 and 03. Generator, upgrader, demo and full-suite work remain in their planned scopes.

---
*Phase: 167-host-expanded-admin-routing*
*Completed: 2026-10-22*

## Post-wave regression repair

After the wave-one broad suite identified downstream test assumptions, the exported-function manifest now records `Config.normalize_mount_path!/1` as an additive extension while retaining the literal 76cf872 baseline. Admin route contract checks now inspect the compiled Phoenix route table and `route_info/4` instead of looking for route literals in `AdminRouter` source; their specific mounted paths and read-only source assertions remain intact. Focused compatibility, route, config, compile-contract and integration checks passed together: 39 tests.

## Self-Check: PASSED

- All eight planned source and test files exist.
- Task commits `f8648603` and `866baa35` are ancestors of the current `HEAD`.
- The original `.planning/state.json` remains byte-identical to the protected copy.
