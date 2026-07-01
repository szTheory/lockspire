# Phase 117: Component Lab, Fixtures & Foundation Hardening - Pattern Map

**Mapped:** 2026-06-25
**Files analyzed:** 7
**Analogs found:** 7 / 7

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `test/support/lockspire/web/admin_lab/fixtures.ex` or equivalent internal fixture module | utility | transform | `.planning/phases/116-inventory-rubric-lab-contract/116-LAB-CONTRACT.md` + `test/lockspire/web/live/admin/design_system_component_stress_test.exs` | role-match |
| `test/support/lockspire/web/admin_lab/stress_surface.ex` or equivalent internal renderer | component | transform | `test/lockspire/web/live/admin/design_system_component_stress_test.exs` | exact |
| `test/lockspire/web/live/admin/design_system_component_stress_test.exs` | test | transform | same file | exact |
| `lib/lockspire/web/admin_css.ex` | config | transform | same file | exact |
| `test/lockspire/web/live/admin/design_system_contract_test.exs` | test | transform | same file | exact |
| `lib/lockspire/web/admin_router.ex` | route | request-response | same file + Phase 116 lab boundary test | exact |
| optional `proof/browser/*` or `scripts/browser-proof/*` files | config/test | request-response | no existing browser harness; use Phase 117 research boundary | no-analog |

## Pattern Assignments

### `test/support/lockspire/web/admin_lab/fixtures.ex` or equivalent internal fixture module (utility, transform)

**Analog:** `.planning/phases/116-inventory-rubric-lab-contract/116-LAB-CONTRACT.md` and existing stress-test literals.

**Boundary and safety pattern** from `.planning/phases/116-inventory-rubric-lab-contract/116-LAB-CONTRACT.md` (lines 20-28, 30-45):

```markdown
- ExUnit-rendered HEEx and Phoenix function components.
- Repo-local fixture modules in later phases.
- Demo-only fixture data with safe placeholders.
- Maintainer screenshots and browser evidence in later CSS/component/page proof phases.
- Source-derived route/component inventory tests.

Allowed classifications are `internal_lab`, `test_only`, and `demo_only`; the lab is never `admin_supported`.
```

```markdown
Fixtures, screenshots, logs, docs, tests, and lab states must not expose:

- client secrets
- registration access token plaintext
- initial access token plaintext after creation
- refresh/access token plaintext
- authorization codes
- cookies
- private keys
- verifier material
- user codes
- unredacted sensitive values

Hostile data is encouraged when redaction-safe: long URLs, long client IDs, dense scopes, disabled actions, destructive confirmations, empty/error states, status clusters, copy-once panels with safe placeholders, light/dark/system themes, reduced-motion states, focus paths, and narrow mobile widths.
```

**Existing safe fixture literal pattern** from `test/lockspire/web/live/admin/design_system_component_stress_test.exs` (lines 44-58, 86-99):

```elixir
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
```

```elixir
<AdminComponents.form_field
  id="stress-read-only-secret"
  label="Client secret hash"
  help="Stored hash is shown for correlation only."
>
  <input id="stress-read-only-secret" readonly value="redacted_handle_secret_hash_v1" />
</AdminComponents.form_field>

<AdminComponents.copy_once_secret_panel
  title="Copy-once credential"
  body="Copy this value now. Lockspire stores only the hash after this response."
  value="iat_copy-once_01HY6Q1P8Y4R5T6U7V8W9X0Y1Z"
/>
```

**Planner instruction:** Extract the hardcoded test literals into named fixture groups: clients, tokens, consents, keys, DCR/IAT, and operations. Use fake namespaces such as `client_`, `acct_`, `tok_`, and `.example.invalid`; use `redacted_handle_*`, `"Redacted"`, or safe copy-once placeholders for sensitive states.

---

### `test/support/lockspire/web/admin_lab/stress_surface.ex` or equivalent internal renderer (component, transform)

**Analog:** `test/lockspire/web/live/admin/design_system_component_stress_test.exs`.

**Imports/component module pattern** (lines 1-12):

