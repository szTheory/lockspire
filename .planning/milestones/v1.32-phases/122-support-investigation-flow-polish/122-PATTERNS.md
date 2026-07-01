# Phase 122: support-investigation-flow-polish - Pattern Map

**Mapped:** 2026-06-28  
**Files analyzed:** 10 required/conditional files  
**Analogs found:** 10 / 10

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/lockspire/web/live/admin/tokens_live/index.ex` | route / LiveView | request-response, transform | `lib/lockspire/web/live/admin/tokens_live/index.ex`; `lib/lockspire/web/live/admin/device_authorizations_live/index.ex` | exact + role-match |
| `lib/lockspire/web/live/admin/tokens_live/show.ex` | route / LiveView | event-driven, request-response | `lib/lockspire/web/live/admin/tokens_live/show.ex`; `lib/lockspire/web/live/admin/clients_live/show.ex` | exact + role-match |
| `lib/lockspire/web/live/admin/consents_live/index.ex` | route / LiveView | request-response, transform | `lib/lockspire/web/live/admin/consents_live/index.ex`; `lib/lockspire/web/live/admin/device_authorizations_live/index.ex` | exact + role-match |
| `lib/lockspire/web/live/admin/consents_live/show.ex` | route / LiveView | event-driven, request-response | `lib/lockspire/web/live/admin/consents_live/show.ex`; `lib/lockspire/web/live/admin/clients_live/show.ex` | exact + role-match |
| `lib/lockspire/web/components/admin_components.ex` | component | transform | `lib/lockspire/web/components/admin_components.ex`; `test/support/lockspire/web/admin_lab/stress_surface.ex` | exact |
| `lib/lockspire/web/admin_css.ex` | config / style | transform | `lib/lockspire/web/admin_css.ex`; `test/lockspire/web/live/admin/design_system_contract_test.exs` | exact |
| `test/lockspire/web/live/admin/tokens_live_test.exs` | test | request-response, event-driven | `test/lockspire/web/live/admin/tokens_live_test.exs`; `test/lockspire/web/live/admin/consents_live_test.exs` | exact |
| `test/lockspire/web/live/admin/consents_live_test.exs` | test | request-response, event-driven | `test/lockspire/web/live/admin/consents_live_test.exs`; `test/lockspire/web/live/admin/tokens_live_test.exs` | exact |
| `test/lockspire/web/live/admin/design_system_contract_test.exs` | test | file-I/O, transform | `test/lockspire/web/live/admin/design_system_contract_test.exs` | exact, conditional |
| `test/lockspire/web/live/admin/design_system_component_stress_test.exs` | test | component render, transform | `test/lockspire/web/live/admin/design_system_component_stress_test.exs`; `test/support/lockspire/web/admin_lab/stress_surface.ex` | exact, conditional |
| planner-selected internal helper, only if needed | utility | transform | private helper patterns in the four LiveViews and `lib/lockspire/web/live/admin/logout_deliveries_live/index.ex` | role-match, optional |

## Pattern Assignments

### `lib/lockspire/web/live/admin/tokens_live/index.ex` (route / LiveView, request-response)

**Analog:** `lib/lockspire/web/live/admin/tokens_live/index.ex` for URL-owned filters/Admin API boundary; `lib/lockspire/web/live/admin/device_authorizations_live/index.ex` for dense-row list anatomy.

**Imports pattern** (`tokens_live/index.ex` lines 4-9):
```elixir
use Phoenix.LiveView

alias Lockspire.Admin
alias Lockspire.Redaction
alias Lockspire.Web.Components.AdminComponents
alias Lockspire.Web.Live.AdminLayoutLive
```

**Route-owned filter/load pattern** (`tokens_live/index.ex` lines 24-35, 155-165):
```elixir
def handle_params(params, _uri, socket) do
  filters = normalize_filters(params)
  tokens = load_tokens(filters)

  {:noreply,
   assign(socket,
     filters: filters,
     tokens: tokens,
     total_tokens: length(tokens),
     token_metrics: token_metrics(tokens)
   )}
end

defp load_tokens(filters) do
  opts =
    []
    |> put_filter(:account_id, filters["account"])
    |> put_filter(:client_id, filters["client"])
    |> put_status_filter(filters["status"])

  case Admin.list_tokens(opts) do
    {:ok, tokens} -> tokens
    {:error, _reason} -> []
  end
end
```

**Decision-summary component API** (`admin_components.ex` lines 186-210):
```elixir
slot :item, required: true do
  attr(:label, :string, required: true)
  attr(:value, :string, required: true)
  attr(:detail, :string)
  attr(:tone, :atom)
end

def decision_summary(assigns) do
  ~H"""
  <dl class={["lockspire-admin-decision-summary", @class]}>
    <%= for item <- @item do %>
      <div class={decision_summary_item_class(Map.get(item, :tone, :neutral))}>
        <dt>{item.label}</dt>
        <dd>{item.value}</dd>
        <p :if={Map.get(item, :detail)}>{item.detail}</p>
        <div :if={item.inner_block != []} class="lockspire-admin-decision-summary__extra">
          {render_slot(item)}
        </div>
      </div>
    <% end %>
  </dl>
  """
end
```

**Dense row pattern to copy** (`device_authorizations_live/index.ex` lines 69-84):
```elixir
<AdminComponents.resource_list>
  <%= for auth <- @device_authorizations do %>
    <AdminComponents.dense_resource_row
      title="Device authorization"
      subtitle="Review device authorizations"
    >
      <:meta>
        <span>Client <AdminComponents.long_value value={redacted_handle(:client, auth.client_id)} kind={:id} /></span>
        <span>Subject <AdminComponents.long_value value={redacted_handle(:account, auth.subject_id)} kind={:id} /></span>
        <span>Handle <AdminComponents.long_value value={redacted_handle(:device_authorization, auth.id || auth.verification_handle)} kind={:id} /></span>
        <span>Expires <AdminComponents.long_value value={formatted_timestamp(auth.expires_at)} kind={:timestamp} /></span>
      </:meta>
      <:status>
        <AdminComponents.status_badge status={auth.status} domain={:device_authorization} />
      </:status>
    </AdminComponents.dense_resource_row>
  <% end %>
