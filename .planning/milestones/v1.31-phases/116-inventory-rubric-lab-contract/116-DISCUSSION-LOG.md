# Phase 116: Inventory, Rubric & Lab Contract - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md — this log preserves the analysis.

**Date:** 2026-06-25T15:07:38Z
**Phase:** 116-inventory-rubric-lab-contract
**Mode:** assumptions with expanded subagent research
**Areas analyzed:** route/workflow inventory, component inventory, visual rubric, lab boundary, Elixir/Phoenix idioms, ecosystem analogs, local prompts/brandbook synthesis

## Assumptions Presented

### Route And Workflow Inventory
| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Phase 116 inventory should derive mounted admin routes directly from `Lockspire.Web.AdminRouter` and add `/admin/clients/:client_id/edit?workflow=logout-propagation` as the only required query-driven workflow exception. | Confident | `lib/lockspire/web/admin_router.ex`; `.planning/phases/107-admin-journey-contract-ia-audit/107-ROUTE-JOURNEY-CONTRACT.md`; `test/lockspire/web/live/admin/design_system_contract_test.exs`; `docs/operator-admin.md` |

### Component Inventory Scope
| Assumption | Confidence | Evidence |
|------------|------------|----------|
| The component inventory should center on `Lockspire.Web.Components.AdminComponents`, then map production usage and exceptions from admin LiveViews/tests instead of inventing a parallel component taxonomy. | Confident | `lib/lockspire/web/components/admin_components.ex`; `.planning/phases/108-design-system-token-component-upgrade/108-CONTEXT.md`; `docs/operator-admin.md`; `test/lockspire/web/live/admin/design_system_contract_test.exs`; `test/lockspire/web/live/admin/design_system_component_stress_test.exs` |

### Visual Rubric Source
| Assumption | Confidence | Evidence |
|------------|------------|----------|
| The rubric should use `brandbook/` as the canonical brand source and translate it into admin-specific checks for architectural structure, restrained Signal Cyan, calm hierarchy, light/dark/system parity, accessibility, and no generic security tropes. | Confident | `brandbook/README.md`; `brandbook/tokens/tokens.json`; `brandbook/notes/decision-log.md`; `brandbook/notes/accessibility-checks.md`; `brandbook/notes/logo-options.md`; `lib/lockspire/web/live/admin_layout_live.ex` |

### Lab Contract Boundary
| Assumption | Confidence | Evidence |
|------------|------------|----------|
| The component lab should be maintainer/demo/test-only proof and must not create a supported admin route, public API, PhoenixStorybook dependency, host-facing theming contract, or runtime support promise. | Confident | `.planning/REQUIREMENTS.md`; `.planning/ROADMAP.md`; `.planning/phases/108-design-system-token-component-upgrade/108-CONTEXT.md`; `docs/operator-admin.md`; `docs/supported-surface.md`; `test/lockspire/web/live/admin/design_system_component_stress_test.exs` |

## Corrections Made

User requested a deeper one-shot research pass before context capture rather than correcting a specific assumption. The research refined the assumptions as follows:

### Route And Workflow Inventory
- **Original assumption:** Derive routes from `AdminRouter` and add the logout-propagation query workflow.
- **Research refinement:** Also classify each inventory row as `admin_supported`, `demo_only`, `test_only`, or `internal_lab`; preserve `/admin...` paths for operator readability but do not include host mount prefixes as route truth.
- **Reason:** Ecosystem analogs showed mountable admin/lab surfaces easily become accidental support and security claims if surface type is not explicit.

### Component Inventory Scope
- **Original assumption:** Center inventory on `AdminComponents` and production usage/exceptions.
- **Research refinement:** Make the inventory explicitly two-tiered: canonical function-component API plus production usage, page-local exceptions, CSS-only patterns, missing states, and candidate meta-components.
- **Reason:** Phoenix idioms favor function components for reusable markup, but a component-module-only inventory would miss real route/page composition and exception pressure.

### Visual Rubric Source
- **Original assumption:** Use `brandbook/` as canonical source.
- **Research refinement:** Add hard rubric floors for accessibility, keyboard/focus, responsive behavior, reduced motion, redaction, destructive confirmation, no secret evidence, and domain-accurate calm microcopy.
- **Reason:** Brand alone is insufficient; identity/admin tools often fail through inaccessible status, dark-mode regressions, excessive threat aesthetics, and leaked evidence.

### Lab Contract Boundary
- **Original assumption:** Keep lab maintainer/demo/test-only.
- **Research refinement:** State that ExUnit/source contracts are the primary Phase 116 proof shape, with browser/screenshot proof later after implementation changes.
- **Reason:** This matches existing Phoenix/LiveView test idioms and keeps Phase 116 contract-only without adding route/dependency/runtime burden.

## Pros, Cons, Tradeoffs

### Route And Workflow Inventory
- **Pros:** Source-derived inventory prevents stale route lists, matches LAB-03, preserves Phase 107 route/journey vocabulary, and stays idiomatic for a Phoenix mountable admin router.
- **Cons/tradeoffs:** Query workflows are invisible to route extraction and must be explicitly listed. Regex/source extraction is pragmatic but less semantic than compiled route introspection.
- **Footguns:** Unprotected admin/debug routes; screenshot files as route truth; lab/story URLs treated as public product URLs; query-state workflows omitted; operation actions added without domain APIs.

