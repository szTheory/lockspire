---
phase: 142-merge-the-corrected-main-baseline
plan: "03"
subsystem: release-hygiene
tags: [github, exact-sha, release-readiness]
requires:
  - phase: 142-02
    provides: [conditional exact-head squash authorization for PR 112]
  - phase: 142-04
    provides: [live release hold and protected-environment controls]
provides:
  - "PR #112 merged at source SHA 5e18d118091a47966bb29300de1fd453bb0880aa after the fresh authorized merge gates passed."
  - "Successful exact-SHA acceptance and public-release truth recorded in 142-RESULT.md."
affects: [phase-143, release-readiness]
actuals:
  tokens: 3500
  tasks: 3
  commits: 1
  plan_head_before: 0761c8cfc8fdc24b2f1baa9cedc23082cd831a9a
  plan_head_after: 9e95971ef4280533cd5686c2064cd091d56cf457
tech-stack:
  added: []
  patterns: [accept exact-source handoff only from successful maintained receipt]
key-files:
  created:
    - .planning/phases/142-merge-the-corrected-main-baseline/142-RESULT.md
  modified:
    - .planning/phases/142-merge-the-corrected-main-baseline/142-03-SUMMARY.md
key-decisions:
  - "The initial local gate failure was caused by a missing GITHUB_REPOSITORY environment value; retrying the same merge SHA with the repository identity passed."
  - "The result commit is documentation outside the accepted source receipt; Phase 143 must revalidate its current main SHA before publication."
requirements-completed: [TRUTH-06, CI-09]
coverage:
  - id: D1
    description: "The specifically authorized PR head was squash-merged through the reviewed main path after all seven required checks and the live release-boundary gates passed."
    requirement: TRUTH-06
    verification:
      - kind: other
        ref: "https://github.com/szTheory/lockspire/pull/112 — merged at source SHA 5e18d118091a47966bb29300de1fd453bb0880aa"
        status: pass
      - kind: other
        ref: "https://github.com/szTheory/lockspire/actions/runs/37553870229 — canonical CI passed all seven jobs on the merge SHA"
        status: pass
    human_judgment: true
    rationale: "The merge was a consequential GitHub action authorized by the maintainer for this exact PR head and squash method."
  - id: D2
    description: "The maintained exact-SHA helper accepted the synchronized merge SHA with passing local CI, zero hygiene blockers, matching canonical CI and a successful Release no-publish run."
    requirement: CI-09
    verification:
      - kind: other
        ref: "Private receipt /private/tmp/lockspire-phase142/142-acceptance.5e18d118091a47966bb29300de1fd453bb0880aa.json; SHA-256 4f08490381f842893690b13a8f14ae9330a9ce53f1ccb82e64eed2eae87fc515; mode 0600"
        status: pass
      - kind: other
        ref: "https://github.com/szTheory/lockspire/actions/runs/37553870235 — Release push succeeded with outcome no_publish"
        status: pass
    human_judgment: true
    rationale: "The exact-SHA acceptance helper binds local mix ci, hygiene, canonical CI and Release no-publish evidence to the accepted full source SHA."
duration: "about 1h"
completed: 2026-10-07
status: complete
---

# Phase 142 Plan 03: Exact-Main Acceptance Summary

**Plan 03 completed its exact-main acceptance: PR #112 was squash-merged at `5e18d118091a47966bb29300de1fd453bb0880aa`, and the maintained exact-SHA acceptance passed for that synchronized main source. Phase 142 remains blocked at its final review/security gate.**

## Performance

- **Duration:** About 1 hour, including merge gates, one environment-corrected acceptance retry, and result recording.
- **Started:** 2026-10-07 (start timestamp was not captured at invocation).
- **Completed:** 2026-10-07.
- **Tasks completed:** 3 of 3.
- **Files recorded:** `142-RESULT.md` plus this summary.

## Accomplishments

