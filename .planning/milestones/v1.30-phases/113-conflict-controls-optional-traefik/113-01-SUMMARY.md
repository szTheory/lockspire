---
phase: 113-conflict-controls-optional-traefik
plan: 01
subsystem: infra
tags: [docker-compose, adoption-demo, docs, exunit]

requires:
  - phase: 111-demo-url-contract-config-unification
    provides: LOCKSPIRE_DEMO_BASE_URL browser-visible URL contract
  - phase: 112-default-docker-compose-app-db
    provides: direct Docker app plus PostgreSQL adoption demo topology
provides:
  - Direct Docker Compose project-name, app-port, and DB host exposure controls
  - Scoped adoption-demo Docker reset helper for active project volumes
  - Contract tests for direct Compose conflict controls and reset/docs truth
affects: [adoption-demo, docker-dx, phase-114-startup-output, phase-115-repo-hygiene]

tech-stack:
  added: []
  patterns:
    - Docker Compose interpolation for demo-scoped app and DB host ports
    - ExUnit contract tests invoking docker compose config --format json
    - POSIX shell reset helper scoped to active Compose project volumes

key-files:
  created:
    - examples/adoption_demo/docker-compose.db-host.yml
    - examples/adoption_demo/bin/docker-reset
    - test/lockspire/adoption_demo_docker_contract_test.exs
  modified:
    - examples/adoption_demo/docker-compose.yml
    - docs/adoption-demo.md

key-decisions:
  - "Kept direct Docker as the default path and used Compose project-name precedence for resource isolation."
  - "Kept PostgreSQL host-port exposure absent by default and isolated it in an explicit override file."
  - "Kept LOCKSPIRE_DEMO_BASE_URL as the browser-visible URL truth for alternate ports and smoke proof."
  - "Reset removes only active-project db_data, deps_volume, and build_volume resources."

patterns-established:
  - "Compose conflict controls are verified by rendering JSON, not by starting containers."
  - "Demo reset helpers must target active project resources and avoid global Docker prune behavior."

requirements-completed: [CONFLICT-01, CONFLICT-02, CONFLICT-03, CONFLICT-04]

duration: 6min
completed: 2026-06-04
---

# Phase 113 Plan 01: Direct Docker Conflict Controls Summary

**Direct Docker adoption-demo conflict controls using Compose interpolation, opt-in DB host exposure, and active-project scoped reset.**

## Performance

- **Duration:** 6 min
- **Started:** 2026-06-04T21:09:11Z
- **Completed:** 2026-06-04T21:14:46Z
- **Tasks:** 3
- **Files modified:** 5

## Accomplishments

- Added deterministic ExUnit contract coverage for default and overridden Compose project names, app-port/base-URL alignment, default DB isolation, opt-in DB host exposure, reset helper scope, and docs truth.
- Updated the direct Docker Compose topology with top-level `name: lockspire-adoption-demo`, configurable `LOCKSPIRE_DEMO_APP_PORT`, and `LOCKSPIRE_DEMO_BASE_URL` interpolation.
- Added `examples/adoption_demo/docker-compose.db-host.yml` so host PostgreSQL access is explicit and configurable through `LOCKSPIRE_DEMO_DB_HOST_PORT`.
- Added executable `examples/adoption_demo/bin/docker-reset` that stops the active project and removes only `db_data`, `deps_volume`, and `build_volume`.
- Updated `docs/adoption-demo.md` with narrow conflict-control, alternate-port smoke, DB host override, and scoped reset instructions.

## Task Commits

Each task was committed atomically:

1. **Task 1 RED: Add direct Compose and DB exposure contract tests** - `7e3eccc` (test)
2. **Task 2 GREEN: Implement direct Compose port controls and opt-in DB host override** - `c7f38c5` (feat)
3. **Task 3 RED: Add reset helper and docs contracts** - `45a2edd` (test)
4. **Task 3 GREEN: Add active-project reset helper and narrow docs** - `3afdf61` (feat)

