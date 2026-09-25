---
phase: 138-baseline-inventory-evidence-taxonomy
plan: "21"
subsystem: release-maintenance
tags: [evidence-ledger, github, snapshot-relation, immutable-publication, fail-closed]
requires:
  - phase: 138-20
    provides: Complete maintained evidence semantics, archive accounting, and portable encoding proof.
provides:
  - Complete canonical Git, GitHub, and maintained-evidence ledger anchored to a corrected clean base.
  - Ledger-only immutable publication with exact parent, path, and blob evidence.
  - Production currentness relation returning authorized_bookkeeping at the clean ledger commit.
affects: [phase-138-verification, phase-139, phase-140, phase-141]
estimate:
  tokens: 24000
  tasks: 2
actuals:
  tokens: 8861
  tasks: 2
  commits: 4
tech-stack:
  added: []
  patterns: [repository-bound fixtures, ledger-only immutable publication, independent live-source comparison]
key-files:
  created:
    - .planning/phases/138-baseline-inventory-evidence-taxonomy/138-21-SUMMARY.md
  modified:
    - .planning/phases/138-baseline-inventory-evidence-taxonomy/baseline-inventory-2026-08-28.md
    - test/support/lockspire/release_proof/package_assertions.ex
    - test/lockspire/release/repository_hygiene_contract_test.exs
    - mix.lock
key-decisions:
  - "Bind the refreshed canonical ledger to corrected evidence base c2313891 and preserve it as ledger-only commit 632af389."
  - "Treat repository identity as part of snapshot authority, including in working-tree transition fixtures."
  - "Keep every ledger disposition proposal-only and require production relation revalidation after lifecycle writes."
patterns-established:
  - "A complete snapshot is published only after focused, release-readiness, full-CI, API-coverage, and independent live-source gates pass."
  - "Post-publication authority is an explicit read-only relation over immutable anchors, external receipts, lifecycle semantics, and worktree state."
requirements-completed: [BASE-01, BASE-02, TRIAGE-01, TRIAGE-02, LOOSE-01]
coverage:
  - id: D1
    description: Immutable one-parent, one-path canonical ledger publication with fail-closed production currentness relation proof.
    requirement: BASE-01
    verification:
      - kind: integration
        ref: mix test test/lockspire/release/repository_hygiene_contract_test.exs#baseline snapshot relation resolves only the current immutable ledger publication
        status: pass
      - kind: integration
        ref: mix test test/lockspire/release/repository_hygiene_contract_test.exs#baseline snapshot relation closes relation integrity gaps
        status: pass
    human_judgment: false
duration: 41min active execution
completed: 2026-09-09
status: complete
---

# Phase 138 Plan 21: Canonical Ledger Publication and Relation Proof Summary

**A complete proposal-only Git, GitHub, and maintained-evidence ledger is immutably anchored to the corrected base and accepted by the production currentness relation.**

## Performance

- **Duration:** 41 minutes of active execution across the prerequisite checkpoint and resumed publication
- **Completed:** 2026-09-09
- **Tasks:** 2/2
- **Files changed by Plan 138-21 and prerequisite closure:** 4 implementation/evidence files plus this summary

## Accomplishments

- Recollected the no-scope canonical ledger from clean corrected evidence base `c23138910acb45e8cee1cfd1aacc059ccde7599d` after every required gate passed.
- Independently matched 29 branch refs and SHAs, 38 tag refs and SHAs, one worktree, seven authenticated open pull requests (`83`, `87`, `88`, `91`, `96`, `97`, `98`), zero open issues, maintained authorities, ordering, and unique stable IDs.
- Published the replacement as ledger-only commit `632af389569251a848f938fd853b12360a0fb12d`, with blob `fb5e8cb7b203db009de352055ab225c9bc3b8005` and sole parent equal to the evidence base.
- Proved the clean publication through the production relation command with exit zero and `snapshot_relation: authorized_bookkeeping`.
- Preserved the UTC observation boundary and explicit revalidation before Phases 139, 140, any Phase 140 mutation, and Phase 141 closure without executing a proposal.

## Task Commits

