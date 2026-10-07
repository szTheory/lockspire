---
phase: 138-baseline-inventory-evidence-taxonomy
plan: "19"
subsystem: release-maintenance
tags: [git, evidence-integrity, lifecycle-validation, topology, fail-closed]
requires:
  - phase: 138-18
    provides: Object-format-valid baseline receipts and exact regular-file publication.
provides:
  - Complete canonical ledger schema authorization with declared-source receipt replay.
  - Object-format-aware, read-only topology and porcelain-v2 currentness proof.
  - Positive semantic validation for every authorized lifecycle companion document.
affects: [phase-138-verification, phase-139, phase-140, snapshot-currentness]
actuals:
  tokens: 7651
  tasks: 3
  commits: 7
tech-stack:
  added: []
  patterns: [schema-before-authority, explicit source receipt replay, positive lifecycle transition validation]
key-files:
  created:
    - .planning/phases/138-baseline-inventory-evidence-taxonomy/138-19-SUMMARY.md
  modified:
    - scripts/maintainer/baseline_inventory.sh
    - test/lockspire/release/repository_hygiene_contract_test.exs
    - test/support/lockspire/release_proof/package_assertions.ex
key-decisions:
  - "Resolve snapshot authority only after one repository-bound complete canonical frontmatter block validates every declared source fingerprint."
  - "Treat malformed porcelain-v2 branch metadata as unavailable currentness evidence even when git status exits successfully."
  - "Authorize lifecycle commits only when every changed companion satisfies its class-specific parent-to-child semantic contract."
patterns-established:
  - "not_applicable is valid only for Git, GitHub, or maintained sources excluded by declared_source_scopes."
  - "Committed and working-tree lifecycle candidates fail closed on unvalidated path, type, identity, structure, or semantic transition."
requirements-completed: [BASE-01, BASE-02, LOOSE-01]
coverage:
  - id: D1
    description: Complete canonical ledger schema and every declared receipt are required before snapshot authority resolves.
    requirement: BASE-01
    verification:
      - kind: integration
        ref: test/lockspire/release/repository_hygiene_contract_test.exs#baseline snapshot relation closes relation integrity gaps
        status: pass
    human_judgment: false
  - id: D2
    description: Local branch, tag, worktree, and porcelain status replay is deterministic, read-only, and fail-closed.
    requirement: BASE-02
    verification:
      - kind: integration
        ref: test/lockspire/release/repository_hygiene_contract_test.exs#baseline snapshot relation closes relation integrity gaps
        status: pass
    human_judgment: false
  - id: D3
    description: Every authorized lifecycle class positively validates all changed primary and companion documents.
    requirement: LOOSE-01
    verification:
      - kind: integration
        ref: test/lockspire/release/repository_hygiene_contract_test.exs#baseline snapshot relation closes relation integrity gaps
        status: pass
      - kind: integration
        ref: mix test test/lockspire/release_readiness_contract_test.exs
        status: pass
    human_judgment: false
duration: 30min
completed: 2026-09-09
status: complete
---

# Phase 138 Plan 19: Snapshot Relation Integrity Summary

**Snapshot currentness now derives only from a complete repository-bound ledger, readable unchanged topology, and positively validated lifecycle transitions.**

## Performance

- **Duration:** 30 min
- **Started:** 2026-09-09T16:10:28Z
- **Completed:** 2026-09-09T16:40:40Z
- **Tasks:** 3/3
- **Files modified:** 3

## Accomplishments

- Required one closed canonical ledger frontmatter block with complete status, repository identity, collection bounds, object-format-valid SHAs, and explicit fingerprints for every declared source.
- Recollected Git, GitHub, and maintained evidence when declared, while rejecting missing, invalid, implicit, or forged receipt authority before lifecycle classification.
- Replayed branches, tags, worktrees, and porcelain-v2 status through validated normalized projections with source-specific failure rows and deterministic read-only assertions.
- Positively validated PLAN, STATE, ROADMAP, REQUIREMENTS, REVIEW, VERIFICATION, SUMMARY, and PROJECT transitions wherever an authorized lifecycle class permits them.
- Added a focused `:phase138_relation_gap` entry point covering schema forgeries, topology drift/failures, stable replay, authorized lifecycle controls, and hostile primary/companion histories.

## Task Commits

