# Protect Phoenix API Routes

Lockspire issues RFC 9068 `at+jwt` access tokens by default. `Lockspire.Plug.VerifyToken` accepts JWT bearer tokens for host Phoenix API routes. Lockspire-owned `/userinfo` and `/introspect` use stored opaque tokens; those are not interchangeable. To opt a client back to opaque, see the admin Client Detail page.

This page describes the contract `Lockspire.Plug.VerifyToken` enforces after the v1.27 runtime narrowing and default-issuance flip.

For the public support contract around this surface, see [`docs/supported-surface.md`](supported-surface.md).

## Canonical plug order

Lockspire enforces the token contract via `Lockspire.Plug.VerifyToken`, `Lockspire.Plug.EnforceSenderConstraints`, and `Lockspire.Plug.RequireToken`; your host application keeps ownership of business authorization and tenant checks.

```elixir
# BEGIN LOCKSPIRE_PROTECTED_PIPELINE
pipeline :lockspire_protected_api do
  plug Lockspire.Plug.VerifyToken, scopes: ["read:billing"], audience: "https://api.billingo.test/billing", enforce_audience: true
  plug Lockspire.Plug.EnforceSenderConstraints
  plug Lockspire.Plug.RequireToken
end
# END LOCKSPIRE_PROTECTED_PIPELINE
```

`Lockspire.Plug.VerifyToken` authenticates the access token and enforces route-level `scopes:` / `audience:` restrictions.

`Lockspire.Plug.EnforceSenderConstraints` is part of the canonical shipped path even when bearer tokens are currently the common case. It is a no-op for unconstrained bearer tokens, and it preserves correctness automatically when the same route later receives DPoP-bound or mTLS-bound access tokens. With no option, DPoP replay protection uses the configured Lockspire repository, which is the durable installed default. When a DPoP proof is present but missing a valid resource-server nonce, the shipped plug pipeline returns `401` with `WWW-Authenticate: DPoP ... error="use_dpop_nonce"` plus a `DPoP-Nonce` response header so the client can retry with a fresh proof.

An application with its own compatible durable store can provide `dpop_replay_store: MyApp.DpopReplayStore` as an advanced override. That override is optional, not a prerequisite for the canonical pipeline; an unavailable, incompatible, or failing override rejects the proof rather than falling back to acceptance.

`Lockspire.Plug.RequireToken` turns structured verification failures into the correct OAuth-style HTTP response, including `403 insufficient_scope` when the token is valid but under-scoped.

## Example route

Mount any host-owned `scope` through the canonical pipeline by appending `:lockspire_protected_api` to its `pipe_through` list (for example, `pipe_through [:api, :lockspire_protected_api]` on a `scope "/api", MyAppWeb` block containing a `get "/billing/summary", ProtectedApiController, :show` route). This keeps the route host-owned. Lockspire is not taking over your API controller or product policy.

## Scope-restricted route example

See the canonical pipeline above; this example narrows it to a single `scopes:` value (e.g., `scopes: ["read:billing"]`) with no `audience:` restriction. Keep `Lockspire.Plug.EnforceSenderConstraints` in the pipeline even on bearer-only routes so the route stays correct when sender-constrained tokens arrive later.

## Audience-restricted route example

See the canonical pipeline above; this example pins `audience:` (e.g., `audience: "https://api.billingo.test/billing"`) to constrain the route to tokens minted for a specific resource server. Route-level audience checks are exact-match against the token `aud` set.

## Access-token assigns contract

On success, the verified token is available at `conn.assigns.access_token` as `%Lockspire.AccessToken{}`.

Use the semantic readers for normalized protocol facts:

`Lockspire.AccessToken.subject/1`, `Lockspire.AccessToken.scopes/1`,
`Lockspire.AccessToken.audiences/1`, `Lockspire.AccessToken.expires_at/1`, and
`Lockspire.AccessToken.confirmation/1` are the supported readers.

```elixir
subject = Lockspire.AccessToken.subject(access_token)
scopes = Lockspire.AccessToken.scopes(access_token)
audiences = Lockspire.AccessToken.audiences(access_token)
expires_at = Lockspire.AccessToken.expires_at(access_token)
confirmation = Lockspire.AccessToken.confirmation(access_token)
```

The readers return `String.t() | nil`, `[String.t()]`, `[String.t()]`, `DateTime.t() | nil`, and an allowlisted confirmation map or `nil`, respectively. `access_token.claims` remains available as raw compatibility and extension data, but route and controller examples should not reimplement claim parsing from it.

Lockspire enforces protocol validity, route scope, audience, and sender constraints. Your host application enforces tenant, object, billing, product, response, and additional rate-limit policy. Those are separate decisions: a valid, correctly scoped token never by itself authorizes a tenant resource.

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