</AdminComponents.resource_list>
```

**Redaction/timestamp helper pattern** (`tokens_live/index.ex` lines 201-218):
```elixir
defp selected_filter(""), do: "All"
defp selected_filter("all"), do: "All"
defp selected_filter(value), do: value

defp redacted_handle(_type, nil), do: "Not recorded"
defp redacted_handle(type, value), do: Redaction.handle(type, value)

defp formatted_timestamp(nil), do: "Not recorded"

defp formatted_timestamp(%DateTime{} = value),
  do: Calendar.strftime(value, "%Y-%m-%d %H:%M:%SZ")

defp formatted_timestamp(value), do: to_string(value)
```

Planner note: Phase 122 should replace the index row contract from `AdminComponents.resource_item` (`tokens_live/index.ex` lines 104-148) with `AdminComponents.dense_resource_row`, and add the exact summary labels: `Selected filters`, `Token health`, `Family pressure`, `Smallest safe action`.

---

### `lib/lockspire/web/live/admin/tokens_live/show.ex` (route / LiveView, event-driven)

**Analog:** `lib/lockspire/web/live/admin/tokens_live/show.ex` for mount/load/events/detail panes; `lib/lockspire/web/live/admin/clients_live/show.ex` for confirmation errors passed through component `errors`.

**Mount/load pattern** (`tokens_live/show.ex` lines 11-31, 273-279):
```elixir
def mount(%{"id" => id}, _session, socket) do
  {:ok,
   assign(socket,
     page_title: "Token detail",
     current_section: :tokens,
     token_id: parse_id(id),
     token_detail: nil,
     revoke_error: nil,
     family_error: nil,
     family_notice: nil
   )}
end

def handle_params(params, _uri, socket) do
  token_id = parse_id(Map.get(params, "id", socket.assigns.token_id))

  {:noreply,
   socket
   |> assign(token_id: token_id, revoke_error: nil, family_error: nil, family_notice: nil)
   |> load_token(token_id)}
end

defp load_token(socket, token_id) do
  case Admin.get_token(token_id) do
    {:ok, token_detail} -> assign(socket, token_detail: token_detail)
    {:error, _reason} -> assign(socket, token_detail: nil)
  end
end
```

**Event/API boundary pattern** (`tokens_live/show.ex` lines 35-83):
```elixir
def handle_event("revoke_token", %{"revoke" => %{"confirm" => "true"}}, socket) do
  case Admin.revoke_token(socket.assigns.token_id, %{revoked_by: "operator"}) do
    {:ok, detail} ->
      {:noreply, assign(socket, token_detail: detail, revoke_error: nil)}

    {:error, _reason} ->
      {:noreply, assign(socket, revoke_error: "Token could not be revoked.")}
  end
end

def handle_event("revoke_family", %{"family" => %{"confirm" => "true"}}, socket) do
  case Admin.revoke_token_family(socket.assigns.token_id, %{revoked_by: "operator"}) do
    {:ok, %{count: count, token: detail}} ->
      ...

    {:error, :no_family} ->
      {:noreply,
       assign(socket, family_error: "This token does not belong to a refresh family.")}

    {:error, _reason} ->
      {:noreply, assign(socket, family_error: "Refresh family could not be revoked.")}
  end
end
```

Planner note: keep the event/API shape, but replace error strings with locked Phase 122 copy and pass them through `confirmation_panel` `errors` or another existing error primitive.

**Detail pane and lineage pattern** (`tokens_live/show.ex` lines 126-210):
```elixir
<AdminComponents.pane
  title="Token identity and current state"
  subtitle="Review the durable token pivots used by support without rendering hashes or plaintext token material."
>
  <AdminComponents.description_list>
    <:item label="Client">
      <AdminComponents.long_value value={@token_detail.token.client_display} kind={:id} />
    </:item>
    ...
    <:item label="Reuse detected at">
      <AdminComponents.timestamp value={@token_detail.token.reuse_detected_at} />
    </:item>
  </AdminComponents.description_list>
</AdminComponents.pane>

<AdminComponents.resource_list>
  <%= for entry <- @token_detail.family_tokens do %>
    <AdminComponents.dense_resource_row
      title={if(entry.current?, do: "Current token", else: entry.token.handle)}
      subtitle={"#{entry.token.token_type} token generation #{entry.token.generation}"}
    >
      <:meta>
        <span>
          Token
          <AdminComponents.long_value value={entry.token.handle} kind={:id} />
        </span>
      </:meta>
      <:status>
        <AdminComponents.status_badge status={entry.status} />
      </:status>
    </AdminComponents.dense_resource_row>
  <% end %>
</AdminComponents.resource_list>
```

**Confirmation errors pattern to copy** (`clients_live/show.ex` lines 557-588):
```elixir
<AdminComponents.confirmation_panel
  title={if @client.active, do: "Confirm client disable", else: "Confirm client enable"}
  variant={if @client.active, do: :danger, else: :warning}
  errors={@lifecycle_errors}
