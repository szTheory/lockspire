# Phase 109: Weak-Spot Page Polish - Pattern Map

**Mapped:** 2026-06-04
**Files analyzed:** 28
**Analogs found:** 28 / 28

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/lockspire/web/components/admin_components.ex` | component | transform | `lib/lockspire/web/components/admin_components.ex` | exact |
| `lib/lockspire/web/admin_css.ex` | config | transform | `lib/lockspire/web/admin_css.ex` | exact |
| `lib/lockspire/web/live/admin/tokens_live/index.ex` | component | request-response | `lib/lockspire/web/live/admin/clients_live/index.ex` | role-match |
| `lib/lockspire/web/live/admin/tokens_live/show.ex` | component | event-driven | `lib/lockspire/web/live/admin/tokens_live/show.ex` | exact |
| `lib/lockspire/web/live/admin/consents_live/index.ex` | component | request-response | `lib/lockspire/web/live/admin/tokens_live/index.ex` | exact |
| `lib/lockspire/web/live/admin/consents_live/show.ex` | component | event-driven | `lib/lockspire/web/live/admin/consents_live/show.ex` | exact |
| `lib/lockspire/web/live/admin/logout_deliveries_live/index.ex` | component | request-response | `lib/lockspire/web/live/admin/overview_live/index.ex` | role-match |
| `lib/lockspire/web/live/admin/device_authorizations_live/index.ex` | component | request-response | `lib/lockspire/web/live/admin/overview_live/index.ex` | role-match |
| `lib/lockspire/web/live/admin/interactions_live/index.ex` | component | request-response | `lib/lockspire/web/live/admin/overview_live/index.ex` | role-match |
| `lib/lockspire/web/live/admin/dcr_live/index.ex` | component | request-response | `lib/lockspire/web/live/admin/dcr_live/index.ex` | exact |
| `lib/lockspire/web/live/admin/iat_live/index.ex` | component | event-driven | `lib/lockspire/web/live/admin/iat_live/index.ex` | exact |
| `lib/lockspire/web/live/admin/iat_live/index.html.heex` | component | event-driven | `lib/lockspire/web/live/admin/iat_live/index.html.heex` | exact |
| `lib/lockspire/web/live/admin/iat_live/new.ex` | component | event-driven | `lib/lockspire/web/live/admin/iat_live/new.ex` | exact |
| `lib/lockspire/web/live/admin/iat_live/new.html.heex` | component | event-driven | `lib/lockspire/web/live/admin/clients_live/rotate_secret_component.ex` | role-match |
| `lib/lockspire/web/live/admin/keys_live/index.ex` | component | event-driven | `lib/lockspire/web/live/admin/dcr_live/index.ex` | role-match |
| `lib/lockspire/web/live/admin/keys_live/show.ex` | component | event-driven | `lib/lockspire/web/live/admin/keys_live/show.ex` | exact |
| `lib/lockspire/web/live/admin/clients_live/show.ex` | component | event-driven | `lib/lockspire/web/live/admin/clients_live/show.ex` | exact |
| `test/lockspire/web/live/admin/design_system_contract_test.exs` | test | transform | `test/lockspire/web/live/admin/design_system_contract_test.exs` | exact |
| `test/lockspire/web/live/admin/tokens_live_test.exs` | test | event-driven | `test/lockspire/web/live/admin/tokens_live_test.exs` | exact |
| `test/lockspire/web/live/admin/consents_live_test.exs` | test | event-driven | `test/lockspire/web/live/admin/consents_live_test.exs` | exact |
| `test/lockspire/web/live/admin/logout_deliveries_live_test.exs` | test | request-response | `test/lockspire/web/live/admin/logout_deliveries_live_test.exs` | exact |
| `test/lockspire/web/live/admin/device_authorizations_live_test.exs` | test | request-response | `test/lockspire/web/live/admin/device_authorizations_live_test.exs` | exact |
| `test/lockspire/web/live/admin/interactions_live_test.exs` | test | request-response | `test/lockspire/web/live/admin/interactions_live_test.exs` | exact |
| `test/lockspire/web/live/admin/iat_live_test.exs` | test | event-driven | `test/lockspire/web/live/admin/iat_live_test.exs` | exact |
| `test/lockspire/web/live/admin/keys_live_test.exs` | test | event-driven | `test/lockspire/web/live/admin/keys_live_test.exs` | exact |
| `test/lockspire/web/live/admin/clients_live/show_test.exs` | test | event-driven | `test/lockspire/web/live/admin/clients_live/show_test.exs` | exact |

## Pattern Assignments

### `lib/lockspire/web/components/admin_components.ex` (component, transform)

**Analog:** `lib/lockspire/web/components/admin_components.ex`

**Imports pattern** (lines 1-4):
```elixir
defmodule Lockspire.Web.Components.AdminComponents do
  @moduledoc false

  use Phoenix.Component
