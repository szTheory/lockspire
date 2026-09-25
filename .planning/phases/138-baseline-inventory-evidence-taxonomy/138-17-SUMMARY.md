---
phase: 138-baseline-inventory-evidence-taxonomy
plan: "17"
subsystem: release-maintenance
tags: [github, graphql, evidence-integrity, duplicate-agreement, fail-closed]
requires:
  - phase: 138-16
    provides: Complete immutable baseline publication and relation proof.
provides:
  - Error-aware outer and nested GitHub GraphQL normalization.
  - Collection-neutral exact duplicate agreement for pull requests and issues.
  - Full-by-default GitHub CLI and GraphQL capability matrix.
affects: [phase-138-verification, phase-139, phase-140, github-triage]
actuals:
  tokens: 4374
  tasks: 2
  commits: 4
tech-stack:
  added: []
  patterns: [top-level GraphQL error rejection, namespace-neutral contradiction gating, production-CLI adversarial fixtures]
key-files:
  created:
    - .planning/phases/138-baseline-inventory-evidence-taxonomy/138-17-SUMMARY.md
  modified:
    - scripts/maintainer/baseline_inventory.sh
    - test/lockspire/release/repository_hygiene_contract_test.exs
    - test/support/lockspire/release_proof/package_assertions.ex
    - .planning/phases/138-baseline-inventory-evidence-taxonomy/COVERAGE.md
key-decisions:
  - "Reject any nonempty or malformed top-level GraphQL errors field before accepting outer or nested response data."
  - "Apply contradiction_count gating identically to pull-request and issue namespaces while retaining only validated safe siblings as defer evidence."
patterns-established:
  - "GraphQL error receipts expose stable local classifications only; remote diagnostic payloads never cross the rendering boundary."
  - "Exact duplicate corroboration is namespace-local, deterministic, and independent of page order."
requirements-completed: [TRIAGE-01, TRIAGE-02]
coverage:
  - id: D1
    description: Outer and nested partial-data-plus-errors responses remain partial and cannot produce merge-ready authority.
    requirement: TRIAGE-01
    verification:
      - kind: integration
        ref: test/lockspire/release/repository_hygiene_contract_test.exs#baseline inventory collector closes GitHub integrity gaps
        status: pass
    human_judgment: false
  - id: D2
    description: Contradictory issues are suppressed while exact duplicates and safe siblings remain deterministically visible under the correct authority.
    requirement: TRIAGE-02
    verification:
      - kind: integration
        ref: test/lockspire/release/repository_hygiene_contract_test.exs#baseline inventory collector closes GitHub integrity gaps
        status: pass
    human_judgment: false
  - id: D3
    description: Every GitHub CLI and GraphQL capability used by the phase is explicitly integrated with no unexplained opt-out.
    requirement: TRIAGE-02
    verification:
      - kind: other
        ref: node /Users/jon/.codex/gsd-core/bin/gsd-tools.cjs check api-coverage.verify-pre .planning/phases/138-baseline-inventory-evidence-taxonomy
        status: pass
    human_judgment: false
duration: 13min
completed: 2026-09-09
status: complete
---

# Phase 138 Plan 17: GitHub Completeness and Contradiction Closure Summary

**Every GitHub proposal now derives from error-free, terminally complete, internally consistent GraphQL evidence across both pull-request and issue namespaces.**

## Performance

- **Duration:** 13 min
- **Completed:** 2026-09-09T15:41:19Z
- **Tasks:** 2/2
- **Files modified:** 4

## Accomplishments

- Rejected nonempty top-level GraphQL errors in outer PR/issue pages and nested PR check pages before their data can establish completeness.
- Preserved pending and unknown checks as non-actionable evidence and rendered only stable sanitized error classifications.
- Generalized exact duplicate agreement to issues, suppressing contradictory identities while retaining safe corroborated siblings under aggregate partial status.
- Replaced the no-integration declaration with an explicit 8/8 `INTEGRATE` matrix for the GitHub CLI and GraphQL collection surface.

