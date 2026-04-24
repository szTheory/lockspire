# Lockspire

Lockspire is an embedded OAuth/OIDC authorization server library for Phoenix and Elixir applications.

It lets a Phoenix SaaS team become an OAuth/OIDC provider inside its existing app without moving accounts, login UX, branding, or product policy into a separate auth service.

The public support contract for the current `v0.1` preview lives in [`docs/supported-surface.md`](docs/supported-surface.md).

## What v0.1 includes

- Authorization code + PKCE
- Pushed authorization requests through Lockspire-issued `request_uri` references on the existing authorization code + PKCE path
- OIDC discovery and JWKS
- Userinfo, revocation, introspection, and refresh rotation
- Host-owned login and consent seams
- LiveView admin surfaces for clients, consents, tokens, and keys
- Generator-backed install flow for Phoenix hosts

## What v0.1 does not include

- Hosted auth as a separate service
- Request-object-by-value support, generic external `request_uri` handling, device flow, or dynamic client registration
- SAML or LDAP federation
- A full CIAM suite
- Lockspire-owned account tables or login UX

## Guides

- [Getting started](docs/getting-started.md)
- [Install and onboard](docs/install-and-onboard.md)
- [Operator and admin guide](docs/operator-admin.md)
- [Supported surface and preview contract](docs/supported-surface.md)
- [Maintainer and release guide](docs/maintainer-release.md)
- [Sigra companion host](docs/sigra-companion-host.md)
- [Security policy](SECURITY.md)