```

**Component API pattern** (lines 35-57, 210-244):
```elixir
attr(:eyebrow, :string, required: true)
attr(:title, :string, required: true)
attr(:body, :string, default: nil)
attr(:class, :string, default: "")
slot(:summary)
slot(:actions)

def page_hero(assigns) do
  ~H"""
  <section class={["lockspire-admin-hero lockspire-admin-page-hero", @class]}>
    <div class="lockspire-admin-page-hero__main">
      <p class="lockspire-admin-eyebrow">{@eyebrow}</p>
      <h2>{@title}</h2>
      <p :if={@body}>{@body}</p>
      <div :if={@summary != []} class="lockspire-admin-page-hero__summary">
        {render_slot(@summary)}
      </div>
    </div>
    <div :if={@actions != []} class="lockspire-admin-page-hero__actions">
      {render_slot(@actions)}
    </div>
  </section>
  """
end
```

```elixir
slot(:inner_block, required: true)

def resource_list(assigns) do
  ~H"""
  <ul class="lockspire-admin-resource-list">
    {render_slot(@inner_block)}
  </ul>
  """
end

attr(:href, :string, default: nil)
attr(:title, :string, required: true)
attr(:subtitle, :string, default: nil)
attr(:class, :string, default: "")
slot(:meta)
slot(:status)
slot(:actions)
```

**Long value / action / confirmation pattern** (lines 247-339):
```elixir
def copy_once_secret_panel(assigns) do
  ~H"""
  <section class={["lockspire-admin-secret-reveal lockspire-admin-copy-once-secret", @class]}>
    <h3>{@title}</h3>
    <p :if={@body}>{@body}</p>
    <div class="lockspire-admin-copy-once-secret__value">
      <span class="lockspire-admin-copy-once-secret__label">{@label}</span>
      <code :if={@value && !@redacted}>{@value}</code>
      <span :if={!@value || @redacted} class="lockspire-admin-redacted-value">Redacted</span>
    </div>
  </section>
  """
end
```

```elixir
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

```elixir
def action_group(assigns) do
  ~H"""
  <div class={["lockspire-admin-action-group", @class]}>
    <div :if={@primary != []} class="lockspire-admin-action-group__primary">
      {render_slot(@primary)}
    </div>
    <div :if={@secondary != []} class="lockspire-admin-action-group__secondary">
      {render_slot(@secondary)}
    </div>
    <div :if={@destructive != []} class="lockspire-admin-action-group__destructive">
      {render_slot(@destructive)}
    </div>
  </div>
  """
end
```

### `lib/lockspire/web/admin_css.ex` (config, transform)

**Analog:** `lib/lockspire/web/admin_css.ex`

**Responsive primitive pattern** (lines 618-655, 969-979, 1152-1235):
```elixir
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
```

```elixir
.lockspire-admin-long-value {
  display: inline-block;
  max-width: 100%;
  min-width: 0;
  overflow-wrap: anywhere;
  word-break: break-word;
}
```

