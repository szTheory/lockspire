---
phase: 67-release-candidate-trusted-publish-prep
plan: 67-02
subsystem: release
tags:
  - trusted-publish
  - release-please
  - workflow
  - docs
requires:
  - phase: 67-01
    provides: root package version, changelog, and tag-target release-candidate alignment
provides:
  - explicit trusted publish lane boundary and recovery-only replay contract
  - maintainer release-candidate checklist tied to repo-owned artifacts
  - checked-in root tag expectations for the root Lockspire package
affects:
  - phase-68-publish-verification
  - release-runbook
  - trusted-release-workflow
tech-stack:
  added: []
  patterns:
    - repo-controlled Release Please shim remains the only workflow entry point
    - protected-environment proof starts only at the single hex-publish boundary
key-files:
  created:
    - .planning/phases/67-release-candidate-trusted-publish-prep/67-02-SUMMARY.md
  modified:
    - .github/workflows/release.yml
    - .github/actions/release-please/action.yml
    - docs/maintainer-release.md
key-decisions:
  - Keep Phase 67 strictly pre-publish by documenting where checked-in proof ends and protected-environment proof begins.
  - Preserve root release tag truth in the repo-controlled Release Please action and surface it in the trusted workflow contract.
patterns-established:
  - "Release candidate checklist: review version files, workflow files, and support-contract docs together before merge."
  - "Trusted publish boundary: mix release.preflight and mix hex.publish --yes belong only to the protected hex-publish environment."
requirements-completed:
  - REL-01
  - REL-02
  - REL-03
metrics:
  duration: 12m
  completed: 2026-05-07
---

# Phase 67 Plan 02 Summary

**Explicit trusted-publish lane contract, root tag expectations, and maintainer release-candidate checklist that stop at the single protected `hex-publish` boundary.**

## Performance

- **Duration:** 12m
- **Started:** 2026-05-07T15:23:44Z
- **Completed:** 2026-05-07T15:35:32Z
- **Tasks:** 1
- **Files modified:** 4

## Accomplishments

- Made `.github/workflows/release.yml` explicitly carry the root `tag_name` output forward, restate the `lockspire-v<version>` contract, and mark the exact point where protected publish proof begins.
- Kept `.github/actions/release-please/action.yml` as the repo-controlled Release Please shim while making root tag output preservation part of the checked-in contract.
- Added a maintainer release-candidate checklist in `docs/maintainer-release.md` that names file reviews, repo-owned commands, evidence buckets, recovery-only replay semantics, and deference to `docs/supported-surface.md`.

## Task Commits

1. **Task 1: Make the trusted publish lane and release-candidate checklist explicit** - `07b8529` (`chore`)

## Files Created/Modified

- `.github/workflows/release.yml` - Explicitly documents root tag handoff and the single protected `hex-publish` boundary.
- `.github/actions/release-please/action.yml` - Tightens the repo-controlled Release Please shim around root tag output behavior.
- `docs/maintainer-release.md` - Adds the explicit release-candidate checklist and checked-in versus protected proof boundary.
- `.planning/phases/67-release-candidate-trusted-publish-prep/67-02-SUMMARY.md` - Records execution, verification, and decisions for this plan.

## Decisions Made

- Kept the trusted publish lane narrow: no new publish behavior was introduced beyond explicit checked-in guardrails.
- Documented the current `1.0.0` root tag expectation as `lockspire-v1.0.0` while preserving the generic `lockspire-v<version>` contract for future root releases.

## Verification

- Ran the plan verification command:

```bash
rg 'environment: hex-publish|workflow_dispatch:|recovery_reason|recovery_ref|mix release.preflight|mix hex.publish --yes' .github/workflows/release.yml && rg 'uses: composite|node-version: "24"|node \.github/actions/release-please/runtime/index.js|tag_name|release_created' .github/actions/release-please/action.yml && rg 'Repo-owned proof|GitHub settings proof|Workflow-run proof|Release candidate checklist|tag target|supported-surface' docs/maintainer-release.md
```

- Result: passed.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - this plan only tightened checked-in workflow and runbook artifacts.

## Next Phase Readiness

- Phase 68 can now validate real publish execution against an explicit pre-publish contract.
- The trusted lane still preserves one protected `hex-publish` boundary and does not claim Hex-public proof prematurely.

## Known Stubs

None.

## Self-Check

PASSED.
