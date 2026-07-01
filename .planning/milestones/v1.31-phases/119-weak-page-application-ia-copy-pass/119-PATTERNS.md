# Phase 119: Weak-Page Application & IA/Copy Pass - Pattern Map

**Mapped:** 2026-06-26
**Files analyzed:** 20
**Analogs found:** 20 / 20

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/lockspire/web/live/admin/clients_live/show.ex` | route | request-response + event-driven | `lib/lockspire/web/live/admin/clients_live/show.ex` + `lib/lockspire/web/components/admin_components.ex` | exact + primitive |
| `lib/lockspire/web/live/admin/policies_live/dcr.html.heex` | component | request-response + CRUD form | `lib/lockspire/web/live/admin/policies_live/dcr.html.heex`, `lib/lockspire/web/live/admin/policies_live/dcr.ex`, `lib/lockspire/web/components/admin_components.ex` | partial |
| `lib/lockspire/web/live/admin/policies_live/dcr.ex` | route | CRUD form | `lib/lockspire/web/live/admin/policies_live/dcr.ex` | exact; preserve |
| `lib/lockspire/web/live/admin/policies_live/dcr/policy_form.ex` | model | transform + validation | `lib/lockspire/web/live/admin/policies_live/dcr/policy_form.ex` | exact; preserve |
| `lib/lockspire/web/live/admin/iat_live/index.html.heex` | component | CRUD + request-response | `lib/lockspire/web/live/admin/iat_live/index.html.heex`, `lib/lockspire/web/live/admin/clients_live/index.ex` | exact + role-match |
| `lib/lockspire/web/live/admin/iat_live/new.html.heex` | component | CRUD + copy-once file-like secret reveal | `lib/lockspire/web/live/admin/iat_live/new.html.heex`, `lib/lockspire/web/live/admin/clients_live/index.ex` | exact + role-match |
| `lib/lockspire/web/live/admin/tokens_live/show.ex` | route | CRUD + request-response | `lib/lockspire/web/live/admin/tokens_live/show.ex` | exact |
| `lib/lockspire/web/live/admin/consents_live/show.ex` | route | CRUD + request-response | `lib/lockspire/web/live/admin/consents_live/show.ex` | exact |
| `lib/lockspire/web/live/admin/device_authorizations_live/index.ex` | route | request-response + read-only event state | `lib/lockspire/web/live/admin/device_authorizations_live/index.ex` | exact |
| `lib/lockspire/web/live/admin/interactions_live/index.ex` | route | request-response + read-only event state | `lib/lockspire/web/live/admin/device_authorizations_live/index.ex` | role-match |
| `lib/lockspire/web/live/admin/logout_deliveries_live/index.ex` | route | request-response + read-only queue state | `lib/lockspire/web/live/admin/device_authorizations_live/index.ex`, `lib/lockspire/web/live/admin/interactions_live/index.ex` | role-match |
| `test/lockspire/web/live/admin/design_system_contract_test.exs` | test | batch/source-contract | `test/lockspire/web/live/admin/design_system_contract_test.exs` | exact |
| `test/lockspire/web/live/admin/clients_live/show_test.exs` | test | request-response + event-driven verification | `test/lockspire/web/live/admin/clients_live/show_test.exs` | exact |
| `test/lockspire/web/live/admin/policies_live/dcr_test.exs` | test | CRUD form verification | `test/lockspire/web/live/admin/policies_live/dcr_test.exs` | exact |
| `test/lockspire/web/live/admin/iat_live_test.exs` | test | CRUD + copy-once verification | `test/lockspire/web/live/admin/iat_live_test.exs` | exact |
| `test/lockspire/web/live/admin/tokens_live_test.exs` | test | CRUD + event verification | `test/lockspire/web/live/admin/tokens_live_test.exs` | exact |
| `test/lockspire/web/live/admin/consents_live_test.exs` | test | CRUD + event verification | `test/lockspire/web/live/admin/consents_live_test.exs` | exact |
| `test/lockspire/web/live/admin/device_authorizations_live_test.exs` | test | request-response + redaction verification | `test/lockspire/web/live/admin/device_authorizations_live_test.exs` | exact |
| `test/lockspire/web/live/admin/interactions_live_test.exs` | test | request-response + read-only verification | `test/lockspire/web/live/admin/interactions_live_test.exs` | exact |
| `test/lockspire/web/live/admin/logout_deliveries_live_test.exs` | test | request-response + read-only verification | `test/lockspire/web/live/admin/logout_deliveries_live_test.exs` | exact |

## Pattern Assignments

### `lib/lockspire/web/live/admin/clients_live/show.ex` (route, request-response + event-driven)

**Analog:** `lib/lockspire/web/live/admin/clients_live/show.ex` and `lib/lockspire/web/components/admin_components.ex`

**Imports and LiveView ownership pattern** (`clients_live/show.ex` lines 1-17):

```elixir
defmodule Lockspire.Web.Live.Admin.ClientsLive.Show do
  @moduledoc false

  use Phoenix.LiveView

  alias Lockspire.Admin
  alias Lockspire.Admin.Clients, as: AdminClients
  alias Lockspire.Admin.ServerPolicy, as: AdminServerPolicy
  alias Lockspire.Domain.Client
  alias Lockspire.Domain.ServerPolicy
  alias Lockspire.Protocol.MessageSigningProfile
  alias Lockspire.Protocol.ParPolicy
  alias Lockspire.Protocol.SecurityProfile
  alias Lockspire.Web.Components.AdminComponents
  alias Lockspire.Web.Live.Admin.ClientsLive.FormComponent
  alias Lockspire.Web.Live.Admin.ClientsLive.RotateSecretComponent
  alias Lockspire.Web.Live.AdminLayoutLive
```

**Event contract to preserve** (`clients_live/show.ex` lines 57-87, 90-150):

```elixir
def handle_event("save_client", %{"client" => params}, socket) do
  result =
    Admin.update_client(
      socket.assigns.client_id,
      save_client_attrs(params, socket.assigns.client)
    )

  case result do
    {:ok, %Client{} = client} ->
      server_policy = server_policy()

      {:noreply,
       assign(socket,
         client: client,
         effective_par_policy: resolve_effective_par_policy(client),
         effective_security_profile: resolve_effective_security_profile(client),
         strict_readiness: strict_readiness(),
         remote_jwks_summary: AdminClients.remote_jwks_summary(client),
         global_access_token_format: global_access_token_format(server_policy),
         effective_access_token_format:
           resolve_effective_access_token_format(server_policy, client),
         form_errors: []
       )}

    {:error, errors} when is_list(errors) ->
      {:noreply, assign(socket, form_errors: errors)}
