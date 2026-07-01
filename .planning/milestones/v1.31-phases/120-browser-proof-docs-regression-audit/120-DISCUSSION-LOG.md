# Phase 120: Browser Proof, Docs & Regression Audit - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in `120-CONTEXT.md` — this log preserves the analysis.

**Date:** 2026-06-26  
**Phase:** 120-browser-proof-docs-regression-audit  
**Mode:** assumptions with expanded subagent research bundle  
**Areas analyzed:** Browser proof matrix, proof tooling boundary, automated guardrails, accessibility, operator docs, support boundary, maintainer DX, operator JTBD, visual rubric, final adversarial review

## Assumptions Presented

### Browser Evidence Matrix

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Phase 120 proof should use `Lockspire.Web.AdminRouter` plus `/admin/clients/:client_id/edit?workflow=logout-propagation` as route truth, then cover every journey and all Phase 119-touched weak surfaces. | Likely | `.planning/ROADMAP.md`, `.planning/phases/116-inventory-rubric-lab-contract/116-ROUTE-WORKFLOW-INVENTORY.md`, `lib/lockspire/web/admin_router.ex`, `.planning/phases/119-weak-page-application-ia-copy-pass/119-CONTEXT.md` |

### Proof Tooling Boundary

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Browser/axe evidence should remain maintainer proof and not become a packaged runtime dependency, public route, or public support claim; fallback to Elixir contracts plus manual browser evidence is acceptable if Playwright/axe is too heavy. | Likely | `.planning/ROADMAP.md`, `mix.exs`, `test/lockspire/web/live/admin/design_system_contract_test.exs`, `.planning/phases/116-inventory-rubric-lab-contract/116-LAB-CONTRACT.md` |

### Automated Guardrails

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| PROOF-03 should extend deterministic design-system contracts and rendered component stress tests, with browser evidence supplementing them for actual viewport/theme behavior. | Confident | `test/lockspire/web/live/admin/design_system_contract_test.exs`, `test/lockspire/web/live/admin/design_system_component_stress_test.exs`, `test/support/lockspire/web/admin_lab/fixtures.ex`, `test/support/lockspire/web/admin_lab/stress_surface.ex`, `lib/lockspire/web/admin_css.ex` |

### Docs And Final Review Boundary

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Docs should update `docs/operator-admin.md` with v1.31 workflow/boundary guidance while keeping `docs/supported-surface.md` as the public support ceiling. | Confident | `docs/operator-admin.md`, `docs/supported-surface.md`, `.planning/phases/116-inventory-rubric-lab-contract/116-LAB-CONTRACT.md`, `.planning/phases/119-weak-page-application-ia-copy-pass/119-CONTEXT.md` |

## Expanded Research Requested

The user asked to discuss and consider all assumptions using subagents, with pros/cons/tradeoffs, Elixir/Phoenix/LiveView idioms, ecosystem lessons, developer ergonomics, UI/UX/JTBD lenses, accessibility, design-system consistency, and a cohesive one-shot recommendation.

Four subagents researched distinct tracks:

1. Browser proof matrix and tooling choice.
2. Automated guardrails, accessibility, and regression audit coverage.
3. Operator docs, support-boundary truth, and maintainer/developer DX.
4. Operator UI/JTBD/design-system/persona review and final adversarial audit lenses.

## Subagent Findings Applied

### Browser Proof Matrix And Tooling

| Approach | Pros | Cons | Decision |
|----------|------|------|----------|
| Full Playwright + axe automated harness | Strongest real-browser viewport/theme/reduced-motion/accessibility proof. | Adds Node/browser stack, CI weight, artifact redaction risk, and public-support implication risk. | Do not make it the sole/default blocking truth. |
| Elixir contracts plus manual browser evidence | Deterministic, repo-native, no new dependency or package weight. | Weaker computed-style, overflow, focus, and accessibility evidence. | Keep as fallback, not preferred if browser proof is feasible. |
| Hybrid quarantined browser proof plus ExUnit gates | Fresh browser evidence while keeping support/runtime boundaries narrow; matches existing repo-native contract style. | Maintains two proof layers and still needs a clear maintainer command. | **Selected.** |

### Guardrails And Accessibility

| Approach | Pros | Cons | Decision |
|----------|------|------|----------|
| Static/source contracts | Fast and strong for token/raw-color/copy/package/support drift. | Cannot prove mounted DOM, focus, computed contrast, or overflow. | Keep as always-on baseline. |
| Rendered component contracts | Exercises real components and redaction-safe hostile fixtures. | Lab can become synthetic if not cross-checked with production routes. | Keep and extend for component-level invariants. |
| Focused LiveView route render tests | Covers real route markup and LiveViewTest duplicate-ID behavior. | Requires route fixtures and still lacks browser layout engine. | Use for representative Phase 119/120 pages. |
| Browser + axe checks | Real computed-style, viewport, focus, and automated accessibility evidence. | Adds toolchain and cannot certify full WCAG alone. | Use as quarantined Phase 120 proof lane. |
| Screenshot inventories | Useful human evidence and Phase 110 precedent. | Weak assertion mechanism and can go stale. | Evidence only after guardrails pass. |
| Manual adversarial review | Catches judgment-heavy UX/security/support creep. | Requires discipline and explicit lenses. | Final release-blocking review. |

