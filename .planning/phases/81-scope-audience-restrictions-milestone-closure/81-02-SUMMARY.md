---
phase: 81-scope-audience-restrictions-milestone-closure
plan: 02
subsystem: auth
tags: [plug, phoenix, jwt, dpop, integration]
requires:
  - phase: 81-scope-audience-restrictions-milestone-closure
    provides: Structured invalid-audience and insufficient-scope errors from `VerifyToken`
provides:
  - `RequireToken` 401 vs 403 enforcement semantics for route protection
  - Generated-host protected API route proving the shipped plug order
  - End-to-end Bearer and DPoP route-protection coverage
affects: [docs, release-readiness, verification-report]
tech-stack:
  added: []
  patterns: [single strict HTTP boundary in RequireToken, generated-host protected route proof]
key-files:
  created: [test/support/generated_host_app_web/controllers/protected_api_controller.ex, test/integration/phase81_generated_host_route_protection_e2e_test.exs]
  modified: [lib/lockspire/plug/require_token.ex, test/lockspire/plug/require_token_test.exs, test/support/generated_host_app_web/router.ex]
key-decisions:
  - "Kept `RequireToken` as the only plug that renders HTTP failures; upstream plugs continue assigning typed `%Lockspire.AccessToken{}` errors."
  - "Used one narrow generated-host billing route to prove valid, missing, audience-mismatch, insufficient-scope, and DPoP-bound cases through real Phoenix dispatch."
patterns-established:
  - "Protected Phoenix API routes use `VerifyToken -> EnforceSenderConstraints -> RequireToken` in that exact order."
  - "Scope denials render `403 insufficient_scope` with required scopes in `WWW-Authenticate`; token/audience/sender failures stay `401 invalid_token`."
requirements-completed: [VAL-DX-01, VAL-DX-02, VAL-BIND-03]
duration: 11min
completed: 2026-05-23
---

# Phase 81: Scope/Audience Restrictions & Milestone Closure Summary

**`RequireToken` now cleanly splits `401 invalid_token` from `403 insufficient_scope`, and the generated-host fixture proves Phoenix API route protection with Bearer and DPoP tokens end to end.**

## Performance

- **Duration:** 11 min
- **Started:** 2026-05-23T14:09:36Z
- **Completed:** 2026-05-23T14:20:22Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments

- Extended `RequireToken` to preserve sender-aware `401` challenges while adding `403 insufficient_scope` responses with required scope hints.
- Added a generated-host protected API controller and router pipeline using the shipped plug order and explicit route restrictions.
- Proved the route-protection matrix with an integration suite covering valid access, missing token, audience mismatch, insufficient scope, and DPoP-bound success/failure.

## Task Commits

Each task was committed atomically where practical:

1. **Task 1: Keep `RequireToken` as the single strict boundary while adding insufficient-scope semantics** - `c50ea4e` (feat)
2. **Task 2: Prove route protection through the generated-host Phoenix fixture** - `c50ea4e` (feat)

**Plan metadata:** pending summary commit

## Files Created/Modified

- `lib/lockspire/plug/require_token.ex` - Renders structured audience failures as `401 invalid_token` and scope denials as `403 insufficient_scope`.
- `test/lockspire/plug/require_token_test.exs` - Covers audience-driven `401` responses, scope-driven `403` responses, and existing sender-aware challenges with warnings-as-errors.
- `test/support/generated_host_app_web/router.ex` - Adds a narrow JSON API pipeline using `VerifyToken`, `EnforceSenderConstraints`, and `RequireToken`.
- `test/support/generated_host_app_web/controllers/protected_api_controller.ex` - Exposes the documented `%Lockspire.AccessToken{}` assigns contract as minimal JSON for route tests.
- `test/integration/phase81_generated_host_route_protection_e2e_test.exs` - Drives the generated-host protected route with Bearer and DPoP tokens through real Phoenix dispatch.

## Decisions Made

- Kept the replay-store seam local to the generated-host proof route with a tiny acceptor module so the integration test focuses on route protection semantics rather than DB replay persistence.
- Standardized the generated-host proof on the actual `http://api.example.test` test-request shape used by `Phoenix.ConnTest` so DPoP `htu` validation stays deterministic.
- Preserved minimal JSON response bodies while putting the required scope set into the `WWW-Authenticate` challenge.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Removed deprecated `use Plug.Test` from the `RequireToken` unit suite**
- **Found during:** Task 1 verification
- **Issue:** Warnings-as-errors would fail the targeted suite on the deprecated Plug test helper.
- **Fix:** Switched the unit test module to `import Plug.Test` and `import Plug.Conn`.
- **Files modified:** `test/lockspire/plug/require_token_test.exs`
- **Verification:** `MIX_ENV=test mix test test/lockspire/plug/require_token_test.exs test/integration/phase81_generated_host_route_protection_e2e_test.exs --include integration --warnings-as-errors`
- **Committed in:** `c50ea4e`

**2. [Rule 3 - Blocking] Corrected the generated-host DPoP proof target to match the actual test request URI**
- **Found during:** Task 2 verification
- **Issue:** The initial proof used an `https` target while the generated-host test dispatch used `http`, which produced `invalid_htu`.
- **Fix:** Normalized the integration harness to the real request URI shape used by the route proof.
- **Files modified:** `test/integration/phase81_generated_host_route_protection_e2e_test.exs`
- **Verification:** `MIX_ENV=test mix test test/lockspire/plug/require_token_test.exs test/integration/phase81_generated_host_route_protection_e2e_test.exs --include integration --warnings-as-errors`
- **Committed in:** `c50ea4e`

**3. [Rule 3 - Execution Protocol] Combined Tasks 1 and 2 into one code commit**
- **Found during:** Plan finalization
- **Issue:** The HTTP contract and generated-host proof crossed the same files and verification command, so splitting them cleanly into separate commits would have been artificial.
- **Fix:** Landed the shipped code in one feature commit and recorded the deviation here.
- **Files modified:** `lib/lockspire/plug/require_token.ex`, `test/lockspire/plug/require_token_test.exs`, `test/support/generated_host_app_web/router.ex`, `test/support/generated_host_app_web/controllers/protected_api_controller.ex`, `test/integration/phase81_generated_host_route_protection_e2e_test.exs`
- **Verification:** `MIX_ENV=test mix test test/lockspire/plug/require_token_test.exs test/integration/phase81_generated_host_route_protection_e2e_test.exs --include integration --warnings-as-errors`
- **Committed in:** `c50ea4e`

---

**Total deviations:** 3 auto-fixed (2 blocking verification fixes, 1 commit-protocol deviation)
**Impact on plan:** No scope creep. The route-protection surface matches the plan, and the extra fixes only stabilized the proof harness.

## Issues Encountered

- The first generated-host DPoP proof failed on `invalid_htu` until the test harness was aligned with the actual request URI shape used by `Phoenix.ConnTest`.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- The public docs can now cite a real generated-host protected route that matches the shipped plug order.
- The milestone verification report can point to concrete unit and integration evidence for the final resource-server support claim.

---
*Phase: 81-scope-audience-restrictions-milestone-closure*
*Completed: 2026-05-23*
