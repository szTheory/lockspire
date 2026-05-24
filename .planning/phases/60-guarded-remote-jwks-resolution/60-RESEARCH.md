# Phase 60: Guarded Remote JWKS Resolution - Research

**Researched:** 2026-05-06
**Scope:** `JWKS-01`, `JWKS-02`, `JWKS-03`
**Overall confidence:** HIGH

## Executive Summary

Phase 60 should harden the existing `Lockspire.JwksFetcher` seam, not replace it. The repo already has:

- a dedicated fetcher module,
- a supervised cache process,
- `Req.Test` coverage for fast network-path verification,
- and a downstream consumer seam (`ClientAuth`) that will need trustworthy remote key resolution in Phase 61.

What is missing is the security contract:

1. the fetcher still accepts whatever `Req` can reach;
2. redirects, unsafe targets, and oversized payloads are not explicitly blocked;
3. the cache contract has no bounded forced-refresh path for ordinary key rotation.

The recommended Phase 60 shape is therefore:

- keep `Lockspire.JwksFetcher` as the single remote-key seam;
- add a strict request policy and stable internal failure model;
- add pre-request target-safety checks based on resolved destination addresses;
- keep the current cache substrate for now, but add explicit TTL and one forced-refresh recovery path.

## Key Findings

### 1. The current fetcher is usable but too permissive for a security boundary

`lib/lockspire/jwks_fetcher.ex` currently:

- caches successful fetches in `Cachex`,
- disables retries,
- sets only `receive_timeout`,
- parses a successful JSON body into `JOSE.JWK`,
- and returns transport/http/format errors more or less directly.

Gaps relative to Phase 60:

- no runtime `https` gate,
- no explicit redirect refusal,
- no destination safety enforcement,
- no body-size boundary,
- no normalized error contract for later OAuth mapping,
- no explicit forced-refresh contract for key rotation.

### 2. Cache infrastructure already exists and should be hardened in place

`lib/lockspire/application.ex` already supervises:

- `Cachex.child_spec(name: :lockspire_jwks_cache)`

That means Phase 60 does not need to solve cache infrastructure from scratch. The narrowest path is to keep the supervised cache and focus on:

- explicit TTL semantics,
- refresh behavior,
- and how the fetcher handles refresh failure vs last-known-good entries.

The older `45-S02` strategy argued for an `:ets` rewrite. That may still be a reasonable future optimization, but it is not necessary to satisfy `JWKS-01`..`JWKS-03`, and it would create extra churn in a security-sensitive milestone.

### 3. The current `private_key_jwt` path proves why Phase 60 must stay narrow

`lib/lockspire/protocol/client_auth.ex` currently:

- extracts `client_id` by peeking into the JWT payload,
- validates only TTL and replay state,
- does not verify signatures,
- and does not resolve inline `jwks` vs remote `jwks_uri`.

That confirms the correct phase boundary:

- Phase 60 should produce a hardened remote key-resolution contract.
- Phase 61 should consume that contract for actual JWT verification.

Trying to wire verification in early would collapse two different risk surfaces into one plan and make failure analysis harder.

### 4. Target safety must be based on resolved addresses, not string patterns

`JWKS-02` explicitly requires rejection of unsafe destinations before the request is made. For an embedded auth library, hostname allow/deny string checks are too weak because:

- public hostnames can resolve to private or loopback addresses,
- DNS rebinding-style behavior becomes possible if only the URL string is checked,
- and the security boundary should be testable independently of the HTTP layer.

The research-backed implementation shape is:

- resolve the host before issuing the request,
- classify every resolved IP as public-routable or unsafe,
- fail closed if any chosen destination is unsafe or resolution is ambiguous in a risky way,
- and make the resolver injectable for unit tests.

### 5. Body-size and refresh behavior belong in the fetcher contract itself

`JWKS-01` and `JWKS-03` both imply that fetcher callers should not need to reason about transport quirks. The fetcher should own:

