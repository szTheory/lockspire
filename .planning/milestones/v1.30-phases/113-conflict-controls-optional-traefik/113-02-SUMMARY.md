---
phase: 113-conflict-controls-optional-traefik
plan: 02
subsystem: infra
tags: [docker-compose, traefik, adoption-demo, docs, exunit]

requires:
  - phase: 113-conflict-controls-optional-traefik
    provides: Direct Docker conflict controls from Plan 01
provides:
  - Opt-in Traefik override for adoption-demo hostname routing
  - Contract tests proving default Compose remains Traefik-free
  - Contract tests proving configurable Traefik labels and web-only proxy network membership
  - Optional Traefik setup and hostname smoke documentation
affects: [adoption-demo, docker-dx, phase-114-startup-output, phase-115-repo-hygiene]

tech-stack:
  added: []
  patterns:
    - Docker Compose override file for optional Traefik routing
    - Equal-sign Traefik labels for interpolated router and service names
    - Compose JSON contract tests for optional proxy network isolation

key-files:
  created:
    - examples/adoption_demo/docker-compose.traefik.yml
  modified:
    - docs/adoption-demo.md
    - test/lockspire/adoption_demo_docker_contract_test.exs

key-decisions:
  - "Kept direct Docker as the default path with no Traefik labels or external proxy network dependency."
  - "Used an explicit docker-compose.traefik.yml override instead of modifying the default Compose path."
  - "Attached only web to the external Traefik proxy network while keeping db project-internal."
  - "Kept LOCKSPIRE_DEMO_BASE_URL as the hostname smoke truth for Traefik mode."

patterns-established:
  - "Optional Traefik routing belongs in a Compose override, not the default demo topology."
  - "Interpolated Traefik router/service labels use equal-sign list syntax and are verified by docker compose config JSON."

requirements-completed: [TRAEFIK-01, TRAEFIK-02, CONFLICT-02]

duration: 4min
completed: 2026-06-04
---

# Phase 113 Plan 02: Optional Traefik Routing Summary

**Opt-in Traefik hostname routing for the adoption demo with configurable labels, web-only proxy network membership, and hostname-based smoke docs.**

## Performance

- **Duration:** 4 min
- **Started:** 2026-06-04T21:18:35Z
- **Completed:** 2026-06-04T21:21:43Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments

- Added RED contract coverage proving the default adoption-demo Compose file has no Traefik labels or external proxy network dependency.
- Added RED/GREEN contract coverage for configurable Traefik hostname, router, service, proxy network, and explicit backend service port labels.
- Added `examples/adoption_demo/docker-compose.traefik.yml` as an explicit opt-in override that attaches only `web` to the external proxy network.
- Updated adoption-demo docs with optional network creation, repo-local Traefik helper startup, override startup, env var defaults, and hostname smoke command.

## Task Commits

Each task was committed atomically:

1. **Task 1 RED: Add Traefik opt-in contract tests** - `26dcd45` (test)
2. **Task 2 GREEN: Create opt-in Traefik override and documentation** - `8b0b1ae` (feat)

_Note: Task 1 was intentionally committed with failing tests per TDD RED. Task 2 made the same focused suite pass._

## Files Created/Modified

- `examples/adoption_demo/docker-compose.traefik.yml` - Adds optional Traefik labels and external proxy network membership for `web`.
- `docs/adoption-demo.md` - Documents optional Traefik network setup, helper startup, override startup, env vars, and hostname smoke command.
- `test/lockspire/adoption_demo_docker_contract_test.exs` - Adds default no-Traefik, opt-in label, web-only network, and docs contract tests.

## Decisions Made

- Used an explicit override file instead of a profile so default Compose rendering stays independent of the external Traefik network.
- Kept `web` on the default internal network as well as the proxy network so app-to-DB connectivity remains intact.
- Kept Traefik setup local-DX-only and did not add production deployment guidance or hosted-auth service claims.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- `mix test.fast` could not create `Lockspire.TestRepo` because the shared local Postgres instance was already at `too_many_connections` from unrelated `/Users/jon/projects/scoria` Mix/BEAM processes. No Lockspire code changes were made for that environmental issue. Focused plan tests and Compose render proof passed.

## User Setup Required

None - no external service configuration required for the default Docker path. Optional Traefik use requires the documented local proxy network/helper setup.

## Verification

- `mix test test/lockspire/adoption_demo_docker_contract_test.exs --seed 0` - passed, 11 tests, 0 failures.
- `docker compose -f examples/adoption_demo/docker-compose.yml config --format json >/tmp/lockspire-phase113-default-no-traefik.json` - passed.
- `LOCKSPIRE_DEMO_APP_PORT=4102 LOCKSPIRE_DEMO_BASE_URL=http://lockspire-alt.localhost LOCKSPIRE_DEMO_TRAEFIK_HOST=lockspire-alt.localhost LOCKSPIRE_DEMO_TRAEFIK_ROUTER=lockspire-alt-router LOCKSPIRE_DEMO_TRAEFIK_SERVICE=lockspire-alt-service LOCKSPIRE_DEMO_TRAEFIK_NETWORK=lockspire-alt-proxy docker compose -f examples/adoption_demo/docker-compose.yml -f examples/adoption_demo/docker-compose.traefik.yml config --format json >/tmp/lockspire-phase113-traefik.json` - passed.
- `rg -n "docker-compose\\.traefik\\.yml|LOCKSPIRE_DEMO_TRAEFIK_HOST|LOCKSPIRE_DEMO_TRAEFIK_ROUTER|LOCKSPIRE_DEMO_TRAEFIK_SERVICE|LOCKSPIRE_DEMO_TRAEFIK_NETWORK|lockspire-demo\\.localhost|adoption_smoke\\.py" docs/adoption-demo.md` - passed.
- `mix test.fast` - blocked by external local Postgres connection exhaustion (`FATAL 53300 too_many_connections`) before the suite could create `Lockspire.TestRepo`.

## Known Stubs

None.

## Next Phase Readiness

Phase 114 can consume the documented `LOCKSPIRE_DEMO_BASE_URL` hostname smoke pattern when adding startup output and smoke wrappers. Before treating the whole repo as regression-green, rerun `mix test.fast` after the unrelated local Postgres connection pressure drains.

## Self-Check: PASSED

- Found created file: `examples/adoption_demo/docker-compose.traefik.yml`.
- Found modified files: `docs/adoption-demo.md` and `test/lockspire/adoption_demo_docker_contract_test.exs`.
- Found task commits: `26dcd45` and `8b0b1ae`.

---
*Phase: 113-conflict-controls-optional-traefik*
*Completed: 2026-06-04*
