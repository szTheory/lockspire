---
phase: 137-ci-conformance-and-release-proof
plan: 04
subsystem: ci
tags: [github-actions, coverage, sobelow, dependency-policy]
requires:
  - phase: 137-ci-conformance-and-release-proof
    provides: checksum-bound coverage exports and explicit security/dependency gates
provides:
  - SHA-bound fast/integration coverage artifact transport
  - Non-executing complete-coverage aggregate job
  - Required Sobelow and dependency-topology steps
affects: [release-proof, required-checks, dependency-fixtures]
tech-stack:
  added: []
  patterns: [least-privilege artifact handoff, static CI topology contract]
key-files:
  created:
    - test/lockspire/ci_workflow_evidence_contract_test.exs
  modified:
    - .github/workflows/ci.yml
key-decisions:
  - "The aggregate job imports exactly the SHA-named fast and integration artifacts and runs no test partition."
  - "Repository-level contents: read permission remains the only CI token permission."
patterns-established:
  - "Use static contracts to enforce needs edges, artifact paths, revision binding, and required fail-closed scripts."
requirements-completed: [CI-01, CI-02, CI-03]
coverage:
  - id: D1
    description: Required CI transports one fast and one integration coverage export into a SHA-bound aggregate verdict.
    requirement: CI-02
    verification:
      - kind: unit
        ref: test/lockspire/ci_workflow_evidence_contract_test.exs
        status: pass
    human_judgment: false
  - id: D2
    description: Required CI retains explicit security, dependency, topology, and lock-boundary gates.
    requirement: CI-01
    verification:
      - kind: unit
        ref: test/lockspire/ci_security_dependency_contract_test.exs
        status: pass
    human_judgment: false
duration: 10min
completed: 2026-08-27
status: complete
---

# Phase 137 Plan 04: CI Evidence Topology Summary

**Required CI now transports SHA-bound coverage evidence into a non-rerunning 84% aggregate job while explicitly enforcing both router scans, dependency truth, and immutable fixture locks.**

## Accomplishments

- Fast and integration jobs export native coverdata with `github.sha`, upload exact receipt/data files under distinct SHA-bound names, and retain them for seven days.
- A least-privilege `coverage-aggregate` job depends on both producer jobs, downloads only their named artifacts into bounded directories, and invokes `aggregate_coverage.sh` without rerunning tests.
- Fast CI runs the dual-router Sobelow scan and dependency/cycle truth gate explicitly, while existing QA, docs, audit, package, and architecture work remains required.
- Adoption-demo lock drift is checked explicitly, independently of the compatibility fixture lock boundary.

## Task Commits

1. **Task 1: Coverage evidence topology (RED)** - `9beca637` (shared-index race captured the new contract test without changing its contents)
2. **Tasks 1–2: Green workflow and required security/fixture gates** - `311f8ae4`

## Verification

- `MIX_ENV=test mix test test/lockspire/ci_workflow_evidence_contract_test.exs test/lockspire/ci_static_contract_test.exs test/lockspire/workflow_supply_chain_contract_test.exs test/lockspire/ci_security_dependency_contract_test.exs` — 10 tests, 0 failures.
- `bash scripts/ci/lint_workflows.sh` — passed with repository-pinned actionlint and shellcheck.
- `git diff --check -- .github/workflows/ci.yml test/lockspire/ci_workflow_evidence_contract_test.exs` — passed.

## Decisions Made

- GitHub’s artifact guidance supports same-workflow named artifact handoff with `needs`; the aggregate job keeps the repository’s `contents: read` permission and relies on the Plan 02 receipt validation before Mix imports coverage data.
- The coverage uploader has `if-no-files-found: error`, so producer evidence absence cannot become a passing aggregate.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Shared-index race] Preserved the RED contract test after another agent committed it accidentally.**
- **Found during:** Task 1.
- **Issue:** the shared git index placed the newly staged RED test in unrelated commit `9beca637`.
- **Fix:** retained the exact test, formatted and strengthened it in the Plan 04 green commit, and recorded the provenance here.
- **Files modified:** `test/lockspire/ci_workflow_evidence_contract_test.exs`.
- **Verification:** focused workflow contracts pass.

## Self-Check: PASSED

The workflow, contract test, and summary exist; commits `9beca637` and `311f8ae4` are present in git history.
