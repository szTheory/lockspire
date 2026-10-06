---
phase: 138-baseline-inventory-evidence-taxonomy
plan: "23"
subsystem: release-maintenance
tags: [git, github-graphql, evidence-ledger, currentness, fail-closed]
requires:
  - phase: 138-22
    provides: Exact PR-head joins, full-blob archive classification, format-bound Git identities, and production relation validation.
provides:
  - Complete current Git, GitHub, and maintained-source ledger.
  - Immutable ledger-only commit bound to its clean evidence base.
  - Clean authorized_bookkeeping production relation.
affects: [phase-138-verification, phase-139, phase-140, phase-141]
actuals:
  tokens: 5510
  tasks: 2
  commits: 7
tech-stack:
  added: []
  patterns: [ledger-only publication, independent source reconciliation, exact lifecycle authorization]
key-files:
  created: [.planning/phases/138-baseline-inventory-evidence-taxonomy/138-23-SUMMARY.md]
  modified:
    - .planning/phases/138-baseline-inventory-evidence-taxonomy/baseline-inventory-2026-08-28.md
    - scripts/maintainer/baseline_inventory.sh
    - test/support/lockspire/release_proof/package_assertions.ex
    - test/lockspire/release/repository_hygiene_contract_test.exs
key-decisions:
  - "Archive action authority requires explicit current-action markers; incidental historical prose and superseded review status remain summarized."
  - "Summary bookkeeping may include state.json only when its contract-v1 Phase 138 entry has GSD's emitted in_progress status."
  - "All dispositions remain proposals requiring named authority and fresh target revalidation."
patterns-established:
  - "Immutable ledger commit, clean relation proof, then summary/tracking metadata."
  - "Collector success is corroborated by independent Git, GraphQL, maintained-source, encoding, and fingerprint audits."
requirements-completed: [BASE-01, BASE-02, TRIAGE-01, TRIAGE-02, LOOSE-01]
coverage:
  - id: D1
    description: Complete clean-base Git baseline and topology inventory.
    requirement: BASE-01
    verification:
      - kind: integration
        ref: "independent Git audit plus production relation"
        status: pass
    human_judgment: false
  - id: D2
    description: Every branch, tag, and worktree has a stable exact-format proposal row.
    requirement: BASE-02
    verification:
      - kind: integration
        ref: "hygiene contracts and 29/38/1 equality"
        status: pass
    human_judgment: false
  - id: D3
    description: Every open PR has coherent outer metadata and nested exact-head checks.
    requirement: TRIAGE-01
    verification:
      - kind: integration
        ref: "authenticated GraphQL 7-PR exact-head audit"
        status: pass
    human_judgment: false
  - id: D4
    description: Open issues have terminal pagination and honest complete-zero evidence.
    requirement: TRIAGE-02
    verification:
      - kind: integration
        ref: "authenticated GraphQL 0-issue terminal audit"
        status: pass
    human_judgment: false
  - id: D5
    description: Every maintained candidate is inventoried or explicitly summarized/incomplete.
    requirement: LOOSE-01
    verification:
      - kind: integration
        ref: "14=14 candidates; 2 full-blob expansions"
        status: pass
    human_judgment: false
duration: 2h38m
completed: 2026-09-09
status: complete
---

# Phase 138 Plan 23: Canonical Evidence Publication Summary

**A complete proposal-only Git, GitHub, and maintained-source ledger is immutably bound to its clean evidence base and returns `snapshot_relation: authorized_bookkeeping`.**

## Performance

- **Duration:** 2 hours 38 minutes
- **Started:** 2026-09-09T19:52:27Z
- **Completed:** 2026-09-09T22:30:34Z
- **Tasks:** 2/2
- **Files modified:** 4 production/test/evidence files plus this summary

## Accomplishments