>
  <:body>
    <form class="lockspire-admin-form-stack" phx-submit="toggle_client">
      <label class="lockspire-admin-checkbox-field">
        <input type="checkbox" name="toggle[confirm]" value="true" />
        <span>
          <%= if @client.active do %>
            Disable
            <AdminComponents.long_value value={@client.client_id} kind={:id} />
            so future OAuth/OIDC requests for this client are blocked until an operator enables it again.
          <% else %>
            Enable
            <AdminComponents.long_value value={@client.client_id} kind={:id} />
            so configured OAuth/OIDC use can resume.
          <% end %>
        </span>
      </label>
      <AdminComponents.action_bar>
        <AdminComponents.admin_button
          type="submit"
          variant={if @client.active, do: :danger, else: :secondary}
        >
          {if @client.active, do: "Disable client", else: "Enable client"}
        </AdminComponents.admin_button>
      </AdminComponents.action_bar>
    </form>
  </:body>
</AdminComponents.confirmation_panel>
```

**Closed-state predicate source** (`lib/lockspire/admin/tokens.ex` lines 190-204):
```elixir
defp token_status(%Token{reuse_detected_at: %DateTime{}}), do: :reuse_detected
defp token_status(%Token{revoked_at: %DateTime{}}), do: :revoked

defp token_status(%Token{expires_at: %DateTime{} = expires_at}) do
  if DateTime.compare(expires_at, DateTime.utc_now()) == :gt, do: :active, else: :expired
end

defp family_status(tokens) do
  cond do
    Enum.any?(tokens, &(&1.status == :reuse_detected)) -> :reuse_detected
    Enum.any?(tokens, &(&1.status == :active)) -> :active
    Enum.any?(tokens, &(&1.status == :expired)) -> :expired
    true -> :revoked
  end
end
```

Planner note: derive closed UI from explicit `revoked_at`, `reuse_detected_at`, and family presence, not only `@token_detail.status == :revoked`.

---

### `lib/lockspire/web/live/admin/consents_live/index.ex` (route / LiveView, request-response)

**Analog:** `lib/lockspire/web/live/admin/consents_live/index.ex` for URL-owned filters/Admin API boundary; `lib/lockspire/web/live/admin/interactions_live/index.ex` for dense non-table rows.

**Imports and filter/load pattern** (`consents_live/index.ex` lines 4-9, 24-35, 147-157):
```elixir
use Phoenix.LiveView

alias Lockspire.Admin
alias Lockspire.Redaction
alias Lockspire.Web.Components.AdminComponents
alias Lockspire.Web.Live.AdminLayoutLive

def handle_params(params, _uri, socket) do
  filters = normalize_filters(params)
  consents = load_consents(filters)

  {:noreply,
   assign(socket,
     filters: filters,
     consents: consents,
     total_consents: length(consents),
     consent_metrics: consent_metrics(consents)
   )}
end

defp load_consents(filters) do
  opts =
    []
    |> put_filter(:account_id, filters["account"])
    |> put_filter(:client_id, filters["client"])
    |> put_status_filter(filters["status"])

  case Admin.list_consents(opts) do
    {:ok, consents} -> consents
    {:error, _reason} -> []
  end
end
```

**Dense row pattern to copy** (`interactions_live/index.ex` lines 68-85):
```elixir
<AdminComponents.resource_list>
  <%= for interaction <- @interactions do %>
    <AdminComponents.dense_resource_row
      title="Authorization interaction"
      subtitle="Review interactions"
    >
      <:meta>
        <span>Interaction <AdminComponents.long_value value={interaction.interaction_id} kind={:id} /></span>
        <span>Client <AdminComponents.long_value value={redacted_handle(:client, interaction.client_id)} kind={:id} /></span>
        <span>Subject <AdminComponents.long_value value={redacted_handle(:account, interaction.account_id)} kind={:id} /></span>
        <span>Prompt <AdminComponents.long_value value={prompt_label(interaction.prompt)} kind={:text} /></span>
        <span>Created <AdminComponents.long_value value={formatted_timestamp(interaction.inserted_at)} kind={:timestamp} /></span>
        <span>Expires <AdminComponents.long_value value={formatted_timestamp(interaction.expires_at)} kind={:timestamp} /></span>
      </:meta>
      <:status>
        <AdminComponents.status_badge status={interaction.status} />
      </:status>
    </AdminComponents.dense_resource_row>
  <% end %>
</AdminComponents.resource_list>
```

**Consent-specific helpers** (`consents_live/index.ex` lines 179-210):
```elixir
defp consent_metrics(consents) do
  %{
    active: Enum.count(consents, &(&1.grant.status == :active)),
    revoked: Enum.count(consents, &(&1.grant.status == :revoked))
  }
end

defp selected_filter(""), do: "All"
defp selected_filter("all"), do: "All"
defp selected_filter(value), do: value

defp redacted_handle(_type, nil), do: "Not recorded"
defp redacted_handle(type, value), do: Redaction.handle(type, value)

defp scope_label([]), do: "No scopes recorded"
defp scope_label(scopes), do: Enum.join(scopes, ", ")
```

Planner note: add the exact summary labels `Selected filters`, `Grant status`, `Scope context`, `Smallest safe action`, and convert rows away from `AdminComponents.resource_item` (`consents_live/index.ex` lines 96-140) toward dense rows.

---

### `lib/lockspire/web/live/admin/consents_live/show.ex` (route / LiveView, event-driven)

**Analog:** `lib/lockspire/web/live/admin/consents_live/show.ex` for consent detail/event boundary; `lib/lockspire/web/live/admin/clients_live/show.ex` for `confirmation_panel` errors and consequence copy structure.

**Event/API boundary pattern** (`consents_live/show.ex` lines 34-51):
```elixir
def handle_event("revoke_consent", %{"revoke" => %{"confirm" => "true"}}, socket) do
  case Admin.revoke_consent(socket.assigns.consent_id, %{
         revoked_by: "operator",
         revoked_reason: "operator_revoked"
       }) do
    {:ok, consent} ->
      {:noreply, assign(socket, consent: consent, revoke_error: nil)}

    {:error, _reason} ->
      {:noreply, assign(socket, revoke_error: "Consent could not be revoked.")}
  end
