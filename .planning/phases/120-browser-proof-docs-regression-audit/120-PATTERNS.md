# Phase 120: Browser Proof, Docs & Regression Audit - Pattern Map

**Mapped:** 2026-06-26
**Files analyzed:** 10 file groups
**Analogs found:** 9 / 10

Phase 120 is a proof and documentation phase. Reuse the existing ExUnit, LiveViewTest, LazyHTML-ready, component-stress, route-inventory, docs-boundary, and demo-smoke shapes. Do not create new runtime admin surface area.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `.planning/phases/120-browser-proof-docs-regression-audit/120-BROWSER-PROOF.md` | docs/proof artifact | batch | `.planning/phases/110-demo-state-screenshots-docs-and-regression-proof/110-SCREENSHOTS.md` | role-match |
| `test/lockspire/web/live/admin/design_system_contract_test.exs` | test | transform | same file | exact |
| `test/lockspire/web/live/admin/design_system_component_stress_test.exs` | test | transform | same file | exact |
| `test/support/lockspire/web/admin_proof/html_assertions.ex` or inline equivalent | utility | transform | `test/lockspire/web/live/admin/design_system_contract_test.exs` helpers | role-match |
| `test/lockspire/web/admin_router_test.exs` | test | request-response | same file | exact |
| `test/lockspire/web/live/admin/*_test.exs` focused route tests | test | request-response | existing admin LiveView tests | exact |
| `docs/operator-admin.md` | docs | transform | same file | exact |
| `docs/supported-surface.md` | docs/support boundary | transform | same file | exact, avoid unless ambiguity found |
| optional `scripts/maintainer/admin_browser_proof` | utility/command | request-response + batch | `scripts/demo/adoption_smoke.sh` and `.py` | partial |
| optional Playwright/axe package/config/spec files | test/tooling | request-response | no existing browser harness | no-analog |

## Existing Patterns To Reuse

### Route Truth And Supported Surface

**Use for:** route matrix, stale link checks, browser route proof.

**Primary analog:** `lib/lockspire/web/admin_router.ex` lines 1-6, 13-25, 29-35, 73-84.

```elixir
defmodule Lockspire.Web.AdminRouter do
  @moduledoc """
  Mountable Phoenix router exposing only Lockspire operator/admin LiveViews.

  Host applications should mount this router behind their own operator
  authentication pipeline before the general `Lockspire.Web.Router` forward.
  """
```

```elixir
scope "/" do
  live("/", Lockspire.Web.Live.Admin.OverviewLive.Index, :index)
  live("/overview", Lockspire.Web.Live.Admin.OverviewLive.Index, :index)
  live("/clients", Lockspire.Web.Live.Admin.ClientsLive.Index, :index)
  live("/clients/:client_id", Lockspire.Web.Live.Admin.ClientsLive.Show, :show)
  live("/consents", Lockspire.Web.Live.Admin.ConsentsLive.Index, :index)
  live("/tokens", Lockspire.Web.Live.Admin.TokensLive.Index, :index)
  live("/interactions", Lockspire.Web.Live.Admin.InteractionsLive.Index, :index)
  live("/logouts", Lockspire.Web.Live.Admin.LogoutDeliveriesLive.Index, :index)
```

**Why:** Phase 120 route coverage must derive from `AdminRouter` plus only the query workflow `/admin/clients/:client_id/edit?workflow=logout-propagation`. Do not derive coverage from old screenshot filenames.

**Inventory analog:** `.planning/phases/116-inventory-rubric-lab-contract/116-ROUTE-WORKFLOW-INVENTORY.md` lines 1-5 and 18-49. It already classifies routes by journey, JTBD, empty/risk state, follow-up route, evidence, and surface classification.

### Source Contract Guardrails

**Use for:** PROOF-03 blocking tests for token drift, raw color drift, route/docs alignment, public boundary drift, generic CTA drift, secret leakage, theme/motion contracts.

**Analog:** `test/lockspire/web/live/admin/design_system_contract_test.exs` lines 1-35.

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
  @operator_admin_doc_path Path.expand("../../../../../docs/operator-admin.md", __DIR__)
