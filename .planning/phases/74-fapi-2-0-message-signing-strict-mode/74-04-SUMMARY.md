---
phase: 74-fapi-2-0-message-signing-strict-mode
plan: 04
subsystem: auth
tags: [fapi, oauth, oidc, introspection, jwt, rfc9701]
requires:
  - phase: 73-jwt-introspection-responses
    provides: optional RFC 9701 JWT introspection baseline
  - phase: 74-fapi-2-0-message-signing-strict-mode
    provides: canonical strict-profile and readiness semantics
provides:
  - protocol-owned strict introspection caller entitlement
  - controller enforcement that successful strict introspection responses require explicit JWT negotiation
affects: [74-05, introspection_controller, RFC9701]
tech-stack:
  added: []
  patterns: [protocol-owned entitlement truth, strict success-path negotiation, JSON error fallback]
key-files:
  created: []
  modified:
    - lib/lockspire/protocol/introspection.ex
    - lib/lockspire/protocol/introspection_jwt.ex
    - lib/lockspire/web/controllers/introspection_controller.ex
    - test/lockspire/protocol/introspection_test.exs
    - test/lockspire/protocol/introspection_jwt_test.exs
    - test/lockspire/web/introspection_controller_test.exs
key-decisions:
  - "Reserved strict JWT-only handling for authenticated callers whose own effective profile resolves to `:fapi_2_0_message_signing`."
  - "Kept downgrade and signer-failure responses JSON-shaped even when success responses must be JWTs."
patterns-established:
  - "Controllers consume explicit protocol entitlement truth instead of inferring caller policy ad hoc."
requirements-completed: [ENF-01]
duration: resume verification
completed: 2026-05-08
---

# Phase 74 Plan 04: Introspection Negotiation Summary

**Strict-profile introspection callers must now explicitly negotiate `application/token-introspection+jwt` for successful responses**

## Performance

- **Duration:** Resume verification
- **Started:** 2026-05-08T15:02:07Z
- **Completed:** 2026-05-08T15:02:07Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments

- Extended `Introspection.Success` with protocol-owned strict entitlement truth.
- Updated the introspection controller to reject JSON success downgrades for strict callers while preserving JSON OAuth errors.
- Patched `Lockspire.Protocol.IntrospectionJwt` so mismatched key/algorithm pairs return stable `:unsupported_signing_algorithm` errors instead of leaking JOSE exceptions.

## Task Commits

No plan-local commits were created during this resume pass. The implementation was already present as uncommitted work in the shared tree, so this execution pass verified behavior and documented the completed plan state.

## Files Created/Modified

- `lib/lockspire/protocol/introspection.ex` - Strict JWT entitlement truth on successful introspection results.
- `lib/lockspire/protocol/introspection_jwt.ex` - Default strict-profile algorithm selection and stable signer error shaping.
- `lib/lockspire/web/controllers/introspection_controller.ex` - JWT `Accept` negotiation enforcement for strict callers.
- `test/lockspire/protocol/introspection_test.exs` - Entitlement truth coverage for strict vs non-strict callers.
- `test/lockspire/protocol/introspection_jwt_test.exs` - Stable signing error coverage for unsupported key/algorithm combinations.
- `test/lockspire/web/introspection_controller_test.exs` - JSON downgrade rejection and JWT negotiation coverage.

## Decisions Made

- Strictness is caller-owned: eligibility for strict JWT-only introspection depends on the authenticated caller’s own effective profile, not resource-server heuristics.
- Error responses stay JSON: even under strict mode, OAuth errors and signer failures keep the baseline JSON contract.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Restored stable signer error mapping for strict-profile algorithm selection**
- **Found during:** Resume verification
- **Issue:** Full non-integration testing surfaced a raw JOSE `{:not_supported, [:ES256]}` exception when a strict-profile request selected `ES256` against an RSA JWK in `test/lockspire/protocol/introspection_jwt_test.exs`.
- **Fix:** Wrapped compact JWT signing in `Lockspire.Protocol.IntrospectionJwt` so mismatched key and algorithm pairs return `{:error, :unsupported_signing_algorithm}`.
- **Files modified:** `lib/lockspire/protocol/introspection_jwt.ex`
- **Verification:** `MIX_ENV=test mix test --warnings-as-errors test/lockspire/protocol/introspection_jwt_test.exs`

## Issues Encountered

- Full non-integration testing reached `769 tests, 0 failures (255 excluded)` but still exits non-zero because of unrelated warning debt in other test files when `--warnings-as-errors` is enabled.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Strict introspection negotiation is now proven at both the protocol and controller seams.
- Phase `74-05` can rely on end-to-end coverage for global strict mode, per-client strict mode, and mixed-mode opt-out behavior.

## Verification

- Focused signer fix verification:
  `MIX_ENV=test mix test --warnings-as-errors test/lockspire/protocol/introspection_jwt_test.exs`
- Covered by the Phase 74 aggregate verification run:
  `MIX_ENV=test mix test --warnings-as-errors test/lockspire/storage/ecto/server_policy_record_test.exs test/lockspire/storage/ecto/client_record_test.exs test/lockspire/protocol/security_profile_test.exs test/lockspire/protocol/message_signing_profile_test.exs test/lockspire/admin/server_policy_test.exs test/lockspire/admin/clients_test.exs test/lockspire/protocol/registration_test.exs test/lockspire/protocol/registration_management_test.exs test/lockspire/protocol/authorization_request_test.exs test/lockspire/protocol/introspection_test.exs test/lockspire/web/introspection_controller_test.exs test/lockspire/web/live/admin/policies_live/security_profile_test.exs test/lockspire/web/live/admin/clients_live/show_test.exs test/integration/phase41_fapi_2_0_e2e_test.exs test/lockspire/release_readiness_contract_test.exs`

---
*Phase: 74-fapi-2-0-message-signing-strict-mode*
*Completed: 2026-05-08*
