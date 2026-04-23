# Operator And Admin Guide

Lockspire ships a library-owned operator surface for protocol state, while the host app keeps ownership of account UX.

## Lockspire-owned operator workflows

- Register and inspect OAuth clients
- Rotate client secrets
- Inspect and revoke consents
- Inspect and revoke tokens
- Publish, activate, and retire signing keys

These routes live under the embedded Lockspire router and are meant for application operators.

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
