# Domain Pitfalls

**Domain:** Embedded OAuth/OIDC Provider for Elixir/Phoenix
**Researched:** 2025-05-24

## Critical Pitfalls

### Pitfall 1: mTLS Reverse Proxy Header Spoofing
**What goes wrong:** Malicious clients inject `X-Forwarded-Client-Cert` (or similar) into their HTTP requests. If the reverse proxy does not strip incoming headers before appending the actual client certificate, the Elixir application trusts the spoofed certificate.
**Why it happens:** Misconfigured load balancers (Nginx, HAProxy, AWS ALB). 
**Consequences:** Complete bypass of client authentication and sender-constrained token security. Critical CVE.
**Prevention:** Extensive documentation for the host app developer. Lockspire should potentially require a strict configuration explicit opt-in for header-based mTLS, acknowledging the security risk.

### Pitfall 2: CIBA Polling Exhaustion
**What goes wrong:** A consumption device initiates thousands of CIBA requests and continuously polls the token endpoint at a high frequency, exhausting the database connections or process limits.
**Why it happens:** Lack of rate limiting on the token endpoint for the `urn:openid:params:grant-type:ciba` grant.
**Prevention:** Implement strict compliance with the CIBA spec regarding `slow_down` error responses and mandatory minimum polling intervals.

## Moderate Pitfalls

### Pitfall 3: Token Exchange Infinite Delegation Loops
**What goes wrong:** Service A exchanges a token for Service B, which exchanges for Service C, which exchanges back for Service A.
**Prevention:** Implement strict `act` (actor) claim tracking as per RFC 8693 to maintain an audit trail and prevent circular delegation loops.

## Phase-Specific Warnings

| Phase Topic | Likely Pitfall | Mitigation |
|-------------|---------------|------------|
| 1.0 GA | Churning public APIs after GA | Strict semantic versioning and deprecation warnings in `Lockspire` core modules. |
| mTLS | Incompatible PEM/DER decoding | Provide helper functions to parse both URL-encoded PEMs and Base64 DER formats as proxies pass them differently. |
| RAR | Ecto schema bloat | Ensure host app can opt-out of RAR completely if they only use standard scopes. |
