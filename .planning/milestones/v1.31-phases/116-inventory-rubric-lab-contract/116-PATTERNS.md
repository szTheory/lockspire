# Phase 116: Inventory, Rubric & Lab Contract - Pattern Map

**Mapped:** 2026-06-25
**Files analyzed:** 5
**Analogs found:** 5 / 5

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `.planning/phases/116-inventory-rubric-lab-contract/116-ROUTE-WORKFLOW-INVENTORY.md` | config | transform | `.planning/phases/107-admin-journey-contract-ia-audit/107-ROUTE-JOURNEY-CONTRACT.md` + `test/lockspire/web/live/admin/design_system_contract_test.exs` | exact |
| `.planning/phases/116-inventory-rubric-lab-contract/116-COMPONENT-GROUP-INVENTORY.md` | component | transform | `lib/lockspire/web/components/admin_components.ex` + `test/lockspire/web/live/admin/design_system_contract_test.exs` | exact |
| `.planning/phases/116-inventory-rubric-lab-contract/116-VISUAL-UX-RUBRIC.md` | config | transform | `brandbook/tokens/tokens.json` + `test/lockspire/web/live/admin/design_system_contract_test.exs` | exact |
| `.planning/phases/116-inventory-rubric-lab-contract/116-LAB-CONTRACT.md` | config | transform | `test/lockspire/web/live/admin/design_system_component_stress_test.exs` + `docs/supported-surface.md` | exact |
| `test/lockspire/web/live/admin/design_system_contract_test.exs` | test | transform | `test/lockspire/web/live/admin/design_system_contract_test.exs` | exact |

## Pattern Assignments

### `.planning/phases/116-inventory-rubric-lab-contract/116-ROUTE-WORKFLOW-INVENTORY.md` (config, transform)

**Analog:** `.planning/phases/107-admin-journey-contract-ia-audit/107-ROUTE-JOURNEY-CONTRACT.md`

**Route truth and workflow exception pattern** (lines 3-7):

```markdown
Phase 107 is audit-only. It adds no admin routes, protocol behavior, operator authentication, tenant policy, layouts, branding, or product-specific authorization. Lockspire owns protocol and operator state after the host-mounted admin route is reached; the host app owns staff auth, MFA, role checks, tenant policy, layouts, branding, and product policy before the admin router.

This contract uses `lib/lockspire/web/admin_router.ex` as route truth and publishes mounted `/admin...` paths because the operator-visible surface is mounted under the embedded admin router. It also includes `/admin/clients/:client_id/edit?workflow=logout-propagation`, which is a query-driven workflow in `ClientsLive.Show`, not a separate Phoenix route.

No evidence note copies client secrets, raw token values, registration access token plaintext, or other copy-once material.
```

**Inventory row shape pattern** (lines 16-19):

```markdown
## Route Journey Contract

| Route | Primary journey | Persona | JTBD | Entry point | Primary decision | Primary action | Empty state | Risk state | Follow-up route | Evidence |
|-------|-----------------|---------|------|-------------|------------------|----------------|-------------|------------|-----------------|----------|
```

**Concrete row pattern** (lines 20-28):

```markdown
| `/admin` | Orient | Provider operator | Understand attention-worthy provider state and choose the next workflow. | Host admin mount or overview redirect | Which provider area needs attention first? | Record overview routing | No attention items recorded; use journey cards to enter clients, security, support, or operations. | Warning and danger counts only | `/admin/clients` | `AdminRouter`, `OverviewLive.Index`, `tmp/admin-ui-polish/v128-overview-desktop.png`, `tmp/admin-ui-polish/v128-overview-mobile.png` |
| `/admin/clients/:client_id/edit?workflow=logout-propagation` | Configure | Security/platform owner | Maintain RP logout cleanup endpoints separately from browser redirects. | Client workspace logout action | Which RP cleanup endpoints receive logout propagation? | Save logout propagation | No logout propagation URIs recorded; add back-channel or front-channel cleanup endpoints if the RP supports them. | Failed cleanup, best-effort front-channel, invalid URI | `/admin/logouts` | `ClientsLive.Show.resolve_form_mode/2`, `docs/operator-admin.md` |
```

