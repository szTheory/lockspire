---
phase: 138-baseline-inventory-evidence-taxonomy
plan: "05"
subsystem: maintainer inventory
tags: [bash, git, evidence, release-hygiene, exunit]
requires:
  - phase: 138-04
    provides: safe source-receipt and Markdown-sanitization seams
provides:
  - Bounded D-17 maintained-source manifest and D-19 exclusions
  - D-18 archive summaries with narrow actionable expansion
  - Path-stable REC rows with aggregate evidence and exact maintained taxonomy
affects: [139, 140, 141, release-train]
tech-stack:
  added: []
  patterns: [bounded source families, proposal-only evidence receipts, canonical-path REC identity]
key-files:
  created: []
  modified:
    - scripts/maintainer/baseline_inventory.sh
    - test/support/lockspire/release_proof/package_assertions.ex
decisions:
  - REC identity is derived only from normalized canonical tracked paths, never a discovery family or enumeration order.
  - Fulfilled archive containers are summarized unless their bounded content proves an actionable, unresolved, contradictory, or ambiguous record.
coverage:
  - id: D1
    description: Bounded maintained taxonomy, archive summaries, path-stable identities, and explicit ambiguity receipts.
    requirement: LOOSE-01
    verification:
      - kind: integration
        ref: mix test test/lockspire/release/repository_hygiene_contract_test.exs#baseline inventory collector accounts for maintained follow-up sources
        status: pass
      - kind: integration
        ref: mix test test/lockspire/release/repository_hygiene_contract_test.exs#baseline inventory collector fails closed for maintained selectors and hostile paths
        status: pass
    human_judgment: false
metrics:
  duration: 20m
  completed_date: 2026-08-28
  tasks_completed: 2
  files_modified: 2
status: complete
---

# Phase 138 Plan 05: Baseline Inventory & Evidence Taxonomy Summary

Bounded, non-destructive maintained-follow-up collection now produces auditable source receipts, archive summaries, stable REC records, and explicit ambiguity instead of broad planning-history rows or guessed taxonomy.

## Tasks Completed

1. **Bound maintained discovery and summarize fulfilled archives**
   - Replaced planning-wide source roots with explicit D-17 selectors.
   - Applied D-19 exclusions before per-record reads and rendered per-family receipts.
   - Summarized debug, quick, and milestone archives while expanding only evidence matching the narrow predicate.
   - Commit: `478392ea`

2. **Aggregate REC identity and enforce maintained taxonomy and backstops**
   - Derived REC identity from normalized tracked paths and aggregated deterministic family references and rationale.
   - Enforced exact lifecycle, confidence, and maintained-disposition enums.
   - Routed unmatched candidates to an explicit `unclassified/ambiguous` receipt with recheck need.
   - Commit: `3399a2a7`

## Verification

- `bash -n scripts/maintainer/baseline_inventory.sh` — passed.
- `mix test test/lockspire/release/repository_hygiene_contract_test.exs` — passed (9 tests, 0 failures).
- Rendered fake-Git fixture proves archive summaries, successful-zero receipts, excluded history/generation paths, taxonomy values, supersession rationale, duplicate-family evidence aggregation, and unclassified receipts.

## Deviations from Plan

None - plan executed exactly as written.

## Security and Boundary Notes

The collector remains proposal-only and does not modify source records. It adds no product/runtime, network, credential, or host-seam surface. D-19 exclusions run before maintained per-file content reads.

## Self-Check: PASSED

- Modified collector and hermetic contract assertion files exist.
- Task commits `478392ea` and `3399a2a7` exist in Git history.
