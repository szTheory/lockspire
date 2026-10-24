---
phase: 171-accepted-baseline-finding-qualification
verified: 2026-10-24T21:34:36Z
status: gaps_found
score: 9/10 must-haves verified
covered_files:
  - .planning/phases/171-accepted-baseline-finding-qualification/171-01-PLAN.md
  - .planning/phases/171-accepted-baseline-finding-qualification/171-01-SUMMARY.md
  - .planning/phases/171-accepted-baseline-finding-qualification/171-02-PLAN.md
  - .planning/phases/171-accepted-baseline-finding-qualification/171-02-SUMMARY.md
  - .planning/phases/171-accepted-baseline-finding-qualification/171-03-PLAN.md
  - .planning/phases/171-accepted-baseline-finding-qualification/171-03-SUMMARY.md
  - .planning/phases/171-accepted-baseline-finding-qualification/171-DELIVERY.md
  - .planning/phases/171-accepted-baseline-finding-qualification/171-MAIN-ACCEPTANCE.json
  - .planning/phases/171-accepted-baseline-finding-qualification/171-QUALIFICATION-DECISIONS.md
  - .planning/phases/171-accepted-baseline-finding-qualification/171-QUALIFICATION-PROBE-20261024T204101Z.json
  - .planning/phases/171-accepted-baseline-finding-qualification/171-QUALIFICATION-PROBE.json
  - .planning/phases/171-accepted-baseline-finding-qualification/171-QUALIFICATION.json
  - .planning/phases/171-accepted-baseline-finding-qualification/171-REVIEW-DISPOSITION.md
  - .planning/phases/171-accepted-baseline-finding-qualification/171-REVIEW-FIX.iter2.md
  - .planning/phases/171-accepted-baseline-finding-qualification/171-REVIEW-FIX.md
  - .planning/phases/171-accepted-baseline-finding-qualification/171-REVIEW.md
  - .planning/phases/171-accepted-baseline-finding-qualification/171-SECURITY.md
  - .planning/phases/171-accepted-baseline-finding-qualification/171-VALIDATION.md
  - .planning/phases/171-accepted-baseline-finding-qualification/171-qualification_probe_test.exs
  - config/test.exs
  - docs/supported-surface.md
  - lib/lockspire/domain/interaction.ex
  - lib/lockspire/protocol/authorization_request.ex
  - lib/lockspire/web/controllers/authorize_controller.ex
  - lib/lockspire/web/router.ex
  - scripts/conformance/fapi2-plan.json
  - scripts/conformance/oidf-suite-lock.json
  - scripts/conformance/phase37-plan.json
  - scripts/conformance/run_ephemeral_oidf_profile.sh
  - scripts/conformance/runner-requirements.lock
  - scripts/maintainer/repo_hygiene_check.sh
  - test/integration/phase15_par_authorization_e2e_test.exs
  - test/integration/phase37_protocol_strictness_e2e_test.exs
  - test/lockspire/qualification_ledger_contract_test.exs
  - test/lockspire/web/authorize_controller_test.exs
  - test/lockspire/web/discovery_controller_test.exs
  - test/support/config_case.ex
  - test/support/test_account_resolver.ex
  - test/test_helper.exs
covered_digest: "v3:sha256:c2d7bab769164f9bc0277261254aaa25eea97401342398d898f6d2dc38887851"
behavior_unverified: 1
overrides_applied: 0
behavior_unverified_items:
  - truth: Shared-profile runs are serialized across the disposable database, port 4100, Compose resources and artifact directories, and interruption preserves the actual exit/classification.
    test: Keep the two selected wrappers recorded as unlaunched; before asserting the broader guarantee, either scope it to explicit sequential operation or exercise overlap/interruption in an isolated runner environment.
    expected: Record that zero processes launched, so no shared-resource or interruption event occurred and no execution/cleanup result is claimed; any broader serialization/classification guarantee has separate evidence or is narrowed.
    why_human: The authorized unavailable path was used. Static wrapper traps and contract checks do not empirically prove concurrent-run or interruption behavior.
