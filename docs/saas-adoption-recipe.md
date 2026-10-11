# SaaS Adoption Recipe

Use this recipe to register a partner client and prove its first OAuth flow in your Phoenix app.

First, complete the [canonical install and verification guide](install-and-onboard.md). It covers
installation, migrations, routes, and `mix lockspire.verify`; this recipe starts after that setup.

For an OAuth/OIDC overview before configuring a client, read
[OAuth/OIDC for Phoenix adopters](oauth-oidc-for-phoenix-adopters.md).

## 1. Keep host and protocol routes separate

The install guide shows how to mount these routes. Keep their responsibilities separate:

- Host account routes such as `/verify` and `/authorized-apps` stay inside your normal browser/session pipeline.
- `Lockspire.Web.AdminRouter` must be mounted behind the host's staff sign-in and access checks.
- `Lockspire.Web.Router` exposes the public OAuth/OIDC protocol surface.

## 2. Resolve accounts and choose claims

Implement the generated `AccountResolver` before shipping.

- Read the signed-in user from host-owned assigns or session state, such as `conn.assigns.current_user` or `conn.assigns.current_scope.user`.
- Use a stable subject, for example `"user:" <> to_string(user.id)`.
- Keep default claims narrow: `email`, `name`, and other low-risk profile facts only when your product wants to expose them.
- Keep tenant membership, billing, staff/admin status, and product authorization in the host app.

If the host uses Sigra, keep the integration in the generated resolver. Do not add a compile-time dependency from Lockspire to Sigra.

## 3. Create the first partner client

For a first local proof, use the admin UI, DCR with an initial access token, or:

```bash
mix lockspire.client.create \
  --client-type confidential \
  --name "Local Partner App" \
  --redirect-uri "https://partner.example.test/oauth/callback" \
  --scope openid \
  --scope profile \
  --grant-type authorization_code
```

Store the printed `client_secret` immediately. Lockspire stores only the secret hash and will not show the plaintext value again.

## 4. Prove the flow

Before giving credentials to a real integrator:

- Fetch discovery and JWKS from the mounted issuer.
- Complete authorization code + PKCE with the exact redirect URI.
- Confirm consent renders inside the host-owned UI.
- Exchange the code with the configured client authentication method.
- If exposing API routes, follow the canonical pipeline in [`docs/protect-phoenix-api-routes.md`](protect-phoenix-api-routes.md).

Lockspire proves protocol facts. Your Phoenix app still owns tenant checks, business authorization, rate limiting, and response shaping.
