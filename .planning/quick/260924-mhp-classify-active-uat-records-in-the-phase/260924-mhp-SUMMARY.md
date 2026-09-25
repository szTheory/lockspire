---
quick_id: 260924-mhp
slug: classify-active-uat-records-in-the-phase
status: complete
completed: 2026-09-24
description: Classify active UAT records from exact lifecycle status and document structure
requirements-completed: [LOOSE-01]
---

# Quick Task 260924-mhp Summary

The maintained inventory now classifies valid active UAT records from unique frontmatter status and required document headings, while malformed records remain visibly ambiguous.

## Completed Work

- Added a distinct `:phase138_maintained_uat` contract covering the titleless complete Phase 138 shape, titled partial Phase 139 shape, and malformed status/section near misses.
- Extended the fake-Git maintained scenarios to provide tracked UAT paths and representative blobs, including prose that must not override structured lifecycle status.
- Classified `complete` UAT records as `resolved | already-resolved | direct_current` and `partial` records as `active | defer-with-trigger | direct_current`.
- Routed exact `*-UAT.md` records with invalid structure or status to `unclassified | unclassified | inferred` before generic prose classification.
- The heading check ignores delimited frontmatter, fenced code, HTML comments, four-space indented code, and tab-indented code while accepting rendered headings with zero to three leading spaces.
- Preserved deterministic row IDs, complete receipts for valid records, partial receipts for malformed records, and existing maintained-gap behavior.

## Commits

- `c91a55c6` — `test(260924-mhp): add failing UAT lifecycle contract` (RED)
- `37a1d62c` — `feat(260924-mhp): classify active UAT lifecycle records` (GREEN)
- `2b0b768b` — `fix(260924-mhp): ignore non-rendered UAT headings`
- `785b565b` — `fix(260924-mhp): ignore non-rendered UAT headings`
- `a736ef7e` — `fix(260924-mhp): reject indented UAT code headings`

## Verification

- RED: the focused test failed on the expected assertion: the complete UAT record was incorrectly classified as `active | fix-now` by incidental prose.
- `mix test test/lockspire/release/repository_hygiene_contract_test.exs --only phase138_maintained_uat` — passed, 1 test.
- `mix test test/lockspire/release/repository_hygiene_contract_test.exs --only phase138_maintained_gap` — passed, 1 test.
- `bash -n scripts/maintainer/baseline_inventory.sh` — passed.
- `git diff --check` for the three scoped files — passed.
- Hostile near-miss contracts cover headings in fences, comments, frontmatter, and indented code; the focused UAT and maintained-gap gates both passed again after the fixes.
- Follow-up review for commit `a736ef7e` closed the reported heading-classification blockers and found no further issues.
- The system `mix` shim had no default Elixir pin; tests ran successfully with installed Elixir `1.20.2-otp-29` and Erlang `29.0.5` selected through environment variables.

## Deviations from Plan

None. The canonical dated ledger, Phase 139 finalizer, runtime code, and public API were not changed.

## Self-Check: PASSED

- The three plan-scoped files contain the test contract, fake-Git fixture scenarios, and classifier branch.
- Both task commits exist in the current Git history.
- The summary records the successful focused tests and shell/diff checks.
