# Phase 39: Automated RP Logout Propagation - Pattern Map

**Mapped:** 2026-04-29
**Files analyzed:** 16
**Analogs found:** 15 / 16

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `priv/repo/migrations/*_create_lockspire_logout_events.exs` | migration | CRUD | `priv/repo/migrations/20260429000001_add_sid_to_lockspire_interactions.exs` | partial |
| `priv/repo/migrations/*_create_lockspire_logout_deliveries.exs` | migration | CRUD | `priv/repo/migrations/20260429000002_add_sid_to_lockspire_tokens.exs` | partial |
| `priv/repo/migrations/*_add_logout_propagation_fields_to_lockspire_clients.exs` | migration | CRUD | `priv/repo/migrations/20260428153000_add_dpop_policy_fields.exs` | role-match |
| `lib/lockspire/domain/client.ex` | model | CRUD | `lib/lockspire/domain/client.ex` | exact |
| `lib/lockspire/storage/ecto/client_record.ex` | model | CRUD | `lib/lockspire/storage/ecto/client_record.ex` | exact |
| `lib/lockspire/admin/clients.ex` | service | CRUD | `lib/lockspire/admin/clients.ex` | exact |
| `lib/lockspire/protocol/registration.ex` | service | request-response | `lib/lockspire/protocol/registration.ex` | exact |
| `lib/lockspire/protocol/discovery.ex` | service | request-response | `lib/lockspire/protocol/discovery.ex` | exact |
| `lib/lockspire/storage/ecto/repository.ex` | service | CRUD | `lib/lockspire/storage/ecto/repository.ex` | exact |
| `lib/lockspire/web/controllers/end_session_controller.ex` | controller | request-response | `lib/lockspire/web/controllers/end_session_controller.ex` | exact |
| `lib/lockspire/web/controllers/end_session_html.ex` | component | request-response | `lib/lockspire/web/controllers/end_session_html.ex` | exact |
| `lib/lockspire/web/controllers/end_session_html/logged_out.html.heex` | component | request-response | `lib/lockspire/web/controllers/end_session_html/logged_out.html.heex` | exact |
| `lib/lockspire/application.ex` | config | event-driven | `lib/lockspire/application.ex` | partial |
| `lib/lockspire/domain/logout_event.ex` + `lib/lockspire/domain/logout_delivery.ex` | model | event-driven | `lib/lockspire/domain/token.ex` | role-match |
| `lib/lockspire/storage/ecto/logout_event_record.ex` + `lib/lockspire/storage/ecto/logout_delivery_record.ex` | model | CRUD | `lib/lockspire/storage/ecto/token_record.ex` | role-match |
| `lib/lockspire/workers/backchannel_logout_delivery_worker.ex` | worker | event-driven | none in repo | no-analog |

## Pattern Assignments

### `priv/repo/migrations/*_create_lockspire_logout_events.exs`

**Analog:** `priv/repo/migrations/20260429000001_add_sid_to_lockspire_interactions.exs` lines 1-10 and `priv/repo/migrations/20260428153000_add_dpop_policy_fields.exs` lines 1-12

**Migration shape**
```elixir
defmodule Lockspire.Repo.Migrations.AddSidToLockspireInteractions do
  use Ecto.Migration

  def change do
    alter table(:lockspire_interactions) do
      add :sid, :string
    end

    create index(:lockspire_interactions, [:sid])
  end
end
```

```elixir
defmodule Lockspire.TestRepo.Migrations.AddDpopPolicyFields do
  use Ecto.Migration

  def change do
    alter table(:lockspire_server_policies) do
      add :dpop_policy, :text, null: false, default: "bearer"
    end
  end
end
```

**Reuse:** `use Ecto.Migration`, a single `change/0`, explicit column defaults, and explicit indexes on lookup keys. For `logout_events`, stay in the same plain additive style: enum-like text columns, timestamps, and indexes on the session/client lookup dimensions that Phase 39 queries will need.

---

### `priv/repo/migrations/*_create_lockspire_logout_deliveries.exs`

**Analog:** `priv/repo/migrations/20260429000002_add_sid_to_lockspire_tokens.exs` lines 1-10

**Index-first additive pattern**
```elixir
def change do
  alter table(:lockspire_tokens) do
    add :sid, :string
  end

  create index(:lockspire_tokens, [:sid])
end
```

