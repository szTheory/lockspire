---
phase: 66
plan: 66-01
subsystem: conformance-truth
tags:
  - docs
  - contract-test
  - conformance
requirements:
  - CONF-01
  - CONF-02
objective: Retire current-proof conformance overclaims and lock the narrower repo-native truth hierarchy in executable tests and docs.
files:
  modified:
    - test/lockspire/release_readiness_contract_test.exs
    - docs/supported-surface.md
    - docs/maintainer-conformance.md
verification:
  - mix test test/lockspire/release_readiness_contract_test.exs
completed_at: 2026-05-07
---

# Phase 66 Plan 66-01 Summary

The canonical conformance story now stays anchored to repo-native proof for the embedded Phoenix path. `docs/supported-surface.md` names the strictness E2E and release-readiness contract test as the current proof, while `docs/maintainer-conformance.md` explicitly defers public truth to the supported-surface contract and treats external OIDF/FAPI runs as optional maintainer corroboration only.

## Changes

- Strengthened `test/lockspire/release_readiness_contract_test.exs` so the release-readiness fence rejects the old public-proof hierarchy. The test now requires repo-native strictness proof references in `docs/supported-surface.md`, rejects public reliance on `docs/maintainer-conformance.md`, `mix conformance.phase37`, and `.artifacts/conformance/phase37`, and requires the maintainer guide to describe external-suite work as optional, supplemental, not part of the public support contract, not a required release gate, and not milestone-closing proof.
- Narrowed `docs/supported-surface.md` to remove the retired external-lane references from the public proof chain and convert external OIDF/FAPI runs into an explicit non-claim for the current embedded-library support contract.
- Reworked `docs/maintainer-conformance.md` into a subordinate maintainer runbook that starts with repo-native proof and frames external-suite execution as optional supplemental corroboration.

## Verification

- Ran `mix test test/lockspire/release_readiness_contract_test.exs`
- Result: 18 tests, 0 failures

## Deviations from Plan

None. The plan was executed within the requested file scope.

## Known Stubs

None in the files modified by this plan.
