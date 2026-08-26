# Install And Onboard

The canonical onboarding path is Phoenix-first and generator-first. Lockspire stays embedded inside your host app; the host continues to own accounts, login UX, layouts, branding, and product policy. For the full 1.0 GA support contract, see `docs/supported-surface.md`.

If you plan to authenticate confidential clients with `private_key_jwt`, read `docs/private-key-jwt-host-guide.md` for the shipped `jwks` / `jwks_uri` support slice, issuer-string `aud` requirement, bounded reactive rollover truth, and runtime remote-key diagnosis path.

If you plan to authenticate confidential clients with `client_secret_jwt`, read `docs/client-secret-jwt-host-guide.md` for the shipped `HS256`-only direct-client slice, issuer-string `aud` requirement, required `jti`, replay prevention, and explicit non-claims.

## 1. Add Lockspire

Add `:lockspire` to your dependencies and fetch deps.

Lockspire's logout propagation slice also expects:

- `Oban` running in the host release. Lockspire starts a named Oban runtime and fails fast if the repo or Oban runtime config is missing or invalid.
- `Req` available for back-channel logout delivery. Lockspire uses `Req` for server-to-server logout POSTs once `/end_session/complete` persists and enqueues the work.

## 2. Generate the host seam

Run:

```bash
mix lockspire.install
```

This creates one canonical Phoenix onboarding layout with two ownership classes:

- Lockspire-managed scaffolding:
  - `config/lockspire.exs`
  - `lib/<web>/router/lockspire.ex`
  - `test/<app>/lockspire_smoke_e2e_test.exs`
  - byte-identical Lockspire migrations copied into `priv/repo/migrations`
  - `.lockspire/install_manifest.json`
- Host-owned seams:
  - Account resolution
  - Interaction handoff
  - Consent UI shell
  - Authorized apps account surface
  - Device verification controller and templates

The manifest records managed scaffolding and the packaged migration inventory. The
installer preflights every managed file and migration before changing the host
tree: it copies only missing byte-identical migration files, never overwrites a
host file, and stops with a collision report if an existing version, name, or
content differs.

The generator also creates host-owned files for:

- Lockspire config
- Router mount helpers
- Account resolution
- Interaction handoff
- Consent UI shell
- Authorized apps account surface
- Device verification controller (`lockspire_verification_controller.ex`)
- Device verification HTML module (`lockspire_verification_html.ex`)
- Device verification template (`lockspire_verification_html/index.html.heex`)

## 3. Wire the generated files

Import `config/lockspire.exs` from your main config entrypoint.

Import `YourAppWeb.Router.Lockspire` from your host router and call the imported
`lockspire_routes/0` macro where your product wants the Lockspire routes to
live. The host router must already define its normal `:browser` pipeline and a
host-owned `:require_operator` pipeline:

```elixir
import YourAppWeb.Router.Lockspire

pipeline :require_operator do
  plug YourAppWeb.Plugs.RequireOperator
end

lockspire_routes()
```

The generated route helper separates host-owned account routes, an admin mount, and the public OAuth/OIDC mount. Keep `Lockspire.Web.AdminRouter` behind your operator pipeline and before the general `Lockspire.Web.Router` forward. Lockspire does not authenticate your staff; your host app owns operator sessions, MFA, role checks, and any IP or tenant policy before requests reach the admin LiveViews. `mix lockspire.verify` proves compiled mount shape and order only; add host request tests that prove unauthenticated users cannot reach the admin mount.

The generated macro mounts the host-owned `/verify` and `/authorized-apps`
routes, then the generated `lockspire_consent_live.ex` seam, then the guarded
admin router, and finally the public Lockspire router. Do not replace this with
hand-written route source strings: `mix lockspire.verify` checks the compiled
Phoenix route table and its order.

Implement the generated `AccountResolver` with:

- Current-account lookup from your host-owned session seam
- For Sigra pairings, read `conn.assigns.current_scope.user` instead of importing Sigra at compile time
- Account lookup by subject reference
- Claim building for ID token and userinfo
- Login redirect behavior that preserves `interaction_id` and `return_to`
- Post-login resume behavior that sends the browser back through the generated interaction path before consent continues

