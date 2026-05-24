---
phase: 83-lockspire-owned-dpop-endpoint-adoption
verified: 2026-05-24T17:23:01+02:00
status: passed
score: 6/6 truths verified
---

# Phase 83: Lockspire-owned DPoP Endpoint Adoption Verification Report

**Phase Goal:** Apply nonce challenge and retry behavior to the Lockspire-owned DPoP `/token` and protected-resource surfaces without widening the product shape or regressing existing sender-constraint behavior.
**Verified:** 2026-05-24T17:23:01+02:00
**Status:** passed
**Re-verification:** Yes — added after milestone audit flagged missing closure artifact

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Lockspire-owned `/token` DPoP exchanges now require an authorization-server nonce and return retryable `use_dpop_nonce` failures when a proof omits or misuses it. | ✓ VERIFIED | Token-side nonce enforcement is wired through `nonce_purpose: :authorization_server` and `secret_key_base` at [lib/lockspire/protocol/token_endpoint_dpop.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/token_endpoint_dpop.ex:142), then mapped to `use_dpop_nonce` plus issued nonce material at [lib/lockspire/protocol/token_endpoint_dpop.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/token_endpoint_dpop.ex:387). |
| 2 | Supported `/token` flows succeed on retry when the client replays the request with the supplied authorization-server nonce. | ✓ VERIFIED | Protocol proof covers authorization-code, device-code, CIBA, and refresh retry success at [test/lockspire/protocol/token_exchange_test.exs](/Users/jon/projects/lockspire/test/lockspire/protocol/token_exchange_test.exs:378), [test/lockspire/protocol/token_exchange_test.exs](/Users/jon/projects/lockspire/test/lockspire/protocol/token_exchange_test.exs:1167), [test/lockspire/protocol/token_exchange_test.exs](/Users/jon/projects/lockspire/test/lockspire/protocol/token_exchange_test.exs:1256), and [test/lockspire/protocol/refresh_exchange_test.exs](/Users/jon/projects/lockspire/test/lockspire/protocol/refresh_exchange_test.exs:294). |
| 3 | `/token` controller responses expose the shipped HTTP retry contract: `400`, OAuth `use_dpop_nonce`, and a `DPoP-Nonce` header. | ✓ VERIFIED | Controller coverage asserts the nonce challenge contract on the authorization-code and device-code surfaces at [test/lockspire/web/token_controller_test.exs](/Users/jon/projects/lockspire/test/lockspire/web/token_controller_test.exs:337) and [test/lockspire/web/token_controller_test.exs](/Users/jon/projects/lockspire/test/lockspire/web/token_controller_test.exs:673). |
| 4 | Lockspire-owned protected resources now require a resource-server nonce and surface retryable DPoP failures without adding a new host abstraction. | ✓ VERIFIED | Resource-side proof validation is wired through `nonce_purpose: :resource_server` and typed failure mapping at [lib/lockspire/protocol/protected_resource_dpop.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/protected_resource_dpop.ex:80) and [lib/lockspire/protocol/protected_resource_dpop.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/protected_resource_dpop.ex:321). |
| 5 | `/userinfo` returns the exact retry contract and succeeds after the client echoes the supplied resource-server nonce in a fresh proof. | ✓ VERIFIED | Controller proof asserts `WWW-Authenticate`, `DPoP-Nonce`, exposed headers, and retry success at [test/lockspire/web/userinfo_controller_test.exs](/Users/jon/projects/lockspire/test/lockspire/web/userinfo_controller_test.exs:233). |
| 6 | Existing replay, binding, `ath`, MTLS, wrong-scheme, and bearer semantics remain intact after nonce adoption. | ✓ VERIFIED | Regression coverage stays pinned in protocol and controller suites at [test/lockspire/protocol/token_endpoint_dpop_test.exs](/Users/jon/projects/lockspire/test/lockspire/protocol/token_endpoint_dpop_test.exs:81), [test/lockspire/protocol/protected_resource_dpop_test.exs](/Users/jon/projects/lockspire/test/lockspire/protocol/protected_resource_dpop_test.exs:116), and the full targeted phase run below. |