**AdminRouter route source pattern** from `lib/lockspire/web/admin_router.ex` (lines 1-15, 29-35, 73-84):

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
```

```elixir
    live(
      "/device_authorizations",
      Lockspire.Web.Live.Admin.DeviceAuthorizationsLive.Index,
      :index
    )

    live("/clients/:client_id/edit", Lockspire.Web.Live.Admin.ClientsLive.Show, :edit)
```

```elixir
    live("/dcr", Lockspire.Web.Live.Admin.DcrLive.Index, :index)
    live("/policies", Lockspire.Web.Live.Admin.PoliciesLive.Index, :index)
    live("/policies/par", Lockspire.Web.Live.Admin.PoliciesLive.Par, :show)

    live(
      "/policies/security-profile",
      Lockspire.Web.Live.Admin.PoliciesLive.SecurityProfile,
      :show
    )

    live("/policies/dpop", Lockspire.Web.Live.Admin.PoliciesLive.Dpop, :show)
    live("/policies/dcr", Lockspire.Web.Live.Admin.PoliciesLive.Dcr, :show)
```

**Source-derived proof pattern** from `test/lockspire/web/live/admin/design_system_contract_test.exs` (lines 416-428, 868-876):

```elixir
test "phase 107 route journey contract covers admin routes and locked vocabulary" do
  router = File.read!(@admin_router_path)
  contract = File.read!(@route_contract_path)
  guide = File.read!(@operator_admin_doc_path)

  expected_routes =
    router
    |> mounted_admin_routes()
    |> Kernel.++(["/admin/clients/:client_id/edit?workflow=logout-propagation"])
    |> Enum.sort()

  for route <- expected_routes do
    assert contract =~ "| `#{route}` |"
  end
```

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

**Planning instruction:** Copy Phase 107's row fields, then add `Surface classification` as a new column. Generate or test normal rows from `AdminRouter`; append only `/admin/clients/:client_id/edit?workflow=logout-propagation` as the query workflow exception.

---

### `.planning/phases/116-inventory-rubric-lab-contract/116-COMPONENT-GROUP-INVENTORY.md` (component, transform)

**Analog:** `lib/lockspire/web/components/admin_components.ex`

**Imports/API source pattern** (lines 1-8):

```elixir
defmodule Lockspire.Web.Components.AdminComponents do
  @moduledoc false

  use Phoenix.Component

  attr(:status, :atom, required: true)

  def status_badge(assigns) do
```

**Canonical attrs/slots structural pattern** (lines 35-57):

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

**Form/error pattern** (lines 160-204):

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
      <%= for error <- @errors do %>
        <li>{format_error(error)}</li>
      <% end %>
    </ul>
  </div>
  """
end

attr(:title, :string, default: "Review the highlighted fields")
attr(:errors, :list, default: [])

def error_summary(assigns) do
```

**Safety and long-value pattern** (lines 302-340, 373-395):

```elixir
attr(:title, :string, required: true)
attr(:body, :string, default: nil)
attr(:value, :any, default: nil)
attr(:redacted, :boolean, default: false)
attr(:label, :string, default: "Copy-once value")
attr(:class, :string, default: "")

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

attr(:value, :any, required: true)
attr(:kind, :atom, default: :text)
attr(:redacted, :boolean, default: false)
attr(:class, :string, default: "")

def long_value(assigns) do
```

```elixir
attr(:title, :string, required: true)
attr(:variant, :atom, default: :warning)
attr(:errors, :list, default: [])
slot(:body, required: true)
slot(:actions)

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
```

**Current status fallback pressure** (lines 451-458, 460-476):

