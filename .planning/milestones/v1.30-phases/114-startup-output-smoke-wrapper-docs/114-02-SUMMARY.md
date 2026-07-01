---
phase: 114-startup-output-smoke-wrapper-docs
plan: 02
subsystem: demo-dx
tags: [docker, shell, smoke, adoption-demo, exunit]

requires:
  - phase: 114-startup-output-smoke-wrapper-docs
    provides: Plan 01 docker-info startup output and redaction posture
  - phase: 112-default-docker-compose-app-db
    provides: Direct Docker startup path and black-box smoke proof
  - phase: 113-conflict-controls-optional-traefik
    provides: Optional Traefik hostname URL posture
provides:
  - Thin adoption smoke wrapper for direct Docker and optional hostname targets
  - Reprint command truth for running Docker web service
  - Contract tests proving wrapper delegation and no duplicated OAuth proof logic
affects: [phase-114, adoption-demo, docker-smoke, demo-docs]

tech-stack:
  added: []
  patterns:
    - POSIX shell wrapper delegates to existing Python smoke with normalized LOCKSPIRE_DEMO_BASE_URL
    - Source contracts keep OAuth/OIDC proof logic in the Python black-box smoke

key-files:
  created:
    - scripts/demo/adoption_smoke.sh
  modified:
    - examples/adoption_demo/bin/docker-info
    - test/lockspire/adoption_demo_docker_contract_test.exs

key-decisions:
  - "Kept scripts/demo/adoption_smoke.py as the only black-box OAuth/OIDC proof implementation."
  - "Used LOCKSPIRE_DEMO_BASE_URL as the only switch between direct Docker and optional Traefik hostname smoke."
  - "Recorded INFO-04 reprint truth as docker compose exec against the running web service."

patterns-established:
  - "Maintainer smoke wrappers may normalize and echo the target URL, then must exec the existing Python smoke."
  - "Reprint commands for startup information target a running container with docker compose exec, not container recreation."

requirements-completed: [INFO-04, SMOKE-01, SMOKE-02]

duration: 4min
completed: 2026-06-24
status: complete
---

# Phase 114 Plan 02: Smoke Wrapper Summary

**Thin base-URL-driven smoke wrapper now delegates to the existing Python OAuth/OIDC proof and docker-info prints the running-service reprint command.**

## Performance

- **Duration:** 4 min
- **Started:** 2026-06-24T16:47:57Z
- **Completed:** 2026-06-24T16:51:10Z
- **Tasks:** 3
- **Files modified:** 3

## Accomplishments

- Added `scripts/demo/adoption_smoke.sh`, an executable POSIX shell wrapper that trims `LOCKSPIRE_DEMO_BASE_URL`, prints the active target, and `exec`s `scripts/demo/adoption_smoke.py`.
- Added `docker compose -f examples/adoption_demo/docker-compose.yml exec web ./bin/docker-info` to `docker-info` as the canonical INFO-04 reprint command.
- Expanded adoption demo Docker contracts to prove wrapper delegation, default direct URL behavior, hostname URL help text, and absence of shell-side OAuth callback/token/cookie/CSRF/device parsing.
- Ran direct Docker smoke through the new wrapper against `http://127.0.0.1:4100`; it passed with `adoption demo smoke passed`.

## Task Commits

Each task was committed atomically:

1. **Task 1: Add contract tests for reprint and smoke wrapper behavior** - `8c02f7f` (test)
2. **Task 2: Implement thin adoption smoke wrapper** - `34a8398` (feat)
3. **Task 3: Record direct and optional Traefik smoke verification commands** - `1899e7f` (chore, verification-only empty commit)

**Plan metadata:** summary/state commit follows this file.

## Files Created/Modified

- `scripts/demo/adoption_smoke.sh` - Base-URL-normalizing shell wrapper that delegates to `scripts/demo/adoption_smoke.py`.
- `examples/adoption_demo/bin/docker-info` - Prints the canonical running-container reprint command.
- `test/lockspire/adoption_demo_docker_contract_test.exs` - Adds reprint and wrapper source contracts.

