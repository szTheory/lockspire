---
phase: 138-baseline-inventory-evidence-taxonomy
plan: "12"
subsystem: release-maintenance
tags: [github, graphql, pagination, evidence-integrity, fail-closed]
requires:
  - phase: 138-11
    provides: Immutable baseline ledger publication and bounded currentness classification.
provides:
  - Complete per-pull-request CheckRun and StatusContext pagination with explicit terminal-success evaluation.
  - Strict outer GraphQL page-chain validation and contradiction-aware duplicate corroboration.
  - End-to-end adversarial regressions proving incomplete GitHub evidence cannot acquire disposition authority.
affects: [phase-138-verification, phase-139, phase-140, github-triage]
actuals:
  tokens: 8192
  tasks: 2
  commits: 5
tech-stack:
  added: []
  patterns: [two-stage GraphQL connection collection, exact normalized duplicate agreement, fail-closed partial receipts]
key-files:
  created: [".planning/phases/138-baseline-inventory-evidence-taxonomy/138-12-SUMMARY.md"]
  modified: ["scripts/maintainer/baseline_inventory.sh", "test/lockspire/release/repository_hygiene_contract_test.exs", "test/support/lockspire/release_proof/package_assertions.ex"]
key-decisions:
  - "Collect each pull request's statusCheckRollup contexts through a dedicated cursor query so nested completeness is proven independently of outer PR pagination."
  - "Treat duplicate GitHub node IDs as corroboration only when every normalized decision-bearing field agrees; remove contradictory identities from renderable rows and make the namespace partial."
patterns-established:
  - "Nested connection proof: totalCount, every pageInfo transition, cursor progression, terminal page, and normalized context count must agree before checks are complete."
  - "Duplicate proof: group normalized outer nodes by immutable ID, retain byte-equivalent groups deterministically, and disclose contradictions without action authority."
requirements-completed: [TRIAGE-01, TRIAGE-02]
coverage:
  - id: D1
    description: Pending, legacy-failing, unknown, malformed, or incompletely paginated PR checks remain non-actionable while complete terminal-success checks can support merge-ready.
    requirement: TRIAGE-01
    verification:
      - kind: integration
        ref: test/lockspire/release/repository_hygiene_contract_test.exs#baseline inventory collector requires complete GitHub check evidence
        status: pass
    human_judgment: false
  - id: D2
    description: Contradictory duplicate identities and impossible outer GraphQL page chains make the exact namespace and aggregate partial before rendering.
    requirement: TRIAGE-02
    verification:
      - kind: integration
        ref: test/lockspire/release/repository_hygiene_contract_test.exs#baseline inventory collector rejects contradictory duplicates and impossible page chains
        status: pass
    human_judgment: false
  - id: D3
    description: Deterministic PR and issue namespace ordering, complete-zero issue wording, redaction, and maintainer-only product boundaries remain intact.
    requirement: TRIAGE-02
    verification:
      - kind: integration
        ref: mix test test/lockspire/release/repository_hygiene_contract_test.exs
        status: pass
      - kind: integration
        ref: mix test test/lockspire/release_readiness_contract_test.exs
        status: pass
      - kind: other
        ref: node /Users/jon/.codex/gsd-core/bin/gsd-tools.cjs check api-coverage.verify-pre .planning/phases/138-baseline-inventory-evidence-taxonomy
        status: pass
    human_judgment: false
duration: 18min
completed: 2026-08-28
status: complete
---

# Phase 138 Plan 12: GitHub Evidence Integrity Summary

**Complete nested PR check collection and contradiction-aware outer pagination now prevent incomplete or inconsistent GitHub evidence from producing affirmative dispositions.**

## Performance

- **Duration:** 18 min
- **Started:** 2026-08-28T22:50:39Z
- **Completed:** 2026-08-28T23:08:39Z
- **Tasks:** 2/2
- **Files modified:** 3

## Accomplishments

- Added per-PR cursor pagination for allowlisted CheckRun and StatusContext tuples, with total-count and page-chain completeness proof and explicit terminal-success evaluation.
- Replaced ID-only duplicate collapse with exact normalized agreement, strict outer cursor progression, deterministic corroboration, and stable contradiction receipts.
- Added production-CLI fixtures for pending/null states, legacy failures, terminal and unknown conclusions, more than 100 nested contexts, malformed nested evidence, contradictory duplicates, and impossible outer chains.

## Task Commits

