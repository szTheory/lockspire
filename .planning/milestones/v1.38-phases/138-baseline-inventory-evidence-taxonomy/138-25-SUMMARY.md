---
phase: 138-baseline-inventory-evidence-taxonomy
plan: "25"
subsystem: release-maintenance
tags: [evidence-ledger, git, github, lifecycle-taxonomy, immutable-snapshot]
requires:
  - phase: 138-24
    provides: Exact GitHub object identity, structural active lifecycle authority, and shared structured archive-action classification.
provides:
  - A complete proposal-only canonical ledger recollected from final corrected evidence base 9d70b89f.
  - An immutable ledger-only publication commit with independently matched Git, GitHub, and maintained receipts.
  - A production currentness relation that semantically authorizes exact GSD plan-closeout metadata while failing closed on hostile near misses.
affects: [phase-139, phase-140, phase-141, repository-reconciliation]
actuals:
  tokens: 9963
  tasks: 2
  commits: 8
tech-stack:
  added: []
  patterns: [anchored archive authority, semantic GSD closeout validation, clean-base evidence capture, ledger-only immutable publication, fail-closed relation proof]
key-files:
  created:
    - .planning/phases/138-baseline-inventory-evidence-taxonomy/138-25-SUMMARY.md
  modified:
    - scripts/maintainer/baseline_inventory.sh
    - test/lockspire/release/repository_hygiene_contract_test.exs
    - test/support/lockspire/release_proof/package_assertions.ex
    - .planning/phases/138-baseline-inventory-evidence-taxonomy/baseline-inventory-2026-08-28.md
key-decisions:
  - "A free-form body mention of fix-now is not archive action authority; the fix-now marker family is anchored while status, outcome, disposition, and dedicated action headings remain structural authorities."
  - "An exact four-path GSD plan-closeout commit is authorized only when subject, identity, summary, requirements, coverage, self-check, and monotonic roadmap/state transitions all agree."
  - "The final corrected clean evidence base is 9d70b89fa3c2db65cbb0681dcdfc1f3b747dd3af and its ledger-only child is c5b25c4456e9da6d7aca3919caa1e0ecc1b3c642."
  - "Every ledger disposition remains proposal-only; later phases must rerun the production relation and revalidate the exact target before action."
patterns-established:
  - "Incidental archive prose cannot acquire structured action authority merely by containing disposition vocabulary."
  - "Publication follows source/test commits, full green prerequisites, stable double collection, ledger-only commit, then relation proof and lifecycle bookkeeping."
requirements-completed: [BASE-01, BASE-02, TRIAGE-01, TRIAGE-02, LOOSE-01]
coverage:
  - id: D1
    description: Complete current Git baseline and exact branch, tag, and worktree inventory are bound to one clean committed evidence base.
    requirement: BASE-01
    verification:
      - kind: integration
        ref: "production collection plus independent live Git equality; 29 branches, 38 tags, 1 worktree"
        status: pass
      - kind: integration
        ref: "baseline_inventory.sh --verify-snapshot-relation at ledger publication and final metadata HEAD; authorized_bookkeeping"
        status: pass
    human_judgment: false
  - id: D2
    description: Every current branch, tag, and worktree has a stable proposal-only row with exact object-format identity.
    requirement: BASE-02
    verification:
      - kind: integration
        ref: "independent for-each-ref/worktree comparison and full repository-hygiene contract (30 tests)"
        status: pass
    human_judgment: false
  - id: D3
    description: All seven open pull requests have exact 40-character head/base identities and nested checks bound to their outer head.
    requirement: TRIAGE-01
    verification:
      - kind: integration
        ref: "authenticated gh outer equality plus nested GraphQL head equality"
        status: pass
      - kind: integration
        ref: "phase138_review_gap contract; 1 test, 0 failures"
        status: pass
    human_judgment: false
  - id: D4
    description: The independently authenticated open-issue namespace is complete-zero without implying repository health.
    requirement: TRIAGE-02
    verification:
      - kind: integration
        ref: "authenticated gh issue observation; 0 open issues and terminal pagination"
        status: pass
    human_judgment: false
  - id: D5
    description: Maintained sources include current structural review/verification rows while terminal archives with incidental fix-now prose remain summarized.
    requirement: LOOSE-01
    verification:
      - kind: integration
        ref: "phase138_review_gap and full repository-hygiene contracts"
        status: pass
      - kind: integration
        ref: "independent maintained path/action scan; 835 milestone archives, 2 active lifecycle rows, 0 structured archive action lines"
        status: pass
    human_judgment: false