```

**Theme/motion pattern:** `test/lockspire/web/live/admin/design_system_contract_test.exs` lines 274-333.

```elixir
assert css =~ "color-scheme: light;"
assert css =~ ":root[data-theme=\"light\"]"
assert css =~ ":root[data-theme=\"dark\"]"
assert css =~ "@media (prefers-color-scheme: dark)"

refute css =~ ~r/transition(?:-property)?\s*:\s*all\b/
refute css =~ ~r/transition\s*:/

assert css =~ "@media (prefers-reduced-motion: reduce)"
assert css =~ "transition-duration: 0.01ms !important"
assert css =~ "animation-duration: 0.01ms !important"
```

**Public boundary pattern:** `test/lockspire/web/live/admin/design_system_contract_test.exs` lines 335-353.

```elixir
for forbidden <- ["component-lab", "design-system-lab", "Playwright proof", "axe proof"] do
  refute supported_surface =~ forbidden
end

for forbidden_path <- [
      "proof/browser",
      "scripts/browser-proof",
      "package.json",
      "playwright.config"
    ] do
  refute mix =~ forbidden_path
end
```

**Route extraction helper:** `test/lockspire/web/live/admin/design_system_contract_test.exs` lines 1515-1535.

```elixir
defp inventory_row!(inventory, route) do
  row_prefix = "| `#{route}` |"

  inventory
  |> String.split("\n")
  |> Enum.find(&String.starts_with?(&1, row_prefix))
  |> case do
    nil -> flunk("missing inventory row for #{route}")
    row -> row
  end
end

defp mounted_admin_routes(router_source) do
  ~r/live\(\s*"([^"]+)"/
  |> Regex.scan(router_source, capture: :all_but_first)
  |> List.flatten()
  |> Enum.map(&mounted_admin_route/1)
end
```

### Component Stress And Internal Lab Boundary

**Use for:** PROOF-03 rendered component stress, redaction-safe fixture checks, no public lab route claims.

**Fixtures analog:** `test/support/lockspire/web/admin_lab/fixtures.ex` lines 42-53, 55-64, 154-192.

```elixir
@forbidden_substrings [
  "real-client-secret",
  "production-secret",
  "prod-access-token",
  "prod-refresh-token",
  "customer.example.com",
  "tenant.example.com",
  "sk_live_",
  "pk_live_",
  "eyJhbGci",
  "BEGIN PRIVATE KEY"
]
```

```elixir
status_matrix: [
  %{domain: :configure, status: :active},
  %{domain: :configure, status: :open},
  %{domain: :support, status: :pending},
  %{domain: :operate, status: :retryable},
  %{domain: :support, status: :reuse_detected},
  %{domain: :support, status: :expired},
  %{domain: :support, status: :unknown_lab_only}
],
theme_modes: [:light, :dark, :system],
motion_modes: [:default, :reduced_motion]
```

**Renderer analog:** `test/support/lockspire/web/admin_lab/stress_surface.ex` lines 1-19, 30-55, 191-217, 228-252.

```elixir
defmodule Lockspire.Web.AdminLab.StressSurface do
  @moduledoc false

  use Phoenix.Component

  alias Lockspire.Web.AdminLab.Fixtures
  alias Lockspire.Web.Components.AdminComponents

  attr(:fixture_set, :map, required: true)
```

```elixir
<section
  data-lab-surface="component-stress"
  data-theme-mode="light dark system"
  data-motion-mode="default reduced-motion"
  aria-label="Render stress surface"
>
```

**Stress test analog:** `test/lockspire/web/live/admin/design_system_component_stress_test.exs` lines 13-58, 61-174, 195-209.

```elixir
fixture_blob = inspect(Fixtures.all())

for forbidden <- Fixtures.forbidden_substrings() do
  refute fixture_blob =~ forbidden
end
```

```elixir
html = render_component(&StressSurface.render/1, fixture_set: Fixtures.all())

for marker <- [
      ~s(data-lab-surface="component-stress"),
      ~s(data-theme-mode="light dark system"),
      ~s(data-motion-mode="default reduced-motion")
    ] do
  assert html =~ marker
