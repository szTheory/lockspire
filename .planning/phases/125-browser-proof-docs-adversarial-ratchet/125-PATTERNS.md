# Phase 125: Browser Proof, Docs & Adversarial Ratchet - Pattern Map

**Mapped:** 2026-06-30
**Files analyzed:** 25 planned or conditional new/modified files
**Analogs found:** 25 / 25

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `test/support/lockspire/web/admin_proof/sensitive_values.ex` | utility | transform | `test/support/lockspire/web/admin_proof/html_assertions.ex` + `test/support/lockspire/web/admin_lab/fixtures.ex` | role-match |
| `test/support/lockspire/web/admin_proof/browser_evidence.ex` | utility | file-I/O + transform | `test/support/lockspire/web/admin_proof/route_scorecards.ex` | role-match |
| `test/support/lockspire/web/admin_proof/html_assertions.ex` | utility | transform | `test/support/lockspire/web/admin_proof/html_assertions.ex` | exact/self |
| `test/support/lockspire/web/admin_proof/route_scorecards.ex` | utility | file-I/O + transform | `test/support/lockspire/web/admin_proof/route_scorecards.ex` | exact/self |
| `test/support/lockspire/web/admin_lab/fixtures.ex` | utility | batch + transform | `test/support/lockspire/web/admin_lab/fixtures.ex` | exact/self |
| `test/support/lockspire/web/admin_lab/stress_surface.ex` | component | transform | `test/support/lockspire/web/admin_lab/stress_surface.ex` | exact/self |
| `test/lockspire/web/live/admin/design_system_contract_test.exs` | test | batch + file-I/O + transform | `test/lockspire/web/live/admin/design_system_contract_test.exs` | exact/self |
| `test/lockspire/web/live/admin/design_system_component_stress_test.exs` | test | transform | `test/lockspire/web/live/admin/design_system_component_stress_test.exs` | exact/self |
| `test/lockspire/web/live/admin/tokens_live_test.exs` | test | request-response + CRUD | `test/lockspire/web/live/admin/tokens_live_test.exs` | exact/self |
| `test/lockspire/web/live/admin/consents_live_test.exs` | test | request-response + CRUD | `test/lockspire/web/live/admin/tokens_live_test.exs` | role-match |
| `test/lockspire/web/live/admin/interactions_live_test.exs` | test | request-response | `test/lockspire/web/live/admin/tokens_live_test.exs` + `.planning/phases/123-operate-queue-flow-polish/123-OPERATE-PROOF.md` | role-match |
| `test/lockspire/web/live/admin/device_authorizations_live_test.exs` | test | request-response | `test/lockspire/web/live/admin/tokens_live_test.exs` + `.planning/phases/123-operate-queue-flow-polish/123-OPERATE-PROOF.md` | role-match |
| `test/lockspire/web/live/admin/logout_deliveries_live_test.exs` | test | request-response | `test/lockspire/web/live/admin/tokens_live_test.exs` + `.planning/phases/123-operate-queue-flow-polish/123-OPERATE-PROOF.md` | role-match |
| `test/lockspire/web/live/admin/clients_live_test.exs` | test | request-response + CRUD | `test/lockspire/web/live/admin/tokens_live_test.exs` + `design_system_contract_test.exs` Phase 124 section | role-match |
| `test/lockspire/web/live/admin/clients_live/show_test.exs` | test | request-response + CRUD | `test/lockspire/web/live/admin/tokens_live_test.exs` + `design_system_contract_test.exs` Phase 124 section | role-match |
| `test/lockspire/web/live/admin/iat_live_test.exs` | test | request-response + CRUD | `test/lockspire/web/live/admin/tokens_live_test.exs` + `design_system_component_stress_test.exs` Phase 124 stress proof | role-match |
| `test/lockspire/web/live/admin/keys_live_test.exs` | test | request-response + CRUD | `test/lockspire/web/live/admin/tokens_live_test.exs` + `design_system_contract_test.exs` Phase 124 section | role-match |
| `test/lockspire/web/live/admin/policies_live/index_test.exs` | test | request-response + CRUD | `test/lockspire/web/live/admin/tokens_live_test.exs` + `design_system_contract_test.exs` Phase 124 section | role-match |
| `test/lockspire/web/live/admin/policies_live/dcr_test.exs` | test | request-response + CRUD | `test/lockspire/web/live/admin/tokens_live_test.exs` + `design_system_contract_test.exs` Phase 124 section | role-match |
| `test/lockspire/web/live/admin/policies_live/par_test.exs` | test | request-response + CRUD | `test/lockspire/web/live/admin/tokens_live_test.exs` + `design_system_contract_test.exs` Phase 124 section | role-match |
| `test/lockspire/web/live/admin/policies_live/dpop_test.exs` | test | request-response + CRUD | `test/lockspire/web/live/admin/tokens_live_test.exs` + `design_system_contract_test.exs` Phase 124 section | role-match |
| `test/lockspire/web/live/admin/policies_live/security_profile_test.exs` | test | request-response + CRUD | `test/lockspire/web/live/admin/tokens_live_test.exs` + `design_system_contract_test.exs` Phase 124 section | role-match |
| `test/lockspire/web/live/admin/overview_live_test.exs` | test | request-response | `test/lockspire/web/live/admin/tokens_live_test.exs` + `.planning/phases/120-browser-proof-docs-regression-audit/120-BROWSER-PROOF.md` | role-match |
| `docs/operator-admin.md` | documentation | file-I/O | `docs/operator-admin.md` | exact/self |
| `.planning/phases/125-browser-proof-docs-adversarial-ratchet/125-V1.32-PROOF.md` | test artifact | batch + file-I/O | `.planning/phases/120-browser-proof-docs-regression-audit/120-BROWSER-PROOF.md` | exact |

Conditional no-edit file: `docs/supported-surface.md` should stay unchanged unless implementation finds a concrete public-support ambiguity. If edited, copy the support-ceiling style from `docs/supported-surface.md` lines 1-7, 113-138, and 150-168.

## Pattern Assignments

### `test/support/lockspire/web/admin_proof/sensitive_values.ex` (utility, transform)

**Analog:** `test/support/lockspire/web/admin_proof/html_assertions.ex` and `test/support/lockspire/web/admin_lab/fixtures.ex`

Use this helper only if duplicated sensitive-value checks appear across rendered tests, source contracts, docs scans, and evidence parsing. Keep it test-only under `AdminProof`.

**Imports/module pattern** (`html_assertions.ex` lines 1-13):

```elixir
defmodule Lockspire.Web.AdminProof.HtmlAssertions do
  @moduledoc false

  import ExUnit.Assertions

  @generic_cta_text [
    "Click here",
    "Learn more",
    "Read more",
    "Submit"
  ]

  def document(html) when is_binary(html), do: LazyHTML.from_fragment(html)
```

**Shared denylist shape** (`fixtures.ex` lines 42-53, 196-198):

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

def scenario_states, do: @scenario_states
def fixture_keys, do: @fixture_keys
def forbidden_substrings, do: @forbidden_substrings
```

**Assertion return pattern** (`html_assertions.ex` lines 176-183):

```elixir
def assert_no_text(html, denied_values) when is_list(denied_values) do
  source = html_source(html)

  for denied <- denied_values, is_binary(denied), denied != "" do
    refute source =~ denied, "expected rendered HTML to omit denied text #{inspect(denied)}"
  end

  html