duration: 2h55m
completed: 2026-09-10
status: complete
---

# Phase 138 Plan 25: Corrected Immutable Baseline Inventory Summary

**A complete proposal-only Git, GitHub, and maintained-source ledger is immutably published from the corrected clean base with an authorized production currentness relation.**

## Performance

- **Duration:** 2 hours 55 minutes
- **Started:** 2026-09-10T01:42:00Z
- **Completed:** 2026-09-10T04:37:00Z
- **Tasks:** 2/2
- **Files modified:** 4 production/test/ledger files plus this summary

## Accomplishments

- Added a red/green process regression proving that a terminal archived record containing incidental `fix-now` body prose is summarized rather than treated as structured action authority.
- Added a second red/green regression that recognizes the exact valid GSD plan-closeout metadata shape only after semantic validation of its summary, requirements, coverage, self-check, and monotonic tracking transitions; hostile near misses remain `refresh_required`.
- Recollected complete current evidence from final clean committed base `9d70b89fa3c2db65cbb0681dcdfc1f3b747dd3af`, with stable fingerprints across a second fresh collection.
- Published ledger-only commit `c5b25c4456e9da6d7aca3919caa1e0ecc1b3c642` as the direct child of that evidence base and proved its unchanged blob and `authorized_bookkeeping` relation.
- Preserved proposal-only authority, exact identifiers, safe rendering, redaction, deterministic ordering, and fail-closed ambiguity handling.

## Task Commits

1. **Approved regression RED: incidental fix-now archive prose** — `87778945` (test)
2. **Approved regression GREEN: anchored fix-now archive authority** — `a8fe1973` (fix)
3. **Prerequisite correction: phase-neutral fixture heading** — `0d777d1a` (fix)
4. **Task 1: recollect and publish corrected ledger relation** — `15a556a9` (docs; ledger-only publication)
5. **Approved relation regression RED: exact GSD closeout and hostile near misses** — `b20ea464` (test)
6. **Approved relation regression GREEN: semantic GSD plan-closeout classifier** — `15ed0b5f` (fix)
7. **Prerequisite correction: phase-neutral closeout fixtures** — `9d70b89f` (fix)
8. **Task 1 republication: final corrected ledger relation** — `c5b25c44` (docs; ledger-only publication)

Task 2 was read-only verification; its durable evidence is this summary and the production relation output below.

## Files Created/Modified

- `scripts/maintainer/baseline_inventory.sh` — narrows the `fix-now` action-marker family to anchored forms and recognizes only the exact semantically valid GSD closeout transition, rejecting ambiguity and unrelated mutations.
- `test/lockspire/release/repository_hygiene_contract_test.exs` — adds focused process coverage for the production closeout relation.
- `test/support/lockspire/release_proof/package_assertions.ex` — models the real terminal archive shape plus a valid plan closeout and hostile path, identity, summary, requirement, progress, state, roadmap, subject, and author near misses.
- `.planning/phases/138-baseline-inventory-evidence-taxonomy/baseline-inventory-2026-08-28.md` — complete canonical ledger bound to the corrected evidence base.
- `.planning/phases/138-baseline-inventory-evidence-taxonomy/138-25-SUMMARY.md` — immutable anchors, prerequisite results, independent equality checks, coverage, and relation handoff.