end

def handle_event("revoke_consent", _params, socket) do
  {:noreply,
   assign(socket,
     revoke_error: "Confirm the revoke action before changing durable consent state."
   )}
end
```

**Detail layout pattern** (`consents_live/show.ex` lines 69-170):
```elixir
<AdminComponents.page_hero
  eyebrow="Support"
  title="Stored grant decision"
  body="Review whether this consent grant remains healthy and whether revocation is the next safe action."
>
  <:summary>
    <span>Status: <AdminComponents.status_badge status={@consent.grant.status} /></span>
    <span>Scopes: {scope_label(@consent.grant.scopes)}</span>
  </:summary>
  <:actions>
    <AdminComponents.admin_button href={consents_index_path()}>
      Review stored grant
    </AdminComponents.admin_button>
  </:actions>
</AdminComponents.page_hero>

<AdminComponents.entity_header
  title={@consent.client && (@consent.client.name || @consent.client.client_id) || @consent.grant.client_id}
  subtitle="Durable consent truth for support workflows. This screen does not infer from event history."
  identifier={redacted_handle(:consent_grant, @consent.grant.id)}
>
  <:status>
    <AdminComponents.status_badge status={@consent.grant.status} />
    <AdminComponents.status_badge status={@consent.grant.kind} />
  </:status>
</AdminComponents.entity_header>

<AdminComponents.confirmation_panel title="Revoke consent grant" variant={:danger}>
  <:body>
    <form class="lockspire-admin-form-stack" phx-submit="revoke_consent">
      ...
      <AdminComponents.admin_button type="submit" variant={:danger}>
        {if @consent.grant.status == :revoked,
          do: "Consent grant already revoked",
          else: "Revoke consent grant"}
      </AdminComponents.admin_button>
    </form>
  </:body>
</AdminComponents.confirmation_panel>
```

Planner note: keep the layout primitives, but insert `decision_summary` before long detail lists with exact labels `Grant status`, `Scope context`, `Client/account pivot`, `Revocation consequence`. Replace the already-revoked paragraph with locked copy and disabled/de-emphasized action semantics.

---

### `lib/lockspire/web/components/admin_components.ex` (component, transform)

**Analog:** same file; use only if existing primitives are insufficient. Phase 122 should mostly consume these components, not grow a new component surface.

**Filter + button pattern** (`admin_components.ex` lines 239-293):
```elixir
def filter_bar(assigns) do
  ~H"""
  <form method={@method} action={@action} class={["lockspire-admin-filter-bar", @class]}>
    <div class="lockspire-admin-filter-bar__fields">
      {render_slot(@fields)}
    </div>
    <div :if={@help != []} class="lockspire-admin-filter-bar__help">
      {render_slot(@help)}
    </div>
    <div :if={@actions != []} class="lockspire-admin-filter-bar__actions">
      {render_slot(@actions)}
    </div>
  </form>
  """
end

def admin_button(assigns) do
  assigns = assign(assigns, :class, button_class(assigns.variant))

  ~H"""
  <a
    :if={@href && !@disabled}
    href={@href}
    class={@class}
    {@rest}
  >
    {render_slot(@inner_block)}
  </a>
  <span
    :if={@href && @disabled}
    role="link"
    aria-disabled="true"
    class={@class}
    {@rest}
  >
    {render_slot(@inner_block)}
  </span>
  <button :if={!@href} type={@type} disabled={@disabled} class={@class} {@rest}>
    {render_slot(@inner_block)}
  </button>
  """
end
```

**Dense row + long value pattern** (`admin_components.ex` lines 438-459, 535-552):
```elixir
def dense_resource_row(assigns) do
  ~H"""
  <li class={["lockspire-admin-dense-resource-row", @class]}>
    <div class="lockspire-admin-dense-resource-row__main">
      <strong>{@title}</strong>
      <span :if={@subtitle}>{@subtitle}</span>
    </div>
    <div :if={@meta != []} class="lockspire-admin-dense-resource-row__meta">{render_slot(@meta)}</div>
    <div :if={@status != []} class="lockspire-admin-status-cluster">{render_slot(@status)}</div>
    <div :if={@actions != []} class="lockspire-admin-dense-resource-row__actions">
      {render_slot(@actions)}
    </div>
  </li>
  """
end

def long_value(assigns) do
  assigns = assign(assigns, :class_name, long_value_class(assigns.kind, assigns.class))

  ~H"""
  <span class={@class_name}>
    <%= if @redacted do %>
      <span class="lockspire-admin-redacted-value">Redacted</span>
    <% else %>
      {@value}
    <% end %>
  </span>
  """
end
```

**Error/confirmation pattern** (`admin_components.ex` lines 327-341, 585-607, 653-662):
```elixir
def error_summary(assigns) do
  ~H"""
  <section :if={@errors != []} class="lockspire-admin-error-summary" role="alert" tabindex="-1">
    <h2>{@title}</h2>
    <ul>
      <%= for error <- @errors do %>
        <li>{format_error(error)}</li>
      <% end %>
    </ul>
  </section>
  """
end

def confirmation_panel(assigns) do
  assigns = assign(assigns, :class, confirmation_panel_class(assigns.variant))

  ~H"""
  <section class={@class}>
    <header>
      <h3>{@title}</h3>
    </header>
    <div class="lockspire-admin-confirmation-panel__body">
      {render_slot(@body)}
    </div>
    <.error_list errors={@errors} />
    <div :if={@actions != []} class="lockspire-admin-confirmation-panel__actions">
      {render_slot(@actions)}
    </div>
  </section>
  """
end

def error_list(assigns) do
  ~H"""
  <ul :if={@errors != []} class="lockspire-admin-errors">
    <%= for error <- @errors do %>
      <li>{format_error(error)}</li>
    <% end %>
  </ul>
  """