Each task was committed through its RED and GREEN gates:

1. **Task 1 RED: GitHub check completeness contract** — `1372fe35` (test)
2. **Task 1 GREEN: Complete nested PR check evidence** — `b9457eec` (feat)
3. **Task 2 RED: Duplicate and page-chain contracts** — `3eb3b3a6` (test)
4. **Task 2 GREEN: Contradiction-aware page evidence** — `e70809ca` (feat)

## Files Created/Modified

- `scripts/maintainer/baseline_inventory.sh` — two-stage outer/nested GraphQL collection, complete check evaluation, page-chain validation, and exact duplicate corroboration.
- `test/support/lockspire/release_proof/package_assertions.ex` — adversarial fake GitHub page streams and exported completeness/consistency assertions.
- `test/lockspire/release/repository_hygiene_contract_test.exs` — focused end-to-end entry points for check completeness and duplicate/page-chain integrity.
- `.planning/phases/138-baseline-inventory-evidence-taxonomy/138-12-SUMMARY.md` — canonical execution evidence for the plan.

## Decisions Made

- Nested status contexts are collected with a separate PullRequest-node GraphQL query. This prevents outer PR pagination mechanics from silently bounding or confusing the nested connection.
- Only CheckRun `COMPLETED` plus `SUCCESS`, and StatusContext `SUCCESS`, count as terminal success. Known terminal failures are failed; pending, missing, and unrecognized values remain unknown.
- Duplicate outer nodes are grouped only after normalization. Contradictory groups are excluded from safe rendered rows, disclosed by stable identity, and make both the namespace and aggregate partial.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Preserved successful collector exit for malformed namespaces with no safe rows**
- **Found during:** Task 1 full focused-suite verification
- **Issue:** The new partial-row rendering guard returned the failed file predicate's status when a malformed namespace had no combined file, causing an intended partial receipt to exit nonzero.
- **Fix:** Made the no-safe-row branch return success explicitly after rendering the partial limitation.
- **Files modified:** `scripts/maintainer/baseline_inventory.sh`
- **Verification:** Failure-receipt and aggregate fail-closed focused tests passed, followed by the complete 20-test focused suite.
- **Committed in:** `b9457eec`

---

**Total deviations:** 1 auto-fixed (1 Rule 1 bug). **Impact on plan:** The correction preserves the existing contract that source failures publish visible partial evidence while preventing affirmative authority; no scope expansion.

## Issues Encountered

- The focused contract is process-heavy because every scenario executes the production Bash collector; the final 20-test run completed in 82.8 seconds with zero failures.
- The state advance handler started from a stale `Plan: 1 of 16` body field and reported Plan 2 even though twelve summaries exist. ROADMAP's disk-derived counter correctly reported 12/16, so STATE was aligned to that same completed-summary truth before the metadata commit.

## Known Stubs

None. Empty shell variables added by this plan are transient collector state, not placeholder product data.

## Security and Boundary Notes

- T-138-47 is closed by complete allowlisted CheckRun and StatusContext pagination with stable per-PR limitation receipts.
- T-138-48 is closed by explicit terminal-success evaluation and aggregate disposition-authority suppression.
- T-138-49 is closed by page-chain validation and exact normalized duplicate agreement before rendering.
- T-138-50 is preserved: queries retain only identifiers, status fields, refs, SHAs, check names/states/conclusions, counts, and cursor metadata; no bodies, comments, logs, headers, credentials, environment values, or tokens cross the collector boundary.
- No runtime endpoint, authentication path, schema, package dependency, Mix task, or product API surface was introduced.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Verification gaps 2 and 10 now have exact adversarial regression coverage through the production `--scope github` path.
- Plan 138-13 can continue the remaining gap-closure sequence; GitHub disposition authority now fails closed on incomplete nested evidence, contradictory identities, and impossible page chains.

## Self-Check: PASSED

- Confirmed all three modified implementation/test files and this summary exist.
- Confirmed commits `1372fe35`, `b9457eec`, `3eb3b3a6`, and `e70809ca` exist in plan order.
- Re-ran shell syntax, the focused 20-test repository-hygiene contract, the 2-test release-readiness contract, and API-coverage preflight with successful results.
- Confirmed no skipped tests, unrun verification steps, product-surface additions, or goal-blocking stubs remain in this plan.

---
*Phase: 138-baseline-inventory-evidence-taxonomy*
*Completed: 2026-08-28*
