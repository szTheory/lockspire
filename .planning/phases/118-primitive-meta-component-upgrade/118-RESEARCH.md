# Phase 118: primitive-meta-component-upgrade - Research

**Researched:** 2026-06-25
**Domain:** Phoenix LiveView function-component design-system primitives for Lockspire admin UI
**Confidence:** HIGH for codebase scope and locked decisions; MEDIUM for external UI guidance because Context7 was unavailable and official docs were fetched directly.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

### Component Architecture

- **D-01:** Extend `Lockspire.Web.Components.AdminComponents` with slot-based structural meta-components as the Phase 118 default. The target set is architectural panes, entity headers, workflow shells, status/action clusters, lifecycle rows, dense resource rows, and responsive table/list alternatives.
- **D-02:** Keep Phoenix function components with explicit `attr` and `slot` declarations as the shared admin design-system shape. LiveViews continue to own URL state, filtering, loading, mutations, and page intent.
- **D-03:** Do not introduce domain workflow components that hide OAuth/OIDC policy or mutation behavior. Reusable components should render structure, hierarchy, status, actions, rows, fields, confirmations, empty states, and long values; domain-specific behavior stays in LiveViews and admin/context modules.
- **D-04:** Do not use LiveComponents for ordinary markup reuse. A LiveComponent in this phase requires a concrete local-state plus event-handling reason that cannot stay cleanly in the parent LiveView.
- **D-05:** Keep existing component APIs backward-compatible. Add attrs/slots or new wrappers rather than renaming/removing current primitives such as `page_hero`, `filter_bar`, `resource_item`, `action_group`, `status_badge`, `form_field`, `confirmation_panel`, and `empty_state`.
- **D-06:** Tables remain acceptable for true comparison or tabular scanning, but Phase 118 should provide table/list alternatives and dense resource row primitives so Phase 119 can avoid mobile overflow and raw table drift on Support and Operate pages.

### Status Semantics

- **D-07:** Upgrade `status_badge` around explicit domain-aware status metadata. Keep the simple function-component API, but add a `:domain` or `:context` attr for ambiguous statuses and derive label, tone, non-color cue, and optional title from one pattern-matched mapping.
- **D-08:** No real Configure, Support, or Operate status currently rendered by admin pages may fall through to disabled styling. Disabled fallback remains only for truly unknown values and should be covered by a contract test.
- **D-09:** Use a small semantic tone set: `:healthy`, `:waiting`, `:warning`, `:danger`, `:disabled`, `:completed`, and `:provenance`. Avoid unbounded color meanings.
- **D-10:** Treat provenance states such as `:operator` and `:self_registered` as origin/provenance, not health. Treat waiting states such as `:pending`, `:pending_login`, `:pending_consent`, `:enqueued`, `:attempted`, and approved-but-not-consumed device states as waiting, not disabled. Treat completed states such as `:completed`, `:consumed`, `:used`, `:succeeded`, `:rendered`, and `:skipped` as completed. Reserve danger for security incidents or terminal operational failures such as `:reuse_detected` and discarded logout work. Use warning for operator-attention states such as `:retiring`, `:retryable`, and `:denied`.
- **D-11:** Status badges must carry meaning through text and/or non-color cues, not color alone. Light, dark, and system themes must use the brandbook semantic status aliases rather than one-off colors.

### Form And Workflow Primitives

- **D-12:** Make slot-based `form_field` the default chrome for routine production configuration fields and filter fields where practical. It owns label, help, required marker, error text, and accessible help/error IDs; the page still renders the actual Phoenix input/select/textarea explicitly.
- **D-13:** Preserve idiomatic LiveView form behavior: form-level `phx-change` and `phx-submit`, stable input IDs/names, existing `to_form`/changeset behavior where present, and page-owned validation/mutation semantics.
- **D-14:** Add narrow workflow primitives only where they clarify existing destructive, lifecycle, confirmation, and copy-once flows. Good candidates are confirmation checkbox/help structure, workflow form shell, and lifecycle action grouping layered on `confirmation_panel`, `copy_once_secret_panel`, `action_group`, and `admin_button`.
- **D-15:** Do not wrap every input in a high-level Lockspire input component in Phase 118. That would increase migration risk, fight existing explicit HEEx/Phoenix form patterns, and make unusual confirmation/copy-once workflows harder to read.
- **D-16:** Complex checkbox confirmations, lifecycle action forms, and copy-once secret/RAT/IAT flows may remain page-local or use workflow primitives when field wrappers reduce clarity. Every exception must be named in contract proof or focused LiveView tests.
- **D-17:** Error handling should pair error summaries with field-level errors when validation is user-correctable. Inputs with errors should connect help/error copy through `aria-describedby` and use `aria-invalid` only for validated invalid states.
- **D-18:** Secret and token material stays copy-once or redacted. Form, confirmation, test fixture, screenshot, log, and docs surfaces must never expose client secrets, registration access token plaintext, initial access token plaintext after creation, refresh/access token plaintext, authorization codes, cookies, private keys, verifier material, user codes, or unredacted sensitive values.

### Stress Proof And Verification