Implement the generated interaction and consent modules in the host app where your product wants login and approval UX to live. The generated consent LiveView calls the supported Lockspire consent context and posts decisions to Lockspire's existing interaction completion endpoint; it must not call Lockspire repositories or protocol internals directly. Lockspire owns the OAuth/OIDC protocol flow; your host app owns the human-facing account and policy decisions.

Set the generated `logout_path` to the host route that clears the browser
session. The host logout endpoint clears the host session and returns to
Lockspire's `/end_session/complete` endpoint; Lockspire then owns protocol
revocation and logout propagation.

If you also want to protect host-owned Phoenix API routes with Lockspire-issued access tokens, follow [`docs/protect-phoenix-api-routes.md`](protect-phoenix-api-routes.md). That guide is the canonical optional host-route path inside the same embedded-library product shape. It keeps the route middleware narrow: Lockspire verifies token protocol facts, while your host app keeps business authorization and tenant policy.

If you need custom RAR consent copy, edit the generated `lockspire_consent_live.ex` seam directly and follow [`docs/rar-consent-host-guide.md`](rar-consent-host-guide.md). The guide shows one illustrative `payment_initiation` example built on structural `authorization_details` data while keeping semantics, branding, and policy host-owned.

Keep the generated host logout seam truthful as well: your host app clears its own browser session first, then returns to Lockspire's `/end_session/complete` endpoint. That completion endpoint is the protocol-owned fork point for token revocation, persisted logout propagation intent, durable back-channel enqueueing, and the front-channel best effort cleanup page.

Implement the generated `LockspireVerificationController` and `lockspire_verification_html` files as a host-owned `/verify` seam. Keep your session and account pipeline in front of the approval routes, treat `verification_uri_complete` as prefill-only, and keep GET side-effect free.

If you plan to support device login, keep that host-owned `/verify` seam paired with Lockspire's shipped device endpoints:

- `POST /device/code` issues the device authorization and tells clients to begin with a 5-second poll interval.
- `POST /token` accepts `grant_type=urn:ietf:params:oauth:grant-type:device_code`, returns `authorization_pending` while approval is still pending, and returns `slow_down` when the client polls too aggressively.
- Approval still happens only through the host-owned `/verify` seam; Lockspire does not take over your browser UX.

## 4. Run host migrations

Generated new installs set:

```elixir
config :lockspire,
  storage_prefix: "lockspire",
  oban_prefix: "lockspire"
```

That keeps Lockspire-owned tables and Lockspire's Oban tables in a dedicated Postgres schema instead of the host app's default schema. If you intentionally want the default/public schema, generate with:

```bash
mix lockspire.install --storage-prefix public --oban-prefix public
```

Existing apps that installed Lockspire before this config key keep their current public/default-schema behavior until they explicitly add a prefix and run a data-move plan. Do not point an existing production install at `storage_prefix: "lockspire"` without first moving the existing `lockspire_*` and Oban tables.

Run:

```bash
mix ecto.migrate
```

Run that ordinary host command from the project containing
`priv/repo/migrations`. Do not point Ecto at Lockspire's dependency directory:
the installer has already delivered the packaged migration files to the host's
normal migration path.

## 5. Verify the install wiring

Run:

```bash
mix lockspire.verify
```

This is the canonical post-install diagnostics step. It checks every item in
one run, so fix every `ERROR` line before continuing:

- each required `:lockspire` runtime key: `repo`, `account_resolver`, `issuer`,
  `mount_path`, `logout_path`, and the Lockspire Oban runtime contract
- the generated account-resolver and interaction-handler modules
- compiled host `/verify`, `/authorized-apps`, and consent routes
- a host-owned operator guard on `Lockspire.Web.AdminRouter` before the public
  Lockspire forward at your configured mount path
- the packaged migration inventory in host `priv/repo/migrations` and its
  applied database state

Each failure includes the exact `config/lockspire.exs`, generated seam, router,
installer/upgrade, or `mix ecto.migrate` remediation. The command does not
inspect or print client secrets, tokens, claims, or interaction data.

`mix lockspire.verify` does not diagnose runtime remote-`jwks_uri` incidents. For those, use `mix lockspire.doctor remote-jwks --client <client_id>` and the matching admin Remote JWKS summary described in `docs/private-key-jwt-host-guide.md`.