**Reuse:** keep the delivery table migration equally small and explicit. Create indexes for the durable retry queue dimensions up front, especially `logout_event_id`, `client_id`, terminal state lookups, and any uniqueness key used to prevent duplicate fan-out.

---

### `priv/repo/migrations/*_add_logout_propagation_fields_to_lockspire_clients.exs`

**Analog:** `priv/repo/migrations/20260428153000_add_dpop_policy_fields.exs` lines 4-11

**Column-addition pattern**
```elixir
alter table(:lockspire_clients) do
  add :dpop_policy, :text, null: false, default: "inherit"
end
```

**Reuse:** Phase 39’s four logout fields should follow this exact additive style. Put the two boolean `*_session_required` flags on the client table as `null: false, default: false`; keep the URIs as nullable text columns.

---

### `lib/lockspire/domain/client.ex`

**Analog:** `lib/lockspire/domain/client.ex` lines 12-48 and `lib/lockspire/domain/token.ex` lines 8-60

**Struct/type extension pattern**
```elixir
@type t :: %__MODULE__{
  ...
  post_logout_redirect_uris: [String.t()],
  ...
}

defstruct [
  ...
  post_logout_redirect_uris: [],
  ...
]
```

**Reuse:** extend the typed durable struct directly. Add the four logout-propagation fields as first-class typed members rather than hiding them in `metadata`.

For new durable logout models, copy the `Token` pattern from [`lib/lockspire/domain/token.ex`](../../../lib/lockspire/domain/token.ex:1): explicit `@type t`, explicit `defstruct`, and nil/default values for durable state.

---

### `lib/lockspire/storage/ecto/client_record.ex`

**Analog:** `lib/lockspire/storage/ecto/client_record.ex` lines 12-18, 63-117, 133-168

**Schema + cast + to-domain pattern**
```elixir
schema "lockspire_clients" do
  field(:redirect_uris, {:array, :string}, default: [])
  field(:post_logout_redirect_uris, {:array, :string}, default: [])
end
```

```elixir
|> cast(Map.from_struct(client), [
  :redirect_uris,
  :post_logout_redirect_uris,
  ...
])
|> validate_required([
  :client_id,
  ...
])
```

```elixir
def update_changeset(record, attrs) do
  record
  |> cast(attrs, [
    :name,
    :redirect_uris,
    :post_logout_redirect_uris,
    ...
  ])
end
```

**Reuse:** add the four new fields in all three places together: schema, create cast, update cast, and `to_domain/1`. Keep the existing “operator-safe update path” discipline intact.

For new `logout_event_record` and `logout_delivery_record` modules, follow the same three-part record pattern as [`lib/lockspire/storage/ecto/token_record.ex`](../../../lib/lockspire/storage/ecto/token_record.ex:12): schema, `changeset/2`, and `to_domain/1`.

---

### `lib/lockspire/admin/clients.ex`

**Analog:** `lib/lockspire/admin/clients.ex` lines 12-24, 123-127, 206-249, 310-340, 414-495

**Mutable-field boundary**
```elixir
@mutable_fields ~w(
  name
  redirect_uris
  post_logout_redirect_uris
  ...
)a
```

**Safe update path**
```elixir
with {:ok, %Client{} = client} <- get_client(client_id),
     :ok <- reject_immutable_changes(attrs),
     :ok <- validate_safe_update(attrs) do
  Repository.update_client(client, normalize_update_attrs(attrs))
end
```

**Field-specific validation remap**
```elixir
defp validate_post_logout_redirects_if_present(attrs) do
  case fetch_attr(attrs, :post_logout_redirect_uris) do
    nil -> :ok
    post_logout_redirect_uris ->
      case Clients.validate_redirect_uris(post_logout_redirect_uris) do
        :ok -> :ok
        {:error, errors} ->
          {:error, Enum.map(errors, &Map.put(&1, :field, :post_logout_redirect_uris))}
      end
  end
end
```

**Audit + telemetry emission**
```elixir
Repository.transact(fn ->
  case fun.() do
    {:ok, result} -> append_audit_event(build_audit_event, result)
    {:error, reason} -> {:error, reason}
  end
end)
```

