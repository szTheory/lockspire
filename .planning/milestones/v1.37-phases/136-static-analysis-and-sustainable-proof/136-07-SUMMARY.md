---
phase: 136-static-analysis-and-sustainable-proof
plan: "07"
subsystem: storage-and-lifecycle
tags: [dialyzer, ecto, client-lifecycle, dcr]
requires: [136-01]
provides: [truthful-client-lifecycle-contracts, warning-free-storage-lifecycle-seam]
affects: [136-08, 136-09, 136-11]
tech-stack:
  added: []
  patterns: [complete-domain-value-delegation, named-result-unions]
key-files:
  modified:
    - lib/lockspire/storage/ecto/repository.ex
    - lib/lockspire/storage/ecto/repository/token_store.ex
    - lib/lockspire/client_lifecycle.ex
    - lib/lockspire/protocol/registration_management.ex
decisions:
  - Repository delegates retain the complete persisted Client value instead of reconstructing a partial struct.
  - Client lifecycle and DCR update outcomes use named, exact result unions.
metrics:
  tasks_completed: 2
  tests: 64
  dialyzer_warnings_removed: 30
status: complete
---

# Phase 136 Plan 07: Lifecycle and Storage Dialyzer Summary

Repository client mutations now pass the complete typed domain client through the facade, eliminating impossible partial-client calls while preserving transactional Ecto behavior and DCR lifecycle contracts.

## Accomplishments

- Kept the original persisted client when delegating update, activation, secret rotation, DCR replacement, and RAT rotation to `ClientStore`.
- Removed the unreachable `when false` refresh-token clause.
- Named the shared lifecycle result union and narrowed DCR management updates to their actual success and public error shapes.
- Retained audit transactions, secret/RAT handling, and telemetry behavior unchanged.

## Verification

- `mix test test/lockspire/client_lifecycle_test.exs test/lockspire/protocol/registration_management_test.exs test/lockspire/storage/repository_test.exs test/lockspire/storage/repository_atomicity_test.exs` — 64 tests, 0 failures.
- `mix qa.dialyzer` — 36 project warnings remain in later-plan owners; no warning references Repository, ClientStore, TokenStore, ClientLifecycle, or RegistrationManagement.

## Task Commits

1. `751a1e80` — preserve complete client values in repository delegates and remove the impossible token guard.
2. `c80536d2` — name lifecycle and registration-management result contracts.

## Deviations from Plan

None - the existing behavior tests already characterized every requested operator and DCR mutation; implementation repaired the type contract without needing behavior changes.

## Known Stubs

None.

## Self-Check: PASSED

- Both task commits are present in git history.
- All four owning source modules exist and have no Dialyzer diagnostic in the final capture.
