---
phase: 90
plan: 2
subsystem: proof
tags: [tests, docs-contract, discovery, client-secret-jwt]
provides:
  - Semantic support-truth assertions reused by release/docs proof
  - Discovery proof that keeps `client_secret_jwt` route-local and `POST /par` excluded
  - Runtime proof that keeps the symmetric slice outside FAPI posture
affects: [release-contract, discovery, runtime]
key-files:
  created:
    - test/support/client_secret_jwt_support_truth.ex
  modified:
    - test/lockspire/release_readiness_contract_test.exs
    - test/lockspire/protocol/direct_client_auth_client_secret_jwt_test.exs
    - test/lockspire/protocol/discovery_test.exs
    - test/lockspire/web/discovery_controller_test.exs
requirements-completed: [PROOF-01]
completed: 2026-05-25
---

# Phase 90 Plan 2 Summary

**Repo-native proof now ties the new docs to the existing runtime and discovery seams using semantic anchors instead of prose snapshots.**

## Accomplishments

- Added `Lockspire.TestSupport.ClientSecretJwtSupportTruth` so release/docs tests can assert the narrow support facts once without turning tests into a second runtime truth store.
- Extended `test/lockspire/release_readiness_contract_test.exs` to pin the canonical support contract, dedicated host guide, onboarding link, and maintainer-guide deferral posture for `client_secret_jwt`.
- Tightened discovery and representative runtime tests so the shipped slice stays route-local, keeps `POST /par` excluded, and rejects the symmetric method under FAPI posture.

## Task Commits

1. **Task 90-02-01: add shared support-truth helper** - `e84b9eb`
2. **Task 90-02-02: pin release/docs support semantics** - `0f13c69`
3. **Task 90-02-03: align runtime and discovery proof** - `3fb8bb7`

## Verification

- `mix test test/lockspire/release_readiness_contract_test.exs`
- `mix test test/lockspire/protocol/direct_client_auth_client_secret_jwt_test.exs test/lockspire/protocol/discovery_test.exs test/lockspire/web/discovery_controller_test.exs`

## Deviations from Plan

- The release-contract suite was rerun after the maintainer guide landed in Plan 3 because the new semantic helper intentionally checks that downstream guide too. The final Phase 90 verification set passed without relaxing that contract.

## Next Phase Readiness

- Milestone-close docs can now cite one concrete evidence chain spanning docs, release contract, discovery metadata, runtime behavior, and full regression proof.
