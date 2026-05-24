# Phase 25: DCR Storage Skeleton, Domain Types, and Policy Resolver - Pattern Map

**Mapped:** 2026-04-26
**Files analyzed:** 17 (10 NEW, 7 MODIFIED)
**Analogs found:** 17 / 17

## File Classification

### NEW files

| New File | Role | Data Flow | Closest Analog | Match Quality |
|----------|------|-----------|----------------|---------------|
| `lib/lockspire/protocol/dcr_policy.ex` | protocol resolver | pure-function transform | `lib/lockspire/protocol/par_policy.ex` (lines 1-52) | role-match (only resolver in repo) |
| `lib/lockspire/domain/initial_access_token.ex` | domain (defstruct + typespec) | data shape | `lib/lockspire/domain/server_policy.ex` (lines 1-19) + `lib/lockspire/domain/client.ex` (lines 38-46) | exact (defstruct shape + timestamp idiom) |
| `lib/lockspire/storage/ecto/initial_access_token_record.ex` | storage (Ecto schema + changeset + to_domain) | DB read/write | `lib/lockspire/storage/ecto/pushed_authorization_request_record.ex` (lines 1-79) | exact (multi-row record with `unique_index` and hash field) |
| `priv/repo/migrations/{ts}_extend_lockspire_server_policies_dcr.exs` | migration (additive `alter table`) | schema migration | `priv/repo/migrations/20260424180000_add_lockspire_server_policy_and_client_par_policy.exs` (lines 1-15) | exact (PAR additive template) |
| `priv/repo/migrations/{ts}_create_lockspire_initial_access_tokens.exs` | migration (`create table` + `unique_index`) | schema migration | `priv/repo/migrations/20260424093000_create_lockspire_pushed_authorization_requests.exs` (lines 1-24) | exact (create-table + unique-index pattern) |
| `priv/repo/migrations/{ts}_extend_lockspire_clients_dcr.exs` | migration (additive `alter table` + FK + backfill via default) | schema migration | `priv/repo/migrations/20260424180000_add_lockspire_server_policy_and_client_par_policy.exs` (line 11-13) + `priv/repo/migrations/20260423120000_add_client_admin_lifecycle_fields.exs` (lines 1-14) | exact (default-backfill) |
| `test/lockspire/protocol/dcr_policy_test.exs` | test (pure-function resolver) | unit | `test/lockspire/protocol/par_policy_test.exs` (lines 1-76) | exact (resolver test shape, `async: true`, no DB) |
| `test/lockspire/protocol/dcr_policy_invariant_test.exs` | test (cross-module invariant) | unit | `test/lockspire/protocol/security_policy_test.exs` (lines 1-40) — closest pure-module unit shape | role-match (no existing intersection-invariant test) |
| `test/lockspire/domain/initial_access_token_test.exs` | test (domain defstruct shape) | unit | (no existing `test/lockspire/domain/` dir — closest pattern is `test/lockspire/protocol/par_policy_test.exs` `async: true` ExUnit shape) | role-match |
| `test/support/fixtures/initial_access_token_fixtures.ex` | test fixtures | constructor helpers | (no existing `.ex` fixture files — `test/support/fixtures/` only contains `generated_host_app/.keep`); closest helper pattern is `test/support/jar_test_helpers.ex` | role-match (greenfield) |

### MODIFIED files

| Modified File | Role | Data Flow | Modification Pattern | Source of Modification Pattern |
|---------------|------|-----------|---------------------|-------------------------------|
| `lib/lockspire/domain/server_policy.ex` | domain | data shape | extend `@type t` + `defstruct` with new fields + new `@type registration_policy ::` | self (lines 1-19) — the existing `par_policy` typespec is the template |
| `lib/lockspire/domain/client.ex` | domain | data shape | extend `@type t` + `defstruct` with 7 new fields | self (lines 38-46) — existing `:utc_datetime_usec` timestamps are the template |
| `lib/lockspire/storage/ecto/server_policy_record.ex` | storage | DB read/write | extend `schema` block + `changeset` cast list + `to_domain` mapping | self (lines 13-34) — existing `:par_policy` `Ecto.Enum` field is the template |
| `lib/lockspire/storage/ecto/client_record.ex` | storage | DB read/write | extend `schema` block + `changeset` cast list (NOT `update_changeset/2` — provenance is create-time only) + `to_domain` mapping | self (lines 12-50, 52-98, 125-161) |
| `lib/lockspire/admin/server_policy.ex` | admin/application surface | request-response (pure) | add `get_dcr_policy/0` + `put_dcr_policy/1` mirroring `get_server_policy/0` + `put_server_policy/1` (lines 11-22); reuse `error_detail` typespec at line 9 | self |
| `lib/lockspire/protocol/discovery.ex` | protocol | pure-function accessor | extract a public `def token_endpoint_auth_methods_supported, do: @token_endpoint_auth_methods_supported` (`/0`) alongside the existing private `/1` (line 82) and module attribute (line 21) | self |
| `test/lockspire/admin/server_policy_test.exs` | test (admin surface) | DB-backed unit | add `get_dcr_policy/0` / `put_dcr_policy/1` cases following the existing `par_policy` cases (lines 22-47); keep `async: false` + sandbox setup | self |

---

## Pattern Assignments

### `lib/lockspire/protocol/dcr_policy.ex` (protocol resolver, pure-function transform)

**Analog:** `lib/lockspire/protocol/par_policy.ex` (verbatim structural template)

