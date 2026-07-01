---
phase: 114-startup-output-smoke-wrapper-docs
plan: 01
subsystem: demo-dx
tags: [docker, shell, adoption-demo, redaction, exunit]

requires:
  - phase: 111-demo-url-contract-config-unification
    provides: LOCKSPIRE_DEMO_BASE_URL as the browser-visible demo URL truth
  - phase: 112-default-docker-compose-app-db
    provides: Docker startup path with HTTP readiness proof
  - phase: 113-conflict-controls-optional-traefik
    provides: direct Docker default and optional Traefik routing posture
provides:
  - Redacted adoption-demo startup information printer
  - Docker startup integration after HTTP readiness
  - Contract tests for INFO-01, INFO-02, and INFO-03
affects: [phase-114, adoption-demo, docker-startup-output, smoke-wrapper-docs]

tech-stack:
  added: []
  patterns:
    - POSIX shell startup helper with static allowlisted demo output
    - ExUnit source/output contracts for redacted maintainer-facing logs

key-files:
  created:
    - examples/adoption_demo/bin/docker-info
  modified:
    - examples/adoption_demo/bin/docker-start
    - test/lockspire/adoption_demo_docker_contract_test.exs

key-decisions:
  - "docker-info uses static allowlisted fixture truth instead of database inspection or seed stdout."
  - "docker-start prints startup information only after wait_for_http succeeds."
  - "LOCKSPIRE_DEMO_BASE_URL remains the single source for all printed public demo URLs."

patterns-established:
  - "Startup output redaction is enforced against both script source and rendered output."
  - "Maintainer-local demo banners may print account emails and client IDs, but not secret, token, private key, code, or cookie material."

requirements-completed: [INFO-01, INFO-02, INFO-03]

duration: 5min
completed: 2026-06-24
status: complete
---

# Phase 114 Plan 01: Startup Info Output Summary

**Redacted Docker startup information now prints the active demo URLs, seeded account/client allowlists, and exact smoke command after HTTP readiness.**

## Performance

- **Duration:** 5 min
- **Started:** 2026-06-24T16:42:00Z
- **Completed:** 2026-06-24T16:44:21Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments

- Added `examples/adoption_demo/bin/docker-info`, an executable POSIX shell helper that derives every printed URL from trimmed `LOCKSPIRE_DEMO_BASE_URL`.
- Updated `examples/adoption_demo/bin/docker-start` to call `./bin/docker-info` only after `wait_for_http` succeeds.
- Added deterministic ExUnit contracts for INFO-01 URL/smoke output, INFO-02 seeded account output, and INFO-03 client allowlist/redaction behavior.

## Task Commits

Each task was committed atomically:

1. **Task 1: Add contract tests for redacted docker-info output** - `cc1a6d1` (test)
2. **Task 2: Implement docker-info and call it after startup readiness** - `3e09e4e` (feat)

**Plan metadata:** summary commit follows this file.

## Files Created/Modified

- `examples/adoption_demo/bin/docker-info` - Prints ready banner, URLs, seeded account allowlist, seeded OAuth client safe shapes, and exact smoke command.
- `examples/adoption_demo/bin/docker-start` - Calls `./bin/docker-info` after public HTTP readiness.
- `test/lockspire/adoption_demo_docker_contract_test.exs` - Adds source/output contracts for startup info, redaction, and startup ordering.

## Decisions Made

- Used static allowlisted fixture truth for accounts and clients rather than reading database rows or replaying seed output.
- Kept the helper dependency-free and POSIX-shell compatible with the existing adoption-demo scripts.
- Treated startup logs as copyable maintainer output, so tests reject secret-like seed values and sensitive storage field names in both source and rendered output.

## Deviations from Plan

None - plan executed as written.

## Issues Encountered

- The RED test run failed as intended because `examples/adoption_demo/bin/docker-info` did not exist yet.
- Focused ExUnit runs emitted a pre-existing asynchronous KeyCache refresh log about `Lockspire.TestRepo` not being started, but the contract test command completed successfully after implementation with 15 tests and 0 failures.

## Known Stubs

None.

## User Setup Required

None - no external service configuration required.

## Verification

- `mix test test/lockspire/adoption_demo_docker_contract_test.exs --seed 0` failed before implementation because `examples/adoption_demo/bin/docker-info` did not exist.
- `sh -n examples/adoption_demo/bin/docker-info` passed.
- `sh -n examples/adoption_demo/bin/docker-start` passed.
- `test -x examples/adoption_demo/bin/docker-info` passed.
- `LOCKSPIRE_DEMO_BASE_URL=http://127.0.0.1:4101/ examples/adoption_demo/bin/docker-info` printed all INFO-01 URLs using `http://127.0.0.1:4101`.
- Redaction grep for demo secrets, token hashes, private JWK material, authorization-code material, refresh/access token material, and cookie material passed.
- Final focused test command passed: `mix test test/lockspire/adoption_demo_docker_contract_test.exs --seed 0` with 15 tests, 0 failures.

## Next Phase Readiness

Plan 02 can build on the reusable `docker-info` command for reprint proof and smoke wrapper work. No blockers remain for Phase 114 follow-on plans.

## Self-Check: PASSED

- Created file exists: `examples/adoption_demo/bin/docker-info`.
- Modified files exist: `examples/adoption_demo/bin/docker-start`, `test/lockspire/adoption_demo_docker_contract_test.exs`.
- Task commits found: `cc1a6d1`, `3e09e4e`.
- Plan verification passed after implementation.

---
*Phase: 114-startup-output-smoke-wrapper-docs*
*Completed: 2026-06-24*