```elixir
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
  .lockspire-admin-task-card__header,
  .lockspire-admin-task-card__actions {
    align-items: stretch;
    flex-direction: column;
  }

  .lockspire-admin-resource-list a,
  .lockspire-admin-resource-list__item,
  .lockspire-admin-client-list li,
  .lockspire-admin-key-list li,
  .lockspire-admin-token-list li,
  .lockspire-admin-consent-list li,
  .lockspire-admin-list li {
    align-items: flex-start;
    flex-direction: column;
  }
}
```

### Support Indexes: `tokens_live/index.ex`, `consents_live/index.ex`

**Analogs:** `lib/lockspire/web/live/admin/clients_live/index.ex`, `lib/lockspire/web/live/admin/tokens_live/index.ex`, `lib/lockspire/web/live/admin/consents_live/index.ex`

**Imports and URL state pattern** (clients index lines 4-9, tokens index lines 23-32):
```elixir
use Phoenix.LiveView

alias Lockspire.Admin
alias Lockspire.Web.Components.AdminComponents
alias Lockspire.Web.Live.AdminLayoutLive
```

```elixir
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

**Filter bar pattern** (tokens index lines 43-74):
```elixir
<AdminComponents.filter_bar action={tokens_index_path()}>
  <:fields>
    <div class="lockspire-admin-field">
      <label for="token_account">Account</label>
      <input id="token_account" name="account" type="text" value={@filters["account"]} />
    </div>

    <div class="lockspire-admin-field">
      <label for="token_status">Status</label>
      <select id="token_status" name="status">
        <option value="all" selected={@filters["status"] == "all"}>All</option>
        <option value="active" selected={@filters["status"] == "active"}>Active</option>
        <option value="revoked" selected={@filters["status"] == "revoked"}>Revoked</option>
      </select>
    </div>
  </:fields>
  <:help>
    <p>Total matching tokens: {@total_tokens}</p>
  </:help>
  <:actions>
    <AdminComponents.admin_button type="submit">Apply</AdminComponents.admin_button>
  </:actions>
</AdminComponents.filter_bar>
```

**Resource row pattern to copy from clients index** (lines 114-127):
```elixir
<AdminComponents.resource_list>
  <%= for client <- @clients do %>
    <AdminComponents.resource_item
      href={client_show_path(client.client_id)}
      title={client.name || client.client_id}
      subtitle={client.client_id}
    >
      <:meta>
        <AdminComponents.status_badge status={status_for(client)} />
        <AdminComponents.status_badge status={client.provenance} />
      </:meta>
    </AdminComponents.resource_item>
  <% end %>
</AdminComponents.resource_list>
```

**Filter normalization pattern** (tokens index lines 100-135, consents index lines 97-127):
```elixir
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

### Support Details: `tokens_live/show.ex`, `consents_live/show.ex`

**Analogs:** `lib/lockspire/web/live/admin/tokens_live/show.ex`, `lib/lockspire/web/live/admin/consents_live/show.ex`

**Event guard and error pattern** (tokens show lines 35-83, consents show lines 33-51):
```elixir
def handle_event("revoke_token", %{"revoke" => %{"confirm" => "true"}}, socket) do
  case Admin.revoke_token(socket.assigns.token_id, %{revoked_by: "operator"}) do
    {:ok, detail} ->
      {:noreply, assign(socket, token_detail: detail, revoke_error: nil)}

    {:error, _reason} ->
      {:noreply, assign(socket, revoke_error: "Token could not be revoked.")}
  end
end

def handle_event("revoke_token", _params, socket) do
  {:noreply,
   assign(socket,
     revoke_error: "Confirm the single-token action before changing lifecycle state.",
     family_notice: nil
   )}
end
```

