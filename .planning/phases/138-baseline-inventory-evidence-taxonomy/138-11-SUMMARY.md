---
phase: 138-baseline-inventory-evidence-taxonomy
plan: "11"
subsystem: release-maintenance
tags: [git, github, immutable-snapshot, evidence-ledger, semantic-currentness]
requires:
  - phase: 138-10
    provides: Source-stable collection, immutable publication resolution, and the fail-closed post-snapshot classifier.
provides:
  - Canonical complete Git, GitHub, and maintained-evidence ledger bounded to an exact UTC collection window and committed evidence base.
  - Ledger-only immutable snapshot commit whose sole parent equals evidence_base_sha and whose committed blob is unchanged.
  - Executed read-only currentness proof with a complete zero-row post-snapshot table and authorized_bookkeeping verdict.
affects: [phase-138-verification, phase-139, phase-140, phase-141, release-readiness]
actuals:
  tokens: 5990
  tasks: 1
  commits: 1
tech-stack:
  added: []
  patterns: [ledger-only snapshot publication, bounded-as-of evidence, semantic lifecycle classification]
key-files:
  created: [".planning/phases/138-baseline-inventory-evidence-taxonomy/138-11-SUMMARY.md"]
  modified: [".planning/phases/138-baseline-inventory-evidence-taxonomy/baseline-inventory-2026-08-28.md"]
key-decisions:
  - "Anchor the canonical ledger to the clean pre-collection commit and publish it as that commit's ledger-only child so the evidence relation is self-reference-safe and immutable."
  - "Bound currentness to the recorded UTC evidence window and require the production semantic classifier after every later lifecycle write; no later commit is pre-authorized."
  - "Keep every inventory disposition proposal-only and require the named D-08 revalidation and maintainer authority before any action."
patterns-established:
  - "Publication relation: evidence_base_sha equals the ledger commit's sole parent, the commit changes only the canonical ledger, and the committed ledger blob remains unchanged."
  - "Currentness relation: disclose every first-parent post-snapshot commit and fail closed on unknown semantics, source drift, dirty state, or ambiguous topology."
requirements-completed: [BASE-01, BASE-02, TRIAGE-01, TRIAGE-02, LOOSE-01]
coverage:
  - id: D1
    description: The canonical ledger contains complete live Git, GitHub, and maintained receipts with exact immutable identifiers, normalized fingerprints, safe taxonomy, and proposal-only authority.
    requirement: BASE-01
    verification:
      - kind: manual_procedural
        ref: fresh read-only Git, authenticated GraphQL, and maintained-family comparison against baseline-inventory-2026-08-28.md
        status: pass
    human_judgment: false
  - id: D2
    description: The immutable publication has exactly one parent equal to evidence_base_sha, changes only the canonical ledger, and preserves the committed ledger blob.
    requirement: BASE-02
    verification:
      - kind: integration
        ref: bash scripts/maintainer/baseline_inventory.sh --verify-snapshot-relation .planning/phases/138-baseline-inventory-evidence-taxonomy/baseline-inventory-2026-08-28.md
        status: pass
    human_judgment: false
  - id: D3
    description: The production classifier reports authorized_bookkeeping and a complete zero-or-more post-snapshot table while remaining read-only and failing closed on hostile near misses.
    requirement: LOOSE-01
    verification:
      - kind: integration
        ref: test/lockspire/release/repository_hygiene_contract_test.exs#snapshot relation and lifecycle classification contracts
        status: pass
    human_judgment: false
duration: 18min
completed: 2026-08-28
status: complete
---

# Phase 138 Plan 11: Immutable Baseline Snapshot Publication Summary

**A complete live Git, GitHub, and maintained-evidence ledger published as an immutable ledger-only child of its exact evidence base, with executable bounded-currentness proof.**

## Performance

