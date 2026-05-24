# Phase 25: DCR Storage Skeleton, Domain Types, and Policy Resolver - Research

**Researched:** 2026-04-26
**Domain:** Elixir/Phoenix/Ecto — additive Ecto migrations + domain defstruct extensions + Postgres-backed singleton policy + new `lockspire_initial_access_tokens` table + intersection-only `Lockspire.Protocol.DcrPolicy.resolve/3` resolver bound to `Discovery.token_endpoint_auth_methods_supported/0` via invariant test
**Confidence:** HIGH

## Summary

Phase 25 lays the durable substrate for the v1.5 DCR milestone: three additive Ecto migrations, three extended domain defstructs (`ServerPolicy`, `Client`, plus a new `InitialAccessToken`), one extended admin surface (`Admin.ServerPolicy`), one new resolver module (`Lockspire.Protocol.DcrPolicy`), and one in-phase Discovery extraction (a public `/0` accessor for `token_endpoint_auth_methods_supported`). It ships **zero** user-visible behavior — no HTTP routes, no LiveView, no IAT redemption logic — and prepares every seam later phases call into.

The dominant move is **structural mirroring**: Phase 25 copies the v1.3 PAR additive-migration template (`priv/repo/migrations/20260424180000_add_lockspire_server_policy_and_client_par_policy.exs`) and the `lib/lockspire/protocol/par_policy.ex` resolver shape one-to-one. The CONTEXT.md correctly flags that **`par_policy.ex` is the only existing resolver precedent in the repo** — there is no `jar_policy.ex` (verified: `ls lib/lockspire/protocol/` shows `par_policy.ex` but not `jar_policy.ex`). Plans must cite PAR, not JAR, as the structural template.

**Primary recommendation:** Execute the plan as five tightly-coupled task groups in this order — (1) extend `Discovery` with a public `/0` accessor (smallest change, unblocks invariant test); (2) ship the three additive migrations with in-place `default:` backfill; (3) extend `Domain.ServerPolicy` + `Storage.Ecto.ServerPolicyRecord` + `Admin.ServerPolicy.{get,put}_dcr_policy/0,1`; (4) extend `Domain.Client` + `Storage.Ecto.ClientRecord` schema/changeset/`to_domain`; (5) create `Domain.InitialAccessToken` + `Storage.Ecto.InitialAccessTokenRecord` (struct + schema only — no redemption logic) + new `Lockspire.Protocol.DcrPolicy` module with `Resolved` substruct and the discovery-binding invariant test. All in-phase, no Phase 26 logic leaks in.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Add DCR columns to existing `lockspire_server_policies` row | Database / Storage | — | Postgres-backed singleton policy state already lives here (PAR pattern) |
| Add DCR provenance + RAT/timestamp fields to `lockspire_clients` | Database / Storage | — | One-table widening; existing rows backfill via `default:` at `ADD COLUMN` time (atomic in Postgres) |
| Create `lockspire_initial_access_tokens` table with `unique_index([:token_hash])` | Database / Storage | — | Multi-row credential lifecycle; new table; index is required from Phase 25 because Phase 26 atomic redemption depends on it (per D-03) |
| Domain types (`ServerPolicy`, `Client`, `InitialAccessToken` defstructs) | Domain | — | Plain Elixir defstructs that storage maps onto via `to_domain/1` |
| `Admin.ServerPolicy.{get,put}_dcr_policy/0,1` operator surface | Admin / Application | Domain | Mirrors `get_server_policy/0` / `put_server_policy/1` shape; Phase 28 LiveView consumes this |
| `Lockspire.Protocol.DcrPolicy.resolve/3` intersection-only resolver | Protocol Core | Domain | Pure-function resolver mirroring `Lockspire.Protocol.ParPolicy` `Resolved` substruct shape (NOT `JarPolicy` — does not exist) |
| Public `Discovery.token_endpoint_auth_methods_supported/0` accessor | Protocol Core | — | In-phase extraction of an existing `@module_attribute` + private `/1` helper into a public `/0` function so the invariant test does not poke private state |
| Discovery-binding invariant test (`MapSet.intersection` equality) | Test (Protocol Core) | — | Asserts DCR-accepted methods equal `MapSet.intersection(server_allowlist, discovery_supported_set)`; fails on either-side drift |

**Tier check:** All capabilities live in Lockspire's existing Domain / Storage / Admin / Protocol Core / Test layers — there is no UI, HTTP, or LiveView work in this phase. This matches the Build Order Level 1 partition in `.planning/research/ARCHITECTURE.md`.

## User Constraints (from CONTEXT.md)

### Locked Decisions

**Migration shape & ordering:**
- **D-01:** Three additive Ecto migrations in `priv/repo/migrations/`, in this order: (a) extend `lockspire_server_policies` with DCR fields, (b) extend `lockspire_clients` with provenance + RAT/timestamp fields and backfill `provenance = 'operator'` in the same migration, (c) create `lockspire_initial_access_tokens`. New columns use `null: false, default: '<atom-as-string>'` for enums and `{:array, :text}` for allowlists, mirroring the v1.3 PAR-policy additive migration at `priv/repo/migrations/20260424180000_add_lockspire_server_policy_and_client_par_policy.exs`.
- **D-02:** Existing `lockspire_clients` rows backfill via the `default: 'operator'` column default at `ADD COLUMN` time — no separate data-migration step. Postgres `ADD COLUMN ... NOT NULL DEFAULT` is atomic.
- **D-03:** `lockspire_initial_access_tokens` carries `unique_index(:lockspire_initial_access_tokens, [:token_hash])` from this phase. Phase 26's atomic single-use redemption depends on this index existing.

**ServerPolicy field shape and Admin surface:**
- **D-04:** DCR fields land as **top-level columns** on `lockspire_server_policies` — not as an embedded `:dcr` map or a separate `lockspire_dcr_policy` table. Mirrors the established PAR pattern at `lib/lockspire/storage/ecto/server_policy_record.ex:14`.
- **D-05:** `registration_policy` is a `text` column cast to `Ecto.Enum` with values `:disabled | :initial_access_token | :open` and default `:disabled`. Tri-state, not split into two booleans.
- **D-06:** Allowlists are `{:array, :text}` columns: `dcr_allowed_scopes`, `dcr_allowed_grant_types`, `dcr_allowed_response_types`, `dcr_allowed_redirect_uri_schemes`, `dcr_allowed_redirect_uri_hosts`, `dcr_allowed_token_endpoint_auth_methods`. Lifetimes are `:integer` second-counts: `dcr_default_client_lifetime_seconds`, `dcr_default_client_secret_lifetime_seconds`, `dcr_default_registration_access_token_lifetime_seconds`.
- **D-07:** `Admin.ServerPolicy` is **extended in place** with `get_dcr_policy/0` and `put_dcr_policy/1` returning/accepting a `%DcrPolicy{}` substruct view; the existing `get_server_policy/0` / `put_server_policy/1` shape at `lib/lockspire/admin/server_policy.ex:11-22` is the template.

**Client provenance fields and backfill:**
- **D-08:** `lockspire_clients` gains seven additive columns: `provenance` (`text`, NOT NULL, default `'operator'`), `registration_access_token_hash` (`text`, nullable), `registration_client_uri` (`text`, nullable), `initial_access_token_id` (`bigint`, nullable, FK to `lockspire_initial_access_tokens(id)` `on_delete: :restrict`), `client_id_issued_at` (`utc_datetime_usec`, nullable), `client_secret_expires_at` (`utc_datetime_usec`, nullable). Timestamp types mirror existing fields at `lib/lockspire/domain/client.ex:38-46`.
- **D-09:** **Two-value provenance enum**: `:operator | :self_registered`. Not three. The IAT-vs-open distinction at registration time is recoverable via `initial_access_token_id IS NOT NULL` and is a Phase 26/28 concern, not a column shape decision.
- **D-10:** The IAT FK uses `on_delete: :restrict` — operators cannot delete an IAT that minted a still-existing client. Soft-delete (`revoked_at`) is the supported way to retire an IAT.

**InitialAccessToken schema:**
- **D-11:** `lockspire_initial_access_tokens` columns: `id` (bigserial), `token_hash` (`text`, NOT NULL, unique), `expires_at` (`utc_datetime_usec`, NOT NULL), `single_use` (`boolean`, NOT NULL, default `true`), `used_at` (`utc_datetime_usec`, nullable), `revoked_at` (`utc_datetime_usec`, nullable), `policy_overrides` (`jsonb`, nullable), `created_by` (`text`, nullable — operator id), `timestamps(type: :utc_datetime_usec)`.
- **D-12:** Soft-delete-only via `revoked_at IS NOT NULL` in Phase 25. No hard-delete pathway.
- **D-13:** `single_use` is a boolean (default `true`), not a `uses_remaining` integer.
- **D-14:** Hash-at-rest reuses `Lockspire.Security.Policy.hash_token/1` at `lib/lockspire/security/policy.ex:84-89` (sha256, lowercase hex) — no new hash primitive. Phase 26 redemption compares against this same function.
- **D-15:** `Lockspire.Domain.InitialAccessToken` is a defstruct that mirrors the column set one-to-one. Phase 25 ships **schema + struct only** — `Lockspire.Protocol.InitialAccessToken.redeem/1` is Phase 26 (DCR-11).

