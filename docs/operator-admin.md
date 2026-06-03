# Operator And Admin Guide

Lockspire ships a library-owned operator surface for protocol state, while the host app keeps ownership of account UX.

For the canonical advanced-setup support contract, see `docs/supported-surface.md`. This guide stays subordinate to that contract and should not be read as a second support matrix.

## Lockspire-owned operator workflows

- Use `/admin` as the operator overview for client posture, security posture, key readiness, support incidents, and live protocol work
- Register and inspect OAuth clients from `/admin/clients`
- Rotate client secrets and registration access tokens from client detail workflows
- Inspect and revoke consents from `/admin/consents`
- Inspect and revoke tokens from `/admin/tokens`
- Publish, activate, and retire signing and encryption keys from `/admin/keys`
- Manage security posture from `/admin/policies`, with detailed PAR, Security Profile, DPoP, and DCR policy workflows
- Manage Global PAR policy at `/admin/policies/par`
- Manage Client PAR override at `/admin/clients/:client_id/par-policy`
- Manage Dynamic Client Registration onboarding from `/admin/dcr`, including Initial Access Tokens at `/admin/iats`
- Inspect runtime operations from `/admin/interactions`, `/admin/device_authorizations`, and `/admin/logouts`
- Edit post-logout redirect URIs separately from logout propagation settings
- Manage client logout propagation from the dedicated workflow at `/admin/clients/:client_id/edit?workflow=logout-propagation`

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

Keep the more specific admin forward before the general public OAuth/OIDC forward. Lockspire owns protocol and operator state after the request reaches its LiveViews; the host owns staff sessions, MFA, role checks, IP policy, and audit framing around access to those routes.

## Admin navigation model

The admin UI is organized around operator intent:

- **Overview**: the default `/admin` cockpit for attention, posture, and next actions.
- **Clients**: client inventory, registration, detail, redirect/logout URI edits, credentials, and per-client policy overrides.
- **Security**: issuer-level PAR, DPoP, FAPI/security profile, and DCR policy posture.
- **Keys**: signing and encryption key lifecycle with guided publish, activate, and retire actions.
- **DCR**: partner onboarding, Initial Access Tokens, self-registered clients, and registration access token support.
- **Support**: consent and token investigation/revocation workflows.
- **Operations**: interactions, device authorizations, and logout deliveries.

This organization is deliberate: setup, security, support, and runtime operations are separate journeys even when they reference the same client.

## Logout propagation workflow

Operators now have two separate logout-related surfaces on each client:

- **Post-logout redirect URIs**: where the RP may send the browser after RP-initiated logout completes.
- **Logout propagation**: the `backchannel_logout_uri`, `frontchannel_logout_uri`, and their `*_session_required` flags.

Keep those concerns separate. Redirect URIs are browser destinations; logout propagation URIs are RP cleanup endpoints.

Lockspire's shipped truth model is:

- Back-channel logout is the durable path. After the host app clears its own browser session and returns to `/end_session/complete`, Lockspire persists delivery intent, then Oban runs Req-based POST delivery out of band.
- Front-channel logout is best effort only. Lockspire renders invisible iframes and a bounded continue page, but it does not claim remote success.
- Dynamic Client Registration now manages the same existing logout propagation metadata for eligible self-service clients. Operators still have an explicit admin workflow for review, correction, and support-driven updates.

## PAR Policy Management

Operators can control whether PAR is required for authorization requests:

- **Global PAR policy**: The default requirement for all clients (Required or Optional).
- **Client PAR override**: A per-client setting that can override the global default.
- **Effective PAR requirement**: The resolved policy for a specific request, used by Lockspire to enforce or allow direct authorization.

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
