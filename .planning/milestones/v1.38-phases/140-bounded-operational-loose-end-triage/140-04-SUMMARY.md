---
phase: 140-bounded-operational-loose-end-triage
plan: "04"
subsystem: planning-evidence
tags: [dispositions, exact-sha-acceptance, release-hygiene]
dependency_graph:
  requires: [140-01, 140-02, 140-03]
  provides: [final-disposition-audit, post-summary-exact-main-acceptance-contract]
  affects: [CI-06, CI-07, BASE-03, LOOSE-02, LOOSE-03]
tech_stack:
  added: []
  patterns: [terminal-proof-or-trigger-per-finding, final-sha-is-post-summary-only]
key_files:
  created: [.planning/phases/140-bounded-operational-loose-end-triage/140-ACCEPTANCE.md]
  modified: [.planning/phases/140-bounded-operational-loose-end-triage/140-DISPOSITIONS.md]
decisions:
  - "Keep the Phase 139 roadmap-count correction already-resolved based on Plan 140-02's exact source-pair and commit evidence."
  - "Keep CI-06/CI-07 pending until the phase verifier proves canonical same-SHA CI, Release no-publish, and exact hygiene evidence after all Phase 140 writes."
  - "Defer WR-01 with a trigger to reopen on recurrence of the exact sealed-candidate relation rejection; its cause remains unknown and it is not fixed."
requirements-completed: [BASE-03, LOOSE-02, LOOSE-03]
coverage:
  - id: T1
    description: "Every current inventory finding has one supported outcome, terminal proof, or explicit recheck trigger; protected entry hashes match."
    requirement: LOOSE-02
    verification:
      - kind: other
        ref: "Row/ID audit in 140-DISPOSITIONS.md and primary-checkout protected hash check; four recorded SHA-256 values match"
        status: pass
      - kind: test
        ref: "test/lockspire/release/repository_hygiene_contract_test.exs, post-merge seed 924694: 60 tests, 0 failures"
        status: pass
    human_judgment: true
    rationale: "Disposition correctness includes source-boundary and authority judgment; the phase verifier still owns external acceptance."
  - id: T2
    description: "The exact-main acceptance contract is prepared and CI-06/CI-07 remain pending until the phase-level same-SHA gate passes."
    requirement: CI-06
    verification:
      - kind: test
        ref: "repository_hygiene_contract_test.exs --only phase139_exact_sha_hygiene: 2 tests, 0 failures"
        status: pass
      - kind: test
        ref: "test/lockspire/release_ci_evidence_contract_test.exs: 3 tests, 0 failures"
        status: pass
      - kind: command
        ref: "git diff --check for the three Plan 140-04 output files"
        status: pass
    human_judgment: true
    rationale: "Canonical CI, Release no-publish, and exact synchronized-main acceptance remain with the phase verifier."
metrics:
  duration: "about 55 min initial execution; later closeout evidence completed 2026-10-01"
  completed: 2026-10-01
  tasks: 2
  files: 3
status: complete
actuals:
  tokens: 7112
  tasks: 2
  commits: 2
  plan_head_before: 57d33ab35f3b16efe2ed184d81a3e7779fa5821a
---

# Phase 140 Plan 04: Final Dispositions and Exact-Main Acceptance Summary

The refreshed finding set now has one auditable disposition per current inventory row, while CI-06/CI-07 remain bound to the phase verifier's post-summary exact-main gate.

## Execution Result

Plan 140-04's local T1 and T2 work is complete. T1 initially failed its full repository-hygiene contract on two Phase 140 recovery diagnostic assertions, and the initial local `mix ci` failed with 1,439 tests and 44 failures. Later bounded plans repaired and verified those local findings. The required post-merge full repository-hygiene contract then passed on unchanged HEAD `8061247594fb563d79e3b7d62f1d21b6789ede9f`: 60 tests, 0 failures at seed `924694`; compile/build completed with warnings as errors and exit 0. T2's focused acceptance contracts and diff check passed. These results close this plan's local criteria; CI-06/CI-07 remain pending phase-level external acceptance.

## Task Results

| Task | Result | Evidence |
| --- | --- | --- |
| 140-04-T1: terminal finding dispositions | Complete | Current inventory IDs audited against the disposition register; post-merge full repository-hygiene contract passed 60 tests, 0 failures at seed `924694`; all four protected hashes match from the primary checkout. |
| 140-04-T2: post-summary exact-main gate | Complete as a verification contract | `140-ACCEPTANCE.md` specifies a fail-closed post-summary gate. Exact-SHA hygiene selector: 2 tests, 0 failures. Release CI evidence contract: 3 tests, 0 failures. `git diff --check` passes. CI-06/CI-07 remain pending for the phase verifier. |

