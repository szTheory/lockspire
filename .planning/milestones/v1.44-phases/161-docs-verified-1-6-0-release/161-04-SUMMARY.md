---
phase: 161-docs-verified-1-6-0-release
plan: 04
subsystem: release
tags: [github, ci, dialyzer, release]
requires: ["161-03"]
provides:
  - "Milestone PR #132 with exact head and required CI evidence"
  - "Approved behavior-preserving client.create Dialyzer repair"
affects: [161-05, 161-06]
tech-stack:
  added: []
key-files:
  created: []
  modified:
    - lib/mix/tasks/lockspire.client.create.ex
    - .planning/phases/161-docs-verified-1-6-0-release/161-RELEASE-EVIDENCE.md
    - .planning/phases/161-docs-verified-1-6-0-release/161-SAFE02-EVIDENCE.md
key-decisions:
  - "Existing push/PR approval persists across sessions; refreshed live remote guards before writing"
  - "Maintainer approved a scoped lib/ CI fix after Dialyzer diagnosed the raise-only helper clause"
requirements-completed: []
actuals:
  tasks: 3
  commits: 7
completed: 2026-10-20
status: complete
---

# Phase 161 Plan 04: Milestone PR and CI

PR #132 publishes v1.44 on milestone/v1.44-adopter-polish while protected main remains unchanged.

## Accomplishments

- Revalidated origin/main at 038df080748c046829f9f98297da8403c47b4d89 and opened https://github.com/szTheory/lockspire/pull/132 with the prepared title and body.
- First revision d1c9c057 passed every check except Dialyzer. After explicit maintainer approval, commit a679e9ce moved the existing validation-error raise directly into the case branch, removing its raise-only helper clause without changing formatter, message or runtime handling.
- Repeated the nine cold client-creation tests, 199-test SAFE-02 suite, zero-warning Dialyzer and formatter checks locally. Extended SAFE-02 evidence to the repaired source revision.
- Updated PR head T: c12b2c65f5705090fc7641f16b0f3e633659a733. CI run 39471393273 and Dependency Review run 39471393331.

## Task commits

1. Preflight evidence: dd3eb1ec (prior session).
2. Approval checkpoint: retained existing push/PR approval; current user directed continuation.
3. Resume/preflight d1c9c057; first-CI checkpoint c4ebec9a; approved repair a679e9ce; safety revalidation c12b2c65; final CI evidence recorded separately.

## Deviations

Required CI found a Dialyzer success-typing warning at the client.create error helper call. Per the plan's lib/ scope gate, obtained explicit maintainer approval before changing source. No new tests were needed: existing tests cover success, duplicate IDs, invalid redirects, missing options, repo failure and redaction. No dependency, protocol, schema or security-default changes.

## Verification

All seven required checks and dependency-review succeeded at T. CI run 39471393273 and Dependency Review run 39471393331 completed successfully. Remote milestone branch matches T, remote main remains 038df080, PR is OPEN and CLEAN, and Release Please Auto Merge remains disabled_manually. The final verification and evidence append were performed after CI completed.

## Next readiness

Plan 161-05 begins with the separate maintainer checkpoint for appending the prepared v1.40/v1.41 commit override to merged PR #122. No merge or publication occurred in this plan. REL-01, SAFE-02 and REL-02 remain unchecked until their prescribed later events. Final evidence and summary commits remain local after T for plan 161-06's documented preservation/reset procedure.
