# Phase 44 (S01): Ecto Replay Protection & Client Config Strategy

## Wave 1

- **[44-01-PLAN.md](./44-01-PLAN.md)**: Database Migration, Ecto Schema, Domain Struct, Storage behavior, and Pruner integration for tracking used JTIs.
- **[44-02-PLAN.md](./44-02-PLAN.md)**: Dynamic Client Registration (DCR) validation for `jwks` and `jwks_uri` coherence.

## Wave 2

- **[44-03-PLAN.md](./44-03-PLAN.md)**: Integration into `Lockspire.Protocol.ClientAuth` to enforce strict 10-minute maximum lifetime for `client_assertion` JWTs and replay logic. (Depends on 44-01-PLAN.md).
