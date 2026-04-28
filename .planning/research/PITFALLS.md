# Pitfalls Research

**Domain:** Embedded OIDC Provider (JAR Decryption, Back/Front-Channel Logout, Core Conformance)
**Researched:** 2024-05-24 (Current Date)
**Confidence:** HIGH

## Critical Pitfalls

### Pitfall 1: Front-Channel Logout Broken by Third-Party Cookies

**What goes wrong:**
The Identity Provider (IdP) renders a hidden `<iframe>` pointing to the Relying Party's (RP) logout endpoint. The RP's code attempts to clear its session cookie, but the browser blocks it. The user remains logged into the RP even after logging out of the IdP.

**Why it happens:**
Modern browsers (Safari, Firefox, Chrome) block third-party cookies by default. Since the iframe is hosted on the IdP's domain but points to the RP's domain, the browser treats the RP's session cookies as third-party and restricts access, breaking the standard Front-Channel Logout flow.

**How to avoid:**
Do not rely on Front-Channel Logout for cross-domain RPs. Prioritize **Back-Channel Logout**. If Front-Channel Logout must be supported, explicitly document that it only reliably functions when the IdP and RP share a parent domain (e.g., `auth.example.com` and `app.example.com`) so cookies are treated as first-party.

**Warning signs:**
Users report being still logged into partner apps after a central logout. Logout test suites pass on localhost but fail in production environments with strict browser privacy settings.

**Phase to address:**
Phase addressing OIDC Logout Mechanisms.

---

### Pitfall 2: The Back-Channel Logout "Cookie Trap"

**What goes wrong:**
The IdP sends a valid Back-Channel Logout request (a POST with a JWT) to the RP, but the RP's session is never terminated.

**Why it happens:**
Developers mistakenly try to invalidate the session using standard browser session mechanisms (like `request.getSession().invalidate()` or trying to read/delete a cookie). Because the request is a server-to-server webhook from the IdP, it **does not contain the user's browser cookies**.

**How to avoid:**
The RP must parse the Logout Token (JWT), extract the `sid` (Session ID) or `sub` (Subject), and invalidate the session directly in the backend session store (e.g., Database, Redis). If the RP uses stateless JWTs, it must implement a Revocation List (Logout Store) to reject the revoked `jti`/`sid` until the token naturally expires.

**Warning signs:**
Back-Channel Logout endpoints return `200 OK` but sessions remain active.

**Phase to address:**
Phase addressing Back-Channel Logout.

---

### Pitfall 3: The JWE "Encryption-Only" Trap

**What goes wrong:**
The Authorization Server (AS) accepts a JWE-encrypted Request Object, decrypts it, and processes the authorization request, but it cannot guarantee who actually sent the request.

**Why it happens:**
Encryption (JWE) provides confidentiality but not **source authentication**. If an attacker obtains the AS's public encryption key, they can encrypt and submit a malicious request object.

**How to avoid:**
Enforce the **Sign-then-Encrypt** pattern (Nested JWTs). The Client must first sign the Request Object with a JWS, and then encrypt the resulting JWS with a JWE. The AS must decrypt the JWE, and then verify the inner JWS signature before processing any claims.

**Warning signs:**
Accepting Request Objects that only have JWE headers (e.g., `alg: RSA-OAEP`, `enc: A256GCM`) without an inner signed payload.

**Phase to address:**
Phase addressing JAR Decryption / Encrypted Request Objects.

---

### Pitfall 4: OIDC Conformance Type Strictness

**What goes wrong:**
The OIDC Provider fails the official OpenID Foundation (OIDF) Conformance Suite on basic token validation tests, even though the tokens work fine in common libraries.

**Why it happens:**
The OIDF Conformance Suite is extremely strict about the JSON types defined in the specification. A common mistake is rendering `iat` (Issued At) or `exp` (Expiration Time) claims as strings (`"1716500000"`) instead of numeric integers (`1716500000`).

**How to avoid:**
Ensure the JSON encoder strongly enforces integer types for all timestamp claims across ID Tokens, UserInfo responses, and Logout Tokens. Also, ensure exact matching for `redirect_uri` (no fuzzy matching, ignoring trailing slashes, or subdomains).

**Warning signs:**
`oidcc-basic-certification` fails immediately on token format validation.

**Phase to address:**
Phase addressing OIDC Core Conformance / Certification.

---

## Technical Debt Patterns

Shortcuts that seem reasonable but create long-term problems.

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| Supporting `dir` (symmetric) JWE encryption | Easier key setup for clients | Forces the AS to store `client_secret` in plaintext or reversible encryption, breaking secure hashing models. | Never for secure-by-default embedded providers. Stick to asymmetric encryption. |
| Fuzzy `redirect_uri` matching | Fewer client integration errors | High risk of Open Redirect and Authorization Code interception attacks. Fails OIDC conformance. | Never. Must be exact match. |
| Ignoring Logout Token `sub` (Global Logout) | Simpler implementation (only checking `sid`) | If a client triggers a global logout without a specific `sid`, the user remains logged in across other sessions. | Only in MVP if explicitly documented as unsupported; must fix for production. |

