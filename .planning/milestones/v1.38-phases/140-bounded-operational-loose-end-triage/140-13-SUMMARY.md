---
phase: 140-bounded-operational-loose-end-triage
plan: "13"
subsystem: release-proof
tags: [receipt-identity, git-modes, local-ci]
requires:
  - phase: 140-09
    provides: Exact-SHA acceptance boundary and post-summary handoff.
  - phase: 140-12
    provides: Historical receipt fixture lineage repair.
provides:
  - Deterministic protected-file modes in synthetic Phase 138 receipt fixtures.
  - Complete local mix ci result for candidate 0227dea2fd7cc8646d098505c3eb6637afb70d87.
affects: [LOOSE-03, CI-06, phase-140-closeout]
actuals:
  tokens: 42006
  tasks: 2
  commits: 1
  plan_head_before: fe19498de2be8ac9b2bab2095835f41dc4afb05d
tech-stack:
  added: []
  patterns:
    - "Synthetic files bound to Git tree identity are written with the corresponding tracked mode, independent of process umask."
key-files:
  created:
    - .planning/phases/140-bounded-operational-loose-end-triage/140-13-SUMMARY.md
  modified:
    - test/support/lockspire/release_proof/package_assertions.ex
    - test/lockspire/release/repository_hygiene_contract_test.exs
key-decisions:
  - "Keep the validator's exact mode, size, and digest comparison strict; make the fixture create tracked 0644 files deterministically."
  - "Treat local mix ci as preparatory proof only; CI-06/CI-07 and pending-receipt recovery remain with the orchestrator."
requirements-completed: []
requirements-addressed: [LOOSE-03, CI-06]
coverage:
  - id: D1
    description: "Protected Phase 138 planning-file fixtures match their committed Git mode, size, and digest; forged before-file identity remains rejected."
    requirement: LOOSE-03
    verification:
      - kind: integration
        ref: "Private umask `077` legacy/current probe: /private/tmp/lockspire-140-plan/identity-cause-probe.log; both original assertion functions reject before identity without chmod and pass with current helper; mode regression at current line307 and post-transition test at347 passed"
        status: pass
    human_judgment: false
  - id: D2
    description: "Complete local mix ci passes on the repaired candidate, including unit and integration suites."
    requirement: CI-06
    verification:
      - kind: integration
        ref: "ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.1 ERL_FLAGS='+S 1:1' HEX_HOME=/private/tmp/lockspire-hex-cache mix ci; /private/tmp/lockspire-140-13-ci.oVxPXP; 1441 unit tests and 102 integration tests, 0 failures"
        status: pass
    human_judgment: false
  - id: D3
    description: "Pending Phase 139 receipt remains unchanged and final synchronized-main acceptance stays pending."
    requirement: CI-06
    verification:
      - kind: other
        ref: "sha256 / .git/gsd-lifecycle/post-completion-finalizer.json = cfab9f9ea553a9cce0ee7db54aa128acbf66710d4faf7d17a37780fbaf881f4d"
        status: pass
    human_judgment: true
    rationale: "Canonical CI, Release no-publish, exact hygiene, ref synchronization, and any required exact-candidate authorization are post-summary orchestrator gates."
duration: about 90 minutes
completed: 2026-10-01
status: complete
---

# Phase 140 Plan 13: Receipt Identity Repair Summary

**Phase 138 receipt fixtures now preserve committed file identities across process umask settings, and complete local CI passes on the repaired candidate.**

## Performance

- **Duration:** About 90 minutes; start timestamp was not captured.
- **Completed:** 2026-10-01T18:57:08Z.
- **Tasks:** 2.
- **Files changed:** 3 including this summary.

## Accomplishments

- Made the four protected synthetic planning files use tracked mode `0644`, avoiding false receipt rejection when fixtures are created under a restrictive inherited umask.
- Added a regression comparing mode, size, and SHA-256 with the committed Git blobs, and added a forged before-file identity case to the post-transition adversaries.
- Ran complete local `mix ci` on candidate `0227dea2fd7cc8646d098505c3eb6637afb70d87`: 1,441 unit tests, 0 failures, 6 skipped (286 excluded), followed by 102 integration tests, 0 failures (33 excluded). The complete mode-0600 log is `/private/tmp/lockspire-140-13-ci.oVxPXP`.
- Confirmed the pending Phase 139 receipt digest remains `cfab9f9ea553a9cce0ee7db54aa128acbf66710d4faf7d17a37780fbaf881f4d`. `mix.lock` remained unchanged.

## Causal Verification

The review and orchestrator diagnostics used private temporary helper copies and confined umask `077` to the diagnostic child process. Normal full-suite runs used umask `022`; source files and the live receipt remained unchanged.

