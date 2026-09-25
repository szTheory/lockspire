---
phase: 138-baseline-inventory-evidence-taxonomy
plan: "24"
subsystem: release-maintenance
tags: [github, object-identity, maintained-records, lifecycle-taxonomy, fail-closed]
requires:
  - phase: 138-23
    provides: Immutable proposal-only ledger, complete process contracts, and production currentness relation.
provides:
  - Exact 40-or-64 hexadecimal GitHub object identity across validation and PR proposal authority.
  - Structural active-record lifecycle precedence over incidental display prose.
  - Shared structured archive-action authority with fail-visible contradiction handling.
affects: [phase-138-recollection, phase-139, phase-140, phase-141]
actuals:
  tokens: 6374
  tasks: 3
  commits: 6
tech-stack:
  added: []
  patterns: [shared identity predicates, structural lifecycle authority, structured archive precedence, adversarial process fixtures]
key-files:
  created:
    - .planning/phases/138-baseline-inventory-evidence-taxonomy/138-24-SUMMARY.md
  modified:
    - scripts/maintainer/baseline_inventory.sh
    - test/lockspire/release/repository_hygiene_contract_test.exs
    - test/support/lockspire/release_proof/package_assertions.ex
key-decisions:
  - "GitHub head and base object identifiers use one exact 40-or-64 hexadecimal predicate in both normalized-row validation and merge-ready proposal authority."
  - "Exact REVIEW/VERIFICATION structure and status control active lifecycle classification; bounded display prose cannot suppress a record."
  - "Archive expansion and disposition consume one structured action result; conflicting structured authorities remain ambiguous and partial."
patterns-established:
  - "One authority parser feeds both selection and disposition so preprocessing cannot disagree with classification."
  - "Malformed or contradictory evidence retains safe sibling observations without affirmative action authority."
requirements-completed: [BASE-01, BASE-02, TRIAGE-01, TRIAGE-02, LOOSE-01]
coverage:
  - id: D1
    description: Existing fetch, baseline, porcelain, divergence, and limitation behavior remains fail-closed.
    requirement: BASE-01
    verification:
      - kind: integration
        ref: "test/lockspire/release/repository_hygiene_contract_test.exs full contract (29 tests)"
        status: pass
    human_judgment: false
  - id: D2
    description: Existing branch, tag, and worktree exact-format evidence remains intact.
    requirement: BASE-02
    verification:
      - kind: integration
        ref: "test/lockspire/release/repository_hygiene_contract_test.exs full contract (29 tests)"
        status: pass
    human_judgment: false
  - id: D3
    description: PR head and base OIDs are exactly 40 or 64 hexadecimal characters before complete or merge-ready authority.
    requirement: TRIAGE-01
    verification:
      - kind: integration
        ref: "repository_hygiene_contract_test.exs --only phase138_review_gap; 40/41/63/64 fixtures"
        status: pass
    human_judgment: false
  - id: D4
    description: Separate issue evidence and honest complete-zero behavior remain visible and defer-only when the PR namespace is partial.
    requirement: TRIAGE-02
    verification:
      - kind: integration
        ref: "repository_hygiene_contract_test.exs --only phase138_review_gap plus full contract"
        status: pass
    human_judgment: false
  - id: D5
    description: Active maintained records survive incidental prose and explicit archive actions outrank unrelated body text while contradictions remain partial.
    requirement: LOOSE-01
    verification:
      - kind: integration
        ref: "repository_hygiene_contract_test.exs --only phase138_review_gap; active lifecycle and 31-case archive matrix"
        status: pass
    human_judgment: false
duration: 38min
completed: 2026-09-09
status: complete
---

# Phase 138 Plan 24: Evidence Classification Fail-Closed Corrections Summary

**Exact GitHub identities, structural active lifecycle records, and structured archive actions now share fail-closed authority with adversarial process proof.**

## Performance

- **Duration:** 38 minutes
- **Started:** 2026-09-10T00:42:25Z
- **Completed:** 2026-09-10T01:20:14Z
- **Tasks:** 3/3
- **Files modified:** 3 implementation/test files plus this summary

## Accomplishments

- Replaced three permissive GitHub object-ID checks with one exact 40-or-64 hexadecimal predicate, preventing 41- and 63-character base OIDs from reaching complete or merge-ready authority.
- Removed display-fragment suppression so structurally valid `issues_found` reviews and `gaps_found` verifications remain stable active/fix-now REC rows even when they discuss missing terminal proof.
- Unified archive expansion and classification behind one full-blob structured action parser; 30 marker/prose/order combinations stay active/fix-now and a contradictory marker pair remains visibly ambiguous and partial.
- Preserved safe sibling observations, proposal-only authority, redaction, deterministic ordering, complete-zero language, exact supersession, and all eight existing GitHub coverage capabilities.

## Task Commits

1. **Task 1 RED: impossible GitHub OID regressions** — `f786d735` (test)
2. **Task 1 GREEN: exact shared GitHub OID predicate** — `994b8fb2` (fix)
3. **Task 2 RED: incidental active-lifecycle prose regressions** — `83801f55` (test)
4. **Task 2 GREEN: structural active-record authority** — `d797004f` (fix)
5. **Task 3 RED: archive action/prose contradiction matrix** — `1644a738` (test)
6. **Task 3 GREEN: structured archive-action precedence** — `f125b2ae` (fix)

## Files Created/Modified

