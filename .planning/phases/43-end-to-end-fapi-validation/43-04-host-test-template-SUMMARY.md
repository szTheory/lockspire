---
phase: 43-end-to-end-fapi-validation
plan: 04
subsystem: testing
tags: [elixir, phoenix, generator, fapi, oauth, oidc]
requires:
  - phase: 41-fapi-2-0-profile-configuration
    provides: FAPI 2.0 PAR-required and DPoP enforcement used by the generated smoke
provides:
  - Host-owned FAPI smoke template rendered by `mix lockspire.install`
  - Install-generator assertions proving the template path, content, and compilation
  - Registry entry count locked at 12 templates
affects: [install-generator, host-onboarding, phase-43-verification]
tech-stack:
  added: []
  patterns: [host-owned generated integration test, public-api-only smoke proof]
key-files:
  created: [priv/templates/lockspire.install/fapi_smoke_e2e_test.exs]
  modified:
    [lib/lockspire/generators/templates.ex, test/integration/install_generator_test.exs]
key-decisions:
  - "Kept the generated smoke bounded to /authorize negative-path proof so it can use only public Lockspire APIs and avoid sandbox/DataCase coupling."
  - "Derived the generated host module/path from `scope_module` inside owned files because the current install-task `app_module/app_path` resolves to the library project during the fixture test harness."
patterns-established:
  - "Generated host tests should prove public API usage and compile from rendered output inside install-generator tests."
  - "When generator assigns drift in fixture harnesses, prefer deriving host namespace from explicit CLI-owned seams before widening generator internals."
requirements-completed: [FAPI-05, FAPI-06]
duration: 34 min
completed: 2026-05-03
---

# Phase 43 Plan 04: Host Test Template Summary

**Generated a host-owned FAPI 2.0 smoke test template that proves PAR gating, RFC 9207 `iss`, and exact redirect matching through Lockspire's public router and client-registration API**

## Performance

- **Duration:** 34 min
- **Started:** 2026-05-03T12:14:43Z
- **Completed:** 2026-05-03T12:48:43Z
- **Tasks:** 1
- **Files modified:** 3

## Accomplishments
- Added `priv/templates/lockspire.install/fapi_smoke_e2e_test.exs` as one bounded host-owned smoke test file under the ~200-line cap.
- Registered the template in `Lockspire.Generators.Templates.all/0` and locked the registry count at 12 entries.
- Extended `test/integration/install_generator_test.exs` to verify rendered path, expected public API references, forbidden internal references, and successful compilation of the generated test module.

## Task Commits

1. **Task 1: Create the FAPI smoke E2E test EEx template (D-17, D-18)** - `2db7988` (feat)

## Files Created/Modified
- `priv/templates/lockspire.install/fapi_smoke_e2e_test.exs` - Host-owned FAPI smoke exercising `/authorize` negative paths and `iss` emission through public APIs only.
- `lib/lockspire/generators/templates.ex` - Added the 12th template registry entry and routed the generated test into the host `test/generated_host_app/` namespace.
- `test/integration/install_generator_test.exs` - Added registry-count, rendered-content, forbidden-reference, compile, and fixture cleanup assertions for the new template.

## Decisions Made
- Used `/authorize`-only negative-path coverage in the generated test to keep the scaffold executable without internal storage helpers or sandbox setup.
- Added a compile check in the install-generator integration test so the generated file is validated as real Elixir code, not just string content.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Derived host namespace/path from `scope_module` inside owned files**
- **Found during:** Task 1 (Create the FAPI smoke E2E test EEx template)
- **Issue:** In the existing install-generator fixture harness, `build_assigns/1` resolves `app_module/app_path` from the library project (`Lockspire`), which would have rendered the new host test to `test/lockspire/...` with the wrong module namespace.
- **Fix:** Kept `install.ex` untouched per ownership and derived the generated host module/path from `scope_module` in `priv/templates/lockspire.install/fapi_smoke_e2e_test.exs` and `lib/lockspire/generators/templates.ex`.
- **Files modified:** `priv/templates/lockspire.install/fapi_smoke_e2e_test.exs`, `lib/lockspire/generators/templates.ex`
- **Verification:** `mix test test/integration/install_generator_test.exs --color`, `mix run -e 'IO.puts(length(Lockspire.Generators.Templates.all()))'`
- **Committed in:** `2db7988`

---

**Total deviations:** 1 auto-fixed (1 blocking)
**Impact on plan:** The fix was required to satisfy the host-fixture contract without widening plan ownership into `install.ex`. Scope stayed bounded to the plan-owned files.

## Issues Encountered
- A manual generator probe left rendered fixture files under `test/support/fixtures/generated_host_app`, which caused Mix to try compiling the fixture app on the next `mix test` run. Removing only those probe outputs restored the intended clean-fixture verification path.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- The install generator now emits executable host-side FAPI proof scaffolding and the registry count is locked for downstream contract checks.
- Phase 43 truth-in-docs and broader milestone verification plans can treat the generated FAPI smoke template as shipped.

## Self-Check

PASSED

- Found summary file: `.planning/phases/43-end-to-end-fapi-validation/43-04-host-test-template-SUMMARY.md`
- Found task commit: `2db7988`
