---
phase: 138-baseline-inventory-evidence-taxonomy
plan: "29"
subsystem: release-maintenance
tags: [baseline-inventory, immutable-evidence, git, github-graphql, maintained-sources, relation-proof]
requires:
  - phase: 138-28
    provides: Central credential redaction plus the corrected path, authority, closeout, publication, and relation contracts from Plans 26-28.
provides:
  - One current proposal-only Git, GitHub, and maintained-source ledger collected twice from a clean corrected base.
  - A ledger-only immutable publication whose sole parent is its evidence base.
  - Live-source production relation proof returning authorized_bookkeeping with no fingerprint overrides.
affects: [phase-139, phase-140, phase-141, repository-reconciliation, release-evidence]
actuals:
  tokens: 9897
  tasks: 2
  commits: 3
tech-stack:
  added: []
  patterns: [clean-base-double-collection, immutable-ledger-publication, live-only-relation-proof, cross-vm-fixture-isolation]
key-files:
  created:
    - .planning/phases/138-baseline-inventory-evidence-taxonomy/138-29-SUMMARY.md
  modified:
    - .planning/phases/138-baseline-inventory-evidence-taxonomy/baseline-inventory-2026-08-28.md
    - test/support/lockspire/release_proof/package_assertions.ex
key-decisions:
  - "The immutable evidence base is 37b08394fbcec49ed92d527a3bad583dedd7283d; publication 891fe796e86a9e803669cc977e96cbeccf6f34aa changes only the canonical ledger."
  - "Source equality is accepted only from two production collections plus independent live Git, authenticated GraphQL, and maintained-source observations; normalized timestamps are the only permitted byte difference."
  - "The production relation must run with both legacy fingerprint variables unset and return authorized_bookkeeping; any uncertainty requires recollection, not inferred authorization."
patterns-established:
  - "Publication boundary: collect from a clean committed base, verify twice, then commit exactly one canonical ledger path with one parent."
  - "Currentness boundary: verify immutable anchors first, then re-observe every mutable source live through the production classifier."
requirements-completed: [BASE-01, BASE-02, TRIAGE-01, TRIAGE-02, LOOSE-01]
coverage:
  - id: D1
    description: "The canonical inventory is current at an exact clean evidence base and published as its ledger-only child."
    requirement: BASE-01
    verification:
      - kind: other
        ref: "git rev-list --parents -n 1 891fe796 && git diff-tree --no-commit-id --name-only -r 891fe796"
        status: pass
      - kind: integration
        ref: "baseline_inventory.sh --verify-snapshot-relation baseline-inventory-2026-08-28.md"
        status: pass
    human_judgment: false
  - id: D2
    description: "All branches, tags, and the legal worktree path are represented through delimiter-safe structured transport."
    requirement: BASE-02
    verification:
      - kind: integration
        ref: "mix test test/lockspire/release/repository_hygiene_contract_test.exs --only phase138_path_gap"
        status: pass
      - kind: other
        ref: "Independent live Git comparison: 29 branches, 38 tags, 1 worktree"
        status: pass
    human_judgment: false
  - id: D3
    description: "GitHub pull-request evidence is complete, authenticated, paginated, and bound to matching outer and nested identities."
    requirement: TRIAGE-01
    verification:
      - kind: integration
        ref: "mix test test/lockspire/release/repository_hygiene_contract_test.exs --only phase138_source_authority_gap"
        status: pass
      - kind: other
        ref: "Independent authenticated GraphQL comparison: 7 pull requests with terminal outer and nested pagination"
        status: pass
    human_judgment: false
  - id: D4
    description: "GitHub issue complete-zero is backed by authenticated terminal pagination rather than absence inference."
    requirement: TRIAGE-02
    verification:
      - kind: integration
        ref: "mix test test/lockspire/release/repository_hygiene_contract_test.exs --only phase138_relation_gap"
        status: pass
      - kind: other
        ref: "Independent authenticated GraphQL issue observation: 0 records, terminal page"
        status: pass
    human_judgment: false
  - id: D5
    description: "Maintained evidence is scanned live with complete family receipts and fail-closed handling for unsafe or conflicting records."
    requirement: LOOSE-01
    verification:
      - kind: integration
        ref: "mix test test/lockspire/release/repository_hygiene_contract_test.exs"
        status: pass
      - kind: other
        ref: "Two production collections and independent maintained-source counts/fingerprint comparison"
        status: pass
    human_judgment: false
  - id: D6
    description: "Credentials, forged closeout metadata, fingerprint injection, and wrong output targets cannot become authoritative evidence."
    verification:
      - kind: integration
        ref: "phase138_closeout_gap, phase138_redaction_gap, phase138_source_authority_gap, and full repository-hygiene contracts"
        status: pass
      - kind: other
        ref: "Production relation run with LOCKSPIRE_INVENTORY_TEST_* fingerprint variables unset"
        status: pass
    human_judgment: false
