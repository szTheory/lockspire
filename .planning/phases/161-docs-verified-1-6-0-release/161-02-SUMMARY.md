---
phase: 161-docs-verified-1-6-0-release
plan: 02
subsystem: release
tags: [release-train, hygiene, ci-gate, contract-test]
requires: []
provides:
  - "repo_hygiene_check.sh accepts RELEASE-TRAIN metadata >= public package version"
  - "File-derived release contract test helpers (no pinned 1.5.1 facts)"
affects: [161-04, 161-09]
tech-stack:
  added: []
  patterns: ["ledger values captured from RELEASE-TRAIN.md by Regex in test helpers"]
key-files:
  created: []
  modified:
    - scripts/maintainer/repo_hygiene_check.sh
    - test/support/lockspire/release_proof/workflow_assertions.ex
    - test/support/lockspire/release_proof/package_assertions.ex
key-decisions:
  - "D-16: only the metadata-vs-public clause relaxes to >=; public == artifact == tag and SHA equality stay strict"
requirements-completed: [REL-01]
duration: 25 min
completed: 2026-10-20
status: complete
commits: 3
plan_head_before: f166ef775232322ce816a182e6eda676dd5834af
plan_head_after: 1509aa7eab96a571348bda5048954754fbc0b13c
actuals:
  tasks: 3
  commits: 3
---

# Phase 161 Plan 02: Release-train gate repair Summary

The ledger gate now passes the post-#121 state (metadata 1.6.0, public 1.5.1) via a `version_ge` helper, still blocks lower metadata and inconsistent evidence, and the two release contract helpers derive their facts from the ledger.

## Tasks

| Task | Commit | Result |
| ---- | ------ | ------ |
| 1 version_ge + simulation | 73701c33 | metadata >= public; parsers, counts, metadata == mix.exs check untouched |
| 2 de-pin assert_current_release_truth! | b7bea5ae | captures via Regex; Version.compare; release_automation_contract_test 3 tests 0 failures |
| 3 file-derived fail-closed matrix | 1509aa7e | lower-metadata and higher-public cases; new pass case; `:expect_release_train_pass` option |

## Simulation (throwaway worktree under mktemp, removed afterwards)

Commands: `git worktree add --detach $SIM/tree HEAD`, edit mix.exs, `.release-please-manifest.json`, CHANGELOG.md heading and the RELEASE-TRAIN metadata line to the target version, then `bash scripts/maintainer/repo_hygiene_check.sh --ci`.

- Real tree: `Summary: 18 PASS, 0 WARN, 0 BLOCK`
- Simulated 1.6.0 (public line still 1.5.1): `Summary: 18 PASS, 0 WARN, 0 BLOCK`
- Simulated 1.5.0 (all metadata at 1.5.0, public 1.5.1): `[BLOCK] release train ledger ...` and `Summary: 17 PASS, 0 WARN, 1 BLOCK`
- Simulated 1.6.0 worktree, `mix test` of repository_hygiene_contract_test and release_automation_contract_test: 13 tests, 0 failures. Real tree: same, 13 tests, 0 failures.

The pending-release pass case asserts only the absence of the ledger BLOCK and no credential or raw-response leak; overall exit status was not asserted.

## Deviations from Plan

None - plan executed exactly as written.

## Known Stubs

None.

## Self-Check: PASSED

All three commits exist; `mix format --check-formatted` clean; no leftover worktree; mix.exs, manifest, CHANGELOG.md and workflows unchanged in the real tree.
