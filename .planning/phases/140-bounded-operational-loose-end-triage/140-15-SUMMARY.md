---
phase: 140-bounded-operational-loose-end-triage
plan: "15"
subsystem: release-verification
tags: [exact-sha, repository-hygiene, main-only-fetch, phase-140]
requires:
  - phase: 140-bounded-operational-loose-end-triage
    provides: exact-SHA hygiene command and post-summary acceptance contract
provides:
  - Main-only no-tags remote refresh at the exact-SHA acceptance boundary
  - Tagged regression assertion that rejects broader fetch argv and retains fetch failure coverage
affects: [phase-140-verification, phase-140-acceptance, CI-06, CI-07]
actuals:
  tokens: 1800
  tasks: 1
  commits: 2
tech-stack:
  added: []
  patterns: [main-only exact-SHA remote refresh]
key-files:
  created:
    - .planning/phases/140-bounded-operational-loose-end-triage/140-15-SUMMARY.md
  modified:
    - scripts/maintainer/repo_hygiene_check.sh
    - test/support/lockspire/release_proof/package_assertions.ex
    - test/lockspire/release/repository_hygiene_contract_test.exs
    - .planning/phases/140-bounded-operational-loose-end-triage/140-ACCEPTANCE.md
key-decisions:
  - "Exact-SHA acceptance refreshes only the selected remote main ref, with tags and pruning excluded."
  - "CI-06 and CI-07 remain pending until final local, remote, CI, Release, and hygiene evidence joins on one SHA."
requirements-completed: [BASE-03]
requirements-pending: [CI-06, CI-07]
coverage:
  - id: D1
    description: "Exact-SHA acceptance accepts and records only the main-only no-tags fetch and preserves fail-closed refresh errors."
    requirement: BASE-03
    verification:
      - kind: unit
        ref: test/lockspire/release/repository_hygiene_contract_test.exs#phase139_exact_sha_hygiene
        status: pass
    human_judgment: false
  - id: D2
    description: "Post-summary same-SHA CI and Release acceptance remains explicitly pending until the blocking candidate gate and executable evidence join complete."
    verification: []
    human_judgment: true
    rationale: "The final refs and canonical GitHub CI/Release graph require fresh candidate-specific review and may require a separate human-authorized ref action."
duration: 7min
completed: 2026-10-02
status: in_progress
plan_head_before: 4cd5c3299989378f1f58535e633335b0e3e0f609
---

# Phase 140 Plan 15: Exact-SHA Acceptance Boundary Summary

The exact-SHA hygiene check now refreshes only remote main; its fixture rejects broader fetches, while final Phase 140 acceptance remains pending.

## Progress

- Plan status: T1 complete; the first T2 candidate was approved and pushed; T3's first canonical CI run exposed and now has a focused regression fix. The corrected candidate needs a fresh T2 checkpoint before synchronization.
- Focused validation: shell syntax passed; tagged exact-SHA contract passed with 2 tests, 0 failures (58 excluded); Phase 139 planning consistency passed with 2 tests, 0 failures; both changed Elixir files pass mix format --check-formatted.
- Acceptance status: CI-06 and CI-07 remain pending. The first canonical CI run failed at the test-owner consistency assertion; no passing exact hygiene receipt exists.

## Accomplishments

- Replaced exact-mode git fetch "$REMOTE" --prune with git fetch --no-tags "$REMOTE" "refs/heads/main:refs/remotes/$REMOTE/main". The separate local local_checks() fetch remains unchanged.
- Updated the existing exact-SHA fake Git boundary to record and accept only the precise main-only argv. The success contract requires at least one such fetch; the fake rejects other fetch arguments and still simulates refresh failure.
- Restored the existing tagged test's exact title after the first remote CI run showed that Phase 139's owner check matches this title as a tracked executable entry.
- Kept the historical Phase 139 live finalizer failure and WR-01 recurrence disposition intact. The live finalizer was not rerun.

## T1 validation

Shell syntax: bash -n scripts/maintainer/repo_hygiene_check.sh
Focused contract: mix test test/lockspire/release/repository_hygiene_contract_test.exs --only phase139_exact_sha_hygiene
Result: 2 tests, 0 failures (58 excluded)
Formatting: mix format --check-formatted test/support/lockspire/release_proof/package_assertions.ex test/lockspire/release/repository_hygiene_contract_test.exs

The current exact-candidate packet is captured after this summary and its commit, outside tracked files with restrictive permissions. It will report fresh HEAD, local and remote main, separately advertised remote identity, exact binary diff, porcelain, protected execution-entry hashes, ancestry, and any required normal non-force ref action with its recovery route.

## First T3 attempt on the prior candidate

The initial push of candidate 7f88840923ea829351500f87496efc0ca14e0122 produced Release run 37001116850, which completed successfully: Maintain Release Please PR succeeded and all four protected publication jobs were skipped. CI run 37001116711 failed in Fast Checks and Minimum Supported Elixir/OTP because both encountered the Phase 139 planning-consistency assertion that the original tagged test name remains an executable owner. The accidental title change has been reverted; the direct consistency test and the Plan 15 tagged contract both pass at the corrected worktree. These failed runs belong to the prior candidate and do not satisfy CI-06.

The authorized non-force push succeeded, and GitHub reported bypassing the main branch's no-merge-commits rule because history contains merge 8061247594fb563d79e3b7d62f1d21b6789ede9f. This observation is retained; no force update, publication dispatch, or live Phase 139 finalizer rerun occurred.

## Remaining plan work

- T2: Recheck and present the corrected exact candidate packet. The earlier approval applies only to 7f88840923ea829351500f87496efc0ca14e0122 and does not transfer. If the corrected candidate needs local-main movement or a push, stop for its own explicit approval.
- T3: Only after the T2 condition is satisfied, pursue the full same-SHA local hygiene, canonical CI, and Release no-publish join. Keep CI-06 and CI-07 pending if any evidence or authorization is missing.
