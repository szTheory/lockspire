---
phase: 140-bounded-operational-loose-end-triage
plan: "03"
subsystem: planning-evidence
tags: [dependency-assessment, supply-chain, read-only]
dependency_graph:
  requires: [140-02]
  provides: [current-dependency-pr-dispositions]
  affects: [TRIAGE-03, LOOSE-02]
tech_stack:
  added: []
  patterns: [PR-specific-evidence, explicit-defer-triggers]
key_files:
  created: [.planning/phases/140-bounded-operational-loose-end-triage/140-03-SUMMARY.md]
  modified: [.planning/phases/140-bounded-operational-loose-end-triage/140-DISPOSITIONS.md]
decisions:
  - "Keep each candidate finding disposition separate from its PR-native recommendation."
  - "Treat missing check diagnostics, absent jobs, stale bases, and missing upstream release detail as explicit defer triggers."
  - "Classify Postgrex 0.22.4 as already resolved on current main; recommend closing only as a disposition, without remote action."
metrics:
  duration: "~20m"
  completed: 2026-09-30
  tasks: 2
  files: 2
  commits: 2
  plan_head_before: 585ceecd435fcf69e64b01b2cf7eb2378e60ec15
status: complete
actuals:
  tokens: 4954
  tasks: 2
  commits: 2
---

# Phase 140 Plan 03: Current Dependency PR Assessment Summary

Six open dependency-update PRs were independently assessed using fresh GitHub identity, diff, check, and upstream release/security evidence; no package or remote state was changed.

## Completed Tasks

1. Assessed Oban #98, Phoenix LiveView #97, and Req #96, recording exact heads/bases, per-job outcomes, upstream evidence, and individual defer triggers.
2. Assessed setup-python #91, Sobelow #88, and Postgrex #87, including current queue coverage and the focused supply-chain contract.

## Findings and Recommendations

| PR | Finding disposition | PR-native recommendation | Current evidence |
| --- | --- | --- | --- |
| #98 Oban 2.21.1 → 2.24.0 | defer-with-trigger | needs-work | Stale base; multiple failed jobs; candidate is behind upstream 2.24.1. |
| #97 LiveView 1.2.10 → 1.2.11 | defer-with-trigger | needs-work | Stale base, Release Hygiene Drift failed, and official changelog did not document 1.2.11. |
| #96 Req 0.7.1 → 0.7.4 | defer-with-trigger | needs-work | Stale base; Dependency Review and Release Hygiene Drift failed without available diagnostics; official 0.7.4 changelog detail unavailable. |
| #91 actions/setup-python 6 → 7 | defer-with-trigger | needs-work | Full-SHA identity verified; stale base and Fast Checks / minimum Elixir-OTP failed; runner floor needs confirmation. |
| #88 Sobelow 0.14.1 → 0.15.0 | defer-with-trigger | needs-work | Stale and incomplete rollup; Fast Checks failed with unavailable diagnostics; full current CI and scan result needed. |
| #87 Postgrex 0.22.3 → 0.22.4 | already-resolved | close | Current main at `5ad2b2e935556c8f1a91be32605958530b477527` already contains 0.22.4, the official CVE fix. Recommendation is not a PR action. |

All six candidate PRs remained open with stale base OIDs during the 2026-09-30 02:34–02:43 UTC evidence window. The open queue also included documentation-only draft #83, which was checked separately and excluded from the dependency assessment. Every candidate's required-job outcomes are recorded individually in [140-DISPOSITIONS.md](140-DISPOSITIONS.md); absent or skipped jobs are not represented as passing.

Official sources established the relevant Oban and Sobelow compatibility changes, LiveView advisory ranges, Req advisory ranges, setup-python v7 runtime/runner notes, and Postgrex CVE-2026-66838 fix. Remaining source limitations and failed-check diagnostic gaps are documented per PR as concrete defer triggers. No candidate was called merge-ready.

## Verification

- Focused supply-chain contract: `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.1 ERL_FLAGS='+S 1:1' mix test test/lockspire/workflow_supply_chain_contract_test.exs` — **5 tests, 0 failures**.
- All six `gh pr view` identity/diff/check queries completed, as did the open-queue query and exact diff inspection. Official-source review is complete to available published material; unavailable Req 0.7.4 release notes and GitHub failed-job summaries remain explicit defer items.
- `git diff --check` passed before task 2 commit.
- No dependency files, workflow pins, package state, PRs, branches, tags, worktrees, or remotes were mutated. Existing LOOSE-03 fixture gap remains as documented; no archive identity or package state was inferred.

## Commits

- `7a4e3fd9` — `docs(140-03): assess Oban LiveView and Req PRs`
- `e6137a5c` — `docs(140-03): assess setup-python Sobelow and Postgrex PRs`

## Deviations from Plan

None. Evidence unavailable from upstream or check metadata was recorded with a defer trigger rather than treated as green.

## Self-Check: PASSED

The summary and disposition artifact are present; both task commits are in local history. The only plan-scoped working-tree changes are these two authorized artifacts.
