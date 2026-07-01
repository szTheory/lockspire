# Phase 118: Primitive & Meta-Component Upgrade - Pattern Map

**Mapped:** 2026-06-25
**Files analyzed:** 14
**Analogs found:** 14 / 14

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/lockspire/web/components/admin_components.ex` | component | transform | `lib/lockspire/web/components/admin_components.ex` | exact |
| `lib/lockspire/web/admin_css.ex` | config | transform | `lib/lockspire/web/admin_css.ex` | exact |
| `test/support/lockspire/web/admin_lab/fixtures.ex` | test utility | transform | `test/support/lockspire/web/admin_lab/fixtures.ex` | exact |
| `test/support/lockspire/web/admin_lab/stress_surface.ex` | test component | transform | `test/support/lockspire/web/admin_lab/stress_surface.ex` | exact |
| `test/lockspire/web/live/admin/design_system_component_stress_test.exs` | test | transform | `test/lockspire/web/live/admin/design_system_component_stress_test.exs` | exact |
| `test/lockspire/web/live/admin/design_system_contract_test.exs` | test | file-I/O | `test/lockspire/web/live/admin/design_system_contract_test.exs` | exact |
| `lib/lockspire/web/live/admin/clients_live/form_component.ex` | component | request-response | `lib/lockspire/web/live/admin/clients_live/form_component.ex` | exact |
| `lib/lockspire/web/live/admin/policies_live/dcr.html.heex` | component template | request-response | `lib/lockspire/web/live/admin/policies_live/dcr.html.heex` | exact |
| `lib/lockspire/web/live/admin/tokens_live/index.ex` | component | request-response | `lib/lockspire/web/live/admin/tokens_live/index.ex` | exact |
| `lib/lockspire/web/live/admin/consents_live/index.ex` | component | request-response | `lib/lockspire/web/live/admin/consents_live/index.ex` | exact |
| `lib/lockspire/web/live/admin/tokens_live/show.ex` | component | request-response | `lib/lockspire/web/live/admin/tokens_live/show.ex` | exact |
| `lib/lockspire/web/live/admin/clients_live/show.ex` | component | request-response | `lib/lockspire/web/live/admin/clients_live/show.ex` | exact |
| `lib/lockspire/web/live/admin/keys_live/action_component.ex` | component | request-response | `lib/lockspire/web/live/admin/keys_live/action_component.ex` | exact |
| `lib/lockspire/web/live/admin/device_authorizations_live/index.ex`, `interactions_live/index.ex`, `logout_deliveries_live/index.ex` | component | request-response | same files | exact |

## Pattern Assignments

### `lib/lockspire/web/components/admin_components.ex` (component, transform)

**Analog:** `lib/lockspire/web/components/admin_components.ex`

**Imports and component declaration pattern** (lines 1-7):
```elixir
defmodule Lockspire.Web.Components.AdminComponents do
  @moduledoc false

  use Phoenix.Component

  attr(:status, :atom, required: true)
```

**Slot-based structural component pattern** (lines 35-57):
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

**Form-field chrome pattern** (lines 160-188):
```elixir
attr(:id, :string, required: true)
attr(:label, :string, required: true)
attr(:help, :string, default: nil)
attr(:errors, :list, default: [])
attr(:required, :boolean, default: false)
attr(:class, :string, default: "")
slot(:inner_block, required: true)

def form_field(assigns) do
  assigns =
    assigns
    |> assign(:help_id, "#{assigns.id}-help")
    |> assign(:error_id, "#{assigns.id}-error")

  ~H"""
  <div class={["lockspire-admin-field", @errors != [] && "lockspire-admin-field-error", @class]}>
    <label for={@id}>
      {@label}
      <span :if={@required} aria-hidden="true" class="lockspire-admin-required-marker">*</span>
    </label>
    <p :if={@help} id={@help_id} class="lockspire-admin-help">{@help}</p>
    {render_slot(@inner_block)}
    <ul :if={@errors != []} id={@error_id} class="lockspire-admin-field-errors">
```

**Resource row and status cluster pattern** (lines 273-299):
```elixir
attr(:href, :string, default: nil)
attr(:title, :string, required: true)
attr(:subtitle, :string, default: nil)
attr(:class, :string, default: "")
slot(:meta)
slot(:status)
slot(:actions)

def resource_item(assigns) do
  ~H"""
  <li class={["lockspire-admin-resource-list__item", @class]}>
    <div class="lockspire-admin-resource-list__main">
      <a :if={@href} href={@href} class="lockspire-admin-resource-list__title">{@title}</a>
      <strong :if={!@href} class="lockspire-admin-resource-list__title">{@title}</strong>
      <span :if={@subtitle} class="lockspire-admin-resource-list__subtitle">{@subtitle}</span>
    </div>
    <div :if={@meta != []} class="lockspire-admin-resource-list__meta">
      {render_slot(@meta)}
    </div>
    <div :if={@status != []} class="lockspire-admin-status-cluster">
