# Lockspire

Lockspire is an embedded OAuth/OIDC authorization server for Phoenix applications.

It lets a Phoenix SaaS team become an OAuth/OIDC provider inside its existing app without moving accounts, login UX, branding, or product policy into a separate auth service.

## What v0.1 includes

- Authorization code + PKCE
- OIDC discovery and JWKS
- Userinfo, revocation, introspection, and refresh rotation
- Host-owned login and consent seams
- LiveView admin surfaces for clients, consents, tokens, and keys
- Generator-backed install flow for Phoenix hosts

## What v0.1 does not include

- Hosted auth as a separate service
- SAML or LDAP federation
- A full CIAM suite
- Lockspire-owned account tables or login UX

## Canonical install path

1. Add `:lockspire` to your Phoenix app.
2. Run `mix lockspire.install`.
3. Import the generated config and router snippets into your host app.
4. Implement the generated `AccountResolver` and interaction handoff modules.
5. Run migrations, register a client, and complete an auth-code + PKCE flow.

The canonical proof for that path lives in:

- `test/integration/install_generator_test.exs`
- `test/integration/phase6_onboarding_e2e_test.exs`

## Secure defaults

- PKCE S256 required by default
- Exact-match redirect URI validation
- Authorization codes are single-use and short-lived
- Refresh token rotation revokes the full family on reuse
- Client secrets are hashed at rest
- No implicit flow
- No `alg=none`

## Guides

- [Getting started](docs/getting-started.md)
- [Install and onboard](docs/install-and-onboard.md)
- [Operator and admin guide](docs/operator-admin.md)
- [Supported surface](docs/supported-surface.md)
- [Maintainer and release guide](docs/maintainer-release.md)
- [Sigra companion host](docs/sigra-companion-host.md)
- [Security policy](SECURITY.md)

## Release discipline

Lockspire ships as an Apache-2.0 library with versioned docs, CI gates, changelog automation, and Hex dry-run validation in-repo.
