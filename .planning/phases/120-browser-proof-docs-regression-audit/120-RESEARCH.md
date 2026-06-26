# Phase 120: Browser Proof, Docs & Regression Audit - Research

**Researched:** 2026-06-26
**Domain:** Phoenix LiveView admin UI proof, accessibility guardrails, maintainer browser evidence, and operator documentation
**Confidence:** MEDIUM

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

### Browser Proof Matrix And Tooling

- **D-01:** Use `Lockspire.Web.AdminRouter` plus the documented query workflow `/admin/clients/:client_id/edit?workflow=logout-propagation` as browser-proof route truth. Do not source Phase 120 route coverage from old screenshot filenames.
- **D-02:** Browser evidence should cover a representative route matrix spanning Orient, Configure, Support, Operate, every Phase 119-touched weak surface, and the component-lab/stress proof boundary. The matrix must exercise 320px, 390px, 768px, 1024px, and 1440px widths plus light, dark, system, and reduced-motion modes. It does not need a full route x width x theme cartesian explosion if the coverage table explicitly shows which route proves which width/theme/motion risk.
- **D-03:** Default to a hybrid proof strategy: deterministic ExUnit/LiveView contracts remain the always-on blocking guardrails, while Playwright plus axe may be added as quarantined maintainer browser proof for real viewport, computed-style, focus, and accessibility evidence.
- **D-04:** Browser tooling must stay outside Lockspire's runtime and public support surface. If Playwright/axe is introduced, keep Node/browser dependencies, reports, screenshots, and commands as maintainer proof only; do not add a supported runtime admin route, Hex package content, or public claim that Lockspire ships a browser testing product.
- **D-05:** If implementation proves Playwright/axe too heavy or flaky for this repo, fall back to Elixir contracts plus manual browser evidence while preserving the same route/viewport/theme/reduced-motion acceptance matrix and explicit gap notes.
- **D-06:** Treat the current `/admin/logout-deliveries` link in `ClientsLive.Show` as a Phase 120 audit/fix target because the supported route is `/admin/logouts`. Browser proof must catch route/link drift of this class before closure.

### Automated Guardrails And Accessibility

- **D-07:** Extend `test/lockspire/web/live/admin/design_system_contract_test.exs` as the fast deterministic source-contract layer for brand-token drift, raw hex color drift, public/package boundary drift, generic CTA drift, route/docs alignment, secret/redaction wording, theme contracts, and reduced-motion contracts.
- **D-08:** Keep `test/support/lockspire/web/admin_lab/*` and `test/lockspire/web/live/admin/design_system_component_stress_test.exs` as the internal component stress layer. It should continue proving real `AdminComponents` output across hostile redaction-safe fixtures, status semantics, long values, copy-once states, disabled/destructive controls, form help/error IDs, and theme/motion markers.
- **D-09:** Add or reuse rendered-markup helpers, preferably with existing LazyHTML/LiveViewTest capabilities, for duplicate IDs, accessible label/description references, generic CTA text, secret denylist checks, and route-specific redaction. Favor mounted `live/2` tests for representative real admin pages where shell, navigation, and route markup matter.
- **D-10:** Browser/axe checks are supplemental, not a WCAG certification claim. Automated accessibility scans should target WCAG A/AA-relevant issues where possible, but final review must still cover keyboard flow, focus order, microcopy clarity, destructive consequence framing, and screen-reader comprehension risks that automation cannot prove.
- **D-11:** Screenshot inventories are evidence after guardrails pass, not the primary assertion mechanism. Store screenshot paths and browser notes as maintainer evidence and avoid committing or documenting sensitive values.

### Operator JTBD And Design-System Review

- **D-12:** Use route-by-route JTBD as the review spine. Each representative route should still answer its locked operator job: Orient asks what needs attention, Configure asks what posture should change, Support asks what happened to an account/client/token/grant, and Operate asks what live protocol work is waiting or failing.
- **D-13:** Apply the Phase 116 visual rubric and current `brandbook/` as the visual source of truth. The admin should read as calm, precise, structured trust: dense but scannable, domain-specific, light/dark/system-safe, reduced-motion-safe, and free of generic security-dashboard tropes.
- **D-14:** Final adversarial review must explicitly check host-app integration weight, inaccessible custom behavior, backend implementation leakage into operator UX, generic template UI drift, dark/mobile regressions, screenshot-only quality, secret/plaintext leakage, bad links, unsupported queue actions, and protocol/support-surface creep.
- **D-15:** Phase 120 design-quality pillars are accessibility, responsive reflow, information architecture, security/redaction, theme and motion behavior, performance/tooling weight, maintainability, docs truth, and developer/maintainer DX. Planning should map proof tasks to these pillars rather than treating the phase as screenshot capture only.

### Docs And Support Boundary

- **D-16:** Update `docs/operator-admin.md` with a short v1.31 design-system workflow and proof-boundary section covering shared primitives, component lab boundary, theme behavior, and verification expectations.
- **D-17:** Add a maintainer-only Phase 120 proof artifact, such as `120-BROWSER-PROOF.md` or `120-DOCS-DX-PROOF.md`, to record the route matrix, commands, screenshot/evidence paths, axe/browser notes, gaps, and final adversarial review. This artifact is planning evidence, not runtime or public support truth.
- **D-18:** Do not create a new public design-system doc in Phase 120. That would imply a public component API, lab, or theming support surface that Lockspire does not ship.
- **D-19:** Avoid changing `docs/supported-surface.md` unless implementation finds a concrete ambiguity that needs a narrow exclusion. The public support contract should remain the ceiling, not a home for design-system internals.
- **D-20:** Public docs should keep the exact ownership split: Lockspire owns protocol/operator state after the host-guarded admin router; the host owns staff authentication, MFA, roles, tenant policy, outer layouts, branding, and product authorization.

### the agent's Discretion

Planner may choose exact artifact names, browser script shape, and proof command layout as long as D-01 through D-20 remain true. Prefer a small, explicit maintainer command over a broad CI matrix if the browser stack is unstable. Prefer source-derived route matrices, focused rendered assertions, and clear evidence tables over brittle wholesale HTML or screenshot snapshots.

### Deferred Ideas (OUT OF SCOPE)

- Full browser-proof CI as a required branch-protection gate is deferred unless the quarantined harness proves stable and low-noise.
- Visual snapshot diffing remains deferred until browser evidence is stable enough to avoid screenshot churn.
- A public design-system documentation site or public component API remains out of scope.
- PhoenixStorybook remains a future option only if the internal lab becomes too bespoke or component API growth justifies the dependency and route boundary.
- Public theming, host-editable component registries, standalone admin services, hosted auth, React/JS Storybook shells, and mounted public lab routes remain out of scope.
- New retry/discard/approval/logout worker controls for operation queues are deferred unless a later phase adds explicit domain APIs.

### Reviewed Todos (not folded)

No matching pending todos were found for Phase 120.
</user_constraints>

