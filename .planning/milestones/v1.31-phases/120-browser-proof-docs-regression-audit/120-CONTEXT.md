# Phase 120: Browser Proof, Docs & Regression Audit - Context

**Gathered:** 2026-06-26 (assumptions mode with subagent research bundle)
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 120 proves the v1.31 admin design-system pass is idempotent, accessible, responsive, and documented. It owns PROOF-02, PROOF-03, and PROOF-04: fresh browser evidence, automated regression guardrails, operator/admin docs, and final adversarial audit.

This phase verifies and documents the completed design-system/page work. It must not add OAuth/OIDC protocol behavior, storage schemas, supported admin routes, operation-queue actions, a public component lab, a public theming engine, a React/Storybook admin shell, a hosted admin service, or host-owned staff authentication/layout/branding behavior.
</domain>

<decisions>
## Implementation Decisions

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

### Claude's Discretion

Planner may choose exact artifact names, browser script shape, and proof command layout as long as D-01 through D-20 remain true. Prefer a small, explicit maintainer command over a broad CI matrix if the browser stack is unstable. Prefer source-derived route matrices, focused rendered assertions, and clear evidence tables over brittle wholesale HTML or screenshot snapshots.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase Scope

- `.planning/ROADMAP.md` - Phase 120 goal, success criteria, and implementation notes.
- `.planning/REQUIREMENTS.md` - PROOF-02, PROOF-03, PROOF-04 acceptance requirements.
- `.planning/STATE.md` - current milestone state and locked v1.31 decisions.
- `.planning/METHODOLOGY.md` - assumption-first, research-first, one-shot recommendation, and high-threshold escalation lenses.

### v1.31 Contracts And Precedent

- `.planning/phases/116-inventory-rubric-lab-contract/116-CONTEXT.md` - route/component/lab/brand boundary decisions.
- `.planning/phases/116-inventory-rubric-lab-contract/116-ROUTE-WORKFLOW-INVENTORY.md` - browser-proof route/workflow truth and surface classifications.
- `.planning/phases/116-inventory-rubric-lab-contract/116-COMPONENT-GROUP-INVENTORY.md` - component API, usage points, missing states, and direct-markup exceptions.
- `.planning/phases/116-inventory-rubric-lab-contract/116-VISUAL-UX-RUBRIC.md` - visual, accessibility, motion, status, and operator UX gates.
- `.planning/phases/116-inventory-rubric-lab-contract/116-LAB-CONTRACT.md` - internal lab boundary, fixture safety, and supported-surface limits.
- `.planning/phases/117-component-lab-fixtures-foundation-hardening/117-PATTERNS.md` - lab fixture/stress-surface patterns.
- `.planning/phases/117-component-lab-fixtures-foundation-hardening/117-01-SUMMARY.md` - Phase 117 lab fixture and stress-surface delivery summary.
- `.planning/phases/117-component-lab-fixtures-foundation-hardening/117-02-SUMMARY.md` - Phase 117 light/dark/system and motion foundation summary.
- `.planning/phases/118-primitive-meta-component-upgrade/118-CONTEXT.md` - structural primitive, status, form, and verification decisions.
- `.planning/phases/118-primitive-meta-component-upgrade/118-UI-SPEC.md` - approved UI contract for primitives and stress proof.
- `.planning/phases/119-weak-page-application-ia-copy-pass/119-CONTEXT.md` - Phase 119 page/group polish and proof deferrals.
- `.planning/phases/110-demo-state-screenshots-docs-and-regression-proof/110-CONTEXT.md` - prior browser/screenshot/docs proof precedent.
- `.planning/phases/110-demo-state-screenshots-docs-and-regression-proof/110-SCREENSHOTS.md` - prior screenshot inventory pattern; baseline evidence only.

### Source And Tests

