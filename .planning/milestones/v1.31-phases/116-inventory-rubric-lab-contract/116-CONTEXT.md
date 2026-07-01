# Phase 116: Inventory, Rubric & Lab Contract - Context

**Gathered:** 2026-06-25 (assumptions mode, expanded research pass)
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 116 locks the exact route, workflow, component, recurring group, visual rubric, and component-lab boundary for the v1.31 admin design-system stress test. It is a contract and inventory phase, not an implementation phase for new OAuth/OIDC behavior, storage schemas, supported admin routes, public theming, PhoenixStorybook, or production page redesign.
</domain>

<decisions>
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
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase Scope
- `.planning/ROADMAP.md` — Phase 116 goal, success criteria, and v1.31 milestone boundary.
- `.planning/REQUIREMENTS.md` — LAB-01 and LAB-03 plus future/deferred PhoenixStorybook guidance.
- `.planning/STATE.md` — Current v1.31 decisions, defaults, and release-train context.

### Prior Admin Contracts
- `.planning/phases/107-admin-journey-contract-ia-audit/107-ROUTE-JOURNEY-CONTRACT.md` — Route/workflow inventory model, journey vocabulary, JTBD fields, and logout-propagation query workflow.
- `.planning/phases/107-admin-journey-contract-ia-audit/107-CONTEXT.md` — Locked route/journey/admin IA decisions.
- `.planning/phases/108-design-system-token-component-upgrade/108-CONTEXT.md` — Phoenix function component, BEM/token, motion, component API, and proof decisions.
- `.planning/phases/109-weak-spot-page-polish/109-CONTEXT.md` — Weak-route, support/operate, redaction, destructive action, and microcopy decisions.
- `.planning/phases/110-demo-state-screenshots-docs-and-regression-proof/110-CONTEXT.md` — Demo state, screenshot, browser, redaction, and proof boundary decisions.
- `.planning/phases/110-demo-state-screenshots-docs-and-regression-proof/110-SCREENSHOTS.md` — Prior route-complete evidence matrix; evidence only, not route truth.
- `.planning/phases/110-demo-state-screenshots-docs-and-regression-proof/110-VERIFICATION.md` — Closure proof for the previous admin UI pass.

### Brand And Prompt Research
- `brandbook/README.md` — Canonical current brandbook and package boundary.
- `brandbook/tokens/tokens.json` — Machine-readable canonical `--ls-*` token truth.
- `brandbook/notes/decision-log.md` — Signal Cyan, light/dark/system, typography, and package decisions.
- `brandbook/notes/accessibility-checks.md` — Contrast, focus, non-color status, and motion checks.
- `brandbook/notes/logo-options.md` — Rejected generic mark directions and architectural identity rationale.
- `prompts/lockspire-operator-admin-ia-and-workflows.md` — Operator IA, JTBD, and calm admin workflow research; subordinate to `brandbook/` for visual tokens.
- `prompts/lockspire-operator-ux-liveview.md` — Phoenix LiveView operator UX and component guidance.
- `prompts/Oauth server jtbd and domain.md` — Domain language, nouns/events/verbs, and user jobs.
- `prompts/Embedding an OAuth-OIDC server in Phoenix the case for a new Elixir library.md` — Embedded-library rationale and theme/support burden lessons.
- `prompts/lockspire-elixir-oss-library-practices.md` — Elixir OSS library DX and packaging posture.

