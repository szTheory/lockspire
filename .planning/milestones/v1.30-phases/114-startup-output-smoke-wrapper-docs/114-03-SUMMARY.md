---
phase: 114-startup-output-smoke-wrapper-docs
plan: 03
subsystem: demo-dx
tags: [docker, docs, smoke, adoption-demo, exunit]

requires:
  - phase: 114-startup-output-smoke-wrapper-docs
    provides: Plan 01 docker-info startup output and Plan 02 smoke wrapper/reprint command
  - phase: 112-default-docker-compose-app-db
    provides: Direct Docker startup path with app and database
  - phase: 113-conflict-controls-optional-traefik
    provides: Optional Traefik hostname routing and conflict controls
provides:
  - Docker-first adoption demo maintainer guide
  - Documentation contracts for DOCS-01, DOCS-02, INFO-04, SMOKE-01, and SMOKE-02
  - Phase 114 cleanup-boundary wording that defers broader hygiene commands to Phase 115
affects: [phase-114, phase-115, adoption-demo, docker-docs, smoke-wrapper-docs]

tech-stack:
  added: []
  patterns:
    - Documentation contracts assert ordered sections and exact maintainer commands.
    - Adoption demo docs use scripts/demo/adoption_smoke.sh as the maintainer-facing smoke entrypoint.

key-files:
  created:
    - .planning/phases/114-startup-output-smoke-wrapper-docs/114-03-SUMMARY.md
  modified:
    - docs/adoption-demo.md
    - test/lockspire/adoption_demo_docker_contract_test.exs

key-decisions:
  - "Docker remains the default maintainer path; host-local Mix/Postgres is documented only as fallback."
  - "Maintainer docs point to scripts/demo/adoption_smoke.sh while preserving scripts/demo/adoption_smoke.py as the black-box OAuth/OIDC proof."
  - "Phase 114 documents stop/reset boundaries and leaves broader cleanup/hygiene command implementation to Phase 115."

patterns-established:
  - "Docs contracts should assert exact command strings for startup, reprint, smoke, stop, reset, and optional Traefik flows."
  - "Docs for demo cleanup must distinguish stop, active-project reset, and future broader hygiene work."

requirements-completed: [DOCS-01, DOCS-02, INFO-04, SMOKE-01, SMOKE-02]

duration: 8min
completed: 2026-06-24
status: complete
---

# Phase 114 Plan 03: Adoption Demo Docs Summary

**Docker-first adoption demo docs now cover startup output, reprint, smoke wrappers, stop/reset boundaries, overrides, optional Traefik, and troubleshooting.**

## Performance

- **Duration:** 8 min
- **Started:** 2026-06-24T16:48:00Z
- **Completed:** 2026-06-24T16:56:25Z
- **Tasks:** 3
- **Files modified:** 3

## Accomplishments

- Added deterministic docs contracts proving Docker startup appears before host-local fallback and that direct Docker remains the default maintainer path.
- Rewrote `docs/adoption-demo.md` into a self-contained maintainer guide for startup output, reprint, direct smoke, optional Traefik smoke, stop, reset, cleanup boundary, environment overrides, and troubleshooting.
- Verified shell syntax, Python smoke compilation, focused docs contracts, and the full local non-integration suite.

## Task Commits

Each task was committed atomically:

1. **Task 1: Add docs coverage contracts for Phase 114 maintainer guide** - `b64fd6a` (test)
2. **Task 2: Rewrite adoption demo docs as Docker-first self-describing guide** - `259dc9a` (docs)
3. **Task 3: Run phase-level contract and shell verification** - `1a0ede8` (chore, verification-only empty commit)

**Plan metadata:** summary/state commit follows this file.

## Files Created/Modified

- `docs/adoption-demo.md` - Docker-first maintainer guide for startup, reprint, smoke, stop, reset, cleanup boundary, overrides, optional Traefik, host-local fallback, and troubleshooting.
- `test/lockspire/adoption_demo_docker_contract_test.exs` - Adds docs coverage contracts for ordering, exact commands, wrapper usage, cleanup boundary, and troubleshooting coverage.
- `.planning/phases/114-startup-output-smoke-wrapper-docs/114-03-SUMMARY.md` - Execution summary and verification evidence.

