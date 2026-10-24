---
phase: 171-accepted-baseline-finding-qualification
verified: 2026-10-24T22:10:04Z
status: passed
score: 10/10 must-haves verified
covered_files:
  - .planning/REQUIREMENTS.md
  - .planning/ROADMAP.md
  - .planning/phases/171-accepted-baseline-finding-qualification/171-01-PLAN.md
  - .planning/phases/171-accepted-baseline-finding-qualification/171-01-SUMMARY.md
  - .planning/phases/171-accepted-baseline-finding-qualification/171-02-PLAN.md
  - .planning/phases/171-accepted-baseline-finding-qualification/171-02-SUMMARY.md
  - .planning/phases/171-accepted-baseline-finding-qualification/171-03-PLAN.md
  - .planning/phases/171-accepted-baseline-finding-qualification/171-03-SUMMARY.md
  - .planning/phases/171-accepted-baseline-finding-qualification/171-04-PLAN.md
  - .planning/phases/171-accepted-baseline-finding-qualification/171-04-SUMMARY.md
  - .planning/phases/171-accepted-baseline-finding-qualification/171-DELIVERY.md
  - .planning/phases/171-accepted-baseline-finding-qualification/171-MAIN-ACCEPTANCE.json
  - .planning/phases/171-accepted-baseline-finding-qualification/171-PATTERNS.md
  - .planning/phases/171-accepted-baseline-finding-qualification/171-QUALIFICATION-DECISIONS.md
  - .planning/phases/171-accepted-baseline-finding-qualification/171-QUALIFICATION-PROBE-20261024T204101Z.json
  - .planning/phases/171-accepted-baseline-finding-qualification/171-QUALIFICATION-PROBE.json
  - .planning/phases/171-accepted-baseline-finding-qualification/171-QUALIFICATION.json
  - .planning/phases/171-accepted-baseline-finding-qualification/171-RESEARCH.md
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
  - scripts/maintainer/repo_hygiene_check.sh
  - test/integration/phase15_par_authorization_e2e_test.exs
  - test/integration/phase37_protocol_strictness_e2e_test.exs
  - test/lockspire/protocol/pushed_authorization_request_test.exs
  - test/lockspire/qualification_ledger_contract_test.exs
  - test/lockspire/web/authorize_controller_test.exs
  - test/lockspire/web/discovery_controller_test.exs
  - test/support/config_case.ex
  - test/support/test_account_resolver.ex
  - test/test_helper.exs
covered_digest: "v3:sha256:73450df2c041e335bba6f597c42620a84d84001ba5951c15210fe27a24e17c72"
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 9/10
  gaps_closed:
    - "Six unreferenced Phase 172–174 TBD plan/progress placeholders are replaced with explicit unplanned states and prerequisites."
    - "The broad automatic profile overlap/interruption claim is narrowed to the recorded sequential operator procedure; the old claim remains dated and explicitly UNVERIFIED."
  gaps_remaining: []
  regressions: []
---

# Phase 171: Accepted Baseline & Finding Qualification Verification Report

