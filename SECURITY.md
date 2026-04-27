# Security Policy

## Reporting a vulnerability

Please do not file public issues for suspected security vulnerabilities.

Use one of these private paths instead:

- Open a GitHub Security Advisory draft for this repository.
- If advisories are unavailable, contact the maintainer account listed in repository ownership and request a private security channel before sharing details.

Include:

- affected Lockspire version or commit
- deployment shape and Phoenix version
- reproduction steps
- expected impact
- whether bearer material, secrets, or private user data were exposed

## Response expectations

Lockspire aims to:

- acknowledge new reports promptly
- confirm severity and affected surface
- ship fixes or mitigations through the normal changelog and release flow
- avoid disclosing exploit details publicly before a fix is available

## Supported security surface

Lockspire's supported security surface is limited to the embedded OAuth/OIDC provider behavior shipped in this repo and described in `docs/supported-surface.md`:

- authorization code + PKCE
- pushed authorization requests only through Lockspire-issued `request_uri` references on the authorization code + PKCE path (supports `required` or `optional` policy enforcement)
- discovery and JWKS
- userinfo
- revocation and introspection
- refresh token rotation
- generator-backed Phoenix install flow
- operator workflows for clients, consents, tokens, keys, and PAR policies

Unsupported or out-of-scope surfaces include:

- host-owned account databases
- host login/session implementations
- third-party IdP integrations not shipped in this repo
- hosted auth as a separate service
- request-object-by-value support, generic external `request_uri` handling, and device flow
- SAML, LDAP, or generic federation features
- DCR scope limits: software statements (RFC 7591 §2.3), external-IdP federation, FAPI bundles, JAR-04 encryption, and `jwks_uri` outbound fetch
- DCR rate limiting: Lockspire does NOT provide built-in rate limiting for dynamic client registration endpoints. It is the host application's responsibility to protect these endpoints via Plug.

## Secure defaults

- PKCE S256 required by default
- exact-match redirect URI validation
- client secrets hashed at rest
- short-lived, single-use authorization codes
- refresh-token family revocation on reuse
- no implicit flow
- no `alg=none`

This file does not broaden the public preview contract. For the full supported and out-of-scope surface, see `docs/supported-surface.md`.
