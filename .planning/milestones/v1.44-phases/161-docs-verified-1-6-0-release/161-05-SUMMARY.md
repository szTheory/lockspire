---
phase: 161-docs-verified-1-6-0-release
plan: 05
subsystem: release
tags: [release-please, changelog, squash-merge]
requires: ["161-04"]
provides:
  - "PR #122 exact approved changelog override, original body preserved"
  - "PR #132 squash S1 with verified parent and tree equality"
affects: [161-06]
key-files:
  modified: [.planning/phases/161-docs-verified-1-6-0-release/161-RELEASE-EVIDENCE.md]
requirements-completed: []
actuals:
  tasks: 4
  commits: 3
completed: 2026-10-20
status: complete
---

# Phase 161 Plan 05: Changelog correction and milestone squash

Merged v1.44 as `db33c470c5deef9cc72e2240e0db0bdf0044e22b` after two separately approved maintainer actions.

## Accomplishments

- Appended the exact two-entry BEGIN_COMMIT_OVERRIDE block to merged PR #122 after explicit approval. Read-back preserves the full original body as its prefix and contains exactly one approved block. Offline parse produces two feat(admin) entries without a breaking change. Evidence commit 626880b9; body hashes recorded there.
- Maintainer separately approved squash-merging PR #132 at T `c12b2c65f5705090fc7641f16b0f3e633659a733` using its current title. Immediately before merging, checked all eight green checks, exact head, live main at 038df080, unchanged #122 body hash, and auto-merge workflow disabled_manually.
- Merged with --squash and --match-head-commit, without admin bypass. S1 parent is `038df080748c046829f9f98297da8403c47b4d89`; subject is `feat(install): add mix lockspire.gen.kek and show Key protection status in admin (v1.44) (#132)`; `git diff --quiet T S1` passed. Merge evidence commit 4739294e.
- Did not reset, stash, cherry-pick, create the backup branch, rerun Release, or edit #121 during this plan.

## Next readiness

Plan 161-06 rebinds SAFE-02 to S1, preserves planning work and state.json during the documented local-main reset, and verifies regenerated #121 by exact-head simulation before the next merge approval. REL-01 / SAFE-02 / REL-02 remain unchecked at this boundary; no package was published.
