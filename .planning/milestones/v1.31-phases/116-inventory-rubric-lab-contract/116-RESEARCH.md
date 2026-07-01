# Phase 116: Inventory, Rubric & Lab Contract - Research

**Researched:** 2026-06-25
**Domain:** Phoenix LiveView admin design-system inventory, visual rubric, and internal lab contract
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
## Implementation Decisions

### Route And Workflow Inventory
- **D-01:** Derive the normal admin route inventory from `Lockspire.Web.AdminRouter` as the canonical mounted admin route source.
- **D-02:** Append `/admin/clients/:client_id/edit?workflow=logout-propagation` as the required query-driven workflow exception. Treat it as operator-visible workflow truth, not as a Phoenix route or router expansion.
- **D-03:** Inventory rows should publish operator-readable `/admin...` paths while preserving `AdminRouter` as source truth; do not include host-specific mount prefixes as canonical route truth.
- **D-04:** Each route/workflow row should carry the Phase 107 operator contract shape: journey, persona, JTBD, entry point, primary decision, primary action, empty state, risk state, follow-up route, evidence, and surface classification.
- **D-05:** Classify inventory surfaces explicitly as `admin_supported`, `demo_only`, `test_only`, or `internal_lab` so lab/demo evidence cannot become an accidental public support promise.
- **D-06:** Do not add retry, discard, logout, or other operation-queue actions unless existing domain APIs already back them.

### Component And Group Inventory
- **D-07:** Build component inventory as a two-tier artifact: canonical component API from `Lockspire.Web.Components.AdminComponents`, plus production LiveView usage, page-local exceptions, and missing states.
- **D-08:** Group inventory by reusable operator building blocks, not by every CSS class: primitives, recurring meta-components, CSS-only patterns, direct-markup exceptions, candidate Phase 118 meta-components, and tested/lab-only fixtures.
- **D-09:** Keep Phoenix function components with attrs/slots as the default design-system shape. Use LiveComponents only for genuinely stateful forms or isolated event loops, not basic layout organization.
- **D-10:** Do not introduce domain-specific workflow components prematurely. Components should render reusable structure such as panes, heroes, rows, badges, fields, long values, confirmations, action groups, empty states, and status clusters; LiveViews keep page intent, URL state, loading, and mutation behavior.
- **D-11:** Inventory production exceptions explicitly, especially direct button/action markup, form/error patterns, page-local detail sections, queue rows, remaining tables, long-value handling, status fallbacks, redaction boundaries, disabled states, destructive confirmations, and mobile-sensitive layouts.
- **D-12:** The inventory should expose DS-03 and DS-04 pressure directly: real Configure, Support, and Operate statuses must not fall through to disabled styling, and production forms should either use shared field/help/error/workflow primitives or document tested exceptions.

### Visual UX Rubric
- **D-13:** Use `brandbook/` as the canonical visual and token source. Older prompt brand references are subordinate and may inform voice only where they do not conflict with the newer brandbook.
- **D-14:** Translate the brandbook into admin-specific rubric gates: architectural structure, restrained Signal Cyan, Deep Cyan on light surfaces, semantic alias dark-mode remapping, first-class light/dark/system behavior, visible focus, reduced-motion safety, non-color status cues, and no generic security tropes.
- **D-15:** Treat Signal Cyan as role-bound: `#22d3ee` is appropriate for dark/hero/focus/non-text accents, while light-mode text/actions use contrast-safe Deep Cyan. Do not allow neon-cyan overload or white text on low-contrast cyan in light mode.
- **D-16:** The rubric must include hard floors beyond brand: accessibility, keyboard/focus reachability, responsive behavior at narrow widths, reduced motion, redaction, no secret evidence, destructive-action confirmation, concise domain-accurate microcopy, and no page-level overflow.
- **D-17:** Keep operator psychology anchored to the locked journeys: Orient answers what needs attention, Configure answers what posture should change, Support answers what happened to an account/client/token/grant, and Operate answers what live protocol work is waiting or failing.

### Lab Contract Boundary
- **D-18:** The component lab is a repo-local maintainer proof tool for rendering real admin components, recurring groups, route/workflow states, and ugly fixture data. It is not public runtime behavior.
- **D-19:** Do not mount the lab through `Lockspire.Web.AdminRouter`, document it as a supported admin route/API, add PhoenixStorybook in Phase 116, add a React/JS Storybook shell, create a public theme engine, or add a host-editable component registry.
- **D-20:** The lab contract should say: this lab exists to test Lockspire's admin design system against real route/component states and hostile data shapes without creating a new supported surface.
- **D-21:** Fixtures, screenshots, logs, docs, and lab states must never expose client secrets, registration access token plaintext, initial access token plaintext after creation, refresh/access token plaintext, authorization codes, cookies, private keys, verifier material, user codes, or unredacted sensitive values.
- **D-22:** ExUnit/source contracts should be the primary Phase 116 proof shape. Browser/screenshot evidence remains important for later phases after CSS, component, fixture, or page changes.

### Claude's Discretion
Downstream planning may choose the exact artifact filenames and test names as long as Phase 116 produces the four contracts above and keeps the lab boundary internal. Prefer source-derived inventory generation or deterministic tests where practical; use manual markdown tables only when they remain tied to source-derived proof.

### the agent's Discretion
Downstream planning may choose the exact artifact filenames and test names as long as Phase 116 produces the four contracts above and keeps the lab boundary internal. Prefer source-derived inventory generation or deterministic tests where practical; use manual markdown tables only when they remain tied to source-derived proof.

### Deferred Ideas (OUT OF SCOPE)
- PhoenixStorybook remains a future option only if the internal lab becomes too bespoke or the component API grows beyond current admin UI needs.
- Visual snapshot comparison tooling remains future work until the browser harness is stable enough to avoid noisy screenshot churn.
- Public theming, host-editable component registries, standalone admin services, hosted auth, React/JS Storybook shells, and mounted public lab routes remain out of scope.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| LAB-01 | Maintainer can inspect every admin primitive and recurring component group in a lightweight Lockspire-owned stress surface without mounting a new supported admin route. | Use the component/group inventory, internal lab contract, and existing ExUnit component stress pattern to define a maintainer/demo/test-only surface. [VERIFIED: .planning/REQUIREMENTS.md; test/lockspire/web/live/admin/design_system_component_stress_test.exs] |
| LAB-03 | Route inventory for stress proof derives from `Lockspire.Web.AdminRouter` plus the query-driven client logout-propagation workflow. | Use the existing `mounted_admin_routes/1` extraction pattern from `design_system_contract_test.exs`, append the logout-propagation workflow, and publish `/admin...` operator paths. [VERIFIED: lib/lockspire/web/admin_router.ex; test/lockspire/web/live/admin/design_system_contract_test.exs; .planning/phases/107-admin-journey-contract-ia-audit/107-ROUTE-JOURNEY-CONTRACT.md] |
</phase_requirements>