```elixir
Observability.emit(event, %{}, %{
  actor_type: actor[:type],
  actor_id: actor[:id],
  client_id: client.client_id,
  reason_code: event
} |> Map.merge(metadata))
```

**Reuse:** add Phase 39 client validation here, not in the LiveView. Specifically:
- URI normalization and dedupe belong in `normalize_update_attrs/1`.
- Offline validation belongs in a dedicated `validate_*_if_present/1`.
- Client-save audit/telemetry should keep the same actor/resource metadata pattern.

---

### `lib/lockspire/protocol/registration.ex`

**Analog:** `lib/lockspire/protocol/registration.ex` lines 124-130 and 135-140

**Unsupported-in-slice rejection pattern**
```elixir
def validate_intake_metadata(metadata, %Resolved{} = _resolved) when is_map(metadata) do
  with :ok <- validate_jwks(metadata),
       :ok <- validate_grant_response_coherence(metadata),
       :ok <- validate_redirect_uris(metadata) do
    validate_pkce_floor(metadata)
  end
end
```

```elixir
Map.has_key?(metadata, "jwks_uri") ->
  {:error,
   %Error{code: :invalid_client_metadata, field: :jwks_uri, reason: :unsupported_in_slice}}
```

**Reuse:** reject DCR-supplied `backchannel_logout_uri`, `backchannel_logout_session_required`, `frontchannel_logout_uri`, and `frontchannel_logout_session_required` with this exact error shape instead of silently ignoring them.

Test analog: `test/lockspire/protocol/registration_test.exs` lines 306-324 pins `:unsupported_in_slice` behavior.

---

### `lib/lockspire/protocol/discovery.ex`

**Analog:** `lib/lockspire/protocol/discovery.ex` lines 75-95 and 176-180

**Truthful discovery builder**
```elixir
%{
  "issuer" => issuer,
  ...
}
|> Map.merge(endpoint_metadata)
|> maybe_put_dpop_metadata(endpoint_metadata)
|> put_bcl_fcl_metadata()
```

```elixir
defp put_bcl_fcl_metadata(metadata) do
  Map.merge(metadata, %{
    "backchannel_logout_supported" => false,
    "frontchannel_logout_supported" => false
  })
end
```

**Reuse:** keep the same pure map-builder shape. Phase 39 should only flip these booleans once both delivery and browser surfaces are actually wired. Add the two `*_session_supported` booleans in the same single truth function so discovery cannot drift into half-shipped state.

Test analogs:
- `test/lockspire/protocol/discovery_test.exs` lines 124-141
- `test/lockspire/web/discovery_controller_test.exs` lines 62-110

---

### `lib/lockspire/storage/ecto/repository.ex`

**Analog:** `lib/lockspire/storage/ecto/repository.ex` lines 444-459 and 606-620

**Persist-then-audit transaction**
```elixir
def transact_with_audit(audit_event, fun) when is_function(fun, 0) do
  transact(fn ->
    result =
      case fun.() do
        {:ok, value} -> value
        {:error, reason} -> repo().rollback(reason)
        value -> value
      end

    case append_audit_event(audit_event) do
      {:ok, _event} -> result
      {:error, reason} -> repo().rollback(reason)
    end
  end)
end
```

**Bulk status update**
```elixir
def revoke_by_sid(sid) when is_binary(sid) do
  {count, _records} =
    TokenRecord
    |> where([token], token.sid == ^sid)
    |> where([token], is_nil(token.revoked_at))
    |> where([token], is_nil(token.redeemed_at))
    |> repo_update_all(
      [set: [revoked_at: DateTime.utc_now(), updated_at: DateTime.utc_now()]],
      sensitive: true
    )

  {:ok, count}
end
```

**Reuse:** Phase 39 durable logout persistence should follow this split:
- DB state transitions and enqueue intent happen in repository-backed transactions.
- No outbound HTTP occurs inside those transactions.
- Bulk state transitions should use `repo_update_all` style updates where appropriate.

---

### `lib/lockspire/web/controllers/end_session_controller.ex`

**Analog:** `lib/lockspire/web/controllers/end_session_controller.ex` lines 20-40, 67-82, 106-120

