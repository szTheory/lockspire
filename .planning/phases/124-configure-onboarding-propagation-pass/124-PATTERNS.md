# Phase 124: Configure Onboarding Propagation Pass - Pattern Map

**Mapped:** 2026-06-29
**Files analyzed:** 28 target files plus shared boundary/helpers
**Analogs found:** 28 / 28

Phase 124 is a route-scoped Configure polish pass. It should copy current Admin LiveView/component/test patterns and must not add admin routes, public APIs, schemas, migrations, public lab routes, package dependencies, or host-owned auth/layout seams.

Current worktree note: relevant admin files are dirty. Treat the excerpts below as the current local analogs, and preserve unrelated local edits during execution.

Project-local skills checked: `.codex/skills/` and `.agents/skills/` do not exist in this repo.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/lockspire/web/live/admin/clients_live/index.ex` | LiveView/controller | request-response, CRUD, event-driven | `lib/lockspire/web/live/admin/clients_live/index.ex` plus `clients_live/show.ex` | exact/self |
| `lib/lockspire/web/live/admin/clients_live/show.ex` | LiveView/controller | request-response, CRUD, event-driven | `lib/lockspire/web/live/admin/clients_live/show.ex` | exact/self |
| `lib/lockspire/web/live/admin/clients_live/form_component.ex` | component | request-response, transform | `lib/lockspire/web/live/admin/clients_live/form_component.ex` | exact/self |
| `lib/lockspire/web/live/admin/clients_live/rotate_secret_component.ex` | component | event-driven, request-response | `lib/lockspire/web/live/admin/clients_live/rotate_secret_component.ex` and `keys_live/action_component.ex` | role-match |
| `lib/lockspire/web/live/admin/dcr_live/index.ex` | LiveView/controller | request-response, CRUD/read | `lib/lockspire/web/live/admin/dcr_live/index.ex` plus `policies_live/dcr.html.heex` | exact/self |
| `lib/lockspire/web/live/admin/iat_live/index.ex` | LiveView/controller | request-response, CRUD, event-driven | `lib/lockspire/web/live/admin/iat_live/index.ex` plus `keys_live/show.ex` | exact/self |
| `lib/lockspire/web/live/admin/iat_live/index.html.heex` | component/template | request-response, event-driven | `lib/lockspire/web/live/admin/iat_live/index.html.heex` plus `keys_live/action_component.ex` | exact/self |
| `lib/lockspire/web/live/admin/iat_live/new.ex` | LiveView/controller | request-response, CRUD, event-driven | `lib/lockspire/web/live/admin/iat_live/new.ex` | exact/self |
| `lib/lockspire/web/live/admin/iat_live/new.html.heex` | component/template | request-response, event-driven | `lib/lockspire/web/live/admin/iat_live/new.html.heex` | exact/self |
| `lib/lockspire/web/live/admin/keys_live/index.ex` | LiveView/controller | request-response, CRUD, event-driven | `lib/lockspire/web/live/admin/keys_live/index.ex` | exact/self |
| `lib/lockspire/web/live/admin/keys_live/show.ex` | LiveView/controller | request-response, CRUD, event-driven | `lib/lockspire/web/live/admin/keys_live/show.ex` | exact/self |
| `lib/lockspire/web/live/admin/keys_live/action_component.ex` | component | event-driven, request-response | `lib/lockspire/web/live/admin/keys_live/action_component.ex` | exact/self |
| `lib/lockspire/web/live/admin/policies_live/index.ex` | LiveView/controller | request-response, CRUD/read | `lib/lockspire/web/live/admin/policies_live/dcr.html.heex` and `policies_live/index.ex` | role-match |
| `lib/lockspire/web/live/admin/policies_live/par.ex` | LiveView/controller | request-response, CRUD, event-driven | `lib/lockspire/web/live/admin/policies_live/dcr.ex` and `policies_live/dcr.html.heex` | role-match |
| `lib/lockspire/web/live/admin/policies_live/dpop.ex` | LiveView/controller | request-response, CRUD, event-driven | `lib/lockspire/web/live/admin/policies_live/dcr.ex` and `policies_live/dcr.html.heex` | role-match |
| `lib/lockspire/web/live/admin/policies_live/security_profile.ex` | LiveView/controller | request-response, CRUD, event-driven | `lib/lockspire/web/live/admin/policies_live/security_profile.ex` plus `policies_live/dcr.html.heex` | exact/self |
| `lib/lockspire/web/live/admin/policies_live/dcr.ex` | LiveView/controller | request-response, CRUD, event-driven | `lib/lockspire/web/live/admin/policies_live/dcr.ex` | exact/self |
| `lib/lockspire/web/live/admin/policies_live/dcr.html.heex` | component/template | request-response, transform | `lib/lockspire/web/live/admin/policies_live/dcr.html.heex` | exact/self |
| `test/lockspire/web/live/admin/clients_live_test.exs` | test | request-response, event-driven proof | `test/lockspire/web/live/admin/clients_live_test.exs` | exact/self |
| `test/lockspire/web/live/admin/clients_live/show_test.exs` | test | request-response, event-driven proof | `test/lockspire/web/live/admin/clients_live/show_test.exs` | exact/self |
| `test/lockspire/web/live/admin/iat_live_test.exs` | test | request-response, event-driven proof | `test/lockspire/web/live/admin/iat_live_test.exs` | exact/self |
| `test/lockspire/web/live/admin/keys_live_test.exs` | test | request-response, event-driven proof | `test/lockspire/web/live/admin/keys_live_test.exs` | exact/self |
| `test/lockspire/web/live/admin/policies_live/dcr_test.exs` | test | request-response, event-driven proof | `test/lockspire/web/live/admin/policies_live/dcr_test.exs` | exact/self |
| `test/lockspire/web/live/admin/policies_live/par_test.exs` | test | request-response, event-driven proof | `test/lockspire/web/live/admin/policies_live/par_test.exs` | exact/self |
| `test/lockspire/web/live/admin/policies_live/dpop_test.exs` | test | request-response, event-driven proof | `test/lockspire/web/live/admin/policies_live/dpop_test.exs` | exact/self |
| `test/lockspire/web/live/admin/policies_live/security_profile_test.exs` | test | request-response, event-driven proof | `test/lockspire/web/live/admin/policies_live/security_profile_test.exs` | exact/self |
| `test/lockspire/web/live/admin/design_system_contract_test.exs` | test | file-I/O, source-contract proof | `test/lockspire/web/live/admin/design_system_contract_test.exs` | exact/self |
| `test/lockspire/web/live/admin/design_system_component_stress_test.exs` | test | component stress proof | `test/lockspire/web/live/admin/design_system_contract_test.exs` component primitive contracts | role-match |

## Pattern Assignments

### `lib/lockspire/web/live/admin/clients_live/index.ex` (LiveView/controller, request-response + CRUD)

**Analog:** `lib/lockspire/web/live/admin/clients_live/index.ex`

**Imports and assigns pattern** (lines 4-23):
```elixir
use Phoenix.LiveView

alias Lockspire.Admin
alias Lockspire.Web.Components.AdminComponents
alias Lockspire.Web.Live.Admin.ClientsLive.FormComponent
alias Lockspire.Web.Live.AdminLayoutLive

@per_page 10

@impl true
def mount(_params, _session, socket) do
  {:ok,
   assign(socket,
     page_title: "Clients",
     current_section: :clients,
     clients: [],
     filters: %{"q" => "", "status" => "all", "provenance" => "all", "page" => "1"},
     form_errors: [],
     created_result: nil
   )}