**DcrPolicy resolver shape and discovery binding:**
- **D-16:** `Lockspire.Protocol.DcrPolicy` at `lib/lockspire/protocol/dcr_policy.ex` exposes `resolve(server_policy, iat_overrides_or_nil, inbound_metadata) :: {:ok, %Resolved{}} | {:error, :invalid_client_metadata, %{field: atom(), reason: atom(), allowed: list()}}`. Arity-3 is locked by DCR-08. Mirror `lib/lockspire/protocol/par_policy.ex:1-52`.
- **D-17:** Resolution semantics: per-allowlist `MapSet.intersection/2` between server-allowlist, IAT-overrides (when non-nil), and inbound metadata. Any inbound value not in the server-allowlist returns `{:error, :invalid_client_metadata, %{field: ..., reason: ..., allowed: ...}}` naming the offending field.
- **D-18:** **IAT overrides are assumed already-narrowed to ⊆ server allowlist at IAT-mint time** (Phase 28 admin path) and are *not* re-validated for widening at `resolve/3` time.
- **D-19:** Invariant test lives at `test/lockspire/protocol/dcr_policy_invariant_test.exs` and asserts `MapSet.equal?(MapSet.intersection(server_allowlist, discovery_supported_set), accepted_dcr_set)` — failing if either side drifts.
- **D-20:** **Add a public `Lockspire.Protocol.Discovery.token_endpoint_auth_methods_supported/0` accessor** in this phase (does not exist today — only a private `/1` plus a module attribute at `discovery.ex:21,82`). Small in-phase task.

### Claude's Discretion

- File-internal layout of `dcr_policy.ex` (helpers, internal struct fields, doctests) may follow `par_policy.ex` ergonomics without further user sign-off.
- Test fixture factories for IAT (e.g., `test/support/fixtures/initial_access_token_fixtures.ex` if one is added) follow existing fixture naming and may be added without further sign-off.
- Migration filenames follow the standard timestamped Ecto convention; no naming negotiation required.

### Deferred Ideas (OUT OF SCOPE)

- **3-value provenance enum** (`:operator | :dcr_initial_access_token | :dcr_open`) — future-proofs audit-event vocabulary. Recoverable later via column type widening; v1.5 uses two-value form.
- **`uses_remaining` N-use IATs** — would require a schema migration; out of scope for v1.5.
- **Per-IAT `policy_overrides` admin UI** — column lands now (DCR-10); UI is DCR-FUT-03.
- **`jwks_uri` outbound fetch** — DCR-FUT-01; rejected at intake in Phase 26.
- **Built-in rate limiting on `POST /register`** — DCR-FUT-04; host-side Plug seam documented in Phase 29.
- **Embedded `:dcr` substruct on `Domain.ServerPolicy`** — adds serialization layer that breaks PAR symmetry.
- **Separate `lockspire_dcr_policy` table** — premature normalization for a row count of 1.
- **Combined `consumed_at` field on IAT** (instead of `revoked_at` + `used_at`) — loses operator-revoked vs registrant-consumed distinction.

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| DCR-06 | `Lockspire.Domain.ServerPolicy` exposes a 3-mode `registration_policy` field (`:disabled` default \| `:initial_access_token` \| `:open`) with a singleton row in `lockspire_server_policies`. | Standard Stack §`Ecto.Enum` text-cast pattern; Code Examples §1 (migration template); Code Examples §3 (defstruct widening) |
| DCR-07 | ServerPolicy DCR allowlists (scopes, grant_types, response_types, redirect-URI hosts/schemes, `token_endpoint_auth_method`) and DCR defaults (client lifetime, `client_secret` expiry, RAT lifetime) bind intake; metadata that exceeds an allowlist is rejected with `invalid_client_metadata`. | Architecture Patterns §Pattern 1 (intersection resolver); Code Examples §5 (resolver intersection helpers); Common Pitfalls §Pitfall 11 (allowlist enforcement) |
| DCR-08 | `Lockspire.Protocol.DcrPolicy.resolve/3` produces an effective policy as the intersection of server, IAT, and inbound metadata; the resolver is intersection-only and never widens. | Architecture Patterns §Pattern 1; Code Examples §5; Common Pitfalls §Pitfall 11 |
| DCR-09 | The set of `token_endpoint_auth_method` values DCR will accept is the intersection of the ServerPolicy DCR allowlist and `Lockspire.Protocol.Discovery.token_endpoint_auth_methods_supported/0`; an invariant test asserts this binding. | Code Examples §6 (Discovery `/0` extraction); Code Examples §7 (invariant test shape); Common Pitfalls §Pitfall 7 (truth-binding) |
| DCR-10 | `Lockspire.Domain.InitialAccessToken` and the `lockspire_initial_access_tokens` table persist IATs with hash-at-rest, expiry, single-use default, and a nullable `policy_overrides` JSONB column. | Code Examples §2 (IAT migration); Code Examples §4 (IAT defstruct + schema); Standard Stack §hash-at-rest reuses `Security.Policy.hash_token/1` |

## Project Constraints (from AGENTS.md)

These directives have the same authority as locked decisions:

- **Embedded library shape:** Lockspire is not a standalone auth service; do not add hosted-service deps.
- **Strong internal boundaries:** protocol core, storage, generators, Plug/Phoenix integration, LiveView/admin must stay separated. Phase 25 work touches Domain, Storage, Admin, and Protocol layers — keep each commit scoped to one boundary.
- **Tech stack pinned:** Phoenix 1.8.5, Phoenix LiveView 1.1.28, Ecto SQL 3.13.5, PostgreSQL 14+, Bandit 1.6.1, Oban 2.21.x, OpenTelemetry 1.6.0. **Do not add or upgrade any runtime dep in Phase 25.** All new code is internal modules + migrations.
- **Security defaults to preserve:** PKCE S256 by default; exact-match redirect URI validation; client secrets hashed at rest; no implicit flow; no `alg=none`. Phase 25 does not touch any of these but the resolver design must not enable later phases to violate them.

(Verified: `cat AGENTS.md`. No `./CLAUDE.md` exists at repo root — the AGENTS.md is the project guide.)

## Standard Stack

### Core (already pinned, no changes)

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `ecto_sql` | `~> 3.13.5` | Three additive migrations, schema extensions, singleton-row record (`ServerPolicyRecord`), new `InitialAccessTokenRecord` | Already the durable boundary for all Lockspire state |
| `postgrex` | `>= 0.0.0` | Postgres driver — `ADD COLUMN ... NOT NULL DEFAULT` is atomic in Postgres (key for D-02 backfill) | [VERIFIED: Postgres 14 docs] standard behavior; in-place backfill works without a separate data-migration step |
| `:crypto` (OTP stdlib) | n/a | sha256 lowercase-hex hashing reused via `Lockspire.Security.Policy.hash_token/1` for IAT `token_hash` | No new primitive; D-14 reuses the existing one |
| ExUnit (stdlib) | n/a | All Phase 25 tests (schema round-trip, resolver intersection, invariant binding) | Existing test infra; no framework changes |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `Ecto.Enum` | (built into ecto_sql) | Cast text columns to atoms (`:disabled | :initial_access_token | :open`, `:operator | :self_registered`) | Used in `ServerPolicyRecord` (`par_policy` precedent at line 14) and `ClientRecord` (`token_endpoint_auth_method` at line 25) |
| `MapSet` (stdlib) | n/a | Per-allowlist set intersection in `DcrPolicy.resolve/3` | D-17 specifies `MapSet.intersection/2`; D-19 invariant test uses `MapSet.equal?(MapSet.intersection(...), ...)` |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `MapSet.intersection/2` | `Enum.filter/2` with `Enum.member?/2` | O(n*m) vs MapSet O(n+m). With small allowlists (≤10 items) either works, but MapSet is the idiomatic Elixir choice and reads cleanly in test assertions (`MapSet.equal?/2`). [ASSUMED] |
| Top-level columns on `lockspire_server_policies` | Embedded `:dcr` map field | D-04 locks top-level columns. Reasoning: PAR symmetry, easier `Ecto.Changeset.cast/3`, no JSONB serialization layer to test. |
| Separate `lockspire_dcr_policy` table | Add fields to existing singleton | D-04 locks singleton extension. Reasoning: row count is 1 (PAR/JAR/DCR all share one server-wide policy row); separate table is premature normalization. |
| `single_use boolean` | `uses_remaining int` | D-13 locks boolean. Reasoning: v1.5 admin mints single-use IATs only; boolean keeps Phase 26 redemption simpler (`UPDATE ... WHERE used_at IS NULL`) than decrement-and-check. |
| Two-value `provenance` enum (`:operator | :self_registered`) | Three-value (`:operator | :dcr_initial_access_token | :dcr_open`) | D-09 locks two-value. The IAT-vs-open distinction is recoverable via `initial_access_token_id IS NOT NULL`. Three-value is deferred and recoverable via column-type widening. |

**Installation:** None. All deps already pinned in `mix.exs`.

**Version verification:** Verified `ecto_sql 3.13.5`, `postgrex` (any), `phoenix 1.8.5`, `phoenix_live_view 1.1.28` are pinned per `AGENTS.md` Technology Stack section (no `mix.exs` deps changes required). Postgres 14.17 verified locally via `psql --version`.

## Architecture Patterns

### System Architecture Diagram (Phase 25 scope only)