**Thin controller / protocol-owned correctness**
```elixir
case EndSession.validate(%{params: params}) do
  {:ok, %EndSession.Result{} = result} ->
    completion_token = sign_completion_token(result)
    completion_url = append_query_param(Config.mount_path() <> "/end_session/complete", "token", completion_token)
    redirect(conn, to: host_logout_destination(conn, result, completion_url))
```

**Completion fork point**
```elixir
case Phoenix.Token.verify(...) do
  {:ok, payload} when is_map(payload) ->
    revoke_sid(payload["sid"] || payload[:sid])
    redirect_or_render_logged_out(conn, payload["post_logout_redirect_uri"] || payload[:post_logout_redirect_uri], payload["state"] || payload[:state])
```

**Minimal HTML fallback**
```elixir
conn
|> put_resp_content_type("text/html")
|> send_resp(200, logged_out_page())
```

**Reuse:** keep `/end_session/complete` as the sole completion seam. Extend that branch to:
- persist logout propagation intent,
- enqueue back-channel work,
- render front-channel iframe state,
- then continue or redirect.

Do not move third-party dispatch into the request-start path.

Test analog: `test/lockspire/web/end_session_controller_test.exs` lines 152-205.

---

### `lib/lockspire/web/controllers/end_session_html.ex` and `.../logged_out.html.heex`

**Analog:** `lib/lockspire/web/controllers/end_session_html.ex` lines 1-6 and `logged_out.html.heex`

**Plain HEEx embedding**
```elixir
defmodule Lockspire.Web.EndSessionHTML do
  use Phoenix.Component
  embed_templates "end_session_html/*"
end
```

**Minimal page pattern**
```heex
<main>
  <section class="lockspire-logged-out">
    <h1>You have been signed out</h1>
    <p>Your session has ended. You may close this tab or return to the application.</p>
  </section>
</main>
```

**Reuse:** Phase 39’s front-channel completion page should stay in this plain controller-rendered HEEx family, not LiveView. Extend the current page rather than introducing a new rendering stack.

---

### `lib/lockspire/application.ex`

**Analog:** `lib/lockspire/application.ex` lines 8-15 and `config/config.exs` lines 3-9

**Supervision seam**
```elixir
def start(_type, _args) do
  children = [
    # Library-owned services will be added here...
  ]

  Supervisor.start_link(children, strategy: :one_for_one, name: Lockspire.Supervisor)
end
```

**Public config seam**
```elixir
config :lockspire,
  ...
  oban: [],
  ...
```

**Reuse:** if Phase 39 introduces library-owned Oban wiring, this is the sanctioned seam. Add the Oban child here and drive it from the existing `config :lockspire, oban: []` surface instead of inventing a separate runtime config API.

---

### `lib/lockspire/domain/logout_event.ex` + `lib/lockspire/domain/logout_delivery.ex`

**Analog:** `lib/lockspire/domain/token.ex` lines 6-60

**Durable domain state pattern**
```elixir
@type t :: %__MODULE__{
  id: integer() | nil,
  ...
  inserted_at: DateTime.t() | nil,
  updated_at: DateTime.t() | nil
}

defstruct [
  :id,
  ...
]
```

**Reuse:** model logout propagation as typed durable records with explicit state fields, not anonymous maps. Give each struct explicit terminal/transient timestamps and reason fields needed for retries and auditability.

---

### `lib/lockspire/storage/ecto/logout_event_record.ex` + `lib/lockspire/storage/ecto/logout_delivery_record.ex`

**Analog:** `lib/lockspire/storage/ecto/token_record.ex` lines 12-95

**Record-module pattern**
```elixir
schema "lockspire_tokens" do
  field(:token_hash, :string)
  ...
  timestamps()
end

def changeset(record, %Token{} = token) do
  record
  |> cast(Map.from_struct(token), [...])
  |> validate_required([...])
end

def to_domain(%__MODULE__{} = record) do
  %Token{...}
end
```

**Reuse:** mirror this exact schema/changeset/to-domain triplet for the new durable logout tables. That keeps repository code consistent with every other Ecto-backed domain surface in Lockspire.

---

### `lib/lockspire/workers/backchannel_logout_delivery_worker.ex`

**Analog:** none in repo

**Implication**
- There is no existing `Oban.Worker` or library-owned worker module to copy.
- Reuse `application.ex` and `config/config.exs` for supervision/config seams.
- Reuse repository transaction boundaries and observability/audit/redaction helpers for job body behavior.

