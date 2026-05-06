# Pitfalls: JWKS URI & Private Key JWT

**Project:** Lockspire
**Researched:** 2026-05-06
**Milestone:** v1.15 JWKS URI & Private Key JWT Client Authentication

## Highest-risk pitfalls

### 1. Treating `private_key_jwt` as “claims-only”
Current repo truth: `Lockspire.Protocol.ClientAuth` records replay and checks TTL, but it does not yet verify the JWS signature against client keys.

Why this is dangerous:
- any actor who can guess a valid `client_id` can fabricate an unsigned or attacker-signed assertion that passes the current structural checks
- the product would advertise stronger client auth than the repo actually proves

Prevent it:
- require strict JWS verification before any replay side effect
- reject `alg=none` and symmetric algorithms for this method
- bind verification to registered client keys only

### 2. Overly broad `jwks_uri` fetch behavior
Current repo truth: `Lockspire.JwksFetcher` uses caching and timeouts, but it does not yet show redirect bans, DNS/IP screening, or body-size constraints.

Why this is dangerous:
- SSRF against internal services
- unexpected redirect chains
- denial of service through large or slow responses

Prevent it:
- `https` only
- no redirects
- DNS and resolved-address filtering to public IP ranges only
- body cap and low timeouts
- standard `invalid_client` outward failure with detailed internal telemetry

### 3. Accepting the wrong `aud` shape
Historical specs often allowed or encouraged token-endpoint audience values. On 2025-01, the OpenID Foundation published a responsible disclosure explaining cross-AS impersonation risk when clients reuse keys across authorization servers and audiences are endpoint-based.

Prevent it:
- default Lockspire to issuer-identifier audience validation for `private_key_jwt`
- document the choice explicitly in security and support docs
- keep tests pinned to the safer audience rule

### 4. Publishing partial metadata truth
If discovery advertises `private_key_jwt`, RFC 8414 expects signing-alg metadata for the affected endpoint metadata entries.

Prevent it:
- update endpoint auth-method metadata and signing-alg metadata together
- cover token, revocation, and introspection, not only token endpoint discovery

### 5. Replay recording before full validation
Recording `jti` before signature or audience validation lets invalid assertions poison the replay store.

Prevent it:
- record replay only after signature and claims are fully accepted
- keep expiry-derived TTL tied to the accepted assertion validity window

### 6. Stale-cache-only key validation
If a client rotates keys at `jwks_uri`, permanent cache reliance turns valid assertions into false negatives.

Prevent it:
- allow one forced refresh on verification miss
- do not silently widen acceptance beyond the registered client’s key set

## Phase ownership

| Pitfall | Best phase to close |
|---------|---------------------|
| Claims-only verification | shared auth phase |
| SSRF / redirect / slow-fetch risk | JWKS fetcher phase |
| Wrong audience rule | shared auth phase plus docs |
| Metadata drift | discovery/docs phase |
| Replay poisoning | shared auth phase |
| Rotation false negatives | JWKS fetcher phase plus endpoint regressions |

## Primary sources
- RFC 7523: https://datatracker.ietf.org/doc/html/rfc7523
- RFC 8414: https://datatracker.ietf.org/doc/html/rfc8414
- OpenID Foundation responsible disclosure notice dated January 2025: https://openid.net/wp-content/uploads/2025/01/OIDF-Responsible-Disclosure-Notice-on-Security-Vulnerability-for-private_key_jwt.pdf