end
```

**Implementation guidance:** expose pure functions such as `denied_values/0` and assertion wrappers returning the original input, following `HtmlAssertions`. Do not create runtime APIs, app config, or public docs promises.

---

### `test/support/lockspire/web/admin_proof/browser_evidence.ex` (utility, file-I/O + transform)

**Analog:** `test/support/lockspire/web/admin_proof/route_scorecards.ex`

Use this only if `125-V1.32-PROOF.md` row parsing/scrubbing would otherwise duplicate logic in the contract test. Keep markdown parsing strict and failure messages specific.

**Constants and support-promise pattern** (`route_scorecards.ex` lines 4-49):

```elixir
@workflow_exception "/admin/clients/:client_id/edit?workflow=logout-propagation"

@required_fields [
  "Route",
  "Source truth",
  "Journey",
  "Persona",
  "JTBD",
  "Top task",
  "Who / What / Where / When / Why",
  "Entry point",
  "Primary decision",
  "Primary action",
  "Earned-place check",
  "Empty state",
  "Error state",
  "Long-data state",
  "Mobile risk",
  "Theme risk",
  "Focus/motion risk",
  "Redaction/security check",
  "Unsupported action check",
  "Follow-up route",
  "Component/group fit",
  "Evidence class",
  "Public support promise",
  "Runtime/package impact",
  "Notes"
]

@allowed_evidence_classes [
  "internal_lab",
  "rendered_guardrail",
  "manual_browser_note",
  "none"
]

@support_promise "This scorecard may reference maintainer-only lab/stress proof. That proof is not a supported admin route, public API, host extension point, theming interface, browser-testing product, or Hex package surface."

def workflow_exceptions, do: [@workflow_exception]
def required_fields, do: @required_fields
def allowed_evidence_classes, do: @allowed_evidence_classes
def support_promise, do: @support_promise
```

**Markdown parser pattern** (`route_scorecards.ex` lines 59-66, 68-82):

```elixir
def parse!(markdown) when is_binary(markdown) do
  {current, parsed} =
    markdown
    |> String.split("\n")
    |> Enum.reduce({nil, %{}}, &parse_line!/2)

  finalize_block!(current, parsed)
end