```

```elixir
def handle_event("rotate_secret", %{"rotate" => %{"confirm" => "true"}}, socket) do
  case Admin.rotate_client_secret(socket.assigns.client_id, %{
         actor: %{type: :operator, id: "admin-ui"}
       }) do
    {:ok, %{client: client, client_secret: secret}} ->
      {:noreply, assign(socket, client: client, revealed_secret: secret, rotation_errors: [])}
```

```elixir
def handle_event(
      "toggle_client",
      _params,
      %{assigns: %{client: %Client{active: true}}} = socket
    ) do
  {:noreply, apply_toggle(socket, false)}
end

def handle_event("toggle_client", _params, socket) do
  {:noreply, apply_toggle(socket, true)}
end
```

**Existing page grouping to replace with primitives** (`clients_live/show.ex` lines 168-180, 183-223):

```elixir
<AdminComponents.page_hero
  eyebrow="Configure"
  title="Review client configuration"
  body="Review identity, effective posture, credentials, endpoints, DCR context, and lifecycle actions for this client."
/>

<AdminComponents.section_card
  title={@client.name || @client.client_id}
  subtitle="Client workspace for identity, effective security posture, endpoints, credentials, and safe lifecycle actions."
>
  <div class="lockspire-admin-client-workspace">
    <section class="lockspire-admin-detail-section">
      <h3>Identity and current status</h3>
```

```elixir
<section class="lockspire-admin-detail-section">
  <h3>Effective security posture</h3>
  <AdminComponents.description_list>
    <:item label="Global security profile">
      <code>{security_profile_label(@effective_security_profile.global_profile)}</code>
    </:item>
    <:item label="Client security override">
      <code>{security_profile_label(@client.security_profile)}</code>
    </:item>
    <:item label="Effective security profile">
      <strong>{security_verdict_for(@effective_security_profile)}</strong>
    </:item>
```

**Action destination contract to preserve** (`clients_live/show.ex` lines 386-455, 668-683):

```elixir
<section class="lockspire-admin-detail-section">
  <h3>Endpoint and logout settings</h3>
  <AdminComponents.action_group>
    <:primary>
      <.link class="lockspire-admin-btn lockspire-admin-btn-secondary" patch={show_path(@client.client_id, :redirects)}>Edit redirect URIs</.link>
      <.link class="lockspire-admin-btn lockspire-admin-btn-secondary" patch={show_path(@client.client_id, :logout_uris)}>
        Edit post-logout redirect URIs
      </.link>
    </:primary>
    <:secondary>
      <.link class="lockspire-admin-btn lockspire-admin-btn-secondary" patch={show_path(@client.client_id, :logout_propagation)}>
        Edit logout propagation URIs
      </.link>
    </:secondary>
  </AdminComponents.action_group>
</section>
```

```elixir
defp show_path(client_id, :show), do: Lockspire.mount_path() <> "/admin/clients/" <> client_id
defp show_path(client_id, :edit), do: show_path(client_id, :show) <> "/edit"

defp show_path(client_id, :logout_propagation),
  do: show_path(client_id, :edit) <> "?workflow=logout-propagation"

defp show_path(client_id, :security_profile),
  do: show_path(client_id, :show) <> "/security-profile"

defp show_path(client_id, :par_policy), do: show_path(client_id, :show) <> "/par-policy"
defp show_path(client_id, :redirects), do: show_path(client_id, :show) <> "/redirects"
defp show_path(client_id, :logout_uris), do: show_path(client_id, :show) <> "/logout-uris"
defp show_path(client_id, :rotate_secret), do: show_path(client_id, :show) <> "/rotate-secret"
```

**Primitive target pattern** (`admin_components.ex` lines 83-97, 109-128, 444-460, 533-545):

```elixir
def pane(assigns) do
  ~H"""
  <section class={["lockspire-admin-pane", @class]} {@rest}>
    <header class="lockspire-admin-pane__header">
      <div>
        <h2>{@title}</h2>
        <p :if={@subtitle}>{@subtitle}</p>
      </div>
      <div :if={@status != []} class="lockspire-admin-pane__status">{render_slot(@status)}</div>
      <div :if={@actions != []} class="lockspire-admin-pane__actions">{render_slot(@actions)}</div>
    </header>
    <div class="lockspire-admin-pane__body">{render_slot(@inner_block)}</div>
  </section>
  """
end
```

```elixir
def entity_header(assigns) do
  ~H"""
  <header class={["lockspire-admin-entity-header", @class]} {@rest}>
    <div class="lockspire-admin-entity-header__main">
      <p :if={@eyebrow} class="lockspire-admin-eyebrow">{@eyebrow}</p>
      <h2>{@title}</h2>
      <p :if={@subtitle}>{@subtitle}</p>
      <.long_value
        :if={@identifier}
        class="lockspire-admin-entity-header__identifier"
        kind={:id}
        value={@identifier}
      />
```

```elixir
def lifecycle_row(assigns) do
  ~H"""
  <div class={["lockspire-admin-lifecycle-row", @class]}>
    <div class="lockspire-admin-lifecycle-row__main">
      <strong>{@title}</strong>
      <p :if={@consequence}>{@consequence}</p>
    </div>
    <div class="lockspire-admin-lifecycle-row__meta">
      <.status_badge :if={@state} status={@state} domain={@domain} />
      <.timestamp :if={@timestamp} value={@timestamp} />
      <span :if={@actor}>{@actor}</span>
    </div>
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
```

**Planner guidance:** Re-group the client page into `entity_header`, `pane`, `status_cluster`, `lifecycle_row`, `long_value`, and existing `action_group` clusters. Do not rename events, helpers, patch paths, `FormComponent.client_form`, or mutation helpers.

---

### `lib/lockspire/web/live/admin/policies_live/dcr.html.heex` (component, request-response + CRUD form)

**Analog:** `dcr.html.heex`, `dcr.ex`, `policy_form.ex`, `AdminComponents.workflow_shell/1`, `AdminComponents.form_field/1`

**Current one-form submit contract** (`dcr.html.heex` lines 10-16, 30-40, 58-60, 85-103):

```heex
<form class="lockspire-admin-form-stack" phx-submit="save_policy">
  <Lockspire.Web.Components.AdminComponents.form_field
    id="registration_policy"
    label="Enforcement mode"
    help="Choose how Dynamic Client Registration requests are admitted."
  >
    <select id="registration_policy" name="policy[registration_policy]">
```

```heex
<Lockspire.Web.Components.AdminComponents.form_field
  id="dcr_allowed_scopes"
  label="Allowed Scopes"
  help="Comma-separated list of allowed scopes."
>
  <input type="text" id="dcr_allowed_scopes" name="policy[dcr_allowed_scopes]" value={Enum.join(@policy.dcr_allowed_scopes || [], ", ")} />
