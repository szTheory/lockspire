---
phase: 171-accepted-baseline-finding-qualification
plan: "02"
subsystem: testing
tags: [oidc, par, conformance, qualification-ledger]
requires:
  - phase: 171-01
    provides: Reviewed accepted-base entry gate and preserved original acceptance receipt
provides:
  - Exact-input observations for both existing supplemental OIDF profiles, including honest unavailable boundaries
  - Finite redacted AUTHR/PARB case inventory with source proof, unresolved proof/policy gaps, and owners
affects: [171-03, BASE-02, FIND-01, AUTHR, PARB]
actuals:
  tokens: 22344
  tasks: 2
  commits: 2
plan_head_before: d78f0fd944b8c8612261883e09cfb844a698bd92
plan_head_after: 5d73b211bf369476c3681186eaa5bb8ba6e4af70
tech-stack:
  added: []
  patterns:
    - Exact-input profile observations distinguish unlaunched wrappers from actual runner outcomes
    - Stable case IDs keep distinct supported conditions and dated observations attributable
key-files:
  created: []
  modified:
    - .planning/phases/171-accepted-baseline-finding-qualification/171-QUALIFICATION.json
    - test/lockspire/qualification_ledger_contract_test.exs
key-decisions:
  - "Keep both supplemental profiles unavailable because the locked Python environment is absent; record no wrapper exit, result classification, or receipt for attempts that did not start."
  - "Keep unsupported response_mode as a required proof gap and the pushed-versus-front-channel scope conflict unresolved for scoped replan."
  - "Treat external issuer/TLS/proxy/browser reachability as supplemental unavailable evidence, not as a product defect or selected mandatory case."
patterns-established:
  - "Case identity is stable across repeated observations of the same concrete condition; equal results do not merge distinct conditions."
  - "Runner-level status cannot satisfy deterministic source-host repro evidence."
requirements-completed: [BASE-02, FIND-01]
coverage:
  - id: D1
    description: Both existing OIDF profile attempts have exact source, suite, lock, plan, helper and image identities plus a truthful unavailable record.
    requirement: BASE-02
    verification:
      - kind: other
        ref: "python3 scripts/conformance/oidf_inputs.py --lock scripts/conformance/oidf-suite-lock.json --validate-only"
        status: pass
      - kind: unit
        ref: "test/lockspire/conformance_immutable_inputs_contract_test.exs; test/lockspire/conformance_profile_execution_test.exs; test/mix/tasks/lockspire/oidf_conformance_test.exs (17 tests)"
        status: pass
    human_judgment: true
    rationale: Both wrappers were not launched because CPython 3.13.15/pip 26.2.1 and the locked dependency closure were unavailable; no external profile result exists.
  - id: D2
    description: Twelve stable AUTHR/PARB cases distinguish ten passing source-host proofs from two explicit proof or policy gaps.
    requirement: FIND-01
    verification:
      - kind: unit
        ref: "test/lockspire/qualification_ledger_contract_test.exs (13 tests)"
        status: pass
      - kind: integration
        ref: "mix test --include integration test/integration/phase37_protocol_strictness_e2e_test.exs test/lockspire/web/authorize_controller_test.exs test/lockspire/protocol/pushed_authorization_request_test.exs test/integration/phase15_par_authorization_e2e_test.exs (44 tests)"
        status: pass
      - kind: unit
        ref: "test/lockspire/web/discovery_controller_test.exs (7 tests)"
        status: pass
    human_judgment: true
    rationale: A171-003 lacks a deterministic unsupported-response-mode proof and P171-005 requires a policy decision before its conflicting pushed/front-channel parameters can be qualified.
  - id: D3
    description: The case matrix and category coverage preserve the external TLS/proxy/browser boundary separately from source-host metadata proof.
    requirement: FIND-01
    verification:
      - kind: unit
        ref: "Qualification ledger validation in test/lockspire/qualification_ledger_contract_test.exs"
        status: pass
    human_judgment: true
    rationale: The external profile path was unavailable and remains supplemental; Plan 03 must review scope and readiness without treating unobserved reachability as a Lockspire defect.
duration: 14m
completed: 2026-10-24
status: complete
commits: 2
---

# Phase 171 Plan 02: Accepted Baseline Finding Qualification Summary

**Twelve attributable AUTHR/PARB cases reuse ten current source-host proofs, isolate two remaining proof or policy gaps, and record both supplemental profile runs as unlaunched due to missing locked Python prerequisites.**

## Performance