end
```

```elixir
for forbidden <- ["component-lab", "component_lab", "design-system-lab", "design_system_lab"] do
  refute router =~ forbidden
  refute supported_surface =~ forbidden
end
```

### Phoenix Component And CSS Contracts

**Use for:** rendered assertions, accessibility hooks, long-value wrapping, responsive table/list alternatives, reduced-motion and theme proof.

**Component analog:** `lib/lockspire/web/components/admin_components.ex` lines 50-94, 100-152, 239-291, 419-520, 533-581.

```elixir
attr(:title, :string, required: true)
attr(:subtitle, :string, default: nil)
attr(:class, :string, default: "")
attr(:rest, :global)
slot(:status)
slot(:actions)
slot(:inner_block, required: true)

def pane(assigns) do
  ~H"""
  <section class={["lockspire-admin-pane", @class]} {@rest}>
```

```elixir
def admin_button(assigns) do
  assigns = assign(assigns, :class, button_class(assigns.variant))

  ~H"""
  <a :if={@href && !@disabled} href={@href} class={@class} {@rest}>
    {render_slot(@inner_block)}
  </a>
  <span :if={@href && @disabled} role="link" aria-disabled="true" class={@class} {@rest}>
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
```

```elixir
def responsive_table(assigns) do
  ~H"""
  <div class={["lockspire-admin-responsive-table", @class]}>
    <div class="lockspire-admin-table-wrap">
      <table class="lockspire-admin-table">
```

**CSS analog:** `lib/lockspire/web/admin_css.ex` lines 1-7, 228-248, 636-717, 800-810, 1488-1515, 1608-1695.

```elixir
@css """
/* Lockspire Admin UI - Design Tokens & BEM Architecture */
:root {
  color-scheme: light;
```

```css
.lockspire-admin-nav-item:focus-visible,
.lockspire-admin-secondary-nav a:focus-visible,
.lockspire-admin-btn-primary:focus-visible,
.lockspire-admin-btn-secondary:focus-visible,
.lockspire-admin-btn-danger:focus-visible,
.lockspire-admin-resource-list a:focus-visible {
  outline: var(--ls-focus-ring-width) solid var(--ls-focus-ring-color);
  outline-offset: var(--ls-focus-ring-offset);
}
```

```css
@media (prefers-reduced-motion: reduce) {
  .lockspire-admin-shell *,
  .lockspire-admin-shell *::before,
  .lockspire-admin-shell *::after {
    animation-duration: 0.01ms !important;
    animation-iteration-count: 1 !important;
    scroll-behavior: auto !important;
    transition-duration: 0.01ms !important;
  }

  .lockspire-admin-btn-primary:active,
  .lockspire-admin-btn-secondary:active,
  .lockspire-admin-btn-danger:active {
    transform: none;
  }
}
```

```elixir
@dark_css """
:root[data-theme="light"] {
  color-scheme: light;
  --ls-text-accent: var(--ls-color-brand-600);
}

@media (prefers-color-scheme: dark) {
  :root:not([data-theme="light"]) {
  #{@dark_vars}
  }
```

### Admin Shell Theme Pattern

**Use for:** browser/manual proof of light/dark/system theme selector behavior and nav route grouping.

**Analog:** `lib/lockspire/web/live/admin_layout_live.ex` lines 15-58, 60-119, 123-170.

```elixir
assign(assigns, :nav_groups, [
  %{label: "Orient", items: [%{label: "Overview", key: :overview, href: admin_path("/"), enabled: true}]},
  %{label: "Configure", items: [
    %{label: "Clients", key: :clients, href: admin_path("/clients"), enabled: true},
    %{label: "Security", key: :policies, href: admin_path("/policies"), enabled: true},
    %{label: "Keys", key: :keys, href: admin_path("/keys"), enabled: true},
    %{label: "DCR", key: :dcr, href: admin_path("/dcr"), enabled: true}
  ]},
```

```javascript
const storageKey = "lockspire-admin-theme";
const root = document.documentElement;
const applyTheme = (theme) => {
  if (theme === "light" || theme === "dark") {
    root.dataset.theme = theme;
  } else {
    root.removeAttribute("data-theme");
  }
```

### Focused Mounted LiveView Tests

**Use for:** route-specific rendered markup, stale link, read-only queue, redaction, and support copy assertions.

**Client detail analog:** `test/lockspire/web/live/admin/clients_live/show_test.exs` lines 179-252, 294-328.

```elixir
assert {:ok, _view, html} =
         live(conn_for_admin(), "/admin/clients/#{self_registered_client.client_id}")

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

assert html =~ "/admin/clients/#{self_registered_client.client_id}/edit?workflow=logout-propagation"
refute html =~ "sha256:show:hash"
refute html =~ "client_secret_hash"
```

```elixir
assert {:ok, _view, html} =
         live(
           conn_for_admin(),
           "/admin/clients/#{client.client_id}/edit?workflow=logout-propagation"
         )

assert html =~ "Update logout propagation"
assert html =~ "not post-logout redirects"
assert html =~ "durable back-channel delivery"
assert html =~ "front-channel logout stays best effort"
```

**Current stale link audit target:** `lib/lockspire/web/live/admin/clients_live/show.ex` lines 497-518.

```elixir
<AdminComponents.action_group>
  <:secondary>
    <.link class="lockspire-admin-btn lockspire-admin-btn-secondary" href={Lockspire.mount_path() <> "/admin/tokens"}>Review tokens</.link>
    <.link class="lockspire-admin-btn lockspire-admin-btn-secondary" href={Lockspire.mount_path() <> "/admin/consents"}>Review consent grants</.link>
    <.link class="lockspire-admin-btn lockspire-admin-btn-secondary" href={Lockspire.mount_path() <> "/admin/logout-deliveries"}>Review logout deliveries</.link>
  </:secondary>
</AdminComponents.action_group>
```

Planner should add/fix proof expecting `/admin/logouts` and rejecting `/admin/logout-deliveries`.

**DCR policy analog:** `test/lockspire/web/live/admin/policies_live/dcr_test.exs` lines 61-99.

```elixir
assert occurrence_count(html, ~s(phx-submit="save_policy")) == 1

for name <- [
      "policy[registration_policy]",
      "policy[dcr_allowed_scopes]",
      "policy[dcr_allowed_grant_types]",
      "policy[dcr_allowed_response_types]",
      "policy[dcr_allowed_redirect_uri_schemes]",
      "policy[dcr_allowed_redirect_uri_hosts]",
      "policy[dcr_allowed_token_endpoint_auth_methods]"
    ] do
  assert html =~ ~s(name="#{name}")
end
```

**IAT copy-once analog:** `test/lockspire/web/live/admin/iat_live_test.exs` lines 91-119.

```elixir
initial_html = render(view)
assert initial_html =~ "lockspire-admin-workflow-shell"
refute initial_html =~ "Initial access token minted"

html_after_mint =
  view
  |> element("form")
  |> render_submit(%{"single_use" => "true", "expires_in_days" => "30"})

assert html_after_mint =~ "Initial access token minted"
assert html_after_mint =~ "lockspire-admin-copy-once-secret"
assert html_after_mint =~ "Copy this value now. Lockspire stores only the hash after this response."
```

**Support detail analogs:** `test/lockspire/web/live/admin/tokens_live_test.exs` lines 130-159 and `test/lockspire/web/live/admin/consents_live_test.exs` lines 113-128.

```elixir
assert html =~ "Token health decision"
assert html =~ "Opaque tokens stay opaque here"
assert html =~ "lockspire-admin-confirmation-panel"
assert html =~ ~s(phx-submit="revoke_token")
assert html =~ ~s(phx-submit="revoke_family")
refute html =~ "token-ui-refresh-hash"
refute html =~ "family-ui-123"
refute html =~ "account-token-ui"
```

```elixir
assert html =~ "Stored grant decision"
assert html =~ "Durable consent truth"
assert html =~ ~s(phx-submit="revoke_consent")
assert html =~ "remembered grant will no longer"
refute html =~ "account-consent-ui"
refute html =~ "sha256:consent-ui:hash"
```

**Operate queue analogs:** `test/lockspire/web/live/admin/logout_deliveries_live_test.exs` lines 66-103, `device_authorizations_live_test.exs` lines 56-83, `interactions_live_test.exs` lines 44-75.

```elixir
assert Enum.any?(routes, &live_route?(&1, "/admin/logouts", Index))

assert page_html =~ "Operate"
assert page_html =~ "Logout propagation queue"
assert page_html =~ "Review logout deliveries"
assert page_html =~ "lockspire-admin-dense-resource-row"
refute page_html =~ "<table"
refute page_html =~ "lockspire-admin-table-wrap"
refute page_html =~ "phx-click"
refute page_html =~ "phx-submit"
```

### Docs Boundary Pattern

**Use for:** PROOF-04 docs update and public support ceiling.

**Operator docs analog:** `docs/operator-admin.md` lines 18-35, 50-64, 81-95, 116-130.

```markdown
Mount the operator UI behind your host application's operator-auth pipeline. Lockspire does not authenticate your staff or decide who counts as an operator.
```

```markdown
Theme behavior is intentionally narrow:

- **System** is the default and follows `prefers-color-scheme`.
- **Light** and **Dark** are explicit admin-only choices exposed in the shell theme selector.
- The selector persists only a local browser preference for the Lockspire admin surface.
- The host app still owns outer access control, staff identity, product layout, and any policy framing around the mounted admin router.
```

**Supported surface analog:** `docs/supported-surface.md` lines 1-7, 113-137, 148-168.

Use this as the ceiling. Update it only if Phase 120 finds a concrete ambiguity. Do not add component lab, browser proof, screenshots, Playwright, axe, or public theming claims here.

### Maintainer Command And Browser Evidence Pattern

**Use for:** optional PROOF-02 browser/manual command shape.

**Shell wrapper analog:** `scripts/demo/adoption_smoke.sh` lines 1-47.

```sh
#!/usr/bin/env sh
set -eu

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$REPO_ROOT"

BASE_URL="${LOCKSPIRE_DEMO_BASE_URL:-$DEFAULT_BASE_URL}"
BASE_URL="${BASE_URL%/}"

echo "Running adoption demo smoke against ${BASE_URL}"
LOCKSPIRE_DEMO_BASE_URL="${BASE_URL}" exec python3 scripts/demo/adoption_smoke.py
```

**Black-box route proof analog:** `scripts/demo/adoption_smoke.py` lines 157-207.

```python
admin = browser.request("GET", "/lockspire/admin")
assert_status(admin, 200, "operator admin access")
assert_contains(admin, "lockspire-admin-shell", "admin design system shell")
assert_contains(admin, "data-lockspire-theme-select", "admin theme selector")
assert_contains(admin, "--ls-text-accent", "admin embedded semantic tokens")

for route in [
    "/lockspire/admin/clients",
    "/lockspire/admin/policies",
    "/lockspire/admin/keys",
    "/lockspire/admin/dcr",
    "/lockspire/admin/consents",
    "/lockspire/admin/tokens",
    "/lockspire/admin/interactions",
    "/lockspire/admin/device_authorizations",
    "/lockspire/admin/logouts",
]:
    page = browser.request("GET", route)
    assert_status(page, 200, f"operator admin route {route}")
    assert_contains(page, "lockspire-admin-shell", f"admin shell on {route}")
```

**Proof artifact analog:** `.planning/phases/110-demo-state-screenshots-docs-and-regression-proof/110-SCREENSHOTS.md` lines 1-8, 9-12, 43-48.

Reuse the table style, but add Phase 120 columns for viewport, theme, motion, accessibility note, sensitive evidence check, and gap note. Keep screenshots as evidence only.

## Recommended File Homes

| Need | Recommended Home | Pattern To Copy | Notes |
|------|------------------|-----------------|-------|
| Phase 120 route/browser/manual evidence | `.planning/phases/120-browser-proof-docs-regression-audit/120-BROWSER-PROOF.md` | `110-SCREENSHOTS.md` table shape | Planning evidence only. Include commands, route/JTBD matrix, viewport/theme/motion coverage, screenshots/report paths, gaps, and final adversarial audit. |
| Source/docs/CSS/package boundary guardrails | extend `test/lockspire/web/live/admin/design_system_contract_test.exs` | same file lines 1-35, 274-354, 1359-1535 | Keep fast deterministic ExUnit as blocking proof. |
| Rendered component stress | extend `test/lockspire/web/live/admin/design_system_component_stress_test.exs` | same file lines 13-58, 61-174, 195-209 | Use real `AdminComponents`, not snapshots or public lab routes. |
| Rendered DOM helpers for IDs/ARIA/labels/redaction | `test/support/lockspire/web/admin_proof/html_assertions.ex` if helpers outgrow inline functions | `design_system_contract_test.exs` helper style lines 1515-1535 | Use LazyHTML-style structured DOM queries. Avoid regex-only proof for rendered relationships. |
| Stale route/link and real page assertions | existing focused admin tests under `test/lockspire/web/live/admin/` and `test/lockspire/web/admin_router_test.exs` | route tests listed above | Prefer mounted `live/2` tests for shell/nav/links where possible. |
| Operator docs update | `docs/operator-admin.md` | lines 18-35 and 50-64 | Add a short v1.31 workflow/proof-boundary section. |
| Public support ceiling | `docs/supported-surface.md` | lines 1-7, 113-137, 148-168 | Avoid changes unless a concrete ambiguity appears. |
| Optional browser/manual proof command | `scripts/maintainer/admin_browser_proof` | `scripts/demo/adoption_smoke.sh` | Maintainer-only. Write reports/screenshots under `tmp/admin-ui-polish/phase-120/`. |
| Optional Playwright/axe config/spec | only after `checkpoint:human-verify` | no local exact analog | Keep dev/test only, outside Hex runtime/package support claims, with manual fallback documented. |

## Tiny Route/Test/Docs Analog Matrix

| Route / Surface | Journey | Test Analog | Docs / Proof Analog | Phase 120 Use |
|-----------------|---------|-------------|---------------------|---------------|
| `/admin`, `/admin/overview` | Orient | `test/lockspire/web/admin_router_test.exs` lines 4-50; `adoption_smoke.py` lines 186-207 | `docs/operator-admin.md` lines 7-16, 37-48 | Shell, nav grouping, theme selector, overview route proof. |
| `/admin/clients/:client_id` | Configure | `test/lockspire/web/live/admin/clients_live/show_test.exs` lines 179-252 | `docs/operator-admin.md` lines 81-95 | Client workspace structure, redaction, action destinations, stale logout link. |
| `/admin/clients/:client_id/edit?workflow=logout-propagation` | Configure | `show_test.exs` lines 294-328; `show.ex` lines 755-759 | `116-ROUTE-WORKFLOW-INVENTORY.md` line 25; `docs/operator-admin.md` lines 83-87 | Query workflow proof. Not a router expansion. |
| `/admin/policies/dcr` | Configure | `test/lockspire/web/live/admin/policies_live/dcr_test.exs` lines 61-99 | `docs/operator-admin.md` lines 72-79 | One grouped form, unchanged field names, no broad risk language. |
| `/admin/iats`, `/admin/iats/new` | Configure | `test/lockspire/web/live/admin/iat_live_test.exs` lines 56-75, 91-119 | `docs/operator-admin.md` lines 72-79 | Copy-once IAT proof, secret redaction, form help IDs. |
| `/admin/tokens/:id` | Support | `test/lockspire/web/live/admin/tokens_live_test.exs` lines 130-159 | `docs/operator-admin.md` lines 11-14, 37-46 | Token detail redaction and revoke/family consequence copy. |
| `/admin/consents/:id` | Support | `test/lockspire/web/live/admin/consents_live_test.exs` lines 113-128 | `docs/operator-admin.md` lines 11-14, 37-46 | Grant detail redaction and revoke consequence copy. |
| `/admin/device_authorizations` | Operate | `device_authorizations_live_test.exs` lines 56-83 | `116-ROUTE-WORKFLOW-INVENTORY.md` line 42 | Read-only queue, no code material, no unsupported controls. |
| `/admin/interactions` | Operate | `interactions_live_test.exs` lines 44-75 | `116-ROUTE-WORKFLOW-INVENTORY.md` line 38 | Read-only queue, dense rows, no phx actions. |
| `/admin/logouts` | Operate | `logout_deliveries_live_test.exs` lines 66-103 | `116-ROUTE-WORKFLOW-INVENTORY.md` line 39; `docs/operator-admin.md` line 14 | Supported logout route and stale `/admin/logout-deliveries` rejection. |
| `AdminLab.StressSurface` | internal lab | `design_system_component_stress_test.exs` lines 61-174 | `116-LAB-CONTRACT.md` lines 1-18, 30-45 | Component state proof only. Never route or public support truth. |

## Anti-Patterns And Footguns

| Footgun | Avoid | Use Instead |
|---------|-------|-------------|
| Public browser tooling claims | Do not say Lockspire ships Playwright/axe, a browser testing product, or public visual regression support. | Label any browser lane as maintainer-only proof in `120-BROWSER-PROOF.md`; guard `docs/supported-surface.md` and package metadata. |
| Public lab routes | Do not add `component_lab`, `design_system_lab`, Storybook, or lab routes to `AdminRouter`. | Keep `AdminLab.Fixtures` and `AdminLab.StressSurface` under `test/support`. |
| Screenshot-as-source-of-truth | Do not derive route coverage from `tmp/admin-ui-polish/` filenames or Phase 110 screenshots. | Derive from `AdminRouter` plus the one locked query workflow, then attach screenshots as evidence. |
| Support boundary creep | Do not expand `docs/supported-surface.md` with design-system internals, browser tooling, public theming, or lab claims. | Update `docs/operator-admin.md` with a bounded v1.31 workflow/proof note; leave support ceiling unchanged unless ambiguity is concrete. |
| Stale logout route | Do not preserve `/admin/logout-deliveries` in client support pivots or browser route proof. | Use `/admin/logouts`; add test coverage that rejects `/admin/logout-deliveries`. |
| Sensitive evidence | Do not commit screenshots/reports/traces/docs containing secrets, tokens, cookies, private keys, auth codes, verifier material, user codes, real tenant hostnames, or token-looking JWT strings. | Use redaction-safe fixtures/seeds, denylist checks, and `tmp/admin-ui-polish/phase-120/` as local evidence output. |
| Axe as certification | Do not claim WCAG certification from axe or browser scans. | Treat scans as supplemental; keep manual keyboard/focus/copy/screen-reader-risk review in the final audit. |
| Operation queue actions | Do not add retry, discard, approval, logout, requeue, or worker controls unless existing domain APIs already back them. | Assert queues remain read-only with `refute page_html =~ "phx-click"` / `phx-submit` and denylisted action labels. |
| Full cartesian browser matrix | Do not require every route x width x theme x motion combination. | Use a representative risk matrix that explicitly covers 320, 390, 768, 1024, 1440, light, dark, system, and reduced motion. |
| Optional package drift | Do not install Playwright/axe without the required human verification checkpoint. | Keep `checkpoint:human-verify`; if declined, record manual browser evidence against the same matrix. |

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| optional Playwright/axe package/config/spec files | test/tooling | request-response | The repo has no `package.json`, Playwright config, Node browser harness, or axe harness. Research marks current optional npm packages as `SUS` due recent publishes and requires human verification before install. |

## Metadata

**Analog search scope:** `.planning/phases/116-*`, `.planning/phases/117-*`, `.planning/phases/118-*`, `.planning/phases/119-*`, `.planning/phases/120-*`, `lib/lockspire/web/**`, `test/lockspire/web/live/admin/**`, `test/support/lockspire/web/admin_lab/**`, `docs/operator-admin.md`, `docs/supported-surface.md`, `scripts/demo/adoption_smoke.*`.

**Files scanned:** 30+ planning/source/test/doc/script files via targeted `rg`, `wc`, and numbered reads.

**Pattern extraction date:** 2026-06-26.
