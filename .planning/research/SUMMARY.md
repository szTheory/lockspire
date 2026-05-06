# Research Summary: JWKS URI & Private Key JWT

**Domain:** Embedded OAuth/OIDC provider for Phoenix/Elixir
**Researched:** 2026-05-06
**Milestone:** v1.15 JWKS URI & Private Key JWT Client Authentication
**Overall confidence:** HIGH

## Executive Summary

Lockspire already has most of the structural pieces for this milestone: the durable client model includes both `jwks` and `jwks_uri`, `Lockspire.JwksFetcher` already performs cached remote retrieval, and all direct-client endpoint flows already converge on `Lockspire.Protocol.ClientAuth`. The missing work is not new architecture so much as turning an incomplete auth method into a truthful, secure-by-default one.

The core product recommendation is:
- support `jwks_uri` as the normal remote-key path for confidential clients
- keep the fetcher intentionally narrow and SSRF-resistant
- upgrade `private_key_jwt` from payload-shape validation to full signature and claim verification
- publish endpoint metadata truthfully wherever the shared client-auth seam is used

## Key findings

### Stack additions
- No new dependency is required.
- Existing repo versions are sufficient: `Req 0.5.17`, `Cachex 4.1.1`, and `JOSE 1.11.12`.
- The likely implementation center is `Lockspire.Protocol.ClientAuth` plus a hardened `Lockspire.JwksFetcher` path.

### Feature table stakes
- `jwks_uri` support must be mutually exclusive with inline `jwks`.
- `private_key_jwt` must verify signature, `iss`, `sub`, `aud`, `exp`, and `jti`.
- Replay protection must remain durable.
- Discovery must publish the relevant auth-method and signing-alg metadata when these methods are supported.

### Architecture recommendation
- Keep key resolution and assertion verification Lockspire-owned.
- Reuse the shared client-auth seam across token, PAR, revocation, introspection, device authorization, token exchange, and CIBA.
- Isolate remote JWKS retrieval logic so fetch policy is testable independently of auth-claim logic.

### Watch-outs
- The January 2025 OpenID Foundation disclosure materially changes the audience story for `private_key_jwt`. The safer milestone choice is issuer-identifier audience validation rather than token-endpoint audience acceptance.
- The current `Lockspire.JwksFetcher` is useful but too permissive for a security milestone.
- Current `ClientAuth` tests prove replay and TTL behavior, but not cryptographic correctness.

## Recommended roadmap shape

1. Registration and metadata truth for `jwks_uri` and `private_key_jwt`
2. Guarded remote JWKS resolution with cache and refresh behavior
3. Full `private_key_jwt` verification in the shared auth seam
4. Endpoint regressions, docs, and release-truth closure

## Milestone-specific decisions suggested by research

- Choose `v1.15` and keep the wedge limited to `jwks_uri` plus `private_key_jwt`; do not add `client_secret_jwt`.
- Enforce issuer-identifier audience binding for `private_key_jwt`.
- Keep mTLS, federation, and signed metadata URIs out of scope.

## Sources
- RFC 7523: https://datatracker.ietf.org/doc/html/rfc7523
- RFC 8414: https://datatracker.ietf.org/doc/html/rfc8414
- OpenID Connect Registration 1.0: https://www.openid.net/specs/openid-connect-registration-1_0-39.html
- OpenID Connect Core 1.0: https://openid.net/specs/openid-connect-core-1_0-18.html
- OpenID Foundation responsible disclosure notice dated January 2025: https://openid.net/wp-content/uploads/2025/01/OIDF-Responsible-Disclosure-Notice-on-Security-Vulnerability-for-private_key_jwt.pdf
- Req docs: https://hexdocs.pm/req/Req.html
- Cachex docs: https://hexdocs.pm/cachex/Cachex.html
- JOSE docs: https://hexdocs.pm/jose/JOSE.JWK.html
