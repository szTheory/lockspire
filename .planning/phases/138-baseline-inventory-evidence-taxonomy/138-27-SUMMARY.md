---
phase: 138-baseline-inventory-evidence-taxonomy
plan: "27"
subsystem: release-maintenance
tags: [source-authority, github-receipts, maintained-evidence, exact-transitions, adversarial-validation]
requires:
  - phase: 138-26
    provides: Path-safe worktree evidence, caller-bound publication targets, and deterministic dependency preflight.
provides:
  - Live-only GitHub and maintained-source receipt authority with no caller-controlled fingerprint injection.
  - Bounded summary frontmatter validation with exact required metadata cardinality and coverage membership.
  - Exact-cardinality ROADMAP and STATE closeout transitions that reject surplus matching-prefix mutations.
affects: [138-28, 138-29, phase-139, phase-140, repository-reconciliation]
actuals:
  tokens: 5435
  tasks: 2
  commits: 4
tech-stack:
  added: []
  patterns: [live-source authority, bounded frontmatter parsing, exact diff cardinality, hermetic executable fixtures]
key-files:
  created:
    - .planning/phases/138-baseline-inventory-evidence-taxonomy/138-27-SUMMARY.md
  modified:
    - scripts/maintainer/baseline_inventory.sh
    - test/lockspire/release/repository_hygiene_contract_test.exs
    - test/support/lockspire/release_proof/package_assertions.ex
key-decisions:
  - "External receipt authority is derived only from current authenticated GitHub collection and current tracked maintained-source observation."
  - "Closeout summaries expose exactly one canonical bounded frontmatter object; body text never supplies authoritative metadata."
  - "ROADMAP and STATE closeout validators require the exact target-plan diff cardinality and reject all surplus matching-prefix rows."
patterns-established:
  - "Hermetic source-authority tests drive the unchanged production shell entry point through fake gh executables and real tracked repository state."
  - "Semantic allowlists combine target-specific content validation with total diff cardinality so unrelated assertions cannot ride along."
requirements-completed: [BASE-01, TRIAGE-01, TRIAGE-02, LOOSE-01]
coverage:
  - id: D1
    description: Exact public caller fingerprints cannot authorize unavailable GitHub or drifted maintained evidence.
    requirement: TRIAGE-01
    verification:
      - kind: integration
        ref: "repository_hygiene_contract_test.exs#baseline snapshot relation accepts external receipts only from live sources"
        status: pass
    human_judgment: false
  - id: D2
    description: Live hermetic GitHub and maintained observations authorize when normalized receipts agree exactly.
    requirement: TRIAGE-02
    verification:
      - kind: integration
        ref: "package_assertions.ex#build_live_source_snapshot_repository!"
        status: pass
    human_judgment: false
  - id: D3
    description: Summary authority is bounded to one frontmatter block with exact keys and requirement membership.
    requirement: BASE-01
    verification:
      - kind: integration
        ref: "repository_hygiene_contract_test.exs#baseline snapshot relation authorizes only exact GSD plan closeout metadata"
        status: pass
    human_judgment: false
  - id: D4
    description: Surplus ROADMAP and STATE mutations fail even when every added line uses a recognized prefix.
    requirement: LOOSE-01
    verification:
      - kind: integration
        ref: "package_assertions.ex#apply_gsd_plan_closeout_near_miss!"
        status: pass
    human_judgment: false
duration: 45min
completed: 2026-09-10
status: complete
---

# Phase 138 Plan 27: Live Source Authority and Exact Closeout Transitions Summary

**Caller-controlled receipt fingerprints no longer substitute for live evidence, and GSD closeout authorization now rejects body forgeries and every surplus matching-prefix planning mutation.**

## Performance

- **Duration:** 45 minutes
- **Started:** 2026-09-10T15:50:03Z
- **Completed:** 2026-09-10T16:34:57Z
- **Tasks:** 2/2
- **Files modified:** 3 production/test files plus this summary

## Accomplishments

- Removed both production-readable external fingerprint injection branches and revalidated GitHub and maintained receipts exclusively from current sources.
- Added live hermetic controls proving authenticated fake GitHub pagination and tracked maintained evidence still authorize when their normalized receipt fingerprints agree.
- Bounded summary metadata to exactly one canonical frontmatter block with exact top-level key cardinality and exact five-requirement closeout coverage membership.
- Rejected extra checked plan rows, Phase 138 roadmap rows, state status lines, decision lines, and performance rows even when they match formerly allowlisted prefixes.

