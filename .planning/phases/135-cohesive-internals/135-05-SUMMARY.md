---
phase: 135-cohesive-internals
plan: 05
subsystem: storage
tags: [ecto, repository, signing-keys, atomicity]
status: complete
dependency-graph:
  requires: [135-04]
  provides: [aggregate-owned-storage-lifecycles, thin-repository-facade]
  affects: [token-exchange, signing, key-management]
tech-stack:
  added: []
  patterns: [aggregate-store-delegation, locked-key-transition, source-fitness-test]
key-files:
  created: [lib/lockspire/storage/ecto/repository/signing_key_store.ex]
  modified: [lib/lockspire/storage/ecto/repository.ex, test/lockspire/architecture_fitness_test.exs]
decisions:
  - Signing-key publish, readiness, filtering, and transitions belong to SigningKeyStore; Repository retains compatible delegates only.
metrics:
  tasks_completed: 3
  tests: 62
---

# Phase 135 Plan 05: Cohesive Ecto Storage Aggregates Summary

Token, logout, initial-access-token, and signing-key lifecycles now have focused Ecto aggregate owners while the configured Repository remains the behavior-compatible facade.

## Completed Work

- Extracted token lifecycle and atomic refresh/code handling into `Repository.TokenStore`.
- Extracted logout propagation and initial-access-token persistence into their respective aggregate stores.
- Extracted all signing-key reads, FAPI readiness checks, filters, private-material stripping, and locked publish/activate/retire transitions into `Repository.SigningKeyStore`.
- Added an architecture fitness assertion that every `KeyStore` callback remains exported by Repository, delegates to the signing-key aggregate, and does not reintroduce `SigningKeyRecord` ownership.

## Security Properties Preserved

- Signing-key activation locks the selected key and current active key, retires the prior active key, and promotes the selected key within one transaction.
- Public and publishable key listing strips encrypted private material before returning domains.
- Algorithm and FAPI security-profile filters remain applied by the aggregate owner.

## Verification

- `mix test test/lockspire/storage/repository_test.exs test/lockspire/storage/repository_atomicity_test.exs test/lockspire/architecture_fitness_test.exs` — 38 tests, 0 failures.
- `mix test test/lockspire/storage/repository_test.exs test/lockspire/storage/repository_atomicity_test.exs test/lockspire/storage/ecto/repository_logout_propagation_test.exs test/lockspire/protocol/initial_access_token_test.exs test/lockspire/protocol/refresh_exchange_test.exs` — 62 tests, 0 failures.
- `mix compile --warnings-as-errors` — passed.

## Deviations from Plan

None - plan behavior was preserved while removing now-orphaned signing-key facade helpers.

## Known Stubs

None.

## Self-Check: PASSED

- `SigningKeyStore` exists and Repository delegates all `KeyStore` callbacks.
- Task commits: `7e748500`, `2860ef3f`.
