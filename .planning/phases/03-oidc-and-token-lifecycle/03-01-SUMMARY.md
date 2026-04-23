---
phase: 03-oidc-and-token-lifecycle
plan: 01
subsystem: auth
tags: [oidc, discovery, jwks, phoenix, ecto, postgres]
requires:
  - phase: 02-authorization-core
    provides: oauth authorization-code and token endpoint foundations reused by discovery metadata
provides:
  - mount-aligned OIDC discovery metadata
  - durable JWKS publication from publishable signing-key rows
  - strict issuer validation tied to mount_path
affects: [oidc, token-lifecycle, userinfo, revocation, introspection]
tech-stack:
  added: []
  patterns: [thin phoenix delivery adapters, router-derived metadata, durable public-key publication]
key-files:
  created:
    - lib/lockspire/protocol/discovery.ex
    - lib/lockspire/protocol/jwks.ex
    - lib/lockspire/web/controllers/discovery_controller.ex
    - lib/lockspire/web/controllers/jwks_controller.ex
    - test/lockspire/web/discovery_controller_test.exs
    - test/lockspire/web/jwks_controller_test.exs
  modified:
    - lib/lockspire/config.ex
    - lib/lockspire/storage/key_store.ex
    - lib/lockspire/storage/ecto/repository.ex
    - lib/lockspire/web/router.ex
    - test/lockspire/storage/repository_test.exs
    - config/test.exs
key-decisions:
  - "Issuer validation now treats issuer and mount_path as one contract and rejects query, fragment, and path drift."
  - "Discovery metadata is built from a whitelist of supported fields plus the mounted router's real endpoints to avoid hand-maintained drift."
  - "JWKS publication reads only publishable signing-key rows and re-whitelists public JWK members before rendering."
patterns-established:
  - "Discovery stays in protocol core and controllers only set cache headers, status, and JSON rendering."
  - "Public key publication uses durable repository reads that strip private material before protocol serialization."
requirements-completed: [OIDC-01, OIDC-02]
duration: 6min
completed: 2026-04-23
---

# Phase 03 Plan 01: OIDC and Token Lifecycle Summary

**Path-aligned OIDC discovery metadata and JWKS publication backed by durable signing-key state**

## Performance

- **Duration:** 6 min
- **Started:** 2026-04-23T02:42:00Z
- **Completed:** 2026-04-23T02:48:01Z
- **Tasks:** 2
- **Files modified:** 15

## Accomplishments

- Added strict `issuer` validation so Lockspire only publishes metadata when the configured issuer is absolute, queryless, fragmentless, and path-aligned with `mount_path`.
- Added durable publishable-key reads and public-key sanitization for JWKS consumers.
- Added protocol-owned discovery and JWKS builders plus thin Phoenix controllers and mounted routes for `/.well-known/openid-configuration` and `/jwks`.
- Added repository and controller coverage for issuer-path enforcement, truthful discovery metadata, and public-only JWKS filtering.

## Task Commits

Each task was committed atomically:

1. **Task 1: Add issuer validation and durable key-publication helpers** - `e41b6eb` (feat)
2. **Task 2: Implement mount-aligned discovery and JWKS endpoints** - `a1a1177` (feat)
3. **Formatting follow-up for new discovery module** - `0dbb084` (style)

## Files Created/Modified

- `lib/lockspire/config.ex` - validates the issuer contract against `mount_path`
- `lib/lockspire/storage/key_store.ex` - adds a publishable-key read callback
- `lib/lockspire/storage/ecto/repository.ex` - returns only active or retiring keys and strips private material
- `lib/lockspire/protocol/discovery.ex` - builds discovery metadata from config and mounted routes
- `lib/lockspire/protocol/jwks.ex` - serializes a public JWK set from durable keys
- `lib/lockspire/web/router.ex` - mounts discovery and JWKS endpoints
- `lib/lockspire/web/controllers/discovery_controller.ex` - thin JSON adapter for discovery
- `lib/lockspire/web/controllers/jwks_controller.ex` - thin JSON adapter for JWKS
- `test/lockspire/storage/repository_test.exs` - verifies publishable key filtering and private-key stripping
- `test/lockspire/web/discovery_controller_test.exs` - verifies truthful discovery metadata and omitted unsupported fields
- `test/lockspire/web/jwks_controller_test.exs` - verifies publishable public keys only
- `config/test.exs` - aligns the test issuer with the new path-based issuer contract

## Decisions Made

- Discovery metadata intentionally omits `userinfo_endpoint`, `revocation_endpoint`, and `introspection_endpoint` until those routes exist, keeping the published document truthful to the mounted surface in this plan.
- JWKS serialization re-whitelists allowed public JWK members even after repository sanitization so accidental private members in stored maps do not leak to clients.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Aligned the test environment issuer with the new Phase 3 issuer contract**
- **Found during:** Task 2 (Implement mount-aligned discovery and JWKS endpoints)
- **Issue:** `config/test.exs` still used `https://example.test`, which became invalid once issuer-path alignment was enforced.
- **Fix:** Updated the configured test issuer to `https://example.test/lockspire`.
- **Files modified:** `config/test.exs`
- **Verification:** `mix test test/lockspire/config_test.exs`
- **Committed in:** `a1a1177`

---

**Total deviations:** 1 auto-fixed (1 blocking)
**Impact on plan:** The fix was required to exercise the new config contract in controller and config tests. No scope creep.

## Issues Encountered

- `mix format --check-formatted` still fails because of a pre-existing unrelated formatting drift in `lib/lockspire/protocol/token_exchange.ex`. The new Phase 3 files were formatted, but that existing file was left untouched to avoid rewriting unrelated in-flight work.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Lockspire now exposes a truthful path-based discovery endpoint and a durable JWKS surface for upcoming ID token and userinfo work.
- Future Phase 3 plans can add `userinfo`, `revocation`, and `introspection` routes and the discovery builder will begin publishing them once the mounted surface is real.

## Self-Check: PASSED

- Summary file exists at `.planning/phases/03-oidc-and-token-lifecycle/03-01-SUMMARY.md`
- Verified commits exist: `e41b6eb`, `a1a1177`, `0dbb084`

---
*Phase: 03-oidc-and-token-lifecycle*
*Completed: 2026-04-23*
