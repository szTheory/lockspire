# Feature Landscape: JWKS URI & Private Key JWT

**Project:** Lockspire
**Researched:** 2026-05-06
**Milestone:** v1.15 JWKS URI & Private Key JWT Client Authentication

## Table stakes

| Feature | Why expected | Complexity | Notes |
|---------|--------------|------------|-------|
| `jwks_uri` registration support | OIDC registration treats `jwks_uri` as the normal way to publish client keys and rotate them without re-registration. | Medium | Must stay mutually exclusive with inline `jwks`. |
| Full `private_key_jwt` signature verification | Current Lockspire path only validates payload shape and replay, not signature trust. | Medium | Must use client `jwks` or fetched `jwks_uri` keys. |
| Standard claim validation | `iss`, `sub`, `aud`, `exp`, and `jti` are the minimum safe assertion checks. | Medium | `iss` and `sub` should both bind to `client_id`. |
| Truthful metadata publication | RFC 8414 requires signing-alg metadata whenever JWT client auth methods are advertised for supported endpoints. | Medium | Token, revocation, and introspection metadata matter here. |

## Differentiators

| Feature | Value | Complexity | Notes |
|---------|-------|------------|-------|
| Narrow SSRF-guarded remote key retrieval | Keeps Lockspire embedded and trustworthy without outsourcing fetch risk to the host app. | High | `https` only, no redirects, public-IP-only resolution, body caps, tight timeouts. |
| Shared verification across all Lockspire-owned direct-client surfaces | One client-auth implementation raises trust everywhere it is reused. | Medium | Token, revocation, introspection, PAR, device authorization, token exchange, and CIBA all benefit. |
| Rotation-aware cache refresh | Lets clients rotate keys at `jwks_uri` without operator intervention. | Medium | One cache-bypass refresh on verification miss is enough for v1.15. |
| Security-posture-aligned audience enforcement | Avoids drifting into known multi-AS `private_key_jwt` audience footguns. | Medium | January 2025 OIDF guidance pushes implementations toward issuer-identifier audience binding. |

## Anti-features

| Anti-feature | Why avoid | Instead |
|-------------|-----------|---------|
| `client_secret_jwt` in the same milestone | Broadens the auth-method matrix without adding the same trust gain as `private_key_jwt`. | Keep the milestone asymmetric-only. |
| Signed JWKS URI / federation trust chains | Expands into federation and metadata trust distribution. | Limit v1.15 to plain `jwks` and guarded `jwks_uri`. |
| mTLS client authentication | Breaks the embedded Phoenix ergonomics through proxy and TLS edge complexity. | Keep DPoP as the sender-constraining story. |
| Generic outbound fetch framework | Too much surface for a single milestone. | Keep a single-purpose JWKS fetcher. |

## Feature dependencies

`jwks_uri` intake/policy -> guarded fetcher/cache -> client-auth verification -> truthful metadata/docs -> end-to-end proof

## Recommendation

Build the milestone around four feature groups:
1. Registration and policy truth
2. Secure JWKS resolution
3. Shared `private_key_jwt` verification
4. Discovery/docs/verification closure

## Primary sources
- RFC 7523: https://datatracker.ietf.org/doc/html/rfc7523
- RFC 8414: https://datatracker.ietf.org/doc/html/rfc8414
- OpenID Connect Registration 1.0: https://www.openid.net/specs/openid-connect-registration-1_0-39.html
- OpenID Connect CIBA Core 1.0: https://openid.net/specs/openid-client-initiated-backchannel-authentication-core-1_0-final.html
