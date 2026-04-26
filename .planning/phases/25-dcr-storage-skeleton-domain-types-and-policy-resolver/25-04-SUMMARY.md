---
phase: 25
plan: 04
subsystem: lockspire/domain
tags:
  - dcr
  - domain-types
  - defstruct
  - tdd
dependency_graph:
  requires:
    - lib/lockspire/security/policy.ex (hash_token/1 — D-14 hash-at-rest primitive)
  provides:
    - Lockspire.Domain.ServerPolicy (extended with registration_policy + 9 DCR fields)
    - Lockspire.Domain.Client (extended with provenance + 5 RAT/IAT/timestamp fields)
    - Lockspire.Domain.InitialAccessToken (NEW defstruct + typespec)
    - Lockspire.Test.Fixtures.InitialAccessTokenFixtures.initial_access_token/0,1
  affects:
    - Plan 25-05 (storage records will to_domain/1 into the new Client / ServerPolicy / IAT shapes)
    - Plan 25-06 (Admin.ServerPolicy DCR accessors return %ServerPolicy{} carrying these fields)
    - Plan 25-07 (DcrPolicy.resolve/3 reads server_policy.dcr_allowed_* directly; types are guaranteed by this plan)
    - Phase 26 (IAT redemption — token_hash equality MUST go through Security.Policy.hash_token/1)
tech_stack:
  added: []
  patterns:
    - "Defstruct + @type t :: %__MODULE__{...} mirrors the column set 1:1 (D-15)."
    - "Hash-at-rest via Lockspire.Security.Policy.hash_token/1 — single hash sink (D-14)."
    - "Test fixture factories under test/support/fixtures/ (auto-compiled via elixirc_paths(:test))."
    - "Two-value provenance enum (D-09) — IAT-vs-open recoverable via initial_access_token_id IS NOT NULL."
key_files:
  created:
    - lib/lockspire/domain/initial_access_token.ex
    - test/support/fixtures/initial_access_token_fixtures.ex
    - test/lockspire/domain/initial_access_token_test.exs
  modified:
    - lib/lockspire/domain/server_policy.ex
    - lib/lockspire/domain/client.ex
decisions:
  - "Followed plan verbatim: 2-value provenance enum, single_use boolean (not uses_remaining), schema+struct only for IAT (no behavior fns)."
  - "Test fixture file placed at test/support/fixtures/initial_access_token_fixtures.ex per plan (Claude's Discretion in 25-CONTEXT.md). Confirmed mix.exs elixirc_paths(:test) -> [\"lib\", \"test/support\"] picks it up recursively."
  - "Honored TDD gate sequence: separate test(25-04) commit before feat(25-04) fixture commit, even though both files now exist together."
metrics:
  duration_minutes: 6
  completed: "2026-04-26T15:47:00Z"
  tasks_completed: 2
  commits: 3
  files_changed: 5
  tests_added: 4
  tests_passing: 4
---

# Phase 25 Plan 04: Domain types — ServerPolicy + Client + InitialAccessToken Summary

Extended three Domain layer defstructs with all DCR fields the Plan 25-05 storage records will `to_domain/1` into, plus shipped the IAT test fixture (using `Security.Policy.hash_token/1` exclusively) and Wave 0 unit test that downstream plans consume.

## What Was Built

### `lib/lockspire/domain/server_policy.ex` (modified)

Extended in place. Added one typedef and 10 fields to both the `@type t` map and the `defstruct` defaults block:

- `@type registration_policy :: :disabled | :initial_access_token | :open` (new typedef, lines 7).
- 6 allowlist fields (all `[String.t()]`, default `[]`):
  `dcr_allowed_scopes`, `dcr_allowed_grant_types`, `dcr_allowed_response_types`,
  `dcr_allowed_redirect_uri_schemes`, `dcr_allowed_redirect_uri_hosts`,
  `dcr_allowed_token_endpoint_auth_methods`.
- 3 lifetime fields (all `non_neg_integer() | nil`, default `nil`):
  `dcr_default_client_lifetime_seconds`, `dcr_default_client_secret_lifetime_seconds`,
  `dcr_default_registration_access_token_lifetime_seconds`.
