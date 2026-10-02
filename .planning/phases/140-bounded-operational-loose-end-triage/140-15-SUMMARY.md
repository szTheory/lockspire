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
  commits: 4
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
    description: "Post-summary same-SHA CI and Release acceptance passes only when the executable evidence join succeeds on the authorized synchronized candidate."
    verification:
      - kind: other
        ref: "/private/tmp/lockspire-140-plan/140-15-final-acceptance.47fbdf68a33c0542afa479c43aa95da2174b2bd6.json"
        status: pass
      - kind: other
        ref: "/private/tmp/lockspire-140-plan/phase140-15-post-sync-mix-ci.f9a0c50a7ef117aa8023fae823d14c12e95f46c2.log; GitHub CI run 37024977354"
        status: fail
    human_judgment: false
    rationale: "The first authorized candidate passed the executable exact-SHA join. The post-write candidate failed local mix ci and canonical CI, so CI-06/CI-07 remain pending and no terminal acceptance receipt exists."
duration: 7min
completed: 2026-10-02
status: in_progress
plan_head_before: 4cd5c3299989378f1f58535e633335b0e3e0f609
---

# Phase 140 Plan 15: Exact-SHA Acceptance Boundary Summary

The exact-SHA hygiene check now refreshes only remote main; its fixture rejects broader fetches, while final Phase 140 acceptance remains pending.

## Progress

- Plan status: T1/T2 complete for candidate 47fbdf68a33c0542afa479c43aa95da2174b2bd6; its first exact-SHA join passed. After the completion-record commit, candidate f9a0c50a7ef117aa8023fae823d14c12e95f46c2 was separately authorized and non-force pushed. Its local mix ci and canonical CI failed; the provisional CI-06/CI-07 marks are reverted to pending in this commit.
- Focused validation: shell syntax passed; tagged exact-SHA contract passed with 2 tests, 0 failures (58 excluded); Phase 139 planning consistency passed with 2 tests, 0 failures; both changed Elixir files pass mix format --check-formatted.
- Acceptance status: First candidate 47fbdf68a33c0542afa479c43aa95da2174b2bd6 passed together on 2026-10-02. Post-write candidate f9a0c50a7ef117aa8023fae823d14c12e95f46c2 failed local and canonical CI, so CI-06/CI-07 are pending. No terminal exact-hygiene receipt was produced.

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

The first T2 packet for 47fbdf68a33c0542afa479c43aa95da2174b2bd6 was captured after the prior summary commit, outside tracked files with restrictive permissions. It records exact refs, binary diff, porcelain, protected hashes, ancestry, and the approved normal non-force ref action. This summary update creates a new candidate and requires a fresh packet before any further ref action.

## First T3 attempt on the prior candidate

The initial push of candidate 7f88840923ea829351500f87496efc0ca14e0122 produced Release run 37001116850, which completed successfully: Maintain Release Please PR succeeded and all four protected publication jobs were skipped. CI run 37001116711 failed in Fast Checks and Minimum Supported Elixir/OTP because both encountered the Phase 139 planning-consistency assertion that the original tagged test name remains an executable owner. The accidental title change has been reverted; the direct consistency test and the Plan 15 tagged contract both pass at the corrected worktree. These failed runs belong to the prior candidate and do not satisfy CI-06.

The authorized non-force push succeeded, and GitHub reported bypassing the main branch's no-merge-commits rule because history contains merge 8061247594fb563d79e3b7d62f1d21b6789ede9f. This observation is retained; no force update, publication dispatch, or live Phase 139 finalizer rerun occurred.

## First exact-SHA acceptance pass

After the separate T2 approval, local `main` and `origin/main` were fast-forwarded to `47fbdf68a33c0542afa479c43aa95da2174b2bd6` with a normal non-force push. A fresh post-push fetch and separate advertisement confirmed `HEAD`, local `main`, fetched `origin/main`, and advertised `origin/main` at that full SHA; the worktree was clean and the four protected execution-entry hashes matched their preserved values.

