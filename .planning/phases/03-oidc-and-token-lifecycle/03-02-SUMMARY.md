---
phase: 03-oidc-and-token-lifecycle
plan: 02
subsystem: auth
tags: [oidc, id-token, userinfo, jose, phoenix, ecto, postgres]
requires:
  - phase: 03-01
    provides: discovery metadata and durable JWKS/signing-key truth for RS256 issuance
provides:
  - RS256 ID token issuance from the token endpoint for OIDC code flow
  - nonce-enforced openid authorization requests
  - durable bearer-backed /userinfo responses with host claim enrichment
affects: [oidc, token-lifecycle, userinfo, discovery, jwks]
tech-stack:
  added: [jose]
  patterns: [destination-oriented host claims, durable opaque bearer validation, thin phoenix delivery adapters]
key-files:
  created:
    - lib/lockspire/protocol/id_token.ex
    - lib/lockspire/protocol/userinfo.ex
    - lib/lockspire/web/controllers/userinfo_controller.ex
    - lib/lockspire/web/controllers/userinfo_json.ex
    - test/lockspire/web/userinfo_controller_test.exs
  modified:
    - lib/lockspire/host/claims.ex
    - lib/lockspire/protocol/authorization_flow.ex
    - lib/lockspire/protocol/authorization_request.ex
    - lib/lockspire/protocol/token_exchange.ex
    - lib/lockspire/storage/ecto/repository.ex
    - lib/lockspire/storage/key_store.ex
    - lib/lockspire/storage/token_store.ex
    - lib/lockspire/web/controllers/token_controller.ex
    - lib/lockspire/web/controllers/token_json.ex
    - lib/lockspire/web/router.ex
    - test/lockspire/protocol/authorization_request_test.exs
    - test/lockspire/protocol/token_exchange_test.exs
    - test/lockspire/web/token_controller_test.exs
    - mix.exs
    - mix.lock
key-decisions:
  - "ID token signing stays protocol-owned in Lockspire.Protocol.IdToken and reads nonce from the linked interaction instead of denormalizing OIDC context into authorization-code rows."
  - "Host claims remain destination-oriented through Lockspire.Host.Claims helpers so protocol claims stay Lockspire-owned while userinfo and id_token can diverge safely."
  - "Userinfo validates opaque bearer access tokens against durable token state and filters host claims by granted scope before rendering."
patterns-established:
  - "Token endpoint JSON is truthful: id_token appears only for openid authorization-code exchanges."
  - "Bearer-protected endpoints stay thin controllers over protocol services that own token lookup and claim shaping."
requirements-completed: [OIDC-03]
duration: 13min
completed: 2026-04-23
---

# Phase 03 Plan 02: OIDC and Token Lifecycle Summary

**RS256 ID tokens, nonce-enforced OIDC code flow, and durable bearer-backed userinfo over the existing host seam**

## Performance

- **Duration:** 13 min
- **Started:** 2026-04-23T02:47:00Z
- **Completed:** 2026-04-23T03:00:14Z
- **Tasks:** 2
- **Files modified:** 20

## Accomplishments

- Added protocol-owned RS256 ID token signing that reads the linked interaction for nonce, merges destination-specific host claims, and preserves opaque access tokens.
- Evolved authorization requests to admit `scope=openid`, require `nonce`, and persist it through interaction state for later token-time use.
- Added a protected `GET /userinfo` endpoint that validates durable bearer tokens, returns `sub` plus scope-bounded host claims, and omits absent optional claims.
- Extended token and controller coverage to prove OIDC-vs-OAuth response truthfulness and subject consistency across ID token and userinfo.

## Task Commits

Each task was committed atomically:

1. **Task 1: Add OIDC claim-packaging and ID-token signing over the existing host seam** - `2ec7803` (feat)
2. **Task 2: Enforce OIDC request inputs and expose `/userinfo` as a thin protected adapter** - `f5699eb` (feat)

## Files Created/Modified

