---
phase: 39-automated-rp-logout-propagation
plan: "03"
subsystem: auth
tags: [oidc, logout, ecto, postgres, repository, phoenix]
requires:
  - phase: 39-01
    provides: Wave 0 logout propagation scaffolds and repository test target
  - phase: 39-02
    provides: Typed client logout propagation fields and operator validation
provides:
  - Durable logout event and logout delivery storage rows
  - Repository-backed snapshotting of logout targets from token history
  - Authoritative per-delivery ids for later queue uniqueness and worker fan-out
affects: [phase-39, logout-propagation, repository, workers, end-session-complete]
tech-stack:
  added: []
  patterns:
    - durable logout event plus delivery tables
    - snapshot-authoritative delivery rows
    - sid-based client fan-out from token history
key-files:
  created:
    - lib/lockspire/domain/logout_event.ex
    - lib/lockspire/domain/logout_delivery.ex
    - lib/lockspire/storage/logout_store.ex
    - lib/lockspire/storage/ecto/logout_event_record.ex
    - lib/lockspire/storage/ecto/logout_delivery_record.ex
    - priv/repo/migrations/20260429110000_add_logout_propagation_fields_to_lockspire_clients.exs
    - priv/repo/migrations/20260429110010_create_lockspire_logout_events.exs
    - priv/repo/migrations/20260429110020_create_lockspire_logout_deliveries.exs
  modified:
    - lib/lockspire/storage/ecto/repository.ex
    - test/lockspire/storage/ecto/repository_logout_propagation_test.exs
key-decisions:
  - "Logout propagation persists one event row and separate per-channel delivery rows instead of deriving history from jobs or live client config."
  - "Repository snapshot selection keys off active access and refresh tokens by sid, then dedupes to distinct client ids before building delivery rows."
  - "The earlier plan-owned client-field migration was kept as a compatibility no-op because Phase 39-02 had already shipped the real additive migration under version 20260429193000."
patterns-established:
  - "Delivery rows generate stable UUID delivery_id values for later Oban uniqueness and correlation."
  - "Snapshot rows carry target_uri and session_required from client state at logout time, surviving later client edits and token revocation."
requirements-completed: [SLO-03, SLO-04]
duration: 6 min
completed: 2026-04-29
---

# Phase 39 Plan 03: Durable logout event storage, delivery snapshots, and repository fan-out

**Durable logout event and delivery tables now back sid-based repository fan-out, with snapshot-owned target URIs and stable delivery identifiers for later worker enqueueing.**

## Performance

- **Duration:** 6 min
- **Started:** 2026-04-29T19:14:38Z
- **Completed:** 2026-04-29T19:20:54Z
- **Tasks:** 3
- **Files modified:** 10

## Accomplishments
- Added typed logout event and logout delivery domain structs plus a dedicated `LogoutStore` persistence behaviour.
- Created durable Ecto schemas and migrations for logout events and per-channel delivery snapshots, while preserving redaction-safe stored fields.
- Implemented repository logout propagation persistence that snapshots distinct target clients from active token history and inserts authoritative delivery rows transactionally.

## Task Commits

Each task was committed atomically:

1. **Task 1: Add logout event and delivery domain/store contracts** - `676aaf7` (`feat`)
2. **Task 2: Add migrations and Ecto records for durable logout rows** - `d4e4f04` (`feat`)
3. **Task 3: Implement repository snapshot and persistence helpers** - `08db809` (`feat`)

TDD RED commits:

1. **Task 1 RED: failing logout storage contract coverage** - `925bd46` (`test`)
2. **Task 2 RED: failing logout record persistence coverage** - `77e417d` (`test`)
3. **Task 3 RED: failing logout repository persistence coverage** - `35be50f` (`test`)

