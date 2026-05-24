---
phase: 34-token-issuance-and-refresh-device-binding
verified: 2026-04-28T17:52:59Z
status: passed
score: 9/9 must-haves verified
overrides_applied: 0
---

# Phase 34: Token Issuance and Refresh/Device Binding Verification Report

**Phase Goal:** The token endpoint can issue and rotate DPoP-bound tokens on the Lockspire-owned grant paths without breaking the existing bearer default.
**Verified:** 2026-04-28T17:52:59Z
**Status:** passed
**Re-verification:** No - initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Authorization-code exchanges for DPoP-mode clients require a valid proof and collapse missing or invalid proofs to `invalid_dpop_proof`. | ✓ VERIFIED | `TokenEndpointDPoP.resolve_context/2` resolves policy, validates proof, and maps failures to `invalid_dpop_proof` in [lib/lockspire/protocol/token_endpoint_dpop.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/token_endpoint_dpop.ex:24), [lib/lockspire/protocol/token_endpoint_dpop.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/token_endpoint_dpop.ex:61), [lib/lockspire/protocol/token_endpoint_dpop.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/token_endpoint_dpop.ex:68); exercised in [test/lockspire/protocol/token_exchange_test.exs](/Users/jon/projects/lockspire/test/lockspire/protocol/token_exchange_test.exs:191). |
| 2 | Successful DPoP auth-code exchanges return `token_type: "DPoP"` while bearer auth-code behavior stays bearer. | ✓ VERIFIED | Auth-code flow threads `issuance_context` from shared resolver and emits `issuance_context.token_type` in [lib/lockspire/protocol/token_exchange.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/token_exchange.ex:89), [lib/lockspire/protocol/token_exchange.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/token_exchange.ex:564); protocol and controller assertions live in [test/lockspire/protocol/token_exchange_test.exs](/Users/jon/projects/lockspire/test/lockspire/protocol/token_exchange_test.exs:219) and [test/lockspire/web/token_controller_test.exs](/Users/jon/projects/lockspire/test/lockspire/web/token_controller_test.exs:175). |
| 3 | DPoP auth-code issuance persists durable `cnf.jkt` on both access and refresh tokens. | ✓ VERIFIED | Access and refresh builders persist `issuance_context.cnf` in [lib/lockspire/protocol/token_exchange.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/token_exchange.ex:861), [lib/lockspire/protocol/token_exchange.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/token_exchange.ex:995); asserted in [test/lockspire/protocol/token_exchange_test.exs](/Users/jon/projects/lockspire/test/lockspire/protocol/token_exchange_test.exs:258). |
| 4 | A DPoP-bound refresh token only rotates when the presented proof is bound to the stored refresh-token key. | ✓ VERIFIED | Refresh exchange resolves DPoP context from the presented refresh token and passes `expected_cnf` into atomic rotation in [lib/lockspire/protocol/refresh_exchange.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/refresh_exchange.ex:58), [lib/lockspire/protocol/refresh_exchange.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/refresh_exchange.ex:272); repository compares `record.cnf != expected_cnf` under lock in [lib/lockspire/storage/ecto/repository.ex](/Users/jon/projects/lockspire/lib/lockspire/storage/ecto/repository.ex:1365). |
| 5 | Refresh proof-key mismatch collapses publicly to `invalid_grant` while retaining a private mismatch reason. | ✓ VERIFIED | Repository returns `:dpop_binding_mismatch` and protocol maps it to `invalid_grant` with reason `:refresh_dpop_binding_mismatch` in [lib/lockspire/protocol/refresh_exchange.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/refresh_exchange.ex:297), [lib/lockspire/protocol/refresh_exchange.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/refresh_exchange.ex:308); asserted in [test/lockspire/protocol/refresh_exchange_test.exs](/Users/jon/projects/lockspire/test/lockspire/protocol/refresh_exchange_test.exs:291). |
| 6 | Missing, malformed, replayed, stale, or otherwise invalid refresh proofs remain public `invalid_dpop_proof` failures. | ✓ VERIFIED | Refresh proof validation reuses the shared DPoP validator and replay recorder in [lib/lockspire/protocol/token_endpoint_dpop.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/token_endpoint_dpop.ex:85), [lib/lockspire/protocol/token_endpoint_dpop.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/token_endpoint_dpop.ex:106); missing and malformed proof cases are covered in [test/lockspire/protocol/refresh_exchange_test.exs](/Users/jon/projects/lockspire/test/lockspire/protocol/refresh_exchange_test.exs:332), [test/lockspire/protocol/refresh_exchange_test.exs](/Users/jon/projects/lockspire/test/lockspire/protocol/refresh_exchange_test.exs:369). |
| 7 | Rotated child access and refresh tokens preserve the original family `cnf.jkt` binding. | ✓ VERIFIED | Rotation stores `cnf: expected_cnf` on both child refresh and child access tokens in [lib/lockspire/storage/ecto/repository.ex](/Users/jon/projects/lockspire/lib/lockspire/storage/ecto/repository.ex:1573), [lib/lockspire/storage/ecto/repository.ex](/Users/jon/projects/lockspire/lib/lockspire/storage/ecto/repository.ex:1596); asserted in [test/lockspire/protocol/refresh_exchange_test.exs](/Users/jon/projects/lockspire/test/lockspire/protocol/refresh_exchange_test.exs:263). |
| 8 | Approved device-code redemption can issue DPoP-bound tokens at the winning `/token` request without changing the host-owned `/verify` seam. | ✓ VERIFIED | Device flow resolves shared issuance context only during token redemption in [lib/lockspire/protocol/token_exchange.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/token_exchange.ex:132), [lib/lockspire/protocol/token_exchange.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/token_exchange.ex:505); generated-host integration proves approval still occurs through `/verify` before DPoP binding at `/lockspire/token` in [test/integration/phase32_device_flow_token_exchange_e2e_test.exs](/Users/jon/projects/lockspire/test/integration/phase32_device_flow_token_exchange_e2e_test.exs:117). |
| 9 | DPoP device clients receive `token_type: "DPoP"` with durable `cnf.jkt`, while bearer device clients keep the existing contract and replay semantics. | ✓ VERIFIED | Device grant success reuses shared token shaping and persistence in [lib/lockspire/protocol/token_exchange.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/token_exchange.ex:525), [lib/lockspire/protocol/token_exchange.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/token_exchange.ex:576), [lib/lockspire/protocol/token_exchange.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/token_exchange.ex:920); asserted in [test/lockspire/protocol/token_exchange_test.exs](/Users/jon/projects/lockspire/test/lockspire/protocol/token_exchange_test.exs:890), [test/lockspire/protocol/token_exchange_test.exs](/Users/jon/projects/lockspire/test/lockspire/protocol/token_exchange_test.exs:956), and [test/integration/phase32_device_flow_token_exchange_e2e_test.exs](/Users/jon/projects/lockspire/test/integration/phase32_device_flow_token_exchange_e2e_test.exs:157). |