## Verification Evidence

- Post-merge receipt `/private/tmp/lockspire-140-plan/post-merge-gate-result.json` records HEAD `8061247594fb563d79e3b7d62f1d21b6789ede9f` before and after, build exit 0, and hygiene exit 0. The hygiene log `/private/tmp/lockspire-140-plan/post-merge-hygiene-seed-924694.log` reports **60 tests, 0 failures**.
- Latest complete local `mix ci` preparatory evidence remains Plan 140-13 source candidate `0227dea2fd7cc8646d098505c3eb6637afb70d87`: 1,441 unit tests, 0 failures, 6 skipped (286 excluded), plus 102 integration tests, 0 failures (33 excluded). Log: `/private/tmp/lockspire-140-13-ci.oVxPXP`. The source diff from `0227dea2` to `80612475` across `lib/test/scripts/tools/mix/.github` is empty. This remains local preparatory proof, not canonical final-SHA acceptance.
- The controlled causal probe `/private/tmp/lockspire-140-plan/identity-cause-probe.log` confirms both original before-file-identity rejections under the legacy helper with `umask 077` and passes both with the repaired helper. The old 140-04 failures are now resolved by Plan 140-06 (`bfc21d32`, `30068cf1`), Plan 140-07 (`893b6c5b`, `098b6701`), Plans 140-10/11/12, and Plan 140-13 (`0227dea2`).
- The Phase 138 immutable ledger and three protected execution-entry overlays match their exact primary-checkout SHA-256 values: ledger `b200d2491cffd55c5334e03a25f3410945a6df77e43c57172972e61f8c93c10f`; `138-UAT.md` `adebfc5edc5d5671b4776b6c6495643a43123768907635c8905bd7045abd517b`; `138-VERIFICATION.md` `a38ba1062de64e990bd05381cacd1a044abefad1e5d1a6320b72413a7a55cc10`; and the roadmap ratchet prompt `8cba24252908e0de1a9c64198b0644579970c5c9c1bfa0ab26d733d720ca3b05`.
- The pending Phase 139 receipt digest remains `cfab9f9ea553a9cce0ee7db54aa128acbf66710d4faf7d17a37780fbaf881f4d`; the entry-gate plan remains failed for the stale writer descriptor. This separate entry gate is not represented as repaired here.

## Disposition Audit

The refreshed inventory contains 114 current IDs: 40 branch refs, 38 tags, 2 worktrees, 7 open PRs, and 27 maintained/archive records. Every current ID has one outcome in the disposition register, with no current duplicates or omissions. The register separately retains `REC-7c205a386481`, an older partial-snapshot archive identity. The earlier “109 unique rows” structural count is not the refreshed inventory denominator and is corrected by the explicit current counts in `140-DISPOSITIONS.md`.

The seven general open-PR inventory rows remain `defer-with-trigger` pending fresh exact-target, authority, and recovery checks. Six dependency PRs also receive individual compatibility, security, and gate assessments: #98 Oban, #97 Phoenix LiveView, #96 Req, #91 setup-python, #88 Sobelow, and #87 Postgrex. Five dependency findings are deferred; Postgrex is already present in current source, so its dependency finding is `already-resolved`, while the PR-native close recommendation is not an action and does not replace the general PR-row deferral.

The archive evidence retains its source-native boundaries. The v1.27 `5+2+2` report does not identify nine distinct UAT records: five Phase 81 cases have exact names, and four historical Phase 32/AuditWriter identities remain unavailable. Four later current Phase 32/AuditWriter test failures are separate present-day findings and are resolved by the exact Plan 140-07 tests. v1.32 Phase 115 and JWKS reports remain aggregate caveats.

WR-01 records the earlier standalone seed-924694 sealed-candidate relation rejection. Its cause remains unknown. The clean post-merge replay passed, so the finding is `defer-with-trigger`: reopen and diagnose with stage-specific evidence if the exact selector/relation rejection recurs. Do not call it fixed. The historical Lockspire 1.5.0 release chain and all intentional refs remain preserved; supplemental OIDF/FAPI evidence stays redacted and non-certifying.

