# Phase 28: Operator Admin UI and Telemetry - Pattern Map

**Mapped:** 2024-04-26
**Files analyzed:** 6
**Analogs found:** 6 / 6

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/lockspire/web/live/admin/policies_live/dcr.ex` | controller (LiveView) | CRUD | `policies_live/par.ex` | exact |
| `lib/lockspire/web/live/admin/iat_live/index.ex` | controller (LiveView) | CRUD | `tokens_live/index.ex` | exact |
| `lib/lockspire/web/live/admin/iat_live/new.ex` | controller (LiveView) | CRUD | `clients_live/index.ex` (form) | partial |
| `lib/lockspire/web/live/admin/clients_live/index.ex` | controller (LiveView) | CRUD | self (modifying) | exact |
| `lib/lockspire/web/live/admin/clients_live/show.ex` | controller (LiveView) | CRUD | self (modifying) | exact |
| `test/integration/phase28_e2e_test.exs` | test | event-driven | `protocol/dcr_telemetry_redaction_test.exs` | exact |

## Pattern Assignments

### `lib/lockspire/web/live/admin/policies_live/dcr.ex` (controller, CRUD)

**Analog:** `lib/lockspire/web/live/admin/policies_live/par.ex`

**Core Pattern (Form Submission & State)** (lines 33-50):
```elixir
  @impl true
  def handle_event("save_policy", %{"policy" => %{"par_policy" => mode}}, socket) do
    case Admin.put_server_policy(mode) do
      {:ok, %ServerPolicy{} = policy} ->
        {:noreply,
         socket
         |> assign(policy: policy, form_errors: [])
         |> put_flash(:info, "Global PAR policy updated")}

      {:error, errors} when is_list(errors) ->
        {:noreply, assign(socket, form_errors: errors)}

      {:error, _reason} ->
        {:noreply,
         assign(socket,
           form_errors: [%{field: :par_policy, reason: :request_failed, detail: nil}]
         )}
    end
  end
```

**Testing Pattern** (`test/lockspire/web/live/admin/policies_live/par_test.exs`, lines 65-75):
```elixir
  test "saving global PAR policy persists change" do
    assert {:ok, _policy} = ServerPolicy.put_server_policy(:optional)

    assert {:ok, view, _html} = live(conn_for_admin(), "/admin/policies/par")

    view
    |> form("form[phx-submit=save_policy]", %{policy: %{par_policy: "required"}})
    |> render_submit()

    assert {:ok, %{par_policy: :required}} = ServerPolicy.get_server_policy()
  end
```

---

### `lib/lockspire/web/live/admin/iat_live/index.ex` (controller, CRUD)

**Analog:** `lib/lockspire/web/live/admin/tokens_live/index.ex`

**Core Listing and Filtering Pattern** (lines 32-41):
```elixir
  @impl true
  def handle_params(params, _uri, socket) do
    filters = normalize_filters(params)
    tokens = load_tokens(filters)

    {:noreply,
     assign(socket,
       filters: filters,
       tokens: tokens,
       total_tokens: length(tokens)
     )}
  end
```

---

### `lib/lockspire/web/live/admin/iat_live/new.ex` (controller, CRUD)

**Analog:** `lib/lockspire/web/live/admin/clients_live/index.ex` (for reveal-once pattern)

**Copy-Once Reveal Pattern** (`clients_live/index.ex`, lines 84-93):
```elixir
        <div :if={@created_result} class="lockspire-admin-secret-reveal">
          <h3>Client created</h3>
          <p>Client ID: <code>{@created_result.client.client_id}</code></p>
          <p :if={@created_result.client_secret}>
            Client secret: <code>{@created_result.client_secret}</code>
          </p>
          <p :if={!@created_result.client_secret}>This public client does not use a client secret.</p>
        </div>
```
*(Apply this shape to reveal the IAT plaintext secret with a strong warning.)*

---

### `lib/lockspire/web/live/admin/clients_live/index.ex` (controller, CRUD - modification)

**Analog:** Self

**Adding Filter and Provenance Column Pattern** (lines 104-108, modifying `load_clients`):
```elixir
  defp load_clients(filters) do
    opts =
      [search: blank_to_nil(filters["q"])]
      |> put_status_filter(filters["status"])
      # -> ADD: |> put_provenance_filter(filters["provenance"])
```

**List View Pattern** (lines 75-79):
```elixir
              <li>
                <a href={client_show_path(client.client_id)}>{client.name || client.client_id}</a>
                <span>{client.client_id}</span>
                <!-- ADD provenance badge here -->
                <AdminComponents.status_badge status={status_for(client)} />
              </li>
```

---

### `lib/lockspire/web/live/admin/clients_live/show.ex` (controller, CRUD - modification)

**Analog:** Self

**Adding Live Action Pattern** (lines 112-118, mirror `:rotate_secret` for `:rotate_registration_access_token`):
```elixir
      <AdminComponents.section_card
        :if={@action == :rotate_secret}
        title="Secret rotation"
        subtitle="Rotation is explicit and reveals the new secret once."
      >
        <RotateSecretComponent.rotation_panel
          errors={@rotation_errors}
          revealed_secret={@revealed_secret}
        />
      </AdminComponents.section_card>
```

---

### E2E Telemetry Assertion Test (test, event-driven)

**Analog:** `test/lockspire/protocol/dcr_telemetry_redaction_test.exs`

**Telemetry Attachment Pattern** (lines 50-60):
```elixir
      :telemetry.attach_many(
        handler_id,
        @attached_events,
        fn event, measurements, metadata, pid ->
          send(pid, {:telemetry_event, event, measurements, metadata})
        end,
        self()
      )

    on_exit(fn -> :telemetry.detach(handler_id) end)
```

## Shared Patterns

### Telemetry Emission Wrapper
**Source:** `lib/lockspire/observability.ex`
**Apply to:** All protocol/domain logic modified for Phase 28 telemetry
```elixir
    :telemetry.execute(
      @telemetry_prefix ++ [event_name],
      normalized_measurements,
      redacted_metadata
    )
```
*(All new DCR and IAT events must pass through `Observability.emit/3` which expands them to `[:lockspire, :event_name]` or update it to handle namespace correctly).*

## No Analog Found

None. All Phase 28 features neatly follow established administrative views, copy-once UI workflows, and established `telemetry` attachment testing models.
