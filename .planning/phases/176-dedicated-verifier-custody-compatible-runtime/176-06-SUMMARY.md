---
phase: 176-dedicated-verifier-custody-compatible-runtime
plan: "06"
subsystem: security
tags: [client-secret-jwt, verifier-custody, endpoint-compatibility, guarded-issuance]

requires:
  - phase: 176-dedicated-verifier-custody-compatible-runtime
    provides: Dedicated verifier readers, final-ID writers, and approved lifetime behavior from Plans 01–05
  - phase: 175-accepted-baseline-verifier-compatibility-contract
    provides: Frozen endpoint matrix, assertion rules, and ciphertext-sensitive issuance authority
provides:
  - Endpoint regression coverage for all existing positive client_secret_jwt callers and preserved PAR/FAPI exclusions
  - Persisted authorization-code exchange regression for ciphertext-sensitive guarded issuance
affects: [client-secret-jwt, verifier-custody, token-exchange, phase-177-maintenance]

actuals:
  tokens: 7241
  tasks: 2
  commits: 4
commits: 4
plan_head_before: 37e4b1e66f2dfe156ffe3ad4c50a8b275c752554
plan_head_after: d62fd1a1b418089fc13fefb9dae63f6d464beeab

tech-stack:
  added: []
  patterns:
    - Exercise the existing endpoint entry points with dedicated verifier custody and bounded error observations
    - Re-seal the same secret to produce a ciphertext-only credential identity change before the guarded persisted issuance check

key-files:
  created:
    - test/lockspire/protocol/client_secret_verifier_endpoints_test.exs
    - test/integration/client_secret_verifier_guarded_issuance_test.exs
  modified: []

key-decisions:
  - "Preserve device authorization and CIBA JWT support as shipped, while retaining PAR and both FAPI exclusions."
  - "Keep this guarded-issuance proof sequential; concurrent maintenance contention and rollback remain Phase 177 work."

requirements-completed: [SEC-03, SEC-05, VUP-01]

coverage:
  - id: D1
    description: "Dedicated and explicitly allowed legacy verifier reads retain the existing endpoint success matrix, assertion checks, replay behavior, and safe failure mapping."
    requirement: SEC-05
    verification:
      - kind: unit
        ref: test/lockspire/protocol/client_secret_verifier_endpoints_test.exs#READER-INTROSPECTION-REVOCATION and READER-PAR-DEVICE-CIBA
        status: pass
      - kind: unit
        ref: test/lockspire/protocol/client_secret_verifier_endpoints_test.exs#READER-HS256-AUDIENCE-JTI-EXCLUSIONS
        status: pass
      - kind: unit
        ref: test/lockspire/protocol/client_secret_verifier_endpoints_test.exs#READER-UNAVAILABLE and READER-KEY-ROTATION
        status: pass
    human_judgment: false
  - id: D2
    description: "Persisted token exchange rejects a ciphertext-only verifier change without successful code, token, or grant effects; the consumed JTI replays and a fresh JTI succeeds."
    requirement: SEC-03
    verification:
      - kind: integration
        ref: test/integration/client_secret_verifier_guarded_issuance_test.exs#READER-TOKEN-EXCHANGE
        status: pass
    human_judgment: false

duration: 6 min
completed: 2026-10-25
status: complete
---

# Phase 176 Plan 06: Endpoint and Guarded Issuance Summary

**Dedicated verifier custody preserves all five shipped JWT endpoint families and rejects token issuance when persisted verifier ciphertext changes after authentication.**

## Performance

- **Duration:** 6 min
- **Started:** 2026-10-25T22:30:40Z
- **Completed:** 2026-10-25T22:36:47Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- Added endpoint acceptance for introspection, revocation, device authorization, and CIBA through their actual protocol entry points. Successful introspection returns an active payload, revocation timestamps only its authorized target, device authorization persists a device code, and CIBA persists an `auth_req_id`.
- Kept `client_secret_jwt` excluded from PAR and both FAPI security profiles. Tested dedicated custody, explicit legacy allow/reject, retained old-key reads with a new current key, missing versus empty versus unavailable verifier mapping, key/identity mismatch, tampering, and invalid-present configuration.
- Pinned HS256-only signing, issuer-string audience, issuer identity, required non-empty JTI, assertion age/expiry, replay ordering, and public `invalid_client` redaction. Failure and replay telemetry contains only client ID, auth method, and reason code.
- Added a PostgreSQL-backed authorization-code + PKCE exchange using a persisted dedicated verifier. A fresh encryption of the same secret changes only ciphertext; the existing current-authority guard rejects issuance, keeps the authorization code unredeemed, adds no token or grant, and leaves the consumed JTI rejected on replay. A fresh assertion/JTI succeeds against the current ciphertext.

