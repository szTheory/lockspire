# Stack Research

**Milestone:** v1.45 DCR Lifetime Enforcement
**Researched:** 2026-10-20
**Confidence:** HIGH for existing seams; MEDIUM for proposed implementation until Phase 162 resolves policy.
**Method:** Inline research; no delegated or independent researcher claim. Existing Phase 153 source audit reused, with bounded current-source checks.

## Recommended Stack

Use the repository's existing Elixir/OTP, Ecto/PostgreSQL persistence, Phoenix integration, ExUnit and clean-room host infrastructure. No new runtime dependency or version upgrade is indicated by the lifetime work. This is a compatibility recommendation, not a claim that current pins are the latest upstream versions.

| Existing component | New responsibility | Boundary |
|---|---|---|
| DcrPolicy.Resolved | Exact effective duration rules | Host policy input stays host-owned |
| Domain.Client and Ecto.ClientRecord | Represent selected lifecycle data | Data model decided before migration |
| ClientStore behavior and Ecto implementation | Persist lifecycle and atomic rotations | Custom stores need an explicit contract |
| Protocol modules | Request-time eligibility checks | No dependency on Phoenix UI or worker timing |
| Install.Migrations and existing SQL migrations | Fresh and upgrading host schema | Never rewrite shipped migrations |
| ExUnit, PostgreSQL and clean-room hosts | Deterministic expiry and compatibility proof | Avoid sleep-based boundary tests |

## Alternatives Considered

A pure timestamp check is simple and works without jobs; a persisted inactive transition supports operator reporting but requires ordering and recovery decisions. A hybrid can provide both, at greater complexity. Phase 162 must choose; a pruner alone cannot enforce exact deadlines between runs. No standalone service, external TTL database, KMS or new scheduler is needed for this scope.

## Version Compatibility

Test against the existing supported host and database matrix. Specify deployment ordering for schema, code and policy activation, including mixed-version nodes and custom storage. Avoid adding a callback or required field without a documented host transition.

## Sources

- [Existing audit](../../milestones/v1.42-phases/153-configure-support-page-refinement/153-LIFETIME-TRUTH.md).
- Current repository: lib/lockspire/storage/client_store.ex, storage/ecto/repository/client_store.ex, storage/ecto/client_record.ex and install/migrations.ex.
