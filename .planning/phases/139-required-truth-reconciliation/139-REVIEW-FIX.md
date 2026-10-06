---
phase: phase-139-required-truth-reconciliation
fixed_at: 2026-10-06T10:08:37Z
review_path: .planning/phases/139-required-truth-reconciliation/139-REVIEW.md
iteration: 2
findings_in_scope: 1
fixed: 1
skipped: 0
status: all_fixed
---

# Phase 139: Code Review Fix Report

**Fixed at:** 2026-10-06T10:08:37Z
**Source review:** `.planning/phases/139-required-truth-reconciliation/139-REVIEW.md`
**Iteration:** 2

**Summary:**
- Findings in scope: 1
- Fixed: 1
- Skipped: 0

## Iteration 2: Fixed Issue

### CR-01: GitHub release evidence is not bound to the Lockspire repository

**Files modified:** `scripts/maintainer/repo_hygiene_check.sh`, `test/support/lockspire/release_proof/package_assertions.ex`
**Commit:** `4d123918`
**Status:** fixed: requires human verification
**Applied fix:** Parse the URL owner/repository and require it to equal `LOCKSPIRE_HYGIENE_REPOSITORY` when configured, defaulting to `szTheory/lockspire`; preserve the label/tag version equality check. Added a fail-closed fixture mutation that changes the URL repository while keeping the tag version unchanged.

## Iteration 1: Previously Fixed Issues

### CR-01: Exact public release query is not tied to the candidate version

**Files modified:** `scripts/maintainer/repo_hygiene_check.sh`, `test/support/lockspire/release_proof/package_assertions.ex`
**Commit:** `7803706c`
**Status:** fixed: requires human verification
**Applied fix:** Capture the exact Hex release-query version and require it to match Release Please metadata. Added a fixture mutation that changes only the queried version.

### CR-02: GitHub tag link destination can disagree with the parsed release version

**Files modified:** `scripts/maintainer/repo_hygiene_check.sh`, `test/support/lockspire/release_proof/package_assertions.ex`
**Commit:** `29cac690`
**Status:** fixed: requires human verification
**Applied fix:** Capture both the GitHub release label version and URL tag version, accepting the ledger row only when they match. Added a fixture mutation that changes only the URL version.

### WR-01: Historical release fixture leaves Release Please metadata unchanged

**Files modified:** `test/support/lockspire/release_proof/package_assertions.ex`
**Commit:** `bdcf2108`
**Status:** fixed
**Applied fix:** Replace the historical `Release Please version metadata` bullet from `1.5.1` to `1.5.0` when constructing the fixture.

## Verification

Iteration 1 read-back and syntax verification ran in its isolated review-fix worktree. Iteration 2 read-back, `bash -n scripts/maintainer/repo_hygiene_check.sh`, Elixir `Code.string_to_quoted!/1` parsing of `package_assertions.ex`, and `git diff --check` ran in the isolated review-fix worktree. A focused parser check accepted the configured canonical repository and rejected a different repository with the same tag version. The full test suite was not run.

## Skipped Issues

None.

---

_Fixed: 2026-10-06T10:08:37Z_
_Fixer: the agent (gsd-code-fixer)_
_Iteration: 2_
