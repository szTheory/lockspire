---
phase: 88
plan: 1
subsystem: auth
tags: [oauth, oidc, client-auth, jwt, client-secret-jwt]
requires: []
provides:
  - Runtime-only JWT auth-method resolution from stored client state
  - Explicit dispatch boundary between private_key_jwt and client_secret_jwt
  - Surface-level JWT allowlist so PAR stays out of the Phase 88 slice
affects: [88-02, 88-03, direct-client-auth, support-truth]
tech-stack:
  added: []
  patterns: [resolve attempted JWT auth method after client lookup, endpoint-level shared JWT surface allowlist]
key-files:
  created: []
  modified:
    - lib/lockspire/protocol/client_auth.ex
    - lib/lockspire/protocol/introspection.ex
    - lib/lockspire/protocol/revocation.ex
    - lib/lockspire/protocol/device_authorization.ex
    - lib/lockspire/protocol/backchannel_authentication.ex
    - lib/lockspire/protocol/token_exchange.ex
key-decisions:
  - "JWT bearer assertions now parse as a neutral attempted mode and resolve only after client lookup."
  - "Phase 88 exposes client_secret_jwt only on the shipped direct-client surfaces and keeps PAR excluded through per-endpoint JWT allowlists."
patterns-established:
  - "Shared ClientAuth remains the only runtime seam for direct-client JWT auth-method routing."
requirements-completed: [AUTH-01, AUTH-02]
duration: 25min
completed: 2026-05-25
---

# Phase 88 Plan 1 Summary

**Shared direct-client auth now resolves JWT assertions from the registered client method instead of implicitly routing all assertions through `private_key_jwt`**

## Performance

- **Duration:** 25 min
- **Started:** 2026-05-25T04:35:00Z
- **Completed:** 2026-05-25T05:00:00Z
- **Tasks:** 3
- **Files modified:** 6

## Accomplishments

- Changed `ClientAuth.authenticate/3` so JWT assertions are tentatively identified, then resolved from `client.token_endpoint_auth_method` after client lookup.
- Preserved the existing fail-closed `invalid_client` behavior for method mismatch with no fallback to `client_secret_basic`, `client_secret_post`, or `private_key_jwt`.
- Added per-endpoint JWT auth-method allowlists so `client_secret_jwt` is enabled only on the intended Phase 88 surfaces and remains excluded from PAR.

## Task Commits

1. **Task 88-01-01: split runtime JWT routing from published auth-method truth** - working tree
2. **Task 88-01-02: add explicit symmetric verifier dispatch seam** - working tree
3. **Task 88-01-03: prove routing and mismatch behavior** - working tree

## Files Created/Modified

- `lib/lockspire/protocol/client_auth.ex` - routes JWT assertions from stored client auth state and dispatches to method-specific verifiers.
- `lib/lockspire/protocol/introspection.ex` - enables the Phase 88 symmetric JWT slice on the shared introspection surface.
- `lib/lockspire/protocol/revocation.ex` - enables the Phase 88 symmetric JWT slice on the shared revocation surface.
- `lib/lockspire/protocol/device_authorization.ex` - enables the Phase 88 symmetric JWT slice on the shared device authorization surface.
- `lib/lockspire/protocol/backchannel_authentication.ex` - enables the Phase 88 symmetric JWT slice on the shared backchannel surface.
- `lib/lockspire/protocol/token_exchange.ex` - enables the token endpoint-side shared JWT slice while keeping PAR unchanged.

## Decisions Made

- Runtime support was separated from discovery/publication truth, so `supported_auth_method_names/0` still reflects the pre-Phase-89 public contract.
- JWT surface scoping was enforced by endpoint auth options rather than branching inside each protocol module.

## Deviations from Plan

- The direct-client surface gate was implemented alongside routing so the Phase 88 runtime slice could stay truthful without waiting for later proof work.

## Issues Encountered

- GSD tracking remained at the pre-execution state after the crash, so this plan was reconciled from repo truth after verification instead of through the original orchestrated flow.

## User Setup Required

None.

## Next Phase Readiness

- Plan 88-02 can build on the new dispatch seam to add sealed verifier material, strict HS256 verification, and replay/audience enforcement.

---
*Phase: 88*
*Completed: 2026-05-25*