- **Duration:** 18 min
- **Started:** 2026-08-28T21:31:52Z
- **Completed:** 2026-08-28T21:49:52Z
- **Tasks:** 1/1
- **Files modified:** 1

## Accomplishments

- Regenerated the canonical ledger from clean committed evidence base `603b222ca9bfa340ea0321b2c71d4f9a9ae2b0b2` during the UTC window `2026-08-28T21:38:12Z`–`2026-08-28T21:38:40Z`, with complete Git, GitHub, and maintained-family receipts.
- Independently matched all 28 branch, 38 tag, and 1 worktree identities; local-main divergence of 92 ahead and 0 behind; 6 open pull requests and 0 open issues across complete single-page GraphQL receipts; and every maintained-family count, stable record identity, archive summary, tracked marker, taxonomy, and proposal-only execution field.
- Published commit `ab83aea8ac904ff8a2ea36ae2e665dfd6437ad61` as the direct ledger-only child of its recorded evidence base, with committed ledger blob `d5cb25c02e03ebdefabc64016973c1c656de4b02`.
- Ran the production currentness classifier from the clean task-commit HEAD; it proved the exact anchor relation, unchanged blob, current source receipts, clean worktree, complete zero-row post-snapshot table, and `authorized_bookkeeping` verdict.

## Task Commits

1. **Task 1: Regenerate the canonical ledger from a fixed corrected evidence base** — `ab83aea8` (docs)

## Files Created/Modified

- `.planning/phases/138-baseline-inventory-evidence-taxonomy/baseline-inventory-2026-08-28.md` — complete immutable evidence ledger with exact UTC bounds, source fingerprints, proposal rows, immutable anchor, and bounded currentness instructions.
- `.planning/phases/138-baseline-inventory-evidence-taxonomy/138-11-SUMMARY.md` — execution evidence and exact publication/currentness result.

## Decisions Made

- The clean pre-collection HEAD is the evidence base; successful publication is its single-parent ledger-only child, not a claim that repository HEAD can never move again.
- Later repository movement is valid only when the production classifier enumerates and semantically authorizes every observed row. Missing, ambiguous, relevant, or source-drifting movement requires recollection from a new clean base.
- All ledger dispositions remain `executed: no` proposals. Publication neither changes product/release state nor grants cleanup authority.

## Verification

### Fresh pre-publication gates

- `bash -n scripts/maintainer/baseline_inventory.sh` — passed.
- `mix test test/lockspire/release/repository_hygiene_contract_test.exs` — passed, 18 tests and 0 failures.
- `mix test test/lockspire/release_readiness_contract_test.exs` — passed, 2 tests and 0 failures.
- `mix ci` — passed end to end: 13 architecture tests, 1,387 unit/contract tests (6 skipped, 286 excluded), and 102 integration tests (33 excluded), all with 0 failures; formatting, Credo, Sobelow, docs, dependency audit, package build, and migrations also completed successfully.
- `node /Users/jon/.codex/gsd-core/bin/gsd-tools.cjs check api-coverage.verify-pre .planning/phases/138-baseline-inventory-evidence-taxonomy` — passed; `COVERAGE.md` declares no external product API integration.

### Live receipt comparison

- Git: 28 branches, 38 tags, 1 worktree, and every full SHA/stable ID matched; local `main` was 92 ahead and 0 behind `origin/main`.
- GitHub: authenticated receipt completed with 1 pull-request page/6 items and 1 issue page/0 items; every PR number, head SHA, and base SHA matched.
- Maintained evidence: family counts matched for todos 0, debug 1, quick 5, threads 2, seeds 3, active records 0, milestones 835, continue 0, roadmap/state/project/release-train/development-train 1 each, and conformance 0. Ten selected maintained records, two tracked-marker files, and fifteen unique rendered REC rows matched the ledger.
- All six top-level source receipts were complete; every maintained family was `complete`, `complete-zero`, or `archive-summary`; taxonomy and every `executed` field remained safe and proposal-only.

