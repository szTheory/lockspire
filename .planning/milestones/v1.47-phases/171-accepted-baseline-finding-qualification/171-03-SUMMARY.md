---
phase: 171-accepted-baseline-finding-qualification
plan: "03"
subsystem: testing
tags: [qualification, oauth, oidc, par, evidence]
requires:
  - phase: 171-accepted-baseline-finding-qualification
    provides: Accepted main receipt, exact source-host proofs, settled expectations and twelve-case ledger
provides:
  - Frozen twelve-case qualification matrix with six downstream requirement dispositions and ordered source/input manifest
  - Controlled normative counterexamples and qualification-driven Phase 172/173 scope
affects: [phase-172-authorization-responses, phase-173-conditional-par-profile-boundaries, phase-174-packaged-proof-delivery-handoff]
actuals:
  tokens: 44623
  tasks: 3
  commits: 3
plan_head_before: 3561a51d032e86dc10607b37f78c14313dcb1872
plan_head_after: 1374f76d6893de67a39882335c8ec25cf76e612c
commits: 3
tech-stack:
  added: []
  patterns: [Explicitly invoked phase-local HTTP qualification probe, source-bound ordered freeze manifest, matrix contract fixtures]
key-files:
  created:
    - .planning/phases/171-accepted-baseline-finding-qualification/171-qualification_probe_test.exs
    - .planning/phases/171-accepted-baseline-finding-qualification/171-QUALIFICATION-PROBE.json
  modified:
    - .planning/phases/171-accepted-baseline-finding-qualification/171-QUALIFICATION.json
    - test/lockspire/qualification_ledger_contract_test.exs
    - .planning/REQUIREMENTS.md
    - .planning/ROADMAP.md
    - .planning/phases/171-accepted-baseline-finding-qualification/171-DELIVERY.md
key-decisions:
  - "A171-003's controlled unsupported response_mode request requires HTTP 400 with no OAuth Error Response parameters."
  - "For P171-005, the valid pushed scope is authoritative over the conflicting outer scope under the attributed RFC 9126 to RFC 9101 clause chain; plain form PAR remains supported."
  - "Retain only the two reproduced correction scopes; reuse existing proof for the other ten cases and keep optional external profile unavailability supplemental."
patterns-established:
  - "Qualification counterexamples remain visible as protocol failures and do not pass a green-tracer gate."
  - "Freeze selected evidence through an ordered path/selector/hash manifest and reject drift in the executable ledger contract."
requirements-completed: [FIND-02]
coverage:
  - id: D1
    description: "Freeze the twelve-case AUTHR/PARB matrix, explicit requirement dispositions and qualification-driven roadmap scope."
    requirement: FIND-02
    verification:
      - kind: unit
        ref: "mix test test/lockspire/qualification_ledger_contract_test.exs (19 tests, 0 failures)"
        status: pass
    human_judgment: false
  - id: D2
    description: "Record two controlled source-host normative counterexamples with passing positive controls and bounded actual outcomes."
    requirement: FIND-02
    verification:
      - kind: integration
        ref: "mix test --include integration .planning/phases/171-accepted-baseline-finding-qualification/171-qualification_probe_test.exs --seed 0 (2 tests, 2 expected normative assertion failures)"
        status: fail
    human_judgment: true
    rationale: "The normative expectations and linked-clause interpretation require maintainer judgment; the qualified REDs are preserved as correction inputs, not product acceptance."
duration: 31min
completed: 2026-10-24
status: complete
---

# Phase 171 Plan 03: Accepted Baseline Finding Qualification Summary

**Two controlled HTTP counterexamples now drive an immutable twelve-case matrix and narrowly revised authorization/PAR correction scopes.**

## Performance

- **Duration:** 31 min (started 2026-10-24T20:23:58Z)
- **Completed:** 2026-10-24
- **Tasks:** 3
- **Files modified:** 7

## Accomplishments

- Ran the explicitly invoked two-case probe against the accepted-main implementation using Elixir 1.19.5 / OTP 28.5 and the owned disposable database `lockspire_171_main_20261024b`. Both valid-path controls passed; the two settled normative assertions failed at their final assertions and were recorded as source-bound counterexamples.
- Frozen the twelve existing case IDs, seven-category coverage and all six AUTHR/PARB requirement dispositions. The 29-entry ordered input manifest records digest `cf44b71ae6aeaa52338f20d6cd307518d569ed6be078a7c665f91cc699b62e5b`; the contract rejects input drift, unresolved blockers, omitted requirements and invalid empty-scope freezes.
- Revised Phase 172 to correct only A171-003 while carrying forward existing authorization evidence. Revised Phase 173 to correct only P171-005 while carrying forward existing PAR and source-host metadata evidence. Phase 174 CPROOF/DELIV obligations remain unchanged.
- Preserved the original accepted receipt byte-for-byte: 1,933 bytes, SHA-256 `be2cdf5fe60df6788d304e451d736b4ac7746a111c9ff71b422ef27b5b777e39`. The two optional Python profile wrappers remained unlaunched with null exits/classifications and no receipts; their original owners/actions remain supplemental and nonblocking.
- Made no product runtime, dependency, migration, public API, conformance-runner or default test-discovery changes. Historical worktrees and shared resources remain retained; release auto-merge remains paused; no remote refs, merge or publication changed.

