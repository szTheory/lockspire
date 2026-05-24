# Phase 82: Shared DPoP Nonce Primitive - Research

**Researched:** 2026-05-23
**Domain:** shared DPoP nonce issuance and validator integration inside Lockspire's existing protocol seams
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- One shared protocol-owned nonce primitive, not separate endpoint implementations.
- Stateless nonce issuance/validation rooted in `secret_key_base`.
- Explicit purpose separation between authorization-server and resource-server nonces.
- Nonce checks compose into `Lockspire.Protocol.DPoP.validate_proof/2`.
- Typed internal nonce failures, no new operator/client policy knobs, no widened product surface.

### Deferred Ideas (OUT OF SCOPE)

- Durable nonce storage
- New admin/discovery/DCR surface
- Full endpoint retry contract proof
- Generated-host end-to-end validation

</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| NONCE-CORE-01 | Issue unpredictable nonce values separately for authorization-server and resource-server validation. | Use one primitive with explicit purpose-tagged issuance so downstream callers request either `:authorization_server` or `:resource_server` without sharing accepted values. |
| NONCE-CORE-02 | Reject nonce-enforced proofs when `nonce` is missing. | Extend the existing proof validator with an opt-in nonce check that returns `:missing_dpop_nonce` when the caller requested nonce enforcement. |
| NONCE-CORE-03 | Reject nonce-enforced proofs when the supplied nonce was not issued for that surface or is no longer recent. | Keep validation inside the primitive with typed `:invalid_dpop_nonce` results for wrong-purpose, malformed, or expired nonces. |
| NONCE-CORE-04 | Keep authorization-server and resource-server nonce values distinct. | Encode the purpose inside the signed nonce payload and compare it during validation rather than trusting endpoint-local context alone. |

</phase_requirements>

## Summary

Phase 82 fits cleanly into Lockspire's existing DPoP architecture if the nonce work stays protocol-owned and opt-in. The repo already has the right seam in `Lockspire.Protocol.DPoP.validate_proof/2`: it centralizes claim validation and returns typed failure reasons consumed by token-endpoint and protected-resource adapters. The shared nonce primitive should therefore be a small helper module plus one extra branch in the existing claim-validation path, not a new validator stack or HTTP-aware service.

The safest primitive shape is stateless signing rooted in `secret_key_base`. That matches Lockspire's embedded-library deployment model, avoids introducing a nonce table or background cleanup path, and lets any Lockspire-owned DPoP surface issue a retry nonce without coordinating storage. Purpose separation belongs inside the signed payload so downstream callers can validate a proof against the expected surface class and reject cross-surface reuse deterministically.

The plan split from the roadmap is the right one:

1. build the shared primitive and wire it into the validator seam
2. prove issuance, purpose separation, and typed failure propagation with focused tests

That keeps Phase 82 narrow and lets later phases adopt the primitive on `/token`, `/userinfo`, and the host plug pipeline without redesigning the underlying nonce logic.

**Primary recommendation:** implement `Lockspire.Protocol.DPoPNonce` as a stateless issue/validate helper rooted in `secret_key_base`, thread `nonce_purpose:` through `DPoP.validate_proof/2`, and keep all public HTTP challenge work in downstream endpoint adapters rather than inside the primitive.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Nonce minting and verification | protocol core | host secret-key seam | Keeps nonce truth protocol-owned while reusing the host app's existing signing root. |
| Proof-level `nonce` claim enforcement | `Lockspire.Protocol.DPoP` | `Lockspire.Protocol.DPoPNonce` | Preserves one canonical proof-validation path and typed reason contract. |
| Token-endpoint/public error mapping | token-endpoint adapter | web controller | Should stay outside the primitive so transport behavior remains a consumer concern. |
| Protected-resource/public error mapping | protected-resource adapter | userinfo/plug controller | Same reason: public challenge rendering belongs in consumers. |

## Recommended Plan Shape

### Plan 01: Primitive + Validator Wiring

Focus on:

- adding a dedicated `DPoPNonce` helper
- explicit purpose-tagged nonce issuance and verification
- optional nonce enforcement in `DPoP.validate_proof/2`
- typed nonce failures propagating into existing token and protected-resource DPoP adapters

### Plan 02: Proof Surface

Focus on:

- dedicated unit tests for `DPoPNonce`
- validator tests for missing/invalid nonce semantics
- protocol adapter tests proving purpose separation and typed `use_dpop_nonce` mapping inputs

## Concrete File Impact

### Likely source files to modify

- `lib/lockspire/protocol/dpop_nonce.ex`
- `lib/lockspire/protocol/dpop.ex`
- `lib/lockspire/protocol/token_endpoint_dpop.ex`
- `lib/lockspire/protocol/protected_resource_dpop.ex`

### Likely test files to add or expand

- `test/lockspire/protocol/dpop_nonce_test.exs`
- `test/lockspire/protocol/dpop_test.exs`
- `test/lockspire/protocol/token_endpoint_dpop_test.exs`
- `test/lockspire/protocol/protected_resource_dpop_test.exs`

## Pattern Guidance

### Reuse the Phase 33 validator style

`Lockspire.Protocol.DPoP` already validates claims in one pass and returns typed atoms. Nonce enforcement should be another claim-validation branch in that flow, not an endpoint wrapper that reparses proofs.

### Keep endpoint adapters thin

Token and protected-resource adapters should continue to interpret typed failure reasons and decide whether the public response is `invalid_dpop_proof` or `use_dpop_nonce`. The primitive should not know about HTTP status codes or headers.

### Avoid hidden global policy

If nonce validation needs parameters such as max age or secret key base, pass them explicitly through validation opts from the caller. That matches existing request-option seams and keeps the host boundary obvious.

## Validation Architecture

| Property | Value |
|----------|-------|
| Framework | ExUnit |
| Quick run command | `mix test test/lockspire/protocol/dpop_nonce_test.exs test/lockspire/protocol/dpop_test.exs` |
| Protocol run command | `mix test test/lockspire/protocol/token_endpoint_dpop_test.exs test/lockspire/protocol/protected_resource_dpop_test.exs` |
| Full suite command | `mix test` |

### Sampling Rate

- After primitive changes: run nonce and validator tests
- After adapter changes: run token/protected-resource protocol tests
- Before phase verification: full suite green

## Threat Notes

| Threat | Risk | Mitigation |
|--------|------|------------|
| Cross-surface nonce reuse | authorization-server nonce accepted on resource-server path | Encode and validate purpose inside the signed payload. |
| Predictable or forgeable nonce values | attacker can guess or mint acceptable nonces | Use signed opaque tokens with fresh random identifiers rooted in `secret_key_base`. |
| Drift between proof validator and endpoint adapters | different surfaces disagree on nonce semantics | Keep nonce checking in `DPoP.validate_proof/2` and surface only typed reasons to adapters. |
| Product-surface creep | phase widens into policy knobs or broader nonce infra | Keep Phase 82 limited to primitive and unit/protocol proof only. |
