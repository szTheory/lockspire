---
quick_id: 260924-mhp
slug: classify-active-uat-records-in-the-phase
status: planned
created: 2026-09-24
description: Classify active UAT records in the Phase 138 baseline inventory from structured lifecycle status and document shape
requirements: [LOOSE-01]
files_modified:
  - scripts/maintainer/baseline_inventory.sh
  - test/support/lockspire/release_proof/package_assertions.ex
  - test/lockspire/release/repository_hygiene_contract_test.exs
must_haves:
  truths:
    - A completed, well-formed active UAT record has one resolved/already-resolved/direct_current maintained row.
    - A partial, well-formed active UAT record has one active/defer-with-trigger/direct_current maintained row.
    - An exact UAT path with missing or unknown lifecycle status or missing required document sections remains unclassified; the maintained receipt and aggregate inventory report partial.
  artifacts:
    - scripts/maintainer/baseline_inventory.sh
    - test/support/lockspire/release_proof/package_assertions.ex
    - test/lockspire/release/repository_hygiene_contract_test.exs
  key_links:
    - The active-records selector passes tracked UAT content from Git to classify_active_record, then to the canonical REC row and maintained-family completeness receipt.
---

# Quick Task 260924-mhp: Classify Active UAT Records

## Objective

Make the Phase 138 baseline inventory classify current UAT records from their exact YAML frontmatter `status` and UAT document structure, preserving proposal-only dispositions and the collector's fail-visible completeness contract. This permits Phase 139's pre-verification inventory refresh to include the current UAT records without treating incidental body prose as lifecycle authority.

## Contract Diagnosis

`classify_active_record` handles review and verification documents but has no UAT branch. A UAT record therefore falls through to the generic body-text heuristic: the tracked `138-UAT.md` has `status: complete` yet the current ledger marks it `active | fix-now`; the tracked `139-UAT.md` has `status: partial` and an outstanding lifecycle gate. Both documents have `## Current Test` and `## Tests`; the Phase 138 file has no level-one UAT title. The fix must recognize that real shape while rejecting ambiguous variants. The canonical ledger is immutable evidence and is refreshed by the existing Phase 139 finalizer, not edited by this quick task.

## Task

<task type="auto" tdd="true">
  <name>Task 1: Pin and implement structured UAT lifecycle classification</name>
  <files>scripts/maintainer/baseline_inventory.sh, test/support/lockspire/release_proof/package_assertions.ex, test/lockspire/release/repository_hygiene_contract_test.exs</files>
  <behavior>
    - The titleless `138-UAT.md` shape with byte-zero frontmatter `status: complete`, `## Current Test`, and `## Tests` yields exactly one stable REC row with `resolved | already-resolved | direct_current`, even if the body mentions actionable work.
    - The titled `139-UAT.md` shape with `status: partial` and the same required sections yields exactly one stable REC row with `active | defer-with-trigger | direct_current`; the pending test completion is the recheck trigger, not an executed action.
    - Exact `*-UAT.md` active-record paths with absent, duplicate, or unknown status, or either required section missing, produce an `unclassified/ambiguous` active-records receipt and partial aggregate, even when body text contains words that the generic heuristic recognizes.
    - Both recognized cases retain deterministic REC IDs, one row per tracked path, complete active-records and maintained receipts, and no change to review/verification classifications.
  </behavior>
  <action>Add a focused ExUnit entry point with a distinct `:phase138_maintained_uat` tag in `repository_hygiene_contract_test.exs`, delegating to a new assertion in `package_assertions.ex`. Extend the existing fake-Git maintained scenarios to return tracked UAT paths and representative complete, partial, and near-miss document blobs; assert the rendered rows by stable evidence ID, lifecycle, disposition, confidence, and family/aggregate status. Write these assertions first, observe their failing focused run, then add an exact `*-UAT.md` branch to `classify_active_record` in `baseline_inventory.sh`. Require the two UAT section headings and exact frontmatter status; allow an optional level-one title because the real Phase 138 UAT has none. Map `complete` to `resolved/already-resolved/direct_current` and `partial` to `active/defer-with-trigger/direct_current` per D-12 and D-13. For an exact UAT path whose structured classification fails, return `unclassified/unclassified/inferred` from `classify_record` before its generic prose heuristic, preserving D-07, D-17, and D-24 fail-visible behavior. Keep stable IDs, deduplication, redaction, and proposal-only authority per D-11, D-14, D-15, and D-20. Do not alter the canonical dated ledger, Phase 139 finalizer, runtime code, or public API.</action>
  <verify>
    <automated>bash -n scripts/maintainer/baseline_inventory.sh &amp;&amp; mix test test/lockspire/release/repository_hygiene_contract_test.exs --only phase138_maintained_uat &amp;&amp; git diff --check -- scripts/maintainer/baseline_inventory.sh test/support/lockspire/release_proof/package_assertions.ex test/lockspire/release/repository_hygiene_contract_test.exs</automated>
  </verify>
  <done>The focused fixture contract passes for both current UAT lifecycle states and all malformed near misses; valid records produce exactly one correctly classified proposal each, while invalid UAT records visibly downgrade inventory completeness without body-text fallback.</done>
</task>

## Source Coverage Audit

| Source | Item | Coverage |
|---|---|---|
| GOAL | Phase 139 pre-verification inventory can classify active UAT records completely | Task 1 |
| REQ | LOOSE-01 maintained follow-up inventory | Task 1 |
| RESEARCH | No new dependency or external integration; established collector and fixture patterns suffice | Level 0 discovery |
| CONTEXT | D-07, D-11–D-15, D-17, D-20, D-24 as applicable to this targeted Phase 138 repair | Task 1 |
| CONTEXT | Deferred machine-readable database and runtime/UI surface | Excluded |

## Verification

Run the task gate, then run the existing maintained-record contract entry point to confirm the new branch preserves review, verification, selector, and dedup behavior:

`mix test test/lockspire/release/repository_hygiene_contract_test.exs --only phase138_maintained_uat`

`mix test test/lockspire/release/repository_hygiene_contract_test.exs --only phase138_maintained_gap`

The executor should report any preexisting unrelated focused-gate failure separately and leave the immutable ledger untouched. The Phase 139 pre-verification finalizer remains the owner of any later ledger replacement.

## Success Criteria

- The two tracked UAT document shapes have explicit, deterministic lifecycle proposals in maintained inventory fixtures.
- Missing or malformed UAT structure/status cannot be inferred from incidental prose and is visible as partial inventory.
- Existing review and verification classification contracts pass, and only the three named maintainer script/test files change.