**Detail and redaction pattern** (tokens show lines 100-130):
```elixir
<AdminComponents.description_list>
  <:item label="Client"><code>{@token_detail.token.client_display}</code></:item>
  <:item label="Client handle"><code>{@token_detail.token.client_handle}</code></:item>
  <:item label="Account">
    <code>{@token_detail.token.account_handle || "Not recorded"}</code>
  </:item>
  <:item label="Status"><AdminComponents.status_badge status={@token_detail.status} /></:item>
  <:item label="Expires at">
    <AdminComponents.timestamp value={@token_detail.token.expires_at} />
  </:item>
  <:item label="Family"><code>{@token_detail.token.family_handle || "Not recorded"}</code></:item>
  <:item label="Scopes">{Enum.join(@token_detail.token.scopes, ", ")}</:item>
</AdminComponents.description_list>
```

**Confirmation pattern** (consents show lines 104-120):
```elixir
<AdminComponents.confirmation_panel title="Revoke stored grant" variant={:danger}>
  <:body>
    <form class="lockspire-admin-form-stack" phx-submit="revoke_consent">
      <label class="lockspire-admin-checkbox-field">
        <input type="checkbox" name="revoke[confirm]" value="true" />
        <span>I understand this revokes the stored grant for this account and client.</span>
      </label>
      <AdminComponents.action_bar>
        <AdminComponents.admin_button type="submit" variant={:danger}>
          {if @consent.grant.status == :revoked,
            do: "Consent already revoked",
            else: "Revoke consent"}
        </AdminComponents.admin_button>
      </AdminComponents.action_bar>
    </form>
  </:body>
</AdminComponents.confirmation_panel>
```

### Operations Queues: `logout_deliveries_live/index.ex`, `device_authorizations_live/index.ex`, `interactions_live/index.ex`

**Analogs:** `lib/lockspire/web/live/admin/overview_live/index.ex`, `lib/lockspire/web/live/admin/dcr_live/index.ex`, existing operation pages

**Imports and load pattern** (logout lines 4-8, device lines 4-8, interactions lines 4-8):
```elixir
use Phoenix.LiveView

alias Lockspire.Storage.Ecto.Repository
alias Lockspire.Web.Components.AdminComponents
alias Lockspire.Web.Live.AdminLayoutLive
```

```elixir
use Phoenix.LiveView

alias Lockspire.Admin
alias Lockspire.Web.Components.AdminComponents
alias Lockspire.Web.Live.AdminLayoutLive
```

**Metric summary pattern** (overview lines 43-54, DCR lines 43-53):
```elixir
<AdminComponents.metric_grid wide>
  <AdminComponents.summary_stat value={@summary.clients.total} label="clients" />
  <AdminComponents.summary_stat
    value={@summary.tokens.reuse_detected}
    label="reuse incidents"
  />
  <AdminComponents.summary_stat value={@summary.logouts.failed} label="logout failures" />
</AdminComponents.metric_grid>
```

**Derived bucket helper pattern** (overview lines 153-193):
```elixir
defp load_summary do
  clients = ok_list(Admin.list_clients())
  tokens = ok_list(Admin.list_tokens())
  consents = ok_list(Admin.list_consents())
  logouts = ok_list(Repository.list_all_logout_deliveries())

  %{
    tokens: %{
      active: Enum.count(tokens, &(&1.status == :active)),
      reuse_detected: Enum.count(tokens, &(&1.status == :reuse_detected))
    },
    consents: %{active: Enum.count(consents, &(&1.grant.status == :active))},
    logouts: %{failed: Enum.count(logouts, &(&1.status in [:retryable, :discarded]))}
  }
end

defp ok_list({:ok, list}) when is_list(list), do: list
defp ok_list(_result), do: []
```

**Current raw-table replacement target** (logout lines 41-66, interactions lines 41-62):
```elixir
<div class="lockspire-admin-table-wrap">
  <table class="lockspire-admin-table">
    <thead>
      <tr>
        <th>Delivery ID</th>
        <th>Client</th>
        <th>Channel</th>
        <th>Status</th>
        <th>Attempts</th>
        <th>Created</th>
      </tr>
    </thead>
    <tbody>
      <%= for delivery <- @deliveries do %>
        <tr>
          <td>{delivery.delivery_id}</td>
          <td>{delivery.client_id}</td>
          <td>{delivery.channel}</td>
          <td><AdminComponents.status_badge status={delivery.status} /></td>
          <td>{delivery.attempt_count}</td>
          <td>{delivery.inserted_at}</td>
        </tr>
      <% end %>
    </tbody>
  </table>
</div>
```