gaps:
  - truth: Files changed by Phase 171 contain no unreferenced debt markers.
    status: failed
    reason: The phase modified .planning/ROADMAP.md, which still contains six unreferenced TBD markers for Phase 172–174 plan/progress placeholders. The verifier debt-marker gate treats each unreferenced TBD in a phase-modified file as a blocker.
    artifacts:
      - path: .planning/ROADMAP.md
        issue: 'The phrases "Plans: TBD" and "0/TBD" remain in downstream phase entries without a same-line issue, PR, or DEF reference.'
    missing:
      - Replace the markers with explicit auditable downstream planning status or attach the formal follow-up reference before closing verification.
---

# Phase 171: Accepted Baseline & Finding Qualification Verification Report

**Phase Goal:** Maintainers can identify an accepted implementation base and a finite set of current, supported cases whose expected outcomes and owners are settled before dependent planning.
**Verified:** 2026-10-24T21:34:36Z
**Status:** gaps_found
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|---|---|---|
| 1 | The accepted implementation base is backed by reviewed delivery reconciliation and the original exact-main authority receipt. | ✓ VERIFIED | `171-DELIVERY.md` records PR #138 integration and custody dispositions. The receipt is 1,933 bytes, hashes to `be2cdf5fe60df6788d304e451d736b4ac7746a111c9ff71b422ef27b5b777e39`, and names base `fe38beee987b135e87c99e7aa7f2488b4c8613e8`; its JSON records local gate pass (199 ExUnit), same-SHA CI pass, Release no-publish pass, 22 PASS / 2 WARN / 0 BLOCK, and both warning dispositions. The authority was not rerun. |
| 2 | The selected external profiles have exact immutable inputs and their unavailable prerequisite boundary is visible. | ✓ VERIFIED | The two profile records identify source host/SHA, suite commit/tag, lock, archive/helper and image hashes, exact plan hashes, required/observed Python and pip, the interpreter lookup exit 2, dependency-closure exit 1, and concrete retry owner/action. Both wrappers are explicitly NOT LAUNCHED with null exits/classifications and no receipts; they are not protocol passes. |
| 3 | The finite ledger attributes twelve current cases with distinct conditions, expected/observed outcomes, normative/support sources, repro identities and owners. | ✓ VERIFIED | `171-QUALIFICATION.json` contains A171-001…006 and P171-001…006. Ten rows cite source-host tests and two cite controlled HTTP observations; the ledger separates support/cause, source date/hash, observations, reproducible command and owners. The current allowlisted probe record binds both named assertions and positive controls to source `30e385a33bb2a7f67d94c558dedf7691ecde5863` and probe SHA-256 `0f32ab008fe4ebffc17d471ffd0959fe55861d418ce62fe8f636330f6f9972f5`. |
| 4 | The two actual counterexamples qualify downstream corrections without being described as product passes or fixes. | ✓ VERIFIED | The recorded run completed 2 tests with 2 named normative failures, 0 skipped, exit 2, and all positive controls passed. A171-003 observed HTTP 302 with OAuth error parameters where OIDC Core 3.1.2.6 expects HTTP 400 without them. P171-005 observed HTTP 400 before consent where the attributed RFC 9126 §4 → RFC 9101 §§5, 6.3, 10.7 interpretation expects consent under pushed `openid email`; the addendum explicitly says this is a linked-clause interpretation and adds no JAR requirement. Neither behavior is claimed fixed. The probe was not rerun for verification, as instructed; its source-bound observation and assertions were inspected. |
| 5 | All six AUTHR/PARB requirements have explicit evidence-backed dispositions and dependent phase scope reflects only the two reproduced corrections. | ✓ VERIFIED | Matrix lists all six dispositions. Phase 172 is narrowed to A171-003; Phase 173 to P171-005; other ten proofs are reused. Requirements retain all six IDs as pending behavior acceptance and Phase 174 retains correction RED/GREEN, negative/security, packaged proof and delivery obligations. |
| 6 | The frozen matrix is finite, ordered, identity-bound and protected against drift. | ✓ VERIFIED | Matrix is `frozen`, has twelve sorted rows, six dispositions, no blocking entries, and 30 ordered manifest inputs. Current `input_digest` is `26648970ba7164cf9fa357c6ff03d819fa7643736bce2127208670e713d5346c`. The independently rerun ledger contract validates current references and manifest: 21 tests, 0 failures. |
| 7 | Unresolved selected-case/security/API/support choices and missing mandatory repro evidence block planning instead of being silently approved. | ✓ VERIFIED | The final ledger has no blockers because both selected cases have controlled observations and the scoped normative interpretation is recorded. The unavailable optional profiles remain explicitly supplemental. No product runtime change, install, input refresh, publication or merge is claimed. |
| 8 | The owner/provenance, ordering and malformed-ledger contracts distinguish equal outcomes and reject incomplete or empty inventories without an explicit replan. | ✓ VERIFIED | `test/lockspire/qualification_ledger_contract_test.exs` exercises unique IDs, source/reference validation, malformed types, evidence boundaries, requirement coverage, ordering, empty/single inventories and freeze consistency. Focused run: 21 tests, 0 failures. |
| 9 | Profile retries sharing resources are serialized, and interruptions preserve the actual exit/classification. | ⚠️ PRESENT_BEHAVIOR_UNVERIFIED | The plans require serial profile execution and wrapper source contains INT/TERM handling. Both selected wrappers were explicitly not launched: zero processes means no resource collision, interruption, or cleanup event occurred. No test exercises concurrent overlap or interruption, so the broader state/order claim is not behaviorally proven. See Human Verification Required. |
| 10 | The completed phase leaves an auditable handoff with accepted base, preserved ownership, current branch and explicit next actions. | ✓ VERIFIED | `171-DELIVERY.md` separates accepted main from the feature branch, preserves unknown worktrees and histories, records the original receipt and warns that supplemental profile preparation is optional. Current Phase 172/173 correction owners and Phase 174 delivery obligations are explicit. |

