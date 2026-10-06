---
phase: 139-required-truth-reconciliation
verified: 2026-10-05T23:43:02Z
status: gaps_found
score: 3/5 roadmap success criteria verified
covered_files:
  - .github/actions/release-please/action.yml
  - .github/workflows/ci.yml
  - .github/workflows/oidf-conformance.yml
  - .github/workflows/release-please-automerge.yml
  - .github/workflows/release.yml
  - .gsd-capabilities.json
  - .planning/phases/139-required-truth-reconciliation/139-01-PLAN.md
  - .planning/phases/139-required-truth-reconciliation/139-01-SUMMARY.md
  - .planning/phases/139-required-truth-reconciliation/139-02-PLAN.md
  - .planning/phases/139-required-truth-reconciliation/139-02-SUMMARY.md
  - .planning/phases/139-required-truth-reconciliation/139-03-PLAN.md
  - .planning/phases/139-required-truth-reconciliation/139-03-SUMMARY.md
  - .planning/phases/139-required-truth-reconciliation/139-04-PLAN.md
  - .planning/phases/139-required-truth-reconciliation/139-04-SUMMARY.md
  - .planning/phases/139-required-truth-reconciliation/139-05-PLAN.md
  - .planning/phases/139-required-truth-reconciliation/139-05-SUMMARY.md
  - .planning/phases/139-required-truth-reconciliation/139-06-PLAN.md
  - .planning/phases/139-required-truth-reconciliation/139-06-SUMMARY.md
  - .planning/phases/139-required-truth-reconciliation/139-07-PLAN.md
  - .planning/phases/139-required-truth-reconciliation/139-07-SUMMARY.md
  - .planning/phases/139-required-truth-reconciliation/139-08-PLAN.md
  - .planning/phases/139-required-truth-reconciliation/139-08-SUMMARY.md
  - .planning/phases/139-required-truth-reconciliation/139-09-PLAN.md
  - .planning/phases/139-required-truth-reconciliation/139-09-SUMMARY.md
  - .planning/phases/139-required-truth-reconciliation/139-10-PLAN.md
  - .planning/phases/139-required-truth-reconciliation/139-10-SUMMARY.md
  - .planning/phases/139-required-truth-reconciliation/139-11-PLAN.md
  - .planning/phases/139-required-truth-reconciliation/139-11-SUMMARY.md
  - .planning/phases/139-required-truth-reconciliation/139-12-PLAN.md
  - .planning/phases/139-required-truth-reconciliation/139-12-SUMMARY.md
  - .planning/phases/139-required-truth-reconciliation/139-13-PLAN.md
  - .planning/phases/139-required-truth-reconciliation/139-13-SUMMARY.md
  - .planning/phases/139-required-truth-reconciliation/139-UAT.md
  - .planning/phases/139-required-truth-reconciliation/139-VALIDATION.md
  - .planning/phases/139-required-truth-reconciliation/COVERAGE.md
  - docs/maintainer-release.md
  - mix.exs
  - mix.lock
  - scripts/ci/lint_workflows.sh
  - scripts/maintainer/baseline_inventory.sh
  - scripts/maintainer/finalize_phase_138_inventory.sh
  - scripts/maintainer/finalize_phase_139_acceptance.sh
  - scripts/maintainer/repo_hygiene_check.sh
  - scripts/maintainer/verify_phase140_read_only_closure.py
  - test/lockspire/conformance_redacted_evidence_contract_test.exs
  - test/lockspire/conformance_workflow_contract_test.exs
  - test/lockspire/quality/phase_138_prohibition_consistency_test.exs
  - test/lockspire/quality/phase_139_planning_consistency_test.exs
  - test/lockspire/quality/proof_quality_baseline_test.exs
  - test/lockspire/release/phase140_read_only_closure_contract_test.exs
  - test/lockspire/release/repository_hygiene_contract_test.exs
  - test/lockspire/release_ci_evidence_contract_test.exs
  - test/lockspire/workflow_supply_chain_contract_test.exs
  - test/support/lockspire/release_proof/package_assertions.ex
  - test/support/lockspire/release_proof/workflow_assertions.ex
  - test/support/quality_baseline.ex
  - tools/gsd-capabilities/lockspire-phase-finalizer/capability.json
  - tools/gsd-capabilities/lockspire-phase-finalizer/fixtures/gsd-host-contract.json
  - tools/gsd-capabilities/lockspire-phase-finalizer/lockspire-finalize-command-router.cjs
  - tools/gsd-capabilities/lockspire-phase-finalizer/lockspire-finalize-command-router.test.cjs
  - tools/gsd-capabilities/lockspire-phase-finalizer/lockspire-finalize-lifecycle.test.cjs
  - tools/gsd-capabilities/lockspire-phase-finalizer/lockspire-finalizer-process-supervisor.cjs
  - tools/gsd-capabilities/lockspire-phase-finalizer/post-completion-finalizer-state.cjs