## Acceptance Boundary

CI-06 and CI-07 remain pending until the phase verifier records final synchronized `HEAD`/local `main`/fresh `origin/main`, exact hygiene acceptance, required canonical CI job results, and the intentional Release no-publish job graph on one final full SHA. The Phase 139 receipt is entry-only evidence. No final SHA, remote CI/Release pass, push, publication, or external target action is claimed here.

## Historical initial execution evidence (2026-09-30)

The following is the original failed-run record, retained verbatim as dated evidence. Its blockers were subsequently resolved by the scoped plans and current passing checks above; its ref observations and authorization statements describe that earlier execution.

- Protected execution-entry hashes passed from the primary checkout:
  - Phase 138 ledger `b200d2491cffd55c5334e03a25f3410945a6df77e43c57172972e61f8c93c10f`.
  - `138-UAT.md` `adebfc5edc5d5671b4776b6c6495643a43123768907635c8905bd7045abd517b`.
  - `138-VERIFICATION.md` `a38ba1062de64e990bd05381cacd1a044abefad1e5d1a6320b72413a7a55cc10`.
  - `docs/lockspire-milestone-roadmap-ratchet-prompt.txt` `8cba24252908e0de1a9c64198b0644579970c5c9c1bfa0ab26d733d720ca3b05`.
- T1 contract command: `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.1 ERL_FLAGS='+S 1:1' mix test test/lockspire/release/repository_hygiene_contract_test.exs` — **58 tests, 2 failures, exit 2**. Failures:
  1. `Phase 140 recovery validates dependency and inventory fixture timeout follow-ups` (`test/lockspire/release/repository_hygiene_contract_test.exs:225`): expected `git_topology|branches|mismatch|refresh_required`, received `relation_boundary|phase-139-sealed-candidate|refresh_required` and `snapshot_relation: refresh_required`.
  2. `Phase 140 recovery authenticates the exact planning preparation prefix` (`...:231`): received the same phase-139 sealed-candidate boundary diagnostic instead of the expected prefix-specific result.
- Final local CI was first blocked because Hex could not write `/Users/jon/.hex/cache.ets` (`:eaccess`). It was retried with the cache redirected to `/private/tmp/lockspire-hex-cache`; dependency resolution then passed without package changes. `mix ci` ended **1439 tests, 44 failures, 6 skipped (286 excluded)** in 1491.3s, exit 1. The output included the stale ReleaseAutomation assertion that Phase 140 remains gated despite current PROJECT saying execution is underway, the two recovery diagnostic failures above, duplicate `client_id: client_jar` errors in `AuthorizationRequestTest`, and the existing `:invalid_signing_key` token exchange failure. Other gates before ExUnit passed: compile, dependency/cycle checks, 13 focused tests, Credo (570 files, no issues), Sobelow, docs generation, retired-package check, vulnerability audit, package build, and migrations. The run logged `error: cannot open '.git/FETCH_HEAD': Operation not permitted`; it continued, but that fetch evidence is not treated as a pass. The returned output was truncated at 44,624 tokens, so the listed causes are representative and not an exhaustive list of all 44 failures.
- The current exact synchronized-main gate is **not run**. At plan entry HEAD was `57d33ab35f3b16efe2ed184d81a3e7779fa5821a`, while local and `origin/main` were `5ad2b2e935556c8f1a91be32605958530b477527`. The Phase 139 receipt at `c6332d3a8b716b938f93d978243281764e3eac41` is entry-only evidence. No push authorization exists; no push, publication, ref movement, PR mutation, or release-owned file edit was performed.

## Task Commits

- T1 disposition/acceptance changes from the original execution: `c64a5d38`, `8e963968`.
- The resumed closeout is recorded by the scoped `docs(140-04): finalize dispositions and acceptance contract` commit.

## Deviations from Plan

The plan's original T1 checks failed before the bounded fixes in later plans. These findings were not hidden or rewritten as passes; the later terminal evidence and the post-merge replay close the local checks. WR-01 remains cause-unknown and deferred on recurrence. No external action or cleanup was performed.

## Self-Check: PASSED

- The three plan artifacts exist and focused verification passed.
- Four protected execution-entry hashes match exactly.
- Every current inventory ID is represented exactly once; one superseded partial-snapshot archive ID remains explicitly historical.
- Plan-local T1/T2 are complete; CI-06/CI-07 and the stale-writer entry gate remain pending at their separate owners.
