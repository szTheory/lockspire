---
phase: 142-merge-the-corrected-main-baseline
plan: "02"
subsystem: release-hygiene
tags: [github, merge-authorization, release-gates]

requires:
  - phase: 142-01
    provides: [corrected PR content and passing local contributor gate]
  - phase: 142-04
    provides: [default-deny release controls and verified main/environment policy]
provides:
  - "Conditional squash-merge authorization bound to PR #112 and its exact reviewed head."
  - "Fresh live PR, required-check, and release-timing evidence for Plan 03."
affects: [142-03, release-readiness]

actuals:
  tokens: 1825
  tasks: 2
  commits: 0
  plan_head_before: 9912702614cf833d5930a8c42b9aab09a4e73e1e
  plan_head_after: 9912702614cf833d5930a8c42b9aab09a4e73e1e

tech-stack:
  added: []
  patterns: [exact-head human authorization conditional on green required CI]

key-files:
  created:
    - .planning/phases/142-merge-the-corrected-main-baseline/142-02-SUMMARY.md
  modified: []

key-decisions:
  - 'User response verbatim: "yes if ci green u can squash merge". It authorizes only a squash-merge attempt for PR #112 at the full reviewed SHA below, conditional on all seven required CI checks remaining green.'
  - "No Release Please opt-in, release dispatch, tag, or package publication is authorized; Plan 03 must repeat every live merge gate immediately before acting."

requirements-completed: [TRUTH-06, CI-09]

coverage:
  - id: D1
    description: "The maintainer's conditional squash-merge authorization is recorded for one exact PR head and remains contingent on green required CI."
    verification:
      - kind: other
        ref: "gh pr view 112 --json url,state,baseRefName,headRefOid,mergeable; gh pr checks 112 --required at 2026-10-07T00:17:56Z"
        status: pass
    human_judgment: true
    rationale: "The decision is the maintainer's authorization; automated checks can verify its target and conditions but cannot grant it."
  - id: D2
    description: "The release hold, current no-run timing boundary, and public 1.5.0 release truth are captured for the handoff."
    verification:
      - kind: other
        ref: "Authenticated GitHub API readbacks and complete paginated active-run census at 2026-10-07T00:16Z; https://hex.pm/api/packages/lockspire at 2026-10-07T00:17Z"
        status: pass
    human_judgment: false

duration: 2min
completed: 2026-10-06
status: complete
---

# Phase 142 Plan 02: Conditional Merge Authorization

**PR #112 has a conditional squash-merge authorization bound to its reviewed full SHA, with all seven required checks green and the release hold still closed.**

PR_URL=https://github.com/szTheory/lockspire/pull/112
APPROVED_HEAD_SHA=9d38928be44a7f137bb8f39fd1bd29f84ddf06b1

## Performance

- **Duration:** 2 min
- **Started:** 2026-10-07T00:16:23Z (continuation verification)
- **Completed:** 2026-10-07T00:18:14Z
- **Tasks:** 2
- **Files modified:** 1

## Accomplishments

- Verified PR [#112](https://github.com/szTheory/lockspire/pull/112) is open against `main`, mergeable, and still at the authorized full head `9d38928be44a7f137bb8f39fd1bd29f84ddf06b1`. The complete paginated file inventory contains 258 paths across three pages; the PR contains 84 commits. The prior Task 1 review of the complete diff remains the review basis.
- All seven required `main` checks pass for that exact head: Adoption Demo Smoke, Complete Coverage Evidence, Dialyzer, Fast Checks, Integration Checks, Minimum Supported Elixir/OTP, and Release Hygiene Drift. Main protection requires these seven checks strictly, requires a PR, dismisses stale reviews, enforces rules for admins and conversation resolution, and disallows force pushes and branch deletion.
- The repository's PR approval count is zero. PR #112 has no reviews or blocking change request, and GitHub reports it mergeable. The separate exact-head human authorization is therefore the applicable merge decision; no independent GitHub approval is claimed.
- Recorded the user's authorization verbatim: "yes if ci green u can squash merge". It applies only to a squash-merge attempt for PR #112 at the exact SHA above, and only while all seven required CI checks remain green.
- Preserved the prior timing record from 142-04: at 2026-10-06T23:09Z, no release runs were active. A fresh observation at 2026-10-07T00:16Z found no open Release Please PR and zero runs in queued, in-progress, waiting, pending, or requested states for either release workflow. The Release Please auto-merge workflow remains `disabled_manually`; the protected publish workflow is active for its normal guarded path; both `LOCKSPIRE_RELEASE_AUTOMERGE_ENABLED` and `LOCKSPIRE_PHASE143_AUTHORIZED_SHA` remain unset.
- The `hex-publish` environment remains restricted to the `main` branch and requires reviewer `szTheory` (ID 28652), with self-review allowed. This is an explicit maintainer gate, not independent review. Hex reports Lockspire 1.5.0 as the latest public package, and GitHub's latest release is `lockspire-v1.5.0`.

## Task Commits

1. **Task 1: Create the review PR and assess its live automation boundary** — completed before the checkpoint as an external PR operation; no local files or commit.
2. **Task 2: Authorize the reviewed correction PR merge** — decision verified and recorded; no production-file commit.

**Plan metadata:** This summary is the only local commit for this continuation.

## Files Created/Modified

- `.planning/phases/142-merge-the-corrected-main-baseline/142-02-SUMMARY.md` — records the exact-head authorization and live release boundary.

## Decisions Made

- The authorization remains conditional on green required CI and is limited to an attempted squash merge of PR #112 at `9d38928be44a7f137bb8f39fd1bd29f84ddf06b1`.
- The response grants no permission to enable Release Please auto-merge, set either repository variable, dispatch `release.yml`, create a tag or release, or publish Lockspire.
- Plan 03 must repeat all live PR, exact-SHA, check, review-policy, release-control, variable, candidate-PR, and active-run gates immediately before any squash-merge attempt.

## Deviations from Plan

None - plan executed as written. Task 1 completed before the blocking decision; Task 2 resumed after the explicit conditional authorization.

## Issues Encountered

The referenced predecessor executor log was not present in this worktree. The available timestamped 142-04 timing observation was retained, and the full release-control and active-run queries were refreshed for this continuation.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 02 is complete. Plan 03 may attempt the authorized squash merge only after it repeats every live gate immediately before acting and confirms PR #112 remains open at the exact authorized SHA with all seven required checks green. No merge was attempted here. Plan 03 was not executed. Phase 143 publication authority remains separate and ungranted.

## Self-Check: PASSED

- Live PR state, base, exact SHA, mergeability, required-check results, review policy, release controls, complete active-run census, and public package version were verified from read-only sources.
- This summary records the exact user response and the conditional, PR-only squash scope.
- The summary path exists, and only this summary is staged for its metadata commit.

---
*Phase: 142-merge-the-corrected-main-baseline*
*Completed: 2026-10-06*

## Post-Plan Continuation — PR #113

The later remediation review produced PR [#113](https://github.com/szTheory/lockspire/pull/113), reviewed at `084e2849a584c5d287add7693e41af37d7abd5d9`. The maintainer separately authorized its squash merge conditionally on green CI (“yes i approve if ci green i can squash merge”). All seven required checks were green for that exact head, so Plan 03 completed the authorized merge. The accepted squash SHA is `6f1a19b39999f96eb24352c75c2a0628375175ae`; canonical post-merge CI passed all seven jobs in run [37617422181](https://github.com/szTheory/lockspire/actions/runs/37617422181). The earlier PR #112 authorization above remains historical and did not authorize PR #113 by itself.
