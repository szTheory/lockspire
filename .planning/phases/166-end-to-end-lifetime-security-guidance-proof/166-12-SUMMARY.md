---
phase: "166"
plan: "12"
subsystem: security-proof
tags: [oauth, client-lifetimes, ci, security-review, receipts]
requires:
  - phase: "166-11"
    provides: Final lifetime guidance and candidate documentation
provides:
  - Final candidate-bound live CI, package receipt, and independent security review evidence
  - Reconciled 69-case evidence map and explicit probe dispositions
  - Conditional completion of the DCR default-lifetime audit todo
affects: [phase-166, DCR-15, DCR-16, DCR-17, DCR-18, DCR-19]
actuals:
  tokens: 35495
  tasks: 2
  commits: 18
commits: 18
plan_head_before: 6c8d9191f4800b5d50addafabce24d7414d08917
plan_head_after: 93bb6e386d6751873ec2c090bd751ddfbd575a7d
tech-stack:
  added: []
  patterns:
    - Final proof binds to an exact source/package/docs candidate SHA
    - Probe flags remain explicit when tests do not supply defined predicates
key-files:
  created:
    - .planning/phases/166-end-to-end-lifetime-security-guidance-proof/166-SECURITY.md
    - .planning/phases/166-end-to-end-lifetime-security-guidance-proof/166-CI-EVIDENCE.json
    - .planning/phases/166-end-to-end-lifetime-security-guidance-proof/166-12-SUMMARY.md
    - scripts/acceptance/clean_room/client_lifetime_upgrade.py
    - test/acceptance/client_lifetime_upgrade_test.py
  modified:
    - .planning/phases/166-end-to-end-lifetime-security-guidance-proof/166-EVIDENCE-MAP.json
    - .planning/phases/166-end-to-end-lifetime-security-guidance-proof/166-VALIDATION.md
    - .planning/phases/166-end-to-end-lifetime-security-guidance-proof/deferred-items.md
    - .planning/todos/completed/2026-10-13-audit-dcr-default-lifetime-semantics.md
decisions:
  - "Use candidate f68c7f0f47cb957ed8dc31b35cc78fd612eeb1ea for final behavior, package, documentation, CI, receipt, and review evidence; subsequent commits are planning records only."
  - "Close the umbrella after current DCR-15–19 gates passed, while retaining A-EDGE-16/17/19 as unresolved and both descriptor-less prohibitions as flagged-unverified."
metrics:
  duration: "7h 40m from preceding plan summary commit through final source-fix evidence; elapsed calendar interval"
  completed: "2026-10-22"
status: complete
---

# Phase 166 Plan 12: Final Security, CI, and Lifetime Evidence Summary

**Final exact-candidate CI, the nine-scenario packaged lifetime proof, and an independent scoped security review all passed on `f68c7f0f47cb957ed8dc31b35cc78fd612eeb1ea`; the DCR audit todo remains completed with probe limits explicit.**

## Completed gates