## Files Created/Modified
- `lib/lockspire/domain/logout_event.ex` - Defines the durable protocol-owned logout event shape.
- `lib/lockspire/domain/logout_delivery.ex` - Defines per-client per-channel delivery lifecycle state.
- `lib/lockspire/storage/logout_store.ex` - Introduces the logout persistence behaviour contract.
- `lib/lockspire/storage/ecto/logout_event_record.ex` - Maps durable logout events into Ecto storage.
- `lib/lockspire/storage/ecto/logout_delivery_record.ex` - Maps snapshot-owned delivery rows into Ecto storage.
- `lib/lockspire/storage/ecto/repository.ex` - Persists logout events and derived delivery snapshots from token history.
- `priv/repo/migrations/20260429110000_add_logout_propagation_fields_to_lockspire_clients.exs` - Compatibility no-op for the already-shipped client logout columns migration drift.
- `priv/repo/migrations/20260429110010_create_lockspire_logout_events.exs` - Creates the authoritative logout event table.
- `priv/repo/migrations/20260429110020_create_lockspire_logout_deliveries.exs` - Creates the per-channel delivery snapshot table.
- `test/lockspire/storage/ecto/repository_logout_propagation_test.exs` - Proves contract, schema, and repository fan-out behavior.

## Decisions Made

- Used one durable `logout_event` row plus many `logout_delivery` rows so later worker and controller plans can rely on snapshot truth instead of mutable client config.
- Generated UUID `event_id` and `delivery_id` values inside the repository/storage layer so downstream queue uniqueness does not depend on database ids alone.
- Kept raw logout artifacts out of storage entirely; persisted rows expose only redaction-safe correlation data and snapshot metadata.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Reconciled the plan-owned client migration path with the already-shipped Phase 39-02 migration**
- **Found during:** Task 2 (Add migrations and Ecto records for durable logout rows)
- **Issue:** Phase 39-02 had already committed the real client logout column migration as `20260429193000_add_logout_propagation_fields_to_lockspire_clients.exs`, so creating the plan-listed `20260429110000` migration as another additive migration would have caused duplicate-column failures on fresh databases.
- **Fix:** Added `20260429110000_add_logout_propagation_fields_to_lockspire_clients.exs` as a compatibility no-op and left the committed Phase 39-02 additive migration authoritative.
- **Files modified:** `priv/repo/migrations/20260429110000_add_logout_propagation_fields_to_lockspire_clients.exs`
- **Verification:** `MIX_ENV=test mix test.setup`; `MIX_ENV=test mix test test/lockspire/storage/ecto/repository_logout_propagation_test.exs`
- **Committed in:** `d4e4f04`

---

**Total deviations:** 1 auto-fixed (1 blocking)
**Impact on plan:** Necessary schema compatibility only. The shipped storage surface remains the same, and fresh plus already-migrated databases converge safely.

## Issues Encountered

- The plan’s exact verification command uses `mix test ... -x`, but this Mix version rejects `-x` as an unknown option. The file-scoped `mix test` equivalent was used for runnable verification.
- `MIX_ENV=test mix test.setup` was required after adding the new migrations so the test database contained the logout event and delivery tables.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Later Phase 39 worker and controller slices can now consume authoritative logout snapshot rows rather than recalculating from live client state.
- Back-channel enqueueing can use `delivery_id` as the unique durable correlation key without inventing a second identifier shape.

## Verification

- `MIX_ENV=test mix test.setup` — passed; test database already existed and reported the new logout migrations as up.
- `MIX_ENV=test mix test test/lockspire/storage/ecto/repository_logout_propagation_test.exs -x` — failed before execution because this Mix version reports `-x` as an unknown option.
- `MIX_ENV=test mix test test/lockspire/storage/ecto/repository_logout_propagation_test.exs` — passed (`9 tests, 0 failures`).

## Self-Check: PASSED

- Found summary file: `.planning/phases/39-automated-rp-logout-propagation/39-03-SUMMARY.md`
- Found commits: `925bd46`, `676aaf7`, `77e417d`, `d4e4f04`, `35be50f`, `08db809`