```elixir
defp badge_class(:active), do: "lockspire-admin-badge lockspire-admin-badge-active"
defp badge_class(:upcoming), do: "lockspire-admin-badge lockspire-admin-badge-info"
defp badge_class(:retiring), do: "lockspire-admin-badge lockspire-admin-badge-warning"
defp badge_class(:retired), do: "lockspire-admin-badge lockspire-admin-badge-disabled"
defp badge_class(:revoked), do: "lockspire-admin-badge lockspire-admin-badge-danger"
defp badge_class(:expired), do: "lockspire-admin-badge lockspire-admin-badge-disabled"
defp badge_class(:reuse_detected), do: "lockspire-admin-badge lockspire-admin-badge-danger"
defp badge_class(_other), do: "lockspire-admin-badge lockspire-admin-badge-disabled"
```

```elixir
defp badge_label(:active), do: "Active"
defp badge_label(:upcoming), do: "Upcoming"
defp badge_label(:retiring), do: "Retiring"
defp badge_label(:retired), do: "Retired"
defp badge_label(:disabled), do: "Disabled"
defp badge_label(:revoked), do: "Revoked"
defp badge_label(:expired), do: "Expired"
defp badge_label(:reuse_detected), do: "Reuse detected"
defp badge_label(:remembered), do: "Remembered"
defp badge_label(:one_time), do: "One-time"
defp badge_label(:pending_login), do: "Pending login"
defp badge_label(:pending_consent), do: "Pending consent"

defp badge_label(value) when is_atom(value),
  do: value |> Atom.to_string() |> String.replace("_", " ") |> String.capitalize()
```

**Existing component contract proof pattern** from `test/lockspire/web/live/admin/design_system_contract_test.exs` (lines 266-329):

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

**Planning instruction:** Inventory `attr/3`, `slot/3`, function names, CSS classes, production usage files, page-local direct markup, status gaps, form exceptions, redaction boundaries, disabled states, destructive confirmations, and mobile/long-value pressure. Group by reusable operator building block, not individual CSS class.

---

### `.planning/phases/116-inventory-rubric-lab-contract/116-VISUAL-UX-RUBRIC.md` (config, transform)

**Analog:** `brandbook/tokens/tokens.json`

**Canonical token source pattern** (lines 1-20):

```json
{
  "$schema": "https://design-tokens.github.io/community-group/format/",
  "_meta": {
    "name": "Lockspire Design Tokens",
    "version": "1.0.0",
    "description": "Canonical token source for the Lockspire brand and product UI. Variable names mirror lib/lockspire/web/admin_css.ex (--ls-*) verbatim. Dark mode remaps semantic aliases only.",
    "status_legend": {
      "shipped": "Implemented in the live admin UI today (post re-skin).",
      "proposed": "Designed and documented; additive; safe to adopt."
    }
  },

  "color": {
    "brand": {
      "_note": "Signal Cyan scale. 500 = hero (dark/accent), 600 = AA-safe action+text on light, 700 = hover.",
      "50":  { "value": "#ecfeff", "status": "shipped" },
      "100": { "value": "#cffafe", "status": "shipped" },
      "500": { "value": "#22d3ee", "status": "shipped", "name": "Signal Cyan" },
      "600": { "value": "#0e7490", "status": "shipped", "name": "Deep Cyan", "contrast_on_white": "5.0:1", "wcag": "AA" },
```

**Semantic dark-mode pattern** (lines 46-72):