Replace primary scanning UI with `metric_grid` plus `resource_list/resource_item`; use `long_value kind={:id | :url | :timestamp}` for `delivery_id`, `target_uri`, `interaction_id`, timestamps, and device verification handles. Do not add retry/discard controls unless backed by existing APIs.

### Configure Pages: `dcr_live/index.ex`, IAT, Keys, Client Detail

**Analogs:** `lib/lockspire/web/live/admin/dcr_live/index.ex`, `lib/lockspire/web/live/admin/iat_live/index.html.heex`, `lib/lockspire/web/live/admin/clients_live/rotate_secret_component.ex`, `lib/lockspire/web/live/admin/keys_live/action_component.ex`, `lib/lockspire/web/live/admin/clients_live/show.ex`

**DCR page hero / summary pattern** (DCR lines 31-53):
```elixir
<AdminComponents.page_hero
  eyebrow="Partner onboarding"
  title="Dynamic registration policy, Initial Access Tokens, and self-registered clients."
  body="DCR is an onboarding journey: decide who may register, mint short-lived intake tokens, review what appeared, and rotate registration access tokens when needed."
>
  <:actions>
    <AdminComponents.admin_button href={admin_path("/iats/new")} variant={:primary}>
      Mint IAT
    </AdminComponents.admin_button>
  </:actions>
</AdminComponents.page_hero>

<AdminComponents.metric_grid>
  <AdminComponents.summary_stat value={@policy.registration_policy} label="registration mode" />
  <AdminComponents.summary_stat value={@summary.iats.active} label="active IATs" />
  <AdminComponents.summary_stat value={@summary.clients.self_registered} label="self-registered clients" />
</AdminComponents.metric_grid>
```

**IAT row and event pattern** (IAT index lines 19-30, index template lines 18-44):
```elixir
def handle_event("revoke", %{"id" => id}, socket) do
  case InitialAccessTokens.revoke_iat(String.to_integer(id)) do
    :ok ->
      {:noreply,
       socket
       |> put_flash(:info, "IAT revoked successfully.")
       |> assign(tokens: load_tokens())}

    {:error, _reason} ->
      {:noreply, put_flash(socket, :error, "Failed to revoke IAT.")}
  end
end
```

```elixir
<Lockspire.Web.Components.AdminComponents.resource_item
  title={"IAT ##{token.id}"}
  subtitle={"Created by #{token.created_by || "operator"}"}
>
  <:meta>
    <Lockspire.Web.Components.AdminComponents.status_badge status={iat_status(token)} />
    <span class="lockspire-admin-help">
      {if token.single_use, do: "Single use", else: "Multi-use"}
    </span>
  </:meta>
  <:actions>
    <%= if iat_status(token) == :active do %>
      <Lockspire.Web.Components.AdminComponents.admin_button
        phx-click="revoke"
        phx-value-id={token.id}
        data-confirm="Are you sure you want to revoke this IAT?"
        variant={:danger}
      >
        Revoke
      </Lockspire.Web.Components.AdminComponents.admin_button>
    <% end %>
  </:actions>
</Lockspire.Web.Components.AdminComponents.resource_item>
```

**Copy-once secret pattern for IAT new** (rotate secret component lines 21-27, IAT new lines 27-36):
```elixir
<AdminComponents.copy_once_secret_panel
  :if={@revealed_secret}
  title="New client secret"
  body="Copy it now. Lockspire does not store or re-show plaintext secrets."
  label="Client secret"
  value={@revealed_secret}
/>
```

