---
phase: 139-required-truth-reconciliation
reviewed: 2026-10-06T09:49:30Z
depth: standard
files_reviewed: 5
files_reviewed_list:
  - scripts/maintainer/repo_hygiene_check.sh
  - test/lockspire/quality/phase_139_planning_consistency_test.exs
  - test/lockspire/release/repository_hygiene_contract_test.exs
  - test/lockspire/workflow_supply_chain_contract_test.exs
  - test/support/lockspire/release_proof/package_assertions.ex
findings:
  critical: 2
  warning: 1
  info: 0
  total: 3
status: issues_found
---

# Phase 139: Code Review Report

**Reviewed:** 2026-10-06T09:49:30Z
**Depth:** standard
**Files Reviewed:** 5
**Status:** issues_found

## Summary

Reviewed the hygiene gate, Phase 139 consistency and workflow contract tests, and release-proof fixtures. The ledger parser can accept internally contradictory publication evidence, and one historical release fixture no longer changes its metadata to match the simulated version. Tests were not run.

## Critical Issues

### CR-01: Exact public release query is not tied to the candidate version

**Classification:** BLOCKER
**File:** `scripts/maintainer/repo_hygiene_check.sh:651-652`
**Issue:** The parser captures the Hex latest version (`$1`) but discards the exact release-query version (`$2`). `release_train_has_consistent_versions` then checks only that the latest package agrees with the artifact and GitHub tag. Changing the query from the candidate version to an unrelated nonexistent version still passes, so the exact-404 claim can falsely imply the current candidate is unpublished and allow an acceptance receipt.
**Fix:** Capture both versions and require the query version to equal `metadata_version` (and therefore the checked `mix.exs` version). Add a fixture mutation that changes only the query version and requires the gate to block.

### CR-02: GitHub tag link destination can disagree with the parsed release version

**Classification:** BLOCKER
**File:** `scripts/maintainer/repo_hygiene_check.sh:659-660`
**Issue:** The regex returns the version from the Markdown link label, but `[^)]*` consumes the destination without capturing or comparing its tag version. A line labeled `lockspire-v1.5.0` that links to `/tag/lockspire-v1.5.1` is accepted as version 1.5.0, allowing inconsistent release evidence through the gate.
**Fix:** Capture the version in both the link label and URL and require them to match; add a fixture case that changes only the URL tag version.

## Warnings

### WR-01: Historical release fixture leaves Release Please metadata unchanged

**Classification:** WARNING
**File:** `test/support/lockspire/release_proof/package_assertions.ex:3718-3725`
**Issue:** The fixture reads the historical ledger containing `Release Please version metadata: 1.5.1`, then tries to change it using a replacement string for the old `Latest released version` wording. That replacement is now a no-op, while the fixture sets the manifest to 1.5.0. Scenarios using this fixture therefore start with mismatched release metadata and do not model the intended 1.5.0 state.
**Fix:** Replace the current metadata bullet containing version 1.5.1 with the corresponding 1.5.0 bullet when constructing the fixture.

---

_Reviewed: 2026-10-06T09:49:30Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
