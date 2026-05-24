<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
None - CONTEXT.md not found.

### the agent's Discretion
None - CONTEXT.md not found.

### Deferred Ideas (OUT OF SCOPE)
None - CONTEXT.md not found.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| TE-01 | Accept token exchange grant type & parse inputs | `Lockspire.Protocol.TokenExchange` pattern accepts extensible grant types. We must add `urn:ietf:params:oauth:grant-type:token-exchange` as a supported type in the endpoint and `Lockspire.Clients`. |
| TE-02 | Validate tokens and enforce strict downscoping | Tokens reside in `lockspire_tokens` and are accessible via `TokenStore.fetch_lifecycle_token/1`. Scopes must be strictly matched against the retrieved token using set operations. |
| TE-05 | Persist tokens, track lineage, cascading revocation | `lockspire_tokens` already tracks `family_id` and `parent_token_id`. Cascading revocation is achieved via `TokenStore.revoke_token_family/1`. Assigning the exchanged token the same `family_id` as `subject_token` natively satisfies this without DB migrations. |
</phase_requirements>

# Phase 48: Protocol Foundation & Storage (OAuth 2.0 Token Exchange - RFC 8693) - Research

**Researched:** 2024-05-24
**Domain:** OAuth 2.0 Token Exchange, Identity Federation, Access Delegation
**Confidence:** HIGH

## Summary

This phase implements the RFC 8693 OAuth 2.0 Token Exchange protocol foundation in the Lockspire authorization server. The objective is to allow services to exchange a valid token (the `subject_token`) for a new token, enabling token downscoping and impersonation/delegation patterns securely. 

**Primary recommendation:** Extend `Lockspire.Protocol.TokenExchange` to handle `grant_type=urn:ietf:params:oauth:grant-type:token-exchange`. Avoid adding new database columns for lineage (`grant_id`); instead, leverage the existing `family_id` and `parent_token_id` in `Lockspire.Storage.Ecto.TokenRecord` to support cascading revocation natively.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Request Parsing | API / Backend | — | `Lockspire.Protocol.TokenExchange` acts as the pipeline parsing all `grant_type` interactions on `/token`. |
| Token Lineage Tracking | Database Layer | API / Backend | `lockspire_tokens.family_id` already serves as the `grant_id` equivalent for token families; the API tier links the new token to this ID. |
| Subject Token Validation | Storage Layer | API / Backend | `TokenStore.fetch_lifecycle_token/1` performs fast hash-based lookups; the API tier verifies expiration and status. |
| Downscoping Enforcement | API / Backend | — | Scope intersections are purely business logic verified before Ecto ingestion. |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Elixir / Phoenix | Current | Core API runtime | Existing Lockspire stack. |
| Ecto | Current | Token persistence | Handles `TokenRecord` queries and transaction boundaries cleanly. |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Reusing `family_id` for lineage | Adding `grant_id` DB column | Adding `grant_id` accurately mirrors the OIDC Grant Management API semantics but introduces unnecessary schema migrations and forces a rewrite of `revoke_token_family`. |

## Architecture Patterns

### Pattern 1: Token Lineage via Family Identity
**What:** Mapping the Token Exchange "Grant Lineage" requirement to Lockspire's existing Token Family abstraction.
**When to use:** Whenever a new access or refresh token is derived directly from the authority of an existing token.
**Example:**
```elixir
# In Lockspire.Protocol.TokenExchange

# 1. Fetch subject token
{:ok, subject_token} = TokenStore.fetch_lifecycle_token(hash_token(subject_token_raw))

# 2. Inherit or establish family_id
# If subject_token was a CC grant or implicit, it might not have a family_id.
# We establish one by defaulting to its own hash.
family_id = subject_token.family_id || subject_token.token_hash

# 3. Create exchanged token
exchanged_token = %Token{
  token_hash: hash_token(new_token_raw),
  token_type: :access_token,
  family_id: family_id,
  parent_token_id: subject_token.id,
  scopes: downscoped_scopes,
  # ...
}
```

### Anti-Patterns to Avoid
- **Anti-pattern:** Passing the literal `subject_token` directly into Ecto queries without hashing it first. Lockspire stores `token_hash` (`sha256`), never plaintext.
- **Anti-pattern:** Assuming the `requested_token_type` is always provided. RFC 8693 states it is optional, and the server defaults to an access token (`urn:ietf:params:oauth:token-type:access_token`).

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Token Verification | Custom DB expiration checks | `TokenStore.fetch_active_access_token` (or lifecycle equiv) | Handles `revoked_at`, `redeemed_at`, and `expires_at` uniformly. |
| Token Hashing | `crypto.hash/2` inline | `Lockspire.Security.Policy.hash_token/1` | Enforces the system-wide constant-time canonical representation of sensitive materials. |
| Cascading Revocations | Custom recursive Ecto CTE queries | `TokenStore.revoke_token_family/1` | Already cascades revocation to all tokens sharing a `family_id`. |