end
```

---

### `lib/lockspire/web/admin_css.ex` (config / style, transform)

**Analog:** same file. Add CSS only if existing dense row, decision summary, long value, confirmation, or responsive rules do not cover the implementation.

**Dense row layout** (`admin_css.ex` lines 464-587):
```css
.lockspire-admin-pane__header,
.lockspire-admin-entity-header,
.lockspire-admin-lifecycle-row,
.lockspire-admin-dense-resource-row {
  align-items: flex-start;
  display: flex;
  gap: var(--ls-space-4);
  justify-content: space-between;
  min-width: 0;
}

.lockspire-admin-resource-list > .lockspire-admin-dense-resource-row {
  background: var(--ls-surface-muted);
  border: 1px solid var(--ls-border-subtle);
  border-radius: var(--ls-radius-md);
  padding: var(--ls-space-4);
}

.lockspire-admin-dense-resource-row__meta {
  align-items: center;
  color: var(--ls-text-muted);
  display: flex;
  flex-wrap: wrap;
  gap: var(--ls-space-3);
  min-width: 0;
}
```

**Filter/error/decision/long-value rules** (`admin_css.ex` lines 928-1015, 1158-1221, 1391-1401):
```css
.lockspire-admin-filter-bar {
  align-items: end;
  background: var(--ls-surface-panel);
  border: 1px solid var(--ls-border-subtle);
  border-radius: var(--ls-radius-lg);
  display: grid;
  gap: var(--ls-space-4);
  grid-template-columns: minmax(0, 1fr) auto;
  margin-bottom: var(--ls-space-6);
  padding: var(--ls-space-4);
}

.lockspire-admin-error-summary {
  background: var(--ls-status-danger-bg);
  border: 1px solid var(--ls-status-danger-border);
  border-radius: var(--ls-radius-md);
  color: var(--ls-status-danger-text);
  display: grid;
  gap: var(--ls-space-2);
  margin: 0 0 var(--ls-space-5);
  padding: var(--ls-space-4);
}

.lockspire-admin-decision-summary {
  display: grid;
  gap: var(--ls-space-3);
  grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
  margin: 0 0 var(--ls-space-5);
  max-width: 100%;
  min-width: 0;
}

.lockspire-admin-long-value {
  display: inline-block;
  max-width: 100%;
  min-width: 0;
  overflow-wrap: anywhere;
  word-break: break-word;
}
```

**Mobile/confirmation rules** (`admin_css.ex` lines 1553-1723):
```css
.lockspire-admin-confirmation-panel {
  background: var(--ls-surface-panel);
  border: 1px solid var(--ls-border-subtle);
  border-radius: var(--ls-radius-lg);
  box-shadow: var(--ls-shadow-sm);
  margin-top: var(--ls-space-5);
  padding: var(--ls-space-5);
}

@media (max-width: 720px) {
  .lockspire-admin-filter-bar {
    grid-template-columns: 1fr;
  }

  .lockspire-admin-filter-bar__fields,
  .lockspire-admin-filter-bar__actions,
  .lockspire-admin-action-group,
  .lockspire-admin-action-group__primary,
  .lockspire-admin-action-group__secondary,
  .lockspire-admin-action-group__destructive,
  .lockspire-admin-pane__header,
  .lockspire-admin-entity-header,
  .lockspire-admin-lifecycle-row,
  .lockspire-admin-dense-resource-row,
  .lockspire-admin-task-card__header,
  .lockspire-admin-task-card__actions {
    align-items: stretch;
    flex-direction: column;
  }

  .lockspire-admin-btn-primary,
  .lockspire-admin-btn-secondary,
  .lockspire-admin-btn-danger {
    max-width: 100%;
    min-width: 0;
    width: 100%;
  }
}
```

---

### `test/lockspire/web/live/admin/tokens_live_test.exs` (test, request-response/event-driven)

**Analog:** same file. Extend existing route render and event tests; do not add browser tooling.

**Setup pattern** (`tokens_live_test.exs` lines 1-12, 14-73):
```elixir
defmodule Lockspire.Web.Live.Admin.TokensLiveTest do
  use ExUnit.Case, async: false

  import Phoenix.LiveViewTest

  alias Lockspire.Domain.Client
  alias Lockspire.Domain.Token
  alias Lockspire.Storage.Ecto.Repository
  alias Lockspire.Web.AdminProof.HtmlAssertions
  alias Lockspire.Web.Live.Admin.TokensLive.Index
  alias Lockspire.Web.Live.Admin.TokensLive.Show
  alias Phoenix.Router

  setup_all do
    Application.put_env(:lockspire, :repo, Lockspire.TestRepo)
    Application.put_env(:lockspire, :mount_path, "/lockspire")

    start_supervised!(Lockspire.TestRepo)
    Ecto.Adapters.SQL.Sandbox.mode(Lockspire.TestRepo, :manual)

    :ok
  end
```

**Rendered HTML + redaction assertions** (`tokens_live_test.exs` lines 83-114):
```elixir
html = rendered_to_string(Index.render(socket.assigns))

assert html =~ "Support"
assert html =~ "Token investigation"
assert html =~ "Selected account: account-token-ui"
assert html =~ "Selected status: active"
assert html =~ "Filter tokens"
assert html =~ "Review token"
assert html =~ "lockspire-admin-resource-list__item"
assert html =~ "lockspire-admin-long-value"
...
refute html =~ "token-ui-refresh-hash"
refute html =~ "client_secret"
refute html =~ "verifier"
refute html =~ "user_code"
```

Planner note: update this index assertion from `lockspire-admin-resource-list__item` to `lockspire-admin-dense-resource-row`, add exact decision-summary labels, and invert selected-filter raw-value expectations where summaries must be redacted.

**Detail/event assertions** (`tokens_live_test.exs` lines 131-188):
```elixir
HtmlAssertions.assert_no_duplicate_ids(html)
HtmlAssertions.assert_describedby_targets_exist(html)
HtmlAssertions.assert_no_generic_cta_text(html)
HtmlAssertions.assert_has_link(html, "/lockspire/admin/tokens")