## Summary

Phase 116 should produce four durable planning contracts: route/workflow inventory, component/group inventory, visual/UX rubric, and component-lab boundary. [VERIFIED: .planning/phases/116-inventory-rubric-lab-contract/116-CONTEXT.md] The route inventory must derive normal routes from `Lockspire.Web.AdminRouter`, then append the query-driven `/admin/clients/:client_id/edit?workflow=logout-propagation` workflow as an exception rather than adding a Phoenix route. [VERIFIED: lib/lockspire/web/admin_router.ex; .planning/phases/107-admin-journey-contract-ia-audit/107-ROUTE-JOURNEY-CONTRACT.md]

The strongest implementation pattern is deterministic source proof in ExUnit: the existing contract test already extracts `live("...")` entries, maps `/` to `/admin`, prefixes other routes with `/admin`, and appends the logout-propagation workflow for Phase 107 and Phase 110 proof. [VERIFIED: test/lockspire/web/live/admin/design_system_contract_test.exs] For component proof, the existing stress test renders real Phoenix function components with awkward data using `Phoenix.LiveViewTest.rendered_to_string/1`, which matches the maintainer-only lab direction without mounting a route. [VERIFIED: test/lockspire/web/live/admin/design_system_component_stress_test.exs; CITED: https://hexdocs.pm/phoenix_live_view/1.1.28/Phoenix.LiveViewTest.html]

**Primary recommendation:** Create source-derived markdown contracts plus focused ExUnit contract tests; do not add PhoenixStorybook, a mounted lab route, public theming, or new workflow actions in Phase 116. [VERIFIED: .planning/phases/116-inventory-rubric-lab-contract/116-CONTEXT.md]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Admin route/workflow inventory | Frontend Server (Phoenix Router/LiveView) | Docs/planning artifacts | `Lockspire.Web.AdminRouter` owns mounted route truth, while the query workflow is URL state in the client LiveView and should be documented as workflow truth. [VERIFIED: lib/lockspire/web/admin_router.ex; .planning/phases/107-admin-journey-contract-ia-audit/107-ROUTE-JOURNEY-CONTRACT.md; CITED: https://hexdocs.pm/phoenix_live_view/1.1.28/Phoenix.LiveView.Router.html] |
| Component and group inventory | Frontend Server (Phoenix components) | CSS/design-token layer | `AdminComponents` is the shared function-component API and `Admin.CSS` provides namespaced token/BEM styling. [VERIFIED: lib/lockspire/web/components/admin_components.ex; lib/lockspire/web/admin_css.ex] |
| Visual/UX rubric | Frontend Server + CSS/design-token layer | Brandbook planning source | `brandbook/` is canonical token/visual truth, while admin CSS mirrors the `--ls-*` token vocabulary. [VERIFIED: brandbook/README.md; brandbook/tokens/tokens.json; lib/lockspire/web/admin_css.ex] |
| Component lab contract | Test tier / maintainer evidence | Frontend Server render helpers | The lab must render real admin components for maintainer proof without creating a supported admin route/API. [VERIFIED: .planning/phases/116-inventory-rubric-lab-contract/116-CONTEXT.md; test/lockspire/web/live/admin/design_system_component_stress_test.exs] |
| Redaction and no-secret evidence | API/Backend policy + Frontend rendering | Tests/docs | Sensitive plaintext and verifier material must not appear in fixtures, screenshots, logs, docs, or lab states. [VERIFIED: .planning/phases/116-inventory-rubric-lab-contract/116-CONTEXT.md; .planning/phases/110-demo-state-screenshots-docs-and-regression-proof/110-VERIFICATION.md] |

## Project Constraints (from AGENTS.md)

- Build Lockspire as a separate companion library, not a Sigra module. [VERIFIED: AGENTS.md]
- Preserve the embedded-library shape; do not turn this into a required standalone auth service. [VERIFIED: AGENTS.md]
- Keep strong internal boundaries between protocol core, storage, generators, Plug/Phoenix integration, and LiveView/admin surfaces. [VERIFIED: AGENTS.md]
- Treat the host seam as explicit and narrow: account resolution, claims, login redirects, branding, and product policy belong to the host app. [VERIFIED: AGENTS.md]
- Do not broaden v1 into SAML, LDAP/AD federation, hosted auth, or a full CIAM suite. [VERIFIED: AGENTS.md]
- Preserve secure defaults: PKCE S256 by default, exact redirect matching, hashed client secrets, short-lived single-use authorization codes, refresh token rotation with family-wide revocation on reuse, no implicit flow, no `alg=none`, and strong redaction. [VERIFIED: AGENTS.md]
- Use the stated stack baseline: Phoenix, Phoenix LiveView, Ecto SQL, PostgreSQL, Bandit, Oban, and OpenTelemetry. [VERIFIED: AGENTS.md; mix.exs; mix.lock]

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Phoenix | `~> 1.8.5`, locked `1.8.7` | Router and Phoenix app primitives for `Lockspire.Web.AdminRouter`. | Existing project dependency and official LiveView router integration target. [VERIFIED: mix.exs; mix.lock; CITED: https://hexdocs.pm/phoenix_live_view/1.1.28/Phoenix.LiveView.Router.html] |
| Phoenix LiveView | `~> 1.1.28`, locked `1.1.30` | Function components, LiveViews, LiveView tests, component rendering. | Existing admin UI uses LiveView and `Phoenix.Component` attrs/slots; official docs support function-component testing with `render_component/3`. [VERIFIED: mix.exs; mix.lock; CITED: https://hexdocs.pm/phoenix_live_view/1.1.28/Phoenix.Component.html; CITED: https://hexdocs.pm/phoenix_live_view/1.1.28/Phoenix.LiveViewTest.html] |
| ExUnit | Elixir `1.19.5` runtime | Deterministic contract proof for source-derived inventory and component rendering. | Existing admin design-system tests are ExUnit-based and already prove route/component contracts. [VERIFIED: local `elixir --version`; test/lockspire/web/live/admin/design_system_contract_test.exs] |
| Lockspire `AdminComponents` | Local module | Canonical shared admin function-component API. | Contains the current primitive set and should be inventoried as source truth. [VERIFIED: lib/lockspire/web/components/admin_components.ex] |
| Lockspire `Admin.CSS` | Local module | Embedded namespaced design-token CSS. | Mirrors brandbook token vocabulary and backs component classes. [VERIFIED: lib/lockspire/web/admin_css.ex; brandbook/README.md] |

### Supporting

| Library/Artifact | Version | Purpose | When to Use |
|------------------|---------|---------|-------------|
| `brandbook/tokens/tokens.json` | `1.0.0` metadata | Canonical machine-readable token source. | Use for rubric gates around Signal Cyan, Deep Cyan, status colors, semantic aliases, typography, focus, and motion. [VERIFIED: brandbook/tokens/tokens.json] |
| `107-ROUTE-JOURNEY-CONTRACT.md` | Phase 107 artifact | Route/workflow vocabulary and row shape. | Use as baseline route contract shape, not as route truth. [VERIFIED: .planning/phases/107-admin-journey-contract-ia-audit/107-ROUTE-JOURNEY-CONTRACT.md] |
| `design_system_component_stress_test.exs` | Existing test | Maintainer-only rendered component stress proof. | Use as lab-contract precedent for Phase 117 without exposing a route. [VERIFIED: test/lockspire/web/live/admin/design_system_component_stress_test.exs] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| ExUnit/source-derived contracts | PhoenixStorybook | PhoenixStorybook is explicitly deferred and would add dependency/route/support-surface questions outside Phase 116. [VERIFIED: .planning/REQUIREMENTS.md; .planning/phases/116-inventory-rubric-lab-contract/116-CONTEXT.md] |
| Phoenix function components | LiveComponents | LiveComponents are stateful components with encapsulated state in the LiveView process; use them only for genuinely stateful forms/event loops, not basic layout inventory. [CITED: https://hexdocs.pm/phoenix_live_view/1.1.28/Phoenix.Component.html; VERIFIED: .planning/phases/116-inventory-rubric-lab-contract/116-CONTEXT.md] |
| Markdown contracts tied to source proof | Standalone public component registry | A registry would imply a host-editable/public surface and is out of scope. [VERIFIED: .planning/phases/116-inventory-rubric-lab-contract/116-CONTEXT.md] |

**Installation:** No new packages should be installed in Phase 116. [VERIFIED: .planning/phases/116-inventory-rubric-lab-contract/116-CONTEXT.md]

**Version verification:** Existing dependency versions were verified with `rg` over `mix.exs` and `mix.lock`; Phase 116 should not perform registry upgrades. [VERIFIED: mix.exs; mix.lock]

## Package Legitimacy Audit

No external packages are recommended or required for Phase 116. [VERIFIED: .planning/phases/116-inventory-rubric-lab-contract/116-CONTEXT.md]

| Package | Registry | Age | Downloads | Source Repo | Verdict | Disposition |
|---------|----------|-----|-----------|-------------|---------|-------------|
| None | — | — | — | — | — | No install |

**Packages removed due to [SLOP] verdict:** none
**Packages flagged as suspicious [SUS]:** none

## Architecture Patterns

### System Architecture Diagram

```text
Phase 116 planner inputs
  |
  v
Read CONTEXT + REQUIREMENTS + STATE + AGENTS
  |
  v
Source inventory
  |-- AdminRouter live(...) routes ----------------------.
  |-- AdminComponents attr/slot/function API ------------+--> 116 contracts
  |-- Admin LiveView usage + exceptions -----------------+      |-- route/workflow inventory
  |-- brandbook tokens/notes + Admin.CSS ----------------+      |-- component/group inventory
  |-- prior Phase 107/108/109/110 artifacts -------------'      |-- visual/UX rubric
                                                                 |-- maintainer lab boundary
                                                                 v
                                                        ExUnit contract proof
                                                                 |
                                                                 v
                                                        Phase 117-120 planning inputs
```

### Recommended Project Structure

```text
.planning/phases/116-inventory-rubric-lab-contract/
├── 116-RESEARCH.md              # this research artifact
├── 116-ROUTE-WORKFLOW-INVENTORY.md
├── 116-COMPONENT-GROUP-INVENTORY.md
├── 116-VISUAL-UX-RUBRIC.md
└── 116-LAB-CONTRACT.md

test/lockspire/web/live/admin/
└── design_system_contract_test.exs  # extend or add focused Phase 116 tests
```

The exact artifact filenames are planner discretion, but the four contracts are mandatory. [VERIFIED: .planning/phases/116-inventory-rubric-lab-contract/116-CONTEXT.md]

### Pattern 1: Source-Derived Route Inventory

**What:** Parse `Lockspire.Web.AdminRouter` for `live("...")` route paths, map `/` to `/admin`, prefix other paths with `/admin`, sort, then append `/admin/clients/:client_id/edit?workflow=logout-propagation`. [VERIFIED: test/lockspire/web/live/admin/design_system_contract_test.exs]

**When to use:** Use for LAB-03 inventory proof and later stress/screenshot coverage. [VERIFIED: .planning/REQUIREMENTS.md]

**Example:**

```elixir
# Source: test/lockspire/web/live/admin/design_system_contract_test.exs
defp mounted_admin_routes(router_source) do
  ~r/live\(\s*"([^"]+)"/
  |> Regex.scan(router_source, capture: :all_but_first)
  |> List.flatten()
  |> Enum.map(&mounted_admin_route/1)
end

defp mounted_admin_route("/"), do: "/admin"
defp mounted_admin_route(route), do: "/admin" <> route
```

### Pattern 2: Phoenix Function Components As Contract Surface

**What:** Treat `attr/3`, `slot/3`, and `def component(assigns)` declarations in `AdminComponents` as canonical component API; inventory production usage and exceptions separately. [VERIFIED: lib/lockspire/web/components/admin_components.ex; CITED: https://hexdocs.pm/phoenix_live_view/1.1.28/Phoenix.Component.html]

**When to use:** Use for LAB-01 and Phase 118 planning. [VERIFIED: .planning/REQUIREMENTS.md]

**Example:**

```elixir
# Source: lib/lockspire/web/components/admin_components.ex
attr(:title, :string, required: true)
attr(:body, :string, required: true)

def empty_state(assigns) do
  ~H"""
  <section class="lockspire-admin-empty">
    <h2>{@title}</h2>
    <p>{@body}</p>
  </section>
  """
end
```

### Pattern 3: Maintainer-Only Rendered Stress Surface

**What:** Render real admin components with awkward but redaction-safe fixture data under ExUnit; do not mount a route or publish a public API. [VERIFIED: test/lockspire/web/live/admin/design_system_component_stress_test.exs]

**When to use:** Use as Phase 117 lab precedent and as Phase 116 contract language. [VERIFIED: .planning/phases/116-inventory-rubric-lab-contract/116-CONTEXT.md]

**Example:**

```elixir
# Source: test/lockspire/web/live/admin/design_system_component_stress_test.exs
html = rendered_to_string(StressSurface.render(%{}))

assert html =~ "Design-system stress surface"
assert html =~ "lockspire-admin-copy-once-secret"
assert html =~ "lockspire-admin-confirmation-panel-danger"
```

### Anti-Patterns to Avoid

- **Mounted lab route:** It would create support-surface ambiguity and violates the lab boundary. [VERIFIED: .planning/phases/116-inventory-rubric-lab-contract/116-CONTEXT.md]
- **PhoenixStorybook in Phase 116:** It is explicitly default-deferred and should remain a rejected/deferred alternative. [VERIFIED: .planning/REQUIREMENTS.md; .planning/phases/116-inventory-rubric-lab-contract/116-CONTEXT.md]
- **Manual route lists without source proof:** They drift from `AdminRouter` and fail LAB-03. [VERIFIED: .planning/REQUIREMENTS.md; test/lockspire/web/live/admin/design_system_contract_test.exs]
- **Domain workflow components too early:** LiveViews should keep page intent, URL state, loading, and mutations; components should render reusable structure. [VERIFIED: .planning/phases/116-inventory-rubric-lab-contract/116-CONTEXT.md]
- **Generic security imagery/copy:** Brandbook chooses architectural/faceted trust and rejects generic mark directions; rubric should ban generic security tropes. [VERIFIED: brandbook/notes/logo-options.md; .planning/phases/116-inventory-rubric-lab-contract/116-CONTEXT.md]

## Route/Workflow Inventory Requirements

The inventory should include every route currently declared in `Lockspire.Web.AdminRouter` plus the query-driven logout-propagation workflow. [VERIFIED: lib/lockspire/web/admin_router.ex; .planning/phases/116-inventory-rubric-lab-contract/116-CONTEXT.md]

Required rows:

| Surface | Source Truth | Surface Classification | Notes |
|---------|--------------|------------------------|-------|
| `/admin` | `live("/")` | `admin_supported` | Map root route to operator-visible `/admin`. [VERIFIED: lib/lockspire/web/admin_router.ex] |
| `/admin/overview` | `live("/overview")` | `admin_supported` | Orient route. [VERIFIED: lib/lockspire/web/admin_router.ex; docs/operator-admin.md] |
| `/admin/clients` and client detail/edit/workflow routes | `AdminRouter` `live` routes | `admin_supported` | Include edit, redirects, logout URIs, PAR policy, security profile, rotate secret, and RAT rotation. [VERIFIED: lib/lockspire/web/admin_router.ex] |
| `/admin/clients/:client_id/edit?workflow=logout-propagation` | `ClientsLive.Show` URL workflow + Phase 107 contract | `admin_supported` workflow exception | Operator-visible workflow truth, not a router expansion. [VERIFIED: .planning/phases/107-admin-journey-contract-ia-audit/107-ROUTE-JOURNEY-CONTRACT.md; docs/operator-admin.md] |
| `/admin/policies`, `/admin/policies/par`, `/admin/policies/security-profile`, `/admin/policies/dpop`, `/admin/policies/dcr` | `AdminRouter` `live` routes | `admin_supported` | Configure policy surface. [VERIFIED: lib/lockspire/web/admin_router.ex] |
| `/admin/keys`, `/admin/keys/:id` | `AdminRouter` `live` routes | `admin_supported` | Configure key lifecycle surface. [VERIFIED: lib/lockspire/web/admin_router.ex] |
| `/admin/dcr`, `/admin/iats`, `/admin/iats/new` | `AdminRouter` `live` routes | `admin_supported` | DCR onboarding and IAT workflow. [VERIFIED: lib/lockspire/web/admin_router.ex; docs/operator-admin.md] |
| `/admin/consents`, `/admin/consents/:id` | `AdminRouter` `live` routes | `admin_supported` | Support investigation surface. [VERIFIED: lib/lockspire/web/admin_router.ex] |
| `/admin/tokens`, `/admin/tokens/:id` | `AdminRouter` `live` routes | `admin_supported` | Support token/family surface. [VERIFIED: lib/lockspire/web/admin_router.ex] |
| `/admin/interactions`, `/admin/device_authorizations`, `/admin/logouts` | `AdminRouter` `live` routes | `admin_supported` | Operate queues; do not add retry/discard actions without domain APIs. [VERIFIED: lib/lockspire/web/admin_router.ex; .planning/REQUIREMENTS.md] |

Each row should carry the Phase 107 fields plus `surface classification`: route/workflow, journey, persona, JTBD, entry point, primary decision, primary action, empty state, risk state, follow-up route, evidence, and classification. [VERIFIED: .planning/phases/107-admin-journey-contract-ia-audit/107-ROUTE-JOURNEY-CONTRACT.md; .planning/phases/116-inventory-rubric-lab-contract/116-CONTEXT.md]

## Component And Group Inventory Requirements

The canonical component API currently includes `status_badge`, `section_card`, `page_hero`, `metric_grid`, `task_card`, `filter_bar`, `admin_button`, `form_field`, `error_summary`, `action_bar`, `alert`, `description_list`, `summary_stat`, `resource_list`, `resource_item`, `copy_once_secret_panel`, `long_value`, `action_group`, `badge_group`, `confirmation_panel`, `empty_state`, `policy_nav`, `timestamp`, and `error_list`. [VERIFIED: lib/lockspire/web/components/admin_components.ex]

Recommended group taxonomy:

| Group | Members / Examples | Inventory Must Capture |
|-------|--------------------|------------------------|
| Primitives | badge, button, field, error list, long value, timestamp | attrs/slots, CSS classes, supported states, current fallbacks. [VERIFIED: lib/lockspire/web/components/admin_components.ex] |
| Structural components | page hero, section card, metric grid, resource list/item, description list | production usage points and missing responsive/empty/error states. [VERIFIED: lib/lockspire/web/components/admin_components.ex; lib/lockspire/web/live/admin] |
| Safety components | copy-once panel, confirmation panel, alert, error summary | redaction boundaries and destructive confirmation language. [VERIFIED: lib/lockspire/web/components/admin_components.ex; .planning/phases/116-inventory-rubric-lab-contract/116-CONTEXT.md] |
| Meta-components/candidates | status/action clusters, workflow shell, lifecycle row, dense resource row, architectural panes | mark as Phase 118 candidates rather than Phase 116 implementation. [VERIFIED: .planning/REQUIREMENTS.md; .planning/phases/116-inventory-rubric-lab-contract/116-CONTEXT.md] |
| CSS-only patterns | `lockspire-admin-detail-section`, `lockspire-admin-form-shell`, summary grids, table wrappers, value lists | document whether to preserve, convert, or treat as exceptions. [VERIFIED: lib/lockspire/web/admin_css.ex; lib/lockspire/web/live/admin] |
| Direct-markup exceptions | direct `.link` button classes, raw field wrappers, checkbox labels, page-local detail sections | list exact files and risk so Phase 118 can decide. [VERIFIED: lib/lockspire/web/live/admin/clients_live/show.ex; lib/lockspire/web/live/admin/clients_live/form_component.ex] |
| Test/lab fixtures | existing `StressSurface` and future lab states | classify as `test_only` or `internal_lab`, never `admin_supported`. [VERIFIED: test/lockspire/web/live/admin/design_system_component_stress_test.exs] |

Current pressure points the planner should expect: `status_badge/1` falls unknown statuses back to disabled styling, while real surfaces use statuses including pending, enqueued, retryable, discarded, skipped, succeeded, rendered, approved, denied, used, open, and policy/profile atoms. [VERIFIED: lib/lockspire/web/components/admin_components.ex; lib/lockspire/web/live/admin/logout_deliveries_live/index.ex; lib/lockspire/web/live/admin/device_authorizations_live/index.ex; lib/lockspire/web/live/admin/interactions_live/index.ex; lib/lockspire/web/live/admin/policies_live]

## Visual/UX Rubric Requirements

Rubric gates should be hard pass/fail checks:

| Gate | Rule |
|------|------|
| Brand source | `brandbook/` is canonical; older prompts are subordinate when they conflict. [VERIFIED: brandbook/README.md; .planning/phases/116-inventory-rubric-lab-contract/116-CONTEXT.md] |
| Signal Cyan | Use `#22d3ee` as dark/hero/focus/non-text accent; do not use it as normal light-mode text. [VERIFIED: brandbook/notes/decision-log.md; brandbook/notes/accessibility-checks.md] |
| Deep Cyan | Use `#0e7490` for contrast-safe light-mode text/actions. [VERIFIED: brandbook/tokens/tokens.json; brandbook/notes/accessibility-checks.md] |
| Light/dark/system parity | Semantic aliases remap in dark mode; primitive colors stay stable. [VERIFIED: brandbook/README.md; brandbook/notes/decision-log.md; lib/lockspire/web/admin_css.ex] |
| Accessibility | Preserve visible focus, non-color status cues, reduced-motion handling, and contrast floors. [VERIFIED: brandbook/notes/accessibility-checks.md; lib/lockspire/web/admin_css.ex] |
| Operator hierarchy | Orient, Configure, Support, Operate keep distinct jobs and page hierarchy. [VERIFIED: docs/operator-admin.md; .planning/phases/107-admin-journey-contract-ia-audit/107-ROUTE-JOURNEY-CONTRACT.md] |
| Identity | Use architectural/faceted structured-trust language; reject generic shields, locks, neon threat maps, or fear-led copy. [VERIFIED: brandbook/notes/logo-options.md; .planning/phases/116-inventory-rubric-lab-contract/116-CONTEXT.md] |
| Safety | No secret evidence, no unredacted sensitive values, destructive actions confirm durable context and consequence. [VERIFIED: .planning/phases/116-inventory-rubric-lab-contract/116-CONTEXT.md; .planning/phases/110-demo-state-screenshots-docs-and-regression-proof/110-VERIFICATION.md] |

## Lab Contract Requirements

The lab contract should state that the lab is a repo-local maintainer/demo/test-only proof surface for real admin components, recurring groups, route/workflow states, and hostile data shapes. [VERIFIED: .planning/phases/116-inventory-rubric-lab-contract/116-CONTEXT.md]

Required contract language:

- The lab does not mount through `Lockspire.Web.AdminRouter`. [VERIFIED: .planning/phases/116-inventory-rubric-lab-contract/116-CONTEXT.md]
- The lab does not create a supported admin route, public API, PhoenixStorybook dependency, React/JS shell, theme engine, or host-editable registry. [VERIFIED: .planning/phases/116-inventory-rubric-lab-contract/116-CONTEXT.md]
- The lab may use ExUnit-rendered HEEx/function-component surfaces and future demo/test fixtures. [VERIFIED: test/lockspire/web/live/admin/design_system_component_stress_test.exs; CITED: https://hexdocs.pm/phoenix_live_view/1.1.28/Phoenix.LiveViewTest.html]
- Lab/demo/browser evidence must never expose client secrets, RAT/IAT plaintext after creation, token plaintext, authorization codes, cookies, private keys, verifier material, user codes, or unredacted sensitive values. [VERIFIED: .planning/phases/116-inventory-rubric-lab-contract/116-CONTEXT.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Route extraction | A second ad hoc manually maintained route list | Existing `mounted_admin_routes/1` style source extraction from `AdminRouter` | Prevents drift and satisfies LAB-03. [VERIFIED: test/lockspire/web/live/admin/design_system_contract_test.exs; .planning/REQUIREMENTS.md] |
| Component API modeling | A separate public registry | `AdminComponents` `attr`/`slot` declarations plus production usage inventory | Phoenix already exposes component contracts through attrs/slots. [VERIFIED: lib/lockspire/web/components/admin_components.ex; CITED: https://hexdocs.pm/phoenix_live_view/1.1.28/Phoenix.Component.html] |
| Visual token truth | A new token scale | `brandbook/tokens/tokens.json` and existing `--ls-*` CSS variables | Brandbook and admin CSS already share names. [VERIFIED: brandbook/README.md; lib/lockspire/web/admin_css.ex] |
| Component lab runtime | Public admin route or Storybook app | ExUnit-rendered internal stress surface | Keeps proof internal and avoids support-surface expansion. [VERIFIED: test/lockspire/web/live/admin/design_system_component_stress_test.exs; .planning/phases/116-inventory-rubric-lab-contract/116-CONTEXT.md] |
| Redaction rules | Page-local secret filtering | Existing redaction contract and no-secret evidence list | Secret leakage is a cross-cutting security boundary. [VERIFIED: .planning/phases/116-inventory-rubric-lab-contract/116-CONTEXT.md] |

**Key insight:** Phase 116 is a contract phase; custom runtime infrastructure would create more support-surface risk than planning value. [VERIFIED: .planning/phases/116-inventory-rubric-lab-contract/116-CONTEXT.md]

## Common Pitfalls

### Pitfall 1: Treating Query Workflow As Router Truth
**What goes wrong:** `/admin/clients/:client_id/edit?workflow=logout-propagation` gets added to router-derived route lists as if it were a `live` route. [VERIFIED: .planning/phases/107-admin-journey-contract-ia-audit/107-ROUTE-JOURNEY-CONTRACT.md]
**Why it happens:** The workflow is operator-visible and route-like, but it is URL/query-driven state. [VERIFIED: docs/operator-admin.md]
**How to avoid:** Append it as an explicit workflow exception with evidence pointing to Phase 107 and docs. [VERIFIED: .planning/phases/116-inventory-rubric-lab-contract/116-CONTEXT.md]
**Warning signs:** A test expects `AdminRouter` to contain the query string. [VERIFIED: lib/lockspire/web/admin_router.ex]

### Pitfall 2: Creating A Supported Lab Surface By Accident
**What goes wrong:** A maintainer stress page becomes a route hosts depend on. [VERIFIED: .planning/phases/116-inventory-rubric-lab-contract/116-CONTEXT.md]
**Why it happens:** Route-mounted demos are convenient but imply public behavior. [ASSUMED]
**How to avoid:** Classify lab as `internal_lab` or `test_only`, keep it out of `AdminRouter`, and document non-support status. [VERIFIED: .planning/phases/116-inventory-rubric-lab-contract/116-CONTEXT.md]
**Warning signs:** Lab paths appear in `docs/operator-admin.md`, `docs/supported-surface.md`, or `AdminRouter`. [VERIFIED: docs/operator-admin.md; docs/supported-surface.md; lib/lockspire/web/admin_router.ex]

### Pitfall 3: Status Fallback Hides Real State
**What goes wrong:** Unsupported statuses render as disabled, weakening DS-03 evidence. [VERIFIED: lib/lockspire/web/components/admin_components.ex; .planning/REQUIREMENTS.md]
**Why it happens:** `badge_class(_other)` falls back to disabled while several production statuses are not explicitly classed. [VERIFIED: lib/lockspire/web/components/admin_components.ex; lib/lockspire/web/live/admin]
**How to avoid:** Inventory all production status atoms and mark missing semantic mappings as Phase 118 work. [VERIFIED: .planning/phases/116-inventory-rubric-lab-contract/116-CONTEXT.md]
**Warning signs:** Configure, Support, or Operate statuses appear only via generic fallback labels/classes. [VERIFIED: lib/lockspire/web/components/admin_components.ex]

### Pitfall 4: Brand Token Drift
**What goes wrong:** Admin CSS and brandbook drift into two design systems. [VERIFIED: brandbook/README.md]
**Why it happens:** Local CSS changes can bypass token truth. [ASSUMED]
**How to avoid:** Keep rubric tied to `brandbook/tokens/tokens.json` and existing token-alignment tests. [VERIFIED: test/lockspire/web/live/admin/design_system_contract_test.exs]
**Warning signs:** Raw hex appears outside token declarations or `#22d3ee` is used as light-mode text. [VERIFIED: brandbook/notes/accessibility-checks.md; test/lockspire/web/live/admin/design_system_contract_test.exs]

### Pitfall 5: Inventory Becomes Implementation
**What goes wrong:** Phase 116 starts changing primitives, CSS, route pages, or demo seeds. [VERIFIED: .planning/phases/116-inventory-rubric-lab-contract/116-CONTEXT.md]
**Why it happens:** Inventory exposes obvious gaps. [ASSUMED]
**How to avoid:** Record gaps and Phase 118/119/120 handoffs; only add contract artifacts and tests. [VERIFIED: .planning/REQUIREMENTS.md; .planning/phases/116-inventory-rubric-lab-contract/116-CONTEXT.md]
**Warning signs:** Diffs touch production LiveViews/CSS for visual changes rather than proof scaffolding. [VERIFIED: .planning/phases/116-inventory-rubric-lab-contract/116-CONTEXT.md]

## Code Examples

### Route Extraction With Workflow Exception

```elixir
# Source: test/lockspire/web/live/admin/design_system_contract_test.exs
expected_routes =
  router
  |> mounted_admin_routes()
  |> Kernel.++(["/admin/clients/:client_id/edit?workflow=logout-propagation"])
  |> Enum.sort()
```

### Component Contract From Attrs And Slots

```elixir
# Source: lib/lockspire/web/components/admin_components.ex
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
  </div>
  """
end
```

### Rendered Component Stress Proof

```elixir
# Source: test/lockspire/web/live/admin/design_system_component_stress_test.exs
html = rendered_to_string(StressSurface.render(%{}))

assert html =~ "Copy-once credential"
assert html =~ "Revoke token family"
assert html =~ "lockspire-admin-empty"
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Screenshot lists as enough route proof | Source-derived `AdminRouter` inventory plus explicit query workflow | Phase 107/110 baseline | Phase 116 should preserve source-derived route truth. [VERIFIED: .planning/phases/107-admin-journey-contract-ia-audit/107-ROUTE-JOURNEY-CONTRACT.md; .planning/phases/110-demo-state-screenshots-docs-and-regression-proof/110-SCREENSHOTS.md] |
| Generic admin blue/product tokens | Brandbook Signal Cyan + Deep Cyan + semantic dark remap | Brandbook shipped before v1.31 | Rubric must enforce brandbook rather than older prompt references. [VERIFIED: brandbook/notes/decision-log.md; brandbook/README.md] |
| Raw page tables/lists as default admin layout | Shared primitives and resource rows with long-value handling | Phase 108/109 baseline | Inventory should list remaining direct/page-local patterns as exceptions. [VERIFIED: .planning/phases/108-design-system-token-component-upgrade/108-CONTEXT.md; .planning/phases/109-weak-spot-page-polish/109-CONTEXT.md] |
| Browser proof as immediate contract for every change | ExUnit/source contracts first, browser proof later after CSS/component/page changes | Phase 116 decision | Phase 116 proof should be deterministic; Phase 120 handles broad browser evidence. [VERIFIED: .planning/phases/116-inventory-rubric-lab-contract/116-CONTEXT.md; .planning/REQUIREMENTS.md] |

**Deprecated/outdated:**
- PhoenixStorybook as a Phase 116 default: rejected/deferred unless later evidence shows the lightweight lab stops scaling. [VERIFIED: .planning/REQUIREMENTS.md]
- Public theming or host-editable component registry: out of scope for v1.31. [VERIFIED: .planning/REQUIREMENTS.md]
- Generic security tropes: brandbook favors architectural/faceted structured trust. [VERIFIED: brandbook/notes/logo-options.md]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Route-mounted demos are convenient but can imply public behavior. | Common Pitfalls | Low; locked decisions already forbid mounted lab routes. |
| A2 | Local CSS changes can bypass token truth. | Common Pitfalls | Low; existing tests already cover raw hex and token alignment. |
| A3 | Inventory phases tend to expose tempting implementation gaps. | Common Pitfalls | Low; phase boundary explicitly prevents implementation work. |

## Open Questions - RESOLVED

1. **Should Phase 116 create separate contract files or one combined contract?**
   - What we know: Context requires four contracts but leaves filenames to planner discretion. [VERIFIED: .planning/phases/116-inventory-rubric-lab-contract/116-CONTEXT.md]
   - RESOLVED: Use four focused files for planner/phase handoff clarity: `116-ROUTE-WORKFLOW-INVENTORY.md`, `116-COMPONENT-GROUP-INVENTORY.md`, `116-VISUAL-UX-RUBRIC.md`, and `116-LAB-CONTRACT.md`. [VERIFIED: .planning/phases/116-inventory-rubric-lab-contract/116-CONTEXT.md]

2. **Should route/component inventory generation be implemented as reusable helper code?**
   - What we know: Existing tests use local helper functions and simple source parsing. [VERIFIED: test/lockspire/web/live/admin/design_system_contract_test.exs]
   - RESOLVED: Keep Phase 116 to test-local helpers unless later duplication in Phase 117 or Phase 120 proves a shared helper is needed. [VERIFIED: test/lockspire/web/live/admin/design_system_contract_test.exs]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Elixir/Mix | ExUnit contracts | yes | Elixir 1.19.5 / Mix 1.19.5 | None needed. [VERIFIED: local command output] |
| Erlang/OTP | Elixir runtime | yes | OTP 28 | None needed. [VERIFIED: local command output] |
| PostgreSQL client | Existing project tests that touch DB | yes | psql 14.17 | Phase 116 should prefer source/static tests that do not require DB. [VERIFIED: local command output; test/lockspire/web/live/admin/design_system_contract_test.exs] |
| Node/npm | Not required by Phase 116 | yes | Node 22.14.0 / npm 11.1.0 | Avoid new Node tooling. [VERIFIED: local command output; .planning/phases/116-inventory-rubric-lab-contract/116-CONTEXT.md] |
| Context7 CLI/MCP | Docs lookup | no | — | Official HexDocs web pages were used. [VERIFIED: local command output; CITED: https://hexdocs.pm/phoenix_live_view/1.1.28/Phoenix.Component.html] |

**Missing dependencies with no fallback:** none. [VERIFIED: local command output]

**Missing dependencies with fallback:** Context7 was unavailable; official HexDocs pages were used. [VERIFIED: local command output]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit via Elixir/Mix. [VERIFIED: test/test_helper.exs; local command output] |
| Config file | `test/test_helper.exs`. [VERIFIED: test/test_helper.exs] |
| Quick run command | `mix test test/lockspire/web/live/admin/design_system_contract_test.exs --max-failures 1` [VERIFIED: existing test path] |
| Full suite command | `mix test` [VERIFIED: project convention in Phase 110 verification] |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| LAB-01 | Component/group inventory and internal lab contract cover every primitive/group without mounting a supported route. | source contract + rendered component unit | `mix test test/lockspire/web/live/admin/design_system_contract_test.exs --max-failures 1` | yes, extend existing file. [VERIFIED: test/lockspire/web/live/admin/design_system_contract_test.exs] |
| LAB-03 | Route inventory derives from `AdminRouter` plus logout-propagation query workflow. | source contract | `mix test test/lockspire/web/live/admin/design_system_contract_test.exs --max-failures 1` | yes, extend existing file. [VERIFIED: test/lockspire/web/live/admin/design_system_contract_test.exs] |

### Sampling Rate

- **Per task commit:** `mix test test/lockspire/web/live/admin/design_system_contract_test.exs --max-failures 1` [VERIFIED: test/lockspire/web/live/admin/design_system_contract_test.exs]
- **Per wave merge:** `mix test test/lockspire/web/live/admin/design_system_component_stress_test.exs test/lockspire/web/live/admin/design_system_contract_test.exs --max-failures 1` [VERIFIED: existing test paths]
- **Phase gate:** `mix test` before `$gsd-verify-work` if implementation touches tests/docs broadly. [VERIFIED: .planning/phases/110-demo-state-screenshots-docs-and-regression-proof/110-VERIFICATION.md]

### Wave 0 Gaps

- [ ] Add or extend contract tests that assert Phase 116 artifact existence, required headings, source-derived route rows, query workflow row, `surface classification` values, brand rubric gates, and lab non-support language. [VERIFIED: .planning/phases/116-inventory-rubric-lab-contract/116-CONTEXT.md]
- [ ] Add source/static check for no lab mount in `Lockspire.Web.AdminRouter` if the lab contract file names a future lab module/path. [VERIFIED: lib/lockspire/web/admin_router.ex]
- [ ] Add status inventory proof or explicit TODO list for DS-03 status fallback pressure. [VERIFIED: .planning/REQUIREMENTS.md; lib/lockspire/web/components/admin_components.ex]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V2 Authentication | no direct Phase 116 implementation | Host owns operator authentication before `AdminRouter`; do not change auth. [VERIFIED: docs/operator-admin.md; AGENTS.md] |
| V3 Session Management | no direct Phase 116 implementation | Keep lab out of runtime routes and supported admin surface. [VERIFIED: .planning/phases/116-inventory-rubric-lab-contract/116-CONTEXT.md] |
| V4 Access Control | yes, boundary documentation | Surface classifications and non-support lab contract prevent accidental public/admin support expansion. [VERIFIED: .planning/phases/116-inventory-rubric-lab-contract/116-CONTEXT.md] |
| V5 Input Validation | yes, fixture/lab data handling | Use redaction-safe fixtures; no plaintext sensitive evidence. [VERIFIED: .planning/phases/116-inventory-rubric-lab-contract/116-CONTEXT.md] |
| V6 Cryptography | yes, evidence safety only | Never expose private keys, authorization codes, verifier material, client secrets, or token plaintext. [VERIFIED: .planning/phases/116-inventory-rubric-lab-contract/116-CONTEXT.md] |

### Known Threat Patterns for Phoenix LiveView Admin Contracts

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Lab route becomes accessible admin/runtime surface | Elevation of Privilege / Information Disclosure | Keep lab unmounted, classify as `internal_lab`/`test_only`, and assert no `AdminRouter` route. [VERIFIED: .planning/phases/116-inventory-rubric-lab-contract/116-CONTEXT.md] |
| Sensitive values appear in fixtures/docs/screenshots | Information Disclosure | Contract bans client secrets, token plaintext, codes, cookies, private keys, verifier material, user codes, and unredacted sensitive values. [VERIFIED: .planning/phases/116-inventory-rubric-lab-contract/116-CONTEXT.md] |
| Support-surface docs overclaim lab/demo evidence | Spoofing / Repudiation | Keep `docs/supported-surface.md` canonical and do not document lab as supported route/API. [VERIFIED: docs/supported-surface.md; .planning/phases/116-inventory-rubric-lab-contract/116-CONTEXT.md] |
| UI adds operation actions not backed by domain APIs | Tampering | Do not add retry/discard/logout actions unless existing APIs back them. [VERIFIED: .planning/REQUIREMENTS.md; .planning/phases/116-inventory-rubric-lab-contract/116-CONTEXT.md] |

## Sources

### Primary (HIGH confidence)

- `AGENTS.md` - project boundaries, stack, security defaults. [VERIFIED: AGENTS.md]
- `.planning/phases/116-inventory-rubric-lab-contract/116-CONTEXT.md` - locked decisions and phase scope. [VERIFIED: .planning/phases/116-inventory-rubric-lab-contract/116-CONTEXT.md]
- `.planning/REQUIREMENTS.md` - LAB-01/LAB-03 and v1.31 boundaries. [VERIFIED: .planning/REQUIREMENTS.md]
- `.planning/STATE.md` - milestone status and v1.31 decisions. [VERIFIED: .planning/STATE.md]
- `lib/lockspire/web/admin_router.ex` - canonical admin route source. [VERIFIED: lib/lockspire/web/admin_router.ex]
- `lib/lockspire/web/components/admin_components.ex` - canonical component API. [VERIFIED: lib/lockspire/web/components/admin_components.ex]
- `lib/lockspire/web/admin_css.ex` - token/BEM CSS source. [VERIFIED: lib/lockspire/web/admin_css.ex]
- `test/lockspire/web/live/admin/design_system_contract_test.exs` - existing route/component/source contract patterns. [VERIFIED: test/lockspire/web/live/admin/design_system_contract_test.exs]
- `test/lockspire/web/live/admin/design_system_component_stress_test.exs` - existing internal component stress proof. [VERIFIED: test/lockspire/web/live/admin/design_system_component_stress_test.exs]
- `brandbook/README.md`, `brandbook/tokens/tokens.json`, `brandbook/notes/*` - brand and accessibility rules. [VERIFIED: brandbook/README.md; brandbook/tokens/tokens.json; brandbook/notes/decision-log.md; brandbook/notes/accessibility-checks.md; brandbook/notes/logo-options.md]

### Secondary (MEDIUM confidence)

- Phoenix LiveView `Phoenix.Component` docs for function components, attrs, slots, and LiveComponents. [CITED: https://hexdocs.pm/phoenix_live_view/1.1.28/Phoenix.Component.html]
- Phoenix LiveView `Phoenix.LiveViewTest` docs for component rendering tests. [CITED: https://hexdocs.pm/phoenix_live_view/1.1.28/Phoenix.LiveViewTest.html]
- Phoenix LiveView router docs for `live/4` route/action behavior. [CITED: https://hexdocs.pm/phoenix_live_view/1.1.28/Phoenix.LiveView.Router.html]

### Tertiary (LOW confidence)

- Assumptions A1-A3 in the Assumptions Log. [ASSUMED]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - verified from `mix.exs`, `mix.lock`, project docs, and official HexDocs. [VERIFIED: mix.exs; mix.lock; CITED: https://hexdocs.pm/phoenix_live_view/1.1.28/Phoenix.Component.html]
- Architecture: HIGH - locked by local phase context and existing code/test artifacts. [VERIFIED: .planning/phases/116-inventory-rubric-lab-contract/116-CONTEXT.md; lib/lockspire/web/admin_router.ex; test/lockspire/web/live/admin/design_system_contract_test.exs]
- Pitfalls: MEDIUM - major pitfalls are verified by locked decisions; process-risk explanations include a few assumptions. [VERIFIED: .planning/phases/116-inventory-rubric-lab-contract/116-CONTEXT.md; ASSUMED]

**Research date:** 2026-06-25
**Valid until:** 2026-07-25