## Verification

All Mix commands used Elixir 1.19.5 / OTP 28.4.1 through process-local ASDF variables.

| Gate | Result |
| --- | --- |
| `bash -n scripts/maintainer/baseline_inventory.sh` | exit 0 |
| focused `phase138_review_gap` contract | 1 test, 0 failures, 28 excluded |
| focused `phase138_relation_gap` contracts | 2 tests, 0 failures, 28 excluded |
| full repository-hygiene contract | 30 tests, 0 failures |
| release-readiness contract | 2 tests, 0 failures |
| `mix ci` | exit 0; all static, audit, package, migration, main-suite, and integration gates passed; integration suite 102 tests, 0 failures |
| API coverage pre-gate | `block: false`; 8/8 capabilities integrated |
| production collection | exit 0; overall and every source receipt complete |
| independent source equality | pass; exact Git rows, GitHub identities, nested heads, issues, maintained counts, ordering, and stable IDs |
| second fresh collection | identical evidence base, local/remote refs, and all three source fingerprints |
| production relation | exit 0; `snapshot_relation: authorized_bookkeeping` |

The Hex client emitted an expired optional user-session warning during dependency resolution, but public dependency resolution and every CI gate completed successfully; GitHub authentication remained current and was used for the live evidence collection.

## Immutable Evidence Anchors

| Anchor | Value |
| --- | --- |
| Original approved checkpoint base | `d1029e915732dffa27fbe7e079edced3834d6d08` |
| Prior corrected `evidence_base_sha` / local `main` | `0d777d1ad098b45743c9a97b101db27e23ab389c` |
| Final corrected `evidence_base_sha` / local `main` | `9d70b89fa3c2db65cbb0681dcdfc1f3b747dd3af` |
| Refreshed `origin/main` | `d82eaa1c74f396c5eb5dcfa393ddd5dd952acb92` |
| Prior ledger publication commit | `15a556a9b897b611579cf933d84af19078277b68` |
| Final ledger publication commit | `c5b25c4456e9da6d7aca3919caa1e0ecc1b3c642` |
| Publication sole parent | `9d70b89fa3c2db65cbb0681dcdfc1f3b747dd3af` |
| Publication changed path | `.planning/phases/138-baseline-inventory-evidence-taxonomy/baseline-inventory-2026-08-28.md` |
| Committed ledger blob | `f31917cc7c3b98335ab4e9f30bf6137a18f3a22e` |
| Git receipt fingerprint | `2834680ce6c13408b61725e2dd551e81718b1392` |
| GitHub receipt fingerprint | `e4a0d93da8dfded613c99066c2ee3b0af081be38` |
| Maintained receipt fingerprint | `d9cef9bbcee3bdef1245567583f452fcf69169db` |

Production relation output at the publication commit:

```text
ledger_commit|c5b25c4456e9da6d7aca3919caa1e0ecc1b3c642|parent=9d70b89fa3c2db65cbb0681dcdfc1f3b747dd3af|verdict=authorized_bookkeeping
working_tree|clean|authorized_bookkeeping|none
snapshot_relation: authorized_bookkeeping
```

## Independent Source Equality

- Git: 29 branch rows, 38 tag rows, and 1 worktree row exactly equal live canonical subjects and OIDs; the repository uses 40-character SHA-1 objects.
- GitHub: 7 open PR rows and 0 open issues equal fresh authenticated observations. All 14 PR head/base OIDs are exactly 40 hexadecimal characters; every latest nested commit OID equals its outer `headRefOid`; all seven current PR proposals are `needs-work`.
- Maintained sources: selectors observed 2 debug, 5 quick, 2 thread, 3 seed, 2 active-record, and 835 milestone paths. The current Phase 138 REVIEW and VERIFICATION each appear once as stable active/fix-now rows. No archive contains an anchored/structural action line, so archive containers remain summarized.
- Identity and encoding: all 92 rendered evidence IDs are unique; no invalid-width GitHub OID exists; UTF-8 validation and JSON-compatible strict frontmatter scalar parsing passed; no credential pattern was rendered.
- Stability: the second fresh collection reproduced `9d70b89f`, `d82eaa1c`, and all three fingerprints exactly.

