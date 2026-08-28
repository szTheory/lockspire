---
phase: 134-architecture-topology
plan: 07
subsystem: token-exchange-topology
tags: [oauth, oidc, tokens, dpop, xref]
requires: []
provides:
  - Neutral token success and error values
  - One-way compatibility conversion for retained token helper facades
  - Internal signer and token DPoP collaborators
affects: [token-exchange, access-token-signer, token-endpoint-dpop]
tech-stack:
  added: []
  patterns: [neutral result spine, compatibility facade, internal collaborator]
key-files:
  created:
    - lib/lockspire/protocol/token_result.ex
    - lib/lockspire/protocol/token_exchange/compatibility.ex
    - lib/lockspire/protocol/token_exchange/internal/access_token_signer.ex
    - lib/lockspire/protocol/token_exchange/internal/token_endpoint_dpop.ex
  modified:
    - lib/lockspire/protocol/access_token_signer.ex
    - lib/lockspire/protocol/token_endpoint_dpop.ex
    - test/lockspire/protocol/token_result_test.exs
    - test/lockspire/protocol/access_token_signer_test.exs
    - test/lockspire/protocol/token_endpoint_dpop_test.exs
decisions:
  - Lower token collaborators return neutral token values; only retained callable facades convert neutral errors to TokenExchange.Error.
  - TokenExchange.Compatibility is one-way and is not called by the dispatcher or neutral internal collaborators.
metrics:
  duration: 7m
  completed: 2026-08-27
status: complete
---

# Phase 134 Plan 07: Neutral Token Result Spine Summary

Token signing and token-endpoint DPoP now use neutral result values behind public-compatible facades, providing the foundation for the remaining token-dispatcher inversion.

## Completed Work

- Added neutral `TokenResult.Success` and `TokenResult.Error` structs containing the exact token and OAuth/DPoP fields required for lossless public conversion.
- Added one-way `TokenExchange.Compatibility.to_public/1` conversion to retained `%TokenExchange.Success{}` and `%TokenExchange.Error{}` structs.
- Moved signer and token-endpoint DPoP implementations beneath `TokenExchange.Internal`; they construct neutral errors and do not alias or call the public facade or compatibility adapter.
- Recreated `AccessTokenSigner` and `TokenEndpointDPoP` as public-compatible facades that retain all four documented function arities and convert only neutral error values.

## Verification

- `mix test test/lockspire/protocol/token_result_test.exs test/lockspire/protocol/access_token_signer_test.exs test/lockspire/protocol/token_endpoint_dpop_test.exs test/lockspire/protocol/token_exchange_test.exs` — 33 tests, 0 failures.
- `mix xref graph --format cycles` — one token-exchange cycle remains, as expected until Plans 09–10 invert the dispatcher; neutral internal implementations have no alias/call dependency on `TokenExchange` or `Compatibility`.
- Neutral error tests verify exact public mapping and do not add credential, proof, token, or key fields to error values.

## Commits

- `a224c3b` — test(134-07): characterize neutral token result conversion
- `6d29ae4` — feat(134-07): add neutral token result compatibility
- `a1102a6` — docs(134-06): complete protected-resource topology plan (shared staging race also recorded the two Plan 07 source-file renames)
- `b0e1c13` — refactor(134-07): isolate signer and DPoP implementations

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Test loading] Loaded public facade modules before asserting exported arities.**
- **Found during:** Task 2 focused verification.
- **Issue:** `function_exported?/3` returns false for unloaded modules, producing a test-order-dependent failure.
- **Fix:** Added `Code.ensure_loaded!/1` before each arity assertion.
- **Files modified:** `test/lockspire/protocol/access_token_signer_test.exs`, `test/lockspire/protocol/token_endpoint_dpop_test.exs`
- **Commit:** `b0e1c13`

### Coordination Note

The shared staging race recorded the two mechanical Plan 07 source-file renames in `a1102a6`, a Plan 06 documentation commit. The subsequent Plan 07 implementation commit contains all module, facade, and test changes; no work was reverted or lost.

No new network endpoints or persistence paths were introduced. Token material remains on success paths only; neutral error values hold the same established safe OAuth/DPoP fields.

## Self-Check: PASSED

- Neutral result, compatibility, and both internal implementation files exist.
- All Plan 07 implementation commits are present in git history.
