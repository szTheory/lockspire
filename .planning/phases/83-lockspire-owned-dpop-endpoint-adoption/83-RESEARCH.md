# Phase 83: Lockspire-owned DPoP Endpoint Adoption - Research

**Researched:** 2026-05-24
**Domain:** authorization-server and protected-resource nonce challenge/retry adoption on Lockspire-owned DPoP surfaces
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- Keep Phase 83 scoped to Lockspire-owned `/token` and `/userinfo` surfaces only.
- Use the existing protocol seams: `Lockspire.Protocol.TokenEndpointDPoP` for `/token` and `Lockspire.Protocol.ProtectedResourceDPoP` for protected-resource validation.
- Preserve exact RFC 9449 surface semantics:
  - `/token` nonce failures stay `400` + OAuth `use_dpop_nonce` + `DPoP-Nonce`
  - `/userinfo` nonce failures stay `401` + `WWW-Authenticate: DPoP ... error="use_dpop_nonce"` + `DPoP-Nonce`
- Keep missing-proof, replay, `ath`, key binding, MTLS, and bearer behavior otherwise unchanged.
- Keep RFC 8693 token exchange explicitly out of Phase 83 support claims.

### Deferred Ideas (OUT OF SCOPE)

- Generated-host nonce retry end-to-end proof
- Host plug nonce contract closure and public support-surface wording
- Generic gateway or third-party protected-resource middleware claims
- New nonce policy knobs or admin controls

</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| NONCE-AS-01 | `/token` must return `400 use_dpop_nonce` plus `DPoP-Nonce` when the proof is present but nonce is missing/invalid. | Keep nonce failure mapping inside `TokenEndpointDPoP`, then let `TokenController` stay a thin header/status adapter. |
| NONCE-AS-02 | Retried `/token` request with the supplied nonce must succeed when all other DPoP checks pass. | Reuse the existing `TokenEndpointDPoP.resolve_context/2` and `resolve_refresh_context/3` seams across authorization-code, device-code, CIBA, and DPoP-bound refresh exchanges. |
| NONCE-AS-03 | Existing `/token` missing-proof, replay, `ath`, binding, MTLS, and bearer behavior must remain unchanged. | Add focused protocol and controller regressions instead of rewriting grant-specific flows. |
| NONCE-RS-01 | `/userinfo` must return a DPoP-aware `401` challenge plus `DPoP-Nonce` on missing/invalid resource nonce. | Keep nonce error classification in `ProtectedResourceDPoP`; `UserinfoController` should only render challenge details. |
| NONCE-RS-02 | Retried `/userinfo` request with the supplied nonce must succeed when the rest of the DPoP checks pass. | Add one exact HTTP retry proof on `/userinfo` rather than duplicating the full protocol negative matrix. |
| NONCE-RS-03 | Existing protected-resource replay, `ath`, binding, MTLS, bearer, and `401` vs `403` semantics must remain unchanged. | Preserve `ProtectedResourceDPoP` as the single resource-server validator seam and add focused negative-path regressions with a valid nonce present. |

</phase_requirements>

## Summary

Phase 83 does not need a new nonce architecture. The current codebase already threads `nonce_purpose` through both DPoP protocol seams, already emits typed `use_dpop_nonce` failures, and already exposes `DPoP-Nonce` headers in the token and userinfo controllers. The real Phase 83 work is to make that behavior uniform across every Lockspire-owned `/token` grant path, prove the exact `/userinfo` retry contract, and lock the non-nonce regressions in place so nonce adoption does not quietly degrade sender-constrained semantics.

The authorization-server side should stay centralized in `Lockspire.Protocol.TokenEndpointDPoP`. That module already sits beneath authorization-code, device-code, and CIBA token issuance, and `RefreshExchange` already routes DPoP-bound refresh requests through `resolve_refresh_context/3`. The safest implementation path is therefore to tighten coverage and helper behavior in that seam instead of branching per grant type or controller action. RFC 8693 token exchange should remain excluded from the support claim until it deliberately adopts the same seam.

The resource-server side should stay centralized in `Lockspire.Protocol.ProtectedResourceDPoP`. `Userinfo` already uses it as the protected-resource validator for DPoP-bound access tokens, which means nonce retry semantics can remain protocol-owned while the controller proves the public `401` challenge contract. That keeps `/userinfo` aligned with the host plug pipeline at the semantic level without prematurely coupling this phase to the Phase 84 plug work.

**Primary recommendation:** treat Phase 83 as endpoint-adoption plus proof hardening. Keep `/token` and `/userinfo` on their existing protocol seams, extend exact retry coverage where it is still thin, and add regression proof that replay, `ath`, binding, MTLS, and bearer semantics do not get reclassified as nonce failures.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| `/token` nonce validation and retry classification | `Lockspire.Protocol.TokenEndpointDPoP` | `Lockspire.Protocol.TokenExchange` / `RefreshExchange` | One validator seam already fans out to the supported Lockspire-owned `/token` grants. |
| `/token` public wire contract | `Lockspire.Web.TokenController` | controller tests | Keep headers/status/body thin and RFC-shaped. |
| `/userinfo` nonce validation and retry classification | `Lockspire.Protocol.ProtectedResourceDPoP` | `Lockspire.Protocol.Userinfo` | Preserves one resource-server validator path shared with future plug adoption. |
| `/userinfo` public challenge rendering | `Lockspire.Web.UserinfoController` | controller tests | One HTTP-level proof should lock the exact `401` + `WWW-Authenticate` + `DPoP-Nonce` contract. |
| Nonce/non-nonce regression protection | protocol + controller tests | release-readiness/docs in later phase | Phase 83 should prove behavior, not broaden support claims. |

