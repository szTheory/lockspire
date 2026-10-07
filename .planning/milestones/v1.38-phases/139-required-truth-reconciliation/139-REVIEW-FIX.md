---
phase: phase-139-required-truth-reconciliation
fixed_at: 2026-10-06T10:13:27Z
review_path: .planning/phases/139-required-truth-reconciliation/139-REVIEW.md
iteration: 2
findings_in_scope: 4
fixed: 4
skipped: 0
status: all_fixed
---

# Phase 139: Code Review Fix Report

**Fixed at:** 2026-10-06T10:13:27Z
**Source review:** `.planning/phases/139-required-truth-reconciliation/139-REVIEW.md`
**Iterations:** 2

**Summary:**
- Findings addressed across both iterations: 4
- Fixed: 4
- Skipped: 0

## Fixed Issues

### CR-01: GitHub release evidence is not bound to the Lockspire repository

**Files modified:** `scripts/maintainer/repo_hygiene_check.sh`, `test/support/lockspire/release_proof/package_assertions.ex`
**Commit:** `4d123918`
**Status:** fixed
**Applied fix:** Require the GitHub release URL owner/repository to match `LOCKSPIRE_HYGIENE_REPOSITORY` (default `szTheory/lockspire`) and retain label/tag version equality. Added a fail-closed fixture mutation that changes only the URL repository.

### CR-01: Exact public release query is not tied to the candidate version

**Files modified:** `scripts/maintainer/repo_hygiene_check.sh`, `test/support/lockspire/release_proof/package_assertions.ex`
**Commit:** `7803706c`
**Status:** fixed
**Applied fix:** Capture the exact Hex release-query version and require it to match Release Please metadata. Added a fixture mutation that changes only the queried version.

### CR-02: GitHub tag link destination can disagree with the parsed release version

**Files modified:** `scripts/maintainer/repo_hygiene_check.sh`, `test/support/lockspire/release_proof/package_assertions.ex`
**Commit:** `29cac690`
**Status:** fixed
**Applied fix:** Capture both the GitHub release label version and URL tag version, accepting the ledger row only when they match. Added a fixture mutation that changes only the URL version.

### WR-01: Historical release fixture leaves Release Please metadata unchanged

**Files modified:** `test/support/lockspire/release_proof/package_assertions.ex`
**Commit:** `bdcf2108`
**Status:** fixed
**Applied fix:** Replace the historical `Release Please version metadata` bullet from `1.5.1` to `1.5.0` when constructing the fixture.

## Additional CI correction

The first full CI run exposed a separate stale setup in the merged-release-lineage fixture. It attempted to change a metadata line that the historical release-train file did not contain, leaving `.planning/RELEASE-TRAIN.md` unchanged in the simulated 1.5.0 to 1.5.1 Release Please commit. The fixture now changes the actual historical `Latest released version` line before simulating that release.

**Commit:** `72b68192`
**Verification:** The specific merged-release-lineage test passed (1 test, 0 failures). The isolated baseline-relation fixture that timed out in the first full run passed on its own (1 test, 0 failures).

## Verification

The two review-fix iterations passed read-back and syntax checks, including `bash -n scripts/maintainer/repo_hygiene_check.sh`, Elixir parsing of `package_assertions.ex`, and `git diff --check`. The second iteration also ran a focused parser check that accepted the configured repository and rejected a different repository with the same tag version. The standard code review was rerun after both source and fixture corrections and returned `clean`; its report is `139-REVIEW.md`.

Focused regression checks passed: release-hygiene contracts (5 tests), Phase 139 planning checks (2 tests), merged-release lineage (1 test), and baseline relation integrity (1 test).

Full local CI passed with the pinned Elixir 1.19.5 / OTP 28.1 toolchain and a writable temporary Hex cache:

- Main suite: 1,447 tests, 0 failures, 6 skipped (286 excluded).
- Integration suite: 102 tests, 0 failures (33 excluded).
- Credo, Sobelow, package build, dependency checks, and the remaining `mix ci` steps passed.

## Skipped Issues

None.

---

_Fixed: 2026-10-06T10:13:27Z_
_Fixer: the agent (gsd-code-fixer)_
