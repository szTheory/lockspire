---
phase: 82-shared-dpop-nonce-primitive
verified: 2026-05-23T20:53:21Z
status: passed
score: 6/6 must-haves verified
overrides_applied: 0
---

# Phase 82: Shared DPoP Nonce Primitive Verification Report

**Phase Goal:** Add one shared DPoP nonce issuance and validation path without introducing new operator or client policy knobs.
**Verified:** 2026-05-23T20:53:21Z
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Lockspire owns one shared DPoP nonce primitive instead of separate token- and resource-side implementations. | ✓ VERIFIED | [lib/lockspire/protocol/dpop_nonce.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/dpop_nonce.ex:1) defines the single `Lockspire.Protocol.DPoPNonce` helper; token and protected-resource flows call into it rather than duplicating nonce signing logic at [token_endpoint_dpop.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/token_endpoint_dpop.ex:393) and [protected_resource_dpop.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/protected_resource_dpop.ex:327). |
| 2 | Authorization-server and resource-server nonces are purpose-separated, so cross-surface nonce reuse fails deterministically. | ✓ VERIFIED | Purpose is embedded in the signed payload and enforced during verification at [dpop_nonce.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/dpop_nonce.ex:16) and [dpop_nonce.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/dpop_nonce.ex:47); direct proof exists in [dpop_nonce_test.exs](/Users/jon/projects/lockspire/test/lockspire/protocol/dpop_nonce_test.exs:22), validator proof in [dpop_test.exs](/Users/jon/projects/lockspire/test/lockspire/protocol/dpop_test.exs:240), and both protocol suites assert wrong-purpose rejection at [token_endpoint_dpop_test.exs](/Users/jon/projects/lockspire/test/lockspire/protocol/token_endpoint_dpop_test.exs:101) and [protected_resource_dpop_test.exs](/Users/jon/projects/lockspire/test/lockspire/protocol/protected_resource_dpop_test.exs:125). |
| 3 | Nonce checking composes into the existing `Lockspire.Protocol.DPoP.validate_proof/2` seam and remains opt-in per caller. | ✓ VERIFIED | `validate_proof/2` still uses the existing shared claim-validation flow and adds `check_nonce/2` as an optional branch at [dpop.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/dpop.ex:123) and [dpop.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/dpop.ex:254); when `nonce_purpose` is absent it returns `:ok` at [dpop.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/dpop.ex:264). |
| 4 | Missing nonce and invalid, wrong-purpose, or stale nonce produce typed internal failures that downstream adapters can map without reparsing proofs. | ✓ VERIFIED | `DPoPNonce.validate/3` returns only `:missing_dpop_nonce` or `:invalid_dpop_nonce` at [dpop_nonce.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/dpop_nonce.ex:24); `DPoP.validate_proof/2` surfaces those typed atoms through `check_nonce/2` at [dpop.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/dpop.ex:255); direct proof covers missing, malformed, expired, and wrong-purpose cases at [dpop_nonce_test.exs](/Users/jon/projects/lockspire/test/lockspire/protocol/dpop_nonce_test.exs:43) and [dpop_test.exs](/Users/jon/projects/lockspire/test/lockspire/protocol/dpop_test.exs:216). |
| 5 | Token-endpoint and protected-resource DPoP consumers preserve nonce-specific failure distinctions. | ✓ VERIFIED | Token endpoint maps nonce failures first to `use_dpop_nonce` at [token_endpoint_dpop.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/token_endpoint_dpop.ex:149); protected-resource does the same at [protected_resource_dpop.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/protected_resource_dpop.ex:87); protocol tests assert those mappings at [token_endpoint_dpop_test.exs](/Users/jon/projects/lockspire/test/lockspire/protocol/token_endpoint_dpop_test.exs:81) and [protected_resource_dpop_test.exs](/Users/jon/projects/lockspire/test/lockspire/protocol/protected_resource_dpop_test.exs:116). |
| 6 | Phase 82 has repo-native proof for the shared primitive, typed validator failures, and both protocol consumers. | ✓ VERIFIED | Dedicated primitive tests exist at [dpop_nonce_test.exs](/Users/jon/projects/lockspire/test/lockspire/protocol/dpop_nonce_test.exs:1); validator tests at [dpop_test.exs](/Users/jon/projects/lockspire/test/lockspire/protocol/dpop_test.exs:200); protocol-consumer tests at [token_endpoint_dpop_test.exs](/Users/jon/projects/lockspire/test/lockspire/protocol/token_endpoint_dpop_test.exs:81) and [protected_resource_dpop_test.exs](/Users/jon/projects/lockspire/test/lockspire/protocol/protected_resource_dpop_test.exs:116). |