**Score:** 9/10 must-haves verified (1 present, behavior-unverified).

### Deferred Items

None. The two protocol counterexamples are qualified inputs for Phases 172/173, not failures of Phase 171’s qualification goal.

### Required Artifacts

| Artifact | Expected | Status | Details |
|---|---|---|---|
| `171-DELIVERY.md` | Reviewed reconciliation, accepted-base handoff and preserved ownership | ✓ VERIFIED | Substantive inventory, PR/receipt history, retained resources and next actions. |
| `171-MAIN-ACCEPTANCE.json` | Original successful exact-main receipt | ✓ VERIFIED | 1,933-byte receipt; content hash matches the canonical ledger reference. |
| `171-QUALIFICATION.json` | Finite case ledger, profiles, frozen matrix and manifest | ✓ VERIFIED | Parsed JSON; 12 case IDs, 7 category entries, 6 dispositions, zero selected-case blockers and 30 ordered manifest entries. |
| `171-QUALIFICATION-PROBE.json` | Allowlisted controls, expected/observed projections and named outcomes | ✓ VERIFIED | Two actual counterexamples, both with passing controls, source/probe hashes and no skipped cases. |
| `171-qualification_probe_test.exs` | Explicit two-case HTTP qualification outside default test discovery | ✓ VERIFIED | Substantive router/repository HTTP tests with controlled setup and final normative assertions; probe observation identifies exact source and file hash. |
| `qualification_ledger_contract_test.exs` | Executable ledger and frozen-matrix consistency contract | ✓ VERIFIED | 21 focused tests pass; negative fixtures cover shape/reference/evidence and freeze drift. |
| `171-QUALIFICATION-DECISIONS.md` | Attributed normative and support interpretation | ✓ VERIFIED | Distinguishes direct OIDC rule from RFC linked-clause interpretation and preserves plain PAR boundary. |
| `171-SECURITY.md`, `171-REVIEW.md` | Mitigation/review evidence for phase artifacts | ✓ VERIFIED | Security report records 13/13 threats closed; final review records zero findings and disposition has zero open items. |

