# Supported Surface

Lockspire `v0.1` is a preview release of an embedded OAuth/OIDC authorization server library for Phoenix and Elixir. It is meant for Phoenix teams that want to become an OAuth/OIDC provider inside an existing app while keeping accounts, login UX, layouts, branding, and product policy in the host application.

This page is the canonical preview contract for what Lockspire currently supports, what it does not support, and what repo-owned proof backs those claims.

## Supported in scope

Lockspire `v0.1` preview currently supports this repo-proven surface:

- Embedded Phoenix install flow through `mix lockspire.install`
- Authorization code flow with PKCE S256
- Pushed authorization requests only as Lockspire-issued `request_uri` references that extend the existing authorization code + PKCE flow
- OIDC discovery and JWKS
- Userinfo
- Revocation
- Introspection
- Refresh token rotation
- Host-owned login redirects and consent handoff seams
- LiveView and admin workflows for clients, consents, tokens, and keys
- Phoenix-first onboarding docs and generated host integration files

## Explicitly out of scope

Lockspire `v0.1` preview does not currently support:

- Implicit flow
- Request-object-by-value support
- Generic external `request_uri` handling outside Lockspire's own PAR endpoint
- Device flow
- Dynamic client registration
- Hosted auth as a separate required service
- SAML
- LDAP or Active Directory federation
- Full CIAM or workforce identity platform scope
- Lockspire-owned account database, passwords, or login UX
- Broad compatibility claims beyond the Phoenix/Elixir embedded-library path documented in this repo

## Trust posture

Lockspire stays at `v0.1` preview because public claims are limited to what this repo can prove today. Repo-owned proof for this preview posture lives in:

- `docs/install-and-onboard.md` as the canonical Phoenix host onboarding path
- `test/integration/install_generator_test.exs` for generator-backed install proof
- `test/integration/phase6_onboarding_e2e_test.exs` for the canonical auth-code + PKCE onboarding flow
- `test/lockspire/release_readiness_contract_test.exs` for narrow release and docs posture checks
- `.github/workflows/ci.yml` and `.github/workflows/release.yml` for maintained contributor and protected release lanes
- `docs/maintainer-release.md` and `SECURITY.md` for versioned release and disclosure guidance

Lockspire does not use a demo app, certification language, or external folklore as its primary public proof story.

## Preview bar

A `v0.1` preview claim can honestly say:

- there is one canonical Phoenix onboarding path
- secure OAuth/OIDC defaults are enforced inside the supported surface
- executable install and onboarding proof is checked into the repo
- contributor and release workflows are versioned in the repo
- a private disclosure path exists for supported security issues

A `v0.1` preview claim should not say:

- Lockspire is production-ready for unsupported host shapes
- Lockspire supports broader request-object modes, generic external `request_uri` handling, device flow, dynamic client registration, SAML, or LDAP
- Lockspire is a hosted auth service or full CIAM product
- Lockspire has broad certification or conformance coverage

## 1.0 bar

A `1.0` claim should require everything in the preview bar plus:

- repeated green release gates in the trusted publish lane
- maintainer runbooks that match real release operations
- stable support expectations for the documented embedded-library surface
- evidence that public docs, workflows, and shipped behavior still agree over time