HtmlAssertions.assert_no_text(html, [
  "token-ui-refresh-hash",
  "family-ui-123",
  "account-token-ui"
])

assert html =~ "lockspire-admin-dense-resource-row"
assert html =~ "lockspire-admin-confirmation-panel"
assert html =~ ~s(phx-submit="revoke_token")
assert html =~ ~s(phx-submit="revoke_family")

assert {:noreply, socket} =
         Show.handle_event("revoke_token", %{"revoke" => %{"confirm" => "true"}}, socket)

assert socket.assigns.token_detail.token.revoked_at

assert {:noreply, socket} = Show.handle_event("revoke_family", %{}, socket)

assert socket.assigns.family_error =~ "Confirm the family-wide action"
```

Planner note: replace the old expected strings with exact Phase 122 errors:
`Select the confirmation checkbox to revoke this token.`,
`Select the confirmation checkbox to revoke this refresh family.`,
`This token is already revoked. No further token action is available.`,
and `This token is not part of a refresh family, so family-wide revocation is unavailable.`

---

### `test/lockspire/web/live/admin/consents_live_test.exs` (test, request-response/event-driven)

**Analog:** same file; mirror token route test style.

**Setup and index pattern** (`consents_live_test.exs` lines 1-12, 24-53, 63-99):
```elixir
defmodule Lockspire.Web.Live.Admin.ConsentsLiveTest do
  use ExUnit.Case, async: false

  import Phoenix.LiveViewTest

  alias Lockspire.Domain.Client
  alias Lockspire.Domain.ConsentGrant
  alias Lockspire.Storage.Ecto.Repository
  alias Lockspire.Web.AdminProof.HtmlAssertions
  alias Lockspire.Web.Live.Admin.ConsentsLive.Index
  alias Lockspire.Web.Live.Admin.ConsentsLive.Show
  alias Phoenix.Router

  ...

  html = rendered_to_string(Index.render(socket.assigns))

  assert html =~ "Support"
  assert html =~ "Consent grant investigation"
  assert html =~ "Selected account: account-consent-ui"
  assert html =~ "Selected client: consent-ui-client"
  assert html =~ "Selected status: active"
  assert html =~ "Filter consent grants"
  assert html =~ "Review stored grant"
  assert html =~ "lockspire-admin-resource-list__item"
  assert html =~ "lockspire-admin-long-value"
  ...
  refute html =~ "sha256:consent-ui:hash"
  refute html =~ "client_secret"
  refute html =~ "refresh_token"
  refute html =~ "user_code"
  refute html =~ "verifier"
```

**Detail/event assertions** (`consents_live_test.exs` lines 101-145):
```elixir
HtmlAssertions.assert_no_duplicate_ids(html)
HtmlAssertions.assert_describedby_targets_exist(html)
HtmlAssertions.assert_no_generic_cta_text(html)
HtmlAssertions.assert_has_link(html, "/lockspire/admin/consents")
HtmlAssertions.assert_no_text(html, ["account-consent-ui", "sha256:consent-ui:hash"])

assert html =~ "Support"
assert html =~ "Stored grant decision"
assert html =~ "Durable grant identity and current state"
assert html =~ "Scope context"
assert html =~ "Review stored grant"
assert html =~ "Revoke consent grant"
assert html =~ ~s(phx-submit="revoke_consent")
assert html =~ "future remembered-consent reuse"

assert {:noreply, socket} =
         Show.handle_event("revoke_consent", %{"revoke" => %{"confirm" => "true"}}, socket)

assert socket.assigns.consent.grant.status == :revoked

assert {:noreply, socket} = Show.handle_event("revoke_consent", %{}, socket)

assert socket.assigns.revoke_error =~ "Confirm the revoke action"
```

Planner note: add exact labels `Selected filters`, `Grant status`, `Scope context`, `Smallest safe action`, `Client/account pivot`, `Revocation consequence`; update missing-confirmation expected copy to `Select the confirmation checkbox to revoke this consent grant.`

---

### `test/lockspire/web/live/admin/design_system_contract_test.exs` (test, file-I/O/source contract, conditional)

**Analog:** same file. Touch only if implementation changes shared CSS/component/source-contract expectations.

**Existing source-contract row expectation to update if dense rows replace resource items** (`design_system_contract_test.exs` lines 974-996):
```elixir
for path <- @phase_109_support_sources do
  source = File.read!(path)

  assert source =~ "Support"
  assert source =~ "AdminComponents.long_value"
end

for path <- [
      Path.expand(
        "../../../../../lib/lockspire/web/live/admin/tokens_live/index.ex",
        __DIR__
      ),
      Path.expand(
        "../../../../../lib/lockspire/web/live/admin/consents_live/index.ex",
        __DIR__
      )
    ] do
  source = File.read!(path)

  assert source =~ "AdminComponents.filter_bar"
  assert source =~ "AdminComponents.resource_item"
end
```

Planner note: if Phase 122 converts both indexes to `dense_resource_row`, this assertion should move from `AdminComponents.resource_item` to `AdminComponents.dense_resource_row`.

**Responsive CSS/source guardrail pattern** (`design_system_contract_test.exs` lines 780-837):
```elixir
css = File.read!(@admin_css_path)
components = File.read!(@admin_components_path)

assert css_rule(
         css,
         ".lockspire-admin-pane__header,\n  .lockspire-admin-entity-header,\n  .lockspire-admin-lifecycle-row,\n  .lockspire-admin-dense-resource-row"
       ) =~ "min-width: 0"

