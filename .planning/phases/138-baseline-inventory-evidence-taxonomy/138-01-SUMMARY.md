---
phase: 138
plan: "01"
subsystem: repository-maintainer evidence collection
tags: [bash, git, exunit, release-hygiene]
requires: []
provides: [safe Git baseline receipts, deterministic Git ref evidence rows]
affects: [phase-138-plan-02, phase-138-plan-03, phase-140-triage]
tech_stack:
  added: []
  patterns: [strict Bash, atomic same-directory output, hermetic ExUnit command fixtures]
key_files:
  created: [scripts/maintainer/baseline_inventory.sh]
  modified: [test/lockspire/release/repository_hygiene_contract_test.exs, test/support/lockspire/release_proof/package_assertions.ex]
decisions:
  - "The collector permits only git fetch --prune --tags REMOTE as metadata mutation and records degraded evidence visibly."
  - "Git evidence IDs derive from kind plus canonical subject through git hash-object, never list position."
coverage:
  - id: D1
    description: Safe Git baseline receipt with deterministic branch, tag, and worktree proposal rows.
    requirement: BASE-01
    verification:
      - kind: integration
        ref: mix test test/lockspire/release/repository_hygiene_contract_test.exs#baseline inventory collector renders a safe Git receipt
        status: pass
      - kind: integration
        ref: mix test test/lockspire/release/repository_hygiene_contract_test.exs#baseline inventory collector renders deterministic Git domain rows
        status: pass
    human_judgment: false
metrics:
  duration: "approximately 10 minutes"
  completed: "2026-08-28"
status: complete
---

# Phase 138 Plan 01: Baseline Inventory & Evidence Taxonomy Summary

Implemented a safe, proposal-only Git baseline collector with deterministic branch, tag, and worktree evidence rows.

## Tasks Completed

1. End-to-end current Git baseline receipt
   - Added a strict Bash collector with scoped CLI arguments, exclusive target locking, atomic same-directory output, and overwrite refusal.
   - Captures the allowed fetch receipt, full SHAs, porcelain-v2 state, correctly oriented divergence counts, UTC provenance, completeness, limitations, and redaction-safe Markdown.
   - Added a hermetic ExUnit fixture that proves the safe receipt and dangerous-command exclusions.

2. Expand the proven slice to branches, tags, and worktrees
   - Added `--scope git` collection using `git for-each-ref` and `git worktree list --porcelain`.
   - Renders stable `GIT-BR-*`, `GIT-TAG-*`, and `GIT-WT-*` proposal-only rows with the D-14 evidence fields.
   - Uses canonical-subject hashes and stable sorting, preserving distinct equal-SHA references.

## Verification

- `mix test test/lockspire/release/repository_hygiene_contract_test.exs` — passed (4 tests).
- `mix test test/lockspire/release_readiness_contract_test.exs` — passed (2 tests).
- `bash -n scripts/maintainer/baseline_inventory.sh` — passed.
- Source-policy scan found no forbidden tag pruning, ref deletion, checkout/reset, worktree removal, or history rewrite invocation.

## Commits

- `d15935eb` — test(138-01): add failing baseline inventory contract
- `383226f5` — feat(138-01): collect safe Git baseline receipts
- `432e126d` — test(138-01): add failing Git inventory domain contract
- `2679cb75` — feat(138-01): inventory Git refs tags and worktrees

## Deviations from Plan

None - plan executed exactly as written.

## Self-Check: PASSED

- Confirmed `scripts/maintainer/baseline_inventory.sh` exists.
- Confirmed all four task commits exist in Git history.
