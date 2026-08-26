---
phase: 127-executable-quality-baselines
plan: 03
subsystem: testing
tags: [exunit, coverage, ci]
requires:
  - phase: 127-executable-quality-baselines
    provides: exact compatibility and CI baseline contracts
provides:
  - built-in ExUnit coverage threshold of 73 percent
  - coverage execution in required Fast Checks
affects: [ci, testing]
tech-stack:
  added: []
  patterns: [fixed built-in coverage floor from measured baseline]
key-files:
  created: [test/lockspire/coverage_baseline_contract_test.exs]
  modified: [mix.exs, .github/workflows/ci.yml]
key-decisions:
  - "Use Mix built-in coverage with a fixed rounded-down 73% floor from the 73.11% measurement."
requirements-completed: [COVER-01]
coverage:
  - id: D1
    description: "Fast Checks runs the existing non-integration suite once under native ExUnit coverage and enforces 73%."
    requirement: COVER-01
    verification:
      - kind: unit
        ref: test/lockspire/coverage_baseline_contract_test.exs
        status: pass
      - kind: other
        ref: MIX_ENV=test mix test.coverage
        status: pass
    human_judgment: false
duration: 12min
completed: 2026-08-26
status: complete
---

# Phase 127 Plan 03: Coverage Ratchet Summary

**Fast Checks now runs its existing non-integration test pass under built-in ExUnit coverage and rejects totals below the measured 73% floor.**

## Accomplishments

- Configured native Mix coverage with no external service, package, or production-module exclusions.
- Added `test.coverage` with the same test database setup and default integration exclusion as `test.fast`.
- Replaced Fast Checks' ordinary fast test invocation rather than adding a duplicate pass, and fenced the behavior with source contracts.

## Task Commits

1. **Task 1: Carry the measured built-in coverage floor through the existing Fast Checks suite** - `8c70a52` (test)

## Deviations from Plan

None - plan executed exactly as written.

## Verification

- 54 focused coverage, release, compatibility, supply-chain, and CI contracts passed.
- `MIX_ENV=test mix test.coverage` — passed with **73.11%** total coverage.
- `bash scripts/ci/lint_workflows.sh` — passed.

## Next Phase Readiness

Phase 127 requirements are implemented and guarded by fresh automated proof.