covered_digest: "v2:sha256:49785ee0f2454b719d64e1723a298d7cfb38d984ab396f28a385b545e38d7a1a"
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: passed
  previous_score: 5/5 roadmap success criteria verified
  gaps_closed: []
  gaps_remaining:
    - "Repository-owned exact-SHA acceptance is blocked by the current release-train ledger format before it can refresh origin/main."
    - "The current focused ExUnit selection has failures in the Phase 139 planning and release-hygiene contracts."
  regressions:
    - "Post-verification Phase 141 release-train wording is not recognized by the existing hygiene parser."
    - "Phase 139 planning and CI workflow contract tests still encode Phase 140-era expectations."
gaps:
  - truth: "Repository-owned acceptance checks enforce mix ci and repository hygiene for the reconciled baseline, including no unresolved hygiene BLOCK and an explicit disposition for every WARN."
    status: failed
    reason: "On the current records, repo_owned_checks emits a BLOCK for the release-train ledger. The exact-acceptance branch only calls run_exact_acceptance when BLOCK_COUNT is zero, so its success path is unreachable; the focused exact-SHA contract observed no fetch.argv."
    artifacts:
      - path: "scripts/maintainer/repo_hygiene_check.sh"
        issue: "release_train_version() only parses '- Latest released version: ...' (line 647); the current maintained ledger instead distinguishes Release Please version metadata 1.5.1 from latest public package 1.5.0. repo_owned_checks() reports the missing value as BLOCK, and the exact-acceptance gate skips identity validation while any BLOCK remains."
      - path: ".planning/RELEASE-TRAIN.md"
        issue: "The current format accurately separates unpublished Release Please metadata from the latest public package, but is not recognized by the Phase 139 parser."
      - path: "test/support/lockspire/release_proof/package_assertions.ex"
        issue: "The exact positive fixture asserts that origin/main was refreshed, but the focused multi-contract run failed with 'exact-SHA acceptance did not refresh origin/main'."
    missing:
      - "Teach the hygiene contract to validate the current release-train schema while keeping release metadata distinct from public-package truth."
      - "Run the positive exact-SHA fixture after the local hygiene preflight is clear and confirm it reaches the pinned origin/main fetch and receipt path."
  - truth: "Repository-owned acceptance logic identifies the exact synchronized main SHA and fails closed without canonical same-SHA CI and Release no-publish evidence; the live evidence itself is accepted at the Phase 140 entry gate."
    status: failed
    reason: "The code contains the exact SHA and canonical workflow checks, but the current accepted local path does not reach validate_acceptance_identity(): the preceding ledger BLOCK prevents run_exact_acceptance() from running. A standalone run of the named positive test passed once; the focused multi-contract run reproduced the missing-fetch failure. No live finalizer or workflow gate was run during this verification."
    artifacts:
      - path: "scripts/maintainer/repo_hygiene_check.sh"
        issue: "The exact identity implementation is present and wired, but current repository-owned preflight state makes the successful path unavailable."
      - path: "test/lockspire/release/repository_hygiene_contract_test.exs"
        issue: "The exact-SHA positive contract failed in the focused selection at line 39 because its fixture did not observe a refresh of origin/main."
    missing:
      - "Resolve the hygiene preflight regression and demonstrate the current exact-SHA fixture reaches identity refresh and same-SHA receipt validation."
  - truth: "Maintainer can run mix ci from the reconciled baseline with all checks passing (QUAL-05)."
    status: failed
    reason: "A focused 8-test ExUnit selection exited 2 with four failures. Two are Phase 139 regression contracts that still assert Phase 140-era state or CI step structure; the exact-SHA positive and fail-closed contracts also fail against the current ledger preflight. The full mix ci command was not run."
    artifacts:
      - path: "test/lockspire/quality/phase_139_planning_consistency_test.exs"
        issue: "The current-position assertion requires current_phase 140, current_plan 18, and status verifying; .planning/STATE.md now records Phase 141 complete."
      - path: "test/lockspire/workflow_supply_chain_contract_test.exs"
        issue: "The test requires a separate 'Verify phase finalizer command router' CI step. Current CI combines router and lifecycle Node tests in the single portable lifecycle step, so the exact step-list assertion fails."
      - path: "test/lockspire/release/repository_hygiene_contract_test.exs"
        issue: "The focused exact-SHA acceptance and fail-closed contracts did not pass against the current ledger format."
    missing:
      - "Update the Phase 139 regression assertions to recognize the completed Phase 141 lifecycle and the current combined CI command, without weakening router/lifecycle coverage."
      - "Re-run the focused failing contracts and the required CI lane after the hygiene format regression is corrected."