## Task Commits

Each behavior task was executed through a failing regression followed by its passing implementation:

1. **Task 1 RED: GraphQL partial-data error paths** — `b43a1b6b` (test)
2. **Task 1 GREEN: Error-aware outer and nested normalization** — `bc19013a` (fix)
3. **Task 2 RED: Contradictory issue evidence** — `64cb51c6` (test)
4. **Task 2 GREEN: Namespace-neutral contradiction gating and coverage matrix** — `1bd7b5d3` (fix)

## Files Created/Modified

- `scripts/maintainer/baseline_inventory.sh` — rejects top-level GraphQL errors and applies contradiction gating to both namespaces.
- `test/support/lockspire/release_proof/package_assertions.ex` — adds production-CLI fixtures for error-bearing responses, pending checks, contradictory and exact duplicate issues, namespace collisions, zero results, redaction, and ordering.
- `test/lockspire/release/repository_hygiene_contract_test.exs` — adds the tagged `:phase138_github_gap` gap-closure entry point.
- `.planning/phases/138-baseline-inventory-evidence-taxonomy/COVERAGE.md` — records the full GitHub CLI/GraphQL capability matrix.

## Decisions Made

- A top-level GraphQL `errors` field is acceptable only when it is an empty array. Any nonempty or malformed value yields a stable local failure code and discards that page set's authority.
- Duplicate agreement is collection-neutral. Pull requests and issues use their normalized allowlisted fields, and any conflicting identity makes its namespace and the aggregate partial.
- Contradictory identities never render an actionable row. Independently corroborated siblings may remain visible, but only with `defer` while aggregate evidence is partial.

## Verification

- `bash -n scripts/maintainer/baseline_inventory.sh` — passed.
- `mix test test/lockspire/release/repository_hygiene_contract_test.exs --only phase138_github_gap` — passed, 1 test and 0 failures (23 excluded).
- `mix test test/lockspire/release/repository_hygiene_contract_test.exs` — passed, 24 tests and 0 failures.
- `api-coverage.verify-pre` — passed with 8 capabilities, 8 integrated, and 0 opt-outs.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- The repository's unrelated untracked `.tool-versions` specifies only Node.js, so verification used the already-installed Elixir 1.19.5 / OTP 28 toolchain through explicit ASDF environment selection. The file was not modified or committed.

## Known Stubs

None. TODO/FIXME strings in the scanned files are maintained-evidence selector inputs and test fixtures, not implementation stubs. No skipped test was added.

## Security and Boundary Notes

- T-138-68 is closed by rejecting error-bearing outer and nested GraphQL pages before completeness is assigned.
- T-138-69 is closed by exact normalized duplicate agreement for both namespaces.
- T-138-70 is closed by stable sanitized limitation codes and adversarial assertions that remote diagnostic messages never render.
- T-138-71 is closed by namespace and aggregate disposition-authority gating.
- No mutation query, endpoint, authentication path, schema, dependency, runtime module, Mix task, or Lockspire product API was added.

## User Setup Required

None.

## Next Phase Readiness

- Verification gaps 2 and 10 plus review findings WR-01 and CR-02 now have focused production-path regressions.
- Later Phase 138 gap plans can proceed with GitHub evidence completeness and contradiction handling fail-closed across both namespaces.

## Self-Check: PASSED

- Confirmed all four changed implementation/test/coverage files and this summary exist.
- Confirmed commits `b43a1b6b`, `bc19013a`, `64cb51c6`, and `1bd7b5d3` exist in RED/GREEN order.
- Re-ran shell syntax, the focused tagged test, and API coverage after the final implementation change; all passed.
- Confirmed the broader 24-test repository-hygiene contract passed with zero failures and no unexpected deletions.
- Confirmed no goal-blocking stub, newly skipped test, unrun verification, raw GraphQL diagnostic, or unmodeled threat surface remains.

---
*Phase: 138-baseline-inventory-evidence-taxonomy*
*Completed: 2026-09-09*