### Source And Tests
- `lib/lockspire/web/admin_router.ex` — Canonical admin route source.
- `lib/lockspire/web/components/admin_components.ex` — Canonical shared admin component API.
- `lib/lockspire/web/admin_css.ex` — Embedded `lockspire-admin-*` BEM/design-token CSS.
- `lib/lockspire/web/live/admin_layout_live.ex` — Admin shell, journey labels, and theme selector behavior.
- `test/lockspire/web/live/admin/design_system_contract_test.exs` — Existing route/component/design-system contract proof.
- `test/lockspire/web/live/admin/design_system_component_stress_test.exs` — Existing component stress proof pattern.
- `docs/operator-admin.md` — Operator journey, mount boundary, design system, DCR/logout vocabulary, and host-owned seam.
- `docs/supported-surface.md` — Public support truth hierarchy and maintainer-evidence boundary.
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Lockspire.Web.AdminRouter` already enumerates the supported mounted admin LiveView surface.
- `107-ROUTE-JOURNEY-CONTRACT.md` already models every admin route and the logout-propagation query workflow by journey, persona, JTBD, decision, action, empty state, risk state, follow-up, and evidence.
- `Lockspire.Web.Components.AdminComponents` already provides structural primitives for status badges, cards, page heroes, metric grids, task cards, filters, buttons, fields, error summaries, alerts, description lists, summary stats, resource lists/items, copy-once panels, long values, action groups, badge groups, confirmations, empty states, policy navigation, timestamps, and error lists.
- `Lockspire.Web.Admin.CSS` and `brandbook/tokens/` already share `--ls-*` token vocabulary, making brand drift testable without a second design system.
- `design_system_contract_test.exs` already contains useful source/static proof patterns for routes, docs, component primitives, class names, no inline layout styles, and route inventory.
- `design_system_component_stress_test.exs` already demonstrates rendering real components as ExUnit proof without mounting a public lab route.

### Established Patterns
- Admin UI remains a host-mounted, host-protected Phoenix router surface; hosts own staff authentication, authorization, MFA, tenant policy, layouts, and outer branding.
- Shared admin UI implementation stays Phoenix function-component-first with embedded namespaced CSS, not Tailwind, shadcn, React Storybook, public theming, or generated host-editable components.
- Admin journey vocabulary remains exactly Orient, Configure, Support, Operate.
- DCR onboarding and DCR policy stay connected but distinct.
- Post-logout redirect URIs and logout propagation URIs stay distinct.
- Maintainer evidence under planning or `tmp/admin-ui-polish/` is not runtime or public support truth.

### Integration Points
- Phase 116 likely adds or updates planning artifacts and deterministic tests around route/workflow inventory, component/group inventory, visual rubric, and lab contract.
- Phase 117 should consume the lab contract to build the lightweight stress surface, fixture states, and foundation hardening.
- Phase 118 should consume the component/group inventory to upgrade primitives and meta-components.
- Phase 119 should consume the route/workflow inventory and rubric to apply weak-page polish.
- Phase 120 should consume the rubric and lab/evidence contract for browser proof, docs, and regression audit.
</code_context>

<specifics>
## Specific Ideas

- Use ecosystem analogs as lessons, not product direction: Phoenix LiveDashboard validates host-mounted admin surfaces protected by host pipelines; Storybook/PhoenixStorybook validate visual review value but also show route/dependency/publication risk; Keycloak is the cautionary example for theme burden and identity-console complexity; Auth0/Okta/WorkOS/LaunchDarkly/Unleash are useful references for workflow clarity, lifecycle state, audit/change history, and visible consequences.
- The route inventory should be source-derived where possible and should not silently trust old screenshot lists.
- The lab should stress hostile but redaction-safe states: long URLs/identifiers, dense scopes, disabled/destructive actions, validation errors, empty/error states, reduced motion, light/dark/system themes, focus paths, status clusters, copy-once panels without plaintext persistence, and narrow mobile widths.
- UX microcopy should stay calm, specific, consequence-oriented, and domain-accurate. Avoid fear language and generic security-dashboard copy.
- Visual direction should feel like structured trust: architectural, restrained, precise, and operationally calm rather than neon, threat-map, shield/lock, or marketing-console imagery.
</specifics>

<deferred>
## Deferred Ideas

- PhoenixStorybook remains a future option only if the internal lab becomes too bespoke or the component API grows beyond current admin UI needs.
- Visual snapshot comparison tooling remains future work until the browser harness is stable enough to avoid noisy screenshot churn.
- Public theming, host-editable component registries, standalone admin services, hosted auth, React/JS Storybook shells, and mounted public lab routes remain out of scope.
</deferred>

---

*Phase: 116-inventory-rubric-lab-contract*
*Context gathered: 2026-06-25*
