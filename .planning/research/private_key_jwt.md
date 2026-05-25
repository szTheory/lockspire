# Research: Private Key JWT Client Authentication (RFC 7523)

**Project:** Lockspire
**Researched:** Current Year
**Overall Confidence:** HIGH

## Executive Summary

`private_key_jwt` (RFC 7523) is the gold standard for secure client authentication in OpenID Connect (OIDC). Instead of using a static, shared `client_secret`, the client generates a short-lived JSON Web Token (JWT), signs it with its own private key, and sends it as a `client_assertion` to the Authorization Server (Lockspire). The server validates the signature using the client's registered public key or by dynamically fetching keys via a `jwks_uri`.

For Lockspire, as an embedded Elixir/Phoenix OIDC provider, implementing `private_key_jwt` effectively means navigating specific cryptographic requirements, managing external network calls for key retrieval, and enforcing strict replay protection without degrading the developer experience (DX). 

## 1. Pros, Cons, and Tradeoffs

### Pros
- **No Shared Secrets:** Lockspire never sees the client's private key, drastically reducing the attack surface. A breach of the Lockspire database does not leak client credentials.
- **Key Rotation (Zero Downtime):** If a client uses a `jwks_uri`, they can rotate their keys asynchronously. Lockspire will simply fetch the new public keys, avoiding manual credential updates.
- **Non-repudiation:** The use of asymmetric cryptography ensures cryptographic proof of the client's identity.
- **Compliance:** Required for Financial-grade API (FAPI) and highly regulated environments.

### Cons & Tradeoffs
- **Complexity for Clients:** Client developers must generate keypairs, securely store private keys (e.g., in HSMs or KMS), and implement JWT signing logic.
- **Stateful Replay Protection:** Lockspire must persistently track the `jti` (JWT ID) of every assertion until its expiration time (`exp`) to prevent replay attacks.
- **Network Dependency:** If `jwks_uri` is used, Lockspire must make outbound HTTP requests during the `/token` exchange, introducing latency and potential failure points.
- **Performance Overhead:** Asymmetric signature verification (RS256/ES256) is computationally heavier than symmetric HMAC (HS256) validation.

## 2. Lessons Learned from the Ecosystem 

Analysis of issues in `node-oidc-provider`, IdentityServer, and Keycloak reveals several common "footguns" that Lockspire must actively mitigate to ensure good DX.

### A. The "Audience" Trap (`aud` claim)
**The Problem:** The RFC states the `aud` claim must identify the authorization server. Client libraries are inconsistent—some send the Issuer URL (e.g., `https://auth.example.com`), while others send the exact Token Endpoint URL (e.g., `https://auth.example.com/oauth/token`). In `node-oidc-provider`, being overly strict here is the #1 cause of `invalid_client` errors.
**The Solution (DX Focus):** Lockspire should strictly validate the `aud` claim but be **permissive in its accepted values**, allowing *either* the exact Token Endpoint URL or the Issuer URL.

### B. Distributed JTI Replay Protection
**The Problem:** Clients send a unique `jti` (JWT ID) to prevent replay attacks. A common mistake is using in-memory caches for tracking used `jti`s. In a multi-node deployment, an attacker could replay the same JWT against different nodes if the cache isn't distributed.
**The Solution:** Lockspire is built for the BEAM, which natively supports clustering. However, the safest and most stateless approach is an **Ecto-backed JTI tracking table** (e.g., `lockspire_used_jtis`) with a unique index. Since assertions are short-lived (usually < 5 minutes), the table can be routinely pruned via Oban.

### C. The JWKS Network Tar Pit
**The Problem:** When fetching public keys from a client's `jwks_uri`, a slow or unresponsive client server can exhaust Lockspire's connection pool, causing a denial-of-service.
**The Solution:** Lockspire must use a robust HTTP client (like Finch) with **aggressive timeouts** (e.g., 2-3 seconds max) for `jwks_uri` fetches. Furthermore, JWKS responses *must* be cached locally using `:ets` or Nebulex, respecting the HTTP `Cache-Control` headers provided by the client, with a fallback TTL.