duration: 1h 40m
completed: 2026-09-10
status: complete
---

# Phase 138 Plan 29: Current Immutable Baseline Inventory Summary

**A clean corrected evidence base now has one immutable proposal-only ledger whose live Git, authenticated GitHub, and maintained-source relation is independently reproducible and authorized.**

## Performance

- **Duration:** 1h 40m
- **Started:** 2026-09-10T19:29:23Z
- **Completed:** 2026-09-10T21:09:34Z
- **Tasks:** 2
- **Files modified:** 2 implementation/evidence files plus this summary

## Accomplishments

- Recollected the canonical ledger twice from corrected base `37b08394fbcec49ed92d527a3bad583dedd7283d`; source identities and fingerprints matched, and timestamp-normalized output was byte-identical.
- Published commit `891fe796e86a9e803669cc977e96cbeccf6f34aa` as a one-parent, one-path child of that evidence base without rewriting any prior ledger history.
- Proved the production relation with live sources only: `snapshot_relation: authorized_bookkeeping`, while ledger blob `e7f91f16538131606bb925f394432a8aa5b80702` and SHA-256 `f0cc1e32a8aef0b2770d63dc828c5ca96dd586b53adc6b98080d6b5b73d384c0` remained unchanged.
- Closed the six verification gaps with direct implementation, adversarial contracts, current live evidence, and explicit fail-closed treatment.

## Task Commits

1. **Task 1 prerequisite correction: keep closeout fixtures phase-neutral** - `2dc62f3b` (test)
2. **Task 1 prerequisite correction: isolate collector temp fixtures across VM runs** - `37b08394` (test)
3. **Task 1: publish the corrected canonical baseline inventory** - `891fe796` (docs)
4. **Task 2: prove current relation and record the six-gap handoff** - read-only verification recorded in this summary

## Files Created/Modified

- `.planning/phases/138-baseline-inventory-evidence-taxonomy/baseline-inventory-2026-08-28.md` - Current immutable proposal-only ledger.
- `test/support/lockspire/release_proof/package_assertions.ex` - Phase-neutral closeout fixtures and cross-VM-safe collector temp paths.
- `.planning/phases/138-baseline-inventory-evidence-taxonomy/138-29-SUMMARY.md` - Immutable anchors, source equality, relation proof, and six-gap handoff.
- `.planning/STATE.md`, `.planning/ROADMAP.md`, and `.planning/state.json` - Exact Phase 138 plan-closeout lifecycle bookkeeping.

## Immutable Anchors

| Anchor | Value |
| --- | --- |
| Evidence base | `37b08394fbcec49ed92d527a3bad583dedd7283d` |
| Publication commit | `891fe796e86a9e803669cc977e96cbeccf6f34aa` |
| Publication parent | `37b08394fbcec49ed92d527a3bad583dedd7283d` |
| Changed path | `.planning/phases/138-baseline-inventory-evidence-taxonomy/baseline-inventory-2026-08-28.md` |
| Ledger Git blob | `e7f91f16538131606bb925f394432a8aa5b80702` |
| Ledger SHA-256 | `f0cc1e32a8aef0b2770d63dc828c5ca96dd586b53adc6b98080d6b5b73d384c0` |
| Normalized double-collection SHA-256 | `1abc1ca4f1f8d5e5cf760fa1f03c446d17c8aa8e9197c50810eac34cf50af520` |
| Git receipt fingerprint | `67345cb9de192463d504d23deec5913180ff971e` |
| GitHub receipt fingerprint | `e4a0d93da8dfded613c99066c2ee3b0af081be38` |
| Maintained receipt fingerprint | `7a9936c6db4bac02d6524061c65f4b812e1334ee` |
| Collection window | `2026-09-10T20:28:20Z` through `2026-09-10T20:28:39Z` |

