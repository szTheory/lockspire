---
phase: 171-accepted-baseline-finding-qualification
fixed_at: 2026-10-24T21:18:34Z
review_path: .planning/phases/171-accepted-baseline-finding-qualification/171-REVIEW.md
iteration: 1
findings_in_scope: 4
fixed: 4
skipped: 0
status: all_fixed
---

# Phase 171: Code Review Fix Report

**Fixed at:** 2026-10-24T21:18:34Z  
**Source review:** `.planning/phases/171-accepted-baseline-finding-qualification/171-REVIEW.md`  
**Iteration:** 1

**Summary:**
- Findings in scope: 4
- Fixed: 4
- Skipped: 0

## Fixed Issues

### WR-01: Delivery record reports a stale final contract count

**Files modified:** `.planning/phases/171-accepted-baseline-finding-qualification/171-DELIVERY.md`  
**Commit:** `5d5b7d80`  
**Applied fix:** Distinguished the earlier 18-test run from the final post-metadata-audit result of 19 tests and 0 failures. Later review verification is recorded separately, preserving both prior counts.

### WR-02: Consent control accepts an off-origin redirect

**Files modified:** `.planning/phases/171-accepted-baseline-finding-qualification/171-qualification_probe_test.exs`, `.planning/phases/171-accepted-baseline-finding-qualification/171-QUALIFICATION-PROBE.json`, `.planning/phases/171-accepted-baseline-finding-qualification/171-QUALIFICATION-PROBE-20261024T204101Z.json`, `.planning/phases/171-accepted-baseline-finding-qualification/171-QUALIFICATION.json`, `.planning/phases/171-accepted-baseline-finding-qualification/171-DELIVERY.md`, `test/lockspire/qualification_ledger_contract_test.exs`  
**Commits:** `ca476179`, `b02f76e4`, `30e385a3`, `9d774872`  
**Applied fix:** Consent classification and interaction lookup now accept only the exact relative `/lockspire/consent/<id>` route, with no scheme, host, user info, or port. Synthetic checks reject an HTTPS off-origin URL, a network-path URL, and lookalike routes. The original probe JSON is preserved byte-for-byte in its dated archive. A fresh run at source `30e385a33bb2a7f67d94c558dedf7691ecde5863` recorded probe SHA-256 `0f32ab008fe4ebffc17d471ffd0959fe55861d418ce62fe8f636330f6f9972f5`, exit 2, 2 tests, 2 failures, and 0 skipped. All synthetic and valid-path controls passed before the two existing normative assertions reproduced their RED results. The earlier observation remains in the ledger with its original source and probe hashes.

### WR-03: Malformed nested ledger entries can crash validation

**Files modified:** `test/lockspire/qualification_ledger_contract_test.exs`, `.planning/phases/171-accepted-baseline-finding-qualification/171-QUALIFICATION.json`  
**Commit:** `2e4b0116`  
**Applied fix:** Added pre-traversal shape checks and validation guards for scalar profile, case, row, and disposition entries, including string and null `existing_proof` values. Added negative fixtures; the malformed profile first reproduced a `BadMapError`, then all malformed fixtures returned validation errors without crashing. Existing proof predicates remain required.

### WR-04: Validator complexity exceeds the project Credo limit

**Files modified:** `test/lockspire/qualification_ledger_contract_test.exs`, `.planning/phases/171-accepted-baseline-finding-qualification/171-QUALIFICATION.json`, `.planning/phases/171-accepted-baseline-finding-qualification/171-QUALIFICATION-PROBE.json`, `.planning/phases/171-accepted-baseline-finding-qualification/171-DELIVERY.md`  
**Commit:** `9d774872`  
**Applied fix:** Split profile, case-shape, reference, proof, observation, disposition, frozen-scope, manifest, and probe-evidence validation into focused helpers. Kept the required checks and existing positive, negative, equality, single-case, and empty-scope fixtures. Updated only reviewed manifest entries and selectors, with audit reasons and a recomputed ordered digest.

## Verification

Verification ran in the main checkout on `milestone/v1.47-core-hardening`, with `workflow.use_worktrees=false`.

- `mix format --check-formatted test/lockspire/qualification_ledger_contract_test.exs .planning/phases/171-accepted-baseline-finding-qualification/171-qualification_probe_test.exs` — passed.
- `mix test test/lockspire/qualification_ledger_contract_test.exs` — 20 tests, 0 failures.
- `mix credo --strict` — exit 0, no issues across 683 source files.
- The single valid post-fix phase-local probe observation — exit 2, 2 tests, 2 normative assertion failures, 0 skipped; all preceding controls passed. These are preserved qualification counterexamples, not protocol passes.
- The original probe archive matches the bytes from commit `4a302bda` at SHA-256 `3f1fd7c2797614b98bfdb6466942a06c05ea11ec908f31f944bd6adaf26ad764`.

---

_Fixed: 2026-10-24T21:18:34Z_  
_Fixer: the agent (gsd-code-fixer)_  
_Iteration: 1_