```json
"semantic": {
  "light": {
    "surface-page":   { "value": "{color.neutral.50}" },
    "surface-panel":  { "value": "#ffffff" },
    "surface-muted":  { "value": "{color.neutral.100}" },
    "surface-inverse":{ "value": "{color.neutral.950}" },
    "text-strong":    { "value": "{color.neutral.950}", "contrast_on_page": "17.4:1", "wcag": "AAA" },
    "text-body":      { "value": "{color.neutral.700}", "contrast_on_page": "9.6:1", "wcag": "AAA" },
    "text-muted":     { "value": "{color.neutral.500}", "contrast_on_page": "4.6:1", "wcag": "AA" },
    "text-accent":    { "value": "{color.brand.600}", "contrast_on_page": "5.0:1", "wcag": "AA" },
    "border-subtle":  { "value": "{color.neutral.200}" },
    "border-strong":  { "value": "{color.neutral.300}" },
    "focus-ring":     { "value": "{color.brand.600}" }
  },
  "dark": {
    "surface-page":   { "value": "{color.neutral.950}", "name": "Obsidian" },
    "surface-panel":  { "value": "#131c2e" },
    "surface-muted":  { "value": "{color.neutral.800}" },
    "surface-inverse":{ "value": "{color.neutral.50}" },
    "text-strong":    { "value": "{color.neutral.50}", "contrast_on_page": "16.8:1", "wcag": "AAA" },
    "text-body":      { "value": "#c9d4e3", "name": "Mist", "contrast_on_page": "11.9:1", "wcag": "AAA" },
    "text-muted":     { "value": "#8a99ad", "contrast_on_page": "5.6:1", "wcag": "AA" },
    "text-accent":    { "value": "{color.brand.500}", "contrast_on_page": "10.7:1", "wcag": "AAA" },
    "border-subtle":  { "value": "#1e293b" },
    "border-strong":  { "value": "#334155" },
    "focus-ring":     { "value": "{color.brand.500}" }
  }
}
```

**Brandbook source and package boundary** from `brandbook/README.md` (lines 25-33):

```markdown
`tokens/tokens.css` uses the **same `--ls-*` variable names** as the live admin
stylesheet (`lib/lockspire/web/admin_css.ex`). It is not a parallel design system -
it is the same token vocabulary, so brand and product stay in lockstep.

Dark mode is implemented by remapping **semantic aliases only**
(`--ls-surface-*`, `--ls-text-*`, `--ls-status-*`); primitives are theme-agnostic.
```

**Contrast/accessibility gate pattern** from `brandbook/notes/accessibility-checks.md` (lines 18-26, 45-60):

```markdown
| Signal Cyan `#22d3ee` | white | 1.5:1 | FAIL | FAIL -> **non-text only** |

**Rule enforced:** `#22d3ee` is never used for text or small icons on light
surfaces - only focus glow, large solid fills (with dark text), borders, and the
logo. Light-mode actions/links use `#0e7490`.
```

```markdown
## Focus rings

- Light: `#0e7490`, 2px, 3px offset, + `0 0 0 3px #cffafe` glow. Non-text contrast vs white = 5.0:1.
- Dark: `#22d3ee`, 2px, 3px offset, + `0 0 0 3px rgb(34 211 238 / .35)`. Non-text contrast vs Obsidian = 10.7:1.
- Never removed (`outline: none` without replacement is prohibited).

## Non-color signals

State is never communicated by color alone (WCAG 1.4.1). Status badges carry a
text label; destructive actions carry an icon + label; focus carries a ring, not
just a color shift.

## Motion

`prefers-reduced-motion: reduce` zeroes `--ls-motion-duration-*`. No parallax,
no auto-playing motion in the brand book or admin.
```

**Token alignment proof pattern** from `test/lockspire/web/live/admin/design_system_contract_test.exs` (lines 178-209):

```elixir
test "embedded admin CSS stays aligned with canonical brandbook token values" do
  css = File.read!(@admin_css_path)
  tokens = @brandbook_tokens_path |> File.read!() |> Jason.decode!()

  expected_tokens = %{
    "--ls-color-brand-50" => get_in(tokens, ["color", "brand", "50", "value"]),
    "--ls-color-brand-100" => get_in(tokens, ["color", "brand", "100", "value"]),
    "--ls-color-brand-500" => get_in(tokens, ["color", "brand", "500", "value"]),
    "--ls-color-brand-600" => get_in(tokens, ["color", "brand", "600", "value"]),
    "--ls-color-brand-700" => get_in(tokens, ["color", "brand", "700", "value"]),
    "--ls-color-info-bg" => get_in(tokens, ["status", "light", "info", "bg"]),
    "--ls-color-info-text" => get_in(tokens, ["status", "light", "info", "text"]),
    "--ls-color-info-border" => get_in(tokens, ["status", "light", "info", "border"]),
    "--ls-color-info-bg-dark" => get_in(tokens, ["status", "dark", "info", "bg"]),
    "--ls-color-info-text-dark" => get_in(tokens, ["status", "dark", "info", "text"]),
    "--ls-color-info-border-dark" => get_in(tokens, ["status", "dark", "info", "border"])
  }

  for {token, value} <- expected_tokens do
    assert css =~ "#{token}: #{value};"
  end