The plan artifact CLI returned all artifacts present/substantive: 4/4 for Plan 01, 2/2 for Plan 02, and 6/6 for Plan 03. No runtime UI/data rendering is in scope; the ledger’s case values flow from source-bound tests/probe records into the matrix and are checked by the contract, rather than from a hardcoded user-facing data source.

### Key Link Verification

| From | To | Via | Status | Details |
|---|---|---|---|---|
| Delivery handoff | `scripts/maintainer/repo_hygiene_check.sh` | Reviewed reconciliation precedes exact-main authority | ✓ WIRED | CLI link check found target; receipt matches the ledger’s accepted SHA. |
| Qualification ledger | `test/integration/phase37_protocol_strictness_e2e_test.exs` | A171-001 source-host proof | ✓ WIRED | Named redirect-mismatch test and source revision are recorded. |
| Qualification ledger | `scripts/conformance/oidf-suite-lock.json` | Immutable suite identity | ✓ WIRED | Lock hash and exact input fields are recorded. |
| Qualification ledger | `test/integration/phase15_par_authorization_e2e_test.exs` | PAR proof owner | ✓ WIRED | Existing cases reference named assertions from this test file. |
| Qualification ledger | `171-qualification_probe_test.exs` | Controlled A171-003/P171-005 observations | ✓ WIRED | Both case references resolve to named assertions and bounded observations. |
| Qualification ledger | `.planning/REQUIREMENTS.md` | Six downstream requirement dispositions | ✓ WIRED | All AUTHR/PARB IDs appear in the matrix and requirement mapping. |
| Qualification ledger | `.planning/ROADMAP.md` | Narrowed downstream phase contracts | ✓ WIRED | Roadmap Phase 172/173 goals match retained corrections. |

CLI key-link check: 7/7 verified. Data-flow tracing is not applicable to dynamic UI/API output; there is no rendered data artifact in this phase.

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|---|---|---|---|
| Frozen ledger validation and negative fixtures | `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 LOCKSPIRE_TEST_DB_NAME=lockspire_171_main_20261024b mix test test/lockspire/qualification_ledger_contract_test.exs` | 21 tests, 0 failures, 9.0s | ✓ PASS |
| Controlled A171-003/P171-005 source-host observations | Recorded command in `171-QUALIFICATION-PROBE.json` | Earlier process completed 2 tests, 2 named normative failures, 0 skipped; verification did not rerun it | ✓ EVIDENCE INSPECTED |
| Exact-main authority | Original `171-MAIN-ACCEPTANCE.json` | Original receipt hash and exact-base identity match; authority not rerun | ✓ EVIDENCE INSPECTED |

No full suite, external profile, server, package installation or main acceptance gate was rerun.

### Probe Execution

| Probe | Command | Result | Status |
|---|---|---|---|
| `.planning/phases/171-accepted-baseline-finding-qualification/171-qualification_probe_test.exs` | Recorded explicit command, Elixir 1.19.5 / OTP 28.5, dedicated DB `lockspire_171_main_20261024b` | Observation source `30e385a33bb2a7f67d94c558dedf7691ecde5863`, probe hash `0f32ab…9972f5`, exit 2, 2 tests / 2 expected normative failures / 0 skipped; all controls passed | COMPLETED COUNTEREXAMPLE; inspected, not rerun |
| `phase37` and `fapi2` optional wrappers | Recorded profile attempts in qualification ledger | Authorized unavailable path: zero processes launched, interpreter lookup exit 2, locked closure check exit 1, wrapper exit/classification null, no receipts and no cleanup event | UNAVAILABLE, NOT A PROTOCOL RESULT |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|---|---|---|---|---|
| BASE-01 | 171-01 | Reviewed delivery reconciliation and fresh accepted-main evidence | ✓ SATISFIED | Delivery record plus unchanged exact receipt and matching SHA/CI/no-publish evidence. |
| BASE-02 | 171-02 | Exact immutable profile identities and honest unavailable-input behavior | ✓ SATISFIED | Exact input hashes and failed prerequisites are recorded; wrappers remain visibly unlaunched, supplemental and owned for retry. |
| FIND-01 | 171-01/02 | Finite attributable case ledger with current proof and honest cause | ✓ SATISFIED | Twelve cases, ten existing proofs, two actual controls-backed counterexamples, normative/support references and owners. |
| FIND-02 | 171-03 | Frozen matrix and qualification-driven downstream scope | ✓ SATISFIED | 12-row frozen matrix, all six requirement dispositions, 30-entry digest and explicit Phase 172/173 narrowing. |