- `lib/lockspire/protocol/id_token.ex` - builds and signs minimal RS256 ID tokens with Lockspire-owned protocol claims.
- `lib/lockspire/protocol/token_exchange.ex` - issues ID tokens only for OpenID code flow and resolves nonce/claims/signing-key context through durable seams.
- `lib/lockspire/host/claims.ex` - adds destination-aware claim builders for ID token and userinfo packaging.
- `lib/lockspire/protocol/authorization_request.ex` - accepts `openid`, requires `nonce`, and preserves the validated nonce contract.
- `lib/lockspire/protocol/authorization_flow.ex` - persists validated nonce into the linked interaction record.
- `lib/lockspire/protocol/userinfo.ex` - validates opaque bearer tokens and filters host claims by granted scopes.
- `lib/lockspire/web/controllers/token_controller.ex` and `token_json.ex` - keep token delivery thin while rendering `id_token` only when it exists.
- `lib/lockspire/web/controllers/userinfo_controller.ex` and `userinfo_json.ex` - expose protected `/userinfo` JSON over protocol-owned bearer validation.
- `lib/lockspire/storage/key_store.ex`, `token_store.ex`, and `storage/ecto/repository.ex` - add active signing-key and active access-token lookups needed for OIDC issuance and userinfo.
- `test/lockspire/protocol/authorization_request_test.exs`, `token_exchange_test.exs`, `web/token_controller_test.exs`, and `web/userinfo_controller_test.exs` - cover nonce enforcement, ID token issuance, truthful token JSON, and durable userinfo behavior.

## Decisions Made

- Reused the linked interaction as the authoritative source for token-time OIDC context in Phase 3, which keeps nonce out of authorization-code token rows for now.
- Added the `jose` dependency rather than hand-rolling JOSE/JWS behavior, matching the phase research guidance for RS256 correctness.
- Scoped userinfo claims through a fixed OpenID-standard scope-to-claim map and the existing host seam instead of widening access-token semantics.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Added the missing JOSE dependency required for RS256 signing**
- **Found during:** Task 1 (Add OIDC claim-packaging and ID-token signing over the existing host seam)
- **Issue:** The repo did not include `jose`, so correct RS256 signing could not be implemented without either adding the dependency or violating the plan's research guidance.
- **Fix:** Added `{:jose, "~> 1.11"}` and updated `mix.lock`.
- **Files modified:** `mix.exs`, `mix.lock`
- **Verification:** `mix test test/lockspire/protocol/token_exchange_test.exs`
- **Committed in:** `2ec7803`

**2. [Rule 3 - Blocking] Passed repository-backed interaction and signing-key stores through the token controller**
- **Found during:** Task 2 (Enforce OIDC request inputs and expose `/userinfo` as a thin protected adapter)
- **Issue:** Controller-driven OIDC redemption defaulted store lookups to the configured Ecto repo module, which does not implement the protocol-store functions directly.
- **Fix:** Updated `Lockspire.Web.TokenController` to pass `Repository` for interaction and signing-key lookups alongside the existing client/token store wiring.
- **Files modified:** `lib/lockspire/web/controllers/token_controller.ex`
- **Verification:** `mix test test/lockspire/web/token_controller_test.exs`
- **Committed in:** `f5699eb`

---

**Total deviations:** 2 auto-fixed (2 blocking)
**Impact on plan:** Both fixes were required to complete the planned OIDC surface correctly. No scope creep.

## Issues Encountered

- None beyond the blocking items auto-fixed above.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Lockspire now supports the narrow Phase 3 OIDC code-flow subset end-to-end: `openid` + `nonce`, token-endpoint ID token issuance, and bearer-backed `/userinfo`.
- Discovery from `03-01` is now truthful for `userinfo_endpoint`, and later refresh, revocation, and introspection work can reuse the same durable token and controller patterns.

## Self-Check: PASSED

- Summary file exists at `.planning/phases/03-oidc-and-token-lifecycle/03-02-SUMMARY.md`
- Verified commits exist: `2ec7803`, `f5699eb`

---
*Phase: 03-oidc-and-token-lifecycle*
*Completed: 2026-04-23*
