# Phase 125: Browser Proof, Docs & Adversarial Ratchet - Research

**Researched:** 2026-06-30
**Domain:** Phoenix LiveView admin proof, accessibility guardrails, redaction-safe maintainer evidence
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

The locked decisions, discretion area, and deferred ideas below are copied from `.planning/phases/125-browser-proof-docs-adversarial-ratchet/125-CONTEXT.md`. [VERIFIED: 125-CONTEXT.md]

### Locked Decisions

### Proof Boundary

- **D-01:** Keep deterministic ExUnit, Phoenix LiveViewTest, LazyHTML, source-contract, and rendered-route proof as the blocking Phase 125 path. Browser/manual evidence is supplemental maintainer proof, not release truth by itself.
- **D-02:** Do not add first-class Playwright, axe, screenshot-baseline, Node package, browser binary, CI browser gate, trace/report, public browser-proof route, or Hex package content in Phase 125. Browser automation remains future/optional and requires separate human approval plus explicit non-runtime/non-Hex documentation.
- **D-03:** Browser/manual evidence must be redaction-safe and maintainer-only. It may record route, viewport, theme, motion, focus, scroll-width/client-width, notes, and scrubbed evidence paths; it must not preserve cookies, auth codes, token-looking strings, plaintext credentials, private keys, verifier material, user/device codes, production-looking hostnames, or copy-once secrets.

### Fixture Matrix

- **D-04:** Use a hybrid fixture strategy: extend existing internal `AdminLab`/component stress fixtures for shared primitive, status, theme, motion, and redaction coverage; use route-specific test-local fixtures for Support, Operate, and Configure page/JTBD proof.
- **D-05:** Phase 125 fixture coverage must explicitly include cardinality/layout states (`empty`, one item, many items, dense/high counts, zero counts), string pressure (long names, IDs, URLs), optionality (`Not recorded`/missing optional fields), lifecycle/security states (warning, incident, disabled, expired, revoked, reuse-detected, copy-once, stale/read-only), visual/accessibility states (light, dark, system, reduced motion, focus, mobile widths), and journey coverage for Orient, Configure, Support, Operate, plus internal lab boundary.
- **D-06:** Do not create a public/demo fixture route or Storybook-style surface. Screenshot-only or browser-only fixture evidence is insufficient and must remain supplemental after deterministic guardrails pass.
- **D-07:** Adoption-demo seeded browser evidence may support manual review, but it is not the primary proof source and must not create demo support truth, plaintext evidence, or public route/package claims.

### Guardrail Shape

- **D-08:** Extend/consolidate existing proof assets instead of creating a parallel framework. Keep `test/lockspire/web/live/admin/design_system_contract_test.exs` as the global route/CSS/docs/package contract layer, keep changed-page assertions in focused LiveView tests, and keep component stress proof in `design_system_component_stress_test.exs`.
- **D-09:** Move reusable logic into `test/support/lockspire/web/admin_proof` as needed. Existing `HtmlAssertions` and `RouteScorecards` stay canonical; new helpers such as sensitive deny lists, source assertions, or browser-evidence parsing are allowed if they reduce duplicated proof logic without becoming runtime API.
- **D-10:** Blocking PROOF-02 guardrails should cover: scorecard parity from `AdminRouter` plus the logout-propagation workflow; required scorecard fields/evidence classes/support promise/follow-up routes; generic CTA drift; unsupported action drift by journey; secret/redaction drift; duplicate IDs; `aria-describedby`/`aria-labelledby`/`aria-controls`; explicit labels; link hrefs; disabled-link semantics; long-value wrapping; copy-once handling; `--ls-*` token usage; no inline styles/raw colors outside token declarations; light/dark/system theme aliases; reduced-motion contracts; and source/package fences against public lab/browser/theming creep.
- **D-11:** Responsive no-page-overflow claims must be backed by source/CSS contracts and browser/manual evidence rows that name route, viewport width, `scrollWidth`, `clientWidth`, pass/fail result, theme/motion mode, and scrubbed evidence notes for changed representative pages.

### Evidence, Docs, And Adversarial Ratchet

- **D-12:** Create a maintainer-only `.planning` proof artifact for the final v1.32 closeout, recommended as `125-V1.32-PROOF.md`. It should mirror Phase 120's route/viewport/theme/motion matrix and add final v1.32 Support, Operate, Configure, Orient, and internal-lab signoff.
- **D-13:** Update `docs/operator-admin.md` narrowly to explain the page-first improvement loop: scorecard -> page change -> deterministic guardrails -> browser/manual notes -> adversarial signoff. Keep lab, browser, screenshot, report, and AI/persona judge artifacts described as maintainer evidence only.
- **D-14:** Leave `docs/supported-surface.md` unchanged unless implementation finds a concrete ambiguity in public support wording. The public support ceiling must not gain lab, browser-proof, screenshot, public design-system, public theming, or AI judge promises.
- **D-15:** Final adversarial review must check aesthetic overfit, inaccessible custom behavior, generic admin-template drift, backend implementation leakage, host integration weight, screenshot-only quality, dark/light/system regressions, reduced-motion/focus failures, redaction failures, unsupported action creep, stale route evidence, package/runtime creep, and accidental support-surface expansion.
- **D-16:** Use current `brandbook/` as the visual and accessibility source of truth. Older `prompts/lockspire_brand_book.md` is background only where it does not conflict with current brandbook tokens, accessibility notes, and decision log.
- **D-17:** Optional AI/persona judge prompts may be documented only as advisory maintainer input with human signoff. They are not deterministic gates, release blockers, public support claims, or substitutes for source/rendered/browser/manual proof.

### the agent's Discretion

Planner may choose exact helper names, proof artifact name, command grouping, and route-test organization as long as D-01 through D-17 remain true. Prefer small, reusable test-support helpers and focused route proof over adding a second proof system or expanding an already-large omnibus test with page-specific details.

### Deferred Ideas (OUT OF SCOPE)

- First-class Playwright/axe/screenshot/visual-regression automation: future optional maintainer tooling only after separate approval, package legitimacy review, artifact-scrubbing plan, and non-runtime/non-Hex boundary docs.
- Public component lab, Storybook/PhoenixStorybook route, public design-system docs/API, public theming engine, or host component registry: out of scope for v1.32 and deferred unless a future milestone deliberately accepts that product/support burden.
- Runtime AI/persona judge gate: out of scope. Optional prompts may be advisory maintainer evidence only.
- Full route x viewport x theme x motion screenshot cartesian matrix: out of scope unless future evidence shows representative coverage misses important regressions.
- `docs/supported-surface.md` edits: deferred unless Phase 125 implementation finds a concrete public-support ambiguity.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| PROOF-01 | Redaction-safe fixtures cover empty, one, many, long names/IDs/URLs, high/zero counts, missing optionals, warning, incident, disabled, expired, revoked, reuse-detected, copy-once, stale/read-only, light/dark/system/reduced-motion/mobile states. | Use the hybrid fixture model: extend `AdminLab.Fixtures` and `AdminLab.StressSurface` for shared primitive/status/theme/motion/redaction cases, and add route-local fixtures only where Support, Operate, or Configure route proof needs page-specific JTBD states. [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: test/support/lockspire/web/admin_lab/fixtures.ex] |
| PROOF-02 | Guardrails cover scorecard drift, unsupported action drift, generic CTA drift, redaction drift, long-value handling, focus/label refs, duplicate IDs, light/dark/system token usage, and responsive no-overflow. | Extend `RouteScorecards`, `HtmlAssertions`, `design_system_contract_test.exs`, focused LiveView tests, and CSS/source contracts instead of adding browser-only gates. [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: test/support/lockspire/web/admin_proof/route_scorecards.ex] [VERIFIED: test/support/lockspire/web/admin_proof/html_assertions.ex] |
| PROOF-03 | Maintainers can review browser/manual evidence and docs for the representative v1.32 matrix without turning screenshots, browser tooling, AI judges, or lab artifacts into public surface. | Create a maintainer-only `.planning` proof artifact and a narrow `docs/operator-admin.md` update; leave `docs/supported-surface.md` unchanged unless implementation finds a concrete public-support ambiguity. [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: 125-CONTEXT.md] |
</phase_requirements>

