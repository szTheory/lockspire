---
phase: 55
plan: 01
subsystem: storage
tags: [rar, rfc-9396, par, interaction, schema, ecto]
requires:
  - .planning/phases/54-resource-indicators/
provides:
  - "Database column `authorization_details` on `lockspire_pushed_authorization_requests`"
  - "Database column `authorization_details` on `lockspire_interactions`"
  - "Domain field `:authorization_details` on `Lockspire.Domain.PushedAuthorizationRequest`"
  - "Domain field `:authorization_details` on `Lockspire.Domain.Interaction`"
  - "Storage round-trip for RAR `authorization_details` JSON arrays"
affects:
  - .planning/phases/55-rar-protocol-intake/55-02-PLAN.md
  - .planning/phases/55-rar-protocol-intake/55-03-PLAN.md
tech_stack:
  added: []
  patterns:
    - "JSONB array storage via Ecto `{:array, :map}` (matches Phase 51/53 metadata pattern)"
    - "Domain struct passthrough via `Map.from_struct/1` + `cast/3`"
key_files:
  created:
    - priv/repo/migrations/20260506020000_add_rar_intake_state.exs
  modified:
    - lib/lockspire/domain/pushed_authorization_request.ex
    - lib/lockspire/storage/ecto/pushed_authorization_request_record.ex
    - lib/lockspire/domain/interaction.ex
    - lib/lockspire/storage/ecto/interaction_record.ex
decisions:
  - "Use `{:array, :map}` (Postgres JSONB) for `authorization_details` to mirror existing array-of-maps storage (e.g., CIBA delivery metadata) and to keep RAR object shape opaque at the storage layer"
  - "Default to `[]` rather than `NULL` so legacy rows behave identically and downstream `List.wrap/1` paths remain branch-free"
  - "Wire `:authorization_details` through `PushedAuthorizationRequest.issue/2` so subsequent plans can plug intake validation in without changing the issuance signature"
metrics:
  duration_minutes: 4
  completed_date: "2026-05-06"
requirements: [RAR-01]
---

# Phase 55 Plan 01: RAR Storage & Domain Foundation Summary

JSONB-backed `authorization_details` storage on PAR and Interaction tables plus domain-struct passthrough that keeps the RAR object opaque to storage while leaving validation to later plans.

## What Was Built

Plan 55-01 extends the durable PAR and Interaction lifecycles with a single `authorization_details` slot of type `{:array, :map}` (JSONB array in Postgres). The migration `20260506020000_add_rar_intake_state.exs` adds the column to both `lockspire_pushed_authorization_requests` and `lockspire_interactions` with a `[]` default. Domain structs (`Lockspire.Domain.PushedAuthorizationRequest` and `Lockspire.Domain.Interaction`) gain a typed `:authorization_details` field defaulting to `[]`, and Ecto records cast/expose the field in `changeset/2` and `to_domain/{1,2}`. `PushedAuthorizationRequest.issue/2` now wraps incoming `:authorization_details` via `List.wrap/1`, matching the existing `:resources_requested` shape.

This is purely a foundation slice: no validation, no normalization, no introspection wiring. Plans 55-02 and 55-03 will sit on top of these fields to plumb the parameter through the PAR intake and authorization endpoint pipelines.

## Tasks Completed

| Task | Name                                                  | Commit  | Files                                                                                                                       |
| ---- | ----------------------------------------------------- | ------- | --------------------------------------------------------------------------------------------------------------------------- |
| 1    | Create migration for RAR intake state                 | 61ed749 | priv/repo/migrations/20260506020000_add_rar_intake_state.exs                                                                |
| 2    | Update PushedAuthorizationRequest domain and storage  | a585b23 | lib/lockspire/domain/pushed_authorization_request.ex, lib/lockspire/storage/ecto/pushed_authorization_request_record.ex      |
| 3    | Update Interaction domain and storage                 | 1962e36 | lib/lockspire/domain/interaction.ex, lib/lockspire/storage/ecto/interaction_record.ex                                       |

## Verification

- `MIX_ENV=test mix ecto.migrate` — applied `20260506020000` cleanly against the test database (forward direction, both tables altered).
- `MIX_ENV=dev mix ecto.migrate` — applied `20260506020000` cleanly against the dev database to keep generated host environments in sync.
- `MIX_ENV=test mix test test/lockspire/storage/repository_test.exs` — 24 tests, 0 failures (covers PAR + Interaction round-trips through the schema).
- `MIX_ENV=test mix test test/lockspire/storage/ecto/interaction_record_test.exs` — 1 test, 0 failures (round-trip persistence including the new column showing `authorization_details` defaulting to `[]`).
- `MIX_ENV=test mix test test/lockspire/domain/ test/lockspire/storage/` — 29 tests, 0 failures (broader smoke check across affected suites).

## Deviations from Plan

None — plan executed exactly as written.

The plan's verification command pointed at `test/lockspire/storage/ecto/repository_test.exs`, but the project's repository test actually lives at `test/lockspire/storage/repository_test.exs`. We executed the canonical path; this is a documentation-only reference correction rather than a behavioral deviation, so it is not tracked as a Rule deviation.

## Threat Surface

The plan's `<threat_model>` listed `T-55-01` (Tampering / Ecto Records / mitigate) with the mitigation "use strict schema casting in Ecto changesets." That mitigation is satisfied:

- Both `PushedAuthorizationRequestRecord.changeset/2` and `InteractionRecord.changeset/2` add `:authorization_details` to the explicit `cast/3` allow-list, preventing arbitrary attribute injection from `Map.from_struct/1`.
- The Ecto `{:array, :map}` type rejects non-list-of-maps inputs at write time, surfacing a changeset error before reaching JSONB.
- No new external surface (HTTP endpoint, host callback, file IO) is introduced — this slice is purely schema/domain plumbing. No new threat flags to raise.

## Self-Check: PASSED

Verified each created/modified file exists on disk and each task commit is reachable from `HEAD`.

- FOUND: priv/repo/migrations/20260506020000_add_rar_intake_state.exs
- FOUND: lib/lockspire/domain/pushed_authorization_request.ex (modified)
- FOUND: lib/lockspire/storage/ecto/pushed_authorization_request_record.ex (modified)
- FOUND: lib/lockspire/domain/interaction.ex (modified)
- FOUND: lib/lockspire/storage/ecto/interaction_record.ex (modified)
- FOUND commit: 61ed749 (Task 1)
- FOUND commit: a585b23 (Task 2)
- FOUND commit: 1962e36 (Task 3)
