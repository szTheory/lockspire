---
phase: 72
plan: 02
title: Encode nested JARM responses and fail closed on encryption failures
status: complete
commits:
  - f4013f7
  - c64c6af
key_files:
  - lib/lockspire/protocol/jarm/client_key_resolver.ex
  - lib/lockspire/protocol/jarm.ex
  - lib/lockspire/protocol/authorization_flow.ex
  - lib/lockspire/web/controllers/authorize_controller.ex
  - test/lockspire/protocol/jarm_test.exs
  - test/lockspire/protocol/authorization_flow_test.exs
  - test/lockspire/web/authorize_controller_test.exs
---

# Phase 72 Plan 02 Summary

Delivered encrypted JARM as nested JWTs, resolved recipient keys from inline or guarded remote JWKS, and kept authorization responses fail-closed when encrypted JARM could not be produced safely.

## Delivered

- Added `Lockspire.Protocol.Jarm.ClientKeyResolver` for explicit recipient-key resolution.
- Reused the guarded JWKS seam:
  - inline `jwks` selection prefers `use=enc`
  - matching `kid` is respected when supplied
  - `jwks_uri` uses cached fetch first and one bounded `refresh_keys/2` retry
  - unsupported key shape or unsupported algorithms return stable internal failure reasons
- Refactored `Lockspire.Protocol.Jarm` around a single `encode/2` boundary:
  - signed-only JARM returns compact JWS
  - encrypted JARM signs first and encrypts second into compact nested JWE
  - encryption requires explicit signing metadata and the Phase 72 `alg`/`enc` allow-list
- Updated `AuthorizationFlow` to call the unified JARM encode boundary and to resolve clients through either `fetch_client/1` or `fetch_client_by_id/1`.
- Wired the controller protocol opts so browser-visible authorization handling uses the same client/key stores and fail-closed behavior as the internal protocol path.
- Extended focused protocol and controller coverage for:
  - nested JARM encoding
  - approval and denial fail-closed behavior
  - first-party browser errors when encrypted JARM generation fails

## Deviations from Plan

None - plan executed within the intended scope.

## Verification

Exact commands run:

```bash
MIX_ENV=test mix test --warnings-as-errors test/lockspire/protocol/jarm_test.exs test/lockspire/protocol/authorization_flow_test.exs test/lockspire/web/authorize_controller_test.exs
mix test test/lockspire/jwks_fetcher_test.exs test/lockspire/protocol/jarm_test.exs
```

Results:

- `MIX_ENV=test mix test --warnings-as-errors test/lockspire/protocol/jarm_test.exs test/lockspire/protocol/authorization_flow_test.exs test/lockspire/web/authorize_controller_test.exs`
  - `50 tests, 0 failures`
- `mix test test/lockspire/jwks_fetcher_test.exs test/lockspire/protocol/jarm_test.exs`
  - `21 tests, 0 failures`

## Self-Check

PASSED

- Summary file exists.
- Plan commits exist: `f4013f7`, `c64c6af`.
- Focused verification commands passed on the final code.