</Lockspire.Web.Components.AdminComponents.form_field>

<div class="lockspire-admin-field">
  <label for="dcr_allowed_grant_types">Allowed Grant Types</label>
  <input type="text" id="dcr_allowed_grant_types" name="policy[dcr_allowed_grant_types]" value={Enum.join(@policy.dcr_allowed_grant_types || [], ", ")} />
```

```heex
<div class="lockspire-admin-field">
  <label for="dcr_allowed_token_endpoint_auth_methods">Allowed Token Endpoint Auth Methods</label>
  <input type="text" id="dcr_allowed_token_endpoint_auth_methods" name="policy[dcr_allowed_token_endpoint_auth_methods]" value={Enum.join(@policy.dcr_allowed_token_endpoint_auth_methods || [], ", ")} />
```

```heex
<input type="number" id="dcr_default_client_lifetime_seconds" name="policy[dcr_default_client_lifetime_seconds]" value={@policy.dcr_default_client_lifetime_seconds} />
```

```heex
<Lockspire.Web.Components.AdminComponents.action_bar>
  <Lockspire.Web.Components.AdminComponents.admin_button type="submit" variant={:primary}>
    Save global DCR policy
  </Lockspire.Web.Components.AdminComponents.admin_button>
</Lockspire.Web.Components.AdminComponents.action_bar>
</form>
```

**Persistence contract to preserve** (`dcr.ex` lines 29-60):

```elixir
def handle_event("save_policy", %{"policy" => policy_params}, socket) do
  changeset = PolicyForm.changeset(policy_params)

  if changeset.valid? do
    policy_attrs = Ecto.Changeset.apply_changes(changeset)
    attrs = Map.from_struct(policy_attrs)

    case Admin.put_dcr_policy(attrs) do
      {:ok, %ServerPolicy{} = policy} ->
        {:noreply,
         socket
         |> assign(
           policy: policy,
           private_key_jwt_truth: dcr_private_key_jwt_truth(policy),
           client_secret_jwt_truth: dcr_client_secret_jwt_truth(policy),
           form_errors: []
         )
         |> put_flash(:info, "Global DCR policy updated")}
```

**Validation field list to preserve** (`policy_form.ex` lines 10-20, 26-48):

```elixir
embedded_schema do
  field(:registration_policy, Ecto.Enum, values: [:disabled, :initial_access_token, :open])
  field(:dcr_allowed_scopes, {:array, :string}, default: [])
  field(:dcr_allowed_grant_types, {:array, :string}, default: [])
  field(:dcr_allowed_response_types, {:array, :string}, default: [])
  field(:dcr_allowed_redirect_uri_schemes, {:array, :string}, default: [])
  field(:dcr_allowed_redirect_uri_hosts, {:array, :string}, default: [])
  field(:dcr_allowed_token_endpoint_auth_methods, {:array, :string}, default: [])
  field(:dcr_default_client_lifetime_seconds, :integer)
  field(:dcr_default_client_secret_lifetime_seconds, :integer)
  field(:dcr_default_registration_access_token_lifetime_seconds, :integer)
end
```

```elixir
policy
|> cast(attrs, [
  :registration_policy,
  :dcr_allowed_scopes,
  :dcr_allowed_grant_types,
  :dcr_allowed_response_types,
  :dcr_allowed_redirect_uri_schemes,
  :dcr_allowed_redirect_uri_hosts,
  :dcr_allowed_token_endpoint_auth_methods,
  :dcr_default_client_lifetime_seconds,
  :dcr_default_client_secret_lifetime_seconds,
  :dcr_default_registration_access_token_lifetime_seconds
])
|> validate_required([:registration_policy])
|> validate_number(:dcr_default_client_lifetime_seconds, greater_than_or_equal_to: 0)
```

**Workflow grouping primitive** (`admin_components.ex` lines 139-155, 278-295):

```elixir
def workflow_shell(assigns) do
  ~H"""
  <section class={["lockspire-admin-workflow-shell", @class]} {@rest}>
    <header>
      <h2>{@title}</h2>
      <p :if={@help} class="lockspire-admin-help">{@help}</p>
    </header>
    <.error_summary errors={@errors} />
    <div class="lockspire-admin-workflow-shell__body">
      {render_slot(@inner_block)}
      {render_slot(@body)}
    </div>
```

```elixir
def form_field(assigns) do
  assigns =
    assigns
    |> assign(:help_id, "#{assigns.id}-help")
    |> assign(:error_id, "#{assigns.id}-error")

  ~H"""
  <div class={["lockspire-admin-field", @errors != [] && "lockspire-admin-field-error", @class]}>
    <label for={@id}>
      {@label}
```

**Planner guidance:** Convert raw `lockspire-admin-field` wrappers to `AdminComponents.form_field`, group fields into one form with multiple `workflow_shell` sections, and keep every `name="policy[...]"` unchanged.

---

### `lib/lockspire/web/live/admin/policies_live/dcr.ex` (route, CRUD form)

**Analog:** `lib/lockspire/web/live/admin/policies_live/dcr.ex`

**Pattern:** Preserve this route module unless page grouping requires only assign/copy support. The current pattern loads policy in `mount/3`, leaves `handle_params/3` passive, validates through `PolicyForm`, and persists with `Admin.put_dcr_policy/1`.

**Load and posture truth pattern** (`dcr.ex` lines 63-83):

```elixir
defp load_policy(socket) do
  policy =
    case Admin.get_server_policy() do
      {:ok, %ServerPolicy{} = p} -> p
      {:error, _reason} -> %ServerPolicy{registration_policy: :disabled}
    end

  assign(socket,
    policy: policy,
    private_key_jwt_truth: dcr_private_key_jwt_truth(policy),
    client_secret_jwt_truth: dcr_client_secret_jwt_truth(policy)
  )
end

defp dcr_private_key_jwt_truth(%ServerPolicy{} = policy) do
  AdminServerPolicy.private_key_jwt_registration_truth(policy)
