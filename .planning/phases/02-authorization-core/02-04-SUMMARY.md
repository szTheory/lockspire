---
phase: 02-authorization-core
plan: 04
subsystem: auth
tags: [oauth, token, pkce, phoenix, ecto, telemetry]
requires:
  - phase: 02-authorization-core
    provides: durable authorization codes, consent finalization, and authorize browser wiring
provides:
  - replay-safe `/token` authorization-code exchange with opaque bearer access tokens
  - transactional code redemption plus access-token persistence behind the token store seam
  - OAuth-safe JSON token responses with redacted telemetry and audit events
affects: [03-01, AUTH-05, SECU-01, SECU-02, SECU-03, SECU-04]
tech-stack:
  added: []
  patterns:
    - transactional code redemption through the repository contract rather than controller-layer writes
    - internal token formatter seam for opaque bearer issuance without exposing JWT configuration
    - thin Phoenix token adapter over protocol-owned client auth and PKCE validation
key-files:
  created:
    - lib/lockspire/protocol/token_formatter.ex
    - lib/lockspire/protocol/token_exchange.ex
    - lib/lockspire/web/controllers/token_controller.ex
    - lib/lockspire/web/controllers/token_json.ex
    - test/lockspire/protocol/token_formatter_test.exs
    - test/lockspire/protocol/token_exchange_test.exs
    - test/lockspire/web/token_controller_test.exs
  modified:
    - lib/lockspire/storage/token_store.ex
    - lib/lockspire/storage/ecto/repository.ex
    - lib/lockspire/observability.ex
    - lib/lockspire/web/router.ex
key-decisions:
  - "TokenExchange owns token-endpoint client authentication and grants only `:none`, `:client_secret_basic`, and `:client_secret_post` to keep Phase 2 aligned with client registration."
  - "Access tokens stay opaque and hashed at rest behind TokenFormatter, while authorization-code redemption uses one repository transaction to prevent double minting."
  - "The /token controller only adapts request headers and JSON responses; all protocol validation, replay detection, and reason-code emission stay in protocol core."
patterns-established:
  - "Authorization code lookup is split into fetch-by-hash plus transactional redeem-and-store so mismatch reasons can be classified without giving up atomic redemption."
  - "Token responses always set no-store/no-cache headers and emit redacted observability metadata instead of raw codes, verifiers, or bearer tokens."
requirements-completed: [AUTH-05]
duration: 5min
completed: 2026-04-23
---

# Phase 2 Plan 4: Authorization Core Summary

**Replay-safe `/token` exchange with opaque bearer access tokens, transactional code redemption, and OAuth-safe JSON delivery**

## Performance

- **Duration:** 5 min
- **Started:** 2026-04-23T01:54:10Z
- **Completed:** 2026-04-23T01:58:47Z
- **Tasks:** 2
- **Files modified:** 11

## Accomplishments
- Extended the token storage seam with fetch-by-code-hash and a single transaction that marks an authorization code redeemed while persisting the new access token.
- Added `Lockspire.Protocol.TokenFormatter` and `Lockspire.Protocol.TokenExchange` so opaque bearer issuance, client auth checks, PKCE verification, redirect binding, and replay handling all stay in protocol core.
- Mounted `POST /token` through a thin Phoenix controller that returns OAuth-safe JSON, sets `no-store` cache headers, and emits redacted success, failure, and replay events.

## Task Commits

Each task was committed atomically:

1. **Task 1: Add redemption queries and the opaque-token formatter seam** - `9427fe7` (feat)
2. **Task 2: Implement the authorization-code exchange service and thin `/token` adapter** - `453d2d5` (feat)

**Verification cleanup:** `cbeea0a` (style)

## Files Created/Modified

- `lib/lockspire/storage/token_store.ex` - Expanded the domain token-store contract with fetch-by-hash and atomic redeem-and-store callbacks.
- `lib/lockspire/storage/ecto/repository.ex` - Added authorization-code lookup plus transactional redemption and access-token persistence in one repository operation.
- `lib/lockspire/protocol/token_formatter.ex` - Internal-only opaque bearer token formatter and hashing seam for access-token issuance.
- `lib/lockspire/protocol/token_exchange.ex` - Protocol-core `/token` service for grant validation, client auth, PKCE checks, redirect binding, replay detection, and access-token issuance.
- `lib/lockspire/web/controllers/token_controller.ex` - Thin `/token` adapter that passes request auth into protocol core and returns cache-safe JSON responses.
- `lib/lockspire/web/controllers/token_json.ex` - Minimal OAuth token and error JSON rendering helpers.
- `lib/lockspire/observability.ex` - Expanded redaction to cover token-endpoint auth and bearer material.
- `lib/lockspire/web/router.ex` - Mounted `POST /token`.
- `test/lockspire/protocol/token_formatter_test.exs` - Coverage for opaque token generation and hashing.
- `test/lockspire/protocol/token_exchange_test.exs` - Integration coverage for happy path, replay, expiry, verifier mismatch, client mismatch, redirect mismatch, unsupported grant type, and unsupported auth method handling.
- `test/lockspire/web/token_controller_test.exs` - Controller coverage for public-client token exchange and OAuth-safe error JSON bodies.

## Decisions Made

- Kept access-token formatting internal and opaque so Phase 3 can add JWT support later without exposing token-shape configuration in Phase 2.
- Required the token endpoint to match each client’s registered auth method exactly instead of silently accepting multiple methods for the same client.
- Returned `invalid_grant` for code, PKCE, redirect, expiry, and replay failures while reserving `invalid_client` for token-endpoint authentication failures.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- `mix format --check-formatted` initially failed on the new token files, so the formatter was applied and recorded in a separate style commit before the final verification pass.

## Known Stubs

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Phase 3 can build discovery, OIDC, refresh, revocation, and introspection surfaces on top of a real opaque-token issuance path and durable access-token records.
- Security and observability hardening can now validate replay, downgrade, and redaction behavior against a complete authorization-code flow.

## Threat Flags

None.

## Self-Check: PASSED

- Verified `.planning/phases/02-authorization-core/02-04-SUMMARY.md` exists.
- Verified task commits `9427fe7`, `453d2d5`, and `cbeea0a` exist in git history.
- Verified the core created files exist: `lib/lockspire/protocol/token_formatter.ex`, `lib/lockspire/protocol/token_exchange.ex`, and `lib/lockspire/web/controllers/token_controller.ex`.

---
*Phase: 02-authorization-core*
*Completed: 2026-04-23*
