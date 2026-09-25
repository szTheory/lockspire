---
phase: 138-baseline-inventory-evidence-taxonomy
plan: "15"
subsystem: release-maintenance
tags: [git, topology, lifecycle-validation, fail-closed, tdd]
requires:
  - phase: 138-14
    provides: Structured maintained evidence, quoted frontmatter, and byte-safe canonical rendering.
provides:
  - Relation-time branch, tag, and worktree receipt comparison against the immutable ledger fingerprint.
  - Explicit unavailable evidence for failed or malformed topology, stable-ID, and worktree-status queries.
  - Positive committed and working-tree validators for Phase 138 summaries, reviews, verification, completion, and transition bookkeeping.
affects: [138-16, phase-138-verification, phase-139, phase-140, baseline-currentness]
actuals:
  tokens: 11554
  tasks: 2
  commits: 5
tech-stack:
  added: []
  patterns: [normalized immutable receipt comparison, positive old-to-new lifecycle validation, shared committed-and-working-tree semantics]
key-files:
  created:
    - .planning/phases/138-baseline-inventory-evidence-taxonomy/138-15-SUMMARY.md
  modified:
    - scripts/maintainer/baseline_inventory.sh
    - test/lockspire/release/repository_hygiene_contract_test.exs
    - test/support/lockspire/release_proof/package_assertions.ex
key-decisions:
  - "Normalize only the authorized primary main/worktree advance back to the evidence base; every other branch, tag, and linked-worktree identity or target remains exact receipt evidence."
  - "Authorize lifecycle bookkeeping only through class-specific regular-file, frontmatter, heading, path-set, and old-to-new semantic validators."
  - "Use the same Phase 138-to-139 content contract for committed, staged, unstaged, and mixed-index transition projections."
patterns-established:
  - "Relation receipt replay: recollect each Git topology domain, preserve incomplete-domain diagnostics, normalize only expected lifecycle movement, then compare both domain renderings and the aggregate ledger fingerprint."
  - "Positive lifecycle proof: exact subject and paths select a class, but raw change status, nonempty blobs, phase identity, document structure, and monotonic semantics grant authorization."
requirements-completed: [BASE-01, BASE-02, LOOSE-01]
coverage:
  - id: D1
    description: Snapshot currentness now fails closed on changed or unreadable local branches, tags, worktrees, stable IDs, and relation-time status evidence.
    requirement: BASE-02
    verification:
      - kind: integration
        ref: test/lockspire/release/repository_hygiene_contract_test.exs#baseline snapshot relation fails closed on topology and destructive bookkeeping drift
        status: pass
      - kind: other
        ref: bash -n scripts/maintainer/baseline_inventory.sh
        status: pass
    human_judgment: false
  - id: D2
    description: Summary, review, verification, completion, and transition bookkeeping require positive document and old-to-new semantics in committed and working-tree forms.
    requirement: LOOSE-01
    verification:
      - kind: integration
        ref: test/lockspire/release/repository_hygiene_contract_test.exs#baseline snapshot relation fails closed on topology and destructive bookkeeping drift
        status: pass
      - kind: integration
        ref: test/lockspire/release_readiness_contract_test.exs
        status: pass
    human_judgment: false
  - id: D3
    description: The repository-wide quality, security, packaging, fast-test, and integration gates remain green with the stricter relation classifier.
    requirement: BASE-01
    verification:
      - kind: other
        ref: mix ci
        status: pass
    human_judgment: false
duration: 31min
completed: 2026-08-29
status: complete
---

# Phase 138 Plan 15: Complete Snapshot Relation and Positive Lifecycle Validation Summary

**Immutable snapshot currentness now replays local Git topology and authorizes Phase 138 bookkeeping only through positive, non-destructive document transitions.**

## Performance

- **Duration:** 31 min
- **Started:** 2026-08-29T00:18:06Z
- **Completed:** 2026-08-29T00:48:44Z
- **Tasks:** 2/2
- **Files modified:** 3

## Accomplishments

- Bound relation verification to the ledger's normalized branch, tag, and worktree receipt, with exact mismatch rows for add/delete/move drift and unavailable rows for every failed or malformed query.
- Made relation-time porcelain-v2 status capture explicit so unreadable or malformed worktree evidence can never become a clean authorized projection.
- Replaced added-line keyword denial with positive summary, review, passed-verification, phase-completion, and Phase 138-to-139 transition validators.
- Proved deletion, empty content, rename, type change, wrong phase, missing headings, arbitrary prose, and mixed source paths fail closed for every lifecycle class, while valid staged, unstaged, and mixed-index transitions remain authorized.

## Task Commits

Each TDD task was committed through RED and GREEN gates:

1. **Task 1 RED: Expose snapshot topology drift** — `4b7fc9b2` (test)
2. **Task 1 GREEN: Bind relation to Git topology** — `975e27e0` (feat)
3. **Task 2 RED: Expose destructive lifecycle authorization** — `7a4e6431` (test)
4. **Task 2 GREEN: Validate lifecycle transitions positively** — `e9705cfe` (feat)
5. **Verification fix: Preserve CI-safe lifecycle evidence** — `506ce6a3` (fix)