- **D-19:** Extend the existing test-only admin lab fixtures and ExUnit-rendered stress surface for Phase 118 proof. Do not add a public/admin route, PhoenixStorybook, Playwright, axe, or package files in this phase.
- **D-20:** Component stress proof should cover disabled links, destructive action groups, dense filters, secondary navigation, empty table/list alternatives, repeated badges, generated long values, domain-aware status semantics, and form/workflow primitives.
- **D-21:** Prefer focused rendered assertions over brittle full HTML snapshots. Assert user-visible labels, stable `lockspire-admin-*` classes, accessibility hooks, redaction boundaries, and fixture coverage rather than exact wholesale markup.
- **D-22:** Keep the lab classified as `test_only` / `internal_lab`, excluded from `Lockspire.Web.AdminRouter`, public supported-surface docs, and Hex package files.
- **D-23:** Phase 120 owns mounted/browser/viewport/theme/reduced-motion/axe/screenshot evidence after primitives and weak-page applications stabilize.

### the agent's Discretion

Planner may choose exact function names if they preserve the intent above. Prefer plain, descriptive names that match current component vocabulary over abstract design-system jargon. Good examples: `pane`, `entity_header`, `workflow_shell`, `status_cluster`, `lifecycle_row`, `dense_resource_row`, and `responsive_table`.

### Deferred Ideas (OUT OF SCOPE)