end
```

**URL filter and inventory load pattern** (lines 27-36):
```elixir
def handle_params(params, _uri, socket) do
  filters = normalize_filters(params)
  clients = load_clients(filters)

  {:noreply,
   assign(socket,
     filters: filters,
     clients: paginate(clients, filters),
     total_clients: length(clients)
   )}
end
```

**Create and copy-once result pattern** (lines 40-56, 131-149):
```elixir
def handle_event("save_client", %{"client" => client_params}, socket) do
  case Admin.create_client(create_attrs(client_params)) do
    {:ok, result} ->
      filters = socket.assigns.filters

      {:noreply,
       socket
       |> assign(
         created_result: result,
         form_errors: [],
         clients: paginate(load_clients(filters), filters),
         total_clients: length(load_clients(filters))
       )}

    {:error, errors} ->
      {:noreply, assign(socket, form_errors: errors, created_result: nil)}
  end
end

<AdminComponents.copy_once_secret_panel
  title="Client created"
  body={
    if @created_result.client_secret,
      do: "Copy it now. Lockspire does not store or re-show plaintext secrets.",
      else: "This public client does not use a client secret."
  }
  label="Client secret"
  value={@created_result.client_secret}
  redacted={is_nil(@created_result.client_secret)}
/>
```

**Action copy to revise:** line 104 currently renders `Apply`; Phase 124 should use `Filter clients`.

---

### `lib/lockspire/web/live/admin/clients_live/show.ex` (LiveView/controller, request-response + event-driven)

**Analog:** `lib/lockspire/web/live/admin/clients_live/show.ex`

**Imports pattern** (lines 4-17):
```elixir
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

**Event and error handling pattern** (lines 64-94):
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

    {:error, _reason} ->
      {:noreply,
       assign(socket, form_errors: [%{field: :base, reason: :request_failed, detail: nil}])}
  end
end
```

**Page-first Configure spine** (lines 181-213):
```elixir
<AdminLayoutLive.shell current_section={@current_section} page_title={@page_title}>
  <AdminComponents.page_hero
    eyebrow="Configure"
    title="Review client configuration"
    body="Review identity, effective posture, credentials, endpoints, DCR context, and lifecycle actions for this client."
  />

  <div class="lockspire-admin-client-workspace">
    <AdminComponents.entity_header
      eyebrow="Client workspace"
      title={@client.name || @client.client_id}
      subtitle="Identity, posture, credentials, endpoints, DCR context, support pivots, and lifecycle actions for this client."
      identifier={@client.client_id}
    >
      <:status>
        <AdminComponents.status_badge status={status_for(@client)} />
        <AdminComponents.status_badge status={@client.provenance} />
      </:status>
      <:actions>
        <AdminComponents.action_group>
          <:primary>
            <.link class="lockspire-admin-btn lockspire-admin-btn-secondary" patch={show_path(@client.client_id, :edit)}>
              Edit client metadata
            </.link>
          </:primary>
        </AdminComponents.action_group>
      </:actions>
    </AdminComponents.entity_header>
```

**Grouped action pattern** (lines 316-321, 398-409):
```elixir
<AdminComponents.action_group>
  <:primary>
    <.link class="lockspire-admin-btn lockspire-admin-btn-secondary" patch={show_path(@client.client_id, :par_policy)}>Edit PAR policy</.link>
    <.link class="lockspire-admin-btn lockspire-admin-btn-secondary" patch={show_path(@client.client_id, :security_profile)}>Edit security profile</.link>
  </:primary>
</AdminComponents.action_group>

<AdminComponents.action_group>
  <:primary>
    <.link class="lockspire-admin-btn lockspire-admin-btn-secondary" :if={@client.client_type == :confidential} patch={show_path(@client.client_id, :rotate_secret)}>
      Rotate client secret
    </.link>
  </:primary>
  <:secondary>
    <.link class="lockspire-admin-btn lockspire-admin-btn-secondary" :if={@client.provenance == :self_registered} patch={show_path(@client.client_id, :rotate_registration_access_token)}>
      Rotate registration access token
    </.link>
  </:secondary>
</AdminComponents.action_group>
```

**Inline destructive confirmation pattern** (lines 557-588):
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
        <AdminComponents.admin_button type="submit" variant={if @client.active, do: :danger, else: :secondary}>
          {if @client.active, do: "Disable client", else: "Enable client"}
        </AdminComponents.admin_button>
      </AdminComponents.action_bar>
    </form>
  </:body>
</AdminComponents.confirmation_panel>
```

**RAT copy-once pattern** (lines 619-645):
```elixir
<div :if={@revealed_rat}>
  <AdminComponents.copy_once_secret_panel
    title="New Registration Access Token"
    body="Copy it now. Lockspire does not store or re-show plaintext tokens."
    label="Registration access token"
    value={@revealed_rat}
  />
  <AdminComponents.action_bar>
    <AdminComponents.admin_button phx-click="acknowledge_rat">
      I have copied the token
    </AdminComponents.admin_button>
  </AdminComponents.action_bar>
</div>

<form :if={is_nil(@revealed_rat)} phx-submit="rotate_rat">
  <label class="lockspire-admin-checkbox-field">
    <input type="checkbox" name="rotate[confirm]" value="true" />
    <span>I understand the previous RAT stops being the current credential after rotation.</span>
  </label>
```

**Existing route/query workflow pattern** (lines 791-806):
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

defp show_path(client_id, :rotate_registration_access_token),
  do: show_path(client_id, :show) <> "/rotate-registration-access-token"
```

---

### `lib/lockspire/web/live/admin/clients_live/form_component.ex` (component, request-response transform)

**Analog:** `lib/lockspire/web/live/admin/clients_live/form_component.ex`

**Component attr/default pattern** (lines 9-22):
```elixir
attr(:mode, :atom, required: true)
attr(:client, Client, default: nil)
attr(:effective_par_policy, :map, default: nil)
attr(:effective_security_profile, :map, default: nil)
attr(:strict_readiness, :map, default: nil)
attr(:errors, :list, default: [])

def client_form(assigns) do
  assigns =
    assigns
    |> assign(:title, title_for(assigns.mode))
    |> assign(:button_label, button_for(assigns.mode))
    |> assign(:defaults, defaults_for(assigns.mode, assigns.client))
```

**Form shell and error pattern** (lines 24-33, 383-388):
```elixir
<section class="lockspire-admin-form-shell">
  <header>
    <h2>{@title}</h2>
    <p class="lockspire-admin-help">{subtitle_for(@mode)}</p>
  </header>

  <.error_list errors={@errors} />

  <form class="lockspire-admin-form-stack" phx-submit="save_client">
    <input type="hidden" name="client[mode]" value={Atom.to_string(@mode)} />

    <AdminComponents.action_bar>
      <AdminComponents.admin_button type="submit" variant={:primary}>
        {@button_label}
      </AdminComponents.admin_button>
    </AdminComponents.action_bar>
  </form>
</section>
```

**Mode-specific copy and CTA pattern** (lines 506-539):
```elixir
defp title_for(:new), do: "Register client"
defp title_for(:edit), do: "Update safe metadata"
defp title_for(:logout_propagation), do: "Update logout propagation"
defp title_for(:redirects), do: "Update redirect URIs"
defp title_for(:logout_uris), do: "Update post-logout redirect URIs"
defp title_for(:par_policy), do: "Update PAR policy"
defp title_for(:security_profile), do: "Update security profile"

