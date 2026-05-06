# Architecture Notes: JWKS URI & Private Key JWT

**Project:** Lockspire
**Researched:** 2026-05-06
**Milestone:** v1.15 JWKS URI & Private Key JWT Client Authentication

## Existing architecture fit

The repo already has the right boundary shape for this milestone:
- `Lockspire.Protocol.Registration` already models `private_key_jwt`, `jwks`, and `jwks_uri`.
- `Lockspire.Domain.Client` and `Lockspire.Storage.Ecto.ClientRecord` already persist `jwks_uri`.
- `Lockspire.Protocol.ClientAuth` is the single shared seam for direct client authentication.
- `Lockspire.JwksFetcher` already encapsulates remote JWKS retrieval and caching, but it is too permissive for v1.15 as-is.

## Recommended architecture

### 1. Keep trust resolution inside Lockspire
Do not push remote key validation to the host app. The milestone’s value is that Lockspire owns the dangerous part:
- resolve client key material from inline `jwks` or remote `jwks_uri`
- verify `private_key_jwt` cryptographically
- enforce replay, claim, and algorithm policy consistently

### 2. Split assertion processing into explicit steps
`Lockspire.Protocol.ClientAuth` should separate:
1. unverified extraction of header and payload for `client_id` lookup
2. registered-client auth-method validation
3. key resolution from `jwks` or `jwks_uri`
4. signature verification
5. claim validation (`iss`, `sub`, `aud`, `exp`, `iat`/`nbf`, `jti`)
6. replay recording

This keeps failure reasons precise and preserves a narrow seam for tests.

### 3. Make JWKS resolution a dedicated sub-boundary
Prefer a dedicated resolver module or a sharply expanded `Lockspire.JwksFetcher` contract:
- validate `jwks_uri` eligibility before network access
- fetch with safe Req options
- parse and cache JWKS
- optionally force-refresh once on key miss or signature mismatch

### 4. Truthful metadata is part of the architecture
If `private_key_jwt` is supported on an endpoint, discovery metadata must stay aligned:
- `token_endpoint_auth_methods_supported`
- `token_endpoint_auth_signing_alg_values_supported`
- `revocation_endpoint_auth_methods_supported`
- `revocation_endpoint_auth_signing_alg_values_supported`
- `introspection_endpoint_auth_methods_supported`
- `introspection_endpoint_auth_signing_alg_values_supported`

Inference from RFC 8414 and current repo usage:
because `ClientAuth` is reused by revocation and introspection today, metadata truth should cover those endpoints too, not just `/token`.

## Suggested phase build order

1. Registration, policy, and discovery truth
2. Guarded JWKS fetcher and cache behavior
3. Shared `private_key_jwt` verification in `ClientAuth`
4. Endpoint regressions, docs, and release-truth proof

## What changes vs. what stays put

### New or materially changed
- `Lockspire.Protocol.ClientAuth`
- `Lockspire.JwksFetcher` or a new client-key resolver beside it
- discovery metadata builders
- DCR/admin policy presentation
- tests across direct-client endpoints

### Likely unchanged
- core token storage model
- host seam ownership of accounts/login/branding
- operator/admin shape outside auth-method truth updates

## Primary sources
- RFC 8414: https://datatracker.ietf.org/doc/html/rfc8414
- RFC 7523: https://datatracker.ietf.org/doc/html/rfc7523
- OpenID Connect Core 1.0 / Section 9 family: https://openid.net/specs/openid-connect-core-1_0-18.html
- OpenID Foundation notice on `private_key_jwt` audience vulnerability (January 2025): https://openid.net/wp-content/uploads/2025/01/OIDF-Responsible-Disclosure-Notice-on-Security-Vulnerability-for-private_key_jwt.pdf
