---
phase: 135-cohesive-internals
plan: 02
subsystem: storage
tags: [ecto, postgres, repository, oauth, audit, transactions]
requires:
  - phase: 135-01
    provides: DB-backed rollback characterization for DCR and token storage
provides:
  - Explicit repo-injected Ecto support and transaction/audit collaborators
  - Aggregate-owned client lifecycle and server-policy persistence behind the compatible Repository facade
affects: [135-03, architecture-fitness, storage]
tech-stack:
  added: []
  patterns: [explicit Ecto repo collaborator dependency, aggregate-owned locked transactional mutation]
key-files:
  created:
    - lib/lockspire/storage/ecto/repository/support.ex
    - lib/lockspire/storage/ecto/repository/transaction_store.ex
    - lib/lockspire/storage/ecto/repository/audit_store.ex
    - lib/lockspire/storage/ecto/repository/client_store.ex
    - lib/lockspire/storage/ecto/repository/server_policy_store.ex
  modified:
    - lib/lockspire/storage/ecto/repository.ex
    - test/lockspire/storage/repository_test.exs
key-decisions:
  - "Repository remains the sole configured-repo facade; collaborators receive the concrete repo explicitly."
  - "Client DCR replacement and RAT rotation retain their locked write and audit append in one collaborator transaction."
requirements-completed: [COH-01, COH-02]
coverage:
  - id: D1
    description: Explicit support preserves sensitive-query logging suppression and storage prefix options.
    requirement: COH-01
    verification:
      - kind: integration
        ref: mix test test/lockspire/storage/repository_test.exs
        status: pass
    human_judgment: false
  - id: D2
    description: Client and server-policy aggregate collaborators preserve facade behavior, locks, and audit rollback.
    requirement: COH-02
    verification:
      - kind: integration
        ref: mix test test/lockspire/storage/repository_test.exs test/lockspire/storage/repository_atomicity_test.exs test/lockspire/client_lifecycle_test.exs
        status: pass
    human_judgment: false
completed: 2026-08-27
status: complete
---

# Phase 135 Plan 02: Aggregate Storage Ownership Summary

Repository now delegates all configured Ecto access to repo-explicit collaborators, with client lifecycle and server-policy mutations organized by aggregate while maintaining the established public storage contracts.

## Accomplishments

- Centralized Ecto prefix and sensitive-query options in `Repository.Support`.
- Moved transactional and audited operations into explicit collaborators without changing `Repository` arities or results.
- Moved client CRUD, secret/status transitions, DCR replacement, RAT rotation, and server-policy persistence behind aggregate owners.
- Kept DCR/RAT lock, write, and audit append in one transaction with rollback proof intact.

## Verification

`mix test test/lockspire/storage/repository_test.exs test/lockspire/storage/repository_atomicity_test.exs test/lockspire/client_lifecycle_test.exs`

Result: 32 tests, 0 failures.

## Task Commits

1. Task 1 RED: `34e13ff` — characterize support options.
2. Task 1 GREEN: `bdaeba2` — extract Ecto support, transaction, and audit ownership.
3. Task 2 RED: `e8c1968` — characterize explicit aggregate collaborator repos.
4. Task 2 GREEN: `0fc3f55` — extract audited client and policy stores.

## Decisions Made

- `Repository` alone resolves `Config.repo!/0`; internal collaborators accept that concrete repo as their first dependency.
- `ClientLifecycle` and all external callers remain on the compatible `Repository` facade.
- Audit append remains in the same transaction as DCR replacement/RAT rotation and rolls the mutation back on failure.

## Deviations from Plan

### Auto-fixed Issues

1. [Rule 1 - Bug] Corrected repo-explicit support calls that were initially piped with the query as the first argument.
   - **Found during:** Task 2.
   - **Fix:** Used explicit `then/2` calls so `Support` always receives the configured repo first.
   - **Verification:** Focused suite passed 32/0.

2. [Rule 1 - Bug] Replaced an invalid nested capture while constructing client activation attributes.
   - **Found during:** Task 2.
   - **Fix:** Bound lifecycle attributes before invoking the update helper.
   - **Verification:** Focused suite passed 32/0.

## Issues Encountered

`mix compile --warnings-as-errors` was temporarily unavailable while concurrent Plan 06 was mid-refactor with token-exchange arity warnings. The Plan 02 source compiled successfully before that concurrent work began; its focused storage verification passed after the extraction.

## Next Phase Readiness

The explicit aggregate-delegate pattern is ready for the remaining repository extractions. No public storage API changes were introduced.

## Self-Check: PASSED

- All five collaborator modules exist.
- All four TDD task commits are present.
