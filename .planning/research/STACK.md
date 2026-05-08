# Technology Stack: JWKS URI & Private Key JWT

**Project:** Lockspire
**Researched:** 2026-05-06
**Milestone:** v1.15 JWKS URI & Private Key JWT Client Authentication

## Recommended Stack

### Existing foundation to reuse
| Technology | Version | Purpose | Why it fits this milestone |
|------------|---------|---------|-----------------------------|
| Elixir | `~> 1.18` | Core runtime | Existing runtime; no milestone-specific stack change needed. |
| Phoenix | `~> 1.8.5` | Mounted OAuth/OIDC endpoints | Existing direct-client endpoints already route through shared auth seams. |
| Ecto SQL / PostgreSQL | `~> 3.13.5` / `14+` | Durable client, token, and replay state | Existing `used_jti` durability and client metadata model already fit the wedge. |
| Req | `0.5.17` | Outbound JWKS fetch | Already shipped; official docs show `redirect`, `max_redirects`, `retry`, and timeout controls needed for a narrow fetcher. |
| Cachex | `4.1.1` | JWKS cache | Existing `Cachex.fetch/4` and TTL support match rotation-aware remote key caching. |
| JOSE | `1.11.12` | JWK parsing and JWS verification | Existing crypto library already supports `JOSE.JWK.from_map/1` and strict verification primitives. |

### No new mandatory dependency
The repo already contains the core pieces required for this milestone:
- `Lockspire.JwksFetcher` for outbound retrieval
- `Lockspire.Protocol.ClientAuth` for shared direct-client auth
- durable `jwks` and `jwks_uri` client fields
- durable `used_jti` replay recording in the client store seam

## Integration guidance

### Req
- Disable redirects for `jwks_uri` fetches rather than relying on defaults.
- Keep retries disabled for the synchronous auth path.
- Use aggressive connect and receive timeouts.
- Keep credentials off redirects even if redirects are accidentally enabled.

### Cachex
- Continue using read-through caching via `Cachex.fetch/4`.
- Cache successful JWKS retrievals with explicit TTL.
- On signature failure against a cached JWKS, allow one forced refresh path before returning `invalid_client`.

### JOSE
- Resolve a concrete public key by `kid` when present; otherwise attempt the narrow compatible key set.
- Reject symmetric and unsigned algorithms for `private_key_jwt`.
- Prefer asymmetric algorithms already aligned with Lockspire’s security posture (`RS256`, `PS256`, `ES256`, with `EdDSA` only if explicitly verified end to end).

## What not to add
- No new background job requirement for baseline support. Synchronous fetch plus cache is enough for the narrow slice.
- No general-purpose SSRF library unless the existing Elixir/Req boundary proves insufficient.
- No mTLS, signed metadata, or federation trust stack in this milestone.

## Primary sources
- RFC 8414 OAuth 2.0 Authorization Server Metadata: https://datatracker.ietf.org/doc/html/rfc8414
- RFC 7523 JWT Profile for OAuth 2.0 Client Authentication: https://datatracker.ietf.org/doc/html/rfc7523
- OpenID Connect Dynamic Client Registration 1.0 (errata set 2): https://www.openid.net/specs/openid-connect-registration-1_0-39.html
- Req docs `v0.5.17`: https://hexdocs.pm/req/Req.html
- Cachex docs `v4.1.1`: https://hexdocs.pm/cachex/Cachex.html
- JOSE docs `v1.11.12`: https://hexdocs.pm/jose/JOSE.JWK.html
