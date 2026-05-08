---
phase: 73-jwt-introspection-responses
plan: 02
subsystem: web
tags: [jwt, introspection, phoenix, oauth, accept-negotiation]
requires:
  - phase: 73-jwt-introspection-responses
    plan: 01
    provides: signer foundation and protocol-owned success context
provides:
  - Explicit `Accept` negotiation for RFC 9701 introspection responses
  - JWT success delivery with JSON-only error fallback
  - Focused regression proof for JSON/JWT branching and signer-failure behavior
affects: [introspection_controller, introspection_json, RFC9701]
tech-stack:
  added: []
  patterns: [controller-owned representation negotiation, signed-success-json-error split]
key-files:
  modified:
    - lib/lockspire/web/controllers/introspection_controller.ex
    - lib/lockspire/web/controllers/introspection_json.ex
    - test/lockspire/web/introspection_controller_test.exs
    - lib/lockspire/protocol/introspection.ex
    - lib/lockspire/storage/ecto/consent_grant_record.ex
    - lib/lockspire/storage/ecto/token_record.ex
    - test/lockspire/protocol/introspection_test.exs
    - test/lockspire/protocol/direct_client_auth_private_key_jwt_test.exs
    - priv/repo/migrations/20260508120500_add_introspection_payload_state.exs
key-decisions:
  - "Kept response negotiation in the Phoenix controller and only switched formats after a successful protocol result."
  - "Returned JSON `server_error` on post-success signing failure rather than inventing signed error payloads."
  - "Restored persisted consent-grant payload fields so JWT and JSON introspection surfaces can share the same truthful payload."
requirements-completed: [INT-01]
completed: 2026-05-08
---

# Phase 73 Plan 02: JWT Introspection Delivery Summary

**Explicit `Accept` negotiation for signed introspection responses with JSON-preserving error semantics**

## Accomplishments

- Added explicit `Accept: application/token-introspection+jwt` negotiation in `IntrospectionController`.
- Delivered signed JWT responses for active and inactive successful introspection outcomes while keeping OAuth errors on the JSON path.
- Added a signer-failure fallback that returns a standard JSON `server_error`.
- Restored persisted `authorization_details` and `consent_grant_id` mappings so the shared introspection payload remains truthful across JSON and JWT representations.

## Task Commit

1. **Plan execution:** `498d605` (`feat(73-02): negotiate JWT introspection responses`)

## Verification

- `MIX_ENV=test mix test.setup`
- `MIX_ENV=test mix test --warnings-as-errors test/lockspire/protocol/introspection_test.exs test/lockspire/protocol/introspection_jwt_test.exs test/lockspire/protocol/direct_client_auth_private_key_jwt_test.exs test/lockspire/web/introspection_controller_test.exs`
  - Result: `30 tests, 0 failures`

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Restored persisted grant payload fields needed for truthful introspection output**
- **Found during:** controller verification
- **Issue:** the Ecto mappings were not persisting `consent_grant_id` or `authorization_details`, which made both JSON and JWT introspection payloads lose grant-backed truth.
- **Fix:** added the missing record mappings and a migration so introspection payloads can preserve existing semantics while the controller negotiates representation.
- **Files modified:** `lib/lockspire/storage/ecto/consent_grant_record.ex`, `lib/lockspire/storage/ecto/token_record.ex`, `priv/repo/migrations/20260508120500_add_introspection_payload_state.exs`
- **Verification:** same focused suite above
- **Committed in:** `498d605`

## Next Phase Readiness

- Public support docs can now describe the shipped RFC 9701 surface truthfully.
- Release-readiness can pin the new wording without overclaiming strict mode, encryption, or discovery changes.
