# SaaS Adoption Recipe

Use this when you are wiring Lockspire into a real Phoenix SaaS for the first time.

## 1. Install and mount

Run `mix lockspire.install`, import `config/lockspire.exs`, run migrations, and call the generated `lockspire_routes/0` helper from your host router.

Keep three boundaries separate:

- Host account routes such as `/verify` and `/authorized-apps` stay inside your normal browser/session pipeline.
- `Lockspire.Web.AdminRouter` must be mounted behind your operator-auth pipeline.
- `Lockspire.Web.Router` exposes the public OAuth/OIDC protocol surface.

## 2. Resolve accounts and claims

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