## Probe Results

The command exited **2** with **2 tests, 2 failures and 0 skipped**. The controls passed before each final assertion, so these are actual qualification results rather than setup or control failures.

| Case | Required projection | Observed projection | Result |
| --- | --- | --- | --- |
| A171-003 | HTTP 400, no Location, no OAuth Error Response parameters | HTTP 302 to registered callback with parameter names `error`, `error_description`, `iss`, `state` | Protocol counterexample; assertion `A171-003:http-error-disposition` |
| P171-005 | Consent redirect with pushed `openid email`, matching state/nonce/client and no `profile` | HTTP 400 before consent; effective scopes/state/nonce/client unavailable | Protocol counterexample; assertion `P171-005:pushed-scope-authority` |

The P171-005 expectation follows the recorded linked-clause interpretation: RFC 9126 §4 incorporates RFC 9101 request semantics, with RFC 9101 §§5 and 6.3 for duplicate/authoritative handling and §10.7 for its integrity rationale. This is not represented as a direct RFC 9126 quotation; plain form-encoded PAR remains valid and no JWT/JAR requirement is added. A171-003 uses OIDC Core §3.1.2.6. Product corrections belong to Phases 172 and 173.

## Task Commits

1. **Task 1: Qualify authorization and PAR counterexamples** — `4a302bda` (`test`)
2. **Task 2: Review qualification matrix dispositions** — `6d9a5db6` (`docs`)
3. **Task 3: Reconcile and freeze qualified scope** — `1374f76d` (`docs`)

## Files Created/Modified

- `171-qualification_probe_test.exs` — Explicitly invoked two-case HTTP observation outside default test discovery.
- `171-QUALIFICATION-PROBE.json` — Allowlisted actual controls, projections, named assertions, counts and runtime identity.
- `171-QUALIFICATION.json` — Frozen cases/dispositions, qualification identity and 29 ordered input hashes.
- `qualification_ledger_contract_test.exs` — Draft/frozen consistency, counterexample, input-drift, blocker, empty-scope and amendment fixtures.
- `.planning/REQUIREMENTS.md` and `.planning/ROADMAP.md` — Explicit six-ID mapping and narrowly revised Phase 172/173 contracts; Phase 174 is preserved.
- `171-DELIVERY.md` — Qualification outcomes, source/branch distinction, retained-resource disposition and next-owner handoff.

## Decisions Made

- Treat the two completed normative REDs as qualified defects owned by downstream correction plans, not as passes or open qualification-evidence blockers.
- Preserve the linked RFC interpretation with provenance, without turning the settled behavior into an unsupported discretionary-policy claim or adding signed PAR.
- Keep A-EDGE-FIND-02 unclassified and descriptorless prohibitions `flagged-unverified`; they are not fabricated passes or matrix blockers for this freeze.
- Keep unavailable OIDF/FAPI wrappers supplemental, preserving their prerequisite, owner and next action without a retry or installation.

## Deviations from Plan

None. Contract hardening and its malformed/frozen fixtures are part of the specified matrix verification. No product correction was made in this qualification plan.

## Issues Encountered

The first frozen-contract run surfaced stale manifest hashes and malformed-input fixture crashes after the contract was extended. The contract was tightened to reject malformed frozen inputs safely; the ordered manifest was refreshed from the final source bytes, and the prescribed contract suite passed 19 tests with 0 failures.

## User Setup Required

None. The optional Python profile wrappers remain unavailable because the exact CPython 3.13.15 / pip 26.2.1 environment was absent; they were not launched, and the recorded supplemental owner/action is preserved.

## Next Phase Readiness

Phase 172 may be planned against the frozen scope for A171-003's HTTP 400/no-error-parameters correction with RED at the qualified source and GREEN after correction. Phase 173 may proceed after Phase 172 for P171-005's pushed-scope authority correction. Reuse the other ten cases' existing proof. Keep Phase 174's packaged proof and delivery gates. The accepted main receipt is distinct from this milestone implementation branch; this plan claims no milestone integration or publication.

Two durable lessons: follow normative reference chains before calling behavior discretionary policy; use an observation task, not a green-tracer gate, when a deliberate normative RED is required. Preserve expected failures visibly for their correction owners.

## Self-Check: PASSED

The frozen matrix, probe evidence and SUMMARY exist. Task commits `4a302bda`,
`6d9a5db6` and `1374f76d` are ancestors of the measured plan head; the plan
ledger measures three commits from `3561a51d032e86dc10607b37f78c14313dcb1872`
through `1374f76d6893de67a39882335c8ec25cf76e612c`. Frozen identity, manifest
digest and original receipt bytes match the recorded values.

---
*Phase: 171-accepted-baseline-finding-qualification*
*Completed: 2026-10-24*
