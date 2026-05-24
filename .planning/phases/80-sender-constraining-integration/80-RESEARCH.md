# Phase 80: Sender-Constraining Integration (DPoP & MTLS) - Research

**Researched:** 2026-05-23
**Domain:** Phoenix Plug resource-server validation, DPoP protected-resource enforcement, MTLS certificate binding
**Confidence:** HIGH

## Summary

Phase 80 should keep the Phase 79 "soft verify / strict require" shape intact while introducing a third, sender-constraint-aware step between them. The repo already contains the hard protocol logic needed for this phase in `Lockspire.Protocol.ProtectedResourceDPoP`, `Lockspire.Protocol.Userinfo`, and `Lockspire.Protocol.TokenEndpointDPoP`; the resource-server plugs should reuse and generalize those primitives rather than re-implement DPoP or MTLS checks in plug code.

**Primary recommendation:** keep `Lockspire.Plug.VerifyToken` responsible only for parsing the `Authorization` scheme, validating the JWT, and assigning `%Lockspire.AccessToken{}` with extracted `cnf` binding metadata. Add a new `Lockspire.Plug.EnforceSenderConstraints` soft plug that reads `conn.assigns.access_token`, validates DPoP and MTLS bindings when present, and mutates the assigned token error state so `Lockspire.Plug.RequireToken` can remain the single halting boundary that emits either `Bearer` or `DPoP` `WWW-Authenticate` challenges.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| JWT extraction and verification | `Lockspire.Plug.VerifyToken` | `Lockspire.KeyCache` | Preserve the hot-path JWT validation split from Phase 79. |
| Sender-constraint enforcement | `Lockspire.Plug.EnforceSenderConstraints` | `ProtectedResourceDPoP` / MTLS thumbprint helper | Keep transport-bound checks explicit and composable. |
| Error rendering / `WWW-Authenticate` | `Lockspire.Plug.RequireToken` | access-token error mapping | Maintain one strict halting boundary. |
| DPoP proof semantics | `Lockspire.Protocol.ProtectedResourceDPoP` | `Lockspire.Protocol.DPoP` | Existing proof validation already handles `htm`, `htu`, `iat`, `jti`, `ath`, and replay. |
| MTLS thumbprint enforcement | shared helper extracted from `Userinfo` / `TokenEndpointDPoP` | `Lockspire.MTLS.Extractor` seam | Avoid duplicate `x5t#S256` hashing logic. |

## Recommended Architecture

### 1. Preserve the Three-Plug Pipeline

Recommended pipeline for resource-server routes:

```elixir
plug Lockspire.Plug.VerifyToken
plug Lockspire.Plug.EnforceSenderConstraints,
  dpop_replay_store: Lockspire.Config.repo(),
  mtls_extractor: {Lockspire.MTLS.CowboyDirectExtractor, []}
plug Lockspire.Plug.RequireToken
```

Behavior split:

- `VerifyToken` remains soft and never halts.
- `EnforceSenderConstraints` remains soft and only acts when a verified token has `cnf`.
- `RequireToken` remains strict and emits the HTTP failure response.

This matches the existing Phase 79 locked decision while keeping sender constraints opt-in and explicit.

### 2. Reuse `ProtectedResourceDPoP` Instead of Rewriting DPoP Logic

The repo already has a protected-resource DPoP validator in `lib/lockspire/protocol/protected_resource_dpop.ex`. It already validates:

- `Authorization: DPoP`
- presence of `DPoP` proof header
- proof signature and algorithm policy through `Lockspire.Protocol.DPoP`
- `htm`, `htu`, `iat`, `jti`
- `ath` binding against the raw access token
- `jkt` token binding against `cnf`
- replay detection through an injected store

Phase 80 should extract or generalize this logic so the new plug can validate arbitrary Phoenix requests, not just the hard-coded `/userinfo` endpoint. The likely seam is a new generic function such as:

```elixir
Lockspire.Protocol.ProtectedResourceDPoP.validate_access(token, request)
```

where `request` includes:

- `authorization_scheme`
- `access_token`
- `dpop`
- `method`
- `target_uri`
- `opts`

The existing `validate_userinfo_access/2` can then become a thin wrapper over the generic function.

### 3. Normalize `cnf` Into `AccessToken`

`VerifyToken` should populate existing `%Lockspire.AccessToken{}` fields from JWT claims:

- `binding_type: "dpop"` and `binding_thumbprint: cnf["jkt"]` for DPoP-bound access tokens
- `binding_type: "mtls"` and `binding_thumbprint: cnf["x5t#S256"]` for MTLS-bound access tokens
- if both exist, prefer a deterministic representation such as `binding_type: "dpop+mtls"` while leaving raw claims intact in `claims["cnf"]`

This lets downstream plugs branch on assigned token metadata without reparsing claims repeatedly.

### 4. Keep MTLS Validation as a Shared Helper

The same `x5t#S256` validation exists today in:

- `lib/lockspire/protocol/userinfo.ex`
- `lib/lockspire/protocol/token_endpoint_dpop.ex`

Phase 80 should extract a shared helper or module so the sender-constraint plug, userinfo flow, and refresh-path validation all rely on the same thumbprint comparison and error semantics.

Expected check:

```elixir
actual_thumbprint = :crypto.hash(:sha256, cert) |> Base.url_encode64(padding: false)
expected_thumbprint == actual_thumbprint
```

### 5. Prefer a Narrow Replay Store Seam, But Stay Compatible With Existing Store Contracts

The phase context recommends an ETS-backed replay cache seam for resource servers. The current code already depends on a generic `record_dpop_proof/1` callback shape through injected stores. That means Phase 80 does not need a greenfield replay API; it can:

