---
phase: 43-end-to-end-fapi-validation
plan: 07
subsystem: release-readiness-contract
tags: [fapi2, docs-truth, contract-test]
dependency_graph:
  requires:
    - 43-03-oidf-conformance-task
    - 43-04-host-test-template
    - 43-05-truthful-claim-docs
  provides:
    - phase-43-truth-in-docs-contract
  affects:
    - test/lockspire/release_readiness_contract_test.exs
tech_stack:
  added: []
  patterns:
    - executable-doc-contract
    - repo-truth-assertions
key_files:
  created:
    - .planning/phases/43-end-to-end-fapi-validation/43-07-truth-in-docs-contract-SUMMARY.md
  modified:
    - test/lockspire/release_readiness_contract_test.exs
decisions:
  - "Phase 43 truth-in-docs claims remain enforced by a single release-readiness contract test that reads the public docs, pinned OIDF plan JSON, template registry, and workflow text directly from the repo."
  - "Shared planner-state files were left untouched because Plan 06 is running concurrently and this execution was explicitly limited to the contract test file plus this summary."
metrics:
  completed_at: 2026-05-03T12:53:58Z
  duration: short
---

# Phase 43 Plan 07: Truth-in-Docs Contract Summary

Phase 43's truth-in-docs gate now asserts the exact public FAPI 2.0 claim vocabulary across
`SECURITY.md`, `README.md`, and `docs/supported-surface.md`, rejects the literal word
`certified` in each, and pins the OIDF plan/variant strings, workflow task reference, and host
template registration that earlier Phase 43 plans introduced.

## Verification

- `mix test test/lockspire/release_readiness_contract_test.exs --color`
- `mix compile --warnings-as-errors`
- Acceptance grep checks for the new attributes, test name, and pinned strings all returned the expected counts.

## Commits

- `b57192f` `test(43-07): add truth-in-docs contract assertions`

## Deviations from Plan

### Auto-fixed Issues

None - the repo artifacts from Plans 03/04/05 already matched the new contract assertions.

### Execution Deviations

1. Shared planning-state updates were intentionally skipped.
   The execution instructions normally call for `STATE.md`/`ROADMAP.md` updates and a metadata
   commit, but another agent is executing Plan 06 in parallel and this task's ownership was
   limited to `test/lockspire/release_readiness_contract_test.exs` plus this summary. Updating
   shared phase state here would create unnecessary merge risk.

## TDD Gate Compliance

This plan is marked `tdd="true"`, but its only owned deliverable is a new contract test over
artifacts already implemented by dependency plans. After adding the new assertions, the test file
passed immediately because the repo already satisfied the contract. No separate `feat(...)`
implementation commit was applicable within this plan's ownership boundary.

## Known Stubs

None.

## Self-Check: PASSED

- Found summary file: `.planning/phases/43-end-to-end-fapi-validation/43-07-truth-in-docs-contract-SUMMARY.md`
- Found task commit: `b57192f`