1. **Prerequisite correction: repository-bound relation fixture** — `058e81ca` (fix)
2. **Prerequisite closure: Mint security advisory remediation** — `9f81c7a6` (dependency)
3. **Prerequisite closure: stable relation timeout under parallel load** — `c2313891` (test)
4. **Task 1: refreshed canonical ledger-only publication** — `632af389` (docs)

Task 2 was read-only and produced the relation evidence recorded here; its durable output is this summary commit.

## Files Created/Modified

- `.planning/phases/138-baseline-inventory-evidence-taxonomy/baseline-inventory-2026-08-28.md` — complete canonical ledger with current receipts, stable rows, fingerprints, and bounded revalidation instructions.
- `test/support/lockspire/release_proof/package_assertions.ex` — keeps the working-tree relation fixture in the original repository identity.
- `test/lockspire/release/repository_hygiene_contract_test.exs` — allows the relation contract sufficient time under parallel full-suite load.
- `mix.lock` — resolves the blocking Mint advisories through Mint 1.10.0.
- `.planning/phases/138-baseline-inventory-evidence-taxonomy/138-21-SUMMARY.md` — immutable anchors, gates, independent comparisons, relation result, and no-silent-drop audit.

## Decisions Made

- Repository identity is authoritative: a cloned ledger cannot be treated as the same snapshot merely because its Git history and blob match.
- The publication commit remains a single-parent, single-path child of the exact corrected evidence base; summary and lifecycle tracking occur only afterward.
- The full ledger remains evidence and proposal vocabulary only. No branch, tag, worktree, PR, issue, maintained record, release file, or source history was mutated by collection.

## Verification

### Pre-publication gates

- `bash -n scripts/maintainer/baseline_inventory.sh` — passed.
- `mix test test/lockspire/release/repository_hygiene_contract_test.exs` — passed, 27 tests and 0 failures.
- `mix test test/lockspire/release_readiness_contract_test.exs` — passed, 2 tests and 0 failures.
- Fresh full `mix ci` after prerequisite closure — passed, 1,396 tests with 0 failures and 6 skipped, plus 102 integration tests with 0 failures.
- `api-coverage.verify-pre` — passed with 8 capabilities integrated and 0 opt-outs.

### Independent live comparison

- Exact `git for-each-ref` comparison: 29/29 branch rows and 38/38 tag rows matched names and full SHAs.
- Exact `git worktree list --porcelain` comparison: 1/1 worktree path and full SHA matched.
- Independent authenticated GitHub observation: 7/7 open PR numbers matched in numeric order; the issue query completed with zero results matching the ledger.
- The ledger is valid UTF-8, has one closed frontmatter block, reports `status: complete`, contains no duplicate evidence IDs, and includes current `138-REVIEW.md` and `138-VERIFICATION.md` authorities.
- Source fingerprints: Git `dbb431c3cd3588eea534fbba518d9cb93131e99f`; GitHub `e4a0d93da8dfded613c99066c2ee3b0af081be38`; maintained `d9cef9bbcee3bdef1245567583f452fcf69169db`.

### Immutable relation

Command:

```bash
bash scripts/maintainer/baseline_inventory.sh --verify-snapshot-relation .planning/phases/138-baseline-inventory-evidence-taxonomy/baseline-inventory-2026-08-28.md
```

Exit: `0`

```text
ledger_commit|632af389569251a848f938fd853b12360a0fb12d|parent=c23138910acb45e8cee1cfd1aacc059ccde7599d|verdict=authorized_bookkeeping
working_tree|clean|authorized_bookkeeping|none
snapshot_relation: authorized_bookkeeping
```

There were zero post-ledger commits at this proof point. The committed ledger blob remained `fb5e8cb7b203db009de352055ab225c9bc3b8005` before and after verification.

### No-silent-drop audit

