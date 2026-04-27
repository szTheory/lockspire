# Milestone Research Summary: v1.2 PAR Foundation

**Project:** Lockspire  
**Researched:** 2026-04-24  
**Confidence:** HIGH

## Executive Summary

The recommended v1.2 milestone stays narrow: add pushed authorization requests as an extension of the existing authorization code + PKCE flow, make discovery and support posture truthful about exactly that slice, and close the lingering release-runtime warning so the preview release path stays defensible. PAR fits Lockspire well because it strengthens the request path without forcing the project into hosted-auth shape, dynamic registration, or a broader CIAM surface.

The core architectural consequence is that PAR cannot be implemented as a stateless edge helper. Lockspire needs a durable, client-bound, expiring, single-use `request_uri` lifecycle that feeds back into `/authorize` safely. The repo already exposes the right seams for this: discovery currently omits PAR metadata, the authorization validator currently rejects `request_uri`, and the release workflow still carries the runtime-warning constraint as explicit tech debt.

## Key Findings

### Stack additions

- No new platform stack is required.
- Add durable storage for pushed authorization requests.
- Reuse existing client-auth and authorization validation paths instead of inventing a PAR-specific policy layer.
- Treat release-runtime cleanup as an outcome requirement, because the current pin already claims `v4.4.0` and may still need more than a superficial version change.

### Feature table stakes

- Client can push an authorization request to a PAR endpoint and receive `request_uri` plus `expires_in`.
- `request_uri` is bound to the issuing client, expires quickly, and is rejected after use or misuse.
- `/authorize` consumes a PAR-issued `request_uri` as part of the existing code + PKCE path.
- Discovery metadata and docs advertise PAR support truthfully and no broader unsupported features.
- Tests cover success, expiry, replay rejection, client binding, and discovery truth.

### Watch out for

- Do not let `/authorize` accept conflicting raw parameters alongside a PAR request reference.
- Do not blur PAR into JAR-by-value or generic external `request_uri` support.
- Do not keep PAR state in memory.
- Do not leave the release-runtime warning as silent background debt while adding new protocol breadth.

## Recommended Requirement Buckets

1. PAR intake and request reference issuance
2. Authorization consumption and lifecycle enforcement
3. Discovery/docs/support posture truth
4. Verification and release-runtime hygiene

## Ready for Requirements

Yes. The milestone is narrow enough and the integration points are concrete enough to define scoped requirements and phases without more discovery.

## Primary Sources

- RFC 9126: OAuth 2.0 Pushed Authorization Requests — https://www.rfc-editor.org/rfc/rfc9126
- RFC 8414: OAuth 2.0 Authorization Server Metadata — https://www.rfc-editor.org/rfc/rfc8414.html
- OpenID Connect Core 1.0 — https://openid.net/specs/openid-connect-core-1_0-18.html
- OpenID Connect Discovery 1.0 — https://openid.net/specs/openid-connect-discovery-1_0-final.html
- `googleapis/release-please-action` repository — https://github.com/googleapis/release-please-action
- GitHub changelog: Node 20 deprecation on Actions runners — https://github.blog/changelog/2025-09-19-deprecation-of-node-20-on-github-actions-runners/

---
*Research completed: 2026-04-24*
*Ready for roadmap: yes*