defp button_for(:new), do: "Create client"
defp button_for(:edit), do: "Save metadata"
defp button_for(:logout_propagation), do: "Save logout propagation"
defp button_for(:redirects), do: "Save redirect URIs"
defp button_for(:logout_uris), do: "Save post-logout redirect URIs"
defp button_for(:par_policy), do: "Save PAR policy"
defp button_for(:security_profile), do: "Save security profile"
```

---

### `lib/lockspire/web/live/admin/clients_live/rotate_secret_component.ex` (component, event-driven)

**Analog:** `lib/lockspire/web/live/admin/clients_live/rotate_secret_component.ex`; confirmation structure should copy `keys_live/action_component.ex`.

**Current copy-once panel pattern** (lines 19-40):
```elixir
<AdminComponents.error_list errors={@errors} />

<AdminComponents.copy_once_secret_panel
  :if={@revealed_secret}
  title="New client secret"
  body="Copy it now. Lockspire does not store or re-show plaintext secrets."
  label="Client secret"
  value={@revealed_secret}
/>

<form phx-submit="rotate_secret">
  <label class="lockspire-admin-checkbox-field">
    <input type="checkbox" name="rotate[confirm]" value="true" />
    <span>I understand the previous secret stops being the current credential after rotation.</span>
  </label>

  <AdminComponents.action_bar>
    <AdminComponents.admin_button type="submit" variant={:danger}>
      Rotate secret
    </AdminComponents.admin_button>
  </AdminComponents.action_bar>
</form>
```

**Phase 124 copy note:** update the button text to `Rotate client secret` where this component is touched, matching the UI-SPEC and the client detail action text.

---

### `lib/lockspire/web/live/admin/dcr_live/index.ex` (LiveView/controller, request-response read)

**Analog:** `lib/lockspire/web/live/admin/dcr_live/index.ex`; decision summary should copy `policies_live/dcr.html.heex`.

**Page hero and primary actions** (lines 31-44):
```elixir
<AdminComponents.page_hero
  eyebrow="Configure"
  title="DCR onboarding"
  body="DCR onboarding is the partner intake journey: mint short-lived initial access tokens, review self-registered clients, and route issuer posture changes to DCR policy."
>
  <:actions>
    <AdminComponents.admin_button href={admin_path("/iats/new")} variant={:primary}>
      Mint initial access token
    </AdminComponents.admin_button>
    <AdminComponents.admin_button href={admin_path("/iats")}>
      Review initial access tokens
    </AdminComponents.admin_button>
  </:actions>
</AdminComponents.page_hero>
```

**Inventory posture before sections** (lines 46-56):
```elixir
<AdminComponents.metric_grid>
  <AdminComponents.summary_stat
    value={@policy.registration_policy}
    label="registration mode"
  />
  <AdminComponents.summary_stat value={@summary.iats.active} label="active IATs" />
  <AdminComponents.summary_stat
    value={@summary.clients.self_registered}
    label="self-registered clients"
  />
</AdminComponents.metric_grid>
```

**Summary load pattern** (lines 132-147):
```elixir
defp load_summary do
  clients = ok_list(Admin.list_clients())
  iats = ok_list(Lockspire.Admin.InitialAccessTokens.list_iats())
  self_registered_clients = Enum.filter(clients, &(&1.provenance == :self_registered))

  %{
    clients: %{
      self_registered: length(self_registered_clients),
      self_registered_clients: self_registered_clients
    },
    iats: %{
      active: Enum.count(iats, &(iat_status(&1) == :active)),
      revoked: Enum.count(iats, &(iat_status(&1) == :revoked)),
      closed: Enum.count(iats, &(iat_status(&1) in [:expired, :used]))
    }
  }
end
```

---

### `lib/lockspire/web/live/admin/iat_live/index.ex` and `index.html.heex` (LiveView/controller + template, event-driven CRUD)

**Analog:** Current IAT files for inventory; `keys_live/show.ex` + `keys_live/action_component.ex` for replacing `data-confirm`.

**Current revoke event to refactor into confirmation-submit shape** (lines 20-31):
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

**Metrics-first inventory pattern** (`index.html.heex` lines 14-39):
```elixir
<Lockspire.Web.Components.AdminComponents.pane
  title="Review initial access tokens"
  subtitle="DCR onboarding inventory for active, used, expired, and revoked partner intake tokens."
>
  <Lockspire.Web.Components.AdminComponents.metric_grid>
    <Lockspire.Web.Components.AdminComponents.summary_stat value={iat_metrics(@tokens).active} label="Active" />
    <Lockspire.Web.Components.AdminComponents.summary_stat value={iat_metrics(@tokens).used} label="Used" />
    <Lockspire.Web.Components.AdminComponents.summary_stat value={iat_metrics(@tokens).expired} label="Expired" />
    <Lockspire.Web.Components.AdminComponents.summary_stat value={iat_metrics(@tokens).revoked} label="Revoked" />
    <Lockspire.Web.Components.AdminComponents.summary_stat value={iat_metrics(@tokens).total} label="Total intake" />
  </Lockspire.Web.Components.AdminComponents.metric_grid>
```

**Dense row and long-value pattern** (`index.html.heex` lines 53-91):
```elixir
<Lockspire.Web.Components.AdminComponents.resource_list>
  <%= for token <- @tokens do %>
    <Lockspire.Web.Components.AdminComponents.dense_resource_row
      title={token_title(token)}
      subtitle="DCR onboarding intake token"
    >
      <:meta>
        <span>
          Creator
          <Lockspire.Web.Components.AdminComponents.long_value value={token.created_by || "operator"} kind={:id} />
        </span>
        <span>
          Expires
          <Lockspire.Web.Components.AdminComponents.long_value value={formatted_timestamp(token.expires_at)} kind={:timestamp} />
        </span>
        <span>
          Last state change
          <Lockspire.Web.Components.AdminComponents.long_value value={formatted_timestamp(token_timestamp(token))} kind={:timestamp} />
        </span>
        <span>
          Usage/limit
          <Lockspire.Web.Components.AdminComponents.long_value value={usage_label(token)} kind={:text} />
        </span>
      </:meta>
      <:status>
        <Lockspire.Web.Components.AdminComponents.status_badge status={iat_status(token)} />
      </:status>
```

**Current anti-pattern to replace** (`index.html.heex` lines 92-101):
```elixir
<Lockspire.Web.Components.AdminComponents.admin_button
  phx-click="revoke"
  phx-value-id={token.id}
  data-confirm={"Revoke initial access token #{redacted_handle(:iat, token.id)}. Partners using this intake token will no longer be able to dynamically register clients."}
  variant={:danger}
>
  Revoke initial access token
</Lockspire.Web.Components.AdminComponents.admin_button>
```

**Replacement analog:** copy `confirmation_panel` form structure from `keys_live/action_component.ex` lines 66-87 and event guard shape from `keys_live/show.ex` lines 96-123. Use `name="revoke[confirm]"`, consequence copy naming the redacted IAT handle, and an error assign when confirmation is missing.

---

### `lib/lockspire/web/live/admin/iat_live/new.ex` and `new.html.heex` (LiveView/controller + template, copy-once create)

**Analog:** `lib/lockspire/web/live/admin/iat_live/new.ex` and `new.html.heex`

**Mint/acknowledge event pattern** (`new.ex` lines 20-42):
```elixir
def handle_event("mint", %{"single_use" => single_use, "expires_in_days" => days}, socket) do
  attrs = %{
    single_use: single_use == "true",
    expires_at: days_from_now(days),
    created_by: "operator"
  }

  case InitialAccessTokens.mint_iat(attrs) do
    {:ok, _iat, plaintext_secret} ->
      {:noreply,
       socket
       |> put_flash(:info, "IAT minted successfully.")
       |> assign(iat_secret: plaintext_secret)}

    {:error, _reason} ->
      {:noreply, put_flash(socket, :error, "Failed to mint IAT.")}
  end