```

**Workflow/action pattern** (lines 342-359, 373-395):
```elixir
attr(:class, :string, default: "")
slot(:primary)
slot(:secondary)
slot(:destructive)

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

**Status helper pattern to replace/extend** (lines 451-476):
```elixir
defp badge_class(:active), do: "lockspire-admin-badge lockspire-admin-badge-active"
defp badge_class(:upcoming), do: "lockspire-admin-badge lockspire-admin-badge-info"
defp badge_class(:retiring), do: "lockspire-admin-badge lockspire-admin-badge-warning"
defp badge_class(:retired), do: "lockspire-admin-badge lockspire-admin-badge-disabled"
defp badge_class(:revoked), do: "lockspire-admin-badge lockspire-admin-badge-danger"
defp badge_class(:expired), do: "lockspire-admin-badge lockspire-admin-badge-disabled"
defp badge_class(:reuse_detected), do: "lockspire-admin-badge lockspire-admin-badge-danger"
defp badge_class(_other), do: "lockspire-admin-badge lockspire-admin-badge-disabled"

defp badge_label(:active), do: "Active"
defp badge_label(:upcoming), do: "Upcoming"
defp badge_label(:retiring), do: "Retiring"
defp badge_label(:retired), do: "Retired"
defp badge_label(:disabled), do: "Disabled"
defp badge_label(:revoked), do: "Revoked"
defp badge_label(:expired), do: "Expired"
defp badge_label(:reuse_detected), do: "Reuse detected"
```

**Planner note:** keep existing `status_badge/1` API, add optional `domain` or `context` attr, and replace scattered `badge_class/1` / `badge_label/1` decisions with one metadata helper returning label, tone, cue/title. Disabled fallback should remain only for unknown values.

### `lib/lockspire/web/admin_css.ex` (config, transform)

**Analog:** `lib/lockspire/web/admin_css.ex`

**Token and semantic alias pattern** (lines 4-14, 91-114):
```elixir
@css """
/* Lockspire Admin UI - Design Tokens & BEM Architecture */
:root {
  color-scheme: light;

  /* Spacing Scale (4px baseline) */
  --ls-space-1: 0.25rem;
  --ls-space-2: 0.5rem;
  --ls-space-3: 0.75rem;
  --ls-space-4: 1rem;
```

```css
--ls-surface-page: var(--ls-color-gray-50);
--ls-surface-panel: #ffffff;
--ls-surface-muted: var(--ls-color-gray-100);
--ls-surface-inverse: var(--ls-color-gray-950);
--ls-text-strong: var(--ls-color-gray-950);
--ls-text-body: var(--ls-color-gray-700);
--ls-text-muted: var(--ls-color-gray-500);
--ls-text-accent: var(--ls-color-brand-600);
--ls-border-subtle: var(--ls-color-gray-200);
--ls-border-strong: var(--ls-color-gray-300);
--ls-status-success-bg: var(--ls-color-success-bg);
--ls-status-success-text: var(--ls-color-success-text);
--ls-status-success-border: var(--ls-color-success-border);
```

