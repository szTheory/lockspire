# Phase 125: Browser Proof, Docs & Adversarial Ratchet - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md — this log preserves the analysis.

**Date:** 2026-06-30
**Phase:** 125-browser-proof-docs-adversarial-ratchet
**Mode:** assumptions + user-requested subagent research
**Areas analyzed:** Proof Boundary, Fixture Matrix, Guardrail Shape, Evidence/Docs/Adversarial Review

## Assumptions Presented

### Proof Boundary

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Phase 125 should keep deterministic ExUnit/LiveViewTest/LazyHTML proof as the blocking path, with browser/manual evidence maintainer-only and outside runtime, Hex, CI browser gates, and public support claims. | Confident | `.planning/ROADMAP.md`, `.planning/phases/120-browser-proof-docs-regression-audit/120-BROWSER-PROOF.md`, `docs/operator-admin.md`, `docs/supported-surface.md`, `test/lockspire/web/live/admin/design_system_contract_test.exs` |

### Fixture Matrix

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Phase 125 should build the v1.32 proof fixture matrix on existing internal AdminLab/test-local stress patterns, extending only test/planning evidence as needed. | Likely | `test/support/lockspire/web/admin_lab/fixtures.ex`, `test/support/lockspire/web/admin_lab/stress_surface.ex`, `test/lockspire/web/live/admin/design_system_component_stress_test.exs`, `.planning/phases/124-configure-onboarding-propagation-pass/124-06-SUMMARY.md` |

### Guardrail Shape

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Phase 125 guardrails should extend/consolidate existing helpers and tests rather than create a parallel proof framework. | Confident | `test/support/lockspire/web/admin_proof/html_assertions.ex`, `test/support/lockspire/web/admin_proof/route_scorecards.ex`, `test/lockspire/web/live/admin/design_system_contract_test.exs` |

### Evidence, Docs, And Adversarial Review

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Phase 125 should produce a maintainer-only v1.32 proof artifact plus a bounded `docs/operator-admin.md` update, while leaving `docs/supported-surface.md` unchanged unless a concrete ambiguity is found. | Confident | `.planning/phases/120-browser-proof-docs-regression-audit/120-BROWSER-PROOF.md`, `docs/operator-admin.md`, `docs/supported-surface.md`, `.planning/phases/121-route-scorecards-judgment-contract/121-ROUTE-SCORECARDS.md`, Phase 122-124 UI specs and verification artifacts |

## User Research Request

After assumptions were presented, the user asked for deeper subagent research for each area:

- compare pros/cons/tradeoffs for each approach;
- consider idiomatic Elixir, Plug, Ecto, Phoenix, and LiveView practice;
- learn from successful comparable libraries/apps in Elixir and other ecosystems;
- emphasize great developer ergonomics, least surprise, architecture, DevOps/SRE/release quality, and UI/UX where applicable;
- consider the local `prompts/` directory and current `brandbook/`, with newer `brandbook/` taking precedence over older prompt brand guidance;
- produce one coherent recommendation bundle so the user does not need to assemble the decisions.

## Subagent Research Summary

### Proof Boundary

Compared deterministic-only, deterministic + maintainer manual browser evidence, and deterministic + first-class Playwright/axe/screenshot tooling.

**Recommendation:** deterministic blocking path plus maintainer-only manual/browser evidence. Deterministic-only under-proves actual layout/focus/theme behavior; first-class browser tooling adds Node/browser/package/CI/artifact support burden and risks public claims. The hybrid gives Phase 125 real browser review without widening Lockspire's embedded-library surface.

### Fixture Matrix

Compared internal AdminLab fixtures, route-specific test-local fixtures, adoption-demo seeded browser fixtures, public/demo fixture routes, and screenshot-only/browser-only scenarios.

**Recommendation:** hybrid internal AdminLab plus route-specific test-local fixtures. AdminLab proves shared primitives/status/theme/motion/redaction; route-specific fixtures prove Support/Operate/Configure JTBD and page hierarchy. Adoption-demo/browser evidence stays supplemental; public fixture routes and screenshot-only proof are rejected.

### Guardrail Shape

Compared one large global contract test, smaller domain-specific proof modules, helper extraction under `test/support`, browser automation guardrails, and static source-contract tests.

