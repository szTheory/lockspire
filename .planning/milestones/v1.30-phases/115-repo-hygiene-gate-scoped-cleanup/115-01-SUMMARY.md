---
phase: 115-repo-hygiene-gate-scoped-cleanup
plan: 01
subsystem: tooling
tags: [docker, adoption-demo, cleanup, repo-hygiene, exunit]

requires:
  - phase: 113-conflict-controls-optional-traefik
    provides: adoption demo Compose project-name scoping and active-project reset boundary
  - phase: 114-startup-output-smoke-wrapper-docs
    provides: Docker-first demo lifecycle docs and smoke wrapper boundary
provides:
  - volume-preserving adoption demo stop helper
  - dry-run-first scoped adoption demo cleanup helper
  - source contracts for stop/reset/cleanup safety
affects: [phase-115, adoption-demo, repo-hygiene]

tech-stack:
  added: []
  patterns:
    - POSIX shell helpers under examples/adoption_demo/bin
    - ExUnit source contracts for Docker lifecycle safety

key-files:
  created:
    - examples/adoption_demo/bin/docker-stop
    - examples/adoption_demo/bin/docker-cleanup
  modified:
    - test/lockspire/adoption_demo_docker_contract_test.exs

key-decisions:
  - "Stop preserves active-project volumes by running project-scoped docker compose down without volume deletion flags."
  - "Cleanup is dry-run-first and deletes only exact active-project demo volumes plus three explicit generated artifact paths when --execute is supplied."
  - "tmp/admin-ui-polish/ remains preserved and outside default cleanup scope."

patterns-established:
  - "Lifecycle helpers resolve active project from --project, COMPOSE_PROJECT_NAME, then lockspire-adoption-demo."
  - "Destructive Docker cleanup uses exact allowlisted resource names rather than labels or host-wide prune commands."

requirements-completed: [CLEAN-01, CLEAN-02, CLEAN-03, HYGIENE-03, HYGIENE-04]

duration: 9min
completed: 2026-06-24
status: complete
---

# Phase 115 Plan 01: Lifecycle Cleanup Contracts Summary

**Contract-proven adoption demo stop and cleanup helpers with active-project Docker scoping and dry-run-first deletion safeguards.**

## Performance

- **Duration:** 9min
- **Started:** 2026-06-24T17:40:00Z
- **Completed:** 2026-06-24T17:48:52Z
- **Tasks:** 3
- **Files modified:** 3

## Accomplishments

- Added RED ExUnit contracts proving stop/reset/cleanup safety without requiring a Docker daemon for the new helper assertions.
- Added `examples/adoption_demo/bin/docker-stop`, preserving volumes while stopping only the resolved active Compose project.
- Added `examples/adoption_demo/bin/docker-cleanup`, defaulting to dry-run and requiring `--execute` before deleting exact active-project demo volumes and allowlisted generated artifacts.

## Task Commits

1. **Task 1: Add RED lifecycle safety contracts** - `09e978c` (test)
2. **Task 2: Implement docker-stop and preserve reset semantics** - `5ecae2e` (feat)
3. **Task 3: Implement dry-run-first scoped cleanup** - `19f07b9` (feat)

## Files Created/Modified

- `test/lockspire/adoption_demo_docker_contract_test.exs` - Added stop and cleanup source contracts for flags, allowlists, dry-run behavior, forbidden broad cleanup commands, and preserved admin UI evidence.
- `examples/adoption_demo/bin/docker-stop` - New executable helper for `--project` aware, volume-preserving Compose shutdown.
- `examples/adoption_demo/bin/docker-cleanup` - New executable helper for dry-run-first scoped cleanup with exact Docker volume and generated artifact allowlists.

## Decisions Made

- Followed the plan's split shell-script architecture; no Mix task, Makefile facade, runtime module, or production Lockspire surface was added.
- Kept `docker-reset` behavior unchanged and contract-proven as scoped to `db_data`, `deps_volume`, and `build_volume`.
- Did not use Docker labels as destructive selectors; cleanup removes only exact active-project volume names in execute mode.

## Deviations from Plan

None - plan executed exactly as written.

**Total deviations:** 0 auto-fixed.
**Impact on plan:** No scope changes.

## Issues Encountered

- The Task 2 helper help text initially used "preserving" while the RED contract asserted the literal word "preserve"; corrected before committing Task 2.
- The focused ExUnit command logs an existing KeyCache/TestRepo startup message, but the contract suite completes successfully with 25 tests and 0 failures.

## Verification

- `sh -n examples/adoption_demo/bin/docker-stop` - passed
- `sh -n examples/adoption_demo/bin/docker-reset` - passed
- `sh -n examples/adoption_demo/bin/docker-cleanup` - passed
- `mix test test/lockspire/adoption_demo_docker_contract_test.exs --seed 0` - passed, 25 tests, 0 failures
- `examples/adoption_demo/bin/docker-cleanup --project lockspire-adoption-demo-test` - dry-run printed exact candidate volumes/artifacts and did not require Docker or delete resources

## Known Stubs

None found in files created or modified by this plan.

## Threat Flags

No new unplanned threat surface. The planned maintainer shell-to-Docker/filesystem surface is mitigated by dry-run default cleanup, explicit `--execute`, exact active-project volume names, narrow generated-artifact allowlists, and source contracts forbidding host-wide Docker prune or broad Compose volume deletion.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 02 can build the repo hygiene gate on top of the committed lifecycle helpers and contracts. The unrelated pre-existing `.gitignore` modification was left untouched and uncommitted.

## Self-Check: PASSED

- Found `examples/adoption_demo/bin/docker-stop`.
- Found `examples/adoption_demo/bin/docker-cleanup`.
- Found `test/lockspire/adoption_demo_docker_contract_test.exs`.
- Verified commits `09e978c`, `5ecae2e`, and `19f07b9` in git history.
- Verified `.planning/phases/115-repo-hygiene-gate-scoped-cleanup/115-01-SUMMARY.md` exists after creation.

---
*Phase: 115-repo-hygiene-gate-scoped-cleanup*
*Completed: 2026-06-24*
