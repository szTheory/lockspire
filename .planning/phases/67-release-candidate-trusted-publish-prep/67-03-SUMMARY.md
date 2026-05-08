---
phase: 67-release-candidate-trusted-publish-prep
plan: 67-03
subsystem: testing
tags:
  - release
  - contract-test
  - trusted-publish
  - docs
requires:
  - phase: 67-01
    provides: root package version, changelog, and package-metadata release candidate alignment
  - phase: 67-02
    provides: trusted publish lane wording, release candidate checklist, and evidence bucket boundaries
provides:
  - executable drift fences for Phase 67 release metadata and package links
  - executable drift fences for evidence-bucket wording and canonical support-contract boundaries
  - workflow job-scope assertions that keep publish-only commands inside `hex-publish`
affects:
  - phase-68-publish-verification
  - release-runbook
  - release-readiness-contract
tech-stack:
  added: []
  patterns:
    - repo-owned release readiness assertions stay string-based and offline against checked-in artifacts
    - protected publish proof is fenced by workflow-job scope, not maintainer prose alone
key-files:
  created:
    - .planning/phases/67-release-candidate-trusted-publish-prep/67-03-SUMMARY.md
  modified:
    - test/lockspire/release_readiness_contract_test.exs
key-decisions:
  - Keep Phase 67 verification offline by extending the checked-in release contract test instead of adding live Hex or GitHub checks.
  - Treat `docs/supported-surface.md` as the only support matrix and make maintainer release guidance fail if it starts mirroring public scope sections.
patterns-established:
  - "Release metadata fence: package links, root tag wording, and manifest/version/changelog alignment are asserted together."
  - "Evidence-boundary fence: checked-in docs cannot claim Hex-public proof, install-from-Hex proof, or publish success."
requirements-completed:
  - REL-01
  - REL-02
  - REL-03
metrics:
  duration: 4m
  completed: 2026-05-07
---

# Phase 67 Plan 03 Summary

**Expanded the release readiness contract test so Phase 67 release-candidate metadata, trusted-publish evidence boundaries, and support-contract posture fail fast if checked-in files drift.**

## Performance

- **Duration:** 4m
- **Started:** 2026-05-07T15:35:00Z
- **Completed:** 2026-05-07T15:39:01Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- Extended `test/lockspire/release_readiness_contract_test.exs` to assert the `1.0.0` release-candidate chain, root package naming, canonical Hex docs links, and root tag wording stay aligned across checked-in artifacts.
- Added executable drift fences for the Phase 67 release-candidate checklist, evidence buckets, and the rule that checked-in docs cannot claim Hex-public proof, install-from-Hex proof, or authenticated publish success.
- Tightened workflow assertions so `mix release.preflight` and `mix hex.publish --yes` remain isolated to the protected `publish` job inside `hex-publish`.

## Task Commits

1. **Task 1: Extend release-candidate and package-metadata assertions** - `8af7d4e` (`test`)
2. **Task 2: Add evidence-boundary and support-contract drift fences** - `58a0ea2` (`test`)

## Files Created/Modified

- `test/lockspire/release_readiness_contract_test.exs` - Adds Phase 67 metadata, evidence-boundary, and support-contract drift fences.
- `.planning/phases/67-release-candidate-trusted-publish-prep/67-03-SUMMARY.md` - Records scope, verification, and commits for this plan.

## Decisions Made

- Kept verification repo-owned and offline by asserting only checked-in files and workflow text.
- Added negative assertions against second support-matrix headings in the maintainer guide to keep `docs/supported-surface.md` canonical.

## Verification

- `MIX_ENV=test mix test test/lockspire/release_readiness_contract_test.exs`
- Result: passed after Task 1 and again after Task 2.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - this plan only changed the offline release-readiness contract test and its summary.

## Next Phase Readiness

- Phase 68 can rely on these offline drift fences before adding live publish verification.
- Protected-environment proof and Hex-public proof still remain outside checked-in Phase 67 claims.

## Known Stubs

None.

## Self-Check

PASSED.
