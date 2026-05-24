# Phase 48: Protocol Foundation & Storage (RFC 8693 Token Exchange) - Research

## Overview
This phase implements the foundation for RFC 8693 Token Exchange, specifically addressing three major architectural gray areas:
1. Module Architecture for Parsing & Validation
2. Lineage Tracking in Ecto (Cascading Revocation)
3. Downscoping Logic

We researched idiomatic Elixir/Ecto patterns, lessons learned from identity providers like Keycloak, Auth0, and Ory Hydra, and optimized for developer ergonomics (DX) and the principle of least surprise.

---

## Gray Area 1: Module Architecture for Parsing & Validation

### Options
1. **Extend Existing `Lockspire.Protocol.TokenExchange`**
   - *Pros:* Centralizes all `/token` endpoint grant type logic in one file. Follows the existing pattern where `authorization_code`, `refresh_token`, and `device_code` are matched in a single `exchange/1` function.
   - *Cons:* `TokenExchange` is already ~1000 lines long. RFC 8693 introduces vastly different semantics (`subject_token`, `actor_token`, URI parsing, token type validation) that do not share the lifecycle of standard grants. This risks turning `TokenExchange` into a "god module".

2. **Dedicated Orchestrator: `Lockspire.Protocol.RFC8693Exchange`**
   - *Pros:* High cohesion, low coupling. Isolates RFC 8693 specific URI parsing (`urn:ietf:params:oauth:token-type:access_token`), specific validations, and token interception logic. We can simply delegate from `Lockspire.Protocol.TokenExchange.exchange/1` to this dedicated orchestrator.
   - *Cons:* Slightly indirectional.

### Lessons Learned & Recommendations
- **Auth0 / Keycloak:** They treat token exchange as a distinct pipeline/flow due to its complexity (impersonation vs. delegation).
- **Idiomatic Elixir:** "Small, focused modules". Pluggable/delegation architectures are preferred over bloated contexts.
- **Recommendation:** **Dedicated Orchestrator**. Add a match in `Lockspire.Protocol.TokenExchange.exchange/1` for `"urn:ietf:params:oauth:grant-type:token-exchange"` that strictly delegates to a new `Lockspire.Protocol.TokenExchange.RFC8693` (or `RFC8693Exchange`) module. Keep URI definitions as module attributes (e.g., `@access_token_type "urn:ietf:params:oauth:token-type:access_token"`).

---

## Gray Area 2: Lineage Tracking in Ecto (Cascading Revocation)

### Options
1. **`parent_token_id` (Foreign Key / Adjacency List)**
   - *Pros:* We already have `parent_token_id: integer() | nil` in `Lockspire.Domain.Token`. Accurately represents the tree structure of token derivation.
   - *Cons:* Cascading revocation requires recursive CTEs (Common Table Expressions) in PostgreSQL, or multiple sequential queries in Elixir. This is complex and performance-intensive for deep delegation chains.

2. **`grant_id` (Shared UUID for the Delegation Chain)**
   - *Pros:* All tokens derived from an initial grant share the same string UUID. Cascading revocation becomes an `O(1)` database operation: `UPDATE tokens SET revoked_at = NOW() WHERE grant_id = $1`.
   - *Cons:* Requires adding a new column to the `tokens` schema and migrating existing rows.

3. **Hybrid: `parent_token_id` + `family_id` (or `grant_id`)**
   - *Pros:* We already have `family_id` (currently used for refresh token rotation families).

### Lessons Learned & Recommendations
- **Keycloak:** Uses a session-bound `root_session_id`. When the root session is terminated, all associated tokens are revoked instantly.
- **Auth0:** Employs a `grant_id` concept. A grant represents the overarching authorization, and all tokens (access, refresh, exchanged) are tied to it.
- **Idiomatic Ecto:** Modifying multiple rows by a common index (`grant_id`) via `Repo.update_all/3` is vastly preferred over recursive queries or multiple loops for both performance and DX.
- **Recommendation:** **Introduce `grant_id` (UUID)** to `Lockspire.Domain.Token`. When a token is exchanged, the new token inherits the `grant_id` of the `subject_token`. Revocation logic can then perform a single `Repo.update_all` to cascade revocation. Maintain `parent_token_id` strictly for audit/lineage visualization, but use `grant_id` for structural cascading revocation.

---

## Gray Area 3: Downscoping Logic

### Options
1. **Strict Intersect (Requested ∩ Subject)**
   - If `requested_scopes` are provided, the resulting scopes are exactly the intersection of `requested_scopes` and `subject_token.scopes`. If requested scopes are omitted, default to the `subject_token.scopes`.
   - *Pros:* Highly secure. Principle of least privilege.
   - *Cons:* If a client requests a scope not present in the subject token, should it fail or just omit it?

2. **Fail on Escalation**
   - If `requested_scopes` contains any scope NOT present in `subject_token.scopes`, reject the request with `invalid_scope`.
   - *Pros:* Explicit failure prevents silent privilege reduction that the client might not expect, aiding debugging (great DX).

### Lessons Learned & Recommendations
- **RFC 8693 Section 2.1:** States that the requested scope MUST NOT exceed the scopes authorized by the subject token.
- **Ory Hydra & Auth0:** Both implement strict validation—requesting an un-granted scope yields an `invalid_scope` error rather than a silent intersection. This follows the principle of least surprise for API consumers.
- **Recommendation:** **Fail on Escalation with Fallback**. If `scope` is omitted in the request, inherit 100% of the `subject_token` scopes. If `scope` is provided, calculate the difference. If the client requests any scope not in the subject token, return a `400 Bad Request` with `invalid_scope`. Otherwise, grant the exact requested scopes. This provides the best DX (explicit errors) and adheres strictly to security best practices.