- PhoenixStorybook remains a future option if the component API grows beyond current admin-only needs or the internal lab becomes too bespoke.
- Mounted browser/viewport/focus/axe/screenshot proof belongs to Phase 120 after Phase 118 primitives and Phase 119 page applications settle.
- Public theming, host-editable component registries, standalone admin services, hosted auth, React/JS Storybook shells, and mounted public lab routes remain out of scope.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| DS-02 | Shared admin components expose backward-compatible primitives for architectural panes, entity headers, workflow shells, status/action clusters, lifecycle rows, dense resource rows, and table/list alternatives. [VERIFIED: .planning/REQUIREMENTS.md] | Add Phoenix function components in `Lockspire.Web.Components.AdminComponents`, keep existing primitive APIs, and extend `lockspire-admin-*` CSS plus contract tests. [VERIFIED: codebase grep] |
| DS-03 | Every real admin status used by Configure, Support, and Operate surfaces maps to intentional badge semantics instead of falling through to disabled styling. [VERIFIED: .planning/REQUIREMENTS.md] | Replace scattered fallback semantics with one domain-aware metadata mapping for `status_badge`, then test all real atoms from current admin pages. [VERIFIED: codebase grep] |
| DS-04 | Production admin forms use shared field, help, error, and workflow primitives or document a tested exception. [VERIFIED: .planning/REQUIREMENTS.md] | Upgrade `form_field`, `error_summary`, and workflow wrappers while preserving explicit Phoenix inputs and page-owned form events. [CITED: https://phoenix-live-view.hexdocs.pm/form-bindings.html] |
</phase_requirements>

## Summary

Phase 118 should be planned as an additive Phoenix function-component upgrade centered on `lib/lockspire/web/components/admin_components.ex`, `lib/lockspire/web/admin_css.ex`, and the internal lab/test files under `test/support/lockspire/web/admin_lab` and `test/lockspire/web/live/admin`. [VERIFIED: codebase grep] No new dependency, public route, PhoenixStorybook, Playwright, axe, storage schema, or OAuth/OIDC protocol behavior belongs in this phase. [VERIFIED: 118-CONTEXT.md]

The primary technical risk is not component syntax; it is semantic drift. [VERIFIED: codebase grep] `status_badge/1` currently maps only a small subset of real statuses to intentional classes and sends unknown statuses to disabled styling, while real admin pages render statuses such as `:operator`, `:self_registered`, `:pending`, `:pending_login`, `:pending_consent`, `:completed`, `:denied`, `:enqueued`, `:retryable`, `:discarded`, `:succeeded`, `:rendered`, `:skipped`, `:used`, and key lifecycle statuses. [VERIFIED: codebase grep]

**Primary recommendation:** Implement one additive component/CSS/test wave for structural primitives, one focused wave for status metadata contract, and one production-form/workflow proof wave with documented exceptions. [VERIFIED: 118-CONTEXT.md]

## Project Constraints (from AGENTS.md)

- Preserve Lockspire as an embedded OAuth/OIDC authorization server library for Phoenix/Elixir, not a standalone service. [VERIFIED: AGENTS.md]
- Keep strong internal boundaries between protocol core, storage, generators, Plug/Phoenix integration, and LiveView/admin surfaces. [VERIFIED: AGENTS.md]
- Keep the host seam explicit and narrow; account resolution, claims, login redirects, branding, and product policy belong to the host app. [VERIFIED: AGENTS.md]
- Do not broaden v1 into SAML, LDAP/AD federation, hosted auth, or a full CIAM suite. [VERIFIED: AGENTS.md]
- Preserve security defaults including PKCE S256 by default, exact redirect URI validation, hashed client secrets, short-lived single-use authorization codes, refresh-token rotation with family-wide reuse revocation, no implicit flow, no `alg=none`, and strong redaction. [VERIFIED: AGENTS.md]
- Use the current project stack: Phoenix, Phoenix LiveView, Ecto SQL, PostgreSQL, Bandit, Oban, and OpenTelemetry. [VERIFIED: AGENTS.md]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|--------------|----------------|-----------|
| Structural admin primitives | Frontend Server / LiveView | Browser / CSS | Phoenix function components render HEEx structure server-side; CSS controls responsive and state presentation. [CITED: https://phoenix-live-view.hexdocs.pm/Phoenix.Component.html] |
| Domain-aware status badge semantics | Frontend Server / LiveView | Browser / CSS | Status meaning should be mapped before rendering; CSS should only express the chosen semantic tone. [VERIFIED: 118-CONTEXT.md] |
| Form/help/error primitives | Frontend Server / LiveView | Browser / HTML accessibility | Pages keep `phx-change`, `phx-submit`, ids, names, and validation; shared components render labels/help/errors and accessible associations. [CITED: https://phoenix-live-view.hexdocs.pm/form-bindings.html] |
| Stress proof | Test Support | Frontend Server / LiveView | Existing proof uses ExUnit plus `Phoenix.LiveViewTest.render_component/2`, not a mounted route. [VERIFIED: codebase grep] |
| Redaction boundary | API / Backend | Frontend Server / LiveView | Domain/test fixtures must avoid plaintext secrets before UI rendering; UI must keep copy-once/redacted behavior. [VERIFIED: AGENTS.md] |

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Phoenix | locked `1.8.7`; recent `1.8.8` on Hex [VERIFIED: Hex registry via `mix hex.info phoenix`] | Phoenix web framework used by Lockspire admin rendering. [VERIFIED: mix.lock] | Existing project dependency; do not upgrade in this phase. [VERIFIED: mix.exs] |
| Phoenix LiveView | locked `1.1.30`; recent `1.2.3` on Hex [VERIFIED: Hex registry via `mix hex.info phoenix_live_view`] | HEEx function components, LiveViews, rendered component tests. [VERIFIED: mix.lock] | Official docs support `attr`, `slot`, and function components for reusable UI. [CITED: https://phoenix-live-view.hexdocs.pm/Phoenix.Component.html] |
| Phoenix.Component | bundled with LiveView [VERIFIED: mix.lock] | `attr/3`, `slot/3`, `render_slot/1`, global attrs, and HEEx components. [CITED: https://phoenix-live-view.hexdocs.pm/Phoenix.Component.html] | Matches locked decision to keep function components with explicit attrs/slots. [VERIFIED: 118-CONTEXT.md] |
| Lockspire `AdminComponents` | local module [VERIFIED: codebase grep] | Shared admin primitives and meta-components. [VERIFIED: codebase grep] | Current call sites already depend on it; Phase 118 should extend it rather than create a parallel system. [VERIFIED: codebase grep] |
| Lockspire `AdminCSS` | local embedded CSS [VERIFIED: codebase grep] | Namespaced `lockspire-admin-*` BEM/token styling. [VERIFIED: codebase grep] | AGENTS and project state require embedded-library CSS boundaries. [VERIFIED: AGENTS.md] |

### Supporting

| Library / Tool | Version | Purpose | When to Use |
|----------------|---------|---------|-------------|
| ExUnit | bundled with Elixir `1.19.5` in environment [VERIFIED: local command] | Component contract and rendered stress tests. [VERIFIED: codebase grep] | Use for Phase 118 proof. [VERIFIED: 118-CONTEXT.md] |
| Phoenix.LiveViewTest | from LiveView `1.1.30` lock [VERIFIED: mix.lock] | `render_component/2` and `rendered_to_string/1` proof patterns. [VERIFIED: codebase grep] | Use for focused rendered assertions. [VERIFIED: 118-CONTEXT.md] |
| lazy_html | locked `0.1.11`; recent `0.1.11` on Hex [VERIFIED: Hex registry via `mix hex.info lazy_html`] | Existing test-only HTML parsing dependency. [VERIFIED: mix.exs] | Use only if selectors make assertions clearer than string checks. [ASSUMED] |
| PostgreSQL | `14.17` available locally [VERIFIED: local command] | Existing integration tests and setup aliases may need local DB. [VERIFIED: mix.exs] | Component-only tests should avoid DB unless touching LiveView integration tests. [ASSUMED] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Lockspire-owned lab | PhoenixStorybook | Deferred by locked decision; would add router/content integration and dependency weight outside Phase 118. [VERIFIED: 118-CONTEXT.md] |
| Phoenix function components | LiveComponents | Official LiveView docs say LiveComponents are for event handling plus additional state and not generic DOM organization. [CITED: https://phoenix-live-view.hexdocs.pm/Phoenix.LiveComponent.html] |
| ExUnit rendered proof | Playwright/axe/browser screenshots | Phase 120 owns mounted browser, viewport, theme, reduced-motion, axe, and screenshot evidence. [VERIFIED: 118-CONTEXT.md] |
| High-level Lockspire input component | Explicit Phoenix inputs inside `form_field` | Locked decision keeps input IDs/names/events visible to maintainers and reduces migration risk. [VERIFIED: 118-CONTEXT.md] |

**Installation:**
```bash
# No new package install for Phase 118. [VERIFIED: 118-CONTEXT.md]
```

## Package Legitimacy Audit

Phase 118 should install no external packages. [VERIFIED: 118-CONTEXT.md] Package legitimacy gate is not triggered because the plan should use existing Hex dependencies and local modules only. [VERIFIED: mix.exs]

| Package | Registry | Age | Downloads | Source Repo | Verdict | Disposition |
|---------|----------|-----|-----------|-------------|---------|-------------|
| none | n/a | n/a | n/a | n/a | n/a | No install approved. [VERIFIED: 118-CONTEXT.md] |

**Packages removed due to [SLOP] verdict:** none. [VERIFIED: 118-CONTEXT.md]
**Packages flagged as suspicious [SUS]:** none. [VERIFIED: 118-CONTEXT.md]

## Architecture Patterns

### System Architecture Diagram

```text
Admin LiveView assigns / HEEx call sites
  -> AdminComponents function components
    -> status metadata mapping / structural attrs / named slots
      -> lockspire-admin-* semantic CSS classes
        -> rendered admin HTML
          -> ExUnit rendered stress and contract assertions

Domain mutations, URL state, filters, forms, policies
  -> stay in LiveViews and admin/context modules
  -> are passed into components only as explicit attrs/slots
```

### Recommended Project Structure

```text
lib/lockspire/web/
├── components/admin_components.ex     # Additive attrs/slots and new function components. [VERIFIED: codebase grep]
├── admin_css.ex                       # Namespaced CSS for new structural/status/form classes. [VERIFIED: codebase grep]
└── live/admin/                        # Minimal proof migrations and documented exceptions. [VERIFIED: codebase grep]

test/support/lockspire/web/admin_lab/
├── fixtures.ex                        # Redaction-safe long/dense/status fixture coverage. [VERIFIED: codebase grep]
└── stress_surface.ex                  # Internal rendered stress surface. [VERIFIED: codebase grep]

test/lockspire/web/live/admin/
├── design_system_component_stress_test.exs  # Rendered stress assertions. [VERIFIED: codebase grep]
└── design_system_contract_test.exs          # Source/CSS/component contract assertions. [VERIFIED: codebase grep]
```

### Pattern 1: Additive Slot-Based Function Components

**What:** Add new `attr` and `slot` declarations before each function component and preserve existing component functions unchanged. [CITED: https://phoenix-live-view.hexdocs.pm/Phoenix.Component.html]

**When to use:** Use for `pane`, `entity_header`, `workflow_shell`, `status_cluster`, `lifecycle_row`, `dense_resource_row`, and `responsive_table`. [VERIFIED: 118-CONTEXT.md]

**Example:**
```elixir
# Source: Phoenix.Component docs and existing AdminComponents pattern. [CITED: https://phoenix-live-view.hexdocs.pm/Phoenix.Component.html]
attr(:title, :string, required: true)
attr(:subtitle, :string, default: nil)
attr(:class, :string, default: "")
slot(:status)
slot(:actions)
slot(:inner_block, required: true)

def pane(assigns) do
  ~H"""
  <section class={["lockspire-admin-pane", @class]}>
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

### Pattern 2: Single Status Metadata Helper

**What:** Keep `status_badge status={...}` compatible, add optional `domain` or `context`, and route all label/tone/title/cue decisions through one private metadata helper. [VERIFIED: 118-CONTEXT.md]

**When to use:** Use for every badge rendered by Configure, Support, and Operate pages. [VERIFIED: codebase grep]

**Example:**
```elixir
# Source: Phase 118 context and current status_badge implementation. [VERIFIED: codebase grep]
attr(:status, :atom, required: true)
attr(:domain, :atom, default: nil)
attr(:title, :string, default: nil)

def status_badge(assigns) do
  metadata = status_metadata(assigns.status, assigns.domain)

  assigns =
    assigns
    |> assign(:label, metadata.label)
    |> assign(:tone, metadata.tone)
    |> assign(:title, assigns.title || metadata.title)

  ~H"""
  <span class={badge_class(@tone)} title={@title}>{@label}</span>
  """
end
```

### Pattern 3: Field Wrapper Owns Chrome, Caller Owns Input

**What:** `form_field` renders label/help/error/required chrome and deterministic ids; the caller renders the input/select/textarea with explicit `id`, `name`, `aria-describedby`, and `aria-invalid`. [VERIFIED: 118-CONTEXT.md]

**When to use:** Use for ordinary configuration fields and filters where it does not obscure dense layout or security workflows. [VERIFIED: 118-CONTEXT.md]

**Example:**
```elixir
# Source: existing StressSurface form_field pattern. [VERIFIED: codebase grep]
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

### Anti-Patterns to Avoid

- **Parallel design-system module:** Do not create a new component namespace when current admin pages already use `AdminComponents`. [VERIFIED: codebase grep]
- **LiveComponent for DOM grouping:** Official docs warn against LiveComponents merely for organization or generic DOM abstraction. [CITED: https://phoenix-live-view.hexdocs.pm/Phoenix.LiveComponent.html]
- **Domain workflow hiding:** Do not hide OAuth/OIDC mutation policy in components; LiveViews and admin/context modules keep behavior. [VERIFIED: 118-CONTEXT.md]
- **Disabled status fallback for real states:** Unknown fallback may remain, but real Configure/Support/Operate statuses need intentional metadata. [VERIFIED: 118-CONTEXT.md]
- **Raw color/status drift:** New CSS should use semantic aliases and `lockspire-admin-*` names, not raw one-off colors. [VERIFIED: codebase grep]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Reusable HEEx component model | Custom rendering DSL | Phoenix.Component `attr`, `slot`, `render_slot`, and `:global` attrs. [CITED: https://phoenix-live-view.hexdocs.pm/Phoenix.Component.html] | Compile-time validations and existing project pattern already solve this. [CITED: https://phoenix-live-view.hexdocs.pm/Phoenix.Component.html] |
| Stateful component wrappers | LiveComponents for layout | Function components. [CITED: https://phoenix-live-view.hexdocs.pm/Phoenix.LiveComponent.html] | LiveComponents are for event handling plus additional state, not markup grouping. [CITED: https://phoenix-live-view.hexdocs.pm/Phoenix.LiveComponent.html] |
| Form event abstraction | A new Lockspire input framework | Phoenix forms plus explicit inputs inside `form_field`. [CITED: https://phoenix-live-view.hexdocs.pm/form-bindings.html] | Form-level `phx-change` and `phx-submit` behavior should remain visible. [CITED: https://phoenix-live-view.hexdocs.pm/form-bindings.html] |
| Browser lab/storybook | Public route or PhoenixStorybook | Existing test-only admin lab. [VERIFIED: 118-CONTEXT.md] | Phase 118 must not add a supported admin route or package dependency. [VERIFIED: 118-CONTEXT.md] |
| Status color semantics | Per-page badge classes | One metadata mapping plus semantic CSS aliases. [VERIFIED: 118-CONTEXT.md] | Prevents real statuses from falling through to disabled styling. [VERIFIED: codebase grep] |

**Key insight:** The hard part is preserving semantic and security boundaries while improving composition; custom UI frameworks would add risk without solving that boundary problem. [VERIFIED: 118-CONTEXT.md]

## Common Pitfalls

### Pitfall 1: Backward Compatibility Breaks Existing Call Sites
**What goes wrong:** Renaming old primitives or changing required slots breaks current admin pages. [VERIFIED: codebase grep]
**Why it happens:** New meta-components replace instead of wrap existing APIs. [ASSUMED]
**How to avoid:** Keep `page_hero`, `filter_bar`, `resource_item`, `action_group`, `status_badge`, `form_field`, `confirmation_panel`, `empty_state`, and related existing APIs. [VERIFIED: 118-CONTEXT.md]
**Warning signs:** Contract tests fail on "shared component primitives are exposed" source checks. [VERIFIED: codebase grep]

### Pitfall 2: Real Statuses Look Disabled
**What goes wrong:** Provenance, waiting, completed, or failed operational states render with muted disabled styling. [VERIFIED: codebase grep]
**Why it happens:** Current `badge_class(_other)` returns disabled. [VERIFIED: codebase grep]
**How to avoid:** Test every real admin status atom and keep disabled fallback for unknown-only proof. [VERIFIED: 118-CONTEXT.md]
**Warning signs:** Statuses like `:operator`, `:self_registered`, `:pending`, `:completed`, `:denied`, or `:discarded` lack explicit metadata. [VERIFIED: codebase grep]

### Pitfall 3: Form Wrapper Hides Phoenix Form Semantics
**What goes wrong:** IDs, names, `phx-change`, `phx-submit`, and changeset behavior become hard to inspect or change. [VERIFIED: 118-CONTEXT.md]
**Why it happens:** The component tries to own the actual input. [VERIFIED: 118-CONTEXT.md]
**How to avoid:** Keep inputs explicit in page HEEx and use `form_field` only for chrome and accessibility ids. [CITED: https://phoenix-live-view.hexdocs.pm/form-bindings.html]
**Warning signs:** A new component accepts a `field` and renders all input markup for production forms. [ASSUMED]

### Pitfall 4: Tests Become Snapshot-Like
**What goes wrong:** Large string snapshots fail on harmless layout edits. [ASSUMED]
**Why it happens:** Stress proof asserts whole HTML instead of labels, classes, statuses, and accessibility hooks. [VERIFIED: 118-CONTEXT.md]
**How to avoid:** Use focused assertions for user-visible labels, stable classes, `aria-*`, redaction, and fixture coverage. [VERIFIED: 118-CONTEXT.md]
**Warning signs:** A test compares an entire rendered component output blob. [ASSUMED]

### Pitfall 5: Secret Material Leaks Through Fixtures
**What goes wrong:** Copy-once/test fixture values normalize plaintext secret examples in rendered HTML or docs. [VERIFIED: AGENTS.md]
**Why it happens:** Stress tests add realistic-looking values without forbidden substring checks. [ASSUMED]
**How to avoid:** Extend `Fixtures.forbidden_substrings/0` and keep copy-once values as redacted placeholders. [VERIFIED: codebase grep]
**Warning signs:** Rendered HTML includes JWT-looking strings, private key markers, or production-like token prefixes. [VERIFIED: codebase grep]

## Code Examples

### Component With Named Slots
```elixir
# Source: Phoenix.Component slot docs. [CITED: https://phoenix-live-view.hexdocs.pm/Phoenix.Component.html]
slot :column do
  attr :label, :string, required: true
end

attr :rows, :list, default: []

def responsive_table(assigns) do
  ~H"""
  <div class="lockspire-admin-table-wrap">
    <table class="lockspire-admin-table">
      <thead>
        <tr><th :for={col <- @column}>{col.label}</th></tr>
      </thead>
      <tbody>
        <tr :for={row <- @rows}>
          <td :for={col <- @column}>{render_slot(col, row)}</td>
        </tr>
      </tbody>
    </table>
  </div>
  """
end
```

### LiveComponent Boundary
```elixir
# Source: Phoenix.LiveComponent docs. [CITED: https://phoenix-live-view.hexdocs.pm/Phoenix.LiveComponent.html]
# Use a LiveComponent only when the component owns additional state plus events.
# Use a function component for Phase 118 layout, row, pane, badge, and form chrome.
```

### Form-Level Events Stay Page-Owned
```elixir
# Source: Phoenix LiveView form bindings docs. [CITED: https://phoenix-live-view.hexdocs.pm/form-bindings.html]
<.form for={@form} id="client-form" phx-change="validate" phx-submit="save">
  <AdminComponents.form_field id="client-name" label="Client name" errors={@name_errors}>
    <input id="client-name" name="client[name]" value={@form[:name].value} />
  </AdminComponents.form_field>
</.form>
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Generic disabled fallback for unknown and many real badge states. [VERIFIED: codebase grep] | Domain-aware metadata mapping with explicit tone set. [VERIFIED: 118-CONTEXT.md] | Phase 118 target. [VERIFIED: .planning/ROADMAP.md] | Prevents real statuses from reading as unavailable controls. [VERIFIED: 118-CONTEXT.md] |
| Page-local repeated markup for pane/header/row/workflow groupings. [VERIFIED: codebase grep] | Shared slot-based meta-components. [VERIFIED: 118-CONTEXT.md] | Phase 118 target. [VERIFIED: .planning/ROADMAP.md] | Lets Phase 119 polish pages through reusable building blocks. [VERIFIED: .planning/ROADMAP.md] |
| Existing lab covers baseline primitives and states. [VERIFIED: codebase grep] | Phase 118 lab should add meta-components, status inventory, form/workflow stress, and long/dense cases. [VERIFIED: 118-UI-SPEC.md] | Phase 118 target. [VERIFIED: 118-UI-SPEC.md] | Keeps proof internal without browser stack. [VERIFIED: 118-CONTEXT.md] |

**Deprecated/outdated:**
- PhoenixStorybook as a Phase 118 default is out of scope; it remains future evaluation only. [VERIFIED: 118-CONTEXT.md]
- Browser/axe/screenshot proof is out of scope for Phase 118 and belongs to Phase 120. [VERIFIED: 118-CONTEXT.md]
- High-level Lockspire input components are out of scope for Phase 118. [VERIFIED: 118-CONTEXT.md]

## Status Inventory For Planning

| Status / State | Current Source | Required Tone | Planning Note |
|----------------|----------------|---------------|---------------|
| `:active`, `:open` | clients, consents, tokens, keys. [VERIFIED: codebase grep] | `:healthy` | Already partly mapped; keep explicit. [VERIFIED: codebase grep] |
| `:disabled`, `:retired` | clients, DCR policy, keys. [VERIFIED: codebase grep] | `:disabled` | Disabled is valid only for true disabled/retired states. [VERIFIED: 118-CONTEXT.md] |
| `:operator`, `:self_registered` | client provenance filters/badges. [VERIFIED: codebase grep] | `:provenance` | Do not treat as health. [VERIFIED: 118-CONTEXT.md] |
| `:pending`, `:pending_login`, `:pending_consent`, `:enqueued`, `:attempted` | device auth, interactions, logout deliveries. [VERIFIED: codebase grep] | `:waiting` | Must not fall through to disabled. [VERIFIED: 118-CONTEXT.md] |
| `:completed`, `:consumed`, `:used`, `:succeeded`, `:rendered`, `:skipped` | interactions, IATs, logout deliveries. [VERIFIED: codebase grep] | `:completed` | Finished states should not read as disabled. [VERIFIED: 118-CONTEXT.md] |
| `:retiring`, `:retryable`, `:denied` | keys, logouts, interactions. [VERIFIED: codebase grep] | `:warning` | Operator-attention, not terminal danger by default. [VERIFIED: 118-CONTEXT.md] |
| `:revoked`, `:reuse_detected`, `:discarded` | tokens, consents, IATs, logouts. [VERIFIED: codebase grep] | `:danger` | Danger for security incidents or terminal operational failure. [VERIFIED: 118-CONTEXT.md] |
| `:expired` | tokens, IATs, interactions, device auth. [VERIFIED: codebase grep] | `:disabled` or closed metadata | Must not imply a disabled control state unless context says closed elapsed-time state. [VERIFIED: 118-UI-SPEC.md] |
| `:upcoming` | keys. [VERIFIED: codebase grep] | `:waiting` or informational | Existing `:upcoming` info class should remain intentional. [VERIFIED: 118-UI-SPEC.md] |
| unknown atom | contract test only. [VERIFIED: 118-CONTEXT.md] | `:disabled` fallback | Test fallback as unknown-only behavior. [VERIFIED: 118-CONTEXT.md] |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `lazy_html` can be used only if selector assertions are clearer than string checks. | Standard Stack | Low; planner can use existing string assertions instead. |
| A2 | Component snapshot tests are brittle and should be avoided. | Common Pitfalls | Low; this is consistent with locked Phase 118 guidance but not separately verified. |
| A3 | A new component that accepts a field and renders all input markup would conflict with Phase 118 intent. | Common Pitfalls | Medium; locked decisions already discourage this, but exact acceptable wrapper shape is implementation-dependent. |

## Open Questions

1. **Should `domain` or `context` be the public attr name on `status_badge`?**
   - What we know: The context locks either `:domain` or `:context` as acceptable. [VERIFIED: 118-CONTEXT.md]
   - What's unclear: Which name best matches current admin vocabulary. [ASSUMED]
   - Recommendation: Use `domain` if the mapping distinguishes Configure/Support/Operate/resource domains; use `context` only if the same resource has state-dependent ambiguity. [ASSUMED]

2. **How much production migration belongs in Phase 118?**
   - What we know: The phase must prove forms use shared primitives where practical and exceptions are tested. [VERIFIED: .planning/ROADMAP.md]
   - What's unclear: Whether every existing form/filter should migrate now or only representative pressure points. [ASSUMED]
   - Recommendation: Migrate representative high-pressure forms/filters and add source-contract tests that document remaining exceptions. [VERIFIED: 118-CONTEXT.md]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Elixir | Compile and ExUnit tests. [VERIFIED: mix.exs] | yes | `1.19.5` [VERIFIED: local command] | none needed |
| Mix | Test aliases and dependency metadata. [VERIFIED: mix.exs] | yes | `1.19.5` [VERIFIED: local command] | none needed |
| PostgreSQL | Existing DB-backed tests if planner touches LiveView integration paths. [VERIFIED: mix.exs] | yes | `14.17`, accepting connections [VERIFIED: local command] | Prefer component-only tests where possible. [ASSUMED] |
| Hex package metadata | Version verification. [VERIFIED: local command] | yes | `mix hex.info` succeeded [VERIFIED: local command] | Use `mix.lock` if network fails. [ASSUMED] |

**Missing dependencies with no fallback:** none found. [VERIFIED: local command]

**Missing dependencies with fallback:** Context7 CLI/MCP unavailable; official docs were fetched directly from HexDocs/W3C/GOV.UK. [VERIFIED: local command]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit with Phoenix.LiveViewTest. [VERIFIED: codebase grep] |
| Config file | `test/test_helper.exs`. [VERIFIED: codebase grep] |
| Quick run command | `mix test test/lockspire/web/live/admin/design_system_component_stress_test.exs test/lockspire/web/live/admin/design_system_contract_test.exs` [VERIFIED: codebase grep] |
| Full suite command | `mix test.fast` [VERIFIED: mix.exs] |

### Phase Requirements -> Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| DS-02 | New primitive functions, attrs/slots, and CSS classes exist without removing old APIs. [VERIFIED: .planning/REQUIREMENTS.md] | source contract + rendered component | `mix test test/lockspire/web/live/admin/design_system_contract_test.exs` | yes [VERIFIED: codebase grep] |
| DS-03 | All real Configure/Support/Operate statuses map to intentional non-disabled semantics except unknown fallback. [VERIFIED: .planning/REQUIREMENTS.md] | source/rendered contract | `mix test test/lockspire/web/live/admin/design_system_contract_test.exs test/lockspire/web/live/admin/design_system_component_stress_test.exs` | yes, needs new cases [VERIFIED: codebase grep] |
| DS-04 | Forms use shared field/help/error/workflow primitives or document tested exceptions. [VERIFIED: .planning/REQUIREMENTS.md] | rendered component + source contract + focused LiveView tests | `mix test test/lockspire/web/live/admin/design_system_component_stress_test.exs test/lockspire/web/live/admin/*_test.exs` | yes, needs new cases [VERIFIED: codebase grep] |

### Sampling Rate

- **Per task commit:** `mix test test/lockspire/web/live/admin/design_system_component_stress_test.exs test/lockspire/web/live/admin/design_system_contract_test.exs` [VERIFIED: codebase grep]
- **Per wave merge:** `mix test.fast` [VERIFIED: mix.exs]
- **Phase gate:** Full suite green before `$gsd-verify-work`. [VERIFIED: .planning/config.json]

### Wave 0 Gaps

- [ ] Extend `test/lockspire/web/live/admin/design_system_contract_test.exs` for new component names/classes, status metadata, and exception inventory. [VERIFIED: codebase grep]
- [ ] Extend `test/support/lockspire/web/admin_lab/fixtures.ex` with all real status atoms and generated long values required by Phase 118. [VERIFIED: 118-UI-SPEC.md]
- [ ] Extend `test/support/lockspire/web/admin_lab/stress_surface.ex` for meta-components, disabled links, destructive action groups, dense filters, secondary navigation, empty table/list alternatives, repeated badges, and form/workflow primitives. [VERIFIED: 118-UI-SPEC.md]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V2 Authentication | no direct protocol change [VERIFIED: 118-CONTEXT.md] | Preserve host-owned operator authentication boundary. [VERIFIED: AGENTS.md] |
| V3 Session Management | no direct session change [VERIFIED: 118-CONTEXT.md] | Do not alter cookies or auth flows. [VERIFIED: 118-CONTEXT.md] |
| V4 Access Control | yes, boundary preservation [VERIFIED: AGENTS.md] | Do not mount lab routes or broaden admin surface. [VERIFIED: 118-CONTEXT.md] |
| V5 Input Validation | yes, admin forms and filters render validation feedback [VERIFIED: .planning/REQUIREMENTS.md] | Phoenix forms plus field-level errors and error summary. [CITED: https://phoenix-live-view.hexdocs.pm/form-bindings.html] |
| V6 Cryptography | yes, redaction boundary for secrets/keys/tokens [VERIFIED: AGENTS.md] | Never render plaintext secret/token/key material except approved copy-once creation surfaces. [VERIFIED: 118-CONTEXT.md] |
| V9 Communications | no direct transport change [VERIFIED: 118-CONTEXT.md] | No new endpoint or browser proof stack. [VERIFIED: 118-CONTEXT.md] |
| V14 Configuration | yes, admin DCR/security forms [VERIFIED: codebase grep] | Keep form semantics page-owned and documented. [VERIFIED: 118-CONTEXT.md] |

### Known Threat Patterns for Lockspire Admin UI

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Plaintext secret/token leakage in fixture/rendered HTML | Information Disclosure | Forbidden substring checks plus redacted/copy-once components. [VERIFIED: codebase grep] |
| Unsupported lab route exposed as public/admin surface | Elevation of Privilege / Information Disclosure | Keep lab under `test/support` and assert router/docs/package exclusions. [VERIFIED: codebase grep] |
| Status misclassification hides incident/waiting states | Tampering / Repudiation | Central metadata mapping and contract tests for all real statuses. [VERIFIED: 118-CONTEXT.md] |
| Color-only status meaning | Information Disclosure / Usability risk | Badge text plus non-color cue per WCAG use-of-color guidance. [CITED: https://www.w3.org/WAI/WCAG21/Understanding/use-of-color.html] |
| Form validation not programmatically associated with fields | Usability / Integrity | `aria-describedby`, field-level errors, and error summary. [CITED: https://design-system.service.gov.uk/components/error-summary/] |

## Sources

### Primary (HIGH confidence)

- `AGENTS.md` - Lockspire boundaries, stack, priorities, and security defaults. [VERIFIED: AGENTS.md]
- `.planning/phases/118-primitive-meta-component-upgrade/118-CONTEXT.md` - locked Phase 118 implementation decisions. [VERIFIED: 118-CONTEXT.md]
- `.planning/phases/118-primitive-meta-component-upgrade/118-UI-SPEC.md` - UI contract, stress scenarios, and explicit non-goals. [VERIFIED: 118-UI-SPEC.md]
- `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`, `.planning/STATE.md` - phase requirements, success criteria, and project state. [VERIFIED: planning docs]
- `lib/lockspire/web/components/admin_components.ex`, `lib/lockspire/web/admin_css.ex`, `test/support/lockspire/web/admin_lab/*`, `test/lockspire/web/live/admin/*design_system*` - actual implementation/test surface. [VERIFIED: codebase grep]

### Secondary (MEDIUM confidence)

- `https://phoenix-live-view.hexdocs.pm/Phoenix.Component.html` - function components, attrs, slots, global attrs. [CITED: https://phoenix-live-view.hexdocs.pm/Phoenix.Component.html]
- `https://phoenix-live-view.hexdocs.pm/Phoenix.LiveComponent.html` - LiveComponent use boundary. [CITED: https://phoenix-live-view.hexdocs.pm/Phoenix.LiveComponent.html]
- `https://phoenix-live-view.hexdocs.pm/form-bindings.html` - `phx-change`, `phx-submit`, and form event behavior. [CITED: https://phoenix-live-view.hexdocs.pm/form-bindings.html]
- `https://www.w3.org/WAI/WCAG21/Understanding/use-of-color.html` - non-color status meaning requirement. [CITED: https://www.w3.org/WAI/WCAG21/Understanding/use-of-color.html]
- `https://design-system.service.gov.uk/components/error-summary/` and `https://design-system.service.gov.uk/components/error-message/` - error summary plus field error pattern. [CITED: GOV.UK Design System]
- Hex registry via `mix hex.info` - current package metadata for Phoenix, LiveView, Phoenix HTML, and lazy_html. [VERIFIED: Hex registry]

### Tertiary (LOW confidence)

- Assumptions listed in the Assumptions Log. [ASSUMED]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - existing dependencies and local modules verified through `mix.exs`, `mix.lock`, and Hex metadata. [VERIFIED: codebase grep]
- Architecture: HIGH - locked by Phase 118 context and current component/test structure. [VERIFIED: 118-CONTEXT.md]
- Pitfalls: MEDIUM - major pitfalls are verified in code/context; brittleness guidance includes implementation judgment. [ASSUMED]

**Research date:** 2026-06-25
**Valid until:** 2026-07-25 for project-local findings; recheck HexDocs/Hex metadata if LiveView/Phoenix upgrades are proposed before implementation. [ASSUMED]