No orphaned Phase 171 requirement IDs were found.

### Test Quality Audit

The active contract test contains no disabled/skipped test markers. Its assertions check exact field/value/reference/freeze properties and malformed-input rejection, rather than only file presence. The phase-local probe compares independently recorded normative expectations against actual HTTP projections; its intentional RED assertions remain outside default test discovery. No test-generated expected-value loop or production result capture was found in the reviewed evidence path.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|---|---:|---|---|---|
| `.planning/ROADMAP.md` | 67, 79, 92, 110–112 | Unreferenced `TBD` placeholders (`Plans: TBD`, `0/TBD`) | 🛑 Blocker | The roadmap was modified by this phase and these six markers have no same-line issue/PR/DEF follow-up reference. The verifier debt-marker gate makes this a gap even though the placeholders describe future downstream planning. |
| `171-03-SUMMARY.md`, `171-REVIEW.md` | — | Older manifest digest narratives | ℹ️ Info | SUMMARY reports the earlier 29-entry digest `cf44…`; review reports `d5b…`. The current canonical ledger and passing contract use the 30-entry digest `26648970…`. The older narratives were not used as verification evidence. |

### Human Verification Required

1. **Review scoped normative interpretation and phase changes**

   **Test:** Review `171-QUALIFICATION-DECISIONS.md` and the REQUIREMENTS/ROADMAP amendments before dependent plans are authored; acknowledge the RFC 9126 → RFC 9101 interpretation and whether the two unclassified A-EDGE assumptions remain material.
   **Expected:** The maintainer confirms the selected expectations and scope are acceptable, while keeping the two observed product counterexamples assigned to Phases 172/173.
   **Why human:** The plan explicitly deferred this normative/support judgment and the two assumptions remain flagged-unverified; a contract test cannot supply maintainer policy judgment.

2. **Resolve descriptor-less plan prohibitions**

   **Test:** Review the three unresolved plan prohibitions and decide whether their current documented constraints are sufficient or need executable descriptors.
   **Expected:** Each prohibition receives an explicit human disposition; none is silently treated as enforced or passing.
   **Why human:** Each is marked unresolved and has no wired verification descriptor.

3. **Accept the optional-profile unavailable boundary**

   **Test:** Review both profile records, null wrapper results and concrete preparation/retry owner/actions before deciding whether any later optional retry is needed.
   **Expected:** Missing CPython/pip/locked dependencies remain an infrastructure-unavailable result, with no protocol pass inferred and no unreviewed installation/input refresh.
   **Why human:** The wrappers did not launch, so external provider/profile behavior was not observed; retry setup is a maintainer decision.

4. **Exercise profile overlap and interruption behavior**

   **Test:** Record that the explicitly authorized unavailable path launched zero profile processes. Before carrying the broad guarantee forward, either narrow the wording to the documented sequential retry procedure or gather overlap/interruption evidence in an isolated runner environment.
   **Expected:** No resource collision, interruption, or cleanup outcome is claimed for this run; any broader guarantee has separate evidence or is scoped down.
   **Why human:** The selected wrappers were not launched. Static signal traps and contract tests do not establish concurrent-run ordering or interrupted-result behavior.

### Gaps Summary

The baseline receipt, finite ledger, two real controlled counterexamples, six requirement dispositions, narrowed downstream scope and current manifest drift contract are evidenced. Phase 171 cannot report `passed` because `.planning/ROADMAP.md`, a phase-modified file, retains six unreferenced `TBD` markers and the mandatory debt-marker gate classifies them as blockers. The separate human-review items remain visible; the two known product defects are valid Phase 172/173 inputs, not Phase 171 gaps.

---

_Verified: 2026-10-24T21:34:36Z_  
_Verifier: the agent (gsd-verifier)_