## 6. Create a client and prove the flow

Run the generated default-profile smoke as part of the ordinary host suite:

```bash
mix test test/<app>/lockspire_smoke_e2e_test.exs
```

It proves discovery/JWKS plus authorization-code routing with PKCE S256 and
exact redirect matching under Lockspire's unchanged `:none` security profile.
It registers `profile` as an application scope and requests `openid profile`
only at authorization time.

FAPI 2.0 proof is deliberately separate. Only hosts that explicitly operate
the FAPI 2.0 security profile should generate and run it:

```bash
mix lockspire.install --with-fapi-smoke
mix test test/<app>/lockspire_fapi_smoke_e2e.exs --include fapi
```

That opt-in is recorded in the install manifest, so later `mix lockspire.upgrade`
commands retain and update the FAPI smoke. For a legacy manifest, pass
`mix lockspire.upgrade --with-fapi-smoke` once to add the managed proof.

The opt-in test is not named `*_test.exs`, so a normal `mix test` does not make
FAPI/PAR claims for a default-profile installation.

The canonical proof bar is:

- Discovery returns the issuer and endpoint set.
- JWKS returns the public signing keys.
- A first partner client is registered through the admin UI, DCR, or `mix lockspire.client.create`.
- A client can complete an authorization-code + PKCE exchange.
- Host Phoenix API routes can enforce route-level `scopes:` and `audience:` restrictions with the shipped plug pipeline when you choose to expose protected routes in the host app.
- A confidential client can use the shipped direct-client auth surface the way `docs/private-key-jwt-host-guide.md` describes if you choose that mode.
- A confidential client can use the shipped direct-client auth surface the way `docs/client-secret-jwt-host-guide.md` describes if you choose the narrow `client_secret_jwt` mode.
- If you configure RP logout propagation, `/end_session/complete` persists the logout event, enqueues durable back-channel delivery through Oban and Req, and renders front-channel iframe cleanup as best effort only.

The executable repo proof lives in:

- `test/integration/install_generator_test.exs`
- `test/integration/phase6_onboarding_e2e_test.exs` for the unauthenticated `/authorize` -> host login -> interaction resume -> consent -> token exchange path
- `test/integration/phase81_generated_host_route_protection_e2e_test.exs` for host Phoenix API route protection with bearer and DPoP-bound access tokens

The maintained contributor gate for that proof is `mix ci`, which runs the docs, package, fast-test, integration, and phase gates described in `.github/workflows/ci.yml`.

For a human-pokable host app, see `docs/adoption-demo.md`. That demo boots a small Phoenix SaaS host from `examples/adoption_demo` and CI runs its black-box smoke over HTTP.

## 7. Upgrade managed artifacts and migrations

When a newer Lockspire version changes generated managed files, preview the update with:

```bash
mix lockspire.upgrade --dry-run
```

Apply it with:

```bash
mix lockspire.upgrade
```

`mix lockspire.upgrade` only touches manifest-tracked managed scaffolding that is still unchanged and copies only newly packaged migrations into the host's normal `priv/repo/migrations` path. It never rewrites host-owned seams or migrations, and it refuses risky overwrites when a managed file or migration has drifted from the recorded checksum. Run `mix ecto.migrate` after every successful upgrade that reports copied migrations.

## 8. Finish the verification seam before shipping device login

Before you expose `/verify` publicly:

- Wire host auth and session behavior around the generated `LockspireVerificationController`.
- Add host-owned rate limiting for both `GET /verify` and `POST /verify`.
- Keep approve and deny behind explicit signed-in user actions.
- Read `docs/device-flow-host-guide.md` for the full verification security contract, including anti-phishing rules, trusted proxy IP guidance, the 5-second device polling baseline, `slow_down` backoff, `Retry-After`, and normalized-code limiter keys.

## Sigra companion path

If your host app already uses Sigra for end-user auth, run:

```bash
mix lockspire.install --sigra-host
```

That only changes comments and guidance in the generated resolver stub. It does not add a compile-time dependency on Sigra or create a second canonical path. For the full host-seam contract, including `conn.assigns.current_scope.user`, claim-shape guidance, and login-resume expectations, see `docs/sigra-companion-host.md`.
