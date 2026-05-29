# Protect Phoenix API Routes

Lockspire issues RFC 9068 `at+jwt` access tokens by default. `Lockspire.Plug.VerifyToken` accepts JWT bearer tokens for host Phoenix API routes. Lockspire-owned `/userinfo` and `/introspect` use stored opaque tokens; those are not interchangeable. To opt a client back to opaque, see the admin Client Detail page.

<!-- PHASE-102: delete this caveat sentence when issuance flip ships -->

This page describes the contract `Lockspire.Plug.VerifyToken` enforces; the runtime narrowing and the default-issuance flip land in v1.27. Until v1.27 is fully shipped, opaque tokens may still be silently accepted on these routes.

For the public support contract around this surface, see [`docs/supported-surface.md`](supported-surface.md).

## Canonical plug order

Lockspire enforces the token contract via `Lockspire.Plug.VerifyToken`, `Lockspire.Plug.EnforceSenderConstraints`, and `Lockspire.Plug.RequireToken`; your host application keeps ownership of business authorization and tenant checks.

```elixir
# BEGIN LOCKSPIRE_PROTECTED_PIPELINE
pipeline :lockspire_protected_api do
  plug Lockspire.Plug.VerifyToken, scopes: ["read:billing"], audience: "https://billing.acme-ledger.test", enforce_audience: true
  plug Lockspire.Plug.EnforceSenderConstraints,
    dpop_replay_store: MyAppWeb.ProtectedApiReplayStore
  plug Lockspire.Plug.RequireToken
end
# END LOCKSPIRE_PROTECTED_PIPELINE
```

`Lockspire.Plug.VerifyToken` authenticates the access token and enforces route-level `scopes:` / `audience:` restrictions.

`Lockspire.Plug.EnforceSenderConstraints` is part of the canonical shipped path even when bearer tokens are currently the common case. It is a no-op for unconstrained bearer tokens, and it preserves correctness automatically when the same route later receives DPoP-bound or mTLS-bound access tokens. When a DPoP proof is present but missing a valid resource-server nonce, the shipped plug pipeline returns `401` with `WWW-Authenticate: DPoP ... error="use_dpop_nonce"` plus a `DPoP-Nonce` response header so the client can retry with a fresh proof. Lockspire verifies the token protocol facts; your host app still owns business authorization, tenant policy, domain lookups, and whether a protected route should exist at all.

`Lockspire.Plug.RequireToken` turns structured verification failures into the correct OAuth-style HTTP response, including `403 insufficient_scope` when the token is valid but under-scoped.

## Example route

Mount any host-owned `scope` through the canonical pipeline by appending `:lockspire_protected_api` to its `pipe_through` list (for example, `pipe_through [:api, :lockspire_protected_api]` on a `scope "/api", MyAppWeb` block containing a `get "/billing/summary", ProtectedApiController, :show` route). This keeps the route host-owned. Lockspire is not taking over your API controller or product policy.

## Scope-restricted route example

See the canonical pipeline above; this example narrows it to a single `scopes:` value (e.g., `scopes: ["read:billing"]`) with no `audience:` restriction. Keep `Lockspire.Plug.EnforceSenderConstraints` in the pipeline even on bearer-only routes so the route stays correct when sender-constrained tokens arrive later.

## Audience-restricted route example

See the canonical pipeline above; this example pins `audience:` (e.g., `audience: "https://billing.acme-ledger.test"`) to constrain the route to tokens minted for a specific resource server. Route-level audience checks are exact-match against the token `aud` set.

## Access-token assigns contract

On success, the verified token is available at `conn.assigns.access_token` as `%Lockspire.AccessToken{}`.

Representative fields available to the host:

- `subject` for the Lockspire subject reference
- `client_id` for the OAuth client
- `scope` for the granted scope string
- `audience` for the granted audience list
- `expires_at` for expiry-aware policy decisions
- `cnf` for sender-constrained token confirmation data when present

Treat these as protocol facts. Your host app still decides whether the subject can view this tenant, whether the client is allowed for this product area, and whether additional internal policy checks apply.

## Failure behavior

| Situation | Status | Wire behavior |
| --- | --- | --- |
| Missing or invalid token | `401` | `WWW-Authenticate: Bearer ... error="invalid_token"` |
| Audience mismatch | `401` | Bearer challenge with `invalid_token` and a restriction failure description |
| Missing required scope | `403` | `WWW-Authenticate: Bearer ... error="insufficient_scope"` plus `scope="..."` |
| DPoP-bound token without valid proof | `401` | `WWW-Authenticate: DPoP ...` sender-constraint failure |
| DPoP-bound token with proof missing a valid nonce | `401` | `WWW-Authenticate: DPoP ... error="use_dpop_nonce"` plus `DPoP-Nonce: ...` |

## Ownership boundary

Lockspire owns:

- Access-token verification
- Route-level scope and audience restriction checks
- DPoP sender-constraint enforcement when you mount the sender-constraint plug
- OAuth-compatible failure responses from `Lockspire.Plug.RequireToken`

Your host app owns:

- Business authorization
- Tenant and account policy
- Internal rate limiting
- Controller behavior and domain lookups
- Whether a protected route should exist at all

## Repo-owned proof

This surface is proven in-repo by:

- `test/lockspire/plug/verify_token_test.exs`
- `test/lockspire/plug/require_token_test.exs`
- `test/integration/phase81_generated_host_route_protection_e2e_test.exs`
