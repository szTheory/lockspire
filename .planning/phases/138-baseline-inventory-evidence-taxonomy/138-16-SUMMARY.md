---
phase: 138-baseline-inventory-evidence-taxonomy
plan: "16"
subsystem: release-maintenance
tags: [git, github-graphql, evidence-ledger, immutable-snapshot, lifecycle-taxonomy]
requires:
  - phase: 138-15
    provides: Topology-aware currentness and positive lifecycle authorization for the production relation verifier.
provides:
  - Complete canonical Git, GitHub, and maintained-family evidence ledger anchored to one corrected committed base.
  - Ledger-only immutable publication whose sole parent, path, and blob relation are exact and history-preserving.
  - Executed authorized_bookkeeping verdict at the clean ledger task-commit HEAD with a fail-closed later-verifier handoff.
affects: [phase-138-verification, phase-139, phase-140, phase-141, repository-hygiene]
actuals:
  tokens: 20317
  tasks: 2
  commits: 5
tech-stack:
  added: []
  patterns: [explicit Git pathspec expansion, structured active-record lifecycle classification, immutable ledger-only publication]
key-files:
  created:
    - .planning/phases/138-baseline-inventory-evidence-taxonomy/138-16-SUMMARY.md
  modified:
    - scripts/maintainer/baseline_inventory.sh
    - test/support/lockspire/release_proof/package_assertions.ex
    - .planning/phases/138-baseline-inventory-evidence-taxonomy/baseline-inventory-2026-08-28.md
key-decisions:
  - "Enumerate every active-record suffix as an explicit Git pathspec because git ls-files does not expand brace alternatives."
  - "Classify current REVIEW and VERIFICATION authorities from exact frontmatter status plus document structure, never incidental prose."
  - "Treat only .planning/milestone.lock as workflow-owned local control state through an exact .git/info/exclude entry; every other untracked path remains blocking and the lock is absent from evidence."
patterns-established:
  - "Publication audit: pass full gates, regenerate from a committed base, compare all live sources independently, then commit only the canonical ledger."
  - "Lifecycle evidence: document kind, structural headings, and exact status jointly determine active or resolved taxonomy."
requirements-completed: [BASE-01, BASE-02, TRIAGE-01, TRIAGE-02, LOOSE-01]
coverage:
  - id: D1
    description: The canonical ledger contains complete current Git, GitHub, and maintained-family evidence with valid UTF-8/YAML and proposal-only dispositions.
    requirement: BASE-01
    verification:
      - kind: integration
        ref: test/lockspire/release/repository_hygiene_contract_test.exs
        status: pass
      - kind: other
        ref: independent Git, authenticated GraphQL, maintained-family, UTF-8, and YAML comparison before publication
        status: pass
    human_judgment: false
  - id: D2
    description: The replacement ledger is the only path in a one-parent commit whose parent equals evidence_base_sha and whose committed blob matches the audited artifact.
    requirement: BASE-02
    verification:
      - kind: other
        ref: git rev-list/diff-tree/hash-object immutable publication assertions at cf25db040cb034e665fbcffb0e8ef2db8c7bd8e4
        status: pass
    human_judgment: false
  - id: D3
    description: The production currentness command authorizes the exact ledger HEAD and discloses the complete zero-post-snapshot relation without mutating repository state.
    requirement: LOOSE-01
    verification:
      - kind: integration
        ref: bash scripts/maintainer/baseline_inventory.sh --verify-snapshot-relation .planning/phases/138-baseline-inventory-evidence-taxonomy/baseline-inventory-2026-08-28.md
        status: pass
    human_judgment: false
duration: 55min
completed: 2026-08-29
status: complete
---

# Phase 138 Plan 16: Complete Immutable Baseline Publication Summary

**A complete canonical evidence ledger now binds live Git, terminal GitHub queues, and structured maintained records to an exact ledger-only commit with an authorized production currentness relation.**

## Performance

- **Duration:** 55 min
- **Started:** 2026-08-29T00:52:54Z
- **Completed:** 2026-08-29T01:47:00Z
- **Tasks:** 2/2
- **Files modified:** 4

## Accomplishments

- Regenerated a valid UTF-8/YAML `status: complete` ledger from corrected base `94772b7acd9f5e54251f1b8c643cc740d3b5e454` after the focused 23-test suite, release-readiness suite, full `mix ci`, and API coverage gate passed.
- Independently matched 28 branch rows, 38 tags, 1 worktree, stable IDs, 6 open PRs, 0 open issues, terminal nested check counts `7, 6, 6, 6, 8, 8`, and both current maintained lifecycle authorities.
- Published the ledger alone in `cf25db040cb034e665fbcffb0e8ef2db8c7bd8e4`, preserving prior blob `d5cb25c02e03ebdefabc64016973c1c656de4b02` and committing audited blob `c7240521eb00f0370da65cb15690a8e409cab8c4`.
- Ran the production relation at the ledger task-commit HEAD and received `snapshot_relation: authorized_bookkeeping` with a clean working tree and no repository-state change.

