---
phase: 136-static-analysis-and-sustainable-proof
plan: "05"
subsystem: admin-proof
tags: [exunit, admin, redaction, architecture-fitness]
requires:
  - phase: 136-static-analysis-and-sustainable-proof
    provides: explicit CSS and route capability helpers
provides:
  - current rendered and source redaction proof
  - capability-oriented admin proof fitness without macro or historical quantities
affects: [136-11]
key-files:
  created:
    - test/support/lockspire/web/admin_proof/redaction_assertions.ex
  modified:
    - test/lockspire/web/live/admin/design_system/proof_artifact_contract_test.exs
    - test/lockspire/web/live/admin/design_system/inventory_contract_test.exs
  deleted:
    - test/support/admin_contract_helpers.ex
key-decisions:
  - "Admin proof evaluates current source, rendered safety, and inline browser-evidence contracts rather than archived milestone artifacts."
  - "Permanent fitness rejects macro injection, phase-numbered APIs, archived reads, wrapper loading, and quantity thresholds."
metrics:
  completed: 2026-08-27
  deleted_lines: 2210
status: complete
---

# Phase 136 Plan 05: Current Admin Proof Summary

**Admin proof now uses small named capabilities and current security behavior; the 1,606-line macro and historical test/assertion inventories are gone.**

## Accomplishments

- Added rendered and source redaction assertions covering credentials, tokens, keys, cookies, SQL, unsafe upstream bodies, safe handles, and status context.
- Kept browser evidence strict through maintained inline inputs with schema, result, uniqueness, route, and sensitive-evidence rejection proof.
- Replaced phase archaeology and quantity thresholds with synthetic architecture-fitness violations for every retired construct.
- Removed the final `AdminContractHelpers` consumer and deleted the macro.

## Task Commits

1. Task 1 — `a7d15a40` `test(136-05): replace archived admin proof with current behavior`
2. Task 2 — `a0faa567` `refactor(136-05): retire admin proof macro and count archaeology`

## Verification

- All four admin capability suites — 21 tests, 0 failures.
- `mix credo --strict` — 553 source files checked, no issues.
- No production or test capability suite reads `.planning/milestones` or invokes the retired macro.

## Deviations from Plan

None.

## Known Stubs

None.

## Self-Check: PASSED

- Named CSS, route, browser-evidence, HTML, and redaction helpers remain independently callable.
- The legacy macro file is absent and permanent synthetic fitness covers all five forbidden construct classes.