**Badge semantics and non-color cue pattern** (lines 395-441):
```css
.lockspire-admin-badge {
  display: inline-flex;
  align-items: center;
  border: 1px solid currentColor;
  gap: var(--ls-space-2);
  padding: 0.125rem 0.625rem;
  border-radius: 9999px;
  font-size: 0.75rem;
  font-weight: 600;
  line-height: 1.25rem;
  white-space: nowrap;
}

.lockspire-admin-badge::before {
  background: currentColor;
  border-radius: 9999px;
  content: "";
  display: inline-block;
  height: 0.45rem;
  width: 0.45rem;
}
```

**Form/error/accessibility CSS pattern** (lines 652-763, 821-850):
```css
.lockspire-admin-field {
  display: flex;
  flex-direction: column;
  gap: var(--ls-space-2);
}

.lockspire-admin-field input:focus-visible,
.lockspire-admin-field select:focus-visible,
.lockspire-admin-field textarea:focus-visible {
  outline: none;
  border-color: var(--ls-focus-ring-color);
  box-shadow: var(--ls-focus-ring-shadow);
}

.lockspire-admin-field-error input,
.lockspire-admin-field-error select,
.lockspire-admin-field-error textarea,
.lockspire-admin-field input[aria-invalid="true"],
.lockspire-admin-field select[aria-invalid="true"],
.lockspire-admin-field textarea[aria-invalid="true"] {
  border-color: var(--ls-status-danger-border);
  box-shadow: 0 0 0 1px var(--ls-status-danger-border);
}
```

**Responsive action/resource pattern** (lines 933-957, 1082-1167, 1374-1488):
```css
.lockspire-admin-action-group {
  align-items: center;
  display: flex;
  flex-wrap: wrap;
  gap: var(--ls-space-3);
  max-width: 100%;
  min-width: 0;
}

.lockspire-admin-action-group__destructive {
  border-left: 1px solid var(--ls-status-danger-border);
  margin-left: var(--ls-space-1);
  padding-left: var(--ls-space-3);
}
```

```css
.lockspire-admin-resource-list__meta,
.lockspire-admin-resource-list__actions,
.lockspire-admin-badge-group,
.lockspire-admin-status-cluster {
  align-items: center;
  display: flex;
  flex-wrap: wrap;
  gap: var(--ls-space-2);
}
```

**Dark/system theme pattern** (lines 1509-1570):
```elixir
# Dark mode mirrors the brandbook: primitives remain stable and only semantic
# aliases remap. Components consume aliases so theme changes do not require
# component-specific overrides.
@dark_vars """
  color-scheme: dark;

  --ls-surface-page: var(--ls-color-gray-950);
  --ls-surface-panel: #131c2e;
```

### `test/support/lockspire/web/admin_lab/fixtures.ex` (test utility, transform)

**Analog:** `test/support/lockspire/web/admin_lab/fixtures.ex`

**Internal fixture scope and redaction pattern** (lines 1-48):
```elixir
defmodule Lockspire.Web.AdminLab.Fixtures do
  @moduledoc false

  @scenario_states [
    :normal,
    :empty,
    :error,
    :disabled,
    :destructive,
    :long_value,
    :dense_data,
    :light,
    :dark,
    :system,
    :reduced_motion,
    :healthy,
    :warning,
    :incident,
    :self_registered,
    :expired,
    :revoked,
    :reuse_detected,
    :copy_once
  ]

  @forbidden_substrings [
    "real-client-secret",
    "production-secret",
    "prod-access-token",
    "prod-refresh-token",
```

**Long/dense redaction-safe data pattern** (lines 50-132):
```elixir
def all do
  %{
    clients: [
      %{
        state: :healthy,
        id: "client_acme_ledger_public",
        name: "Acme Ledger Partner With A Very Long Client Name That Wraps Safely",
        redirect_uri:
          "https://tenant-with-a-long-name.example.invalid/oauth/callbacks/production/eu-west-1/finance-ledger/reconciliation",
        secret_handle: "redacted_handle_client_secret_hash_v1"
      },
```

**Planner note:** extend `@scenario_states`, fixture keys, and `all/0` with Phase 118 statuses and structural cases. Keep fake `.example.invalid` style data and redacted handles only.

### `test/support/lockspire/web/admin_lab/stress_surface.ex` (test component, transform)

**Analog:** `test/support/lockspire/web/admin_lab/stress_surface.ex`

