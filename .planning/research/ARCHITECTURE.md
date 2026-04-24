# PAR Milestone Research: Architecture

**Project:** Lockspire  
**Milestone:** v1.2 PAR Foundation  
**Researched:** 2026-04-24  
**Confidence:** HIGH

## Recommended Integration Shape

### 1. PAR Intake Path

- Add a dedicated web endpoint for PAR under the existing Lockspire mount path.
- Reuse existing client lookup and direct-call authentication rules rather than creating a PAR-only auth subsystem.
- Validate pushed request parameters against the same core authorization-policy rules that later govern `/authorize`.

### 2. Durable Request Reference

- Persist the normalized pushed request payload behind a server-issued `request_uri`.
- Store enough state to enforce:
  - expiry
  - single use
  - client binding
  - redirect and PKCE invariants
- Keep the format of `request_uri` opaque to callers and generated from a cryptographically strong random value.

### 3. Authorization Consumption Path

- Teach the authorization-request pipeline to accept `request_uri` when it originated from the PAR endpoint.
- Merge or replace raw query parameters carefully so Lockspire does not accidentally accept conflicting request data outside the PAR reference.
- Keep the host seam unchanged: host apps still own accounts, login UX, claims, branding, and policy.

### 4. Truthful Surface Updates

- Extend discovery metadata generation with `pushed_authorization_request_endpoint`.
- Update docs and support posture tests together so the repo never claims more than the implemented PAR slice.

### 5. Release Hygiene Sidecar

- Keep release-runtime cleanup in a separate roadmap phase or requirement bucket so it cannot distort the PAR architecture.
- Accept either an action upgrade or a different checked-in release automation adjustment, but require the trusted release path to stay reviewable and warning-free.

## Build Order

1. PAR intake endpoint and durable model
2. Authorization consumption via `request_uri`
3. Discovery/docs/support posture updates
4. Verification sweep and release-runtime hygiene

## Primary Sources

- RFC 9126: OAuth 2.0 Pushed Authorization Requests — https://www.rfc-editor.org/rfc/rfc9126
- RFC 8414: OAuth 2.0 Authorization Server Metadata — https://www.rfc-editor.org/rfc/rfc8414.html

---
*Research completed: 2026-04-24*