## Summary

Phase 125 should be planned as a proof-ratchet phase, not a product-surface phase: the blocking work is deterministic ExUnit/LiveView/LazyHTML/source-contract proof plus a maintainer-only evidence artifact. [VERIFIED: 125-CONTEXT.md] The existing codebase already contains the right extension points: `HtmlAssertions`, `RouteScorecards`, `AdminLab.Fixtures`, `AdminLab.StressSurface`, `design_system_contract_test.exs`, `design_system_component_stress_test.exs`, and focused admin LiveView tests. [VERIFIED: codebase grep]

The primary implementation strategy is to consolidate reusable proof logic under `test/support/lockspire/web/admin_proof`, add only route-local fixture detail where page-specific proof requires it, and use `design_system_contract_test.exs` for global route/CSS/docs/package boundary checks. [VERIFIED: 125-CONTEXT.md] Browser/manual evidence belongs in `.planning`, modeled after Phase 120's matrix, with route, viewport, theme, motion, focus, `scrollWidth`, `clientWidth`, pass/fail, scrubbed notes, and explicit redaction boundaries. [VERIFIED: .planning/phases/120-browser-proof-docs-regression-audit/120-BROWSER-PROOF.md] [VERIFIED: 125-CONTEXT.md]

**Primary recommendation:** Use existing admin proof helpers and tests as the blocking gate, add a maintainer-only `125-V1.32-PROOF.md`, and update only `docs/operator-admin.md` unless a concrete public-support ambiguity is found. [VERIFIED: 125-CONTEXT.md]

## Project Constraints (from AGENTS.md)

- Lockspire is an embedded OAuth/OIDC authorization server library for Phoenix and Elixir; the host app keeps ownership of accounts, login UX, layouts, branding, and product-specific policy. [VERIFIED: AGENTS.md]
- Build Lockspire as a separate companion library, not a Sigra module. [VERIFIED: AGENTS.md]
- Preserve the embedded-library shape and do not turn Lockspire into a required standalone auth service. [VERIFIED: AGENTS.md]
- Keep strong internal boundaries between protocol core, storage, generators, Plug/Phoenix integration, and LiveView/admin surfaces. [VERIFIED: AGENTS.md]
- Keep the host seam explicit and narrow: account resolution, claims, login redirects, branding, and product policy belong to the host app. [VERIFIED: AGENTS.md]
- Do not broaden v1 into SAML, LDAP/AD federation, hosted auth, or a full CIAM suite. [VERIFIED: AGENTS.md]
- Preserve security defaults: PKCE S256 required by default, exact-match redirect URI validation, hashed client secrets, short-lived single-use authorization codes, refresh token rotation with family-wide revocation on reuse, no implicit flow, no `alg=none`, and strong redaction in logs and operator surfaces. [VERIFIED: AGENTS.md]
- The project guide names Phoenix `1.8.5`, Phoenix LiveView `1.1.28`, Ecto SQL `3.13.5`, PostgreSQL `14+`, Bandit `1.6.1`, Oban `2.21.x`, and OpenTelemetry `1.6.0` as the technology stack; the current lockfile resolves Phoenix `1.8.7`, Phoenix LiveView `1.1.30`, Ecto SQL `3.13.5`, PostgreSQL client `14.17`, Bandit `1.11.1`, Oban `2.21.1`, and `opentelemetry_api` `1.5.0`. [VERIFIED: AGENTS.md] [VERIFIED: mix.exs] [VERIFIED: mix.lock] [VERIFIED: environment probe]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|--------------|----------------|-----------|
| Route truth and scorecard parity | Test Support | Phoenix Router | `RouteScorecards.expected_routes/0` derives route truth from `Lockspire.Web.AdminRouter` plus the single logout-propagation workflow exception, so the planner should keep route drift proof in tests. [VERIFIED: test/support/lockspire/web/admin_proof/route_scorecards.ex] |
| Rendered accessibility and redaction proof | Test Support | LiveView render output | `HtmlAssertions` already parses rendered HTML with LazyHTML and asserts duplicate IDs, ARIA targets, explicit labels, hrefs, generic CTAs, denied controls, and denied text. [VERIFIED: test/support/lockspire/web/admin_proof/html_assertions.ex] |
| Fixture matrix and component stress | Test Support | Component layer | `AdminLab.Fixtures` and `AdminLab.StressSurface` already exercise shared primitives, status states, theme modes, motion modes, long values, copy-once panels, and redaction boundaries. [VERIFIED: test/support/lockspire/web/admin_lab/fixtures.ex] [VERIFIED: test/support/lockspire/web/admin_lab/stress_surface.ex] |
| Support/Operate/Configure page proof | Focused LiveView tests | Admin LiveViews | Focused admin tests already cover route rendering, redaction, copy-once, closed states, and unsupported action behavior for the v1.32 page families. [VERIFIED: codebase grep] |
| Responsive and theme proof | CSS/source contracts | Maintainer browser/manual notes | `admin_css.ex` contains token, theme, reduced-motion, long-value, and mobile layout rules, while Phase 125 requires representative browser/manual no-page-overflow rows for changed pages. [VERIFIED: lib/lockspire/web/admin_css.ex] [VERIFIED: 125-CONTEXT.md] |
| Maintainer evidence | `.planning` artifact | Manual browser inspection | Phase 125 requires maintainer-only evidence and forbids turning browser tooling, screenshots, reports, lab surfaces, or AI judges into public support claims. [VERIFIED: 125-CONTEXT.md] |
| Operator documentation | Project docs | Contract tests | `docs/operator-admin.md` should describe the page-first improvement loop, while `docs/supported-surface.md` stays unchanged unless a concrete support ambiguity appears. [VERIFIED: 125-CONTEXT.md] [VERIFIED: docs/operator-admin.md] [VERIFIED: docs/supported-surface.md] |

## Standard Stack

### Core

