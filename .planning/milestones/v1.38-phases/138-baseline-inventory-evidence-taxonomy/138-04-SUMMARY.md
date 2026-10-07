---
phase: 138-baseline-inventory-evidence-taxonomy
plan: "04"
subsystem: maintainer evidence collection
tags: [bash, git, github-cli, graphql, sanitization, exunit]
requires:
  - phase: 138-03
    provides: canonical inventory collector and hermetic contract harness
provides:
  - Fail-closed per-domain Git source receipts and aggregate snapshot completeness
  - Distinct GitHub failure codes plus credential and control-byte-safe rendered fields
affects: [phase-138-verification, phase-139-reconciliation]
tech-stack:
  added: []
  patterns: [receipt-driven source completeness, failure-class preserving GraphQL parsing, boundary sanitization]
key-files:
  created: []
  modified:
    - scripts/maintainer/baseline_inventory.sh
    - test/support/lockspire/release_proof/package_assertions.ex
    - test/lockspire/release/repository_hygiene_contract_test.exs
key-decisions:
  - "A valid empty Git query is complete evidence; malformed and nonzero outcomes remain partial or unavailable."
  - "GitHub authentication, API, JSON, node, pageInfo, and cursor failures retain distinct receipt codes."
requirements-completed: [BASE-01, BASE-02, TRIAGE-01, TRIAGE-02]
coverage:
  - id: D1
    description: Per-domain Git receipt completeness distinguishes empty, malformed, unavailable, and unknown conditions.
    requirement: BASE-02
    verification:
      - kind: unit
        ref: test/lockspire/release/repository_hygiene_contract_test.exs#fails closed for malformed or unavailable Git domains
        status: pass
    human_judgment: false
  - id: D2
    description: GitHub failure classes and hostile rendered fields remain fail-visible and redacted.
    requirement: TRIAGE-01
    verification:
      - kind: unit
        ref: test/lockspire/release/repository_hygiene_contract_test.exs#keeps GitHub failure receipts distinct and sanitizes fields
        status: pass
    human_judgment: false
duration: 19min
completed: 2026-08-28
status: complete
---

# Phase 138 Plan 04: Baseline Inventory & Evidence Taxonomy Summary

**Fail-closed Git and GitHub inventory receipts now preserve source-specific failures while preventing credential-like or control-byte-bearing remote text from reaching durable Markdown evidence.**

## Performance

- **Tasks:** 2/2
- **Files modified:** 3
- **Verification:** `bash -n`, focused ExUnit inventory contracts, and API-coverage preflight passed.

## Accomplishments

- Added complete, partial, and unavailable receipts for branch, tag, and worktree collection; valid empty output remains explicit successful-zero evidence.
- Aggregated every requested source before assigning snapshot completeness, so fetch success cannot hide a failed sibling source.
- Preserved distinct `null_nodes`, `malformed_json`, `malformed_page_info`, `premature_pagination`, `auth_failed`, and `api_failed` GitHub receipts.
- Redacted case-insensitive credential markers and removed C0/C1 control bytes at the GitHub rendering boundary.

## Task Commits

1. **Task 1: Make every Git inventory domain receipt-driven and fail-closed** — `bf623bc0`, `b900f5b2`
2. **Task 2: Preserve distinct GitHub failures and sanitize hostile rendered fields** — `7407d4bb`

## Decisions Made

- Empty source output is only successful-zero after a valid command and complete grammar validation.
- Failure reasons stay in the receipt rather than collapsing into a generic pagination status.

## Deviations from Plan

None - plan executed exactly as written.

## Verification

- `bash -n scripts/maintainer/baseline_inventory.sh` — passed
- `mix test test/lockspire/release/repository_hygiene_contract_test.exs` — passed (9 tests, 0 failures)
- `node /Users/jon/.codex/gsd-core/bin/gsd-tools.cjs check api-coverage.verify-pre .planning/phases/138-baseline-inventory-evidence-taxonomy` — passed

## Self-Check: PASSED

- All modified collector and contract files exist.
- Task commits `bf623bc0`, `b900f5b2`, and `7407d4bb` exist in Git history.

## Next Phase Readiness

The inventory collector now supplies honest source status for later reconciliation without widening product or external-integration surface.