The publication commit has exactly one parent and exactly one changed path. The ledger's `local_head_sha`, `local_main_sha`, and `evidence_base_sha` all equal the publication parent. The committed blob and filesystem SHA-256 were identical before and after relation proof.

## Independent Source Equality

| Source | Independent current observation | Ledger result |
| --- | --- | --- |
| Git | 29 branch rows, 38 tag rows, 1 legal worktree row; exact object IDs and deterministic order | Complete; fingerprint matched both collections |
| GitHub pull requests | 7 records: 83, 87, 88, 91, 96, 97, 98; terminal outer pagination; each head/base/state present; nested commit OID equals head OID; nested contexts terminal | Complete; fingerprint matched both collections |
| GitHub issues | 0 records from authenticated terminal pagination | Complete-zero; not inferred from absence |
| Maintained sources | debug 2, quick 5, threads 2, seeds 3, milestones 835, active-record candidates 2, plus 5 singleton maintained documents | Complete family receipts; fingerprint matched both collections |

Both production collections used the explicit absolute canonical output target and `--replace`, with `LOCKSPIRE_INVENTORY_TEST_GITHUB_FINGERPRINT` and `LOCKSPIRE_INVENTORY_TEST_MAINTAINED_FINGERPRINT` absent. Their only raw byte differences were the four expected collection/relation timestamps; after normalizing those timestamps, the outputs were byte-identical.

## Current Relation Proof

The exact Task 2 verifier passed at the ledger commit:

```console
test "$(git rev-list --parents -n 1 HEAD | awk '{print NF}')" -eq 2
test "$(git diff-tree --no-commit-id --name-only -r HEAD)" = ".planning/phases/138-baseline-inventory-evidence-taxonomy/baseline-inventory-2026-08-28.md"
env -u LOCKSPIRE_INVENTORY_TEST_GITHUB_FINGERPRINT \
  -u LOCKSPIRE_INVENTORY_TEST_MAINTAINED_FINGERPRINT \
  bash scripts/maintainer/baseline_inventory.sh --verify-snapshot-relation \
  .planning/phases/138-baseline-inventory-evidence-taxonomy/baseline-inventory-2026-08-28.md
```

Observed relation rows:

```text
ledger_commit|891fe796e86a9e803669cc977e96cbeccf6f34aa|parent=37b08394fbcec49ed92d527a3bad583dedd7283d|verdict=authorized_bookkeeping
working_tree|clean|authorized_bookkeeping|none
snapshot_relation: authorized_bookkeeping
```

Exit status was zero. Any later nonzero result or `refresh_required` requires a fresh clean-base recollection and a new ledger-only replacement; it cannot be reinterpreted as bookkeeping authority.

## Six-Gap Outcome

| Verification gap | Implementation and adversarial proof | Current live proof |
| --- | --- | --- |
| Canonical inventory stale at HEAD | Ledger-only publication and immutable parent/path/blob checks | Fresh double collection and `authorized_bookkeeping` relation |
| Legal tab/newline worktree paths unsafe | Plan 26 delimiter-safe structured transport and real-repository hostile-path fixtures | All current legal worktrees independently matched |
| Production fingerprint hooks bypass sources | Plan 27 matching-value bypass regressions and removal of production-visible injection authority | Both legacy variables unset; all three live fingerprints matched |
| Forged/unrelated GSD closeout metadata authorized | Plan 27 bounded parser, exact semantic transition checks, and surplus-prefix adversaries | Current post-snapshot rows classified exactly and fail closed |
| AWS/Slack/JWT/PEM/opaque credentials unredacted | Plan 28 cross-domain credential matrix and benign controls | Canonical bytes scanned; supported raw credential shapes absent |
| Relative output re-rooted after `cd` | Plan 26 nested-caller and wrong-target fixtures | Collection used invocation-resolved absolute canonical target |

The earlier jq diagnostic concern is resolved by the full repository-hygiene contract and successful production collection; no malformed structured record or uncontrolled body was accepted.

## Requirements and Decision Coverage

