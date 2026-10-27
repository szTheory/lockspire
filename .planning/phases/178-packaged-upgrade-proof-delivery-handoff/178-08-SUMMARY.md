---
phase: 178-packaged-upgrade-proof-delivery-handoff
plan: "08"
subsystem: testing
tags: [python, github-actions, verifier-matrix, receipts, postgres, ci]
requires:
  - phase: 178-03
    provides: rollout and legacy-control receipt owners
  - phase: 178-04
    provides: endpoint and release-RPC receipt owners
  - phase: 178-05
    provides: contention and atomicity receipt owners
  - phase: 178-06
    provides: issuance and recovery receipt owners
  - phase: 178-07
    provides: disclosure success/failure receipt owners
provides:
  - Strict complete and pair-scoped verifier receipt validation with explicit runner and candidate-source pins
  - Bounded locked/floor wrapper and existing-workflow integration
  - Retained full and pair receipt validation evidence with separate runner and validator identities
affects: [178-09, 178-10, verifier-delivery]
actuals:
  tokens: 48127
  tasks: 2
  commits: 19
plan_head_before: d77a44b893facf3df5e647a6ebc1a20608fa0930
plan_head_after: 3d8f99cc8cca9df15d4e0338b660391cea49f30d
tech-stack:
  added: []
  patterns: [closed-receipt-matrix, explicit-runner-and-candidate-pins, fail-closed-process-group-ownership]
key-files:
  created:
    - scripts/acceptance/clean_room/verifier_receipts.py
    - scripts/ci/run_verifier_upgrade_proof.sh
    - test/acceptance/client_verifier_receipts_test.py
    - test/acceptance/client_verifier_ci_test.py
    - test/fixtures/verifier-matrix-26
  modified:
    - scripts/acceptance/clean_room_verifier_upgrade.py
    - scripts/acceptance/clean_room/verifier_core.py
    - .github/workflows/ci.yml
    - .planning/phases/178-packaged-upgrade-proof-delivery-handoff/178-08-PLAN.md
    - .planning/phases/178-packaged-upgrade-proof-delivery-handoff/178-09-PLAN.md
    - .planning/phases/178-packaged-upgrade-proof-delivery-handoff/178-10-PLAN.md
key-decisions:
  - "Retained proof validation pins runner revision and candidate-source revision separately; validator revision is recorded independently."
  - "Plan08 accepts immutable retained package evidence; Plan10 owns fresh fixed-wrapper pair runs and their strict composed matrix, instead of a third all-scope producer."
  - "A candidate source different from the runner requires an explicit source-owner pin; Plan08 supports checkout receipts and leaves authenticated frozen archive ownership to Plan10."
patterns-established:
  - "Every required matrix cell has a fixed producer path, stable case list, typed schema, raw digest and owner identity."
  - "Process-group cleanup uncertainty fails closed and cannot be converted to success by terminating only the direct child."
requirements-completed: []
coverage:
  - id: D1
    description: "Closed full and pair receipt validators reject omitted or substituted identities and accept the retained byte-pinned package receipts."
    requirement: VPROOF-02
    verification:
      - kind: unit
        ref: "python3 -m unittest discover -s test/acceptance -p '*_test.py' (168 tests)"
        status: pass
      - kind: integration
        ref: ".artifacts/phase178/aggregate-revalidated-3d8f99cc/aggregate.json (26 receipts, 64 cases)"
        status: pass
    human_judgment: false
  - id: D2
    description: "Bounded pair wrapper is integrated into the existing workflow and has fail-closed contract coverage; successful fixed-wrapper package execution remains assigned to Plan10."
    verification:
      - kind: unit
        ref: "test/acceptance/client_verifier_ci_test.py"
        status: pass
      - kind: integration
        ref: "Historical real wrapper attempts: locked 14/33 and floor 12/31, both exit 1 before the validator import fix; no fixed-wrapper green is claimed."
        status: unknown
    human_judgment: true
    rationale: "Plan10 must observe successful fixed-wrapper runs on authenticated frozen inputs and validate their composed package matrix."
duration: 96min
completed: 2026-10-27
status: complete
---

# Phase 178 Plan 08: Closed Verifier Matrix and Pair CI Integration Summary

**A strict 26-cell receipt boundary and bounded pair wrapper are implemented; retained package receipts validate with original runner identities, while successful fixed-wrapper runs move to Plan10 by approved sequence.**

## Performance