advisory: []
audit_acknowledged:
  milestone: v1.38
  at: 2026-10-06
  status: gaps_found
---

# Phase 139: Required Truth Reconciliation Verification Report

**Phase Goal:** Maintainers can rely on one exact-SHA, repository-owned acceptance and release truth across gates, workflows, planning, and release records.
**Verified:** 2026-10-05T23:43:02Z
**Status:** gaps_found
**Re-verification:** Yes — current Phase 140/141 records and code were checked after the 2026-10-03 verification.

## Goal Achievement

### Observable Truths — Roadmap Contract

| # | Truth | Status | Evidence |
|---|---|---|---|
| 1 | Repository-owned acceptance checks enforce `mix ci` and repository hygiene for the reconciled baseline, with no unresolved `BLOCK` and a disposition for every `WARN`. | ✗ FAILED | Current `RELEASE-TRAIN.md` no longer has the legacy `Latest released version` line. `repo_owned_checks()` reports a release-train ledger `BLOCK`; exact acceptance only enters `run_exact_acceptance()` when the block count is zero. The focused positive fixture failed because it did not observe `fetch.argv`. |
| 2 | Repository-owned acceptance identifies the exact synchronized `main` SHA and fails closed without canonical same-SHA CI and Release no-publish evidence; live evidence is accepted at the Phase 140 entry gate. | ✗ FAILED | The identity fetch and workflow validation are present in source, but current acceptance is blocked before `validate_acceptance_identity()` by the ledger preflight. A standalone exact-SHA test passed once; the same named test failed in the focused 8-test run with “exact-SHA acceptance did not refresh origin/main.” No live finalizer gate was run. |
| 3 | Maintainers can distinguish required acceptance from supplemental OIDF evidence, whose retained findings are redacted and non-certifying. | ✓ VERIFIED | Current OIDF workflow remains explicitly supplemental. The focused redaction and workflow contract tests passed; the receipt contract separates supplemental evidence from required acceptance. |
| 4 | Maintainers can trace the current public release from source SHA through CI, release run, tag, checksum, Hex package, and maintained records without rewriting history. | ✓ VERIFIED | The current maintained release ledger and Phase 141 baseline preserve the 1.5.0 source SHA, canonical CI and Release run IDs, tag, checksum, Hex package, and the distinction between public 1.5.0 and unpublished 1.5.1 Release Please metadata. This is a trace through maintained records; no live package or workflow query was made. |
| 5 | Maintained planning and release records agree on current milestone and release posture while Release Please ownership, protected exact-ref publishing, full-SHA action pins, and manifest-bound artifact proof remain intact. | ✓ VERIFIED | Current PROJECT, ROADMAP, STATE, MILESTONES, REQUIREMENTS, RELEASE-TRAIN, and Phase 141 baseline consistently describe completed v1.38, Phase 141 closure, no package publication, and the sustaining release train. The Phase 140 exact-SHA CI/release receipt is explicitly bounded to its accepted source SHA. Current release-control source and the selected release contract test retain protected push/no-publish versus dispatch/publish boundaries. The separate Phase 139 planning-consistency test is stale and fails under the QUAL-05 finding below. |