end
```

**Identity anti-pattern source** from `brandbook/notes/logo-options.md` (lines 31-49):

```markdown
## Constraints honored

- **No rectangular cage** - all marks transparent.
- **No subtitle on primary** - tagline is a separate, secondary lockup.
- **Unified mark + wordmark** - shared faceted-crystal language (diamond <-> tower).
- **Integrated typemark** - the diamond is a motif worked into the letterform, not a
  floating icon.
- **Mono / favicon safe** - `-mono` variants via `currentColor`; tower holds at 16px.

## Tournament record (why this, not the others)

The identity went through six rounds of rendered exploration. Rejected along the way:

- **Blocky rounded-rect marks** (v1) - read as 8-bit / Atari.
- **Full-height spire "i"** (v6) - too tall, unbalanced the wordmark.
- **L-spire initial** (v5) - illegible / detached at size.
- **Converging beams** (v5) - generic triangle read.
```

**Planning instruction:** Rubric gates should be pass/fail and source-bound: brandbook as canonical source, restrained Signal Cyan, contrast-safe Deep Cyan in light mode, semantic alias dark remap, light/dark/system parity, visible focus, reduced motion, non-color status cues, responsive no-overflow, redaction/no-secret evidence, destructive-action confirmation, and calm domain microcopy.

---

### `.planning/phases/116-inventory-rubric-lab-contract/116-LAB-CONTRACT.md` (config, transform)

**Analog:** `test/lockspire/web/live/admin/design_system_component_stress_test.exs`

**Maintainer-only render surface imports pattern** (lines 1-11):

```elixir
defmodule Lockspire.Web.Live.Admin.DesignSystemComponentStressTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  defmodule StressSurface do
    use Phoenix.Component

    alias Lockspire.Web.Components.AdminComponents

    def render(assigns) do
```

**Real component stress pattern** (lines 13-31, 39-60, 95-118):

```elixir
<AdminComponents.page_hero
  eyebrow="Configure"
  title="Design-system stress surface"
  body="Real operator components rendered together with long identifiers, dangerous actions, empty states, and field errors."
>
  <:summary>
    <AdminComponents.badge_group>
      <AdminComponents.status_badge status={:active} />
      <AdminComponents.status_badge status={:reuse_detected} />
      <AdminComponents.status_badge status={:pending_consent} />
    </AdminComponents.badge_group>
  </:summary>
  <:actions>
    <AdminComponents.admin_button variant={:primary}>Create registration token</AdminComponents.admin_button>
    <AdminComponents.admin_button disabled href="/lockspire/admin/clients">
      Disabled link action
    </AdminComponents.admin_button>
  </:actions>
</AdminComponents.page_hero>
```

```elixir
<AdminComponents.section_card
  title="Long operator data"
  subtitle="This group intentionally contains awkward real-world strings."
>
  <AdminComponents.resource_list>
    <AdminComponents.resource_item
      title="Acme Ledger Partner With A Very Long Client Name That Should Wrap Without Page Overflow"
      subtitle="client_01HY6Q1P8Y4R5T6U7V8W9X0Y1Z-long-value-boundary-case"
      href="/lockspire/admin/clients/client_01HY6Q1P8Y4R5T6U7V8W9X0Y1Z-long-value-boundary-case"
    >
      <:meta>
        <AdminComponents.long_value
          kind={:url}
          value="https://tenant-with-a-long-name.example.invalid/oauth/callbacks/production/eu-west-1/finance-ledger/reconciliation"
        />
      </:meta>
      <:status>
        <AdminComponents.status_badge status={:warning} />
      </:status>
    </AdminComponents.resource_item>
  </AdminComponents.resource_list>