**Phase Goal:** Maintainers can identify an accepted implementation base and a finite set of current, supported cases whose expected outcomes and owners are settled before dependent planning.
**Verified:** 2026-10-24T22:10:04Z
**Status:** passed
**Re-verification:** Yes — after Plan 04 gap closure

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|---|---|---|
| 1 | The accepted implementation base is backed by reviewed delivery reconciliation and the original exact-main authority receipt. | ✓ VERIFIED | `171-DELIVERY.md` records PR #138 and custody dispositions. The unchanged 1,933-byte receipt SHA-256 is `be2cdf5fe60df6788d304e451d736b4ac7746a111c9ff71b422ef27b5b777e39`, identifying accepted base `fe38beee987b135e87c99e7aa7f2488b4c8613e8`, with its original local/canonical CI/Release no-publish evidence and warning dispositions. The authority was not rerun. |
| 2 | Selected external profiles have exact immutable inputs and their unavailable prerequisite boundary is visible. | ✓ VERIFIED | Both ledger observations bind source/provider, suite, archive/helper/image and plan identities. Required Python 3.13.15/pip 26.2.1 and locked closure were unavailable. Both wrappers are `NOT LAUNCHED`, with `started=false`, `interrupted=false`, null exit/classification and no receipt. No profile result is presented as protocol acceptance. |
| 3 | The finite ledger attributes twelve current cases with conditions, expected/observed outcomes, support/normative sources, repro identities and owners. | ✓ VERIFIED | The ledger retains ordered A171-001…006 and P171-001…006, ten existing source-host proofs and two controlled observations, with distinct conditions and ownership. Current input manifest has 33 resolving entries and digest `c20ab6075973d27eb0e15d9de70910fd25ddde8bf2e5864d653cd1fab3e73c93`. |
| 4 | The two actual counterexamples qualify downstream corrections without being described as product passes or fixes. | ✓ VERIFIED | Bound probe records show 2 tests, 2 named normative assertion failures, 0 skipped, exit 2, with positive controls passing. A171-003 observed HTTP 302 with OAuth error parameters where OIDC Core 3.1.2.6 requires HTTP 400 without them. P171-005 observed rejection before consent despite valid pushed `openid email`; its expected interpretation is attributed to RFC 9126 §4 → RFC 9101 §§5, 6.3, 10.7. No product fix or probe rerun is claimed. |
| 5 | All six AUTHR/PARB requirements have evidence-backed dispositions, and dependent scope reflects only the two reproduced corrections. | ✓ VERIFIED | The current matrix has six dispositions for the twelve cases. Phases 172 and 173 name only A171-003 and P171-005 respectively; the remaining ten proofs are reused, and Phase 174 retains packaged-proof, security and delivery obligations. |
| 6 | The frozen matrix is finite, ordered, identity-bound and protected against drift. | ✓ VERIFIED | JSON is `frozen`, retains the 12 ordered case IDs, six requirement dispositions, frozen timestamp and qualification SHA. Its 33-entry ordered manifest digest matches the value above. The fresh focused ledger contract validates the frozen references and negative fixtures: 22 tests, 0 failures. |
| 7 | Selected-case/security/API/support choices and mandatory repro evidence do not silently pass unresolved. | ✓ VERIFIED | Both selected correction cases have source-bound controls and observations; optional external profiles remain supplemental and unavailable. Current roadmap makes downstream prerequisites explicit. Delegated maintainer decisions are dated in DECISIONS, DELIVERY and VALIDATION; A-EDGE-BASE-01/A-EDGE-FIND-02 and descriptor-less prohibitions remain flagged-unverified, not claimed as human approval or wired enforcement. |
| 8 | Owner/provenance, ordering and malformed-ledger contracts distinguish equal outcomes and reject incomplete or empty inventories without an explicit replan. | ✓ VERIFIED | `test/lockspire/qualification_ledger_contract_test.exs` has negative fixtures for identity, ownership, source/reference, malformed, empty/single inventory, ordering and freeze cases. Fresh focused run: 22 tests, 0 failures. |
| 9 | Optional profile retries follow the explicit sequential operator procedure for shared resources; unlaunched attempts do not claim overlap, interruption or cleanup outcomes. | ✓ VERIFIED | Current Plan 02 truth is procedure-scoped. Both attempts record zero launches and no execution/cleanup event. The contract rejects `interrupted=true` in a draft unlaunched profile independently of manifest drift. The former broader automatic guarantee remains quoted with date and marked UNVERIFIED; this report does not claim it. |
| 10 | The handoff identifies the accepted base, preserved ownership, current branch and explicit next actions before dependent planning. | ✓ VERIFIED | `171-DELIVERY.md` separates accepted main from the feature branch, preserves unknown worktrees/history, and records the original receipt and optional retry owner/actions. Roadmap phases 172–174 now state `0 — Not planned` with precise prerequisites; no dependent plan exists. |

**Score:** 10/10 truths verified (0 behavior-unverified).

### Deferred Items

None. The two qualified protocol corrections remain assigned to Phases 172/173 and are part of this phase's handoff, not Phase 171 gaps.

### Required Artifacts