**Score:** 3/5 roadmap success criteria verified (0 present, behavior-unverified).

### Re-verification Context

The prior report was `passed`, 5/5, at `2026-10-03T23:51:12Z`. The GSD status query now returns `stale` because covered source files changed afterward. The verifier refreshed only this report: no plan, STATE, ROADMAP, phase transition, or live finalizer gate was run. CI-06 and CI-07 are currently assigned to Phase 140 in REQUIREMENTS.md and are recorded there as closed by the Phase 140 terminal receipt, with its accepted source and evidence boundary documented in the Phase 141 baseline. Those historical receipts are not evidence that the current post-Phase-141 checkout passed the live gates.

### Deferred Items

None remain from the prior report: CI-06 and CI-07 were moved to Phase 140 and the current requirements mark them complete. No current Phase 139 gap is deferred because no later roadmap criterion specifically resolves the hygiene parser or stale ExUnit assertions.

### Advisory (New Scope, Unevidenced)

No Step 7 new-scope blockers were found. The static `verify.artifacts` query reported several missing-export/pattern results for plan-specific declarations; manual source inspection confirmed the named functions and current wiring, so these query mismatches were not treated as code gaps. Plans 10–13 also returned no parsed artifact rows from that query. The direct behavioral and source checks listed below are the evidence used for those areas.

| # | Finding | Category | Why Advisory |
|---|---|---|---|
| — | None | — | No unevidenced Step 7 blocker was raised. |

### Required Artifacts

| Artifact | Expected | Status | Details |
|---|---|---|---|
| `scripts/maintainer/repo_hygiene_check.sh` | Local `mix ci`, hygiene classification, exact SHA/ref refresh, canonical workflow evidence, and bounded receipt | ✗ GAP | Substantive and connected to ExUnit fixtures. The current release-train wording causes a local `BLOCK`, preventing the exact-SHA success path from reaching the origin/main refresh. |
| `.planning/RELEASE-TRAIN.md` | Current release metadata and public release record | ✓ VERIFIED | The record preserves 1.5.1 Release Please metadata separately from the 1.5.0 public package. The consumer parser in the hygiene script is stale. |
| `test/support/lockspire/release_proof/package_assertions.ex` and `test/lockspire/release/repository_hygiene_contract_test.exs` | Positive and hostile exact-SHA acceptance proof | ✗ GAP | Real fixture and named test entry points exist; the positive and final positive-warning contracts fail in the selected run against current records. |
| `scripts/maintainer/baseline_inventory.sh` and phase finalizer scripts | Bounded inventory and sealed lifecycle transitions | ✓ PRESENT / WIRED | Substantive implementations and current portable lifecycle tests exist. This verification did not execute a live Phase 139 finalizer gate. |
| `.github/workflows/{ci,release,oidf-conformance}.yml` and `.github/actions/release-please/action.yml` | Required CI/release wiring, supplemental OIDF separation, protected exact-ref publishing | ✓ PRESENT / WIRED | Source contains the CI lifecycle command and release trigger boundaries; the portable lifecycle and release-evidence contracts passed. The source-level CI step-name assertion is stale and contributes to the QUAL-05 failure. |
| `tools/gsd-capabilities/lockspire-phase-finalizer/*` | Portable routing, lifecycle, and recovery contracts | ✓ VERIFIED (portable) | Current Node router/lifecycle suite passed 18 tests, failed 0, with 2 expected skips. This is fixture-based portable evidence, not a live installed-GSD finalizer run. |
| Phase 139 plans, summaries, validation, and coverage | 13 completed plan/summary pairs with executable prohibition ownership | ✓ VERIFIED | All 13 plan/summary pairs exist. The selected planning-consistency prohibition test passed and verified all 19 declared prohibition mappings have executable owners. |

