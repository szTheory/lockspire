---
phase: 142-merge-the-corrected-main-baseline
plan: "04"
subsystem: release-engineering
tags: [github-actions, github-protection, mix-ci, phase-finalizer]
requires:
  - phase: 142-01
    provides:
      - corrected Phase 141 release-train baseline
      - archived-path release fixtures and contributor gate
provides:
  - live release hold with verified main and protected-environment controls
  - archived-phase-aware finalizer root detection and portable regression coverage
  - default-deny release authorization tied to the exact current main SHA
affects: [142-02, phase-142, release-train, release-workflows]
actuals:
  tokens: 5297.25
  tasks: 3
  commits: 4
  plan_head_before: ae8693d0ac8fbcc7d5d6d7b0feeb6f84fbaf3f16
  plan_head_after: 7d38b04c58df10725959040a316afe50ab8b7b98
tech-stack:
  added: []
  patterns:
    - fail-closed release authorization immediately before package upload
    - root detection accepts active and archived phase layouts
key-files:
  created:
    - .planning/phases/142-merge-the-corrected-main-baseline/142-04-SUMMARY.md
  modified:
    - tools/gsd-capabilities/lockspire-phase-finalizer/lockspire-finalize-command-router.cjs
    - tools/gsd-capabilities/lockspire-phase-finalizer/lockspire-finalize-command-router.test.cjs
    - .github/workflows/release-please-automerge.yml
    - .github/workflows/release.yml
    - test/lockspire/release_ci_evidence_contract_test.exs
    - docs/maintainer-release.md
key-decisions:
  - "Keep Release Please auto-merge disabled and both authorization variables absent throughout Phase 142; Phase 143 may authorize only one exact SHA."
  - "With szTheory as the only eligible reviewer, require explicit hex-publish environment approval with self-review allowed, and record that it is not independent review; main therefore requires a PR but zero GitHub approvals."
  - "Accept both active and archived phase layouts while preserving maintainer-script checks and child-process exit semantics."
requirements-completed: [TRUTH-06, CI-09]
coverage:
  - id: D1
    description: "Live release automation remains held behind main protection and an explicit protected-environment reviewer gate."
    verification:
      - kind: other
        ref: "GitHub API readback at 2026-10-06T23:09Z: auto-merge workflow disabled; hex-publish restricted to main with required reviewer; main has seven strict required checks, PR requirement, admin enforcement, stale-review dismissal, and no force pushes or deletions."
        status: pass
      - kind: other
        ref: "Paginated release workflow run inventories before and after the hold, and final in-progress queries: no active runs."
        status: pass
    human_judgment: false
  - id: D2
    description: "The finalizer routes valid archived project roots while rejecting unrelated roots and preserving lifecycle exit behavior."
    requirement: CI-09
    verification:
      - kind: integration
        ref: "LOCKSPIRE_SKIP_BEAM_INTEGRATION=1 LOCKSPIRE_GSD_HOST_FIXTURE=tools/gsd-capabilities/lockspire-phase-finalizer/fixtures/gsd-host-contract.json node --test tools/gsd-capabilities/lockspire-phase-finalizer/lockspire-finalize-command-router.test.cjs tools/gsd-capabilities/lockspire-phase-finalizer/lockspire-finalize-lifecycle.test.cjs — 21 passed, 2 skipped, 0 failed."
        status: pass
    human_judgment: false
  - id: D3
    description: "Release auto-merge requires literal opt-in and protected recovery publication requires every SHA observation to match current main."
    requirement: TRUTH-06
    verification:
      - kind: unit
        ref: "test/lockspire/release_ci_evidence_contract_test.exs — 4 tests, 0 failures."
        status: pass
      - kind: integration
        ref: "mix ci on Elixir 1.19.5 / OTP 28 — exit 0; test.fast reported 1,449 tests and 0 failures, test.integration reported 102 tests and 0 failures."
        status: pass
      - kind: other
        ref: "GitHub API readback at 2026-10-06T23:09Z: LOCKSPIRE_PHASE143_AUTHORIZED_SHA absent and LOCKSPIRE_RELEASE_AUTOMERGE_ENABLED absent; release workflow remains enabled for the normal no-publish path."
        status: pass
    human_judgment: false
duration: 39min
completed: 2026-10-06
status: complete
---

# Phase 142 Plan 04: Merge the Corrected Main Baseline Summary

**Live GitHub release controls now hold publication, while archived-path routing and exact-main release authorization are repaired and verified.**

## Performance

- **Duration:** 39 min
- **Started:** 2026-10-06T22:30:42Z (initial hosted-settings snapshot)
- **Completed:** 2026-10-06T23:09:57Z
- **Tasks:** 3
- **Files modified:** 6

