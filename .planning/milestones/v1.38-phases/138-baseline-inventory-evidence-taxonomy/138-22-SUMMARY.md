---
phase: 138-baseline-inventory-evidence-taxonomy
plan: "22"
subsystem: release-maintenance
tags: [github, temporal-coherence, maintained-records, git-object-format, fail-closed]
requires:
  - phase: 138-21
    provides: Canonical proposal-only ledger and production currentness relation.
provides:
  - Exact outer-to-nested PR head binding before check evidence gains disposition authority.
  - Full-blob archive expansion and classification with independently bounded display excerpts.
  - Repository-format-exact object validation across branch, tag, and worktree evidence.
affects: [phase-138-verification, phase-139, phase-140, phase-141]
estimate:
  tokens: 30000
  tasks: 3
actuals:
  tokens: 8136
  tasks: 3
  commits: 6
tech-stack:
  added: []
  patterns: [exact temporal joins, authoritative-full-blob classification, format-bound object validation]
key-files:
  created:
    - .planning/phases/138-baseline-inventory-evidence-taxonomy/138-22-SUMMARY.md
  modified:
    - scripts/maintainer/baseline_inventory.sh
    - test/lockspire/release/repository_hygiene_contract_test.exs
    - test/support/lockspire/release_proof/package_assertions.ex
key-decisions:
  - "Nested PR check evidence carries exactly one commit OID and gains authority only when it equals the captured outer headRefOid."
  - "Archive expansion and disposition classification read the complete tracked blob; truncation remains display-only."
  - "Every branch, tag, and worktree object passes valid_snapshot_sha for the captured repository format."
patterns-established:
  - "Identity ambiguity suppresses affirmative authority while retaining safe sibling evidence."
  - "Authoritative classification inputs and rendered excerpts are separate data paths."
requirements-completed: [BASE-02, TRIAGE-01, LOOSE-01]
coverage:
  - id: D1
    description: Nested pull-request checks gain authority only when their validated commit OID equals the outer headRefOid.
    requirement: TRIAGE-01
    verification:
      - kind: integration
        ref: mix test test/lockspire/release/repository_hygiene_contract_test.exs#baseline inventory collector closes current evidence-integrity gaps
        status: pass
    human_judgment: false
  - id: D2
    description: Maintained archives are classified from complete tracked blobs while display excerpts remain bounded.
    requirement: LOOSE-01
    verification:
      - kind: integration
        ref: mix test test/lockspire/release/repository_hygiene_contract_test.exs#baseline inventory collector closes current evidence-integrity gaps
        status: pass
    human_judgment: false
  - id: D3
    description: Branch, tag, and worktree identities match the repository's exact SHA-1 or SHA-256 object format.
    requirement: BASE-02
    verification:
      - kind: integration
        ref: mix test test/lockspire/release/repository_hygiene_contract_test.exs#baseline inventory collector closes current evidence-integrity gaps
        status: pass
    human_judgment: false
duration: 25min
completed: 2026-09-09
status: complete
---

# Phase 138 Plan 22: Current Evidence-Integrity Gap Closure Summary

**PR checks are now commit-coherent, maintained archives are classified from complete tracked content, and Git evidence accepts only the repository's exact object format.**

## Performance

- **Duration:** 25 minutes
- **Completed:** 2026-09-09
- **Tasks:** 3/3
- **Files changed:** 3 implementation/test files plus this summary

## Accomplishments

- Bound each nested PR check receipt to one validated commit OID and compared it case-normalized for exact equality with the outer `headRefOid` before granting merge-ready authority.
- Added process-level fixtures for matching, pushed, missing, null, ambiguous, malformed, and page-changing nested PR identities while preserving pagination, duplicate corroboration, numeric ordering, and complete-zero behavior.
- Moved archive expansion and disposition classification to the complete collector-owned blob while preserving the existing 400-character rendered excerpt boundary.
- Prevented unreadable archive blobs from producing archive-summary authority and retained benign archive summarization.
- Routed branch, tag, and worktree object identities through `valid_snapshot_sha`, including both worktree parsing and stanza finalization, with SHA-1 and SHA-256 adversarial coverage.

## Task Commits