1. **Task 1 RED: Canonical ledger authority cases** — `13f14aa0` (test)
2. **Task 1 GREEN: Complete schema and declared-source replay** — `9ffd239f` (fix)
3. **Task 2 RED: Malformed status-header replay** — `da6dfa1a` (test)
4. **Task 2 GREEN: Object-format-aware status validation** — `6d1ae9da` (fix)
5. **Task 3 RED: Lifecycle companion rewrites** — `141284c5` (test)
6. **Task 3 GREEN: Positive companion-document validation** — `c002571d` (fix)
7. **Verification fix: Repeated fixture isolation** — `aec9d3b0` (fix)

## Files Created/Modified

- `scripts/maintainer/baseline_inventory.sh` — validates canonical snapshot authority, replays all declared receipts and local topology, and proves every allowed lifecycle document transition.
- `test/support/lockspire/release_proof/package_assertions.ex` — supplies complete canonical fixtures plus forged-ledger, topology/status, read-only, and lifecycle companion matrices.
- `test/lockspire/release/repository_hygiene_contract_test.exs` — exposes the focused `:phase138_relation_gap` contract with an explicit process-test timeout.

## Decisions Made

- Repository identity and complete status are authorization inputs, not descriptive metadata; a clone or partial ledger must be recollected before it can become currentness authority.
- A successful Git command contributes evidence only after its normalized output and object identities validate.
- Allowed-looking subjects and regular-file writes are necessary but insufficient; each companion document must prove its own phase identity, structure, and monotonic transition.

## Verification

- `bash -n scripts/maintainer/baseline_inventory.sh` — passed.
- `mix test test/lockspire/release/repository_hygiene_contract_test.exs --only phase138_relation_gap` — passed, 1 test and 0 failures (25 excluded).
- `mix test test/lockspire/release_readiness_contract_test.exs` — passed, 2 tests and 0 failures.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Isolated stale process-test fixture roots**
- **Found during:** Plan-level focused verification
- **Issue:** A previously interrupted ExUnit process could leave a deterministic temporary repository name behind, causing a later verification run to fail during fixture initialization rather than exercise relation behavior.
- **Fix:** Remove each relation matrix's own temporary root before repository initialization; the fixture remains isolated and is still removed after the test.
- **Files modified:** `test/support/lockspire/release_proof/package_assertions.ex`
- **Verification:** Repeated focused relation-gap run passed all schema, topology, and lifecycle histories.
- **Committed in:** `aec9d3b0`

---

**Total deviations:** 1 auto-fixed blocking test-isolation issue.
**Impact on plan:** The fix makes repeated verification deterministic without changing production behavior or broadening scope.

## Issues Encountered

- The unrelated untracked `.tool-versions` declares only Node.js, so verification used the installed Elixir 1.19.5 / OTP 28 toolchain through explicit ASDF version environment variables. The file was not modified or committed.

## Known Stubs

None. No implementation placeholder, skipped test, or incomplete relation branch was introduced.

## Security and Boundary Notes

- T-138-76 is closed by complete schema, repository identity, object-format, declared-source, and fingerprint validation before ledger resolution.
- T-138-77 is closed by explicit command success capture, normalized topology/status validation, exact receipt comparison, stable ordering, and before/after read-only proof.
- T-138-78 and T-138-79 are closed by class-specific validation for every authorized primary and companion path across committed and working-tree candidates.
- The verifier adds no ref, worktree, index, GitHub, maintained-record, ledger, schema, runtime API, endpoint, or product mutation surface.

## User Setup Required

None.

## Next Phase Readiness

- Verification gaps 5, 6, and 7 and review findings CR-03 and CR-04 now have focused fail-first production-path regressions.
- Plans 138-20 and 138-21 can rely on snapshot authority failing closed across forged schemas, local topology/status drift, and destructive lifecycle companion writes.

## Self-Check: PASSED

- Confirmed all three implementation/test files and this summary exist.
- Confirmed all seven task/deviation commits exist in the expected RED/GREEN order.
- Re-ran every plan-required verification after the final production and fixture changes; all passed with nonzero test counts.
- Confirmed no unexpected deletion, goal-blocking stub, skipped test, unrun plan verification, or unmodeled threat surface remains.

---
*Phase: 138-baseline-inventory-evidence-taxonomy*
*Completed: 2026-09-09*
