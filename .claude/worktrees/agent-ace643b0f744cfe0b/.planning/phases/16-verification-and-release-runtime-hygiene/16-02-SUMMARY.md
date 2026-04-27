---
phase: 16-verification-and-release-runtime-hygiene
plan: 02
subsystem: infra
tags: [release-please, github-actions, release-hygiene, docs, exunit]
requires:
  - phase: 16-01
    provides: "Phase-16 verification discipline and milestone-close evidence shape"
provides:
  - "Repo-controlled Release Please invocation on a supported Node runtime"
  - "Unchanged protected hex-publish lane gated by release_created or recovery-only dispatch"
  - "Maintainer docs and contract tests aligned to the local action path and checked-in policy files"
affects: [release-lane, maintainer-runbook, contract-tests]
tech-stack:
  added: []
  patterns: ["Repo-controlled composite action for third-party workflow internals", "Repo-truth contract tests pin workflow and docs together"]
key-files:
  created:
    [
      .github/actions/release-please/action.yml,
      .planning/phases/16-verification-and-release-runtime-hygiene/16-02-SUMMARY.md
    ]
  modified:
    [
      .github/workflows/release.yml,
      docs/maintainer-release.md,
      test/lockspire/release_readiness_contract_test.exs
    ]
key-decisions:
  - "Swap only the Release Please implementation detail by moving it behind a checked-in composite action instead of redesigning the release workflow."
  - "Mirror the upstream action's release-then-PR behavior and root release_created output so the protected publish lane keeps the same trust boundary."
patterns-established:
  - "Release workflow internals that risk runtime deprecation should be wrapped in repo-owned actions so workflow contracts stay stable while implementations can change."
  - "Release docs and contract tests should explicitly refute deprecated workflow references when a trusted implementation swap lands."
requirements-completed: [RELS-04]
duration: 4min
completed: 2026-04-24
---

# Phase 16 Plan 02: Repo-controlled Release Please runtime on node24 with unchanged publish gating

**Release Please now runs through a checked-in composite action on `node24` while the review-only PR posture and protected `hex-publish` lane remain unchanged.**

## Performance

- **Duration:** 4 min
- **Started:** 2026-04-24T15:23:30Z
- **Completed:** 2026-04-24T15:27:21Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments

- Replaced the direct `googleapis/release-please-action` reference with a checked-in composite action that installs `release-please@17.3.0` on `node24` and preserves the `release_created` output contract.
- Kept the release workflow review-only on PR generation, recovery-only on `workflow_dispatch`, and protected on the `hex-publish` lane that still runs `mix release.preflight` and `mix hex.publish --yes`.
- Updated the maintainer guide and repo-truth contract test to pin the new local action path and explicitly reject fallback to the deprecated direct action reference.

## Task Commits

Each task was committed atomically:

1. **Task 1: Replace the Node-20-bound Release Please action with a repo-controlled supported-runtime invocation** - `084f723` (`fix`)
2. **Task 2: Align maintainer docs and repo-truth tests with the unchanged release contract** - `03fc9c4` (`docs`)

## Files Created/Modified

- `.github/actions/release-please/action.yml` - Composite action that runs Release Please on `node24`, mirrors root-component outputs, and keeps checked-in config and manifest as the policy source.
- `.github/workflows/release.yml` - Switches the Release Please step to the local action while preserving the existing publish gate and protected environment.
- `docs/maintainer-release.md` - Documents the repo-controlled invocation path as part of repo-owned proof and preflight review.
- `test/lockspire/release_readiness_contract_test.exs` - Extends the contract to assert the local action path, supported runtime, and absence of the deprecated direct action dependency.
- `.planning/phases/16-verification-and-release-runtime-hygiene/16-02-SUMMARY.md` - Records plan outcome, commits, and verification.

## Decisions Made

- Used a checked-in composite action rather than another direct marketplace action reference so future runtime swaps stay behind the same workflow contract.
- Kept the upstream release ordering semantics by creating releases before release PRs, preserving `release_created` as the publish-lane signal.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- `RELS-04` is now satisfied in-repo with a supported runtime and unchanged release semantics.
- The release lane remains ready for future verification evidence without reopening publish policy or maintainer expectations.

## Self-Check: PASSED

- Verified `.github/actions/release-please/action.yml`, `.github/workflows/release.yml`, `docs/maintainer-release.md`, `test/lockspire/release_readiness_contract_test.exs`, and `.planning/phases/16-verification-and-release-runtime-hygiene/16-02-SUMMARY.md` exist.
- Verified commits `084f723` and `03fc9c4` exist in `git log`.

---
*Phase: 16-verification-and-release-runtime-hygiene*
*Completed: 2026-04-24*
