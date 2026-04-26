---
phase: 25-dcr-storage-skeleton-domain-types-and-policy-resolver
plan: 02
subsystem: database
tags: [ecto, postgres, migration, dcr, server-policy, rfc7591]

# Dependency graph
requires:
  - phase: v1.3-par
    provides: "lockspire_server_policies singleton table (id=1 row, par_policy column) — the table this migration extends"
provides:
  - "10 new columns on lockspire_server_policies for DCR (registration_policy enum + 6 allowlists + 3 lifetime integers)"
  - "Singleton row backfilled with secure-by-default values (registration_policy='disabled', allowlists=[], lifetimes=NULL)"
  - "Reversible migration template for the rest of Phase 25's storage extensions (Plan 03 IAT table, Plan 05 client provenance)"
affects:
  - "Plan 05 (ServerPolicyRecord widening) — Ecto.Enum cast list MUST include all 10 new fields, registration_policy as :enum [:disabled, :initial_access_token, :open]"
  - "Plan 06 (Admin.ServerPolicy.get_dcr_policy/0) — reads from the singleton row this migration backfilled"
  - "Phase 26 (DcrPolicy resolver) — consumes these allowlists for intersection; lifetime nil-fallback to global defaults"
  - "Phase 28 (admin LiveView for DCR policy) — bound to put_dcr_policy/1 surface that maps to these columns"

# Tech tracking
tech-stack:
  added: []  # No new deps; reuses Ecto.Migration + Postgres column types
  patterns: ["additive Ecto migration with text-as-enum + {:array, :text} allowlists + nullable :integer lifetimes"]

key-files:
  created:
    - "priv/repo/migrations/20260427000000_extend_lockspire_server_policies_dcr.exs"
  modified: []

key-decisions:
  - "No formatter parens added to migration file: project convention (all 6 existing migrations) and the plan's verbatim template both use no-parens style; .formatter.exs scope deliberately excludes priv/repo/migrations/. The plan's grep-based acceptance criteria all match the no-parens form. The mix format --check-formatted criterion contradicts the verbatim template — we followed the template + project convention."

patterns-established:
  - "Pattern: Singleton-table additive migration. ADD COLUMN ... NOT NULL DEFAULT '<atom-as-string>' atomically backfills the existing id=1 row; no execute() data migration step needed for small tables. Mirrors the v1.3 PAR migration template at 20260424180000_*.exs verbatim."
  - "Pattern: DCR allowlists default to [] (empty), forcing operator to explicitly populate via Admin.ServerPolicy.put_dcr_policy/1 (Plan 06). Combined with registration_policy default :disabled, this is the secure-by-default posture (T-25-10 disposition: accept)."

requirements-completed: [DCR-06, DCR-07]

# Metrics
duration: ~5 min
completed: 2026-04-26
---

# Phase 25 Plan 02: Migration A — Extend lockspire_server_policies with DCR Columns Summary

**Additive Ecto migration adding 10 DCR columns (1 tri-state enum, 6 allowlists, 3 nullable lifetime integers) to the singleton lockspire_server_policies table; secure-by-default backfill via column defaults.**

## Performance

- **Duration:** ~5 min (one-task plan; bulk of time was deps install)
- **Started:** 2026-04-26T15:38:00Z (approx)
- **Completed:** 2026-04-26T15:42:44Z
- **Tasks:** 1/1
- **Files created:** 1
- **Files modified:** 0

## Accomplishments

- Created `priv/repo/migrations/20260427000000_extend_lockspire_server_policies_dcr.exs` with module `Lockspire.TestRepo.Migrations.ExtendLockspireServerPoliciesDcr` (project-conventional `Lockspire.TestRepo.Migrations.*` prefix).
- 10 DCR columns ship verbatim per D-06 in 25-CONTEXT.md:
  - `registration_policy text NOT NULL DEFAULT 'disabled'` (D-05 tri-state enum target; Ecto.Enum cast lives in Plan 05).
  - 6 `{:array, :text}` allowlists, all `NOT NULL DEFAULT ARRAY[]::text[]`: `dcr_allowed_scopes`, `dcr_allowed_grant_types`, `dcr_allowed_response_types`, `dcr_allowed_redirect_uri_schemes`, `dcr_allowed_redirect_uri_hosts`, `dcr_allowed_token_endpoint_auth_methods`.
  - 3 nullable `:integer` lifetime columns: `dcr_default_client_lifetime_seconds`, `dcr_default_client_secret_lifetime_seconds`, `dcr_default_registration_access_token_lifetime_seconds`.
