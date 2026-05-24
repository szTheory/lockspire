# Phase 44 (S01): Ecto Replay Protection & Client Config Strategy

## Context & User Preferences
Based on the global user directives, Lockspire defaults to deep, cohesive, one-shot architectural decisions optimized for developer ergonomics, the principle of least surprise, and idiomatic Elixir/Phoenix patterns, mirroring lessons from successful ecosystem libraries.

## 1. JWT Max TTL (Bounding the Replay Table)
**Decision:** Enforce a strict **10-minute maximum lifetime** for `client_assertion` JWTs (the delta between `exp` and `iat` or `nbf`), rejecting any assertion that requests a longer life.
**Rationale:**
- **Prior Art:** Libraries like Node's `oidc-provider` strictly cap assertion lifetimes to prevent replay caches from growing indefinitely. Keycloak historically allowed long lifetimes, leading to bloated in-memory caches or massive database tables.
- **Security & FAPI 2.0:** FAPI 2.0 strongly encourages short-lived, single-use assertions. 
- **Developer Ergonomics:** Since `client_assertion` JWTs are generated programmatically by the client microseconds before the HTTP request, a 10-minute limit introduces zero friction for legitimate clients while completely neutralizing DoS vectors that attempt to fill the provider's database with 10-year `jti` records.

## 2. JTI Ecto Schema Indexing
**Decision:** The `lockspire_used_jtis` schema will use a standard Ecto auto-incrementing integer `id` as the primary key, with a `unique_index([:client_id, :jti])`.
**Rationale:**
- **Idiomatic Elixir/Ecto:** The principle of least surprise dictates using Ecto's default `id` column. Using a composite primary key (`@primary_key {:jti, :string, autogenerate: false}`) breaks conventions, complicates standard Ecto queries, and often causes friction with admin panels (like LiveDashboard or Kaffy).
- **Correct Uniqueness Scope:** RFC 7523 requires a `jti` to be unique *per issuer*. For Private Key JWT, the client is the issuer, so the `[:client_id, :jti]` index perfectly models the domain requirement.
- **Pruning Ergonomics:** The existing `Lockspire.Workers.Pruner` expects schemas with standard primary keys and an `expires_at` column. This design drops seamlessly into the existing Oban pruning infrastructure.

## 3. DCR Metadata Enforcement for `private_key_jwt`
**Decision:** In `Lockspire.Protocol.Registration`, remove the `:unsupported_in_slice` block for `jwks_uri`. Add a validation step ensuring that if `token_endpoint_auth_method` is `:private_key_jwt`, the client *must* provide exactly one of `jwks` or `jwks_uri`.
**Rationale:**
- **RFC 7591 Alignment:** Dynamic Client Registration states that providers must validate metadata coherence. A client claiming to use Private Key JWT but failing to provide public keys is in an invalid state.
- **Fail Early:** Rejecting incoherent metadata at intake (DCR) is vastly superior to accepting it and then throwing obscure 500s or validation errors later when the client attempts to use the `/token` endpoint.

## Next Steps
This strategy resolves the gray areas for Phase 44 (Slice S01). The phase is now fully defined and ready for the `plan` phase.