---
phase: 59
plan: 59-01
subsystem: dynamic-client-registration
tags:
  - dcr
  - rfc7591
  - rfc7592
  - private_key_jwt
  - jwks_uri
requirements:
  - REG-01
  - REG-02
key_files:
  created: []
  modified:
    - lib/lockspire/protocol/registration.ex
    - lib/lockspire/protocol/registration_management.ex
    - test/support/fixtures/dcr_fixtures.ex
    - test/lockspire/protocol/registration_test.exs
    - test/lockspire/protocol/registration_management_test.exs
decisions:
  - Keep `jwks_uri` admission narrow to `token_endpoint_auth_method=private_key_jwt`.
  - Require `https` for `jwks_uri` at registration and RFC 7592 full-replace update time.
  - Persist `jwks_uri` as a first-class client field rather than hiding it in extension metadata.
commits:
  - 7a93cc7
  - 15732ca
---

# Phase 59 Plan 01: Registration Policy Metadata Truth Summary

Implemented the narrow `jwks_uri` registration and management slice for `private_key_jwt` without adding any remote fetch behavior.

## Completed Work

- Tightened `Lockspire.Protocol.Registration.validate_jwks/1` so `jwks_uri` is:
  - rejected when paired with non-`private_key_jwt` auth methods,
  - rejected unless it is an `https` URI,
  - still mutually exclusive with inline `jwks`,
  - still required as part of the cryptographic-material contract for `private_key_jwt`.
- Persisted `jwks_uri` on self-registered clients in `Lockspire.Protocol.Registration`.
- Added DCR fixture helpers for the supported `private_key_jwt + jwks_uri` and inline `jwks` paths.
- Extended registration tests to pin:
  - admitted `private_key_jwt + https jwks_uri`,
  - rejected non-`private_key_jwt + jwks_uri`,
  - rejected non-`https jwks_uri`,
  - rejected `jwks` plus `jwks_uri`,
  - rejected `private_key_jwt` registrations without cryptographic material.
- Updated `Lockspire.Protocol.RegistrationManagement.apply_metadata_to_client/2` to preserve `jwks_uri` on RFC 7592 full-replace updates.
- Extended registration-management tests to pin:
  - updating a self-registered client from inline `jwks` to `jwks_uri`,
  - persistence of the new `jwks_uri` field,
  - rejection of xor violations and unsupported auth-method combinations.

## Verification

- `MIX_ENV=test mix test --warnings-as-errors test/lockspire/protocol/registration_test.exs`
- `MIX_ENV=test mix test --warnings-as-errors test/lockspire/protocol/registration_management_test.exs`

Both commands passed.

## Deviations from Plan

- None in owned phase files.
- Execution environment note: unrelated in-flight repo changes outside this plan also exist in the worktree. They were not modified.

## Known Stubs

- None.

## Self-Check: PASSED

- Summary file exists.
- Commit `7a93cc7` exists.
- Commit `15732ca` exists.
