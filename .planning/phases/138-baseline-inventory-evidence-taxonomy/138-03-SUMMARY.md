---
phase: 138
plan: "03"
subsystem: maintainer evidence collection
tags: [git, github, release-hygiene, planning]
requires: [138-01, 138-02]
provides: [canonical-baseline-ledger, maintained-record-inventory]
affects: [139, 140, 141]
tech_stack:
  added: []
  patterns: [allowlisted-source-manifest, proposal-only-evidence, stable-record-ids]
key_files:
  created:
    - .planning/phases/138-baseline-inventory-evidence-taxonomy/baseline-inventory-2026-08-28.md
  modified:
    - scripts/maintainer/baseline_inventory.sh
    - test/lockspire/release/repository_hygiene_contract_test.exs
    - test/support/lockspire/release_proof/package_assertions.ex
decisions:
  - Maintained evidence is collected only from an explicit D-17 allowlist and rendered as proposal-only REC rows.
  - Completed archive containers are retained as summaries unless evidence requires expansion.
coverage:
  - id: D1
    description: Combined proposal-only Git, GitHub, and bounded maintained-record ledger with executable currentness instructions.
    requirement: BASE-01
    verification:
      - kind: integration
        ref: mix test test/lockspire/release/repository_hygiene_contract_test.exs#baseline inventory collector accounts for maintained follow-up sources
        status: pass
      - kind: integration
        ref: mix test test/lockspire/release/repository_hygiene_contract_test.exs#complete baseline inventory renders executable currentness instructions
        status: pass
    human_judgment: false
metrics:
  tasks_completed: 2
  files_changed: 4
status: complete
---

# Phase 138 Plan 03: Baseline Inventory & Evidence Taxonomy Summary

The maintainer collector now produces one dated, proposal-only Markdown ledger covering Git, authenticated GitHub queues, and bounded maintained-record evidence.

## Completed Tasks

1. Added the D-17 maintained-source manifest, archive summaries, stable `REC-*` identities, deduplication seam, bounded tracked TODO/FIXME scan, and deterministic maintained-record Markdown renderer.
2. Collected and committed the live `baseline-inventory-2026-08-28.md` ledger with complete Git, GitHub, and maintained-family receipts.

## Verification

- `mix test test/lockspire/release/repository_hygiene_contract_test.exs` — passed (7 tests).
- `mix test test/lockspire/release_readiness_contract_test.exs` — passed (2 tests).
- `mix ci` — passed after formatting the touched contract module.
- Fresh authenticated GraphQL comparison — 6 open PRs and 0 open issues, matching ledger rows.
- Fresh Git comparison — ledger records full local `HEAD`/`main` SHA `dce02afd685aee6e6b31787248c53fdf69b69b6b` and origin/main SHA `d82eaa1c74f396c5eb5dcfa393ddd5dd952acb92` observed at collection time.

## Decisions Made

- Keep all Phase 138 dispositions proposal-only with `executed: no`; Phases 139–141 must revalidate before action.
- Preserve archive history as citable summary evidence and avoid generated/incidental tree walks.

## Deviations from Plan

### Auto-fixed Issues

1. [Rule 1 - Bug] Preserved nullable GitHub GraphQL fields during row rendering.
- **Found during:** Task 2 live audit.
- **Issue:** Tab-delimited shell parsing collapsed an empty review-decision field and shifted subsequent PR evidence columns.
- **Fix:** Switched the rendered GraphQL transport separator to an ASCII unit separator and cleaned collector-owned temporary pages.
- **Commit:** `dce02afd`.

2. [Rule 1 - Bug] Applied required formatter output to the touched release-proof module.
- **Found during:** Task 2 `mix ci` verification.
- **Fix:** Formatted the module to satisfy the repository's checked formatting gate.
- **Commit:** `d7a315e8`.

## Known Stubs

None.

## Self-Check: PASSED

- Canonical ledger exists and task commits `45e35611`, `56bc9de4`, `dce02afd`, `d7a315e8`, and `9dca8aa1` exist in Git history.