| Artifact | Expected | Status | Details |
|---|---|---|---|
| `171-DELIVERY.md` | Reviewed reconciliation, accepted-base handoff and preserved ownership | ✓ VERIFIED | Substantive custody record, PR #138 delivery and current next actions. |
| `171-MAIN-ACCEPTANCE.json` | Original exact-main receipt | ✓ VERIFIED | Original bytes/hash and accepted SHA match the ledger. |
| `171-QUALIFICATION.json` | Finite ledger, profile observations, frozen matrix and manifest | ✓ VERIFIED | 12 cases, 6 dispositions, 33 manifest inputs; contract passes. |
| `171-QUALIFICATION-PROBE.json` and dated archive | Allowlisted source-bound expectations, observations and named outcomes | ✓ VERIFIED | Current and archived observation identities preserved; outcome inspected, not repeated. |
| `171-qualification_probe_test.exs` | Controlled A171-003/P171-005 HTTP qualification | ✓ VERIFIED | Two named HTTP cases and successful positive controls are bound to source/probe hashes. |
| `test/lockspire/qualification_ledger_contract_test.exs` | Ledger and frozen-matrix consistency contract | ✓ VERIFIED | Fresh run: 22 tests, 0 failures; interrupted-unlaunched negative regression included. |
| `171-QUALIFICATION-DECISIONS.md`, `171-RESEARCH.md`, `171-VALIDATION.md` | Attributed interpretation, preserved uncertainty and current verification record | ✓ VERIFIED | Dated selections preserve original questions, unavailable history and external boundaries. |
| `171-SECURITY.md`, `171-REVIEW.md`, `171-REVIEW-DISPOSITION.md` | Threat closure and clean review evidence | ✓ VERIFIED | Security reports 15/15 threats closed; current review is clean with 0 findings, and prior five warnings have fixed dispositions. |

All plan-declared artifacts passed the GSD CLI checks: Plan 01 4/4, Plan 02 2/2, Plan 03 6/6, Plan 04 6/6. No UI or dynamic data-rendering artifact is in scope; Level 4 UI data-flow tracing is not applicable.

### Key Link Verification

| From | To | Via | Status | Details |
|---|---|---|---|---|
| `171-DELIVERY.md` | `scripts/maintainer/repo_hygiene_check.sh` | Reviewed reconciliation precedes acceptance | ✓ WIRED | Plan 01 CLI link resolves; original receipt names the accepted SHA. |
| `171-QUALIFICATION.json` | `test/integration/phase37_protocol_strictness_e2e_test.exs` | A171-001 proof owner | ✓ WIRED | Named source-host assertion and source SHA recorded. |
| `171-QUALIFICATION.json` | `scripts/conformance/oidf-suite-lock.json` | Immutable suite identity | ✓ WIRED | Exact lock and plan inputs recorded. |
| `171-QUALIFICATION.json` | `test/integration/phase15_par_authorization_e2e_test.exs` | PAR proof owner | ✓ WIRED | Named existing PAR evidence recorded. |
| `171-QUALIFICATION.json` | `171-qualification_probe_test.exs` | A171-003/P171-005 observations | ✓ WIRED | Named assertions and bounded outcomes resolve. |
| `171-QUALIFICATION.json` | `.planning/REQUIREMENTS.md` | Case-backed requirements | ✓ WIRED | All six AUTHR/PARB IDs appear in dispositions. |
| `171-QUALIFICATION.json` | `.planning/ROADMAP.md` | Frozen downstream scope | ✓ WIRED | CLI link verifies current case-backed amendments and prerequisites. |
| `171-QUALIFICATION.json` | `171-02-PLAN.md` | Consumed current profile-claim authority | ✓ WIRED | Exact hash is included in the manifest. |
| `171-VALIDATION.md` | `171-04-PLAN.md` | Wave 4 task records | ✓ WIRED | Current execution records resolve to the gap-closure plan. |
| `171-QUALIFICATION.json` | `.planning/ROADMAP.md` | Phase 172–174 plan gates | ✓ WIRED | CLI verifies the reviewed downstream contract selector. |

Plan-declared key links: 10/10 verified by the CLI (2 + 2 + 3 + 3).

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|---|---|---|---|---|
| Frozen case ledger | Case observations and matrix rows | Source-bound existing tests and the two controlled HTTP observations | Yes; manifest and contract bind the input identities and assertions | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|---|---|---|---|
| Frozen ledger and negative fixtures | `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 LOCKSPIRE_TEST_DB_NAME=lockspire_171_main_20261024b mix test test/lockspire/qualification_ledger_contract_test.exs` | 22 tests, 0 failures, 8.4s | ✓ PASS |
| Current roadmap statuses and prerequisites | Read Phase 172–174 roadmap sections | All three explicitly `0 — Not planned` and gated; no plan placeholders remain | ✓ PASS |

### Probe Execution