- Recollected the canonical ledger from clean commit `fb00b98a3bd34fdfd22cf66a83e24b06309f1191` with every source receipt complete.
- Published `4b4989ed67019de134e26a5fcc8db89b30d4987c` as a one-parent, one-path ledger replacement and proved its committed blob unchanged.
- Independently matched 29 branches, 38 tags, one worktree, seven open PRs, zero open issues, fourteen maintained candidates, two archive expansions, three archive summaries, and all fingerprints.
- Ran the complete prerequisite chain before collection and again after final publication as the auto-mode tracer feedback gate.

## Task Commits

1. **Task 1 support: phase-neutral proof label** — `9719582a` (fix)
2. **Task 1 support: explicit archive action markers** — `0c2c3563` (fix)
3. **Task 1 support: archived review supersession** — `e2ffe1b2` (fix)
4. **Task 1 support: synchronized-state lifecycle guard** — `c22de272` (fix)
5. **Task 1 provisional immutable publication** — `960b214a` (fix; superseded after lifecycle dry audit)
6. **Task 1 support: actual GSD state status** — `fb00b98a` (fix)
7. **Task 1 final immutable publication** — `4b4989ed` (fix)
8. **Task 2 currentness/coverage proof** — read-only; no production diff manufactured

## Files Created/Modified

- `.planning/phases/138-baseline-inventory-evidence-taxonomy/baseline-inventory-2026-08-28.md` — complete canonical proposal-only evidence ledger.
- `scripts/maintainer/baseline_inventory.sh` — exact archive authority and safe synchronized-state lifecycle authorization.
- `test/support/lockspire/release_proof/package_assertions.ex` — incidental/superseded archive and malformed state-contract regressions.
- `test/lockspire/release/repository_hygiene_contract_test.exs` — phase-neutral current-gap proof label.
- `.planning/phases/138-baseline-inventory-evidence-taxonomy/138-23-SUMMARY.md` — anchors, comparisons, gap outcomes, and revalidation handoff.

## Verification

Mix commands used `ASDF_ELIXIR_VERSION=1.19.5-otp-28` and `ASDF_ERLANG_VERSION=28.4.1`.

| Exact command | Final result |
| --- | --- |
| `bash -n scripts/maintainer/baseline_inventory.sh` | exit 0 |
| `mix test test/lockspire/release/repository_hygiene_contract_test.exs --only phase138_current_gap` | 1 test, 0 failures |
| `mix test test/lockspire/release/repository_hygiene_contract_test.exs` | 28 tests, 0 failures |
| `mix test test/lockspire/release_readiness_contract_test.exs` | 2 tests, 0 failures |
| `mix ci` | exit 0; 1397 tests, 0 failures, 6 pre-existing skips; integration 102/0 |
| `node /Users/jon/.codex/gsd-core/bin/gsd-tools.cjs check api-coverage.verify-pre .planning/phases/138-baseline-inventory-evidence-taxonomy` | `block: false`; 8/8 integrated; 0 opt-outs |
| `bash scripts/maintainer/baseline_inventory.sh --output .planning/phases/138-baseline-inventory-evidence-taxonomy/baseline-inventory-2026-08-28.md --replace` | exit 0; `status: complete` |
| `bash scripts/maintainer/baseline_inventory.sh --verify-snapshot-relation .planning/phases/138-baseline-inventory-evidence-taxonomy/baseline-inventory-2026-08-28.md` | exit 0; `snapshot_relation: authorized_bookkeeping` |

The final relation rows were:

```text
ledger_commit|4b4989ed67019de134e26a5fcc8db89b30d4987c|parent=fb00b98a3bd34fdfd22cf66a83e24b06309f1191|verdict=authorized_bookkeeping
working_tree|clean|authorized_bookkeeping|none
snapshot_relation: authorized_bookkeeping
```

### Immutable anchors

