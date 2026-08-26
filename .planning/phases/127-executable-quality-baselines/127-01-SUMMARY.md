---
phase: 127-executable-quality-baselines
plan: 01
subsystem: testing
tags: [credo, static-analysis, ci]
requires:
  - phase: 126-trusted-release-path
    provides: required CI quality gates
provides:
  - Credo parser-timeout failures that block qa and CI
affects: [ci, static-analysis]
tech-stack:
  added: []
  patterns: [repo-owned fail-closed static-analysis wrappers]
key-files:
  created: [scripts/ci/run_credo.sh, test/lockspire/static_analysis_baseline_contract_test.exs]
  modified: [.credo.exs, mix.exs]
key-decisions:
  - "Use a 30-second bounded Credo parse budget and fail on its stable timeout warning."
requirements-completed: [STATIC-01]
coverage:
  - id: D1
    description: "Credo analyzes all configured lib/ and test/ sources without silently accepting parser timeouts."
    requirement: STATIC-01
    verification:
      - kind: unit
        ref: test/lockspire/static_analysis_baseline_contract_test.exs
        status: pass
      - kind: other
        ref: bash scripts/ci/run_credo.sh
        status: pass
    human_judgment: false
duration: 8min
completed: 2026-08-26
status: complete
---

# Phase 127 Plan 01: Fail-Closed Credo Summary

**The qa gate now gives every intended source 30 seconds to parse and fails if Credo reports any skipped source.**

## Accomplishments

- Added a bounded parse budget without narrowing Credo's `lib/` or `test/` source set.
- Routed `mix qa` through a wrapper that preserves Credo output and native failure status while turning parser-timeout warnings into failure.
- Added executable source contracts for the config, qa alias, and wrapper behavior.

## Task Commits

1. **Task 1: Carry one fail-closed Credo run from mix qa through all intended sources** - `e4a4c6e` (chore)

## Deviations from Plan

None - plan executed exactly as written.

## Verification

- `mix test test/lockspire/static_analysis_baseline_contract_test.exs` — passed.
- `bash scripts/ci/run_credo.sh` — passed; 407 source files analyzed with no issues or timeout warnings.
- `mix qa` — passed after the final formatter and static-analysis checks.

## Next Phase Readiness

Static-analysis source coverage is now part of the ordinary qa path used by Fast Checks.
