---
phase: 169-install-and-upgrade-convergence
plan: "01"
subsystem: testing
tags: [phoenix, liveview, install-generator, native-admin-routes, host-authorization]

requires: []
provides:
  - "Installer-rendered native admin routes with a host-owned deny-by-default Plug and LiveView hook."
  - "Maintained generated-host parity and route-boundary regressions for default, root, and nested mounts."
affects: [170, install, generated-host, admin-routes]

actuals:
  tokens: 8023
  tasks: 2
  commits: 3

tech-stack:
  added: []
  patterns:
    - "Generated host authorization stays host-owned and denies until an adopter implements policy."
    - "Admin routing uses the canonical native LiveView route macro and fixed session."

key-files:
  created:
    - priv/templates/lockspire.install/operator_authorization.ex
    - test/integration/install_admin_integration_test.exs
    - test/support/generated_host_app_web/operator_authorization.ex
  modified:
    - lib/lockspire/generators/templates.ex
    - lib/lockspire/generators/install.ex
    - priv/templates/lockspire.install/router.ex
    - test/integration/install_generator_test.exs
    - test/support/generated_host_app_web/router/lockspire.ex
    - test/support/generated_host_app_web/router.ex

key-decisions:
  - "Keep generated operator policy in a host-owned file excluded from managed overwrite authority."
  - "Use the shared native AdminRoutes macro; preserve protocol and consent routes as separate host seams."

patterns-established:
  - "Test rendered installation bytes through a compiled isolated host rather than duplicating route inventories."
  - "Normalize the root mount before appending /admin so generated paths remain valid."

requirements-completed: [HDX-01, HDX-04]
coverage:
  - id: D1
    description: "Fresh installer output denies admin entry until the host implements Plug and LiveView authorization policy."
    requirement: HDX-04
    verification:
      - kind: integration
        ref: "test/integration/install_admin_integration_test.exs#installer-rendered router uses the canonical native admin integration"
        status: pass
      - kind: integration
        ref: "test/integration/install_admin_integration_test.exs#an explicitly implemented host policy connects its rendered admin overview"
        status: pass
    human_judgment: false
  - id: D2
    description: "Native admin routes preserve the canonical route inventory and path boundaries across default, root, and nested mounts, and stale install preflight leaves competing files unchanged."
    requirement: HDX-01
    verification:
      - kind: integration
        ref: "ASDF_ELIXIR_VERSION=1.20.4-otp-29 ASDF_ERLANG_VERSION=29.1.1 asdf exec mix test test/integration/install_generator_test.exs test/integration/install_admin_integration_test.exs test/lockspire/web/admin_routes_compile_test.exs test/lockspire/web/admin_route_inventory_test.exs"
        status: pass
    human_judgment: false

duration: 17min
completed: 2026-10-23
status: complete
plan_head_before: 509753daca4a575cf659777a2b592e337fd96fcf
plan_head_after: bae9b6a81cca75046fccc4bc5f6bb1dfedf01792
---

# Phase 169 Plan 01: Install and Upgrade Convergence Summary

**Generated host apps now compile Lockspire's native admin LiveViews behind an always-deny host-owned authorization seam, with route and stale-preflight coverage.**

## Performance

- **Duration:** 17 min
- **Started:** 2026-10-23T01:55:00Z
- **Completed:** 2026-10-23T02:12:04Z
- **Tasks:** 2
- **Files modified:** 11, including two TDD evidence records

## Accomplishments

- Added a host-owned generated Plug and LiveView hook that deny access until the adopting app supplies current staff authorization. The generated seam is excluded from the install manifest's managed-file ownership.
- Replaced the generated admin forward with the canonical native LiveView route macro and retained independent consent and public protocol routing.
- Verified installer-rendered HTTP denial and real connected LiveView access under an explicit test-host policy; retained server-side lifecycle evidence only.
- Updated the maintained generated-host fixture and covered all 29 route/action entries across default, root, and nested mounts, plus adjacent prefixes, `/clients/new` precedence, and stale preflight refusal without tree changes.

## Task Commits

1. **Task 1: Install rendered native routes and connect one host-authorized admin page** - `3e2d8e1d` (RED test), `35fc25f5` (implementation)
2. **Task 2: Keep the maintained generated host coherent and cover mount/ordering edges** - `bae9b6a8` (tests, fixtures, root-mount normalization)

## Files Created/Modified

- `priv/templates/lockspire.install/operator_authorization.ex` - Host-owned always-deny Plug and LiveView hook.
- `priv/templates/lockspire.install/router.ex` - Native admin route declaration and root mount normalization.
- `lib/lockspire/generators/templates.ex`, `lib/lockspire/generators/install.ex` - Template ownership and host setup instructions.
- `test/integration/install_admin_integration_test.exs` - Rendered host HTTP, connected LiveView, and mount-path coverage.
- `test/integration/install_generator_test.exs` - Template ownership, fixture parity, compiled route contract, and stale-plan coverage.
- `test/support/generated_host_app_web/operator_authorization.ex`, `test/support/generated_host_app_web/router.ex`, `test/support/generated_host_app_web/router/lockspire.ex` - Maintained generated-host fixtures.

## Decisions Made

- Keep staff identity, authentication, and policy in the host app. Generated authorization is host-owned and always denies until implemented.
- Preserve the existing independent literal route inventory and make installer behavior consume the canonical native macro.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Normalize a root mount before composing the generated admin path**
- **Found during:** Task 2 (maintained fixture and mount variants)
- **Issue:** Appending `/admin` directly to `/` generated `//admin`, which the native route macro correctly rejected.
- **Fix:** Render `/admin` for a root mount while preserving the configured prefix for other mount paths.
- **Files modified:** `priv/templates/lockspire.install/router.ex`
- **Verification:** Root-mount variant passed with the full required route and generator test set.
- **Committed in:** `bae9b6a8`

**Total deviations:** 1 auto-fixed (Rule 1)
**Impact on plan:** Required for the planned root-mount behavior; no scope expansion.

## Issues Encountered

- Phoenix's route table exposes native LiveView metadata and route pipelines through separate APIs. Assertions were aligned with the actual `Phoenix.Router.routes/1` and `route_info/4` contracts.
- The test suite emits existing compiler warnings, including a deliberate compile-error diagnostic from invalid-pipeline coverage; all targeted tests passed.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

The generated host integration, server-side lifecycle, and route inventory are ready for Phase 170. Package-consumer/browser verification and exact dependency-floor certification remain Phase 170's scope.

---
*Phase: 169-install-and-upgrade-convergence*
*Completed: 2026-10-23*

## Self-Check: PASSED

- Summary and task evidence files exist.
- Task commits `3e2d8e1d`, `35fc25f5`, and `bae9b6a8` are ancestors of the current plan head.
- Measured plan diff: 32,092 characters (8,023 tokens by chars/4); measured task commit count before summary commit: 3.
