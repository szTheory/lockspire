# Supported Surface

Lockspire v0.1 is a focused embedded OAuth/OIDC provider library.

## Supported in scope

- Embedded Phoenix install flow
- Authorization code flow with PKCE S256
- OIDC discovery and JWKS
- Userinfo
- Refresh rotation
- Revocation
- Introspection
- Host-owned login and consent seams
- Operator/admin workflows for clients, consents, tokens, and keys

## Explicitly out of scope

- Implicit flow
- Hosted auth as a separate required service
- SAML
- LDAP or Active Directory federation
- Full CIAM or workforce identity platform scope
- Lockspire-owned account database or login UX

## Trust posture

Lockspire is aiming for a serious public preview bar first, then a stricter 1.0 bar.

That means public claims must stay inside what the repo can prove through:

- automated tests
- generated host fixtures
- CI gates
- versioned maintainer guidance

## Preview bar

A public preview can claim:

- one canonical Phoenix onboarding path
- secure default protocol behavior
- executable install and onboarding proof
- versioned docs and release automation
- a private disclosure path

It should not claim:

- broad ecosystem coverage
- certification or formal conformance
- production readiness for unsupported host shapes

## 1.0 bar

A `1.0` claim should require everything in the preview bar plus:

- stable support expectations
- maintainer runbooks that match real release operations
- repeated green release gates
- evidence that public docs, workflows, and shipped behavior still agree
