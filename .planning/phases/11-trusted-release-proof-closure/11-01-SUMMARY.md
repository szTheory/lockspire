---
phase: 11-trusted-release-proof-closure
plan: 01
subsystem: infra
tags: [release, github-actions, hex, evidence]
requires:
  - phase: 08-trusted-release-path
    provides: canonical Release Please to protected hex-publish lane
provides:
  - protected release evidence ledger with live GitHub environment posture
  - canonical push-run proof with exact run identifiers and command evidence
  - explicit blocker record for missing environment approval protection
affects: [phase-08-verification, release-hardening, trusted-release-proof]
tech-stack:
  added: []
  patterns:
    - external trust-boundary proof captured in phase-local evidence ledgers
    - release closure blocked when environment approval is absent
key-files:
  created:
    - .planning/phases/11-trusted-release-proof-closure/11-01-PROTECTED-RELEASE-EVIDENCE.md
    - .planning/phases/11-trusted-release-proof-closure/11-01-SUMMARY.md
  modified:
    - .planning/phases/11-trusted-release-proof-closure/11-01-PROTECTED-RELEASE-EVIDENCE.md
key-decisions:
  - "Do not mark RELS-01 passed when the live hex-publish environment lacks reviewer approval, even if the push-driven publish run succeeds."
  - "Keep repo-owned release files unchanged because the contradiction was in live GitHub environment posture, not in checked-in workflow or docs truth."
patterns-established:
  - "Release proof requires exact environment API facts, run IDs, URLs, timestamps, and command evidence."
  - "Recovery-only workflow_dispatch runs are recorded as non-canonical and cannot satisfy normal release proof."
requirements-completed: []
duration: 2min
completed: 2026-04-24
---

# Phase 11 Plan 01: Protected Release Proof Closure Summary

**Live GitHub evidence proved the protected Hex lane exists and publishes on `push`, but Phase 11 stays blocked because `hex-publish` has no reviewer approval gate.**

## Performance

- **Duration:** 2 min
- **Started:** 2026-04-24T09:09:38Z
- **Completed:** 2026-04-24T09:11:20Z
- **Tasks:** 3 executed
- **Files modified:** 2

## Accomplishments

- Created a phase-local protected-release evidence ledger with the repo contract snapshot and the required live-proof buckets.
- Captured the exact live `hex-publish` environment posture, secret placement, branch restriction, and canonical `Release` run identifiers from GitHub.
- Recorded the closure blocker precisely: the canonical `push` run executed `mix release.preflight` and `mix hex.publish --yes`, but it was not an approved protected run because the environment has no reviewer rule.

## Task Commits

Each auto task was committed atomically:

1. **Task 1: Create the protected-release evidence ledger** - `aba8189` (`docs`)
2. **Task 2: Capture live GitHub proof checkpoint** - no standalone commit; live `gh` inspection was incorporated into Task 3 evidence finalization
3. **Task 3: Finalize proof artifact and reconcile drift** - `64dbdff` (`docs`)

## Files Created/Modified

- `.planning/phases/11-trusted-release-proof-closure/11-01-PROTECTED-RELEASE-EVIDENCE.md` - durable ledger with repo contract, live environment facts, canonical run proof, and the explicit blocker.
- `.planning/phases/11-trusted-release-proof-closure/11-01-SUMMARY.md` - execution summary for this blocked-but-complete plan run.

## Decisions Made

- Treat the absence of required reviewers on `hex-publish` as a hard blocker for `RELS-01`, even though the canonical run itself succeeded.
- Keep `.github/workflows/release.yml`, `docs/maintainer-release.md`, `release-please-config.json`, `.release-please-manifest.json`, `mix.exs`, and `test/lockspire/release_readiness_contract_test.exs` unchanged because live inspection exposed no repo-owned drift to reconcile.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- Live GitHub environment inspection showed `hex-publish` has branch restriction and `HEX_API_KEY`, but no reviewer approval rule. That prevents an approved protected-run proof and blocks closure.

## User Setup Required

Manual GitHub configuration is required before this plan can pass:

- Add reviewer approval protection to the `hex-publish` environment.
- Re-run the canonical `Release` workflow from a `push` on `main` so the publish job records an explicit approval state and approval timestamp before running `mix release.preflight` and `mix hex.publish --yes`.

## Next Phase Readiness

Not ready for closure. Phase 11 Plan 01 can only be re-run to `passed` after the `hex-publish` environment requires approval and a later canonical `push` run produces approved protected-run evidence.

## Self-Check: PASSED

- Found `.planning/phases/11-trusted-release-proof-closure/11-01-PROTECTED-RELEASE-EVIDENCE.md`
- Found commit `aba8189`
- Found commit `64dbdff`

---
*Phase: 11-trusted-release-proof-closure*
*Completed: 2026-04-24*
