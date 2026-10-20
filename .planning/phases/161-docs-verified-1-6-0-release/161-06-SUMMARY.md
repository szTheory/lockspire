---
phase: 161-docs-verified-1-6-0-release
plan: 06
subsystem: release
tags: [release-please, ci, exact-ref, safety]
requires: ["161-05"]
provides:
  - "SAFE-02 bound to v1.44 squash S1 with exact-tree equality"
  - "Local planning work preserved across reset and release rebase"
  - "Verified and squash-merged Release Please PR #121 with green source push CI"
affects: [161-07, 161-08, 161-09]
requirements-completed: [REL-01, SAFE-02]
key-files:
  modified:
    - .planning/phases/161-docs-verified-1-6-0-release/161-RELEASE-EVIDENCE.md
    - .planning/phases/161-docs-verified-1-6-0-release/161-SAFE02-EVIDENCE.md
    - .planning/phases/161-docs-verified-1-6-0-release/161-CONTEXT.md
actuals:
  tasks: 4
completed: 2026-10-20
status: complete
---

# Phase 161 Plan 06: Verified 1.6.0 release source

PR #121 is squash-merged as `428a9c53e02bc573376d0fcac313f047fbbea81c`, with its own successful main push CI run `39478977350` and all seven jobs success. REL-01 and SAFE-02 are satisfied; no package has been published.

## Accomplishments

- Bound SAFE-02 to S1 `db33c470c5deef9cc72e2240e0db0bdf0044e22b`: exact equality with approved T, empty forbidden-path diff, identical 36 emission matches including the scoped CI repair. Preserved nine post-T planning commits, exact state.json bytes and a backup before resetting local main onto S1.
- Re-read regenerated #121 after successful Release push run 39475380565. Verified title 1.6.0, all v1.40–v1.44 entries plus existing release entries, and exactly four release files. Actual head `14bb083562a195e99feed679a08f74f0e9fc3e75` passed hygiene (18 PASS, 0 WARN, 0 BLOCK) and 13 release contracts in a disposable worktree, removed afterward.
- Maintainer explicitly approved the exact-head squash. Before final successful merge: head unchanged, live main S1, actual PR checks all green, auto-merge disabled_manually. Used --squash --match-head-commit and no admin bypass. S parent is S1; tree exactly equals tested HEAD121; version is 1.6.0.
- CI push run 39478977350 on S completed successfully with all seven required jobs. Ordinary Release push run 39478977389 succeeded with publication jobs skipped. Preserved all 16 local planning commits and exact state.json bytes during rebase onto S, with an additional backup.

## Evidence-led plan correction

D-21's no-PR-workflows assumption was outdated. The initial normal merge was rejected by protection. Dispatch CI 39476538922 passed all seven jobs but did not clear the PR gate. Inspection found actual bot-created PR CI 39475469715 and Dependency Review 39475469657 waiting in action_required. Current GitHub docs explain bot-token PR workflow approval. Started those existing reviewed-head workflows through the normal approval API; they passed, PR became CLEAN, and the already-approved normal squash succeeded. Source, workflows and protection settings were unchanged; no admin bypass or publication attempt. Evidence and CONTEXT record the correction for future releases.

## Preservation and next readiness

Backups: backup/local-main-pre-v1.44-reset and backup/local-main-pre-release-rebase. Local main differs from origin/main only by planning files; state.json remains modified and unstaged, with exact-byte preservation verified. Evidence commit b8af3a51 records final source CI and preservation.

Next: plan 07 read-only publication preconditions, then separate authorization to set the one-use exact-SHA variable and dispatch the protected publish lane. REL-02 remains pending.