**Module + moduledoc + alias pattern** (par_policy.ex lines 1-8):

```elixir
defmodule Lockspire.Protocol.ParPolicy do
  @moduledoc """
  Resolves effective PAR policy from server-wide defaults and client overrides.
  """

  alias Lockspire.Domain.ServerPolicy

  @type mode :: :inherit | :optional | :required
```

**`Resolved` substruct pattern** (par_policy.ex lines 10-24):

```elixir
defmodule Resolved do
  @moduledoc false

  @type t :: %__MODULE__{
          global_policy: ServerPolicy.par_policy(),
          client_policy: Lockspire.Protocol.ParPolicy.mode(),
          effective_policy: ServerPolicy.par_policy(),
          par_required?: boolean()
        }

  defstruct global_policy: :optional,
            client_policy: :inherit,
            effective_policy: :optional,
            par_required?: false
end
```

**Resolver signature + private helpers pattern** (par_policy.ex lines 26-52):

```elixir
@spec resolve_effective_policy(ServerPolicy.t(), struct() | map() | nil) :: Resolved.t()
def resolve_effective_policy(%ServerPolicy{} = server_policy, client) do
  client_policy = normalize_client_policy(client)
  effective_policy = effective_policy(server_policy.par_policy, client_policy)

  %Resolved{
    global_policy: server_policy.par_policy,
    client_policy: client_policy,
    effective_policy: effective_policy,
    par_required?: effective_policy == :required
  }
end

defp normalize_client_policy(nil), do: :inherit

defp normalize_client_policy(client) do
  case Map.get(client, :par_policy, :inherit) do
    :required -> :required
    :optional -> :optional
    _other -> :inherit
  end
end

defp effective_policy(global_policy, :inherit), do: global_policy
defp effective_policy(_global_policy, :required), do: :required
defp effective_policy(_global_policy, :optional), do: :optional
```

**Deltas from analog (DCR is NOT a 1:1 PAR):**
- **Arity:** PAR is `/2`, DCR is `/3` — adds `iat_overrides_or_nil` middle argument (D-16 locked).
- **Return shape:** PAR returns `Resolved.t()` directly (never errors). DCR returns `{:ok, Resolved.t()} | {:error, :invalid_client_metadata, %{field, reason, allowed}}` (D-16; per Pitfall 5: third map element is mandatory).
- **Composition:** PAR is single-axis tri-state. DCR is multi-axis list-valued. Use `MapSet.intersection/2` per allowlist axis (D-17 locked, idiomatic for the small ≤10-item allowlists).
- **Resolved substruct fields:** DCR's `Resolved` has 6 list-valued allowed_* fields + 3 scalar `default_*_seconds` fields (see RESEARCH.md Code Examples §5).
- **Non-widening invariant:** DCR resolver MUST be intersection-only — IAT overrides assumed already ⊆ server allowlist at IAT-mint time (D-18); document in moduledoc.
- **Discovery binding:** `allowed_token_endpoint_auth_methods` in `Resolved` MUST be intersected against `Discovery.token_endpoint_auth_methods_supported/0` — verified by the invariant test (D-19).

---

### `lib/lockspire/domain/initial_access_token.ex` (domain, data shape)

**Analog (defstruct + typespec shape):** `lib/lockspire/domain/server_policy.ex` (lines 1-19)
**Analog (timestamp/utc_datetime_usec idiom):** `lib/lockspire/domain/client.ex` (lines 13-46)

**Defstruct + typespec pattern** (server_policy.ex lines 1-19):

```elixir
defmodule Lockspire.Domain.ServerPolicy do
  @moduledoc """
  Durable server-wide operator policy owned by Lockspire.
  """

  @type par_policy :: :optional | :required

  @type t :: %__MODULE__{
          id: integer() | nil,
          par_policy: par_policy(),
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  defstruct id: nil,
            par_policy: :optional,
            inserted_at: nil,
            updated_at: nil
end
```

**`utc_datetime_usec` timestamp idiom** (client.ex lines 38-46):

```elixir
created_at: DateTime.t() | nil,
active: boolean(),
disabled_at: DateTime.t() | nil,
disabled_by: String.t() | nil,
last_secret_rotated_at: DateTime.t() | nil,
metadata: map(),
inserted_at: DateTime.t() | nil,
updated_at: DateTime.t() | nil
```

**Deltas:**
- 1:1 column mirror (D-15): `id`, `token_hash`, `expires_at`, `single_use` (default `true`), `used_at`, `revoked_at`, `policy_overrides`, `created_by`, `inserted_at`, `updated_at` — see RESEARCH.md Code Examples §4 for the full sketch.
- `single_use` default in defstruct is `true` (matches D-13 / D-11 column default).
- No enum types on this struct (IAT carries no `Ecto.Enum` fields).
- `policy_overrides` is `map() | nil` in typespec (jsonb on disk, decoded as map at the schema layer).

---

### `lib/lockspire/storage/ecto/initial_access_token_record.ex` (storage, DB read/write)

**Analog:** `lib/lockspire/storage/ecto/pushed_authorization_request_record.ex` (lines 1-79) — the closest match because PAR is the only multi-row record in the repo with a `unique_index` on a hash column.

**Schema + changeset + to_domain pattern** (pushed_authorization_request_record.ex lines 1-79):