</AdminComponents.section_card>
```

```elixir
<AdminComponents.copy_once_secret_panel
  title="Copy-once credential"
  body="Copy this value now. Lockspire stores only the hash after this response."
  value="iat_copy-once_01HY6Q1P8Y4R5T6U7V8W9X0Y1Z"
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
    <AdminComponents.admin_button variant={:danger}>Revoke token family</AdminComponents.admin_button>
    <AdminComponents.admin_button>Keep token family active</AdminComponents.admin_button>
  </:actions>
</AdminComponents.confirmation_panel>

<AdminComponents.empty_state
  title="No logout deliveries match these filters"
  body="Clear the filters or inspect active interactions to find pending logout work."
/>
```

**Rendered proof pattern** (lines 123-153):

```elixir
test "stress surface renders shared primitives and awkward operator states" do
  html = rendered_to_string(StressSurface.render(%{}))

  for phrase <- [
        "Design-system stress surface",
        "client_01HY6Q1P8Y4R5T6U7V8W9X0Y1Z-long-value-boundary-case",
        "tenant-with-a-long-name.example.invalid",
        "Review the highlighted fields",
        "aria-invalid=\"true\"",
        "readonly",
        "Copy-once credential",
        "Revoke token family",
        "No logout deliveries match these filters"
      ] do
    assert html =~ phrase
  end

  for class <- [
        "lockspire-admin-page-hero",
        "lockspire-admin-badge",
        "lockspire-admin-summary-stat",
        "lockspire-admin-resource-list__item",
        "lockspire-admin-error-summary",
        "lockspire-admin-field-error",
        "lockspire-admin-copy-once-secret",
        "lockspire-admin-confirmation-panel-danger",
        "lockspire-admin-empty"
      ] do
    assert html =~ class
  end
end
```

**Support-boundary pattern** from `docs/supported-surface.md` (lines 148-168):

```markdown
## Trust posture

Lockspire maintains its 1.0 GA posture because public claims are backed by what this repo can prove today. Repo-owned proof for this posture lives in:
...
Lockspire does not use README summaries, maintainer-only workflow docs, external-suite artifact folders, workflow-run folklore, or a demo app as its primary public proof story. The repo-local adoption demo is a secondary executable DX smoke, not a broader support claim.

Historical Phase 37 external-suite wiring and any OIDF or FAPI Docker runs remain maintainer-only corroboration. They can be useful for standards-sensitive investigation, but they are optional, secondary to the repo-native proof above, and not part of the current public support contract.
```

**Planning instruction:** Define the lab as `internal_lab`/maintainer proof only. It may render HEEx/function components and hostile redaction-safe fixtures, but must not mount through `Lockspire.Web.AdminRouter`, add PhoenixStorybook, add React/JS Storybook, create public theming, create host-editable registries, or document a supported route/API.

---

### `test/lockspire/web/live/admin/design_system_contract_test.exs` (test, transform)

**Analog:** `test/lockspire/web/live/admin/design_system_contract_test.exs`

**File path constants pattern** (lines 1-31):

```elixir
defmodule Lockspire.Web.Live.Admin.DesignSystemContractTest do
  use ExUnit.Case, async: true

  @admin_live_glob Path.expand(
                     "../../../../../lib/lockspire/web/live/admin/**/*.{ex,heex}",
                     __DIR__
                   )
  @admin_css_path Path.expand("../../../../../lib/lockspire/web/admin_css.ex", __DIR__)
  @admin_components_path Path.expand(
                           "../../../../../lib/lockspire/web/components/admin_components.ex",
                           __DIR__
                         )
  @admin_router_path Path.expand("../../../../../lib/lockspire/web/admin_router.ex", __DIR__)
  @admin_layout_path Path.expand(
                       "../../../../../lib/lockspire/web/live/admin_layout_live.ex",
                       __DIR__
                     )
  @brandbook_tokens_path Path.expand("../../../../../brandbook/tokens/tokens.json", __DIR__)
  @operator_admin_doc_path Path.expand("../../../../../docs/operator-admin.md", __DIR__)