## Task Commits

Task 1 required correctness fixes discovered by the independent publication audit, followed by the immutable ledger commit. Task 2 was intentionally read-only and is evidenced at that ledger HEAD.

1. **Task 1 fix: Enumerate maintained active records exactly** — `c6db9d90` (fix)
2. **Task 1 fix: Classify maintained lifecycle authorities** — `4e6bdb98` (fix)
3. **Task 1 verification correction: Format lifecycle fixture** — `f7e65cd8` (style)
4. **Task 1 verification correction: Keep lifecycle fixture phase-neutral** — `94772b7a` (test)
5. **Task 1: Publish complete baseline inventory** — `cf25db04` (docs; ledger-only)
6. **Task 2: Verify immutable relation** — no new commit (read-only at `cf25db04`)

## Files Created/Modified

- `scripts/maintainer/baseline_inventory.sh` — explicit active-record pathspec collection and structure/status lifecycle classification.
- `test/support/lockspire/release_proof/package_assertions.ex` — live discovery assertions and hermetic active-review/verification lifecycle proof.
- `.planning/phases/138-baseline-inventory-evidence-taxonomy/baseline-inventory-2026-08-28.md` — complete immutable canonical evidence snapshot.
- `.planning/phases/138-baseline-inventory-evidence-taxonomy/138-16-SUMMARY.md` — execution, publication, independent comparison, and relation record.

## Decisions Made

- Git brace syntax is not accepted as implicit pathspec expansion. Every REVIEW, AUDIT, VERIFICATION, UAT, HANDOFF, and CHECKPOINT suffix is passed explicitly so discovery is complete and testable.
- A current `issues_found` review and `gaps_found` verification remain active `fix-now` evidence until their normal lifecycle owners rewrite them. The collector inventories these authorities without pretending later review or verification output already exists.
- The orchestrator-created `.planning/milestone.lock` remained present and unmodified. An exact local `.git/info/exclude` rule hid only that named GSD control artifact from Git status; the collector ledger contains no lock reference, and any other untracked path would still fail the clean-base gate.

## Evidence Run

- `bash -n scripts/maintainer/baseline_inventory.sh` — passed.
- `mix test test/lockspire/release/repository_hygiene_contract_test.exs` — passed, 23 tests and 0 failures.
- `mix test test/lockspire/release_readiness_contract_test.exs` — passed, 2 tests and 0 failures.
- `mix ci` — passed: formatting, cycles, Credo, Sobelow, docs, package, and audits were green; 1,392 fast tests passed with 6 existing skips; 102 integration tests passed.
- `node /Users/jon/.codex/gsd-core/bin/gsd-tools.cjs check api-coverage.verify-pre ...` — passed with the phase's explicit no-product-integration declaration.
- Artifact parser audit — `status: complete`, valid UTF-8, parseable YAML, SHA-256 `59a02034a48cdba0a307ff9e00a66c4d2c33bdc27eade9b3694c237e967ad883`.
- Independent Git audit — HEAD/main `94772b7acd9f5e54251f1b8c643cc740d3b5e454`, origin/main `d82eaa1c74f396c5eb5dcfa393ddd5dd952acb92`, ahead 131, behind 0, with 28 branches, 38 tags, 1 worktree, and every stable ID matched.
- Independent authenticated GraphQL audit — 6 PRs and 0 issues, terminal outer pages, terminal complete nested contexts, counts `7, 6, 6, 6, 8, 8`, and exact head/base/draft/merge/review fields matched.
- Independent maintained audit — 2 tracked active records, exact REC IDs, REVIEW and VERIFICATION both represented as active `fix-now`, and zero ambiguous or unavailable receipts.

## Immutable Publication Relation

| Fact | Observed value |
| --- | --- |
| Evidence base / sole parent | `94772b7acd9f5e54251f1b8c643cc740d3b5e454` |
| Ledger task commit | `cf25db040cb034e665fbcffb0e8ef2db8c7bd8e4` |
| Changed path | `.planning/phases/138-baseline-inventory-evidence-taxonomy/baseline-inventory-2026-08-28.md` only |
| Prior ledger blob | `d5cb25c02e03ebdefabc64016973c1c656de4b02` |
| Committed ledger blob | `c7240521eb00f0370da65cb15690a8e409cab8c4` |
| Relation command exit | `0` |
| Relation row | `ledger_commit|cf25db040cb034e665fbcffb0e8ef2db8c7bd8e4|parent=94772b7acd9f5e54251f1b8c643cc740d3b5e454|verdict=authorized_bookkeeping` |
| Working-tree row | `working_tree|clean|authorized_bookkeeping|none` |
| Final verdict | `snapshot_relation: authorized_bookkeeping` |
| Side effects | refs, porcelain status, index tree, and ledger bytes unchanged |

