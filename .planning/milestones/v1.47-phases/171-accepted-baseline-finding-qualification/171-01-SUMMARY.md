---
phase: 171-accepted-baseline-finding-qualification
plan: "01"
subsystem: evidence
tags: [oauth, oidc, redirect-uri, acceptance, exunit]
requires: []
provides:
  - One source-host redirect mismatch qualification tied to accepted main and a named HTTP test
  - A draft evidence ledger and fail-closed contract for baseline and case references
affects: [171-02, 171-03]
actuals:
  tokens: 5259
  tasks: 2
  commits: 2
plan_head_before: 5cefc4ea31c812ac19f513fb3ee0c5dcc275cf83
plan_head_after: 0750100a5028482c68ea1acf5727c8c4a172a99b
tech-stack:
  added: []
  patterns:
    - Bind each finding to its source revision, observed result, expected safety, and owner
key-files:
  created:
    - .planning/phases/171-accepted-baseline-finding-qualification/171-QUALIFICATION.json
    - test/lockspire/qualification_ledger_contract_test.exs
  modified:
    - .planning/phases/171-accepted-baseline-finding-qualification/171-DELIVERY.md
key-decisions:
  - Preserve the original exact-main receipt unchanged; do not rerun the authority after ledger edits.
  - Keep source-host, package, and external-suite evidence distinct; package and suite receipts are explicitly not applicable to this case.
  - Allow observed and expected outcomes to be equal when the evidence attributes each separately.
requirements-completed: [BASE-01, FIND-01]
coverage:
  - id: D1
    description: "A171-001 records the actual redirect_uri mismatch HTTP result against the accepted implementation base."
    requirement: FIND-01
    verification:
      - kind: integration
        ref: "test/integration/phase37_protocol_strictness_e2e_test.exs#exact redirect_uri mismatches stay on the browser-safe surface"
        status: pass
    human_judgment: false
  - id: D2
    description: "The ledger contract validates the retained acceptance receipt, source identity, and evidence references, and rejects malformed evidence fixtures."
    requirement: BASE-01
    verification:
      - kind: unit
        ref: "test/lockspire/qualification_ledger_contract_test.exs#the phase qualification ledger exists and its evidence references resolve"
        status: pass
      - kind: unit
        ref: "test/lockspire/qualification_ledger_contract_test.exs#the contract rejects missing, empty, or nonpassing required gate evidence"
        status: pass
    human_judgment: false
duration: 17min
completed: 2026-10-24
status: complete
commits: 2
---

# Phase 171 Plan 01: Accepted Baseline and Finding Qualification Summary

**One redirect-safety case is traced from the reviewed accepted-main receipt to a passing source-host HTTP test and a draft, validated evidence ledger.**

## Performance

- **Duration:** 17 min
- **Started:** 2026-10-24T19:50:10Z
- **Completed:** 2026-10-24T20:07:44Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments

- Verified the unchanged accepted-main receipt for `fe38beee987b135e87c99e7aa7f2488b4c8613e8`; its 1,933 bytes still hash to `be2cdf5fe60df6788d304e451d736b4ac7746a111c9ff71b422ef27b5b777e39`. The original authority reports 22 PASS, 2 WARN, 0 BLOCK, positive local ExUnit count, required same-SHA CI pass, Release no-publish pass, and one disposition per warning. The authority was not rerun.
- Ran the named source-host integration case at source SHA `5cefc4ea31c812ac19f513fb3ee0c5dcc275cf83`: `mix test --include integration test/integration/phase37_protocol_strictness_e2e_test.exs:106` — 1 test, 0 failures, 4 excluded. It returned HTTP 400 with the browser-safe rejection body and no `Location` header for a trailing-slash redirect mismatch.
- Added draft case A171-001, tied to OIDC Core 3.1.2.6 and the repository support contract. Package and external conformance evidence are explicitly not applicable.
- Added the ledger contract and in-memory negative fixtures for baseline identity, acceptance gates, test count, warning dispositions, duplicate IDs, ownership, observed/expected evidence, and external-suite substitution. Equal observed and expected outcomes remain valid.
- Recorded current delegated custody and the preserved-path distinctions in the delivery handoff. Historical worktree owners remain unknown; their branches and worktrees remain preserved.

## Task Commits

1. **Task 1: Qualify one redirect-safety case through the real delivery gate** — `a0acb349` (`feat`)
2. **Task 2: Make evidence ambiguity and ownership gaps visibly rejectable** — `0750100a` (`test`)

Plan metadata is recorded by the final GSD closeout commit.

## Files Created/Modified

- `.planning/phases/171-accepted-baseline-finding-qualification/171-QUALIFICATION.json` — draft canonical evidence ledger with A171-001.
- `test/lockspire/qualification_ledger_contract_test.exs` — receipt, identity, reference, and negative-fixture contract.
- `.planning/phases/171-accepted-baseline-finding-qualification/171-DELIVERY.md` — tracer result and custody/path handoff.

## Decisions Made

- Keep the accepted-main receipt byte-for-byte intact and reuse its recorded results rather than repeating the long exact-main gate after ledger changes.
- Treat the local generated-host test as repository-source proof only; it is not a package test or OIDF/FAPI result.
- Keep the ledger and matrix in draft; the remaining finite FIND-01 inventory belongs to the dependent plan.
- Treat different retained paths and unknown historical operator identities explicitly; delegated custody authorizes preservation without attributing prior work.

## Deviations from Plan

None — plan executed as written. No product, acceptance machinery, dependencies, remote refs, or publication state changed.

## Issues Encountered

- Default workspace permissions denied Git metadata writes. The requested task commits were created after a scoped elevated Git operation; no hook bypass was used.
- During iteration, a malformed test fixture and a Credo complexity finding were corrected before the final passing run.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

Plan 171-01 is complete. BASE-01 is ready to mark complete. FIND-01 remains shared with later phase work, so the SDK correctly keeps it open until the remaining finite inventory is produced. Proceed to plan 171-02 only after this summary and state closeout are committed. No product implementation occurred.

## Self-Check: PASSED

- The qualification ledger, contract test, delivery handoff, and this summary exist.
- Task commits `a0acb349` and `0750100a` are ancestors of HEAD; two plan task commits were measured from the persisted plan base.
- The original acceptance receipt still has SHA-256 `be2cdf5fe60df6788d304e451d736b4ac7746a111c9ff71b422ef27b5b777e39` and required acceptance fields pass the final identity check.
- `gsd-tools check evaluation-scope --plan 171-01 --commits-only` resolved both task commits on this branch.

---
*Phase: 171-accepted-baseline-finding-qualification*
*Completed: 2026-10-24*
