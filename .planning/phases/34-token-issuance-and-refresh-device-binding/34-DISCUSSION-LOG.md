# Phase 34: Token Issuance and Refresh/Device Binding - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in `34-CONTEXT.md`.

**Date:** 2026-04-28
**Phase:** 34-token-issuance-and-refresh-device-binding
**Mode:** assumptions + advisor research
**Areas analyzed:** durable binding state, enforcement topology, shared issuance pipeline, public
contract and error semantics

## Assumptions Presented

### Durable Binding State

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| DPoP binding should be persisted durably in `Token.cnf` and should cover the actual tokens later validated, not just transient request context. | Confident | `lib/lockspire/domain/token.ex`, `lib/lockspire/storage/ecto/token_record.ex`, `.planning/phases/33-dpop-proof-validation-and-replay-state/33-PATTERNS.md` |
| Refresh semantics are most coherent when the same binding truth is carried across the token family instead of derived indirectly. | Likely | `lib/lockspire/protocol/refresh_exchange.ex`, `.planning/STATE.md`, advisor research on RFC 9449 / Keycloak / Duende |

### Enforcement Topology

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Thin adapters plus protocol-owned token semantics are the idiomatic shape for Lockspire and similar successful libraries. | Confident | `lib/lockspire/web/controllers/token_controller.ex`, `lib/lockspire/protocol/token_exchange.ex`, advisor research on OpenIddict / Spring Authorization Server / `oidc-provider` |
| Repository code should own atomic compare-and-write behavior but not become the primary DPoP protocol engine. | Confident | `lib/lockspire/storage/ecto/repository.ex`, existing refresh rotation pattern, advisor research |

### Shared Issuance Pipeline

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Phase 34 should extend the shared issuance path instead of creating DPoP-specific grant branches. | Confident | `.planning/phases/32-polling-token-issuance/32-CONTEXT.md`, `lib/lockspire/protocol/token_exchange.ex`, advisor research on Spring / `oidc-provider` |
| Device flow should bind DPoP at `/token` redemption, not at host verification approval time. | Confident | `.planning/phases/32-polling-token-issuance/32-CONTEXT.md`, `test/integration/phase32_device_flow_token_exchange_e2e_test.exs`, advisor research |

### Public Contract and Error Semantics

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Truthful DPoP-bound access-token responses should return `token_type: "DPoP"` while bearer stays unchanged. | Confident | `.planning/ROADMAP.md`, `lib/lockspire/web/controllers/token_json.ex`, advisor research on RFC 9449 |
| Proof-object failures and refresh binding failures should use different public error families. | Likely | current `invalid_dpop_proof` auth-code preflight tests, `RefreshExchange` invalid_grant precedent, advisor research on mature server behavior |

## Research Applied

### Durable Binding State

- Compared access-token-only binding, token-family binding, sidecar tables, and transient-only
  models.
- Recommendation: persist `cnf.jkt` on both access and refresh tokens and treat it as token-family
  truth.

### Enforcement Topology

- Compared protocol-owned central enforcement, Plug/controller-owned enforcement, duplicated
  per-grant enforcement, and storage-primary enforcement.
- Recommendation: thin controller + protocol-owned central DPoP handling, with repository support
  only for atomic persistence checks.

### Shared Issuance Pipeline

- Compared shared additive pipeline, per-grant DPoP issuers, and hybrid formatter/builder models.
- Recommendation: one shared issuance pipeline with a small internal DPoP issuance context.

### Public Contract and Error Semantics

- Compared broad `invalid_dpop_proof`, split error-family mapping, bearer-compat token type, and
  custom public errors.
- Recommendation: `token_type: "DPoP"` on success; keep proof-object failures under
  `invalid_dpop_proof`; collapse refresh binding mismatch to `invalid_grant`.

## Corrections Made

No user corrections were required. The user requested a deeper one-shot research-backed
recommendation set and asked that low/medium-impact choices be shifted left when coherent.

## Final Locked Direction

- Durable binding truth lives in `Token.cnf` on both access and refresh tokens.
- DPoP is threaded through the shared token pipeline with a protocol-owned issuance context.
- Device flow keeps the host seam unchanged and binds at `/token` redemption.
- Public success responses are truthful (`token_type: "DPoP"`), while public errors remain
  standards-shaped and non-proprietary.
- Downstream GSD work should prefer decisive coherent defaults and escalate only the truly
  high-impact calls.
