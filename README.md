# Lockspire

Lockspire is an embedded OAuth/OIDC authorization server library for Phoenix and Elixir applications.

It lets a Phoenix SaaS team become an OAuth/OIDC provider inside its existing app without moving accounts, login UX, branding, or product policy into a separate auth service.

The public support contract for the current release lives in [`docs/supported-surface.md`](docs/supported-surface.md).

## Current release posture

Lockspire `1.0.0` is the GA release of the embedded Phoenix library wedge documented in [`docs/supported-surface.md`](docs/supported-surface.md). That file is the authoritative support contract and proof boundary for the current release.

## Orientation

- Embedded OAuth/OIDC provider behavior inside an existing Phoenix app, not a hosted auth service or separate control plane
- Generator-backed install and onboarding with host-owned login, account, branding, and product-policy seams
- Core OAuth/OIDC surface for the documented embedded wedge, with exact supported and unsupported claims defined in the canonical support contract
- Maintainer and operator workflows that stay subordinate to the same repo-proven support boundary

## What Lockspire is not

- Hosted auth as a separate service
- SAML or LDAP federation
- A full CIAM suite
- Lockspire-owned account tables or login UX

For exact scope, non-claims, and repo-owned proof, read [`docs/supported-surface.md`](docs/supported-surface.md) before relying on a feature or topology.

## Guides

- [Getting started](docs/getting-started.md)
- [Install and onboard](docs/install-and-onboard.md)
- [Private key JWT host guide](docs/private-key-jwt-host-guide.md)
- [Operator and admin guide](docs/operator-admin.md)
- [Supported surface and GA contract](docs/supported-surface.md)
- [Maintainer and release guide](docs/maintainer-release.md)
- [Sigra companion host](docs/sigra-companion-host.md)
- [Security policy](SECURITY.md)