- `/private/tmp/lockspire-140-13-mode-old.log`: removing only the new chmod produces expected mode 420 (0644) versus observed 384 (0600), while size and SHA-256 match.
- `/private/tmp/lockspire-140-13-mode-current.log`: current mode regression passes under the same umask `077`.
- `/private/tmp/lockspire-140-plan/identity-cause-probe.log`: legacy `assert_phase_138_posttransition_relation!/0` and `assert_phase_138_finalizer_recovery_contract!/0` both reproduce the exact before-file-identity rejection; the current helper passes both under the same controlled condition. Exit 0 means all four expected outcomes were observed.
- `/private/tmp/lockspire-140-13-posttransition-selector.log`: current selector 347 passes, including the forged-before digest adversary.
- `/private/tmp/lockspire-140-13-release-please-selector.log`: current selector 359 passes in isolation; it does not explain the earlier seed 924694 failure.

The causal demonstration establishes inherited file mode as a sufficient trigger for the observed error. The historical full-run log did not capture its process umask, so it does not independently prove that historical environment value.

## Task Commits

1. **Task 1: Stabilize receipt identity fixture modes** — `0227dea2` (`fix(140-13)`).
2. **Task 2: Complete local CI and acceptance handoff** — verification-only; no source changes.

**Plan metadata:** The orchestrator records this summary using the approved local Git path after the executor reported its sandbox denial. The same path recorded the two-file production commit. No sandbox bypass, main-ref movement, or remote action was used.

## Files Created/Modified

- `test/support/lockspire/release_proof/package_assertions.ex` — Deterministic protected-file fixture modes, bounded identity metadata regression, and forged before-identity case.
- `test/lockspire/release/repository_hygiene_contract_test.exs` — Added the protected planning-file mode regression test.
- `140-13-SUMMARY.md` — Execution record and post-summary handoff, committed by the orchestrator.

## Decisions Made

- Kept the production validator's strict Git mode, file size, and digest comparisons. The fixture now creates the tracked file mode explicitly.
- Treated complete local `mix ci` as local proof only. CI-06/CI-07 remain pending for the final synchronized-main CI, Release no-publish, exact hygiene, and receipt recovery gates.

## Deviations from Plan

No implementation-scope expansion. The orchestrator handled local Git writes after the executor sandbox denied its sentinel write. The discriminating RED control was recorded during review after the repair commit, so this was not a test-first commit sequence. The first three-selector command used old line numbers after a four-line insertion; those three passes are not claimed as both original paths. Current selectors are 307 (mode regression), 347 (post-transition), and 408 (pending recovery); full CI and the bounded legacy/current probe cover both original paths. No shared planning state, roadmap, requirements, receipt, remote ref, or release state was changed by the executor.

## Issues Encountered

- The full standalone repository-hygiene contract run under seed `924694` completed with 60 tests and 1 failure in `phase 139 release-please main advance accepts only the authenticated refresh and recorded lag` (`relation_chain|phase-139-sealed-candidate|refresh_required`). The same complete contract was included in the subsequent full `mix ci`, which passed with 1,441 unit tests and 0 failures. No unrelated Phase 139 code was changed.
- The first scoped run found missing worktree dependencies. `mix deps.get` fetched the existing lockfile dependencies without changing `mix.lock`.
- The CI alias logged a denied `.git/FETCH_HEAD` read during its dependency checks, then completed all QA, unit, and integration gates successfully.

## User Setup Required

None.

## Next Phase Readiness

The local receipt identity blocker is repaired and complete local CI passes on the committed candidate SHA above. Plan 140-04 must resume; the orchestrator owns supported receipt recovery after all summary writes and unfiltered Phase 140 verification. CI-06/CI-07 are not accepted by this local result.

## Self-Check: PASSED

- Task commit `0227dea2` exists and contains only the two declared test files.
- Independent review confirmed the mode regression under umask `077`: current helper passes, a private copy with only chmod removed fails with expected 0644/observed 0600 and identical size/digest.
- The bounded probe reproduces `receipt validation failed: before file identity` in both original assertions using the legacy helper under umask `077`, then passes both with the current helper. Source bytes were unchanged.
- Complete local `mix ci` passed: 1,441 unit tests and 102 integration tests, 0 failures.
- `git diff --check` and targeted `mix format --check-formatted` passed; the pending receipt digest matches the required value.
- The orchestrator commits and verifies the required SUMMARY through the approved Git path.
- Review warning WR-01 remains open for Plan 140-04 disposition: the standalone Release Please relation failure did not recur in the isolated selector or complete CI. This is not a claim that the intermittent rejection is repaired.

---
*Phase: 140-bounded-operational-loose-end-triage*
*Completed: 2026-10-01*