```elixir
case InitialAccessTokens.mint_iat(attrs) do
  {:ok, _iat, plaintext_secret} ->
    {:noreply,
     socket
     |> put_flash(:info, "IAT minted successfully.")
     |> assign(iat_secret: plaintext_secret)}

  {:error, _reason} ->
    {:noreply, put_flash(socket, :error, "Failed to mint IAT.")}
end
```

**Key lifecycle action pattern** (key show lines 35-123, key action component lines 22-78):
```elixir
def handle_event("activate_key", %{"activate" => %{"confirm" => "true"}}, socket) do
  case Admin.activate_key(socket.assigns.key_id) do
    {:ok, key_detail} ->
      {:noreply,
       socket
       |> assign(
         key_detail: key_detail,
         action_notice: "Key activated. The prior signer is now retiring.",
         action_error: nil
       )
       |> load_key(socket.assigns.key_id)}

    {:error, :not_published} ->
      {:noreply,
       assign(socket, action_error: "Publish the upcoming key before cutover activation.")}
  end
end
```

```elixir
<AdminComponents.confirmation_panel
  :if={:retire in @key_detail.next_actions}
  title="Retire key"
  variant={:danger}
>
  <:body>
    <form class="lockspire-admin-form-stack" phx-submit="retire_key">
      <label class="lockspire-admin-checkbox-field">
        <input type="checkbox" name="retire[confirm]" value="true" />
        <span>Retire this overlap key after verifiers have moved off it.</span>
      </label>
      <AdminComponents.action_bar>
        <AdminComponents.admin_button type="submit" variant={:danger}>
          Retire key
        </AdminComponents.admin_button>
      </AdminComponents.action_bar>
    </form>
  </:body>
</AdminComponents.confirmation_panel>
```

**Client detail action grouping target** (client show lines 380-397, 415-467):
```elixir
<AdminComponents.action_bar>
  <.link class="lockspire-admin-btn lockspire-admin-btn-secondary" patch={show_path(@client.client_id, :edit)}>Edit metadata</.link>
  <.link class="lockspire-admin-btn lockspire-admin-btn-secondary" patch={show_path(@client.client_id, :logout_propagation)}>
    Edit logout propagation
  </.link>
  <.link class="lockspire-admin-btn lockspire-admin-btn-secondary" patch={show_path(@client.client_id, :security_profile)}>Edit security profile</.link>
  <.link class="lockspire-admin-btn lockspire-admin-btn-secondary" patch={show_path(@client.client_id, :par_policy)}>Edit PAR policy</.link>
  <.link class="lockspire-admin-btn lockspire-admin-btn-secondary" patch={show_path(@client.client_id, :redirects)}>Edit redirect URIs</.link>
  <.link class="lockspire-admin-btn lockspire-admin-btn-secondary" :if={@client.client_type == :confidential} patch={show_path(@client.client_id, :rotate_secret)}>
    Rotate secret
  </.link>
  <button class="lockspire-admin-btn lockspire-admin-btn-danger" phx-click="toggle_client" type="button">
    {if @client.active, do: "Disable client", else: "Enable client"}
  </button>
</AdminComponents.action_bar>
```

Replace this flat `action_bar` with multiple `AdminComponents.action_group` sections. Keep event handlers, `show_path/2`, and copy-once RAT/secret flows unchanged.

## Shared Patterns

### Authentication / Host Boundary

**Source:** `AGENTS.md`
**Apply to:** All admin LiveViews

No Lockspire-owned staff auth, roles, tenant policy, host layout, or branding should be added. Admin LiveViews stay embedded Phoenix surfaces mounted inside a host app.

### Page Shell and Imports

**Source:** `lib/lockspire/web/live/admin/overview_live/index.ex` lines 4-10, 30-41
**Apply to:** All LiveView modules
```elixir
use Phoenix.LiveView

alias Lockspire.Admin
alias Lockspire.Web.Components.AdminComponents
alias Lockspire.Web.Live.AdminLayoutLive
```