### Key Link Verification

| From | To | Via | Status | Details |
|---|---|---|---|---|
| Exact hygiene acceptance | `HEAD`, local `main`, refreshed `origin/main` | Exact full-SHA comparisons before and after local gate | ✗ BLOCKED | Fetch/equality code is present, but the current ledger `BLOCK` prevents the exact branch from invoking it. The fixture's expected fetch log was absent in the focused failing run. |
| Exact hygiene acceptance | Canonical CI and Release no-publish runs | Repository/workflow/event/branch/status/conclusion/head SHA/job validation | ✓ PRESENT / WIRED | The strict selection and validation code plus positive/hostile fixture cases remain in source. Current local preflight prevents reaching this part of the path. |
| OIDF supplemental workflow | Redacted evidence contract | Explicit supplemental label and allowlisted receipt fields | ✓ VERIFIED | Selected redaction and workflow contract tests passed. |
| Release workflow | Release Please → exact verified artifact → protected publish → public verification | SHA-bound manifest and job dependencies | ✓ VERIFIED | The selected Release push/no-publish contract passed; the portable lifecycle suite also passed. No publication path was invoked. |
| Planning consistency contract | Current ROADMAP, REQUIREMENTS, STATE, and Phase 139 artifacts | Source assertions over maintained files | ✗ STALE TEST | The test still requires `current_phase: 140`, `current_plan: 18`, and `status: verifying`; STATE now records Phase 141 complete. This is an outdated assertion, not evidence that the current records disagree. |
| CI workflow contract | Router and lifecycle tests | Exact expected step-name list | ✗ STALE TEST | CI runs the router and lifecycle test files together in the portable lifecycle step; the ExUnit contract still expects an additional router-only step. The underlying Node tests passed. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|---|---|---|---|---|
| Exact acceptance | accepted SHA and workflow evidence | Git refs and canonical GitHub run/job queries | Yes, from validated observations | ⚠️ BLOCKED BEFORE FLOW: local release-train preflight prevents current execution from reaching the ref refresh. |
| Docker hygiene | containers and volumes | Docker CLI output filtered by project and exact volume names | Yes, with separate command-failure outcomes | ✓ FLOWING in fixture-backed implementation; current acceptance is independently blocked by ledger drift. |
| OIDF evidence | module results and retained findings | bounded workflow/test output passed through redaction and receipt allowlist | Yes, redacted and non-certifying | ✓ FLOWING in focused contract tests. |
| Public release record | source SHA, CI/release run IDs, tag, checksum, Hex version | maintained RELEASE-TRAIN, MILESTONES, and Phase 141 baseline records | Yes, linked historic values | ✓ FLOWING as a maintained trace; external values were not queried live in this verification. |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|---|---|---|---|
| Exact-SHA acceptance fixture reaches refreshed `origin/main` | `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.1 MIX_ENV=test mix test test/lockspire/release/repository_hygiene_contract_test.exs:37` | Standalone run: 1 test, 0 failures. In the focused 8-test selection below, this same named test failed with `exact-SHA acceptance did not refresh origin/main`. The standalone pass does not override the failure in the broader current evidence. | ⚠️ INCONSISTENT; gap retained |
| Current Phase 139 hygiene and proof contracts | Focused `mix test` selection of repository hygiene :39/:60, OIDF redaction :66, OIDF workflow :45, release CI :56, Phase 139 planning :7/:48, and workflow supply-chain :46 | 8 tests, 4 failures, exit 2. Failures: exact-SHA did not refresh `origin/main`; fail-closed suite's positive warning-disposition path got a release-train ledger `BLOCK`; planning consistency expected Phase 140; workflow supply-chain test expected a removed standalone router step. Four selected contracts passed. | ✗ FAIL |
| Portable finalizer router and lifecycle contracts | `LOCKSPIRE_GSD_HOST_FIXTURE=tools/gsd-capabilities/lockspire-phase-finalizer/fixtures/gsd-host-contract.json node --test tools/gsd-capabilities/lockspire-phase-finalizer/lockspire-finalize-command-router.test.cjs tools/gsd-capabilities/lockspire-phase-finalizer/lockspire-finalize-lifecycle.test.cjs` | 18 passed, 0 failed, 2 expected skips. Fixture/portable execution only; no live finalizer gate was run. | ✓ PASS |
| Planning prohibition ownership | Included `test/lockspire/quality/phase_139_planning_consistency_test.exs:48` in the focused selection | 19 prohibition rows matched the completed plans and executable owners. | ✓ PASS |