- **Duration:** approximately 96 minutes, from the recorded Plan07-to-Plan08 session boundary at 2026-10-27T01:54:56Z through Plan08 close.
- **Started:** 2026-10-27T01:54:56Z (last recorded session boundary; the first Plan08 command may have started later).
- **Completed:** 2026-10-27T03:30:54Z.
- **Tasks:** 2, completed under the root-approved sequencing amendment.
- **Implementation commits:** 19, measured from `d77a44b893facf3df5e647a6ebc1a20608fa0930` through `3d8f99cc8cca9df15d4e0338b660391cea49f30d`.

## Accomplishments

- Implemented a closed 26-cell / 64-case matrix with stable scope-to-path mappings, both disclosure receipt siblings, distinct rollout/public schema handling, strict source/package/tree/host/lock/run linkage, per-pair projections, and safe aggregate output.
- Added a bounded, pair-scoped CI wrapper with fresh-path checks, allowlisted outcomes, group ownership and cleanup, an overall deadline, fake-mode isolation, and validated-only artifact upload in the existing locked/floor jobs.
- Required explicit expected runner and expected candidate-source pins for retained full/pair validation. Aggregate output keeps the original runner SHA, candidate source/archive/tree, and current validator revision separate.
- Validated immutable retained inputs after the final validator commit: full runner `2da528fba3ca894cda4e5776b47eb6ccaf12f93c` passed 26 receipts / 64 cases; pair runner `90858f9fa1fecb3b5a6daa7ecc5946370e60303f` passed locked 14 / 33 and floor 12 / 31. All reported zero failed cases. The aggregate and pair indexes record validator `3d8f99cc8cca9df15d4e0338b660391cea49f30d` separately.
- The package identity shared across the retained matrices records archive digest `8be113c5d8cd630ee9fefba3494aac2c236350589a5cd9e7c98600a11a8d1e91` and extracted-tree digest `2af2082226f0be0e47b1f761cb4e98dd526effc0f93800fbacacce1f3a46b243`. Locked hosts used Phoenix 1.8.13 / LiveView 1.2.10; floor hosts used Phoenix 1.8.5 / LiveView 1.1.28. Per-cell compiled identities and exact host locks remain in the raw receipts and validated indexes; no locked compiled hash is generalized to floor.
- Full acceptance suite passed: 168 tests, 0 failures. Workflow lint, wrapper shell syntax, and `git diff --check` passed. Native TDD checker classified all seven retained Plan08 evidence records `RED_EVIDENCE_OK`.

## Task Commits

1. **Task 1: Close the complete finite matrix and prove omission/identity failures** — `d0fcc470`, `842865fc`, `34c2f554`, `7b809061`, `ed2b4cb6`, `501f8616`, `b9dc828a`, `d618c4fa`, `d7c53300`, `b10d03f5`, `d8c72310`, `3a404935`, `67cae728`, `3d8f99cc`.
2. **Task 2: Run verifier proof in existing locked/floor CI partitions** — `2da528fb`, `90858f9f`, `952e4e3b`, `69fab524`, `c8b82c14`.

The commit ledger measured 19 plan commits. The `d0fcc470` test attempt errored because then-missing validator APIs prevented the target behavior from running; it is not treated as behavioral RED. Later supported RED records are listed below.

## Actual Package and Wrapper Attempts

- Full installed matrix raw receipts at runner `2da528fba3ca894cda4e5776b47eb6ccaf12f93c`: 26 receipts / 64 cases. The original aggregate attempt exited 1 on receipt-path mapping. Its raw files remained unchanged; the corrected read-only validator later accepted them with an explicit runner and candidate-source pin.
- Locked wrapper process, session 99483, runner `90858f9fa1fecb3b5a6daa7ecc5946370e60303f`: completed 14 receipt files / 33 cases, then exited 1 at `validate/locked` because the pair CLI lacked the `validate_matrix_links` import.
- Floor wrapper process, session 86657, same runner: completed 12 receipt files / 31 cases, then exited 1 at `validate/floor` for the same missing import.
- Import fix is commit `952e4e3b`. Raw receipts were copied byte-for-byte to fresh directories and revalidated at `3d8f99cc`, producing locked 14/33 and floor 12/31. The fixed wrapper itself was not rerun. Per approved sequencing, Plan10 owns the first successful fixed-wrapper run for each pair at authenticated frozen inputs, then composes those exact outputs rather than launching a third all-scope package producer.
- Observed pair proof windows were 1,112.1 seconds locked and 1,019.5 seconds floor. Existing integration limits were raised to 45 minutes based on the measured locked baseline plus package proof; the wrapper enforces a 1,500-second overall deadline. No case was dropped to fit.
- A prior process-group stop returned `EACCES`; that refusal does not prove descendants stopped. Direct-child termination was treated as best-effort only. The implementation fails closed with a fixed cleanup-unconfirmed outcome and does not accept a receipt on uncertain group cleanup.