- All eleven verification gaps map one-to-one to Plans 138-17 through 138-21: current ledger (21); GitHub completeness and contradictory duplicates (17); publication concurrency and stable source snapshot (18); topology, bookkeeping semantics, and failed live status (19); maintained hostile fields, complete-zero markers, and YAML/UTF-8 (20).
- All five requirement IDs are evidenced: BASE-01, BASE-02, TRIAGE-01, TRIAGE-02, and LOOSE-01.
- Fourteen spec-less candidates equal fourteen explicit dispositions: BASE-01 unclassified; BASE-02 adjacency, empty, ordering, idempotency, and concurrency; TRIAGE-01 adjacency, empty, ordering, and concurrency; TRIAGE-02 adjacency, empty, and ordering; LOOSE-01 unclassified.
- Descriptor-less bespoke prohibitions remain `flagged-unverified`; no descriptor was fabricated, no candidate was omitted or dismissed, and canon security concerns remain owned by the threat model.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Corrected a repository-identity-invalid relation fixture**

- **Found during:** Task 1 precondition, full focused contract
- **Issue:** The working-tree transition fixture cloned a repository-bound ledger to a different root and incorrectly expected authorization.
- **Fix:** Exercise the working-tree projection at the original snapshot repository and exact ledger identity.
- **Files modified:** `test/support/lockspire/release_proof/package_assertions.ex`
- **Commit:** `058e81ca`

**2. [Rule 3 - Blocking] Closed newly surfaced dependency advisories**

- **Found during:** Task 1 precondition, `mix ci`
- **Issue:** Mint 1.9.3 acquired one high and one medium security advisory, causing the mandatory audit gate to fail.
- **Fix:** Mint was upgraded to 1.10.0 before evidence collection.
- **Files modified:** `mix.lock`
- **Commit:** `9f81c7a6`

**3. [Rule 3 - Blocking] Stabilized the relation contract under parallel load**

- **Found during:** Full CI prerequisite closure
- **Issue:** The production-process relation fixture exceeded its prior timeout only under the complete parallel suite.
- **Fix:** Applied a bounded timeout adjustment without weakening assertions.
- **Files modified:** `test/lockspire/release/repository_hygiene_contract_test.exs`
- **Commit:** `c2313891`

## Issues Encountered

- The machine-local `.tool-versions` contains only the Node.js launcher version. Execution selected installed Elixir 1.19.5 / OTP 28.4.1 through process-local ASDF variables; `.tool-versions` remained untouched and checkout-locally excluded.
- The first full gate exposed the repository-bound fixture mismatch, then `mix ci` exposed fresh Mint advisories. Both were resolved and all gates rerun before collection.

## Known Stubs

None. TODO/FIXME text in collector and fixture files is maintained-evidence test input, not an implementation stub. No test was newly skipped and no verification command was left unrun.

## Security and Boundary Notes

- T-138-84 is closed by clean-base gates, authenticated complete collection, stable snapshot rechecks, and independent live comparison.
- T-138-85 is closed by the exact `c2313891` → `632af389` one-parent relation, single changed ledger path, and unchanged committed blob.
- T-138-86 is closed by the production `authorized_bookkeeping` result over strict schema, receipts, topology, identity, and worktree state.
- T-138-87 is closed by allowlisted evidence fields, redaction, valid UTF-8/YAML-compatible frontmatter, and proposal-only rendering.
- No endpoint, authentication path, schema, runtime/public API, disposition mutation, source-history rewrite, or release-owned file mutation was introduced by ledger collection.

## User Setup Required

None.

## Next Phase Readiness

- Normal Phase 138 verification can rerun the production relation after this summary and later lifecycle writes.
- Any `refresh_required`, unavailable, ambiguous, destructive, omitted, or source-drift result must route back to gap closure rather than being reinterpreted as current.
- Phases 139, 140, and 141 have one current immutable proposal-only baseline and explicit revalidation boundaries.

## Self-Check: PASSED

- Confirmed the ledger, prerequisite files, and this summary exist.
- Confirmed prerequisite commits `058e81ca`, `9f81c7a6`, `c2313891` and ledger publication commit `632af389` exist.
- Confirmed `632af389` has exactly one parent, that parent is `c2313891`, and its only changed path is the canonical ledger.
- Confirmed the relation exited zero with `snapshot_relation: authorized_bookkeeping`, the ledger blob stayed unchanged, and the working tree was clean at the proof point.
- Confirmed the eleven-gap mapping, fourteen-candidate equality, all five requirement IDs, current authorities, and proposal-only boundaries are present.

---
*Phase: 138-baseline-inventory-evidence-taxonomy*
*Completed: 2026-09-09*