```

**Contract artifact test pattern** (lines 685-733):

```elixir
test "phase 110 screenshot and browser evidence inventories cover route proof fields" do
  router = File.read!(@admin_router_path)
  screenshots = File.read!(phase_110_path("110-SCREENSHOTS.md"))
  browser = File.read!(phase_110_path("110-BROWSER-EVIDENCE.md"))

  expected_routes =
    router
    |> mounted_admin_routes()
    |> Kernel.++(["/admin/clients/:client_id/edit?workflow=logout-propagation"])
    |> Enum.sort()

  for route <- expected_routes do
    assert screenshots =~ route
  end

  for heading <- [
        "Coverage Matrix",
        "Journey",
        "Route",
        "Desktop",
        "Mobile",
        "Demo state",
        "Browser note"
      ] do
    assert screenshots =~ heading
  end
end
```

**Redaction/source fence test pattern** (lines 797-821, 858-865):

```elixir
test "phase 110 proof artifacts fence runtime dependencies, generic labels, and redaction notes" do
  artifacts = phase_110_artifact_blob()

  for path <- Path.wildcard(@admin_live_glob) ++ [@admin_css_path, @admin_components_path] do
    refute File.read!(path) =~ "tmp/admin-ui-polish"
  end

  refute Regex.match?(
           ~r/(?:^|>|\n|\|)\s*(Submit|OK|Cancel|Apply|Open)\s*(?:<|\n|\||$)/,
           artifacts
         )

  for phrase <- [
        "Do not persist plaintext IATs",
        "RATs",
        "client secrets",
        "user codes",
        "verifier material",
        "access tokens",
        "refresh tokens",
        "token hashes",
        "Keep screenshot files under `tmp/admin-ui-polish/` as milestone evidence only"
      ] do
    assert artifacts =~ phrase
  end
end
```

```elixir
test "admin LiveViews do not reintroduce raw inline styles or unnamespaced button markup" do
  for path <- Path.wildcard(@admin_live_glob) do
    content = File.read!(path)

    refute content =~ ~r/\sstyle=/
    refute Regex.match?(~r/class="lockspire-admin-btn-(primary|secondary|danger)"/, content)
    refute Regex.match?(~r/<button(?![^>]*lockspire-admin-btn)/, content)
  end
end
```

**Planning instruction:** Add focused Phase 116 tests here unless the planner chooses a separate test file. Tests should prove artifact existence, source-derived route rows, row field headers including `Surface classification`, component inventory coverage from `AdminComponents`, brand/rubric gates from `brandbook/`, lab boundary language, and no-secret terms.

## Shared Patterns

### Host-Mounted Admin Boundary

**Source:** `lib/lockspire/web/admin_router.ex` lines 1-7 and `docs/supported-surface.md` lines 173-176
**Apply to:** route inventory, lab contract, tests

```elixir
@moduledoc """
Mountable Phoenix router exposing only Lockspire operator/admin LiveViews.

Host applications should mount this router behind their own operator
authentication pipeline before the general `Lockspire.Web.Router` forward.
"""
```

```markdown
- there is one canonical Phoenix onboarding path
- the host app owns operator authentication before mounting `Lockspire.Web.AdminRouter`
- `--sigra-host` is guidance-only; it does not create a second install topology or a compile-time Sigra dependency
```

### Source-Derived Route Extraction

**Source:** `test/lockspire/web/live/admin/design_system_contract_test.exs` lines 868-876
**Apply to:** route/workflow inventory and tests

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

### Phoenix Function Components

**Source:** `lib/lockspire/web/components/admin_components.ex` lines 1-4
**Apply to:** component/group inventory, lab contract

```elixir
defmodule Lockspire.Web.Components.AdminComponents do
  @moduledoc false

  use Phoenix.Component