- keep using the existing `record_dpop_proof/1` contract shape
- add a lightweight in-memory implementation suitable for resource-server use
- allow host apps to keep using `Config.repo!()` when they want durable replay semantics

This gives low-friction embedded DX without breaking the current repo patterns.

## Concrete File Impact

### Likely source files to modify

- `lib/lockspire/plug/verify_token.ex`
- `lib/lockspire/plug/require_token.ex`
- `lib/lockspire/access_token.ex`
- `lib/lockspire/protocol/protected_resource_dpop.ex`
- `lib/lockspire/protocol/userinfo.ex`
- `lib/lockspire/protocol/token_endpoint_dpop.ex`

### Likely new source files

- `lib/lockspire/plug/enforce_sender_constraints.ex`
- `lib/lockspire/protocol/mtls_token_binding.ex` or similar shared helper
- optional lightweight replay-store adapter, if the phase chooses the ETS path

### Likely tests to add or expand

- `test/lockspire/plug/enforce_sender_constraints_test.exs`
- `test/lockspire/plug/verify_token_test.exs`
- `test/lockspire/plug/require_token_test.exs`
- `test/lockspire/protocol/protected_resource_dpop_test.exs`
- `test/lockspire/web/userinfo_controller_test.exs`
- `test/lockspire/protocol/token_endpoint_dpop_test.exs`

## Implementation Notes

### Authorization scheme handling

`VerifyToken` currently only accepts `Authorization: Bearer`. Phase 80 should allow both:

- `Authorization: Bearer <token>`
- `Authorization: DPoP <token>`

but it should not treat the scheme itself as proof that the token is DPoP-bound. The scheme is part of sender-constraint enforcement, not JWT validity.

### Error mapping strategy

`RequireToken` currently emits only Bearer challenges. Phase 80 needs deterministic mapping from token error reasons to challenge type:

- generic token parse/signature/time errors -> `Bearer`
- DPoP-bound token presented without `Authorization: DPoP` -> `DPoP`
- missing/invalid DPoP proof for a DPoP-bound token -> `DPoP`
- replay / `ath` mismatch / `jkt` mismatch -> `DPoP`
- MTLS certificate missing or mismatch -> `Bearer` is acceptable unless the product explicitly defines a dedicated MTLS challenge surface

For DPoP challenges, mirror the existing userinfo behavior by including the allowed algorithms (`algs="..."`) from `Lockspire.Protocol.DPoP.signing_alg_values_supported/1`.

### Logging and observability

Reuse the current DPoP failure telemetry pattern from `ProtectedResourceDPoP`:

- emit structured reason codes
- never log raw access tokens or raw proofs
- log DPoP vs MTLS failure classes distinctly so operators can diagnose edge/proxy issues separately from proof misuse

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit |
| Config file | `test/test_helper.exs` |
| Quick run command | `mix test test/lockspire/plug/enforce_sender_constraints_test.exs` |
| Full suite command | `mix test` |

### Phase Requirements -> Test Map

| Requirement | Behavior | Test Type | Automated Command | File Exists? |
|-------------|----------|-----------|-------------------|-------------|
| VAL-BIND-01 | DPoP `cnf` tokens require matching request proof and thumbprint | unit | `mix test test/lockspire/plug/enforce_sender_constraints_test.exs` | ❌ Wave 0 |
| VAL-BIND-02 | MTLS `cnf` tokens require matching extracted client certificate | unit | `mix test test/lockspire/plug/enforce_sender_constraints_test.exs` | ❌ Wave 0 |
| VAL-BIND-03 | Binding failures reject the request path through `RequireToken` | unit | `mix test test/lockspire/plug/require_token_test.exs` | ✅ |
| VAL-DX-02 | DPoP failures emit `WWW-Authenticate: DPoP` with RFC-aware fields | unit | `mix test test/lockspire/plug/require_token_test.exs` | ✅ |
| VAL-DX-03 | Failure reasons remain differentiated in logs / telemetry | unit | `mix test test/lockspire/protocol/protected_resource_dpop_test.exs` | ✅ |

### Sampling Rate

- After every task commit: run the directly affected ExUnit file
- After every plan wave: run `mix test`
- Before phase verification: full suite green

### Wave 0 Gaps

- `test/lockspire/plug/enforce_sender_constraints_test.exs`

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes | Validate proof-of-possession requirements before treating token as usable |
| V3 Session Management | yes | Short-lived DPoP proof acceptance window and replay rejection |
| V4 Access Control | yes | Reject constrained tokens when sender proof or certificate is missing |
| V5 Input Validation | yes | Strict parsing of authorization scheme, DPoP proof JWT, and certificate material |
| V6 Cryptography | yes | JOSE proof signature verification and SHA-256 thumbprint matching |

### Known Threat Patterns

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| DPoP proof replay | Replay / Elevation of Privilege | Record `jti` + `jkt` + `htm` + `htu` within the proof validity window |
| Wrong-key proof substitution | Spoofing | Enforce `cnf["jkt"] == proof.jkt` |
| Access-token substitution | Tampering | Enforce `ath` against the raw presented access token |
| Proxy/header certificate spoofing | Spoofing | Require explicit extractor configuration and trust only host-owned extraction seams |
| Scheme downgrade (`DPoP` token over `Bearer`) | Elevation of Privilege | Require `Authorization: DPoP` when token `cnf` contains `jkt` |
| Certificate mismatch bypass | Tampering | Compare `x5t#S256` against the extracted DER certificate thumbprint |

## Recommended Plan Shape

This phase is best split into 3 plans:

1. Shared protocol and token-shape changes
2. DPoP sender-constraint plug integration
3. MTLS enforcement plus `RequireToken` challenge/error updates

That keeps the generic protocol reuse, plug integration, and error-surface changes independently testable.