## Case IDs and Effects

| Stable case | Outcome and persisted effects |
|---|---|
| `READER-INTROSPECTION-REVOCATION` | Dedicated introspection succeeds with `active: true`; authorized revocation sets `revoked_at` on the selected token. |
| `READER-PAR-DEVICE-CIBA` | Device authorization and CIBA succeed and persist their records; PAR remains `unsupported_token_endpoint_auth_method`. |
| `READER-LEGACY-ALLOW` / `READER-LEGACY-REJECT` | Legacy verifier succeeds only with explicit allow; reject returns unavailable `invalid_client` without endpoint success effects. |
| `READER-UNAVAILABLE` / `READER-KEY-ROTATION` | Missing and empty verifier map to missing; malformed, wrong-key, wrong-identity, tampered, and invalid-present material map to unavailable. Retained old key remains readable when another key is current. |
| `READER-HS256-AUDIENCE-JTI-EXCLUSIONS` | Invalid issuer/audience/signature/algorithm/JTI/age requests produce no endpoint success effects. Valid replay inserts once and then returns `client_assertion_replayed`. |
| `READER-TOKEN-EXCHANGE` | Ciphertext-only change rejects with `credential_changed`; JTI count increases once, but code remains unredeemed and token/grant counts do not change. Same assertion replays; fresh JTI redeems and issues successfully. |

The issuance regression is a deterministic sequential change between persisted authentication fetch and guarded row reload. It does not prove a concurrent PostgreSQL maintenance transaction, contention, or rollback; those remain assigned to Phase 177.

## Task Commits

1. **Task 1:** - `b1ce61a2` — `test(176-06): cover dedicated verifier endpoint compatibility`
2. **Task 2:** - `fc23bd3f` — `test(176-06): guard token issuance against verifier changes`
3. **Task 1: formatting refinement** - `ff85351a` — `test(176-06): format endpoint regression matrix`
4. **Task 1: coverage refinement** - `d62fd1a1` — `test(176-06): assert endpoint telemetry redaction`

## Files Created

- `test/lockspire/protocol/client_secret_verifier_endpoints_test.exs` — direct protocol endpoint, policy, replay, redaction, and support-boundary acceptance.
- `test/integration/client_secret_verifier_guarded_issuance_test.exs` — real persisted ClientAuth and token exchange, with ciphertext-only authority mutation and fresh-JTI retry.

## TDD Notes

Both plan tasks add regression acceptance around behavior that was already implemented. Each test file was created before its focused command was run; the first failures were fixture setup issues (lifetime authority declaration and missing signing-key fixture), not product behavior. After correcting the test fixtures, the behavior passed. No artificial RED failure or product-source change was introduced.

## Verification

- `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 mix test test/lockspire/protocol/client_secret_verifier_endpoints_test.exs test/lockspire/protocol/direct_client_auth_client_secret_jwt_test.exs` — passed, 10 tests, 0 failures.
- `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 MIX_ENV=test mix test --include integration test/integration/client_secret_verifier_guarded_issuance_test.exs` — passed, 2 tests, 0 failures.
- `git diff --check` — passed.
- No product source, dependency, schema, protocol-support, signing, or frozen Phase 175 contract file was changed.

## Decisions Made

- Existing positive support for token exchange, introspection, revocation, device authorization, and CIBA is contractual behavior; PAR and FAPI remain excluded.
- The regression is strictly sequential and leaves real maintenance contention proof to its assigned phase.

## Deviations from Plan

None. The tasks remained test-only; test-fixture setup was corrected without changing product code.

## Known Stubs

None found in the files created by this plan.

## Threat Flags

None. The plan adds acceptance tests only and introduces no runtime trust boundary or production surface.

## Self-Check: PASSED

- Both declared test files exist.
- Task commits `b1ce61a2`, `fc23bd3f`, `ff85351a`, and `d62fd1a1` are ancestors of `HEAD`.
- The two focused verification commands pass, and `git diff --check` is clean.

---
*Phase: 176-dedicated-verifier-custody-compatible-runtime*
*Completed: 2026-10-25*