end
```

---

### `lib/lockspire/web/live/admin/policies_live/dcr/policy_form.ex` (model, transform + validation)

**Analog:** `lib/lockspire/web/live/admin/policies_live/dcr/policy_form.ex`

**Array input transform pattern** (`policy_form.ex` lines 50-82):

```elixir
defp prepare_array_fields(attrs) do
  array_fields = [
    "dcr_allowed_scopes",
    "dcr_allowed_grant_types",
    "dcr_allowed_response_types",
    "dcr_allowed_redirect_uri_schemes",
    "dcr_allowed_redirect_uri_hosts",
    "dcr_allowed_token_endpoint_auth_methods",
    :dcr_allowed_scopes,
    :dcr_allowed_grant_types,
    :dcr_allowed_response_types,
    :dcr_allowed_redirect_uri_schemes,
    :dcr_allowed_redirect_uri_hosts,
    :dcr_allowed_token_endpoint_auth_methods
  ]

  Enum.reduce(array_fields, attrs, fn field, acc ->
    case Map.fetch(acc, field) do
      {:ok, [val]} when is_binary(val) ->
        list = val |> String.split(",") |> Enum.map(&String.trim/1) |> Enum.reject(&(&1 == ""))
        Map.put(acc, field, list)
```

**Planner guidance:** Treat this file as a semantic fence. Do not add registration modes, auth methods, policy values, or storage fields in Phase 119.

---

### `lib/lockspire/web/live/admin/iat_live/index.html.heex` (component, CRUD + request-response)

**Analog:** `iat_live/index.html.heex` and `clients_live/index.ex`

**Page job and metric pattern** (`iat_live/index.html.heex` lines 2-18, 18-39):

```heex
<Lockspire.Web.Components.AdminComponents.page_hero
  eyebrow="Configure"
  title="Initial access token inventory"
  body="Review DCR onboarding intake tokens by status, expiration, creator, usage limit, and safe revocation context. Plaintext tokens are not shown after creation."
>
  <:actions>
    <Lockspire.Web.Components.AdminComponents.admin_button href={iat_new_path()} variant={:primary}>
      Mint initial access token
    </Lockspire.Web.Components.AdminComponents.admin_button>
  </:actions>
</Lockspire.Web.Components.AdminComponents.page_hero>
```

```heex
<Lockspire.Web.Components.AdminComponents.metric_grid>
  <Lockspire.Web.Components.AdminComponents.summary_stat
    value={iat_metrics(@tokens).active}
    label="Active"
  />
```

**Resource list and guarded revoke pattern** (`iat_live/index.html.heex` lines 53-99):

```heex
<Lockspire.Web.Components.AdminComponents.resource_list>
  <%= for token <- @tokens do %>
    <Lockspire.Web.Components.AdminComponents.resource_item
      title={token_title(token)}
      subtitle={usage_label(token)}
    >
      <:meta>
        <span>
          Creator
          <Lockspire.Web.Components.AdminComponents.long_value
            value={token.created_by || "operator"}
            kind={:id}
          />
```

```heex
<Lockspire.Web.Components.AdminComponents.admin_button
  phx-click="revoke"
  phx-value-id={token.id}
  data-confirm={"Revoke initial access token #{redacted_handle(:iat, token.id)}. Partners using this intake token will no longer be able to dynamically register clients."}
  variant={:danger}
>
  Revoke initial access token
</Lockspire.Web.Components.AdminComponents.admin_button>
```

**Planner guidance:** If restructuring, keep DCR onboarding vocabulary, metrics, `resource_list` rows, `long_value`, `data-confirm`, `phx-click="revoke"`, and no plaintext token rendering.

---

### `lib/lockspire/web/live/admin/iat_live/new.html.heex` (component, CRUD + copy-once)

**Analog:** `iat_live/new.html.heex`, `AdminComponents.copy_once_secret_panel/1`, `AdminComponents.form_field/1`

**Copy-once secret pattern** (`iat_live/new.html.heex` lines 12-27 and `admin_components.ex` lines 495-505):

```heex
<%= if @iat_secret do %>
  <Lockspire.Web.Components.AdminComponents.copy_once_secret_panel
    title="Initial access token minted"
    body="Copy once now. This initial access token is not stored or shown again as plaintext."
    label="Initial access token"
    value={@iat_secret}
  />
  <Lockspire.Web.Components.AdminComponents.action_bar>
    <Lockspire.Web.Components.AdminComponents.admin_button
      phx-click="acknowledge_copy"
      variant={:primary}
    >
      I have copied this secret
```

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
```

**Form contract to preserve while replacing raw fields** (`iat_live/new.html.heex` lines 28-60):

```heex
<form phx-submit="mint" class="lockspire-admin-form-shell">
  <div class="lockspire-admin-field">
    <label for="iat_single_use">Single use</label>
    <select id="iat_single_use" name="single_use">
      <option value="true" selected={@form["single_use"].value == "true"}>Yes (Recommended)</option>
      <option value="false" selected={@form["single_use"].value == "false"}>No (Multi-use)</option>
    </select>
  </div>

  <div class="lockspire-admin-field">
    <label for="iat_expires_in_days">Expires in days</label>
    <input
      id="iat_expires_in_days"
      type="number"
      name="expires_in_days"
```

**Planner guidance:** Convert the two raw fields to `form_field` if touched. Preserve `phx-submit="mint"`, `name="single_use"`, `name="expires_in_days"`, and `phx-click="acknowledge_copy"`.

---

### `lib/lockspire/web/live/admin/tokens_live/show.ex` (route, CRUD + request-response)

**Analog:** `tokens_live/show.ex`

**Destructive event pattern** (`tokens_live/show.ex` lines 35-83):

```elixir
def handle_event("revoke_token", %{"revoke" => %{"confirm" => "true"}}, socket) do
  case Admin.revoke_token(socket.assigns.token_id, %{revoked_by: "operator"}) do
    {:ok, detail} ->
      {:noreply, assign(socket, token_detail: detail, revoke_error: nil)}

    {:error, _reason} ->
      {:noreply, assign(socket, revoke_error: "Token could not be revoked.")}
  end
end
```

```elixir
def handle_event("revoke_family", %{"family" => %{"confirm" => "true"}}, socket) do
  case Admin.revoke_token_family(socket.assigns.token_id, %{revoked_by: "operator"}) do
    {:ok, %{count: count, token: detail}} ->
      notice =
        if count == 0,
          do: "This refresh family was already fully revoked.",
          else: "Revoked #{count} token(s) in this refresh family."
```

**Support hierarchy and redaction pattern** (`tokens_live/show.ex` lines 100-164):

```elixir
<AdminComponents.page_hero
  eyebrow="Support"
  title="Token health decision"
  body="Review durable token state, refresh-family context, and the smallest safe revocation path."
>
  <:summary>
    <span>Status: <AdminComponents.status_badge status={@token_detail.status} /></span>
  </:summary>
```

```elixir
<AdminComponents.description_list>
  <:item label="Client">
    <AdminComponents.long_value value={@token_detail.token.client_display} kind={:id} />
  </:item>
  <:item label="Client handle">
    <AdminComponents.long_value value={@token_detail.token.client_handle} kind={:id} />
  </:item>
```

**Confirmation panel pattern** (`tokens_live/show.ex` lines 209-256 and `admin_components.ex` lines 565-580):

```elixir
<AdminComponents.confirmation_panel title="Revoke token" variant={:danger}>
  <:body>
    <form class="lockspire-admin-form-stack" phx-submit="revoke_token">
      <label class="lockspire-admin-checkbox-field">
        <input type="checkbox" name="revoke[confirm]" value="true" />
        <span>
          Revoke only this {@token_detail.token.token_type} token for client
          {@token_detail.token.client_display}, subject
          {@token_detail.token.account_handle || "not recorded"}, expiring
```

```elixir
def confirmation_panel(assigns) do
  assigns = assign(assigns, :class, confirmation_panel_class(assigns.variant))

  ~H"""
  <section class={@class}>
    <header>
      <h3>{@title}</h3>
    </header>
    <div class="lockspire-admin-confirmation-panel__body">
      {render_slot(@body)}
```

**Planner guidance:** Only adjust hierarchy/copy if needed. Preserve `Admin.revoke_token/2`, `Admin.revoke_token_family/2`, the checkbox confirmation names, and long-value redaction.

---

### `lib/lockspire/web/live/admin/consents_live/show.ex` (route, CRUD + request-response)

**Analog:** `consents_live/show.ex`

**Imports and redaction helper pattern** (`consents_live/show.ex` lines 1-9, 186-187):

```elixir
defmodule Lockspire.Web.Live.Admin.ConsentsLive.Show do
  @moduledoc false

  use Phoenix.LiveView

  alias Lockspire.Admin
  alias Lockspire.Redaction
  alias Lockspire.Web.Components.AdminComponents
  alias Lockspire.Web.Live.AdminLayoutLive
```

```elixir
defp redacted_handle(_type, nil), do: "Not recorded"
defp redacted_handle(type, value), do: Redaction.handle(type, value)
```

**Destructive event and confirmation pattern** (`consents_live/show.ex` lines 34-52, 133-155):

```elixir
def handle_event("revoke_consent", %{"revoke" => %{"confirm" => "true"}}, socket) do
  case Admin.revoke_consent(socket.assigns.consent_id, %{
         revoked_by: "operator",
         revoked_reason: "operator_revoked"
       }) do
    {:ok, consent} ->
      {:noreply, assign(socket, consent: consent, revoke_error: nil)}
```

```elixir
<AdminComponents.confirmation_panel title="Revoke consent grant" variant={:danger}>
  <:body>
    <form class="lockspire-admin-form-stack" phx-submit="revoke_consent">
      <label class="lockspire-admin-checkbox-field">
        <input type="checkbox" name="revoke[confirm]" value="true" />
        <span>
          Revoke consent grant for client
          {client_display(@consent)}, subject
          {redacted_handle(:account, @consent.grant.account_id)}, and scopes
          {scope_label(@consent.grant.scopes)}. This remembered grant will no longer
          authorize future consent reuse.
```

**Planner guidance:** Keep the durable grant wording and revocation semantics. Use panes only to clarify incident hierarchy; do not introduce new consent actions.

---

### `lib/lockspire/web/live/admin/device_authorizations_live/index.ex` (route, request-response + read-only event state)

**Analog:** `device_authorizations_live/index.ex`

**Read-only operate route pattern** (`device_authorizations_live/index.ex` lines 30-39, 63-87):

```elixir
<AdminComponents.page_hero
  eyebrow="Operate"
  title="Device authorization queue"
  body="Triage pending, approved, denied, expired, and completed device-flow state without exposing device or user code material."
/>

<AdminComponents.section_card
  title="Review device authorizations"
  subtitle="Read-only queue rows expose client, status, subject, expiration, and durable non-secret identifiers."
>
```

```elixir
<%= if @device_authorizations == [] do %>
  <AdminComponents.empty_state
    title="No device authorizations"
    body="There are no device flow requests waiting for operator review."
  />
<% else %>
  <AdminComponents.resource_list>
    <%= for auth <- @device_authorizations do %>
      <AdminComponents.resource_item
        title="Device authorization"
        subtitle="Review device authorizations"
      >
        <:meta>
          <span>Client <AdminComponents.long_value value={redacted_handle(:client, auth.client_id)} kind={:id} /></span>
```

**Load and redaction pattern** (`device_authorizations_live/index.ex` lines 93-110):

```elixir
defp load_device_authorizations do
  case Admin.list_device_authorizations() do
    {:ok, auths} -> auths
    {:error, _reason} -> []
  end
end

defp count_status(auths, status), do: Enum.count(auths, &(&1.status == status))

defp redacted_handle(_type, nil), do: "Not recorded"
defp redacted_handle(type, value), do: Redaction.handle(type, value)
```

**Planner guidance:** This is the cleanest operate-queue analog. Copy it for interactions/logout delivery cleanup: no row actions, no retry/discard UI, non-secret identifiers through `long_value`, and clear empty state.

---

### `lib/lockspire/web/live/admin/interactions_live/index.ex` (route, request-response + read-only event state)

**Analog:** `device_authorizations_live/index.ex`; self shows the drift to remove

**Current table-wrap drift** (`interactions_live/index.ex` lines 62-87):

```elixir
<%= if @interactions == [] do %>
  <AdminComponents.empty_state
    title="No active interactions"
    body="There are no authorization interactions waiting for operator review."
  />
<% else %>
  <div class="lockspire-admin-table-wrap">
    <AdminComponents.resource_list>
      <%= for interaction <- @interactions do %>
        <AdminComponents.resource_item title="Authorization interaction" subtitle="Review interactions">
          <:meta>
            <span>Interaction <AdminComponents.long_value value={interaction.interaction_id} kind={:id} /></span>
            <span>Client <AdminComponents.long_value value={redacted_handle(:client, interaction.client_id)} kind={:id} /></span>
```

**Target row primitive** (`admin_components.ex` lines 375-380, 419-431):

```elixir
def resource_list(assigns) do
  ~H"""
  <ul class="lockspire-admin-resource-list">
    {render_slot(@inner_block)}
  </ul>
  """
end
```

```elixir
def dense_resource_row(assigns) do
  ~H"""
  <li class={["lockspire-admin-dense-resource-row", @class]}>
    <div class="lockspire-admin-dense-resource-row__main">
      <strong>{@title}</strong>
      <span :if={@subtitle}>{@subtitle}</span>
    </div>
    <div :if={@meta != []} class="lockspire-admin-dense-resource-row__meta">{render_slot(@meta)}</div>
```

**Planner guidance:** Remove non-table `lockspire-admin-table-wrap`; use `resource_list` plus `resource_item` or `dense_resource_row`. Do not add `phx-click`, `phx-submit`, approve, deny, retry, or discard controls.

---

### `lib/lockspire/web/live/admin/logout_deliveries_live/index.ex` (route, request-response + read-only queue state)

**Analog:** `device_authorizations_live/index.ex`; self shows queue metrics and drift

**Current metrics and read-only copy** (`logout_deliveries_live/index.ex` lines 33-49):

```elixir
<AdminComponents.page_hero
  eyebrow="Operate"
  title="Logout propagation queue"
  body="Triage waiting, retrying, failed, discarded, and completed logout delivery work without adding worker controls."
/>

<AdminComponents.section_card
  title="Review logout deliveries"
  subtitle="Read-only delivery rows expose status pressure, client, endpoint, attempts, and durable delivery context."
>
  <AdminComponents.metric_grid>
    <AdminComponents.summary_stat value={@delivery_metrics.waiting} label="Waiting" />
    <AdminComponents.summary_stat value={@delivery_metrics.retrying} label="Retrying" />
```

**Current table-wrap drift to replace** (`logout_deliveries_live/index.ex` lines 51-78):

```elixir
<%= if @deliveries == [] do %>
  <AdminComponents.empty_state
    title="No logout deliveries"
    body="There are no logout propagation records waiting for operator review."
  />
<% else %>
  <div class="lockspire-admin-table-wrap">
    <AdminComponents.resource_list>
      <%= for delivery <- @deliveries do %>
        <AdminComponents.resource_item
          title={"#{delivery.channel} logout delivery"}
          subtitle="Review logout deliveries"
```

**Metric helper pattern to preserve** (`logout_deliveries_live/index.ex` lines 84-97):

```elixir
defp delivery_metrics(deliveries) do
  %{
    waiting: Enum.count(deliveries, &(&1.status in [:pending, :enqueued])),
    retrying: Enum.count(deliveries, &(&1.status == :attempted)),
    failed: Enum.count(deliveries, &(&1.status == :retryable)),
    discarded: Enum.count(deliveries, &(&1.status in [:discarded, :skipped])),
    completed: Enum.count(deliveries, &(&1.status in [:succeeded, :rendered]))
  }
end
```

**Planner guidance:** Keep this page read-only and remove table-like chrome around list content. Preserve status bucket mapping and the negative contract that there are no worker controls.

---

## Test Pattern Assignments

### `test/lockspire/web/live/admin/design_system_contract_test.exs` (test, batch/source-contract)

**Analog:** `design_system_contract_test.exs`

**Source inventory pattern** (lines 4-19, 36-89):

```elixir
@admin_live_glob Path.expand(
                   "../../../../../lib/lockspire/web/live/admin/**/*.{ex,heex}",
                   __DIR__
                 )
@admin_css_path Path.expand("../../../../../lib/lockspire/web/admin_css.ex", __DIR__)
@admin_components_path Path.expand(
                         "../../../../../lib/lockspire/web/components/admin_components.ex",
                         __DIR__
                       )
```

```elixir
@phase_109_operations_sources [
  Path.expand(
    "../../../../../lib/lockspire/web/live/admin/logout_deliveries_live/index.ex",
    __DIR__
  ),
  Path.expand(
    "../../../../../lib/lockspire/web/live/admin/device_authorizations_live/index.ex",
    __DIR__
  ),
  Path.expand("../../../../../lib/lockspire/web/live/admin/interactions_live/index.ex", __DIR__)
]
```

**Primitive/source fence pattern** (lines 334-390, 486-527):

```elixir
test "shared component primitives are exposed and backed by namespaced CSS" do
  components = File.read!(@admin_components_path)
  css = File.read!(@admin_css_path)

  for function_name <- [
        "page_hero",
        "metric_grid",
        "task_card",
        "filter_bar",
        "copy_once_secret_panel",
        "action_group",
        "long_value",
        "empty_state",
        "confirmation_panel",
        "form_field",
        "error_summary",
        "resource_item",
        "status_badge",
        "pane",
        "entity_header",
        "workflow_shell",
```

```elixir
test "phase 118 representative form adoption keeps explicit Phoenix controls and named exceptions" do
  adoption_paths = [
    Path.expand(
      "../../../../../lib/lockspire/web/live/admin/clients_live/form_component.ex",
      __DIR__
    ),
    Path.expand(
      "../../../../../lib/lockspire/web/live/admin/policies_live/dcr.html.heex",
      __DIR__
    ),
```

**Phase route/copy/redaction fence pattern** (lines 724-790, 792-849):

```elixir
test "phase 109 routes use approved journey labels, shared primitives, and style fences" do
  for path <- @phase_109_support_sources do
    source = File.read!(path)

    assert source =~ "Support"
    assert source =~ "AdminComponents.long_value"
  end
```

```elixir
test "phase 109 routes fence generic CTAs, redaction, and risky action copy" do
  sources = phase_109_source_blob()
  tests = phase_109_test_blob()

  refute Regex.match?(
           ~r/(?:^|>|\n)\s*(Apply|Submit|OK|Cancel|Open|Revoke|Mint IAT|Rotate secret|Rotate RAT)\s*(?:<|\n|$)/,
           sources
         )

  for phrase <- [
        "redacted_handle",
        "plaintext",
        "copy_once_secret_panel",
        "not stored or shown again as plaintext",
```

**Planner guidance:** Add Phase 119-specific source lists or extend Phase 109 lists for touched files. Assert primitive adoption, no inline styles, no non-table `lockspire-admin-table-wrap` around resource lists, no unsupported queue controls, and redaction/copy vocabulary.

---

### `test/lockspire/web/live/admin/clients_live/show_test.exs` (test, request-response + event-driven verification)

**Analog:** `clients_live/show_test.exs`

**Setup pattern** (lines 14-60):

```elixir
setup_all do
  Application.put_env(:lockspire, :repo, Lockspire.TestRepo)
  Application.put_env(:lockspire, :mount_path, "")

  on_exit(fn ->
    Application.put_env(:lockspire, :mount_path, "/lockspire")
  end)
```

```elixir
{:ok, client} =
  Repository.register_client(%Client{
    client_id: "security-show-client",
    client_secret_hash: "sha256:show:hash",
    client_type: :confidential,
    name: "Security Show Client",
```

**Detail assertions to extend** (lines 69-106, 300-345, 437-459):

```elixir
assert {:ok, _view, html} = live(conn_for_admin(), "/admin/clients/#{client.client_id}")

assert html =~ "Global security profile"
assert html =~ "Client security override"
assert html =~ "Effective security profile"
assert html =~ "Strict message-signing posture"
assert html =~ "Mixed-mode escape hatch"
assert html =~ "Warning:"
assert html =~ "mixed-mode bypass"
```

```elixir
assert html =~ "Remote JWKS"
assert html =~ "Status"
assert html =~ "incident"
assert html =~ "remote_jwks_key_unavailable"
assert html =~ "Stage=select_key"
assert html =~ "subreason=post_refresh_key_still_missing"
assert html =~ "forced_refresh=true"
assert html =~ "cache_preserved=true"
assert html =~ "Publish the requested key alongside the previous key"
assert html =~ "mix lockspire.doctor remote-jwks --client pkjwt-incident-client"
refute html =~ "client_secret_hash"
```

```elixir
assert html =~ "Global access token format"
assert html =~ "Client access token override"
assert html =~ "Effective access token format"

# nil override renders as "inherit"; server default is :jwt, so effective is jwt.
assert html =~ "inherit"
assert html =~ "jwt"
```

**Planner guidance:** Extend with assertions for `lockspire-admin-entity-header`, `lockspire-admin-pane`, support pivots, endpoint/logout vocabulary split, and preserved action patch destinations.

---

### `test/lockspire/web/live/admin/policies_live/dcr_test.exs` (test, CRUD form verification)

**Analog:** `policies_live/dcr_test.exs`

**Route/current-mode pattern** (lines 44-59):

```elixir
test "router exposes global DCR policy management route" do
  routes = Phoenix.Router.routes(Lockspire.Web.Router)

  assert Enum.any?(routes, &live_route?(&1, "/admin/policies/dcr", Dcr))
end

test "global DCR policy page renders current mode" do
  assert {:ok, _policy} =
           ServerPolicy.put_dcr_policy(%{registration_policy: :initial_access_token})

  assert {:ok, _view, html} = live(conn_for_admin(), "/admin/policies/dcr")

  assert html =~ "Global DCR policy"
```

**One-form submit pattern** (lines 93-107):

```elixir
assert {:ok, view, _html} = live(conn_for_admin(), "/admin/policies/dcr")

view
|> form("form[phx-submit=save_policy]", %{
  policy: %{registration_policy: "open", dcr_allowed_scopes: "openid, email"}
})
|> render_submit()

assert {:ok, policy} = ServerPolicy.get_server_policy()
assert policy.registration_policy == :open
assert policy.dcr_allowed_scopes == ["openid", "email"]
```

**Planner guidance:** Add assertions that there is still exactly one `phx-submit="save_policy"` form, grouped decisions render gate/allowlist/lifetime/auth-method/risk copy, and all existing field names remain visible.

---

### `test/lockspire/web/live/admin/iat_live_test.exs` (test, CRUD + copy-once verification)

**Analog:** `iat_live_test.exs`

**Vocabulary and index pattern** (lines 38-45, 48-81):

```elixir
test "DCR page preserves onboarding and policy vocabulary" do
  {:ok, _view, html} = live(conn_for_admin(), "/admin/dcr")

  assert html =~ "DCR onboarding"
  assert html =~ "DCR policy"
  assert html =~ "Mint initial access token"
  assert html =~ "Review initial access tokens"
end
```

```elixir
assert html =~ "Configure"
assert html =~ "Initial access token inventory"
assert html =~ "Review initial access tokens"
assert html =~ "Active"
assert html =~ "Used"
assert html =~ "Expired"
assert html =~ "Revoked"
assert html =~ "Single-use"
assert html =~ "Creator"
assert html =~ "Revoke initial access token"
assert html =~ "lockspire-admin-resource-list__item"
assert html =~ "lockspire-admin-long-value"
refute html =~ secret
```

**Copy-once test pattern** (lines 85-115):

```elixir
html_after_mint =
  view
  |> element("form")
  |> render_submit(%{"single_use" => "true", "expires_in_days" => "30"})

assert html_after_mint =~ "Initial access token minted"
assert html_after_mint =~ "lockspire-admin-copy-once-secret"
assert html_after_mint =~ "Copy once"
assert html_after_mint =~ "not stored or shown again as plaintext"
assert html_after_mint =~ "I have copied this secret"
```

**Planner guidance:** Extend for form-field adoption and grouped workflow copy while keeping plaintext negative assertions.

---

### `test/lockspire/web/live/admin/tokens_live_test.exs` (test, CRUD + event verification)

**Analog:** `tokens_live_test.exs`

**Support detail and destructive event proof** (lines 115-168):

```elixir
html = rendered_to_string(Show.render(socket.assigns))

assert html =~ "Support"
assert html =~ "Token health decision"
assert html =~ "Opaque tokens stay opaque here"
assert html =~ "Refresh family lineage"
assert html =~ "lockspire-admin-description-list"
assert html =~ "lockspire-admin-long-value"
assert html =~ "Client"
assert html =~ "Token UI Client"
assert html =~ "account_"
assert html =~ "family_"
assert html =~ "Session ID"
assert html =~ "Not recorded"
assert html =~ "Parent token"
assert html =~ "lockspire-admin-confirmation-panel"
assert html =~ "Revoke token"
assert html =~ "Revoke token family"
assert html =~ "family-wide action"
assert html =~ "revokes every active token"
refute html =~ "token-ui-refresh-hash"
refute html =~ "family-ui-123"
refute html =~ "account-token-ui"
```

```elixir
assert {:noreply, socket} =
         Show.handle_event("revoke_token", %{"revoke" => %{"confirm" => "true"}}, socket)

assert socket.assigns.token_detail.token.revoked_at
```

**Planner guidance:** If token detail is touched, add assertions for new `pane`/hierarchy classes and keep all existing redaction/action assertions.

---

### `test/lockspire/web/live/admin/consents_live_test.exs` (test, CRUD + event verification)

**Analog:** `consents_live_test.exs`

**Support detail and revocation proof** (lines 100-132):

```elixir
html = rendered_to_string(Show.render(socket.assigns))

assert html =~ "Support"
assert html =~ "Stored grant decision"
assert html =~ "Durable consent truth"
assert html =~ "Review stored grant"
assert html =~ "Revoke consent grant"
assert html =~ "remembered grant will no longer"
assert html =~ "openid, email"
assert html =~ "lockspire-admin-long-value"
refute html =~ "account-consent-ui"
refute html =~ "sha256:consent-ui:hash"

assert {:noreply, socket} =
         Show.handle_event("revoke_consent", %{"revoke" => %{"confirm" => "true"}}, socket)
```

**Planner guidance:** Mirror token detail test shape. Add hierarchy assertions only where source changes.

---

### `test/lockspire/web/live/admin/device_authorizations_live_test.exs` (test, request-response + redaction verification)

**Analog:** `device_authorizations_live_test.exs`

**Read-only redaction proof** (lines 59-78):

```elixir
assert {:ok, _view, html} = live(conn_for_admin(), "/admin/device_authorizations")

assert html =~ "Operate"
assert html =~ "Device authorization queue"
assert html =~ "Review device authorizations"
assert html =~ "Pending"
assert html =~ "Approved"
assert html =~ "Denied"
assert html =~ "Expired"
assert html =~ "Completed"
assert html =~ "lockspire-admin-resource-list__item"
assert html =~ "lockspire-admin-long-value"
assert html =~ "Device authorization"
refute html =~ "hash1"
refute html =~ "hash2"
refute html =~ "device_code"
refute html =~ "user_code"
refute html =~ "test-client"
```

**Planner guidance:** Add negative control assertions if page copy changes: no approval/retry/discard buttons and no code material.

---

### `test/lockspire/web/live/admin/interactions_live_test.exs` (test, request-response + read-only verification)

**Analog:** `interactions_live_test.exs`

**Operate queue proof** (lines 47-72):

```elixir
html = rendered_to_string(Index.render(socket.assigns))

assert html =~ "Operate"
assert html =~ "Authorization interaction queue"
assert html =~ "Review interactions"
assert html =~ "Pending login"
assert html =~ "Pending consent"
assert html =~ "Completed"
assert html =~ "Denied"
assert html =~ "Expired"
assert html =~ "lockspire-admin-resource-list__item"
assert html =~ "lockspire-admin-long-value"
assert html =~ "test-interaction-123"
refute html =~ "<table"
assert html =~ "Pending login"
```

**Planner guidance:** Extend this test to refute `lockspire-admin-table-wrap` when the list is non-table, and refute unsupported `phx-click`/`phx-submit` if the rendered row content changes.

---

### `test/lockspire/web/live/admin/logout_deliveries_live_test.exs` (test, request-response + read-only verification)

**Analog:** `logout_deliveries_live_test.exs`

**Operate queue negative-control proof** (lines 69-100):

```elixir
html = rendered_to_string(Index.render(socket.assigns))

assert html =~ "Operate"
assert html =~ "Logout propagation queue"
assert html =~ "Review logout deliveries"
assert html =~ "Waiting"
assert html =~ "Retrying"
assert html =~ "Failed"
assert html =~ "Discarded"
assert html =~ "Completed"
assert summary_stat?(html, "Waiting", 1)
assert summary_stat?(html, "Retrying", 1)
assert summary_stat?(html, "Failed", 1)
assert html =~ "lockspire-admin-resource-list__item"
assert html =~ "lockspire-admin-long-value"
assert html =~ "test-delivery-123"
assert html =~ "test-delivery-attempted"
assert html =~ "test-delivery-retryable"
refute html =~ "<table"
refute html =~ "phx-click"
refute html =~ "phx-submit"
assert html =~ "Pending"
```

**Planner guidance:** Keep this as the strictest operate-queue read-only test. Add `refute html =~ "lockspire-admin-table-wrap"` after removing the wrapper.

## Shared Patterns

### Admin Component Primitives

**Source:** `lib/lockspire/web/components/admin_components.ex`
**Apply to:** all touched LiveViews/HEEx pages

Use these existing primitives instead of local structural wrappers:

```elixir
def pane(assigns) do
  ~H"""
  <section class={["lockspire-admin-pane", @class]} {@rest}>
```

```elixir
def workflow_shell(assigns) do
  ~H"""
  <section class={["lockspire-admin-workflow-shell", @class]} {@rest}>
```

```elixir
def dense_resource_row(assigns) do
  ~H"""
  <li class={["lockspire-admin-dense-resource-row", @class]}>
```

```elixir
def long_value(assigns) do
  assigns = assign(assigns, :class_name, long_value_class(assigns.kind, assigns.class))

  ~H"""
  <span class={@class_name}>
```

### Journey Labels And Page Jobs

**Source:** `iat_live/index.html.heex` lines 2-6, `tokens_live/show.ex` lines 100-103, `device_authorizations_live/index.ex` lines 30-33
**Apply to:** all touched admin pages

```heex
<Lockspire.Web.Components.AdminComponents.page_hero
  eyebrow="Configure"
  title="Initial access token inventory"
  body="Review DCR onboarding intake tokens by status, expiration, creator, usage limit, and safe revocation context. Plaintext tokens are not shown after creation."
>
```

```elixir
<AdminComponents.page_hero
  eyebrow="Support"
  title="Token health decision"
  body="Review durable token state, refresh-family context, and the smallest safe revocation path."
>
```

```elixir
<AdminComponents.page_hero
  eyebrow="Operate"
  title="Device authorization queue"
  body="Triage pending, approved, denied, expired, and completed device-flow state without exposing device or user code material."
/>
```

### Redaction And Sensitive Material

**Source:** `consents_live/show.ex` lines 186-187, `device_authorizations_live/index.ex` lines 102-103, `copy_once_secret_panel/1` lines 495-505
**Apply to:** all support, operate, and copy-once pages

```elixir
defp redacted_handle(_type, nil), do: "Not recorded"
defp redacted_handle(type, value), do: Redaction.handle(type, value)
```

```elixir
<code :if={@value && !@redacted}>{@value}</code>
<span :if={!@value || @redacted} class="lockspire-admin-redacted-value">Redacted</span>
```

### Confirmation And Consequence Copy

**Source:** `tokens_live/show.ex` lines 209-256, `consents_live/show.ex` lines 133-155
**Apply to:** destructive actions only

```elixir
<AdminComponents.confirmation_panel title="Revoke token family" variant={:danger}>
  <:body>
    <form class="lockspire-admin-form-stack" phx-submit="revoke_family">
      <label class="lockspire-admin-checkbox-field">
        <input type="checkbox" name="family[confirm]" value="true" />
```

```elixir
Revoke consent grant for client
{client_display(@consent)}, subject
{redacted_handle(:account, @consent.grant.account_id)}, and scopes
{scope_label(@consent.grant.scopes)}. This remembered grant will no longer
authorize future consent reuse.
```

### Read-Only Operate Queues

**Source:** `device_authorizations_live/index.ex` lines 63-87; `logout_deliveries_live_test.exs` lines 97-99
**Apply to:** device authorizations, interactions, logout deliveries

```elixir
<AdminComponents.resource_list>
  <%= for auth <- @device_authorizations do %>
    <AdminComponents.resource_item
      title="Device authorization"
      subtitle="Review device authorizations"
    >
```

```elixir
refute html =~ "<table"
refute html =~ "phx-click"
refute html =~ "phx-submit"
```

## No Analog Found

No file lacks a usable analog. One subpattern is partial: no existing production page currently combines `workflow_shell` groups inside the DCR one-form policy page. For `dcr.html.heex`, combine the DCR one-form contract from `dcr.html.heex`/`dcr.ex` with `AdminComponents.workflow_shell/1` and `form_field/1`.

## Metadata

**Analog search scope:** `lib/lockspire/web/live/admin`, `lib/lockspire/web/components`, `test/lockspire/web/live/admin`
**Files scanned:** 44
**Pattern extraction date:** 2026-06-26
**Output file:** `.planning/phases/119-weak-page-application-ia-copy-pass/119-PATTERNS.md`