**Planner note:** treat this as a new pattern introduction, not a copy-paste task.

## Shared Patterns

### Observability
**Source:** `lib/lockspire/observability.ex` lines 15-28
```elixir
def emit(event_name, measurements \\ %{}, metadata \\ %{}) when is_atom(event_name) do
  redacted_metadata = redact(metadata)
  normalized_measurements = Map.put_new(measurements, :count, 1)

  :telemetry.execute(@audit_prefix ++ [event_name], normalized_measurements, redacted_metadata)
  :telemetry.execute(@telemetry_prefix ++ [event_name], normalized_measurements, redacted_metadata)
end
```

Apply to all Phase 39 enqueue/attempt/success/failure signals. Emit distinct events; do not collapse enqueue and HTTP success.

### Audit Normalization
**Source:** `lib/lockspire/audit/event.ex` lines 39-76
```elixir
%__MODULE__{
  action: attrs |> get_value(:action) |> normalize_required_value(),
  outcome: attrs |> get_value(:outcome) |> normalize_required_value(),
  ...
  metadata:
    attrs
    |> get_value(:metadata, %{})
    |> Redaction.for_audit()
    |> compact_metadata()
}
```

Apply to durable logout event/delivery audit rows. Keep action, outcome, actor, resource, and compact metadata explicit.

### Redaction
**Source:** `lib/lockspire/redaction.ex` lines 127-141 and 186-222
```elixir
def for_telemetry(metadata) when is_map(metadata) do
  metadata |> Enum.reduce(%{}, &reduce_telemetry_metadata/2)
end

def for_audit(metadata) when is_map(metadata) do
  metadata |> Enum.reduce(%{}, &reduce_audit_metadata/2)
end
```

Apply to logout token payloads, response bodies, and query strings. Raw logout JWTs and raw HTTP bodies should not survive into telemetry or audit metadata.

### Controller Truthfulness
**Source:** `lib/lockspire/web/controllers/end_session_controller.ex` lines 67-82 and `logged_out.html.heex`

Apply to the front-channel completion page. The UX should remain minimal and honest: best-effort browser cleanup, bounded wait, visible continue fallback.

## Test Patterns To Reuse

### Protocol validation tests
**Sources**
- `test/lockspire/protocol/end_session_test.exs` lines 21-136
- `test/lockspire/protocol/registration_test.exs` lines 306-324

**Reuse:** small module-local fake stores, direct protocol calls, and precise error-shape assertions for unsupported metadata and URI validation.

### Controller integration tests
**Source:** `test/lockspire/web/end_session_controller_test.exs` lines 71-205

**Reuse:** full router calls via `build_conn`, signed completion-token fixtures, and DB assertions after `/end_session/complete`.

### Discovery truth tests
**Sources**
- `test/lockspire/protocol/discovery_test.exs` lines 124-141
- `test/lockspire/web/discovery_controller_test.exs` lines 62-110

**Reuse:** assert exact discovery booleans in both protocol and HTTP layers when Phase 39 flips them on.

### Admin workflow tests
**Sources**
- `test/lockspire/admin/clients_test.exs` lines 228-245
- `test/lockspire/web/live/admin/clients_live_test.exs` lines 136-167 and 304-323

**Reuse:** pair command-boundary tests with LiveView workflow tests. Phase 39 should do the same for new logout client metadata and any delivery-status/operator surfaces.

### Repository durability tests
**Sources**
- `test/lockspire/storage/ecto/repository_sid_test.exs` lines 38-109
- `test/lockspire/storage/ecto/client_record_test.exs` lines 19-124

**Reuse:** verify bulk transitions, nil/empty edge cases, persistence round-trips, and update-cast boundaries at the Ecto layer.

## No Analog Found

| File | Role | Data Flow | Reason |
|---|---|---|---|
| `lib/lockspire/workers/backchannel_logout_delivery_worker.ex` | worker | event-driven | No `Oban.Worker` modules exist yet in the repo. Phase 39 introduces this pattern for the first time. |

## Metadata

**Analog search scope:** `lib/lockspire`, `priv/repo/migrations`, `test/lockspire`
**Files scanned:** 30+
**Pattern extraction date:** 2026-04-29