## Accomplishments

- Disabled the live `Release Please Auto Merge` workflow and verified it reads back as `disabled_manually`. The `hex-publish` environment retains its custom `main`-only policy and requires an explicit reviewer. Its sole eligible reviewer is `szTheory` (user ID 28652), with `prevent_self_review=false`; this is an explicit maintainer self-approval gate, not independent review. Main requires a PR, all seven strict canonical CI checks, stale-review dismissal, conversation resolution, admin enforcement, and no force pushes or branch deletion. The approval count is zero because no independent reviewer is available. No release runs were active before or after the hold.
- Repaired finalizer root detection for both archived Phase 138/139 directories and the active portable fixture layout. Unrelated roots are still rejected, and the portable lifecycle suite retains its timeout, signal, spawn-error, missing-status, and ordinary nonzero-exit checks.
- Added a literal `LOCKSPIRE_RELEASE_AUTOMERGE_ENABLED == 'true'` opt-in and fail-closed Phase 143 recovery authorization. After environment approval, the protected publish job fetches `main` again and requires the fetched SHA, GitHub API main SHA, hosted authorization variable, recovery ref, and validated SHA to match before Hex upload. Both repository variables remain absent; the release workflow remains enabled for the normal no-publish path.

## Task Commits

1. **Task 1: Establish and verify the live release hold** — GitHub settings only; no repository files changed. Settings were read back at 2026-10-06T22:31:21Z.
2. **Task 2: Repair the archived-phase router regression** — `e891fbad` (RED), `fc4c155a` (GREEN).
3. **Task 3: Add default-deny release authorization contracts** — `6bc586c6` (RED), `7d38b04c` (GREEN).

**Plan metadata:** committed atomically with this summary.

## TDD Gate Compliance

- **Task 2:** The named archived-root test failed on the expected missing route before implementation; the RED evidence classifier returned `RED_EVIDENCE_OK`. The router fix then passed the portable command with 21 passed, 2 skipped, and 0 failed.
- **Task 3:** The named release-authorization contract failed before the guards were added; its TAP-formatted ExUnit evidence passed the RED classifier. The focused contract passed with 4 tests and 0 failures, and `mix ci` exited 0.
- Both TDD tasks have separate `test(142-04)` and implementation commits. No refactor commit was needed.

## Files Created/Modified

- `tools/gsd-capabilities/lockspire-phase-finalizer/lockspire-finalize-command-router.cjs` — accepts active and archived project layouts while checking required maintainer scripts.
- `tools/gsd-capabilities/lockspire-phase-finalizer/lockspire-finalize-command-router.test.cjs` — covers archived roots, portable fixture roots, and unrelated-root rejection.
- `.github/workflows/release-please-automerge.yml` — requires explicit repository-variable opt-in.
- `.github/workflows/release.yml` — gates recovery on one authorized SHA and rechecks current main immediately before upload.
- `test/lockspire/release_ci_evidence_contract_test.exs` — asserts the opt-in, recovery validation, and same-SHA joins.
- `docs/maintainer-release.md` — records live reviewer limitations, the Phase 142 hold, Phase 143 authorization, and rollback steps.

## Decisions Made

- Keep both authorization variables absent and the auto-merge workflow disabled through Phase 142; no merge, dispatch, tag, or publication was performed.
- Use the plan's solo-maintainer fallback: a named `hex-publish` reviewer may explicitly approve their own deployment, while the repository requires zero PR approvals and documents that this is not independent review.
- Leave shared `TRUTH-06` and `CI-09` checkboxes unchanged: the readiness command reported 0/2 IDs ready because sibling Phase 142 plans also declare them.

## Deviations from Plan

None — plan executed as written.

## Issues Encountered

- `mix deps.get --check-locked` initially could not write the managed `~/.hex/cache.ets`; rerunning with `HEX_HOME=/private/tmp/lockspire-hex` succeeded using locked dependency versions, with `mix.lock` unchanged.
- During `mix ci`, the dependency audit printed that it could not open `.git/FETCH_HEAD` because Git metadata is read-only in this worktree sandbox, then reported no vulnerabilities and completed successfully. The full command exited 0; the audit warning is recorded as an environment limitation.

## Next Phase Readiness

The correction and release guards are committed on this worktree branch, and live publication remains held. Plan 02 can push the remediation, review the hosted PR checks against its exact head, and perform its separate blocking-human merge authorization. No publication occurred in this plan.

## Self-Check: PASSED

- All six changed repository files exist.
- All four task commits are ancestors of the current plan head.
- `gsd_run check evaluation-scope --plan "142-04" --commits-only --raw` resolved this plan with four commits.

---
*Phase: 142-merge-the-corrected-main-baseline*
*Completed: 2026-10-06*
