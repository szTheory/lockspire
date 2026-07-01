---
phase: 99-signer-extraction-jwt-default-issuance
plan: 01
subsystem: database
tags: [ecto, postgres, oauth, access-token, server-policy, client, jwt, opaque]

# Dependency graph
requires:
  - phase: 98-plug-hardening
    provides: "Lockspire.Plug.VerifyToken narrowed to RFC 9068 at+jwt only (the consumer of the JWT-default shape this plan begins to enable)"
provides:
  - "Server-wide ServerPolicy.access_token_format (Ecto.Enum, default :jwt) threaded record<->domain"
  - "Admin.ServerPolicy.put_access_token_format/1 runtime setter (:jwt | :opaque, no nil branch)"
  - "Per-client nullable Client.access_token_format override (nil = inherit) threaded through changeset/2, update_changeset/2, and to_domain/1"
  - "Migration adding :text access_token_format columns to lockspire_clients (nullable) and lockspire_server_policies (null: false, default jwt)"
affects: [99-03-signer-extraction, 99-06-admin-client-detail-ui, signer, discovery, format-resolution]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Runtime ServerPolicy Ecto.Enum with concrete default (mirrors security_profile/dpop_policy)"
    - "Per-client nullable Ecto.Enum override (nil = inherit, mirrors id_token_signed_response_alg) cast in BOTH changesets"
    - "Ecto.Enum atom field paired with a :text DB column (Pitfall 6)"

key-files:
  created:
    - priv/repo/migrations/20260528150000_add_access_token_format.exs
  modified:
    - lib/lockspire/domain/server_policy.ex
    - lib/lockspire/storage/ecto/server_policy_record.ex
    - lib/lockspire/admin/server_policy.ex
    - lib/lockspire/domain/client.ex
    - lib/lockspire/storage/ecto/client_record.ex
    - test/lockspire/admin/server_policy_test.exs
    - test/lockspire/storage/ecto/client_record_test.exs

key-decisions:
  - "Server-wide access_token_format default is :jwt and never nullable; the per-client override is nullable with nil = inherit (no :inherit sentinel)"
  - "Per-client override cast in BOTH changeset/2 and update_changeset/2 so the admin-mutable path can set it; no validate_required, no FAPI coupling"
  - "Unknown setter values return a structured {:error, [%{field:, reason: :invalid_access_token_format, detail:}]} tuple, never {:ok, nil}"

patterns-established:
  - "access_token_format server-wide setter mirrors put_dpop_policy/1 minus the nil branch"
  - "access_token_format per-client field mirrors id_token_signed_response_alg field-for-field"

requirements-completed: [FORMAT-01, FORMAT-02]

# Metrics
duration: 12min
completed: 2026-05-28
---

# Phase 99 Plan 01: Signer Extraction + JWT-Default Issuance (Storage + Domain Foundation) Summary

**Runtime-editable server-wide `ServerPolicy.access_token_format` defaulting to `:jwt` plus a nullable per-client `Client.access_token_format` override, backed by a dual-table `:text` migration and `Admin.ServerPolicy.put_access_token_format/1`.**

## Performance

- **Duration:** ~12 min (includes one-time `mix deps.get` in the fresh worktree)
- **Started:** 2026-05-28T14:01:00Z
- **Completed:** 2026-05-28T14:05:00Z
- **Tasks:** 3
- **Files modified:** 7 (1 created, 6 modified) + 1 net-new migration

## Accomplishments
- Added the migration that adds `access_token_format` `:text` columns to both `lockspire_clients` (nullable, no default = inherit) and `lockspire_server_policies` (`null: false, default: "jwt"`, backfilling the singleton row via the column default).
- Extended `Domain.ServerPolicy` + `ServerPolicyRecord` with a defaulted-`:jwt` `access_token_format` and shipped `Admin.ServerPolicy.put_access_token_format/1` as a runtime setter that normalizes `:jwt | :opaque | "jwt" | "opaque"` and rejects everything else with a structured error.
- Extended `Domain.Client` + `ClientRecord` with a nullable `access_token_format` override threaded through `changeset/2`, `update_changeset/2` (the admin-mutable path), and `to_domain/1`.

## Task Commits

Each task was committed atomically:

