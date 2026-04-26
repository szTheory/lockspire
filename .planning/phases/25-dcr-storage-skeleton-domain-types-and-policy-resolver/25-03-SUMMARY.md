---
phase: 25-dcr-storage-skeleton-domain-types-and-policy-resolver
plan: 03
subsystem: database
tags: [ecto, postgres, migration, dcr, rfc7591, initial-access-token, jsonb, hash-at-rest]

# Dependency graph
requires:
  - phase: 25 (Plan 02, wave 1)
    provides: extends lockspire_server_policies with DCR fields (parallel sibling — no FK between them; ordering only matters relative to Plan 05)
provides:
  - lockspire_initial_access_tokens table (9 columns + id + timestamps) per D-11
  - unique_index(:lockspire_initial_access_tokens, [:token_hash]) per D-03 (REQUIRED for Phase 26 atomic redemption)
  - FK target table for Plan 05's lockspire_clients.initial_access_token_id (D-08, D-10)
  - jsonb policy_overrides column (opaque storage; intake validation deferred to Phase 26 / Phase 28)
affects:
  - Plan 04 (Domain.InitialAccessToken defstruct mirrors this column set)
  - Plan 05 (Storage.Ecto.InitialAccessTokenRecord schema + lockspire_clients FK to id)
  - Phase 26 (Lockspire.Protocol.InitialAccessToken.redeem/1 — atomic UPDATE ... WHERE used_at IS NULL relies on unique_index on token_hash)
  - Phase 28 (admin mint path populates created_by + policy_overrides)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Hash-at-rest IAT storage (D-14): only token_hash persists, never plaintext"
    - "Soft-delete-only lifecycle (D-12): revoked_at + used_at, no hard-delete pathway"
    - "Singular unique_index discipline: index only what downstream redemption needs (D-03); admin-listing indexes deferred to Phase 28 per Open Question 3"

key-files:
  created:
    - priv/repo/migrations/20260427000010_create_lockspire_initial_access_tokens.exs
  modified: []

key-decisions:
  - "Migration timestamp 20260427000010 deliberately ordered between Plan 02 (20260427000000) and Plan 05 (20260427000020) so Plan 05's references(:lockspire_initial_access_tokens, on_delete: :restrict) resolves at migrate-time"
  - "policy_overrides declared as :map (Ecto canonical syntax for jsonb), matching project convention at Lockspire.Storage.Ecto.ClientRecord (field :jwks, :map)"
  - "Shipped ONLY the unique_index on token_hash; deferred admin-listing indexes (revoked_at, expires_at, created_by) to Phase 28 when actual query patterns are visible"

patterns-established:
  - "Singular index discipline for new tables: ship only indexes downstream invariants require; defer composite/listing indexes to the phase that introduces the query"
  - "FK ordering via timestamp interleaving: when wave plans share a migration target window, allocate timestamp slots that respect FK direction (referenced table first)"

requirements-completed: [DCR-10]

# Metrics
duration: 2m 16s
completed: 2026-04-26
---

# Phase 25 Plan 03: lockspire_initial_access_tokens migration Summary

**Created lockspire_initial_access_tokens table with the 9 D-11 columns and the token_hash unique index Phase 26's atomic single-use redemption depends on.**

## Performance

- **Duration:** 2m 16s
- **Started:** 2026-04-26T15:39:20Z
- **Completed:** 2026-04-26T15:41:36Z
- **Tasks:** 1
- **Files modified:** 1 (created)

## Accomplishments
- New Ecto migration `20260427000010_create_lockspire_initial_access_tokens.exs` adds the IAT table with the exact 9 columns from D-11: `token_hash` (text NOT NULL), `expires_at` (utc_datetime_usec NOT NULL), `single_use` (boolean NOT NULL DEFAULT true), `used_at` (nullable), `revoked_at` (nullable), `policy_overrides` (jsonb nullable, declared as Ecto `:map`), `created_by` (text nullable), plus `id` (bigserial) and `inserted_at`/`updated_at`.
- `create(unique_index(:lockspire_initial_access_tokens, [:token_hash]))` per D-03 — the index Phase 26's `UPDATE ... WHERE used_at IS NULL` race-free single-use redemption depends on.
- Filename timestamp `20260427000010` sits between Plan 02's `20260427000000` and Plan 05's `20260427000020` so that Plan 05's `references(:lockspire_initial_access_tokens, on_delete: :restrict)` from `lockspire_clients.initial_access_token_id` resolves at migrate time.
- Verified by full forward migrate, single-step rollback (drops table + index together), and re-migrate — all clean.

## Task Commits

Each task was committed atomically:

1. **Task 1: Create new lockspire_initial_access_tokens table migration with token_hash unique index** — `8a13551` (feat)

_Note: SUMMARY.md will be committed by the metadata commit after this file is written._

## Files Created/Modified

- `priv/repo/migrations/20260427000010_create_lockspire_initial_access_tokens.exs` — Ecto migration creating the IAT table with the D-11 column set and the D-03 unique index on `token_hash`. Module name `Lockspire.TestRepo.Migrations.CreateLockspireInitialAccessTokens` follows project convention. `policy_overrides` uses `:map` (Postgres `jsonb`).