The selected ExUnit command was deliberately limited to named contracts; the full `mix ci` suite was not run. Since selected ExUnit tests fail, QUAL-05 cannot be called green on this checkout.

### Probe Execution

No `probe-*.sh` is declared by the Phase 139 plans or validation strategy, and no conventional `scripts/*/tests/probe-*.sh` was found. No live finalizer or transition probe was run.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|---|---|---|---|---|
| CI-08 | 139-03/04/06 | Distinguish required acceptance from supplemental redacted, non-certifying OIDF evidence | SATISFIED | Current workflow and receipt fields preserve the boundary; the focused OIDF redaction and workflow tests passed. |
| QUAL-05 | 139-01/02/08/10/12/13 | `mix ci` passes at the reconciled acceptance SHA | BLOCKED | The focused ExUnit selection exited 2 with four failures, including two stale Phase 139 expectations and exact acceptance fixtures blocked on current ledger parsing. Full `mix ci` was not run. |
| HYGIENE-05 | 139-01/05/06/10 | No unresolved hygiene BLOCK; every WARN has an explicit disposition | BLOCKED | The current release-train schema causes a real hygiene `BLOCK`; the exact acceptance happy path does not reach ref refresh. |
| HYGIENE-06 | 139-02/03/05/07/08/09/10/11 | Tighten repository-health checks only with repeatable repository-owned evidence | BLOCKED | The check and regression fixture are present, but the current format mismatch makes the positive exact-acceptance contract fail. |
| TRUTH-03 | 139-04/05/08/09/10/11/12/13 | Verify maintained planning and release records describe one coherent current milestone and release posture | SATISFIED (records); stale test | Current records consistently describe Phase 141 closure and the sustaining train. The Phase 139 test still asserts Phase 140 current-state values and fails; its stale assertion is recorded under QUAL-05. |
| TRUTH-04 | 139-04/06/09/10 | Trace the public release across source, CI, release, tag, checksum, Hex, and maintained records | SATISFIED | Maintained 1.5.0 source/run/tag/checksum/package references remain joined in the current release records and Phase 141 baseline. No live external query was made. |
| TRUTH-05 | 139-03/04/07/09/11 | Preserve Release Please ownership, protected exact-ref publishing, full-SHA pins, and manifest-bound proof | SATISFIED | Current release source retains the push/no-publish versus exact-dispatch/publish boundary; the focused release evidence contract and portable lifecycle tests passed. |

CI-06 and CI-07 still appear in older Phase 139 plan requirement fields, but current REQUIREMENTS.md assigns both to Phase 140 and marks them complete there. No current Phase 139 roadmap requirement is orphaned.

### Test Quality Audit

