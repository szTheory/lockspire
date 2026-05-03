---
phase: S02
plan: 01
subsystem: database
tags: [oban, ecto, cron, telemetry, background-job]

requires: []
provides:
  - Configurable Oban Cron setup for background job scheduling.
  - Tail-recursive chunked deletion logic in Ecto for safe pruning.
  - Pruner Oban Worker to delete expired records across 6 security schemas.
  - Telemetry emission for deleted row counts per model.
affects: [security, compliance]

tech-stack:
  added: []
  patterns: [Oban Cron configuration, Ecto tail-recursive batch deletion, Oban telemetry emission]

key-files:
  created:
    - lib/lockspire/workers/pruner.ex
    - test/lockspire/workers/pruner_test.exs
  modified:
    - lib/lockspire/config.ex
    - lib/lockspire/oban.ex
    - lib/lockspire/storage/ecto/repository.ex
    - test/lockspire/storage/repository_test.exs

key-decisions:
  - "Configured pruning interval via `pruner_schedule/0` defaulting to `@hourly`."
  - "Implemented chunked `LIMIT 1000` deletion to prevent table lock escalation during pruning."

patterns-established:
  - "Ecto repository tail-recursive deletion for high-volume table pruning without locking."
  - "Dynamic Oban plugin configuration based on application configuration."

requirements-completed: [S02-PRUNING]

duration: Unknown
completed: 2024-05-03
---

# Phase S02 Plan 01: Automated Token and Nonce Pruning Summary

**Configurable Oban Cron job executing Ecto chunked deletions to prune expired security records (tokens, nonces, etc.) while emitting telemetry.**

## Performance

- **Duration:** Unknown (continuation)
- **Started:** Unknown
- **Completed:** 2024-05-03T17:15:00Z
- **Tasks:** 3
- **Files modified:** 6

## Accomplishments
- Implemented background pruning for expired tokens, nonces, device codes, and pushed authorization requests.
- Avoided long-running transaction locks via recursive chunked deletion logic in Ecto (1000 IDs per chunk).
- Integrated telemetry to track deletion counts per model automatically.

## Task Commits

Each task was committed atomically:

1. **Task 1: Add Pruner Configuration and Oban Setup** - `07ee50a` (feat)
2. **Task 2: Implement Chunked Recursive Deletion** - `d69dcb0` (feat)
3. **Task 3: Create Pruner Worker and Emit Telemetry** - `329eabe` (feat)

## Files Created/Modified
- `lib/lockspire/config.ex` - Added `pruner_schedule/0` config option
- `lib/lockspire/oban.ex` - Dynamically load Oban Cron plugin
- `lib/lockspire/storage/ecto/repository.ex` - Added `prune_expired_records/3` for safe batch deletions
- `lib/lockspire/workers/pruner.ex` - Oban worker routing deletions and emitting telemetry
- `test/lockspire/storage/repository_test.exs` - Unit tests for repository chunked deletion
- `test/lockspire/workers/pruner_test.exs` - Unit tests for worker and telemetry

## Decisions Made
- Used `LIMIT 1000` for batch deletion size as a safe default for typical production setups.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None

## Next Phase Readiness
Automated pruning is ready and will run hourly by default.
