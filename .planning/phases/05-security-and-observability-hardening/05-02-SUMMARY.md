---
phase: 05-security-and-observability-hardening
plan: 02
subsystem: database
tags: [ecto, postgres, audit, security, testing]
requires:
  - phase: 05-security-and-observability-hardening
    provides: "Phase 05 context, threat model, and append-only audit requirements"
provides:
  - "Append-only audit event schema and migration"
  - "Normalized durable audit event boundary"
  - "Repository helpers for transactional audit appends"
  - "Rollback coverage for mutation and audit write failures"
affects: [security, observability, admin, protocol, storage]
tech-stack:
  added: []
  patterns: [append-only audit events, transactional audit append helper, rollback-driven repository tests]
key-files:
  created:
    - lib/lockspire/audit/event.ex
    - lib/lockspire/storage/ecto/audit_event_record.ex
    - priv/repo/migrations/20260423000100_create_lockspire_audit_events.exs
    - test/lockspire/audit/audit_writer_test.exs
  modified:
    - lib/lockspire/storage/ecto/repository.ex
    - test/lockspire/storage/repository_test.exs
key-decisions:
  - "Use a thin domain audit struct plus a normal Ecto record instead of generic row history."
  - "Keep audit writes at the repository seam with a reusable transaction wrapper so durable mutations and audit evidence commit or roll back together."
patterns-established:
  - "Audit payloads normalize to actor_type, actor_id, actor_display, resource_type, resource_id, action, outcome, reason_code, and compact metadata."
  - "Repository helpers accept normalized audit events and roll back the wrapped mutation if the audit append fails."
requirements-completed: [SECU-02]
duration: 4min
completed: 2026-04-23
---

# Phase 05 Plan 02: Durable Audit Foundation Summary

**Append-only audit event storage with normalized actor/resource metadata and repository-level transactional append helpers**

## Performance

- **Duration:** 4 min
- **Started:** 2026-04-23T16:38:00Z
- **Completed:** 2026-04-23T16:42:05Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments
- Added `Lockspire.Audit.Event`, `AuditEventRecord`, and a new `lockspire_audit_events` migration for durable append-only audit truth.
- Added reusable repository helpers for direct audit appends and wrapped transactional writes.
- Proved that wrapped mutation failures and audit append failures both roll back without leaving orphaned audit rows or partial durable state.

## Task Commits

Each task was committed atomically:

1. **Task 1: Add the append-only audit schema and normalized event boundary** - `4e63408` (`test`)
2. **Task 2: Add repository audit append primitives with transactional rollback guarantees** - `7f1c7d1` (`feat`)

## Files Created/Modified
- `lib/lockspire/audit/event.ex` - Normalizes durable audit payloads and compacts metadata.
- `lib/lockspire/storage/ecto/audit_event_record.ex` - Ecto schema and changeset for append-only audit rows.
- `priv/repo/migrations/20260423000100_create_lockspire_audit_events.exs` - Audit table and lookup indexes.
- `lib/lockspire/storage/ecto/repository.ex` - Direct audit append helper plus transaction wrapper for mutation+audit atomicity.
- `test/lockspire/audit/audit_writer_test.exs` - Audit normalization and transactional append tests.
- `test/lockspire/storage/repository_test.exs` - Rollback guarantees for wrapped write failure and invalid audit payloads.

## Decisions Made

- Used free-form string fields for action, outcome, reason code, and actor/resource identifiers so later Phase 05 slices can add domain event names without schema churn.
- Kept audit metadata compact by dropping nil and empty values rather than storing snapshots or generic history payloads.
- Returned repository-level rollback reasons directly from `transact_with_audit/2` so future callers can reuse the same failure semantics as other storage commands.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Aligned test verification with the local Postgres user**
- **Found during:** Task 1 verification
- **Issue:** The repo test config defaulted to `postgres`, but this machine only exposes a local `jon` role, so `mix test.setup` could not create or migrate `lockspire_test`.
- **Fix:** Re-ran the plan verification commands with `PGUSER=jon`, using the existing repo configuration path without changing project code.
- **Files modified:** None
- **Verification:** `PGUSER=jon mix test.setup`, `PGUSER=jon mix test test/lockspire/audit/audit_writer_test.exs`, `PGUSER=jon mix test test/lockspire/audit/audit_writer_test.exs test/lockspire/storage/repository_test.exs`
- **Committed in:** not committed (environment-only)

---

**Total deviations:** 1 auto-fixed (Rule 3: 1)
**Impact on plan:** No scope creep. The deviation was local environment setup only; shipped code matches the plan.

## Issues Encountered

- The first commit staged all newly created Task 1 files together, so the RED/GREEN split collapsed into a single task commit. Task atomicity was preserved and Task 2 still landed as a separate commit.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Later Phase 05 protocol and admin slices can now append durable audit rows through the repository seam instead of inventing per-feature persistence paths.
- The shared audit shape is in place for token, consent, client, and key lifecycle transitions.

## Self-Check: PASSED

- Verified created files exist on disk.
- Verified commits `4e63408` and `7f1c7d1` exist in git history.
