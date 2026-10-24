---
phase: 171-accepted-baseline-finding-qualification
reviewed: 2026-10-24T21:05:26Z
depth: standard
files_reviewed: 9
files_reviewed_list:
  - test/lockspire/qualification_ledger_contract_test.exs
  - .planning/phases/171-accepted-baseline-finding-qualification/171-qualification_probe_test.exs
  - .planning/phases/171-accepted-baseline-finding-qualification/171-QUALIFICATION.json
  - .planning/phases/171-accepted-baseline-finding-qualification/171-QUALIFICATION-PROBE.json
  - .planning/phases/171-accepted-baseline-finding-qualification/171-MAIN-ACCEPTANCE.json
  - .planning/phases/171-accepted-baseline-finding-qualification/171-QUALIFICATION-DECISIONS.md
  - .planning/phases/171-accepted-baseline-finding-qualification/171-DELIVERY.md
  - .planning/REQUIREMENTS.md
  - .planning/ROADMAP.md
findings:
  critical: 0
  warning: 4
  info: 0
  total: 4
status: issues_found
---

# Phase 171: Code Review Report

**Reviewed:** 2026-10-24T21:05:26Z  
**Depth:** standard  
**Files Reviewed:** 9  
**Status:** issues_found

## Summary

Reviewed the frozen qualification ledger and evidence, the two-case HTTP probe, the ledger contract, and downstream requirement/roadmap reconciliation. The claimed source and receipt hashes are consistently bound in the retained evidence. Four warnings remain: the delivery record understates the final contract test count, the consent control can misclassify an off-origin redirect as host consent, malformed nested ledger values can crash validation, and nine validator functions exceed the configured Credo complexity limit.

## Warnings

### WR-01: Delivery record reports a stale final contract count

**File:** `.planning/phases/171-accepted-baseline-finding-qualification/171-DELIVERY.md:333-335`  
**Severity:** WARNING  
**Issue:** The delivery handoff says the matrix contract passes 18 tests, while the Plan 03 summary and final validation record the post-metadata-audit contract as 19 tests with zero failures. This leaves the durable handoff inconsistent about the final validation evidence.  
**Fix:** Update the delivery record to the final audited count and result (19 tests, 0 failures), or explicitly distinguish the earlier 18-test run from the later final run.

### WR-02: Consent control accepts an off-origin redirect

**File:** `.planning/phases/171-accepted-baseline-finding-qualification/171-qualification_probe_test.exs:232-240`  
**Severity:** WARNING  
**Issue:** `location_kind/1` labels any URL with a path beginning `/lockspire/consent/` as `host_consent`, without checking the URL scheme or host. For example, `https://attacker.example/lockspire/consent/<id>` is classified as host consent; the control then fetches the interaction by the final path segment and can pass its scope/state checks. An off-origin authorization redirect can therefore satisfy the positive control that is supposed to establish a safe host-consent path.  
**Fix:** For host consent, require a relative path or an explicitly expected origin, and verify the route path before resolving its interaction ID.

### WR-03: Malformed nested ledger entries can crash validation

**File:** `test/lockspire/qualification_ledger_contract_test.exs:809-837`  
**Severity:** WARNING  
**Issue:** The contract accepts arbitrary decoded ledger structures but traverses nested values before their types are validated. For example, setting a requirement disposition's `existing_proof` to a string reaches `Enum.all?(existing, ...)` and raises `Protocol.UndefinedError` instead of returning a rejection. Similar map/list assumptions occur when iterating profile and case entries. This makes malformed evidence produce an uncontrolled test crash rather than a useful fail-closed validation result.  
**Fix:** Validate each nested entry and collection type before dereferencing or enumerating it; accumulate a clear validation error and skip dependent checks when the shape is invalid. Add malformed-type fixtures for scalar/null nested values.

### WR-04: Validator complexity exceeds the project Credo limit

**File:** `test/lockspire/qualification_ledger_contract_test.exs:679-679, 746-746, 796-796, 927-927, 948-948, 1113-1113, 1184-1184, 1223-1223, 1313-1313`  
**Severity:** WARNING  
**Issue:** The fresh Credo run exits 8 because nine functions exceed its configured complexity limit: `validate_case_proof/3` (CC 40), `validate_case_references/2` (CC 30), `validate_requirement_dispositions/4` (CC 20), `validate_case_fields/2` (CC 18), `validate_matrix_rows/4` (CC 19), `frozen_scope_reconciled?/3` (CC 14), `valid_input_manifest?/3` (CC 10), `probe_counterexample_matches?/2` (CC 14), and `validate_profiles/2` (CC 12). The largest validator combines multiple independent evidence and identity checks, making changes difficult to audit and increasing the chance that a new branch bypasses a required invariant.  
**Fix:** Split the validators into cohesive helpers for shape validation, proof-kind validation, observation matching, and matrix disposition rules. Keep the same negative fixtures and do not suppress the Credo checks.

---

_Reviewed: 2026-10-24T21:05:26Z_  
_Reviewer: the agent (gsd-code-reviewer)_  
_Depth: standard_
