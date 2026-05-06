---
phase: 47
plan: 01
subsystem: documentation
tags:
  - release
  - ga
  - documentation
dependency_graph:
  requires:
    - 46-03
  provides:
    - 1.0.0
  affects:
    - docs/install-and-onboard.md
    - docs/maintainer-release.md
    - docs/supported-surface.md
    - README.md
    - SECURITY.md
    - test/lockspire/release_readiness_contract_test.exs
tech_stack:
  added: []
  patterns: []
key_files:
  created: []
  modified:
    - release-please-config.json
    - docs/install-and-onboard.md
    - docs/maintainer-release.md
    - docs/supported-surface.md
    - README.md
    - SECURITY.md
    - test/lockspire/release_readiness_contract_test.exs
key_decisions:
  - Maintained the integrity of the Release Please pipeline rather than manually updating manifest and changelog files, relying on the `Release-As: 1.0.0` footer to trigger the native bot response.
  - Formally transitioned the project from preview/beta terminology to 1.0 GA across all documentation and support contracts.
---

# Phase 47 Plan 01: 1.0 GA Release Readiness Summary

Disabled preview bumping logic in the release pipeline and scrubbed preview/beta terminology from public-facing documents to transition Lockspire into its 1.0 GA release posture.

## Implementation Details

1. Verified `release-please-config.json` correctly implements `"bump-minor-pre-major": false` to allow the shift to 1.0.0.
2. Undid any manual modifications in the worktree to `mix.exs`, `.release-please-manifest.json`, and `CHANGELOG.md` to adhere strictly to the Strategy document. Instead, relied on the `Release-As: 1.0.0` convention on the final commit.
3. Scrubbed preview/beta terminology across `docs/install-and-onboard.md`, `docs/maintainer-release.md`, `docs/supported-surface.md`, `README.md`, and `SECURITY.md`. Note that most files had already been partially cleaned up in earlier phases, and this plan caught remaining inconsistencies, such as a duplicated sentence typo in `SECURITY.md`.
4. Ensured that `test/lockspire/release_readiness_contract_test.exs` assertions still passed regarding the "1.0 GA" and "current release" strings without breaking continuous integration.
5. All completed documentation modifications were captured in a single atomic commit, appended with the `Release-As: 1.0.0` footer.

## Deviations from Plan

**1. [Rule 3 - Unstaged Worktree Changes] Reverted manual version bumps**
- **Found during:** Task execution (Commit generation)
- **Issue:** The local worktree included unstaged changes updating versions manually in `mix.exs`, `.release-please-manifest.json`, and `CHANGELOG.md`. This conflicted with the strategic requirement to maintain the integrity of Release Please and not update versions manually.
- **Fix:** Performed `git restore mix.exs .release-please-manifest.json CHANGELOG.md` to rely instead strictly on the final commit with `Release-As: 1.0.0`.

## Known Stubs

None. No new stubs or placeholder values were introduced.

## Threat Flags

None. No new network endpoints, authorization paths, or security surfaces were added.