```
                     ┌────────────────────────────────────────┐
                     │ priv/repo/migrations/  (3 new files)   │
                     │   1) extend server_policies (DCR cols) │
                     │   2) extend clients (7 cols + backfill)│
                     │   3) create initial_access_tokens      │
                     └────────────────────────────────────────┘
                                      │ schema reflects into
                                      ▼
┌─────────────────────────────────────────────────────────────────────────┐
│ lib/lockspire/storage/ecto/                                             │
│   ServerPolicyRecord   (extend with DCR fields, casts, to_domain)       │
│   ClientRecord         (extend with 7 fields, casts, to_domain)         │
│   InitialAccessTokenRecord  ◀── NEW                                      │
└─────────────────────────────────────────────────────────────────────────┘
                                      │ to_domain/1 returns
                                      ▼
┌─────────────────────────────────────────────────────────────────────────┐
│ lib/lockspire/domain/                                                   │
│   ServerPolicy           (extend defstruct + typespec — DCR fields)     │
│   Client                 (extend defstruct + typespec — 7 fields)       │
│   InitialAccessToken     ◀── NEW defstruct                               │
└─────────────────────────────────────────────────────────────────────────┘
                                      │ consumed by
                ┌─────────────────────┴─────────────────────┐
                ▼                                           ▼
┌──────────────────────────────────┐        ┌──────────────────────────────────┐
│ lib/lockspire/admin/             │        │ lib/lockspire/protocol/          │
│   ServerPolicy (extend)          │        │   DcrPolicy.ex  ◀── NEW           │
│     get_dcr_policy/0             │        │     %Resolved{}                  │
│     put_dcr_policy/1             │        │     resolve/3 (intersection)     │
└──────────────────────────────────┘        │   Discovery (extend)             │
                                            │     token_endpoint_auth_methods_ │
                                            │     supported/0  ◀── public /0    │
                                            └──────────────────────────────────┘
                                                                ▲
                                                                │ asserted by
                                            ┌──────────────────────────────────┐
                                            │ test/lockspire/protocol/         │
                                            │   dcr_policy_invariant_test.exs  │
                                            │     MapSet.equal?(intersect, ...)│
                                            └──────────────────────────────────┘
```

**Data flow (the only flow Phase 25 exercises):**
- **Operator UI write path (Phase 28; not built here, but the seam is shipped):** UI → `Admin.ServerPolicy.put_dcr_policy/1` → `Repository.put_server_policy/1` → `lockspire_server_policies` (singleton row, lock-for-update transaction).
- **Operator UI read path:** UI → `Admin.ServerPolicy.get_dcr_policy/0` → `Repository.get_server_policy/0` → `ServerPolicyRecord.to_domain/1` → `%Domain.ServerPolicy{}` (with new DCR fields).
- **Resolver call (Phase 26 will invoke; tested standalone in Phase 25):** caller → `DcrPolicy.resolve(server_policy, iat_or_nil, inbound_metadata)` → returns `{:ok, %Resolved{}}` or `{:error, :invalid_client_metadata, %{field, reason, allowed}}`.
- **Invariant binding (test-only):** test → `Discovery.token_endpoint_auth_methods_supported/0` + `ServerPolicy.dcr_allowed_token_endpoint_auth_methods` → `MapSet.intersection/2` → assert equals the set the resolver accepts.

### Recommended Project Structure (Phase 25 deltas only)

```
lib/lockspire/
├── domain/
│   ├── server_policy.ex                  # EXTEND: add registration_policy + dcr_* fields
│   ├── client.ex                         # EXTEND: add provenance + RAT/IAT/timestamp fields
│   └── initial_access_token.ex           # NEW (defstruct + typespec only)
├── storage/ecto/
│   ├── server_policy_record.ex           # EXTEND: add fields, cast list, to_domain mapping
│   ├── client_record.ex                  # EXTEND: add fields, cast list, to_domain mapping
│   └── initial_access_token_record.ex    # NEW (Ecto.Schema + changeset + to_domain)
├── protocol/
│   ├── dcr_policy.ex                     # NEW (Resolved substruct + resolve/3)
│   └── discovery.ex                      # EXTEND: add public token_endpoint_auth_methods_supported/0
├── admin/
│   └── server_policy.ex                  # EXTEND: get_dcr_policy/0 + put_dcr_policy/1
└── priv/repo/migrations/
    ├── <ts>_add_dcr_fields_to_server_policies.exs   # NEW
    ├── <ts>_add_dcr_fields_to_clients.exs           # NEW (with backfill via default:)
    └── <ts>_create_initial_access_tokens.exs        # NEW (with unique_index on token_hash)

test/lockspire/protocol/
├── dcr_policy_test.exs                   # NEW (resolver intersection tests)
└── dcr_policy_invariant_test.exs         # NEW (Discovery binding invariant)

test/lockspire/admin/
└── server_policy_test.exs                # EXTEND: add DCR get/put cases (existing pattern)

test/lockspire/storage/ecto/
├── server_policy_record_test.exs         # EXTEND: schema round-trip with DCR fields
├── client_record_test.exs                # EXTEND: schema round-trip with new fields + provenance default
└── initial_access_token_record_test.exs  # NEW (schema round-trip + unique constraint test)
```

### Pattern 1: Intersection-only resolver with `Resolved` substruct

**What:** A protocol module that takes inputs of varying authority (server-wide, IAT-narrowing, inbound) and returns either a `%Resolved{}` substruct or a typed error. The resolver never widens — every output set is `subset_of(server_allowlist)`.

**When to use:** Any policy axis that intersects multi-source allowlists. DCR is the second instance of this pattern in Lockspire (PAR is the first; JAR uses a simpler tri-state `:inherit | :optional | :required` that is not list-valued and so does not need this shape).

**Example (template — see Code Examples §5 for full sketch):**
```elixir
# Source: lib/lockspire/protocol/par_policy.ex:1-52 (verbatim structural template)
defmodule Lockspire.Protocol.DcrPolicy do
  @moduledoc """
  Resolves the effective DCR policy as an intersection of:
  server allowlists × IAT policy_overrides (when present) × inbound RFC 7591 metadata.

  Intersection-only: the resolver never widens any allowlist. IAT overrides are
  assumed already-narrowed to ⊆ server allowlist at IAT-mint time.
  """

  alias Lockspire.Domain.ServerPolicy

  defmodule Resolved do
    @moduledoc false
    defstruct allowed_scopes: [],
              allowed_grant_types: [],
              allowed_response_types: [],
              allowed_redirect_uri_schemes: [],
              allowed_redirect_uri_hosts: [],
              allowed_token_endpoint_auth_methods: [],
              # ... defaults are scalars carried through as-is
              default_client_lifetime_seconds: nil,
              default_client_secret_lifetime_seconds: nil,
              default_registration_access_token_lifetime_seconds: nil
  end

  @spec resolve(ServerPolicy.t(), map() | nil, map()) ::
          {:ok, Resolved.t()}
          | {:error, :invalid_client_metadata,
             %{field: atom(), reason: atom(), allowed: list()}}
  def resolve(%ServerPolicy{} = sp, iat_overrides, inbound) do
    # Per-axis: MapSet.intersection(server, iat || server, inbound) — never widens
    # On any inbound value not in server allowlist → {:error, ...}
  end
end
```

### Pattern 2: Additive Ecto migration with in-place `default:` backfill

**What:** A single migration adds a NOT NULL column with a column-level `default:` to an existing table. Postgres backfills atomically at `ADD COLUMN` time — no `execute "UPDATE ..."` step needed.

**When to use:** When the new column has a sensible per-installation default and the table is small-to-medium (`lockspire_clients` is operator-managed and bounded; safe). Documented at D-02.

**Example (template — see Code Examples §1 for full sketch):**
```elixir
# Source: priv/repo/migrations/20260424180000_add_lockspire_server_policy_and_client_par_policy.exs
defmodule Lockspire.TestRepo.Migrations.AddDcrFieldsToClients do
  use Ecto.Migration

  def change do
    alter table(:lockspire_clients) do
      add :provenance, :text, null: false, default: "operator"
      # ... 6 more nullable additive columns
    end
  end
end
```

### Pattern 3: Ecto.Enum text-column cast (matches PAR)

**What:** Store enum-shaped data as `text` in Postgres, cast to `Ecto.Enum` at the schema layer. Atoms in Elixir, strings on disk. Matches `field(:par_policy, Ecto.Enum, values: [:optional, :required], default: :optional)` at `server_policy_record.ex:14`.

**When to use:** All three new enum fields in Phase 25:
- `registration_policy` (`:disabled | :initial_access_token | :open`)
- `provenance` (`:operator | :self_registered`)
- (no third — IAT has no enum fields)

### Pattern 4: Singleton record with lock-for-update upsert

**What:** `ServerPolicyRecord` uses a fixed `@singleton_id 1` (line 10). The `Repository.put_server_policy/1` function (lines 109-133) wraps the upsert in `transact(fn -> ... lock("FOR UPDATE") ... end)`. **Phase 25 inherits this pattern unchanged** — adding DCR fields to the same singleton row uses the same plumbing.

**When to use:** Already used. No new code needed; just add fields to the existing changeset cast list.

### Anti-Patterns to Avoid