```elixir
<AdminLayoutLive.shell current_section={@current_section} page_title={@page_title}>
  <AdminComponents.page_hero
    eyebrow="Operator cockpit"
    title="Run the embedded provider with the important state in view."
    body="Start with client posture, issuer security, token incidents, key readiness, and live protocol work. Each card points to the workflow that owns the next action."
  >
    <:actions>
      <AdminComponents.admin_button href={admin_path("/clients")} variant={:primary}>
        Review clients
      </AdminComponents.admin_button>
    </:actions>
  </AdminComponents.page_hero>
</AdminLayoutLive.shell>
```

### Error Handling

**Source:** existing LiveViews
**Apply to:** Mutating LiveViews
```elixir
case Admin.revoke_consent(socket.assigns.consent_id, %{
       revoked_by: "operator",
       revoked_reason: "operator_revoked"
     }) do
  {:ok, consent} ->
    {:noreply, assign(socket, consent: consent, revoke_error: nil)}

  {:error, _reason} ->
    {:noreply, assign(socket, revoke_error: "Consent could not be revoked.")}
end
```

Use explicit confirmation guard clauses for missing checkbox state. Do not silently mutate on unconfirmed events.

### Redaction

**Source:** `lib/lockspire/web/live/admin/clients_live/show.ex` lines 219-230 and test assertions in `tokens_live_test.exs` lines 127-133
**Apply to:** Tokens, consents, IAT, keys, clients
```elixir
<AdminComponents.description_list>
  <:item label="Current secret">
    <span class="lockspire-admin-redacted-value">redacted</span>
  </:item>
  <:item label="Last secret rotation">
    <span class="lockspire-admin-tabular">
      {format_datetime(@client.last_secret_rotated_at)}
    </span>
  </:item>
</AdminComponents.description_list>
```

```elixir
refute html =~ "token-ui-refresh-hash"
refute html =~ "family-ui-123"
refute html =~ "account-token-ui"
refute html =~ "Token ##{refresh_token.id}"
```

### Test Structure

**Source:** `test/lockspire/web/live/admin/design_system_contract_test.exs` lines 203-247 and 358-365
**Apply to:** Contract tests for Phase 109 target files
```elixir
for path <- page_hero_sources do
  source = File.read!(path)

  assert source =~ "AdminComponents.page_hero"
  refute source =~ ~s(class="lockspire-admin-hero")
end

for path <- Path.wildcard(@admin_live_glob) do
  refute File.read!(path) =~ ~r/\sstyle=/
end
```

```elixir
for path <- Path.wildcard(@admin_live_glob) do
  content = File.read!(path)

  refute content =~ ~r/\sstyle=/
  refute Regex.match?(~r/class="lockspire-admin-btn-(primary|secondary|danger)"/, content)
  refute Regex.match?(~r/<button(?![^>]*lockspire-admin-btn)/, content)
end
```

**Source:** focused LiveView tests such as `test/lockspire/web/live/admin/iat_live_test.exs` lines 65-88
**Apply to:** Copy-once and mutation proof
```elixir
html_after_mint =
  view
  |> element("form")
  |> render_submit(%{"single_use" => "true", "expires_in_days" => "30"})

assert html_after_mint =~ "Secret revealed"
assert html_after_mint =~ "I have copied this secret"

html_after_ack =
  view
  |> element("button[phx-click=\"acknowledge_copy\"]")
  |> render_click()

refute html_after_ack =~ "Secret revealed"
refute html_after_ack =~ "I have copied this secret"
```

## No Analog Found

No files lack a close codebase analog. Planner should not introduce new protocol/storage abstractions for this phase.

## Metadata

**Analog search scope:** `lib/lockspire/web/live/admin`, `lib/lockspire/web/components`, `lib/lockspire/web/admin_css.ex`, `test/lockspire/web/live/admin`
**Files scanned:** 40+
**Pattern extraction date:** 2026-06-04
