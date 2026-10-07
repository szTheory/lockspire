---
phase: 142-merge-the-corrected-main-baseline
verified: 2026-10-07T12:53:46Z
status: passed
score: 11/11 must-haves verified
covered_files:
  - .github/workflows/release-please-automerge.yml
  - .github/workflows/release.yml
  - .planning/phases/142-merge-the-corrected-main-baseline/142-01-PLAN.md
  - .planning/phases/142-merge-the-corrected-main-baseline/142-01-SUMMARY.md
  - .planning/phases/142-merge-the-corrected-main-baseline/142-02-PLAN.md
  - .planning/phases/142-merge-the-corrected-main-baseline/142-02-SUMMARY.md
  - .planning/phases/142-merge-the-corrected-main-baseline/142-03-PLAN.md
  - .planning/phases/142-merge-the-corrected-main-baseline/142-03-SUMMARY.md
  - .planning/phases/142-merge-the-corrected-main-baseline/142-04-PLAN.md
  - .planning/phases/142-merge-the-corrected-main-baseline/142-04-SUMMARY.md
  - docs/maintainer-release.md
  - scripts/maintainer/repo_hygiene_check.sh
  - scripts/publish/release_main_freeze.sh
  - test/lockspire/quality/phase_138_prohibition_consistency_test.exs
  - test/lockspire/quality/phase_139_planning_consistency_test.exs
  - test/lockspire/release/phase140_read_only_closure_contract_test.exs
  - test/lockspire/release/repository_hygiene_contract_test.exs
  - test/lockspire/release_ci_evidence_contract_test.exs
  - test/lockspire/release_main_freeze_test.exs
  - test/lockspire/release_workflow_artifact_contract_test.exs
  - test/support/lockspire/release_proof/package_assertions.ex
  - test/support/lockspire/release_proof/workflow_assertions.ex
  - tools/gsd-capabilities/lockspire-phase-finalizer/lockspire-finalize-command-router.cjs
  - tools/gsd-capabilities/lockspire-phase-finalizer/lockspire-finalize-command-router.test.cjs
covered_digest: "v3:sha256:971d0ffdd38c6b4308cd5e95d1df8b0139bf8af81c41d0625b65eda19de70a9b"
behavior_unverified: 0
overrides_applied: 0
---

# Phase 142: Merge the Corrected Main Baseline Verification Report

**Phase Goal:** Maintainers merge the reviewed Phase 141 correction so `main` truthfully identifies 1.5.0 as the latest public package until 1.5.1 has public proof, then establish a green, exact-current-main release candidate.
**Verified:** 2026-10-07T12:53:46Z
**Status:** passed
**Re-verification:** No — initial verification

## Verification Basis

The retained root checkout remains the Phase 141 planning/docs branch; its history does not contain the final squash commit. Source verification used the clean accepted clone at `/private/tmp/lockspire-phase142-main-final`. At verification time, its `HEAD`, local `main`, and `origin/main` were all `6f1a19b39999f96eb24352c75c2a0628375175ae`; the clone worktree remained clean after the spot-check. After the report was generated, the eight covered source files were copied byte-for-byte from that clone into the retained root worktree so the GSD verification owner could recheck the fingerprint there. The local copies now match accepted `main`; no source content was changed from the merged commit.