end

def handle_event("acknowledge_copy", _params, socket) do
  {:noreply, assign(socket, iat_secret: nil)}
end
```

**Copy-once rendered state** (`new.html.heex` lines 8-26):
```elixir
<Lockspire.Web.Components.AdminComponents.workflow_shell
  title="Mint initial access token"
  help="Use short-lived, scoped intake tokens for partner onboarding. Plaintext is not stored or shown again as plaintext."
>
  <%= if @iat_secret do %>
    <Lockspire.Web.Components.AdminComponents.copy_once_secret_panel
      title="Initial access token minted"
      body="Copy this value now. Lockspire stores only the hash after this response."
      label="Initial access token"
      value={@iat_secret}
    />
    <Lockspire.Web.Components.AdminComponents.action_bar>
      <Lockspire.Web.Components.AdminComponents.admin_button phx-click="acknowledge_copy" variant={:primary}>
        I have copied this secret
      </Lockspire.Web.Components.AdminComponents.admin_button>
    </Lockspire.Web.Components.AdminComponents.action_bar>
```

**Form field pattern** (`new.html.heex` lines 28-67):
```elixir
<form phx-submit="mint" class="lockspire-admin-form-stack">
  <Lockspire.Web.Components.AdminComponents.form_field
    id="iat_single_use"
    label="Single use"
    help="Keep partner intake to one registration unless a deliberate multi-use handoff is required."
  >
    <select id="iat_single_use" name="single_use">
      <option value="true" selected={@form["single_use"].value == "true"}>Yes (Recommended)</option>
      <option value="false" selected={@form["single_use"].value == "false"}>No (Multi-use)</option>
    </select>
  </Lockspire.Web.Components.AdminComponents.form_field>

  <Lockspire.Web.Components.AdminComponents.action_bar>
    <Lockspire.Web.Components.AdminComponents.admin_button variant={:primary} type="submit">
      Mint initial access token
    </Lockspire.Web.Components.AdminComponents.admin_button>
    <Lockspire.Web.Components.AdminComponents.admin_button href={iat_index_path()} variant={:secondary}>
      Review initial access tokens
    </Lockspire.Web.Components.AdminComponents.admin_button>
  </Lockspire.Web.Components.AdminComponents.action_bar>
</form>
```

---

### `lib/lockspire/web/live/admin/keys_live/index.ex` (LiveView/controller, key inventory)

**Analog:** `lib/lockspire/web/live/admin/keys_live/index.ex`

**Page hero, metrics, generation actions** (lines 49-75):
```elixir
<AdminLayoutLive.shell current_section={@current_section} page_title={@page_title}>
  <AdminComponents.page_hero
    eyebrow="Configure"
    title="Review key lifecycle"
    body="Review issuer key posture, publication overlap, rollover readiness, and safe lifecycle actions without exposing private key material."
  />

  <AdminComponents.section_card
    title="Key lifecycle posture"
    subtitle="Inspect upcoming, active, retiring, and retired keys without exposing raw status editing."
  >
    <AdminComponents.metric_grid>
      <AdminComponents.summary_stat value={count_keys(@keys, :active)} label="Active" />
      <AdminComponents.summary_stat value={count_keys(@keys, :upcoming)} label="Upcoming" />
      <AdminComponents.summary_stat value={count_keys(@keys, :retiring)} label="Retiring" />
      <AdminComponents.summary_stat value={count_keys(@keys, :retired)} label="Retired" />
      <AdminComponents.summary_stat value={@total_keys} label="Total keys" />
    </AdminComponents.metric_grid>

    <AdminComponents.action_bar class="lockspire-admin-action-bar-compact">
      <AdminComponents.admin_button phx-click="generate" phx-value-use="sig" variant={:primary}>
        Generate signing key
      </AdminComponents.admin_button>
      <AdminComponents.admin_button phx-click="generate" phx-value-use="enc">
        Generate encryption key
      </AdminComponents.admin_button>
    </AdminComponents.action_bar>
```

**Key row pattern** (lines 87-105):
```elixir
<AdminComponents.resource_list>
  <%= for entry <- @keys do %>
    <AdminComponents.resource_item
      href={key_show_path(entry.key.id)}
      title="Review key lifecycle"
      subtitle={"#{entry.key.alg} / #{entry.key.kty}"}
    >
      <:meta>
        <span>Key <AdminComponents.long_value value={entry.key.kid} kind={:id} /></span>
        <span>Use <AdminComponents.long_value value={entry.key.use} kind={:text} /></span>
        <span>Published <AdminComponents.long_value value={format_datetime(entry.key.published_at)} kind={:timestamp} /></span>
        <span>Activated <AdminComponents.long_value value={format_datetime(entry.key.activated_at)} kind={:timestamp} /></span>
        <span>Next action {format_actions(entry.next_actions)}</span>
      </:meta>
      <:status>
        <AdminComponents.status_badge status={entry.key.status} />
        <span class="lockspire-admin-help">JWKS {if entry.publishable, do: "visible", else: "hidden"}</span>
      </:status>
    </AdminComponents.resource_item>
```

---

### `lib/lockspire/web/live/admin/keys_live/show.ex` and `action_component.ex` (LiveView/controller + component, confirmation lifecycle)

**Analog:** `lib/lockspire/web/live/admin/keys_live/show.ex` and `keys_live/action_component.ex`

**Guarded event pattern** (`show.ex` lines 35-62, 96-123):
```elixir
def handle_event("publish_key", %{"publish" => %{"confirm" => "true"}}, socket) do
  case Admin.publish_key(socket.assigns.key_id) do
    {:ok, key_detail} ->
      {:noreply,
       assign(socket,
         key_detail: key_detail,
         action_notice: "Key published for verification overlap.",
         action_error: nil
       )}

    {:error, :already_published} ->
      {:noreply, assign(socket, action_error: "This upcoming key is already published.")}

    {:error, :invalid_state} ->
      {:noreply, assign(socket, action_error: "Only upcoming keys can be published.")}

    {:error, _reason} ->
      {:noreply, assign(socket, action_error: "Key could not be published.")}
  end
end

def handle_event("publish_key", _params, socket) do
  {:noreply,
   assign(socket,
     action_error: "Confirm publish before changing key visibility.",
     action_notice: nil
   )}
end

def handle_event("retire_key", %{"retire" => %{"confirm" => "true"}}, socket) do
  case Admin.retire_key(socket.assigns.key_id) do
    {:ok, key_detail} ->
      {:noreply,
       assign(socket,
         key_detail: key_detail,
         action_notice: "Key retired from publication overlap.",
         action_error: nil
       )}
```

**Detail render pattern** (`show.ex` lines 140-192):
```elixir
<AdminComponents.page_hero
  eyebrow="Configure"
  title="Review key lifecycle"
  body="Review public key metadata, publication state, and lifecycle consequences without exposing private key material."
/>

<AdminComponents.section_card
  title={@key_detail.key.handle}
  subtitle="Key detail shows public metadata, lifecycle truth, and the next safe operator action."