```elixir
defmodule Lockspire.Web.Live.Admin.DesignSystemComponentStressTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  defmodule StressSurface do
    use Phoenix.Component

    alias Lockspire.Web.Components.AdminComponents

    def render(assigns) do
      ~H"""
```

**Core renderer pattern using real shared components** (lines 13-37):

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

<AdminComponents.metric_grid wide>
  <AdminComponents.summary_stat value="1,248" label="Active grants" />
  <AdminComponents.summary_stat value="0" label="Reusable plaintext secrets" />
  <AdminComponents.summary_stat value="99+" label="Warnings" />
</AdminComponents.metric_grid>
```

**Error, destructive, and empty-state pattern** (lines 62-118):

```elixir
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
    <AdminComponents.admin_button variant={:danger}>Revoke token family</AdminComponents.admin_button>
    <AdminComponents.admin_button>Keep token family active</AdminComponents.admin_button>
  </:actions>
</AdminComponents.confirmation_panel>

<AdminComponents.empty_state
  title="No logout deliveries match these filters"
  body="Clear the filters or inspect active interactions to find pending logout work."
/>
```

**Planner instruction:** Move this shape into a reusable module with `@moduledoc false`, `use Phoenix.Component`, `alias Lockspire.Web.Components.AdminComponents`, and an assign such as `:fixture_set`. Do not create a LiveView, router entry, public API, or host-editable registry.

---

### `test/lockspire/web/live/admin/design_system_component_stress_test.exs` (test, transform)

**Analog:** same file.

**Rendered HEEx assertion pattern** (lines 123-153):

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

**Planner instruction:** Keep ExUnit + `Phoenix.LiveViewTest.rendered_to_string/1` as the primary proof. Expand phrase/class assertions to cover LAB-02 and PROOF-01 states: normal, empty, error, disabled, destructive, long-value, dense-data, copy-once, redacted, light, dark, system, reduced-motion, healthy, warning, incident, disabled, self-registered, expired, revoked, and reuse-detected.

---

### `lib/lockspire/web/admin_css.ex` (config, transform)

**Analog:** same file.

**Token/theme import pattern** (lines 1-7, 82-111):

```elixir
defmodule Lockspire.Web.Admin.CSS do
  @moduledoc false

  @css """
  /* Lockspire Admin UI - Design Tokens & BEM Architecture */
  :root {
    /* Spacing Scale (4px baseline) */
```

```css
/* Transitions */
--ls-motion-duration-fast: 150ms;
--ls-motion-duration-medium: 220ms;
--ls-motion-ease-standard: cubic-bezier(0.4, 0, 0.2, 1);
--ls-motion-property-feedback: background-color, border-color, color, box-shadow, transform;
--ls-transition-fast: var(--ls-motion-duration-fast) var(--ls-motion-ease-standard);

/* Semantic Token Aliases */
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
--ls-status-warning-bg: var(--ls-color-warning-bg);
--ls-status-warning-text: var(--ls-color-warning-text);
--ls-status-warning-border: var(--ls-color-warning-border);
--ls-status-danger-bg: var(--ls-color-danger-bg);
--ls-status-danger-text: var(--ls-color-danger-text);
--ls-status-danger-border: var(--ls-color-danger-border);
--ls-status-info-bg: var(--ls-color-info-bg);
--ls-status-info-text: var(--ls-color-info-text);
--ls-status-info-border: var(--ls-color-info-border);
```

**Motion pattern** (lines 518-520, 545-547, 572-574, 1483-1497):

```css
transition-property: var(--ls-motion-property-feedback);
transition-duration: var(--ls-motion-duration-fast);
transition-timing-function: var(--ls-motion-ease-standard);
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

**Dark/system theme pattern** (lines 1501-1557):

```elixir
# Dark mode mirrors the brandbook: primitives remain stable and only semantic
# aliases remap. Components consume aliases so theme changes do not require
# component-specific overrides.
@dark_vars """
  color-scheme: dark;

  --ls-surface-page: var(--ls-color-gray-950);
  --ls-surface-panel: #131c2e;
  --ls-surface-muted: var(--ls-color-gray-800);
  --ls-surface-inverse: var(--ls-color-gray-50);
  --ls-text-strong: var(--ls-color-gray-50);
  --ls-text-body: #c9d4e3;
  --ls-text-muted: #8a99ad;
  --ls-text-accent: var(--ls-color-brand-500);
  --ls-border-subtle: #1e293b;
  --ls-border-strong: #334155;
