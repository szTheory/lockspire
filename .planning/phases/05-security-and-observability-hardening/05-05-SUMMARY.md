---
phase: 05-security-and-observability-hardening
plan: 05
subsystem: security
tags: [redaction, telemetry, audit, ecto, sql-logging, testing]
requires:
  - phase: 05-security-and-observability-hardening
    provides: "Protocol and admin audit wiring from 05-03 and 05-04 plus the append-only audit foundation from 05-02"
provides:
  - "Shared redaction helpers for telemetry and durable audit metadata"
  - "Observability emission routed through the shared redaction seam"
  - "Durable audit metadata shaping routed through the shared redaction seam"
  - "Targeted SQL bind-log suppression for sensitive token, audit, and client-secret repository paths"
affects: [security, observability, audit, storage, protocol, admin]
tech-stack:
  added: []
  patterns: [shared redaction seam, surface-specific metadata projection, query-level log suppression]
key-files:
  created:
    - lib/lockspire/redaction.ex
    - test/lockspire/redaction/redaction_test.exs
  modified:
    - lib/lockspire/observability.ex
    - lib/lockspire/audit/event.ex
    - lib/lockspire/storage/ecto/repository.ex
    - test/lockspire/audit/audit_writer_test.exs
    - test/lockspire/storage/repository_test.exs
key-decisions:
  - "Keep one shared redaction module with separate telemetry and audit projections instead of expanding per-call-site deny lists."
  - "Suppress SQL logging only on token, audit, and client-secret repository operations so ordinary debugging remains available elsewhere."
patterns-established:
  - "Telemetry metadata drops bearer artifacts and secrets, and converts family identifiers to stable correlation handles."
  - "Durable audit metadata preserves canonical resource references while removing bearer artifacts, secrets, and raw payload blobs."
  - "Repository helpers apply `log: false` only on sensitive queries and writes rather than disabling Repo logging globally."
requirements-completed: [SECU-02, SECU-03]
duration: 11min
completed: 2026-04-23
---

# Phase 05 Plan 05: Shared Redaction Hardening Summary

**Shared redaction helpers now protect telemetry and durable audit payloads, while sensitive repository paths suppress SQL bind logging without disabling normal Repo debugging**

## Performance

- **Duration:** 11 min
- **Started:** 2026-04-23T17:00:00Z
- **Completed:** 2026-04-23T17:11:20Z
- **Tasks:** 2
- **Files modified:** 7

## Accomplishments

- Added `Lockspire.Redaction` as the shared surface-aware projection boundary for telemetry and durable audit metadata.
- Routed `Lockspire.Observability` and `Lockspire.Audit.Event` through that shared seam so secrets, bearer artifacts, and raw payload blobs are removed consistently.
- Localized SQL debug-log suppression to sensitive token, audit, and client-secret repository operations while preserving ordinary client-path debugging.

## Task Commits

Each task was committed atomically:

1. **Task 1: Centralize telemetry and durable audit payload redaction** - `342978f` (`feat`)
2. **Task 2: Apply targeted query-level SQL log suppression for sensitive repository paths** - `bd72152` (`fix`)

## Files Created/Modified

- `lib/lockspire/redaction.ex` - Shared redaction helpers for telemetry handles and durable audit metadata projection.
- `lib/lockspire/observability.ex` - Telemetry emission now delegates metadata shaping to `Lockspire.Redaction`.
- `lib/lockspire/audit/event.ex` - Durable audit normalization now passes metadata through the shared audit projection.
- `lib/lockspire/storage/ecto/repository.ex` - Sensitive token, audit, and client-secret queries use localized `log: false` options.
- `test/lockspire/redaction/redaction_test.exs` - Verifies telemetry masking and stable handle generation.
- `test/lockspire/audit/audit_writer_test.exs` - Verifies durable audit payload redaction keeps resource refs while removing secrets.
- `test/lockspire/storage/repository_test.exs` - Verifies sensitive SQL paths stay out of captured debug logs while ordinary client queries still log.

## Decisions Made

- Kept protocol call sites unchanged where they already emitted structured metadata; the shared redaction seam now enforces the security boundary centrally.
- Used stable short handles only where telemetry correlation benefits from them immediately (`family_id`), leaving durable audit resource identifiers canonical for incident reconstruction.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Reused the local Postgres role for verification**
- **Found during:** Task 1 and Task 2 verification
- **Issue:** The local machine still does not expose the default `postgres` role used by the test config fallback.
- **Fix:** Ran the plan verification commands with `PGUSER=jon` so the existing test repo configuration could connect without changing project code.
- **Files modified:** None
- **Verification:** `PGUSER=jon mix test test/lockspire/redaction/redaction_test.exs test/lockspire/audit/audit_writer_test.exs`, `PGUSER=jon mix test test/lockspire/storage/repository_test.exs test/lockspire/redaction/redaction_test.exs`, `PGUSER=jon mix test test/lockspire/redaction/redaction_test.exs test/lockspire/audit/audit_writer_test.exs test/lockspire/storage/repository_test.exs`
- **Committed in:** not committed (environment-only)

---

**Total deviations:** 1 auto-fixed (Rule 3: 1)
**Impact on plan:** No scope creep. The deviation was environment-only; shipped code matches the plan objective.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Later redaction/UI slices can consume `Lockspire.Redaction` instead of introducing new masking logic.
- Phase 05 negative-path and admin masking plans now inherit a centralized metadata boundary and safer repository logging posture.

## Self-Check: PASSED

- Verified `.planning/phases/05-security-and-observability-hardening/05-05-SUMMARY.md` exists on disk.
- Verified commits `342978f` and `bd72152` exist in git history.
