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
  - "Mark the roadmap count finding already-resolved from Plan 140-02 terminal evidence; do not repeat or broaden the roadmap edit."
  - "Keep current signing-key failures and final exact-main CI/Release evidence pending; no repair or push is authorized by this plan."
metrics:
  duration: "approximately 55 minutes"
  completed: 2026-09-30
  tasks: 2
  files: 2
  commits: 2
  plan_head_before: 57d33ab35f3b16efe2ed184d81a3e7779fa5821a
status: blocked
actuals:
  tokens: 4330
  tasks: 2
  commits: 2
---

# Phase 140 Plan 04: Final Dispositions and Exact-Main Acceptance Summary

The roadmap mismatch now cites its completed scoped correction; the final CI-06/CI-07 gate is specified as a post-summary, same-SHA procedure and remains pending.

## Execution Result

Plan 140-04 is **blocked/incomplete**. T2's acceptance contract was produced and its focused contracts passed. T1's full repository-hygiene contract suite failed two Phase 140 recovery diagnostic assertions, and the required final local `mix ci` failed its full ExUnit phase. These failures remain outside this plan's authorized file scope; no unrelated tests, support code, signing fixtures, or implementation were changed. The plan is not represented as passed.

## Task Results

| Task | Result | Evidence |
| --- | --- | --- |
| 140-04-T1: terminal finding dispositions | Incomplete — required contract failed | Updated `REC-ec0732041b6a` to `already-resolved` with 13 paired Phase 139 plan/summary names, verification status, commit `7f3dc899cc15444be5e78059ccf32f29eee92ec5`, and current roadmap blob. The candidate table structural audit passed: 109 unique rows, one allowed disposition and a nonempty trigger/retention condition per row. The full `repository_hygiene_contract_test.exs` command ended **58 tests, 2 failures** in 1035.1s. |
| 140-04-T2: post-summary exact-main gate | Acceptance artifact complete; phase acceptance pending | Added a fail-closed exact-main procedure with the final SHA equality, hygiene command, WARN handling, canonical CI jobs, Release no-publish jobs, and explicit authorization stop. Focused exact-SHA hygiene: **2 tests, 0 failures**; Release evidence contract: **3 tests, 0 failures**; acceptance `git diff --check`: passed. |

## Verification Evidence

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

## Remaining Blockers

- **T1 contract:** the two Phase 140 recovery diagnostic failures above require a separately scoped GSD gap plan; they were not changed here.
- **Local CI:** the full `mix ci` ExUnit suite has 44 failures; only representative categories could be preserved from the truncated tool output. Do not infer that a subsequent clean run exists.
- **LOOSE-03:** four current Phase32/AuditWriter selectors still fail with `:invalid_signing_key`. The four historical Phase32/AuditWriter identities remain unavailable. Preserve the existing trigger: create a bounded fixture-repair plan that seeds a valid active signing key and passes each exact selector. No signing-key repair was attempted.
- **CI-06 / CI-07:** pending exact final-main equality, required canonical CI job success, successful intentional Release no-publish job graph, and exact hygiene receipt at one post-summary SHA. Any new push first requires separate exact-candidate authorization.

## Safety and Scope

- The grouped historical v1.27 `5+2+2` evidence remains aggregate-only; five source-identifiable Phase81 cases remain separate, and four unnamed historical Phase32/AuditWriter identities were not invented.
- The historical Lockspire 1.5.0 release chain remains historical evidence. Supplemental OIDF/FAPI evidence stays redacted and non-certifying.
- No PR, issue, branch, tag, worktree, remote, release workflow, package state, or protected overlay was mutated. `.planning/STATE.md`, `.planning/state.json`, and `.planning/ROADMAP.md` were left to orchestrator bookkeeping.
- The required `.git/gsd-plan-head-before-140-04` ledger records `57d33ab35f3b16efe2ed184d81a3e7779fa5821a`; measured task commits before this summary: 2.

## Self-Check: PASSED

- Both plan artifacts exist, and task commits `c64a5d38` and `8e963968` are present.
- The protected Phase 138 ledger and three local execution overlays match their exact entry hashes.
- This self-check confirms artifact and commit presence only. It does not override the failed T1 contract, failed `mix ci`, or pending CI-06/CI-07 and LOOSE-03 requirements.
