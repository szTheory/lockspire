---
phase: 59-registration-policy-metadata-truth
verified: 2026-05-06T19:05:00Z
status: passed
score: 7/7 must-haves verified
overrides_applied: 0
---

# Phase 59: Registration, Policy & Metadata Truth Verification Report

**Phase Goal:** Clients and operators can configure the `private_key_jwt` slice truthfully, and discovery/endpoint metadata advertise only what Lockspire will actually verify.
**Verified:** 2026-05-06T19:05:00Z
**Status:** passed
**Re-verification:** Yes - after correcting discovery metadata overclaim

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | A confidential client can register or update `jwks_uri` only within the supported `private_key_jwt` slice. | ✓ VERIFIED | `Registration.validate_jwks/1` rejects `jwks_uri` outside `private_key_jwt` and rejects non-`https` URIs in [registration.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/registration.ex:214); registration and RFC 7592 tests cover acceptance and rejection paths in [registration_test.exs](/Users/jon/projects/lockspire/test/lockspire/protocol/registration_test.exs:352) and [registration_management_test.exs](/Users/jon/projects/lockspire/test/lockspire/protocol/registration_management_test.exs:150). |
| 2 | `jwks` and `jwks_uri` stay mutually exclusive with explicit validation errors. | ✓ VERIFIED | `validate_jwks/1` returns `invalid_client_metadata` with `:mutually_exclusive_with_jwks_uri` in [registration.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/registration.ex:220); both protocol test files assert the explicit error in [registration_test.exs](/Users/jon/projects/lockspire/test/lockspire/protocol/registration_test.exs:384) and [registration_management_test.exs](/Users/jon/projects/lockspire/test/lockspire/protocol/registration_management_test.exs:179). |
| 3 | RFC 7592 updates persist the same `jwks_uri` truth as RFC 7591 registration intake. | ✓ VERIFIED | The update path reuses `Registration.validate_intake_metadata/3` and writes `jwks_uri` in `apply_metadata_to_client/2` in [registration_management.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/registration_management.ex:76) and [registration_management.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/registration_management.ex:242). |
| 4 | Operator-facing `private_key_jwt` policy truth is derived from existing server policy and security profile, not a new editable crypto plane. | ✓ VERIFIED | `Admin.ServerPolicy.private_key_jwt_registration_truth/1` derives the allowlist gate plus algorithms from `policy.security_profile` via `SecurityProfile.allowed_signing_algorithms/1` in [server_policy.ex](/Users/jon/projects/lockspire/lib/lockspire/admin/server_policy.ex:113). |
| 5 | Admin policy and client-detail surfaces explain the `private_key_jwt` slice truthfully and stay read-only for this slice. | ✓ VERIFIED | DCR policy help text explains self-registration posture and derived algorithms in [dcr.html.heex](/Users/jon/projects/lockspire/lib/lockspire/web/live/admin/policies_live/dcr.html.heex:53); client detail shows read-only `jwks_uri`/JWKS posture in [show.ex](/Users/jon/projects/lockspire/lib/lockspire/web/live/admin/clients_live/show.ex:183). |
| 6 | Discovery narrows endpoint metadata where runtime behavior is narrower, notably introspection omitting `private_key_jwt`. | ✓ VERIFIED | Discovery filters introspection to `client_secret_basic` and `client_secret_post` in [discovery.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/discovery.ex:236), matching `validate_confidential_caller/1` in [introspection.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/introspection.ex:86). |
| 7 | Discovery and endpoint metadata advertise `private_key_jwt` and signing algorithms only where Lockspire will actually verify JWT client assertions. | ✓ VERIFIED | Discovery now omits `private_key_jwt` and endpoint signing-algorithm fields from token, revocation, and introspection metadata until runtime signature verification exists in [discovery.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/discovery.ex:173); the protocol and controller tests pin that truthful omission in [discovery_test.exs](/Users/jon/projects/lockspire/test/lockspire/protocol/discovery_test.exs:99) and [discovery_controller_test.exs](/Users/jon/projects/lockspire/test/lockspire/web/discovery_controller_test.exs:102). |