## Gap Outcomes

| Prior gap | Current outcome |
| --- | --- |
| Canonical inventory stale at HEAD | Closed by fresh complete collection at `9d70b89f`, ledger-only child `c5b25c44`, and production `authorized_bookkeeping` proof. |
| Impossible 41–63-character PR base OIDs | Closed by Plan 138-24 exact predicate regressions plus live equality showing every head/base OID is exactly 40 hexadecimal characters. |
| Incidental terminal-proof wording can omit active records | Closed by Plan 138-24 structural-first regressions and live equality showing both current `issues_found`/`gaps_found` records once as active/fix-now. |
| Archive action markers lose to unrelated prose | Closed by the Plan 138-24 marker matrix and this plan's additional terminal-archive regression: incidental `fix-now` body prose no longer becomes action authority. |
| Valid GSD plan closeout appears as unknown bookkeeping | Closed by exact four-path semantic validation plus hostile near-miss regressions; the former 138-25 closeout shape is authorized without broadening arbitrary planning writes. |

## Requirement and Decision Coverage

- **BASE-01:** complete fetch, clean working-tree, local/main/origin identities, divergence, and production relation evidence.
- **BASE-02:** exact live equality for every branch, tag, and worktree with stable proposal-only rows.
- **TRIAGE-01:** authenticated exact outer PR identities, exact nested-head coherence, current state/check observations, and fail-closed malformed-ID regressions.
- **TRIAGE-02:** independently authenticated explicit complete-zero issue evidence without empty-queue health semantics.
- **LOOSE-01:** complete allowlisted maintained receipts, structural active lifecycle rows, archive summaries, anchored action authority, and visible ambiguity backstops.

Decision coverage is **24/24**: D-01 through D-24 remain implemented or regression-enforced across canonical Markdown ownership, provenance/completeness, fetch-only mutation, safe structured interfaces, redaction, exact taxonomy/fields, proposal-only authority, maintained-family/archive boundaries, stable deduplication, accessible output, calm microcopy, and focused executable contracts.

## No-Silent-Drop Audit

| Candidate | Explicit current disposition |
| --- | --- |
| BASE-01 unclassified | Unresolved backstop: any fetch, identity, status, divergence, or relation uncertainty blocks completeness. |
| BASE-02 adjacency | Exact object-format and subject/OID equality distinguish malformed rows from valid siblings. |
| BASE-02 empty | Complete-zero is accepted only after a successful, valid source observation. |
| BASE-02 ordering | Independent comparison confirms deterministic Git row order. |
| BASE-02 idempotency | Stable IDs and repeat collection reproduce the same three source fingerprints. |
| BASE-02 concurrency | Lock-first replacement and immediate source-stability checks remain enforced. |
| TRIAGE-01 adjacency | Exact 40/64 identities and exact outer/nested head equality bind each PR. |
| TRIAGE-01 empty | Authenticated terminal-zero remains explicit and does not imply health. |
| TRIAGE-01 ordering | Independent comparison confirms numeric PR order. |
| TRIAGE-01 concurrency | Exact nested-head comparison detects movement between outer and nested observations. |
| TRIAGE-02 adjacency | Issue identity/duplicate agreement remains independent of the PR namespace. |
| TRIAGE-02 empty | Authenticated terminal issue pagination produced explicit complete-zero evidence. |
| TRIAGE-02 ordering | Numeric issue ordering remains enforced; the current result is an authenticated empty set. |
| LOOSE-01 unclassified | Unresolved backstop: unreadable, invalid, or conflicting maintained evidence forces partial/ambiguous status. |