## TDD Gate Compliance

- Seven Plan08 JSON records passed `gsd_run check tdd-red-evidence`: `178-08-01-explicit-runner-red-evidence.json`, `178-08-01-historical-red-evidence.json`, `178-08-01-retained-pair-runner-red-evidence.json`, `178-08-02-cleanup-red-evidence.json`, `178-08-02-initial-red-evidence.json`, `178-08-02-overall-timeout-red-evidence.json`, and `178-08-02-pair-red-evidence.json`.
- The original RED JSON records were missing. The historical-source reproductions are labeled as new reproductions and do not claim original timestamps or recovered evidence.
- The supported REDs cover disclosure same-run identity, retained runner pinning, wrapper entrypoint, pair projection/import, total deadline, and cleanup-unconfirmed behavior. The initial `d0fcc470` missing-API error is explicitly excluded as a behavioral RED.

## Historical Security and Resource Incidents Preserved

- Plan03: an artifact retained raw JWT/code/PKCE material and was later scrubbed; its historical exposure remains recorded.
- Plan04 and Plan06: each had a failed-tool synthetic-secret exposure. Those are distinct incidents and are not recategorized as package failures.
- Plan07 source-database incidents: one shared, unboxed committed fixture change and one development-database migration. No development/shared database rollback, repair, or cleanup was performed. The first guard also had an OID-string refusal, followed by exact owned cleanup being corrected to use the witnessed OID cast.
- Plan07 had one unexplained post-capture unknown-key failure followed by success after a stage-only change. No causal fix is claimed.
- Plan08 preserved the complete aggregate path failure and both pair validator-import failures. These are distinct from the historical incidents above.

## Decisions Made

- Runner revision, candidate source revision, candidate archive/tree, per-host lock/compiled identities, and aggregate validator revision remain distinct fields with explicit owners.
- Plan08 validates retained checkout-source evidence. Authenticated frozen archive/input ownership belongs to Plan10; no archive-mode support is implied here.
- VPROOF-02 and VDELIV-01 remain pending. Plan08 completion does not infer phase completion, hosted green, merge acceptance, or publication.

## Deviations from Plan

### Root-approved sequencing amendment

Plan08's original wrapper verification expected both local wrappers to exit zero. Both real attempts instead completed package cases and failed at the validator import; after the import fix, the root directed no duplicate pair rerun solely for validator/deadline corrections. Root approved closing Plan08 against the corrected committed byte-pinned retained full and pair validations, preserving the actual wrapper exit-1 history, and assigning fresh zero-exit wrapper execution plus strict composition to Plan10. This changes verification ownership without representing the prior wrappers as green.

### Rule 1 — Corrected receipt path mapping and disclosure owner linkage

Observed full aggregate path mapping omitted the producer's disclosure failure sibling. Corrected mapping and same-run exception only for matching pair/store/source/host/package metadata; adversarial tests cover mismatched identities. Commits: `501f8616`, `d8c72310`, `3a404935`.

### Rule 3 — Fixed wrapper and validator integration blockers

Fixed the missing pair-validator import, explicit pin wiring, and fail-closed cleanup/deadline behavior. Preserved the original wrapper failures; committed fixes include `952e4e3b`, `69fab524`, `c8b82c14`, `67cae728`, and `3d8f99cc`.

**Total deviations:** 2 auto-fixed implementation blockers plus 1 root-approved sequencing amendment. No dependencies, schemas, protocol scope, or CI job graph were added.

## User Setup Required

None.

## Next Phase Readiness

Plan09 may proceed with the corrected retained full-matrix command and explicit `2da528...` runner and candidate-source pins. Plan10 must own authenticated frozen input/archive attribution, run the fixed wrapper successfully once for locked and once for floor, and semantically compose exactly 14 + 12 raw receipts / 33 + 31 cases into a strict complete matrix. The canonical `scripts/ci/run_owned_source_tests.py --ci` remains required for source acceptance. Merge and publication remain separately gated.

## Self-Check: PASSED

- Summary, plan amendment, and retained proof artifacts exist.
- All 19 implementation commits from `d77a44b8` through `3d8f99cc` are ancestors of the current branch.
- Retained identities and exact receipt/case counts match the validated JSON artifacts.

---
*Phase: 178-packaged-upgrade-proof-delivery-handoff*
*Completed: 2026-10-27*