- Verified `MIX_ENV=test mix ecto.drop && ecto.create && ecto.migrate` runs cleanly through all 7 migrations (v1.0 → v1.5).
- Verified `MIX_ENV=test mix ecto.rollback --step 1` reverses Plan 02 only.
- Verified `MIX_ENV=test mix ecto.migrate` re-applies idempotently after rollback.
- Confirmed via `psql \d lockspire_server_policies` that all 10 new columns exist with correct types, nullability, and defaults.

## Task Commits

1. **Task 1: Create additive migration extending lockspire_server_policies with 10 DCR columns** — `6ffb1a6` (feat)

## Files Created/Modified

- `priv/repo/migrations/20260427000000_extend_lockspire_server_policies_dcr.exs` — Ecto migration extending lockspire_server_policies with DCR columns (10 new columns); reversible via standard `Ecto.Migration.change/0` idiom.

## Verification Output

### `mix ecto.drop && ecto.create && ecto.migrate` (clean from empty)

```
== Running 20260424180000 Lockspire.TestRepo.Migrations.AddLockspireServerPolicyAndClientParPolicy.change/0 forward
create table lockspire_server_policies
alter table lockspire_clients
== Migrated 20260424180000 in 0.0s
== Running 20260427000000 Lockspire.TestRepo.Migrations.ExtendLockspireServerPoliciesDcr.change/0 forward
alter table lockspire_server_policies
== Migrated 20260427000000 in 0.0s
```

### `mix ecto.rollback --step 1`

```
== Running 20260427000000 Lockspire.TestRepo.Migrations.ExtendLockspireServerPoliciesDcr.change/0 backward
alter table lockspire_server_policies
== Migrated 20260427000000 in 0.0s
```

### `mix ecto.migrate` (after rollback — idempotency)

```
== Running 20260427000000 Lockspire.TestRepo.Migrations.ExtendLockspireServerPoliciesDcr.change/0 forward
alter table lockspire_server_policies
== Migrated 20260427000000 in 0.0s
```

### `psql -d lockspire_test -c "\d lockspire_server_policies"` (final state)

```
                         Column                         |            Type             | Nullable |             Default
--------------------------------------------------------+-----------------------------+----------+-----------------------------------
 id                                                     | bigint                      | not null | nextval('lockspire_server_policies_id_seq'::regclass)
 par_policy                                             | text                        | not null | 'optional'::text
 inserted_at                                            | timestamp without time zone | not null |
 updated_at                                             | timestamp without time zone | not null |
 registration_policy                                    | text                        | not null | 'disabled'::text
 dcr_allowed_scopes                                     | text[]                      | not null | ARRAY[]::text[]
 dcr_allowed_grant_types                                | text[]                      | not null | ARRAY[]::text[]
 dcr_allowed_response_types                             | text[]                      | not null | ARRAY[]::text[]
 dcr_allowed_redirect_uri_schemes                       | text[]                      | not null | ARRAY[]::text[]
 dcr_allowed_redirect_uri_hosts                         | text[]                      | not null | ARRAY[]::text[]
 dcr_allowed_token_endpoint_auth_methods                | text[]                      | not null | ARRAY[]::text[]
 dcr_default_client_lifetime_seconds                    | integer                     |          |
 dcr_default_client_secret_lifetime_seconds             | integer                     |          |
 dcr_default_registration_access_token_lifetime_seconds | integer                     |          |
```

`SELECT count(*) FROM information_schema.columns WHERE table_name = 'lockspire_server_policies' AND (column_name LIKE 'dcr_%' OR column_name = 'registration_policy')` returns **10**. Singleton row at id=1 (created by the v1.3 PAR migration) is backfilled atomically with the column defaults.

## Decisions Made

1. **No formatter parens added to migration file.** The plan's verbatim template uses no-parens `add :col, :type, ...` style, matching all 6 existing migrations. Project's `.formatter.exs` `inputs` scope is `mix.exs` + `{config,lib,test}/**/*.{ex,exs}` — it deliberately excludes `priv/repo/migrations/`, so the existing PAR template at `20260424180000_*.exs` also fails `mix format --check-formatted` when checked explicitly. We followed the verbatim template + project convention; this matches what `mix qa` actually validates.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Installed missing Hex deps before running mix ecto.migrate**
- **Found during:** Task 1 (verification step)
- **Issue:** Worktree had no `deps/` or `_build/` directories; `mix ecto.migrate` could not run.
- **Fix:** Ran `HEX_API_KEY= mix deps.get && MIX_ENV=test mix compile`.
- **Files modified:** None (deps + build artifacts only; gitignored).
- **Verification:** `mix ecto.migrate` ran successfully against `lockspire_test` DB.
- **Committed in:** N/A (deps are not tracked)