No-silent-drop equality: **14 surfaced candidates = 12 explicit acceptance/backstop dispositions + 2 flagged unresolved assumptions; none omitted or dismissed.**

## Prohibition Recall Audit

All four descriptor-less prohibitions remain explicitly `flagged-unverified`; no synthetic verifier descriptor was invented:

1. Collector observations and proposals grant no authority to merge, close, delete, prune, or rewrite.
2. Republication preserves all prior immutable ledger history and does not amend or destroy earlier evidence.
3. The refreshed ledger and diagnostics expose no secrets, credentials, uncontrolled bodies, raw logs, or environment values.
4. Partial, ambiguous, malformed, stale, or unavailable evidence cannot be presented as complete, clean, merge-ready, resolved, or historical authority.

Executable contracts, independent live checks, the ledger-only diff, redaction scan, and fail-closed relation supply the current safety evidence; canon security/compliance remains owned by the security workflow.

## Decisions Made

- Anchored `fix-now` lines, optionally expressed as a list marker, remain an explicit action-marker family; prose merely discussing the phrase does not.
- Structural `status`/`outcome`/`disposition` action values and dedicated action headings are unchanged and retain precedence over incidental downgrade prose.
- The Phase 138 canonical ledger is evidence capture only. Phase 139 reconciles truth, Phase 140 owns authorized actions, and Phase 141 owns exact-SHA closure.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Prevented incidental `fix-now` prose from acquiring archive action authority**

- **Found during:** Task 1 production collection after the original clean prerequisites.
- **Issue:** A terminal archived verification with `status: passed` contained “Choosing fix-now…” in explanatory body prose. The whole-document token matcher treated it as actionable, creating `milestones:ambiguous` and a partial receipt.
- **Fix:** Added a reproduction matching the real archive shape, proved RED, and narrowed `fix-now` to anchored marker forms without path-specific suppression. Existing status/outcome/disposition/action-heading families and contradiction behavior remain unchanged.
- **Files modified:** `scripts/maintainer/baseline_inventory.sh`, `test/support/lockspire/release_proof/package_assertions.ex`
- **Verification:** focused contract 1/0; full repository-hygiene contract 29/0; stable production recollection complete.
- **Committed in:** `87778945` (RED), `a8fe1973` (GREEN)

**2. [Rule 3 - Blocking] Kept the regression fixture compatible with proof-quality policy**

- **Found during:** clean-base `mix ci` prerequisite rerun.
- **Issue:** The fake archived document heading included a phase-numbered label, which the repository proof-quality scanner correctly reserves for canonical current-proof locations.
- **Fix:** Made the fake heading phase-neutral while retaining the terminal status and exact incidental prose reproduction.
- **Files modified:** `test/support/lockspire/release_proof/package_assertions.ex`
- **Verification:** proof-quality test 4/0; focused contract 1/0; final `mix ci` exit 0.
- **Committed in:** `0d777d1a`

**3. [Rule 1 - Bug, user approved] Recognized the exact valid GSD plan-closeout metadata transition**

- **Found during:** final post-bookkeeping relation proof after the first ledger publication.
- **Issue:** The required GSD closeout commit changed exactly SUMMARY, ROADMAP, STATE, and `state.json`, but the production classifier treated it as unknown and returned `refresh_required`.
- **Fix:** Added RED process coverage for the valid shape and hostile near misses, then implemented one narrow semantic classifier requiring exact paths, subject/plan identity, complete summary structure, exact requirement/coverage agreement, self-check, monotonic progress, and allowlisted state/roadmap transitions.
- **Files modified:** `scripts/maintainer/baseline_inventory.sh`, `test/lockspire/release/repository_hygiene_contract_test.exs`, `test/support/lockspire/release_proof/package_assertions.ex`
- **Verification:** RED failed for `class=unknown`; GREEN focused relation 2/0; full repository hygiene 30/0; final `mix ci` exit 0.
- **Committed in:** `b20ea464` (RED), `15ed0b5f` (GREEN)