for selector <- [
      ".lockspire-admin-status-cluster",
      ".lockspire-admin-dense-resource-row__meta",
      ".lockspire-admin-action-group",
      ".lockspire-admin-action-group__destructive"
    ] do
  assert declaration_block(css, selector) =~ "flex-wrap: wrap"
end

mobile_css = css_media_rule(css, "@media (max-width: 720px)")

assert css_rule(
         mobile_css,
         ".lockspire-admin-filter-bar__fields,\n    .lockspire-admin-filter-bar__actions,\n    .lockspire-admin-action-group,\n    .lockspire-admin-action-group__primary,\n    .lockspire-admin-action-group__secondary,\n    .lockspire-admin-action-group__destructive,\n    .lockspire-admin-pane__header,\n    .lockspire-admin-entity-header,\n    .lockspire-admin-lifecycle-row,\n    .lockspire-admin-dense-resource-row,\n    .lockspire-admin-task-card__header,\n    .lockspire-admin-task-card__actions"
       ) =~ "flex-direction: column"

assert components =~ ~s(role="link")
assert components =~ ~s(aria-disabled="true")
```

**Secret-evidence guard pattern** (`design_system_contract_test.exs` lines 1801-1828):
```elixir
defp assert_no_phase_121_secret_evidence(source) do
  for forbidden <- [
        "real-client-secret",
        "production-secret",
        "prod-access-token",
        "prod-refresh-token",
        "customer.example.com",
        "tenant.example.com",
        "sk_live_",
        "pk_live_",
        "eyJhbGci",
        "BEGIN PRIVATE KEY",
        "BEGIN RSA PRIVATE KEY"
      ] do
    refute source =~ forbidden
  end

  refute Regex.match?(~r/\beyJ[a-zA-Z0-9_-]{20,}\.[a-zA-Z0-9_-]{20,}/, source)

  for pattern <- [
        ~r/\bauthorization:\s*bearer\s+[a-z0-9._~+\/=-]{20,}/i,
        ~r/(?:^|[?&\s])(?:client_secret|access_token|refresh_token|id_token|device_code|user_code)=["']?[a-z0-9._~+\/=-]{8,}/i,
        ~r/"(?:client_secret|access_token|refresh_token|id_token|device_code|user_code)"\s*:\s*"[^"]{8,}"/i,
        ~r/-----BEGIN (?:RSA |EC )?PRIVATE KEY-----/
      ] do
    refute Regex.match?(pattern, source)
  end
end
```

---

### `test/lockspire/web/live/admin/design_system_component_stress_test.exs` (test, component render/transform, conditional)

**Analog:** same file plus `test/support/lockspire/web/admin_lab/stress_surface.ex`. Use only if shared component/CSS behavior changes.

**Stress render/assertion pattern** (`design_system_component_stress_test.exs` lines 62-193):
```elixir
html = render_component(&StressSurface.render/1, fixture_set: Fixtures.all())

HtmlAssertions.assert_no_duplicate_ids(html)
HtmlAssertions.assert_describedby_targets_exist(html)
HtmlAssertions.assert_label_targets_exist(html)

HtmlAssertions.assert_no_text(html, [
  "Click here",
  "Learn more",
  "Read more",
  "Submit"
])

HtmlAssertions.assert_no_text(html, Fixtures.forbidden_substrings())

for class <- [
      "lockspire-admin-page-hero",
      "lockspire-admin-decision-summary",
      "lockspire-admin-dense-resource-row",
      "lockspire-admin-long-value",
      "lockspire-admin-error-summary",
      "lockspire-admin-confirmation-panel-danger",
      "lockspire-admin-action-group",
      "lockspire-admin-empty"
    ] do
  assert html =~ class
end

for marker <- [
      ~s(role="link" aria-disabled="true"),
      ~s(id="stress-redirect-uri-help"),
      ~s(id="stress-redirect-uri-error"),
      ~s(aria-invalid="true"),
      ~s(aria-describedby="stress-redirect-uri-help stress-redirect-uri-error")
    ] do
  assert html =~ marker
end
```

**Stress surface component pattern** (`stress_surface.ex` lines 93-115, 155-170, 208-276):
```elixir
<AdminComponents.decision_summary>
  <:item
    label="Registration gate"
    value="IAT-gated"
    tone={:success}
    detail="Partners need a valid intake token before self-registration metadata is accepted."
  >
  </:item>
</AdminComponents.decision_summary>

<ul class="lockspire-admin-resource-list">
  <AdminComponents.dense_resource_row
    :for={row <- @structural_rows}
    title={row.title}
    subtitle={row.subtitle}
  >
    <:meta>
      <AdminComponents.long_value kind={:id} value={row.identifier} />
    </:meta>
    <:status>
      <AdminComponents.status_badge status={row.state} domain={:operate} />
    </:status>
    <:actions>
      <AdminComponents.admin_button>Inspect row</AdminComponents.admin_button>
    </:actions>
  </AdminComponents.dense_resource_row>
</ul>

<AdminComponents.error_summary
  errors={[
    "Redirect URI must match a registered exact URI.",
    %{field: :client_name, reason: :too_long, detail: [count: 160]}
  ]}
/>

<AdminComponents.confirmation_panel
  title="Revoke token family"
  variant={:danger}
  errors={["Type the client ID before revoking this family."]}
>
  <:body>
    Revoking this family invalidates all active refresh tokens for the selected client and account.
  </:body>
  <:actions>
    <AdminComponents.action_group>
      <:destructive>
        <AdminComponents.admin_button variant={:danger}>Revoke token family</AdminComponents.admin_button>
      </:destructive>
    </AdminComponents.action_group>
  </:actions>