## Task Commits

1. **Task 1 RED: expose external receipt authority bypasses** — `4c42ff1b` (test)
2. **Task 1 GREEN: require live external receipt observations** — `51e2f0bb` (fix)
3. **Task 2 RED: expose forged closeout metadata transitions** — `e8fdef19` (test)
4. **Task 2 GREEN: bound GSD closeout transitions exactly** — `c8aeea7a` (fix)

## Files Created/Modified

- `scripts/maintainer/baseline_inventory.sh` — removes environment fingerprint authority, parses bounded closeout summary frontmatter, and enforces target-specific diff cardinality.
- `test/lockspire/release/repository_hygiene_contract_test.exs` — adds focused `:phase138_source_authority_gap` and `:phase138_closeout_gap` entry points.
- `test/support/lockspire/release_proof/package_assertions.ex` — adds exact matching-fingerprint bypass fixtures, live-source controls, body forgeries, duplicate metadata, and matching-prefix surplus mutations.
- `.planning/phases/138-baseline-inventory-evidence-taxonomy/138-27-SUMMARY.md` — records TDD gates, threat outcomes, verification evidence, and gap closure.

## Decisions Made

- Kept hermeticity outside the production interface: tests control fake executables on `PATH` and tracked fixture content, never a production-readable authority switch.
- Required exactly one summary frontmatter delimiter pair and one occurrence of each authoritative top-level key before interpreting values.
- Preserved target-plan generality by binding ROADMAP and STATE validators to the plan captured from the commit subject while constraining the complete diff cardinality.

## Verification

| Gate | Result |
| --- | --- |
| Focused `phase138_source_authority_gap` contract | 1 test, 0 failures; 31 excluded |
| Focused `phase138_closeout_gap` contract | 1 test, 0 failures; 31 excluded |
| Combined source-authority and closeout contract | 2 tests, 0 failures; 30 excluded |
| Existing `phase138_relation_gap` contract | 2 tests, 0 failures; 30 excluded |
| API coverage preflight | 8 capabilities integrated, 0 opt-outs, `block=false` |
| `bash -n scripts/maintainer/baseline_inventory.sh` | exit 0 |

The first combined relation run encountered an ExUnit cleanup timeout under transient concurrent fixture load. An immediate clean rerun completed in 69.8 seconds with both relation tests passing; no source changes occurred between runs.

## Threat Outcomes

| Threat | Outcome |
| --- | --- |
| T-138-112 caller-environment spoofing | Closed; production contains no external fingerprint injection branch. |
| T-138-113 summary metadata tampering | Closed; authoritative metadata must be in one bounded frontmatter block with exact cardinality. |
| T-138-114 surplus planning privilege | Closed; extra matching-prefix ROADMAP or STATE lines violate exact diff cardinality. |
| T-138-115 unverifiable currentness | Closed; unavailable or mismatched live observations return nonzero `refresh_required`. |

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- One broad relation verification run timed out during temporary fixture cleanup after 180 seconds. The same command passed on the immediate clean rerun with 2 tests and 0 failures in 69.8 seconds.

## Known Stubs

None. TODO strings in the modified test support are deliberate maintained-evidence fixture payloads, not product or test stubs.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Plans 138-28 and 138-29 can continue gap closure on top of live-only source authority and bounded lifecycle classification.
- BASE-01 unclassified lifecycle forms remain fail-closed as `refresh_required`; LOOSE-01 malformed or conflicting maintained evidence remains partial.
- No schema, ledger replacement, GitHub mutation, runtime API, sidecar, or product surface was introduced.

## Self-Check: PASSED

- All three planned source/test files exist.
- All four RED/GREEN task commits exist in Git history.
- Focused, broader relation, API coverage, and shell syntax verifications passed after the final code change.
- The pre-existing `138-VERIFICATION.md` modification remains untouched and uncommitted.
- The orchestrator-owned `.planning/state.json` modification remains unstaged.

---
*Phase: 138-baseline-inventory-evidence-taxonomy*
*Completed: 2026-09-10*