_Note: TDD tasks produced RED/GREEN commits. Task 3's implementation did not need a separate refactor commit._

## Files Created/Modified

- `examples/adoption_demo/docker-compose.yml` - Adds default Compose project name and interpolated app port/base URL.
- `examples/adoption_demo/docker-compose.db-host.yml` - Adds optional DB host-port override using `LOCKSPIRE_DEMO_DB_HOST_PORT`.
- `examples/adoption_demo/bin/docker-reset` - Adds active-project scoped reset helper.
- `docs/adoption-demo.md` - Documents project, port, base URL, DB override, smoke, and reset controls.
- `test/lockspire/adoption_demo_docker_contract_test.exs` - Adds Compose/render, reset-helper, and docs contract tests.

## Decisions Made

- Used top-level Compose `name: lockspire-adoption-demo` while preserving standard `--project-name` and `COMPOSE_PROJECT_NAME` overrides.
- Kept the app's internal database port as `5432`; only maintainer host access uses the DB override.
- Kept reset behavior explicit and allowlisted instead of using `docker compose down -v` or prune commands.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Relaxed rendered port assertions for Compose metadata**
- **Found during:** Task 2 (Implement direct Compose port controls and opt-in DB host override)
- **Issue:** Docker Compose renders port objects with extra `mode` and `protocol` keys, so exact map membership assertions failed even though the published and target ports were correct.
- **Fix:** Replaced exact map membership with `assert_port/3`, which checks the relevant `published` and `target` pair.
- **Files modified:** `test/lockspire/adoption_demo_docker_contract_test.exs`
- **Verification:** `mix test test/lockspire/adoption_demo_docker_contract_test.exs --seed 0` passed with 5 tests at Task 2 and 7 tests after Task 3.
- **Committed in:** `c7f38c5`

---

**Total deviations:** 1 auto-fixed (Rule 1)
**Impact on plan:** The auto-fix corrected the contract test to match Docker Compose's rendered JSON shape without changing planned behavior.

## Issues Encountered

- `mix test` and `mix test.fast` emitted pre-existing transient repo/log messages from `KeyCache`, Oban/Postgres, and normal debug SQL output, but both verification commands completed with zero failures.

## User Setup Required

None - no external service configuration required.

## Verification

- `mix test test/lockspire/adoption_demo_docker_contract_test.exs --seed 0` - passed, 7 tests, 0 failures.
- `docker compose -f examples/adoption_demo/docker-compose.yml config --format json >/tmp/lockspire-phase113-direct.json` - passed.
- `LOCKSPIRE_DEMO_APP_PORT=4101 LOCKSPIRE_DEMO_BASE_URL=http://127.0.0.1:4101 docker compose --project-name lockspire-adoption-demo-alt -f examples/adoption_demo/docker-compose.yml config --format json >/tmp/lockspire-phase113-direct-alt.json` - passed.
- `LOCKSPIRE_DEMO_DB_HOST_PORT=15432 docker compose -f examples/adoption_demo/docker-compose.yml -f examples/adoption_demo/docker-compose.db-host.yml config --format json >/tmp/lockspire-phase113-db-host.json` - passed.
- `sh -n examples/adoption_demo/bin/docker-reset` - passed.
- `mix test.fast` - passed, 1081 tests, 0 failures, 287 excluded.

## Known Stubs

None.

## Next Phase Readiness

Phase 113 Plan 02 can add optional Traefik routing on top of the direct Docker controls. Phase 114 can consume the documented `LOCKSPIRE_DEMO_BASE_URL` and port controls for startup output and smoke wrappers.

## Self-Check: PASSED

- Found created files: `examples/adoption_demo/docker-compose.db-host.yml`, `examples/adoption_demo/bin/docker-reset`, `test/lockspire/adoption_demo_docker_contract_test.exs`, and this summary.
- Found task commits: `7e3eccc`, `c7f38c5`, `45a2edd`, and `3afdf61`.

---
*Phase: 113-conflict-controls-optional-traefik*
*Completed: 2026-06-04*
