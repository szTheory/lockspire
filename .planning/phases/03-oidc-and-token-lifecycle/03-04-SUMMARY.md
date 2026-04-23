---
phase: 03-oidc-and-token-lifecycle
plan: 04
subsystem: token-lifecycle
tags: [oauth, oidc, revocation, introspection, phoenix, ecto, postgres]
requires:
  - phase: 03-03
    provides: shared token-endpoint client authentication and durable refresh-family token state
provides:
  - client-bound revocation for opaque access and refresh tokens with success-on-unknown semantics
  - confidential-caller opaque token introspection with inactive-state collapse
  - thin `/revoke` and `/introspect` Phoenix adapters over shared protocol/storage truth
affects: [token-lifecycle, token-endpoint, revocation, introspection, storage, web]
tech-stack:
  added: []
  patterns: [shared lifecycle client auth, durable token-state classification, thin phoenix adapters]
key-files:
  created:
    - lib/lockspire/protocol/revocation.ex
    - lib/lockspire/protocol/introspection.ex
    - lib/lockspire/web/controllers/revocation_controller.ex
    - lib/lockspire/web/controllers/revocation_json.ex
    - lib/lockspire/web/controllers/introspection_controller.ex
    - lib/lockspire/web/controllers/introspection_json.ex
    - test/lockspire/protocol/revocation_test.exs
    - test/lockspire/protocol/introspection_test.exs
    - test/lockspire/web/revocation_controller_test.exs
    - test/lockspire/web/introspection_controller_test.exs
  modified:
    - lib/lockspire/storage/token_store.ex
    - lib/lockspire/storage/ecto/repository.ex
    - lib/lockspire/web/router.ex
key-decisions:
  - "Revocation and introspection both reuse `Lockspire.Protocol.ClientAuth` so lifecycle endpoints keep the hardened token-endpoint auth posture from 03-03."
  - "Opaque token introspection is caller-authorized by matching the authenticated confidential caller to the token's client binding and collapsing every inactive or unauthorized state to `active: false`."
  - "Lifecycle token lookup and revocation stay behind `TokenStore` callbacks so Phoenix controllers remain delivery-only adapters."
patterns-established:
  - "Shared lifecycle token helpers live in the repository and are reused by multiple protocol services."
  - "Inactive-state collapse happens in protocol core, not controllers, so response-shape leakage stays constrained."
requirements-completed: [TOKN-02, TOKN-03]
duration: unknown
completed: 2026-04-22
---

# Phase 03 Plan 04: OIDC and Token Lifecycle Summary

**RFC-safe revocation and confidential opaque-token introspection over the shared durable token lifecycle**

## Performance

- **Duration:** unknown
- **Started:** unknown
- **Completed:** 2026-04-22T23:22:49Z
- **Tasks:** 2
- **Files modified:** 13

## Accomplishments
- Added `Lockspire.Protocol.Revocation` plus `POST /revoke` so authenticated clients can revoke access or refresh tokens without leaking token existence.
- Added `Lockspire.Protocol.Introspection` plus `POST /introspect` so confidential callers can introspect opaque access and refresh tokens against the durable lifecycle truth from `03-03`.
- Kept controller code thin by pushing lifecycle auth, client binding, inactive-state collapse, and telemetry emission into protocol/storage layers.

## Task Commits

1. **Task 1: Implement client-authenticated token revocation** - `2d68408` (`feat`)
2. **Task 2: Implement opaque-token introspection with inactive-state collapse** - `694e5c0` (`feat`)

## Files Created/Modified

- `lib/lockspire/protocol/revocation.ex` - Revocation service with shared client auth, token binding, and success-on-unknown behavior.
- `lib/lockspire/protocol/introspection.ex` - Opaque token introspection service with confidential-caller gating and inactive-state collapse.
- `lib/lockspire/storage/token_store.ex` and `lib/lockspire/storage/ecto/repository.ex` - Shared lifecycle token lookup and revocation callbacks over durable token state.
- `lib/lockspire/web/router.ex` and new controllers/json modules - Mounted `/revoke` and `/introspect` as thin Phoenix adapters.
- `test/lockspire/protocol/*` and `test/lockspire/web/*` - Protocol and endpoint tests for happy path, unknown token, client mismatch, revoked/expired state, unauthorized caller behavior, and refresh-family reuse invalidation.

## Decisions Made

- Reused the repository as the lifecycle source of truth for both revocation and introspection instead of adding endpoint-specific token queries in protocol code.
- Allowed revocation to return `200` with an empty JSON body for unknown or mismatched tokens, preserving RFC-safe semantics without extra response branches.
- Limited active introspection responses to opaque access and refresh tokens owned by the authenticated confidential caller; all other cases return only `active: false`.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed introspection response handling during Task 2 verification**
- **Found during:** Task 2
- **Issue:** `Lockspire.Protocol.Introspection` double-wrapped protocol responses before telemetry emission, raising a function-clause error for both active and inactive paths.
- **Fix:** Matched on `{:ok, response}` directly in `introspect/1` before emitting telemetry and returning the response.
- **Files modified:** `lib/lockspire/protocol/introspection.ex`
- **Verification:** `mix test test/lockspire/protocol/introspection_test.exs` and `mix test test/lockspire/web/introspection_controller_test.exs`
- **Committed in:** `694e5c0`

## Issues Encountered

- `mix format --check-formatted` initially reported formatting drift in the new lifecycle files; rerunning `mix format` and the formatter gate cleared it without additional tracked changes.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Revocation and introspection now share the same client-auth and durable token truth as refresh rotation, so later operator or audit work can build on one lifecycle model.
- `STATE.md` and `ROADMAP.md` were intentionally left untouched for the orchestrator.

## Known Stubs

None.

## Self-Check: PASSED

- Summary file exists at `.planning/phases/03-oidc-and-token-lifecycle/03-04-SUMMARY.md`
- Verified commits exist: `2d68408`, `694e5c0`