### Immutable anchor and post-snapshot currentness

Exact command:

```console
bash scripts/maintainer/baseline_inventory.sh --verify-snapshot-relation .planning/phases/138-baseline-inventory-evidence-taxonomy/baseline-inventory-2026-08-28.md
```

- Exit status: `0`.
- Ledger commit: `ab83aea8ac904ff8a2ea36ae2e665dfd6437ad61`.
- Sole parent and `evidence_base_sha`: `603b222ca9bfa340ea0321b2c71d4f9a9ae2b0b2`.
- Sole changed path: `.planning/phases/138-baseline-inventory-evidence-taxonomy/baseline-inventory-2026-08-28.md`.
- Committed/current ledger blob: `d5cb25c02e03ebdefabc64016973c1c656de4b02`.
- Classifier output: `ledger_commit|ab83aea8ac904ff8a2ea36ae2e665dfd6437ad61|parent=603b222ca9bfa340ea0321b2c71d4f9a9ae2b0b2|verdict=authorized_bookkeeping` and `snapshot_relation: authorized_bookkeeping`.
- Complete post-snapshot table at the task-commit HEAD: zero rows. This is the valid complete-zero case because the classifier ran at the ledger commit before summary creation.
- Final plan verification remained clean and preserved `/tmp/lockspire-milestone-lock.mfrfY0/milestone.lock`.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- An independent maintained-record audit initially used zsh's special `path` variable as a loop name, which removed command lookup for the remainder of that disposable shell. The repository was unchanged; the audit was rerun with a neutral variable name and all maintained counts, identities, taxonomy, receipts, and integrity assertions passed.
- `mix ci` reported an expired local Hex authentication session, then successfully used public dependency metadata and completed the dependency audit, package build, and all remaining gates with exit status 0. No authentication-gated operation was required.
- The first summary draft repeated the reserved pending-marker token names in prose, so the production classifier correctly rejected that lifecycle projection. The summary was reworded to describe the bounded marker receipt without reproducing those tokens before sequential tracking continued.

## Known Stubs

None. The ledger's reserved pending-marker wording identifies the bounded maintained-marker receipt and does not represent unfinished product behavior.

## Security and Boundary Notes

- T-138-42 is closed by clean-base aggregate gates, complete receipts, immediate source rechecks, and independent live comparisons.
- T-138-43 is closed by the exact single-parent ledger-only ancestry and unchanged committed blob.
- T-138-44 is closed by the read-only semantic classifier and complete disclosed table; later writes require rerunning the same classifier.
- T-138-45 is closed by sanitized receipt rendering, redacted maintained evidence, final byte inspection, and credential/control-character checks.
- T-138-46 remains proposal-only: no disposition, source/test/plan mutation, runtime endpoint, auth path, schema boundary, or release-owned state change occurred.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

The normal Phase 138 verifier can rerun the exact production classifier after summary and review lifecycle writes, enumerate every then-present authorized commit in `138-VERIFICATION.md`, and fail closed on `refresh_required`. Phases 139, 140, and 141 have one exact bounded evidence snapshot and explicit D-08 revalidation points; no cleanup or release action has been pre-authorized.

## Self-Check: PASSED

- Confirmed the canonical ledger and this summary exist.
- Confirmed task commit `ab83aea8ac904ff8a2ea36ae2e665dfd6437ad61` exists and has exactly one parent, matching `evidence_base_sha`.
- Confirmed the task commit changes only the canonical ledger and the current ledger blob equals its committed blob.
- Re-ran the exact plan-level classifier, focused gates, full `mix ci`, and API-coverage command from the clean task-commit HEAD.
- Confirmed the final plan verification reported `authorized_bookkeeping`, complete-zero post-snapshot rows, a clean worktree, and the preserved external lock backup.

---
*Phase: 138-baseline-inventory-evidence-taxonomy*
*Completed: 2026-08-28*