>
  <AdminComponents.description_list>
    <:item label="Status"><AdminComponents.status_badge status={@key_detail.key.status} /></:item>
    <:item label="Key handle">
      <AdminComponents.long_value value={@key_detail.key.handle} kind={:id} />
    </:item>
    <:item label="Database handle">
      <AdminComponents.long_value value={@key_detail.key.database_handle} kind={:id} />
    </:item>
    <:item label="Algorithm"><code>{@key_detail.key.alg}</code></:item>
    <:item label="Key type"><code>{@key_detail.key.kty}</code></:item>
    <:item label="Use"><code>{@key_detail.key.use}</code></:item>
    <:item label="Visible in JWKS"><code>{to_string(@key_detail.publishable)}</code></:item>
  </AdminComponents.description_list>
</AdminComponents.section_card>

<AdminComponents.section_card
  title="Lifecycle actions"
  subtitle="Publish, activate, and retire remain separate commands so rollover state stays truthful."
>
  <ActionComponent.lifecycle_actions
    key_detail={@key_detail}
    action_error={@action_error}
    action_notice={@action_notice}
  />
</AdminComponents.section_card>
```

**Confirmation panel component pattern** (`action_component.ex` lines 66-87):
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
        <span>
          Retire key {@key_detail.key.handle} for {@key_detail.key.use}. This removes the key
          from publication overlap after verifiers have moved off it.
        </span>
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

---

### `lib/lockspire/web/live/admin/policies_live/index.ex` (LiveView/controller, policy navigation)

**Analog:** Current `policies_live/index.ex` for summary loading; `policies_live/dcr.html.heex` for page-first Configure summary.

**Policy nav and manual hero current state** (lines 30-42):
```elixir
<AdminLayoutLive.shell current_section={@current_section} page_title={@page_title}>
  <AdminComponents.policy_nav />

  <section class="lockspire-admin-hero">
    <div>
      <p class="lockspire-admin-eyebrow">Security policy</p>
      <h2>Issuer posture, override pressure, and registration gates in one place.</h2>
      <p>
        Use this landing page to decide which detailed policy workflow to enter. Each
        policy remains its own explicit operator action surface.
      </p>
    </div>
  </section>
```

**Phase 124 replacement direction:** use `AdminComponents.page_hero` with eyebrow `Configure`, and keep `policy_nav`. Do not add a new route.

**Policy card pattern and generic CTA to replace** (lines 45-87):
```elixir
<.policy_card
  title="PAR"
  value={@policy.par_policy}
  detail={"#{@summary.par.required} clients require PAR; #{@summary.par.optional} mark it optional."}
  href={admin_path("/policies/par")}
/>

defp policy_card(assigns) do
  ~H"""
  <AdminComponents.section_card title={@title} subtitle={@detail}>
    <p class="lockspire-admin-kicker">Current setting</p>
    <p class="lockspire-admin-display-value">{@value}</p>
    <AdminComponents.action_bar>
      <AdminComponents.admin_button href={@href}>Open workflow</AdminComponents.admin_button>
    </AdminComponents.action_bar>
  </AdminComponents.section_card>
  """
end
```

**Phase 124 copy replacements:** `Review PAR policy`, `Review security profile`, `Review DPoP policy`, `Review DCR policy`.

---

### Policy form pages: `par.ex`, `dpop.ex`, `security_profile.ex`, `dcr.ex`, `dcr.html.heex`

**Analog:** `policies_live/dcr.ex` and `policies_live/dcr.html.heex` are the strongest global policy pattern.

**Policy save event pattern** (`dcr.ex` lines 29-61):
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

      {:error, errors} when is_list(errors) ->
        {:noreply, assign(socket, form_errors: errors)}

      {:error, _reason} ->
        {:noreply,
         assign(socket,
           form_errors: [%{field: :registration_policy, reason: :request_failed, detail: nil}]
         )}
    end
  else
    errors = format_changeset_errors(changeset)
    {:noreply, assign(socket, form_errors: errors)}
  end
end
```

**Decision summary pattern** (`dcr.html.heex` lines 2-39):
```elixir
<Lockspire.Web.Components.AdminComponents.page_hero
  eyebrow="Configure"
  title="Global DCR policy"
  body={"Current mode is #{@policy.registration_policy}. Decide who can self-register and what metadata future DCR requests may ask Lockspire to store."}
>
  <:summary>
    <Lockspire.Web.Components.AdminComponents.decision_summary>
      <:item
        label="Registration gate"
        value={registration_policy_label(@policy.registration_policy)}
        tone={registration_policy_tone(@policy.registration_policy)}
        detail={registration_policy_detail(@policy.registration_policy)}
      >
      </:item>
      <:item label="Metadata allowlists" value={allowlist_summary(@policy)} tone={:info} detail="Scopes, grants, responses, redirect schemes, and hosts bound requested metadata.">
      </:item>
      <:item label="Token auth methods" value={auth_methods_summary(@policy)} tone={:info} detail="This allowlist controls what self-registered clients may request.">
      </:item>
      <:item label="Default lifetimes" value={lifetime_summary(@policy)} tone={:info} detail="Applies only to clients and credentials created through DCR.">
      </:item>
    </Lockspire.Web.Components.AdminComponents.decision_summary>
  </:summary>
</Lockspire.Web.Components.AdminComponents.page_hero>
```

**Grouped workflow-shell form pattern** (`dcr.html.heex` lines 43-72, 183-199):
```elixir
<Lockspire.Web.Components.AdminComponents.section_card
  title="Edit future registration policy"
  subtitle={"Current mode is #{@policy.registration_policy}. This save changes future Dynamic Client Registration requests only; existing client records keep their stored configuration."}
>
  <Lockspire.Web.Components.AdminComponents.error_list :if={@form_errors != []} errors={@form_errors} />

  <form class="lockspire-admin-form-stack" phx-submit="save_policy">
    <Lockspire.Web.Components.AdminComponents.workflow_shell
      title="Registration gate"
      help="Choose how issuer registration requests are admitted before any client metadata is accepted."
    >
      ...
    </Lockspire.Web.Components.AdminComponents.workflow_shell>

    <Lockspire.Web.Components.AdminComponents.workflow_shell
      title="Risk and posture"
      help="Review what this issuer policy changes before saving."
    >
      <p class="lockspire-admin-help">
        This form updates global issuer policy for future Dynamic Client Registration requests. It does not mint Initial Access Tokens, rotate registration access tokens, update existing client records, or create credential material.
      </p>
    </Lockspire.Web.Components.AdminComponents.workflow_shell>

    <Lockspire.Web.Components.AdminComponents.action_bar>
      <Lockspire.Web.Components.AdminComponents.admin_button type="submit" variant={:primary}>
        Save global DCR policy
      </Lockspire.Web.Components.AdminComponents.admin_button>
    </Lockspire.Web.Components.AdminComponents.action_bar>
  </form>
```

**Helper label/tone pattern** (`dcr.ex` lines 96-114):
```elixir
defp registration_policy_label(:disabled), do: "Disabled"
defp registration_policy_label(:initial_access_token), do: "IAT-gated"
defp registration_policy_label(:open), do: "Open registration"
defp registration_policy_label(value), do: value |> to_string() |> String.replace("_", " ")

defp registration_policy_tone(:disabled), do: :neutral
defp registration_policy_tone(:initial_access_token), do: :success
defp registration_policy_tone(:open), do: :warning
defp registration_policy_tone(_value), do: :info

defp registration_policy_detail(:disabled), do: "No new clients can self-register."
defp registration_policy_detail(:initial_access_token),
  do: "Partners need a valid intake token before metadata is accepted."
defp registration_policy_detail(:open),
  do: "Unauthenticated registration is allowed; keep allowlists and lifetimes narrow."
```

