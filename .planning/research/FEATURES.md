# Feature Landscape

**Domain:** Embedded OAuth/OIDC Authorization Server (Lockspire)
**Researched:** 2026-04-28
**Overall confidence:** HIGH

## Table Stakes

Features users expect. Missing = product feels incomplete for an OIDC-certified provider.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| **OIDC Core Conformance (Strict)** | Standard OIDC client libraries (like `next-auth`, `passport-openidconnect`) expect exact, spec-compliant behaviors for parameters like `nonce`, `max_age`, `auth_time`, and `prompt=none`. Failure to strictly conform causes integrations to mysteriously fail. | High | "Death by a thousand cuts." Modifies the existing Authorization endpoint to strictly enforce edge cases, return exact error codes (e.g., `login_required`, `interaction_required`), and validate claims requests. Depends on existing Auth Code flow. |
| **Back-Channel Logout** | Reliable Single Sign-Out (SLO) is mandatory for enterprise/B2B ecosystems. With the death of third-party cookies (Safari ITP, Chrome Privacy Sandbox), front-channel browser-based logouts are deeply fragile. A direct server-to-server webhook (JWT) is the only reliable way to terminate RP sessions. | Medium | Requires the OP to track which clients the user has authorized in the current session. Needs async/background job processing to POST the `logout_token` JWT to RPs without blocking the user's logout UI. |

## Differentiators

Features that set product apart. Not expected for basic auth, but highly valued for enterprise/fintech.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| **JAR Decryption (JWE)** | Required for FAPI (Financial-grade API) profiles and high-security deployments (healthcare, finance). It encrypts the authorization request, protecting sensitive PII (like `login_hint`, `id_token_hint`, or requested claims) from being intercepted in the browser URL or logs. | High | Depends on existing PAR and JAR (JWS) features. The AS must now maintain an RSA/EC encryption keypair in its JWKS, perform JWE decryption (CEK unboxing), and gracefully handle crypto failures before validating the inner JWS. |
| **Front-Channel Logout** | Supports SPAs and legacy Relying Parties that do not have a backend to receive a Back-Channel webhook. The OP renders an HTML page with hidden `<iframe>` tags pointing to the RPs' logout URIs, leveraging the browser to clear RP session cookies. | Low/Medium | Easy to implement (just rendering iframes), but operationally fragile. Highly dependent on browser cookie policies (SameSite, third-party blocking). Host app must render this UI. |

## Anti-Features

Features to explicitly NOT build.

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| **Implicit Flow / Form Post** | `response_type=token` and `response_type=id_token` are deprecated by OAuth 2.1 and OIDC Security BCPs due to token leakage in the browser URI fragment. | Strictly enforce Authorization Code flow with PKCE for all clients, including SPAs. |
| **Stateful OP Sessions in Lockspire Core** | Lockspire should not own or read the host application's user session cookie directly. The host app owns authentication. | The host app must notify Lockspire when a logout occurs, passing the necessary context so Lockspire can trigger Back/Front-Channel logouts for the tracked clients. |
| **Custom Logout Protocols** | Inventing a proprietary webhook format for logout creates integration headaches for Relying Parties. | Stick strictly to the OIDC Back-Channel Logout specification (JWT `logout_token` with `events` claim). |

## Feature Dependencies

```text
OIDC Core Conformance → Auth Code Flow (Existing)
OIDC Core Conformance → PAR (Existing)
JAR Decryption (JWE) → PAR (Existing)
JAR Decryption (JWE) → JAR Signatures / JWS (Existing)
JAR Decryption (JWE) → AS JWKS Encryption Keys (New Key Management)
Back-Channel Logout → User-Client Session Tracking (New Storage/Tracking)
Front-Channel Logout → User-Client Session Tracking (New Storage/Tracking)
```

## MVP Recommendation

Prioritize:
1. **OIDC Core Conformance**: Getting standard parameters (`prompt`, `max_age`, `nonce`) right is critical for basic interoperability with off-the-shelf client libraries. This is the foundation of trust.
2. **Back-Channel Logout**: Fixes the broken Single Sign-Out experience for B2B apps using modern browsers.

Defer: 
- **JAR Decryption**: Defer until FAPI or strict privacy compliance is demanded. It adds heavy crypto complexity (JWE) that most standard OAuth clients do not support or need.
- **Front-Channel Logout**: Defer or mark as "best effort". It is fundamentally fragile in the modern browser ecosystem (third-party cookie blocking) and creates support burdens when iframes fail to clear RP cookies silently.

## Sources

- [OpenID Connect Core 1.0 specification (Standard Knowledge, HIGH confidence)]
- [OpenID Connect Back-Channel Logout 1.0 (Standard Knowledge, HIGH confidence)]
- [OpenID Connect Front-Channel Logout 1.0 (Standard Knowledge, HIGH confidence)]
- [RFC 9101: OAuth 2.0 JWT Secured Authorization Request (Standard Knowledge, HIGH confidence)]
- [OAuth 2.1 Security BCP / FAPI profiles (Standard Knowledge, HIGH confidence)]