- request policy,
- response body cap,
- parsing into a JWK set,
- caching,
- and a refresh path for rotation.

The cleanest consumer contract is still:

- `{:ok, jwk_set}` on success,
- `{:error, reason}` with stable, fetcher-owned reason atoms/tuples on failure,
- plus one explicit way to bypass stale cache for rotation recovery.

### 6. Fast verification can stay unit-focused in this phase

The existing test seam is already strong:

- `test/lockspire/jwks_fetcher_test.exs` uses `Req.Test`,
- current tests already prove success, timeout, non-200, parse failure, and caching.

Phase 60 should extend that fast loop with:

- redirect rejection,
- `https`-only rejection,
- unsafe-address rejection using injected resolution fixtures,
- oversize-body rejection,
- forced-refresh success,
- forced-refresh failure behavior.

No end-to-end auth flow is required yet because Phase 61 owns actual client-auth verification.

## Recommended Implementation Shape

1. Keep `Lockspire.JwksFetcher` as the main API surface.
2. Add one small helper module for target safety if needed, rather than pushing IP classification logic into the main fetcher.
3. Normalize request defaults:
   - `https` only
   - redirects disabled
   - retries disabled
   - low connect/read timeouts
   - explicit response-body cap
4. Expose one bounded forced-refresh path that:
   - bypasses cache,
   - replaces cache on success,
   - and has defined behavior when refresh fails.
5. Avoid touching `ClientAuth` except for the minimum contract prep required by Phase 61.

## Concrete Risks To Plan Around

### Over-expansion risk

The phase can drift into a generic outbound-fetch framework or cache rewrite if the plan is not explicit. That would violate the milestone boundary and slow delivery.

### False-safety risk

A hostname-only or scheme-only check would look secure while still allowing unsafe routed destinations. Tests must prove actual address-class rejection.

### Rotation-regression risk

If forced refresh is bolted on without clear cache semantics, the library may either:

- keep serving stale keys forever,
- or erase last-known-good state too aggressively on transient upstream failure.

The plan should force that choice into explicit tests.

## Test Targets

Primary files to extend:

- `test/lockspire/jwks_fetcher_test.exs`

Likely new focused test file:

- `test/lockspire/jwks_fetcher/target_safety_test.exs`

Primary code files:

- `lib/lockspire/jwks_fetcher.ex`
- `lib/lockspire/application.ex` if cache wiring needs a narrow API-visible adjustment
- optionally `lib/lockspire/jwks_fetcher/target_safety.ex`

## Validation Architecture

Phase 60 is well-served by fast ExUnit coverage around the fetcher seam.

- Task-local loop: `MIX_ENV=test mix test --warnings-as-errors test/lockspire/jwks_fetcher_test.exs`
- Safety helper loop: `MIX_ENV=test mix test --warnings-as-errors test/lockspire/jwks_fetcher_test.exs test/lockspire/jwks_fetcher/target_safety_test.exs`
- No integration suite is required in this phase because cryptographic verification and endpoint wiring are intentionally deferred to Phase 61.

## Recommended Plan Split

- `60-01`: Harden request policy and normalize failure behavior in `Lockspire.JwksFetcher`
- `60-02`: Enforce target-safety and response-size boundaries before or during fetch
- `60-03`: Add explicit TTL/refresh semantics and a bounded forced-refresh path for key rotation

## Sources Read

- `.planning/ROADMAP.md`
- `.planning/REQUIREMENTS.md`
- `.planning/STATE.md`
- `.planning/research/SUMMARY.md`
- `.planning/phases/59-registration-policy-metadata-truth/59-RESEARCH.md`
- `.planning/phases/45-s02-dynamic-jwks-fetching/45-S02-STRATEGY.md`
- `lib/lockspire/jwks_fetcher.ex`
- `lib/lockspire/application.ex`
- `lib/lockspire/protocol/client_auth.ex`
- `test/lockspire/jwks_fetcher_test.exs`
- `test/lockspire/protocol/client_auth_test.exs`

## RESEARCH COMPLETE
