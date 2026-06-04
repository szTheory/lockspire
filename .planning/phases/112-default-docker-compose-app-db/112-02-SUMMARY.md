---
phase: 112-default-docker-compose-app-db
plan: 02
subsystem: infra
tags: [docker, compose, postgres, readiness, adoption-demo]
requires:
  - phase: 112-default-docker-compose-app-db
    provides: "Plan 112-01 default Compose topology"
provides:
  - "Idempotent Docker startup wrapper for adoption demo"
  - "HTTP readiness wait before Docker ready line"
  - "Runtime proof that direct Docker smoke passes"
affects: [adoption-demo, docker-dx, phase-113, phase-114, phase-115]
tech-stack:
  added: []
  patterns: [bounded shell readiness loops, minimal startup output, direct compose smoke proof]
key-files:
  created:
    - examples/adoption_demo/bin/docker-start
  modified:
    - examples/adoption_demo/docker-compose.yml
    - examples/adoption_demo/Dockerfile.dev
key-decisions:
  - "Startup wrapper tolerates an already-created database but fails on real setup errors."
  - "Seed stdout is suppressed during Docker startup unless seeding fails, preserving Phase 112 minimal output."
patterns-established:
  - "Docker startup uses `LOCKSPIRE_DEMO_BASE_URL` for public HTTP readiness."
  - "Runtime proof runs direct Compose startup plus existing `scripts/demo/adoption_smoke.py`."
requirements-completed: [DOCKER-05, DOCKER-06]
duration: 18min
completed: 2026-06-04
---

# Phase 112: Default Docker Compose App + DB Summary

**Idempotent Docker startup wrapper with Postgres wait, database prepare, public HTTP readiness, and direct smoke proof**

## Performance

- **Duration:** 18 min
- **Started:** 2026-06-04T19:00:00Z
- **Completed:** 2026-06-04T19:05:00Z
- **Tasks:** 3
- **Files modified:** 3

## Accomplishments

- Added `examples/adoption_demo/bin/docker-start` to wait for Postgres, fetch deps, create/reuse the DB, migrate, seed, start Phoenix, and wait for HTTP readiness.
- Wired Compose `web` to run the startup wrapper.
- Proved the direct Docker stack reaches `Adoption demo ready at http://127.0.0.1:4100`.
- Ran the existing black-box smoke against the direct Docker URL successfully.

## Task Commits

Each task was committed atomically:

1. **Task 1: Add demo-owned Docker startup wrapper** - `420afc6`
2. **Task 2: Wire Compose web startup to the wrapper** - `01c061d`
3. **Task 3: Prove Docker startup locally when Docker is available** - runtime proof, no source commit

Additional deviation commits:

- `01bfe4a` - switched Dockerfile to an available HexPM Elixir image tag.
- `67cd5e6` - suppressed seed stdout to keep Docker startup output minimal.

## Files Created/Modified

- `examples/adoption_demo/bin/docker-start` - Docker startup and readiness wrapper.
- `examples/adoption_demo/docker-compose.yml` - Web service runs `./bin/docker-start`.
- `examples/adoption_demo/Dockerfile.dev` - Uses a valid Elixir 1.18.4 / OTP 28.5 image and includes `curl` plus `postgresql-client`.

## Decisions Made

- Used `hexpm/elixir:1.18.4-erlang-28.5-ubuntu-noble-20260509.1` because the previous `hexpm/elixir:1.15.7-erlang-26.1.2-alpine` tag no longer resolves.
- Suppressed seed stdout in Docker startup so Phase 112 reports only minimal readiness output; Phase 114 still owns the deliberate account/client/banner output.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] Added readiness utilities to the image**
- **Found during:** Task 1
- **Issue:** The startup wrapper requires `pg_isready` and `curl`, but the image did not include PostgreSQL client utilities or curl.
- **Fix:** Added `curl` and `postgresql-client` to `examples/adoption_demo/Dockerfile.dev`.
- **Files modified:** `examples/adoption_demo/Dockerfile.dev`
- **Verification:** `rg -n "curl postgresql-client|WORKDIR /workspace/examples/adoption_demo" examples/adoption_demo/Dockerfile.dev`
- **Committed in:** `420afc6`

**2. [Rule 3 - Blocking] Replaced unavailable Docker base image**
- **Found during:** Task 3
- **Issue:** `docker compose up --build` failed because `hexpm/elixir:1.15.7-erlang-26.1.2-alpine` no longer exists.
- **Fix:** Switched to `hexpm/elixir:1.18.4-erlang-28.5-ubuntu-noble-20260509.1` and replaced `apk` with noninteractive `apt-get` package installation.
- **Files modified:** `examples/adoption_demo/Dockerfile.dev`
- **Verification:** `docker manifest inspect hexpm/elixir:1.18.4-erlang-28.5-ubuntu-noble-20260509.1`
- **Committed in:** `01bfe4a`

**3. [Rule 2 - Missing Critical] Suppressed seed stdout during Docker startup**
- **Found during:** Task 3 runtime proof
- **Issue:** The startup wrapper itself printed only a ready line, but `mix run priv/repo/seeds.exs` printed existing account/client output during startup.
- **Fix:** Wrapped seed execution and suppressed stdout unless seeding fails.
- **Files modified:** `examples/adoption_demo/bin/docker-start`
- **Verification:** `sh -n examples/adoption_demo/bin/docker-start` and direct Docker smoke proof.
- **Committed in:** `67cd5e6`

---

**Total deviations:** 3 auto-fixed.
**Impact on plan:** All deviations were necessary to satisfy the Docker startup and readiness contract without expanding Phase 112 scope.

## Issues Encountered

- First Docker build failed on the unavailable legacy HexPM image tag; fixed by switching to a valid current HexPM tag.
- Non-TTY Compose process could not be interrupted through stdin; stopped cleanly with `docker compose -f examples/adoption_demo/docker-compose.yml down`.

## User Setup Required

None - no external service configuration required beyond Docker for running the demo.

## Verification

- `test -x examples/adoption_demo/bin/docker-start`
- `sh -n examples/adoption_demo/bin/docker-start`
- `docker compose -f examples/adoption_demo/docker-compose.yml config >/tmp/lockspire-phase112-compose.yml`
- `docker compose -f examples/adoption_demo/docker-compose.yml up --build`
- Compose log contained `Adoption demo ready at http://127.0.0.1:4100`
- `LOCKSPIRE_DEMO_BASE_URL=http://127.0.0.1:4100 python3 scripts/demo/adoption_smoke.py`
- Smoke output: `adoption demo smoke passed`
- `docker compose -f examples/adoption_demo/docker-compose.yml down`

## Self-Check: PASSED

All Plan 112-02 acceptance criteria and plan-level verification commands passed. Docker runtime proof was completed locally and the direct smoke passed.

## Next Phase Readiness

Phase 113 can build on a working direct Docker path for configurable project names, ports, scoped cache reset, and optional Traefik.

---
*Phase: 112-default-docker-compose-app-db*
*Completed: 2026-06-04*
