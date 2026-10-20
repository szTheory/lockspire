---
phase: "162"
slug: "lifetime-semantics-upgrade-contract"
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-10-20"
---

# Phase 162 — Validation Strategy

Contract validation proves design coverage and internal consistency, not runtime enforcement.

## Test Infrastructure

Python 3 standard library, no dependencies, services or database. The phase-local validator is `.planning/phases/162-lifetime-semantics-upgrade-contract/validate_contract.py`; run commands from the repository root.

## Sampling Rate

After each task and wave run the contract validator and `git diff --check`; target feedback under 10 seconds. Do not run unrelated release or runtime suites.

## Per-Task Verification Map

| Task | Requirements | Automated command | Failure signal |
|------|--------------|-------------------|----------------|
| 162-01-1 | DCR-02 | `python3 .planning/phases/162-lifetime-semantics-upgrade-contract/validate_contract.py --stage policy --self-test` | Nonzero exit, missing PASS policy/scope sentence, or unexpectedly accepted named mutation |
| 162-01-2 | DCR-03 | `python3 .planning/phases/162-lifetime-semantics-upgrade-contract/validate_contract.py --stage consumers --self-test` | Nonzero exit, missing PASS consumers/scope sentence, missing consumer/outcome or unexpectedly accepted named mutation |
| 162-01-3 | DCR-04; complete DCR-02/03 mapping | `python3 .planning/phases/162-lifetime-semantics-upgrade-contract/validate_contract.py --stage complete --self-test` | Nonzero exit, missing PASS complete/scope sentence, incomplete mapping or unexpectedly accepted named mutation |

Run `git diff --check` after each task; nonzero exit or whitespace-error output fails. Complete-stage validation includes contract structure, D-01–D-27 coverage, local links, exact consumer inventory, independently computed fixture arithmetic, boundaries, compatibility/deployment and the design-only disclaimer. Self-tests mutate actual valid inputs and require the intended rejection reason. Threat coverage: stale authorization, lockout, legacy promotion, error disclosure and mixed-version bypass are contract invariants, not runtime controls proven here. Independent semantic review remains separate from validator results.

## Wave 0 Requirements

Create a phase-local documentation validator alongside contract fixtures. It must fail for missing decisions, consumers or requirement owners; malformed fixtures, wrong equality/arithmetic, broken local references or incomplete deployment cases. No runtime implementation or test scaffolding.

## Manual-Only Verifications

Independent adversarial semantic review cross-checks selected decisions against contract/fixtures: expired vs disabled; caller vs target; lost PUT response/recovery; stale hash; post-lock time; RAT-only legacy normalization; v1 rollback boundary. Record evidence in verification, not an unsupported enforcement claim.

## Validation Sign-Off

- [ ] Every task has an automated command and observable failure direction.
- [ ] All27selected decisions and3requirements mapped to substantive sections and fixtures/reasoning.
- [ ] Validator exercised positive and meaningful negative cases.
- [ ] Independent semantic review passed.
- [ ] Runtime/migration/race/security/CI claims remain assigned to163–166.

Approval: selected scope; validation pending execution.