"""

@dark_css """
@media (prefers-color-scheme: dark) {
  :root:not([data-theme="light"]) {
  #{@dark_vars}
  }
  :root:not([data-theme="light"]) .lockspire-admin-btn-primary { #{@dark_btn} }
  :root:not([data-theme="light"]) .lockspire-admin-btn-primary:hover { background-color: var(--ls-color-brand-100); }
}
:root[data-theme="dark"] {
#{@dark_vars}
}
:root[data-theme="dark"] .lockspire-admin-btn-primary { #{@dark_btn} }
:root[data-theme="dark"] .lockspire-admin-btn-primary:hover { background-color: var(--ls-color-brand-100); }
"""

def get, do: @css <> @dark_css
```

**Planner instruction:** Harden this module in-place. Add explicit light/default `color-scheme: light` behavior without duplicating primitive tokens in dark blocks. Preserve semantic dark remapping and explicit transition properties. Add/adjust reduced-motion rules for any active transforms introduced by Phase 117.

---

### `test/lockspire/web/live/admin/design_system_contract_test.exs` (test, transform)

**Analog:** same file.

**Source path setup pattern** (lines 1-31):

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
```

**Dark token and reduced motion assertions** (lines 218-254):

```elixir
for token <- [
      "--ls-color-gray-50",
      "--ls-color-gray-100",
      "--ls-color-gray-200",
      "--ls-color-gray-300",
      "--ls-color-gray-400",
      "--ls-color-gray-500",
      "--ls-color-gray-600",
      "--ls-color-gray-700",
      "--ls-color-brand-600",
      "--ls-color-success-bg"
    ] do
  assert ~r/#{Regex.escape(token)}:/ |> Regex.scan(css) |> length() == 1
end

assert css =~ "--ls-status-success-bg: var(--ls-color-success-bg-dark);"
assert css =~ "--ls-text-accent: var(--ls-color-brand-500);"
```

```elixir
test "reduced motion neutralizes animation duration, transition duration, and active transforms" do
  css = File.read!(@admin_css_path)

  assert css =~ "@media (prefers-reduced-motion: reduce)"
  assert css =~ "transition-duration: 0.01ms !important"
  assert css =~ "animation-duration: 0.01ms !important"

  for selector <- [
        ".lockspire-admin-btn-primary:active",
        ".lockspire-admin-btn-secondary:active",
        ".lockspire-admin-btn-danger:active"
      ] do
    assert css =~ selector
  end

  assert css =~ "transform: none;"
end
```

**Component/CSS contract assertion pattern** (lines 270-333):

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

**Helper pattern for source contracts** (lines 1090-1126):

```elixir
defp css_rule(css, selector) do
  pattern = ~r/#{Regex.escape(selector)}\s*\{(?<body>.*?)\}/s

  case Regex.named_captures(pattern, css) do
    %{"body" => body} -> body
    nil -> flunk("missing CSS selector #{selector}")
  end
end

defp css_media_rule(css, media_query) do
  case :binary.match(css, media_query) do
    {start, _length} ->
      rest = String.slice(css, start..-1//1)
      # ...
    :nomatch ->
      flunk("missing CSS media query #{media_query}")
  end
end
```

**Planner instruction:** Extend this file with contract tests for `color-scheme: light`, no `transition: all`, explicit transition properties, reduced-motion active-transform coverage, no lab route/docs claim, and optional browser-proof quarantine/package boundary if adopted.

---

### `lib/lockspire/web/admin_router.ex` (route, request-response)

**Analog:** same file and Phase 116 boundary test.

**Supported route source pattern** from `lib/lockspire/web/admin_router.ex` (lines 1-15, 73-85):

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

**Boundary test pattern** from `test/lockspire/web/live/admin/design_system_contract_test.exs` (lines 982-1025):

```elixir
@tag :phase_116_lab_contract
test "phase 116 lab contract keeps maintainer proof out of supported routes" do
  contract = File.read!(phase_116_path("116-LAB-CONTRACT.md"))
  router = File.read!(@admin_router_path)

  supported_surface =
    File.read!(Path.expand("../../../../../docs/supported-surface.md", __DIR__))

  for phrase <- [
        "maintainer/demo/test-only",
        "not a supported admin route",
        "public API",
        "not mount through Lockspire.Web.AdminRouter",
        "internal_lab",
        "test_only",
        "demo_only",
        "never `admin_supported`"
      ] do
    assert contract =~ phrase
  end

  refute router =~ "component_lab"
  refute router =~ "design_system_lab"

  supported_surface = String.downcase(supported_surface)

  for forbidden <- ["component lab", "design system lab", "design-system lab"] do
    refute supported_surface =~ forbidden
  end
end
```

**Planner instruction:** Do not add any route to `AdminRouter`. If Phase 117 touches docs or proof tooling, keep this boundary assertion updated.

---

### Optional `proof/browser/*` or `scripts/browser-proof/*` files (config/test, request-response)

**Analog:** No existing browser-proof harness in this codebase.

**Closest boundary source:** `117-RESEARCH.md` and `117-UI-SPEC.md` state Playwright/axe are optional, suspicious-by-recency, and require a human verification checkpoint before install. Browser proof must remain quarantined and outside Hex package files.

**Planner instruction:** Treat browser proof as optional. If adopted, put it under `proof/browser/` or `scripts/browser-proof/`, do not add it to `mix.exs` package files or supported docs, and add a `checkpoint:human-verify` before npm install. Core Phase 117 can complete with ExUnit-rendered stress surface and source contract tests.

## Shared Patterns

### Phoenix Component Shape

**Source:** `lib/lockspire/web/components/admin_components.ex` lines 1-4, 35-57, 273-340.

Use `@moduledoc false`, `use Phoenix.Component`, attrs/slots, `~H`, and `render_slot/1`. Lab code should call `AdminComponents`; it should not duplicate production component markup.

### Redaction

**Source:** `lib/lockspire/web/components/admin_components.ex` lines 302-340 and Phase 116 lab contract lines 30-45.

Copy-once panels support `redacted: true` and render `"Redacted"` when no value or redacted. Long values support `redacted: true`. Fixtures must not contain real secrets, token plaintext, authorization codes, cookies, private keys, verifier material, or user codes.

### Theme And Motion

**Source:** `lib/lockspire/web/admin_css.ex` lines 82-87, 1483-1497, 1501-1557.

Use explicit transition properties and duration tokens. Reduced motion must neutralize animation and transition duration and active transforms. Dark mode remaps semantic aliases; primitive tokens stay stable.

### Source Contract Testing

**Source:** `test/lockspire/web/live/admin/design_system_contract_test.exs` lines 1-31, 218-254, 270-333, 1090-1126.

Prefer deterministic source assertions for CSS/theme/motion/router/docs boundaries. Use path module attributes, `File.read!/1`, regex helpers, and clear `assert`/`refute` lists.

### Lab Boundary

**Source:** `.planning/phases/116-inventory-rubric-lab-contract/116-LAB-CONTRACT.md` lines 1-18 and `test/lockspire/web/live/admin/design_system_contract_test.exs` lines 982-1025.

The lab is `internal_lab`, `test_only`, or `demo_only`; it is never `admin_supported`. Do not mount it through `Lockspire.Web.AdminRouter`, publish a public API, or add public support claims.

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| optional `proof/browser/*` or `scripts/browser-proof/*` | config/test | request-response | No existing Playwright/axe or browser-proof harness exists in the repo; Phase 117 research keeps this optional and checkpointed. |

## Metadata

**Analog search scope:** `.planning/phases/117-*`, `.planning/phases/116-*`, `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`, `lib/lockspire/web/**`, `test/lockspire/web/live/admin/**`, `docs/supported-surface.md`.
**Files scanned:** 16 primary files plus targeted `rg` matches.
**Pattern extraction date:** 2026-06-25.