- **Embedded `:dcr` substruct on `Domain.ServerPolicy`:** D-04 explicitly rejects. Breaks PAR symmetry and adds a JSONB serialization layer.
- **Separate `lockspire_dcr_policy` table:** D-04 explicitly rejects. Premature normalization for a row count of 1.
- **Validating IAT widening at `resolve/3` time:** D-18 explicitly rejects. IAT mint-time validation (Phase 28) is the narrow-on-write seam; resolver does intersection only. If an out-of-allowlist override slips through, intersection naturally drops it — never widens.
- **Citing `jar_policy.ex` as the resolver template:** Specifics §1 and verified `ls lib/lockspire/protocol/`: no such file exists. Cite `par_policy.ex` only.
- **Widening `Domain.Client` typespec to admit fields the resolver narrows away:** Pitfall 7 (research/PITFALLS.md) — the existing `Domain.Client` typespec already admits `:private_key_jwt` (line 8) but discovery does not advertise it. Phase 25 resolver MUST bind to discovery, not to the typespec, via the invariant test (D-19).

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Hash-at-rest for IAT `token_hash` | A new sha256 wrapper | `Lockspire.Security.Policy.hash_token/1` (`security/policy.ex:84-89`) | D-14 locks reuse. Phase 26 redemption compares against this same function — drift here breaks atomicity. |
| Singleton-row upsert plumbing | A new transact pattern | `Repository.put_server_policy/1` (`repository.ex:109-133`) — already lock-for-update + insert-or-update | Singleton plumbing already exists; only the changeset cast list widens. |
| Set intersection logic | Hand-rolled `Enum.filter`+`Enum.member?` loops | `MapSet.intersection/2` (stdlib) | Idiomatic Elixir; D-17 specifies it; the invariant test (D-19) uses `MapSet.equal?/2` so the resolver should produce comparable shapes. |
| Backfill of `provenance = 'operator'` for existing rows | A separate `execute "UPDATE lockspire_clients SET provenance = 'operator'"` step | `add :provenance, :text, null: false, default: "operator"` in the same migration | D-02 locks. Postgres `ADD COLUMN ... NOT NULL DEFAULT` is atomic; one step, no race. |
| Random-token generation for IAT plaintext | A new RNG helper | (Out of scope for Phase 25.) Phase 28 admin LiveView mints; Phase 26 redeems. | Phase 25 ships schema only; mint is later. |
| Discovery accessor via module-attribute poke | `Lockspire.Protocol.Discovery.__info__/1` reflection or directly reading `@token_endpoint_auth_methods_supported` from a test | Add a public `def token_endpoint_auth_methods_supported, do: @token_endpoint_auth_methods_supported` `/0` accessor (D-20) | The invariant test must depend on a stable public seam; private/attribute access is fragile and breaks the abstraction. |

**Key insight:** Every "build it from scratch" temptation in this phase has a 1:1 prior-art replacement in the v1.3 PAR slice. Phase 25 is structural mirroring, not invention.

## Runtime State Inventory

> Phase 25 is a greenfield additive change to schema and code. Not a rename/refactor/migration phase. **This section omitted as out-of-scope per researcher protocol.**

(Verified: there is no existing `dcr_policy.ex` to rename, no `Domain.InitialAccessToken` defstruct to refactor, no migration history that needs string-replacement. The only risk surface is **schema drift in test database fixtures** — addressed in Validation Architecture §Wave 0.)

## Common Pitfalls

### Pitfall 1: Citing a non-existent `jar_policy.ex` as resolver template

**What goes wrong:** Plans or task actions reference `lib/lockspire/protocol/jar_policy.ex` as the structural mirror, leading the executor to grep for a file that does not exist or to invent a different shape.

**Why it happens:** The DCR research corpus (`.planning/research/ARCHITECTURE.md`, `STACK.md`, `SUMMARY.md`) repeatedly mentions "JarPolicy" and "JAR-policy resolver" as if a separate module shipped in v1.4. **It did not.** Verified via `ls lib/lockspire/protocol/` — only `par_policy.ex` exists.

**How to avoid:** Plans must cite `lib/lockspire/protocol/par_policy.ex:1-52` only as the structural template. The Resolved substruct shape, the `@spec`, the moduledoc style, and the helper-function layout all come from PAR.

**Warning signs:**
- A task action says "mirror lib/lockspire/protocol/jar_policy.ex" → wrong; that file does not exist.
- A research excerpt cites "v1.4 JarPolicy resolver" → wrong; v1.4 added inline `jwks` validation but no separate policy resolver module.

### Pitfall 2: Discovery invariant test poking private state

**What goes wrong:** The invariant test (D-19) tries to read `@token_endpoint_auth_methods_supported` directly via module attribute reflection or module info, breaking when discovery internals reorganize.

**Why it happens:** D-20 explicitly notes the public `/0` accessor does not exist today. A naive implementation attempts `Module.get_attribute(...)`, `apply(Discovery, :token_endpoint_auth_methods_supported, [])` against the private `/1`, or copy-pastes the literal list into the test.

**How to avoid:** Add the public `/0` accessor in this phase as the first task. The invariant test calls `Lockspire.Protocol.Discovery.token_endpoint_auth_methods_supported/0` exactly as Phase 29's discovery contract test will. One stable seam, two consumers.

**Warning signs:**
- The test uses `Code.fetch_docs/1`, `__info__/1`, or `Module.get_attribute/2`.
- The test contains a literal list `["none", "client_secret_basic", "client_secret_post"]`.

### Pitfall 3: IAT FK omitting `on_delete: :restrict`

**What goes wrong:** A migration writes `references(:lockspire_initial_access_tokens)` without `on_delete: :restrict`. An operator deletes an IAT row that minted a still-active client; the foreign key default cascade or set-null leaves orphaned/unattributable client records.

**Why it happens:** Ecto `references/2` defaults to no action declaration (`NO ACTION` in Postgres, which is restrictive but easy to override accidentally).

**How to avoid:** D-10 locks `on_delete: :restrict`. The executor must write `add :initial_access_token_id, references(:lockspire_initial_access_tokens, on_delete: :restrict), null: true`. Soft-delete via `revoked_at IS NOT NULL` (D-12) is the only retirement path.

**Warning signs:**
- Migration omits the `on_delete:` option.
- A test inserts an IAT, links a client, then `Repo.delete!`s the IAT and expects success — the test should expect a constraint failure.

### Pitfall 4: Enum text-column without `Ecto.Enum` cast

**What goes wrong:** A migration creates a `text` column for an enum field, but the schema reads/writes raw strings instead of casting to atoms. Code that pattern-matches on `:disabled` fails because the value is `"disabled"`.

**Why it happens:** The migration shape (`add :registration_policy, :text, null: false, default: "disabled"`) is independent of the schema shape (`field :registration_policy, Ecto.Enum, values: [:disabled, :initial_access_token, :open], default: :disabled`). It's possible to ship one without the other.

**How to avoid:** Every text column added in Phase 25 that represents an enum must have a matching `Ecto.Enum` field declaration in the corresponding `*_record.ex` schema. Verified template: `server_policy_record.ex:14` `field(:par_policy, Ecto.Enum, values: [:optional, :required], default: :optional)` lines up with `add :par_policy, :text, null: false, default: "optional"` in the v1.3 migration.

**Warning signs:**
- `server_policy_record.ex` adds `field :registration_policy, :string` instead of `Ecto.Enum`.
- A round-trip test asserts `record.registration_policy == "disabled"` instead of `:disabled`.

### Pitfall 5: Resolver returns `{:error, :invalid_client_metadata}` without naming the offending field

**What goes wrong:** The error tuple shape collapses to `{:error, :invalid_client_metadata}`, losing the `%{field, reason, allowed}` payload. Phase 26 intake validator and Phase 27 controller cannot render an RFC 7591 §3.2.2-compliant error message naming the rejected field.

**Why it happens:** D-16 specifies the full error tuple shape, but it is easy to drop the third element if focused on returning early.

**How to avoid:** D-16 exact shape: `{:error, :invalid_client_metadata, %{field: atom(), reason: atom(), allowed: list()}}`. Tests should pattern-match on the full shape. Mirror the `Admin.ServerPolicy` `error_detail` typespec at `server_policy.ex:9` (`%{field: atom(), reason: atom(), detail: term()}`) but use `allowed:` instead of `detail:` for the resolver.

**Warning signs:**
- A test asserts `assert {:error, :invalid_client_metadata} = result` (missing third element).
- The resolver returns `{:error, :invalid_client_metadata, "scope foo not allowed"}` (third element should be a map, not a string).

### Pitfall 6: Provenance backfill skipped for existing rows

**What goes wrong:** A migration adds `provenance` as a nullable column to skip the default-handling complexity, then a follow-up data migration is "planned" for later and never lands. Existing rows have NULL provenance, breaking the two-value enum invariant and downstream filtering.

**Why it happens:** Adding `null: false` with a `default:` means the migration must succeed atomically; reviewers sometimes weaken the constraint to ship faster.

**How to avoid:** D-02 locks `null: false, default: 'operator'` at `ADD COLUMN` time. Postgres backfills atomically (verified [CITED: PostgreSQL 11+ release notes — `ADD COLUMN ... DEFAULT` no longer rewrites the table]). A round-trip test on existing rows must assert `provenance == :operator` after migration, not `nil`.

**Warning signs:**
- Migration uses `add :provenance, :text, null: true` (skips the default-backfill).
- A separate "data migration" file is referenced but does not exist.

## Code Examples

### Example 1: Additive migration template (extend `lockspire_server_policies` with DCR fields)

```elixir
# Source: priv/repo/migrations/20260424180000_add_lockspire_server_policy_and_client_par_policy.exs
# (verbatim structural template; new file follows same shape)
defmodule Lockspire.TestRepo.Migrations.AddDcrFieldsToServerPolicies do
  use Ecto.Migration

  def change do
    alter table(:lockspire_server_policies) do
      add :registration_policy, :text, null: false, default: "disabled"

      add :dcr_allowed_scopes, {:array, :text}, null: false, default: []
      add :dcr_allowed_grant_types, {:array, :text}, null: false, default: []
      add :dcr_allowed_response_types, {:array, :text}, null: false, default: []
      add :dcr_allowed_redirect_uri_schemes, {:array, :text}, null: false, default: []
      add :dcr_allowed_redirect_uri_hosts, {:array, :text}, null: false, default: []
      add :dcr_allowed_token_endpoint_auth_methods, {:array, :text}, null: false, default: []

      add :dcr_default_client_lifetime_seconds, :integer
      add :dcr_default_client_secret_lifetime_seconds, :integer
      add :dcr_default_registration_access_token_lifetime_seconds, :integer
    end
  end
end
```