1. **Task 1 RED: PR head-coherence regression** — `db961d5c` (test)
2. **Task 1 GREEN: exact outer/nested head binding** — `d0874cc4` (fix)
3. **Task 2 RED: late-marker and unreadable-archive regressions** — `9fdc4121` (test)
4. **Task 2 GREEN: authoritative full-blob classification** — `81f15d77` (fix)
5. **Task 3 RED: exact object-format regressions** — `c643836b` (test)
6. **Task 3 GREEN: branch/tag/worktree format enforcement** — `292455f7` (fix)

## Files Created/Modified

- `scripts/maintainer/baseline_inventory.sh` — returns and validates nested commit OIDs, classifies archive content from complete blobs, and enforces exact repository object formats.
- `test/support/lockspire/release_proof/package_assertions.ex` — provides process-level temporal, late-marker, unreadable-blob, and SHA-1/SHA-256 adversarial fixtures.
- `test/lockspire/release/repository_hygiene_contract_test.exs` — adds the focused `:phase138_current_gap` contract entry point.
- `.planning/phases/138-baseline-inventory-evidence-taxonomy/138-22-SUMMARY.md` — records the gap-closure evidence and lifecycle outcome.

## Requirements Coverage

| Requirement | Coverage |
| --- | --- |
| BASE-01 | Preserved by the complete repository-hygiene suite; baseline capture and currentness behavior remain unchanged. |
| BASE-02 | Exact SHA-1/SHA-256 validation now covers branches, tags, and worktrees while retaining valid sibling rows. |
| TRIAGE-01 | Outer PR metadata and nested checks now join only on one exact full head OID; every identity ambiguity fails closed. |
| TRIAGE-02 | Existing issue pagination, duplicate consistency, ordering, and aggregate gating remain green. |
| LOOSE-01 | Archive expansion and classification use complete tracked blobs; display truncation cannot hide late actionable evidence. |

## Verification

- `bash -n scripts/maintainer/baseline_inventory.sh` — passed.
- `mix test test/lockspire/release/repository_hygiene_contract_test.exs --only phase138_current_gap` — passed, 1 test and 0 failures (27 excluded).
- `mix test test/lockspire/release/repository_hygiene_contract_test.exs` — passed, 28 tests and 0 failures.
- The focused fixture covers matching, pushed, absent, ambiguous, malformed, and pagination-varying PR OIDs; late archive markers after 410 benign characters; unreadable blobs; and exact 40/64-character acceptance across every Git domain.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Corrected the duplicate-order fixture's nested PR-2 head**

- **Found during:** Task 3 full contract verification
- **Issue:** The strengthened temporal join exposed that the exact-duplicate ordering fixture returned PR-1's nested OID for PR-2.
- **Fix:** Return PR-2's captured `4444...` head only for that scenario, preserving the fixture's intended coherent duplicate-order proof.
- **Files modified:** `test/support/lockspire/release_proof/package_assertions.ex`
- **Commit:** `292455f7`

## Issues Encountered

- The repository-local `.tool-versions` does not select Elixir. Verification used installed Elixir 1.19.5 / OTP 28.4.1 through process-local ASDF variables, matching the prior Phase 138 execution convention; no tool-version file was changed.

## Known Stubs

None. `TODO`/`FIXME` strings in the changed files are maintained-evidence selector vocabulary and fixtures, not implementation stubs. No tests were skipped and every planned verification command ran.

## Security and Boundary Notes

- T-138-88 and T-138-92 are closed by exact outer/nested commit identity and aggregate defer-only gating on every mismatch or ambiguity.
- T-138-89 is closed by complete-blob archive classification and fail-visible unreadable evidence.
- T-138-90 is closed by format-bound validation in every Git-domain path, including worktree rollover, blank closure, and final flush.
- T-138-91 remains preserved through sanitized limitation codes, allowlisted GitHub fields, bounded display, and existing encoding/redaction contracts.
- No network mutation, proposal disposition, Git ref deletion, product/runtime API, Mix task, schema, sidecar, or hygiene-checker ownership was introduced.

## User Setup Required

None.

## Next Phase Readiness

- Phase 138 verification may now rerun against the corrected collector.
- Plan 138-23 remains the sole owner of recollecting and republishing the canonical ledger after these corrections.

## Self-Check: PASSED

- Confirmed all three modified implementation/test files and this summary exist.
- Confirmed all six RED/GREEN commits exist in order.
- Reran the focused and complete repository-hygiene contracts with zero failures.
- Verified all acceptance criteria, proposal-only boundaries, and all five phase requirement relationships above.

---
*Phase: 138-baseline-inventory-evidence-taxonomy*
*Completed: 2026-09-09*
