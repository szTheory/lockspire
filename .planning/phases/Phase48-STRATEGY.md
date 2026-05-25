# Phase 48: Protocol Foundation & Storage (RFC 8693 Token Exchange) - Strategy

## Executive Summary
This document outlines the architectural strategy for implementing Token Exchange (RFC 8693) in the Lockspire project. The recommendations focus on developer ergonomics, principle of least surprise, idiomatic Elixir/Ecto architecture, and highly secure token management.

---

## 1. Module Architecture: Dedicated Orchestrator

**Approach:**
- Do **not** overload the existing `Lockspire.Protocol.TokenExchange` module.
- Create a new, dedicated orchestrator: `Lockspire.Protocol.RFC8693Exchange` (or similar).
- Add a routing clause in `Lockspire.Protocol.TokenExchange.exchange/1` to delegate `"urn:ietf:params:oauth:grant-type:token-exchange"` requests to the new orchestrator.

**Why:**
RFC 8693 requires entirely new validation semantics, such as parsing URI token types (e.g., `urn:ietf:params:oauth:token-type:access_token`), validating the target `audience`, and verifying `subject_token`/`actor_token` pairings. Treating it as a standalone flow preserves module cohesion and keeps the codebase understandable (great DX).

---

## 2. Lineage Tracking: The `grant_id` Strategy

**Approach:**
- Introduce a new column `grant_id` (a UUID string) to the `Lockspire.Domain.Token` (and `tokens` DB schema).
- When any root token (e.g., from an authorization code or device code) is issued, generate a unique `grant_id` and assign it to the token.
- During a Token Exchange (RFC 8693), the newly minted token **inherits the exact `grant_id`** of the `subject_token`.
- Retain the `parent_token_id` to allow building a visual or logical tree for audits, but strictly use `grant_id` for revocation.

**Why:**
To support cascading revocation (if a user revokes an app's access, all derived tokens must die instantly), a shared `grant_id` allows Ecto to perform a highly efficient `Repo.update_all(where: [grant_id: id], set: [revoked_at: now])` query in `O(1)`. Relying on `parent_token_id` alone would require complex, non-idiomatic recursive queries or n+1 loops. This approach mirrors best-in-class systems like Auth0 and Keycloak.

---

## 3. Downscoping Logic: Fail on Escalation

**Approach:**
- **Default Fallback:** If the `scope` parameter is omitted in the token exchange request, the new token inherits 100% of the scopes present in the `subject_token`.
- **Strict Validation:** If the `scope` parameter is provided, intersect the requested scopes against the `subject_token`'s scopes.
- **Explicit Failure:** If the client requests any scope that is **not** present in the `subject_token`, abort the request and return an HTTP 400 Bad Request with an `invalid_scope` error.

**Why:**
Silent intersection (simply dropping unapproved scopes) violates the principle of least surprise. If a developer explicitly requests `scope=admin user:read` and only gets `user:read`, their application might fail downstream in a confusing way. Explicit failure provides excellent developer ergonomics by immediately pointing out the privilege escalation attempt, adhering strictly to RFC 8693 Section 2.1.