- `BASE-01`: exact repository identity, clean evidence base, immutable publication relation, and fail-closed currentness.
- `BASE-02`: complete delimiter-safe branch, tag, and worktree representation with deterministic identity/order.
- `TRIAGE-01`: authenticated full-shape pull-request evidence with exact outer/nested/base identities and terminal pagination.
- `TRIAGE-02`: authenticated issue pagination, namespace separation, and honest terminal complete-zero.
- `LOOSE-01`: live maintained scanning, complete family receipts, safe encoding, and partial status for unsafe/conflicting evidence.

D-01 through D-24 are covered: canonical dated Markdown authority; Bash collector ownership; separated hygiene proof; compact output; provenance and completeness receipts; revalidation and fetch-only boundaries; structured complete sources; centralized redaction; bounded lifecycle taxonomy; full proposal-only rows; terminal pagination proof; source manifest and archive summary; explicit exclusions; stable identity/dedup; maintainer personas; deterministic accessible Markdown; calm microcopy; and executable contracts.

## Spec-less Candidate Audit

All fourteen candidates remain explicit:

1. `BASE-01 unclassified` — unresolved fail-closed backstop for dependency, fetch, identity, status, divergence, lifecycle, or relation uncertainty.
2. `BASE-02 adjacency` — delimiter-safe records and independent subject/OID comparison.
3. `BASE-02 empty` — complete-zero only after valid structured observation.
4. `BASE-02 ordering` — deterministic canonical sorting.
5. `BASE-02 idempotency` — two fresh collections reproduce identities and fingerprints.
6. `BASE-02 concurrency` — lock-first target publication plus source-stability checks.
7. `TRIAGE-01 adjacency` — exact outer/nested identities and live fingerprint binding.
8. `TRIAGE-01 empty` — authenticated terminal-zero without implied health.
9. `TRIAGE-01 ordering` — numeric PR order independently compared.
10. `TRIAGE-01 concurrency` — outer/nested head movement fails equality.
11. `TRIAGE-02 adjacency` — exact issue duplicate agreement and namespace separation.
12. `TRIAGE-02 empty` — authenticated issue pagination alone may establish complete-zero.
13. `TRIAGE-02 ordering` — numeric issue order independently compared.
14. `LOOSE-01 unclassified` — unsafe, unreadable, invalid, or conflicting maintained evidence remains partial.

Equality remains 14 candidates: 12 executable dispositions plus 2 unresolved fail-closed backstops.

## Prohibition Flags

All four descriptor-less constraints remain explicitly `flagged-unverified` for normal verification:

1. Collection and publication authorize no merge, close, delete, prune, rewrite, cleanup, release, or other disposition action.
2. Republication does not amend, delete, or rewrite prior immutable ledgers or historical evidence.
3. Ledgers and diagnostics expose no credential, uncontrolled body, raw log, or environment value.
4. Partial, unavailable, malformed, stale, ambiguous, or caller-injected evidence cannot be presented as complete or authoritative.

## Verification

- Shell syntax passed for `scripts/maintainer/baseline_inventory.sh`.
- Focused Phase 138 tags passed: path 1/0, relation 2/0, source authority 1/0, closeout 1/0, and redaction 1/0.
- Full repository-hygiene contract: 33 tests, 0 failures.
- Release-readiness contract: 2 tests, 0 failures.
- `mix ci`: 1,402 main tests, 0 failures, 6 skipped, 286 excluded; 102 integration tests, 0 failures, 33 excluded; formatting, compile warnings, cycles, Credo, Sobelow, docs, audit, and package checks passed.
- API coverage: 8 surface, 8 integrated, 0 opt-outs, `block: false`.
- Assumption delta: `detected: false`.
- Schema drift: `drift_detected: false`, `block: false`; no schema proposal or push.
- Production relation: exit 0 with `snapshot_relation: authorized_bookkeeping` and unchanged blob.
- Lifecycle tracking: STATE advanced to verification, ROADMAP advanced to 29/29, and all five requirements were already complete.

## Decisions Made

- Evidence remains proposal-only even when current relation proof succeeds; every named disposition still requires revalidation and maintainer authority.
- The ledger commit, not the later lifecycle HEAD, is the immutable anchor. Normal verification must rerun the same live relation after bounded summary/state/roadmap bookkeeping.
- Cross-process fixture paths include wall-clock nanoseconds as well as VM-local uniqueness so stale artifacts from an earlier BEAM instance cannot contaminate a later clean verification run.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking test fixture] Removed phase-number coupling from closeout fixtures**

