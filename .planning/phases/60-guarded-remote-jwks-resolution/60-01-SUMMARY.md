---
phase: 60-guarded-remote-jwks-resolution
plan: 01
subsystem: auth
tags: [jwks, oauth, oidc, req, cachex]
requires:
  - phase: 59-registration-policy-metadata-truth
    provides: private_key_jwt and jwks_uri registration state that later phases will verify against remote JWKS
provides:
  - https-only JWKS fetch validation before cache or network work
  - strict Req runtime policy with redirects and retries disabled
  - stable fetcher-owned error tuples for HTTP, timeout, transport, redirect, and format failures
affects: [phase-61-private-key-jwt-verification, jwks-fetcher, client-auth]
tech-stack:
  added: []
  patterns: [guarded remote fetch boundary, normalized internal error contract]
key-files:
  created: [.planning/phases/60-guarded-remote-jwks-resolution/60-01-SUMMARY.md]
  modified: [lib/lockspire/jwks_fetcher.ex, test/lockspire/jwks_fetcher_test.exs]
key-decisions:
  - "Kept Lockspire.JwksFetcher as the only public remote-JWKS seam and rejected non-https URIs before Cachex or Req work begins."
  - "Enforced redirect: false, retry: false, and low connect/read timeout defaults as non-overridable fetcher policy."
  - "Collapsed fetch failures into {:jwks_fetch_failed, reason} tuples so later client-auth code can map them without depending on Req structs."
patterns-established:
  - "Remote JWKS failures surface as fetcher-owned tuples instead of raw transport or parsing exceptions."
  - "Security-sensitive Req defaults are enforced inside the fetcher even when callers pass more permissive options."
requirements-completed: [JWKS-01]
duration: 20min
completed: 2026-05-06
---

# Phase 60 Plan 01: Guarded Remote JWKS Resolution Summary

**Guarded `jwks_uri` fetching now rejects non-https input, enforces fail-closed Req policy, and returns stable fetcher-owned errors for later `invalid_client` mapping.**

## Performance

- **Duration:** 20 min
- **Completed:** 2026-05-06
- **Tasks:** 1
- **Files modified:** 3

## Accomplishments

- Hardened `Lockspire.JwksFetcher` so URI validation happens before cache lookup or request execution.
- Enforced a strict outbound policy with redirects disabled, retries disabled, and intentionally low connect/read timeouts.
- Normalized JWKS fetch failures into `{:jwks_fetch_failed, reason}` tuples and extended tests for non-https rejection, redirect refusal, strict runtime policy, and the existing success path.

## Files Created/Modified

- `lib/lockspire/jwks_fetcher.ex` - Added https-only validation, strict Req defaults, and normalized fetcher-owned error handling.
- `test/lockspire/jwks_fetcher_test.exs` - Pinned the new failure contract and strict request policy behavior while preserving the success/cache path coverage.
- `.planning/phases/60-guarded-remote-jwks-resolution/60-01-SUMMARY.md` - Captures the plan outcome and verification result.

## Decisions Made

- Kept the fetcher API narrow: callers still receive either `{:ok, %JOSE.JWK{}}` or `{:error, {:jwks_fetch_failed, reason}}`.
- Treated redirect responses as a distinct fail-closed fetcher error instead of following them or surfacing raw 3xx behavior.
- Reduced failure detail to stable internal reasons rather than leaking `Req.TransportError` or parser exceptions.

## Deviations from Plan

None - plan executed within scope and without widening into target-safety resolution or cache-refresh work.

## Verification

- `MIX_ENV=test mix test --warnings-as-errors test/lockspire/jwks_fetcher_test.exs`
- Result: passed (`8 tests, 0 failures`)

## Issues Encountered

- A test-only attempt to inspect final Req options via custom request steps did not compose cleanly with the existing cache path, so the strict-policy assertion was finalized as an observable behavior test instead. No production code change was required for that adjustment.

## Next Phase Readiness

- Phase 61 can consume a stable remote-JWKS fetch contract without depending on Req-specific transport semantics.
- Target-safety resolution and cache-refresh semantics remain intentionally deferred to later Phase 60 plans.
