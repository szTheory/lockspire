# Phase 83: Lockspire-owned DPoP Endpoint Adoption - Pattern Map

## Target Files -> Closest Analogs

| Target file | Role | Closest analogs | Why |
|-------------|------|-----------------|-----|
| `lib/lockspire/protocol/token_endpoint_dpop.ex` | Authorization-server DPoP nonce contract | existing file, `lib/lockspire/protocol/protected_resource_dpop.ex` | Already owns typed nonce failure mapping and replay handling for `/token`. |
| `lib/lockspire/protocol/token_exchange.ex` | Shared `/token` grant fan-out | existing file | Authorization-code, device-code, and CIBA all already pass through `TokenEndpointDPoP.resolve_context/2`. |
| `lib/lockspire/protocol/refresh_exchange.ex` | Refresh-token DPoP/MTLS coexistence | existing file, `lib/lockspire/protocol/token_endpoint_dpop.ex` | Refresh is the only `/token` path with stored binding state and MTLS interplay. |
| `lib/lockspire/web/controllers/token_controller.ex` | Thin `/token` header + status adapter | existing file, `lib/lockspire/web/controllers/userinfo_controller.ex` | Same `DPoP-Nonce` header exposure pattern, but different HTTP status semantics. |
| `lib/lockspire/protocol/protected_resource_dpop.ex` | Resource-server nonce contract | existing file, `lib/lockspire/protocol/token_endpoint_dpop.ex` | Already owns `ath`, replay, binding, and nonce-specific error mapping. |
| `lib/lockspire/protocol/userinfo.ex` | `/userinfo` orchestration over protected-resource DPoP | existing file, `lib/lockspire/plug/enforce_sender_constraints.ex` | Same protected-resource validation intent without the host plug transport boundary. |
| `lib/lockspire/web/controllers/userinfo_controller.ex` | Thin `401` DPoP challenge adapter | existing file, `lib/lockspire/plug/require_token.ex` | Same public DPoP challenge semantics, but without halting a host pipeline. |
| `test/lockspire/web/token_controller_test.exs` | `/token` public retry proof | `test/lockspire/protocol/token_endpoint_dpop_test.exs` | Best place to assert exact `400`, JSON error, `DPoP-Nonce`, and retry success. |
| `test/lockspire/web/userinfo_controller_test.exs` | `/userinfo` public retry proof | `test/lockspire/protocol/protected_resource_dpop_test.exs`, `test/lockspire/plug/require_token_test.exs` | Best place to assert exact `401`, `WWW-Authenticate`, `DPoP-Nonce`, and exposed headers. |

## Concrete Reuse Notes

### `lib/lockspire/protocol/token_endpoint_dpop.ex`

Reuse:

- `validate_proof_value/2`
- `resolve_context/2`
- `resolve_refresh_context/3`
- `use_dpop_nonce_error/2`
- `validate_mtls_binding/2`

Likely change:

- ensure every supported Lockspire-owned `/token` path reaches the same authorization-server nonce contract
- add or tighten regression tests so refresh-path MTLS/binding failures stay differentiated from nonce failures

### `lib/lockspire/protocol/token_exchange.ex`

Reuse:

- the existing grant dispatch
- shared `TokenEndpointDPoP.resolve_context/2` calls for authorization code, device code, and CIBA

Likely change:

- mostly test coverage rather than orchestration changes, unless a supported grant path still bypasses the nonce seam

### `lib/lockspire/protocol/refresh_exchange.ex`

Reuse:

- `TokenEndpointDPoP.resolve_refresh_context/3`
- existing repository rotation and expected-`cnf` validation

Likely change:

- targeted proof that a DPoP-bound refresh path returns `use_dpop_nonce` on missing/invalid nonce but preserves MTLS mismatch and binding mismatch semantics

### `lib/lockspire/protocol/protected_resource_dpop.ex`

Reuse:

- `validate_access/2`
- `validate_userinfo_access/2`
- `validate_ath/2`
- `validate_token_binding/2`
- replay-store integration

Likely change:

- no new validation architecture; concentrate on exact nonce retry proof and non-nonce regression assertions when a valid nonce is present

### `lib/lockspire/web/controllers/userinfo_controller.ex`

Reuse:

- `put_dpop_nonce/2`
- `put_www_authenticate/2`
- `expose_header/2`

Likely change:

- exact retry-proof assertions and any small header-exposure cleanup needed to keep browser retries visible

## Code Excerpts To Mirror

### Authorization-server nonce mapping

From `lib/lockspire/protocol/token_endpoint_dpop.ex`:

```elixir
{:error, reason} when reason in [:missing_dpop_nonce, :invalid_dpop_nonce] ->
  {:error, use_dpop_nonce_error(reason, request)}
```

Pattern to preserve:

- protocol seam owns the classification
- controller should not infer nonce semantics from generic invalid-proof errors

### Resource-server nonce mapping

From `lib/lockspire/protocol/protected_resource_dpop.ex`:

```elixir
{:error, reason} when reason in [:missing_dpop_nonce, :invalid_dpop_nonce] ->
  {:error, use_dpop_nonce_error(reason, request)}
```

Pattern to preserve:

- same typed nonce failure atoms as `/token`
- surface-specific HTTP shape applied later

### `DPoP-Nonce` header exposure

From `lib/lockspire/web/controllers/token_controller.ex` and `lib/lockspire/web/controllers/userinfo_controller.ex`:

```elixir
|> put_resp_header("dpop-nonce", nonce)
|> expose_header("DPoP-Nonce")
```

Pattern to preserve:

- `DPoP-Nonce` stays visible to browser callers
- resource-side challenge also exposes `WWW-Authenticate`

### DPoP challenge rendering

From `lib/lockspire/web/controllers/userinfo_controller.ex` and `lib/lockspire/plug/require_token.ex`:

```elixir
~s(DPoP realm="Lockspire Userinfo", error="use_dpop_nonce", ...)
```

Pattern to preserve:

- resource nonce failures are retry challenges, not generic bearer errors
- reason-specific DPoP challenge only for the protected-resource surface

## Test Patterns To Copy

### `/token` retry success pattern

Use `test/lockspire/web/token_controller_test.exs` as the model for:

- first request with missing nonce -> `400 use_dpop_nonce` + `DPoP-Nonce`
- second request with the supplied nonce -> `200` + `token_type == "DPoP"`

### Protected-resource negative matrix

Use `test/lockspire/protocol/protected_resource_dpop_test.exs` as the model for:

- wrong authorization scheme
- missing proof
- wrong `ath`
- wrong proof key
- replayed proof

Add valid-nonce variants where needed to prove nonce support did not swallow those failures.

### Host-pipeline DPoP challenge shape

Use `test/lockspire/plug/require_token_test.exs` as the semantic reference for:

- `401` DPoP challenge structure
- `error="use_dpop_nonce"`
- `DPoP-Nonce` header plus `WWW-Authenticate` exposure

Do not pull the plug itself into Phase 83 implementation, but keep `/userinfo` challenge semantics aligned.