## Verification Output

`MIX_ENV=test mix ecto.migrate` (forward, full chain through the new migration):

```
== Running 20260427000010 Lockspire.TestRepo.Migrations.CreateLockspireInitialAccessTokens.change/0 forward
create table lockspire_initial_access_tokens
create index lockspire_initial_access_tokens_token_hash_index
== Migrated 20260427000010 in 0.0s
```

`MIX_ENV=test mix ecto.rollback --step 1` (rollback this migration):

```
== Running 20260427000010 Lockspire.TestRepo.Migrations.CreateLockspireInitialAccessTokens.change/0 backward
drop index lockspire_initial_access_tokens_token_hash_index
drop table lockspire_initial_access_tokens
== Migrated 20260427000010 in 0.0s
```

`MIX_ENV=test mix ecto.migrate` (re-migrate to confirm idempotency after rollback):

```
== Running 20260427000010 Lockspire.TestRepo.Migrations.CreateLockspireInitialAccessTokens.change/0 forward
create table lockspire_initial_access_tokens
create index lockspire_initial_access_tokens_token_hash_index
== Migrated 20260427000010 in 0.0s
```

`mix format --check-formatted priv/repo/migrations/20260427000010_create_lockspire_initial_access_tokens.exs` exits 0.

All 13 grep-based acceptance criteria from the plan pass (file exists, module name, create-table, every column, timestamps, unique_index present, ZERO non-unique `create(index(` lines).

## Confirmation: Indexing Discipline

- ✅ Exactly ONE `create(unique_index(:lockspire_initial_access_tokens, [:token_hash]))` call.
- ✅ ZERO non-unique `create(index(...))` calls — no `revoked_at`, `expires_at`, or `created_by` indexes shipped (deferred to Phase 28 per RESEARCH Open Question 3 — admin-listing indexes added when actual query patterns are visible).
- ✅ Threat T-25-11 (a future contributor swapping `unique_index` for `index`) actively guarded by the plan's grep acceptance criteria.

## Decisions Made

- **Followed the plan exactly.** All 9 columns, the single unique_index, the module-name prefix, the filename timestamp, and the `:map` (jsonb) declaration for `policy_overrides` came verbatim from the plan's `<action>` block.
- **No extra indexes added** even though admin-listing queries on `revoked_at`/`expires_at` are foreseeable — explicitly deferred per the plan's Open Question 3 reference.

## Deviations from Plan

None — plan executed exactly as written.

The only environmental work was running `mix deps.get` because the worktree's `_build/`/`deps/` are not pre-populated; this is standard worktree setup and not a code/scope deviation.

## Issues Encountered

None. The migration applied, rolled back, and re-applied cleanly on the first attempt.

## User Setup Required

None — no external service configuration required. The migration is rollback-safe and runs at standard `mix ecto.migrate` time.

## Notes for Downstream Plans

- **Plan 04 (Domain.InitialAccessToken defstruct):** Mirror this column set one-to-one. Field types: `:token_hash` (binary string), `:expires_at` (DateTime, utc microsecond precision), `:single_use` (boolean), `:used_at` and `:revoked_at` (DateTime | nil), `:policy_overrides` (map | nil), `:created_by` (binary string | nil), plus `:id`, `:inserted_at`, `:updated_at`.
- **Plan 05 (Storage.Ecto.InitialAccessTokenRecord + lockspire_clients FK):** Schema columns map identically to the migration. Use `field :policy_overrides, :map` (matches `ClientRecord :jwks, :map` pattern at `lib/lockspire/storage/ecto/client_record.ex:34`). The FK from `lockspire_clients.initial_access_token_id` will resolve because this migration's timestamp `20260427000010` sorts before Plan 05's `20260427000020`.
- **Phase 26 (Protocol.InitialAccessToken.redeem/1):** The `unique_index_token_hash` is the single guarantee that `UPDATE ... WHERE token_hash = $1 AND used_at IS NULL RETURNING *` is collision-free. Do not relax this index without re-deriving the redemption invariant.
- **Phase 28 (admin mint UI):** Populate `:created_by` with the operator id and validate `policy_overrides` is ⊆ server allowlist *before* writing to this column (T-25-05 boundary).

## Next Phase Readiness

- Wave 1 of Phase 25 complete from this plan's side. Plan 02 (server-policies extension) executes in a parallel worktree and merges separately.
- Wave 2 (Plans 04, 05, 06) can begin once both wave-1 worktrees merge into the phase branch — Plan 05 will pick up this table as the FK target.
- No blockers; no follow-ups required from this plan.

---
*Phase: 25-dcr-storage-skeleton-domain-types-and-policy-resolver*
*Plan: 03*
*Completed: 2026-04-26*

## Self-Check: PASSED

Verified:
- ✅ FOUND: priv/repo/migrations/20260427000010_create_lockspire_initial_access_tokens.exs
- ✅ FOUND commit: 8a13551 (feat(25-03): add lockspire_initial_access_tokens migration)