### Component Inventory Scope
- **Pros:** Real usage prevents a fantasy showroom, keeps shared primitives tied to operator workflows, and makes long values, redaction, disabled/destructive states, form errors, focus, and mobile pressure visible.
- **Cons/tradeoffs:** Too much componentization creates domain-specific workflow components too early; too little inventory misses page-local exceptions.
- **Footguns:** Components styled only for lab examples; hidden Storybook CSS/JS reliance; host-facing theme API by accident; snapshots containing sensitive values.

### Visual Rubric Source
- **Pros:** The newer brandbook gives machine-readable token truth, contrast-aware cyan usage, semantic dark-mode aliasing, and a distinctive architectural identity.
- **Cons/tradeoffs:** Older prompt brand material still contains useful voice/positioning, but cannot override tracked `brandbook/` token decisions. Dark-first identity must not become forced-dark operator UI.
- **Footguns:** Generic padlock/shield/security-console tropes; neon cyan everywhere; Signal Cyan used as light-mode text; status conveyed only by color; fear-based microcopy.

### Lab Contract Boundary
- **Pros:** Internal lab proof can stress ugly states aggressively without adding public API/support burden, preserving the embedded-library shape.
- **Cons/tradeoffs:** A test-only lab is less browsable than PhoenixStorybook and may need later browser evidence for visual proof.
- **Footguns:** Mounted lab routes; PhoenixStorybook dependency in Phase 116; public theme engine expectations; screenshots/logs/fixtures leaking secrets or unredacted sensitive values.

## External Research

- Phoenix routing and mounted surfaces: Phoenix supports scoped/forwarded router surfaces protected by host pipelines, supporting Lockspire's explicit host-mounted `AdminRouter` shape. Source: https://phoenix.hexdocs.pm/routing.html
- Phoenix function components: `Phoenix.Component` attrs/slots are idiomatic for reusable markup contracts. Source: https://phoenix-live-view.hexdocs.pm/Phoenix.Component.html
- Phoenix LiveComponent guidance: LiveComponents are appropriate for local state/events, not basic layout decomposition. Source: https://phoenix-live-view.hexdocs.pm/Phoenix.LiveComponent.html
- Phoenix LiveView testing: component/render contracts can be verified without mounting public routes. Source: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveViewTest.html
- Phoenix LiveDashboard: mountable admin/debug surfaces should be explicit and protected, a useful analog for `AdminRouter`. Source: https://hexdocs.pm/phoenix_live_dashboard/Phoenix.LiveDashboard.Router.html
- PhoenixStorybook: useful component-review precedent but carries sandboxing, shared CSS/JS, route, and dependency tradeoffs. Sources: https://hexdocs.pm/phoenix_storybook/sandboxing.html and https://hexdocs.pm/phoenix_storybook/components.html
- Storybook/visual testing: published story/lab surfaces aid review but can become shadow public product artifacts. Sources: https://storybook.js.org/docs/sharing/publish-storybook and https://storybook.js.org/docs/writing-tests/visual-testing
- Django admin and ActiveAdmin: fast model/admin abstractions are useful but become poor product UX when workflows are product-specific. Sources: https://docs.djangoproject.com/en/6.0/ref/contrib/admin/ and https://activeadmin.info/
- Flipper UI: mountable operational UI is a convenient pattern but must be deliberate about access and support surface. Source: https://www.flippercloud.io/docs/ui
- Keycloak: powerful theming/admin-console surface illustrates long-term theme burden and identity-console complexity. Sources: https://www.keycloak.org/ui-customization/themes and https://github.com/keycloak/keycloak/issues/33115
- Auth0, WorkOS, LaunchDarkly, Unleash: useful references for visible state, audit/change history, lifecycle consequence, and operator workflow clarity, but broader provider-centric products than Lockspire. Sources: https://auth0.com/docs/get-started/auth0-overview/dashboard, https://workos.com/docs/reference/audit-logs, https://launchdarkly.com/docs/home/releases/change-history, https://docs.getunleash.io/concepts/environments

## Final Recommendation Bundle

Phase 116 should produce one phase-local contract with four tightly connected sections:

1. Route/workflow inventory from `AdminRouter` plus the logout-propagation query workflow, with journey/JTBD/risk/empty/follow-up fields and surface classification.
2. Component/group inventory from `AdminComponents` plus production usage, missing states, direct-markup exceptions, CSS-only patterns, and candidate meta-components.
3. Visual UX rubric from `brandbook/` plus hard gates for accessibility, redaction, responsive behavior, focus, reduced motion, status semantics, destructive workflows, and calm domain microcopy.
4. Lab boundary declaring maintainer/demo/test-only proof, no mounted supported route, no public API, no PhoenixStorybook in Phase 116, no theme engine, and no evidence leaks.

No separate corrections were needed after research; all original assumptions remain valid with the refinements captured in `116-CONTEXT.md`.