**Score:** 9/9 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `lib/lockspire/protocol/token_endpoint_dpop.ex` | Shared token-endpoint DPoP context for auth-code and refresh/device flows | ✓ VERIFIED | Exists, is substantive, and is wired from auth-code and refresh/device entrypoints via `resolve_context/2` and `resolve_refresh_context/3`. |
| `lib/lockspire/protocol/token_exchange.ex` | Shared issuance path for auth-code and device with truthful `token_type` and durable `cnf` | ✓ VERIFIED | Exists, persists `issuance_context.cnf`, shapes success from `issuance_context.token_type`, and consumes approved device authorizations. |
| `lib/lockspire/protocol/refresh_exchange.ex` | Refresh rotation enforcement and truthful DPoP/bearer response shaping | ✓ VERIFIED | Exists, resolves refresh DPoP context, passes `expected_cnf` into rotation, and emits `token_type` from context. |
| `lib/lockspire/storage/token_store.ex` | Persistence contract for atomic refresh rotation with binding input | ✓ VERIFIED | Callback includes `expected_cnf()` and is used by refresh rotation. |
| `lib/lockspire/storage/ecto/repository.ex` | Atomic compare-and-write refresh rotation plus child persistence carrying `cnf` | ✓ VERIFIED | Compares stored/presented binding under lock and stores rotated children with `cnf: expected_cnf`. |
| `lib/lockspire/web/controllers/token_controller.ex` | Thin controller capture of raw DPoP header and HTTP method | ✓ VERIFIED | Controller only captures request surface and delegates to protocol. |
| `test/lockspire/protocol/token_endpoint_dpop_test.exs` | Proof of bearer vs DPoP context resolution and `invalid_dpop_proof` failures | ✓ VERIFIED | Covers bearer context, DPoP context, and missing-proof failure. |
| `test/lockspire/protocol/token_exchange_test.exs` | Protocol proof for auth-code and device DPoP issuance plus bearer preservation | ✓ VERIFIED | Covers auth-code DPoP issuance, replay handling, DPoP device redemption, and bearer device preservation. |
| `test/lockspire/protocol/refresh_exchange_test.exs` | Proof of DPoP refresh rotation, mismatch collapse, and proof failure handling | ✓ VERIFIED | Covers successful DPoP rotation, wrong-key `invalid_grant`, missing/malformed `invalid_dpop_proof`, and family reuse. |
| `test/lockspire/web/token_controller_test.exs` | HTTP proof of truthful DPoP token responses | ✓ VERIFIED | Verifies `/token` returns `DPoP` for DPoP-mode auth-code clients and persists bound `cnf`. |
| `test/integration/phase32_device_flow_token_exchange_e2e_test.exs` | Host-approved device flow proof that DPoP binding happens only at `/token` | ✓ VERIFIED | Confirms `/verify` approval stays host-owned and winning token response becomes `DPoP`. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `lib/lockspire/web/controllers/token_controller.ex` | `lib/lockspire/protocol/token_endpoint_dpop.ex` | raw `dpop` header and `conn.method` forwarded into protocol-owned context resolution | ✓ WIRED | Controller forwards `dpop` and `method` to `TokenExchange.exchange/1` in [lib/lockspire/web/controllers/token_controller.ex](/Users/jon/projects/lockspire/lib/lockspire/web/controllers/token_controller.ex:17); `TokenExchange` then invokes `TokenEndpointDPoP.resolve_context/2` in [lib/lockspire/protocol/token_exchange.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/token_exchange.ex:87). |
| `lib/lockspire/protocol/token_endpoint_dpop.ex` | `lib/lockspire/protocol/token_exchange.ex` | `issuance_context` carries `token_type` and `cnf` into issuance | ✓ WIRED | Auth-code and device branches both receive `issuance_context` from shared DPoP resolution in [lib/lockspire/protocol/token_exchange.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/token_exchange.ex:89) and [lib/lockspire/protocol/token_exchange.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/token_exchange.ex:137). |
| `lib/lockspire/protocol/token_exchange.ex` | `lib/lockspire/storage/ecto/repository.ex` | access/refresh token persistence carrying `issuance_context.cnf` | ✓ WIRED | TokenExchange sets `cnf: issuance_context.cnf` on access and refresh tokens in [lib/lockspire/protocol/token_exchange.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/token_exchange.ex:861), [lib/lockspire/protocol/token_exchange.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/token_exchange.ex:930), [lib/lockspire/protocol/token_exchange.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/token_exchange.ex:1005); repository persists those token structs. |
| `lib/lockspire/protocol/refresh_exchange.ex` | `lib/lockspire/protocol/token_endpoint_dpop.ex` | refresh-specific DPoP context resolution | ✓ WIRED | Refresh path calls `TokenEndpointDPoP.resolve_refresh_context/3` in [lib/lockspire/protocol/refresh_exchange.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/refresh_exchange.ex:58). |
| `lib/lockspire/protocol/refresh_exchange.ex` | `lib/lockspire/storage/token_store.ex` | atomic `rotate_refresh_token` contract with `expected_cnf` | ✓ WIRED | Refresh path derives `expected_cnf = context.cnf` and passes it into store rotation in [lib/lockspire/protocol/refresh_exchange.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/refresh_exchange.ex:272); callback is defined in [lib/lockspire/storage/token_store.ex](/Users/jon/projects/lockspire/lib/lockspire/storage/token_store.ex:31). |
| `lib/lockspire/storage/ecto/repository.ex` | `lib/lockspire/domain/token.ex` | rotated child tokens carry forward presented refresh binding | ✓ WIRED | Repository writes `cnf: expected_cnf` onto rotated child refresh and access tokens in [lib/lockspire/storage/ecto/repository.ex](/Users/jon/projects/lockspire/lib/lockspire/storage/ecto/repository.ex:1590) and [lib/lockspire/storage/ecto/repository.ex](/Users/jon/projects/lockspire/lib/lockspire/storage/ecto/repository.ex:1614). |
| `lib/lockspire/protocol/token_exchange.ex` | `test/integration/phase32_device_flow_token_exchange_e2e_test.exs` | winning `/lockspire/token` device response returns truthful DPoP `token_type` | ✓ WIRED | Device branch resolves shared issuance context at redemption time in [lib/lockspire/protocol/token_exchange.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/token_exchange.ex:132); integration asserts `first_token_body["token_type"] == "DPoP"` in [test/integration/phase32_device_flow_token_exchange_e2e_test.exs](/Users/jon/projects/lockspire/test/integration/phase32_device_flow_token_exchange_e2e_test.exs:168). |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| `lib/lockspire/protocol/token_exchange.ex` | `issuance_context` | `TokenEndpointDPoP.resolve_context/2` | Yes - policy resolution plus DPoP proof validation/replay storage derive real `token_type` and `cnf` from request state in [lib/lockspire/protocol/token_endpoint_dpop.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/token_endpoint_dpop.ex:24) | ✓ FLOWING |
| `lib/lockspire/protocol/refresh_exchange.ex` | `context.cnf` | `TokenEndpointDPoP.resolve_refresh_context/3` plus repository `fetch_refresh_token/1` | Yes - context comes from persisted refresh-token `cnf` and validated proof in [lib/lockspire/protocol/token_endpoint_dpop.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/token_endpoint_dpop.ex:34) | ✓ FLOWING |
| `lib/lockspire/protocol/token_exchange.ex` | `device_authorization` | `device_authorization_store.record_device_poll/3` and `consume_device_authorization/3` | Yes - approved/consumed device state is loaded and mutated through repository-backed stores, not hardcoded props, in [lib/lockspire/protocol/token_exchange.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/token_exchange.ex:213), [lib/lockspire/protocol/token_exchange.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/token_exchange.ex:891) | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Auth-code DPoP context and issuance | `MIX_ENV=test mix test test/lockspire/protocol/token_endpoint_dpop_test.exs test/lockspire/protocol/token_exchange_test.exs` | `23 tests, 0 failures` | ✓ PASS |
| Refresh-token DPoP rotation and binding mismatch handling | `MIX_ENV=test mix test test/lockspire/protocol/refresh_exchange_test.exs` | `11 tests, 0 failures` | ✓ PASS |
| HTTP `/token` plus generated-host device-flow integration | `MIX_ENV=test mix test test/lockspire/web/token_controller_test.exs test/integration/phase32_device_flow_token_exchange_e2e_test.exs` | `14 tests, 0 failures` | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| `DPoP-05` | `34-01-PLAN.md` | `POST /token` supports DPoP-bound authorization-code exchange for DPoP-mode clients and returns truthful DPoP token responses. | ✓ SATISFIED | Shared DPoP resolution is called from auth-code exchange in [lib/lockspire/protocol/token_exchange.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/token_exchange.ex:83); truthful `DPoP` response proven in [test/lockspire/protocol/token_exchange_test.exs](/Users/jon/projects/lockspire/test/lockspire/protocol/token_exchange_test.exs:219) and [test/lockspire/web/token_controller_test.exs](/Users/jon/projects/lockspire/test/lockspire/web/token_controller_test.exs:175). |
| `DPoP-06` | `34-01-PLAN.md` | DPoP-bound access tokens persist confirmation (`cnf`) state sufficient for later Lockspire-owned validation. | ✓ SATISFIED | Access and refresh token structs persist `issuance_context.cnf` in [lib/lockspire/protocol/token_exchange.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/token_exchange.ex:861), [lib/lockspire/protocol/token_exchange.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/token_exchange.ex:1005); verified in [test/lockspire/protocol/token_exchange_test.exs](/Users/jon/projects/lockspire/test/lockspire/protocol/token_exchange_test.exs:271). |
| `DPoP-07` | `34-02-PLAN.md` | Refresh-token exchange preserves DPoP binding semantics and rejects wrong-key or missing/invalid proof use. | ✓ SATISFIED | Refresh exchange enforces binding with repository compare-and-write in [lib/lockspire/protocol/refresh_exchange.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/refresh_exchange.ex:262) and [lib/lockspire/storage/ecto/repository.ex](/Users/jon/projects/lockspire/lib/lockspire/storage/ecto/repository.ex:1365); tests cover DPoP success, wrong-key `invalid_grant`, and proof failures in [test/lockspire/protocol/refresh_exchange_test.exs](/Users/jon/projects/lockspire/test/lockspire/protocol/refresh_exchange_test.exs:263), [test/lockspire/protocol/refresh_exchange_test.exs](/Users/jon/projects/lockspire/test/lockspire/protocol/refresh_exchange_test.exs:291), [test/lockspire/protocol/refresh_exchange_test.exs](/Users/jon/projects/lockspire/test/lockspire/protocol/refresh_exchange_test.exs:332). |
| `DPoP-08` | `34-03-PLAN.md` | Device-code exchange supports DPoP mode for public and CLI-oriented clients without widening the host-owned verification seam. | ✓ SATISFIED | Device grant reuses shared issuance context at token redemption in [lib/lockspire/protocol/token_exchange.ex](/Users/jon/projects/lockspire/lib/lockspire/protocol/token_exchange.ex:132); protocol and generated-host integration prove DPoP device issuance at `/token` while `/verify` stays the approval seam in [test/lockspire/protocol/token_exchange_test.exs](/Users/jon/projects/lockspire/test/lockspire/protocol/token_exchange_test.exs:890) and [test/integration/phase32_device_flow_token_exchange_e2e_test.exs](/Users/jon/projects/lockspire/test/integration/phase32_device_flow_token_exchange_e2e_test.exs:117). |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| None | - | No blocker or warning-level stub patterns found in the phase implementation files. The only grep hits were benign empty-list fallbacks in rotated token field inheritance. | ℹ️ Info | No impact on phase-goal achievement. |

### Human Verification Required

None.

### Gaps Summary

No functional gaps were found against the phase goal, roadmap success criteria, or plan-level must-haves. The only minor note from verification is that the plan text's suggested `mix test ... -x` command is stale for this Mix version; the equivalent phase-targeted suites passed without `-x`, so this does not block goal achievement.

---

_Verified: 2026-04-28T17:52:59Z_  
_Verifier: Claude (gsd-verifier)_