```elixir
defmodule Lockspire.Storage.Ecto.PushedAuthorizationRequestRecord do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset

  alias Lockspire.Domain.PushedAuthorizationRequest

  @timestamps_opts [type: :utc_datetime_usec]

  schema "lockspire_pushed_authorization_requests" do
    field(:request_uri_hash, :string)
    field(:client_id, :string)
    field(:redirect_uri, :string)
    field(:scopes, {:array, :string}, default: [])
    field(:prompt, {:array, :string}, default: [])
    field(:nonce, :string)
    field(:state, :string)
    field(:code_challenge, :string)
    field(:code_challenge_method, Ecto.Enum, values: [:S256])
    field(:expires_at, :utc_datetime_usec)

    timestamps()
  end

  def changeset(record, %PushedAuthorizationRequest{} = request) do
    attrs =
      request
      |> Map.from_struct()
      |> Map.put(:prompt, normalize_prompt(request.prompt))

    record
    |> cast(attrs, [
      :request_uri_hash,
      :client_id,
      :redirect_uri,
      :scopes,
      :prompt,
      :nonce,
      :state,
      :code_challenge,
      :code_challenge_method,
      :expires_at
    ])
    |> validate_required([
      :request_uri_hash,
      :client_id,
      :redirect_uri,
      :code_challenge,
      :code_challenge_method,
      :expires_at
    ])
    |> unique_constraint(:request_uri_hash)
  end

  def to_domain(%__MODULE__{} = record, opts \\ []) do
    # ...field-by-field map back to %PushedAuthorizationRequest{}
  end
end
```

**Deltas:**
- Replace `request_uri_hash` field name with `token_hash` in the IAT version.
- Drop `prompt` normalization helper — IAT has no equivalent.
- Add `single_use` boolean field with `default: true` matching column default (D-11).
- Add `policy_overrides` as `field(:policy_overrides, :map)` — Ecto handles jsonb↔map automatically.
- `unique_constraint(:token_hash)` mirrors `unique_constraint(:request_uri_hash)` line 54.
- See RESEARCH.md Code Examples §4 for the full target shape.
- IAT has NO `Ecto.Enum` fields (D-09 enum is on `clients`, not on IAT).

---

### `priv/repo/migrations/{ts}_extend_lockspire_server_policies_dcr.exs` (migration, additive `alter table`)

**Analog:** `priv/repo/migrations/20260424180000_add_lockspire_server_policy_and_client_par_policy.exs` (lines 1-15)

**Additive migration pattern**:

```elixir
defmodule Lockspire.TestRepo.Migrations.AddLockspireServerPolicyAndClientParPolicy do
  use Ecto.Migration

  def change do
    create table(:lockspire_server_policies) do
      add :par_policy, :text, null: false, default: "optional"

      timestamps(type: :utc_datetime_usec)
    end

    alter table(:lockspire_clients) do
      add :par_policy, :text, null: false, default: "inherit"
    end
  end
end
```

**Deltas:**
- Use `alter table(:lockspire_server_policies)` (the table already exists from v1.3 PAR migration); do NOT `create table` again.
- Module name uses `Lockspire.TestRepo.Migrations` prefix exactly as the analog (line 1).
- Add 10 columns per D-04/D-05/D-06: 1 enum (`registration_policy`), 6 array allowlists (`{:array, :text}, null: false, default: []`), 3 nullable lifetime integers.
- See RESEARCH.md Code Examples §1 for the full target shape.

---

### `priv/repo/migrations/{ts}_create_lockspire_initial_access_tokens.exs` (migration, `create table` + `unique_index`)

**Analog:** `priv/repo/migrations/20260424093000_create_lockspire_pushed_authorization_requests.exs` (lines 1-24)

**Create-table + unique-index + indexes pattern**:

```elixir
defmodule Lockspire.TestRepo.Migrations.CreateLockspirePushedAuthorizationRequests do
  use Ecto.Migration

  def change do
    create table(:lockspire_pushed_authorization_requests) do
      add(:request_uri_hash, :text, null: false)
      add(:client_id, :text, null: false)
      add(:redirect_uri, :text, null: false)
      add(:scopes, {:array, :text}, null: false, default: [])
      add(:prompt, {:array, :text}, null: false, default: [])
      add(:nonce, :text)
      add(:state, :text)
      add(:code_challenge, :text, null: false)
      add(:code_challenge_method, :text, null: false)
      add(:expires_at, :utc_datetime_usec, null: false)

      timestamps(type: :utc_datetime_usec)
    end

    create(unique_index(:lockspire_pushed_authorization_requests, [:request_uri_hash]))
    create(index(:lockspire_pushed_authorization_requests, [:client_id]))
    create(index(:lockspire_pushed_authorization_requests, [:expires_at]))
  end
end
```

**Deltas:**
- Table name: `lockspire_initial_access_tokens`.
- Columns per D-11: `token_hash text NOT NULL`, `expires_at utc_datetime_usec NOT NULL`, `single_use boolean NOT NULL default true`, `used_at`, `revoked_at`, `policy_overrides jsonb`, `created_by text`, `timestamps(type: :utc_datetime_usec)`.
- Add `policy_overrides :jsonb` — note: Ecto migration syntax is `add :policy_overrides, :jsonb` (string-typed), or `add :policy_overrides, :map` (Postgres translates to jsonb). PAR analog uses neither, so prefer `:map` for consistency with how Ecto schema reads it.
- Index discipline (Open Question 3 in RESEARCH.md): ship `unique_index(:lockspire_initial_access_tokens, [:token_hash])` only (D-03). Defer admin-listing indexes (e.g. `(revoked_at, expires_at)`) to Phase 28 when the actual query patterns are visible. Do NOT add `index(:client_id)` or similar — there is no client_id column on this table.
- See RESEARCH.md Code Examples §2 for the full target shape.
- **Migration-ordering note (RESEARCH A5, MEDIUM risk):** This migration MUST have a timestamp BEFORE the clients-DCR migration because the clients FK references this table. Conceptual order in CONTEXT.md D-01 lists clients second, but physical timestamp order MUST put `create_initial_access_tokens` first.

