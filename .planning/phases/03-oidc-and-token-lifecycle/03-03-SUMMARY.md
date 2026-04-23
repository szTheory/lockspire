---
phase: 03-oidc-and-token-lifecycle
plan: 03
subsystem: token-lifecycle
tags: [oauth, oidc, refresh-token, phoenix, ecto, postgres]
requires:
  - phase: 03-02
    provides: OIDC code flow, ID token issuance, and bearer-backed userinfo
provides:
  - reusable token-endpoint client authentication with correct Basic credential decoding
  - durable refresh-family rotation and family-wide invalidation on reuse
  - `/token` refresh grant dispatch through protocol core with thin Phoenix delivery
affects: [token-endpoint, client-auth, refresh-lifecycle, storage, web]
tech-stack:
  added: []
  patterns: [thin phoenix adapters, protocol-core grant dispatch, durable refresh-family truth]
key-files:
  created:
    - lib/lockspire/protocol/client_auth.ex
    - lib/lockspire/protocol/refresh_exchange.ex
    - test/lockspire/protocol/refresh_exchange_test.exs
  modified:
    - lib/lockspire/protocol/token_exchange.ex
    - lib/lockspire/protocol/token_formatter.ex
    - lib/lockspire/storage/token_store.ex
    - lib/lockspire/storage/ecto/repository.ex
    - lib/lockspire/web/controllers/token_controller.ex
    - lib/lockspire/web/controllers/token_json.ex
    - test/lockspire/protocol/token_exchange_test.exs
    - test/lockspire/storage/repository_test.exs
    - test/lockspire/web/token_controller_test.exs
    - test/lockspire/protocol/authorization_flow_test.exs
key-decisions:
  - "Token-endpoint client authentication now lives in `Lockspire.Protocol.ClientAuth` so refresh, revocation, and introspection can reuse one hardened posture."
  - "Refresh rotation and family invalidation stay in the repository transaction boundary; protocol code never re-implements durable state transitions."
  - "Authorization-code exchanges issue refresh tokens only when the client is allowed to use refresh grants, while `/token` remains a thin adapter over `TokenExchange` dispatch."
duration: unknown
completed: 2026-04-23
---

# Phase 03 Plan 03: OIDC and Token Lifecycle Summary

**Authenticated refresh-token rotation with reusable client auth and thin `/token` dispatch**

## Performance

- **Tasks completed:** 3
- **Commits:** 4

## Accomplishments

- Extracted reusable token-endpoint authentication into `Lockspire.Protocol.ClientAuth`, fixing the Phase 2 Basic-auth gap by splitting credentials once and URL-decoding `client_id` and `client_secret` before lookup and verification.
- Extended the token store and Ecto repository with durable refresh-family rotation, child linkage, and reuse-driven family invalidation, including associated access-token revocation.
- Added `Lockspire.Protocol.RefreshExchange` and `TokenExchange.exchange/1` grant dispatch so `/token` can serve both authorization-code and refresh grants while controllers stay limited to HTTP adaptation and JSON rendering.
- Issued refresh tokens from authorization-code exchanges when the client allows refresh grants, and returned rotated refresh tokens from refresh exchanges with replay-safe invalidation semantics.

## Task Commits

1. **Task 1: Extract reusable token-endpoint client authentication and close the Phase 2 Basic-auth gap** - `32f7e3d` (`feat`)
2. **Task 2: Add durable refresh-family rotation and reuse invalidation** - `421bf5a` (`feat`)
3. **Task 3: Dispatch refresh grants through protocol core and keep `/token` thin** - `ea85839` (`feat`)
4. **Follow-up: satisfy formatter gate after Task 3** - `db1fcd8` (`style`)

## Verification

- `mix test test/lockspire/protocol/token_exchange_test.exs`
- `mix test test/lockspire/storage/repository_test.exs`
- `mix test test/lockspire/protocol/refresh_exchange_test.exs`
- `mix test test/lockspire/web/token_controller_test.exs`
- `mix compile`
- `mix format --check-formatted`

All verification commands passed.

## Decisions Made

- Reused refresh-token hashes as initial `family_id` values so the family model stays fully inside durable token rows without a parallel lifecycle store.
- Kept refresh rotation responses OAuth-safe: rotated access and refresh tokens are returned from protocol core, while ID token behavior remains tied to authorization-code flow.
- Let repository transactions own replay classification and family invalidation so later revocation and introspection surfaces can trust the same durable predicates.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Added a small formatting follow-up after the refresh grant work**
- **Found during:** Final verification
- **Issue:** `mix format --check-formatted` failed on the repository helper lines added for rotated token inheritance.
- **Fix:** Ran the formatter and recorded the result in `db1fcd8`.
- **Files modified:** `lib/lockspire/storage/ecto/repository.ex`
- **Commit:** `db1fcd8`

## Known Stubs

None.

## Self-Check: PASSED

- Summary file exists at `.planning/phases/03-oidc-and-token-lifecycle/03-03-SUMMARY.md`
- Verified commits exist: `32f7e3d`, `421bf5a`, `ea85839`, `db1fcd8`
- `STATE.md` and `ROADMAP.md` were intentionally not updated per execution constraint