- **Duration:** 14 minutes
- **Started:** 2026-10-24T20:08:40Z (execution-state timestamp)
- **Completed:** 2026-10-24T20:22:18Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- Recorded both `phase37` and `fapi2` observations with separate source-host identity (`examples/adoption_demo`, source SHA `d78f0fd944b8c8612261883e09cfb844a698bd92`) and package identity (`not_applicable`). Captured lock/plan checksums, upstream suite commit and tag, archive/helper checksums, three image digests, selected Python/pip versions, and exact prerequisite failures. The immutable-input validator exited 0; `mix lockspire.oidf_conformance --check` also exited 0, but is not evidence of dependency readiness because the locked closure check found seven missing or mismatched distributions. The exact CPython 3.13.15 lookup exited 2 and the dependency check exited 1. Both wrappers were **NOT LAUNCHED**: their exits and classifications are null, no receipts or output directories were created, and cleanup is not applicable. Historical run `33139876101` remains summary-only `suite_failure`; no exact historical module assertion was available.
- Expanded the ledger to twelve stable IDs: A171-001 through A171-006 and P171-001 through P171-006. Ten reuse passing deterministic source-host assertions from the selected tests; matching observed and expected results are separately attributed and do not merge cases. Added seven category-coverage entries and aligned sorted matrix rows.
- Kept **A171-003** unresolved: an otherwise valid callback with unsupported `response_mode` needs a controller-level proof of HTTP 400 without OAuth response parameters (OIDC Core 3.1.2.6). The smallest repro owner is `Lockspire.Web.AuthorizeControllerTest`; Plan 03 owns the proof replan.
- Kept **P171-005** unresolved: push `scope=openid email`, then send the valid `request_uri` with conflicting front-channel `scope=profile`. RFC 9126 Section 4 establishes the pushed request reference but does not settle this implementation's reject-versus-ignore policy for this exact duplicate field. Plan 03 owns the policy decision and smallest end-to-end repro in `Lockspire.Integration.Phase15ParAuthorizationE2ETest`.
- Kept public provider-origin, TLS termination, proxy rewriting, and browser reachability as an explicit external-only unavailable category. The passing configured-issuer/discovery proof is source-host evidence and does not cover this external path. Its absence does not establish a product defect or select a mandatory case.
- Expanded ledger contract fixtures for duplicate/orphan and unsorted IDs, null collections, identity/owner omissions, empty inventory with explicit replan, valid single-case inventory, distinct equal-result conditions, repeated observations under one stable case ID, invalid/interrupted/external proof, and unlaunched-profile receipt integrity.

## Results

- python3 scripts/conformance/oidf_inputs.py --lock scripts/conformance/oidf-suite-lock.json --validate-only — exit 0.
- mix lockspire.oidf_conformance --check — exit 0; separately verified not to establish locked Python dependency readiness.
- mix test test/lockspire/conformance_immutable_inputs_contract_test.exs test/lockspire/conformance_profile_execution_test.exs test/mix/tasks/lockspire/oidf_conformance_test.exs — 17 tests, 0 failures.
- mix test --include integration test/integration/phase37_protocol_strictness_e2e_test.exs test/lockspire/web/authorize_controller_test.exs test/lockspire/protocol/pushed_authorization_request_test.exs test/integration/phase15_par_authorization_e2e_test.exs — 44 tests, 0 failures; integration tag explicitly included.
- mix test test/lockspire/web/discovery_controller_test.exs — 7 tests, 0 failures.
- mix test test/lockspire/qualification_ledger_contract_test.exs — 13 tests, 0 failures.
- python3 -m json.tool .planning/phases/171-accepted-baseline-finding-qualification/171-QUALIFICATION.json and git diff --check — passed.

All Mix commands used Elixir 1.19.5/OTP 28 and the owned disposable test database `lockspire_171_main_20261024b`. No package installation, product-code change, wrapper invocation, or original acceptance authority rerun occurred. The original BASE-01 receipt bytes and SHA-256 `be2cdf5fe60df6788d304e451d736b4ac7746a111c9ff71b422ef27b5b777e39` remain unchanged.

## Task Commits

1. **Task 1: Observe the two existing immutable profiles without changing the experiment** — `9454d6ce` (`docs`).
2. **Task 2: Attribute the bounded authorization and PAR case inventory** — `5d73b211` (`test`).

The plan's measured task commit count is 2, from `d78f0fd944b8c8612261883e09cfb844a698bd92` through `5d73b211bf369476c3681186eaa5bb8ba6e4af70`.

## Files Modified

- `.planning/phases/171-accepted-baseline-finding-qualification/171-QUALIFICATION.json` — exact-input profile observations, finite case evidence, category coverage, and sorted matrix rows.
- `test/lockspire/qualification_ledger_contract_test.exs` — identity, profile, stable-ID, ordering, empty/single inventory, outcome and proof-boundary contracts.

## Decisions Made

- Unavailable wrappers remain without an exit code, runner classification, or receipt because neither process started.
- A171-003 and P171-005 stay required, unresolved cases with named owners; they are not silently excluded or treated as defects.
- External issuer/TLS/proxy/browser reachability remains supplemental and explicitly unobserved.

## Deviations from Plan

None — the plan's unavailable-profile path was used as specified; no input refresh, package install, product correction, or duplicate behavior test was introduced.

## Issues Encountered

- The Mix profile `--check` command returned exit 0 despite a missing/mismatched locked Python closure. The ledger records that output without promoting it to runtime readiness; the prerequisite check independently recorded the exact missing distributions. Runner changes are outside this plan.
- Historical suite artifacts were referenced only through their retained summary; no exact historical assertion or receipt bytes were available to attribute.

## User Setup Required

None for the repository artifacts. Re-running the supplemental profile observations requires the existing workflow-compatible Elixir 1.19.5/OTP 28 and CPython 3.13.15/pip 26.2.1 environment with the complete locked dependency closure, followed by the exact recorded wrapper retries in newly owned artifact directories.

## Next Phase Readiness

Plan 03 has a finite, source-attributed ledger to review. It must replan the unsupported response-mode proof and resolve the pushed/front-channel conflict policy before treating those mandatory cases as qualified. Supplemental external-origin/TLS/proxy/browser observations remain unavailable and separate. Do not infer a protocol defect from either wrapper unavailability or the historical suite-level labels.

## Self-Check: PASSED

- Ledger and test files exist and parse; the updated ledger contract and source proofs pass.
- Task commits `9454d6ce` and `5d73b211` are ancestors of HEAD.
- The measured task commit count is 2; `.git/gsd-plan-head-before-171-02` records the expected base SHA.

---
*Phase: 171-accepted-baseline-finding-qualification*
*Completed: 2026-10-24*