---

### `priv/repo/migrations/{ts}_extend_lockspire_clients_dcr.exs` (migration, additive `alter table` + FK + backfill)

**Analog (default-backfill pattern):** `priv/repo/migrations/20260424180000_add_lockspire_server_policy_and_client_par_policy.exs` (lines 11-13)
**Analog (additive `alter table` to clients with index):** `priv/repo/migrations/20260423120000_add_client_admin_lifecycle_fields.exs` (lines 1-14)

**In-place backfill via `default:` pattern** (PAR migration lines 11-13):

```elixir
alter table(:lockspire_clients) do
  add :par_policy, :text, null: false, default: "inherit"
end
```

**Additive `alter table` + nullable timestamps** (lifecycle migration lines 1-14):

```elixir
defmodule Lockspire.TestRepo.Migrations.AddClientAdminLifecycleFields do
  use Ecto.Migration

  def change do
    alter table(:lockspire_clients) do
      add(:active, :boolean, null: false, default: true)
      add(:disabled_at, :utc_datetime_usec)
      add(:disabled_by, :text)
      add(:last_secret_rotated_at, :utc_datetime_usec)
    end

    create(index(:lockspire_clients, [:active]))
  end
end
```

**Deltas:**
- 7 new columns per D-08:
  - `provenance text NOT NULL DEFAULT 'operator'` — the in-place backfill (D-02).
  - `registration_access_token_hash text` (nullable).
  - `registration_client_uri text` (nullable).
  - `initial_access_token_id` — `references(:lockspire_initial_access_tokens, on_delete: :restrict)` (D-10 locked; Pitfall 3 backstop).
  - `client_id_issued_at :utc_datetime_usec` (nullable).
  - `client_secret_expires_at :utc_datetime_usec` (nullable).
- `on_delete: :restrict` is **mandatory** on the FK — Pitfall 3 explicitly warns about omitting it.
- Do NOT add a separate `execute "UPDATE ..."` step for provenance backfill; column default handles it atomically (D-02).
- See RESEARCH.md Code Examples §2 (top half) for the full target shape.

---

### `test/lockspire/protocol/dcr_policy_test.exs` (test, pure-function resolver)

**Analog:** `test/lockspire/protocol/par_policy_test.exs` (lines 1-76)

**Test module setup pattern** (par_policy_test.exs lines 1-7):

```elixir
defmodule Lockspire.Protocol.ParPolicyTest do
  use ExUnit.Case, async: true

  alias Lockspire.Domain.Client
  alias Lockspire.Domain.ServerPolicy
  alias Lockspire.Protocol.ParPolicy
```

**Single-test pattern (one assertion-cluster per branch)** (par_policy_test.exs lines 8-26):

```elixir
test "resolve_effective_policy follows the optional global default" do
  resolved =
    ParPolicy.resolve_effective_policy(%ServerPolicy{par_policy: :optional}, %Client{})

  assert resolved.global_policy == :optional
  assert resolved.client_policy == :inherit
  assert resolved.effective_policy == :optional
  assert resolved.par_required? == false
end
```