**Imports and assign loading pattern** (lines 1-27):
```elixir
defmodule Lockspire.Web.AdminLab.StressSurface do
  @moduledoc false

  use Phoenix.Component

  alias Lockspire.Web.AdminLab.Fixtures
  alias Lockspire.Web.Components.AdminComponents

  attr(:fixture_set, :map, required: true)

  def render(assigns) do
    assigns =
      assigns
      |> assign_new(:states, fn -> Fixtures.scenario_states() end)
      |> assign_new(:clients, fn -> Map.get(assigns.fixture_set, :clients, []) end)
```

**Rendered component stress pattern** (lines 35-53, 96-119, 128-146):
```elixir
<AdminComponents.page_hero
  eyebrow="Component lab"
  title="Render stress surface"
  body="Component lab proof drifted from the design-system contract when required states are missing."
>
  <:summary>
    <AdminComponents.badge_group>
      <AdminComponents.status_badge status={:active} />
      <AdminComponents.status_badge status={:warning} />
      <AdminComponents.status_badge status={:reuse_detected} />
    </AdminComponents.badge_group>
  </:summary>
```

```elixir
<AdminComponents.form_field
  id="stress-redirect-uri"
  label="Redirect URI"
  help="Use an exact HTTPS URI owned by the relying party."
  errors={["Enter a registered redirect URI."]}
  required
>
  <input
    id="stress-redirect-uri"
    name="redirect_uri"
    aria-invalid="true"
    aria-describedby="stress-redirect-uri-help stress-redirect-uri-error"
    value={@redirect_uri}
  />
</AdminComponents.form_field>
```

```elixir
<AdminComponents.confirmation_panel
  title="Revoke token family"
  variant={:danger}
  errors={["Type the client ID before revoking this family."]}
>
```

### `test/lockspire/web/live/admin/design_system_component_stress_test.exs` (test, transform)

**Analog:** `test/lockspire/web/live/admin/design_system_component_stress_test.exs`

**Render-component test pattern** (lines 1-8, 56-116):
```elixir
defmodule Lockspire.Web.Live.Admin.DesignSystemComponentStressTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  alias Lockspire.Web.AdminLab.Fixtures
  alias Lockspire.Web.AdminLab.StressSurface
```

```elixir
test "stress surface renders real admin components across required states" do
  html = render_component(&StressSurface.render/1, fixture_set: Fixtures.all())

  for phrase <- [
        "Render stress surface",
        "No lab scenarios rendered",
        "Component lab proof drifted from the design-system contract",
        "Revoke token family",
```

**Lab boundary pattern** (lines 136-149):
```elixir
test "component lab stays internal, test-only, and outside package/public routes" do
  router = File.read!(@admin_router_path)
  mix = File.read!(@mix_path)
  supported_surface = File.read!(@supported_surface_path)

  assert Path.expand("../../../../support/lockspire/web/admin_lab/fixtures.ex", __DIR__) =~
           "/test/support/lockspire/web/admin_lab/fixtures.ex"

  refute mix =~ ~r/files:\s+~w\([^)]*test\/support/

  for forbidden <- ["component-lab", "component_lab", "design-system-lab", "design_system_lab"] do
    refute router =~ forbidden
    refute supported_surface =~ forbidden
  end
end
```

### `test/lockspire/web/live/admin/design_system_contract_test.exs` (test, file-I/O)

**Analog:** `test/lockspire/web/live/admin/design_system_contract_test.exs`

**Source/CSS contract pattern** (lines 334-397):
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
        "status_badge"
      ] do
    assert components =~ "def #{function_name}"
  end
```

**Production migration/source-fence pattern** (lines 414-457, 535-600):
```elixir
test "behavior-neutral migrations use shared primitives without inline styles" do
  page_hero_sources = [
    Path.expand("../../../../../lib/lockspire/web/live/admin/overview_live/index.ex", __DIR__),
    Path.expand("../../../../../lib/lockspire/web/live/admin/dcr_live/index.ex", __DIR__)
  ]

  filter_bar_sources = [
    Path.expand("../../../../../lib/lockspire/web/live/admin/clients_live/index.ex", __DIR__),
    Path.expand("../../../../../lib/lockspire/web/live/admin/tokens_live/index.ex", __DIR__),
    Path.expand("../../../../../lib/lockspire/web/live/admin/consents_live/index.ex", __DIR__)
  ]