## Recommended Plan Shape

### Plan 01: `/token` authorization-server adoption

Focus on:

- keeping one authorization-server nonce contract across the supported Lockspire-owned `/token` grants
- preserving refresh-path DPoP and MTLS coexistence
- adding exact `/token` HTTP retry proof where the current coverage is still narrow

### Plan 02: `/userinfo` protected-resource adoption

Focus on:

- preserving `ProtectedResourceDPoP` as the single resource-server nonce seam
- proving exact `401` challenge shape and retry acceptance on `/userinfo`
- keeping `401` vs `403` and bearer/MTLS behavior unchanged

### Plan 03: regression matrix hardening

Focus on:

- replay, `ath`, binding, wrong-scheme, MTLS, and bearer regressions with nonce support active
- proving those paths still map to their original reason codes instead of drifting into `use_dpop_nonce`
- keeping controller-level proof thin and protocol-level proof exhaustive

## Concrete File Impact

### Likely source files to modify

- `lib/lockspire/protocol/token_endpoint_dpop.ex`
- `lib/lockspire/protocol/token_exchange.ex`
- `lib/lockspire/protocol/refresh_exchange.ex`
- `lib/lockspire/web/controllers/token_controller.ex`
- `lib/lockspire/protocol/protected_resource_dpop.ex`
- `lib/lockspire/protocol/userinfo.ex`
- `lib/lockspire/web/controllers/userinfo_controller.ex`

### Likely test files to add or expand

- `test/lockspire/protocol/token_endpoint_dpop_test.exs`
- `test/lockspire/protocol/token_exchange_test.exs`
- `test/lockspire/protocol/refresh_exchange_test.exs`
- `test/lockspire/web/token_controller_test.exs`
- `test/lockspire/protocol/protected_resource_dpop_test.exs`
- `test/lockspire/web/userinfo_controller_test.exs`

## Pattern Guidance

### Reuse the existing DPoP protocol seams

Do not re-implement nonce validation inside grant-specific token code or inside the userinfo controller. `TokenEndpointDPoP` and `ProtectedResourceDPoP` already own proof validation, replay handling, and typed failure mapping.

### Keep HTTP adapters thin

`TokenController` and `UserinfoController` should only translate protocol errors into the exact public wire contract: status code, error payload, `WWW-Authenticate` where applicable, `DPoP-Nonce`, and exposed headers for browser-visible retries.

### Treat refresh differently only where the binding model requires it

Refresh-token issuance still needs its existing `expected_cnf` and MTLS coexistence logic. The nonce contract should ride through `resolve_refresh_context/3`, not fork into a refresh-specific retry surface.

### Lock non-nonce regressions with valid nonce present

To prove nonce adoption did not swallow other failures, add tests where the proof includes a valid nonce but still fails due to replay, wrong `ath`, wrong `jkt`, wrong authorization scheme, or MTLS mismatch. Those cases should continue returning their pre-nonce reason codes.

## Validation Architecture

| Property | Value |
|----------|-------|
| Framework | ExUnit |
| Quick `/token` run command | `mix test test/lockspire/protocol/token_endpoint_dpop_test.exs test/lockspire/protocol/token_exchange_test.exs test/lockspire/protocol/refresh_exchange_test.exs test/lockspire/web/token_controller_test.exs` |
| Quick `/userinfo` run command | `mix test test/lockspire/protocol/protected_resource_dpop_test.exs test/lockspire/web/userinfo_controller_test.exs` |
| Full phase run command | `mix test test/lockspire/protocol/token_endpoint_dpop_test.exs test/lockspire/protocol/token_exchange_test.exs test/lockspire/protocol/refresh_exchange_test.exs test/lockspire/protocol/protected_resource_dpop_test.exs test/lockspire/web/token_controller_test.exs test/lockspire/web/userinfo_controller_test.exs` |
| Full suite command | `mix test` |

### Sampling Rate

- After `/token` protocol changes: run the token-endpoint, token-exchange, and refresh suites
- After `/userinfo` protocol changes: run the protected-resource and userinfo-controller suites
- After any controller/header change: re-run the touched controller suite plus its backing protocol suite
- Before phase verification: run the full phase-targeted suite, then `mix test`

## Threat Notes

| Threat | Risk | Mitigation |
|--------|------|------------|
| Nonce contract drift across `/token` grants | authorization-code path behaves differently from refresh/device/CIBA | Keep all supported `/token` DPoP grants behind `TokenEndpointDPoP` and add per-grant proof where necessary. |
| Resource-server nonce challenge drift | `/userinfo` renders a retry challenge differently from the underlying protocol reason | Keep `use_dpop_nonce` classification protocol-owned and assert the exact controller wire contract. |
| Error reclassification regression | replay/`ath`/binding failures accidentally become `use_dpop_nonce` when nonce support is active | Add negative-path tests with valid nonce present and assert original reason codes. |
| Support-surface overclaim | tests imply RFC 8693 or host-plug nonce support before Phase 84 | Keep Phase 83 plans and assertions limited to `/token` owned grants and `/userinfo`. |