**Notes:**
- Module name uses `Lockspire.TestRepo.Migrations` prefix matching the v1.3 file (verified at `priv/repo/migrations/20260424180000_*.exs:1`). This matches the project's TestRepo naming.
- All array allowlists default to `[]` (empty); operator must explicitly populate via `Admin.ServerPolicy.put_dcr_policy/1` before enabling DCR.
- Lifetime integers are nullable — operator default is "use Lockspire global default" (Phase 26 will fill these in).

### Example 2: Migration template (extend `lockspire_clients` with backfill, then create IAT table)

```elixir
# File: priv/repo/migrations/<ts>_add_dcr_fields_to_clients.exs
# Mirrors v1.3 PAR pattern: add columns with default for in-place backfill.
defmodule Lockspire.TestRepo.Migrations.AddDcrFieldsToClients do
  use Ecto.Migration

  def change do
    alter table(:lockspire_clients) do
      # Provenance: existing rows backfill to "operator" via default at ADD COLUMN time.
      add :provenance, :text, null: false, default: "operator"

      # RFC 7591 §3.2.1 timestamps (nullable on operator-created rows).
      add :client_id_issued_at, :utc_datetime_usec
      add :client_secret_expires_at, :utc_datetime_usec

      # RFC 7592 management credential (hash-at-rest; plaintext returned once at issuance).
      add :registration_access_token_hash, :text
      add :registration_client_uri, :text

      # Provenance attribution: which IAT (if any) minted this client.
      # on_delete: :restrict — D-10 locks; soft-delete via revoked_at is the retirement path.
      add :initial_access_token_id,
          references(:lockspire_initial_access_tokens,
            on_delete: :restrict
          ),
          null: true
    end
  end
end
```

```elixir
# File: priv/repo/migrations/<ts>_create_initial_access_tokens.exs
# MUST run BEFORE the clients migration above (the FK depends on this table existing).
defmodule Lockspire.TestRepo.Migrations.CreateInitialAccessTokens do
  use Ecto.Migration

  def change do
    create table(:lockspire_initial_access_tokens) do
      add :token_hash, :text, null: false
      add :expires_at, :utc_datetime_usec, null: false
      add :single_use, :boolean, null: false, default: true
      add :used_at, :utc_datetime_usec
      add :revoked_at, :utc_datetime_usec
      add :policy_overrides, :jsonb
      add :created_by, :text

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:lockspire_initial_access_tokens, [:token_hash])
  end
end
```

**Migration ordering note:** The three migrations have a dependency: the `lockspire_clients` migration adds an FK referencing `lockspire_initial_access_tokens(id)`. So the actual ordering by timestamp must be:

1. `<ts0>_add_dcr_fields_to_server_policies.exs` (independent)
2. `<ts1>_create_initial_access_tokens.exs` (must run BEFORE clients FK)
3. `<ts2>_add_dcr_fields_to_clients.exs` (FK references IAT table)

CONTEXT.md D-01 lists the conceptual order (server_policies → clients → initial_access_tokens) but the **physical timestamp order** must put `create_initial_access_tokens` before `add_dcr_fields_to_clients` because of the FK. Plans should call this out explicitly.

### Example 3: Defstruct extension (`Domain.ServerPolicy` widening)

```elixir
# Source: lib/lockspire/domain/server_policy.ex (current shape lines 1-19)
# Phase 25 extension — add DCR fields:
defmodule Lockspire.Domain.ServerPolicy do
  @moduledoc """
  Durable server-wide operator policy owned by Lockspire.
  """

  @type par_policy :: :optional | :required
  @type registration_policy :: :disabled | :initial_access_token | :open

  @type t :: %__MODULE__{
          id: integer() | nil,
          par_policy: par_policy(),
          registration_policy: registration_policy(),
          dcr_allowed_scopes: [String.t()],
          dcr_allowed_grant_types: [String.t()],
          dcr_allowed_response_types: [String.t()],
          dcr_allowed_redirect_uri_schemes: [String.t()],
          dcr_allowed_redirect_uri_hosts: [String.t()],
          dcr_allowed_token_endpoint_auth_methods: [String.t()],
          dcr_default_client_lifetime_seconds: non_neg_integer() | nil,
          dcr_default_client_secret_lifetime_seconds: non_neg_integer() | nil,
          dcr_default_registration_access_token_lifetime_seconds: non_neg_integer() | nil,
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  defstruct id: nil,
            par_policy: :optional,
            registration_policy: :disabled,
            dcr_allowed_scopes: [],
            dcr_allowed_grant_types: [],
            dcr_allowed_response_types: [],
            dcr_allowed_redirect_uri_schemes: [],
            dcr_allowed_redirect_uri_hosts: [],
            dcr_allowed_token_endpoint_auth_methods: [],
            dcr_default_client_lifetime_seconds: nil,
            dcr_default_client_secret_lifetime_seconds: nil,
            dcr_default_registration_access_token_lifetime_seconds: nil,
            inserted_at: nil,
            updated_at: nil
end
```

### Example 4: New `Domain.InitialAccessToken` defstruct + `InitialAccessTokenRecord` schema

```elixir
# File: lib/lockspire/domain/initial_access_token.ex
defmodule Lockspire.Domain.InitialAccessToken do
  @moduledoc """
  Durable initial access token used to gate `POST /register` when
  ServerPolicy.registration_policy == :initial_access_token.

  Hash-at-rest reuses Lockspire.Security.Policy.hash_token/1.
  Plaintext is shown once at mint time only (Phase 28 admin LiveView).
  """

  @type t :: %__MODULE__{
          id: integer() | nil,
          token_hash: String.t(),
          expires_at: DateTime.t(),
          single_use: boolean(),
          used_at: DateTime.t() | nil,
          revoked_at: DateTime.t() | nil,
          policy_overrides: map() | nil,
          created_by: String.t() | nil,
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  defstruct id: nil,
            token_hash: nil,
            expires_at: nil,
            single_use: true,
            used_at: nil,
            revoked_at: nil,
            policy_overrides: nil,
            created_by: nil,
            inserted_at: nil,
            updated_at: nil
end
```

```elixir
# File: lib/lockspire/storage/ecto/initial_access_token_record.ex
# Mirrors lib/lockspire/storage/ecto/server_policy_record.ex shape (lines 1-35).
defmodule Lockspire.Storage.Ecto.InitialAccessTokenRecord do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset

  alias Lockspire.Domain.InitialAccessToken

  @timestamps_opts [type: :utc_datetime_usec]

  schema "lockspire_initial_access_tokens" do
    field(:token_hash, :string)
    field(:expires_at, :utc_datetime_usec)
    field(:single_use, :boolean, default: true)
    field(:used_at, :utc_datetime_usec)
    field(:revoked_at, :utc_datetime_usec)
    field(:policy_overrides, :map)
    field(:created_by, :string)

    timestamps()
  end

  def changeset(record, %InitialAccessToken{} = iat) do
    record
    |> cast(Map.from_struct(iat), [
      :id,
      :token_hash,
      :expires_at,
      :single_use,
      :used_at,
      :revoked_at,
      :policy_overrides,
      :created_by
    ])
    |> validate_required([:token_hash, :expires_at, :single_use])
    |> unique_constraint(:token_hash)
  end

  def to_domain(%__MODULE__{} = record) do
    %InitialAccessToken{
      id: record.id,
      token_hash: record.token_hash,
      expires_at: record.expires_at,
      single_use: record.single_use,
      used_at: record.used_at,
      revoked_at: record.revoked_at,
      policy_overrides: record.policy_overrides,
      created_by: record.created_by,
      inserted_at: record.inserted_at,
      updated_at: record.updated_at
    }
  end
end
```

### Example 5: `Lockspire.Protocol.DcrPolicy.resolve/3` resolver (full sketch)