- Canonical GitHub Actions run [39766614548](https://github.com/szTheory/lockspire/actions/runs/39766614548) completed successfully on the final behavior/package/documentation candidate. The seven observed `main` required contexts all passed: Adoption Demo Smoke, Complete Coverage Evidence, Dialyzer, Fast Checks, Integration Checks, Minimum Supported Elixir/OTP, and Release Hygiene Drift.
- The final CI matrix reported Fast Checks at 2 properties / 1,935 tests / 0 failures / 6 skipped / 497 excluded; minimum-supported Elixir/OTP at 2 properties / 2,432 tests / 0 failures / 6 skipped / 497 excluded; broad integration at 494 tests / 0 failures / 1,940 excluded; and the dedicated package lane at 3 tests / 0 failures.
- The broad lane excluded all three package-only wrappers. The explicit lifetime package lane ran them once and validated all nine required scenario IDs: 49 checks passed, 0 failed or skipped; process, database, and temporary-root cleanup all completed. Artifact 12420254180 binds the receipt to f68; c6 artifact 12418964333 is now historical.
- Independent review on the exact candidate and scope digest `3fd1cbc9cf04b2dbf212049399a10159ad16e1f370e9df5277b39ca4f3cee4f4` returned **SECURED**, with 25/25 registered threats closed and no open high/critical finding. The focused security/storage/host selection passed 142 tests with 0 failures on unchanged Elixir surfaces. The new selected-prefix CLI regression passed 3 tests/0 failures, and the independent lifetime Python selection passed 38/0. The final local fast suite before this Python-only fix passed 2,432 tests/0 failures, 497 excluded, and 6 skipped; final CI fast and minimum-supported lanes also passed.
- All 69 Phase 162 contract cases map to evidence on the final candidate. The pending umbrella todo was moved to completed while preserving its metadata, history, and closure explanation.

Safe run/check IDs, artifact hashes, candidate archive/tree identity, exact scenario IDs, counts, cleanup, and historical-run distinction are in [166-CI-EVIDENCE.json](166-CI-EVIDENCE.json). The reviewer’s threat-by-threat results and scope are in [166-SECURITY.md](166-SECURITY.md). The per-case candidate and probe map is [166-EVIDENCE-MAP.json](166-EVIDENCE-MAP.json); gate-by-gate validation and remaining caveats are in [166-VALIDATION.md](166-VALIDATION.md).

## Probe limits and historical failures

A-EDGE-16, A-EDGE-17, and A-EDGE-19 remain explicitly `unresolved`; the two descriptor-less prohibition entries remain `flagged-unverified`. The independent reviewer confirmed that these labels were not cleared by adjacent passing tests, and no test descriptors were fabricated. Umbrella closure reflects completion of defined DCR-15–19 requirements and explicit recording of those probe dispositions, not a claim that each spec-less predicate was individually exercised.

The earlier Plan 10, pre-final failures, and prior c6 candidate success are retained in [deferred-items.md](deferred-items.md) and superseded only as final-candidate evidence by run 39766614548. The former output included Phase 28 update assertions, `lifetime_version` fixture failures, Phase 133 `gen.kek` errors, and a clean-room `scenario=unknown` assertion; available evidence did not establish a single root cause for that matrix run. A separate clean-room management-token timing failure was reproduced with an injected three-second delay and two-second fixture TTL, then repaired by raising only the test fixture TTL to ten seconds while preserving expiry and recovery assertions.

## Deviations from plan

A follow-up review after the first evidence close-out found one bounded CLI correctness bug: in the no-work-root `client_lifetime_upgrade.py` path, `--scenario public` still validated the receipt against both prefixes. The runner now supplies the exact selected set, matching the work-root path. The regression mocks package preparation and scenario execution, covers the single-prefix temporary-root branch, and retains an all-prefix control. Commit `f68c7f0f` contains only this runner fix and its test; the exact candidate was pushed and revalidated through CI and independent security review.

### Auto-fixed blocking issues

1. **Rule 3 — Final proof partition included package wrappers in broad integration.** ExUnit `--only integration` inclusion took precedence for tests also tagged `lifetime_package`; wrappers were made package-only so the broad lane omits them and the explicit package lane runs them exactly once. Focused selectors and final CI passed.
2. **Rule 3 — Strict CI type/unreachable-pattern and selector contracts blocked required checks.** Bounded type and pattern corrections preserved runtime behavior; exact fast-selector expectations and closure-verifier fixtures were aligned. Required Dialyzer, Fast Checks, and Release Hygiene Drift passed on the final candidate.
3. **Rule 1 — Clean-room management-token TTL fixture was too short under setup delay.** A controlled injected delay reproduced expiry before the update request. The fixture duration changed from two to ten seconds; expiry, old-token rejection, host recovery, and unrelated-deadline assertions remain. The packaged candidate receipt passed.

No dependency, protocol behavior, security selection, or test assertion was weakened to obtain green results. Evidence-only commits after `f68c7f0f` do not change source, docs, package, or CI inputs; any change to those inputs requires a new candidate proof. The prior c6 CI/receipt/review records are preserved as historical in the evidence JSON.

## Plan commits

The plan ledger measures 18 commits from `6c8d9191f4800b5d50addafabce24d7414d08917` through refreshed evidence commit `93bb6e38`:

| Commit | Change |
|---|---|
| `9a8c97af` | Repair lifetime proof regressions |
| `d4acd368` | Repair final lifetime proof lanes |
| `0ef8c556` | Resolve strict lint and unreachable clauses |
| `f5b06a99` | Make grant issuance contracts precise |
| `6b32744e` | Clear strict QA gate |
| `4a7fb038` | Include lifetime guidance in published docs |
| `1a5d884a` | Enforce exact lifetime seam boundaries |
| `93fb2a45` | Keep clean-room failures secret-safe |
| `c56c3f64` | Freeze authorization exchange clock |
| `f9996679` | Partition package proof wrappers exactly once |
| `3c84d846` | Isolate package proofs from fast checks |
| `6e055e51` | Enforce exact lifetime proof partition |
| `c6bc4174` | Align closure verifier with fast selector; prior behavior candidate |
| `e0db9671` | Record independent security review for prior candidate |
| `5a2f3dee` | Record prior candidate evidence and initial umbrella closure |
| `f68c7f0f` | Fix temporary-root CLI selected-prefix receipt validation and add regression |
| `e21eee76` | Commit initial Plan 12 summary |
| `93bb6e38` | Refresh final proof artifacts after the selected-prefix fix |

## Self-Check: PASSED

- [x] `166-SECURITY.md`, `166-CI-EVIDENCE.json`, `166-EVIDENCE-MAP.json`, `166-VALIDATION.md`, and the completed todo exist and bind final evidence to f68.
- [x] All 69 mapped cases match the Phase 162 contract; requirement coverage is exactly DCR-15 through DCR-19.
- [x] Final evidence JSON parses; seven checks bind to f68 and are successful; the nine-scenario receipt has 49 passed, zero failed/skipped, and complete cleanup.
- [x] Task/source and evidence commits are ancestors of current HEAD: `f68c7f0f`, `93bb6e38`, and `e21eee76`; the 18-commit count and `plan_head_after` are measured from the recorded base. The final summary commit is recorded separately.
- [x] `git diff --check` passed for proof artifact changes. Parent-owned state and roadmap edits were left untouched.