| Anchor | Value |
| --- | --- |
| Evidence base / ledger parent | `fb00b98a3bd34fdfd22cf66a83e24b06309f1191` |
| Ledger-only commit | `4b4989ed67019de134e26a5fcc8db89b30d4987c` |
| Ledger blob | `0f94a0ca6b526da00db5dd41126ca983dd11fdab` |
| Object format | `sha1` |
| `origin/main` | `d82eaa1c74f396c5eb5dcfa393ddd5dd952acb92` |
| Collection window | `2026-09-09T22:08:35Z`–`2026-09-09T22:08:57Z` |
| Git fingerprint | `2450b99347b226279fb77083e815cec35fb16497` |
| GitHub fingerprint | `e4a0d93da8dfded613c99066c2ee3b0af081be38` |
| Maintained fingerprint | `268fd408b5d529ea31263353429cbe93b9156e0b` |

### Independent comparison

- Fresh `for-each-ref`, worktree porcelain, object-format, and `ls-remote` observations matched every Git ID/ref/OID: 29 branches, 38 tags, one worktree, SHA-1, and recorded remote main.
- Separate authenticated GraphQL returned seven PRs ordered `83,87,88,91,96,97,98` and zero issues with terminal pages. Every nested commit OID equaled outer `headRefOid`; context counts and rendered state/draft/merge/check evidence matched.
- NUL-aware maintained selectors matched debug 2, quick 5, threads 2, seeds 3, active records 2, milestones 835, and seven marker occurrences. Full-blob expansion selected exactly the two v1.27 Phase 99 `99-LEARNINGS.md`/`99-VERIFICATION.md` candidates.
- UTF-8, strict 16-key YAML, control-byte/secret scans, unique stable IDs, proposal-only executed fields, and independent section fingerprints passed.

### Four gap outcomes and no-silent-drop audit

| Prior gap/warning | Outcome |
| --- | --- |
| Stale canonical inventory | Closed by final one-parent/one-path ledger and authorized relation at clean HEAD. |
| Nested checks disconnected from PR head | Closed by Plan 138-22 regressions and exact live OID equality for all seven PRs. |
| Late archive marker omission | Closed by full-blob classification and exact two-row live expansion equality. |
| Impossible Git object lengths | Closed by exact-format regressions and 40-character SHA-1 live identities. |

The maintained candidate set has fourteen canonical direct-or-expanded records and the ledger has fourteen `maintained_record` rows: **14 candidates = 14 rows**. Three archive-summary rows and two deduplicated marker subjects (from seven occurrences) account for the remaining evidence. Current `138-REVIEW.md` and `138-VERIFICATION.md` are individual active rows. No candidate was omitted or dismissed.

### Requirements and D-01–D-24

| Requirement | Passing evidence |
| --- | --- |
| BASE-01 | Clean committed base, complete fetch/baseline, exact anchors/divergence, authorized relation. |
| BASE-02 | Exact 29/38/1 Git equality, stable IDs/order, and format-bound OIDs. |
| TRIAGE-01 | Seven terminal PR rows with exact outer/nested OID joins and current state. |
| TRIAGE-02 | Separate terminal issue pagination and explicit successful-zero count, not a health claim. |
| LOOSE-01 | Complete selectors, 14=14 equality, full-blob decisions, current review/verification, ambiguity backstops. |

| Decisions | Evidence/backstop |
| --- | --- |
| D-01–D-05 | One canonical Markdown ledger, stable sections/IDs, Bash ownership, compact safe tables, no sidecar/product expansion. |
| D-06–D-11 | UTC provenance, completeness states, immutable anchors, revalidation schedule, fetch-only mutation, structured interfaces, redaction. |
| D-12–D-16 | Domain-native lifecycle/dispositions, authority, explicit unexecuted proposals, terminal and merge-readiness guards. |
| D-17–D-20 | Explicit allowlist, 14=14 equality, full-blob archives, exclusions, stable deduplication/supersession, ambiguity fail closure. |
| D-21–D-24 | Steward-focused terminal/Markdown UX, semantic textual states, calm evidence language, comprehensive green process contracts. |