```

### Namespaced CSS and Component Coverage

**Source:** `test/lockspire/web/live/admin/design_system_contract_test.exs` lines 100-122 and 310-329
**Apply to:** component inventory, rubric tests

```elixir
for class <- [
      "lockspire-admin-alert-warning",
      "lockspire-admin-action-bar",
      "lockspire-admin-btn",
      "lockspire-admin-btn-danger",
      "lockspire-admin-confirmation-panel",
      "lockspire-admin-detail-section",
      "lockspire-admin-empty-notice",
      "lockspire-admin-resource-list",
      "lockspire-admin-resource-list__item",
      "lockspire-admin-description-list",
      "lockspire-admin-table-wrap"
    ] do
  assert live_content =~ class
  assert css =~ "." <> class
end
```

### Redaction and No-Secret Evidence

**Source:** `.planning/phases/107-admin-journey-contract-ia-audit/107-ROUTE-JOURNEY-CONTRACT.md` line 7 and `test/lockspire/web/live/admin/design_system_contract_test.exs` lines 809-820
**Apply to:** all Phase 116 artifacts and tests

```markdown
No evidence note copies client secrets, raw token values, registration access token plaintext, or other copy-once material.
```

```elixir
for phrase <- [
      "Do not persist plaintext IATs",
      "RATs",
      "client secrets",
      "user codes",
      "verifier material",
      "access tokens",
      "refresh tokens",
      "token hashes",
      "Keep screenshot files under `tmp/admin-ui-polish/` as milestone evidence only"
    ] do
  assert artifacts =~ phrase
end
```

### Brandbook Is Canonical

**Source:** `brandbook/README.md` lines 25-33 and `brandbook/notes/decision-log.md` lines 21-31
**Apply to:** visual/UX rubric and tests

```markdown
`tokens/tokens.css` uses the **same `--ls-*` variable names** as the live admin
stylesheet (`lib/lockspire/web/admin_css.ex`). It is not a parallel design system -
it is the same token vocabulary, so brand and product stay in lockstep.

Dark mode is implemented by remapping **semantic aliases only**
(`--ls-surface-*`, `--ls-text-*`, `--ls-status-*`); primitives are theme-agnostic.
```

```markdown
**Decision:** Pure `#22D3EE` is the hero on dark surfaces only. Light-mode interactive/text uses **Deep Cyan `#0E7490`** (`brand-600`, ~5:1 on white). `#22D3EE` (`brand-500`) is reserved for dark surfaces, focus glow, large non-text accents, and the logo.
```

### Internal Lab Boundary

**Source:** `test/lockspire/web/live/admin/design_system_component_stress_test.exs` lines 123-153 and `docs/supported-surface.md` lines 166-168
**Apply to:** lab contract and tests

```elixir
html = rendered_to_string(StressSurface.render(%{}))

for phrase <- [
      "Design-system stress surface",
      "client_01HY6Q1P8Y4R5T6U7V8W9X0Y1Z-long-value-boundary-case",
      "tenant-with-a-long-name.example.invalid",
      "Review the highlighted fields",
      "aria-invalid=\"true\"",
      "readonly",
      "Copy-once credential",
      "Revoke token family",
      "No logout deliveries match these filters"
    ] do
  assert html =~ phrase
end
```

```markdown
Lockspire does not use README summaries, maintainer-only workflow docs, external-suite artifact folders, workflow-run folklore, or a demo app as its primary public proof story. The repo-local adoption demo is a secondary executable DX smoke, not a broader support claim.
```

## No Analog Found

All expected Phase 116 files have close analogs in the codebase or prior planning artifacts.

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| None | - | - | - |

## Metadata

**Analog search scope:** `lib/lockspire/web/admin_router.ex`, `lib/lockspire/web/components/admin_components.ex`, `lib/lockspire/web/admin_css.ex`, `lib/lockspire/web/live/admin/**`, `test/lockspire/web/live/admin/**`, `brandbook/**`, `docs/**`, `.planning/phases/107-admin-journey-contract-ia-audit/**`
**Files scanned:** 45+
**Pattern extraction date:** 2026-06-25
