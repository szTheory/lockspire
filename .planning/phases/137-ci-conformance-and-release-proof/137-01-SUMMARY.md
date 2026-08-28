---
phase: 137-ci-conformance-and-release-proof
plan: "01"
subsystem: ci-security-dependencies
tags: [sobelow, dependency-lock, xref, release-quality]
requires:
  - phase: 136-static-analysis-and-sustainable-proof
    provides: static-analysis and architecture fitness baseline
provides:
  - fail-closed low-severity Sobelow scans for both shipped routers
  - read-only unused-lock and compile-connected-cycle policy
affects: [137-02, 137-03]
tech-stack:
  added: []
  patterns: [script-owned CI policy, fixture-safe policy contracts]
key-files:
  created:
    - scripts/ci/check_sobelow_routers.sh
    - scripts/ci/check_dependency_truth.sh
    - test/lockspire/ci_security_dependency_contract_test.exs
  modified:
    - .sobelow-conf
    - scripts/ci/check_architecture_topology.sh
key-decisions:
  - "Each shipped router is scanned explicitly instead of relying on Sobelow router discovery."
  - "Dependency truth uses Mix's non-mutating check-unused mode and compile-connected cycle scope."
metrics:
  completed: 2026-08-27
status: complete
---

# Phase 137 Plan 01: CI Security and Dependency Tracer Summary

**Local CI now has an executable release-quality path that rejects low-severity findings in either router, dead locked dependencies, and compile-connected cycles.**

## Accomplishments

- Added two explicit fail-closed Sobelow invocations for `Lockspire.Web.Router` and `Lockspire.Web.AdminRouter`, each using config, private checks, a low threshold, and non-zero exit behavior.
- Reformatted the Sobelow configuration into individually named exclusions with adjacent reasons; no source tree or file path is ignored.
- Added a side-effect-free dependency gate using `mix deps.unlock --check-unused`, then delegated cycle detection to the architecture script.
- Restricted cycle inspection to `mix xref graph --format cycles --label compile-connected`.
- Added policy contracts with negative fixtures for omitted routers, omitted flags, broad Sobelow ignores, and destructive dependency unlocking.

## Task Commits

1. **Task 1: Prove both router scans through one fail-closed command** — `bce5eeae` (RED), `05c5bca5` (GREEN)
2. **Task 2: Reject unused locked dependencies and compile-connected cycles** — `5406f9f4`

## Verification

- `bash scripts/ci/check_sobelow_routers.sh` — both explicit router scans completed with no findings.
- `bash scripts/ci/check_dependency_truth.sh` — unused-lock check passed; no compile-connected cycles found.
- `MIX_ENV=test mix test test/lockspire/ci_security_dependency_contract_test.exs test/lockspire/architecture_fitness_test.exs` — 10 tests, 0 failures.
- `MIX_ENV=test mix qa.architecture` — 13 tests, 0 failures; no cycles found.
- `git diff --exit-code -- mix.lock examples/adoption_demo/mix.lock compatibility/phoenix_1_8_live_view_1_1/mix.lock` — passed with no lockfile mutation.

## Deviations from Plan

### Auto-fixed Issues

1. **[Rule 1 - Test fixture] Corrected the omitted-private-flag fixture.**
- **Found during:** Task 1.
- **Issue:** its default flags accidentally still included `--private`.
- **Fix:** supplied the explicit reduced fixture flag list.
- **Files modified:** `test/lockspire/ci_security_dependency_contract_test.exs`.
- **Commit:** `05c5bca5`.

## Known Stubs

None.

## Self-Check: PASSED

- Both policy scripts and their executable contract exist.
- Commits `bce5eeae`, `05c5bca5`, and `5406f9f4` are present in git history.