**Recommendation:** keep `design_system_contract_test.exs` for global route/CSS/docs/package fences; keep page-specific rendered checks in focused LiveView tests; extract reusable helpers under `test/support/lockspire/web/admin_proof` as needed. Do not create a parallel proof framework.

### Evidence, Docs, And Adversarial Review

Compared maintainer-only `.planning` proof artifact, public `docs/operator-admin.md` update, `docs/supported-surface.md` update, screenshots/checklists-only, AI/persona judge prompts, and automated visual reports.

**Recommendation:** create `125-V1.32-PROOF.md` or equivalent plus a bounded `docs/operator-admin.md` update. Leave `docs/supported-surface.md` unchanged unless implementation finds a real public ambiguity. AI/persona prompts are advisory only; screenshots/manual notes are supplemental; automated visual tooling is future/optional.

## Corrections Made

No user corrections changed the core assumptions. The user requested deeper research, and that research strengthened the assumptions into the locked decisions in `125-CONTEXT.md`.

## Auto-Resolved

Not applicable.

## External Research

External research was used because the user explicitly requested ecosystem and best-practice research. Primary/official sources checked included:

- Phoenix LiveViewTest docs: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveViewTest.html
- Phoenix.Component docs: https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html
- Phoenix testing guide: https://hexdocs.pm/phoenix/testing.html
- Phoenix.Router docs: https://hexdocs.pm/phoenix/Phoenix.Router.html
- Plug.Router docs: https://plug.hexdocs.pm/Plug.Router.html
- Ecto.Schema redaction docs: https://hexdocs.pm/ecto/Ecto.Schema.html
- LazyHTML docs: https://hexdocs.pm/lazy_html/
- Phoenix LiveDashboard PageBuilder docs: https://hexdocs.pm/phoenix_live_dashboard/Phoenix.LiveDashboard.PageBuilder.html
- Oban Web docs: https://oban.pro/web
- PhoenixStorybook docs: https://phoenix-storybook.hexdocs.pm/PhoenixStorybook.html
- Playwright screenshots docs: https://playwright.dev/docs/screenshots
- Playwright visual comparisons docs: https://playwright.dev/docs/test-snapshots
- Playwright accessibility testing docs: https://playwright.dev/docs/accessibility-testing
- Deque axe-core docs: https://www.deque.com/axe/core-documentation/
- WAI-ARIA Authoring Practices Guide: https://www.w3.org/WAI/ARIA/apg/
- WCAG 2.1 Reflow understanding: https://www.w3.org/WAI/WCAG21/Understanding/reflow.html
- GOV.UK user-needs guidance: https://www.gov.uk/service-manual/user-research/start-by-learning-user-needs
- Cloudscape status indicator docs: https://cloudscape.design/components/status-indicator/
- Cloudscape color guidance: https://cloudscape.design/foundation/visual-foundation/colors/
- GitLab Pajamas badge docs: https://design.gitlab.com/components/badge
- Shopify Polaris badge docs: https://polaris-react.shopify.com/components/feedback-indicators/badge
- Django admin docs: https://docs.djangoproject.com/en/6.0/ref/contrib/admin/
- Doorkeeper project docs: https://github.com/doorkeeper-gem/doorkeeper
- node-oidc-provider project docs: https://github.com/panva/node-oidc-provider
- OpenIddict docs: https://documentation.openiddict.com/introduction
- Keycloak theme docs: https://www.keycloak.org/ui-customization/themes

## Key Tradeoffs Locked

- Deterministic proof is faster, idiomatic, package-safe, and release-safe, but cannot prove every real browser interaction. Therefore browser/manual notes are required as supplemental evidence, not skipped.
- Browser automation is powerful but is a toolchain, artifact, flake, and support-boundary commitment. It is deferred rather than adopted by default.
- AdminLab is useful for shared primitive stress proof, but route-specific test fixtures are needed for actual operator JTBD and page hierarchy.
- Global source-contract tests are high leverage, but too much page detail in one omnibus file hurts maintainability. Page-specific proof belongs near route tests.
- Public docs should explain the operator workflow and proof boundary without turning internal evidence into a support matrix.