- `lib/lockspire/web/admin_router.ex` - canonical mounted admin route surface.
- `lib/lockspire/web/live/admin_layout_live.ex` - admin shell, journey navigation, and theme selector behavior.
- `lib/lockspire/web/components/admin_components.ex` - shared Phoenix function-component design-system API.
- `lib/lockspire/web/admin_css.ex` - embedded `lockspire-admin-*` BEM/design-token CSS, responsive behavior, themes, focus, and motion.
- `lib/lockspire/web/live/admin/clients_live/show.ex` - Phase 119 client workspace and the current logout route-drift audit target.
- `lib/lockspire/web/live/admin/policies_live/dcr.html.heex` - DCR policy workflow proof target.
- `lib/lockspire/web/live/admin/iat_live/index.html.heex` and `lib/lockspire/web/live/admin/iat_live/new.html.heex` - DCR/IAT proof targets.
- `lib/lockspire/web/live/admin/tokens_live/show.ex` and `lib/lockspire/web/live/admin/consents_live/show.ex` - Support detail proof targets.
- `lib/lockspire/web/live/admin/device_authorizations_live/index.ex`, `lib/lockspire/web/live/admin/interactions_live/index.ex`, and `lib/lockspire/web/live/admin/logout_deliveries_live/index.ex` - read-only Operate queue proof targets.
- `test/lockspire/web/live/admin/design_system_contract_test.exs` - primary deterministic design-system and route/docs contract proof.
- `test/lockspire/web/live/admin/design_system_component_stress_test.exs` - rendered internal component stress proof.
- `test/support/lockspire/web/admin_lab/fixtures.ex` - redaction-safe lab fixture state matrix.
- `test/support/lockspire/web/admin_lab/stress_surface.ex` - internal component stress renderer.
- `test/lockspire/web/live/admin/*_test.exs` - focused admin LiveView route tests.
- `docs/operator-admin.md` - operator journey, mount boundary, theme behavior, and v1.31 docs target.
- `docs/supported-surface.md` - canonical public support contract and ceiling.
- `examples/adoption_demo/priv/repo/seeds.exs` - deterministic adoption-demo seed state for browser evidence.
- `scripts/demo/adoption_smoke.sh` and `scripts/demo/adoption_smoke.py` - existing black-box adoption-demo proof precedent.
- `tmp/admin-ui-polish/` - preserved admin UI evidence directory; maintainer evidence only.

### Prompt And Brand Research

- `brandbook/README.md` - current brandbook package and product mapping.
- `brandbook/tokens/tokens.json` - canonical machine-readable `--ls-*` token truth.
- `brandbook/notes/accessibility-checks.md` - contrast, focus, non-color status, and motion checks.
- `brandbook/notes/decision-log.md` - Signal Cyan, light/dark/system, typography, and package decisions.
- `prompts/lockspire-operator-admin-ia-and-workflows.md` - operator jobs, IA, tone, and SRE expectations.
- `prompts/lockspire-operator-ux-liveview.md` - Phoenix LiveView architecture, function components, URL state, forms, testing, and security guidance.
- `prompts/lockspire-auth-domain-language-field-guide.md` - provider-side vocabulary for admin copy and docs.
- `prompts/Oauth server jtbd and domain.md` - personas, JTBD, domain model, and host/library boundaries.
- `prompts/lockspire-security-posture-and-threat-model.md` - redaction, secret, admin workflow, and release-blocking security checks.
- `prompts/lockspire-elixir-oss-library-practices.md` - Elixir OSS library DX, package hygiene, docs, and public API posture.
- `prompts/lockspire-release-readiness-and-conformance.md` - docs-as-contract and release proof expectations.
- `prompts/Embedding an OAuth-OIDC server in Phoenix the case for a new Elixir library.md` - ecosystem lessons from Doorkeeper, node-oidc-provider, OpenIddict, Hydra, Keycloak, and hosted providers.

### External References From Research

- `https://playwright.dev/docs/intro` - Playwright installation, generated files, and browser/tooling footprint.
- `https://playwright.dev/docs/ci` - Playwright CI/browser dependency expectations.
- `https://playwright.dev/docs/accessibility-testing` - official Playwright + `@axe-core/playwright` accessibility pattern and automation caveats.
- `https://playwright.dev/docs/emulation` - viewport/color-scheme/reduced-motion emulation.
- `https://github.com/dequelabs/axe-core` - axe-core browser support and JSDOM color-contrast limitation.
- `https://www.deque.com/axe/core-documentation/api-documentation/` - axe performance and targeted color-contrast guidance.
- `https://www.w3.org/WAI/WCAG21/quickref/` - WCAG 2.1 reference for accessibility checks.
- `https://www.w3.org/WAI/ARIA/apg/` - WAI-ARIA Authoring Practices for focus and widget behavior.
- `https://hexdocs.pm/phoenix_live_view/1.1.28/Phoenix.LiveViewTest.html` - Phoenix LiveViewTest mounted route and DOM proof.
- `https://github.com/phoenixframework/phoenix_live_dashboard` - host-mounted Phoenix admin surface precedent.
- `https://oban.pro/docs/web/installation.html` - host-mounted operator UI/admin-auth boundary precedent.
- `https://documentation.openiddict.com/introduction` - embedded framework/support-boundary precedent.
- `https://oidc-provider.dev/getting-started/accounts/` - account seam precedent.
- `https://www.keycloak.org/ui-customization/themes` - theming-surface cautionary precedent.
- `https://cloudscape.design/foundation/core-principles/accessibility/Building-accessible-experiences/` - mature admin accessibility precedent.
- `https://design.gitlab.com/components/table/` - mature dense-table/list UX precedent.
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `AdminRouter` already exposes the supported mounted admin routes. Phase 120 should derive route proof from it.
- `116-ROUTE-WORKFLOW-INVENTORY.md` already adds the only required query workflow and classifies surfaces as `admin_supported`, `demo_only`, `test_only`, or `internal_lab`.
- `AdminComponents` already exposes structural primitives for page heroes, panes, entity headers, workflow shells, status clusters, lifecycle rows, dense resource rows, responsive tables, form fields, long values, copy-once panels, confirmation panels, and empty states.
- `Admin.CSS` already defines explicit light/dark/system theme contracts, semantic alias remapping, focus treatment, reduced-motion behavior, responsive wrapping, and namespaced BEM classes.
- `AdminLab.Fixtures` and `AdminLab.StressSurface` already give a redaction-safe internal lab for hostile component states without adding a public route.
- `design_system_contract_test.exs` already fences a large share of PROOF-03: token drift, raw color drift, theme/motion contracts, generic CTA drift, package/public boundary, route/docs alignment, status semantics, form adoption, responsive primitive CSS, redaction, and Phase 119 primitive usage.
- `design_system_component_stress_test.exs` already renders real components against hostile fixture states and checks redaction, disabled link markup, aria help/error wiring, and lab boundary behavior.

