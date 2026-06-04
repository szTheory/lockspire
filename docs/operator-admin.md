# Operator And Admin Guide

Lockspire ships a library-owned operator surface for protocol state, while the host app keeps ownership of account UX.

For the canonical advanced-setup support contract, see `docs/supported-surface.md`. This guide stays subordinate to that contract and should not be read as a second support matrix.

## Lockspire-owned operator journeys

Lockspire groups the admin surface by operator intent:

- **Orient**: use `/admin` or `/admin/overview` as the operator cockpit for client posture, security posture, key readiness, support incidents, and live protocol work.
- **Configure**: use `/admin/clients`, `/admin/policies`, `/admin/keys`, and `/admin/dcr` to manage client setup, issuer posture, key lifecycle, and partner intake.
- **Support**: use `/admin/consents` and `/admin/tokens` to investigate durable grant, token, refresh-family, account, client, and status questions.
- **Operate**: use `/admin/interactions`, `/admin/device_authorizations`, and `/admin/logouts` to inspect live authorization work, device flow requests, and logout delivery pressure.

These routes live under the embedded Lockspire router and are meant for application operators.

## Mounting the admin surface

Mount the operator UI behind your host application's operator-auth pipeline. Lockspire does not authenticate your staff or decide who counts as an operator.

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

Keep the more specific admin forward before the general public OAuth/OIDC forward. Lockspire owns protocol and operator state after the request reaches its LiveViews; the host owns staff sessions, MFA, role checks, tenant policy, layouts, branding, operator authorization, IP policy, and audit framing around access to those routes.

## Admin navigation model

The admin UI uses the same four top-level journey labels as `Lockspire.Web.Live.AdminLayoutLive`:

- **Orient**: Overview. The `/admin` cockpit answers what needs attention and points to the next workflow.
- **Configure**: Clients, Security, Keys, and DCR. These routes own setup, issuer posture, client posture, endpoint configuration, credentials, DCR onboarding, DCR policy, IAT inventory, and key lifecycle.
- **Support**: Consents and Tokens. These routes own account/client/status investigation, consent revocation, token revocation, and refresh-family response.
- **Operate**: Device Auth, Interactions, and Logouts. These routes own active protocol queues, device authorization expiry, and logout propagation delivery pressure.

This organization is deliberate: Orient, Configure, Support, and Operate are separate journeys even when they reference the same client.

Route groups remain concrete entries inside those journeys:

- **Overview** belongs to Orient.
- **Clients**, **Security**, **Keys**, and **DCR** belong to Configure.
- **Support** covers Consents and Tokens.
- **Operations** covers Device Auth, Interactions, and Logouts.

## DCR onboarding and DCR policy

Keep DCR onboarding separate from DCR policy:

- **DCR onboarding** lives primarily at `/admin/dcr`, `/admin/iats`, `/admin/iats/new`, self-registered client detail, and `/admin/clients/:client_id/rotate-registration-access-token`. It covers partner intake, short-lived Initial Access Tokens, self-registered clients, and registration access token support.
- **DCR policy** lives at `/admin/policies/dcr`. It covers issuer registration posture, allowed registration methods, and whether registration is disabled, IAT-gated, or open.

These workflows are connected, but they are not the same job. Operators may start in DCR onboarding, discover that issuer policy blocks the intake path, and pivot to DCR policy before returning to the onboarding route.

## Logout propagation workflow

Operators now have two separate logout-related surfaces on each client:

- **Post-logout redirect URIs**: browser destinations the RP may use after RP-initiated logout completes. Edit them at `/admin/clients/:client_id/logout-uris`.
- **Logout propagation URIs**: RP cleanup endpoints for back-channel and front-channel logout propagation. Edit them at `/admin/clients/:client_id/edit?workflow=logout-propagation`.

Keep those concerns separate: post-logout redirect URIs are browser destinations; logout propagation URIs are RP cleanup endpoints.

Lockspire's shipped truth model is:

- Back-channel logout is the durable path. After the host app clears its own browser session and returns to `/end_session/complete`, Lockspire persists delivery intent, then Oban runs Req-based POST delivery out of band.
- Front-channel logout is best effort only. Lockspire renders invisible iframes and a bounded continue page, but it does not claim remote success.
- Dynamic Client Registration now manages the same existing logout propagation metadata for eligible self-service clients. Operators still have an explicit admin workflow for review, correction, and support-driven updates.

## PAR Policy Management

Operators can control whether PAR is required for authorization requests:

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
- Admin workflows for operators

The host app owns:

- Accounts and sessions
- Operator authentication and authorization before the admin router
- Login UX and MFA
- Layouts and branding
- Product policy and authorization framing
