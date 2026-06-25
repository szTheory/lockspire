# Phase 117: Component Lab, Fixtures & Foundation Hardening - Research

**Researched:** 2026-06-25  
**Domain:** Phoenix LiveView admin component lab, redaction-safe fixtures, admin CSS theme/motion foundations, maintainer browser proof  
**Confidence:** HIGH for repo-specific implementation shape; MEDIUM for optional browser tooling package versions

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| LAB-02 | The stress surface covers normal, empty, error, disabled, destructive, long-value, dense-data, light, dark, system, and reduced-motion states. [VERIFIED: .planning/REQUIREMENTS.md] | Use a Lockspire-owned internal lab module rendered by ExUnit with scenario metadata and real `AdminComponents` calls; expand the existing Phase 116 stress test instead of mounting a route. [VERIFIED: test/lockspire/web/live/admin/design_system_component_stress_test.exs; .planning/phases/116-inventory-rubric-lab-contract/116-LAB-CONTRACT.md] |
| DS-01 | Admin CSS declares explicit light and dark color-scheme behavior while preserving semantic-alias dark-mode remapping from the brand book. [VERIFIED: .planning/REQUIREMENTS.md] | Harden `lib/lockspire/web/admin_css.ex` around `color-scheme`, explicit light/default selectors, `prefers-color-scheme`, and semantic dark aliases; keep primitive token declarations stable. [VERIFIED: lib/lockspire/web/admin_css.ex; CITED: https://developer.mozilla.org/en-US/docs/Web/CSS/Reference/Properties/color-scheme; CITED: https://developer.mozilla.org/en-US/docs/Web/CSS/Reference/At-rules/%40media/prefers-color-scheme] |
| DS-05 | Admin motion uses explicit properties, purposeful short feedback, and reduced-motion-safe behavior with no `transition: all`. [VERIFIED: .planning/REQUIREMENTS.md] | Extend CSS source tests to ban `transition: all`, require explicit `transition-property`/duration tokens, and keep reduced-motion active states transform-free. [VERIFIED: lib/lockspire/web/admin_css.ex; test/lockspire/web/live/admin/design_system_contract_test.exs; CITED: https://developer.mozilla.org/en-US/docs/Web/CSS/Reference/Properties/transition-property; CITED: https://developer.mozilla.org/en-US/docs/Web/CSS/Reference/At-rules/%40media/prefers-reduced-motion] |
| PROOF-01 | Demo seeds or reusable test fixtures cover healthy, warning, incident, disabled, self-registered, expired, revoked, reuse-detected, copy-once, empty, dense, and long-value states while preserving redaction. [VERIFIED: .planning/REQUIREMENTS.md] | Add reusable fixture truth with fake namespaces and redaction assertions; do not store plaintext secrets, token material, codes, cookies, private keys, verifier material, or user codes in fixtures/screenshots/logs. [VERIFIED: .planning/phases/117-component-lab-fixtures-foundation-hardening/117-UI-SPEC.md; .planning/phases/116-inventory-rubric-lab-contract/116-LAB-CONTRACT.md] |
</phase_requirements>

## Summary

Phase 117 should build the stress surface as repo-local Lockspire implementation support, not as an admin product feature. The strongest path is to extract the existing test-local `StressSurface` into internal/test-support lab modules that render real `Lockspire.Web.Components.AdminComponents` with reusable redaction-safe fixture maps, then assert the scenario matrix through ExUnit-rendered HTML. [VERIFIED: test/lockspire/web/live/admin/design_system_component_stress_test.exs; .planning/phases/116-inventory-rubric-lab-contract/116-COMPONENT-GROUP-INVENTORY.md]

The production-facing work belongs mostly in `lib/lockspire/web/admin_css.ex`: explicit light behavior, semantic dark remapping, stronger dark panel/elevation readability, Signal Cyan restraint on light surfaces, explicit transition properties, and reduced-motion-safe active states. Existing CSS already has partial support for dark aliases, reduced-motion rules, and explicit transition properties on buttons, so this is hardening and regression proof rather than a rewrite. [VERIFIED: lib/lockspire/web/admin_css.ex]

**Primary recommendation:** Build `Lockspire.Web.AdminLab.Fixtures` plus `Lockspire.Web.AdminLab.StressSurface` as internal modules, keep them unmounted from `Lockspire.Web.AdminRouter`, expand `design_system_*` tests, and add optional Playwright+axe proof only under quarantined maintainer tooling with a human package-verification checkpoint. [VERIFIED: .planning/phases/116-inventory-rubric-lab-contract/116-LAB-CONTRACT.md; VERIFIED: lib/lockspire/web/admin_router.ex; CITED: https://playwright.dev/docs/accessibility-testing]

## Project Constraints (from AGENTS.md)

- Lockspire must remain a separate companion library, not a Sigra module. [VERIFIED: AGENTS.md]
- Preserve the embedded-library shape; do not turn the lab or admin UI into a required standalone auth service. [VERIFIED: AGENTS.md]
- Keep strong boundaries between protocol core, storage, generators, Plug/Phoenix integration, and LiveView/admin surfaces. [VERIFIED: AGENTS.md]
- Keep the host seam explicit and narrow: account resolution, claims, login redirects, branding, and product policy belong to the host app. [VERIFIED: AGENTS.md]
- Do not broaden v1 into SAML, LDAP/AD federation, hosted auth, or a full CIAM suite. [VERIFIED: AGENTS.md]
- Preserve security defaults: PKCE S256 required by default, exact redirect URI validation, hashed client secrets, single-use short-lived authorization codes, refresh token rotation with family-wide revocation on reuse, no implicit flow, no `alg=none`, and strong redaction. [VERIFIED: AGENTS.md]
- AGENTS.md lists Phoenix `1.8.5`, LiveView `1.1.28`, Ecto SQL `3.13.5`, PostgreSQL `14+`, Bandit `1.6.1`, Oban `2.21.x`, and OpenTelemetry `1.6.0`; local `mix.exs`/`mix.lock` currently resolve Phoenix `1.8.7`, LiveView `1.1.30`, Bandit `1.11.1`, Oban `2.21.1`, and `opentelemetry_api` `1.5.0`, so Phase 117 should not change dependency versions unless a separate dependency task is opened. [VERIFIED: AGENTS.md; VERIFIED: mix.exs; VERIFIED: mix.lock; VERIFIED: local `mix deps`]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|--------------|----------------|-----------|
| Component stress rendering | Test/Internal Lab | Browser proof | The lab proves real function components and groups without creating a supported runtime route. [VERIFIED: .planning/phases/116-inventory-rubric-lab-contract/116-LAB-CONTRACT.md] |
| Redaction-safe fixtures | Test/Internal Lab | Demo tooling | Fixtures should be deterministic, fake, and reusable by ExUnit/browser proof; production storage should not be changed. [VERIFIED: .planning/phases/117-component-lab-fixtures-foundation-hardening/117-UI-SPEC.md] |
| Light/dark/system styling | Browser / CSS | LiveView shell | CSS owns semantic tokens; `AdminLayoutLive` owns the existing theme select and `data-theme` behavior. [VERIFIED: lib/lockspire/web/admin_css.ex; VERIFIED: lib/lockspire/web/live/admin_layout_live.ex] |
| Motion/reduced-motion behavior | Browser / CSS | Test contracts | CSS controls transitions and active transforms; tests should enforce no broad transition declarations. [VERIFIED: lib/lockspire/web/admin_css.ex] |
| Browser/a11y proof | Maintainer tooling | Test/Internal Lab | Playwright+axe can inspect rendered pages, but it remains proof tooling, not a Hex package or supported admin API. [VERIFIED: .planning/STATE.md; CITED: https://playwright.dev/docs/intro] |

## Standard Stack

### Core

| Library / Module | Version | Purpose | Why Standard |
|------------------|---------|---------|--------------|
| Phoenix function components (`Phoenix.Component`) | LiveView locked `1.1.30` locally | Render stress surface with `attr/3`, `slot/3`, `~H`, and `render_slot/1`. | Existing `AdminComponents` uses this API and Phase 116 locked Phoenix function components as the design-system shape. [VERIFIED: mix.lock; VERIFIED: lib/lockspire/web/components/admin_components.ex; CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html] |
| `Phoenix.LiveViewTest.rendered_to_string/1` | LiveView locked `1.1.30` locally | Convert rendered lab HEEx into strings for ExUnit assertions. | Existing stress test already uses this pattern; official docs expose `rendered_to_string/1` for rendered template string conversion. [VERIFIED: test/lockspire/web/live/admin/design_system_component_stress_test.exs; CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveViewTest.html] |
| `Lockspire.Web.Components.AdminComponents` | Local module | Real admin primitive/meta-component rendering. | Phase 117 must stress real components, not mocked markup. [VERIFIED: lib/lockspire/web/components/admin_components.ex; VERIFIED: .planning/phases/116-inventory-rubric-lab-contract/116-COMPONENT-GROUP-INVENTORY.md] |
| `Lockspire.Web.Admin.CSS` | Local module | Embedded admin design tokens, BEM classes, theme aliases, motion behavior. | DS-01 and DS-05 are CSS foundation requirements. [VERIFIED: lib/lockspire/web/admin_css.ex; VERIFIED: .planning/REQUIREMENTS.md] |

### Supporting

| Library / Tool | Version | Purpose | When to Use |
|----------------|---------|---------|-------------|
| `lazy_html` | In test deps (`>= 0.1.0`) | Parse/assert rendered HTML structure if string contains become too brittle. | Use for structural assertions on scenario containers, IDs, links, labels, and redaction. [VERIFIED: mix.exs] |
| `@playwright/test` [WARNING: flagged as suspicious — verify before using.] | npm latest `1.61.1`, published 2026-06-23 | Optional browser harness for theme, reduced-motion, viewport, and screenshot proof. | Use only under quarantined maintainer proof tooling if Phase 117 adopts browser scaffolding. [CITED: https://playwright.dev/docs/intro; VERIFIED: npm view; VERIFIED: package-legitimacy seam] |
| `@axe-core/playwright` [WARNING: flagged as suspicious — verify before using.] | npm latest `4.12.1`, published 2026-06-23 | Optional automated accessibility scan integration for Playwright. | Use only as supplemental proof; official docs warn automated a11y tests catch only some issues. [CITED: https://playwright.dev/docs/accessibility-testing; VERIFIED: npm view; VERIFIED: package-legitimacy seam] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Internal Phoenix lab modules | PhoenixStorybook | Rejected/default-deferred by Phase 116/117 contracts; adding it would create dependency and registry surface not needed for this phase. [VERIFIED: .planning/phases/116-inventory-rubric-lab-contract/116-LAB-CONTRACT.md; VERIFIED: .planning/phases/117-component-lab-fixtures-foundation-hardening/117-UI-SPEC.md] |
| ExUnit-rendered component proof | Public/admin lab route | Forbidden by lab contract; would expand supported surface and host expectations. [VERIFIED: .planning/phases/116-inventory-rubric-lab-contract/116-LAB-CONTRACT.md; VERIFIED: lib/lockspire/web/admin_router.ex] |
| Repo-local fake fixture maps | Demo database seed mutation | Demo seeds already cover some proof states, but Phase 117 needs reusable fixture truth without storage side effects or plaintext secrets. [VERIFIED: test/lockspire/web/live/admin/design_system_contract_test.exs; VERIFIED: .planning/REQUIREMENTS.md] |

**Installation:**

No required package install for the core Phase 117 implementation. [VERIFIED: mix.exs; VERIFIED: .planning/phases/117-component-lab-fixtures-foundation-hardening/117-UI-SPEC.md]

If the planner adopts optional browser proof, use a quarantined maintainer directory and add a human checkpoint before install because both latest npm packages are `SUS` by the legitimacy seam:

```bash
# Example only after checkpoint:human-verify
npm install --save-dev @playwright/test @axe-core/playwright
npx playwright install chromium
```

## Package Legitimacy Audit

| Package | Registry | Age | Downloads | Source Repo | Verdict | Disposition |
|---------|----------|-----|-----------|-------------|---------|-------------|
| `@playwright/test` | npm | created 2020-09-24; latest modified 2026-06-25 | 41,891,083/week | github.com/microsoft/playwright | SUS (`too-new`) | Optional only; planner must add `checkpoint:human-verify` before install. [CITED: https://playwright.dev/docs/intro; VERIFIED: npm view; VERIFIED: package-legitimacy seam] |
| `@axe-core/playwright` | npm | created 2021-06-02; latest modified 2026-06-23 | 5,048,139/week | github.com/dequelabs/axe-core-npm | SUS (`too-new`) | Optional only; planner must add `checkpoint:human-verify` before install. [CITED: https://playwright.dev/docs/accessibility-testing; VERIFIED: npm view; VERIFIED: package-legitimacy seam] |

**Packages removed due to [SLOP] verdict:** none. [VERIFIED: package-legitimacy seam]  
**Packages flagged as suspicious [SUS]:** `@playwright/test`, `@axe-core/playwright`. [VERIFIED: package-legitimacy seam]

## Architecture Patterns

### System Architecture Diagram

```text
Phase 116 inventories + UI-SPEC
        |
        v
Lockspire.Web.AdminLab.Fixtures (fake, redaction-safe scenario data)
        |
        v
Lockspire.Web.AdminLab.StressSurface (Phoenix.Component, real AdminComponents)
        |
        +--> ExUnit rendered_to_string / lazy_html assertions
        |       |--> scenario/state coverage
        |       |--> redaction bans
        |       |--> no AdminRouter/docs support-surface expansion
        |
        +--> optional maintainer browser harness
                |--> loads static/demo lab output or demo host page
                |--> theme: light / dark / system
                |--> motion: default / reduced
                |--> viewport: 320 / 390 / 768 / 1024 / 1440
                |--> axe scan and screenshot evidence
```

### Recommended Project Structure

```text
lib/lockspire/web/admin_lab/
├── fixtures.ex          # fake scenario data, redaction helpers, matrix metadata
└── stress_surface.ex    # internal Phoenix.Component renderer for lab scenarios

test/lockspire/web/live/admin/
├── design_system_component_stress_test.exs  # rendered lab matrix coverage
└── design_system_contract_test.exs          # CSS/router/docs/package-boundary contracts

scripts/browser-proof/ or proof/browser/
├── package.json         # optional only; outside Hex package files
├── playwright.config.*  # optional only; maintainer proof config
└── specs/admin_lab.*    # optional only; viewport/theme/motion/axe checks
```

### Pattern 1: Internal Lab Renderer

**What:** Move the current test-local stress component into a `@moduledoc false` internal module that imports/aliases `AdminComponents`, receives a fixture set, and renders grouped scenarios with metadata attributes. [VERIFIED: test/lockspire/web/live/admin/design_system_component_stress_test.exs]

**When to use:** Use for LAB-02 and PROOF-01 coverage where the planner needs real component output without a public route. [VERIFIED: .planning/REQUIREMENTS.md; .planning/phases/116-inventory-rubric-lab-contract/116-LAB-CONTRACT.md]

**Example:**

```elixir
# Source: existing Lockspire stress test pattern + Phoenix.Component docs.
defmodule Lockspire.Web.AdminLab.StressSurface do
  @moduledoc false
  use Phoenix.Component
  alias Lockspire.Web.Components.AdminComponents

  attr :fixture_set, :map, required: true

  def render(assigns) do
    ~H"""
    <section class="lockspire-admin-lab" data-lab-surface="component-stress">
      <AdminComponents.page_hero eyebrow="Internal lab" title="Design-system stress surface">
        <:summary>
          <AdminComponents.badge_group>
            <AdminComponents.status_badge status={:active} />
            <AdminComponents.status_badge status={:reuse_detected} />
          </AdminComponents.badge_group>
        </:summary>
      </AdminComponents.page_hero>
    </section>
    """
  end
end
```

### Pattern 2: Redaction-Safe Fixture Truth

**What:** Keep fixtures as fake maps/struct-like maps with scenario labels, status atoms, long fake identifiers, `.example.invalid` URLs, hash/handle-only values, and copy-once placeholders that cannot be mistaken for live credentials. [VERIFIED: .planning/phases/117-component-lab-fixtures-foundation-hardening/117-UI-SPEC.md]

**When to use:** Use for clients, tokens, consents, keys, DCR/IAT, and operations scenario groups. [VERIFIED: .planning/phases/117-component-lab-fixtures-foundation-hardening/117-UI-SPEC.md]

**Example:**

```elixir
# Source: Phase 117 UI-SPEC fixture and redaction contract.
%{
  client_id: "client_lab_long_01HY6Q1P8Y4R5T6U7V8W9X0Y1Z",
  redirect_uri: "https://tenant-with-long-name.example.invalid/oauth/callbacks/finance/reconciliation",
  client_secret: :redacted,
  client_secret_hash: "redacted_handle_secret_hash_v1",
  copy_once_placeholder: "copy_once_placeholder_not_a_secret",
  status: :self_registered
}
```

### Pattern 3: CSS Source Contracts

**What:** Add tests that parse `Lockspire.Web.Admin.CSS.get()` for explicit light/default behavior, dark semantic remapping, no primitive redeclaration inside dark blocks, no `transition: all`, reduced-motion rules, and Signal Cyan restraint. [VERIFIED: test/lockspire/web/live/admin/design_system_contract_test.exs]

**When to use:** Use whenever changing `admin_css.ex`; Phase 117 should extend existing source-contract tests rather than rely only on screenshots. [VERIFIED: test/lockspire/web/live/admin/design_system_contract_test.exs]

**Example assertions:**

```elixir
css = Lockspire.Web.Admin.CSS.get()
refute css =~ ~r/transition\s*:\s*all\b/
assert css =~ "color-scheme: light"
assert css =~ "@media (prefers-color-scheme: dark)"
assert css =~ "@media (prefers-reduced-motion: reduce)"
```

### Anti-Patterns to Avoid

- **Mounting a lab route:** Do not add `component_lab`, `design_system_lab`, or similar routes to `Lockspire.Web.AdminRouter`. [VERIFIED: .planning/phases/116-inventory-rubric-lab-contract/116-LAB-CONTRACT.md]
- **Letting test modules become the lab implementation:** The Phase 116 stress surface is useful precedent, but Phase 117 needs reusable lab/fixture modules so future phases can render the same truth. [VERIFIED: test/lockspire/web/live/admin/design_system_component_stress_test.exs; VERIFIED: .planning/ROADMAP.md]
- **Persisting fixture secrets:** Do not place plaintext client secrets, RATs, IATs, access/refresh tokens, auth codes, cookies, private keys, verifier material, or user codes in fixtures or screenshots. [VERIFIED: .planning/phases/117-component-lab-fixtures-foundation-hardening/117-UI-SPEC.md]
- **Broad transitions:** Do not use `transition: all`; MDN defines `all` as applying to all transitionable properties, which conflicts with DS-05's explicit-property requirement. [CITED: https://developer.mozilla.org/en-US/docs/Web/CSS/Reference/Properties/transition-property; VERIFIED: .planning/REQUIREMENTS.md]
- **Browser proof as support surface:** Do not include Playwright files in Hex package files or supported admin docs. [VERIFIED: mix.exs; VERIFIED: .planning/phases/117-component-lab-fixtures-foundation-hardening/117-UI-SPEC.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Component templating | Custom string HTML renderer | Phoenix function components and HEEx | Existing admin components use `Phoenix.Component`, attrs, and slots. [VERIFIED: lib/lockspire/web/components/admin_components.ex] |
| Fixture secrecy checks | Visual/manual-only review | ExUnit banned-substring and scenario coverage tests | Secret leakage is security-sensitive and must be deterministic. [VERIFIED: .planning/phases/116-inventory-rubric-lab-contract/116-LAB-CONTRACT.md] |
| Theme switching logic | New public theming engine | Existing `data-theme` shell plus CSS semantic aliases | `AdminLayoutLive` already owns System/Light/Dark control; public theming is out of scope. [VERIFIED: lib/lockspire/web/live/admin_layout_live.ex; VERIFIED: .planning/phases/117-component-lab-fixtures-foundation-hardening/117-UI-SPEC.md] |
| Accessibility engine | Custom DOM accessibility scanner | Optional `@axe-core/playwright` plus manual/contract checks | Playwright docs use axe integration and warn automated scans are incomplete, so use it only as supplemental proof. [CITED: https://playwright.dev/docs/accessibility-testing] |
| Browser automation | Hand-written Chrome DevTools script | Optional `@playwright/test` | Playwright Test provides test runner, assertions, isolation, browser projects, reporting, and CLI execution. [CITED: https://playwright.dev/docs/intro] |

**Key insight:** The lab's value is repeatable pressure on real Lockspire components and CSS foundations; building generic storybook/theming/browser infrastructure would expand surface area without improving Phase 117's required proof. [VERIFIED: .planning/phases/116-inventory-rubric-lab-contract/116-LAB-CONTRACT.md; VERIFIED: .planning/ROADMAP.md]

## Common Pitfalls

### Pitfall 1: Lab Route Creep

**What goes wrong:** The stress surface is mounted under `/admin` and becomes a de facto supported route. [VERIFIED: .planning/phases/116-inventory-rubric-lab-contract/116-LAB-CONTRACT.md]  
**Why it happens:** Browser proof feels easier against a route than ExUnit-rendered HTML or quarantined demo proof. [ASSUMED]  
**How to avoid:** Add a contract test that `AdminRouter` and `docs/supported-surface.md` contain no lab route/support claim. [VERIFIED: test/lockspire/web/live/admin/design_system_contract_test.exs]  
**Warning signs:** New router strings like `component_lab`, public docs mentioning a design-system lab, or lab modules without `@moduledoc false`. [VERIFIED: .planning/phases/117-component-lab-fixtures-foundation-hardening/117-UI-SPEC.md]

### Pitfall 2: Fixture Secret Leakage

**What goes wrong:** Copy-once examples or token states accidentally contain credential-like plaintext. [VERIFIED: .planning/phases/117-component-lab-fixtures-foundation-hardening/117-UI-SPEC.md]  
**Why it happens:** Demo data often copies production nouns and can drift from redaction policy. [ASSUMED]  
**How to avoid:** Centralize fixture values and test for banned tokens/secret phrases across fixtures, lab render output, docs, and optional screenshots metadata. [VERIFIED: test/lockspire/web/live/admin/design_system_contract_test.exs]  
**Warning signs:** Values named `secret`, `token`, `code`, `verifier`, or `private_key` that are not `:redacted`, hash-only, handle-only, or explicitly fake placeholders. [VERIFIED: .planning/phases/116-inventory-rubric-lab-contract/116-LAB-CONTRACT.md]

### Pitfall 3: Theme Fixes Bypass Semantic Tokens

**What goes wrong:** Components get one-off dark-mode primitive inversions instead of consuming semantic aliases. [VERIFIED: .planning/phases/116-inventory-rubric-lab-contract/116-VISUAL-UX-RUBRIC.md]  
**Why it happens:** A local contrast bug is patched at the component selector rather than at the token alias layer. [ASSUMED]  
**How to avoid:** Keep primitive tokens declared once; remap semantic aliases in system/dark selectors; assert no extra primitive redeclarations. [VERIFIED: test/lockspire/web/live/admin/design_system_contract_test.exs]  
**Warning signs:** Raw hex outside token lines, `--ls-color-*` redeclared inside dark blocks, or Signal Cyan used as small light-mode text. [VERIFIED: test/lockspire/web/live/admin/design_system_contract_test.exs; VERIFIED: .planning/phases/117-component-lab-fixtures-foundation-hardening/117-UI-SPEC.md]

### Pitfall 4: Motion Becomes Decorative

**What goes wrong:** Broad transitions or active transforms create unnecessary movement, especially under reduced motion. [VERIFIED: .planning/REQUIREMENTS.md]  
**Why it happens:** `transition` shorthand defaults can hide `all`, and active scale transforms are easy to copy between controls. [CITED: https://developer.mozilla.org/en-US/docs/Web/CSS/Reference/Properties/transition-property]  
**How to avoid:** Require explicit transition properties and reduced-motion overrides for transform-based feedback. [VERIFIED: lib/lockspire/web/admin_css.ex]  
**Warning signs:** `transition: all`, long durations, transforms outside focused controls, or missing `prefers-reduced-motion` coverage. [VERIFIED: .planning/phases/117-component-lab-fixtures-foundation-hardening/117-UI-SPEC.md]

## Code Examples

### ExUnit Rendering Pattern

```elixir
# Source: Phoenix.LiveViewTest docs and existing Lockspire stress test.
import Phoenix.LiveViewTest

test "lab renders required scenario states without secret evidence" do
  html =
    Lockspire.Web.AdminLab.StressSurface.render(%{
      fixture_set: Lockspire.Web.AdminLab.Fixtures.all()
    })
    |> rendered_to_string()

  for phrase <- ["Reuse detected", "Copy-once credential", "No lab scenarios rendered"] do
    assert html =~ phrase
  end

  for forbidden <- ["real-client-secret", "prod-refresh-token", "authorization_code_plaintext"] do
    refute html =~ forbidden
  end
end
```

### Optional Playwright + Axe Pattern

```javascript
// Source: Playwright accessibility testing docs.
const { test, expect } = require('@playwright/test');
const AxeBuilder = require('@axe-core/playwright').default;

test('component lab has no automated WCAG A/AA violations', async ({ page }) => {
  await page.goto(process.env.LOCKSPIRE_ADMIN_LAB_URL);
  const results = await new AxeBuilder({ page })
    .withTags(['wcag2a', 'wcag2aa', 'wcag21a', 'wcag21aa'])
    .analyze();

  expect(results.violations).toEqual([]);
});
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Single happy-path admin screenshots | Source-rendered component matrix plus later browser proof | v1.31 Phase 116-117 contracts | Planner should require explicit state coverage, not just page rendering. [VERIFIED: .planning/ROADMAP.md; VERIFIED: .planning/phases/116-inventory-rubric-lab-contract/116-VISUAL-UX-RUBRIC.md] |
| Test-local stress component only | Reusable internal lab and fixture modules | Phase 117 target | Future phases can reuse identical fixture truth for component/page/browser proof. [VERIFIED: test/lockspire/web/live/admin/design_system_component_stress_test.exs; VERIFIED: .planning/ROADMAP.md] |
| Browser proof as one-off screenshots | Quarantined Playwright+axe proof option | v1.31 decision | Browser proof may be adopted, but it must stay outside Hex package files and not become public support truth. [VERIFIED: .planning/STATE.md; VERIFIED: mix.exs] |

**Deprecated/outdated:**

- PhoenixStorybook/React Storybook for this phase: rejected/default-deferred by Phase 116/117 contracts. [VERIFIED: .planning/phases/116-inventory-rubric-lab-contract/116-LAB-CONTRACT.md; VERIFIED: .planning/phases/117-component-lab-fixtures-foundation-hardening/117-UI-SPEC.md]
- Raw primitive dark-mode inversion: superseded by semantic alias remapping. [VERIFIED: .planning/phases/116-inventory-rubric-lab-contract/116-VISUAL-UX-RUBRIC.md]
- `transition: all`: conflicts with DS-05 and explicit transition-property proof. [VERIFIED: .planning/REQUIREMENTS.md; CITED: https://developer.mozilla.org/en-US/docs/Web/CSS/Reference/Properties/transition-property]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Browser proof feels easier against a route than ExUnit-rendered HTML or quarantined demo proof. | Common Pitfalls | Low; mitigation remains valid because route mounting is contract-forbidden. |
| A2 | Demo data often copies production nouns and can drift from redaction policy. | Common Pitfalls | Medium; if wrong, centralized redaction tests are still useful. |
| A3 | A local contrast bug may be patched at a component selector instead of the token alias layer. | Common Pitfalls | Low; source tests still prevent token discipline drift. |

## Open Questions

1. **Should optional Playwright+axe scaffolding be implemented in Phase 117 or deferred to Phase 120?**
   - What we know: State says adopt Playwright+axe as quarantined proof unless too heavy, while Phase 117 notes say add browser harness scaffolding here if adopting it. [VERIFIED: .planning/STATE.md; VERIFIED: .planning/ROADMAP.md]
   - What's unclear: Whether Phase 117 should install npm packages now or only design the harness path. [VERIFIED: package-legitimacy seam]
   - Recommendation: Plan core ExUnit/CSS work first; add a separate optional task with `checkpoint:human-verify` before npm install. [VERIFIED: package-legitimacy seam]

2. **Should lab modules live under `lib/` or `test/support/`?**
   - What we know: Hex package files include `lib`, `priv`, `docs`, and root package docs; putting lab modules under `lib` would include them in the Hex artifact unless package files change. [VERIFIED: mix.exs]
   - What's unclear: Whether maintainers want internal lab modules available to docs/demo proof outside test. [ASSUMED]
   - Recommendation: Prefer `test/support/lockspire/web/admin_lab/*` for test-only proof unless implementation needs demo/browser reuse; if using `lib`, keep `@moduledoc false` and verify no public docs claim. [VERIFIED: mix.exs; VERIFIED: .planning/phases/116-inventory-rubric-lab-contract/116-LAB-CONTRACT.md]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Elixir | ExUnit lab/tests | yes | 1.19.5 / OTP 28 | none needed. [VERIFIED: local command output] |
| Mix | Test and package commands | yes | 1.19.5 | none needed. [VERIFIED: local command output] |
| PostgreSQL client | Existing project integration tests, not core lab rendering | yes | 14.17 | Core Phase 117 source/render tests do not require DB. [VERIFIED: local command output] |
| Node.js | Optional Playwright proof | yes | 22.14.0 | Skip browser harness and rely on ExUnit/manual proof if not adopted. [VERIFIED: local command output; CITED: https://playwright.dev/docs/intro] |
| npm | Optional Playwright proof | yes | 11.1.0 | Skip browser harness and rely on ExUnit/manual proof if not adopted. [VERIFIED: local command output] |
| Chromium | Optional browser proof | yes | command present | Use Playwright-managed Chromium if packages are installed. [VERIFIED: local command output; CITED: https://playwright.dev/docs/intro] |
| Playwright CLI | Optional browser proof | no | — | Install only after human package checkpoint, or defer to Phase 120. [VERIFIED: local command output; VERIFIED: package-legitimacy seam] |

**Missing dependencies with no fallback:** none for core Phase 117. [VERIFIED: local command output]  
**Missing dependencies with fallback:** Playwright CLI is missing; fallback is ExUnit-rendered lab proof plus manual browser evidence, or a checkpointed optional install. [VERIFIED: local command output; VERIFIED: package-legitimacy seam]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit with Phoenix LiveViewTest; optional Playwright only if checkpointed. [VERIFIED: mix.exs; CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveViewTest.html] |
| Config file | `.formatter.exs` and `mix.exs`; no root Playwright config currently exists. [VERIFIED: local file listing; VERIFIED: mix.exs] |
| Quick run command | `mix test test/lockspire/web/live/admin/design_system_component_stress_test.exs test/lockspire/web/live/admin/design_system_contract_test.exs --max-failures 1` [VERIFIED: .planning/phases/116-inventory-rubric-lab-contract/116-VERIFICATION.md] |
| Full suite command | `mix test.fast` [VERIFIED: mix.exs] |

### Phase Requirements -> Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| LAB-02 | Stress surface renders required component, theme, motion, density, destructive, disabled, empty, error, long-value, copy-once, and redacted states. | unit/render contract | `mix test test/lockspire/web/live/admin/design_system_component_stress_test.exs --max-failures 1` | yes, expand existing file. [VERIFIED: test/lockspire/web/live/admin/design_system_component_stress_test.exs] |
| DS-01 | CSS declares explicit light/default, system, and dark behavior while preserving semantic alias remapping. | source contract | `mix test test/lockspire/web/live/admin/design_system_contract_test.exs --max-failures 1` | yes, expand existing file. [VERIFIED: test/lockspire/web/live/admin/design_system_contract_test.exs] |
| DS-05 | CSS has no `transition: all`, uses explicit properties/durations, and neutralizes reduced-motion active transforms. | source contract | `mix test test/lockspire/web/live/admin/design_system_contract_test.exs --max-failures 1` | yes, expand existing file. [VERIFIED: test/lockspire/web/live/admin/design_system_contract_test.exs] |
| PROOF-01 | Fixture truth covers required states and redaction bans. | unit/source/render contract | `mix test test/lockspire/web/live/admin/design_system_component_stress_test.exs --max-failures 1` | yes, expand existing file; likely add fixture module. [VERIFIED: test/lockspire/web/live/admin/design_system_component_stress_test.exs] |

### Sampling Rate

- **Per task commit:** Run the targeted design-system stress/contract files. [VERIFIED: .planning/phases/116-inventory-rubric-lab-contract/116-VERIFICATION.md]
- **Per wave merge:** Run `mix test.fast`. [VERIFIED: mix.exs]
- **Phase gate:** Run targeted tests plus `mix test.fast`; if optional browser harness is adopted, also run the maintainer browser proof command documented by the implementation. [VERIFIED: mix.exs; CITED: https://playwright.dev/docs/intro]

### Wave 0 Gaps

- [ ] Add or extract a reusable fixture module, likely `test/support/lockspire/web/admin_lab/fixtures.ex` or `lib/lockspire/web/admin_lab/fixtures.ex` depending on demo reuse decision. [VERIFIED: test/lockspire/web/live/admin/design_system_component_stress_test.exs; VERIFIED: mix.exs]
- [ ] Add or extract `StressSurface` from the test-local module into a reusable internal/test-support module. [VERIFIED: test/lockspire/web/live/admin/design_system_component_stress_test.exs]
- [ ] Extend `design_system_contract_test.exs` with DS-01/DS-05 assertions for explicit light behavior, dark surface separation, Signal Cyan restraint, no `transition: all`, and reduced-motion active states. [VERIFIED: test/lockspire/web/live/admin/design_system_contract_test.exs]
- [ ] Optional only: create quarantined browser harness config after human package checkpoint. [VERIFIED: package-legitimacy seam]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V2 Authentication | no | Host owns staff authentication; Phase 117 must not add auth behavior. [VERIFIED: AGENTS.md] |
| V3 Session Management | no | No session changes planned; host seam unchanged. [VERIFIED: AGENTS.md; VERIFIED: .planning/ROADMAP.md] |
| V4 Access Control | yes | Do not create a public/admin lab route; keep `AdminRouter` unchanged for lab. [VERIFIED: .planning/phases/116-inventory-rubric-lab-contract/116-LAB-CONTRACT.md] |
| V5 Input Validation | yes | Lab fixtures should use hostile long URLs/IDs/scopes and render through existing components without overflow or raw inline styles. [VERIFIED: .planning/phases/117-component-lab-fixtures-foundation-hardening/117-UI-SPEC.md] |
| V6 Cryptography | yes | Do not expose plaintext secrets, tokens, auth codes, cookies, private keys, verifier material, or user codes; use redacted/hash/handle-only fake values. [VERIFIED: AGENTS.md; VERIFIED: .planning/phases/117-component-lab-fixtures-foundation-hardening/117-UI-SPEC.md] |

### Known Threat Patterns for Phoenix/LiveView Admin Lab

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Lab becomes reachable admin route | Elevation of Privilege / Information Disclosure | Contract tests against `AdminRouter` and supported-surface docs; no route mount. [VERIFIED: test/lockspire/web/live/admin/design_system_contract_test.exs] |
| Secret-like fixture leaks to screenshots/docs/logs | Information Disclosure | Central fixture redaction, banned-substring tests, fake `.example.invalid` and `redacted_handle_*` values. [VERIFIED: .planning/phases/117-component-lab-fixtures-foundation-hardening/117-UI-SPEC.md] |
| UI polish invents unbacked destructive/operation actions | Tampering | Keep operation queues read-only unless domain APIs already exist; do not add retry/discard/logout controls in lab examples as product truth. [VERIFIED: .planning/STATE.md; VERIFIED: .planning/phases/116-inventory-rubric-lab-contract/116-ROUTE-WORKFLOW-INVENTORY.md] |
| Browser tooling enters Hex package/support surface | Supply Chain / Information Disclosure | Keep npm tooling outside package files; checkpoint suspicious packages before install. [VERIFIED: mix.exs; VERIFIED: package-legitimacy seam] |

## Sources

### Primary (HIGH confidence)

- `AGENTS.md` - project boundaries, stack, security defaults. [VERIFIED: AGENTS.md]
- `.planning/ROADMAP.md` and `.planning/REQUIREMENTS.md` - Phase 117 scope and requirement IDs. [VERIFIED: .planning/ROADMAP.md; VERIFIED: .planning/REQUIREMENTS.md]
- `.planning/phases/117-component-lab-fixtures-foundation-hardening/117-UI-SPEC.md` - UI, fixture, redaction, lab, and foundation contracts. [VERIFIED: .planning/phases/117-component-lab-fixtures-foundation-hardening/117-UI-SPEC.md]
- Phase 116 artifacts - lab boundary, route/workflow inventory, visual rubric, component/group inventory, verification. [VERIFIED: .planning/phases/116-inventory-rubric-lab-contract/116-LAB-CONTRACT.md; VERIFIED: .planning/phases/116-inventory-rubric-lab-contract/116-COMPONENT-GROUP-INVENTORY.md; VERIFIED: .planning/phases/116-inventory-rubric-lab-contract/116-VISUAL-UX-RUBRIC.md; VERIFIED: .planning/phases/116-inventory-rubric-lab-contract/116-ROUTE-WORKFLOW-INVENTORY.md; VERIFIED: .planning/phases/116-inventory-rubric-lab-contract/116-VERIFICATION.md]
- Local code and tests - `AdminComponents`, admin CSS, admin layout, design-system tests, `mix.exs`. [VERIFIED: lib/lockspire/web/components/admin_components.ex; VERIFIED: lib/lockspire/web/admin_css.ex; VERIFIED: lib/lockspire/web/live/admin_layout_live.ex; VERIFIED: test/lockspire/web/live/admin/design_system_contract_test.exs; VERIFIED: test/lockspire/web/live/admin/design_system_component_stress_test.exs; VERIFIED: mix.exs]

### Secondary (MEDIUM confidence)

- Phoenix LiveView docs for `Phoenix.Component` and `Phoenix.LiveViewTest`. [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html; CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveViewTest.html]
- MDN docs for `color-scheme`, `prefers-color-scheme`, `transition-property`, and `prefers-reduced-motion`. [CITED: https://developer.mozilla.org/en-US/docs/Web/CSS/Reference/Properties/color-scheme; CITED: https://developer.mozilla.org/en-US/docs/Web/CSS/Reference/At-rules/%40media/prefers-color-scheme; CITED: https://developer.mozilla.org/en-US/docs/Web/CSS/Reference/Properties/transition-property; CITED: https://developer.mozilla.org/en-US/docs/Web/CSS/Reference/At-rules/%40media/prefers-reduced-motion]
- Playwright official docs for optional browser proof and accessibility scans. [CITED: https://playwright.dev/docs/intro; CITED: https://playwright.dev/docs/accessibility-testing]
- npm registry and GSD package-legitimacy seam for optional package versions/verdicts. [VERIFIED: npm view; VERIFIED: package-legitimacy seam]

### Tertiary (LOW confidence)

- Assumptions in the Assumptions Log only. [ASSUMED]

## Metadata

**Confidence breakdown:**

- Standard stack: HIGH for core Elixir/Phoenix stack because it is verified from local `mix.exs`, `mix.lock`, code, tests, and Phase 116/117 contracts; MEDIUM for optional npm package versions because official docs and npm verify names/versions but legitimacy seam flags current releases as `SUS`. [VERIFIED: mix.exs; VERIFIED: mix.lock; VERIFIED: package-legitimacy seam]
- Architecture: HIGH because Phase 116 explicitly locked the lab boundary and current code already implements the component/CSS/test patterns. [VERIFIED: .planning/phases/116-inventory-rubric-lab-contract/116-LAB-CONTRACT.md; VERIFIED: lib/lockspire/web/components/admin_components.ex]
- Pitfalls: HIGH for route/redaction/CSS boundary pitfalls from Phase 116/117 contracts; LOW where marked assumed for human/process tendencies. [VERIFIED: .planning/phases/117-component-lab-fixtures-foundation-hardening/117-UI-SPEC.md]

**Research date:** 2026-06-25  
**Valid until:** 2026-07-02 for optional browser tooling versions; 2026-07-25 for repo-local architecture and CSS/lab contracts.