```elixir
# File: lib/lockspire/protocol/dcr_policy.ex
# Structural template: lib/lockspire/protocol/par_policy.ex:1-52 (verbatim mirror).
# DcrPolicy differs from ParPolicy in arity (3 vs 2) and intersection scope (multi-axis MapSet).
defmodule Lockspire.Protocol.DcrPolicy do
  @moduledoc """
  Resolves the effective DCR policy for an inbound RFC 7591 client registration request
  as the intersection of:

    1. ServerPolicy DCR allowlists (the operator-configured envelope)
    2. InitialAccessToken policy_overrides (when an IAT was redeemed; nil otherwise)
    3. Inbound RFC 7591 client metadata (what the registrant requested)

  Intersection-only: the resolver never widens any allowlist. IAT overrides are assumed
  already-narrowed to ⊆ server allowlist at IAT-mint time (Phase 28 admin path enforces this).
  If an out-of-allowlist override slips through (e.g. policy was tightened after IAT mint),
  MapSet.intersection/2 naturally drops it — never widens.

  Returns:
    {:ok, %Resolved{}}  — the effective policy bound to this request
    {:error, :invalid_client_metadata, %{field, reason, allowed}}
                        — first inbound value not in the server allowlist
  """

  alias Lockspire.Domain.ServerPolicy

  defmodule Resolved do
    @moduledoc false

    @type t :: %__MODULE__{
            allowed_scopes: [String.t()],
            allowed_grant_types: [String.t()],
            allowed_response_types: [String.t()],
            allowed_redirect_uri_schemes: [String.t()],
            allowed_redirect_uri_hosts: [String.t()],
            allowed_token_endpoint_auth_methods: [String.t()],
            default_client_lifetime_seconds: non_neg_integer() | nil,
            default_client_secret_lifetime_seconds: non_neg_integer() | nil,
            default_registration_access_token_lifetime_seconds: non_neg_integer() | nil
          }

    defstruct allowed_scopes: [],
              allowed_grant_types: [],
              allowed_response_types: [],
              allowed_redirect_uri_schemes: [],
              allowed_redirect_uri_hosts: [],
              allowed_token_endpoint_auth_methods: [],
              default_client_lifetime_seconds: nil,
              default_client_secret_lifetime_seconds: nil,
              default_registration_access_token_lifetime_seconds: nil
  end

  @type error_detail :: %{field: atom(), reason: atom(), allowed: list()}

  @spec resolve(ServerPolicy.t(), map() | nil, map()) ::
          {:ok, Resolved.t()} | {:error, :invalid_client_metadata, error_detail()}
  def resolve(%ServerPolicy{} = server_policy, iat_overrides, inbound_metadata)
      when (is_map(iat_overrides) or is_nil(iat_overrides)) and is_map(inbound_metadata) do
    # Per-axis intersection, fail-fast on first widening attempt.
    with {:ok, scopes} <-
           intersect(:scope, inbound_metadata, server_policy.dcr_allowed_scopes,
             override_for(iat_overrides, "allowed_scopes")),
         {:ok, grants} <-
           intersect(:grant_types, inbound_metadata, server_policy.dcr_allowed_grant_types,
             override_for(iat_overrides, "allowed_grant_types")),
         # ... per the other allowlist axes ...
         do
      {:ok,
       %Resolved{
         allowed_scopes: scopes,
         allowed_grant_types: grants,
         # ... defaults from ServerPolicy carried through ...
         default_client_lifetime_seconds: server_policy.dcr_default_client_lifetime_seconds,
         default_client_secret_lifetime_seconds:
           server_policy.dcr_default_client_secret_lifetime_seconds,
         default_registration_access_token_lifetime_seconds:
           server_policy.dcr_default_registration_access_token_lifetime_seconds
       }}
    end
  end

  defp intersect(field, inbound, server_allowlist, iat_override) do
    requested = MapSet.new(inbound_value(field, inbound))
    server_set = MapSet.new(server_allowlist)
    iat_set = if iat_override, do: MapSet.new(iat_override), else: server_set

    case MapSet.difference(requested, server_set) |> MapSet.to_list() do
      [] ->
        # Inbound is ⊆ server allowlist; intersect with IAT narrowing.
        effective = requested |> MapSet.intersection(server_set) |> MapSet.intersection(iat_set)
        {:ok, MapSet.to_list(effective)}

      [offending | _] ->
        {:error, :invalid_client_metadata,
         %{field: field, reason: :not_in_allowlist, allowed: server_allowlist,
           offending: offending}}
    end
  end

  defp override_for(nil, _key), do: nil
  defp override_for(overrides, key), do: Map.get(overrides, key)

  defp inbound_value(:scope, %{"scope" => s}) when is_binary(s), do: String.split(s, " ", trim: true)
  defp inbound_value(:scope, _inbound), do: []
  defp inbound_value(field, inbound), do: Map.get(inbound, Atom.to_string(field), [])
end
```

