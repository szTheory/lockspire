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

- Back-channel logout is the reliable path. `/end_session/complete` persists delivery intent, then Oban runs Req-based POST delivery out of band.
- Front-channel logout is best effort only. Lockspire renders invisible iframes and a bounded continue page, but it does not claim remote success.
- Dynamic Client Registration now manages the same existing logout propagation metadata for eligible self-service clients. Operators still have an explicit admin workflow for review, correction, and support-driven updates.

## PAR Policy Management

Operators can control whether PAR is required for authorization requests:

- **Global PAR policy**: The default requirement for all clients (Required or Optional).
- **Client PAR override**: A per-client setting that can override the global default.
- **Effective PAR requirement**: The resolved policy for a specific request, used by Lockspire to enforce or allow direct authorization.

## Remote `jwks_uri` diagnostics

For clients that use `private_key_jwt` with remote `jwks_uri`, the client detail page now exposes a read-only Remote JWKS posture panel.

That panel stays inside Lockspire's bounded support contract:

- it distinguishes healthy posture, transient fetch failure, HTTP failure, malformed payload, freshness-triggered recovery, and unsupported rollover posture;
- it shows remediation text without exposing raw JWKS bodies, JWT assertions, or secret-adjacent material;
- it can surface the last runtime observation separately from the current live probe, so operators can tell the difference between "the endpoint is reachable now" and "the last auth attempt hit an unsupported rollover shape".

For CLI-driven support work, operators can run:

```bash
mix lockspire.verify --remote-jwks-client your-client-id
```

That targeted mode is opt-in. It does not mean Lockspire is performing background remote-key monitoring or broader federation-style metadata management.

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