**Score:** 7/7 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `lib/lockspire/protocol/registration.ex` | Narrow `jwks_uri` intake validation and self-registered persistence | ✓ VERIFIED | Enforces xor, `private_key_jwt` gating, `https` requirement, and persists `jwks_uri`. |
| `lib/lockspire/protocol/registration_management.ex` | RFC 7592 parity with registration truth | ✓ VERIFIED | Reuses intake validation and persists `jwks_uri` on full replace. |
| `lib/lockspire/admin/server_policy.ex` | Derived operator truth helper | ✓ VERIFIED | Computes allowlist truth and derived algorithms from existing policy/security profile. |
| `lib/lockspire/web/live/admin/policies_live/dcr.html.heex` | DCR policy explanation for the supported slice | ✓ VERIFIED | Exposes descriptive read-only posture text. |
| `lib/lockspire/web/live/admin/clients_live/show.ex` | Read-only client posture visibility | ✓ VERIFIED | Shows `jwks_uri`, inline JWKS presence, and derived algorithm posture without edit actions. |
| `lib/lockspire/protocol/discovery.ex` | Centralized endpoint auth metadata truth | ✓ VERIFIED | Centralized and route-aware, and now narrows token/revocation/introspection publication to methods the current runtime can truthfully verify. |
| `lib/lockspire/protocol/client_auth.ex` | Shared capability source for published `private_key_jwt` support | ✓ VERIFIED (bounded) | Still exposes the broader static seam, but discovery no longer treats that seam as proof of published runtime verification. |
| `test/lockspire/protocol/registration_test.exs` | DCR contract coverage | ✓ VERIFIED | Covers accepted/rejected `jwks_uri` matrix. |
| `test/lockspire/protocol/registration_management_test.exs` | RFC 7592 regression coverage | ✓ VERIFIED | Covers parity and persistence of `jwks_uri`. |
| `test/lockspire/admin/server_policy_test.exs` | Derived policy helper coverage | ✓ VERIFIED | Pins allowlist and security-profile-driven algorithm derivation. |
| `test/lockspire/web/live/admin/policies_live/dcr_test.exs` | DCR UI truth coverage | ✓ VERIFIED | Pins narrow explanatory UI copy. |
| `test/lockspire/web/live/admin/clients_live/show_test.exs` | Client detail read-only posture coverage | ✓ VERIFIED | Pins read-only `private_key_jwt` / `jwks_uri` display. |
| `test/lockspire/protocol/discovery_test.exs` | Metadata contract coverage | ✓ VERIFIED | Tests now pin the truthful omission of `private_key_jwt` and endpoint signing-algorithm publication until runtime verification exists. |
| `test/lockspire/web/discovery_controller_test.exs` | HTTP discovery contract coverage | ✓ VERIFIED | HTTP assertions match the corrected metadata truth. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `registration.ex` | `registration_management.ex` | shared `validate_intake_metadata` truth | ✓ WIRED | Management update path calls `Registration.validate_intake_metadata/3` in [registration_management.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/registration_management.ex:76). |
| `registration_management.ex` | `domain/client.ex` | durable `jwks_uri` field mapping | ✓ WIRED | `apply_metadata_to_client/2` maps `jwks_uri` into `%Client{}` in [registration_management.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/registration_management.ex:264). |
| `admin/server_policy.ex` | `security_profile.ex` | effective assertion signing algorithms | ✓ WIRED | Derived helper calls `SecurityProfile.allowed_signing_algorithms/1` in [server_policy.ex](/Users/jon/projects/lockspire/lib/lockspire/admin/server_policy.ex:115). |
| `web/live/admin/policies_live/dcr.ex` | `domain/server_policy.ex` | DCR allowlist truth | ✓ WIRED | LiveView loads policy and assigns derived `private_key_jwt_truth` from server policy in [dcr.ex](/Users/jon/projects/lockspire/lib/lockspire/web/live/admin/policies_live/dcr.ex:44). |
| `discovery.ex` | `client_auth.ex` | shared auth-method capability source | ✓ WIRED | Discovery still starts from the shared seam in [discovery.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/discovery.ex:49), then narrows publication to truthful runtime support. |
| `discovery.ex` | `security_profile.ex` | derived signing algorithms | ✓ WIRED | Metadata algorithm publication calls `SecurityProfile.allowed_signing_algorithms/1` in [discovery.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/discovery.ex:212). |
| `discovery.ex` | `introspection.ex` / `revocation.ex` | endpoint-specific truth predicates | ✓ WIRED | Introspection remains narrower and revocation now publishes only the currently verified secret-based methods. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| `lib/lockspire/protocol/discovery.ex` | `token_endpoint_auth_methods_supported` | static client-auth seam narrowed by discovery-side publication filter | Yes - only methods the current runtime truthfully supports are published | ✓ FLOWING |
| `lib/lockspire/protocol/discovery.ex` | `introspection_endpoint_auth_methods_supported` | shared list filtered by discovery predicate + `Introspection.validate_confidential_caller/1` | Yes | ✓ FLOWING |
| `lib/lockspire/admin/server_policy.ex` | `supported_assertion_signing_algorithms` | `SecurityProfile.allowed_signing_algorithms/1` from persisted server policy | Yes | ✓ FLOWING |
| `lib/lockspire/protocol/registration_management.ex` | updated `jwks_uri` field | `metadata["jwks_uri"]` persisted through `%Client{}` mapping | Yes | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Phase 59 protocol/admin/discovery test matrix passes | `MIX_ENV=test mix test --warnings-as-errors test/lockspire/protocol/registration_test.exs test/lockspire/protocol/registration_management_test.exs test/lockspire/admin/server_policy_test.exs test/lockspire/protocol/discovery_test.exs test/lockspire/web/discovery_controller_test.exs test/lockspire/web/live/admin/policies_live/dcr_test.exs test/lockspire/web/live/admin/clients_live/show_test.exs` | `117 tests, 0 failures` | ✓ PASS |
| Current `private_key_jwt` auth behavior remains payload-based, not cryptographic | `MIX_ENV=test mix test --warnings-as-errors test/lockspire/protocol/client_auth_test.exs` | `5 tests, 0 failures`; fixture assertions use a literal `"signature"` string and still succeed on the happy path | ✓ PASS |
| Discovery omits unverified JWT client-auth metadata | `MIX_ENV=test mix test --warnings-as-errors test/lockspire/protocol/discovery_test.exs test/lockspire/web/discovery_controller_test.exs` | `29 tests, 0 failures` | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| `REG-01` | `59-01` | DCR and RFC 7592 accept `jwks_uri` for the narrow `private_key_jwt` slice and reject unsupported combinations explicitly. | ✓ SATISFIED | Intake/update validators and protocol tests in [registration.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/registration.ex:214), [registration_management.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/registration_management.ex:76), [registration_test.exs](/Users/jon/projects/lockspire/test/lockspire/protocol/registration_test.exs:352), [registration_management_test.exs](/Users/jon/projects/lockspire/test/lockspire/protocol/registration_management_test.exs:150). |
| `REG-02` | `59-01` | `jwks_uri` acceptance stays `https`-only and bounded to the narrow client-auth slice. | ✓ SATISFIED | `https_uri?/1` enforcement and unsupported-auth rejection in [registration.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/registration.ex:237). |
| `REG-03` | `59-02` | Operator/admin surfaces truthfully expose whether self-registered `private_key_jwt` is allowed and which algorithms are accepted. | ✓ SATISFIED | Derived helper and read-only UI in [server_policy.ex](/Users/jon/projects/lockspire/lib/lockspire/admin/server_policy.ex:113), [dcr.html.heex](/Users/jon/projects/lockspire/lib/lockspire/web/live/admin/policies_live/dcr.html.heex:57), [show.ex](/Users/jon/projects/lockspire/lib/lockspire/web/live/admin/clients_live/show.ex:183). |
| `META-01` | `59-03` | Discovery truthfully advertises token-endpoint client authentication support and endpoint signing-algorithm metadata only when the corresponding method is actually supported. | ✓ SATISFIED | Token metadata now omits `private_key_jwt` and endpoint signing algorithms until runtime verification exists in [discovery.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/discovery.ex:173). |
| `META-02` | `59-03` | Revocation and introspection metadata truthfully advertise their supported client authentication methods and associated signing algorithms whenever `private_key_jwt` is accepted there. | ✓ SATISFIED | Revocation and introspection metadata now publish only the currently verified secret-based methods, and omit signing-algorithm fields while `private_key_jwt` remains unverified in [discovery.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/discovery.ex:224). |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| None | - | - | - | - |

### Gaps Summary

No gaps found. Phase 59 now keeps the registration/admin `private_key_jwt` slice configurable while ensuring discovery metadata stays bounded to what the current runtime actually verifies.

---

_Verified: 2026-05-06T19:05:00Z_
_Verifier: Claude (gsd-verifier)_
