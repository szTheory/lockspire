# Operator And Admin Guide

Lockspire ships a library-owned operator surface for protocol state, while the host app keeps ownership of account UX.

## Lockspire-owned operator workflows

- Register and inspect OAuth clients
- Rotate client secrets
- Inspect and revoke consents
- Inspect and revoke tokens
- Publish, activate, and retire signing keys
- Manage Global PAR policy at `/admin/policies/par`
- Manage Client PAR override at `/admin/clients/:client_id/par-policy`
- Edit post-logout redirect URIs separately from logout propagation settings
- Manage client logout propagation from the dedicated workflow at `/admin/clients/:client_id/edit?workflow=logout-propagation`

These routes live under the embedded Lockspire router and are meant for application operators.

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
- Login UX and MFA
- Layouts and branding
- Product policy and authorization framing
