---
phase: publish-and-verify-lockspire-1-5-1
plan: "02"
subsystem: release
tags: [hex, github-actions, artifact, release, elixir, exunit]
requires:
  - phase: 143-01
    provides: Exact remote GitHub release tag target verification.
provides:
  - Manifest-bound Hex publisher version copied from the builder Hex version.
  - Prepublish API-export and exact-byte compatibility receipt, with the same checks in the protected publisher before credentials.
  - Regression evidence that the direct Hex uploader receives the manifest-bound package bytes unchanged.
affects: [143-03, 143-04, 143-05, 143-06, release-train]
actuals:
  tokens: 5110
  tasks: 2
  commits: 2
  plan_head_before: 820ab599deaa907ae6c3c0efe0e5aa96444636f7
  plan_head_after: 1f97eb0a60ae56a2517a6a2294b74d631862ba97
tech-stack:
  added: []
  patterns:
    - Isolate builder and publisher MIX_HOME directories and install the exact archive version captured by the artifact manifest.
    - Treat the internal Hex upload API as version-bound and require API-export plus exact-byte fixture proof before publication.
key-files:
  created: []
  modified:
    - .github/workflows/release.yml
    - scripts/publish/release_artifact.py
    - test/lockspire/release_artifact_chain_contract_test.exs
    - test/lockspire/release_workflow_artifact_contract_test.exs
    - docs/maintainer-release.md
key-decisions:
  - "runtime.publisher_hex mirrors runtime.hex; there is no independently selected publisher archive version."
  - "The unlisted runbook update was included because an explicit acceptance criterion requires documenting the internal API caveat and exact-byte evidence."
requirements-completed: [REL-02]
coverage:
  - id: D1
    description: "The manifest binds the publisher Hex archive to the exact builder archive, and the protected job checks that archive before credentials."
    requirement: REL-02
    verification:
      - kind: unit
        ref: "test/lockspire/release_artifact_chain_contract_test.exs#manifest publisher Hex version must match the builder Hex version"
        status: pass
      - kind: unit
        ref: "test/lockspire/release_workflow_artifact_contract_test.exs#protected publish validates downloaded data from a fresh exact-SHA checkout"
        status: pass
    human_judgment: false
  - id: D2
    description: "The prepublish receipt records API export and exact-byte fixture proof tied to the manifest version."
    requirement: REL-02
    verification:
      - kind: integration
        ref: "test/lockspire/release_artifact_chain_contract_test.exs#prepublish receipt records successful manifest-bound publisher compatibility"
        status: pass
      - kind: unit
        ref: "test/lockspire/release_workflow_artifact_contract_test.exs#unprivileged prepublish proof carries one SHA-bound package identity"
        status: pass
    human_judgment: false
  - id: D3
    description: "The uploader fixture proves the bytes and checksum sent to Hex match the verified manifest tar."
    requirement: REL-02
    verification:
      - kind: integration
        ref: "test/lockspire/release_artifact_chain_contract_test.exs#exact-artifact uploader sends the supplied tar bytes without rebuilding"
        status: pass
      - kind: other
        ref: "actionlint .github/workflows/release.yml"
        status: pass
    human_judgment: false
duration: 7min
completed: 2026-10-07
status: complete
---

# Phase 143 Plan 02: Manifest-Bound Hex Publisher Summary

**The protected publisher now installs the exact Hex archive captured by the builder and proves its direct upload API and unchanged package bytes before credential use.**

## Performance

- **Duration:** 7 min
- **Started:** 2026-10-07T17:33:09Z
- **Completed:** 2026-10-07T17:40:33Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments

- Added `runtime.publisher_hex` as a strict manifest field equal to builder `runtime.hex`; the protected job installs that value in an isolated `MIX_HOME` and confirms the runtime version and `Hex.API.Release.publish/5` export before credentials.
- Added prepublish compatibility receipt fields for selected Hex version, API export, and exact-byte fixture result; receipt generation fails closed on version mismatch or absent proof.
- Extended the upload fixture to compare captured byte count and SHA-256 with the manifest, and documented the internal API limitation and evidence review in the maintainer runbook.

## Task Commits

1. **Task 1: Bind the publisher to the exact builder Hex archive** - `14cd1f2b` (`feat(143-02): bind Hex publisher to builder archive`)
2. **Task 2: Prove the protected uploader publishes the manifest-bound bytes** - `1f97eb0a` (`test(143-02): prove manifest-bound upload bytes`)

## Files Modified

- `.github/workflows/release.yml` - Installs and checks the manifest-recorded archive in unprivileged and protected jobs.
- `scripts/publish/release_artifact.py` - Validates publisher version equality and records prepublish compatibility evidence.
- `test/lockspire/release_artifact_chain_contract_test.exs` - Covers manifest mismatch, receipt proof, and exact uploaded bytes.
- `test/lockspire/release_workflow_artifact_contract_test.exs` - Pins workflow ordering, exact version install, compatibility checks, and receipt fields.
- `docs/maintainer-release.md` - Explains the version-bound internal API and proof fields operators review.

## Decisions Made

- The builder's `runtime.hex` remains the sole version source. The new `runtime.publisher_hex` is a validated copy, not a separate version choice.
- Treat `Hex.API.Release.publish/5` as an undocumented, version-bound API; record proof only for the selected archive and make no compatibility-range claim.

## Deviations from Plan

Updated `docs/maintainer-release.md`, although it was not included in the task's `files_modified` list, because the task's acceptance criteria explicitly require the API caveat and exact-byte evidence in the maintainer runbook.

## Issues Encountered

`actionlint` rejected a runner-context expression when `MIX_HOME` was initially placed at job scope. Moving it to the relevant steps resolved the workflow validation. The final focused suites passed with no warnings.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 143-03 can add terminal outcome receipts on top of the manifest and publisher proof now recorded before protected publication.

## Self-Check: PASSED

- Both task commits are reachable from the current branch.
- `actionlint .github/workflows/release.yml`, `git diff --check`, and Python AST parsing passed.
- The focused artifact-chain and workflow-artifact suites passed together: all 14 tests passed.

---
*Phase: publish-and-verify-lockspire-1-5-1*
*Completed: 2026-10-07*