defp parse_line!(line, {current, parsed}) do
  case Regex.run(~r/^### Scorecard: `([^`]+)`\s*$/, line) do
    [_, route] ->
      parsed = finalize_block!(current, parsed)

      {%{route: route, lines: []}, parsed}

    nil ->
      if current do
        {Map.update!(current, :lines, &[line | &1]), parsed}
      else
        {current, parsed}
      end
  end
end
```

**Duplicate/missing-field error pattern** (`route_scorecards.ex` lines 86-114):

```elixir
defp finalize_block!(%{route: route, lines: lines}, parsed) do
  fields =
    lines
    |> Enum.reverse()
    |> Enum.reduce(%{}, fn line, fields ->
      case Regex.run(~r/^- \*\*([^*]+):\*\*\s*(.*)$/, line) do
        [_, field, value] ->
          if Map.has_key?(fields, field) do
            raise ArgumentError,
                  "duplicate field #{inspect(field)} in scorecard #{inspect(route)}"
          end

          Map.put(fields, field, String.trim(value))

        nil ->
          fields
      end
    end)

  unless Map.has_key?(fields, "Route") do
    raise ArgumentError, "scorecard #{inspect(route)} is missing required Route field"
  end

  if Map.has_key?(parsed, route) do
    raise ArgumentError, "duplicate scorecard route #{inspect(route)}"
  end

  Map.put(parsed, route, fields)
end
```

**Evidence row target:** rows should require route, journey, viewport width, theme, motion, focus path, `scrollWidth`, `clientWidth`, result, scrubbed notes/path, and deterministic command outcome.

---

### `test/support/lockspire/web/admin_proof/html_assertions.ex` (utility, transform)

**Analog:** self

Extend this file for rendered HTML assertions only. Avoid page-specific JTBD assertions here.

**Duplicate ID and ARIA target pattern** (`html_assertions.ex` lines 16-31, 39-64):

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

def assert_aria_targets_exist(html, attribute)
    when attribute in ["aria-describedby", "aria-labelledby", "aria-controls"] do
  doc = document(html)
  id_set = id_set(doc)

  values =
    doc
    |> LazyHTML.query("[#{attribute}]")
    |> LazyHTML.attribute(attribute)

  blank_values = Enum.filter(values, &(String.trim(&1) == ""))

  assert blank_values == [],
         "expected #{attribute} values to be non-empty"
```

**Labels and controls pattern** (`html_assertions.ex` lines 66-97):

```elixir
def assert_label_targets_exist(html) do
  doc = document(html)
  id_set = id_set(doc)

  label_targets =
    doc
    |> LazyHTML.query("label[for]")
    |> LazyHTML.attribute("for")
    |> Enum.reject(&(&1 == ""))

  assert label_targets != [], "expected rendered HTML to include explicit label[for] targets"

  missing =
    label_targets
    |> Enum.reject(&MapSet.member?(id_set, &1))
    |> Enum.uniq()

  assert missing == [],
         "expected every label[for] target to reference an existing ID, missing: #{inspect(missing)}"
```

**Generic CTA and unsupported-control pattern** (`html_assertions.ex` lines 153-173):

```elixir
def assert_no_generic_cta_text(html) do
  assert_no_text(html, @generic_cta_text)
end

def assert_no_interactive_controls(html, opts \\ []) do
  source = html_source(html)

  opts
  |> Keyword.get(:events, ["phx-click", "phx-submit"])
  |> Enum.each(fn event ->
    refute source =~ event, "expected rendered HTML to omit interactive event #{inspect(event)}"
  end)

  opts
  |> Keyword.get(:text, [])
  |> Enum.each(fn text ->
    refute Regex.match?(~r/\b#{Regex.escape(text)}\b/i, source),
           "expected rendered HTML to omit unsupported control text #{inspect(text)}"
  end)
```

---

### `test/support/lockspire/web/admin_proof/route_scorecards.ex` (utility, file-I/O + transform)

**Analog:** self

Extend only for route-scorecard truth or field validation. Route truth remains `AdminRouter` plus exactly `/admin/clients/:client_id/edit?workflow=logout-propagation`.

**Source-derived route truth** (`route_scorecards.ex` lines 51-57):

```elixir
def expected_routes do
  Lockspire.Web.AdminRouter
  |> Phoenix.Router.routes()
  |> Enum.map(&mounted_admin_route/1)
  |> Kernel.++(workflow_exceptions())
  |> Enum.sort()
end
```

**Mounted route path helper** (`route_scorecards.ex` lines 116-117):

```elixir
defp mounted_admin_route(%{path: "/"}), do: "/admin"
defp mounted_admin_route(%{path: path}), do: "/admin" <> path
```

**Contract test usage** (`design_system_contract_test.exs` lines 623-633):

```elixir
describe "Phase 121 route scorecard contracts" do
  test "phase 121 route scorecards cover AdminRouter route truth" do
    scorecards = phase_121_scorecards()

    assert Map.keys(scorecards) |> Enum.sort() == RouteScorecards.expected_routes()
    assert length(RouteScorecards.expected_routes()) == 29

    assert RouteScorecards.workflow_exceptions() == [
             "/admin/clients/:client_id/edit?workflow=logout-propagation"
           ]
  end
```

---

### `test/support/lockspire/web/admin_lab/fixtures.ex` (utility, batch + transform)

**Analog:** self

Add PROOF-01 fixture states here only when the state is shared by multiple primitives/routes. Keep values artificial, `.invalid` where hostnames are needed, and redaction-safe.

**Scenario state registry** (`fixtures.ex` lines 4-27):

```elixir
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
  :copy_once,
  :waiting,
  :completed,
  :provenance
]
```

**Fixture map shape** (`fixtures.ex` lines 55-64, 81-105, 117-128, 129-134):

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
    tokens: [
      %{
        state: :healthy,
        account: "acct_healthy_operator",
        family: "tok_family_healthy",
        handle: "redacted_handle_refresh_active"
      },
      %{
        state: :reuse_detected,
        account: "acct_incident_operator",
        family: "tok_family_reuse_detected",
        handle: "redacted_handle_reuse_incident"
      }
    ],
    dcr_iat: [
      %{
        state: :copy_once,
        label: "Initial access token",
        value: "redacted_handle_copy_once_iat_placeholder"
      },
      %{
        state: :revoked,
        label: "Registration access token",
        value: "redacted_handle_rat_revoked"
      }
    ],
    operations: [
      %{state: :normal, label: "Logout delivery", count: 42},
      %{state: :dense_data, label: "Device authorization attempts", count: 1248},
      %{state: :error, label: "Back-channel retry queue", count: 9},
      %{state: :destructive, label: "Token family revocation", count: 1}
    ],
```

**Status/theme/motion matrix** (`fixtures.ex` lines 154-192):

```elixir
status_matrix: [
  %{domain: :configure, status: :active},
  %{domain: :configure, status: :open},
  %{domain: :configure, status: :approved},
  %{domain: :device_authorization, status: :approved},
  %{domain: :support, status: :pending},
  %{domain: :support, status: :pending_login},
  %{domain: :support, status: :pending_consent},
  %{domain: :operate, status: :enqueued},
  %{domain: :operate, status: :attempted},
  %{domain: :operate, status: :retiring},
  %{domain: :operate, status: :retryable},
  %{domain: :support, status: :denied},
  %{domain: :support, status: :reuse_detected},
  %{domain: :operate, status: :discarded},
  %{domain: :configure, status: :disabled},
  %{domain: :configure, status: :retired},
  %{domain: :support, status: :completed},
  %{domain: :support, status: :consumed},
  %{domain: :support, status: :used},
  %{domain: :operate, status: :succeeded},
  %{domain: :operate, status: :rendered},
  %{domain: :operate, status: :skipped},
  %{domain: :configure, status: :operator},
  %{domain: :configure, status: :self_registered},
  %{domain: :configure, status: :self_registered_client},
  %{domain: :operate, status: :system},
  %{domain: :configure, status: :host_app},
  %{domain: :configure, status: :dcr},
  %{domain: :configure, status: :one_time},
  %{domain: :configure, status: :remembered},
  %{domain: :configure, status: :initial_access_token},
  %{domain: :configure, status: :upcoming},
  %{domain: :support, status: :revoked},
  %{domain: :support, status: :expired},
  %{domain: :support, status: :unknown_lab_only}
],
theme_modes: [:light, :dark, :system],
motion_modes: [:default, :reduced_motion]
```

---

### `test/support/lockspire/web/admin_lab/stress_surface.ex` (component, transform)

**Analog:** self

Extend this surface for shared component/primitive stress only. Do not add routes, endpoint handlers, public lab APIs, or host extension seams.

**Imports and assigns pattern** (`stress_surface.ex` lines 1-22):

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
      |> assign_new(:tokens, fn -> Map.get(assigns.fixture_set, :tokens, []) end)
      |> assign_new(:operations, fn -> Map.get(assigns.fixture_set, :operations, []) end)
      |> assign_new(:structural_rows, fn -> Map.get(assigns.fixture_set, :structural_rows, []) end)
      |> assign_new(:status_matrix, fn -> Map.get(assigns.fixture_set, :status_matrix, []) end)
      |> assign_new(:copy_once, fn ->
        assigns.fixture_set |> Map.get(:dcr_iat, []) |> List.first()
      end)
```

**Internal lab markers** (`stress_surface.ex` lines 30-36):

```elixir
~H"""
<section
  data-lab-surface="component-stress"
  data-theme-mode="light dark system"
  data-motion-mode="default reduced-motion"
  aria-label="Render stress surface"
>
```

**Long/redacted/copy-once primitive pattern** (`stress_surface.ex` lines 121-135, 252-256):

```elixir
<AdminComponents.resource_item
  :for={client <- @clients}
  title={client.name}
  subtitle={client.id}
  href={"/lockspire/admin/clients/#{client.id}"}
>
  <:meta>
    <AdminComponents.long_value kind={:url} value={client.redirect_uri} />
    <AdminComponents.long_value kind={:token} value={client.secret_handle} redacted />
  </:meta>
  <:status>
    <AdminComponents.status_badge status={client.state} />
  </:status>
</AdminComponents.resource_item>

<AdminComponents.copy_once_secret_panel
  title="Copy-once credential"
  body="Copy this value now. Lockspire stores only the hash after this response."
  value={@copy_once && @copy_once.value}
/>
```

---

### `test/lockspire/web/live/admin/design_system_component_stress_test.exs` (test, transform)

**Analog:** self

Use this file for AdminLab/shared primitive stress and helper unit tests. Keep route-specific JTBD proof in focused LiveView tests.

**Imports and source paths** (`design_system_component_stress_test.exs` lines 1-15):

```elixir
defmodule Lockspire.Web.Live.Admin.DesignSystemComponentStressTest do
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest

  alias Lockspire.Web.AdminLab.Fixtures
  alias Lockspire.Web.AdminLab.StressSurface
  alias Lockspire.Web.AdminProof.HtmlAssertions
  alias Lockspire.Web.Components.AdminComponents

  @admin_css_path Path.expand("../../../../../lib/lockspire/web/admin_css.ex", __DIR__)
  @admin_router_path Path.expand("../../../../../lib/lockspire/web/admin_router.ex", __DIR__)
  @mix_path Path.expand("../../../../../mix.exs", __DIR__)
  @supported_surface_path Path.expand("../../../../../docs/supported-surface.md", __DIR__)
```

**Fixture contract pattern** (`design_system_component_stress_test.exs` lines 45-91):

```elixir
test "fixtures expose required lab keys and scenario states without forbidden values" do
  assert Fixtures.fixture_keys() == [
           :clients,
           :tokens,
           :consents,
           :keys,
           :dcr_iat,
           :operations,
           :structural_rows,
           :status_matrix,
           :theme_modes,
           :motion_modes
         ]

  for state <- [
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
        :copy_once,
        :waiting,
        :completed,
        :provenance
      ] do
    assert state in Fixtures.scenario_states()
  end

  fixture_blob = inspect(Fixtures.all())

  for forbidden <- Fixtures.forbidden_substrings() do
    refute fixture_blob =~ forbidden
  end
end
```

**Render and shared assertion pattern** (`design_system_component_stress_test.exs` lines 93-108, 150-156, 218-223):

```elixir
test "stress surface renders real admin components across required states" do
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

  for marker <- [
        ~s(data-lab-surface="component-stress"),
        ~s(data-theme-mode="light dark system"),
        ~s(data-motion-mode="default reduced-motion")
      ] do
    assert html =~ marker
  end

  refute html =~ ~r/<a[^>]*aria-disabled="true"/
  refute html =~ ~r/<a[^>]*>\s*Disabled link action\s*<\/a>/s

  for forbidden <- Fixtures.forbidden_substrings() do
    refute html =~ forbidden
  end
end
```

**Internal-lab boundary pattern** (`design_system_component_stress_test.exs` lines 325-355):

```elixir
test "component lab stays internal, test-only, and outside package/public routes" do
  router = File.read!(@admin_router_path)
  mix = File.read!(@mix_path)
  supported_surface = File.read!(@supported_surface_path)

  assert Path.expand("../../../../support/lockspire/web/admin_lab/fixtures.ex", __DIR__) =~
           "/test/support/lockspire/web/admin_lab/fixtures.ex"

  refute mix =~ ~r/files:\s+~w\([^)]*test\/support/

  for forbidden <- [
        "component-lab",
        "component_lab",
        "design-system-lab",
        "design_system_lab",
        "storybook",
        "Storybook",
        "browser-proof",
        "browser_proof",
        "public theming",
        "theme engine",
        "package.json",
        "playwright.config"
      ] do
    refute router =~ forbidden
    refute mix =~ forbidden
    refute supported_surface =~ forbidden
  end

  refute File.exists?(Path.expand("../../../../../package.json", __DIR__))
end
```

---

### `test/lockspire/web/live/admin/design_system_contract_test.exs` (test, batch + file-I/O + transform)

**Analog:** self

Use this for global contracts: route scorecard parity, source/package/docs fences, CSS token/theme/motion contracts, and cross-page unsupported action drift. Avoid putting page-specific route assertions here when focused tests exist.

**Imports and canonical paths** (`design_system_contract_test.exs` lines 1-23):

```elixir
defmodule Lockspire.Web.Live.Admin.DesignSystemContractTest do
  use ExUnit.Case, async: true

  alias Lockspire.Web.AdminProof.{HtmlAssertions, RouteScorecards}

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
  @supported_surface_doc_path Path.expand("../../../../../docs/supported-surface.md", __DIR__)
  @mix_path Path.expand("../../../../../mix.exs", __DIR__)
```

**Scorecard field and support-boundary contracts** (`design_system_contract_test.exs` lines 635-668, 710-748):

```elixir
test "phase 121 route scorecards enforce required judgment fields" do
  markdown = phase_121_scorecards_markdown()
  scorecards = RouteScorecards.parse!(markdown)

  assert Map.keys(scorecards) |> Enum.filter(&String.contains?(&1, "?workflow=")) ==
           RouteScorecards.workflow_exceptions()

  for {_route, fields} <- scorecards,
      required_field <- RouteScorecards.required_fields() do
    assert Map.has_key?(fields, required_field), "missing #{required_field}"
    refute non_final_scorecard_value?(fields[required_field])
  end

  for {route, fields} <- scorecards do
    assert trimmed_backtick_value(fields["Route"]) == route
    assert fields["Journey"] in @phase_121_journeys
    assert fields["Evidence class"] in RouteScorecards.allowed_evidence_classes()
    assert fields["Public support promise"] == RouteScorecards.support_promise()
    assert generic_cta?(fields["Primary action"]) == false
  end

  HtmlAssertions.assert_no_generic_cta_text(rendered_primary_actions)
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

**Raw color/source token pattern** (`design_system_contract_test.exs` lines 787-798):

```elixir
test "raw hex colors are declared only on Lockspire admin token lines" do
  css = File.read!(@admin_css_path)

  offenders =
    css
    |> String.split("\n")
    |> Enum.with_index(1)
    |> Enum.filter(fn {line, _line_number} ->
      Regex.match?(~r/#[0-9a-fA-F]{3,8}/, line) and not String.contains?(line, "--ls-")
    end)

  assert offenders == []
end
```

**Browser/tooling/package fence** (`design_system_contract_test.exs` lines 1480-1524):

```elixir
test "phase 119 copy redaction and browser-boundary fences stay scoped" do
  sources = phase_119_source_blob()
  mix = File.read!(Path.expand("../../../../../mix.exs", __DIR__))

  for forbidden <- [
        "Playwright",
        "playwright",
        "axe-core",
        "@axe-core",
        "screenshot",
        "browser proof",
        "visual regression"
      ] do
    refute sources =~ forbidden
  end

  for forbidden <- ["playwright", "axe-core", "@axe-core", "proof/browser", "package.json"] do
    refute mix =~ forbidden
  end
end
```

**Operate read-only and responsive/theme/motion pattern** (`design_system_contract_test.exs` lines 1527-1648):

```elixir
describe "Phase 123 operate queue contracts" do
  test "operate routes stay bounded to existing read-only queue pages" do
    router_source = File.read!(@admin_router_path)

    routes =
      Lockspire.Web.AdminRouter
      |> Phoenix.Router.routes()
      |> Enum.map(& &1.path)

    for {path, contract} <- @phase_123_route_contracts do
      assert path in routes
      assert router_source =~ ~s("#{path}")
      assert router_source =~ inspect(contract.module)
    end

    for forbidden <- [
          "component_lab",
          "component-lab",
          "browser_proof",
          "browser-proof",
          "storybook",
          "Storybook",
          "design_system",
          "design-system",
          "theme_lab",
          "theming"
        ] do
      refute router_source =~ forbidden
    end
  end

  test "operate LiveViews stay read-only non-table source surfaces with required primitives" do
    for {route, contract} <- @phase_123_route_contracts do
      source = phase_123_source_for(route)

      assert source =~ "Operate"
      assert source =~ contract.title
      assert source =~ contract.pane
      assert source =~ contract.read_path
      assert source =~ "Read-only"
      assert source =~ "redacted_handle"

      refute source =~ "def handle_event"
      refute source =~ "phx-click"
      refute source =~ "phx-submit"
      refute source =~ "<table"
    end
  end

  test "operate layout CSS preserves wrapping mobile focus theme and reduced motion contracts" do
    css = File.read!(@admin_css_path)

    assert Regex.match?(
             ~r/\.lockspire-admin-long-value\s*\{[^}]*overflow-wrap:\s*anywhere;[^}]*word-break:\s*break-word;/s,
             css
           )

    assert css =~ ":focus-visible"
    assert css =~ "--ls-focus-ring-color"
    assert css =~ ":root[data-theme=\"light\"]"
    assert css =~ ":root[data-theme=\"dark\"]"
    assert css =~ "@media (prefers-color-scheme: dark)"
    assert css =~ "@media (prefers-reduced-motion: reduce)"
    assert css =~ "transition-duration: 0.01ms !important"
    assert css =~ "transform: none;"
  end
end
```

**Configure action/copy contract pattern** (`design_system_contract_test.exs` lines 1714-1798):

```elixir
describe "Phase 124 Configure propagation contracts" do
  test "CONFIG-01 D-01 D-02 route truth stays AdminRouter and scorecard derived" do
    assert_configure_route_boundary!()
    assert_no_phase_124_public_surface!()
  end

  test "CONFIG-01 CONFIG-02 CONFIG-03 D-03 through D-10 Configure sources use approved primitives and action semantics" do
    sources = phase_124_configure_sources()
    source_blob = phase_124_configure_source_blob()

    assert Map.keys(sources) |> Enum.sort() ==
             @phase_124_configure_source_paths |> Map.keys() |> Enum.sort()

    for {source_key, primitives} <- @phase_124_required_primitives do
      source = Map.fetch!(sources, source_key)

      for primitive <- primitives do
        assert phase_124_primitive_present?(source, primitive),
               "expected #{source_key} to use AdminComponents.#{primitive}"
      end
    end

    for label <- [
          "Filter clients",
          "Create client",
          "Review client configuration",
          "Edit client metadata",
          "Save metadata",
          "Save redirect URIs",
          "Save post-logout redirect URIs",
          "Save logout propagation",
          "Mint initial access token",
          "Review initial access tokens",
          "Generate signing key",
          "Generate encryption key",
          "Review key lifecycle",
          "Publish key",
          "Activate key",
          "Retire key"
        ] do
      assert source_blob =~ label, "missing approved Configure label #{inspect(label)}"
    end

    for phrase <- [
          "stores only the hash",
          "does not store or re-show",
          "redacted durable state",
          "name=\"toggle[confirm]\"",
          "name=\"revoke[confirm]\"",
          "AdminComponents.confirmation_panel",
          "AdminComponents.action_group"
        ] do
      assert source_blob =~ phrase, "missing Phase 124 copy/action contract #{inspect(phrase)}"
    end

    refute source_blob =~ "data-confirm="
  end
end
```

---

### Focused admin LiveView tests under `test/lockspire/web/live/admin/**` (test, request-response)

**Files:** `tokens_live_test.exs`, `consents_live_test.exs`, `interactions_live_test.exs`, `device_authorizations_live_test.exs`, `logout_deliveries_live_test.exs`, `clients_live_test.exs`, `clients_live/show_test.exs`, `iat_live_test.exs`, `keys_live_test.exs`, `policies_live/*_test.exs`, `overview_live_test.exs`

**Analog:** `test/lockspire/web/live/admin/tokens_live_test.exs`; for Operate proof summaries also use `.planning/phases/123-operate-queue-flow-polish/123-OPERATE-PROOF.md`.

Use focused tests for page/JTBD proof, route-local fixtures, redaction, closed-state behavior, and unsupported action checks.

**Imports/setup pattern** (`tokens_live_test.exs` lines 1-21, 24-73):

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

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Lockspire.TestRepo)

    {:ok, _client} =
      Repository.register_client(%Client{
        client_id: "token-ui-client",
        client_secret_hash: "sha256:token-ui:hash",
        client_type: :confidential,
        name: "Token UI Client",
        redirect_uris: ["https://token-ui.example.com/callback"],
        allowed_scopes: ["openid", "offline_access"],
        allowed_grant_types: ["authorization_code", "refresh_token"],
        allowed_response_types: ["code"],
        token_endpoint_auth_method: :client_secret_basic,
        pkce_required: true,
        subject_type: :public,
        created_at: DateTime.utc_now(),
        metadata: %{}
      })
```

**Router exposure pattern** (`tokens_live_test.exs` lines 76-81):

```elixir
test "router exposes admin token routes" do
  routes = Router.routes(Lockspire.Web.Router)

  assert Enum.any?(routes, &live_route?(&1, "/admin/tokens", Index))
  assert Enum.any?(routes, &live_route?(&1, "/admin/tokens/:id", Show))
end
```

**Rendered route proof pattern** (`tokens_live_test.exs` lines 153-177, 179-214):

```elixir
test "token detail shows lineage and guarded single-token and family revoke flows", %{
  refresh_token: refresh_token
} do
  assert {:ok, socket} =
           Show.mount(%{"id" => Integer.to_string(refresh_token.id)}, %{}, socket_for(:show))

  assert {:noreply, socket} =
           Show.handle_params(
             %{"id" => Integer.to_string(refresh_token.id)},
             "/lockspire/admin/tokens/#{refresh_token.id}",
             socket
           )

  html = rendered_to_string(Show.render(socket.assigns))

  HtmlAssertions.assert_no_duplicate_ids(html)
  HtmlAssertions.assert_describedby_targets_exist(html)
  HtmlAssertions.assert_no_generic_cta_text(html)
  HtmlAssertions.assert_has_link(html, "/lockspire/admin/tokens")

  HtmlAssertions.assert_no_text(html, [
    "token-ui-refresh-hash",
    "family-ui-123",
    "account-token-ui"
  ])

  assert html =~ "Support"
  assert html =~ "Token health decision"
  assert html =~ "Opaque tokens stay opaque here"
  assert html =~ "lockspire-admin-decision-summary"
  assert html =~ "Token identity and current state"
  assert html =~ "Refresh family lineage"
  assert html =~ "Corrective actions"
  assert html =~ "lockspire-admin-entity-header"
  assert html =~ "lockspire-admin-pane"
  assert html =~ "lockspire-admin-dense-resource-row"
  assert html =~ "lockspire-admin-description-list"
  assert html =~ "lockspire-admin-long-value"
  assert html =~ "Session ID"
  assert html =~ "Not recorded"
  assert html =~ "Parent token"
  assert html =~ "lockspire-admin-confirmation-panel"
```

**Closed-state/lifecycle proof pattern** (`tokens_live_test.exs` lines 322-414):

```elixir
test "token detail renders revoked, expired, no-family, and reuse-detected closed states" do
  revoked_token =
    store_support_token!(
      token_hash: "token-ui-already-revoked-hash",
      family_id: "family-ui-revoked",
      revoked_at: DateTime.utc_now()
    )

  {_socket, revoked_html} = render_show_for(revoked_token)

  assert revoked_html =~ "This token is already revoked. No further token action is available."
  assert revoked_html =~ "Token already revoked"
  assert revoked_html =~ ~r/<button[^>]*disabled[^>]*>.*Token already revoked/s

  expired_token =
    store_support_token!(
      token_hash: "token-ui-expired-hash",
      family_id: "family-ui-expired",
      issued_at: DateTime.add(DateTime.utc_now(), -7_200, :second),
      expires_at: DateTime.add(DateTime.utc_now(), -3_600, :second)
    )

  {_socket, expired_html} = render_show_for(expired_token)

  assert expired_html =~
           "This token is expired. No active token remains because its expiration time has passed."

  assert expired_html =~ "Expired"
  assert expired_html =~ ~r/<button[^>]*disabled[^>]*>.*Token expired/s

  reusable_family_summary =
    fragment_html(reusable_family_html, ".lockspire-admin-decision-summary")

  assert reusable_family_summary =~ "Smallest safe action"
  assert reusable_family_summary =~ "Revoke token family"
end
```

**Helper pattern** (`tokens_live_test.exs` lines 417-471):

```elixir
defp socket_for(action) do
  %Phoenix.LiveView.Socket{assigns: %{live_action: action, __changed__: %{}}}
end

defp render_show_for(token) do
  id = Integer.to_string(token.id)

  assert {:ok, socket} = Show.mount(%{"id" => id}, %{}, socket_for(:show))

  assert {:noreply, socket} =
           Show.handle_params(%{"id" => id}, "/lockspire/admin/tokens/#{id}", socket)

  {socket, rendered_to_string(Show.render(socket.assigns))}
end

defp live_route?(route, path, view) do
  route.path == path and match?({^view, _, _, _}, route.metadata[:phoenix_live_view])
end

defp fragment_html(html, selector) do
  html
  |> LazyHTML.from_fragment()
  |> LazyHTML.query(selector)
  |> LazyHTML.to_html()
end
```

**Operate proof pattern** (`123-OPERATE-PROOF.md` lines 38-45, 47-54):

```markdown
| Boundary | Proof | Result |
|----------|-------|--------|
| Route containment | `design_system_contract_test.exs` checks `Lockspire.Web.AdminRouter` routes | Only `/interactions`, `/device_authorizations`, and `/logouts` are accepted for this Operate slice; no `/operate`, detail route, lab route, browser-proof route, Storybook route, or theming route is introduced. |
| Admin API | `design_system_contract_test.exs` checks `lib/lockspire/admin.ex` | No retry, discard, approve, deny, logout-now, requeue, pause/resume, or worker-control delegates are added for interactions, device authorizations, logout deliveries, or logout queues. |
| LiveView source | `design_system_contract_test.exs` and focused route tests | The three queue LiveViews remain read-only, non-table source surfaces using `page_hero`, `pane`, `metric_grid`, `resource_list`, `dense_resource_row`, `status_badge`, `long_value`, and `empty_state`. |
| Rendered HTML | Focused route tests with `HtmlAssertions.assert_no_interactive_controls/2` | Rendered queues omit `phx-click`, `phx-submit`, unsupported command labels, and generic command copy. |

| D-09 logout allowed/forbidden data | `/admin/logouts` | Delivery id, redacted client handle, channel, endpoint URL, attempts, status pressure, sanitized HTTP/failure class, last activity, and support note may render. Logout token JTI, Oban job IDs, raw responses, cookies, endpoint secrets, SQL rows, and worker internals are denied by tests/source contracts. |
| D-10 interaction allowed/forbidden data | `/admin/interactions` | Interaction id, redacted client/account handles, prompt, status pressure, created/activity, and expiry may render. Authorization codes, request object internals, cookies, session tokens, nonce/state values, PKCE material, raw params, and raw sensitive return values are denied. |
| D-11 device authorization allowed/forbidden data | `/admin/device_authorizations` | Redacted client/account handles, redacted durable authorization handle, status, expiry, poll interval, next-poll, and lifecycle activity may render. Raw device/user codes, hashes, raw verification handle, authorization codes, token material, PKCE material, state, nonce, raw params, backend storage details, and `auth.updated_at` rendering are denied. |
| D-12 redaction pattern | All three routes | Rows use `Lockspire.Redaction.handle/2` through page-local helpers and `AdminComponents.long_value`; rendered tests seed sensitive fixture values and assert raw values do not appear. |
```

---

### `docs/operator-admin.md` (documentation, file-I/O)

**Analog:** self

Update narrowly for the page-first loop. Keep it subordinate to `docs/supported-surface.md`; do not make lab, browser, screenshots, reports, or AI judges public support.

**Subordinate support contract pattern** (`docs/operator-admin.md` lines 1-6):

```markdown
# Operator And Admin Guide

Lockspire ships a library-owned operator surface for protocol state, while the host app keeps ownership of account UX.

For the canonical advanced-setup support contract, see `docs/supported-surface.md`. This guide stays subordinate to that contract and should not be read as a second support matrix.
```

**Journey vocabulary pattern** (`docs/operator-admin.md` lines 7-16):

```markdown
## Lockspire-owned operator journeys

Lockspire groups the admin surface by operator intent:

- **Orient**: use `/admin` or `/admin/overview` as the operator cockpit for client posture, security posture, key readiness, support incidents, and live protocol work.
- **Configure**: use `/admin/clients`, `/admin/policies`, `/admin/keys`, and `/admin/dcr` to manage client setup, issuer posture, key lifecycle, and partner intake.
- **Support**: use `/admin/consents` and `/admin/tokens` to investigate durable grant, token, refresh-family, account, client, and status questions.
- **Operate**: use `/admin/interactions`, `/admin/device_authorizations`, and `/admin/logouts` to inspect live authorization work, device flow requests, and logout delivery pressure.

These routes live under the embedded Lockspire router and are meant for application operators.
```

**Proof boundary wording** (`docs/operator-admin.md` lines 50-68):

```markdown
## Design system workflow and proof boundary

The admin UI uses Lockspire-owned design tokens and shared Phoenix components for its operator surface. The runtime tokens intentionally mirror `brandbook/tokens/` so maintainers can audit brand drift without introducing a second styling system or a public component API.

Shared primitives cover the common operator building blocks: page heroes, section cards, action groups, status badges, alerts, resource lists, summaries, long identifiers, copy-once secret panels, confirmation panels, form fields, and error summaries. When adding or revising admin routes, prefer these primitives over page-local class assemblies and keep each change tied to the Orient, Configure, Support, or Operate job it serves.

The component lab and stress surface are internal maintainer proof only. They render real admin primitives and hostile redaction-safe fixture states for tests and local review, but they are not mounted through `Lockspire.Web.AdminRouter`, not a supported admin route, not a host extension point, and not part of `docs/supported-surface.md`.

Maintainer verification should keep this boundary intact: source contracts check shared primitives, token drift, focus, responsive behavior, theme modes, reduced motion, route links, docs truth, and redaction; manual evidence, when captured, remains maintainer proof and must not include secrets or copy-once plaintext. These checks do not make browser tooling, screenshots, lab routes, or theming overrides part of the public support contract.
```

**Scorecard loop location** (`docs/operator-admin.md` lines 79-87):

```markdown
## Page-first scorecards and judgment guardrails

Use `.planning/phases/121-route-scorecards-judgment-contract/121-ROUTE-SCORECARDS.md` as the canonical Phase 121 route scorecard artifact before changing admin pages. It is maintainer evidence for page-first route judgment, sourced from `Lockspire.Web.AdminRouter` plus the single `/admin/clients/:client_id/edit?workflow=logout-propagation` query workflow. Screenshot filenames, host mount prefixes, browser notes, and markdown-only route lists are not route truth.

Before page edits, review the scorecard fields in order: persona, JTBD, top task, entry point, primary decision, primary action, earned-place check, empty/error/long-data states, mobile/theme/focus/motion risk, redaction/security check, unsupported-action check, follow-up route, component/group fit, evidence class, public support promise, and runtime/package impact. Treat the fields as guardrails for what earns a place on the page, what action is backed by real Lockspire behavior, and whether follow-up routes stay inside the known admin route set.

Scorecards and any lab/stress/browser/judge notes are maintainer evidence only. They do not create supported admin routes, public APIs, host extension points, theming interfaces, browser-testing products, Hex package surface, or public support claims. Do not preserve secrets, copy-once values, screenshots with plaintext credentials, traces, reports, cookies, token-looking strings, auth codes, private keys, verifier material, user codes, or production-looking identifiers as evidence; prefer deterministic Mix guardrails and redaction-safe fixture notes.
```

---

### `.planning/phases/125-browser-proof-docs-adversarial-ratchet/125-V1.32-PROOF.md` (test artifact, batch + file-I/O)

**Analog:** `.planning/phases/120-browser-proof-docs-regression-audit/120-BROWSER-PROOF.md`

Create as maintainer-only `.planning` evidence. It should mirror Phase 120 but add v1.32 Support, Operate, Configure, Orient, internal-lab signoff, no-overflow rows with `scrollWidth`/`clientWidth`, command outcomes, gaps, sensitive-evidence denial, and adversarial checklist.

**Header and route truth pattern** (`120-BROWSER-PROOF.md` lines 1-11):

```markdown
# Phase 120 Browser Proof Matrix

**Status:** maintainer-only planning evidence.
**Route truth:** `Lockspire.Web.AdminRouter` plus `/admin/clients/:client_id/edit?workflow=logout-propagation`.
**Runtime impact:** none. This artifact does not create a supported admin route, public document, browser-testing product, CI gate, package dependency, or runtime behavior.

## Source Truth

Route proof starts from mounted `live(...)` entries in `Lockspire.Web.AdminRouter` and then appends one query-workflow row: `/admin/clients/:client_id/edit?workflow=logout-propagation`. That query workflow is URL evidence for `ClientsLive.Show` form mode, not a Phoenix router expansion.

Screenshots and browser notes are evidence after ExUnit/LiveView guardrails pass. They are not route truth, public support claims, or a replacement for source-derived route proof. Phase 110 screenshots remain historical baseline evidence only.
```

**Coverage and tooling boundary** (`120-BROWSER-PROOF.md` lines 13-22, 23-47):

````markdown
## Required Coverage

The representative matrix covers these widths and modes without requiring a full route x width x theme x motion cartesian table:

- Widths: `320px`, `390px`, `768px`, `1024px`, `1440px`
- Themes: `light`, `dark`, `system`
- Motion: default motion and `reduced-motion`
- Journeys: `Orient`, `Configure`, `Support`, `Operate`
- Internal proof boundary: `AdminLab.StressSurface`

## Guardrail Commands

Run deterministic guardrails before collecting or recording any browser evidence:

```bash
MIX_ENV=test mix test test/lockspire/web/admin_router_test.exs test/lockspire/web/live/admin/clients_live/show_test.exs --max-failures 1
```

Manual browser evidence is recorded as notes under `tmp/admin-ui-polish/phase-120/`. Do not commit screenshots, traces, reports, cookies, tokens, private keys, auth codes, verifier material, user codes, copy-once plaintext, or token-looking strings.

## Tooling Boundary

ExUnit, Phoenix LiveViewTest, and LazyHTML guardrails are the blocking proof path for Phase 120. Browser notes are maintainer-only evidence that supplements those guardrails; they do not define runtime behavior, public documentation truth, or package support.

Any package-manager install, `package.json`, lockfile, Playwright config, browser download, axe dependency, npm script, browser report, trace, or screenshot workflow must stop at `checkpoint:human-verify` before it is created. `@playwright/test` and `@axe-core/playwright` are named here only as conditional maintainer tooling that requires human package verification before any package-manager install or package/config file is added.

Do not add public docs, Hex package content, CI browser gates, runtime browser-test behavior, or a supported admin route for this proof lane.
````

**Matrix row pattern** (`120-BROWSER-PROOF.md` lines 49-64):

```markdown
## Representative Matrix

| Route / Surface | Source | Journey / JTBD | Viewport / Theme / Motion Risk | Seeded Or Fixture State | Evidence Path Or Note | Accessibility Note | Sensitive Evidence Check | Gap Note |
|---|---|---|---|---|---|---|---|---|
| `/admin` or `/admin/overview` | `AdminRouter` overview routes | Orient: understand attention-worthy provider state and choose the next workflow. | `1440px` light plus `390px` system. Shell/nav scanability and first-viewport orientation. | Adoption demo overview with healthy, warning, incident, DCR, key, support, and operations summary state. | `tmp/admin-ui-polish/phase-120/orient-overview-1440-light.md` and `tmp/admin-ui-polish/phase-120/orient-overview-390-system.md` notes. | Confirm skip-free keyboard access to journey navigation and visible focus on nav/theme controls. | Deny cookies, auth codes, token-looking strings, and real tenant hostnames. | Browser evidence pending until maintainer manual pass; ExUnit source route proof is blocking. |
| `/admin/device_authorizations` | `AdminRouter` device authorization route | Operate: inspect device authorization queue and expiry state. | `320px` light. Read-only queue rows, long verification handles, no unsupported controls. | Pending, approved, denied, consumed, expired, and long-handle seed states. | `tmp/admin-ui-polish/phase-120/device-authorizations-320-light.md` note. | Confirm queue state text is non-color-only and keyboard traversal reaches each row/action destination. | Refute user code plaintext and device code plaintext. | Manual evidence should confirm no page-level overflow at `320px`. |
| `AdminLab.StressSurface` | Internal `test/support` renderer, not an admin route | Internal lab boundary: prove component states without public support truth. | Light, dark, system, and `reduced-motion` markers across hostile fixture states. | `AdminLab.Fixtures.all()` hostile but redaction-safe component state matrix. | `tmp/admin-ui-polish/phase-120/internal-lab-stress-surface.md` note if manually inspected; ExUnit component stress remains the blocking proof. | Confirm component labels, help/error IDs, disabled links, destructive groups, and long values render coherently. | Use fixture denylist; refute live secrets, token plaintext, private keys, and copy-once values. | No browser route should be added for this surface; it stays internal lab evidence only. |
```

**Denylist, gaps, and adversarial audit pattern** (`120-BROWSER-PROOF.md` lines 66-84, 96-123, 125-140):

```markdown
## Sensitive Evidence Denylist

Before preserving any maintainer evidence, scan notes/screenshots/reports for these classes and delete or redact evidence if found:

- client secrets, registration access token plaintext, initial access token plaintext, refresh/access token plaintext
- authorization codes, cookies, private keys, verifier material, user codes
- JWT-looking strings, `sk_live_`, `pk_live_`, real tenant hostnames, production account identifiers
- source-only values such as `client_secret_hash`, verifier material, or private JWK text

## Explicit Gaps

- Manual browser evidence is not yet captured in this plan artifact; the table defines the route, viewport, theme, motion, seeded state, and evidence note contract for the maintainer pass.
- Optional Playwright/axe automation is not adopted in Plan 120-01. The equivalent manual browser evidence path remains the active PROOF-02 route.
- Full route x width x theme x motion cartesian coverage is intentionally not required; the representative rows above cover each required width/mode and route risk.

## Final adversarial audit

**Status:** PROOF-02, PROOF-03, and PROOF-04 are closed as committed deterministic guardrails plus maintainer-only evidence contracts. Browser evidence remains manual or conditional maintainer automation; no Playwright, axe, screenshot workflow, Node package file, public route, public docs page, protocol/storage change, or runtime browser-test product was added.

| Pillar | Final check | Outcome |
|---|---|---|
| accessibility | Source, LazyHTML, component stress, and mounted LiveView tests cover duplicate IDs, labels, descriptions, visible focus selectors, non-color status text, and read-only queue semantics. | PASS with manual keyboard/screen-reader comprehension still recorded as maintainer evidence work, not WCAG certification. |
| responsive reflow | CSS contracts and route matrix cover `320px`, `390px`, `768px`, `1024px`, and `1440px`, with wrapping/`min-width: 0`/mobile list behavior pinned. | PASS for deterministic contracts; no committed screenshot evidence. |
| security/redaction | Denylists and route tests reject secret/plaintext leakage in docs, fixtures, source, package paths, and rendered operate/support surfaces. | PASS. |
| performance/tooling weight | Browser automation was not adopted; no Node package, browser binary, CI gate, package file, screenshot, trace, or report was added. | PASS. |

| Concern | Check | Outcome |
|---|---|---|
| screenshot-only quality | Screenshots are evidence only; blocking proof is ExUnit, LiveView, LazyHTML, docs, and source contracts. | PASS. |
| protocol/support-surface creep | Public support ceiling stays in `docs/supported-surface.md`; contract tests reject component lab, public design-system, theming-engine, browser proof, Playwright, axe, screenshot-product, and package-content creep. | PASS. |

### Verification command outcomes

| Command | Outcome |
|---|---|
| `MIX_ENV=test mix test test/lockspire/web/live/admin/design_system_contract_test.exs --max-failures 1` | Passed after Task 120-03-02 GREEN: `43 tests, 0 failures`. Test output includes the pre-existing KeyCache startup log before the test repo is started. |

### Final gaps and boundaries

- Manual browser notes under `tmp/admin-ui-polish/phase-120/` are not committed. The representative matrix remains the maintainer evidence contract for manual browser review.
- Optional Playwright/axe automation was not adopted, and no package-manager install was attempted. This avoids browser-tooling support creep and package-legitimacy risk.
- The audit does not claim WCAG certification, public design-system support, public lab support, public theming support, visual-diff support, CI browser gate support, or browser-testing product support.
- No public route, protocol behavior, storage schema, admin operation control, standalone admin behavior, package file, screenshot, trace, or browser report was added.
```

Add Phase 125-specific columns or sections for `scrollWidth`, `clientWidth`, result, theme/motion, focus path, scrubbed notes, command outcomes, and final adversarial signoff.

## Shared Patterns

### Route Truth

**Source:** `test/support/lockspire/web/admin_proof/route_scorecards.ex` lines 51-57 and `design_system_contract_test.exs` lines 624-633
**Apply to:** route scorecard checks, docs proof, browser evidence rows, focused route tests

```elixir
def expected_routes do
  Lockspire.Web.AdminRouter
  |> Phoenix.Router.routes()
  |> Enum.map(&mounted_admin_route/1)
  |> Kernel.++(workflow_exceptions())
  |> Enum.sort()
end
```

Keep exactly one query workflow exception: `/admin/clients/:client_id/edit?workflow=logout-propagation`.

### Rendered HTML Accessibility And Link Contracts

**Source:** `test/support/lockspire/web/admin_proof/html_assertions.ex` lines 16-183
**Apply to:** component stress tests and focused route tests

Use `HtmlAssertions.assert_no_duplicate_ids/1`, `assert_describedby_targets_exist/1`, `assert_aria_targets_exist/2`, `assert_label_targets_exist/1`, `assert_links_have_hrefs/1`, `assert_no_generic_cta_text/1`, `assert_no_interactive_controls/2`, and `assert_no_text/2`.

### Redaction And Sensitive Evidence

**Source:** `fixtures.ex` lines 42-53, `html_assertions.ex` lines 176-183, `120-BROWSER-PROOF.md` lines 66-74
**Apply to:** fixtures, rendered routes, docs/source scans, browser/manual evidence

Do not preserve cookies, auth codes, token-looking strings, plaintext credentials, private keys, verifier material, user/device codes, production-looking hostnames, copy-once plaintext, or source-only secret fields.

### Public Surface And Tooling Boundary

**Source:** `design_system_component_stress_test.exs` lines 325-355, `design_system_contract_test.exs` lines 1480-1524, `120-BROWSER-PROOF.md` lines 39-47, `docs/operator-admin.md` lines 50-68
**Apply to:** all contract tests, docs, proof artifact

Reject new public lab/browser/theming routes, Storybook surfaces, `package.json`, Playwright/axe/browser config, screenshot/report/trace workflows, Hex package content, CI browser gates, runtime browser behavior, and public support claims.

### CSS, Theme, Motion, And Responsive Source Contracts

**Source:** `design_system_contract_test.exs` lines 787-798 and 1614-1648
**Apply to:** `design_system_contract_test.exs`, changed page source/CSS claims, proof artifact

Use source contracts for `--ls-*` tokens, no raw colors outside token declarations, `:focus-visible`, light/dark/system aliases, `prefers-color-scheme`, `prefers-reduced-motion`, long-value wrapping, mobile stacking, and focus ring tokens. Browser/manual evidence rows supplement source contracts with observed `scrollWidth` and `clientWidth`.

### Page-First Operator Language

**Source:** `docs/operator-admin.md` lines 7-16 and 79-87; `tokens_live_test.exs` lines 179-214; `123-OPERATE-PROOF.md` lines 7-21
**Apply to:** focused route tests and docs

Use the journey vocabulary exactly: Orient asks what needs attention; Configure asks what posture should change; Support asks what happened and what smallest safe action exists; Operate asks what protocol work is waiting, expired, failing, or safely reviewable.

### Docs Support Ceiling

**Source:** `docs/supported-surface.md` lines 1-7, 113-138, 150-168
**Apply to:** `docs/operator-admin.md`, `125-V1.32-PROOF.md`, contract tests

`docs/operator-admin.md` remains subordinate. `docs/supported-surface.md` should not change unless implementation finds a concrete ambiguity; if it changes, keep public claims narrow and do not add lab/browser-proof/screenshot/public design-system/public theming/AI judge support.

## No Analog Found

No files lacked a close analog. The only conditional files are helper extraction (`sensitive_values.ex`, `browser_evidence.ex`) and `docs/supported-surface.md`; both have clear existing patterns if Phase 125 implementation proves they are needed.

## Metadata

**Analog search scope:** `test/support/lockspire/web/admin_proof`, `test/support/lockspire/web/admin_lab`, `test/lockspire/web/live/admin`, `docs`, `.planning/phases/120-browser-proof-docs-regression-audit`, `.planning/phases/123-operate-queue-flow-polish`

**Files scanned:** 74 candidate `.ex`, `.exs`, and `.md` files in the analog scope

**Pattern extraction date:** 2026-06-30

**Notes:** `test/lockspire/web/live/admin/design_system_contract_test.exs` is over 2,000 lines, so only targeted non-overlapping ranges were read after grep located relevant sections. Existing dirty work in admin CSS/components/lab files was not modified.
