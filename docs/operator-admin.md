# Admin Guide

Use this guide to mount and maintain Lockspire's admin pages. Lockspire manages protocol state; your Phoenix app keeps ownership of accounts, sign-in, and staff access.

For exact capabilities and limits, see the [supported surface](supported-surface.md). This guide does not define a separate support contract. For the canonical mount and host-access setup, see the [install and onboarding guide](install-and-onboard.md).

**For maintainers:** [Skip to guidance for changing the admin pages](#maintainer-guidance-for-changing-the-admin-pages) at the end of this guide.

## Find the admin task you need

The admin pages group common tasks by the same labels used in the interface:

- **Orient**: use `/admin` or `/admin/overview` to see client and security status, key readiness, support incidents, and current protocol work.
- **Configure**: use `/admin/clients`, `/admin/policies`, `/admin/keys`, and `/admin/dcr` to manage client setup, issuer posture, key lifecycle, and partner intake.
- **Support**: use `/admin/consents` and `/admin/tokens` to investigate durable grant, token, refresh-family, account, client, and status questions.
- **Operate**: use `/admin/interactions`, `/admin/device_authorizations`, and `/admin/logouts` to inspect live authorization work, device flow requests, and logout delivery pressure.

These routes live under the embedded Lockspire router. Your host app controls which staff members can access them.

### Key protection

The Keys page starts with a **Key protection** line. It tells you whether Lockspire is encrypting the private keys it stores. The line is read-only: it never changes anything, and the Keys page has no button for it. Lockspire encrypts those private keys with a key-encryption key that your app provides in its configuration.

| The line says | What it means | What to do |
| --- | --- | --- |
| Encrypted | Every stored private key is encrypted with the current key-encryption key. | Nothing. |
| Encrypted, some with an older key-encryption key | Lockspire can still read all keys. Some use an older key-encryption key. | Run `mix lockspire.keys.reencrypt` to move them to the current one. |
| Some keys are stored unencrypted | Some private keys are stored without encryption, usually because an older Lockspire version created them. | Run `mix lockspire.keys.reencrypt`. |
| Some keys cannot be read | Lockspire cannot open some stored keys with the key-encryption keys it has. | Do not delete them. Run `mix lockspire.doctor.key_encryption`. |
| Not set up | No key-encryption key is set up, so Lockspire cannot create new keys. | Run `mix lockspire.gen.kek`, add the result to your app's configuration, and restart the app. See the [signing key encryption upgrade note](upgrading/signing-key-encryption.md). |
| Setup needs attention | The key-encryption key setup is not valid. | Run `mix lockspire.doctor.key_encryption`. |
| Unknown | Lockspire could not check right now. Unknown is not a healthy result. | Reload the page. If it stays Unknown, run `mix lockspire.doctor.key_encryption`. |

If you try to create a key before a key-encryption key is set up, Lockspire refuses and the page tells you to run `mix lockspire.gen.kek`. It never stores a private key unencrypted.

## Mounting the admin surface

Mount the admin pages behind your host application's staff sign-in and access checks. Lockspire does not sign in staff or decide who can access these pages.

The generated router mounts `Lockspire.Web.AdminRouter` at `/lockspire/admin` before the general `Lockspire.Web.Router` forward:

```elixir
scope "/lockspire/admin" do
  pipe_through [:browser, :require_operator]
  forward "/", Lockspire.Web.AdminRouter
end

scope "/" do
  forward "/lockspire", Lockspire.Web.Router
end
```

Keep the more specific admin forward before the general public OAuth/OIDC forward. Lockspire owns protocol and related admin state after a request reaches its LiveViews. The host owns staff sessions, MFA, role checks, tenant policy, layouts, branding, product-specific authorization, IP policy, and audit framing around access to these routes.

## Admin navigation model

The admin UI uses the same four top-level journey labels as the embedded admin layout:

- **Orient**: Overview. The `/admin` cockpit answers what needs attention and points to the next workflow.
- **Configure**: Clients, Security, Keys, and DCR. These routes own setup, issuer posture, client posture, endpoint configuration, credentials, DCR onboarding, DCR policy, IAT inventory, and key lifecycle.
- **Support**: Consents and Tokens. These routes own account/client/status investigation, consent revocation, token revocation, and refresh-family response.
- **Operate**: Device Auth, Interactions, and Logouts. These routes own active protocol queues, device authorization expiry, and logout propagation delivery pressure.

This organization is deliberate: Orient, Configure, Support, and Operate are separate journeys even when they reference the same client.

Route groups remain concrete entries inside those journeys:

- **Overview** belongs to Orient.
- **Apps**, **Security**, **Keys**, and **App registration** belong to Configure.
- **Consents** and **Tokens** belong to Support.
- **Device authorization requests**, **Sign-in requests**, and **App sign-out notices** belong to Operate.

The admin UI calls OAuth clients "apps" and keeps "client" for identifiers such as the client ID and client secret.

## DCR onboarding and DCR policy

Keep DCR onboarding separate from DCR policy:

- **DCR onboarding** lives primarily at `/admin/dcr`, `/admin/iats`, `/admin/iats/new`, self-registered client detail, and `/admin/clients/:client_id/rotate-registration-access-token`. It covers partner intake, short-lived Initial Access Tokens, self-registered clients, and registration access token support.
- **DCR policy** lives at `/admin/policies/dcr`. It covers issuer registration posture, allowed registration methods, and whether registration is disabled, IAT-gated, or open.

These workflows are connected, but they are not the same job. Admin users may start in DCR onboarding, find that issuer policy blocks registration, then update the policy before returning to onboarding.

### Recovering an app management token

The host team can replace an app management token from the existing app detail task when a partner loses the token or its configured expiry passes. The action requires the normal host staff authorization and confirmation. Lockspire displays the committed replacement token once; deliver it securely to the partner. The old token stops working immediately, including after a successful registration update whose response was lost. Replaying that old token cannot recover the replacement.

Recovery is available for self-registered apps and changes only management access. Rotating this token does not enable the app or extend app or client-secret expiry. A finite token lifetime is an optional provider policy: blank or `0` means no automatic expiry, while a positive duration applies to newly issued or replaced tokens and leaves existing tokens unchanged. A finite lifetime can lock a partner out of self-management after expiry, so the host team should be ready to rotate and securely deliver a replacement.

## Logout propagation workflow

Each client has two separate logout-related settings:

- **Post-logout redirect URIs**: browser destinations the RP may use after RP-initiated logout completes. Edit them at `/admin/clients/:client_id/logout-uris`.
- **Logout propagation URIs**: RP cleanup endpoints for back-channel and front-channel logout propagation. Edit them at `/admin/clients/:client_id/edit?workflow=logout-propagation`.

Keep those concerns separate: post-logout redirect URIs are browser destinations; logout propagation URIs are RP cleanup endpoints.

Lockspire's shipped truth model is:

- Back-channel logout is the durable path. After the host app clears its own browser session and returns to `/end_session/complete`, Lockspire persists delivery intent, then Oban runs Req-based POST delivery out of band.
- Front-channel logout is best effort only. Lockspire renders invisible iframes and a bounded continue page, but it does not claim remote success.
- Dynamic Client Registration now manages the same existing logout propagation metadata for eligible self-service clients. Admin users still have a separate workflow to review, correct, or update these settings when supporting a client.

## PAR Policy Management

Set whether PAR is required for authorization requests:

- **Global PAR policy**: The default requirement for all clients (Required or Optional).
- **Client PAR override**: A per-client setting that can override the global default.
- **Effective PAR requirement**: The resolved policy for a specific request, used by Lockspire to enforce or allow direct authorization.

Use `/admin/policies/par` for the global issuer policy and
`/admin/clients/:client_id/par-policy` for the per-client override workflow.

## Host-owned account workflows

Generated account-facing files keep end-user UX inside the host app:

- Authorized apps listing
- Consent revoke actions
- Login redirects and return paths
- Consent layout, copy, and branding

## Boundary to preserve

Lockspire owns:

- Protocol correctness
- Durable client, consent, token, interaction, and key state
- Client, consent, token, and key management

The host app owns:

- Accounts and sessions
- Staff sign-in and access checks before the admin router
- Login UX and MFA
- Layouts and branding
- Product policy and authorization framing

## Maintainer guidance for changing the admin pages

This section is for people who maintain Lockspire's admin interface. Admin users can follow the tasks and host-ownership guidance above without reading the design and review procedures below.

### Design system and proof boundary

The admin UI uses Lockspire-owned design tokens and shared Phoenix components. Runtime tokens mirror `brandbook/tokens/` so maintainers can audit brand drift without introducing a second styling system or public component API.

Shared components cover common admin needs: page headers, section cards, action groups, status badges, alerts, resource lists, summaries, long identifiers, copy-once secret panels, confirmation panels, form fields, and error summaries. When adding or revising admin routes, prefer these components over page-local class assemblies and tie each change to the Orient, Configure, Support, or Operate task it serves.

Use the shared button variants consistently: **primary** marks the page's main safe action, **secondary** marks navigation, support, recovery, or an alternate action, and **danger** marks a consequential destructive action. A danger style does not replace the consequence text or confirmation step. Keep task-return links secondary and form saves primary; confirmed client disable and credential rotation actions remain danger-styled.

The component lab and stress surface are internal maintainer proof only. They render real admin primitives and redaction-safe fixture states for tests and local review, but they are not mounted through `Lockspire.Web.AdminRouter`, not a supported admin route, not a host extension point, and not part of `docs/supported-surface.md`.

Theme behavior is intentionally narrow:

- **System** is the default and follows `prefers-color-scheme`.
- **Light** and **Dark** are explicit admin-only choices exposed in the shell theme selector.
- The selector persists only a local browser preference for the Lockspire admin surface.
- Dark mode remaps semantic aliases such as surface, text, border, status, focus, and shadow tokens while primitive palette tokens stay stable.
- Reduced-motion preferences must neutralize nonessential transitions and keep focus, form feedback, and queue state understandable without animation.

Maintainer checks cover shared components, token drift, focus, responsive behavior, themes, reduced motion, route links, documentation, and redaction. Captured evidence must not include secrets or copy-once plaintext. These checks do not make browser tooling, screenshots, lab routes, or theme overrides part of the public support contract.

### Page-first review

Before changing an admin page, name the staff member's task, decision, main action, empty and error states, accessibility risks, redaction needs, supported-route boundaries, and package impact. Keep the change tied to that task and the existing support promise.

Implement one focused page change, run deterministic guardrails, and record any supplemental browser evidence. ExUnit, LiveViewTest, LazyHTML, source, and rendered HTML checks are the blocking proof. Browser notes are supplemental; the internal lab and stress surfaces support tests and local review. Optional AI/persona judgments are advisory and require human signoff.

Scorecards and lab, stress, browser, or judge notes are maintainer evidence only. They do not create supported admin routes, public APIs, host extension points, theme interfaces, browser-testing products, Hex package surface, or public support claims. Never preserve secrets, copy-once values, screenshots with plaintext credentials, traces, cookies, tokens, authorization codes, private keys, verifier material, user codes, or production-looking identifiers as evidence; prefer deterministic Mix guardrails and redaction-safe fixture notes.

Keep the host seam clear: Lockspire owns protocol and related admin state after a request reaches the host-guarded admin router. The host owns staff sessions, MFA, role checks, tenant policy, outer layouts, branding, product-specific authorization, IP policy, and audit framing.
