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

`docs/supported-surface.md` is the canonical public support contract. This file stays subordinate to it and does not define a second feature or topology matrix.

Security reports are in scope when they affect the embedded Phoenix surface the repo currently proves, especially:

- Lockspire-owned authorization-server endpoints and token handling
- generator-backed install and upgrade scaffolding that Lockspire ships and maintains
- host-seam contracts documented in repo-owned guides, such as login/consent handoff and the `/verify` device flow seam
- confidential-client `private_key_jwt` support on Lockspire-owned direct-client endpoints
- JAR request objects by value on the shipped `/authorize` and `/par` paths
- the bounded reactive remote-`jwks_uri` verification path on the shipped direct-client surfaces
- the two shipped mTLS extraction patterns plus certificate-bound token enforcement after certificate extraction
- host Phoenix API route protection for Lockspire-issued access tokens through the documented `Lockspire.Plug.VerifyToken -> Lockspire.Plug.EnforceSenderConstraints -> Lockspire.Plug.RequireToken` pipeline
- secure defaults and FAPI 2.0 Security Profile enforcement shipped in this repo

Out of scope examples remain:

- host-owned account databases, login/session implementations, or rate limiting
- hosted auth as a separate service
- third-party IdP integrations not shipped in this repo
- external JAR-by-reference, generic external `request_uri` handling, SAML, LDAP, or generic federation features
- arbitrary custom `Lockspire.MTLS.Extractor` implementations as first-class peers to the two shipped extraction patterns
- generic gateway, service-mesh, or third-party issuer protected-resource middleware
- generic JWT client-auth support outside Lockspire-owned direct-client endpoints
- claims that front-channel logout is durable or that DCR creates a second logout runtime
- DCR scope not named in the canonical support contract, including software statements (RFC 7591 §2.3), external-IdP federation, FAPI bundles, and external JAR-by-reference

## Secure defaults

- PKCE S256 required by default
- exact-match redirect URI validation
- client secrets hashed at rest
- short-lived, single-use authorization codes
- refresh-token family revocation on reuse
- no implicit flow
- no `alg=none`
- issuer-string `aud` for `private_key_jwt`
- generic `invalid_client` wire failures with strong redaction of client assertions and JWKS bodies in logs and operator surfaces

## Guarded remote JWKS fetch

When a confidential client uses `jwks_uri`, Lockspire performs remote key retrieval through a narrow guarded fetch path:

- `https` only
- redirects disabled
- unsafe resolved targets rejected before request dispatch
- bounded timeouts and payload size
- cached last-known-good key material preserved when forced refresh fails

This fetch path exists only to verify `private_key_jwt` client assertions on Lockspire-owned direct-client endpoints. It is not a general outbound metadata-ingestion capability.

## FAPI 2.0 posture

Lockspire ships the FAPI 2.0 Security Profile enforcement stack listed above and pins the
canonical OIDF FAPI 2.0 plan (`fapi2-security-profile-final-test-plan`) plus its variant
axes in `scripts/conformance/fapi2-plan.json` and `docs/maintainer-conformance.md`.

Both DPoP and mTLS are supported sender-constraining mechanisms for FAPI 2.0.

Lockspire does NOT claim:

- external OIDF FAPI 2.0 conformance suite certification (the harness is wired and pinned, but the live Docker run remains a manual maintainer step and is not a CI pass-gate)

This file does not broaden the public support contract. For the full supported and out-of-scope surface, see `docs/supported-surface.md`.