| Probe | Command | Result | Status |
|---|---|---|---|
| `171-qualification_probe_test.exs` | No rerun; inspected `171-QUALIFICATION-PROBE.json` and dated archive | Original source-bound observation: exit 2, 2 named normative failures, 0 skipped, controls passed; source SHA `30e385a33bb2a7f67d94c558dedf7691ecde5863`, probe SHA `0f32ab008fe4ebffc17d471ffd0959fe55861d418ce62fe8f636330f6f9972f5` | EVIDENCE INSPECTED, NOT RERUN |
| `phase37` and `fapi2` wrappers | No rerun | Both recorded `NOT LAUNCHED`; null exits/classifications and no receipts | UNAVAILABLE, NOT A PROTOCOL RESULT |
| Exact-main acceptance authority | No rerun | Original receipt hash and base identity inspected | EVIDENCE INSPECTED, NOT RERUN |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|---|---|---|---|---|
| BASE-01 | 171-01 | Reviewed delivery reconciliation and accepted main | ✓ SATISFIED | DELIVERY plus original receipt and exact-base identity. |
| BASE-02 | 171-02, 171-04 | Immutable profile identities and honest unavailable boundary | ✓ SATISFIED | Exact identities, explicit zero-launch outcomes, concrete owner/actions and contract. |
| FIND-01 | 171-01, 171-02 | Finite attributable ledger with current proof and honest cause | ✓ SATISFIED | Twelve cases with distinct conditions, sources, observations and owners. |
| FIND-02 | 171-03, 171-04 | Frozen matrix and qualification-driven downstream scope | ✓ SATISFIED | Frozen 12-row matrix, six dispositions, current prerequisites and scoped procedure. |

No orphaned Phase 171 requirement IDs were found. REQUIREMENTS.md still contains its prior “Gaps Found” phase-status labels pending workflow projection; the per-requirement evidence above is this independent current assessment.

### Test Quality Audit

| Test File | Linked Requirement | Active | Skipped | Circular | Assertion Level | Verdict |
|---|---|---:|---:|---:|---|---|
| `test/lockspire/qualification_ledger_contract_test.exs` | BASE-01, BASE-02, FIND-01, FIND-02 | 22 | 0 | 0 | Value and behavioral contract assertions over synthetic malformed inputs and actual frozen references | PASS |
| `171-qualification_probe_test.exs` | FIND-01, FIND-02 | 2 | 0 | 0 | Named HTTP behavior, independent normative expectation and valid controls | Evidence inspected; intentionally not rerun |

The active contract has no disabled-test markers. The phase probe stores redacted observations rather than generating expected outcomes from the system under test.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|---|---:|---|---|---|
| `171-04-PLAN.md` | 115 | Literal `TBD` string inside the automated check that rejects roadmap placeholders | ℹ️ Info | Verification-code pattern only; the current roadmap contains no remaining Phase 172–174 plan/progress placeholders. |
| `171-04-SUMMARY.md` | — | Reports an earlier 33-entry manifest digest `dc60a6b7…` | ℹ️ Info | The current canonical JSON digest is `c20ab607…`; the final VALIDATION identity refresh occurred after the summary's recorded digest. Current JSON plus the passing contract, not the older narrative, is authoritative. |

No unreferenced debt marker or implementation stub was found in the modified implementation/evidence files. The fresh review is clean; the five earlier review warnings have recorded fixed dispositions.

### Unverified Boundaries

Both optional profile wrappers remain unlaunched, so external profile behavior and automatic overlap/interruption/cleanup behavior remain unverified. The broader automatic guarantee is retained as dated history with an owner and a future evidence action; it is not part of the narrowed current truth or a Phase 171 requirement. A-EDGE-BASE-01, A-EDGE-FIND-02 and all three descriptor-less prohibitions remain flagged-unverified. Their current scope dispositions do not claim wired enforcement or human-person approval; no new mandatory policy choice was identified.

### Human Verification Required

N/A — this planning/evidence foundation phase has no user-facing behavior to test. The previously deferred normative, support and retry judgments now have dated delegated maintainer dispositions under the user's autonomous-unblock instruction. External behavior stays explicitly unavailable and is not represented as verified.

### Gaps Summary

Both carried-forward gaps are closed. Roadmap entries for Phases 172–174 now state that they are unplanned and identify their actual gates. The current Plan 02 claim now matches the observed sequential procedure and zero-launch profile records; the broader automatic concurrency/interruption/cleanup behavior remains explicitly unverified, with a future owner/action. The selected cases, accepted receipt, profile identities, source observations and frozen selection remain unchanged. No implementation correction, external profile result, publication or additional human approval is claimed.

---

_Verified: 2026-10-24T22:10:04Z_
_Verifier: the agent (gsd-verifier)_
