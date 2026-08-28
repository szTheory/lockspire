---
phase: 129-token-endpoint-cohesion
verified: 2026-08-26T16:40:30Z
status: passed
score: "4/4 must-haves verified"
behavior_unverified: 0
---

# Phase 129 Verification: Token Endpoint Cohesion

**Verdict:** `passed` — token grant orchestration remains behind its stable
facade, while lifetime and private-key policy are centralized and fail closed.
This report records the existing v1.36 evidence; no commands were rerun.

## Roadmap Success Criteria and Requirement Coverage

| Success criterion | Requirement | Status | Existing evidence |
| --- | --- | --- | --- |
| Grant-specific coordinators reduce `TokenExchange` complexity without changing its public API or structs. | ARCH-04 | VERIFIED | Plans 129-01, 129-05, and 129-06 extracted authorization-code, device-code, and CIBA coordination behind `Lockspire.Protocol.TokenExchange`. The milestone matrix confirms the duplicate `GrantSupport.exchange/1` router is absent and the facade remains stable. |
| One internal policy owns existing token lifetime defaults. | RUNTIME-03 | VERIFIED | Plans 129-01 and 129-02 established `TokenLifetime` as the sole 3600/3600/2592000 policy and routed all five consumers through it. The milestone matrix independently confirms those values and consumers. |
| Every signing path uses one fail-closed private-key decoder. | RUNTIME-04 | VERIFIED | Plans 129-03 and 129-04 introduced and completed `PrivateJwk.decode/1` adoption for access, ID, JARM, introspection, logout, and JAR signing paths. The milestone matrix confirms safe JSON/binary-term map acceptance and fail-closed decoding. |
| Dialyzer is a cached required CI gate with zero warnings and no blanket ignore file. | STATIC-02 | VERIFIED | Plans 129-07 and 129-08 resolved warning roots and installed an ordinary required cached CI job with a fail-closed runner. The milestone matrix confirms the lock/version cache key, 20-minute bound, no warning filter, and zero-warning baseline. |

## Historical Verification Evidence

- Plan summaries record focused capability, facade-routing, exact-value, private
  JWK, device, CIBA, Dialyzer, and CI workflow proof.
- The milestone review independently recorded RUNTIME-03, RUNTIME-04, ARCH-04,
  and STATIC-02 as verified, including a focused re-verification of the token
  facade contract.

## Caveat

Focused proof invocations elsewhere in the milestone can emit a KeyCache startup
error before `Lockspire.TestRepo` is available, plus Telemetry local-handler
performance notices. The milestone records these as avoidable proof noise; they
did not fail tests and do not change this phase's passing verdict.
