---
phase: 41-fapi-2-0-profile-configuration
plan: 02
subsystem: auth
tags: [fapi-2-0, plug, enforcer, boundary, router, par, dpop, tdd]

# Dependency graph
requires:
  - phase: 41-fapi-2-0-profile-configuration
    plan: 01
    provides: "SecurityProfile.resolve_effective_profile/2, security_profile field on ServerPolicy and Client"
provides:
  - "Lockspire.Protocol.FAPI20EnforcerPlug implementing @behaviour Plug (init/1, call/2)"
  - "Phoenix router :fapi_boundary pipeline guarding /authorize, /token, /userinfo"
  - "20 unit tests covering Groups A-G (passthrough, enforce, exempt, fail-closed, per-client override)"
affects:
  - "41-03 (protocol integration uses the boundary plug; router.ex landed cleanly)"
  - "41-04 (Admin UI; mixed-mode escape hatch visible in G2 test)"

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Standalone @behaviour Plug module (first in lib/lockspire/protocol/) with init/1 and call/2"
    - "Phoenix pipeline :fapi_boundary with inner scope pipe_through for selective route guarding"
    - "policy_fn option in Plug opts enables fail-closed simulation in unit tests without mocking"
    - "TDD RED/GREEN/REFACTOR cycle across two commits (test commit + feat commit)"

key-files:
  created:
    - lib/lockspire/protocol/fapi20_enforcer_plug.ex
    - test/lockspire/protocol/fapi20_enforcer_plug_test.exs
  modified:
    - lib/lockspire/web/router.ex

key-decisions:
  - "policy_fn option in Plug opts used for fail-closed test injection rather than meck/mox — keeps Plug testable with zero test framework coupling"
  - "init/1 accepts opts as-is (not parsed) so router pipeline passes keyword list naturally"
  - "/userinfo enforcement uses header-shape check only (DPoP header presence + Authorization scheme) per <userinfo_strategy> in plan — no token decode in Plug"
  - "Per-client override supported: global :none + client :fapi_2_0_security rejects (G1); global :fapi_2_0_security + client :none passes (G2/D-01 escape hatch)"

patterns-established:
  - "Standalone Plug module at lib/lockspire/protocol/ tier with @behaviour Plug"
  - "Router sub-scope with pipe_through for selective boundary enforcement without affecting /par or admin routes"

requirements-completed: [FAPI-02, FAPI-03]

# Metrics
duration: ~6min
completed: 2026-05-01
---

# Phase 41 Plan 02: FAPI20EnforcerPlug Boundary Enforcer Summary

**Phoenix Plug enforcing PAR presence on /authorize, DPoP on /token and /userinfo at the boundary when security_profile is :fapi_2_0_security; wired into router via :fapi_boundary pipeline; 20 unit tests green**

## Performance

- **Duration:** ~6 min
- **Started:** 2026-05-01T20:47:25Z
- **Completed:** 2026-05-01T20:53:07Z
- **Tasks:** 2 (Task 1 TDD: 3 commits; Task 2: 1 commit)
- **Files created/modified:** 3

## Accomplishments

- Implemented `Lockspire.Protocol.FAPI20EnforcerPlug` — the first standalone `@behaviour Plug` module in the protocol tier
- Plug dispatches on `path_info` for minimal hot-path overhead; non-FAPI routes are a single pattern-match passthrough
- Full TDD cycle: RED commit (`test(41-02)`) then GREEN commit (`feat(41-02)`) following project TDD convention
- /authorize rejection: 302 redirect with `error=invalid_request&error_description=request_uri+from+the+PAR+endpoint+is+required` when redirect_uri is valid; 400 JSON when no redirect_uri (defense against open redirect)
- /token rejection: 400 JSON `{"error":"invalid_dpop_proof","error_description":"A valid DPoP proof is required"}`
- /userinfo rejection: 401 JSON `{"error":"invalid_token"}` + `WWW-Authenticate: DPoP realm="Lockspire Userinfo"` header
- /par is exempt (path_info `["par"]` falls through to passthrough branch)
- Fail-closed: `{:error, _}` from `Repository.get_server_policy/0` returns 503 JSON
- Per-client override fully supported: client `:fapi_2_0_security` overrides global `:none` (G1); client `:none` overrides global `:fapi_2_0_security` (D-01 escape hatch, G2)
- Router updated with `:fapi_boundary` pipeline and inner scope; PAR and all admin/discovery routes remain unguarded
- Integration test at line 91 (direct /authorize rejection) passes through the Plug boundary