## Decisions Made

- Docker remains the default maintainer path, with host-local Mix/Postgres documented after Docker as a fallback.
- Maintainer docs now use `scripts/demo/adoption_smoke.sh`; the wrapper delegates to `scripts/demo/adoption_smoke.py`, which remains the black-box OAuth/OIDC proof.
- Stop/reset/cleanup wording explicitly separates `docker compose ... down`, `examples/adoption_demo/bin/docker-reset`, and Phase 115-owned broader cleanup/hygiene implementation.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Updated older docs contract from raw Python smoke to wrapper smoke**
- **Found during:** Task 2 (Rewrite adoption demo docs as Docker-first self-describing guide)
- **Issue:** An existing docs assertion still required the old raw `python3 scripts/demo/adoption_smoke.py` command for alternate direct ports, which conflicted with Phase 114 Plan 02's wrapper contract and this plan's wrapper-docs requirement.
- **Fix:** Updated the assertion to expect `scripts/demo/adoption_smoke.sh` for the alternate direct-port example.
- **Files modified:** `test/lockspire/adoption_demo_docker_contract_test.exs`
- **Verification:** `mix test test/lockspire/adoption_demo_docker_contract_test.exs --seed 0`
- **Committed in:** `259dc9a`

---

**Total deviations:** 1 auto-fixed (Rule 1).
**Impact on plan:** The fix aligned the existing contract with prior-wave artifacts and did not widen scope.

## Issues Encountered

- RED failed as intended with 4 docs-contract failures because the previous docs lacked Docker-default wording, startup output coverage, wrapper smoke examples, stop/troubleshooting coverage, and Phase 115 cleanup-boundary wording.
- Focused ExUnit runs emitted the pre-existing asynchronous KeyCache refresh log about `Lockspire.TestRepo` not being started; the focused suite still completed successfully.
- `mix test.fast` was available locally and passed, so no full-suite database blocker remains for this plan.

## Known Stubs

None.

## Threat Flags

None.

## User Setup Required

None - no external service configuration required for the non-Docker docs and contract verification. Optional Traefik runtime smoke still requires a running local Traefik proxy attached to `local-dev-proxy`.

## Verification

- RED: `mix test test/lockspire/adoption_demo_docker_contract_test.exs --seed 0` failed before docs implementation with 21 tests, 4 failures.
- GREEN: `mix test test/lockspire/adoption_demo_docker_contract_test.exs --seed 0` passed with 21 tests, 0 failures.
- Final non-Docker gate passed: `sh -n examples/adoption_demo/bin/docker-info && sh -n examples/adoption_demo/bin/docker-start && sh -n scripts/demo/adoption_smoke.sh && python3 -m py_compile scripts/demo/adoption_smoke.py && mix test test/lockspire/adoption_demo_docker_contract_test.exs --seed 0`.
- Full local non-integration suite passed: `mix test.fast` with 1095 tests, 0 failures, 287 excluded.

## Next Phase Readiness

Phase 115 can build the broader repo hygiene and cleanup lane on top of docs that now explicitly separate stop, active-project reset, and future cleanup/hygiene implementation. No blockers remain for Phase 114 verification.

## Self-Check: PASSED

- Created file exists: `.planning/phases/114-startup-output-smoke-wrapper-docs/114-03-SUMMARY.md`.
- Modified files exist: `docs/adoption-demo.md`, `test/lockspire/adoption_demo_docker_contract_test.exs`.
- Task commits found: `b64fd6a`, `259dc9a`, `1a0ede8`.
- Stub scan found no placeholder/TODO/FIXME/hardcoded-empty UI stubs in modified files.
- Final non-Docker verification and `mix test.fast` passed.

---
*Phase: 114-startup-output-smoke-wrapper-docs*
*Completed: 2026-06-24*
