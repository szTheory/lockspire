---
phase: 127-executable-quality-baselines
plan: 02
subsystem: ci
tags: [phoenix, liveview, postgres, compatibility]
requires:
  - phase: 126-trusted-release-path
    provides: immutable CI dependency and image references
provides:
  - PostgreSQL 14 minimum support lane
  - exact Phoenix 1.8.5 and LiveView 1.1.28 compile fixture
affects: [ci, compatibility]
tech-stack:
  added: []
  patterns: [path-dependency host compatibility fixture]
key-files:
  created: [test/fixtures/phoenix_1_8_live_view_1_1/mix.exs, test/fixtures/phoenix_1_8_live_view_1_1/mix.lock, test/fixtures/phoenix_1_8_live_view_1_1/lib/lockspire_compatibility_fixture.ex, test/lockspire/compatibility_baseline_contract_test.exs]
  modified: [.github/workflows/ci.yml, scripts/ci/lint_workflows.sh]
key-decisions:
  - "Pin the fixture's Phoenix and LiveView dependencies exactly while leaving Lockspire's public dependency ranges broad."
  - "Use an immutable PostgreSQL 14 digest only in the declared minimum compatibility lane."
requirements-completed: [COMPAT-01, COMPAT-02]
coverage:
  - id: D1
    description: "The minimum BEAM lane tests against immutable PostgreSQL 14."
    requirement: COMPAT-01
    verification:
      - kind: unit
        ref: test/lockspire/compatibility_baseline_contract_test.exs
        status: pass
      - kind: other
        ref: bash scripts/ci/lint_workflows.sh
        status: pass
    human_judgment: false
  - id: D2
    description: "A path-dependent host fixture compiles Lockspire against Phoenix 1.8.5 and LiveView 1.1.28."
    requirement: COMPAT-02
    verification:
      - kind: other
        ref: test/fixtures/phoenix_1_8_live_view_1_1: mix deps.get --check-locked && mix compile --warnings-as-errors
        status: pass
    human_judgment: false
duration: 14min
completed: 2026-08-26
status: complete
---

# Phase 127 Plan 02: Compatibility Baseline Summary

**CI now proves the supported PostgreSQL 14, Phoenix 1.8.5, and LiveView 1.1.28 floors with immutable inputs and a real host-router compile.**

## Accomplishments

- Changed only the minimum compatibility service to the registry-resolved PostgreSQL 14 digest.
- Added a committed, exact-version Phoenix/LiveView fixture that mounts Lockspire's protocol and host-guarded admin routers through a path dependency.
- Added fixture dependency/compile/lock checks to CI and contracts for version, image, and lock-drift truth.

## Task Commits

1. **Task 1: Compile an exact Phoenix/LiveView host seam in the PostgreSQL 14 minimum lane** - `78804a2` (test)
2. **Task 1 deviation: Ignore generated fixture dependencies and build output** - `5401ea0` (chore)

## Deviations from Plan

### Auto-fixed Issues

1. [Rule 3 - Blocking issue] Made the CI lint script compatible with Bash 3.
- **Issue:** `mapfile` is unavailable in the local Bash used for verification.
- **Fix:** Replaced it with portable array population loops, retaining the same files and lint commands.
- **Verification:** `bash scripts/ci/lint_workflows.sh` passed.

2. [Rule 3 - Blocking issue] Kept fixture build artifacts outside `test/`.
- **Issue:** generated dependency/template files under `test/fixtures` were discovered by root coverage test loading.
- **Fix:** Configured the fixture to build under ignored `tmp/lockspire-compatibility-fixture` paths.
- **Verification:** `MIX_ENV=test mix test.coverage` passed at 73.11%.

## Verification

- Fixture `mix deps.get --check-locked && mix compile --warnings-as-errors` — passed.
- Compatibility, supply-chain, and CI source contracts — 7 tests passed.
- `bash scripts/ci/lint_workflows.sh` — passed.

## Next Phase Readiness

The CI floor claims are now executable and fixture outputs cannot pollute root test discovery.

## Self-Check: PASSED

- Summary file and task commits `78804a2` and `5401ea0` are present.