### Established Patterns

- Repo-native deterministic tests are the primary regression style; browser/screenshot evidence is maintainer proof, not product runtime truth.
- Admin UI remains Phoenix-native: thin LiveViews, context-owned domain rules, Phoenix function components with attrs/slots, and embedded `lockspire-admin-*` CSS.
- Admin routes are host-mounted and host-guarded. Lockspire does not own staff identity, MFA, roles, tenant policy, host layout, branding, or product authorization.
- Operator copy stays calm, exact, domain-accurate, consequence-oriented, and non-marketing.
- Secret and token material stays copy-once or redacted across fixtures, screenshots, logs, docs, and admin UI.
- Operation queues remain read-only unless existing domain APIs back an action.

### Integration Points

- Browser proof likely integrates through a maintainer-only script or test harness, `tmp/admin-ui-polish/` evidence, and a Phase 120 proof markdown artifact.
- Automated guardrails integrate through `design_system_contract_test.exs`, `design_system_component_stress_test.exs`, and focused admin LiveView tests.
- Docs integration is primarily `docs/operator-admin.md`; `docs/supported-surface.md` should be changed only for a concrete support-boundary ambiguity.
- Demo/browser state should use redaction-safe adoption-demo seeds or internal lab fixtures, never sensitive runtime data.
</code_context>

<specifics>
## Specific Ideas

- Recommended bundle: hybrid browser proof, layered deterministic guardrails, bounded operator docs, and route/JTBD-led adversarial review.
- The proof stack should make it easy for a maintainer to answer: which route, which journey, which persona, which viewport/theme/motion mode, which seeded state, which screenshot/evidence path, which accessibility/browser note, and which guardrail backs the claim.
- Use the mature-product lesson from Phoenix LiveDashboard and Oban Web: host-mounted admin surfaces can be first-class without owning host authentication or becoming a standalone app.
- Use the ecosystem lesson from Doorkeeper, node-oidc-provider, and OpenIddict: make seams explicit, docs practical, and extension/support boundaries boring.
- Use the cautionary lesson from Keycloak/theme-heavy systems: do not turn design-system proof into a public theming product, template language, or support burden.
- Use the UI lesson from Cloudscape/GitLab-style operator systems: dense tables/lists, statuses, empty/error states, and destructive actions are workflow communication, not decoration.
- Use the accessibility lesson from WCAG/ARIA/axe: automation is useful but partial; final proof needs keyboard/focus/manual review in addition to scans.
- Keep browser reports and screenshots redaction-safe. If traces/reports can contain DOM text or URLs, treat them as local/maintainer artifacts unless explicitly scrubbed.
</specifics>

<deferred>
## Deferred Ideas

- Full browser-proof CI as a required branch-protection gate is deferred unless the quarantined harness proves stable and low-noise.
- Visual snapshot diffing remains deferred until browser evidence is stable enough to avoid screenshot churn.
- A public design-system documentation site or public component API remains out of scope.
- PhoenixStorybook remains a future option only if the internal lab becomes too bespoke or component API growth justifies the dependency and route boundary.
- Public theming, host-editable component registries, standalone admin services, hosted auth, React/JS Storybook shells, and mounted public lab routes remain out of scope.
- New retry/discard/approval/logout worker controls for operation queues are deferred unless a later phase adds explicit domain APIs.

### Reviewed Todos (not folded)

No matching pending todos were found for Phase 120.
</deferred>

---

*Phase: 120-browser-proof-docs-regression-audit*
*Context gathered: 2026-06-26*