### D. Clock Skew and "Not Yet Valid" Tokens
**The Problem:** If the client's system clock is slightly ahead of Lockspire's server, the `iat` (Issued At) or `nbf` (Not Before) claims will cause token rejection.
**The Solution:** Allow a reasonable clock tolerance (e.g., 30–60 seconds leeway) when validating timestamps in Joken/JOSE.

## 3. Idiomatic Elixir / Ecto / Plug Patterns

### The Authentication Flow (Plug/Context)
1. **Extraction:** A Plug or controller function inspects the request for `client_assertion_type=urn:ietf:params:oauth:client-assertion-type:jwt-bearer` and the `client_assertion` parameter.
2. **Unverified Parsing:** Use `JOSE.JWT.peek/1` or `Joken.peek_claims/1` to extract the unverified payload.
3. **Client Lookup:** Extract the `sub` (or `iss`) claim to identify the `client_id` and load the client from the database using Ecto.
4. **Key Resolution:** 
   - If the client has a statically registered `jwks` in Ecto, use it.
   - If the client uses a `jwks_uri`, fetch the keys (via cache or HTTP request).
   - Filter the keys to find the one matching the `kid` (Key ID) from the JWT header.
5. **Verification:** Use `JOSE.JWT.verify/2` with the resolved public key to validate the cryptographic signature. Ensure the algorithm (`alg` header) is an allowed asymmetric algorithm (e.g., `RS256`, `ES256`, `PS256`) and explicitly reject `none` or symmetric (`HS256`) algorithms.
6. **Claims Validation:** Validate `exp`, `nbf`, `aud`, and `iss`.
7. **Replay Check:** Insert the `jti` and `exp` into the Ecto JTI tracking table. If a unique constraint violation occurs, reject the request as a replay attack.

### Schema Adjustments
The `Lockspire.Domain.Client` Ecto schema must support:
- `jwks`: A `:map` (JSONB) field to store statically registered public keys.
- `jwks_uri`: A `:string` field for dynamic key retrieval.
- `token_endpoint_auth_method`: Must support the string literal `"private_key_jwt"`.

### JWKS Caching Module
Implement a dedicated module (e.g., `Lockspire.Clients.JWKSCache`) using Elixir's `:ets` or a GenServer. 
When a `/token` request arrives with `jwks_uri`:
```elixir
def get_keys(jwks_uri) do
  case Cache.lookup(jwks_uri) do
    {:ok, keys} -> keys
    :error -> fetch_and_cache(jwks_uri)
  end
end
```
*Note: Ensure the cache handles key rotation properly—if verification fails with a cached key, but the cache is somewhat old, it may be appropriate to bypass the cache, fetch fresh keys, and try again before failing the request.*

## 4. Developer Ergonomics & Principle of Least Surprise

To make Lockspire's `private_key_jwt` implementation a joy to use:
- **Actionable Error Messages:** If a client fails authentication, return an explicit error code but log the exact reason internally (e.g., "invalid_client: audience mismatch", "invalid_client: expired assertion", "invalid_client: jti replayed"). 
- **Tooling Support:** Provide a Mix task or a Lockspire Admin UI helper that lets developers paste a `client_assertion` to see exactly why it is failing validation against a specific client.
- **Sensible Defaults:** Default clock tolerance to 60 seconds.
- **Fail Closed, but Gracefully:** If a `jwks_uri` request times out, return a standard `invalid_client` error to the client, but log a warning indicating that the upstream JWKS endpoint was unreachable.

## Summary of Recommendations

1. **Permissive Audience:** Accept both `Issuer URL` and `Token Endpoint URL` in the `aud` claim.
2. **Ecto-Backed JTI:** Use a DB table for `jti` replay protection with an Oban pruner.
3. **Aggressive JWKS Timeouts:** Use `Finch` with low timeouts and locally cache `jwks_uri` responses.
4. **Clock Leeway:** Implement a 60-second tolerance for time-based claims.
5. **Strict Crypto:** Reject `none` and symmetric algorithms unconditionally for `private_key_jwt` flows.