**PAR/DPoP/security existing save patterns to keep:** `par.ex` lines 33-49, `dpop.ex` lines 34-50, and `security_profile.ex` lines 36-53 all use `Admin`/`AdminServerPolicy`, `form_errors`, and route-local summaries. Add `page_hero`/summary only where it improves posture clarity.

## Shared Patterns

### Existing Admin Router Boundary

**Source:** `lib/lockspire/web/admin_router.ex` lines 13-85

**Apply to:** all route and test planning. Do not add routes.

```elixir
scope "/" do
  live("/", Lockspire.Web.Live.Admin.OverviewLive.Index, :index)
  live("/overview", Lockspire.Web.Live.Admin.OverviewLive.Index, :index)
  live("/clients", Lockspire.Web.Live.Admin.ClientsLive.Index, :index)
  live("/clients/:client_id", Lockspire.Web.Live.Admin.ClientsLive.Show, :show)
  ...
  live("/iats", Lockspire.Web.Live.Admin.IatLive.Index, :index)
  live("/iats/new", Lockspire.Web.Live.Admin.IatLive.New, :new)
  ...
  live("/clients/:client_id/edit", Lockspire.Web.Live.Admin.ClientsLive.Show, :edit)
  ...
  live("/clients/:client_id/rotate-registration-access-token", Lockspire.Web.Live.Admin.ClientsLive.Show, :rotate_registration_access_token)
  live("/dcr", Lockspire.Web.Live.Admin.DcrLive.Index, :index)
  live("/policies", Lockspire.Web.Live.Admin.PoliciesLive.Index, :index)
  live("/policies/par", Lockspire.Web.Live.Admin.PoliciesLive.Par, :show)
  live("/policies/security-profile", Lockspire.Web.Live.Admin.PoliciesLive.SecurityProfile, :show)
  live("/policies/dpop", Lockspire.Web.Live.Admin.PoliciesLive.Dpop, :show)
  live("/policies/dcr", Lockspire.Web.Live.Admin.PoliciesLive.Dcr, :show)
end
```

### Existing Admin API Boundary

**Source:** `lib/lockspire/admin.ex` lines 20-119 and 177-215

**Apply to:** all Configure mutations. Do not broaden Admin/public APIs.

```elixir
defdelegate list_clients(opts \\ []), to: Clients
defdelegate get_client(client_id), to: Clients
defdelegate create_client(attrs), to: Clients
defdelegate update_client(client_id, attrs), to: Clients
defdelegate rotate_client_secret(client_id, attrs \\ %{}), to: Clients
defdelegate disable_client(client_id, attrs \\ %{}), to: Clients
defdelegate enable_client(client_id, attrs \\ %{}), to: Clients

defdelegate get_server_policy(), to: ServerPolicy
defdelegate put_server_policy(mode), to: ServerPolicy
defdelegate put_dpop_policy(mode), to: ServerPolicy
defdelegate put_security_profile(profile), to: ServerPolicy
defdelegate get_dcr_policy(), to: ServerPolicy
defdelegate put_dcr_policy(attrs), to: ServerPolicy

defdelegate list_keys(opts \\ []), to: Keys
defdelegate get_key(key_id), to: Keys
defdelegate generate_key(use \\ :sig), to: Keys
defdelegate publish_key(key_id, attrs \\ %{}), to: Keys
defdelegate activate_key(key_id, attrs \\ %{}), to: Keys
defdelegate retire_key(key_id, attrs \\ %{}), to: Keys
```

### AdminComponents Primitives

**Source:** `lib/lockspire/web/components/admin_components.ex`

**Apply to:** all touched Configure LiveViews/templates.

**Page hero** (lines 50-72):
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

**Decision summary** (lines 188-209):
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

**Dense row, copy-once, long value, action group, confirmation panel** (lines 445-607):
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

def action_group(assigns) do
  ~H"""
  <div class={["lockspire-admin-action-group", @class]}>
    <div :if={@primary != []} class="lockspire-admin-action-group__primary">{render_slot(@primary)}</div>
    <div :if={@secondary != []} class="lockspire-admin-action-group__secondary">{render_slot(@secondary)}</div>
    <div :if={@destructive != []} class="lockspire-admin-action-group__destructive">{render_slot(@destructive)}</div>
  </div>
  """
end

def confirmation_panel(assigns) do
  assigns = assign(assigns, :class, confirmation_panel_class(assigns.variant))

  ~H"""
  <section class={@class}>
    <header><h3>{@title}</h3></header>
    <div class="lockspire-admin-confirmation-panel__body">{render_slot(@body)}</div>
    <.error_list errors={@errors} />
    <div :if={@actions != []} class="lockspire-admin-confirmation-panel__actions">
      {render_slot(@actions)}
    </div>
  </section>
  """
end
```

### IAT Copy-Once Secret Generation

**Source:** `lib/lockspire/admin/initial_access_tokens.ex` lines 16-32

**Apply to:** IAT minting tests/UI; plaintext appears only in immediate create result.

```elixir
@spec mint_iat(map()) :: {:ok, InitialAccessToken.t(), String.t()} | {:error, term()}
def mint_iat(attrs \\ %{}) do
  plaintext_secret = :crypto.strong_rand_bytes(32) |> Base.url_encode64(padding: false)
  token_hash = Policy.hash_token(plaintext_secret)

  iat = %InitialAccessToken{
    token_hash: token_hash,
    expires_at: Map.get(attrs, :expires_at),
    single_use: Map.get(attrs, :single_use, true),
    policy_overrides: Map.get(attrs, :policy_overrides),
    created_by: Map.get(attrs, :created_by, "operator")
  }

  with {:ok, saved_iat} <- Repository.save_initial_access_token(iat) do
    Observability.emit(:iat, :mint, %{count: 1}, %{iat_id: saved_iat.id})
    {:ok, saved_iat, plaintext_secret}
  end
end
```

### Redacted Handles

**Source:** `lib/lockspire/redaction.ex` lines 183-192 and `iat_live/index.ex` lines 71-72

**Apply to:** durable IAT/client/token handles in UI/tests. Do not render secret hashes.

```elixir
@spec handle(atom(), term()) :: String.t()
def handle(type, value) when is_atom(type) do
  encoded =
    value
    |> normalize_scalar()
    |> then(&:crypto.hash(:sha256, &1))
    |> Base.encode16(case: :lower)
    |> binary_part(0, 12)

  "#{type}_#{encoded}"
end

def redacted_handle(_type, nil), do: "Not recorded"
def redacted_handle(type, value), do: Redaction.handle(type, value)
```

### Rendered HTML Assertion Helpers

**Source:** `test/support/lockspire/web/admin_proof/html_assertions.ex`

**Apply to:** all focused LiveView tests touched by Phase 124.

**Accessibility and structure assertions** (lines 16-64, 66-98):
```elixir
def assert_no_duplicate_ids(html) do
  ids =
    html
    |> document()
    |> LazyHTML.query("[id]")
    |> LazyHTML.attribute("id")
    |> Enum.reject(&(&1 == ""))

  duplicates =
    ids
    |> Enum.frequencies()
    |> Enum.filter(fn {_id, count} -> count > 1 end)

  assert duplicates == [],
         "expected rendered HTML to have unique IDs, found duplicates: #{inspect(duplicates)}"

  html
end

def assert_describedby_targets_exist(html) do
  assert_aria_targets_exist(html, "aria-describedby")
end

def assert_label_targets_exist(html) do
  doc = document(html)
  id_set = id_set(doc)

  label_targets =
    doc
    |> LazyHTML.query("label[for]")
    |> LazyHTML.attribute("for")
    |> Enum.reject(&(&1 == ""))

  assert label_targets != [], "expected rendered HTML to include explicit label[for] targets"
  ...