```

**Redaction/destructive proof pattern** (lines 603-660):
```elixir
test "phase 109 routes fence generic CTAs, redaction, and risky action copy" do
  sources = phase_109_source_blob()
  tests = phase_109_test_blob()

  for phrase <- [
        "redacted_handle",
        "plaintext",
        "copy_once_secret_panel",
        "not stored or shown again as plaintext",
```

### Production form/filter/row proof call sites (components, request-response)

**Analog:** `lib/lockspire/web/live/admin/tokens_live/index.ex`

**Filter fields and dense Support row pattern** (lines 58-89, 107-149):
```elixir
<AdminComponents.filter_bar action={tokens_index_path()}>
  <:fields>
    <div class="lockspire-admin-field">
      <label for="token_account">Account</label>
      <input id="token_account" name="account" type="text" value={@filters["account"]} />
    </div>
```

```elixir
<AdminComponents.resource_item
  href={token_show_path(entry.token.id)}
  title={token_title(entry)}
  subtitle={"#{entry.token.token_type} token"}
>
  <:meta>
    <span>
      Client
      <AdminComponents.long_value
        value={redacted_handle(:client, entry.token.client_id)}
        kind={:id}
      />
    </span>
```

**Analog:** `lib/lockspire/web/live/admin/policies_live/dcr.html.heex`

**Explicit Phoenix form pattern to preserve** (lines 8-24, 95-100):
```heex
<Lockspire.Web.Components.AdminComponents.error_list :if={@form_errors != []} errors={@form_errors} />

<form class="lockspire-admin-form-stack" phx-submit="save_policy">
  <div class="lockspire-admin-field">
    <label for="registration_policy">Enforcement mode</label>
    <select id="registration_policy" name="policy[registration_policy]">
```

```heex
<Lockspire.Web.Components.AdminComponents.action_bar>
  <Lockspire.Web.Components.AdminComponents.admin_button type="submit" variant={:primary}>
    Save global DCR policy
  </Lockspire.Web.Components.AdminComponents.admin_button>
</Lockspire.Web.Components.AdminComponents.action_bar>
```

**Analog:** `lib/lockspire/web/live/admin/keys_live/action_component.ex`

**Lifecycle confirmation pattern** (lines 22-40, 66-87):
```elixir
<AdminComponents.confirmation_panel
  :if={:publish in @key_detail.next_actions}
  title="Publish key"
>
  <:body>
    <form class="lockspire-admin-form-stack" phx-submit="publish_key">
      <label class="lockspire-admin-checkbox-field">
        <input type="checkbox" name="publish[confirm]" value="true" />
```

```elixir
<AdminComponents.confirmation_panel
  :if={:retire in @key_detail.next_actions}
  title="Retire key"
  variant={:danger}
>
```

**Analog:** `lib/lockspire/web/live/admin/tokens_live/show.ex`

**Destructive token workflow pattern** (lines 209-256):
```elixir
<AdminComponents.confirmation_panel title="Revoke token" variant={:danger}>
  <:body>
    <form class="lockspire-admin-form-stack" phx-submit="revoke_token">
      <label class="lockspire-admin-checkbox-field">
        <input type="checkbox" name="revoke[confirm]" value="true" />
        <span>
          Revoke only this {@token_detail.token.token_type} token for client
```

**Analog:** `lib/lockspire/web/live/admin/clients_live/show.ex`

**Action grouping pattern** (lines 386-455):
```elixir
<section class="lockspire-admin-detail-section">
  <h3>Credential and RAT rotation</h3>
  <AdminComponents.action_group>
    <:primary>
      <.link class="lockspire-admin-btn lockspire-admin-btn-secondary" :if={@client.client_type == :confidential} patch={show_path(@client.client_id, :rotate_secret)}>
        Rotate client secret
      </.link>
    </:primary>
```

## Shared Patterns

### Phoenix Function Components
**Source:** `lib/lockspire/web/components/admin_components.ex` lines 1-7, 35-57, 160-188
**Apply to:** all new/upgraded primitives in `AdminComponents`

Use `use Phoenix.Component`, explicit `attr/3`, explicit `slot/3`, `render_slot/1`, and HEEx. Do not introduce LiveComponents for ordinary structural reuse.

### Namespaced CSS And Semantic Tokens
**Source:** `lib/lockspire/web/admin_css.ex` lines 91-114, 395-441, 1509-1570
**Apply to:** all new primitive classes and status tones

Use `lockspire-admin-*` BEM names and semantic aliases such as `--ls-status-info-*`, `--ls-status-success-*`, `--ls-status-warning-*`, `--ls-status-danger-*`. Components consume aliases so light/dark/system remapping stays centralized.

### Redaction And Copy-Once Boundaries
**Source:** `test/support/lockspire/web/admin_lab/fixtures.ex` lines 37-48, `lib/lockspire/web/components/admin_components.ex` lines 302-320, 323-339
**Apply to:** fixtures, stress surface, production workflow proofs

Fixtures and rendered proof must use `redacted_handle_*`, `Redacted`, or fake values. Keep copy-once material in `copy_once_secret_panel`; never add plaintext secrets, refresh/access tokens, authorization codes, private keys, cookies, user codes, verifier material, or production-like token strings.

### Internal Lab Boundary
**Source:** `test/lockspire/web/live/admin/design_system_component_stress_test.exs` lines 136-149
**Apply to:** all lab fixture/surface changes

Lab files stay under `test/support/lockspire/web/admin_lab`, remain unmounted from `Lockspire.Web.AdminRouter`, excluded from package files, and absent from supported-surface docs.

### Source Contract Testing
**Source:** `test/lockspire/web/live/admin/design_system_contract_test.exs` lines 334-397, 414-457
**Apply to:** primitive exposure, CSS class backing, behavior-neutral production migrations

Add contract assertions for new component function names and CSS classes. Keep source tests focused on drift fences, not full HTML snapshots.

### Rendered Stress Testing
**Source:** `test/lockspire/web/live/admin/design_system_component_stress_test.exs` lines 56-116
**Apply to:** all new component stress cases

Use `render_component(&StressSurface.render/1, fixture_set: Fixtures.all())`, then assert user-visible labels, `lockspire-admin-*` class markers, accessibility attributes, and forbidden-value absence.

### Explicit Form Semantics
**Source:** `lib/lockspire/web/live/admin/policies_live/dcr.html.heex` lines 10-24, `test/support/lockspire/web/admin_lab/stress_surface.ex` lines 96-119
**Apply to:** `form_field`, production filter/form proof migrations

`form_field` owns label/help/error chrome and IDs; callers keep explicit `<input>`, `<select>`, `<textarea>`, `id`, `name`, `phx-submit`, and `phx-change` semantics visible.

## No Analog Found

| File / Component | Role | Data Flow | Reason |
|------------------|------|-----------|--------|
| `AdminComponents.pane/1` | component | transform | No exact architectural pane exists; copy `section_card/1` and `page_hero/1` attr/slot style. |
| `AdminComponents.entity_header/1` | component | transform | No exact entity-header primitive exists; combine `page_hero/1`, `description_list/1`, `long_value/1`, and `action_group/1` patterns. |
| `AdminComponents.workflow_shell/1` | component | request-response | Existing workflows are page-local `confirmation_panel` plus `<form>`; new wrapper must not own form events. |
| `AdminComponents.lifecycle_row/1` | component | transform | Existing lifecycle actions are section/action groups; use `resource_item/1` slots plus `confirmation_panel/1` workflow proof. |
| `AdminComponents.dense_resource_row/1` | component | transform | Existing `resource_item/1` is the nearest analog, but dense Support/Operate rows need a narrower wrapper. |
| `AdminComponents.responsive_table/1` | component | transform | Existing CSS has `.lockspire-admin-table-wrap`; no function component owns a table/list alternative yet. |

## Metadata

**Analog search scope:** `lib/lockspire/web`, `test/support/lockspire/web/admin_lab`, `test/lockspire/web/live/admin`
**Files scanned:** 52 source/test files from targeted admin web directories
**Pattern extraction date:** 2026-06-25