**Score:** 6/6 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `lib/lockspire/protocol/dpop_nonce.ex` | Stateless nonce issue/validate helper rooted in `secret_key_base` | ✓ VERIFIED | Exists, substantive, and used by the shared validator plus both protocol consumers. |
| `lib/lockspire/protocol/dpop.ex` | Optional nonce enforcement in the shared DPoP proof validator | ✓ VERIFIED | `check_nonce/2` is wired into the existing claim-validation path. |
| `lib/lockspire/protocol/token_endpoint_dpop.ex` | Authorization-server consumption of typed nonce validator failures | ✓ VERIFIED | Passes `nonce_purpose: :authorization_server` and maps typed nonce failures before generic proof errors. |
| `lib/lockspire/protocol/protected_resource_dpop.ex` | Resource-server consumption of typed nonce validator failures | ✓ VERIFIED | Passes `nonce_purpose: :resource_server` and maps typed nonce failures before generic proof errors. |
| `test/lockspire/protocol/dpop_nonce_test.exs` | Unit proof for issuance, validation, purpose separation, and expiry behavior | ✓ VERIFIED | Covers happy-path issuance, wrong-purpose, missing, malformed, and expired nonce behavior. |
| `test/lockspire/protocol/dpop_test.exs` | Shared validator proof for missing and invalid nonce reasons | ✓ VERIFIED | Asserts `:missing_dpop_nonce` and `:invalid_dpop_nonce` directly. |
| `test/lockspire/protocol/token_endpoint_dpop_test.exs` | Authorization-server nonce mapping proof | ✓ VERIFIED | Asserts `use_dpop_nonce` mapping for missing and wrong-purpose nonce cases. |
| `test/lockspire/protocol/protected_resource_dpop_test.exs` | Resource-server nonce mapping proof | ✓ VERIFIED | Asserts `use_dpop_nonce` mapping for missing and wrong-purpose nonce cases. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `lib/lockspire/protocol/dpop.ex` | `lib/lockspire/protocol/dpop_nonce.ex` | claim validation branch for `nonce` | ✓ WIRED | `check_nonce/2` calls `DPoPNonce.validate/3` when `nonce_purpose` is present at [dpop.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/dpop.ex:255). |
| `lib/lockspire/protocol/token_endpoint_dpop.ex` | `lib/lockspire/protocol/dpop.ex` | typed validator failure mapping | ✓ WIRED | `validate_proof_value/2` passes nonce opts to `DPoP.validate_proof/2` and maps typed nonce atoms first at [token_endpoint_dpop.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/token_endpoint_dpop.ex:134). |
| `lib/lockspire/protocol/protected_resource_dpop.ex` | `lib/lockspire/protocol/dpop.ex` | typed validator failure mapping | ✓ WIRED | `validate_proof/3` passes resource nonce opts to `DPoP.validate_proof/2` and maps typed nonce atoms first at [protected_resource_dpop.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/protected_resource_dpop.ex:72). |
| `test/lockspire/protocol/dpop_nonce_test.exs` | `lib/lockspire/protocol/dpop_nonce.ex` | direct primitive contract proof | ✓ WIRED | Tests call `issue/2` and `validate/3` directly. |
| `test/lockspire/protocol/dpop_test.exs` | `lib/lockspire/protocol/dpop.ex` | typed missing/invalid nonce assertions | ✓ WIRED | Tests call `DPoP.validate_proof/2` with `nonce_purpose:` and assert typed failure atoms. |
| `test/lockspire/protocol/token_endpoint_dpop_test.exs` | `lib/lockspire/protocol/token_endpoint_dpop.ex` | authorization-server nonce mapping proof | ✓ WIRED | Tests assert `use_dpop_nonce` for missing and wrong-purpose nonce failures. |
| `test/lockspire/protocol/protected_resource_dpop_test.exs` | `lib/lockspire/protocol/protected_resource_dpop.ex` | resource-server nonce mapping proof | ✓ WIRED | Tests assert `use_dpop_nonce` for missing and wrong-purpose nonce failures. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| `lib/lockspire/protocol/dpop_nonce.ex` | `"nonce"` claim / signed payload | `Plug.Crypto.sign` and `Plug.Crypto.verify` around a payload containing `purpose` and random `nonce_id` | Yes | ✓ FLOWING |
| `lib/lockspire/protocol/dpop.ex` | `nonce_purpose` validation result | `DPoPNonce.validate/3` result returned from `check_nonce/2` into `validate_claims/2` | Yes | ✓ FLOWING |
| `lib/lockspire/protocol/token_endpoint_dpop.ex` | nonce-specific `Error` struct | `DPoP.validate_proof/2` typed failure plus `DPoPNonce.issue/2` for challenge nonce | Yes | ✓ FLOWING |
| `lib/lockspire/protocol/protected_resource_dpop.ex` | nonce-specific `Error` struct | `DPoP.validate_proof/2` typed failure plus `DPoPNonce.issue/2` for challenge nonce | Yes | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Shared primitive and validator proof stay green | `mix test test/lockspire/protocol/dpop_nonce_test.exs test/lockspire/protocol/dpop_test.exs` | `32 tests, 0 failures` | ✓ PASS |
| Token and protected-resource protocol mappings stay green | `mix test test/lockspire/protocol/token_endpoint_dpop_test.exs test/lockspire/protocol/protected_resource_dpop_test.exs` | `14 tests, 0 failures` | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| `NONCE-CORE-01` | `82-01`, `82-02` | Issue unpredictable nonce values separately for authorization-server and resource-server validation. | ✓ SATISFIED | Single primitive issues signed nonces with random `nonce_id` and embedded `purpose` at [dpop_nonce.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/dpop_nonce.ex:16); direct tests cover issuance and purpose separation at [dpop_nonce_test.exs](/Users/jon/projects/lockspire/test/lockspire/protocol/dpop_nonce_test.exs:8). |
| `NONCE-CORE-02` | `82-01`, `82-02` | Reject nonce-enforced proofs when the proof omits `nonce`. | ✓ SATISFIED | `DPoPNonce.validate/3` returns `:missing_dpop_nonce` for missing claims at [dpop_nonce.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/dpop_nonce.ex:29); validator and adapter tests assert that behavior at [dpop_test.exs](/Users/jon/projects/lockspire/test/lockspire/protocol/dpop_test.exs:216), [token_endpoint_dpop_test.exs](/Users/jon/projects/lockspire/test/lockspire/protocol/token_endpoint_dpop_test.exs:81), and [protected_resource_dpop_test.exs](/Users/jon/projects/lockspire/test/lockspire/protocol/protected_resource_dpop_test.exs:116). |
| `NONCE-CORE-03` | `82-01`, `82-02` | Reject nonce-enforced proofs when the supplied nonce was not issued for that surface or is no longer recent. | ✓ SATISFIED | Purpose and age are enforced inside `verify_nonce/3` at [dpop_nonce.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/dpop_nonce.ex:40); expiry and wrong-purpose cases are covered at [dpop_nonce_test.exs](/Users/jon/projects/lockspire/test/lockspire/protocol/dpop_nonce_test.exs:57) and [dpop_test.exs](/Users/jon/projects/lockspire/test/lockspire/protocol/dpop_test.exs:240). |
| `NONCE-CORE-04` | `82-01`, `82-02` | Keep authorization-server and resource-server nonce values distinct. | ✓ SATISFIED | Signed nonce payload stores `purpose` and validation compares it against the caller’s required surface at [dpop_nonce.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/dpop_nonce.ex:47); wrong-purpose adapter regressions are covered on both surfaces. |

Requirement note: the plan frontmatter correctly declares `NONCE-CORE-01` through `NONCE-CORE-04`, and those IDs exist in [.planning/REQUIREMENTS.md](/Users/jon/projects/lockspire/.planning/REQUIREMENTS.md:4). The earlier `requirements.mark-complete` miss appears to be an orchestration lookup issue, not a missing requirements definition.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| `test/lockspire/protocol/dpop_nonce_test.exs` | 8 | Partial happy-path coverage | ⚠️ Warning | The dedicated primitive suite asserts direct success only for `:authorization_server`; `:resource_server` success is exercised indirectly through wrong-purpose and adapter tests. This does not block the phase goal, but a symmetric direct success assertion would tighten proof. |

### Human Verification Required

None.

### Gaps Summary

No goal-level gaps found. The phase goal is achieved in the codebase: one shared nonce primitive exists, the shared proof validator owns opt-in nonce validation, typed nonce failures propagate into both protocol consumers, and the targeted protocol tests pass. No new operator or client policy knob was introduced in the phase-owned protocol seam; nonce behavior is driven by existing request options and hard-coded surface purposes rather than new persisted policy state.

---

_Verified: 2026-05-23T20:53:21Z_
_Verifier: Claude (gsd-verifier)_