end
```

**Copy/secret denial assertions** (lines 153-184):
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

### Focused LiveView Test Patterns

**Source:** `test/lockspire/web/live/admin/iat_live_test.exs`

**IAT inventory and revoke proof pattern** (lines 49-93):
```elixir
test "renders DCR onboarding inventory context and allows guarded revocation" do
  {:ok, iat, secret} =
    InitialAccessTokens.mint_iat(%{
      single_use: true,
      created_by: "test",
      expires_at: DateTime.add(DateTime.utc_now(), 30, :day)
    })

  {:ok, view, html} = live(conn_for_admin(), "/admin/iats")

  HtmlAssertions.assert_no_duplicate_ids(html)
  HtmlAssertions.assert_describedby_targets_exist(html)
  HtmlAssertions.assert_no_generic_cta_text(html)
  HtmlAssertions.assert_has_link(html, "/admin/iats/new")
  HtmlAssertions.assert_no_text(html, [secret | forbidden_secret_samples()])

  assert html =~ "Configure"
  assert html =~ "Initial access token inventory"
  assert html =~ "Review initial access tokens"
  ...
  refute html =~ secret

  view
  |> element("button[phx-click=\"revoke\"][phx-value-id=\"#{iat.id}\"]")
  |> render_click()

  html_after_revoke = render(view)
  refute html_after_revoke =~ "Revoke initial access token</button>"
end
```

**IAT copy-once proof pattern** (lines 97-151):
```elixir
test "minting an IAT uses copy-once panel and clearing removes plaintext" do
  {:ok, view, _html} = live(conn_for_admin(), "/admin/iats/new")

  initial_html = render(view)
  HtmlAssertions.assert_no_duplicate_ids(initial_html)
  HtmlAssertions.assert_describedby_targets_exist(initial_html)
  HtmlAssertions.assert_label_targets_exist(initial_html)
  HtmlAssertions.assert_no_generic_cta_text(initial_html)
  HtmlAssertions.assert_no_text(initial_html, forbidden_secret_samples())

  html_after_mint =
    view
    |> element("form")
    |> render_submit(%{"single_use" => "true", "expires_in_days" => "30"})

  assert html_after_mint =~ "Initial access token minted"
  assert html_after_mint =~ "lockspire-admin-copy-once-secret"
  assert html_after_mint =~ "I have copied this secret"

  [_, plaintext] = Regex.run(~r/<code[^>]*>(?<plaintext>[^<]+)<\/code>/, html_after_mint)

  html_after_ack =
    view
    |> element("button[phx-click=\"acknowledge_copy\"]")
    |> render_click()

  HtmlAssertions.assert_no_text(html_after_ack, [plaintext | forbidden_secret_samples()])
  refute html_after_ack =~ "Initial access token minted"
  refute html_after_ack =~ plaintext
end
```

**Source:** `test/lockspire/web/live/admin/clients_live/show_test.exs`

**Client page hierarchy and action grouping proof** (lines 179-254):
```elixir
test "client detail groups routine, credential, endpoint, posture, and lifecycle actions", %{client: client} do
  ...
  assert html =~ "lockspire-admin-entity-header"
  assert html =~ "lockspire-admin-pane"
  assert html =~ "lockspire-admin-status-cluster"
  assert html =~ "lockspire-admin-long-value"

  for group <- [
        "Identity and current status",
        "Effective posture",
        "Credentials and assertion keys",
        "Endpoints and logout",
        "DCR and RAT context",
        "Support pivots",
        "Lifecycle and destructive actions"
      ] do
    assert html =~ group
  end

  assert html =~ "lockspire-admin-action-group"
  assert html =~ "Rotate client secret"
  assert html =~ "Rotate registration access token"
  assert html =~ "Review DCR onboarding"
  assert html =~ ~s(phx-submit="toggle_client")
  assert html =~ ~s(name="toggle[confirm]")
  assert html =~ "Confirm client disable"
  refute html =~ "sha256:show:hash"
  refute html =~ "client_secret_hash"
end
```

**Client lifecycle confirmation proof** (lines 256-276):
```elixir
test "client lifecycle changes require explicit confirmation", %{client: client} do
  assert {:ok, view, html} = live(conn_for_admin(), "/admin/clients/#{client.client_id}")

  assert html =~ "Confirm client disable"

  html_without_confirm =
    view
    |> form("form[phx-submit=toggle_client]", %{toggle: %{}})
    |> render_submit()

  assert html_without_confirm =~ "confirm this lifecycle change"
  assert {:ok, unchanged_client} = Admin.get_client(client.client_id)
  assert unchanged_client.active

  view
  |> form("form[phx-submit=toggle_client]", %{toggle: %{confirm: "true"}})
  |> render_submit()

  assert {:ok, disabled_client} = Admin.get_client(client.client_id)
  refute disabled_client.active
end
```

**Source:** `test/lockspire/web/live/admin/keys_live_test.exs`

**Key lifecycle proof pattern** (lines 48-71, 73-123):
```elixir
test "key index renders lifecycle states and shared admin navigation" do
  assert {:ok, socket} = Index.mount(%{}, %{}, socket_for(:index))
  assert {:noreply, socket} = Index.handle_params(%{}, "/lockspire/admin/keys", socket)

  html = rendered_to_string(Index.render(socket.assigns))

  assert html =~ "Configure"
  assert html =~ "Review key lifecycle"
  assert html =~ "Key lifecycle posture"
  assert html =~ "lockspire-admin-resource-list__item"
  assert html =~ "lockspire-admin-long-value"
  assert html =~ "JWKS visible"
  assert html =~ "JWKS hidden"
end

test "key detail exposes only guided actions and advances lifecycle", %{active_key: active_key, upcoming_key: upcoming_key} do
  ...
  assert html =~ "Publish key"
  assert html =~ "verification overlap"
  assert html =~ "signing or encryption cutover"
  refute html =~ "Retire key"

  assert {:noreply, socket} =
           Show.handle_event("publish_key", %{"publish" => %{"confirm" => "true"}}, socket)

  assert socket.assigns.action_notice == "Key published for verification overlap."

  assert {:noreply, socket} = Show.handle_event("activate_key", %{}, socket)
  assert socket.assigns.action_error =~ "Confirm activation before changing the active signer."

  assert {:noreply, socket} =
           Show.handle_event("activate_key", %{"activate" => %{"confirm" => "true"}}, socket)

  assert socket.assigns.key_detail.key.status == :active
  assert {:ok, retiring_key} = Repository.fetch_signing_key_by_id(active_key.id)
  assert retiring_key.status == :retiring
end
```

**Source:** `test/lockspire/web/live/admin/policies_live/dcr_test.exs`

**Policy form and validation proof pattern** (lines 62-106, 140-174):
```elixir
test "global DCR policy page renders one grouped workflow form with unchanged fields" do
  assert {:ok, _view, html} = live(conn_for_admin(), "/admin/policies/dcr")

  HtmlAssertions.assert_no_duplicate_ids(html)
  HtmlAssertions.assert_describedby_targets_exist(html)
  HtmlAssertions.assert_label_targets_exist(html)
  HtmlAssertions.assert_no_generic_cta_text(html)
  HtmlAssertions.assert_no_text(html, forbidden_secret_samples())

  assert occurrence_count(html, ~s(phx-submit="save_policy")) == 1
  assert html =~ "Save global DCR policy"
  ...
  assert occurrence_count(html, "lockspire-admin-workflow-shell") >= 5
  assert html =~ "private_key_jwt posture"
  assert html =~ "client_secret_jwt posture"
