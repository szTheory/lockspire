# Phase 121: route-scorecards-judgment-contract - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md - this log preserves the analysis.

**Date:** 2026-06-28
**Phase:** 121-route-scorecards-judgment-contract
**Mode:** assumptions, research-expanded
**Areas analyzed:** Route Scorecard Truth, Judgment Rubric And Guardrails, Baseline Candidate Boundary, Support Boundary And Lab Creep

## Assumptions Presented

### Route Scorecard Truth

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Phase 121 should extend the Phase 107/116 route inventory into scorecards, with normal route truth from `lib/lockspire/web/admin_router.ex` plus only `/admin/clients/:client_id/edit?workflow=logout-propagation` as the query-workflow exception. | Confident | `.planning/ROADMAP.md`; `.planning/phases/107-admin-journey-contract-ia-audit/107-ROUTE-JOURNEY-CONTRACT.md`; `.planning/phases/116-inventory-rubric-lab-contract/116-ROUTE-WORKFLOW-INVENTORY.md`; `lib/lockspire/web/admin_router.ex` |

### Judgment Rubric And Guardrails

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| The new judgment contract should remain deterministic and repo-native: markdown/source scorecards plus source/rendered guardrails, not runtime LLM review or browser tooling requirements. | Confident | `.planning/ROADMAP.md`; `.planning/REQUIREMENTS.md`; `test/lockspire/web/live/admin/design_system_contract_test.exs`; `test/support/lockspire/web/admin_proof/html_assertions.ex`; `.planning/phases/120-browser-proof-docs-regression-audit/120-BROWSER-PROOF.md` |

### Baseline Candidate Boundary

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Current uncommitted admin coherence work should be classified as baseline candidate evidence for scorecard review, while Docker/adoption-demo/Traefik changes stay outside Phase 121 planning truth. | Confident | `.planning/ROADMAP.md`; `.planning/STATE.md`; `git status --short`; `git diff --stat`; focused admin and Docker/demo diff file lists |

### Support Boundary And Lab Creep

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Scorecards may reference internal lab/stress proof but must not create or imply a public design-system route, Storybook dependency, public theming API, host component registry, or supported browser-proof product. | Confident | `.planning/phases/116-inventory-rubric-lab-contract/116-LAB-CONTRACT.md`; `.planning/phases/116-inventory-rubric-lab-contract/116-VISUAL-UX-RUBRIC.md`; `docs/operator-admin.md`; `test/lockspire/web/live/admin/design_system_component_stress_test.exs`; `mix.exs` package boundary |

## Corrections Made

No corrections - the user requested deeper research and one coherent recommendation bundle instead of individual option selection. The researched recommendations were folded into CONTEXT.md as decisions.

## Subagent Research Summary

### Route Scorecard Truth

Compared manual markdown table, one file per route, generated data module, source-derived ExUnit fixture only, and hybrid markdown plus source-derived guard. Recommended the hybrid: one readable scorecard artifact grouped by journey, guarded by route extraction from `AdminRouter` plus the single logout-propagation query exception.

### Judgment Rubric And Guardrails

Compared markdown-only, generated/static source tests, rendered LiveView/LazyHTML checks, browser/axe/Playwright, and optional AI/persona judge prompts. Recommended a deterministic stack: scorecard markdown, source ExUnit gates, and representative rendered checks, with browser/AI deferred to maintainer-only evidence.

### Baseline Candidate Boundary

Compared ignoring dirty work, snapshotting every diff, classifying by phase scope, splitting branch/worktree, and forcing cleanup/stash first. Recommended scope-classified baseline candidate evidence: admin diffs may inform scorecards; Docker/demo/Traefik/repo-hygiene diffs are not Phase 121 truth.

### Support Boundary And Lab Creep

Compared internal lab proof, package-excluded maintainer proof, public Storybook/PhoenixStorybook route, public theming API, generated host-editable admin components, and browser automation as product support. Recommended internal maintainer proof only, with explicit scorecard support-boundary fields and deterministic denylists.

## External Research

- Phoenix LiveDashboard and Oban Web: useful analogs for host-mounted Phoenix admin surfaces protected by the host application, not public unauthenticated support surfaces.
- Phoenix LiveView docs: `Phoenix.Component` attrs/slots, LiveViewTest process-based tests, and `Phoenix.LiveView.JS` support the existing function-component and deterministic rendered-test direction.
- PhoenixStorybook and Storybook: strong component review tools, but their route/dependency/assets/publishing model is deferred because it would add product/support surface.
- GOV.UK service design: reinforces route scorecards around user needs, doing less, making complex services simple, consistency without uniformity, and inspectable evidence.
- W3C WCAG and WAI-ARIA APG: reinforce accessibility as a first-class rubric pillar while avoiding overclaiming automated accessibility proof.
- Cloudscape, GitLab Pajamas, and Shopify Polaris: mature admin design systems pair components with patterns, accessibility, content, responsive behavior, and action hierarchy.
- Doorkeeper, node-oidc-provider, OpenIddict, Ory, and Hydra: reinforce install DX and explicit host/protocol seam separation.
- Keycloak themes: cautionary precedent for public theming/template extension burden and upgrade-sensitive customization.

## Auto-Resolved

Not applicable.
