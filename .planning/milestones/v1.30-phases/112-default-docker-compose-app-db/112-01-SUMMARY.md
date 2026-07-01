---
phase: 112-default-docker-compose-app-db
plan: 01
subsystem: infra
tags: [docker, compose, postgres, adoption-demo]
requires:
  - phase: 111-demo-url-contract-config-unification
    provides: "LOCKSPIRE_DEMO_BASE_URL and LOCKSPIRE_DEMO_BIND_IP contract"
provides:
  - "Default direct Docker Compose topology with web plus PostgreSQL"
  - "Repo-root mounted development image workdir for adoption demo"
  - "Narrow repo-root Docker command in adoption demo docs"
affects: [adoption-demo, docker-dx, phase-113, phase-114]
tech-stack:
  added: []
  patterns: [repo-root compose mount, internal-only postgres, named build volumes]
key-files:
  created: []
  modified:
    - examples/adoption_demo/docker-compose.yml
    - examples/adoption_demo/Dockerfile.dev
    - docs/adoption-demo.md
key-decisions:
  - "Default Compose path is direct web plus PostgreSQL, not Traefik."
  - "The container mounts the repo root so the adoption demo path dependency on Lockspire resolves."
patterns-established:
  - "Compose renders from repo root with `docker compose -f examples/adoption_demo/docker-compose.yml ...`."
  - "Postgres stays internal-only by default; no host 5432 binding."
requirements-completed: [DOCKER-01, DOCKER-02, DOCKER-03, DOCKER-04]
duration: 8min
completed: 2026-06-04
---

# Phase 112: Default Docker Compose App + DB Summary

**Direct Docker Compose adoption-demo stack with Phoenix/Bandit web, internal PostgreSQL, and isolated container build volumes**

## Performance

- **Duration:** 8 min
- **Started:** 2026-06-04T18:52:51Z
- **Completed:** 2026-06-04T19:00:00Z
- **Tasks:** 3
- **Files modified:** 3

## Accomplishments

- Converted the demo Compose file to a direct `web` plus `db` default stack with PostgreSQL 14.
- Wired explicit `LOCKSPIRE_DEMO_DB_*`, `LOCKSPIRE_DEMO_BASE_URL`, and `LOCKSPIRE_DEMO_BIND_IP` values.
- Preserved container-local `deps` and `_build` volumes while mounting the repo root for the local path dependency.
- Added the narrow repo-root Docker command to `docs/adoption-demo.md`.

## Task Commits

Each task was committed atomically:

1. **Task 1: Convert Compose to direct web plus PostgreSQL default** - `0bf5183`
2. **Task 2: Make the development image work from a repo-root mount** - `a4d5d1b`
3. **Task 3: Document the narrow repo-root Docker command** - `595155c`

## Files Created/Modified

- `examples/adoption_demo/docker-compose.yml` - Default direct web plus PostgreSQL Compose stack.
- `examples/adoption_demo/Dockerfile.dev` - Uses `/workspace/examples/adoption_demo` as the image workdir.
- `docs/adoption-demo.md` - Documents the repo-root Docker command and direct URL.

## Decisions Made

Followed the plan as specified. The default path no longer requires Traefik, and PostgreSQL does not publish host port `5432`.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required beyond Docker for running the demo.

## Verification

- `docker compose -f examples/adoption_demo/docker-compose.yml config >/tmp/lockspire-phase112-compose.yml`
- `rg -n "^  web:|^  db:|postgres:14|LOCKSPIRE_DEMO_DB_HOST: db|LOCKSPIRE_DEMO_BIND_IP: 0\\.0\\.0\\.0|LOCKSPIRE_DEMO_BASE_URL: http://127\\.0\\.0\\.1:4100|pg_isready" /tmp/lockspire-phase112-compose.yml`
- `test "$(rg -n "5432:5432|local-dev-proxy|traefik\\.http" /tmp/lockspire-phase112-compose.yml | wc -l | tr -d ' ')" = "0"`
- `rg -n "WORKDIR /workspace/examples/adoption_demo|mix local.hex --force|mix local.rebar --force" examples/adoption_demo/Dockerfile.dev`
- `rg -n "docker compose -f examples/adoption_demo/docker-compose.yml up --build|http://127\\.0\\.0\\.1:4100|host-local|mix deps.get|mix ecto.setup|mix phx.server" docs/adoption-demo.md`

## Self-Check: PASSED

All Plan 112-01 acceptance criteria and plan-level verification commands passed.

## Next Phase Readiness

Plan 112-02 can now wire startup/readiness through the default Compose `web` service.

---
*Phase: 112-default-docker-compose-app-db*
*Completed: 2026-06-04*