**4. [Rule 3 - Blocking] Kept closeout fixtures compatible with proof-quality policy**

- **Found during:** first post-classifier `mix ci` prerequisite run.
- **Issue:** Four exact phase labels in adversarial fixture source violated the proof-quality rule reserving phase-numbered proof text for canonical locations.
- **Fix:** Constructed the fixture label from phase-neutral constants without changing the rendered commits under test.
- **Files modified:** `test/support/lockspire/release_proof/package_assertions.ex`
- **Verification:** focused proof-quality and relation contracts 5/0; complete corrected-base prerequisite chain exit 0.
- **Committed in:** `9d70b89f`

**Total deviations:** 4 auto-fixed (2 Rule 1 correctness defects, 2 Rule 3 blocking fixture-policy corrections). The second Rule 1 deviation was explicitly approved at a blocking-human checkpoint. None adds product/runtime surface or weakens evidence rules.

## Issues Encountered

- The first production collection failed closed exactly as designed and produced no publication commit. The user approved the bounded matcher regression/fix, after which the complete plan was rerun from a new clean committed base.
- The first post-bookkeeping relation also failed closed exactly as designed. The user approved the exact semantic closeout classifier, after which all prerequisites and collections were rerun again from `9d70b89f` without rewriting prior evidence history.
- An initial independent comparison command had faulty field extraction and a missing Ruby runtime. It made no repository change and was immediately replaced by a fail-fast `awk`/`perl` comparison, which passed exact equality.

## Known Stubs

None. The modified source/test files contain no newly introduced TODO, FIXME, placeholder, skipped test, unrun verification, or unwired data source. Existing TODO/FIXME strings are maintained-selector vocabulary and adversarial fixture inputs.

## Threat and Boundary Outcomes

- T-138-103: complete clean-base collection plus independent source equality and stable double-collection fingerprints.
- T-138-104: one-parent, one-path publication with parent equal to `evidence_base_sha` and unchanged committed blob.
- T-138-105: repository identity, ancestry, fingerprints, external receipts, and clean worktree produce `authorized_bookkeeping`.
- T-138-106: safe-field allowlists, UTF-8/frontmatter validation, bounded rendering, and credential-pattern scans remained clean.
- T-138-107: every action remains proposal-only and requires named maintainer authority and exact revalidation.
- No product API, schema, package, auth path, network endpoint, or new trust-boundary surface was introduced.

## User Setup Required

None.

## Next Phase Readiness

- Normal Phase 138 verification must rerun `bash scripts/maintainer/baseline_inventory.sh --verify-snapshot-relation .planning/phases/138-baseline-inventory-evidence-taxonomy/baseline-inventory-2026-08-28.md` after this summary commit.
- Any `refresh_required`, unavailable, ambiguous, malformed, temporally mismatched, omitted, destructive, or source-drift result returns the phase to gap closure.
- With an authorized relation, Phase 139 can reconcile repository truth; Phase 140 retains action authority and Phase 141 retains exact-SHA closure authority.

## Self-Check: PASSED

- Confirmed the canonical ledger, collector, regression support, and this summary exist.
- Confirmed both RED/GREEN regressions, both fixture corrections, both clean bases, and both ledger-publication commits exist with the recorded anchors.
- Confirmed the final publication commit has exactly one parent equal to `evidence_base_sha`, changes only the canonical ledger, and retains blob `f31917cc7c3b98335ab4e9f30bf6137a18f3a22e`.
- Confirmed every prerequisite gate, independent source comparison, stable second collection, and production relation passed.
- Confirmed all five requirements, D-01 through D-24, fourteen edge candidates, and four descriptor-less prohibitions are explicitly represented with no silent omission.
- Confirmed no new stub, skipped test, unrun verification, secret exposure, destructive behavior, or unplanned threat surface remains.

---
*Phase: 138-baseline-inventory-evidence-taxonomy*
*Completed: 2026-09-10*