- 1 enum field: `registration_policy` (default `:disabled` — matches the column default that
  Plan 25-02's migration will install).

### `lib/lockspire/domain/client.ex` (modified)

Extended in place. Added one typedef and 6 fields to both `@type t` (lines 14–47) and `defstruct` (lines 49–88):

- `@type provenance :: :operator | :self_registered` (new typedef — TWO-value enum per D-09, not three).
- `provenance: :operator` (default — matches the `default: "operator"` column default in Plan 25-02's migration).
- 5 nullable scalars (all defaulting to `nil`):
  `registration_access_token_hash` (`String.t() | nil`),
  `registration_client_uri` (`String.t() | nil`),
  `initial_access_token_id` (`integer() | nil`),
  `client_id_issued_at` (`DateTime.t() | nil`),
  `client_secret_expires_at` (`DateTime.t() | nil`).

NO existing fields touched, NO reorderings. The `update_changeset/2` in `client_record.ex` is intentionally untouched per plan instruction (provenance is a create-time invariant; Plan 25-05's concern).

### `lib/lockspire/domain/initial_access_token.ex` (NEW)

Brand-new defstruct + typespec only — **zero behavior functions**. Mirrors the Plan 25-03
column set 1:1 per D-15 (10 fields including `id`/`inserted_at`/`updated_at`):

- `single_use: true` default (boolean, D-13).
- `token_hash: String.t() | nil` (nil at struct-construction; required at insert via Plan 05's changeset).
- `policy_overrides: map() | nil` (jsonb on disk).
- `revoked_at: DateTime.t() | nil` (soft-delete field, D-12).
- Moduledoc documents the `policy_overrides` boundary (T-25-05): Phase 25 ships the field as
  opaque storage; narrowing-at-mint is a Phase 28 concern; resolve-time intersection cannot
  widen per D-18.

`Lockspire.Protocol.InitialAccessToken.redeem/1` is explicitly NOT in this file — that's
Phase 26 (DCR-11). This module is schema + struct only.

### `test/support/fixtures/initial_access_token_fixtures.ex` (NEW)

First `.ex` file in `test/support/fixtures/`. Provides:

- `initial_access_token(attrs \\ %{})` — builds a `%Lockspire.Domain.InitialAccessToken{}` with
  `token_hash = Lockspire.Security.Policy.hash_token(plaintext)`, `expires_at` 1h in the future,
  `single_use: true`. Caller can pass `:plaintext` for deterministic hash; otherwise random
  32-byte plaintext is generated and hashed. `:plaintext` is consumed (`Map.pop`), never
  retained as a struct key. Other attrs override defaults via `struct!/2`.
- `default_plaintext/0` — 32 random bytes base64url-encoded, no padding (mirrors the
  random-token idiom used elsewhere in the codebase).

T-25-02 mitigation: `grep -c ':crypto.hash(:sha256' = 0` in this file. The fixture goes
through `Security.Policy` exclusively.

### `test/lockspire/domain/initial_access_token_test.exs` (NEW)

First file under the new `test/lockspire/domain/` directory. `use ExUnit.Case, async: true`
(pure-function tests, no DB sandbox). Four tests:

1. Empty struct defaults match D-11 / D-13 (`single_use == true`, others nil).
2. Fixture hashes plaintext via `Security.Policy.hash_token/1` byte-for-byte (sha256 lowercase
   hex, 64 chars, lowercase invariant).
3. Fixture lets attrs override defaults; `:plaintext` is consumed (not retained as key).
4. Fixture default plaintext yields unique `token_hash` per call.

## TDD Gate Compliance

Plan task 2 was authored as RED → GREEN:

- **RED gate:** commit `3dcf6b1` (`test(25-04): add Wave 0 unit test for Domain.InitialAccessToken defstruct + IAT fixture contract`) — landed test file alone. Confirmed 4 tests / 3 failures (`UndefinedFunctionError` for the not-yet-existing fixture module; the 4th test — empty-struct defaults — passed because Task 1's defstruct was already in place).
- **GREEN gate:** commit `ebfa277` (`feat(25-04): add InitialAccessTokenFixtures factory using Security.Policy.hash_token/1`) — added fixture; tests now 4/0.
- **REFACTOR gate:** none needed; minimal implementation already clean.

Plan-level frontmatter is `type: execute` (not `type: tdd`), so no plan-level RED/GREEN gate is
strictly required — but the `tdd="true"` task-level flag was honored regardless.

Task 1 (`tdd="true"`) had no separate test file in the plan's `<files>` block; the runtime
defaults were verified via `mix run --no-start --eval` and the IAT defaults were exercised by
Task 2's first test (`empty struct defaults match D-11 / D-13`).

## Verification

| Check | Result |
|-------|--------|
| `mix compile --warnings-as-errors` | Clean |
| `mix format --check-formatted` (5 plan files) | Clean |
| `mix test test/lockspire/domain/initial_access_token_test.exs` | 4 tests, 0 failures |
| `mix test test/lockspire/protocol/par_policy_test.exs` (regression) | 6 tests, 0 failures |
| Empty-struct default `%ServerPolicy{}.registration_policy` | `:disabled` |
| Empty-struct default `%Client{}.provenance` | `:operator` |
| Empty-struct default `%InitialAccessToken{}.single_use` | `true` |
| `grep ':self_registered' lib/.../client.ex` | 1 (TWO-value enum present) |
| `grep ':dcr_initial_access_token\|:dcr_open' lib/.../client.ex` | 0 (3-value form NOT present) |
| `grep ':crypto.hash(:sha256' test/.../initial_access_token_fixtures.ex` | 0 (T-25-02 mitigation: never hand-roll a hash) |
| `grep 'uses_remaining' lib/.../initial_access_token.ex` | 0 (boolean single_use form, not N-use) |

All Task 1 (15 acceptance criteria) and Task 2 (9 acceptance criteria) checks pass.

## Commits

| Commit | Type | Files | Description |
|--------|------|-------|-------------|
| `020ba47` | feat | 3 | Extend Domain.ServerPolicy/Client and create Domain.InitialAccessToken for DCR |
| `3dcf6b1` | test | 1 | Add Wave 0 unit test for Domain.InitialAccessToken defstruct + IAT fixture contract |
| `ebfa277` | feat | 1 | Add InitialAccessTokenFixtures factory using Security.Policy.hash_token/1 |

## Deviations from Plan

None — plan executed exactly as written. Both tasks ran clean on first attempt; no Rule 1/2/3
auto-fixes were needed and no Rule 4 architectural questions arose.

## Deferred Issues

### Pre-existing test failure (out of plan scope)

`test/lockspire/release_readiness_contract_test.exs:250` ("planning metadata and repo truth keep
PAR scoped to the narrow v1.3 slice") asserts `PROJECT.md` contains
`"Current Milestone: v1.3 PAR Policy Controls"` but the project has advanced to v1.5. Confirmed
pre-existing via `git stash` against the base commit `54a450c` — the failure reproduces with
zero Phase 25 changes applied. Recorded in
`.planning/phases/25-dcr-storage-skeleton-domain-types-and-policy-resolver/deferred-items.md`.
Recommend Phase 29 closure work updates this assertion.

## Authentication Gates

None. This plan is pure-Elixir / no-DB / no-network.

## Notes for Downstream Plans

### For Plan 25-05 (Ecto storage records)

`Storage.Ecto.{ServerPolicyRecord, ClientRecord, InitialAccessTokenRecord}.to_domain/1`
mappings MUST populate every new field shipped here, or values fall through as `nil` per
struct defaults (Open Question 1 in research). Specifically:

- `ServerPolicyRecord.to_domain/1` must populate the 9 new DCR fields plus `registration_policy`.
- `ClientRecord.to_domain/1` must populate `provenance` plus 5 RAT/IAT/timestamp fields.
- `InitialAccessTokenRecord.to_domain/1` is brand-new; map all 10 fields directly.

Schema round-trip tests for these mappings live in Plan 25-05; this plan deliberately ships
**zero** storage-layer code per the plan's `<success_criteria>` ("ZERO touches to
`lib/lockspire/storage/`...").

### For Plan 25-06 (Admin.ServerPolicy DCR accessors)

`Admin.ServerPolicy.get_dcr_policy/0` returns a `%ServerPolicy{}` carrying the new fields
typed exactly as defined in this plan; the `put_dcr_policy/1` mutator accepts the same shape.

### For Plan 25-07 (DcrPolicy.resolve/3)

The resolver reads `server_policy.dcr_allowed_*` (lists of `String.t()`) and
`iat.policy_overrides` (`map() | nil`) directly. Both shapes are guaranteed by this plan. The
`%InitialAccessToken{}` is the intersection target of `Lockspire.Protocol.DcrPolicy.resolve/3`'s
second arity-3 argument when non-nil.

### For Phase 26 (IAT redemption)

The `token_hash` equality check in `Lockspire.Protocol.InitialAccessToken.redeem/1` MUST go
through `Lockspire.Security.Policy.hash_token/1` — the fixture in this plan establishes that
contract, and Phase 26's redemption will use the same primitive. Drift in either direction
silently breaks redemption.

## Self-Check: PASSED

All claims verified before write:

- `lib/lockspire/domain/server_policy.ex` — FOUND
- `lib/lockspire/domain/client.ex` — FOUND
- `lib/lockspire/domain/initial_access_token.ex` — FOUND
- `test/lockspire/domain/initial_access_token_test.exs` — FOUND
- `test/support/fixtures/initial_access_token_fixtures.ex` — FOUND
- Commit `020ba47` — FOUND in `git log`
- Commit `3dcf6b1` — FOUND in `git log`
- Commit `ebfa277` — FOUND in `git log`
