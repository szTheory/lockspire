---
phase: 138-baseline-inventory-evidence-taxonomy
reviewed: 2026-10-03T13:35:16Z
depth: standard
files_reviewed: 4
files_reviewed_list:
  - test/lockspire/quality/phase_138_prohibition_consistency_test.exs
  - test/lockspire/release/repository_hygiene_contract_test.exs
  - tools/gsd-capabilities/lockspire-phase-finalizer/lockspire-finalize-command-router.test.cjs
  - tools/gsd-capabilities/lockspire-phase-finalizer/lockspire-finalize-lifecycle.test.cjs
findings:
  critical: 0
  warning: 2
  info: 0
  total: 2
status: issues_found
---

# Phase 138: Code Review Report

**Reviewed:** 2026-10-03T13:35:16Z
**Depth:** standard
**Files Reviewed:** 4
**Status:** issues_found

## Summary

Reviewed the four scoped test files against the Phase 138 summaries and prohibition ledger. Two test reliability gaps remain: the ledger validator can accept evidence metadata that contradicts the stated evidence rule, and a Git fixture command breaks when the system temp path contains whitespace.

## Warnings

### WR-01: Evidence receipt validation accepts mismatched or contradictory receipts

**File:** `test/lockspire/quality/phase_138_prohibition_consistency_test.exs:392-396`
**Issue:** The evidence-backed row validator only searches for selector text and a test-name substring. It never checks that the command runs the recorded owner or that the named test exists in that owner. Its execution regex is unanchored, so contradictory text such as `tests=1 failures=0 exit=0; exit=1` still passes. This allows a fabricated or unrelated receipt to classify a prohibition as `test` / `ENFORCED`, despite the ledger's claim-specific test requirement.
**Fix:** Parse and validate the command's target test file and selector against the tracked owner and named test. Anchor the result format (for example, `^tests=[1-9]\\d* failures=0 exit=0$`) and reject extra or contradictory status text; add negative cases for an unrelated owner and trailing failure status.

### WR-02: Handoff fixture splits a generated filesystem path as command text

**File:** `test/lockspire/release/repository_hygiene_contract_test.exs:197`
**Issue:** `origin` is a temporary path interpolated into a string and tokenized with `String.split/1`. If `System.tmp_dir!/0` returns a path containing whitespace, the remote path becomes multiple Git arguments and this fixture fails before exercising the collector.
**Fix:** Pass Git arguments as a list without string splitting, e.g. `git.( ["remote", "add", "origin", origin], repository)`.

---

_Reviewed: 2026-10-03T13:35:16Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