**Score:** 6/6 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `lib/lockspire/protocol/token_endpoint_dpop.ex` | Authorization-server nonce enforcement and retry nonce issuance on Lockspire-owned `/token` surfaces | ✓ VERIFIED | Enforces `nonce_purpose: :authorization_server` and returns issued nonce material on retryable failures. |
| `lib/lockspire/protocol/protected_resource_dpop.ex` | Resource-server nonce enforcement and retry nonce issuance on Lockspire-owned protected-resource surfaces | ✓ VERIFIED | Enforces `nonce_purpose: :resource_server` and returns issued nonce material on retryable failures. |
| `test/lockspire/protocol/token_endpoint_dpop_test.exs` | Token-side typed `use_dpop_nonce` mapping proof | ✓ VERIFIED | Covers missing and wrong-surface nonce behavior. |
| `test/lockspire/protocol/token_exchange_test.exs` | Retry-success proof for supported `/token` exchange modes | ✓ VERIFIED | Covers auth-code, device-code, and CIBA retry paths. |
| `test/lockspire/protocol/refresh_exchange_test.exs` | Retry-success proof for DPoP-bound refresh exchange | ✓ VERIFIED | Covers missing nonce challenge and successful retried refresh. |
| `test/lockspire/web/token_controller_test.exs` | HTTP `/token` retry contract proof | ✓ VERIFIED | Asserts response status, JSON error, and nonce header contract. |
| `test/lockspire/protocol/protected_resource_dpop_test.exs` | Resource-side typed `use_dpop_nonce` mapping proof | ✓ VERIFIED | Covers missing, wrong-surface, and retry-success behavior. |
| `test/lockspire/web/userinfo_controller_test.exs` | HTTP `/userinfo` retry contract proof | ✓ VERIFIED | Asserts `WWW-Authenticate`, `DPoP-Nonce`, exposed headers, and successful retried request. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `lib/lockspire/protocol/token_endpoint_dpop.ex` | shared DPoP validator | authorization-server nonce options | ✓ WIRED | `/token` proof validation passes authorization-server nonce requirements at [token_endpoint_dpop.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/token_endpoint_dpop.ex:142). |
| `lib/lockspire/protocol/token_endpoint_dpop.ex` | nonce issuer | retryable token error | ✓ WIRED | Retry failures issue a fresh authorization-server nonce at [token_endpoint_dpop.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/token_endpoint_dpop.ex:393). |
| `lib/lockspire/protocol/protected_resource_dpop.ex` | shared DPoP validator | resource-server nonce options | ✓ WIRED | Protected-resource proof validation passes resource-server nonce requirements at [protected_resource_dpop.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/protected_resource_dpop.ex:80). |
| `lib/lockspire/protocol/protected_resource_dpop.ex` | nonce issuer | retryable protected-resource error | ✓ WIRED | Retry failures issue a fresh resource-server nonce at [protected_resource_dpop.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/protected_resource_dpop.ex:327). |
| `test/lockspire/web/token_controller_test.exs` | token controller | concrete OAuth retry contract | ✓ WIRED | Tests prove `400` plus nonce challenge semantics on shipped `/token` endpoints. |
| `test/lockspire/web/userinfo_controller_test.exs` | userinfo controller | concrete resource retry contract | ✓ WIRED | Tests prove `401` plus DPoP challenge semantics on `/userinfo`. |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Token and userinfo nonce adoption subset stays green | `mix test test/lockspire/protocol/token_endpoint_dpop_test.exs test/lockspire/protocol/token_exchange_test.exs test/lockspire/protocol/refresh_exchange_test.exs test/lockspire/protocol/protected_resource_dpop_test.exs test/lockspire/web/token_controller_test.exs test/lockspire/web/userinfo_controller_test.exs` | `81 tests, 0 failures` | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| `NONCE-AS-01` | `83-01` | `/token` returns `400`, `use_dpop_nonce`, and `DPoP-Nonce` when a DPoP proof lacks a valid authorization-server nonce. | ✓ SATISFIED | [token_endpoint_dpop.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/token_endpoint_dpop.ex:387), [token_controller_test.exs](/Users/jon/projects/lockspire/test/lockspire/web/token_controller_test.exs:337) |
| `NONCE-AS-02` | `83-01` | Retried `/token` requests succeed when the proof includes the supplied authorization-server nonce and all existing DPoP checks still pass. | ✓ SATISFIED | [token_exchange_test.exs](/Users/jon/projects/lockspire/test/lockspire/protocol/token_exchange_test.exs:378), [refresh_exchange_test.exs](/Users/jon/projects/lockspire/test/lockspire/protocol/refresh_exchange_test.exs:294) |
| `NONCE-AS-03` | `83-01`, `83-03` | Existing `/token` DPoP behavior outside nonce handling remains unchanged. | ✓ SATISFIED | [token_endpoint_dpop_test.exs](/Users/jon/projects/lockspire/test/lockspire/protocol/token_endpoint_dpop_test.exs:81), full targeted phase suite above |
| `NONCE-RS-01` | `83-02` | Lockspire-owned protected resources return a DPoP-aware `401` plus `DPoP-Nonce` when the proof lacks a valid resource-server nonce. | ✓ SATISFIED | [protected_resource_dpop.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/protected_resource_dpop.ex:321), [userinfo_controller_test.exs](/Users/jon/projects/lockspire/test/lockspire/web/userinfo_controller_test.exs:233) |
| `NONCE-RS-02` | `83-02` | Retried protected-resource requests succeed when the proof includes the supplied resource-server nonce. | ✓ SATISFIED | [userinfo_controller_test.exs](/Users/jon/projects/lockspire/test/lockspire/web/userinfo_controller_test.exs:233) |
| `NONCE-RS-03` | `83-03` | Existing protected-resource sender-constraint behavior remains unchanged outside nonce handling. | ✓ SATISFIED | [protected_resource_dpop_test.exs](/Users/jon/projects/lockspire/test/lockspire/protocol/protected_resource_dpop_test.exs:116), full targeted phase suite above |

### Human Verification Required

None.

### Gaps Summary

No functional or evidence gaps remain in Phase 83. The milestone audit blocker for this phase was the missing verification artifact, and that closure evidence is now present with current passing test proof.

---

_Verified: 2026-05-24T17:23:01+02:00_
_Verifier: Codex_
