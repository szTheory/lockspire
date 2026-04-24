# Install And Onboard

The canonical onboarding path is Phoenix-first and generator-first. Lockspire stays embedded inside your host app; the host continues to own accounts, login UX, layouts, branding, and product policy. For the full `v0.1` preview support contract, see `docs/supported-surface.md`.

## 1. Add Lockspire

Add `:lockspire` to your dependencies and fetch deps.

## 2. Generate the host seam

Run:

```bash
mix lockspire.install
```

This creates host-owned files for:

- Lockspire config
- Router mount helpers
- Account resolution
- Interaction handoff
- Consent UI shell
- Authorized apps account surface

## 3. Wire the generated files

Import `config/lockspire.exs` from your main config entrypoint.

Import `YourAppWeb.Router.Lockspire` from your host router and call `lockspire_routes/0` where your product wants the Lockspire routes to live.

Implement the generated `AccountResolver` with:

- Current-account lookup from your session
- Account lookup by subject reference
- Claim building for ID token and userinfo
- Login redirect behavior that preserves `interaction_id` and `return_to`

Implement the generated interaction and consent modules in the host app where your product wants login and approval UX to live. Lockspire owns the OAuth/OIDC protocol flow; your host app owns the human-facing account and policy decisions.

## 4. Run migrations

Run:

```bash
mix ecto.migrate
```

## 5. Create a client and prove the flow

The canonical proof bar is:

- Discovery returns the issuer and endpoint set.
- JWKS returns the public signing keys.
- A client can complete an authorization-code + PKCE exchange.

The executable repo proof lives in:

- `test/integration/install_generator_test.exs`
- `test/integration/phase6_onboarding_e2e_test.exs`

The maintained contributor gate for that proof is `mix ci`, which runs the docs, package, fast-test, integration, and phase gates described in `.github/workflows/ci.yml`.

## Sigra companion path

If your host app already uses Sigra for end-user auth, run:

```bash
mix lockspire.install --sigra-host
```

That only changes comments and guidance in the generated resolver stub. It does not add a compile-time dependency on Sigra or create a second canonical path.
