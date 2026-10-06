---
phase: 138-baseline-inventory-evidence-taxonomy
plan: "07"
subsystem: release-maintenance
tags: [github, graphql, fail-closed, evidence-ledger, validation]
requires:
  - phase: 138-06
    provides: Safe-field GitHub pagination, sanitization, collector lifecycle, and canonical receipt conventions.
provides:
  - Transaction-like PR-plus-issue collection that computes aggregate publication authority only after both namespaces finish.
  - Pre-render validation for every normalized GitHub row with namespace-specific failure receipts.
  - Hermetic API, pagination, malformed-row, and hostile-field combination fixtures.
affects: [phase-139, phase-140, phase-141, repository-triage]
tech-stack:
  added: []
  patterns: [aggregate disposition gate, namespace result buffering, pre-render row validation, fail-closed sibling observations]
key-files:
  created: [".planning/phases/138-baseline-inventory-evidence-taxonomy/138-07-SUMMARY.md"]
  modified:
    - scripts/maintainer/baseline_inventory.sh
    - test/lockspire/release/repository_hygiene_contract_test.exs
    - test/support/lockspire/release_proof/package_assertions.ex
key-decisions:
  - "Only a complete and row-valid PR-plus-issue aggregate grants affirmative disposition authority."
  - "Usable rows from a complete sibling namespace remain visible as defer-only evidence when the aggregate is partial."
  - "Renderers consume validated normalized JSON rows and never mutate aggregate collection status."
requirements-completed: [TRIAGE-01, TRIAGE-02]
coverage:
  - id: D1
    description: PR success followed by issue API or pagination failure suppresses affirmative proposals while retaining safe observations.
    requirement: TRIAGE-01
    verification:
      - kind: integration
        ref: mix test test/lockspire/release/repository_hygiene_contract_test.exs
        status: pass
    human_judgment: false
  - id: D2
    description: Malformed PR and issue rows fail before publication with namespace-specific receipts while hostile valid fields remain sanitized.
    requirement: TRIAGE-02
    verification:
      - kind: integration
        ref: mix test test/lockspire/release/repository_hygiene_contract_test.exs
        status: pass
    human_judgment: false
duration: 9min
completed: 2026-08-28
status: complete
---

# Phase 138 Plan 07: GitHub Aggregate Fail-Closed Publication Summary

**Buffered PR-plus-issue collection with aggregate disposition authority, namespace-specific row validation, and defer-only partial evidence.**

## Performance

- **Duration:** 9 min
- **Completed:** 2026-08-28T18:39:55Z
- **Tasks:** 2/2
- **Files modified:** 3

## Accomplishments

- Refactored GitHub collection so pull requests and issues produce independent buffered results before any namespace heading, row, successful-zero message, or disposition is rendered.
- Made aggregate completeness the sole authority for `merge-ready`, `retain`, or other affirmative proposals; partial aggregates retain usable sibling observations only as `defer` with an explicit aggregate-incomplete rationale.
- Added strict pre-render validation for required IDs, numbers, URLs, state, types, and PR head/base SHAs, with stable `pull_requests_row_validation_failed` and `issues_row_validation_failed` receipts.
- Replaced delimiter-sensitive row parsing with compact normalized JSON iteration and extended cleanup so raw collector-owned GitHub buffers are removed on normal and trapped exits.

## Task Commits

1. **Task 1: Prove PR-success and issue-failure publication fails closed end to end** — `3f8cf473` (RED), `a25e61cf` (GREEN)
2. **Task 2: Validate every PR and issue row before aggregate disposition rendering** — `82721527` (RED), `511113b8` (GREEN)

## Files Created/Modified

- `scripts/maintainer/baseline_inventory.sh` — buffers both GitHub namespaces, validates normalized rows, gates aggregate disposition authority, renders safe deferred observations, and cleans private buffers.
- `test/lockspire/release/repository_hygiene_contract_test.exs` — adds the focused aggregate fail-closed contract entry point.
- `test/support/lockspire/release_proof/package_assertions.ex` — adds PR-success/issue-failure, pagination-failure, malformed-row combination, and hostile-valid fixtures.

## Decisions Made

- Namespace query success is insufficient for publication authority; both namespaces must also pass terminal pagination and row validation.
- A malformed namespace publishes no malformed row, while a valid sibling namespace may publish observations only with `defer` and no action authority.
- GitHub row state is collected explicitly, and PR identity includes validated full head/base object IDs before proposal logic can run.

## Verification

- `bash -n scripts/maintainer/baseline_inventory.sh` — passed.
- `mix test test/lockspire/release/repository_hygiene_contract_test.exs` — passed, 11 tests and 0 failures.
- `node /Users/jon/.codex/gsd-core/bin/gsd-tools.cjs check api-coverage.verify-pre .planning/phases/138-baseline-inventory-evidence-taxonomy` — passed; `COVERAGE.md` correctly declares no external API integration surface.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None beyond the expected TDD RED failures that demonstrated the two unsafe publication paths before implementation.

## Known Stubs

None.

## Next Phase Readiness

The GitHub aggregate is now fail-closed for API, pagination, and normalized-row failures. Plan 138-08 may address the next verification gap without depending on any affirmative disposition from partial GitHub evidence.

## Self-Check: PASSED

- Confirmed all three changed source/test files and this summary exist.
- Confirmed all four Task 1/Task 2 RED and GREEN commits exist.
- Re-ran every plan verification command successfully after the final implementation commit.