</AdminComponents.confirmation_panel>
```

## Shared Patterns

### Host-Guarded Admin Boundary

**Source:** `lib/lockspire/web/admin_router.ex` lines 1-21  
**Apply to:** all four Support LiveViews.

```elixir
defmodule Lockspire.Web.AdminRouter do
  @moduledoc """
  Mountable Phoenix router exposing only Lockspire operator/admin LiveViews.

  Host applications should mount this router behind their own operator
  authentication pipeline before the general `Lockspire.Web.Router` forward.
  """

  use Phoenix.Router

  import Phoenix.LiveView.Router

  scope "/" do
    live("/", Lockspire.Web.Live.Admin.OverviewLive.Index, :index)
    live("/overview", Lockspire.Web.Live.Admin.OverviewLive.Index, :index)
    live("/clients", Lockspire.Web.Live.Admin.ClientsLive.Index, :index)
    live("/clients/:client_id", Lockspire.Web.Live.Admin.ClientsLive.Show, :show)
    live("/consents", Lockspire.Web.Live.Admin.ConsentsLive.Index, :index)
    live("/consents/:id", Lockspire.Web.Live.Admin.ConsentsLive.Show, :show)
    live("/tokens", Lockspire.Web.Live.Admin.TokensLive.Index, :index)
    live("/tokens/:id", Lockspire.Web.Live.Admin.TokensLive.Show, :show)
```

Do not add operator auth, staff roles, MFA, IP policy, or staff session logic inside Phase 122 LiveViews.

### Admin API Boundary

**Source:** `lib/lockspire/admin.ex` lines 121-175  
**Apply to:** all token/consent reads and revocations.

```elixir
@spec list_consents(keyword()) ::
        {:ok, [Lockspire.Admin.Consents.consent_view()]} | {:error, term()}
defdelegate list_consents(opts \\ []), to: Consents

@spec get_consent(integer()) ::
        {:ok, Lockspire.Admin.Consents.consent_view() | nil} | {:error, term()}
defdelegate get_consent(grant_id), to: Consents

@spec revoke_consent(integer(), map()) ::
        {:ok, Lockspire.Admin.Consents.consent_view()} | {:error, term()}
defdelegate revoke_consent(grant_id, attrs \\ %{}), to: Consents

@spec list_tokens(keyword()) :: {:ok, [Lockspire.Admin.Tokens.token_view()]} | {:error, term()}
defdelegate list_tokens(opts \\ []), to: Tokens

@spec get_token(integer()) ::
        {:ok, Lockspire.Admin.Tokens.token_detail() | nil} | {:error, term()}
defdelegate get_token(token_id), to: Tokens

@spec revoke_token(integer(), map()) ::
        {:ok, Lockspire.Admin.Tokens.token_detail()} | {:error, term()}
defdelegate revoke_token(token_id, attrs \\ %{}), to: Tokens

@spec revoke_token_family(integer(), map()) ::
        {:ok, %{count: non_neg_integer(), token: Lockspire.Admin.Tokens.token_detail()}}
        | {:error, term()}
defdelegate revoke_token_family(token_id, attrs \\ %{}), to: Tokens
```

### Redaction and Long Values

**Sources:** `lib/lockspire/admin/tokens.ex` lines 151-167, `admin_components.ex` lines 535-552, `admin_css.ex` lines 1391-1401  
**Apply to:** account, client, token, family, consent grant, scope, timestamp, and URL-like values.

```elixir
defp token_detail_view(%Token{} = token, client) do
  %{
    id: token.id,
    handle: token_handle(token),
    client_display: client_display(client, token.client_id),
    client_handle: Redaction.handle(:client, token.client_id),
    account_handle: optional_handle(:account, token.account_id),
    token_type: token.token_type,
    generation: token.generation,
    expires_at: token.expires_at,
    revoked_at: token.revoked_at,
    reuse_detected_at: token.reuse_detected_at,
    family_id: token.family_id,
    family_handle: optional_handle(:family, token.family_id),
    parent_handle: parent_handle(token.parent_token_id),
    scopes: token.scopes
  }
end
```

### Accessible Errors

**Sources:** `admin_components.ex` lines 327-341, 585-607, 653-662; `clients_live/show.ex` lines 557-588  
**Apply to:** missing checkbox, backend failure, and validation/mutation errors.

Use `confirmation_panel errors={...}`, `error_summary`, or `error_list`. Avoid plain `<p :if={@revoke_error}>` for Phase 122 destructive-action errors.

### Source and Redaction Tests

**Sources:** `test/support/lockspire/web/admin_proof/html_assertions.ex` lines 153-184; `design_system_contract_test.exs` lines 1801-1828  
**Apply to:** all touched Support LiveView tests and any design contract updates.

```elixir
def assert_no_generic_cta_text(html) do
  assert_no_text(html, @generic_cta_text)
end

def assert_no_text(html, denied_values) when is_list(denied_values) do
  source = html_source(html)

  for denied <- denied_values, is_binary(denied), denied != "" do
    refute source =~ denied, "expected rendered HTML to omit denied text #{inspect(denied)}"
  end

  html
end
```

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| planner-selected internal support summary/helper module, if extracted | utility | transform | No existing dedicated support-investigation helper exists. Prefer private LiveView helpers first; extract only if duplicated summary/closed-state predicates would otherwise spread security-sensitive decisions through templates. |

## Metadata

**Analog search scope:** `lib/lockspire/web/live/admin`, `lib/lockspire/web/components`, `lib/lockspire/web`, `lib/lockspire/admin*.ex`, `test/lockspire/web/live/admin`, `test/support/lockspire/web`  
**Files scanned:** 81 unique web/admin/test files, plus `lib/lockspire/admin.ex`, `lib/lockspire/admin/tokens.ex`, and `lib/lockspire/admin/consents.ex`  
**Pattern extraction date:** 2026-06-28