| Test File | Linked Req | Active | Skipped | Circular | Assertion Level | Verdict |
|---|---|---:|---:|---|---|---|
| `repository_hygiene_contract_test.exs` | QUAL-05, HYGIENE-05 | Yes | 0 found in selected requirement-linked files | No; invokes production shell acceptance against isolated fake commands | Behavioral/value | ✗ Current exact positive path and positive warning-disposition path fail against ledger preflight |
| `phase_139_planning_consistency_test.exs` | TRUTH-03, QUAL-05 | Yes | 0 | No; reads tracked planning state | Behavioral/value | ✗ Stale Phase 140 current-state assertion fails under Phase 141 |
| `workflow_supply_chain_contract_test.exs` | HYGIENE-06, TRUTH-05, QUAL-05 | Yes | 0 | No; compares workflow source contract | Structural/value | ✗ Stale expected step list; the current combined Node command itself passed |
| `conformance_redacted_evidence_contract_test.exs`, `conformance_workflow_contract_test.exs` | CI-08 | Yes | 0 | No; bounded independent receipt assertions | Value/behavioral | ✓ Selected tests passed |
| Portable finalizer/router Node tests | HYGIENE-06, TRUTH-03/05 | Yes | 2 expected skips | No; isolated host fixture and production router | Behavioral | ✓ 18 passed, 0 failed |

Disabled requirement-linked tests were not found in the scanned files. The 19 Phase 139 prohibition mappings have active executable owners and their focused consistency assertion passed. The Phase 139 exact-SHA suite is not circular, but its positive path currently cannot distinguish its own acceptance logic from the stale global hygiene preflight until that drift is fixed.

### Decision Coverage

The decision-coverage query returned `total: 12`, `honored: 12`, `not_honored: []`. All trackable Phase 139 CONTEXT.md decisions remain represented in shipped artifacts; this gate is non-blocking.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|---|---:|---|---|---|
| `scripts/maintainer/repo_hygiene_check.sh` | 647, 845, 1075–1079 | Release-train parser rejects current ledger wording and emits a false `BLOCK` | 🛑 BLOCKER | Prevents exact-SHA acceptance from reaching the `origin/main` refresh; see gaps. |
| `test/lockspire/quality/phase_139_planning_consistency_test.exs` | 27 | Hard-coded Phase 140 lifecycle expectation | ⚠️ WARNING | The regression test no longer recognizes the completed Phase 141 state. |
| `test/lockspire/workflow_supply_chain_contract_test.exs` | 62–72 | Hard-coded separate router CI step | ⚠️ WARNING | The current CI invokes router and lifecycle tests in one combined step; the source assertion fails despite the Node suite passing. |
| — | — | No unreferenced `TBD`, `FIXME`, or `XXX` implementation debt marker found in the inspected acceptance, workflow, fixture, and finalizer files | — | No debt-marker blocker. Grep matches for `return null` were normal router/supervisor control flow, not stubs. |

### Human Verification Required

N/A — infrastructure/release-control phase with no user-facing interaction. The current findings are covered by deterministic repository fixtures and named ExUnit tests; no manual UAT is needed to classify them.

### Gaps Summary

Phase 139's exact-SHA acceptance behavior is not currently usable with the post-Phase-141 release ledger: the hygiene parser recognizes only the earlier `Latest released version` format, so it emits a `BLOCK` and does not proceed to refresh `origin/main`. The exact-SHA positive fixture failed in the focused run for that missing refresh, while its isolated run passed once; the inconsistent result does not establish a current passing contract. The current focused test selection also has red Phase 139 planning and CI workflow assertions tied to Phase 140-era state and step layout, so QUAL-05 is not demonstrated green. The maintained public release chain, OIDF supplemental boundary, current planning records, protected release structure, and portable finalizer contracts remain present and were checked without running live finalizer gates.

---

_Verified: 2026-10-05T23:43:02Z_
_Verifier: the agent (gsd-verifier)_
