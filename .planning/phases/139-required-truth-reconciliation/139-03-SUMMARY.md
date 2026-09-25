---
phase: 139-required-truth-reconciliation
plan: "03"
subsystem: release-automation-contracts
tags: [github-actions, exunit, release-please, supply-chain, full-sha]

requires:
  - phase: 139-required-truth-reconciliation
    plan: "01"
    provides: Exact-SHA acceptance receipt names and no-publish outcome semantics
provides:
  - Static event-aware proof of push-only Release Please maintenance and dispatch-only protected publication
  - Exact dependency and package-before-GitHub-release ordering assertions for the protected release path
  - Immutable full-SHA reference scanning across every workflow and the repository-controlled Release Please composite
affects: [139-05, 139-06, 139-07, phase-141]

actuals:
  tokens: 1623
  tasks: 2
  commits: 4
plan_head_before: 92f123c92a5c212c97939df1f5f79b85b2f6267a

tech-stack:
  added: []
  patterns: [job-region structural parsing, event-separated release authority, exact external-action reference predicate]

key-files:
  created: []
  modified:
    - test/lockspire/release_ci_evidence_contract_test.exs
    - test/lockspire/workflow_supply_chain_contract_test.exs

key-decisions:
  - "Treat successful push runs as positive no-publish evidence only because the parsed release-please job is push-only and every validation/publication job retains its dispatch-owned guard and needs chain."
  - "Keep workflow-only timeout and PostgreSQL image policies on the sorted workflow set while applying one stricter exact-reference predicate to workflows plus the repository-controlled composite."

patterns-established:
  - "Release graph proof extracts top-level job regions before asserting names, events, dependencies, and step ordering."
  - "External actions must match one non-local action path, one @ separator, and exactly forty lowercase hexadecimal characters; local ./ references remain permitted."

requirements-completed: [CI-07, HYGIENE-06, TRUTH-05]

coverage:
  - id: D1
    description: Push-only Release Please maintenance and dispatch-only protected publication are explicitly distinguished by exact job names, guards, dependencies, and ordering.
    requirement: CI-07
    verification:
      - kind: unit
        ref: "test/lockspire/release_ci_evidence_contract_test.exs#release push is no-publish while protected dispatch retains the publication graph"
        status: pass
    human_judgment: false
  - id: D2
    description: Every tracked workflow and the Release Please composite reject mutable external-action references while workflow-only policies retain their original scope.
    requirement: TRUTH-05
    verification:
      - kind: unit
        ref: "test/lockspire/workflow_supply_chain_contract_test.exs#immutable action references include the repository-controlled composite exactly once"
        status: pass
    human_judgment: false
  - id: D3
    description: The two new health assertions close only the demonstrated release-graph and composite-scan gaps without changing executable YAML.
    requirement: HYGIENE-06
    verification:
      - kind: integration
        ref: "mix test test/lockspire/release_ci_evidence_contract_test.exs test/lockspire/workflow_supply_chain_contract_test.exs (6 tests, 0 failures)"
        status: pass
    human_judgment: false

duration: 36 min
completed: 2026-09-11
status: complete
---

# Phase 139 Plan 03: Release Graph and Immutable Action Surface Summary

**Focused ExUnit contracts now pin the push/no-publish versus protected-dispatch release graph and require exact full-SHA external-action references across workflows plus the Release Please composite.**

## Performance

- **Duration:** 36 min
- **Started:** 2026-09-11T22:27:38Z
- **Completed:** 2026-09-11T23:03:24Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- Parsed all five top-level Release workflow job regions and pinned their exact display names, event guards, needs edges, and protected package-publication order.
- Proved the push-owned Release Please job cannot depend on or invoke protected artifact, Hex, or GitHub release steps.
- Extended immutable action scanning to the sorted complete workflow set plus exactly one repository-controlled composite, with hostile tag, branch, short-SHA, expression, and missing-ref cases rejected.

## Task Commits

Each task followed RED then GREEN and was committed atomically:

1. **Task 1: Prove the push no-publish and protected-dispatch job graph**
   - `e3ad158e` — `test(139-03): add failing release job graph contract`
   - `279a46ef` — `feat(139-03): pin release event and publication graph`
2. **Task 2: Scan the complete tracked action-reference surface for immutable pins**
   - `629461c3` — `test(139-03): add failing composite action scan gate`
   - `eb81abc1` — `feat(139-03): scan complete immutable action surface`

## Files Created/Modified

- `test/lockspire/release_ci_evidence_contract_test.exs` — Job-region parser plus event, dependency, negative reachability, artifact-consumption, and publication-order assertions.
- `test/lockspire/workflow_supply_chain_contract_test.exs` — Separate sorted workflow and immutable-reference path sets with exact full-SHA and hostile-reference proof.

## Evidence

- `mix test test/lockspire/release_ci_evidence_contract_test.exs` — 3 tests, 0 failures.
- `mix test test/lockspire/workflow_supply_chain_contract_test.exs` — 3 tests, 0 failures.
- Combined plan gate — 6 tests, 0 failures.
- `git diff --name-only 92f123c9..HEAD -- .github` — no tracked paths beneath `.github` changed in this plan.

## TDD Gate Compliance

- Task 1 RED: the named release graph test failed because its extractor returned zero of the five required job regions; `tdd-red-evidence` returned `RED_EVIDENCE_OK`.
- Task 1 GREEN: all five job regions were parsed and all three release evidence tests passed.
- Task 2 RED: the named immutable-reference test failed because the workflow-only path list contained zero copies of the composite; `tdd-red-evidence` returned `RED_EVIDENCE_OK`.
- Task 2 GREEN: the composite appeared exactly once, mutable-reference mutations were rejected, and all three supply-chain tests passed.
- No separate REFACTOR commit was needed; the GREEN implementations are the minimal test-only contract changes.

## Decisions Made

- Static source proof is not a live release claim: it protects job eligibility and ordering, while the later exact-main plan remains responsible for observed workflow outcomes.
- The immutable-reference predicate rejects multiple `@` separators as well as mutable suffixes, preventing a tag or branch prefix from hiding before a full SHA.

## Assumption Delta

`no-change` — push-owned jobs are event-inapplicable to protected publication, while every validation, package proof, Hex publication, GitHub release, and public-install control remains mandatory on the existing workflow-dispatch release path.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## Known Stubs

None. The temporary RED extractors were fully implemented before GREEN and no skipped or placeholder assertion remains.

## Threat Flags

None. The release-event and tracked-YAML trust boundaries are the exact surfaces covered by T-139-11 through T-139-13; no workflow, release, endpoint, authentication, schema, or runtime surface changed.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- The no-publish job graph and complete immutable action-reference surface are ready for later candidate and exact-main acceptance.
- Executable workflow YAML and the composite action remain byte-for-byte unchanged.

## Self-Check: PASSED

- Both modified contract-test files and this summary exist.
- Task commits `e3ad158e`, `279a46ef`, `629461c3`, and `eb81abc1` resolve in repository history.
- The persisted plan ledger measures four task commits from `92f123c92a5c212c97939df1f5f79b85b2f6267a` through the current task HEAD.
- Fresh combined verification completed with all 6 tests passing; `git diff --check` and `verify-summary` also passed.

---
*Phase: 139-required-truth-reconciliation*
*Completed: 2026-09-11*
