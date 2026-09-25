---
phase: 138-baseline-inventory-evidence-taxonomy
plan: "18"
subsystem: release-maintenance
tags: [git, evidence-integrity, atomic-publication, filesystem-safety, fail-closed]
requires:
  - phase: 138-17
    provides: Error-aware GitHub evidence normalization and contradiction closure.
provides:
  - Object-format-aware Git baseline identity and command validation.
  - Aggregate partial status for missing or malformed baseline evidence.
  - Lock-owned no-follow publication restricted to one exact regular-file target.
affects: [phase-138-verification, phase-139, phase-140, baseline-collector]
estimate:
  tokens: 32000
  tasks: 2
actuals:
  tokens: 5531
  tasks: 2
  commits: 4
tech-stack:
  added: []
  patterns: [explicit command-result capture, object-format digest validation, directory-fd atomic rename, target identity recheck]
key-files:
  created:
    - .planning/phases/138-baseline-inventory-evidence-taxonomy/138-18-SUMMARY.md
  modified:
    - scripts/maintainer/baseline_inventory.sh
    - test/lockspire/release/repository_hygiene_contract_test.exs
    - test/support/lockspire/release_proof/package_assertions.ex
key-decisions:
  - "A Git baseline is complete only when fetch, object-format-valid HEAD/main/origin-main identities, exact divergence grammar, and valid porcelain-v2 evidence all succeed."
  - "Publication authority binds the target's type, identity, and bytes under the target lock, then uses a no-follow directory descriptor to replace only the requested basename."
patterns-established:
  - "Failed Git command stdout is discarded before any immutable identity reaches frontmatter."
  - "Existing output replacement and absent-target creation share one lock-first target-state transaction."
requirements-completed: [BASE-01, BASE-02]
coverage:
  - id: D1
    description: Git baseline completeness and exact lock-owned regular-file publication fail closed on malformed evidence or hostile targets.
    requirement: BASE-01
    verification:
      - kind: integration
        ref: mix test test/lockspire/release/repository_hygiene_contract_test.exs#baseline inventory collector fails closed for malformed or unavailable Git domains
        status: pass
      - kind: integration
        ref: mix test test/lockspire/release/repository_hygiene_contract_test.exs#baseline inventory collector closes publication integrity gaps
        status: pass
    human_judgment: false
duration: 17min
completed: 2026-09-09
status: complete
---

# Phase 138 Plan 18: Baseline and Publication Integrity Summary

**Git baseline receipts now become complete only from validated immutable identities and command grammars, and publication can replace only the exact lock-owned regular ledger file.**

## Performance

- **Duration:** 17 min
- **Completed:** 2026-09-09T16:02:17Z
- **Tasks:** 2/2
- **Files modified:** 3

## Accomplishments

- Validated HEAD, local `main`, and remote `main` against the repository's declared SHA-1 or SHA-256 object format.
- Discarded stdout from failed identity reads and folded identity, divergence, and porcelain completeness into the single top-level snapshot status.
- Rejected directory, symlink-to-file, symlink-to-directory, and other non-regular publication targets while preserving target and neighboring bytes.
- Rechecked existing-target identity and content, or continued absence, under the publication lock immediately before a directory-descriptor-based atomic rename.
- Re-ran absent-target double-writer, tracked modification/deletion, untracked addition, status failure, signal cleanup, exact owned-path exclusion, and retry contracts.

## Task Commits

Each behavior task was executed through a failing regression followed by its passing implementation:

1. **Task 1 RED: Incomplete baseline receipts** — `e68834f8` (test)
2. **Task 1 GREEN: Validated baseline aggregation** — `11634ab0` (fix)
3. **Task 2 RED: Unsafe publication targets** — `28c2665d` (test)
4. **Task 2 GREEN: Exact regular-file publication** — `b92dbeaf` (fix)

## Files Created/Modified

- `scripts/maintainer/baseline_inventory.sh` — validates Git-baseline components and performs no-follow, identity-bound atomic publication.
- `test/support/lockspire/release_proof/package_assertions.ex` — adds missing/malformed baseline and hostile target fixtures and reuses the full publication transaction matrix.
- `test/lockspire/release/repository_hygiene_contract_test.exs` — adds the tagged `:phase138_publication_gap` gap-closure entry point.

## Decisions Made

- Repository object format is authoritative for immutable SHA length; generic 40-to-64-character acceptance is insufficient for baseline identity.
- A nonzero initial working-tree status remains a publication-blocking failure. Successful but malformed porcelain is represented as partial evidence and cannot yield a clean conclusion.
- Existing targets are authorized by non-symlink regular-file type plus device, inode, size, modification time, and SHA-256 content identity under lock.
- Final publication opens the canonical parent without following a symlink and calls `os.replace` with source and destination directory descriptors, preventing directory-destination interpretation.

## Verification

- `bash -n scripts/maintainer/baseline_inventory.sh` — passed.
- `mix test test/lockspire/release/repository_hygiene_contract_test.exs --only phase138_publication_gap` — passed, 1 test and 0 failures (24 excluded).
- `mix test test/lockspire/release/repository_hygiene_contract_test.exs` — passed, 25 tests and 0 failures.
- RED gates were observed before implementation: missing HEAD rendered top-level complete, and an existing directory was accepted as a publication destination.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- The unrelated untracked `.tool-versions` declares only Node.js, so verification used the installed Elixir 1.19.5 / OTP 28 toolchain through explicit ASDF version environment variables. The file was not modified or committed.
- Physical parent canonicalization exposes `/var` versus `/private/var` aliases on macOS. Owned-path matching now canonicalizes absolute candidate parents so collector-owned temporary artifacts remain excluded without treating near-name paths as owned.

## Known Stubs

None. TODO/FIXME strings in the scanned files are maintained-evidence selector inputs and fixtures, not implementation stubs. No skipped test was added.

## Security and Boundary Notes

- T-138-72 is closed by explicit command branches, failure-stdout discard, repository object-format validation, exact divergence validation, and aggregate partial status.
- T-138-73 is closed by under-lock target-type rejection and no-follow directory-descriptor publication.
- T-138-74 is closed by lock-first current-state authorization and an immediate target identity/absence recheck.
- T-138-75 remains closed by identical successful normalized porcelain projections before publication; capture or recheck command failure aborts.
- No mutation beyond the existing metadata fetch, collector-owned lock/temporary state, and explicitly authorized ledger rename was introduced. No schema, dependency, runtime API, authentication path, endpoint, or product surface changed.

## User Setup Required

None.

## Next Phase Readiness

- Verification gaps 3 and 4 and review findings CR-01 and CR-05 now have focused production-process regressions.
- Later Phase 138 plans can rely on baseline completeness and publication integrity failing closed across missing evidence, path confusion, contention, and worktree drift.

## Self-Check: PASSED

- Confirmed all three implementation/test files and this summary exist.
- Confirmed commits `e68834f8`, `11634ab0`, `28c2665d`, and `b92dbeaf` exist in RED/GREEN order.
- Re-ran shell syntax, the focused tagged test, and the broader 25-test repository-hygiene contract after the final implementation; all passed.
- Confirmed no unexpected deletion, goal-blocking stub, newly skipped test, unrun verification, or unmodeled threat surface remains.

---
*Phase: 138-baseline-inventory-evidence-taxonomy*
*Completed: 2026-09-09*