Any unavailable, partial, ambiguous, temporally mismatched, omitted, destructive, source-drift, or unknown-lifecycle observation has a tested nonzero `refresh_required` backstop. Normal Phase 138 verification must rerun the production relation after lifecycle bookkeeping and return `gaps_found` for any such result.

## Decisions Made

- Only explicit disposition/status markers or dedicated actionable headings grant archive action authority.
- Archived `issues_found` alone is superseded historical state, not current action authority.
- `.planning/state.json` is authorized in summary metadata only with contract `1.0.0` and Phase 138 `in_progress`; malformed/arbitrary JSON remains unauthorized.
- Publication records observations and proposals only; Phase 140 still owns any later authorized action.

## Deviations from Plan

### Auto-fixed Issues

1. **[Rule 1 - Bug] Phase-neutral proof label (`9719582a`).** A literal current-phase test title violated proof-quality hygiene; renamed without changing behavior.
2. **[Rule 1 - Bug] Incidental archive terms (`0c2c3563`).** Broad keywords falsely expanded 35 historical files; narrowed authority to explicit markers/headings while retaining full-blob scans.
3. **[Rule 1 - Bug] Archived review supersession (`e2ffe1b2`).** Six old `issues_found` reviews appeared actionable; removed legacy status from generic archive authority and extended regression coverage.
4. **[Rule 2 - Missing critical] State metadata authorization (`c22de272`).** Added a contract/version/phase validator and malformed-companion regression for normal synchronized summary metadata.
5. **[Rule 1 - Bug] Actual GSD state status (`fb00b98a`).** The dry metadata audit showed GSD emits `in_progress`, not `executing`; corrected the validator/fixture and republished from a fresh clean base.

**Total deviations:** 5 auto-fixed (4 Rule 1, 1 Rule 2). Each was necessary for complete collection or authorized lifecycle closure; no unrelated or runtime scope was added.

## Issues Encountered

- Two partial candidates were discarded before publication. The first complete ledger `960b214a` passed clean relation proof but was superseded after the pre-metadata state-contract dry audit; it remains historical, while `4b4989ed` is the current canonical publication.
- Process-local Elixir 1.19.5 / OTP 28.4.1 selection was required; no tool-version file changed.
- `mix ci` warned that the Hex user session expired, but public dependency resolution, audit, packaging, and all tests passed. GitHub CLI authentication and live GraphQL succeeded independently.

## Known Stubs

None. No task-created placeholder, skipped test, unrun verification, or unwired source remains. The six pre-existing suite skips were not introduced or modified here.

## Security and Boundary Notes

- T-138-93 through T-138-96 are closed by clean gates, exact live joins/IDs/full blobs, immutable publication, current receipt relation, safe fields, redaction, UTF-8, and strict YAML.
- T-138-97 remains enforced: every disposition is unexecuted and requires named revalidation plus maintainer authority.
- No refs, worktrees, GitHub objects, release-owned files, historical records, product/runtime APIs, schemas, or proposal targets were mutated.

## User Setup Required

None.

## Next Phase Readiness

- Normal Phase 138 verification can rerun the exact production relation against lifecycle HEAD; anything except exit zero and `authorized_bookkeeping` must route to `gaps_found` and fresh recollection.
- Phase 139 may consume stable IDs after required mutable-source revalidation. Phase 140 retains all action authority. Phase 141 retains exact-SHA closure.
- No Plan 138-23 blocker remains.

## Self-Check: PASSED

- Confirmed all listed files and commits exist.
- Confirmed `4b4989ed` has one parent equal to `evidence_base_sha`, changes only the canonical ledger, and retains blob `0f94a0ca6b526da00db5dd41126ca983dd11fdab`.
- Confirmed every planned gate and final tracer rerun passed, all five requirements and D-01–D-24 have evidence/backstops, and 14=14 holds.
- Confirmed no stubs, unauthorized actions, new threat surface, or untracked generated artifacts remain.

---
*Phase: 138-baseline-inventory-evidence-taxonomy*
*Completed: 2026-09-09*
