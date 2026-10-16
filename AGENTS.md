# Lockspire Agent Guide

## Project

Lockspire

## What This Is

Lockspire is an embedded OAuth/OIDC authorization server library for Phoenix and Elixir. It helps a Phoenix SaaS team become an OAuth/OIDC provider inside its existing app, while the host app keeps ownership of accounts, login UX, layouts, branding, and product-specific policy.

## Core Value

A Phoenix team can become a trustworthy OAuth/OIDC provider inside its existing app without inventing the dangerous parts itself.

## Working Boundaries

- Build Lockspire as a separate companion library, not a Sigra module.
- Preserve the embedded-library shape; do not turn this into a required standalone auth service.
- Keep strong internal boundaries between protocol core, storage, generators, Plug/Phoenix integration, and LiveView/admin surfaces.
- Treat the host seam as explicit and narrow: account resolution, claims, login redirects, branding, and product policy belong to the host app.
- Do not broaden v1 into SAML, LDAP/AD federation, hosted auth, or a full CIAM suite.

## Technology Stack

- Phoenix `1.8.5`
- Phoenix LiveView `1.1.28`
- Ecto SQL `3.13.5`
- PostgreSQL `14+`
- Bandit (host apps, the adoption demo and clean-room hosts only; not a Lockspire dependency)
- Oban `2.21.x`
- OpenTelemetry `1.6.0`

## Product Priorities

1. Install DX for a host Phoenix app
2. Authorization code + PKCE and secure OAuth/OIDC defaults
3. OIDC discovery, JWKS, userinfo, revocation, introspection, and refresh lifecycle
4. Calm operator workflows for clients, consents, tokens, and keys
5. Telemetry, auditability, release hygiene, and executable docs

## Security Defaults To Preserve

- PKCE S256 required by default
- Exact-match redirect URI validation
- Client secrets hashed at rest
- Authorization codes short-lived and single-use
- Refresh token rotation with family-wide revocation on reuse
- No implicit flow
- No `alg=none`
- Strong redaction in logs and operator surfaces

## Admin UI Copy

- Before writing or changing admin UI text, read the personas and vocabulary map in `PRODUCT.md` and write for the least technical persona who uses the page.
- Use the "UI says" term from the vocabulary map. When a change introduces a new domain concept, add it to the map in the same change.
- When you replace wording, add the old phrase to the retired-wording table; `test/lockspire/web/live/admin/vocabulary_contract_test.exs` enforces it.
- Describe what Lockspire actually does, not what a setting's name implies.

## Planning References

- `.planning/PROJECT.md`
- `.planning/REQUIREMENTS.md`
- `.planning/ROADMAP.md`
- `.planning/STATE.md`
- `.planning/research/SUMMARY.md`