## Files Created/Modified

- `scripts/maintainer/baseline_inventory.sh` — relation-time Git receipt replay, domain mismatch/unavailable rows, explicit porcelain-v2 status handling, and positive lifecycle validators.
- `test/lockspire/release/repository_hygiene_contract_test.exs` — focused topology and destructive-bookkeeping fail-closed entry point.
- `test/support/lockspire/release_proof/package_assertions.ex` — stable/read-only controls, add/delete/move topology histories, query-failure shims, positive lifecycle controls, hostile committed variants, and staged/unstaged transition histories.
- `.planning/phases/138-baseline-inventory-evidence-taxonomy/138-15-SUMMARY.md` — canonical execution and verification record.

## Decisions Made

- The current primary `main` branch and root worktree may advance through the already-classified ledger/lifecycle chain, so their receipt SHA is normalized back to `evidence_base_sha`; all sibling branches, tags, and linked worktrees remain exact and any movement requires recollection.
- Familiar subjects and allowed path names are routing hints only. Authorization additionally requires regular nonempty current blobs, exact phase/plan identity, class-specific headings/frontmatter, and valid parent-to-current semantics.
- Working-tree transition authorization reads HEAD and current files directly without constructing commits, changing the index, or mutating repository state.

## Verification

- `bash -n scripts/maintainer/baseline_inventory.sh` — passed.
- `mix format --check-formatted test/lockspire/release/repository_hygiene_contract_test.exs test/support/lockspire/release_proof/package_assertions.ex` — passed.
- `mix test test/lockspire/release/repository_hygiene_contract_test.exs` — passed, 23 tests and 0 failures.
- `mix test test/lockspire/release_readiness_contract_test.exs` — passed, 2 tests and 0 failures.
- `mix ci` — passed: Credo and Sobelow clean, docs/package/audit gates passed, 1,392 fast tests passed with 6 existing skips, and 102 integration tests passed.
- Stable relation controls compared refs, worktree registrations, index tree, porcelain status, and ledger bytes before/after repeated verification and remained byte-for-byte unchanged.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Normalized signed Bash bytes and scoped phase labels for the full CI proof**

- **Found during:** Plan-level `mix ci`
- **Issue:** CI exposed signed-byte rendering of valid UTF-8 under its shell locale and rejected literal phase-numbered labels introduced in active proof fixtures.
- **Fix:** Converted signed shell-byte values to unsigned bytes before UTF-8 validation and constructed fixture phase labels through the existing scoped constants.
- **Files modified:** `scripts/maintainer/baseline_inventory.sh`, `test/support/lockspire/release_proof/package_assertions.ex`
- **Verification:** The focused UTF-8/proof-quality reproductions passed, followed by the complete `mix ci` gate.
- **Committed in:** `506ce6a3`

---

**Total deviations:** 1 auto-fixed (1 Rule 1 bug). **Impact on plan:** The fix preserved existing canonical encoding and proof-quality contracts without expanding product or protocol scope.

## Issues Encountered

- The first `mix ci` run identified the two verification regressions above. Both were fixed and the complete gate passed on rerun.
- Hex printed an expired local authentication warning, but every public dependency, audit, docs, package, dry-run, test, and integration operation completed successfully without private-resource access.

## Known Stubs

None. `TODO` and `FIXME` occurrences are maintained-marker selectors or hostile fixture inputs, not unfinished implementation. No skipped tests or unrun verification steps were introduced by this plan.

## Security and Boundary Notes

- T-138-59 is closed by normalized relation-time branch/tag/worktree recollection plus domain and aggregate fingerprint comparison.
- T-138-60 is closed by explicit porcelain-v2 command and parse failure rows.
- T-138-61 is closed by exact raw write status, nonempty blob, identity, structure, and parent/current validation for every committed class.
- T-138-62 is closed by reusing the Phase 138-to-139 semantic contract for committed and working-tree transitions and rejecting destructive or mixed projections.
- No endpoint, authentication path, database schema, package dependency, runtime module, public API, Git ref mutation, worktree mutation, or external-object mutation was added.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Plan 138-16 can regenerate the canonical inventory with complete local topology/status currentness and strict lifecycle authorization.
- Phase verification can rerun CR-04, CR-05, and CR-06 directly through the focused repository-hygiene contract.
- No blocker remains from Plan 138-15.

## Self-Check: PASSED

- Confirmed all three implementation/test files and this summary exist.
- Confirmed commits `4b7fc9b2`, `975e27e0`, `7a4e6431`, `e9705cfe`, and `506ce6a3` exist in the required RED/GREEN order.
- Confirmed the coverage classifier accepts all three deliverables as fully automated passing evidence.
- Confirmed no goal-blocking stubs, newly skipped tests, unrun verification commands, unexpected deletions, or unmodeled threat surfaces remain.

---
*Phase: 138-baseline-inventory-evidence-taxonomy*
*Completed: 2026-08-29*