- `scripts/maintainer/baseline_inventory.sh` — defines the exact GitHub object predicate, preserves structural active records, and shares archive action authority between expansion and classification.
- `test/lockspire/release/repository_hygiene_contract_test.exs` — adds the focused `:phase138_review_gap` process-contract entry point.
- `test/support/lockspire/release_proof/package_assertions.ex` — adds 40/41/63/64 PR fixtures, incidental active-record fixtures, and the archive marker/prose/order matrix.
- `.planning/phases/138-baseline-inventory-evidence-taxonomy/138-24-SUMMARY.md` — records implementation, adversarial outcomes, verification, and task commits.

## Verification

All Mix commands used Elixir 1.19.5 / OTP 28.4.1 through process-local ASDF variables.

| Command | Result |
| --- | --- |
| `bash -n scripts/maintainer/baseline_inventory.sh` | exit 0 |
| `mix test test/lockspire/release/repository_hygiene_contract_test.exs --only phase138_review_gap` | 1 test, 0 failures, 28 excluded |
| `mix test test/lockspire/release/repository_hygiene_contract_test.exs` | 29 tests, 0 failures |
| `node /Users/jon/.codex/gsd-core/bin/gsd-tools.cjs check api-coverage.verify-pre .planning/phases/138-baseline-inventory-evidence-taxonomy` | `block: false`; 8/8 capabilities integrated |

### Acceptance outcomes

- Exact 40- and 64-character PR head/base OIDs retain complete, merge-ready evidence; 41 and 63 characters make PR and aggregate evidence partial with no merge-ready row.
- The valid issue namespace remains visible only as defer evidence when malformed PR identity makes the aggregate partial.
- Both structurally active record families render exactly once with stable path-derived REC IDs and active/fix-now disposition despite incidental terminal-proof wording.
- Each `fix-now`, anchored status/outcome/disposition, and dedicated-heading action family stays active/fix-now against resolved, historical, and out-of-scope prose in either order.
- Conflicting structured authorities produce an unclassified/ambiguous receipt and a partial maintained aggregate.
- Existing authentication, pagination, nested-head equality, duplicate agreement, ordering, redaction, issue-zero, resolved-control, supersession, benign archive, encoding, and proposal-only contracts remain green.

## Decisions Made

- A single exact GitHub object predicate is the only PR identity authority; validators and proposal classification cannot drift independently.
- Structured lifecycle evidence is evaluated independently of bounded display excerpts.
- Archive fallback prose classification is used only when no structured action authority exists; structured contradictions never resolve by text order.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Aligned the fake active-record selector with production Git pathspecs**

- **Found during:** Task 3 full contract verification
- **Issue:** The fake selector returned `.planning/phases/old/complete.md`, which cannot match the production `*-REVIEW*`/`*-VERIFICATION*` active-record pathspecs after fragment suppression was removed.
- **Fix:** Removed the impossible candidate from both forward and reverse fixture orders while retaining structural resolved controls.
- **Files modified:** `test/support/lockspire/release_proof/package_assertions.ex`
- **Verification:** Full repository-hygiene contract passed with 29 tests and 0 failures.
- **Committed in:** `f125b2ae`

**2. [Rule 1 - Bug] Increased the async contention sentinel deadline**

- **Found during:** Task 3 full contract verification
- **Issue:** The larger adversarial process matrix increased concurrent suite load enough for the existing five-second writer sentinel to time out before the collector reached its deliberate pagination hold.
- **Fix:** Raised the bounded wait to fifteen seconds without changing lock, writer, or production behavior.
- **Files modified:** `test/support/lockspire/release_proof/package_assertions.ex`
- **Verification:** The exact full async contract command passed with 29 tests and 0 failures.
- **Committed in:** `f125b2ae`

**Total deviations:** 2 auto-fixed Rule 1 fixture defects. Both preserve the production contract and add no runtime or product surface.

## Issues Encountered

- The first Task 1 green run exposed an over-specific receipt assertion; it was corrected to the actual aggregate `pullRequests=partial` wording before the green commit.
- The archive fixture initially parsed `$*` rather than the path argument, causing generated records to appear unreadable; the test harness was corrected before Task 3 green verification.

## Known Stubs

None. The realized diff contains no TODO, FIXME, placeholder, skipped test, unrun verification, or unwired data source.

## Security and Boundary Notes

- T-138-98 is closed by exact object identity before normalized-row and merge-ready authority.
- T-138-99 is closed by structural lifecycle classification before incidental display prose can affect a record.
- T-138-100 is closed by one structured full-blob action result shared across expansion and disposition.
- T-138-101 remains preserved through safe-field allowlisting, bounded display, sanitized limitations, and redaction contracts.
- T-138-102 remains preserved because malformed and contradictory inputs force partial aggregates with defer-only or no row authority.
- No Git refs, worktrees, GitHub objects, release-owned files, historical records, canonical ledger, product/runtime APIs, schemas, packages, or proposal targets were mutated.

## User Setup Required

None.

## Next Phase Readiness

- Plan 138-25 can recollect and immutably republish the canonical ledger from this corrected, green collector base.
- Phase 140 retains all action authority; this plan produced observations and proposal classification only.

## Self-Check: PASSED

- Confirmed all three implementation/test files and this summary exist.
- Confirmed all six RED/GREEN task commits exist in order.
- Confirmed the focused contract, complete repository-hygiene contract, Bash syntax check, and API coverage gate passed after the final code changes.
- Confirmed all five requirements and D-01 through D-24 remain covered without changing `COVERAGE.md` or the canonical ledger.
- Confirmed no stubs, skipped tests, unrun verification, secret exposure, destructive behavior, or new threat surface was introduced.

---
*Phase: 138-baseline-inventory-evidence-taxonomy*
*Completed: 2026-09-09*
