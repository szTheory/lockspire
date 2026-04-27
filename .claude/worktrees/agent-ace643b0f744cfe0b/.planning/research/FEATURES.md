# PAR Milestone Research: Features

**Project:** Lockspire  
**Milestone:** v1.2 PAR Foundation  
**Researched:** 2026-04-24  
**Confidence:** HIGH

## Table Stakes

### PAR Protocol Surface

- A client can `POST` a pushed authorization request to a dedicated PAR endpoint using `application/x-www-form-urlencoded`.
- The server authenticates the client using the registered direct-call auth method when applicable.
- The server returns a server-generated `request_uri` plus `expires_in` on success.
- The issued `request_uri` is bound to the client that created it.

### Authorization Flow Consumption

- `/authorize` accepts a PAR-issued `request_uri` and uses it to reconstruct the authorization request context.
- Expired, replayed, guessed, or mismatched-client `request_uri` values are rejected safely.
- PAR stays layered onto the existing authorization code + PKCE flow rather than creating a parallel grant model.

### Discovery and Support Truth

- Discovery metadata publishes `pushed_authorization_request_endpoint` only when supported.
- Support docs and preview-surface docs describe PAR precisely without implying request-object-by-value, dynamic registration, or device-flow support.

### Verification

- Tests cover successful PAR submission, authorization via `request_uri`, expiry, client binding, replay rejection, and truthful discovery metadata.

## Differentiators Worth Considering Later, Not Now

- PAR-only policy toggles at global or per-client scope
- JWT-secured authorization requests by value or signed request objects over PAR
- Client metadata for more advanced PAR/JAR interoperability profiles

## Anti-Features for v1.2

- Dynamic client registration
- Device authorization flow
- Sender-constrained token modes
- Hosted auth or externalized authorization service language
- Broad certification claims

## Primary Sources

- RFC 9126: OAuth 2.0 Pushed Authorization Requests — https://www.rfc-editor.org/rfc/rfc9126
- OpenID Connect Core 1.0 — https://openid.net/specs/openid-connect-core-1_0-18.html
- OpenID Connect Discovery 1.0 — https://openid.net/specs/openid-connect-discovery-1_0-final.html

---
*Research completed: 2026-04-24*