## Integration Gotchas

Common mistakes when connecting to external services.

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| Back-Channel Logout | Returning a `302 Redirect` to a "Logged Out" UI page from the back-channel endpoint. | Return `200 OK` or `204 No Content`. The request is from the IdP server, not a browser. |
| Back-Channel Logout | Hosting the RP logout endpoint on `localhost` or behind a strict corporate firewall. | The IdP must be able to reach the RP's endpoint. Ensure it is publicly routable or firewall rules permit IdP IPs. |
| JAR `request_uri` | Unrestrictedly fetching any URI provided by the client in a JAR authorization request. | Risk of SSRF (Server-Side Request Forgery). Require Pushed Authorization Requests (PAR) instead, or strictly whitelist allowed domains. |

## Performance Traps

Patterns that work at small scale but fail as usage grows.

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| Asymmetric JWE Key Rotation Lockout | Clients suddenly fail to authenticate with "decryption failed" errors. | The AS rotated its private key, but clients cached the old public key. Support multiple active encryption keys (via JWKS `kid`) and overlap their lifespans during rotation. | At first key rotation. |
| Large JWKS Responses | High bandwidth usage, timeouts during automated testing/conformance. | Limit the number of active and expired keys in the published JWKS. Purge old keys promptly after their overlap window. | > 10 keys in JWKS. |

## Security Mistakes

Domain-specific security issues beyond general web security.

| Mistake | Risk | Prevention |
|---------|------|------------|
| Accepting `nonce` in Logout Tokens | Replay attacks or spec violations. | Explicitly reject Logout Tokens that contain a `nonce` claim (per OIDC Back-Channel Logout spec). |
| Missing `events` claim validation | Standard ID Tokens being abused as Logout Tokens. | Ensure the Logout Token contains the `events` claim with `http://schemas.openid.net/event/backchannel-logout`. |
| Cross-JWT Confusion in JAR | An ID Token is replayed as an Authorization Request Object. | Enforce `typ: application/oauth-authz-req+jwt` on Request Objects and strictly validate the `aud` matches the AS issuer. |

## UX Pitfalls

Common user experience mistakes in this domain.

| Pitfall | User Impact | Better Approach |
|---------|-------------|-----------------|
| Relying solely on Front-Channel Logout | Users believe they are logged out but remain active in partner apps (due to blocked third-party cookies), leading to privacy breaches on shared devices. | Implement Back-Channel Logout as the primary mechanism. Provide visual confirmation of which apps were successfully logged out. |

## "Looks Done But Isn't" Checklist

Things that appear complete but are missing critical pieces.

- [ ] **Back-Channel Logout:** Often missing global logout logic — verify that if `sub` is present but `sid` is missing, ALL user sessions are invalidated.
- [ ] **Back-Channel Logout (Stateless):** Often missing revocation persistence — verify that a revoked stateless JWT is rejected on subsequent API calls until it expires.
- [ ] **JAR Decryption:** Often missing nested JWT validation — verify that JWE-only (unsigned) Request Objects are explicitly rejected.
- [ ] **OIDC Conformance:** Often missing exact Redirect URI matching — verify that `https://app.com/cb?extra=1` fails if only `https://app.com/cb` is registered.

## Recovery Strategies

When pitfalls occur despite prevention, how to recover.

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| Front-Channel Logout failure (third-party cookies) | HIGH | Notify users of potential active sessions. Accelerate Back-Channel Logout implementation. |
| Symmetric JWE `client_secret` exposure | HIGH | Force rotation of all client secrets. Deprecate symmetric `dir` encryption in favor of asymmetric. |
| Asymmetric JWE rotation lockout | MEDIUM | Temporarily restore the old private key alongside the new one until client caches expire. |

## Pitfall-to-Phase Mapping

How roadmap phases should address these pitfalls.

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| Front-Channel limitations / Back-Channel Cookie Trap | OIDC Logout Phase | End-to-end test verifying a server-to-server webhook successfully invalidates a browser session without cookies. |
| JWE Encryption-Only Trap / Key Rotation | JAR Decryption Phase | Unit tests asserting that JWE-only objects are rejected, and only Sign-then-Encrypt objects are processed. |
| Conformance Type Strictness | Core Conformance Phase | Automated run of the official OIDF Conformance Suite (e.g., via Docker) passing the basic profile. |

## Sources

- OpenID Connect Core 1.0 Specification
- OpenID Connect Back-Channel Logout 1.0
- OpenID Connect Front-Channel Logout 1.0 (and modern browser tracking prevention docs)
- RFC 9101 (JWT-Secured Authorization Request - JAR)
- OpenID Foundation Conformance Suite documentation and issue trackers
