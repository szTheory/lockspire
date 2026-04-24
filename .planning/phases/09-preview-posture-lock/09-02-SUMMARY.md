---
phase: 09-preview-posture-lock
plan: 02
subsystem: testing
tags: [planning, docs, testing, oauth, oidc, release, security]
requires:
  - phase: 09-preview-posture-lock
    provides: "Canonical preview contract and aligned support-facing docs from 09-01"
provides:
  - "Release-readiness contract coverage for preview-posture drift across docs, workflows, and planning truth"
  - "Planning metadata that records PAR as the next milestone candidate while keeping it unsupported in v1.1"
  - "Executable guardrails against present-tense PAR support leakage"
affects: [preview-contract, roadmap, requirements, release-posture, contract-tests]
tech-stack:
  added: []
  patterns: ["Narrow ExUnit sentinels over trust-bearing preview claims", "Planning-only PAR future-state language with explicit v1.1 non-support"]
key-files:
  created: [.planning/phases/09-preview-posture-lock/09-02-SUMMARY.md]
  modified: [test/lockspire/release_readiness_contract_test.exs, .planning/PROJECT.md, .planning/ROADMAP.md, .planning/REQUIREMENTS.md]
key-decisions:
  - "Keep PAR future-facing in planning metadata only and state explicitly that it is not implemented or supported in v1.1"
  - "Enforce preview-posture honesty with phrase-level contract sentinels rather than snapshot-style markdown locks"
patterns-established:
  - "Preview posture checks may cross README, supported-surface docs, security policy, release guidance, workflows, and planning metadata only for trust-bearing invariants"
  - "Ignored planning artifacts can be committed selectively with forced adds when a plan explicitly scopes them"
requirements-completed: [POST-02, POST-03]
duration: 7 min
completed: 2026-04-24
---

# Phase 09 Plan 02: Preview Posture Lock Summary

**Preview-posture contract sentinels plus planning-only PAR future-state language that keeps v1.1 PAR-free and non-supported**

## Performance

- **Duration:** 7 min
- **Started:** 2026-04-24T03:30:45Z
- **Completed:** 2026-04-24T03:37:29Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments
- Extended `Lockspire.ReleaseReadinessContractTest` with narrow preview-posture sentinels across README, supported-surface docs, security policy, maintainer release guidance, workflows, and roadmap truth.
- Recorded PAR as the default next protocol-expansion milestone in planning metadata while stating explicitly that it is not implemented and not supported in `v1.1`.
- Added executable checks that reject present-tense PAR support leakage from planning truth into the current public preview posture.

## Task Commits

Each task was committed atomically:

1. **Task 1: Extend the release-readiness contract with narrow preview-posture sentinels per D-08 through D-10** - `98fbd6a` (`test`), `f3777e7` (`feat`)
2. **Task 2: Record PAR as the next milestone candidate without current-support leakage per D-11 through D-13** - `d11ff13` (`docs`)

## Files Created/Modified
- `test/lockspire/release_readiness_contract_test.exs` - Added focused sentinels for preview posture, secure defaults, and PAR future-only boundaries.
- `.planning/PROJECT.md` - Marked PAR as the default next protocol milestone and explicit non-support in `v1.1`.
- `.planning/ROADMAP.md` - Tightened phase and next-milestone wording so PAR remains planning-only and future-facing.
- `.planning/REQUIREMENTS.md` - Made `POST-03` and the v1.1 out-of-scope note explicit about PAR non-support.
- `.planning/phases/09-preview-posture-lock/09-02-SUMMARY.md` - Recorded execution results and verification evidence.

## Verification

- `mix test test/lockspire/release_readiness_contract_test.exs` after Task 1: PASS
- `rg -n "preview|v0\\.1|PAR|supported surface|private disclosure|PKCE|hex-publish" test/lockspire/release_readiness_contract_test.exs`: PASS
- `rg -n "full-file equality|heredoc|== File\\.read!|File\\.read!\\(.+==|~r/.+##" test/lockspire/release_readiness_contract_test.exs`: PASS (no matches)
- `mix docs.verify`: PASS
- `mix test test/lockspire/release_readiness_contract_test.exs` after Task 2: PASS
- `rg -n "PAR|next milestone|not supported|out of scope" .planning/PROJECT.md .planning/ROADMAP.md .planning/REQUIREMENTS.md`: PASS
- `rg -n "PAR" README.md docs/supported-surface.md SECURITY.md docs/install-and-onboard.md docs/maintainer-release.md`: PASS, with matches only in explicit out-of-scope or do-not-claim wording

## Decisions Made

- Kept the new drift checks inside the existing `Lockspire.ReleaseReadinessContractTest` module to preserve the narrow, reviewable contract-test pattern established in Phase 8.
- Used explicit `not implemented` and `not supported in v1.1` wording in planning metadata instead of softer milestone language that could leak into current support assumptions.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- `.planning/PROJECT.md`, `.planning/ROADMAP.md`, and `.planning/REQUIREMENTS.md` are ignored by the repo-wide `.gitignore`, so Task 2 required a targeted `git add -f` for only those task-owned files.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Preview-posture drift is now executable across the trust-bearing support and planning artifacts named in the phase.
- PAR is framed as the next milestone candidate without changing the current `v0.1` support surface.
- `STATE.md` was intentionally not updated during this execution, per instruction.

## Self-Check: PASSED

- Found `.planning/phases/09-preview-posture-lock/09-02-SUMMARY.md`
- Verified commits `98fbd6a`, `f3777e7`, and `d11ff13` exist in git history

---
*Phase: 09-preview-posture-lock*
*Completed: 2026-04-24*