| Library / Asset | Version | Purpose | Why Standard |
|-----------------|---------|---------|--------------|
| ExUnit / Mix | Mix `1.19.5` on Elixir `1.19.5` / OTP `28` | Deterministic test execution for proof gates. | Existing project test runner and aliases are Mix/ExUnit based. [VERIFIED: environment probe] [VERIFIED: mix.exs] |
| Phoenix LiveViewTest | `phoenix_live_view` `1.1.30` locked | Render LiveViews and components without browser/runtime tooling. | Official docs describe `live/2`, `render_component/2`, `rendered_to_string/1`, and event helpers for deterministic LiveView/component tests. [VERIFIED: mix.lock] [CITED: https://phoenix-live-view.hexdocs.pm/1.1.30/Phoenix.LiveViewTest.html] |
| LazyHTML | `0.1.11` locked | Parse and query rendered HTML fragments in proof helpers. | Official docs expose `from_fragment/1`, `query/2`, `attribute/2`, and text/HTML extraction for DOM-like assertions. [VERIFIED: mix.lock] [CITED: https://hexdocs.pm/lazy_html/LazyHTML.html] |
| `Lockspire.Web.AdminProof.HtmlAssertions` | Local test support | Central HTML accessibility, href, CTA, denied-control, and redaction assertions. | Existing helper already covers the PROOF-02 assertion families most likely to be extended. [VERIFIED: test/support/lockspire/web/admin_proof/html_assertions.ex] |
| `Lockspire.Web.AdminProof.RouteScorecards` | Local test support | Parse Phase 121 scorecards and derive route truth. | Existing helper keeps route truth source-derived from AdminRouter and the single workflow exception. [VERIFIED: test/support/lockspire/web/admin_proof/route_scorecards.ex] |
| `Lockspire.Web.AdminLab.Fixtures` and `StressSurface` | Local test support | Shared fixture and component-stress proof for primitives, statuses, theme, motion, redaction, and long values. | Existing stress proof already exercises the internal lab boundary and shared UI primitives. [VERIFIED: test/support/lockspire/web/admin_lab/fixtures.ex] [VERIFIED: test/support/lockspire/web/admin_lab/stress_surface.ex] |

### Supporting

| Library / Asset | Version | Purpose | When to Use |
|-----------------|---------|---------|-------------|
| Phoenix.Component | LiveView `1.1.30` docs | Function component API, attributes, global attrs, and slots. | Use when extending component stress proof or verifying component usage contracts. [CITED: https://phoenix-live-view.hexdocs.pm/1.1.30/Phoenix.Component.html] |
| `docs/operator-admin.md` | Local docs | Operator-facing explanation of the page-first loop and proof boundary. | Update narrowly for PROOF-03. [VERIFIED: 125-CONTEXT.md] [VERIFIED: docs/operator-admin.md] |
| `docs/supported-surface.md` | Local docs | Public support ceiling. | Do not edit unless Phase 125 finds a concrete public-support ambiguity. [VERIFIED: 125-CONTEXT.md] [VERIFIED: docs/supported-surface.md] |
| `brandbook/` | Local brand source | Visual, token, accessibility, and decision-log source of truth. | Use for token/theme/accessibility claims; older prompts are background only if non-conflicting. [VERIFIED: 125-CONTEXT.md] [VERIFIED: brandbook/README.md] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| ExUnit/LiveViewTest/LazyHTML source and rendered proof | Playwright, axe, screenshot baselines, browser traces, or CI browser gates | Phase 125 explicitly defers first-class browser automation and treats manual/browser evidence as supplemental maintainer proof only. [VERIFIED: 125-CONTEXT.md] |
| Existing `AdminProof` helpers | A second proof framework | Phase 125 requires extending/consolidating existing proof assets instead of parallel proof infrastructure. [VERIFIED: 125-CONTEXT.md] |
| Maintainer-only `.planning` artifact | Public browser-proof docs, public lab route, or package/browser surface | Public support surface must not gain lab, browser-proof, screenshot, public design-system, public theming, or AI judge promises. [VERIFIED: 125-CONTEXT.md] |
| Representative evidence matrix | Full route x viewport x theme x motion screenshot matrix | Full cartesian screenshot proof is explicitly deferred unless future evidence shows representative coverage misses regressions. [VERIFIED: 125-CONTEXT.md] |

**Installation:**

```bash
# No new package installation is recommended for Phase 125.
```

**Version verification:** Existing dependency versions were verified from `mix.exs`, `mix.lock`, and environment probes; no new external packages are recommended. [VERIFIED: mix.exs] [VERIFIED: mix.lock] [VERIFIED: environment probe]

## Package Legitimacy Audit

Phase 125 should install no external packages. [VERIFIED: 125-CONTEXT.md] The Package Legitimacy Gate is therefore not applicable to new dependencies. [VERIFIED: 125-CONTEXT.md]

| Package | Registry | Age | Downloads | Source Repo | Verdict | Disposition |
|---------|----------|-----|-----------|-------------|---------|-------------|
| none | none | n/a | n/a | n/a | n/a | No package install recommended. [VERIFIED: 125-CONTEXT.md] |

**Packages removed due to [SLOP] verdict:** none. [VERIFIED: 125-CONTEXT.md]
**Packages flagged as suspicious [SUS]:** none. [VERIFIED: 125-CONTEXT.md]

## Architecture Patterns

### System Architecture Diagram

```text
Phase 121 scorecards + AdminRouter
  -> RouteScorecards parser/parity checks
  -> global route/docs/package contracts

AdminLab fixtures + route-local fixtures
  -> component stress render + focused LiveView renders
  -> HtmlAssertions and source/CSS assertions
  -> deterministic PROOF-01/PROOF-02 gate

Changed representative pages
  -> maintainer browser/manual notes
  -> 125-V1.32-PROOF.md redaction-safe evidence matrix
  -> final adversarial checklist

Operator docs
  -> narrow page-first loop explanation
  -> supported-surface ceiling remains unchanged unless ambiguity found
```

This flow keeps proof data moving from source-derived route truth and rendered HTML into deterministic tests before any browser/manual evidence is accepted as supplemental signoff. [VERIFIED: 125-CONTEXT.md] [VERIFIED: test/support/lockspire/web/admin_proof/route_scorecards.ex]

### Recommended Project Structure

```text
test/support/lockspire/web/admin_proof/
  html_assertions.ex          # existing rendered HTML assertions [VERIFIED: codebase grep]
  route_scorecards.ex         # existing source-derived route scorecard parser [VERIFIED: codebase grep]
  sensitive_values.ex         # recommended only if redaction deny lists would otherwise duplicate [VERIFIED: 125-CONTEXT.md]
  browser_evidence.ex         # recommended only if parsing 125 proof rows reduces duplication [VERIFIED: 125-CONTEXT.md]

test/support/lockspire/web/admin_lab/
  fixtures.ex                 # existing shared redaction/status/theme/motion fixture matrix [VERIFIED: codebase grep]
  stress_surface.ex           # existing internal component-stress surface [VERIFIED: codebase grep]

test/lockspire/web/live/admin/
  design_system_contract_test.exs          # global route/CSS/docs/package contract layer [VERIFIED: codebase grep]
  design_system_component_stress_test.exs  # component/lab stress contract layer [VERIFIED: codebase grep]
  **/*_test.exs                            # focused route proof for changed pages [VERIFIED: codebase grep]

.planning/phases/125-browser-proof-docs-adversarial-ratchet/
  125-V1.32-PROOF.md         # maintainer-only browser/manual/adversarial closeout artifact [VERIFIED: 125-CONTEXT.md]
```

### Pattern 1: Source-Derived Route Scorecard Proof

**What:** Treat `AdminRouter` plus the logout-propagation workflow exception as the only route truth, then validate scorecards, evidence classes, public support promises, and follow-up routes against that truth. [VERIFIED: 125-CONTEXT.md] [VERIFIED: test/support/lockspire/web/admin_proof/route_scorecards.ex]

**When to use:** Use this for route-scorecard drift, stale route evidence, unsupported public support promises, and follow-up links that leave the known admin surface. [VERIFIED: .planning/phases/121-route-scorecards-judgment-contract/121-ROUTE-SCORECARDS.md]

**Example:**

```elixir
# Source: test/support/lockspire/web/admin_proof/route_scorecards.ex
scorecards =
  ".planning/phases/121-route-scorecards-judgment-contract/121-ROUTE-SCORECARDS.md"
  |> File.read!()
  |> Lockspire.Web.AdminProof.RouteScorecards.parse!()

assert MapSet.equal?(
         MapSet.new(Map.keys(scorecards)),
         MapSet.new(Lockspire.Web.AdminProof.RouteScorecards.expected_routes())
       )
```

### Pattern 2: Rendered HTML Assertions Stay Centralized

**What:** Keep duplicate ID, ARIA target, label, href, disabled-link, generic CTA, denied-control, and denied-text assertions in `HtmlAssertions` so focused route tests can stay small. [VERIFIED: test/support/lockspire/web/admin_proof/html_assertions.ex]

**When to use:** Use this for PROOF-02 proof against rendered LiveViews, rendered components, and internal lab stress output. [VERIFIED: .planning/REQUIREMENTS.md]

**Example:**

```elixir
# Source: test/support/lockspire/web/admin_proof/html_assertions.ex
html = render(view)

HtmlAssertions.assert_no_duplicate_ids(html)
HtmlAssertions.assert_describedby_targets_exist(html)
HtmlAssertions.assert_label_targets_exist(html)
HtmlAssertions.assert_links_have_hrefs(html)
HtmlAssertions.assert_no_generic_cta_text(html)
```

### Pattern 3: Hybrid Fixture Matrix

**What:** Use `AdminLab.Fixtures` for shared primitive/status/theme/motion/redaction states and route-local fixtures for page-specific Support, Operate, and Configure proof. [VERIFIED: 125-CONTEXT.md] [VERIFIED: test/support/lockspire/web/admin_lab/fixtures.ex]

**When to use:** Use shared fixtures for reusable primitives and visual stress; use route-local fixtures when a page needs domain-specific long data, missing optional fields, copy-once behavior, stale/read-only cases, or closed/revoked lifecycle states. [VERIFIED: 125-CONTEXT.md] [VERIFIED: test/lockspire/web/live/admin/design_system_component_stress_test.exs]

**Example:**

```elixir
# Source: test/lockspire/web/live/admin/design_system_component_stress_test.exs
html =
  render_component(&Lockspire.Web.AdminLab.StressSurface.render/1,
    fixture_set: Lockspire.Web.AdminLab.Fixtures.all()
  )

HtmlAssertions.assert_no_duplicate_ids(html)
HtmlAssertions.assert_describedby_targets_exist(html)
HtmlAssertions.assert_no_generic_cta_text(html)
```

### Pattern 4: Maintainer-Only Evidence Rows

**What:** Record manual/browser evidence as scrubbed rows with route, viewport, theme, motion, focus, `scrollWidth`, `clientWidth`, result, and notes. [VERIFIED: 125-CONTEXT.md] The Phase 120 proof artifact already used maintainer-only route/viewport/theme/motion evidence and warned against committing screenshots, traces, reports, cookies, tokens, private keys, or copy-once plaintext. [VERIFIED: .planning/phases/120-browser-proof-docs-regression-audit/120-BROWSER-PROOF.md]

**When to use:** Use this after deterministic guardrails pass for representative changed pages only; do not use it as replacement release truth. [VERIFIED: 125-CONTEXT.md]

**Example row shape:**

```markdown
| Route | Journey | Viewport | Theme | Motion | Focus path | scrollWidth | clientWidth | Result | Scrubbed notes |
|-------|---------|----------|-------|--------|------------|-------------|-------------|--------|----------------|
| /admin/tokens/:id | Support | 320 | dark | reduced | revoke dialog trigger -> cancel | 320 | 320 | pass | No horizontal page overflow; no token-looking strings persisted. |
```

### Anti-Patterns to Avoid

- **Browser tooling as package/runtime surface:** Phase 125 forbids first-class Playwright, axe, screenshot baselines, browser binaries, CI browser gates, public browser-proof routes, and Hex package content. [VERIFIED: 125-CONTEXT.md]
- **Public lab or Storybook route:** Phase 125 forbids public/demo fixture routes and Storybook-style surfaces. [VERIFIED: 125-CONTEXT.md]
- **Screenshot-only quality claims:** Phase 125 requires deterministic guardrails before supplemental browser/manual notes. [VERIFIED: 125-CONTEXT.md]
- **Generic admin-template drift:** Phase 125's adversarial review must check generic CTA drift and backend implementation leakage. [VERIFIED: 125-CONTEXT.md]
- **Support-surface expansion through docs:** `docs/supported-surface.md` must not gain lab, browser-proof, screenshot, public design-system, public theming, or AI judge promises. [VERIFIED: 125-CONTEXT.md]
- **Dirty work overwrite:** The current working tree contains unrelated dirty files, so execution must inspect diffs before touching candidate files and stage only Phase 125-owned hunks. [VERIFIED: git status]

## Representative Proof Targets

| Journey / Artifact | Representative Targets | Why These Targets Matter |
|--------------------|------------------------|--------------------------|
| Orient | `/admin`, `/admin/overview` | Phase 120 and Phase 121 use these routes to prove "what needs attention" overview/orientation behavior. [VERIFIED: .planning/phases/120-browser-proof-docs-regression-audit/120-BROWSER-PROOF.md] [VERIFIED: .planning/phases/121-route-scorecards-judgment-contract/121-ROUTE-SCORECARDS.md] |
| Configure | `/admin/clients`, `/admin/clients/:client_id`, `/admin/clients/:client_id/edit`, `/admin/clients/:client_id/redirects`, `/admin/clients/:client_id/logout-uris`, `/admin/clients/:client_id/edit?workflow=logout-propagation`, `/admin/iats`, `/admin/iats/new`, `/admin/keys`, `/admin/keys/:id`, `/admin/policies`, `/admin/policies/par`, `/admin/policies/security-profile`, `/admin/policies/dpop`, `/admin/policies/dcr`, `/admin/dcr` | Phase 124 made Configure pages the final page-first pass; Phase 125 should prove those pages hold under long values, copy-once, confirmation, theme, motion, focus, and responsive stress. [VERIFIED: .planning/phases/124-configure-onboarding-propagation-pass/124-UI-SPEC.md] [VERIFIED: .planning/phases/124-configure-onboarding-propagation-pass/124-VERIFICATION.md] |
| Support | `/admin/tokens`, `/admin/tokens/:id`, `/admin/consents`, `/admin/consents/:id` | Phase 122 established Support investigation flows for token/consent review, smallest safe action, redaction, closed states, and decision summaries. [VERIFIED: .planning/phases/122-support-investigation-flow-polish/122-UI-SPEC.md] [VERIFIED: .planning/phases/122-support-investigation-flow-polish/122-VERIFICATION.md] |
| Operate | `/admin/interactions`, `/admin/device_authorizations`, `/admin/logouts` | Phase 123 established read-only operation queue review and explicitly forbids retry/discard/worker controls. [VERIFIED: .planning/phases/123-operate-queue-flow-polish/123-UI-SPEC.md] [VERIFIED: .planning/phases/123-operate-queue-flow-polish/123-OPERATE-PROOF.md] |
| Internal lab boundary | `Lockspire.Web.AdminLab.StressSurface` rendered only in tests | The internal lab proves shared primitives/status/theme/motion/redaction without becoming a public route, package surface, or support promise. [VERIFIED: test/support/lockspire/web/admin_lab/stress_surface.ex] [VERIFIED: 125-CONTEXT.md] |

## Existing Proof Assets To Extend

| Risk / Drift Class | Existing Asset | Phase 125 Extension |
|--------------------|----------------|---------------------|
| Route-scorecard drift | `RouteScorecards.expected_routes/0`, `parse!/1`, and Phase 121 scorecards | Assert parity, required fields, allowed evidence classes, public support promises, and follow-up routes remain tied to AdminRouter plus the workflow exception. [VERIFIED: test/support/lockspire/web/admin_proof/route_scorecards.ex] [VERIFIED: .planning/phases/121-route-scorecards-judgment-contract/121-ROUTE-SCORECARDS.md] |
| Unsupported action drift | `HtmlAssertions.assert_no_interactive_controls/2`, Phase 123/124 denied labels in contract tests | Keep unsupported action denial journey-aware: Operate stays read-only, Configure avoids unsafe one-word/generic mutations, Support uses smallest safe action language. [VERIFIED: test/support/lockspire/web/admin_proof/html_assertions.ex] [VERIFIED: test/lockspire/web/live/admin/design_system_contract_test.exs] |
| Generic CTA drift | `HtmlAssertions.assert_no_generic_cta_text/1`, contract-test CTA lists | Expand or centralize the denied CTA vocabulary if duplicates are found; do not bury page-specific CTA policy in many tests. [VERIFIED: test/support/lockspire/web/admin_proof/html_assertions.ex] [VERIFIED: test/lockspire/web/live/admin/design_system_contract_test.exs] |
| Redaction drift | `Fixtures.forbidden_substrings/0`, contract-test secret scans, focused route assertions | Extract a shared sensitive denylist only if it reduces duplication across fixtures, docs, browser evidence, and rendered tests. [VERIFIED: test/support/lockspire/web/admin_lab/fixtures.ex] [VERIFIED: test/lockspire/web/live/admin/design_system_contract_test.exs] |
| Focus, labels, ARIA refs, duplicate IDs | `HtmlAssertions` | Apply the existing helpers to every changed representative rendered route and stress surface. [VERIFIED: test/support/lockspire/web/admin_proof/html_assertions.ex] |
| Theme tokens and raw color drift | `design_system_contract_test.exs`, `admin_css.ex`, `brandbook/tokens` | Keep raw colors constrained to token declarations and require light/dark/system aliases and `--ls-*` token use. [VERIFIED: test/lockspire/web/live/admin/design_system_contract_test.exs] [VERIFIED: lib/lockspire/web/admin_css.ex] [VERIFIED: brandbook/README.md] |
| Reduced motion drift | `admin_css.ex`, contract tests | Preserve `prefers-reduced-motion` contracts and avoid transition patterns that ignore reduced motion. [VERIFIED: lib/lockspire/web/admin_css.ex] [VERIFIED: test/lockspire/web/live/admin/design_system_contract_test.exs] |
| Long-value handling | `long_value` component, CSS source contracts, focused tests | Prove long IDs, names, URLs, hashes, and redacted values wrap without page overflow. [VERIFIED: lib/lockspire/web/components/admin_components.ex] [VERIFIED: lib/lockspire/web/admin_css.ex] |
| Responsive no-page-overflow claims | CSS source contracts plus manual rows | Record representative `scrollWidth` and `clientWidth` rows at 320, 390, 768, 1024, and 1440 where changed pages are inspected. [VERIFIED: 125-CONTEXT.md] [VERIFIED: .planning/ROADMAP.md] |

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Browser-grade DOM parsing in tests | Regex or ad hoc string parsing for HTML structure | LazyHTML through `HtmlAssertions` | LazyHTML provides fragment parsing, CSS querying, attributes, and text APIs; `HtmlAssertions` already wraps it for local proof. [CITED: https://hexdocs.pm/lazy_html/LazyHTML.html] [VERIFIED: test/support/lockspire/web/admin_proof/html_assertions.ex] |
| LiveView route/component proof | Standalone browser runtime or synthetic screenshots as release truth | Phoenix LiveViewTest and component rendering | LiveViewTest officially supports `live/2`, component rendering, and event helper tests without requiring browser tooling. [CITED: https://phoenix-live-view.hexdocs.pm/1.1.30/Phoenix.LiveViewTest.html] |
| Route inventory | Markdown-only route lists | `RouteScorecards.expected_routes/0` from `AdminRouter` plus the workflow exception | Existing helper already derives route truth from source and catches stale scorecards. [VERIFIED: test/support/lockspire/web/admin_proof/route_scorecards.ex] |
| Accessibility/focus/label proof | Visual-only review | Rendered HTML assertions plus representative manual keyboard evidence | WCAG requires labels/instructions, focus visibility, and no two-dimensional scrolling at 320 CSS px for vertically scrolling content. [CITED: https://www.w3.org/WAI/WCAG21/Understanding/labels-or-instructions.html] [CITED: https://www.w3.org/WAI/WCAG22/Understanding/focus-visible.html] [CITED: https://www.w3.org/WAI/WCAG21/Understanding/reflow.html] |
| Redaction policy | Page-local one-off deny lists only | Shared fixture/source/evidence denylist if duplication appears | Phase 125 requires redaction-safe fixtures and browser/manual evidence across tests, docs, and `.planning` artifacts. [VERIFIED: 125-CONTEXT.md] |
| Public design-system proof | Public lab routes, public theming API, or Storybook | Test-only AdminLab stress surface | Phase 125 forbids public/demo fixture routes and public design-system/lab routes. [VERIFIED: 125-CONTEXT.md] |

**Key insight:** The hard part is not generating more screenshots; it is keeping proof source-derived, rendered, redaction-safe, route-aware, and bounded so v1.32 closes without creating a new support surface. [VERIFIED: 125-CONTEXT.md]

## Common Pitfalls

### Pitfall 1: Treating Browser Evidence As Release Truth
**What goes wrong:** A manual note or screenshot becomes the only proof of accessibility, redaction, or responsiveness. [VERIFIED: 125-CONTEXT.md]
**Why it happens:** Browser inspection feels concrete, but Phase 125 explicitly makes browser/manual evidence supplemental. [VERIFIED: 125-CONTEXT.md]
**How to avoid:** Require deterministic ExUnit/LiveViewTest/LazyHTML/source-contract guardrails before evidence rows are accepted. [VERIFIED: 125-CONTEXT.md]
**Warning signs:** Plans add browser tooling, screenshots, or CI browser gates before extending existing proof helpers. [VERIFIED: 125-CONTEXT.md]

### Pitfall 2: Expanding Public Surface Through Proof Work
**What goes wrong:** Lab routes, browser-proof docs, screenshot artifacts, public theming, or AI/persona judges become public support promises. [VERIFIED: 125-CONTEXT.md]
**Why it happens:** Internal proof artifacts can look like product features when documented without a ceiling. [VERIFIED: docs/operator-admin.md] [VERIFIED: docs/supported-surface.md]
**How to avoid:** Keep lab/browser/report/AI judge references maintainer-only and subordinate to `docs/supported-surface.md`. [VERIFIED: 125-CONTEXT.md]
**Warning signs:** Plans edit `docs/supported-surface.md` without a concrete ambiguity or add routes outside `AdminRouter`. [VERIFIED: 125-CONTEXT.md]

### Pitfall 3: Duplicating Redaction Logic
**What goes wrong:** Fixtures, rendered route tests, docs scans, and manual evidence use different sensitive-value deny lists. [VERIFIED: test/support/lockspire/web/admin_lab/fixtures.ex] [VERIFIED: test/lockspire/web/live/admin/design_system_contract_test.exs]
**Why it happens:** Prior phases added denial checks in more than one layer. [VERIFIED: test/lockspire/web/live/admin/design_system_contract_test.exs] [VERIFIED: test/support/lockspire/web/admin_lab/fixtures.ex]
**How to avoid:** Extract a `test/support/lockspire/web/admin_proof` helper only when it reduces repeated source/rendered/evidence checks. [VERIFIED: 125-CONTEXT.md]
**Warning signs:** New tests introduce independent regexes for tokens, secrets, JWT-looking strings, production hostnames, or private keys. [VERIFIED: test/lockspire/web/live/admin/design_system_contract_test.exs]

### Pitfall 4: Hiding Page-Specific Proof In The Omnibus Contract Test
**What goes wrong:** `design_system_contract_test.exs` grows with route-specific JTBD assertions that belong in focused LiveView tests. [VERIFIED: 125-CONTEXT.md]
**Why it happens:** The contract file already contains global admin UI contracts and is easy to extend. [VERIFIED: test/lockspire/web/live/admin/design_system_contract_test.exs]
**How to avoid:** Put global route/CSS/docs/package/source fences in the contract test; put changed-page behavior in focused route tests. [VERIFIED: 125-CONTEXT.md]
**Warning signs:** A page-specific Support, Operate, or Configure assertion is added to the global file when a focused route test exists. [VERIFIED: codebase grep]

### Pitfall 5: False Responsive Confidence
**What goes wrong:** Source contracts exist, but no changed representative page records `scrollWidth` and `clientWidth` evidence at small widths. [VERIFIED: 125-CONTEXT.md]
**Why it happens:** CSS guardrails prove intent, not observed browser layout. [VERIFIED: lib/lockspire/web/admin_css.ex] [VERIFIED: 125-CONTEXT.md]
**How to avoid:** Combine source/CSS contracts with manual rows at 320, 390, 768, 1024, and 1440 for changed representative pages. [VERIFIED: .planning/ROADMAP.md] [VERIFIED: 125-CONTEXT.md]
**Warning signs:** The proof artifact says "responsive" without viewport, `scrollWidth`, `clientWidth`, theme, motion, and pass/fail columns. [VERIFIED: 125-CONTEXT.md]

## Code Examples

Verified patterns from local code and official docs:

### Rendered Route Assertion Pattern

```elixir
# Source: Phoenix.LiveViewTest docs and local HtmlAssertions helper.
{:ok, view, _html} = live(conn, ~p"/admin/tokens")
html = render(view)

HtmlAssertions.assert_no_duplicate_ids(html)
HtmlAssertions.assert_describedby_targets_exist(html)
HtmlAssertions.assert_label_targets_exist(html)
HtmlAssertions.assert_links_have_hrefs(html)
HtmlAssertions.assert_no_generic_cta_text(html)
```

Phoenix LiveViewTest official docs support route rendering with `live(conn, path)` and rendered output/event helpers. [CITED: https://phoenix-live-view.hexdocs.pm/1.1.30/Phoenix.LiveViewTest.html] The local `HtmlAssertions` helper supplies the admin-specific assertions shown above. [VERIFIED: test/support/lockspire/web/admin_proof/html_assertions.ex]

### Internal Lab Stress Pattern

```elixir
# Source: design_system_component_stress_test.exs
html =
  render_component(&Lockspire.Web.AdminLab.StressSurface.render/1,
    fixture_set: Lockspire.Web.AdminLab.Fixtures.all()
  )

HtmlAssertions.assert_no_duplicate_ids(html)
HtmlAssertions.assert_describedby_targets_exist(html)
HtmlAssertions.assert_no_generic_cta_text(html)
```

The component stress test already renders the internal lab surface and applies shared proof helpers. [VERIFIED: test/lockspire/web/live/admin/design_system_component_stress_test.exs]

### Scorecard Parity Pattern

```elixir
# Source: RouteScorecards helper and Phase 121 scorecards.
expected_routes =
  Lockspire.Web.AdminProof.RouteScorecards.expected_routes()
  |> MapSet.new()

actual_routes =
  scorecards
  |> Map.keys()
  |> MapSet.new()

assert MapSet.equal?(expected_routes, actual_routes)
```

`RouteScorecards.expected_routes/0` derives expected routes from `Lockspire.Web.AdminRouter` and the single logout-propagation workflow exception. [VERIFIED: test/support/lockspire/web/admin_proof/route_scorecards.ex]

### Browser/Manual Evidence Contract Pattern

```markdown
# Source: Phase 125 context and Phase 120 proof artifact.
| Route | Viewport | Theme | Motion | Focus path | scrollWidth | clientWidth | Result | Scrubbed notes |
|-------|----------|-------|--------|------------|-------------|-------------|--------|----------------|
| /admin/clients/:client_id/edit?workflow=logout-propagation | 390 | system | reduced | next safe action -> confirmation cancel | 390 | 390 | pass | No copy-once value, cookie, token, private key, or production hostname retained. |
```

Phase 125 requires responsive no-page-overflow rows with route, viewport width, `scrollWidth`, `clientWidth`, result, theme/motion mode, and scrubbed notes. [VERIFIED: 125-CONTEXT.md]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Component-only admin polish proof | Page-first route scorecards plus rendered route proof | v1.32 Phases 121-124 | Phase 125 must prove Orient, Configure, Support, Operate, and internal lab coverage as a system, not only primitives. [VERIFIED: .planning/STATE.md] [VERIFIED: .planning/phases/121-route-scorecards-judgment-contract/121-ROUTE-SCORECARDS.md] |
| Browser/manual proof as informal notes | Maintainer-only matrix with explicit artifact scrubbing and no public support promise | Phase 120 and Phase 125 context | Browser/manual rows are supplemental evidence and must not become runtime/package/public docs surface. [VERIFIED: .planning/phases/120-browser-proof-docs-regression-audit/120-BROWSER-PROOF.md] [VERIFIED: 125-CONTEXT.md] |
| Generic route lists | Source-derived route truth from `AdminRouter` plus exactly one workflow exception | Phase 121 | Route evidence should fail when AdminRouter and scorecards drift. [VERIFIED: test/support/lockspire/web/admin_proof/route_scorecards.ex] |
| Shared proof repeated in route tests | Central `AdminProof` helpers for repeated HTML and scorecard assertions | Existing codebase before Phase 125 | Phase 125 should extract more helpers only when duplication appears. [VERIFIED: test/support/lockspire/web/admin_proof/html_assertions.ex] [VERIFIED: 125-CONTEXT.md] |

**Deprecated/outdated:**
- First-class Playwright/axe/screenshot/visual-regression automation is not a Phase 125 implementation path. [VERIFIED: 125-CONTEXT.md]
- Public component lab, public design-system docs/API, public theming engine, and host component registry are outside v1.32. [VERIFIED: 125-CONTEXT.md]
- Runtime AI/persona judging is out of scope; optional prompts may be advisory maintainer evidence only. [VERIFIED: 125-CONTEXT.md]

## Assumptions Log

No claims in this research are tagged `[ASSUMED]`; all material findings are sourced from project files, codebase inspection, environment probes, or official documentation opened during research. [VERIFIED: research process]

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| none | none | n/a | n/a |

## Open Questions

1. **Does implementation find a concrete ambiguity in `docs/supported-surface.md`?** [VERIFIED: 125-CONTEXT.md]
   - What we know: Phase 125 says to leave the file unchanged unless a concrete ambiguity appears. [VERIFIED: 125-CONTEXT.md]
   - What's unclear: The ambiguity can only be known after the docs diff is drafted. [VERIFIED: 125-CONTEXT.md]
   - Recommendation: Plan a checkpoint before touching `docs/supported-surface.md`; default to no edit. [VERIFIED: 125-CONTEXT.md]
2. **How much helper extraction is warranted?** [VERIFIED: 125-CONTEXT.md]
   - What we know: `HtmlAssertions` and `RouteScorecards` are canonical, and new helpers are allowed only when they reduce duplicated proof. [VERIFIED: 125-CONTEXT.md]
   - What's unclear: The exact duplication only appears once tests are written. [VERIFIED: codebase grep]
   - Recommendation: Start with route/contract tests, then extract sensitive-value or evidence-parsing helpers only after repeated logic appears. [VERIFIED: 125-CONTEXT.md]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Elixir | Mix/ExUnit tests | yes | `1.19.5` on OTP `28` | none needed. [VERIFIED: environment probe] |
| Mix | Test runner and aliases | yes | `1.19.5` | none needed. [VERIFIED: environment probe] |
| PostgreSQL client | Existing test setup and repo workflows | yes | `psql 14.17` | Existing test setup remains the source of truth for DB startup. [VERIFIED: environment probe] |
| Phoenix LiveViewTest | Rendered LiveView/component proof | yes | `phoenix_live_view 1.1.30` locked | none needed. [VERIFIED: mix.lock] |
| LazyHTML | Rendered HTML assertions | yes | `0.1.11` locked | none needed. [VERIFIED: mix.lock] |
| Browser automation / Node tooling | Not required for Phase 125 | not required | n/a | Manual maintainer evidence rows after deterministic proof. [VERIFIED: 125-CONTEXT.md] |

**Missing dependencies with no fallback:**
- none for the recommended Phase 125 plan. [VERIFIED: environment probe] [VERIFIED: 125-CONTEXT.md]

**Missing dependencies with fallback:**
- Browser automation tooling is intentionally not required; the fallback is maintainer-only manual/browser notes recorded as scrubbed `.planning` evidence after deterministic tests pass. [VERIFIED: 125-CONTEXT.md]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit via Mix, Phoenix.LiveViewTest, and LazyHTML-backed helpers. [VERIFIED: mix.exs] [VERIFIED: mix.lock] |
| Config file | `test/test_helper.exs` plus Mix aliases in `mix.exs`. [VERIFIED: codebase grep] [VERIFIED: mix.exs] |
| Quick run command | `MIX_ENV=test mix test test/lockspire/web/live/admin/design_system_contract_test.exs test/lockspire/web/live/admin/design_system_component_stress_test.exs --max-failures 1` [VERIFIED: codebase grep] |
| Focused route proof command | `MIX_ENV=test mix test test/lockspire/web/live/admin/tokens_live_test.exs test/lockspire/web/live/admin/consents_live_test.exs test/lockspire/web/live/admin/interactions_live_test.exs test/lockspire/web/live/admin/device_authorizations_live_test.exs test/lockspire/web/live/admin/logout_deliveries_live_test.exs test/lockspire/web/live/admin/clients_live_test.exs test/lockspire/web/live/admin/clients_live/show_test.exs test/lockspire/web/live/admin/iat_live_test.exs test/lockspire/web/live/admin/keys_live_test.exs test/lockspire/web/live/admin/policies_live/index_test.exs test/lockspire/web/live/admin/policies_live/dcr_test.exs test/lockspire/web/live/admin/policies_live/par_test.exs test/lockspire/web/live/admin/policies_live/dpop_test.exs test/lockspire/web/live/admin/policies_live/security_profile_test.exs test/lockspire/web/live/admin/design_system_contract_test.exs test/lockspire/web/live/admin/design_system_component_stress_test.exs --max-failures 1` [VERIFIED: codebase grep] |
| Full suite command | `MIX_ENV=test mix test.fast --max-failures 5`; Phase 124 verification recorded unrelated red tests in adoption-demo/repo-hygiene and stale overview copy, so planners should keep focused Phase 125 gates distinct from pre-existing suite debt. [VERIFIED: .planning/phases/124-configure-onboarding-propagation-pass/124-VERIFICATION.md] [VERIFIED: mix.exs] |

### Phase Requirements -> Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| PROOF-01 | Fixture matrix covers cardinality, long values, missing optionals, lifecycle/security, visual/accessibility, and journey states. [VERIFIED: .planning/REQUIREMENTS.md] | Unit/component/rendered | `MIX_ENV=test mix test test/lockspire/web/live/admin/design_system_component_stress_test.exs --max-failures 1` plus focused route tests for changed pages. [VERIFIED: codebase grep] | Existing stress and route test files exist; Phase 125 may add assertions. [VERIFIED: codebase grep] |
| PROOF-02 | Guardrails catch route-scorecard drift, unsupported/generic action drift, redaction drift, duplicate IDs, ARIA/label refs, link hrefs, long values, theme tokens, reduced motion, public-surface fences, and responsive no-overflow source contracts. [VERIFIED: .planning/REQUIREMENTS.md] | Unit/source/rendered contract | `MIX_ENV=test mix test test/lockspire/web/live/admin/design_system_contract_test.exs --max-failures 1` plus focused route tests. [VERIFIED: codebase grep] | Existing global contract test and helper files exist; Phase 125 should extend them. [VERIFIED: codebase grep] |
| PROOF-03 | Maintainer can review final v1.32 proof artifact and docs without new public surface. [VERIFIED: .planning/REQUIREMENTS.md] | Docs/source contract/manual artifact review | `MIX_ENV=test mix test test/lockspire/web/live/admin/design_system_contract_test.exs --max-failures 1` should include docs/package/source fences; manual artifact review remains maintainer-only. [VERIFIED: 125-CONTEXT.md] | `docs/operator-admin.md` exists; `125-V1.32-PROOF.md` needs creation. [VERIFIED: docs/operator-admin.md] [VERIFIED: 125-CONTEXT.md] |

### Sampling Rate

- **Per task commit:** Run the focused file affected plus `design_system_contract_test.exs` or `design_system_component_stress_test.exs` when global proof changes. [VERIFIED: 125-CONTEXT.md] [VERIFIED: codebase grep]
- **Per wave merge:** Run the focused route proof command above. [VERIFIED: codebase grep]
- **Phase gate:** Run the focused route proof command, verify `125-V1.32-PROOF.md` evidence rows are redaction-safe, and then run `MIX_ENV=test mix test.fast --max-failures 5` with explicit handling of known unrelated failures. [VERIFIED: 125-CONTEXT.md] [VERIFIED: .planning/phases/124-configure-onboarding-propagation-pass/124-VERIFICATION.md]

### Wave 0 Gaps

- [ ] `.planning/phases/125-browser-proof-docs-adversarial-ratchet/125-V1.32-PROOF.md` - required maintainer-only proof artifact for PROOF-03. [VERIFIED: 125-CONTEXT.md]
- [ ] Optional `test/support/lockspire/web/admin_proof/sensitive_values.ex` - add only if redaction deny lists duplicate across fixtures, source scans, rendered route tests, and proof artifact parsing. [VERIFIED: 125-CONTEXT.md]
- [ ] Optional `test/support/lockspire/web/admin_proof/browser_evidence.ex` - add only if parsing/scrubbing `125-V1.32-PROOF.md` rows reduces duplicate validation logic. [VERIFIED: 125-CONTEXT.md]
- [ ] Focused assertions in Support, Operate, Configure, and Orient route tests - add only where changed representative pages need more PROOF-01/PROOF-02 coverage. [VERIFIED: 125-CONTEXT.md] [VERIFIED: codebase grep]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V2 Authentication | no new auth behavior | Phase 125 should not add host-owned authentication seams or OAuth/OIDC protocol behavior. [VERIFIED: 125-CONTEXT.md] [VERIFIED: AGENTS.md] |
| V3 Session Management | no new session behavior | Evidence must not preserve cookies, auth codes, verifier material, user/device codes, token-looking strings, or copy-once secrets. [VERIFIED: 125-CONTEXT.md] |
| V4 Access Control | yes | Keep lab/browser proof maintainer-only; do not add public lab routes, browser-proof routes, hosted auth, public design-system routes, or package/runtime surface. [VERIFIED: 125-CONTEXT.md] |
| V5 Input Validation | yes | Validate scorecard fields, evidence rows, route paths, ARIA refs, labels, hrefs, and sensitive deny lists through test helpers. [VERIFIED: test/support/lockspire/web/admin_proof/route_scorecards.ex] [VERIFIED: test/support/lockspire/web/admin_proof/html_assertions.ex] |
| V6 Cryptography | no new crypto behavior | Do not change key, token, hash, verifier, copy-once, or secret storage behavior; proof should only verify redaction boundaries. [VERIFIED: 125-CONTEXT.md] [VERIFIED: AGENTS.md] |

### Known Threat Patterns for Phoenix LiveView Admin Proof

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Secret or token leakage in fixtures, docs, evidence, or rendered HTML | Information Disclosure | Shared redaction deny lists, `HtmlAssertions.assert_no_text/2`, source scans, and scrubbed `.planning` evidence rows. [VERIFIED: 125-CONTEXT.md] [VERIFIED: test/support/lockspire/web/admin_lab/fixtures.ex] |
| Public support-surface expansion through proof artifacts | Elevation of Privilege / Information Disclosure | Docs/package/source fences that keep lab/browser/AI evidence maintainer-only and outside Hex/runtime/public docs promises. [VERIFIED: 125-CONTEXT.md] [VERIFIED: test/lockspire/web/live/admin/design_system_contract_test.exs] |
| Unsupported mutation controls on read-only Operate pages | Tampering | Journey-aware denied control assertions and Phase 123 read-only Operate contracts. [VERIFIED: .planning/phases/123-operate-queue-flow-polish/123-UI-SPEC.md] [VERIFIED: test/support/lockspire/web/admin_proof/html_assertions.ex] |
| Stale route proof or follow-up routes outside AdminRouter | Spoofing / Tampering | Source-derived route parity from `AdminRouter` plus exactly one workflow exception. [VERIFIED: test/support/lockspire/web/admin_proof/route_scorecards.ex] |
| Accessibility regressions hidden by visual polish | Denial of Service | Rendered ARIA/label/focus/href checks plus manual keyboard focus evidence for representative pages. [VERIFIED: test/support/lockspire/web/admin_proof/html_assertions.ex] [CITED: https://www.w3.org/WAI/WCAG22/Understanding/focus-visible.html] |
| Responsive overflow at 320 CSS px | Denial of Service | CSS long-value/mobile contracts plus browser/manual `scrollWidth` and `clientWidth` rows. [VERIFIED: lib/lockspire/web/admin_css.ex] [CITED: https://www.w3.org/WAI/WCAG21/Understanding/reflow.html] |

## Docs And Evidence Boundaries

- `125-V1.32-PROOF.md` should be committed under the phase directory and should not include screenshots, traces, browser reports, cookies, token-looking strings, private keys, verifier material, user/device codes, production hostnames, or copy-once plaintext. [VERIFIED: 125-CONTEXT.md] [VERIFIED: .planning/phases/120-browser-proof-docs-regression-audit/120-BROWSER-PROOF.md]
- Evidence rows should record the route, journey, viewport, theme, motion, focus path, `scrollWidth`, `clientWidth`, result, scrubbed path/note, and related deterministic command outcome. [VERIFIED: 125-CONTEXT.md]
- `docs/operator-admin.md` should describe the scorecard -> page change -> deterministic guardrail -> browser/manual note -> adversarial signoff loop and keep lab/browser/screenshot/report/AI judge artifacts maintainer-only. [VERIFIED: 125-CONTEXT.md]
- `docs/supported-surface.md` should remain unchanged unless a concrete public-support ambiguity is discovered. [VERIFIED: 125-CONTEXT.md]

## Risks And Suggested Plan Slices

| Slice | Planning Goal | Main Files | Verification |
|-------|---------------|------------|--------------|
| 1. Inventory and shared proof helpers | Identify duplicate redaction, CTA, source, and evidence-row checks; extract only if duplication appears. [VERIFIED: 125-CONTEXT.md] | `test/support/lockspire/web/admin_proof/**`, `test/support/lockspire/web/admin_lab/fixtures.ex` [VERIFIED: codebase grep] | Helper unit coverage through existing contract/stress tests. [VERIFIED: codebase grep] |
| 2. Global PROOF-02 contracts | Extend route scorecard, docs/package/source, theme/motion/token, generic CTA, unsupported action, and responsive source contracts. [VERIFIED: 125-CONTEXT.md] | `test/lockspire/web/live/admin/design_system_contract_test.exs` [VERIFIED: codebase grep] | `MIX_ENV=test mix test test/lockspire/web/live/admin/design_system_contract_test.exs --max-failures 1` [VERIFIED: codebase grep] |
| 3. Component and fixture stress | Extend internal lab fixtures for PROOF-01 states that are shared across routes. [VERIFIED: 125-CONTEXT.md] | `test/support/lockspire/web/admin_lab/fixtures.ex`, `test/support/lockspire/web/admin_lab/stress_surface.ex`, `design_system_component_stress_test.exs` [VERIFIED: codebase grep] | `MIX_ENV=test mix test test/lockspire/web/live/admin/design_system_component_stress_test.exs --max-failures 1` [VERIFIED: codebase grep] |
| 4. Focused route proof | Add route-local page/JTBD assertions for Support, Operate, Configure, and Orient representative targets. [VERIFIED: 125-CONTEXT.md] | Focused admin LiveView tests under `test/lockspire/web/live/admin/**` [VERIFIED: codebase grep] | Focused route proof command in Validation Architecture. [VERIFIED: codebase grep] |
| 5. Maintainer evidence artifact | Create redaction-safe `125-V1.32-PROOF.md` with matrix rows, command outcomes, gaps, and adversarial signoff. [VERIFIED: 125-CONTEXT.md] | `.planning/phases/125-browser-proof-docs-adversarial-ratchet/125-V1.32-PROOF.md` [VERIFIED: 125-CONTEXT.md] | Contract/source scan plus manual review. [VERIFIED: 125-CONTEXT.md] |
| 6. Docs ratchet | Narrowly update operator docs and leave supported-surface unchanged unless ambiguity appears. [VERIFIED: 125-CONTEXT.md] | `docs/operator-admin.md`, optional `docs/supported-surface.md` only if ambiguity exists [VERIFIED: 125-CONTEXT.md] | Docs/package/source contract tests. [VERIFIED: test/lockspire/web/live/admin/design_system_contract_test.exs] |

**Highest risks:** unintentional public support expansion, duplicate sensitive-value logic, browser evidence that stores secrets, and touching unrelated dirty admin files without diff review. [VERIFIED: 125-CONTEXT.md] [VERIFIED: git status]

## Sources

### Primary (HIGH confidence)

- `.planning/phases/125-browser-proof-docs-adversarial-ratchet/125-CONTEXT.md` - locked phase decisions, scope, helper boundaries, evidence shape, docs boundaries, deferred ideas. [VERIFIED: 125-CONTEXT.md]
- `.planning/REQUIREMENTS.md` - PROOF-01, PROOF-02, and PROOF-03 behavior. [VERIFIED: .planning/REQUIREMENTS.md]
- `.planning/ROADMAP.md` - Phase 125 roadmap and responsive viewport expectations. [VERIFIED: .planning/ROADMAP.md]
- `.planning/STATE.md` - Phase history and completion status for Phases 120-124. [VERIFIED: .planning/STATE.md]
- `.planning/phases/120-browser-proof-docs-regression-audit/120-BROWSER-PROOF.md` - maintainer-only browser/manual evidence model and sensitive-evidence denylist. [VERIFIED: .planning/phases/120-browser-proof-docs-regression-audit/120-BROWSER-PROOF.md]
- `.planning/phases/121-route-scorecards-judgment-contract/121-ROUTE-SCORECARDS.md` - route scorecard matrix and route truth boundary. [VERIFIED: .planning/phases/121-route-scorecards-judgment-contract/121-ROUTE-SCORECARDS.md]
- `.planning/phases/122-support-investigation-flow-polish/122-UI-SPEC.md` and `122-VERIFICATION.md` - Support page proof and verification context. [VERIFIED: .planning/phases/122-support-investigation-flow-polish/122-UI-SPEC.md] [VERIFIED: .planning/phases/122-support-investigation-flow-polish/122-VERIFICATION.md]
- `.planning/phases/123-operate-queue-flow-polish/123-UI-SPEC.md`, `123-OPERATE-PROOF.md`, and `123-VERIFICATION.md` - Operate page proof and read-only boundaries. [VERIFIED: .planning/phases/123-operate-queue-flow-polish/123-UI-SPEC.md] [VERIFIED: .planning/phases/123-operate-queue-flow-polish/123-OPERATE-PROOF.md] [VERIFIED: .planning/phases/123-operate-queue-flow-polish/123-VERIFICATION.md]
- `.planning/phases/124-configure-onboarding-propagation-pass/124-UI-SPEC.md` and `124-VERIFICATION.md` - Configure page proof and known suite caveats. [VERIFIED: .planning/phases/124-configure-onboarding-propagation-pass/124-UI-SPEC.md] [VERIFIED: .planning/phases/124-configure-onboarding-propagation-pass/124-VERIFICATION.md]
- `test/support/lockspire/web/admin_proof/html_assertions.ex`, `route_scorecards.ex`, `test/support/lockspire/web/admin_lab/fixtures.ex`, `stress_surface.ex`, `design_system_contract_test.exs`, and `design_system_component_stress_test.exs` - existing proof helpers and patterns. [VERIFIED: codebase grep]
- `AGENTS.md` - project/product/security/stack constraints. [VERIFIED: AGENTS.md]

### Secondary (MEDIUM confidence)

- `https://phoenix-live-view.hexdocs.pm/1.1.30/Phoenix.LiveViewTest.html` - LiveView and component test helpers. [CITED: https://phoenix-live-view.hexdocs.pm/1.1.30/Phoenix.LiveViewTest.html]
- `https://phoenix-live-view.hexdocs.pm/1.1.30/Phoenix.Component.html` - function component attrs, global attrs, and slots. [CITED: https://phoenix-live-view.hexdocs.pm/1.1.30/Phoenix.Component.html]
- `https://hexdocs.pm/lazy_html/LazyHTML.html` - LazyHTML fragment parsing and selector/attribute APIs. [CITED: https://hexdocs.pm/lazy_html/LazyHTML.html]
- `https://www.w3.org/WAI/WCAG21/Understanding/reflow.html` - 320 CSS px reflow/no two-dimensional scrolling guidance. [CITED: https://www.w3.org/WAI/WCAG21/Understanding/reflow.html]
- `https://www.w3.org/WAI/WCAG22/Understanding/focus-visible.html` - focus visible intent. [CITED: https://www.w3.org/WAI/WCAG22/Understanding/focus-visible.html]
- `https://www.w3.org/WAI/WCAG21/Understanding/labels-or-instructions.html` - labels/instructions control guidance. [CITED: https://www.w3.org/WAI/WCAG21/Understanding/labels-or-instructions.html]

### Tertiary (LOW confidence)

- none used for recommendations. [VERIFIED: research process]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - existing project dependencies and helper modules were verified from `mix.exs`, `mix.lock`, environment probes, and source files; no new package is recommended. [VERIFIED: mix.exs] [VERIFIED: mix.lock] [VERIFIED: environment probe] [VERIFIED: codebase grep]
- Architecture: HIGH - phase constraints and existing helper/test boundaries are explicit in CONTEXT and source. [VERIFIED: 125-CONTEXT.md] [VERIFIED: codebase grep]
- Pitfalls: HIGH - pitfalls are direct consequences of locked Phase 125 decisions, prior Phase 120 proof boundaries, and existing contract-test structure. [VERIFIED: 125-CONTEXT.md] [VERIFIED: .planning/phases/120-browser-proof-docs-regression-audit/120-BROWSER-PROOF.md] [VERIFIED: test/lockspire/web/live/admin/design_system_contract_test.exs]

**Research date:** 2026-06-30
**Valid until:** 2026-07-30 for local proof architecture; re-check HexDocs if LiveView, LazyHTML, or WCAG references are upgraded before planning. [VERIFIED: research process]
