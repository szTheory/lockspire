---
phase: 133-clean-room-saas-journey
plan: 01
subsystem: testing
tags: [acceptance, clean-room, process-supervision, package-provenance, redaction]
requires:
  - phase: 132-public-api-and-resource-server-truth
    provides: public embedded-provider seams that later clean-room fixtures consume
provides:
  - cleanup-safe two-origin provider/client process supervision
  - copied-package child dependency provenance with checked-in locked manifests
  - sentinel-backed redaction for acceptance diagnostics and evidence
affects: [133-02, 133-03, 133-04, 133-05, 133-06, ci]
tech-stack:
  added: [Python standard library process and package harness]
  patterns: [role-bounded supervision, copied-vendor provenance, pre-format evidence redaction]
key-files:
  created:
    - scripts/acceptance/run_clean_room_saas_journey.sh
    - scripts/acceptance/clean_room/processes.py
    - scripts/acceptance/clean_room/package_input.py
    - scripts/acceptance/clean_room/redaction.py
    - test/clean_room/provider_host/mix.exs
    - test/clean_room/confidential_client/mix.exs
    - test/integration/phase133_harness_test.exs
  modified: []
key-decisions:
  - "The harness owns exactly provider and client roles, avoiding a general-purpose service manager."
  - "Child projects always receive copied unpacked package contents at vendor/lockspire and retain byte-stable locks."
  - "All process diagnostics pass through one sentinel-aware redaction boundary before rendering."
patterns-established:
  - "Acceptance run roots are mode-0700 temporary directories removed by an exit-code-preserving shell trap."
  - "A child-local vendor dependency must be inventory-equal to the unpacked input, free of symlinks, and proven through Mix deps_paths."
requirements-completed: [E2E-01, E2E-06]
coverage:
  - id: D1
    description: Two bounded loopback probe origins are supervised through one cleanup-safe command.
    requirement: E2E-01
    verification:
      - kind: integration
        ref: test/integration/phase133_harness_test.exs#one supervisor reaches two separate loopback probe origins and cleans up
        status: pass
    human_judgment: false
  - id: D2
    description: Child dependencies resolve from copied, locked, child-local package contents.
    requirement: E2E-01
    verification:
      - kind: integration
        ref: test/integration/phase133_harness_test.exs#the two child manifests resolve Lockspire only from copied package contents
        status: pass
    human_judgment: false
  - id: D3
    description: OAuth/client/DPoP/cookie evidence is redacted before it can be rendered or retained.
    requirement: E2E-06
    verification:
      - kind: integration
        ref: test/integration/phase133_harness_test.exs#redaction removes every OAuth secret sentinel before evidence is formatted
        status: pass
    human_judgment: false
metrics:
  duration: 8min
  completed: 2026-08-27
status: complete
---

# Phase 133 Plan 01: Clean-Room Harness Foundation Summary

**A cleanup-safe two-origin acceptance harness now proves isolated child package provenance and secret-safe failure diagnostics.**

## Performance

- **Duration:** 8 min
- **Completed:** 2026-08-27T01:22:18Z
- **Tasks:** 3/3
- **Files modified:** 8

## Accomplishments

- Added a narrowly scoped provider/client supervisor with unequal loopback ports, bounded HTTP readiness, PID reaping, signal-safe cleanup, and preserved exit status.
- Added version-pinned provider/client manifests and locks, plus an unpacked-package builder that copies and verifies child-local `vendor/lockspire` inputs without checkout or symlink escape.
- Added centralized free-text, structured-header, exception, and artifact redaction with unique sentinels for every OAuth/OIDC credential class.

## Task Commits

1. **Task 1: Supervise two real origins through one cleanup-safe command** — `5201d51` (RED), `04baf14` (GREEN)
2. **Task 2: Lock package-clean child dependency resolution** — `02d4778` (RED), `70d380e` (GREEN), `bd5f303` (environment preflight)
3. **Task 3: Make failure evidence safe by construction** — `30fc154` (RED), `4f7acc6` (GREEN)

## Files Created/Modified

- `scripts/acceptance/run_clean_room_saas_journey.sh` — owns the temporary root and exit-code-preserving teardown.
- `scripts/acceptance/clean_room/processes.py` — bounded two-role loopback process supervisor.
- `scripts/acceptance/clean_room/package_input.py` — Hex-style unpacked package builder, inventory/provenance audit, and dependency preflight.
- `scripts/acceptance/clean_room/redaction.py` — centralized evidence redaction and sentinel scan.
- `test/clean_room/{provider_host,confidential_client}/mix.{exs,lock}` — pinned child manifests with stable vendor dependency declarations.
- `test/integration/phase133_harness_test.exs` — process, provenance, and redaction integration coverage.

## Decisions Made

- Keep orchestration role-bounded: provider and client only, avoiding a reusable service manager outside the acceptance boundary.
- Require copied unpacked package content and `Mix.Project.deps_paths/0` provenance rather than trusting a path dependency declaration alone.
- Probe PostgreSQL and loopback availability before child setup; no in-memory fallback is introduced.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing critical functionality] Added clean-room environment preflight**
- **Found during:** Task 2
- **Issue:** The package setup could otherwise begin before discovering unavailable PostgreSQL or loopback binding.
- **Fix:** Added actionable `pg_isready` and loopback allocation checks before preparing either child.
- **Files modified:** `scripts/acceptance/clean_room/package_input.py`
- **Verification:** `mix test --include integration test/integration/phase133_harness_test.exs --only dependency_lock`
- **Committed in:** `bd5f303`

---

**Total deviations:** 1 auto-fixed (Rule 2)
**Impact on plan:** Required preflight behavior from the plan is now explicit; no scope expansion.

## Issues Encountered

None.

## User Setup Required

None — the harness reports a missing local PostgreSQL service as an actionable environment failure.

## Next Phase Readiness

Plan 02 can copy the locked provider template, populate its already-defined vendor dependency, and replace probe startup with the supported generated Phoenix host installation flow.

## Self-Check: PASSED

- Required harness scripts, manifests, locks, and integration test exist.
- Task commits `5201d51`, `04baf14`, `02d4778`, `70d380e`, `bd5f303`, `30fc154`, and `4f7acc6` exist.
