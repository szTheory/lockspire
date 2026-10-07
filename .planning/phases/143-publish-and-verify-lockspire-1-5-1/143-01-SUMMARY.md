---
phase: publish-and-verify-lockspire-1-5-1
plan: "01"
subsystem: release
tags: [github-actions, git, release, bash, elixir, exunit]
requires:
  - phase: 142
    provides: Exact-SHA release readiness baseline and protected release workflow
provides:
  - Remote Git tag target verifier for lightweight and annotated release tags
  - Protected workflow verification before Release Please tag bookkeeping
affects: [143-02, 143-03, 143-05, 143-06, release-train]
actuals:
  tokens: 2653
  tasks: 2
  commits: 2
  plan_head_before: 936bdb48895c17cd5c99f2b352547cffa8d33861
  plan_head_after: 649243b958c8f70a601cad6c8bb076a047ef252c
tech-stack:
  added: []
  patterns:
    - Resolve remote tag refs directly and peel annotated tags before exact source-SHA comparison.
    - Validate release targets in the protected workflow before mutating Release Please tag labels.
key-files:
  created:
    - scripts/publish/verify_github_release_target.sh
  modified:
    - .github/workflows/release.yml
    - test/lockspire/release_artifact_chain_contract_test.exs
    - test/lockspire/release_workflow_artifact_contract_test.exs
key-decisions:
  - "GitHub release metadata is insufficient for an existing tag; accept only the remote ref or peeled annotated-tag target matching the verified source SHA."
requirements-completed: [REL-02]
coverage:
  - id: D1
    description: "Exact remote lightweight and annotated Git tag targets are verified against the source SHA."
    requirement: REL-02
    verification:
      - kind: integration
        ref: "test/lockspire/release_artifact_chain_contract_test.exs#GitHub release target verification accepts exact lightweight and annotated tags"
        status: pass
      - kind: integration
        ref: "test/lockspire/release_artifact_chain_contract_test.exs#GitHub release target verification rejects missing and mismatched refs"
        status: pass
      - kind: integration
        ref: "test/lockspire/release_artifact_chain_contract_test.exs#GitHub release target verification rejects malformed SHA and non-commit tag targets"
        status: pass
    human_judgment: false
  - id: D2
    description: "Both release creation and existing-release paths verify the actual tag target before Release Please bookkeeping."
    requirement: REL-02
    verification:
      - kind: unit
        ref: "test/lockspire/release_workflow_artifact_contract_test.exs#GitHub release target is checked before Release Please tag bookkeeping"
        status: pass
    human_judgment: false
duration: 10min
completed: 2026-10-07
status: complete
---

# Phase 143 Plan 01: Exact GitHub Release Target Summary

**The protected release lane now verifies lightweight and annotated GitHub tag refs against the exact verified source SHA before marking the release PR as tagged.**

## Performance

- **Duration:** 10 min
- **Started:** 2026-10-07T17:20:26Z
- **Completed:** 2026-10-07T17:30:34Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments

- Added a fail-closed helper that resolves remote tag refs and compares direct or peeled targets with the full lowercase source SHA.
- Added local bare-remote fixtures for valid lightweight and annotated tags, missing and mismatched refs, malformed SHAs, and annotated tags that point to a non-commit object.
- Wired the same target check after an existing release lookup or release creation, before Release Please tag-label mutation.

## Task Commits

1. **Task 1: End-to-end existing-tag source verification through the protected release lane** - `4b0a1513` (`feat(143-01): verify GitHub release tag targets`)
2. **Task 2: Pin the workflow contract to the dereferenced tag check** - `649243b9` (`test(143-01): pin release tag verification ordering`)

## Files Created/Modified

- `scripts/publish/verify_github_release_target.sh` - Validates the remote tag ref and peeled annotated-tag target.
- `.github/workflows/release.yml` - Requires exact tag-target verification before release-label bookkeeping.
- `test/lockspire/release_artifact_chain_contract_test.exs` - Exercises tag resolution against a temporary bare remote.
- `test/lockspire/release_workflow_artifact_contract_test.exs` - Pins workflow inputs and ordering.

## Decisions Made

GitHub's `targetCommitish` field does not prove where an existing tag resolves. The release lane now trusts the actual remote tag ref and, for annotated tags, its peeled target.

## Deviations from Plan

None - plan executed as written.

## Issues Encountered

The repository's `.tool-versions` does not select Elixir, and the default `~/.hex` cache is read-only in this environment. Focused checks passed after selecting the project's Elixir 1.19.5/OTP 28 toolchain directly and placing the Hex cache under `/private/tmp`.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 143-02 can bind the publisher's Hex client version to the same builder archive without changing the verified tag contract.

## Self-Check: PASSED

- All four changed production and test files exist.
- Both task commits are reachable from the current branch.
- The focused artifact-chain and workflow-artifact suites passed together: 12 tests, 0 failures.

---
*Phase: publish-and-verify-lockspire-1-5-1*
*Completed: 2026-10-07*