### Docs, Support Boundary, And DX

| Approach | Pros | Cons | Decision |
|----------|------|------|----------|
| Update only `docs/operator-admin.md` | Satisfies public operator guidance without broad support churn. | Weak maintainer evidence alone. | Do it, paired with phase proof artifact. |
| Add maintainer-only Phase 120 proof artifact | Best home for matrix, commands, gaps, screenshot paths, and audit notes. | Not public docs by itself. | Do it as companion evidence. |
| Update `docs/supported-surface.md` | Canonical place for support exclusions. | Easy to create negative-claim sprawl. | Only if concrete ambiguity is found. |
| Create new public design-system doc | Could explain primitives deeply. | Implies public component/theming/lab support. | Do not do this in Phase 120. |

### Operator JTBD And Final Review

| Approach | Pros | Cons | Decision |
|----------|------|------|----------|
| Route-by-route JTBD checklist | Best spine for persona, decision, and safe action. | Can become paperwork if not backed by evidence. | Use as final review spine. |
| Visual rubric checklist | Applies brandbook, hierarchy, density, and microcopy. | Subjective if isolated. | Pair with route JTBD and browser evidence. |
| Browser screenshot matrix | Proves real rendering. | Matrix can explode and screenshots can overfit aesthetics. | Curate representative matrix, not full cartesian bloat. |
| Component lab review | Strong for primitive/state stress. | Can drift from real route pressure. | Keep internal and cross-check with production pages. |
| Adversarial source review | Catches hidden bad links, claims, actions, and leaks. | Manual. | Use as final gate. |

## Final Recommendation Bundle

Phase 120 should implement a layered closeout:

1. **Hybrid proof:** ExUnit/LiveView contracts are blocking; Playwright/axe, if added, is quarantined maintainer proof.
2. **Explicit matrix:** Route truth from `AdminRouter` plus logout-propagation query workflow; coverage table spans widths, themes, reduced motion, journeys, and Phase 119 weak surfaces without requiring an impractical full cartesian matrix.
3. **Layered guardrails:** Source contracts, rendered component lab, focused LiveView route tests, browser/axe checks, screenshot evidence, and final manual adversarial review each own a specific risk class.
4. **Bounded docs:** `docs/operator-admin.md` gets short v1.31 workflow/proof guidance; Phase 120 gets maintainer-only proof artifacts; no new public design-system doc.
5. **JTBD-led audit:** Final review is organized around operator jobs and design pillars, not around screenshots alone.

## Corrections Made

The initial assumptions were not rejected. The user requested deeper research across all assumptions and asked for one cohesive recommendation set, so the final context upgrades the original assumptions into locked decisions based on the subagent research bundle.

## External Research

- Playwright installation and CI docs: browser tooling adds package/config/browser installation and CI dependency management.
- Playwright accessibility docs: `@axe-core/playwright` is the documented approach for automated accessibility scans and supports tags/configuration.
- axe-core docs: color-contrast and computed-style checks need browser-like environments; JSDOM has limitations.
- WCAG/WAI-ARIA references: automated scans are partial; keyboard/focus/manual review remains required.
- Phoenix LiveViewTest docs and prompt research: mounted LiveView tests and user-visible behavior assertions are idiomatic; function components remain preferred for reusable markup.
- Phoenix LiveDashboard and Oban Web precedents: host-mounted admin tools can be first-class without owning host auth.
- Doorkeeper, OpenIddict, and node-oidc-provider precedents: practical docs and explicit host/account seams reduce support burden.
- Keycloak theming precedent: public theming surfaces can become long-term support burden and drift from host/product UX.

## Methodology Lenses Applied

- **Assumption-first recommendation mode:** produced a recommendation bundle instead of escalating medium-value implementation choices.
- **Research-first decisive defaults:** used source, planning, prompts, brandbook, subagents, and official docs before locking decisions.
- **High-threshold escalation:** no user decision remains required because no recommendation changes public API, protocol behavior, runtime support claims, or security posture beyond the fixed Phase 120 scope.
- **One-shot recommendation bundles:** browser proof, guardrails, docs, and final review are aligned as one proof architecture.
- **Least-surprise host seam:** all recommendations preserve host-owned auth/layout/branding/product policy and keep Lockspire-owned proof inside repo-maintainer boundaries.