The post-sync local `mix ci` passed: 1,441 tests, 0 failures, 6 skipped (286 excluded), followed by 102 integration tests, 0 failures (33 excluded). Log: `/private/tmp/lockspire-140-plan/phase140-15-post-sync-mix-ci.47fbdf68a33c0542afa479c43aa95da2174b2bd6.log` (mode 0600). The exact hygiene command's own pinned local gate also passed; its receipt records 102 executed ExUnit tests, 24 PASS, 0 WARN, and 0 BLOCK. Docker 29.5.2 was reachable, with no active or stopped adoption-demo containers and no matching volumes, so the WARN disposition file is empty.

Canonical CI run [37010692578](https://github.com/szTheory/lockspire/actions/runs/37010692578) succeeded for all seven required jobs: Dialyzer, Release Hygiene Drift, Fast Checks, Minimum Supported Elixir/OTP, Integration Checks, Complete Coverage Evidence, and Adoption Demo Smoke. Release run [37010692603](https://github.com/szTheory/lockspire/actions/runs/37010692603) succeeded: Maintain Release Please PR succeeded and all four protected publication jobs were skipped. The workflow_run Release Please Auto Merge run 37012525945 succeeded without moving `main`.

The mode-0600 receipt is `/private/tmp/lockspire-140-plan/140-15-final-acceptance.47fbdf68a33c0542afa479c43aa95da2174b2bd6.json`, SHA-256 `76b42dc2154c728b6fa096532bcfd49b068276ef203e67964a23e0b28449af5c`. The first exact-hygiene invocation omitted the pinned ASDF variables and stopped at the local-gate check before running tests; the successful retry used Elixir 1.19.5 / OTP 28.1. The failed invocation is retained privately and does not represent a source or test failure.

This is the first passing receipt (A), not the terminal receipt. The tracked completion-record changes created candidate `f9a0c50a7ef117aa8023fae823d14c12e95f46c2`; its separate T2 checkpoint was approved, and it was pushed normally. Do not transfer the 47fbdf68 receipt to that SHA. The known failed live Phase 139 finalizer remains historical and was not rerun.

## Post-write candidate terminal-gate failure

The completion-record candidate `f9a0c50a7ef117aa8023fae823d14c12e95f46c2` was authorized and pushed non-force. Fresh refs matched at that SHA, the worktree was clean, and all four protected execution-entry hashes remained unchanged. Local `mix ci` then failed: **1,441 tests, 8 failures, 6 skipped (286 excluded)** after 1,612.8 seconds. The mode-0600 log is `/private/tmp/lockspire-140-plan/phase140-15-post-sync-mix-ci.f9a0c50a7ef117aa8023fae823d14c12e95f46c2.log`. Seven failures were Phase 139/140 lifecycle relation fixtures; one was the baseline-snapshot relation fixture timing out after 180 seconds. The unit gate stopped before the integration suite.

Canonical CI run [37024977354](https://github.com/szTheory/lockspire/actions/runs/37024977354) failed on this SHA: Fast Checks reported 1,441 tests / 7 failures; Minimum Supported Elixir/OTP reported 1,727 tests / 7 failures. Integration Checks, Dialyzer, Release Hygiene Drift, and Adoption Demo Smoke succeeded; Complete Coverage Evidence was skipped. Release run [37024977672](https://github.com/szTheory/lockspire/actions/runs/37024977672) succeeded with `Maintain Release Please PR` successful and all four protected publication jobs skipped. Release Please Auto Merge run 37026427771 was skipped and did not advance `main`.

The terminal `repo_hygiene_check.sh --accept-sha` join was not run: its mandatory local gate and required CI were already observed failing on the candidate. No f9a0 terminal receipt exists. The exact WARN-disposition file is empty and mode 0600; Docker 29.5.2 was reachable, with no project containers or volumes. CI-06/CI-07 are reverted to pending in this commit. Preserve the historical classifier and failed live Phase 139 observation; do not rerun the live finalizer.

## Remaining plan work

- T3 is blocked on `f9a0c50…`: local `mix ci` and canonical CI failed. This commit restores CI-06/CI-07 to pending and records the evidence. Any future attempt requires addressing the fixture failures without broadening the Phase 139 classifier, then a fresh exact-candidate packet and its own blocking-human ref-action checkpoint.
