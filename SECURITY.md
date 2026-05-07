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
- confidential-client `private_key_jwt` authentication on Lockspire-owned direct-client endpoints using inline `jwks` or guarded `jwks_uri`
- generator-backed Phoenix install flow
- operator workflows for clients, consents, tokens, keys, and PAR policies
- FAPI 2.0 Security Profile enforcement when `security_profile: :fapi_2_0_security` is set globally or per-client: PAR-required at /authorize, DPoP sender-constrained access tokens at /token and /userinfo, ES256/PS256 signing only, exact-match redirect URIs with zero tolerance for trailing slashes or query drift
- RFC 9207 `iss` parameter on every authorization-response redirect (success, denial, and error) for all clients regardless of profile
- Truthful FAPI 2.0 keys in `.well-known/openid-configuration`: `authorization_response_iss_parameter_supported` (always true) and `require_pushed_authorization_requests` (true only when the global server policy is `:fapi_2_0_security`)

Unsupported or out-of-scope surfaces include:

- host-owned account databases
- host login/session implementations
- third-party IdP integrations not shipped in this repo
- hosted auth as a separate service
- request-object-by-value support and generic external `request_uri` handling
- SAML, LDAP, or generic federation features
- `client_secret_jwt`, mTLS client authentication, and generic JWT client-auth support outside Lockspire-owned direct-client endpoints
- DCR scope limits: software statements (RFC 7591 §2.3), external-IdP federation, FAPI bundles, and JAR-04 encryption
- DCR rate limiting: Lockspire does NOT provide built-in rate limiting for dynamic client registration endpoints. It is the host application's responsibility to protect these endpoints via Plug.

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

Lockspire does NOT claim:

- external OIDF FAPI 2.0 conformance suite certification (the harness is wired and pinned, but the live Docker run remains a manual maintainer step and is not a CI pass-gate)
- mTLS client authentication or mTLS-bound access tokens (DPoP is the supported sender-constraining mechanism; mTLS is permanently out of scope)

This file does not broaden the public support contract. For the full supported and out-of-scope surface, see `docs/supported-surface.md`.