1. **Task 1: Migration — add access_token_format columns to both tables** - `34c709b` (feat)
2. **Task 2: Server-wide ServerPolicy.access_token_format + runtime setter** - `269ad4d` (feat, TDD)
3. **Task 3: Per-client nullable Client.access_token_format threaded record->domain** - `5b0721d` (feat, TDD)

_Note: Tasks 2 and 3 were TDD. In both cases the RED state was a non-runnable compile error (the struct field did not yet exist), so the failing test and its minimal implementation were committed together as a single `feat` commit rather than a separate `test` commit._

## Files Created/Modified
- `priv/repo/migrations/20260528150000_add_access_token_format.exs` - Adds nullable client column + defaulted-jwt server-policy column (timestamp sorts after 20260525143000).
- `lib/lockspire/domain/server_policy.ex` - `access_token_format` type + `:jwt` defstruct default.
- `lib/lockspire/storage/ecto/server_policy_record.ex` - `access_token_format` Ecto.Enum (default `:jwt`), cast list, `validate_required`, `to_domain/1`.
- `lib/lockspire/admin/server_policy.ex` - `put_access_token_format/1` runtime setter + `normalize_access_token_format/1` (no nil branch).
- `lib/lockspire/domain/client.ex` - `access_token_format` type + `nil` defstruct default (inherit).
- `lib/lockspire/storage/ecto/client_record.ex` - nullable `access_token_format` Ecto.Enum; cast in both changesets; `to_domain/1` mapping.
- `test/lockspire/admin/server_policy_test.exs` - 6 new tests (struct default, default-policy resolution, `:opaque` round-trip, string normalization, invalid atom + invalid string rejection).
- `test/lockspire/storage/ecto/client_record_test.exs` - 5 new tests (struct nil default, changeset `:opaque`, update_changeset `:jwt`, nil round-trip, `:jwt` round-trip).

## Decisions Made
None beyond the plan — followed the plan's D-04/D-06 decisions and the PATTERNS interface analogs exactly. The server-wide default is concrete `:jwt`; the per-client override is nullable (`nil` = inherit) and cast in both changesets per the explicit plan instruction.

## Deviations from Plan

None - plan executed exactly as written.

The migration module namespace was placed under `Lockspire.TestRepo.Migrations.*` to match the existing precedent (`20260430151849_add_security_profile_to_clients_and_policies.exs`); this is the established repo convention, not a deviation.

## Issues Encountered
- The fresh worktree had no fetched dependencies, so the first `mix ecto.migrate` failed with "the dependency is not available." Resolved by running `mix deps.get` (fetching the already-pinned, lockfile-declared dependencies — no new packages added; `mix.lock` is unchanged from the base commit). After that the migration applied cleanly and was idempotent on re-run.

## Verification
- `MIX_ENV=test mix ecto.migrate` applied `20260528150000` once and reported "Migrations already up" on re-run (idempotent).
- `MIX_ENV=test mix test test/lockspire/admin/server_policy_test.exs test/lockspire/storage/ecto/` → 107 tests, 0 failures.
- `MIX_ENV=test mix compile --warnings-as-errors` → clean (honors the warnings-as-errors release posture).
- `%Domain.ServerPolicy{}.access_token_format == :jwt`; `%Domain.Client{}.access_token_format == nil`; both round-trip record<->domain.

## Known Stubs
None. No signing, UI, or discovery behavior was introduced in this plan (by design — that is Plans 03 and 06). The fields and setter are fully wired and exercised by tests.

## Next Phase Readiness
- The storage + domain foundation is complete: the signer (Plan 03) can read `ServerPolicy.access_token_format` (server default) and `Client.access_token_format` (per-client override) to resolve the effective token shape, and the admin UI (Plan 06) can mutate the per-client override via `update_changeset/2` and the server-wide value via `Admin.ServerPolicy.put_access_token_format/1`.
- No blockers. Threat register mitigations T-99-01 (normalize/reject unknown values) and T-99-03 (Ecto.Enum paired with `:text` column) are both satisfied in this plan.

## Self-Check: PASSED

All created/modified files verified present on disk; all four commits (`34c709b`, `269ad4d`, `5b0721d`, `1932ed9`) verified in git history.

---
*Phase: 99-signer-extraction-jwt-default-issuance*
*Completed: 2026-05-28*