## Common Pitfalls

### Pitfall 1: Bypassing Downscoping Constraints
**What goes wrong:** A client requests an exchange with a `scope` parameter larger than the `subject_token`'s bounds, and the server grants it.
**Why it happens:** Failing to perform strict intersection `MapSet.intersection(requested_scopes, subject_scopes)`.
**How to avoid:** Compare the requested `scope` string against the DB `scopes` array strictly. If requested scopes are not a strict subset, return an `invalid_scope` OAuth error.

### Pitfall 2: Client Allowlist Oversight
**What goes wrong:** A client successfully requests a token exchange but was never explicitly configured to use it.
**Why it happens:** Assuming `token-exchange` is globally permitted.
**How to avoid:** Ensure `urn:ietf:params:oauth:grant-type:token-exchange` is added to `Lockspire.Domain.Client.allowed_grant_types` validation (`Lockspire.Clients`), and enforce it during `TokenExchange.validate_grant_type`.

## Code Examples

### Scope Intersection (Downscoping)
```elixir
defp validate_downscoping(requested_scopes, subject_scopes) do
  requested_set = MapSet.new(requested_scopes)
  subject_set = MapSet.new(subject_scopes)

  if MapSet.subset?(requested_set, subject_set) do
    {:ok, requested_scopes}
  else
    {:error, :invalid_scope}
  end
end
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Multi-hop JWT forwarding | Token Exchange (RFC 8693) | Jan 2020 | Allows services to exchange tokens securely rather than passing the user's frontend token all the way to backend microservices. |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `lockspire_tokens` can utilize `family_id` as the primary lineage identifier for token exchange without requiring a new `grant_id`. | Architecture Patterns | If `revoke_token_family/1` behaves differently than assumed, cascading revocation for exchanged tokens will fail. |

## Environment Availability

Step 2.6: SKIPPED (no external dependencies identified beyond the core Elixir runtime and PostgreSQL DB).

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit |
| Config file | `test/test_helper.exs` |
| Quick run command | `mix test test/lockspire/protocol/token_exchange_test.exs` |
| Full suite command | `mix test` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| TE-01 | Rejects missing `subject_token` or `subject_token_type` | unit | `mix test test/lockspire/protocol/token_exchange_test.exs` | ❌ Wave 0 |
| TE-02 | Rejects token exchange if requested scope exceeds subject token | unit | `mix test test/lockspire/protocol/token_exchange_test.exs` | ❌ Wave 0 |
| TE-05 | Exchanged tokens inherit `family_id` from `subject_token` | integration | `mix test test/lockspire/storage/ecto/repository_test.exs` | ✅ Wave 0 |
| TE-05 | Revoking subject token family revokes the exchanged token | integration | `mix test test/lockspire/storage/ecto/repository_test.exs` | ✅ Wave 0 |

### Sampling Rate
- **Per task commit:** `mix test test/lockspire/protocol/token_exchange_test.exs`
- **Per wave merge:** `mix test`
- **Phase gate:** Full suite green before `/gsd-verify-work`

### Wave 0 Gaps
- [ ] `test/lockspire/protocol/token_exchange_test.exs` — needs dedicated RFC 8693 token exchange fixtures (TE-01, TE-02).

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes | Lockspire Protocol validation |
| V3 Session Management | yes | `family_id` lifecycle linking |
| V4 Access Control | yes | Strict scope downscoping logic |
| V5 Input Validation | yes | Ecto Changesets / Elixir Pattern Matching |
| V6 Cryptography | yes | `Lockspire.Security.Policy.hash_token/1` |

### Known Threat Patterns for OAuth Token Exchange

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Privilege Escalation | Elevation of Privilege | Enforce strict `scope` downscoping. Default to subject scopes if requested scopes are empty. |
| Replay Attacks | Spoofing | Validate `subject_token` via `fetch_active_access_token` to ensure it isn't revoked/expired. |
| Client Impersonation | Spoofing | Ensure the requesting client authenticates to the `/token` endpoint before allowing exchange. |

## Sources

### Primary (HIGH confidence)
- Lockspire Source Code (`lib/lockspire/protocol/token_exchange.ex`, `lib/lockspire/storage/ecto/repository.ex`) - Verified codebase architecture.
- IETF RFC 8693 - Official specification for OAuth 2.0 Token Exchange.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Ecto and Phoenix match current repository strictly.
- Architecture: HIGH - Reusing `family_id` accurately leverages existing domain contracts.
- Pitfalls: HIGH - Common issues map directly to OIDC/OAuth threat vectors.

**Research date:** 2024-05-24
**Valid until:** 2024-06-24