end

test "saving global DCR policy persists change" do
  ...
  view
  |> form("form[phx-submit=save_policy]", %{
    policy: %{
      registration_policy: "open",
      dcr_allowed_scopes: "openid, email",
      dcr_allowed_token_endpoint_auth_methods: "private_key_jwt, client_secret_basic"
    }
  })
  |> render_submit()

  assert {:ok, policy} = ServerPolicy.get_server_policy()
  assert policy.registration_policy == :open
end

test "invalid input shows form errors" do
  ...
  assert html =~ "must be greater than or equal to 0"
end
```

### Source Contract Test Patterns

**Source:** `test/lockspire/web/live/admin/design_system_contract_test.exs`

**Route boundary/source truth** (lines 517-640):
```elixir
test "phase 121 route scorecards cover AdminRouter route truth" do
  scorecards = phase_121_scorecards()

  assert Map.keys(scorecards) |> Enum.sort() == RouteScorecards.expected_routes()
  assert length(RouteScorecards.expected_routes()) == 29

  assert RouteScorecards.workflow_exceptions() == [
           "/admin/clients/:client_id/edit?workflow=logout-propagation"
         ]
end

test "phase 121 scorecards preserve support boundary and deny public surface creep" do
  markdown = phase_121_scorecards_markdown()
  scorecards = RouteScorecards.parse!(markdown)
  operator_doc = File.read!(@operator_admin_doc_path)
  supported_surface = File.read!(@supported_surface_doc_path)
  router = File.read!(@admin_router_path)
  mix = File.read!(@mix_path)

  for {_route, fields} <- scorecards do
    assert fields["Public support promise"] == RouteScorecards.support_promise()
    assert fields["Runtime/package impact"] =~
             "no router, runtime, browser package, docs support-surface, or Hex package change"
  end

  for forbidden <- ["component_lab", "design_system_lab", "scorecard", "storybook"] do
    refute String.downcase(router) =~ forbidden
  end
end
```

**Primitive adoption and generic CTA fences** (lines 1123-1210):
```elixir
for path <- [
      Path.expand("../../../../../lib/lockspire/web/live/admin/dcr_live/index.ex", __DIR__),
      Path.expand("../../../../../lib/lockspire/web/live/admin/iat_live/index.html.heex", __DIR__),
      Path.expand("../../../../../lib/lockspire/web/live/admin/iat_live/new.html.heex", __DIR__),
      Path.expand("../../../../../lib/lockspire/web/live/admin/keys_live/index.ex", __DIR__),
      Path.expand("../../../../../lib/lockspire/web/live/admin/keys_live/show.ex", __DIR__),
      Path.expand("../../../../../lib/lockspire/web/live/admin/clients_live/show.ex", __DIR__)
    ] do
  assert File.read!(path) =~ "Configure"
end

assert source_for("iat_live/new.html.heex") =~
         "Lockspire.Web.Components.AdminComponents.copy_once_secret_panel"

assert source_for("clients_live/show.ex") =~ "AdminComponents.action_group"
assert source_for("keys_live/action_component.ex") =~ "AdminComponents.confirmation_panel"

refute Regex.match?(
         ~r/(?:^|>|\n)\s*(Apply|Submit|OK|Cancel|Open|Revoke|Mint IAT|Rotate secret|Rotate RAT)\s*(?:<|\n|$)/,
         sources
       )

assert source_for("iat_live/index.html.heex") =~ "data-confirm="
assert source_for("iat_live/index.html.heex") =~ "Revoke initial access token"
assert source_for("clients_live/show.ex") =~ "AdminComponents.confirmation_panel"
```

**Phase 124 source-contract direction:** once IAT revoke is migrated to inline confirmation, update the `data-confirm=` expectation above to reject `data-confirm` on touched Configure destructive actions and require `AdminComponents.confirmation_panel`.

**Phase 119 source inventory pattern** (lines 1220-1295):
```elixir
test "phase 119 source inventory covers touched routes and shared primitive adoption" do
  for suffix <- [
        "clients_live/show.ex",
        "policies_live/dcr.html.heex",
        "iat_live/index.html.heex",
        "iat_live/new.html.heex",
        "tokens_live/show.ex",
        "consents_live/show.ex",
        "device_authorizations_live/index.ex",
        "interactions_live/index.ex",
        "logout_deliveries_live/index.ex"
      ] do
    assert source_for_phase_119(suffix)
  end

  client = source_for_phase_119("clients_live/show.ex")

  for primitive <- [
        "AdminComponents.entity_header",
        "AdminComponents.pane",
        "AdminComponents.action_group",
        "AdminComponents.long_value"
      ] do
    assert client =~ primitive
  end

  for copy <- [
        "Identity and current status",
        "Effective posture",
        "Credentials and assertion keys",
        "Endpoints and logout",
        "DCR and RAT context",
        "Support pivots",
        "Lifecycle and destructive actions"
      ] do
    assert client =~ copy
  end
```

**Component primitive source contracts** (lines 1539-1562):
```elixir
test "operate row components keep visible status text and wrapped long values" do
  components = File.read!(@admin_components_path)

  dense_row = component_declaration_block(components, "dense_resource_row")
  status_badge = component_declaration_block(components, "status_badge")
  long_value = component_declaration_block(components, "long_value")

  for slot <- ["slot(:meta)", "slot(:status)", "slot(:actions)"] do
    assert dense_row =~ slot
  end

  assert dense_row =~ "lockspire-admin-dense-resource-row__main"
  assert dense_row =~ "lockspire-admin-dense-resource-row__meta"
  assert dense_row =~ "render_slot(@status)"
  assert status_badge =~ "{@label}"
  assert status_badge =~ "data-status-tone"
  assert status_badge =~ "title={@title_text}"
  assert long_value =~ "{@value}"
  assert long_value =~ "Redacted"
  assert long_value =~ "lockspire-admin-redacted-value"
end
```

**Router parser helper** (lines 2542-2550):
```elixir
defp mounted_admin_routes(router_source) do
  ~r/live\(\s*"([^"]+)"/
  |> Regex.scan(router_source, capture: :all_but_first)
  |> List.flatten()
  |> Enum.map(&mounted_admin_route/1)
end

defp mounted_admin_route("/"), do: "/admin"
defp mounted_admin_route(route), do: "/admin" <> route
```

## No Analog Found

None. Every Phase 124 source/test target has an existing local analog. If a planner proposes a new Configure meta-component, treat that as unapproved unless it proves unavoidable duplication, remains internal, and is covered by source contracts.

## Metadata

**Analog search scope:** `lib/lockspire/web/live/admin`, `lib/lockspire/web/components`, `lib/lockspire/web/admin_router.ex`, `lib/lockspire/admin.ex`, `lib/lockspire/admin/initial_access_tokens.ex`, `lib/lockspire/redaction.ex`, `test/lockspire/web/live/admin`, `test/support/lockspire/web/admin_proof`.

**Files scanned:** 35 admin source/test/helper files from `rg --files`, plus Admin API and Redaction helpers.

**Primary analogs:** `clients_live/show.ex`, `keys_live/action_component.ex`, `iat_live/new.ex`, `iat_live/index.html.heex`, `dcr_live/index.ex`, `policies_live/dcr.html.heex`, `design_system_contract_test.exs`, `iat_live_test.exs`, `clients_live/show_test.exs`, `keys_live_test.exs`.

**Pattern extraction date:** 2026-06-29
