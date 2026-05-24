# Phase 45: Observability & Operator Seams - Pattern Map

**Mapped:** 2026-05-15
**Files analyzed:** Domain controllers, Admin contexts, Live views
**Analogs found:** 4 / 4

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| Domain Actions (e.g., Services, Protocol modules) | service | event-driven | `lib/lockspire/admin/clients.ex` | exact |
| Operator LiveView UIs (Admin pages) | component | request-response | `lib/lockspire/web/live/admin/clients_live/index.ex` | exact |
| Telemetry Event Configurations | utility | event-driven | `lib/lockspire/observability.ex` | exact |
| Audit Event Normalization Schemas | utility | event-driven | `lib/lockspire/audit/event.ex` | exact |

## Pattern Assignments

### Domain Actions (service, event-driven)

**Analog:** `lib/lockspire/admin/clients.ex`

**Imports pattern:**
```elixir
alias Lockspire.Clients
alias Lockspire.Clients.RegistrationResult
alias Lockspire.Domain.Client
alias Lockspire.Observability
alias Lockspire.Storage.Ecto.Repository
```

**Core Transaction + Audit + Telemetry pattern (lines 43-62):**
```elixir
case transact_with_audit(
       fn -> Clients.register_client(attrs) end,
       fn %RegistrationResult{client: client} ->
         client_audit_event(:client_created, :succeeded, client, actor, %{
           client_type: client.client_type,
           token_endpoint_auth_method: client.token_endpoint_auth_method
         })
       end
     ) do
  {:ok, %RegistrationResult{client: client} = result} ->
    emit(:client, :created, client, actor, %{
      client_type: client.client_type,
      token_endpoint_auth_method: client.token_endpoint_auth_method
    })

    {:ok, result}

  {:error, reason} ->
    {:error, reason}
end
```

**Internal Telemetry Wrapper pattern (lines 351-364):**
```elixir
defp emit(entity, action, %Client{} = client, actor, metadata) do
  Observability.emit(
    entity,
    action,
    %{},
    %{
      actor_type: actor[:type],
      actor_id: actor[:id],
      client_id: client.client_id,
      reason_code: action
    }
    |> Map.merge(metadata)
  )
end
```

---

### Operator LiveView UIs (component, request-response)

**Analog:** `lib/lockspire/web/live/admin/clients_live/index.ex`

**Imports pattern (lines 4-8):**
```elixir
use Phoenix.LiveView

alias Lockspire.Admin
alias Lockspire.Web.Components.AdminComponents
alias Lockspire.Web.Live.AdminLayoutLive
```

**Core UI URL-Driven Filtering pattern (lines 48-106):**
```elixir
<AdminLayoutLive.shell current_section={@current_section} page_title={@page_title}>
  <AdminComponents.section_card
    title="Client inventory"
    subtitle="Clients are the default operator entrypoint. Search and filters stay URL-driven."
  >
    <form method="get" action={clients_index_path()}>
      <label for="client_search">Search</label>
      <input id="client_search" name="q" type="text" value={@filters["q"]} />

      <!-- Additional filters select boxes go here -->

      <button type="submit">Apply</button>
    </form>

    <p>Total matching clients: {@total_clients}</p>

    <%= if @clients == [] do %>
      <AdminComponents.empty_state
        title="No clients match this view"
        body="Adjust the search or status filter, or register a new client."
      />
    <% else %>
      <ul class="lockspire-admin-client-list">
        <%= for client <- @clients do %>
          <li>
            <a href={client_show_path(client.client_id)}>{client.name || client.client_id}</a>
            <span>{client.client_id}</span>
            <AdminComponents.status_badge status={status_for(client)} />
            <AdminComponents.status_badge status={client.provenance} />
          </li>
        <% end %>
      </ul>
    <% end %>
  </AdminComponents.section_card>
</AdminLayoutLive.shell>
```

---

## Shared Patterns

### Standardized Telemetry & Audit Mirroring
**Source:** `lib/lockspire/observability.ex`
**Apply to:** All domain actions emitting metrics.

Telemetry actions emit two identical paths (an `[:audit | _]` path and a base `[:]` path) after sanitization.
```elixir
def emit(entity, action, measurements \\ %{}, metadata \\ %{}) when is_atom(entity) and is_atom(action) do
  redacted_metadata = redact(metadata)
  normalized_measurements = Map.put_new(measurements, :count, 1)

  :telemetry.execute(@audit_prefix ++ [entity, action], normalized_measurements, redacted_metadata)

  :telemetry.execute(
    @telemetry_prefix ++ [entity, action],
    normalized_measurements,
    redacted_metadata
  )

  :ok
end
```

### Audit Event Normalization
**Source:** `lib/lockspire/audit/event.ex`
**Apply to:** Constructing durable event logs alongside metrics (persisted safely to `AuditEventRecord`).

```elixir
def normalize(%__MODULE__{} = event) do
  %__MODULE__{
    event
    | action: normalize_optional_value(event.action),
      outcome: normalize_optional_value(event.outcome),
      reason_code: normalize_optional_value(event.reason_code),
      actor_type: normalize_optional_value(event.actor_type),
      actor_id: normalize_optional_value(event.actor_id),
      actor_display: normalize_optional_value(event.actor_display),
      resource_type: normalize_optional_value(event.resource_type),
      resource_id: normalize_optional_value(event.resource_id),
      metadata: event.metadata |> Redaction.for_audit() |> compact_metadata()
  }
end
```

## Metadata

**Analog search scope:** `lib/lockspire/web/live/admin/`, `lib/lockspire/admin/`, `lib/lockspire/observability.ex`, `lib/lockspire/audit/event.ex`
**Files scanned:** 10+
**Pattern extraction date:** 2026-05-15