The normal Phase 138 verifier must rerun the same production command after summary/review lifecycle writes and record every resulting row. This task-commit verdict does not pre-authorize those later writes.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Replaced a non-expanding active-record brace pathspec**

- **Found during:** Task 1 independent maintained comparison
- **Issue:** `git ls-files` treated the brace expression literally, so the collector falsely reported complete-zero while current REVIEW and VERIFICATION files existed.
- **Fix:** Added explicit suffix pathspecs and live-discovery regression assertions.
- **Files modified:** `scripts/maintainer/baseline_inventory.sh`, `test/support/lockspire/release_proof/package_assertions.ex`
- **Verification:** Focused 23-test suite, release-readiness, and full CI passed; final live collection found both records.
- **Committed in:** `c6db9d90`

**2. [Rule 1 - Bug] Added positive lifecycle classification for current active authorities**

- **Found during:** Task 1 independent maintained comparison after discovery was corrected
- **Issue:** Valid REVIEW `issues_found` and VERIFICATION `gaps_found` documents were discovered but fell through to ambiguous prose matching, correctly leaving publication partial.
- **Fix:** Classified exact frontmatter statuses only when the corresponding REVIEW/VERIFICATION structure matches, with a hermetic complete control and ambiguous near-miss protection.
- **Files modified:** `scripts/maintainer/baseline_inventory.sh`, `test/support/lockspire/release_proof/package_assertions.ex`
- **Verification:** Focused 23-test suite, proof-quality test 4/4, release-readiness 2/2, and full CI passed; final ledger contains both exact active rows.
- **Committed in:** `4e6bdb98`, with CI-only fixture corrections in `f7e65cd8` and `94772b7a`

---

**Total deviations:** 2 auto-fixed (2 Rule 1 bugs). **Impact on plan:** Both fixes were necessary to make maintained completeness truthful before the immutable publication; no product, protocol, or destructive repository scope was added.

## Issues Encountered

- The first corrected collector run exposed the lifecycle-classification gap before publication. The ledger remained uncommitted and `status: partial` until the fix and all gates passed.
- Full CI caught one formatting-only test change and two phase-numbered fake headings. Both fixture-only issues were corrected before establishing the final evidence base.
- Hex printed an expired local authentication warning, but all public dependency, audit, documentation, packaging, test, and integration operations completed successfully. GitHub CLI authentication remained valid for both collection and the independent GraphQL audit.

## Known Stubs

None. No goal-blocking stub, newly skipped test, or unrun verification was introduced. The 6 `mix ci` skips pre-existed this plan.

## Security and Boundary Notes

- T-138-63 is closed by a clean committed base, all green gates, complete live source receipts, valid encoding, and independent comparison before publication.
- T-138-64 is closed by the exact one-parent, one-path, committed-blob relation while prior ledger history remains addressable.
- T-138-65 is closed at the task-commit HEAD by the production `authorized_bookkeeping` verdict and unchanged before/after repository state.
- T-138-66 is closed by structured allowlists, parser checks, safe display values, and the absence of the named GSD lock or secret payloads from the ledger.
- No endpoint, authentication flow, schema, runtime module, public API, dependency, Git ref, worktree registration, release-owned file, or evidence disposition was mutated.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- The normal Phase 138 verifier can rerun the exact relation command at the later lifecycle HEAD and must fail closed on any unknown, missing, unavailable, destructive, or drifted row.
- Phases 139, 140, and 141 have a complete proposal-only inventory and the ledger's explicit mandatory revalidation boundaries.
- No execution blocker remains from Plan 138-16.

## Self-Check: PASSED

- Confirmed the canonical ledger, collector, package assertions, and this summary exist.
- Confirmed commits `c6db9d90`, `4e6bdb98`, `f7e65cd8`, `94772b7a`, and `cf25db04` exist and the ledger commit is the direct one-path child of its evidence base.
- Confirmed ledger blob `c7240521eb00f0370da65cb15690a8e409cab8c4`, prior blob `d5cb25c02e03ebdefabc64016973c1c656de4b02`, and production task-HEAD relation evidence.
- Confirmed `.planning/milestone.lock` remains present, locally excluded by its exact path only, uncommitted, and absent from the ledger.
- Confirmed no unexpected deletion, stub, newly skipped test, unrun verification, or unmodeled threat surface remains.

---
*Phase: 138-baseline-inventory-evidence-taxonomy*
*Completed: 2026-08-29*
