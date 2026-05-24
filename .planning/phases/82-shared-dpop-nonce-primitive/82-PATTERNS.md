# Phase 82: Shared DPoP Nonce Primitive - Pattern Map

## Target Files -> Closest Analogs

| Target file | Role | Closest analogs | Why |
|-------------|------|-----------------|-----|
| `lib/lockspire/protocol/dpop_nonce.ex` | New shared primitive | `lib/lockspire/protocol/dpop.ex`, `lib/lockspire/protocol/mtls_token_binding.ex` | Small protocol-owned helper with reusable security-sensitive logic and no HTTP rendering. |
| `lib/lockspire/protocol/dpop.ex` | Canonical proof-validator integration | existing file, `.planning/phases/33-dpop-proof-validation-and-replay-state/33-01-PLAN.md` | Already owns typed claim validation and should stay the single proof-validation seam. |
| `lib/lockspire/protocol/token_endpoint_dpop.ex` | Token-side typed error mapping | existing file | Already maps validator failures into endpoint-safe OAuth errors. |
| `lib/lockspire/protocol/protected_resource_dpop.ex` | Protected-resource typed error mapping | existing file | Already maps validator failures into DPoP-aware invalid-token errors. |
| `test/lockspire/protocol/dpop_nonce_test.exs` | Dedicated primitive proof | `test/lockspire/protocol/dpop_test.exs` | Best place to prove purpose separation and expiry without dragging in controller concerns. |
| `test/lockspire/protocol/token_endpoint_dpop_test.exs` | Authorization-server adoption proof | existing file | Existing seam already asserts typed DPoP failure mapping. |
| `test/lockspire/protocol/protected_resource_dpop_test.exs` | Resource-server adoption proof | existing file | Mirrors the token-endpoint mapping on the protected-resource path. |

## Concrete Reuse Notes

### `lib/lockspire/protocol/dpop.ex`

Reuse:

- `validate_proof/2`
- typed `validate_reason` atoms
- claim-validation option parsing

Likely change:

- add a nonce-validation branch that runs only when `nonce_purpose:` is present
- thread `secret_key_base` and nonce age through the existing validation opts

### `lib/lockspire/protocol/token_endpoint_dpop.ex`

Reuse:

- existing `validate_proof_value/2` wrapper
- typed reason mapping into endpoint-safe `Error` structs

Likely change:

- handle `:missing_dpop_nonce` and `:invalid_dpop_nonce` as their own typed branch without disturbing other DPoP failures

### `lib/lockspire/protocol/protected_resource_dpop.ex`

Reuse:

- existing `validate_proof/3` wrapper
- DPoP-aware invalid-token error mapping

Likely change:

- same nonce-specific typed branch as token endpoint, but preserving protected-resource challenge semantics

## Code Excerpts To Mirror

### Typed validator failure branching

Mirror the existing pattern where protocol callers branch on specific atoms first, then collapse the rest into generic DPoP invalidity:

```elixir
case DPoP.validate_proof(proof, opts) do
  {:ok, validated_proof} -> {:ok, validated_proof}
  {:error, specific_reason} -> ...
end
```

### Shared security helper shape

Mirror the narrow helper shape used by `MTLSTokenBinding`: pure issue/validate helpers with caller-provided input and no transport coupling.

## Test Patterns To Copy

### Dedicated protocol helper proof

Use `test/lockspire/protocol/dpop_test.exs` as the pattern for:

- isolated positive/negative proof cases
- typed atom assertions
- deterministic reference time and helper-generated input

### Adapter-level typed reason proof

Use `test/lockspire/protocol/token_endpoint_dpop_test.exs` and `test/lockspire/protocol/protected_resource_dpop_test.exs` as the pattern for:

- asserting the right public error type from a specific validator failure
- keeping transport/controller assertions out of the primitive phase

## Anti-Patterns To Avoid

- Endpoint-specific nonce parsing logic duplicated in multiple protocol modules
- Returning HTTP status tuples directly from `DPoPNonce` or `DPoP`
- Making nonce validation mandatory for all proof validations by default
- Introducing storage or background cleanup for a primitive that can stay stateless