### Acceptance-Criterion Notes (no fix applied — criterion conflicts with project convention)

**2. [Acceptance criterion vs project convention] `mix format --check-formatted` on the migration file fails**
- **Found during:** Task 1 verification
- **Issue:** The plan's acceptance criteria includes `mix format --check-formatted priv/repo/migrations/...` exits 0. However: (a) the plan's verbatim code uses no-parens `add :col, :type, ...`; (b) the formatter wants parens (`add(...)`); (c) the existing v1.3 PAR migration (the plan's "verbatim structural template") fails the same check; (d) `.formatter.exs` `inputs` deliberately excludes `priv/repo/migrations/`, so `mix qa` (the project's actual format gate) does not flag this file.
- **Fix:** None — followed the plan's verbatim template + project convention. Adding parens would diverge from the established migration style and from the plan's own "EXACTLY this content" instruction.
- **Recommended follow-up:** Phase 25 plan-checker should drop this acceptance criterion, or the project should expand `.formatter.exs` `inputs` to cover migrations and reformat all 7 existing migrations together (separate refactor commit). Either way, this is out of scope for Plan 02.

---

**Total deviations:** 1 auto-fixed (Rule 3 blocking) + 1 acceptance-criterion mismatch documented for plan-checker follow-up.
**Impact on plan:** No scope creep. Migration ships exactly the verbatim shape D-06 mandates.

## Issues Encountered

- Initial confusion when querying columns via UNIX-socket `psql` (`/tmp` host) returned an empty table — the Mix-configured connection runs over TCP `localhost:5432` and writes to a different Postgres cluster on this machine. Resolved by querying via `PGHOST=localhost psql`. Not a code issue; environment-only.

## User Setup Required

None — migration runs automatically via `mix ecto.migrate`. No external services, no env-var configuration.

## Next Phase Readiness

- **For Plan 03 (Migration B — IAT table):** `lockspire_initial_access_tokens` will be created as a new table with `unique_index(:lockspire_initial_access_tokens, [:token_hash])` per D-03 + D-11. Plan 03 is independent of this plan (no FKs from this plan into Plan 03's table; the FK lives in Plan 05's client-table widening).
- **For Plan 05 (Migration C + ServerPolicyRecord widening):** The `ServerPolicyRecord` `Ecto.Enum` cast list MUST widen to include all 10 new fields shipped by this plan. `registration_policy` casts as `Ecto.Enum, values: [:disabled, :initial_access_token, :open]` (D-05). The 6 `dcr_allowed_*` fields cast as `{:array, :string}`. The 3 lifetime integers cast as `:integer`.
- **For Plan 06 (Admin.ServerPolicy.get_dcr_policy/0):** Reads from the singleton row this migration backfilled. Default-state read should return `%DcrPolicy{registration_policy: :disabled, allowed_scopes: [], allowed_grant_types: [], allowed_response_types: [], allowed_redirect_uri_schemes: [], allowed_redirect_uri_hosts: [], allowed_token_endpoint_auth_methods: [], default_client_lifetime_seconds: nil, default_client_secret_lifetime_seconds: nil, default_registration_access_token_lifetime_seconds: nil}`.
- **For Phase 26 (DcrPolicy resolver):** Per D-17, the resolver does per-allowlist `MapSet.intersection/2`. Empty-allowlist defaults from this migration mean DCR is effectively closed until an operator populates them, even if `registration_policy` is later flipped to `:initial_access_token` or `:open`.

## Self-Check: PASSED

- File exists: `priv/repo/migrations/20260427000000_extend_lockspire_server_policies_dcr.exs` — FOUND
- Commit `6ffb1a6` for Task 1 — FOUND in `git log --oneline`
- All 10 new columns confirmed in `information_schema.columns` (1 registration_policy + 9 dcr_*)
- Migration up/down/up cycle verified clean

---
*Phase: 25-dcr-storage-skeleton-domain-types-and-policy-resolver*
*Plan: 02*
*Completed: 2026-04-26*
