---
phase: 138-baseline-inventory-evidence-taxonomy
plan: "02"
subsystem: maintainer-inventory
tags: [bash, github-cli, graphql, jq, exunit, evidence]
requires:
  - phase: 138-01
    provides: safe Git baseline collector, receipt, lock, and fixture seams
provides:
  - authenticated cursor-paginated GitHub pull-request and issue inventory
  - redacted proposal-only GitHub evidence rows with honest completeness receipts
affects: [138-03, repository-hygiene, release-maintenance]
tech-stack:
  added: []
  patterns: [safe-field allowlist, terminal-pageInfo receipts, namespace isolation, hermetic gh fixtures]
key-files:
  created: []
  modified:
    - scripts/maintainer/baseline_inventory.sh
    - test/lockspire/release/repository_hygiene_contract_test.exs
    - test/support/lockspire/release_proof/package_assertions.ex
decisions:
  - GitHub queue evidence uses independent pullRequests and issues GraphQL cursor queries.
  - Complete-zero language is reserved for a successful authenticated issue pagination receipt.
  - Merge-ready requires non-draft, approved, clean, SHA-complete, successful-check evidence; checks alone defer or need work.
coverage:
  - id: D1
    description: Authenticated GitHub queue inventory with safe pull-request evidence and honest complete-zero issue semantics.
    requirement: TRIAGE-01
    verification:
      - kind: integration
        ref: mix test test/lockspire/release/repository_hygiene_contract_test.exs#baseline inventory collector renders safe GitHub pull-request evidence
        status: pass
      - kind: integration
        ref: mix test test/lockspire/release/repository_hygiene_contract_test.exs#baseline inventory collector distinguishes complete zero open issues
        status: pass
    human_judgment: false
metrics:
  duration: 32m
  completed_date: 2026-08-28
  tasks_completed: 2
  files_modified: 3
status: complete
---

# Phase 138 Plan 02: GitHub Evidence Inventory Summary

Authenticated, cursor-paginated PR and issue evidence with safe Markdown rendering, proposal-only dispositions, and fail-visible completeness receipts.

## Tasks Completed

1. **Collect every open pull request with safe current evidence** — Added `--scope github`, authenticated repository resolution, GraphQL pagination, temporary-page parsing, duplicate corroboration, safe PR fields, and guarded `merge-ready` proposals.
2. **Collect every open issue with honest zero-result semantics** — Added an independent issue query and renderer, `GH-ISSUE-*` namespace, retain/defer proposals, and complete-only zero wording.

## Verification

- `bash -n scripts/maintainer/baseline_inventory.sh` — passed.
- `mix test test/lockspire/release/repository_hygiene_contract_test.exs` — passed (6 tests).
- `mix test test/lockspire/release_readiness_contract_test.exs` — passed (2 tests).
- `node /Users/jon/.codex/gsd-core/bin/gsd-tools.cjs check api-coverage.verify-pre .planning/phases/138-baseline-inventory-evidence-taxonomy` — passed with the documented no-integration declaration.

## Decisions Made

- Keep PR and issue pagination separate to prevent namespace overlap.
- Treat malformed pages, missing terminal `pageInfo`, authentication failures, and API failures as visible partial/unavailable evidence, never zero results.
- Redact secret-bearing fields and escape Markdown control characters before durable rendering.

## Deviations from Plan

### Auto-fixed Issues

1. **[Rule 1 - Bug] Preserve incomplete GitHub source status**
   - **Found during:** Task 2
   - **Issue:** A successful sibling query could have overwritten an earlier PR/issue failure as complete.
   - **Fix:** Only mark the GitHub receipt complete when both namespaces retain complete status; check summaries now include observed counts and Markdown controls are escaped.
   - **Files modified:** `scripts/maintainer/baseline_inventory.sh`
   - **Commit:** `bdc7d158`

2. **[Rule 2 - Critical functionality] Shared issue collector completed with the GitHub pipeline**
   - **Found during:** Task 1
   - **Issue:** The reusable GraphQL pipeline needs the isolated issue query wired at the same boundary to keep a shared receipt truthful.
   - **Fix:** Added the separate issue renderer and then pinned its zero-result behavior in Task 2’s red/green cycle.
   - **Files modified:** `scripts/maintainer/baseline_inventory.sh`, `test/support/lockspire/release_proof/package_assertions.ex`
   - **Commit:** `093d3681`

**Total deviations:** 2 auto-fixed (1 bug, 1 critical functionality). **Impact:** Tightened fail-visible and safe-rendering behavior without broadening product surface.

## Known Stubs

None. Empty shell variables are collector initialization state, not rendered placeholders.

## Self-Check: PASSED

- Modified collector and release-proof test files exist.
- Task commits `2484e52f`, `40eec201`, `c129bd7f`, `093d3681`, and `bdc7d158` exist in Git history.