The private allowlisted acceptance receipt's SHA-256 was recomputed as `9de0275ccdf269b5b66f318a5992228af302cc977dc0cb2d8b733d3261b3ea27`. Its `baseline_sha` matches the accepted source. Live read-only checks confirmed the same current GitHub `main` SHA, PR #113 is merged from reviewed head `084e2849a584c5d287add7693e41af37d7abd5d9`, all seven PR checks passed, canonical CI run 37617422181 succeeded on the merge SHA, and Release run 37617422018 ended in `no_publish`. The receipt confirms local `mix ci` passed (102 ExUnit tests) and repository hygiene reported 24 PASS, 0 WARN, 0 BLOCK.

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|---|---|---|
| 1 | Roadmap SC1; Plan 01 D-06; Plan 02 D-01/D-08: the correction landed through the reviewed PR path and release truth continues to identify 1.5.0 until 1.5.1 has public proof. | ✓ VERIFIED | GitHub reports PR [#113](https://github.com/szTheory/lockspire/pull/113) merged at `2026-10-07T11:55:44Z`, reviewed head `084e2849a584c5d287add7693e41af37d7abd5d9`, merge SHA `6f1a19b39999f96eb24352c75c2a0628375175ae`. Main's `.planning/RELEASE-TRAIN.md:11,15` points at 1.5.0 and resolves its Phase 141 link to the archived baseline. Current read-only Hex API reports `latest_version` and `latest_stable_version` 1.5.0; 1.5.1 endpoint returns 404. GitHub release list reports 1.5.0 latest and the 1.5.1 tag ref returns 404. |
| 2 | Plan 01 D-07: a focused local-link regression contract resolves the corrected archive target and is selected by required Fast Checks. | ✓ VERIFIED | `test/lockspire/release/repository_hygiene_contract_test.exs:12-32` checks local Markdown destinations relative to the ledger. `mix.exs:94` puts `test/lockspire` under `test.fast`, and `.github/workflows/ci.yml:260` runs `mix test.fast`. The accepted canonical run reports Fast Checks success. |
| 3 | Plan 01 CI-09: archived-path fixtures and the full contributor gate pass without breaking historical-path coverage. | ✓ VERIFIED | Phase 138/139/140 tests and `package_assertions.ex` read the v1.38 archive while preserving historical fixtures. The exact-source receipt binds `mix ci` pass (102 ExUnit tests) to the accepted SHA; canonical CI also passed Release Hygiene Drift and Fast Checks. |
| 4 | Roadmap SC2; Plan 03 D-03: local `main` and refreshed `origin/main` are the same full SHA and that SHA's canonical required CI passes. | ✓ VERIFIED | `git rev-parse HEAD`, `main`, and `origin/main` each returned `6f1a19b39999f96eb24352c75c2a0628375175ae`. GitHub ref query returned the same SHA. Run [37617422181](https://github.com/szTheory/lockspire/actions/runs/37617422181) is a successful push CI run for that SHA with all seven required jobs completed successfully. |
| 5 | Roadmap SC3; Plan 03 D-04: exact-SHA hygiene has no BLOCK, every WARN has a disposition, and OIDF/FAPI evidence is non-certifying. | ✓ VERIFIED | The receipt's baseline is the accepted SHA, hygiene is 24 PASS / 0 WARN / 0 BLOCK, and `warn_dispositions` is empty. It classifies supplemental OIDF as `supplemental_non_certifying` with `required_gate: false`. |
| 6 | Plan 02 D-05/D-10: complete live release-timing checks and the live hold establish a safe merge interval. | ✓ VERIFIED | Current readbacks show Release Please auto-merge `disabled_manually`, `hex-publish` restricted to `main` with required reviewer `szTheory` (ID 28652; self-review allowed), both Phase 143 authorization variables absent (404), and no active runs in either release workflow. The prior phase record documents paginated candidate/run inventories before authorization and merge. |
| 7 | Plan 02 D-11; Plan 04 D-11: PR policy and required checks match the actual main protection and review availability. | ✓ VERIFIED | Current protection requires a PR, strict seven canonical contexts, stale-review dismissal, conversation resolution, admin enforcement, and prohibits force-push/deletion. `required_approving_review_count` is 0, consistent with the recorded solo-maintainer fallback. PR #113 was mergeable and all seven required checks passed; exact-head maintainer authorization is recorded separately. No independent GitHub approval is claimed. |
| 8 | Plan 02 D-02; Plan 03 D-02/D-08: merge authorization did not authorize publication, which remains Phase 143's action. | ✓ VERIFIED | The exact-head conditional authorization and separate PR #113 continuation are recorded in `142-02-SUMMARY.md`; `142-RESULT.md` and the accepted Release run record no dispatch, tag, environment approval, or publish. The live Release run skipped package proof, publish, exact-main validation, and public-install jobs. |
| 9 | Plan 03 D-01/D-05/D-10/D-11: merge occurred only after the final exact-head and live-control rechecks. | ✓ VERIFIED | `142-02-SUMMARY.md` records a separate authorization for PR #113's exact head and green checks; `142-03-SUMMARY.md` records the follow-up merge. The live merged PR, merge SHA, seven checks, workflow hold, environment policy, and closed variables were independently read back during this verification. |
| 10 | Plan 04 D-09: the portable release-hygiene router accepts archived project roots, rejects unrelated roots, and preserves child exit behavior. | ✓ VERIFIED | `tools/gsd-capabilities/lockspire-phase-finalizer/lockspire-finalize-command-router.cjs` and its 453-line regression suite exist in accepted `main`; the phase's recorded exact portable command passed 21 tests with 2 intentional skips and 0 failures. The CI receipt confirms Release Hygiene Drift succeeded. |
| 11 | Plan 04 D-10: checked-in release automation denies by default and binds the protected publish boundary to one unchanged current `main` SHA. | ✓ VERIFIED | `.github/workflows/release-please-automerge.yml:30` requires literal `LOCKSPIRE_RELEASE_AUTOMERGE_ENABLED == 'true'`. `release.yml:93` requires the Phase 143 SHA authorization; the protected publisher invokes the freeze helper directly before upload (`release.yml:273-294`). `release_main_freeze.sh:37-43,77-78` validates an active `main`-only update freeze with no bypass actors; `:94-133` rechecks fetched main, hosted main, hosted authorization, recovery ref, and verified SHA immediately before upload. Cleanup is wired at `release.yml:345-353`. The one named regression test for main movement after authorization passed (see Behavioral Spot-Checks). |

**Score:** 11/11 distinct truths verified (all roadmap success criteria and plan-specific constraints; repeated statements deduplicated).

### Required Artifacts

| Artifact | Expected | Status | Details |
|---|---|---|---|
| `.planning/RELEASE-TRAIN.md` | Correct archived Phase 141 link and 1.5.0 public baseline | ✓ VERIFIED | Main clone lines 11 and 15 preserve the 1.5.0 public truth and resolve the relative archive link. |
| `test/lockspire/release/repository_hygiene_contract_test.exs` | Focused local-link contract | ✓ VERIFIED | Substantive test checks link parsing, URI/fragment handling, and resolved files; wired into `test.fast` and canonical Fast Checks. |
| `test/support/lockspire/release_proof/package_assertions.ex` | Archive-aware package/hygiene assertions | ✓ VERIFIED | Substantive helper is called by the link/hygiene tests; exact contributor and hosted CI gates pass. |
| `test/lockspire/quality/phase_138_prohibition_consistency_test.exs` | Current source points into archive; historical fixture remains explicit | ✓ VERIFIED | Main source uses `.planning/milestones/v1.38-phases/...`; included in `test/lockspire` Fast Checks. |
| `test/lockspire/quality/phase_139_planning_consistency_test.exs` | Archive-backed planning checks with historical boundary | ✓ VERIFIED | Main source reads archived Phase 139 and Phase 141 artifacts; included in Fast Checks. |
| `test/lockspire/release/phase140_read_only_closure_contract_test.exs` | Phase 140 read-only closure contract | ✓ VERIFIED | Substantive contract and archived source mappings exist; contributor gate passed. |
| `142-02-SUMMARY.md` | Exact PR identity, conditions, and maintainer authorization | ✓ VERIFIED | Contains final PR #113 continuation, exact head, conditional authorization, and explicit Phase 143 boundary. |
| `142-RESULT.md` and `142-03-SUMMARY.md` | Exact-source result and separate documentation identity | ✓ VERIFIED | Result records source SHA, matching runs, receipt digest, public observation, and Phase 143 handoff; summary retains historical blocker and its final resolution. |
| `tools/gsd-capabilities/lockspire-phase-finalizer/lockspire-finalize-command-router.cjs` and `.test.cjs` | Archive-aware root detection and portable regressions | ✓ VERIFIED | Substantive implementation and tests are present; the recorded CI command passed and Release Hygiene Drift is green. |
| `.github/workflows/release-please-automerge.yml` | Default-deny auto-merge guard | ✓ VERIFIED | Job condition requires literal repository-variable opt-in; source is enabled only behind current documented live hold. |
| `.github/workflows/release.yml` and `scripts/publish/release_main_freeze.sh` | Exact-SHA protected publish guard and cleanup | ✓ VERIFIED | Workflow invokes the substantive shell helper immediately before upload and removes freeze under `always()`; freeze test and workflow-contract tests are wired into required checks. |
| `test/lockspire/release_ci_evidence_contract_test.exs`, `test/lockspire/release_main_freeze_test.exs`, `test/lockspire/release_workflow_artifact_contract_test.exs`, `test/support/lockspire/release_proof/workflow_assertions.ex` | Contracts for exact CI identity, freeze behavior, and artifact path | ✓ VERIFIED | Tests assert the SHA joins, no-bypass freeze, main movement rejection, artifact binding, and workflow/helper wiring; accepted CI passed all seven jobs. |
| `scripts/maintainer/repo_hygiene_check.sh` and `docs/maintainer-release.md` | Exact-SHA acceptance and operator procedure | ✓ VERIFIED | Substantive helper produced the allowlisted receipt; maintainer guide describes exact-source proof and protected release controls. |

The artifact/link helper returned zero artifacts and links because these plans encode those lists as strings rather than the structured path/from schema expected by that helper. I therefore checked the declared paths and wiring directly in the accepted clone and phase records; this parser limitation did not count as a pass.

### Key Link Verification

| From | To | Via | Status | Details |
|---|---|---|---|---|
| `.planning/RELEASE-TRAIN.md` | `milestones/v1.38-phases/141-maintenance-baseline-closure/141-BASELINE.md` | Relative link from `.planning/` | ✓ WIRED | Target exists at accepted `main`; the focused ExUnit contract resolves local destinations from the ledger directory. |
| `repository_hygiene_contract_test.exs` | canonical `Fast Checks` job | `mix test.fast` includes `test/lockspire`; CI workflow runs `mix test.fast` | ✓ WIRED | Confirmed in `mix.exs` and `.github/workflows/ci.yml`; required run 37617422181 passed. |
| Release Please auto-merge workflow | `LOCKSPIRE_RELEASE_AUTOMERGE_ENABLED` | Job-level literal opt-in | ✓ WIRED | Workflow evaluates the variable before the auto-merge job can run; live workflow is disabled and variable is absent. |
| Protected release workflow | `release_main_freeze.sh` | `publish` helper call adjacent to Hex upload | ✓ WIRED | Workflow passes freeze ID, authorization, recovery ref, verified SHA, package tar, and manifest to the shell helper. |
| Freeze helper | Current main and publication authorization | `check_main_sha` called twice in final preflight | ✓ WIRED | Helper compares fetched and hosted main to authorization, recovery ref, and verified SHA, then validates the no-bypass freeze again before invoking publisher. |
| PR #113 | Accepted `main` and canonical CI | GitHub squash merge and push run | ✓ WIRED | PR head, merge SHA, `main`/`origin/main`, and run 37617422181 all align. |
| Acceptance receipt | Exact source readiness | `baseline_sha` joins CI, Release, local gate, and hygiene outcomes | ✓ WIRED | Recomputed receipt hash matches `142-RESULT.md`; receipt baseline equals the accepted commit. |

### Data-Flow Trace (Level 4)

Not applicable. The phase adds release records, CI contracts, and release workflow scripts; no rendered dynamic UI or database-backed view is part of its artifacts.

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|---|---|---|---|
| Reject `main` movement after recovery authorization | `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 MIX_ENV=test mix test test/lockspire/release_main_freeze_test.exs:25` | 1 test, 0 failures (2 excluded), exit 0 | ✓ PASS |
| Exact accepted-source contributor and hygiene gate | Private allowlisted receipt for `6f1a19b39999f96eb24352c75c2a0628375175ae` | `mix ci` pass, 102 ExUnit tests; 24 PASS / 0 WARN / 0 BLOCK | ✓ PASS |
| Required canonical CI on exact merge source | [Run 37617422181](https://github.com/szTheory/lockspire/actions/runs/37617422181) | All seven jobs completed successfully for the exact SHA | ✓ PASS |
| Push-triggered release behavior | [Run 37617422018](https://github.com/szTheory/lockspire/actions/runs/37617422018) | Successful `no_publish`; protected proof, publish, validation, and install jobs skipped | ✓ PASS |

### Probe Execution

Not applicable: no probe script is declared or implied by this release-baseline phase's plans or success criteria.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|---|---|---|---|---|
| TRUTH-06 | 142-01 through 142-04 | Merge the corrected Phase 141 record through review and keep 1.5.0 latest until public proof for 1.5.1 exists. | ✓ SATISFIED | PR #113 merged; release ledger keeps 1.5.0; current Hex and GitHub release queries show no 1.5.1 release/tag. |
| CI-09 | 142-01 through 142-04 | Verify required CI and hygiene for exact current `main`, with warning dispositions recorded. | ✓ SATISFIED | Local/main/origin SHA match; matching seven-job CI passes; receipt reports 24/0/0 and an empty warning disposition list. |

All plan requirement IDs are present in `.planning/REQUIREMENTS.md`. No additional requirement is mapped to Phase 142 without a plan claim.

### Decision Coverage

The decision-coverage gate reported **11/11** trackable `142-CONTEXT.md` decisions honored, with no unhonored decisions.

### Test Quality Audit

| Test File/Group | Linked Requirement | Active | Skipped | Circular | Assertion Level | Verdict |
|---|---|---:|---:|---:|---|---|
| Release-train link and archived Phase 138/139/140 contracts | TRUTH-06, CI-09 | Yes | 0 disabled | None found | Value/behavior | PASS |
| Release CI, main-freeze, and artifact workflow contracts | TRUTH-06, CI-09 | Yes | 0 disabled | None found | Value/behavior | PASS |

The named tests are included under `test/lockspire` and the exact canonical checks pass. Fixture writes model historical repository or GitHub state; expected failure cases are asserted against explicit fixture inputs rather than generated from the system under test. `2 skipped` in the historical portable router command are the command's intentional integration skips, not disabled requirement-linked tests.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|---|---:|---|---|---|
| — | — | None requiring action | — | Scans found only temporary-file templates, normal `null` guard returns, and TODO strings used as hygiene-test fixture data; no unreferenced debt markers, placeholders, or stubbed release paths. |

### Human Verification Required

N/A — infrastructure/release-engineering phase. The exact-head maintainer authorization for PR #113 is recorded and the merge completed; no human verification step remains outstanding.

### Deferred Items

None. Phase 143 publication is expressly outside this phase and does not defer a Phase 142 success criterion.

### Gaps Summary

No gaps. The corrected Phase 141 record is on reviewed `main`; the accepted merge SHA is synchronized across `HEAD`, local `main`, and `origin/main`; its matching CI and Release no-publish runs passed; exact-SHA hygiene is green with no warnings or blockers; and public Hex/GitHub state still identifies 1.5.0 as latest. Phase 143 must perform its own fresh main and publication checks before any release action.

---

_Verified: 2026-10-07T12:53:46Z_  
_Verifier: the agent (gsd-verifier)_