**Sketch caveats:** This sketch is illustrative. The executor should match the exact PAR `par_policy.ex` style (private helpers below the public function, no `with` macros if PAR doesn't use them, etc.). The `intersect/4` helper signature here is one viable shape; the planner may prefer a different decomposition.

### Example 6: Public `Discovery.token_endpoint_auth_methods_supported/0` accessor

```elixir
# File: lib/lockspire/protocol/discovery.ex
# Existing private helper at lines 82-88. Phase 25 adds a public /0 accessor that
# reuses the module attribute.

# Existing (lines 21, 82-88):
#   @token_endpoint_auth_methods_supported ["none", "client_secret_basic", "client_secret_post"]
#   ...
#   defp token_endpoint_auth_methods_supported(endpoint_metadata) do
#     if Map.has_key?(endpoint_metadata, "token_endpoint") do
#       @token_endpoint_auth_methods_supported
#     else
#       []
#     end
#   end

# Phase 25 ADDITION (place near top of module, after the @grant_types_supported group):
@doc """
Returns the static list of `token_endpoint_auth_method` values this issuer's discovery
document advertises, regardless of mounted-route truthfulness. Phase 25 invariant test
binds DCR-accepted methods to this list (intersection with ServerPolicy DCR allowlist).
"""
@spec token_endpoint_auth_methods_supported() :: [String.t()]
def token_endpoint_auth_methods_supported, do: @token_endpoint_auth_methods_supported
```

**Note:** The new public `/0` and the existing private `/1` (line 82) share the same module attribute. They serve different concerns: `/0` returns the static list for binding tests; `/1` returns the gated list for the live discovery payload (suppressed when `token_endpoint` route isn't mounted). Both are safe to coexist. The Phase 29 discovery contract test (DCR-16/17) will likely consume `/0` as well.

### Example 7: Discovery-binding invariant test shape

```elixir
# File: test/lockspire/protocol/dcr_policy_invariant_test.exs
defmodule Lockspire.Protocol.DcrPolicyInvariantTest do
  use ExUnit.Case, async: true

  alias Lockspire.Domain.ServerPolicy
  alias Lockspire.Protocol.DcrPolicy
  alias Lockspire.Protocol.Discovery

  @moduledoc """
  Asserts that the set of token_endpoint_auth_method values DCR will accept
  equals MapSet.intersection(server_allowlist, discovery_supported_set).

  Fails if either side drifts:
    - if Discovery.token_endpoint_auth_methods_supported/0 changes
    - if ServerPolicy.dcr_allowed_token_endpoint_auth_methods semantics change
    - if DcrPolicy.resolve/3 starts widening or narrowing in unexpected ways
  """

  test "DCR accepts exactly the intersection of ServerPolicy allowlist and discovery support" do
    discovery_set = MapSet.new(Discovery.token_endpoint_auth_methods_supported())

    # A maximal ServerPolicy allowlist — superset of discovery on purpose, to prove the
    # intersection truly bounds DCR by discovery.
    server_allowlist = [
      "none",
      "client_secret_basic",
      "client_secret_post",
      "private_key_jwt",     # in domain typespec but NOT in discovery → must be intersected away
      "tls_client_auth"       # not advertised → must be intersected away
    ]

    server_policy = %ServerPolicy{
      registration_policy: :open,
      dcr_allowed_token_endpoint_auth_methods: server_allowlist,
      dcr_allowed_scopes: [],
      dcr_allowed_grant_types: [],
      dcr_allowed_response_types: [],
      dcr_allowed_redirect_uri_schemes: [],
      dcr_allowed_redirect_uri_hosts: []
    }

    inbound = %{
      "token_endpoint_auth_method" => "client_secret_basic",
      "scope" => "",
      "grant_types" => [],
      "response_types" => [],
      "redirect_uris" => []
    }

    {:ok, resolved} = DcrPolicy.resolve(server_policy, nil, inbound)
    accepted_set = MapSet.new(resolved.allowed_token_endpoint_auth_methods)

    expected_set = MapSet.intersection(MapSet.new(server_allowlist), discovery_set)

    assert MapSet.equal?(accepted_set, expected_set),
           """
           DCR accepted set drifted from intersection(ServerPolicy allowlist, Discovery support).
             discovery_set:  #{inspect(MapSet.to_list(discovery_set))}
             server_set:     #{inspect(server_allowlist)}
             expected:       #{inspect(MapSet.to_list(expected_set))}
             accepted:       #{inspect(MapSet.to_list(accepted_set))}

           Either:
             - Discovery.token_endpoint_auth_methods_supported/0 changed (check discovery.ex:21).
             - ServerPolicy.dcr_allowed_token_endpoint_auth_methods semantics changed.
             - DcrPolicy.resolve/3 is no longer intersection-only.
           """
  end
end
```

**Test placement caveat:** This test should be marked `async: true` and depend only on pure functions (Discovery static method, DcrPolicy resolver). It does NOT need a database — explicitly avoid `setup` blocks that touch `Lockspire.TestRepo`. This keeps the invariant cheap and runnable by every developer on every save.

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| One-axis tri-state policy resolver (PAR/JAR-shaped) | Multi-axis MapSet intersection (DCR-shaped) | Phase 25 (this phase) | DCR is the first multi-axis allowlist resolver in the repo. PAR/JAR each handle a single tri-state (`:inherit | :optional | :required`). DCR introduces the "list-valued allowlist" pattern; future resolvers (e.g., a hypothetical JarPolicy with allowed-algs allowlist) will follow this shape. |
| Policy state on a separate normalized table | Policy state on the `lockspire_server_policies` singleton | v1.3 (PAR shipped this; v1.4 JAR followed) | Phase 25 continues this pattern. Singleton table for per-installation policy is the established Lockspire pattern. |
| Hash-at-rest with `argon2_elixir` or `bcrypt_elixir` | sha256 lowercase-hex via `:crypto.hash/2` (`Security.Policy.hash_token/1`) | v1.0 | IATs and RATs are bearer tokens, not passwords. Argon2/bcrypt is wrong for high-entropy random tokens (slow, no security gain). Verified `security/policy.ex:84-89`. |

**Deprecated/outdated:**
- **Reference to `lib/lockspire/protocol/jar_policy.ex` in research files:** Does not exist. Cite `par_policy.ex` only. (Already flagged in CONTEXT.md Specifics §1; reiterated here because some research-file excerpts the planner reads will still mention "JarPolicy".)

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The `intersect/4` helper signature in Code Examples §5 is illustrative, not prescriptive. | Code Examples §5 | LOW — executor may decompose differently; signature must match `par_policy.ex` style. The locked contract is the public `resolve/3` shape (D-16), not the private helpers. |
| A2 | The invariant test should be `async: true` and avoid the test database. | Code Examples §7 | LOW — works against pure functions. If Discovery's `/0` accessor ends up reading config or a database (it shouldn't), this would need adjustment. |
| A3 | Postgres `ADD COLUMN ... NOT NULL DEFAULT` is atomic and does not rewrite the table for new columns since Postgres 11. | Pitfall 6 | LOW — Postgres docs are authoritative; verified Postgres 14.17 locally. If Lockspire later targets Postgres < 11 (it doesn't; AGENTS.md says "PostgreSQL 14+"), this would be wrong. |
| A4 | The `MapSet.intersection/2` operator (D-17 verbatim) is the right primitive given the small allowlist sizes (≤10 items per axis). | Standard Stack §Alternatives | LOW — for ≤10 items, `Enum.filter/2` would also work; MapSet is idiomatic and matches D-19 invariant test (`MapSet.equal?/2`). |
| A5 | The migration timestamp ordering (IAT table BEFORE clients FK) is required because of the FK reference. | Code Examples §2 (migration ordering note) | MEDIUM — if reversed, the clients migration will fail to find the IAT table. Plans MUST call this ordering out explicitly because CONTEXT.md D-01 lists the conceptual order in a different sequence. |
| A6 | Lockspire's existing `Lockspire.Storage.Ecto.Repository` will gain new functions (`get_initial_access_token/1`, etc.) in Phase 26, NOT Phase 25. Phase 25 only adds the `*_record.ex` schema. | Recommended Project Structure | LOW — explicit per CONTEXT.md (`Phase 25 ships schema + struct only — Lockspire.Protocol.InitialAccessToken.redeem/1 is Phase 26`). If the executor tries to add Repository functions in Phase 25, scope creeps. |

**Confirmation needed before plan execution:** None of the above are critical risks. A5 is the highest-impact (could cause migration failure) but is mechanically detectable on first `mix ecto.migrate`. The planner should call A5 out as a verification step in the migration task.

## Open Questions

1. **Should `Repository.get_server_policy/0` change to fully populate DCR fields when the row is absent?**
   - What we know: `repository.ex:96-106` returns `{:ok, %ServerPolicy{}}` when no row exists, relying on the defstruct defaults. After Phase 25, the defstruct will have new DCR fields with empty-list / disabled defaults — this works automatically.
   - What's unclear: whether the `ServerPolicyRecord.to_domain/1` mapping needs an explicit field-by-field rewrite (current shape lines 27-34). Likely yes — every new field must appear in the to_domain shape or it falls through as `nil`.
   - Recommendation: Treat `to_domain/1` extension as a required Phase 25 task. Add a round-trip test that asserts `to_domain` populates every new field.

2. **Should `Domain.Client.t/0` typespec gain a `:provenance` field even though Phase 25 doesn't update `Storage.Ecto.ClientRecord.update_changeset/2`?**
   - What we know: `update_changeset/2` (lines 100-123) is the operator-update path. It does NOT cast `:provenance` (provenance is set at create time, never updated). Phase 25 should NOT add `:provenance` to that cast list.
   - What's unclear: whether any existing test asserts `update_changeset` rejects unknown fields. If so, adding `:provenance` to the defstruct without the cast list might be fine; if not, an executor might be confused why the update path doesn't include it.
   - Recommendation: The plan should explicitly call out that `update_changeset/2` is unchanged in Phase 25. Provenance is a create-time invariant; Phase 26 (intake) sets it once.

3. **Should the IAT migration include indexes beyond `unique_index(:token_hash)`?**
   - What we know: D-03 explicitly requires `unique_index([:token_hash])`. Phase 28 admin LiveView (out of scope here) will list IATs and probably want a `(revoked_at, expires_at)` partial index for "show active IATs."
   - What's unclear: whether to ship that admin-listing index in Phase 25 or handle in Phase 28.
   - Recommendation: Ship `unique_index([:token_hash])` only in Phase 25. Defer admin-listing indexes to Phase 28 when the actual query patterns are visible. Premature indexing on a small admin table is wasted optimization.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir / OTP | All Phase 25 work | ✓ | OTP 28 / Elixir w/ Mix 1.19.5 | — |
| PostgreSQL | All migrations + integration tests | ✓ | 14.17 (local) | — |
| `mix ecto.migrate` | Migration verification | ✓ | via `Lockspire.TestRepo` (`lib/lockspire/test_repo.ex`) and `mix test.setup` alias | — |
| `mix test` | All Phase 25 ExUnit tests | ✓ | Standard via `mix test.fast` (alias `test.setup` + `test`) | — |
| `mix qa` (format / compile / credo / dialyzer) | Per-task verification | ✓ | All four tools available via project deps | — |

**Missing dependencies with no fallback:** None.

**Missing dependencies with fallback:** None.

(All Phase 25 work is pure Elixir + Ecto + Postgres; everything required is already present per AGENTS.md Technology Stack and verified locally.)

## Validation Architecture

(`workflow.nyquist_validation: true` in `.planning/config.json` — this section is required.)

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit (Elixir stdlib) |
| Config file | `test/test_helper.exs` |
| Quick run command | `mix test.fast` (alias: `test.setup` + `test`) |
| Full suite command | `mix test.fast && mix test.integration && mix qa` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| DCR-06 | `ServerPolicy` exposes 3-mode `registration_policy` field | unit (defstruct round-trip) | `mix test test/lockspire/storage/ecto/server_policy_record_test.exs` | ❌ Wave 0 (file doesn't exist; current admin test only covers `par_policy`) |
| DCR-06 | `Admin.ServerPolicy.{get,put}_dcr_policy/0,1` works | unit (admin surface) | `mix test test/lockspire/admin/server_policy_test.exs` | ✅ extend (file exists at line 1; add DCR test cases) |
| DCR-07 | DCR allowlists bind intake; metadata exceeding allowlist is rejected | unit (resolver) | `mix test test/lockspire/protocol/dcr_policy_test.exs` | ❌ Wave 0 |
| DCR-07 | DCR defaults are operator-readable | unit (admin surface) | `mix test test/lockspire/admin/server_policy_test.exs` | ✅ extend |
| DCR-08 | `DcrPolicy.resolve/3` intersects server × IAT × inbound; never widens | unit (resolver) | `mix test test/lockspire/protocol/dcr_policy_test.exs` | ❌ Wave 0 |
| DCR-09 | DCR-accepted methods = intersection(ServerPolicy allowlist, Discovery support) | unit (invariant) | `mix test test/lockspire/protocol/dcr_policy_invariant_test.exs` | ❌ Wave 0 |
| DCR-10 | `lockspire_initial_access_tokens` table persists IATs with hash-at-rest, expiry, single-use, jsonb policy_overrides | unit (schema round-trip + unique constraint) | `mix test test/lockspire/storage/ecto/initial_access_token_record_test.exs` | ❌ Wave 0 |
| DCR-10 | `Domain.InitialAccessToken` defstruct mirrors column set | unit (defstruct shape) | (covered by InitialAccessTokenRecord test above via `to_domain/1`) | ❌ Wave 0 |
| Migration health | `mix ecto.migrate` then `mix ecto.rollback` is clean on a v1.4 db | manual-only (one-shot via `mix test.setup`) | `MIX_ENV=test mix test.setup` then verify schema columns | ✅ existing alias |

### Sampling Rate

- **Per task commit:** `mix test test/lockspire/<area>` for the area touched by the commit (e.g., `mix test test/lockspire/storage/ecto/server_policy_record_test.exs`).
- **Per wave merge:** `mix test.fast` (full ExUnit fast suite) — runs all unit tests including the new resolver and invariant tests.
- **Phase gate:** `mix test.fast && mix test.integration && mix qa` — full suite plus qa pipeline (format/compile/credo/dialyzer) green before `/gsd-verify-work`.

### Wave 0 Gaps

- [ ] `test/lockspire/protocol/dcr_policy_test.exs` — covers DCR-07, DCR-08 (resolver intersection cases: empty inbound, fully-narrowed inbound, inbound exceeding allowlist, IAT override narrowing, IAT widening attempt naturally dropped, three-way intersection)
- [ ] `test/lockspire/protocol/dcr_policy_invariant_test.exs` — covers DCR-09 (discovery-binding invariant; see Code Examples §7 for shape)
- [ ] `test/lockspire/storage/ecto/server_policy_record_test.exs` — schema round-trip with all DCR fields (no existing file in `test/lockspire/storage/ecto/`); covers DCR-06 storage layer
- [ ] `test/lockspire/storage/ecto/client_record_test.exs` — schema round-trip with new provenance + RAT/IAT/timestamp fields; verifies `provenance` defaults to `:operator` for existing rows after migration; verifies `update_changeset/2` does NOT cast provenance
- [ ] `test/lockspire/storage/ecto/initial_access_token_record_test.exs` — schema round-trip + `unique_index(:token_hash)` constraint test; covers DCR-10 storage layer
- [ ] Test fixture (operator discretion per CONTEXT.md): `test/support/fixtures/initial_access_token_fixtures.ex` — convenience constructors for IAT structs; mirrors any future `client_fixtures.ex` shape (currently no fixtures exist beyond `generated_host_app/.keep`)
- [ ] **Extension** of `test/lockspire/admin/server_policy_test.exs` (file exists; add `get_dcr_policy/0` / `put_dcr_policy/1` cases following the existing `par_policy` pattern at lines 22-47)

**Framework install:** None. ExUnit ships with Elixir; `mix test.setup` alias already wires `Lockspire.TestRepo`.

## Security Domain

(`security_enforcement` not explicitly disabled in config → enabled by default → section required.)

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | partial | Phase 25 itself adds no auth surface, but the IAT schema enables Phase 26 IAT-bearer auth. The hash-at-rest invariant (D-14) is the V2 control: `Lockspire.Security.Policy.hash_token/1` (sha256 lowercase hex). |
| V3 Session Management | no | Phase 25 has no session surface. |
| V4 Access Control | partial | The `provenance` field (D-08) and FK-restrict on IAT (D-10) preserve audit attribution and prevent operator deletion of attribution chains. |
| V5 Input Validation | yes | `DcrPolicy.resolve/3` is the input-validation seam: per-allowlist `MapSet.intersection/2` (D-17) rejects with `:invalid_client_metadata` (RFC 7591 §3.2.2 standard error). No JSON schema library — RFC 7591 has cross-field constraints JSON Schema can't express; hand-rolled validation per project convention. |
| V6 Cryptography | yes | sha256 hash-at-rest for IAT `token_hash` reuses existing `Lockspire.Security.Policy.hash_token/1` — the only sanctioned hash primitive. **Never hand-roll a new hash function.** |
| V7 Error Handling | yes | Resolver error tuple shape `{:error, :invalid_client_metadata, %{field, reason, allowed}}` (D-16) names the offending field — does NOT leak full inbound payload or server allowlist beyond what RFC 7591 §3.2.2 allows. |
| V8 Data Protection | partial | `policy_overrides jsonb` (D-11) stores operator-controlled narrowing overrides; not user data. No PII in Phase 25 schema. |
| V9 Communication | no | No HTTP/network surface in Phase 25. |
| V10 Malicious Code | no | No external code execution in Phase 25. |

### Known Threat Patterns for Elixir/Ecto/Phoenix DCR Schema

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| SQL injection via dynamic Ecto query | Tampering | All queries parameterized by Ecto.Query (no raw `Ecto.Adapters.SQL.query!` with interpolation). Phase 25 has no dynamic queries — only schema additions and a singleton upsert. |
| Hash truncation / format mismatch on IAT lookup | Spoofing / Tampering | Always hash via `Lockspire.Security.Policy.hash_token/1` (sha256 lowercase hex), never compare plaintext — Phase 26 redemption depends on this contract. |
| Race condition: two operators update server policy concurrently | Tampering | Existing `Repository.put_server_policy/1` (`repository.ex:109-133`) wraps in `transact(fn -> ... lock("FOR UPDATE") ... end)` — Phase 25 inherits unchanged. |
| Race condition: IAT redeemed twice | Tampering | Phase 26 concern; Phase 25 enables it via `unique_index([:token_hash])` (D-03) and atomic `UPDATE ... WHERE used_at IS NULL` pattern (D-13 boolean simplifies). |
| Operator deletes IAT that minted active client → orphan client | Repudiation / Tampering | `on_delete: :restrict` (D-10). Soft-delete via `revoked_at` (D-12) preserves audit chain. |
| Provenance backfilled NULL or wrong value | Repudiation | `default: 'operator'` at `ADD COLUMN` time (D-02) backfills atomically; round-trip test verifies. False operator-attribution is a documented v1.5 risk (Pitfall 10 in research/PITFALLS.md). |
| Resolver widens an allowlist via misconfigured IAT override | Elevation of Privilege | D-18 invariant: resolver intersection-only. `MapSet.intersection/2` provably never widens. Invariant test (D-19) backstops drift. |

## Sources

### Primary (HIGH confidence)

- **CONTEXT.md** (`.planning/phases/25-dcr-storage-skeleton-domain-types-and-policy-resolver/25-CONTEXT.md`) — locked decisions D-01 through D-20, Specifics §1-5, deferred ideas
- **REQUIREMENTS.md** (`.planning/REQUIREMENTS.md`) — DCR-06, DCR-07, DCR-08, DCR-09, DCR-10 verbatim text
- **ROADMAP.md** (`.planning/ROADMAP.md`) — Phase 25 success criteria 1-4
- **AGENTS.md** (`/Users/jon/projects/lockspire/AGENTS.md`) — Technology Stack pin (Phoenix 1.8.5, Phoenix LiveView 1.1.28, Ecto SQL 3.13.5, PostgreSQL 14+), security defaults
- **lib/lockspire/protocol/par_policy.ex** (lines 1-52) — verbatim structural template for `dcr_policy.ex`
- **lib/lockspire/storage/ecto/server_policy_record.ex** (lines 1-35) — singleton record shape, `Ecto.Enum` text-cast pattern, `to_domain/1` mapping
- **lib/lockspire/storage/ecto/client_record.ex** (lines 1-161) — schema field idioms, `Ecto.Enum` for `token_endpoint_auth_method`, `update_changeset/2` pattern
- **lib/lockspire/storage/ecto/repository.ex** (lines 96-133) — `get_server_policy/0` / `put_server_policy/1` lock-for-update upsert
- **lib/lockspire/domain/server_policy.ex** (lines 1-19) — current defstruct shape to extend
- **lib/lockspire/domain/client.ex** (lines 1-82) — defstruct field conventions, `:utc_datetime_usec` timestamp pattern (lines 38-46)
- **lib/lockspire/admin/server_policy.ex** (lines 1-42) — `get_server_policy/0` / `put_server_policy/1` template, `error_detail` typespec at line 9
- **lib/lockspire/security/policy.ex** (lines 84-89) — `hash_token/1` sha256 lowercase hex (the only sanctioned IAT hash primitive)
- **lib/lockspire/protocol/discovery.ex** (line 21 module attribute, line 82 private helper) — basis for the public `/0` accessor extraction
- **priv/repo/migrations/20260424180000_add_lockspire_server_policy_and_client_par_policy.exs** — additive-migration template (text-as-Ecto.Enum, in-place defaults)
- **test/lockspire/protocol/par_policy_test.exs** (lines 1-76) — test shape to mirror in `dcr_policy_test.exs`
- **test/lockspire/admin/server_policy_test.exs** (lines 1-48) — admin surface test shape, sandbox setup, async-false convention for repo-touching tests
- **mix.exs** (lines 56-95) — `test.fast` / `test.integration` / `qa` aliases used in Validation Architecture
- **.planning/research/SUMMARY.md** — milestone-level confidence assessment (HIGH overall; v1.5 needs zero new runtime deps)
- **.planning/research/ARCHITECTURE.md** — Pattern 1 (resolver shape), §State Management (column lists), §Build Order Level 1 (this phase's scope)
- **.planning/research/PITFALLS.md** — Pitfall 4 (provenance enum tradeoffs), Pitfall 7 (truth-binding to discovery), Pitfall 11 (allowlist enforcement is intersection)
- **.planning/research/STACK.md** — DCR-relevant library inventory (no new deps)
- **`ls lib/lockspire/protocol/`** verification — confirmed `par_policy.ex` exists; `jar_policy.ex` does NOT exist (CONTEXT.md Specifics §1 confirmed)
- **`pg_isready` + `psql --version`** — verified Postgres 14.17 locally
- **`elixir --version` + `mix --version`** — verified OTP 28, Mix 1.19.5

### Secondary (MEDIUM confidence)

- **RFC 7591** (`https://www.rfc-editor.org/rfc/rfc7591`) — referenced via SUMMARY.md sources; §3.2.1 response shape, §3.2.2 error codes (`invalid_client_metadata` is the standard rejection)
- **RFC 7592** (`https://www.rfc-editor.org/rfc/rfc7592`) — Phase 26/27 concern; only relevant to Phase 25 in that the resolver shape must support a future RFC 7592 PUT validator (full-replace via the same intersection logic)
- **PostgreSQL 11+ release notes** — `ADD COLUMN ... NOT NULL DEFAULT` no longer rewrites the table (key for D-02 atomic backfill claim)

### Tertiary (LOW confidence)

- None flagged for Phase 25. All claims trace to repo-truth or locked CONTEXT.md decisions.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all libraries already pinned (`AGENTS.md` Technology Stack); zero new runtime deps confirmed by SUMMARY.md.
- Architecture: HIGH — direct reuse of v1.3 PAR additive-migration pattern (verified file exists); resolver structural mirror of `par_policy.ex` (verified file exists, line 1-52); admin surface mirror of `Admin.ServerPolicy` (verified `get_server_policy/0` / `put_server_policy/1` shape at `server_policy.ex:11-22`).
- Pitfalls: HIGH — every pitfall traces to a CONTEXT.md decision (Pitfall 1 → Specifics §1, Pitfall 2 → D-19/D-20, Pitfall 3 → D-10, Pitfall 4 → D-04 + Ecto.Enum convention, Pitfall 5 → D-16, Pitfall 6 → D-02). No speculative pitfalls.
- Validation: HIGH — ExUnit + Postgres 14 verified locally; existing `mix test.fast` / `mix qa` aliases work; Wave 0 gaps enumerated against current `test/lockspire/` tree.
- Security: HIGH — ASVS V5/V6/V7 controls trace to existing primitives (`Security.Policy.hash_token/1`), no novel cryptography, no new attack surface beyond what Phase 26+ will exercise.

**Research date:** 2026-04-26
**Valid until:** 2026-05-26 (30 days — stable Elixir/Phoenix/Ecto stack, locked CONTEXT.md decisions, no fast-moving deps).