## Summary

Phase 120 should be planned as a proof-and-documentation phase, not a feature phase: the blocking layer is deterministic ExUnit/Phoenix LiveViewTest coverage over source contracts, mounted route markup, internal stress fixtures, redaction, route alignment, labels/descriptions, duplicate IDs, responsive CSS contracts, theme contracts, and docs boundaries. [VERIFIED: codebase] The browser lane should be maintainer-only and quarantined because the repository currently has no `package.json`, no `node_modules`, and no Playwright binary, while Node 22.14.0 and npm 11.1.0 are available if the planner chooses to add the optional proof harness. [VERIFIED: local environment]

The recommended architecture is a hybrid proof: use `AdminRouter` plus `/admin/clients/:client_id/edit?workflow=logout-propagation` for the route matrix, extend `design_system_contract_test.exs` and `design_system_component_stress_test.exs` for always-on guardrails, add focused LazyHTML/LiveViewTest helpers for rendered markup, and optionally add a small Playwright+axe command for real viewport, computed-style, focus, screenshot, and automated accessibility evidence. [VERIFIED: codebase] [CITED: https://hexdocs.pm/phoenix_live_view/1.1.28/Phoenix.LiveViewTest.html] [CITED: https://playwright.dev/docs/accessibility-testing]

The docs slice should update only `docs/operator-admin.md` unless a concrete ambiguity is found in `docs/supported-surface.md`, and it should add a maintainer proof artifact under the Phase 120 directory. [VERIFIED: 120-CONTEXT.md] The final adversarial audit should be route/JTBD-led and explicitly cover accessibility, responsive reflow, security/redaction, theme/motion, unsupported action drift, bad links, host-boundary creep, and docs truth. [VERIFIED: 120-CONTEXT.md]

**Primary recommendation:** Plan Phase 120 in four slices: deterministic contract guardrails, rendered LiveView markup guardrails, quarantined maintainer browser proof with fallback, and docs plus adversarial audit. [VERIFIED: codebase]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|--------------|----------------|-----------|
| Admin route truth and supported-surface boundaries | Frontend Server (Phoenix Router/LiveView) | Documentation / Maintainer Process | `Lockspire.Web.AdminRouter` is the canonical mounted admin route source, and `docs/supported-surface.md` is the public support ceiling. [VERIFIED: codebase] |
| Deterministic design-system regression guardrails | Frontend Server Test Layer | Browser / Client | Existing ExUnit tests already inspect CSS, component source, docs boundaries, routes, and rendered component output. [VERIFIED: codebase] |
| Real viewport, theme, reduced-motion, focus, and axe evidence | Browser / Client | Maintainer Tooling | Playwright officially supports viewport/media emulation and `@axe-core/playwright` scans the current page state in a real browser. [CITED: https://playwright.dev/docs/api/class-page] [CITED: https://playwright.dev/docs/accessibility-testing] |
| Component lab/stress proof | Frontend Server Test Layer | Documentation / Maintainer Process | `AdminLab.Fixtures` and `AdminLab.StressSurface` are internal test/support surfaces and are not mounted in `AdminRouter`. [VERIFIED: codebase] |
| Operator docs and proof artifact | Documentation / Maintainer Process | Frontend Server Test Layer | Phase 120 requires docs truth without public design-system support claims, and tests can guard against public/package boundary drift. [VERIFIED: 120-CONTEXT.md] |
| Secret/redaction proof | Frontend Server Test Layer | Browser / Client | Existing fixture denylist and component stress tests already check plaintext leakage, while browser artifacts can leak DOM text unless treated as maintainer-local evidence. [VERIFIED: codebase] |

## Project Constraints (from AGENTS.md)

- Lockspire is an embedded OAuth/OIDC authorization server library for Phoenix and Elixir, not a standalone hosted auth service. [VERIFIED: AGENTS.md]
- Host applications keep ownership of accounts, login UX, layouts, branding, and product-specific policy. [VERIFIED: AGENTS.md]
- Preserve the embedded-library shape and keep boundaries between protocol core, storage, generators, Plug/Phoenix integration, and LiveView/admin surfaces. [VERIFIED: AGENTS.md]
- The host seam must stay explicit and narrow: account resolution, claims, login redirects, branding, and product policy belong to the host app. [VERIFIED: AGENTS.md]
- Do not broaden v1 into SAML, LDAP/AD federation, hosted auth, or a full CIAM suite. [VERIFIED: AGENTS.md]
- Security defaults to preserve include PKCE S256 by default, exact-match redirect URI validation, hashed client secrets at rest, short-lived single-use authorization codes, refresh token rotation with family-wide revocation on reuse, no implicit flow, no `alg=none`, and strong redaction in logs/operator surfaces. [VERIFIED: AGENTS.md]
- AGENTS.md names Phoenix `1.8.5` and Phoenix LiveView `1.1.28`, while current `mix.lock` resolves Phoenix `1.8.7` and Phoenix LiveView `1.1.30` under compatible `~>` constraints. [VERIFIED: AGENTS.md] [VERIFIED: mix.lock]

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| PROOF-02 | Browser proof covers 320px, 390px, 768px, 1024px, and 1440px widths across light, dark, system, and reduced-motion modes for the representative route matrix. | Use a source-derived route matrix from `AdminRouter` plus the logout-propagation query workflow, then attach browser/manual evidence by route, width, theme, motion, risk, screenshot path, axe note, and gap note. [VERIFIED: .planning/REQUIREMENTS.md] |
| PROOF-03 | Automated guardrails cover brand-token drift, raw color drift, responsive overflow, focus reachability, accessible labels/descriptions, duplicate IDs, contrast token pairs, plaintext secret leakage, and generic CTA drift. | Extend existing contract/stress tests and add LazyHTML/LiveViewTest helpers for rendered markup; use Playwright/axe only as supplemental maintainer evidence. [VERIFIED: codebase] [CITED: https://hexdocs.pm/phoenix_live_view/1.1.28/Phoenix.LiveViewTest.html] |
| PROOF-04 | Operator docs explain the strengthened design-system workflow, component lab boundary, theme behavior, and verification expectations without creating new public support claims. | Update `docs/operator-admin.md`, add a maintainer-only proof artifact, and avoid `docs/supported-surface.md` unless a narrow support ambiguity is found. [VERIFIED: 120-CONTEXT.md] |
</phase_requirements>

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| ExUnit | bundled with Mix 1.19.5 in this environment | Blocking deterministic regression tests. | Existing admin design-system tests are ExUnit-based and already run in the repo's `mix test.fast` flow. [VERIFIED: local environment] [VERIFIED: mix.exs] |
| Phoenix LiveViewTest | constraint `~> 1.1.28`; lock `1.1.30`; docs target `1.1.28` | Mounted LiveView route rendering, interaction simulation, form checks, duplicate-ID failure path, and function-component rendering. | Official LiveViewTest docs expose `live/3`, `render/1`, `render_component/3`, form helpers, and `:on_error` for detected errors such as duplicate IDs. [VERIFIED: mix.exs] [VERIFIED: mix.lock] [CITED: https://hexdocs.pm/phoenix_live_view/1.1.28/Phoenix.LiveViewTest.html] |
| LazyHTML | `0.1.11` locked | Parse and query rendered HTML for labels, descriptions, duplicate IDs, denied text, and route/link assertions. | The repo already depends on LazyHTML in test, and its docs expose `from_document/1`, `query/2`, `attribute/2`, and `text/1`. [VERIFIED: mix.exs] [VERIFIED: mix.lock] |
| `Lockspire.Web.AdminComponents` | local | Shared Phoenix function-component primitive surface for admin proof. | Phase 118/119 already centralized admin UI primitives here, and stress tests render real component output. [VERIFIED: codebase] |
| `Lockspire.Web.AdminCSS` | local | Embedded `lockspire-admin-*` BEM/token CSS proof target. | Existing CSS contains the theme, responsive, focus, long-value, table/list, and reduced-motion contracts Phase 120 must prove. [VERIFIED: codebase] |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `@playwright/test` [WARNING: flagged as suspicious - verify before using.] | latest `1.61.1`; package created 2020-09-24; latest published 2026-06-23 | Optional maintainer browser proof runner for viewport/media/focus/screenshot evidence. | Use only if the planner accepts a human verification checkpoint because the legitimacy seam flagged the current latest as `SUS` due to a very recent publish. [CITED: https://playwright.dev/docs/intro] [VERIFIED: npm view metadata] [VERIFIED: package-legitimacy seam] |
| `@axe-core/playwright` [WARNING: flagged as suspicious - verify before using.] | latest `4.12.1`; package created 2021-06-02; latest published 2026-06-23 | Optional axe-core integration for automated accessibility scans in Playwright. | Use only as supplemental evidence and only after human verification because the legitimacy seam flagged the current latest as `SUS` due to a very recent publish. [CITED: https://playwright.dev/docs/accessibility-testing] [VERIFIED: npm view metadata] [VERIFIED: package-legitimacy seam] |
| Playwright browser binaries | installed by `npx playwright install --with-deps` | Chromium/browser execution for real viewport, media, focus, screenshots, and axe scans. | Use for maintainer proof only; official CI docs require browser dependencies or Docker image setup. [CITED: https://playwright.dev/docs/ci] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Optional Playwright browser proof | Elixir contracts plus manual browser evidence | This is the locked fallback if Playwright/axe is heavy or flaky, but it cannot automatically prove computed browser layout/focus at real widths. [VERIFIED: 120-CONTEXT.md] |
| LazyHTML rendered assertions | Regex over rendered HTML | Regex is brittle for nested DOM and accessible-reference checks; LazyHTML is already in the test dependency graph. [VERIFIED: mix.exs] |
| Axe scans | Manual-only accessibility checklist | Manual review remains required, but Playwright docs explicitly warn automated scans are partial and still useful for detectable WCAG A/AA issues. [CITED: https://playwright.dev/docs/accessibility-testing] |
| Full route x width x theme cartesian browser matrix | Representative risk matrix | The phase context explicitly rejects a full cartesian requirement when coverage is explicit. [VERIFIED: 120-CONTEXT.md] |

**Installation, only if the optional browser lane is adopted after human verification:**

```bash
npm install --save-dev @playwright/test@1.61.1 @axe-core/playwright@4.12.1
npx playwright install --with-deps chromium
```

**Version verification:** `npm view @playwright/test version time.created time.modified repository.url dist-tags.latest` returned `1.61.1`, created `2020-09-24T05:44:34.469Z`, modified `2026-06-26T06:33:34.602Z`, repo `git+https://github.com/microsoft/playwright.git`; `npm view @axe-core/playwright ...` returned `4.12.1`, created `2021-06-02T15:18:16.053Z`, modified `2026-06-23T16:13:52.632Z`, repo `git+https://github.com/dequelabs/axe-core-npm.git`. [VERIFIED: npm view metadata]

## Package Legitimacy Audit

| Package | Registry | Age | Downloads | Source Repo | Verdict | Disposition |
|---------|----------|-----|-----------|-------------|---------|-------------|
| `@playwright/test` | npm | 5 years 9 months since package creation; latest version published 2026-06-23 | 41,891,083/week | `github.com/microsoft/playwright` | SUS (`too-new`) | Flagged - planner must add `checkpoint:human-verify` before install. [VERIFIED: package-legitimacy seam] |
| `@axe-core/playwright` | npm | 5 years since package creation; latest version published 2026-06-23 | 5,048,139/week | `github.com/dequelabs/axe-core-npm` | SUS (`too-new`) | Flagged - planner must add `checkpoint:human-verify` before install. [VERIFIED: package-legitimacy seam] |

**Packages removed due to [SLOP] verdict:** none. [VERIFIED: package-legitimacy seam]

**Packages flagged as suspicious [SUS]:** `@playwright/test`, `@axe-core/playwright`. [VERIFIED: package-legitimacy seam]

`npm view @playwright/test scripts.postinstall` and `npm view @axe-core/playwright scripts.postinstall` returned no postinstall scripts in this session. [VERIFIED: npm view metadata]

## Architecture Patterns

### System Architecture Diagram

```text
AdminRouter + logout-propagation query workflow
  -> Representative route/JTBD matrix
  -> ExUnit source-contract tests
       -> CSS token/theme/motion/raw-color/public-boundary assertions
       -> Route/docs alignment and secret/generic-copy assertions
  -> LiveViewTest mounted route renders
       -> LazyHTML duplicate-id, label, description, link, CTA, redaction checks
  -> Internal component stress surface
       -> Hostile redaction-safe fixture states across primitives
  -> Optional quarantined Playwright command
       -> Width/theme/reduced-motion/focus/browser overflow checks
       -> Optional AxeBuilder scan scoped to admin shell
       -> Maintainer-local screenshots/report paths
  -> Phase 120 proof artifact + operator docs update
  -> Final adversarial audit against D-14/D-15 pillars
```

### Recommended Project Structure

```text
test/lockspire/web/live/admin/
├── design_system_contract_test.exs              # Extend fast source/docs/CSS/route contracts. [VERIFIED: codebase]
├── design_system_component_stress_test.exs      # Keep internal rendered component stress proof. [VERIFIED: codebase]
└── admin_browser_contract_test.exs              # Optional new mounted-route guardrails if helpers outgrow existing file. [ASSUMED]

test/support/lockspire/web/admin_lab/
├── fixtures.ex                                  # Existing redaction-safe hostile states. [VERIFIED: codebase]
└── stress_surface.ex                            # Existing internal component stress renderer. [VERIFIED: codebase]

test/support/lockspire/web/admin_proof/
└── html_assertions.ex                           # Recommended helper home for LazyHTML checks. [ASSUMED]

scripts/maintainer/
└── admin_browser_proof                          # Recommended optional Playwright/manual proof entrypoint. [ASSUMED]

.planning/phases/120-browser-proof-docs-regression-audit/
├── 120-RESEARCH.md                              # This artifact. [VERIFIED: codebase]
└── 120-BROWSER-PROOF.md                         # Recommended maintainer proof artifact. [VERIFIED: 120-CONTEXT.md]

tmp/admin-ui-polish/phase-120/
└── screenshots-and-reports/                     # Recommended local evidence output; do not treat as public docs. [VERIFIED: 120-CONTEXT.md]
```

### Pattern 1: Contract-First Proof

**What:** Keep all guardrails that can be proven by source, CSS, docs, route tables, rendered components, and mounted LiveViews in ExUnit. [VERIFIED: codebase]

**When to use:** Use this for PROOF-03 and as the prerequisite before collecting screenshots or browser notes. [VERIFIED: 120-CONTEXT.md]

**Example:**

```elixir
# Source: Phoenix LiveViewTest docs and existing test patterns
{:ok, view, html} = live(conn, "/admin/logouts", on_error: :raise)
assert html =~ "Logout propagation"
refute html =~ "/admin/logout-deliveries"
refute render(view) =~ "real-client-secret"
```

### Pattern 2: Rendered DOM Helper Layer

**What:** Add a small helper module around `LazyHTML.from_document/1`, `LazyHTML.query/2`, `LazyHTML.attribute/2`, and `LazyHTML.text/1` to assert duplicate IDs, described-by targets, labels, link destinations, redaction denylist, and generic CTA denylist. [VERIFIED: mix.lock]

**When to use:** Use it when source grep cannot prove the rendered markup that a screen reader or browser receives. [VERIFIED: codebase]

**Example:**

```elixir
# Source: LazyHTML API in deps/lazy_html and Phoenix LiveViewTest render docs
doc = LazyHTML.from_document(html)

ids =
  doc
  |> LazyHTML.query("[id]")
  |> LazyHTML.to_tree()
  |> collect_attr("id")

assert ids == Enum.uniq(ids)
assert LazyHTML.query(doc, ~s(input[aria-describedby])) != []
```

### Pattern 3: Quarantined Maintainer Browser Proof

**What:** Keep Playwright config, package files, reports, screenshots, and commands explicitly labeled as maintainer proof and outside Hex/runtime/public support claims. [VERIFIED: 120-CONTEXT.md]

**When to use:** Use it to collect PROOF-02 evidence after deterministic tests pass, or replace it with manual browser notes if the dependency stack is too noisy. [VERIFIED: 120-CONTEXT.md]

**Example:**

```typescript
// Source: Playwright accessibility and emulation docs
import { test, expect } from '@playwright/test';
import AxeBuilder from '@axe-core/playwright';

test('admin logouts fits 390px dark reduced motion', async ({ page }) => {
  await page.setViewportSize({ width: 390, height: 900 });
  await page.emulateMedia({ colorScheme: 'dark', reducedMotion: 'reduce' });
  await page.goto('/admin/logouts');

  await expect
    .poll(() => page.evaluate(() => document.documentElement.scrollWidth <= window.innerWidth))
    .toBe(true);

  const scan = await new AxeBuilder({ page })
    .include('.lockspire-admin-shell')
    .withTags(['wcag2a', 'wcag2aa', 'wcag21a', 'wcag21aa'])
    .analyze();

  expect(scan.violations).toEqual([]);
});
```

### Pattern 4: Docs-as-Boundary Contract

**What:** Update `docs/operator-admin.md` with the workflow, lab boundary, theme behavior, and verification expectations while guarding public support docs from design-system/lab/browser-product claims. [VERIFIED: 120-CONTEXT.md]

**When to use:** Use it for PROOF-04 and final docs audit. [VERIFIED: .planning/REQUIREMENTS.md]

**Example:**

```elixir
# Source: existing design_system_contract_test.exs public-boundary style
operator_docs = File.read!("docs/operator-admin.md")
supported_surface = File.read!("docs/supported-surface.md")

assert operator_docs =~ "design-system proof"
refute supported_surface =~ "component lab"
refute supported_surface =~ "Playwright"
```

### Anti-Patterns to Avoid

- **Screenshot-only proof:** Screenshots are evidence after guardrails pass, not assertions. [VERIFIED: 120-CONTEXT.md]
- **Full cartesian browser matrix:** A full route x width x theme x motion matrix is explicitly unnecessary if the coverage table maps risk. [VERIFIED: 120-CONTEXT.md]
- **Public lab route:** `AdminLab` stays test/support only and must not become an `AdminRouter` route. [VERIFIED: 116-LAB-CONTRACT.md]
- **Browser dependency in Hex/runtime:** Node/browser tooling must not become package content or a public product claim. [VERIFIED: 120-CONTEXT.md]
- **Axe as certification:** Playwright docs state automated accessibility testing cannot detect all WCAG violations. [CITED: https://playwright.dev/docs/accessibility-testing]
- **Regex-only DOM proof:** Rendered DOM relationships such as labels, descriptions, and IDs need a structured parser. [VERIFIED: mix.lock]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Browser viewport/media proof | Custom HTTP screenshot script or raw browser automation | Playwright, if adopted after human verification | Official Playwright supports deterministic viewport/media emulation and browser reports. [CITED: https://playwright.dev/docs/intro] [CITED: https://playwright.dev/docs/api/class-page] |
| Automated accessibility scan | Custom contrast/ARIA crawler | `@axe-core/playwright`, if adopted after human verification | Playwright's official accessibility guide uses AxeBuilder and warns automation is partial. [CITED: https://playwright.dev/docs/accessibility-testing] |
| Rendered HTML parsing | Regex selectors | LazyHTML | LazyHTML is already in the test graph and exposes CSS querying plus text/attribute APIs. [VERIFIED: mix.lock] |
| Mounted route behavior | Static source grep only | Phoenix LiveViewTest `live/3` and `render/1` | LiveViewTest renders connected route state and raises for detected errors such as duplicate IDs by default. [CITED: https://hexdocs.pm/phoenix_live_view/1.1.28/Phoenix.LiveViewTest.html] |
| Admin component proof | Public Storybook/lab route | Internal `AdminLab.StressSurface` plus rendered component tests | The lab contract says the stress surface is internal/test-only and outside public support. [VERIFIED: 116-LAB-CONTRACT.md] |
| Theming product | Public token/theming engine | Existing embedded CSS theme selector and docs boundary | Phase 120 forbids a public design-system doc or theming support surface. [VERIFIED: 120-CONTEXT.md] |

**Key insight:** Phase 120 is a proof architecture problem: the planner should combine deterministic tests for stable contracts with a small browser evidence path for what only a browser can prove, while keeping public/runtime surface unchanged. [VERIFIED: 120-CONTEXT.md]

## Common Pitfalls

### Pitfall 1: Browser Tooling Becomes Product Surface

**What goes wrong:** Package files, reports, screenshots, or docs imply Lockspire ships browser-testing or component-lab functionality. [VERIFIED: 120-CONTEXT.md]

**Why it happens:** Playwright scaffolding creates public-looking files such as `package.json`, `playwright.config.ts`, reports, and tests by default. [CITED: https://playwright.dev/docs/intro]

**How to avoid:** Name commands/artifacts as maintainer proof, keep them out of Hex package content, and guard public docs/package files in ExUnit. [VERIFIED: 120-CONTEXT.md]

**Warning signs:** `docs/supported-surface.md` mentions Playwright, axe, component lab, screenshots, or public theming. [VERIFIED: 120-CONTEXT.md]

### Pitfall 2: Route Matrix Uses Stale Screenshot Names

**What goes wrong:** Browser proof misses new or changed routes and does not catch bad links such as `/admin/logout-deliveries`. [VERIFIED: 120-CONTEXT.md]

**Why it happens:** Prior screenshot inventory is useful evidence but not canonical route truth. [VERIFIED: 120-CONTEXT.md]

**How to avoid:** Derive routes from `AdminRouter` and append only the locked query workflow `/admin/clients/:client_id/edit?workflow=logout-propagation`. [VERIFIED: 120-CONTEXT.md]

**Warning signs:** Coverage tables cite `tmp/admin-ui-polish/` filenames without a source route/JTBD mapping. [VERIFIED: 120-CONTEXT.md]

### Pitfall 3: Axe Results Are Treated as WCAG Certification

**What goes wrong:** Passing scans are presented as full WCAG compliance. [CITED: https://playwright.dev/docs/accessibility-testing]

**Why it happens:** Automated scans detect only a subset of accessibility issues. [CITED: https://playwright.dev/docs/accessibility-testing]

**How to avoid:** Scope axe scans to automatically detectable WCAG A/AA tags and keep manual keyboard, focus, copy, destructive-action, and screen-reader-risk review in the final audit. [VERIFIED: 120-CONTEXT.md]

**Warning signs:** The proof artifact says "WCAG certified" or omits manual focus/keyboard notes. [VERIFIED: 120-CONTEXT.md]

### Pitfall 4: Secret Leakage in Browser Evidence

**What goes wrong:** Screenshot/report/trace artifacts preserve plaintext secrets, token-looking values, or sensitive URLs. [VERIFIED: 116-VISUAL-UX-RUBRIC.md]

**Why it happens:** Browser reports can include DOM text, URLs, snapshots, screenshots, and traces. [CITED: https://playwright.dev/docs/intro]

**How to avoid:** Use redaction-safe demo seeds/fixtures, denylist forbidden substrings in rendered HTML, store evidence as maintainer-local unless scrubbed, and avoid committing sensitive browser artifacts. [VERIFIED: codebase]

**Warning signs:** Artifacts contain `sk_live_`, `eyJhbGci`, private-key text, real tenant hostnames, or copy-once secret values outside the creation moment. [VERIFIED: test/support/lockspire/web/admin_lab/fixtures.ex]

### Pitfall 5: Responsive Proof Checks Only CSS Source

**What goes wrong:** CSS contracts pass but real browser layout still horizontally overflows or traps focus at 320/390px. [ASSUMED]

**Why it happens:** Source checks cannot prove computed layout, viewport scroll width, or keyboard focus order. [ASSUMED]

**How to avoid:** Use Playwright or manual browser proof for `document.documentElement.scrollWidth <= window.innerWidth`, focus traversal, theme selection, and table/list breakpoint behavior. [CITED: https://playwright.dev/docs/api/class-page]

**Warning signs:** PROOF-02 artifact has no browser/manual observation for 320px or 390px. [VERIFIED: .planning/REQUIREMENTS.md]

## Code Examples

Verified patterns from official and local sources:

### Mounted Route Render With Route Drift Guard

```elixir
# Source: Phoenix.LiveViewTest docs and Phase 120 D-06
test "client detail support pivots link to supported logouts route", %{conn: conn, client: client} do
  {:ok, _view, html} = live(conn, ~p"/admin/clients/#{client.id}", on_error: :raise)

  assert html =~ ~s(href="/admin/logouts")
  refute html =~ "/admin/logout-deliveries"
end
```

### LazyHTML Accessible Reference Guard

```elixir
# Source: LazyHTML API in deps/lazy_html
def assert_describedby_targets_exist!(html) do
  doc = LazyHTML.from_document(html)
  ids = html |> LazyHTML.from_document() |> LazyHTML.query("[id]") |> attrs("id") |> MapSet.new()

  doc
  |> LazyHTML.query("[aria-describedby]")
  |> attrs("aria-describedby")
  |> Enum.flat_map(&String.split(&1))
  |> Enum.each(fn id -> assert MapSet.member?(ids, id) end)
end
```

### Playwright/Axe Supplemental Scan

```typescript
// Source: Playwright accessibility testing docs
const accessibilityScanResults = await new AxeBuilder({ page })
  .include('.lockspire-admin-shell')
  .withTags(['wcag2a', 'wcag2aa', 'wcag21a', 'wcag21aa'])
  .analyze();

expect(accessibilityScanResults.violations).toEqual([]);
```

### Browser Overflow Check

```typescript
// Source: Playwright page evaluation and viewport docs
await page.setViewportSize({ width: 320, height: 900 });
await expect
  .poll(() => page.evaluate(() => document.documentElement.scrollWidth <= window.innerWidth))
  .toBe(true);
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Screenshot inventories as primary proof | Contract-first tests plus browser evidence after guardrails | Locked for Phase 120 v1.31 | Reduces screenshot churn and catches route/docs/redaction drift before visual evidence. [VERIFIED: 120-CONTEXT.md] |
| Static route evidence from old artifacts | Source-derived matrix from `AdminRouter` plus one query workflow | Locked for Phase 120 v1.31 | Catches route/link drift such as `/admin/logout-deliveries` vs `/admin/logouts`. [VERIFIED: 120-CONTEXT.md] |
| JSDOM-like accessibility expectations | Browser-based axe scans for supplemental automation | Official axe docs note limited JSDOM support and color-contrast limitations | Browser scans are better suited for contrast/computed-style evidence. [CITED: https://github.com/dequelabs/axe-core] |
| Public/admin theming as a product surface | Embedded CSS tokens plus host-owned branding/layout boundary | Locked for v1.31 | Prevents support-surface creep into a theming engine. [VERIFIED: AGENTS.md] [VERIFIED: 120-CONTEXT.md] |
| Dense tables everywhere | Table/list alternatives and route-specific task framing | Phase 118/119 primitives | GitLab's design guidance says tables are for structured comparison, not layout, and responsive table views should prioritize important content. [CITED: https://design.gitlab.com/components/table/] |

**Deprecated/outdated:**

- Treating Phase 110 screenshot inventory as route truth is outdated for Phase 120; route proof must derive from `AdminRouter`. [VERIFIED: 120-CONTEXT.md]
- Treating operation queues as action surfaces is out of scope unless later phases add domain APIs. [VERIFIED: 120-CONTEXT.md]
- Treating automated axe scans as complete WCAG proof is invalid because official Playwright docs state automation cannot detect all WCAG violations. [CITED: https://playwright.dev/docs/accessibility-testing]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | A new helper path such as `test/support/lockspire/web/admin_proof/html_assertions.ex` is a suitable home if LazyHTML helpers outgrow existing tests. | Recommended Project Structure | Low; planner can keep helpers inline instead. |
| A2 | A small maintainer script under `scripts/maintainer/` is an acceptable optional browser proof entrypoint. | Recommended Project Structure | Medium; planner may need to choose a different location to match repo conventions. |
| A3 | Real browser overflow/focus proof is meaningfully stronger than source-only responsive checks for 320/390px. | Common Pitfalls | Medium; manual browser proof can satisfy the same risk if Playwright is not adopted. |

## Open Questions

1. **Should Phase 120 install Playwright/axe or use manual browser evidence?**
   - What we know: Node and npm are available, but no `package.json`, `node_modules`, or Playwright binary exists in the repo, and the legitimacy seam flagged latest browser packages as `SUS` due to very recent publishes. [VERIFIED: local environment] [VERIFIED: package-legitimacy seam]
   - What's unclear: Whether maintainers want to accept a Node dev-tool footprint in this repo for Phase 120. [ASSUMED]
   - Recommendation: Plan the browser lane behind `checkpoint:human-verify`; if rejected, require the same route/width/theme/motion table with manual browser notes. [VERIFIED: 120-CONTEXT.md]

2. **What exact proof artifact name should the planner choose?**
   - What we know: Context allows names such as `120-BROWSER-PROOF.md` or `120-DOCS-DX-PROOF.md`. [VERIFIED: 120-CONTEXT.md]
   - What's unclear: Whether docs proof and browser proof should be one artifact or two. [ASSUMED]
   - Recommendation: Use one `120-BROWSER-PROOF.md` artifact with sections for route matrix, commands, evidence paths, docs checks, gaps, and adversarial audit. [ASSUMED]

3. **Which seeded browser data source should be used?**
   - What we know: Existing adoption demo seeds and lab fixtures are redaction-safe proof sources. [VERIFIED: codebase]
   - What's unclear: Whether all representative route states can be reached through the current adoption smoke path without additional harness work. [ASSUMED]
   - Recommendation: Prefer existing adoption-demo seeds for real routes and internal lab fixtures for component-only stress proof. [VERIFIED: codebase]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Elixir | ExUnit/Phoenix test execution | yes | 1.19.5 with Erlang/OTP 28 | none needed. [VERIFIED: local environment] |
| Mix | Test aliases and dependency graph | yes | 1.19.5 | none needed. [VERIFIED: local environment] |
| Phoenix | Admin LiveView/router proof | yes | constraint `~> 1.8.5`; lock `1.8.7` | use lockfile-resolved version for local tests. [VERIFIED: mix.exs] [VERIFIED: mix.lock] |
| Phoenix LiveView | LiveViewTest proof | yes | constraint `~> 1.1.28`; lock `1.1.30` | cite 1.1.28 docs for phase input, but run local lockfile. [VERIFIED: mix.exs] [VERIFIED: mix.lock] |
| LazyHTML | Rendered HTML assertions | yes | 0.1.11 locked | inline minimal helpers if parser use stays small. [VERIFIED: mix.lock] |
| Node.js | Optional Playwright proof | yes | v22.14.0 | manual browser proof if Node lane rejected. [VERIFIED: local environment] |
| npm | Optional Playwright proof | yes | 11.1.0 | manual browser proof if Node lane rejected. [VERIFIED: local environment] |
| `package.json` | Optional Playwright proof | no | n/a | add only after human verification; otherwise manual proof. [VERIFIED: local environment] |
| Playwright CLI | Optional browser automation | no | n/a | manual browser evidence with same matrix. [VERIFIED: local environment] |

**Missing dependencies with no fallback:** none, because Playwright/axe are optional by locked decision D-05. [VERIFIED: 120-CONTEXT.md]

**Missing dependencies with fallback:**

- Playwright CLI, `package.json`, and `node_modules` are absent; fallback is Elixir contracts plus manual browser evidence with the same matrix and explicit gap notes. [VERIFIED: local environment] [VERIFIED: 120-CONTEXT.md]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit + Phoenix LiveViewTest + LazyHTML; optional Playwright Test + axe after human verification. [VERIFIED: mix.exs] [VERIFIED: package-legitimacy seam] |
| Config file | `mix.exs`; no Playwright config exists today. [VERIFIED: mix.exs] [VERIFIED: local environment] |
| Quick run command | `MIX_ENV=test mix test test/lockspire/web/live/admin/design_system_contract_test.exs test/lockspire/web/live/admin/design_system_component_stress_test.exs` [VERIFIED: codebase] |
| Full suite command | `MIX_ENV=test mix test.fast` [VERIFIED: mix.exs] |
| Optional browser command | Planner should add a maintainer-only command only after package checkpoint, for example `npm run admin:browser-proof`. [ASSUMED] |

### Phase Requirements -> Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| PROOF-02 | Width/theme/motion browser evidence across representative route matrix. | Browser/manual evidence plus optional Playwright | Optional command after checkpoint; manual artifact otherwise | No - Wave 0 if Playwright adopted. [VERIFIED: local environment] |
| PROOF-03 | Token/raw-color drift, overflow, focus, labels/descriptions, duplicate IDs, contrast token pairs, secret leakage, generic CTA drift. | Unit/rendered LiveView/component stress plus optional browser/axe | `MIX_ENV=test mix test test/lockspire/web/live/admin/design_system_contract_test.exs test/lockspire/web/live/admin/design_system_component_stress_test.exs` | Yes, with helper gaps. [VERIFIED: codebase] |
| PROOF-04 | Operator docs explain workflow, lab boundary, theme behavior, and verification expectations without public claims. | Docs contract + manual review | `mix docs.verify` plus targeted ExUnit public-boundary assertions | Yes for docs target; proof artifact missing. [VERIFIED: mix.exs] [VERIFIED: codebase] |

### CONTEXT Decisions -> Verification Map

| Decision | Verification Method |
|----------|---------------------|
| D-01 | Generate route matrix from `AdminRouter` and append `/admin/clients/:client_id/edit?workflow=logout-propagation`; assert no stale screenshot-derived routes. [VERIFIED: codebase] |
| D-02 | Proof artifact table maps each route to JTBD, width, theme, motion, and risk instead of full cartesian explosion. [VERIFIED: 120-CONTEXT.md] |
| D-03 | ExUnit/LiveView tests are required gate; Playwright+axe is optional maintainer proof. [VERIFIED: 120-CONTEXT.md] |
| D-04 | Public docs/package tests forbid browser tooling as runtime/public support surface. [VERIFIED: codebase] |
| D-05 | Plan has explicit fallback to manual browser evidence if package checkpoint fails. [VERIFIED: 120-CONTEXT.md] |
| D-06 | Mounted route/link test fails on `/admin/logout-deliveries` and expects `/admin/logouts`. [VERIFIED: codebase] |
| D-07 | Extend `design_system_contract_test.exs` for source/docs/CSS route guardrails. [VERIFIED: codebase] |
| D-08 | Keep component stress test and support fixtures internal/test-only. [VERIFIED: codebase] |
| D-09 | Add LazyHTML/LiveViewTest helpers for duplicate IDs, label/description targets, CTA, secrets, route redaction. [VERIFIED: mix.lock] |
| D-10 | Optional axe uses WCAG A/AA tags and final audit includes manual keyboard/focus/copy/destructive/screen-reader risks. [CITED: https://playwright.dev/docs/accessibility-testing] |
| D-11 | Screenshot inventory records paths/notes only after guardrails pass and uses denylist-safe data. [VERIFIED: 120-CONTEXT.md] |
| D-12 | Proof artifact includes route-by-route JTBD column. [VERIFIED: 120-CONTEXT.md] |
| D-13 | Contract tests continue aligning tokens/rubric/brandbook and final audit checks calm structured trust. [VERIFIED: 116-VISUAL-UX-RUBRIC.md] |
| D-14 | Final audit checklist includes each named adversarial concern. [VERIFIED: 120-CONTEXT.md] |
| D-15 | Validation table maps proof tasks to accessibility, reflow, IA, redaction, theme/motion, tooling weight, maintainability, docs truth, and DX. [VERIFIED: 120-CONTEXT.md] |
| D-16 | `docs/operator-admin.md` gets v1.31 workflow/proof-boundary section. [VERIFIED: 120-CONTEXT.md] |
| D-17 | Create maintainer-only proof artifact under Phase 120. [VERIFIED: 120-CONTEXT.md] |
| D-18 | ExUnit/docs audit forbids new public design-system doc. [VERIFIED: 120-CONTEXT.md] |
| D-19 | `docs/supported-surface.md` remains unchanged unless narrow ambiguity is documented. [VERIFIED: 120-CONTEXT.md] |
| D-20 | Docs contract preserves host/Lockspire ownership split. [VERIFIED: AGENTS.md] [VERIFIED: 120-CONTEXT.md] |

### Recommended Representative Route Matrix

| Route / Surface | Journey | Width / Theme / Motion Risk | Proof Notes |
|-----------------|---------|------------------------------|-------------|
| `/admin` or current overview route from `AdminRouter` | Orient | 1440 light and 390 system | Proves shell/nav/orient scanability. [VERIFIED: 116-ROUTE-WORKFLOW-INVENTORY.md] |
| `/admin/clients/:client_id` | Configure | 320 light and 1440 dark | Proves dense client workspace, credentials, support pivots, destructive lifecycle copy, long values. [VERIFIED: 119-CONTEXT.md] |
| `/admin/clients/:client_id/edit?workflow=logout-propagation` | Configure | 390 light reduced-motion | Proves query workflow route truth and logout-propagation edit path. [VERIFIED: 120-CONTEXT.md] |
| `/admin/policies/dcr` | Configure | 768 dark | Proves one-form DCR policy workflow without semantic changes. [VERIFIED: 119-CONTEXT.md] |
| `/admin/iats` and `/admin/iats/new` | Configure | 320 system and 390 reduced-motion | Proves copy-once/redeemable state, form help/error, and long-value safety. [VERIFIED: 119-CONTEXT.md] |
| `/admin/tokens/:id` | Support | 320 dark | Proves token detail redaction, revoke framing, and responsive support detail. [VERIFIED: 119-CONTEXT.md] |
| `/admin/consents/:id` | Support | 768 system | Proves grant/account/client detail comprehension and revoke consequence copy. [VERIFIED: 119-CONTEXT.md] |
| `/admin/device_authorizations` | Operate | 320 light | Proves read-only queue list behavior and no unsupported action controls. [VERIFIED: 119-CONTEXT.md] |
| `/admin/interactions` | Operate | 390 system | Proves operator queue messaging and dense rows. [VERIFIED: 119-CONTEXT.md] |
| `/admin/logouts` | Operate | 1440 dark and 390 reduced-motion | Proves supported logout propagation route and catches `/admin/logout-deliveries` drift. [VERIFIED: 120-CONTEXT.md] |
| `AdminLab.StressSurface` rendered internally | Internal lab boundary | Light, dark, system, reduced-motion markers | Proves component state coverage without public route. [VERIFIED: codebase] |

### Sampling Rate

- **Per task commit:** Run the quick command for changed admin tests and targeted docs/source contract tests. [VERIFIED: mix.exs]
- **Per wave merge:** Run `MIX_ENV=test mix test.fast`; run optional browser proof only after deterministic tests are green. [VERIFIED: mix.exs] [VERIFIED: 120-CONTEXT.md]
- **Phase gate:** Full suite green, proof artifact completed, docs verified, and final adversarial audit checklist signed off before `$gsd-verify-work`. [VERIFIED: 120-CONTEXT.md]

### Wave 0 Gaps

- [ ] `test/support/lockspire/web/admin_proof/html_assertions.ex` or inline equivalent - shared LazyHTML rendered-markup helpers for PROOF-03. [ASSUMED]
- [ ] Optional `package.json`, lockfile, Playwright config/spec, and maintainer command - only after human verification of `SUS` packages. [VERIFIED: package-legitimacy seam]
- [ ] `.planning/phases/120-browser-proof-docs-regression-audit/120-BROWSER-PROOF.md` - route matrix, commands, evidence paths, browser/axe/manual notes, docs proof, gaps, final adversarial audit. [VERIFIED: 120-CONTEXT.md]
- [ ] `docs/operator-admin.md` v1.31 proof-boundary section - implementation target, not research output. [VERIFIED: 120-CONTEXT.md]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V2 Authentication | no new auth behavior | Phase 120 must preserve host-owned staff auth/MFA/roles and must not add auth routes. [VERIFIED: AGENTS.md] |
| V3 Session Management | no new session behavior | Browser proof must not create session-management features or public admin auth assumptions. [VERIFIED: AGENTS.md] |
| V4 Access Control | yes | Admin routes remain host-mounted/host-guarded; component lab stays internal/test-only; operation queues remain read-only without domain APIs. [VERIFIED: AGENTS.md] [VERIFIED: 116-LAB-CONTRACT.md] |
| V5 Input Validation | yes | Rendered DOM and docs checks validate route links, form help/error references, labels/descriptions, duplicate IDs, and denied CTA/secret strings. [VERIFIED: codebase] |
| V6 Cryptography | no new crypto implementation | Preserve no `alg=none`, hashed secrets, PKCE S256, refresh rotation, and redaction; do not add crypto/protocol behavior. [VERIFIED: AGENTS.md] |
| V8 Data Protection | yes | Screenshots/reports/docs/tests must not leak plaintext secrets, tokens, private keys, auth codes, verifiers, cookies, or token-looking values. [VERIFIED: 116-VISUAL-UX-RUBRIC.md] |
| V14 Configuration | yes | Optional Node/browser tooling must stay dev/test/maintainer-only and outside Hex/runtime support surface. [VERIFIED: 120-CONTEXT.md] |

### Known Threat Patterns for Phoenix LiveView Admin Proof

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Plaintext token/secret leakage in HTML, screenshot, trace, docs, or fixture output | Information Disclosure | Denylist forbidden substrings in ExUnit/LazyHTML/browser artifacts and use redaction-safe seeded states only. [VERIFIED: codebase] |
| Public support-surface creep through docs or package files | Elevation of Privilege / Repudiation | Contract-test `docs/supported-surface.md`, package content, and public docs for lab/browser/theming claims. [VERIFIED: codebase] |
| Unsupported operation-queue actions appear in UI | Tampering | Test operate queue surfaces for read-only copy/actions unless backed by domain APIs. [VERIFIED: 120-CONTEXT.md] |
| Broken admin links route operators to unsupported paths | Denial of Service | Mounted route/link assertions derived from `AdminRouter`, especially `/admin/logouts`. [VERIFIED: codebase] |
| Inaccessible custom behavior blocks keyboard/screen-reader operation | Denial of Service | Combine LiveView/LazyHTML assertions, optional axe scans, and manual keyboard/focus audit. [CITED: https://www.w3.org/WAI/WCAG22/quickref/] [VERIFIED: 120-CONTEXT.md] |
| Browser tooling introduces supply-chain/runtime drift | Tampering | Human-verify `SUS` npm packages, keep Node deps dev-only, and avoid Hex package inclusion. [VERIFIED: package-legitimacy seam] |

## Sources

### Primary (HIGH confidence)

- `AGENTS.md` - project boundaries, stack targets, product priorities, and security defaults. [VERIFIED: codebase]
- `.planning/phases/120-browser-proof-docs-regression-audit/120-CONTEXT.md` - locked Phase 120 decisions D-01 through D-20. [VERIFIED: codebase]
- `.planning/REQUIREMENTS.md` - PROOF-02, PROOF-03, PROOF-04 acceptance requirements. [VERIFIED: codebase]
- `lib/lockspire/web/admin_router.ex`, `admin_css.ex`, `admin_components.ex`, and `admin_layout_live.ex` - canonical admin route, CSS, component, and shell integration points. [VERIFIED: codebase]
- `test/lockspire/web/live/admin/design_system_contract_test.exs`, `design_system_component_stress_test.exs`, and `test/support/lockspire/web/admin_lab/*` - existing guardrail and lab proof surfaces. [VERIFIED: codebase]
- `mix.exs` and `mix.lock` - local dependency constraints and resolved versions. [VERIFIED: codebase]

### Secondary (MEDIUM confidence)

- `https://hexdocs.pm/phoenix_live_view/1.1.28/Phoenix.LiveViewTest.html` - LiveViewTest route/render/form/component/detected-error behavior. [CITED: https://hexdocs.pm/phoenix_live_view/1.1.28/Phoenix.LiveViewTest.html]
- `https://playwright.dev/docs/intro` - Playwright install, generated files, reports, system requirements, and version commands. [CITED: https://playwright.dev/docs/intro]
- `https://playwright.dev/docs/ci` - Playwright CI dependency and browser-install pattern. [CITED: https://playwright.dev/docs/ci]
- `https://playwright.dev/docs/accessibility-testing` - official Playwright + `@axe-core/playwright` pattern and automated-a11y caveats. [CITED: https://playwright.dev/docs/accessibility-testing]
- `https://playwright.dev/docs/api/class-page` - viewport/media emulation, including color scheme and reduced motion. [CITED: https://playwright.dev/docs/api/class-page]
- `https://github.com/dequelabs/axe-core` - axe-core environment/JSDOM limitation, including color-contrast limitation. [CITED: https://github.com/dequelabs/axe-core]
- `https://www.w3.org/WAI/WCAG22/quickref/` - WCAG criteria reference for color, contrast, reflow, keyboard, focus, labels, and name/role/value. [CITED: https://www.w3.org/WAI/WCAG22/quickref/]
- `https://www.w3.org/WAI/ARIA/apg/` - WAI-ARIA Authoring Practices for accessible patterns and widgets. [CITED: https://www.w3.org/WAI/ARIA/apg/]
- `https://github.com/phoenixframework/phoenix_live_dashboard` - host-mounted Phoenix admin surface precedent. [CITED: https://github.com/phoenixframework/phoenix_live_dashboard]
- `https://oban.pro/docs/web/installation.html` - host-mounted operator UI access-control precedent. [CITED: https://oban.pro/docs/web/installation.html]
- `https://www.keycloak.org/ui-customization/themes` - cautionary theming-support precedent. [CITED: https://www.keycloak.org/ui-customization/themes]
- `https://cloudscape.design/foundation/core-principles/accessibility/Building-accessible-experiences/` - mature admin accessibility precedent. [CITED: https://cloudscape.design/foundation/core-principles/accessibility/Building-accessible-experiences/]
- `https://design.gitlab.com/components/table/` - dense table/list responsive UX precedent. [CITED: https://design.gitlab.com/components/table/]

### Tertiary (LOW confidence)

- Local placement suggestions for new helper/script paths are marked `[ASSUMED]` because the planner may choose different names while preserving decisions. [ASSUMED]

## Metadata

**Confidence breakdown:**

- Standard stack: MEDIUM - existing Elixir/Phoenix stack is verified locally, but optional browser package adoption is gated by `SUS` legitimacy results for current latest npm publishes. [VERIFIED: codebase] [VERIFIED: package-legitimacy seam]
- Architecture: HIGH - local context, routes, tests, docs, brandbook, and admin source establish clear integration points. [VERIFIED: codebase]
- Pitfalls: HIGH for local boundary/security risks and MEDIUM for browser-tooling risks because external tooling is optional and not yet installed. [VERIFIED: 120-CONTEXT.md] [VERIFIED: local environment]
- Package recommendations: MEDIUM - package names were confirmed in official docs and registry metadata was checked, but both optional npm packages require human verification due `SUS` verdicts. [CITED: https://playwright.dev/docs/intro] [CITED: https://playwright.dev/docs/accessibility-testing] [VERIFIED: npm view metadata] [VERIFIED: package-legitimacy seam]

**Research date:** 2026-06-26
**Valid until:** 2026-07-03 for browser package/tooling recommendations; 2026-07-26 for local architecture and test guidance. [ASSUMED]