**Deltas:**
- Keep `async: true` — resolver is pure, no DB sandbox needed.
- Cover (per RESEARCH.md Wave 0): empty inbound, fully-narrowed inbound, inbound exceeding allowlist (`{:error, :invalid_client_metadata, %{field, reason, allowed}}` shape — Pitfall 5 reminds: full 3-tuple, not 2-tuple), IAT override narrowing, IAT-attempted-widening naturally dropped via intersection, three-way intersection.
- Use `MapSet.equal?/2` to compare set-shaped fields, not `assert ==` on lists (since intersection result order isn't guaranteed).

---

### `test/lockspire/protocol/dcr_policy_invariant_test.exs` (test, cross-module invariant)

**Analog (closest module-level pure-function test):** `test/lockspire/protocol/security_policy_test.exs` (lines 1-40)

**Module setup + pure-function test pattern** (security_policy_test.exs lines 1-5):

```elixir
defmodule Lockspire.Protocol.SecurityPolicyTest do
  use ExUnit.Case, async: true

  alias Lockspire.Security.Policy
```

**Deltas (no existing intersection-invariant precedent — this is greenfield):**
- Mark `async: true` (depends only on pure functions; A2 in RESEARCH.md confirms).
- Do NOT include `setup` blocks that touch `Lockspire.TestRepo` — keeps the invariant cheap and runnable on every save.
- Single test that asserts `MapSet.equal?(MapSet.intersection(server_allowlist, discovery_supported_set), accepted_dcr_set)` per D-19.
- Test must depend on the **public** `Discovery.token_endpoint_auth_methods_supported/0` accessor — never `Module.get_attribute/2` or `Code.fetch_docs/1` (Pitfall 2 explicitly warns; the public `/0` exists after the discovery extraction in this same phase).
- Use a **maximal `server_allowlist`** that includes values NOT advertised by discovery (`"private_key_jwt"`, `"tls_client_auth"`) so the test proves the intersection truly bounds DCR by discovery.
- Helpful failure message: name which side drifted (server allowlist vs discovery list vs resolver) — see RESEARCH.md Code Examples §7 for the full failure-message shape.

---

### `test/lockspire/domain/initial_access_token_test.exs` (test, domain defstruct shape)

**Analog:** No existing `test/lockspire/domain/` directory. Closest is `test/lockspire/protocol/par_policy_test.exs` for the bare ExUnit module shape (lines 1-7).

**Module setup pattern**:

```elixir
defmodule Lockspire.Domain.InitialAccessTokenTest do
  use ExUnit.Case, async: true

  alias Lockspire.Domain.InitialAccessToken
end
```

**Deltas:**
- `async: true` — defstruct shape has no DB or shared state.
- Cover: defstruct defaults (especially `single_use: true` from D-13), typespec accepts all `nil`-able fields, struct constructable with minimal required fields (`token_hash` + `expires_at`).
- This file may end up minimal — most IAT round-trip behavior lives in `test/lockspire/storage/ecto/initial_access_token_record_test.exs` (Wave 0 gap from RESEARCH.md, but not in the explicit Phase 25 file list — covered indirectly).

---

### `test/support/fixtures/initial_access_token_fixtures.ex` (test fixtures, constructor helpers)

**Analog:** No existing `.ex` fixture files in `test/support/fixtures/` (the directory only contains `generated_host_app/`). Closest helper-module pattern: `test/support/jar_test_helpers.ex`.

**Helper module shape** (drawn from in-repo convention):

```elixir
defmodule Lockspire.Test.Fixtures.InitialAccessTokenFixtures do
  @moduledoc false

  alias Lockspire.Domain.InitialAccessToken
  alias Lockspire.Security.Policy

  def initial_access_token(attrs \\ %{}) do
    plaintext = Map.get(attrs, :plaintext, default_plaintext())
    base = %InitialAccessToken{
      token_hash: Policy.hash_token(plaintext),
      expires_at: DateTime.add(DateTime.utc_now(), 3600, :second),
      single_use: true
    }
    struct!(base, Map.delete(attrs, :plaintext))
  end

  defp default_plaintext, do: Base.url_encode64(:crypto.strong_rand_bytes(32), padding: false)
end
```

**Deltas (no precedent — greenfield, operator discretion per CONTEXT.md):**
- Use `Lockspire.Security.Policy.hash_token/1` to populate `token_hash` — never invent a new hash (D-14 + Pitfall 6).
- Default plaintext via `:crypto.strong_rand_bytes/1` matches the random-token idiom in `lib/lockspire/domain/pushed_authorization_request.ex:80-86`.
- Default lifetime: `3600` seconds (one hour). Tests can override via the `attrs` map.
- Module path: `test/support/fixtures/initial_access_token_fixtures.ex` (operator name from CONTEXT.md Claude's Discretion section).

---

### `lib/lockspire/domain/server_policy.ex` (MODIFIED — extend defstruct)

**Self-analog:** lines 1-19 (the existing `par_policy` typespec + defstruct).

**Existing pattern** (lines 1-19 — full file):

```elixir
defmodule Lockspire.Domain.ServerPolicy do
  @moduledoc """
  Durable server-wide operator policy owned by Lockspire.
  """

  @type par_policy :: :optional | :required

  @type t :: %__MODULE__{
          id: integer() | nil,
          par_policy: par_policy(),
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  defstruct id: nil,
            par_policy: :optional,
            inserted_at: nil,
            updated_at: nil
end
```

**Deltas (extend, do not replace):**
- Add `@type registration_policy :: :disabled | :initial_access_token | :open` next to the existing `@type par_policy ::`.
- Extend `@type t` map with: `registration_policy`, 6 list-valued `dcr_allowed_*` fields (`[String.t()]`), 3 `non_neg_integer() | nil` lifetime fields.
- Extend `defstruct` keyword list with matching defaults: `registration_policy: :disabled`, all allowlists `[]`, all lifetimes `nil`.
- See RESEARCH.md Code Examples §3 for the full target shape.

---

### `lib/lockspire/domain/client.ex` (MODIFIED — extend defstruct with 7 fields)

**Self-analog:** lines 13-46 (existing `@type t` + lines 48-81 existing defstruct list).

**Existing typespec timestamp pattern** (lines 38-46):

```elixir
created_at: DateTime.t() | nil,
active: boolean(),
disabled_at: DateTime.t() | nil,
disabled_by: String.t() | nil,
last_secret_rotated_at: DateTime.t() | nil,
metadata: map(),
inserted_at: DateTime.t() | nil,
updated_at: DateTime.t() | nil
```

**Existing defstruct list pattern** (lines 48-81):

```elixir
defstruct [
  :id,
  :client_id,
  :client_secret_hash,
  ...
  active: true,
  disabled_at: nil,
  disabled_by: nil,
  last_secret_rotated_at: nil,
  metadata: %{},
  inserted_at: nil,
  updated_at: nil
]
```

**Deltas (D-08):**
- Add `@type provenance :: :operator | :self_registered` near the other typespec aliases (lines 6-11). **Two-value enum** (D-09 / Specifics §3 / Pitfall 4).
- Extend `@type t` with: `provenance`, `registration_access_token_hash: String.t() | nil`, `registration_client_uri: String.t() | nil`, `initial_access_token_id: integer() | nil`, `client_id_issued_at: DateTime.t() | nil`, `client_secret_expires_at: DateTime.t() | nil`. (6 new typespec entries; counts as 7 fields once `provenance` is included.)
- Extend `defstruct` with matching defaults: `provenance: :operator` (matches column default), all others `nil`.

---

### `lib/lockspire/storage/ecto/server_policy_record.ex` (MODIFIED — extend Ecto schema)

**Self-analog:** lines 1-35 (full file shows the singleton record pattern + `:par_policy` `Ecto.Enum` cast at line 14).

**Existing schema + changeset + to_domain pattern** (lines 13-34):

```elixir
schema "lockspire_server_policies" do
  field(:par_policy, Ecto.Enum, values: [:optional, :required], default: :optional)

  timestamps()
end

def singleton_id, do: @singleton_id

def changeset(record, %ServerPolicy{} = policy) do
  record
  |> cast(Map.from_struct(policy), [:id, :par_policy])
  |> validate_required([:id, :par_policy])
end

def to_domain(%__MODULE__{} = record) do
  %ServerPolicy{
    id: record.id,
    par_policy: record.par_policy,
    inserted_at: record.inserted_at,
    updated_at: record.updated_at
  }
end
```

**Deltas:**
- Add `field(:registration_policy, Ecto.Enum, values: [:disabled, :initial_access_token, :open], default: :disabled)` — mirrors the `par_policy` line 14 pattern. Pitfall 4 reminds: every text enum column needs the matching `Ecto.Enum` field.
- Add 6 array allowlist fields: `field(:dcr_allowed_scopes, {:array, :string}, default: [])` and 5 siblings.
- Add 3 lifetime integer fields: `field(:dcr_default_client_lifetime_seconds, :integer)` and 2 siblings.
- Extend `cast/3` field list (line 23) with all 10 new fields.
- Extend `validate_required/2` (line 24) with `:registration_policy` (the only NOT NULL with a default-but-no-nil-fallback).
- Extend `to_domain/1` mapping (lines 27-34) — Open Question 1: every new field must appear here or it falls through as `nil`. Required.

---

### `lib/lockspire/storage/ecto/client_record.ex` (MODIFIED — extend Ecto schema with provenance + 6 cols)

**Self-analog:** existing schema (lines 12-50), `changeset/2` (lines 52-98), `update_changeset/2` (lines 100-123 — DO NOT touch), `to_domain/1` (lines 125-161).

**Existing `Ecto.Enum` + create-time cast pattern** (relevant excerpt lines 23-27, 52-97):

```elixir
field(
  :token_endpoint_auth_method,
  Ecto.Enum,
  values: [:client_secret_basic, :client_secret_post, :private_key_jwt, :none]
)

# ...later...
def changeset(record, %Client{} = client) do
  record
  |> cast(Map.from_struct(client), [
    :client_id,
    ...
    :metadata
  ])
  |> validate_required([
    :client_id,
    :client_type,
    ...
  ])
  |> unique_constraint(:client_id)
end
```

**Deltas:**
- Add `field(:provenance, Ecto.Enum, values: [:operator, :self_registered], default: :operator)`. Pitfall 4: must match the migration's text column.
- Add 5 plain-typed fields: `field(:registration_access_token_hash, :string)`, `field(:registration_client_uri, :string)`, `field(:initial_access_token_id, :integer)`, `field(:client_id_issued_at, :utc_datetime_usec)`, `field(:client_secret_expires_at, :utc_datetime_usec)`.
- Extend `changeset/2` cast list with all 6 new field atoms.
- Extend `changeset/2` `validate_required/2` with `:provenance` only (others nullable).
- **DO NOT touch `update_changeset/2`** (Open Question 2): provenance is a create-time invariant, never updated. The plan should explicitly call out that `update_changeset/2` is unchanged in Phase 25.
- Extend `to_domain/1` mapping with all 6 new fields (last block of the file).

---

### `lib/lockspire/admin/server_policy.ex` (MODIFIED — add `get_dcr_policy/0` + `put_dcr_policy/1`)

**Self-analog:** lines 11-22 (the existing `get_server_policy/0` / `put_server_policy/1` shape).

**Existing public-surface pattern** (lines 1-22):

```elixir
defmodule Lockspire.Admin.ServerPolicy do
  @moduledoc """
  Query and command boundary for Lockspire server policy.
  """

  alias Lockspire.Domain.ServerPolicy
  alias Lockspire.Storage.Ecto.Repository

  @type error_detail :: %{field: atom(), reason: atom(), detail: term()}

  @spec get_server_policy() :: {:ok, ServerPolicy.t()} | {:error, term()}
  def get_server_policy do
    Repository.get_server_policy()
  end

  @spec put_server_policy(atom() | String.t()) ::
          {:ok, ServerPolicy.t()} | {:error, [error_detail()]} | {:error, term()}
  def put_server_policy(mode) do
    with {:ok, normalized_mode} <- normalize_par_policy(mode) do
      Repository.put_server_policy(%ServerPolicy{par_policy: normalized_mode})
    end
  end
```

**Deltas (D-07):**
- Add `get_dcr_policy/0` returning a `%DcrPolicy{}` substruct view (or whatever sub-shape the planner picks — the value MUST surface the 10 new ServerPolicy DCR fields, possibly as a thin substruct).
- Add `put_dcr_policy/1` accepting the same shape; persists via `Repository.put_server_policy/1` against the same singleton row (the existing repository code already covers this — D-04 keeps DCR top-level on the same row, so no new Repository code needed).
- Reuse the existing `error_detail` typespec at line 9 — error shape is `[%{field, reason, detail}]` for the admin surface. Note this differs from `DcrPolicy.resolve/3` which uses `%{field, reason, allowed}` (Pitfall 5 — admin error_detail uses `:detail`; resolver error uses `:allowed`). Two different contexts; do not collapse them.

---

### `lib/lockspire/protocol/discovery.ex` (MODIFIED — extract public `/0` accessor)

**Self-analog:** existing module attribute (line 21) + private `/1` (lines 82-88).

**Existing pattern** (lines 21, 82-88):

```elixir
@token_endpoint_auth_methods_supported ["none", "client_secret_basic", "client_secret_post"]

# ...

defp token_endpoint_auth_methods_supported(endpoint_metadata) do
  if Map.has_key?(endpoint_metadata, "token_endpoint") do
    @token_endpoint_auth_methods_supported
  else
    []
  end
end
```

**Deltas (D-20):**
- Add a public `/0` next to the private `/1`:

```elixir
@doc """
Returns the static list of `token_endpoint_auth_method` values this issuer's discovery
document advertises, regardless of mounted-route truthfulness. Phase 25 invariant test
binds DCR-accepted methods to this list (intersection with ServerPolicy DCR allowlist).
"""
@spec token_endpoint_auth_methods_supported() :: [String.t()]
def token_endpoint_auth_methods_supported, do: @token_endpoint_auth_methods_supported
```

- The new public `/0` and the existing private `/1` share the module attribute — they coexist safely (different purposes: `/0` returns the static list for binding tests; `/1` returns the gated list for the live discovery payload).
- See RESEARCH.md Code Examples §6 for the full target shape.

---

### `test/lockspire/admin/server_policy_test.exs` (MODIFIED — extend with DCR cases)

**Self-analog:** existing file (lines 1-48, full file shown in CONTEXT.md research).

**Existing test setup pattern** (lines 1-20):

```elixir
defmodule Lockspire.Admin.ServerPolicyTest do
  use ExUnit.Case, async: false

  alias Lockspire.Admin.ServerPolicy
  alias Lockspire.Domain.ServerPolicy, as: DomainServerPolicy
  alias Lockspire.Storage.Ecto.Repository

  setup_all do
    Application.put_env(:lockspire, :repo, Lockspire.TestRepo)

    start_supervised!(Lockspire.TestRepo)
    Ecto.Adapters.SQL.Sandbox.mode(Lockspire.TestRepo, :manual)

    :ok
  end

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Lockspire.TestRepo)
    :ok
  end
```

**Existing `par_policy` get/put cases** (lines 22-47):

```elixir
test "get_server_policy/0 returns an optional default when no durable row exists" do
  assert {:ok, %DomainServerPolicy{} = policy} = ServerPolicy.get_server_policy()
  assert policy.par_policy == :optional
end

test "put_server_policy/1 persists optional and required modes across fresh fetches" do
  assert {:ok, %DomainServerPolicy{} = required_policy} = ServerPolicy.put_server_policy(:required)
  assert required_policy.par_policy == :required
  ...
end

test "put_server_policy/1 rejects modes outside optional and required" do
  assert {:error, [%{field: :par_policy, reason: :invalid_par_policy, detail: :inherit}]} =
           ServerPolicy.put_server_policy(:inherit)
end
```

**Deltas:**
- Keep `async: false` and existing sandbox setup — DCR cases are DB-backed, same plumbing.
- Add three sibling tests for DCR per D-07: a `get_dcr_policy/0` defaults case, a `put_dcr_policy/1` round-trip case, and a `put_dcr_policy/1` rejection case (pattern-match on the `[%{field: :registration_policy, reason: ..., detail: ...}]` shape).
- Reuse the same `Repository.get_server_policy/0` direct-fetch pattern (line 34) to verify writes landed on the singleton row.

---

## Shared Patterns

### `Ecto.Enum` text-column cast
**Source:** `lib/lockspire/storage/ecto/server_policy_record.ex:14` (and `client_record.ex:23-27`)
**Apply to:** every text column in Phase 25 that represents an enum (`registration_policy` on server_policies, `provenance` on clients).

```elixir
field(:par_policy, Ecto.Enum, values: [:optional, :required], default: :optional)
```

**Pairing rule (Pitfall 4):** every `add :foo, :text, null: false, default: "<atom>"` migration line MUST have a matching `field(:foo, Ecto.Enum, values: [...], default: :<atom>)` schema line. Drift here is silent — code pattern-matches on `:disabled` while the value is `"disabled"`.

### Hash-at-rest via `Lockspire.Security.Policy.hash_token/1`
**Source:** `lib/lockspire/security/policy.ex:84-89`
**Apply to:** every IAT write path (Phase 25 schema only; Phase 26 redemption compares against this same function).

```elixir
@spec hash_token(String.t()) :: String.t()
def hash_token(secret) when is_binary(secret) do
  :sha256
  |> :crypto.hash(secret)
  |> Base.encode16(case: :lower)
end
```

**Drift consequence (Pitfall — V2/V6 ASVS):** if a fixture or test invents a separate `:sha256 |> :crypto.hash(...) |> Base.encode16(case: :upper)` (uppercase), Phase 26 redemption silently never matches. Always go through the public function.

### Singleton-row repository plumbing
**Source:** `lib/lockspire/storage/ecto/repository.ex:96-133` (`get_server_policy/0` + `put_server_policy/1`)
**Apply to:** all DCR ServerPolicy reads/writes — DCR fields land on the same singleton row (D-04), so this plumbing is reused with zero changes. Only the `ServerPolicyRecord` `cast/3` field list widens.

```elixir
def put_server_policy(%ServerPolicy{} = policy) do
  transact(fn ->
    singleton_id = ServerPolicyRecord.singleton_id()

    ServerPolicyRecord
    |> where([stored_policy], stored_policy.id == ^singleton_id)
    |> lock("FOR UPDATE")
    |> repo().one()
    |> case do
      nil -> # insert path
      %ServerPolicyRecord{} = record -> # update path
    end
  end)
end
```

### `Map.from_struct/1` cast-source idiom
**Source:** `lib/lockspire/storage/ecto/server_policy_record.ex:23` and `client_record.ex:54`
**Apply to:** every Phase 25 changeset (`InitialAccessTokenRecord.changeset/2`, extended `ServerPolicyRecord.changeset/2`, extended `ClientRecord.changeset/2`).

```elixir
record
|> cast(Map.from_struct(policy), [:id, :par_policy])
|> validate_required([:id, :par_policy])
```

The struct-to-attrs idiom keeps domain-struct-in / changeset-out flow clean; never hand-build the attrs map from individual fields.

### `Lockspire.TestRepo.Migrations` module-name prefix
**Source:** all 6 existing `priv/repo/migrations/*.exs` (e.g., `priv/repo/migrations/20260424180000_add_lockspire_server_policy_and_client_par_policy.exs:1`)
**Apply to:** all 3 new Phase 25 migrations.

```elixir
defmodule Lockspire.TestRepo.Migrations.AddDcrFieldsToServerPolicies do
  use Ecto.Migration
  ...
end
```

The `Lockspire.TestRepo.Migrations` prefix is the consistent project convention (not `Lockspire.Repo.Migrations`).

### Test sandbox + repo setup for DB-backed tests
**Source:** `test/lockspire/admin/server_policy_test.exs:8-20`
**Apply to:** any Phase 25 test that touches `Lockspire.TestRepo` (storage round-trip tests, extended admin tests).
**Do NOT apply to:** pure-function tests (`dcr_policy_test.exs`, `dcr_policy_invariant_test.exs`, `initial_access_token_test.exs`) — they should be `async: true` and avoid the DB.

```elixir
setup_all do
  Application.put_env(:lockspire, :repo, Lockspire.TestRepo)
  start_supervised!(Lockspire.TestRepo)
  Ecto.Adapters.SQL.Sandbox.mode(Lockspire.TestRepo, :manual)
  :ok
end

setup do
  :ok = Ecto.Adapters.SQL.Sandbox.checkout(Lockspire.TestRepo)
  :ok
end
```

---

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `test/lockspire/protocol/dcr_policy_invariant_test.exs` | test (cross-module invariant) | unit | No prior intersection-invariant test exists in the repo. The closest pure-module unit shape is `security_policy_test.exs`, but the invariant assertion (cross-module `MapSet.equal?(MapSet.intersection(...), ...)`) is greenfield. Use RESEARCH.md Code Examples §7 as the prescriptive shape, not a real prior file. |
| `test/lockspire/domain/initial_access_token_test.exs` | test (domain defstruct) | unit | No `test/lockspire/domain/` directory exists in the repo today. Use the bare `use ExUnit.Case, async: true` + `alias` shape from `par_policy_test.exs` lines 1-7. |
| `test/support/fixtures/initial_access_token_fixtures.ex` | test fixtures | helper | No `.ex` fixture files exist in `test/support/fixtures/` (only `generated_host_app/.keep`). Closest helper-module pattern is `test/support/jar_test_helpers.ex`, but it serves a different purpose. Operator discretion per CONTEXT.md "Claude's Discretion" applies; Hash-at-rest shared pattern (above) is the only hard constraint. |

---

## Metadata

**Analog search scope:**
- `lib/lockspire/protocol/` (17 files)
- `lib/lockspire/storage/ecto/` (9 files)
- `lib/lockspire/domain/` (7 files)
- `lib/lockspire/admin/` (5 files)
- `lib/lockspire/security/` (1 file)
- `priv/repo/migrations/` (6 files)
- `test/lockspire/protocol/` (11 files)
- `test/lockspire/admin/` (5 files)
- `test/lockspire/storage/` (1 file)
- `test/support/` (3 files + 1 subdir)

**Files scanned:** ~65

**Pattern extraction date:** 2026-04-26

**Verification notes:**
- `lib/lockspire/protocol/jar_policy.ex` does NOT exist (CONTEXT.md Specifics §1 confirmed via `ls`). All references to a "JAR policy resolver" template in research files are stale; cite `par_policy.ex` only.
- `Discovery.token_endpoint_auth_methods_supported/0` does NOT exist as a public function today (only the private `/1` at `discovery.ex:82-88` and the module attribute at line 21). Phase 25 adds the public `/0` extraction.
- `test/lockspire/domain/` directory does not yet exist — the new `initial_access_token_test.exs` will create it.
- `test/support/fixtures/` contains no `.ex` files yet — the new `initial_access_token_fixtures.ex` will be the first.

## PATTERN MAPPING COMPLETE