- Rechecked the live merge boundary and the specifically authorized PR head `9d38928be44a7f137bb8f39fd1bd29f84ddf06b1`. PR #112 remained open at that head with all seven required checks green; the live protection, review policy, release hold, protected environment, closed authorization variables, paginated PR inventory, and active-run inventory remained safe for the reviewed merge path.
- Squash-merged [PR #112](https://github.com/szTheory/lockspire/pull/112) under the user's conditional authorization. The accepted merge/source SHA is `5e18d118091a47966bb29300de1fd453bb0880aa`.
- Canonical [CI run 37553870229](https://github.com/szTheory/lockspire/actions/runs/37553870229) passed all seven required jobs on the merge SHA. Push-triggered [Release run 37553870235](https://github.com/szTheory/lockspire/actions/runs/37553870235) succeeded with outcome `no_publish`; the protected package validation, publish, and public-install jobs were skipped.
- Ran `scripts/maintainer/repo_hygiene_check.sh --accept-sha 5e18d118091a47966bb29300de1fd453bb0880aa --format json --wait-seconds 1800` on synchronized `HEAD`, local `main`, and refreshed `origin/main`. With `GITHUB_REPOSITORY=szTheory/lockspire`, it passed local `mix ci` (102 ExUnit tests), hygiene (24 PASS, 0 WARN, 0 BLOCK), matching required CI and Release no-publish. No WARN dispositions were needed; OIDF remained supplemental and non-certifying.
- Retained the exact helper JSON as `/private/tmp/lockspire-phase142/142-acceptance.5e18d118091a47966bb29300de1fd453bb0880aa.json`, mode 0600, SHA-256 `4f08490381f842893690b13a8f14ae9330a9ce53f1ccb82e64eed2eae87fc515`.
- Requeried public Hex and GitHub release records at 2026-10-07 02:15:56 UTC. Hex still reported 1.5.0 as latest stable; the exact 1.5.1 endpoint returned 404. GitHub's latest matching release remained `lockspire-v1.5.0`, whose tag resolves to `5d10ce2219c2e687cf9573c8b280abfb118a47d8`; the 1.5.1 tag ref was unavailable. The dated evidence and links are in `142-RESULT.md`.
- Committed `142-RESULT.md` on the retained Phase 141 planning branch in commit `b24c62066b7f2a44c7b75f08776193ad9c68a488`. That documentation commit is outside the accepted source receipt and did not move local `main` or `origin/main`.

## Task Commits

1. **Task 1: Recheck live boundary and merge the approved PR head** — external squash merge; accepted source SHA `5e18d118091a47966bb29300de1fd453bb0880aa`.
2. **Task 2: Accept the synchronized merge SHA with the maintained receipt** — pass; receipt and its digest are listed above.
3. **Task 3: Record the exact source handoff** — initial result commit `b24c62066b7f2a44c7b75f08776193ad9c68a488`, later updated with the blocker in `9e95971ef4280533cd5686c2064cd091d56cf457`; no push to main.

**Plan metadata:** this summary is committed separately from the result document. Neither planning commit inherits the exact-source acceptance.

## Post-Merge Review Blocker

The Phase 142 code review found one blocker, CR-01: `main` can advance after the recovery SHA check and before the separate Hex upload step. The ASVS level 1 security recheck confirms T-142-10 remains open at high severity (`threats_open: 1`); see [142-REVIEW.md](142-REVIEW.md), [142-REVIEW-DISPOSITION.md](142-REVIEW-DISPOSITION.md), and [142-SECURITY.md](142-SECURITY.md). The Phase 142 exact-source acceptance remains valid for SHA `5e18d118091a47966bb29300de1fd453bb0880aa`, but Phase 143 must not publish until an enforced main freeze or equivalent serialization is implemented and verified. The updated [142-RESULT.md](142-RESULT.md) is in local documentation commit `9e95971ef4280533cd5686c2064cd091d56cf457`; it and this summary are outside the accepted source receipt.

Plan 03's three tasks are complete, but that is not phase completion: verification and roadmap completion remain blocked by CR-01/T-142-10. The user's squash authorization was for PR #112 at reviewed head `9d38928be44a7f137bb8f39fd1bd29f84ddf06b1`; no new PR was merged and no live repository setting was changed. No risk acceptance was recorded.

## Files Created/Modified

- `.planning/phases/142-merge-the-corrected-main-baseline/142-RESULT.md` — accepted source, matching CI and release evidence, retained receipt identity, dated public package observation, and Phase 143 boundary including the open blocker.
- `.planning/phases/142-merge-the-corrected-main-baseline/142-03-SUMMARY.md` — records Plan 03 completion and the separate phase-level review/security block.

## Decisions Made

- The first exact-SHA helper attempt failed locally because `GITHUB_REPOSITORY` was absent; the repo-specific local helper needs that Actions identity for its Release Please relation check. The exact same source SHA passed on retry with `GITHUB_REPOSITORY=szTheory/lockspire` set.
- The accepted receipt applies only to `5e18d118091a47966bb29300de1fd453bb0880aa`. The result commit `9e95971ef4280533cd5686c2064cd091d56cf457` and this summary commit are documentation identities outside that receipt.
- No publication action was taken. Phase 143 owns publication and must revalidate whichever full SHA is current on `main`, plus its current CI, hygiene, and live publication controls.
- The open high-severity finding blocks final Phase 142 verification. Do not mark the phase complete or start Phase 143 publication until CR-01 is resolved and the security audit is rerun.

## Deviations from Plan

Task 2 required one retry after the first local run omitted `GITHUB_REPOSITORY`. No source, gate, or acceptance criteria changed; the maintained helper passed after the environment was corrected.

**Deviations and gates:** one environment-corrected retry; the post-merge review also surfaced CR-01, which blocks final phase verification despite Plan 03's completed tasks. The exact-SHA receipt is valid for the accepted merge SHA but does not mitigate the release race.

**Phase gate:** CR-01/T-142-10 remains open at high severity. Phase-level verification and Phase 143 publication cannot proceed until the race is mitigated and the security audit passes.

## Self-Check: PASSED

- PR #112 is merged at the accepted source SHA and canonical CI run 37553870229 passed all seven jobs.
- The exact-SHA helper receipt is mode 0600 and records local CI pass, 24 PASS / 0 WARN / 0 BLOCK, required CI pass, Release `no_publish`, and supplemental non-certifying OIDF.
- Fresh public observations at 2026-10-07 02:15:56 UTC support Hex 1.5.0 as latest stable and show no 1.5.1 Hex release or GitHub tag/release.
- The updated result document is in commit `9e95971ef4280533cd5686c2064cd091d56cf457`; Phase 143 must not reuse its source acceptance and must revalidate current `main` before publication.
- The phase-level review/security gate is separate from these Plan 03 task checks; do not treat this plan self-check as phase verification.

---
*Phase: 142-merge-the-corrected-main-baseline*
*Completed: 2026-10-07*

## Final Acceptance Continuation — PR #113

The earlier CR-01/T-142-10 blocker was resolved by PR [#113](https://github.com/szTheory/lockspire/pull/113), reviewed at `084e2849a584c5d287add7693e41af37d7abd5d9` and squash-merged as `6f1a19b39999f96eb24352c75c2a0628375175ae` after the user's exact-head conditional authorization and seven green required checks. Canonical CI run [37617422181](https://github.com/szTheory/lockspire/actions/runs/37617422181) passed all seven jobs on the squash SHA. Release run [37617422018](https://github.com/szTheory/lockspire/actions/runs/37617422018) completed `no_publish`; publication, package validation, and public-install jobs were skipped.

A fresh synchronized clone accepted the exact merged-main SHA with local `mix ci` passing (102 ExUnit tests), repository hygiene at 24 PASS / 0 WARN / 0 BLOCK, matching hosted CI and Release evidence, and no warning dispositions. Its mode-0600 receipt is `/private/var/folders/f3/f0clj9rd2zb85n2c849wcsrc0000gn/T/lockspire-phase142-acceptance-6f1a19b39999f96eb24352c75c2a0628375175ae.json`, SHA-256 `9de0275ccdf269b5b66f318a5992228af302cc977dc0cb2d8b733d3261b3ea27`. The clean re-review of all eight PR #113 files recorded zero findings; the ASVS level 1 security recheck closed all 13 threats, including T-142-10. The active main-only freeze, no-bypass ruleset, exact-SHA preflight, and cleanup behavior are represented in the merged source and the updated `142-SECURITY.md`.

Read-only public checks still found Hex 1.5.0 as latest stable and no 1.5.1 release or tag. The authorization variables remained absent. Phase 142 did not dispatch a release, create a tag, approve the protected environment, or publish a package. The exact-source receipt and public truth are recorded in `142-RESULT.md`, committed on this retained branch as `bdbf3ce57c008064abd30e25fbc468310eab7c43`. This continuation supersedes the historical CR-01 blocker above. It does not authorize Phase 143 publication.