## Decisions Made

- Kept the wrapper free of OAuth/OIDC flow parsing; the Python script remains the single black-box proof implementation.
- Used `LOCKSPIRE_DEMO_BASE_URL` as the only runtime switch for direct Docker versus optional Traefik hostname smoke.
- Left optional Traefik runtime smoke manual because `local-dev-proxy` existed but no Traefik container was running on that network.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Relaxed wrapper contract to accept safe quoted env assignment**
- **Found during:** Task 2 (Implement thin adoption smoke wrapper)
- **Issue:** The RED contract required the exact unquoted text `LOCKSPIRE_DEMO_BASE_URL=${BASE_URL}`, but the implementation correctly used the safer quoted shell form `LOCKSPIRE_DEMO_BASE_URL="${BASE_URL}"`.
- **Fix:** Updated the contract regex to allow optional quotes while still requiring the normalized `BASE_URL` value to be passed to Python.
- **Files modified:** `test/lockspire/adoption_demo_docker_contract_test.exs`
- **Verification:** `mix test test/lockspire/adoption_demo_docker_contract_test.exs --seed 0`
- **Committed in:** `34a8398`

---

**Total deviations:** 1 auto-fixed (Rule 1).
**Impact on plan:** The deviation corrected an over-specific test assertion without widening wrapper behavior or changing the security posture.

## Issues Encountered

- RED failed as intended before implementation because `scripts/demo/adoption_smoke.sh` did not exist and `docker-info` lacked the `Reprint:` command.
- Focused ExUnit runs emitted the pre-existing asynchronous KeyCache refresh log about `Lockspire.TestRepo` not being started; the contract test command completed successfully with 18 tests and 0 failures.
- Docker build output was noisy because the local development image installed Ubuntu packages during the first build, but the direct wrapper smoke completed successfully and the cleanup trap stopped the stack.

## Known Stubs

None.

## Threat Flags

None.

## User Setup Required

None for direct Docker smoke beyond Docker itself. Optional Traefik smoke still requires a running local Traefik proxy attached to `local-dev-proxy`.

## Verification

- RED: `mix test test/lockspire/adoption_demo_docker_contract_test.exs --seed 0` failed before implementation with missing wrapper and missing reprint command assertions.
- `sh -n scripts/demo/adoption_smoke.sh` passed.
- `test -x scripts/demo/adoption_smoke.sh` passed.
- `python3 -m py_compile scripts/demo/adoption_smoke.py` passed.
- `mix test test/lockspire/adoption_demo_docker_contract_test.exs --seed 0` passed with 18 tests, 0 failures.
- `LOCKSPIRE_DEMO_BASE_URL=http://lockspire-demo.localhost scripts/demo/adoption_smoke.sh --help` printed the hostname-mode command using the same env var and no Traefik-specific flag.
- Direct Docker smoke ran with `LOCKSPIRE_DEMO_BASE_URL=http://127.0.0.1:4100 scripts/demo/adoption_smoke.sh` and printed `adoption demo smoke passed`.
- Optional Traefik smoke was not run because no container was attached to `local-dev-proxy`; manual command remains `LOCKSPIRE_DEMO_BASE_URL=http://lockspire-demo.localhost scripts/demo/adoption_smoke.sh`.
- No CI workflow files were modified.

## Next Phase Readiness

Plan 03 can document the default Docker startup, reprint, smoke, stop/reset/cleanup, optional Traefik, and troubleshooting flows using the stable wrapper and reprint command added here.

## Self-Check: PASSED

- Created file exists: `scripts/demo/adoption_smoke.sh`.
- Modified files exist: `examples/adoption_demo/bin/docker-info`, `test/lockspire/adoption_demo_docker_contract_test.exs`.
- Task commits found: `8c02f7f`, `34a8398`, `1899e7f`.
- Final non-Docker verification passed.
- Direct Docker wrapper smoke passed and stack cleanup completed.

---
*Phase: 114-startup-output-smoke-wrapper-docs*
*Completed: 2026-06-24*