## Task Commits

1. **Task 1 RED: Failing tests** - `ee32845` (test)
2. **Task 1 GREEN: FAPI20EnforcerPlug implementation** - `90a9fb4` (feat)
3. **Task 2: Router :fapi_boundary pipeline** - `30baa00` (feat)

## Files Created/Modified

- `lib/lockspire/protocol/fapi20_enforcer_plug.ex` — Phoenix Plug enforcing FAPI 2.0 boundary rules (216 lines)
- `test/lockspire/protocol/fapi20_enforcer_plug_test.exs` — 20 unit tests, Groups A-G
- `lib/lockspire/web/router.ex` — :fapi_boundary pipeline, inner scope for /authorize, /token, /userinfo

## Decisions Made

- Used `policy_fn` option in Plug opts for fail-closed test (F1) rather than meck/mox. This avoids any external mock library dependency and keeps the Plug itself testable as a pure unit — the caller injects a lambda returning `{:error, :unavailable}`.
- `init/1` defined as `def init(opts), do: opts` (plan-required exact form). Phoenix router always passes a keyword list; the Plug reads with `Keyword.get(opts, :policy_fn, &Repository.get_server_policy/0)`.
- /userinfo enforcement is header-shape only per `<userinfo_strategy>` in 41-02-PLAN.md. Per-client opt-in under global `:none` is intentionally NOT covered by the Plug (defense-in-depth at `Userinfo.fetch_claims/1` verified by Plan 04 Task 1).
- Formatter auto-converts `plug Lockspire.Protocol.FAPI20EnforcerPlug` to `plug(...)` and `pipe_through :fapi_boundary` to `pipe_through(...)` — both forms are semantically identical in Phoenix.

## Deviations from Plan

None — plan executed exactly as written. All 8 must_haves.truths are verifiable by the 20 unit tests.

## Pre-existing Test Failures (Out-of-Scope)

17 pre-existing failures remain in `mix test --stale` — same set documented in Plan 41-01 SUMMARY (DPoP `validate_proof/2` alg=none, JAR `verify_signature/2` isolation failures, ReleaseReadinessContractTest, SecurityPolicyTest). All caused by uncommitted scaffolding changes in the working tree that predate this plan. None caused by Plan 41-02 changes.

## Known Stubs

None — all plan behaviors are fully implemented and wired.

## Threat Flags

No new security surface beyond what is documented in the plan's STRIDE threat register. The router change adds the Plug to existing routes (not new routes). T-41-01 through T-41-17 disposition unchanged.

## Self-Check: PASSED

- `lib/lockspire/protocol/fapi20_enforcer_plug.ex` - FOUND
- `test/lockspire/protocol/fapi20_enforcer_plug_test.exs` - FOUND (20 tests)
- `lib/lockspire/web/router.ex` contains `:fapi_boundary` pipeline - VERIFIED
- Commit `ee32845` (RED) - FOUND
- Commit `90a9fb4` (GREEN + implementation) - FOUND
- Commit `30baa00` (router) - FOUND
- No unexpected file deletions in plan commits
- `mix compile --warnings-as-errors` exits 0
- `mix test test/lockspire/protocol/fapi20_enforcer_plug_test.exs` — 20 tests, 0 failures
- `mix test test/integration/phase41_fapi_2_0_e2e_test.exs:91` — 1 test, 0 failures
- `mix format --check-formatted` on all 3 files — exits 0

---
*Phase: 41-fapi-2-0-profile-configuration*
*Completed: 2026-05-01*