- **Found during:** Task 1 clean-base prerequisite verification.
- **Issue:** Two literal `Phase 138` fixture strings violated the repository's phase-neutral quality baseline and blocked `mix ci`.
- **Fix:** Constructed the same hostile closeout subjects at runtime from the existing phase-label attribute, retaining exact adversarial semantics without forbidden literals.
- **Files modified:** `test/support/lockspire/release_proof/package_assertions.ex`
- **Verification:** Focused closeout contracts, full repository-hygiene contract, and `mix ci` passed.
- **Committed in:** `2dc62f3b`

**2. [Rule 3 - Blocking test isolation] Made collector temp fixtures unique across BEAM instances**

- **Found during:** Task 1 repeated prerequisite and double-collection verification.
- **Issue:** `System.unique_integer/1` is VM-local, so a later test VM could reuse a directory left by an interrupted earlier run and fail with `:eexist`.
- **Fix:** Centralized fixture-path creation with OS-time nanoseconds plus the VM-local unique integer and routed all collector fixtures through it.
- **Files modified:** `test/support/lockspire/release_proof/package_assertions.ex`
- **Verification:** Focused gap tags, full 33-test hygiene suite, release readiness, and two complete `mix ci` passes succeeded across separate VMs.
- **Committed in:** `37b08394`

**3. [Rule 1 - Relation metadata] Matched the exact bounded plan-closeout projection**

- **Found during:** Post-summary production relation verification.
- **Issue:** The generic SDK commit file set omitted `.planning/state.json`, retained extra session timestamps, and the first coverage draft repeated `BASE-01`; the fail-closed classifier correctly reported the closeout as unknown.
- **Fix:** Included the SDK-generated state contract transition in the same closeout commit, retained only the exact accepted STATE changes, and made the five requirement mappings unique while keeping the sixth security deliverable unscoped.
- **Files modified:** `.planning/phases/138-baseline-inventory-evidence-taxonomy/138-29-SUMMARY.md`, `.planning/STATE.md`, `.planning/state.json`
- **Verification:** The post-closeout production relation was rerun with live sources and no fingerprint overrides.
- **Committed in:** final plan metadata commit

**Total deviations:** 3 auto-fixed (2 Rule 3 blocking test issues, 1 Rule 1 relation-metadata bug)
**Impact on plan:** The corrections were necessary to establish the required clean, reproducible base and exact bounded closeout. They changed no production collector behavior, dependencies, schemas, public API, or disposition authority.

## Issues Encountered

- Hex reported an expired local authentication session during public dependency checks. Resolution and audit still completed successfully, so this was a non-blocking local warning rather than an authentication gate.
- Concurrent repository verification increased the main-suite runtime, but all required commands completed with authoritative zero exits.

## User Setup Required

None - no external service configuration required. Existing `gh` authentication supplied complete live GraphQL evidence.

## Known Stubs

None. No placeholder implementation, skipped test, or unrun verification remains.

## Threat Outcomes

- `T-138-120`: mitigated by clean-base gating, double collection, and independent comparisons.
- `T-138-121`: mitigated by live production relation proof with both fingerprint overrides absent.
- `T-138-122`: mitigated by centralized redaction contracts and canonical-output credential-shape scanning.
- `T-138-123`: mitigated by exact bounded closeout semantics and proposal-only dispositions.
- `T-138-124`: mitigated by the absolute canonical target, one-parent/one-path publication, unchanged blob, and transactional publication contract.

No new network endpoint, auth path, file-access trust boundary, schema, migration, or runtime/package surface was introduced.

## Next Phase Readiness

- Phase 139 can consume the stable evidence IDs after rerunning the production relation against its starting HEAD.
- Phases 140 and 141 must repeat the relation immediately before mutation and exact-SHA closure respectively.
- Any source change, unsafe rendering, malformed path, injected authority, unknown/surplus lifecycle transition, wrong target, or non-complete receipt returns Phase 138 to gap closure.

## Self-Check: PASSED

- Commits `2dc62f3b`, `37b08394`, and `891fe796` exist in repository history.
- The canonical ledger and this summary exist at their required paths.
- The publication parent, sole changed path, blob, SHA-256, and evidence-base anchors were checked directly.
- Every required automated verification ran and passed; no verification was skipped.

*Phase: 138-baseline-inventory-evidence-taxonomy*
*Completed: 2026-09-10*
