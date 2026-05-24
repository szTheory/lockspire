# Phase 44 (S01): Ecto Replay Protection & Client Config Strategy - Research

**Researched:** 2024-05-19
**Domain:** Protocol Authentication, Ecto Schema Design, and DCR Metadata
**Confidence:** HIGH

## Summary

This phase implements Ecto-backed replay protection for `client_assertion` JWTs used during client authentication. By strictly bounding the `client_assertion` maximum lifetime to 10 minutes, the replay cache table can be aggressively pruned, preventing infinite growth. The phase also introduces dynamic client registration (DCR) rules enforcing `jwks`/`jwks_uri` coherence for clients using `private_key_jwt` authentication, failing early on incoherent metadata.

**Primary recommendation:** Implement the `UsedJti` domain and Ecto schema using a standard auto-incrementing ID with a composite unique index on `[:client_id, :jti]`, strictly enforce a 10-minute JWT lifespan limit in `ClientAuth`, and drop the new Ecto record into the existing Oban pruning infrastructure.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| JWT TTL Validation | API / Backend | — | Rejecting overly-long JWTs is core protocol logic implemented in the `ClientAuth` protocol utility. |
| JTI Replay Persistence | Database / Storage | API / Backend | Statefulness of used JTIs requires durable Ecto schema backed by PostgreSQL to prevent replay across distributed instances. |
| Replay Pruning | Database / Storage | API / Backend | `Lockspire.Workers.Pruner` natively handles DB cleanup via Oban background jobs relying on `expires_at`. |
| DCR Metadata Validation | API / Backend | — | Validating `jwks` and `jwks_uri` coherence is DCR intake logic managed by the `Registration` protocol utility. |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Ecto | ~> 3.10 | Database interaction | Existing persistent state layer in Lockspire; standard Elixir pattern. |
| Oban | ~> 2.15 | Background jobs | Handles `Lockspire.Workers.Pruner` executing expiration sweeps out of band. |

## Architecture Patterns

### Pattern 1: Ecto Pruning using expires_at
**What:** Leveraging `Lockspire.Workers.Pruner` for periodic deletion of expired records.
**When to use:** Whenever introducing short-lived state schemas like tokens, interaction records, or replay states.
**Example:**
```elixir
  @schemas [
    TokenRecord,
    DpopReplayRecord,
    PushedAuthorizationRequestRecord,
    InteractionRecord,
    DeviceAuthorizationRecord,
    InitialAccessTokenRecord,
    UsedJtiRecord # <-- Added for Phase 44
  ]
```

### Pattern 2: DCR Metadata Coherence Validation
**What:** Validating conditionally required attributes at intake rather than deferring to point-of-use.
**When to use:** When processing Dynamic Client Registration payloads in `Lockspire.Protocol.Registration`.
**Example:**
Reject requests with `token_endpoint_auth_method: "private_key_jwt"` if both or neither of `jwks` and `jwks_uri` are present.

### Anti-Patterns to Avoid
- **Composite Primary Keys:** Do not use `[:client_id, :jti]` as a composite Ecto primary key. It breaks conventions and administrative UI tools. Use a standard `id` field and a `unique_index`.
- **Silent Coercion:** Do not attempt to fix or default missing JWKS data. Fail early with explicit DCR validation errors.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| JTI Pruning | Custom Task | `Lockspire.Workers.Pruner` | The existing worker natively sweeps any schema with an `expires_at` column. |
| Token Expiration Validations | Custom time checks | `Joken` (or internal logic) | JWT lifetime bounding requires consistent time handling against `iat`, `nbf`, and `exp`. |

## Common Pitfalls

### Pitfall 1: Unbounded Replay Table Growth
**What goes wrong:** Database tables storing `jti` values grow to millions of rows.
**Why it happens:** Allowing JWTs with 1-year lifetimes forces the IDP to remember the `jti` for a year to prevent replay.
**How to avoid:** Enforce a hard 10-minute maximum bound on `client_assertion` lifetimes in `lib/lockspire/protocol/client_auth.ex`.

### Pitfall 2: Globally Unique JTIs
**What goes wrong:** Unique constraints conflict when different clients happen to use the same `jti` (e.g. `12345`).
**Why it happens:** Setting a unique constraint on `jti` alone.
**How to avoid:** RFC 7523 scopes `jti` uniqueness to the issuer. Since the client is the issuer in `private_key_jwt`, the uniqueness constraint must be `[:client_id, :jti]`.

## Code Examples

### DCR Metadata Coherence (Conceptual)
```elixir
  defp validate_jwks(metadata) do
    method = Map.get(metadata, "token_endpoint_auth_method")
    has_jwks = Map.has_key?(metadata, "jwks")
    has_jwks_uri = Map.has_key?(metadata, "jwks_uri")

    cond do
      method == "private_key_jwt" and has_jwks and has_jwks_uri ->
        {:error,
         %Error{
           code: :invalid_client_metadata,
           field: :jwks,
           reason: :mutually_exclusive_with_jwks_uri
         }}

      method == "private_key_jwt" and not has_jwks and not has_jwks_uri ->
        {:error,
         %Error{
           code: :invalid_client_metadata,
           field: :jwks,
           reason: :missing_keys_for_private_key_jwt
         }}

      true ->
        :ok
    end
  end
```

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit |
| Config file | `test/test_helper.exs` |
| Quick run command | `mix test {test_file}` |
| Full suite command | `mix test` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| REQ-01 | Client auth fails if `client_assertion` exceeds 10m TTL | unit | `mix test test/lockspire/protocol/client_auth_test.exs` | ✅ Wave 0 |
| REQ-02 | DCR rejects `private_key_jwt` missing both `jwks` & `jwks_uri` | unit | `mix test test/lockspire/protocol/registration_test.exs` | ✅ Wave 0 |
| REQ-03 | Pruner sweeps expired `UsedJtiRecord`s | unit | `mix test test/lockspire/workers/pruner_test.exs` | ✅ Wave 0 |

### Sampling Rate
- **Per task commit:** `mix test {modified_test_file}`
- **Per wave merge:** `mix test`
- **Phase gate:** Full suite green before `/gsd-verify-work`

### Wave 0 Gaps
- None — existing test infrastructure covers all phase requirements.

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes | JWT Signature Validation & Replay Prevention |
| V3 Session Management | no | — |
| V4 Access Control | no | — |
| V5 Input Validation | yes | DCR metadata coherence bounds validation |
| V6 Cryptography | yes | `private_key_jwt` asymmetric signature verification |

### Known Threat Patterns for Elixir / Ecto

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| JWT Replay Attack | Spoofing | Track `jti` with `[:client_id, :jti]` unique index |
| DoS via Storage Exhaustion | Denial of Service | Cap maximum JWT TTL to 10 minutes to bound replay cache |
| SQL Injection | Tampering | Ecto parameterized queries (built-in) |

## Sources

### Primary (HIGH confidence)
- Phase 44 Strategy Document (`.planning/phases/44-s01-ecto-replay-protection/44-S01-STRATEGY.md`)
- Phase 44 Patterns Document (`.planning/phases/44-s01-ecto-replay-protection/44-PATTERNS.md`)
- Project Codebase (`lib/lockspire/protocol/registration.ex`, `lib/lockspire/protocol/client_auth.ex`, `lib/lockspire/workers/pruner.ex`)

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Ecto and Oban are heavily entrenched in the workspace.
- Architecture: HIGH - Dictated directly by Lockspire phase strategy docs.
- Pitfalls: HIGH - Documented clearly in FAPI 2.0 and strategy context.

**Research date:** 2024-05-19
**Valid until:** 2024-06-19
