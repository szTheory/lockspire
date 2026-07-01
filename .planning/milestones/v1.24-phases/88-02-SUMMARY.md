---
phase: 88
plan: 2
subsystem: auth
tags: [oauth, oidc, client-auth, jwt, client-secret-jwt, storage]
requires:
  - phase: 88-01
    provides: runtime JWT auth-method routing and dispatch
provides:
  - Sealed verifier material for client_secret_jwt alongside hashed client secrets
  - Strict HS256-only verifier with issuer/audience/lifetime/replay enforcement
  - FAPI-effective denial and redaction-safe observability for the symmetric verifier
affects: [88-03, registration, admin, storage, redaction]
tech-stack:
  added: []
  patterns: [seal verifier material with endpoint secret_key_base, preserve hash-at-rest plus sealed verifier split]
key-files:
  created:
    - lib/lockspire/protocol/client_auth/client_secret_jwt.ex
    - priv/repo/migrations/20260525120000_add_client_secret_jwt_verifier_material_to_lockspire_clients.exs
  modified:
    - lib/lockspire/security/policy.ex
    - lib/lockspire/domain/client.ex
    - lib/lockspire/storage/ecto/client_record.ex
    - lib/lockspire/storage/ecto/repository.ex
    - lib/lockspire/clients.ex
    - lib/lockspire/admin/clients.ex
    - lib/lockspire/protocol/registration.ex
    - lib/lockspire/redaction.ex
key-decisions:
  - "client_secret_jwt verifier material is sealed with the Lockspire endpoint secret_key_base instead of widening raw-secret persistence."
  - "The symmetric verifier accepts HS256 only and fails closed under FAPI-effective profiles."
patterns-established:
  - "Confidential secret issuance and rotation now persist both password-style secret hashes and sealed verifier material when direct-client symmetric JWT support needs it."
requirements-completed: [AUTH-01, AUTH-02]
duration: 45min
completed: 2026-05-25
---

# Phase 88 Plan 2 Summary

**Lockspire now has a sealed `client_secret_jwt` verifier path that preserves hashed-at-rest secret posture while enforcing HS256-only, issuer-bound, replay-safe client assertions**

## Performance

- **Duration:** 45 min
- **Started:** 2026-05-25T05:00:00Z
- **Completed:** 2026-05-25T05:45:00Z
- **Tasks:** 3
- **Files modified:** 10

## Accomplishments

- Added a dedicated `ClientSecretJwt` verifier that enforces HS256-only signatures, issuer-string audience, bounded lifetime, required timing claims, and replay recording after successful verification.
- Introduced sealed verifier material persistence on client secret issuance and rotation paths while keeping the existing `client_secret_hash` behavior intact for password-style auth.
- Extended redaction and repo-backed persistence tests so verifier material never leaks through audit or telemetry metadata.

## Task Commits

1. **Task 88-02-01: persist sealed verifier material on issuance and rotation paths** - working tree
2. **Task 88-02-02: implement strict HS256-only verifier behavior with explicit FAPI denial** - working tree
3. **Task 88-02-03: extend audit and negative-path proof** - working tree

## Files Created/Modified

- `lib/lockspire/protocol/client_auth/client_secret_jwt.ex` - symmetric JWT verifier with signature, claim, replay, telemetry, and audit handling.
- `lib/lockspire/security/policy.ex` - seals and unseals verifier material via `secret_key_base`.
- `lib/lockspire/domain/client.ex` - adds durable `client_secret_jwt_verifier_encrypted` state.
- `lib/lockspire/storage/ecto/client_record.ex` - persists the sealed verifier field through create/update flows.
- `lib/lockspire/storage/ecto/repository.ex` - rotates secret hash and sealed verifier material together.
- `lib/lockspire/clients.ex` - issues sealed verifier material when confidential secrets are created.
- `lib/lockspire/admin/clients.ex` - rotates sealed verifier material on operator secret rotation.
- `lib/lockspire/protocol/registration.ex` - persists sealed verifier material for self-service confidential secrets.
- `lib/lockspire/redaction.ex` - strips sealed verifier material from telemetry and audit surfaces.
- `priv/repo/migrations/20260525120000_add_client_secret_jwt_verifier_material_to_lockspire_clients.exs` - adds durable storage for sealed symmetric verifier material.

## Decisions Made

- The verifier uses the host app’s existing endpoint secret base for sealing rather than introducing a parallel secret store or recoverable host seam.
- FAPI-effective profiles deny `client_secret_jwt` outright instead of treating symmetric algorithms as part of the normal signing allowlist.

## Deviations from Plan

- Registration and admin secret lifecycle code needed to move in this phase because valid `client_secret_jwt` success cannot work from hash-only secret storage.

## Issues Encountered

- The earlier research note assumed hash-only storage might be enough, but implementation confirmed the approved plan was correct: a sealed verifier source was required for real HS256 verification.

## User Setup Required

None.

## Next Phase Readiness

- Plan 88-03 can now prove the full runtime slice across representative direct-client surfaces using a real symmetric verifier success path.

---
*Phase: 88*
*Completed: 2026-05-25*
