# Install And Onboard

The canonical onboarding path is Phoenix-first and generator-first. Lockspire stays embedded inside your host app; the host continues to own accounts, login UX, layouts, branding, and product policy. For the full 1.0 GA support contract, see `docs/supported-surface.md`.

If you plan to authenticate confidential clients with `private_key_jwt`, read `docs/private-key-jwt-host-guide.md` for the shipped `jwks` / `jwks_uri` support slice, issuer-string `aud` requirement, and key-rotation behavior.

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

This creates host-owned files for:

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

Import `YourAppWeb.Router.Lockspire` from your host router and call `lockspire_routes/0` where your product wants the Lockspire routes to live.

Implement the generated `AccountResolver` with:

- Current-account lookup from your session
- Account lookup by subject reference
- Claim building for ID token and userinfo
- Login redirect behavior that preserves `interaction_id` and `return_to`

Implement the generated interaction and consent modules in the host app where your product wants login and approval UX to live. Lockspire owns the OAuth/OIDC protocol flow; your host app owns the human-facing account and policy decisions.

If you need custom RAR consent copy, edit the generated `lockspire_consent_live.ex` seam directly and follow [`docs/rar-consent-host-guide.md`](rar-consent-host-guide.md). The guide shows one illustrative `payment_initiation` example built on structural `authorization_details` data while keeping semantics, branding, and policy host-owned.

Keep the generated host logout seam truthful as well: your host app clears its own browser session first, then returns to Lockspire's `/end_session/complete` endpoint. That completion endpoint is the protocol-owned fork point for token revocation, logout propagation persistence, back-channel enqueueing, and the front-channel best effort page.

Implement the generated `LockspireVerificationController` and `lockspire_verification_html` files as a host-owned `/verify` seam. Keep your session and account pipeline in front of the approval routes, treat `verification_uri_complete` as prefill-only, and keep GET side-effect free.

If you plan to support device login, keep that host-owned `/verify` seam paired with Lockspire's shipped device endpoints:

- `POST /device/code` issues the device authorization and tells clients to begin with a 5-second poll interval.
- `POST /token` accepts `grant_type=urn:ietf:params:oauth:grant-type:device_code`, returns `authorization_pending` while approval is still pending, and returns `slow_down` when the client polls too aggressively.
- Approval still happens only through the host-owned `/verify` seam; Lockspire does not take over your browser UX.

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
- A confidential client can use the shipped direct-client auth surface the way `docs/private-key-jwt-host-guide.md` describes if you choose that mode.
- If you configure RP logout propagation, `/end_session/complete` persists the logout event, enqueues back-channel delivery through Oban, and renders front-channel iframe cleanup as best effort only.

The executable repo proof lives in:

- `test/integration/install_generator_test.exs`
- `test/integration/phase6_onboarding_e2e_test.exs`

The maintained contributor gate for that proof is `mix ci`, which runs the docs, package, fast-test, integration, and phase gates described in `.github/workflows/ci.yml`.

## 6. Finish the verification seam before shipping device login

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

That only changes comments and guidance in the generated resolver stub. It does not add a compile-time dependency on Sigra or create a second canonical path.
