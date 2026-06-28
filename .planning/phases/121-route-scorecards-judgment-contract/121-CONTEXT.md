# Phase 121: route-scorecards-judgment-contract - Context

**Gathered:** 2026-06-28 (assumptions mode, research-expanded)
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 121 locks the page-first judgment rubric and route scorecard inventory for v1.32 before more admin UI changes land. It covers deterministic scorecards, source/rendered guardrails, baseline-candidate classification for current admin coherence work, and the proof/support boundary. It does not implement Support, Operate, or Configure page polish; does not change OAuth/OIDC protocol behavior, storage schemas, host-owned seams, public support surface, runtime browser tooling, public design-system routes, theming APIs, or Docker/adoption-demo workflows.
</domain>

<decisions>
## Implementation Decisions

### Route Scorecard Truth

- **D-01:** Create one deterministic route scorecard artifact for Phase 121, recommended as `.planning/phases/121-route-scorecards-judgment-contract/121-ROUTE-SCORECARDS.md`, grouped by the locked journeys `Orient`, `Configure`, `Support`, and `Operate`. Prefer one labeled scorecard block per route over one file per route so maintainers can review the whole admin surface without hunting across many small files.
- **D-02:** Derive the required scorecard route set from `Lockspire.Web.AdminRouter` and append exactly one non-router workflow exception: `/admin/clients/:client_id/edit?workflow=logout-propagation`. Publish operator-readable `/admin...` paths only; do not use host-specific mount prefixes or screenshot filenames as route truth.
- **D-03:** Each scorecard must include: route, source truth, journey, persona, JTBD, top task, who/what/where/when/why, entry point, primary decision, primary action, earned-place check, empty state, error state, long-data state, mobile/theme/focus/motion risks, redaction/security check, unsupported-action check, follow-up route, component/group fit, evidence class, public-support promise, runtime/package impact, and notes.
- **D-04:** Follow-up routes in scorecards should resolve to another known admin scorecard route or to the single logout-propagation workflow exception. If a follow-up is external, documentation-only, or deliberately absent, the scorecard must state that explicitly.

### Judgment Rubric And Guardrails

- **D-05:** Use a hybrid proof strategy: human-readable scorecard markdown for judgment, source-derived ExUnit guardrails for route/field/boundary drift, and rendered LiveView/LazyHTML checks for representative route states. Do not rely on markdown alone.
- **D-06:** Phase 121 guardrails should fail on missing or extra scorecards, missing required fields, any second query-workflow exception, unsupported Operate queue actions, generic CTA drift, public lab/theming/storybook/browser-tooling creep, forbidden secret evidence, and follow-up routes that silently point outside the scorecard route set.
- **D-07:** Keep browser/axe/Playwright and optional AI/persona judge review as later maintainer evidence only. They are not Phase 121 requirements, not CI/release gates, not runtime dependencies, and not public support claims.
- **D-08:** The rubric must apply these design pillars to every route: accessibility, responsive reflow, information architecture, security/redaction, theme and motion behavior, performance/tooling weight, maintainability, docs truth, maintainer/developer DX, operator psychology, brand consistency, microcopy, and component fit. `brandbook/` is the current visual/token source of truth; older prompt brand guidance is subordinate if it conflicts.

### Baseline Candidate Boundary

- **D-09:** Treat committed source plus committed planning artifacts as authoritative baseline truth. Treat current dirty admin UI/proof diffs only as baseline candidate evidence to evaluate in scorecards, not as accepted v1.32 implementation.
- **D-10:** The current worktree baseline observed during context capture is branch `milestone/v1.28-admin-ui-operator-experience-polish` at commit `8515245`. Do not infer v1.32 implementation truth from the stale branch name.
- **D-11:** Admin baseline candidates include dirty files under `lib/lockspire/web/admin*`, `lib/lockspire/web/live/admin*`, `test/lockspire/web/live/admin/*`, `test/support/lockspire/web/admin_lab/*`, and the narrow admin refresh text in `.planning/threads/next-roadmap-assessment.md`. They may inform scorecard questions around confirmation-form lifecycle safety, DCR decision summaries, logout queue scanability, theme controls, form-field consistency, and shared component stress coverage.
- **D-12:** Dirty Docker/adoption-demo/Traefik/repo-hygiene files are not Phase 121 truth: `README.md`, `docs/adoption-demo.md`, `Makefile`, `.dockerignore`, `.gitignore`, `examples/adoption_demo/**`, `scripts/demo/**`, `scripts/maintainer/repo_hygiene_check.sh`, `test/lockspire/adoption_demo_docker_contract_test.exs`, `tools/traefik/**`, and `.planning/research/.cache/**`. Do not let them create admin scorecard requirements or v1.32 success criteria.
- **D-13:** Do not stash, revert, clean, or split worktrees as part of Phase 121 context/planning unless separately requested. The planner may recommend branch/worktree cleanup before implementation commits, but this context phase only classifies the dirty work.

### Support Boundary And Lab Creep

- **D-14:** Scorecards may reference internal maintainer proof, but each scorecard must state the support boundary with these fields: `Evidence class`, `Public support promise`, and `Runtime/package impact`.
- **D-15:** Allowed evidence classes are `internal_lab`, `rendered_guardrail`, `manual_browser_note`, and `none`. `internal_lab` can cite `AdminLab.StressSurface`, redaction-safe fixtures, ExUnit/LiveView/LazyHTML guardrails, and maintainer-only browser notes. It must never be classified as `admin_supported`.
- **D-16:** The required boundary wording is: `This scorecard may reference maintainer-only lab/stress proof. That proof is not a supported admin route, public API, host extension point, theming interface, browser-testing product, or Hex package surface.`
- **D-17:** Forbidden expansions for this phase: public design-system route, PhoenixStorybook/Storybook dependency, public theming API, host component registry, generated host-editable admin components, browser automation support claim, screenshot/trace/report package content, and any `docs/supported-surface.md` claim for lab, browser proof, public theming, or design-system API.

### Ecosystem Lessons To Apply

- **D-18:** Emulate Phoenix LiveDashboard and Oban Web as host-mounted admin surfaces protected by host-owned routing/auth, not standalone products. Keep Lockspire's admin route truth explicit and host seams narrow.
- **D-19:** Preserve Doorkeeper-style install/admin DX, but avoid route-protection ambiguity. Any admin/operator route inventory must be clear about what the host must guard.
- **D-20:** Preserve node-oidc-provider/OpenIddict/Ory/Hydra-style protocol/host seam separation: Lockspire owns protocol/operator state; the host owns account/authentication/product UX. Do not leak backend protocol internals into operator scorecards unless the operator needs them to make a safe decision.
- **D-21:** Apply GOV.UK-style service design: start from user needs, do less, make complex services simple, build services rather than isolated pages, be consistent without forcing uniformity, and make evidence open enough for maintainers to inspect.
- **D-22:** Learn from Cloudscape, GitLab Pajamas, Polaris, WCAG, and WAI-ARIA APG: pair components with patterns, content guidance, accessibility/focus checks, responsive behavior, theme parity, and concrete microcopy rules. Do not treat a design system as colors and cards only.
- **D-23:** Avoid Keycloak-style theming burden and Storybook-style public component/documentation scope creep in v1.32. Internal proof is useful; public theming/component support would become a semver and support burden.

### Claude's Discretion

Planner may choose exact helper names and test module organization, provided the scorecard artifact stays deterministic, route truth remains source-derived from `AdminRouter` plus the single query workflow, and proof stays repo-native. Prefer extracting small test helpers over growing an unreadable omnibus test if implementation pressure warrants it.

### Folded Todos

No matching pending todos were found for Phase 121.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

- `.planning/PROJECT.md`
- `.planning/REQUIREMENTS.md`
- `.planning/ROADMAP.md`
- `.planning/STATE.md`
- `.planning/METHODOLOGY.md`
- `.planning/DEVELOPMENT-TRAIN.md`
- `.planning/RETROSPECTIVE.md`
- `.planning/phases/107-admin-journey-contract-ia-audit/107-ROUTE-JOURNEY-CONTRACT.md`
- `.planning/phases/107-admin-journey-contract-ia-audit/107-CONTEXT.md`
- `.planning/phases/116-inventory-rubric-lab-contract/116-ROUTE-WORKFLOW-INVENTORY.md`
- `.planning/phases/116-inventory-rubric-lab-contract/116-VISUAL-UX-RUBRIC.md`
- `.planning/phases/116-inventory-rubric-lab-contract/116-LAB-CONTRACT.md`
- `.planning/phases/116-inventory-rubric-lab-contract/116-COMPONENT-GROUP-INVENTORY.md`
- `.planning/phases/120-browser-proof-docs-regression-audit/120-BROWSER-PROOF.md`
- `lib/lockspire/web/admin_router.ex`
- `lib/lockspire/web/components/admin_components.ex`
- `lib/lockspire/web/admin_css.ex`
- `docs/operator-admin.md`
- `docs/supported-surface.md`
- `test/lockspire/web/live/admin/design_system_contract_test.exs`
- `test/support/lockspire/web/admin_proof/html_assertions.ex`
- `test/lockspire/web/live/admin/design_system_component_stress_test.exs`
- `test/support/lockspire/web/admin_lab/fixtures.ex`
- `test/support/lockspire/web/admin_lab/stress_surface.ex`
- `prompts/Oauth server jtbd and domain.md`
- `prompts/lockspire-operator-admin-ia-and-workflows.md`
- `prompts/lockspire-operator-ux-liveview.md`
- `prompts/lockspire-host-app-integration-seam.md`
- `prompts/lockspire-elixir-oss-library-practices.md`
- `prompts/lockspire-release-engineering-and-ci.md`
- `prompts/lockspire-release-readiness-and-conformance.md`
- `prompts/lockspire-security-posture-and-threat-model.md`
- `brandbook/README.md`
- `brandbook/tokens/tokens.json`
- `brandbook/notes/accessibility-checks.md`
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `Lockspire.Web.AdminRouter` is the canonical mounted admin route source.
- Phase 107 and 116 route artifacts already provide route, journey, persona, JTBD, primary decision/action, empty/risk state, follow-up, evidence, and surface classification.
- `Lockspire.Web.Components.AdminComponents` and `Lockspire.Web.Admin.CSS` are the existing function-component and BEM/token CSS foundation.
- `Lockspire.Web.AdminProof.HtmlAssertions` already checks duplicate IDs, ARIA target references, label targets, links, generic CTA text, denied text, and unsupported interactive controls.
- `AdminLab.Fixtures` and `AdminLab.StressSurface` already provide internal redaction-safe component/lab proof.

### Established Patterns

- Admin UI proof favors deterministic ExUnit, LiveViewTest, LazyHTML, source contracts, and planning artifacts over browser-package tooling.
- Route truth is source-derived and appends only explicitly documented query workflows.
- Operator UI vocabulary is journey-led: Orient, Configure, Support, Operate.
- Admin components are Phoenix function components with attrs/slots. LiveViews own page intent, URL state, forms, validation, and mutation semantics.
- Public support truth remains bounded by `docs/supported-surface.md`; operator docs can explain maintainer workflow but cannot raise the public support ceiling.

### Integration Points

- Phase 121 should add/extend planning artifacts under `.planning/phases/121-route-scorecards-judgment-contract/`.
- Phase 121 guardrails likely extend `test/lockspire/web/live/admin/design_system_contract_test.exs` or extract a focused helper/test module around route scorecards.
- Rendered checks should reuse `test/support/lockspire/web/admin_proof/html_assertions.ex` instead of building a parallel HTML assertion vocabulary.
- Scorecard evidence may cite `test/support/lockspire/web/admin_lab/*`, but that citation remains maintainer-only/internal.
</code_context>

<specifics>
## Specific Ideas

- Recommended scorecard block shape:
  - `Route`
  - `Source truth`
  - `Journey`
  - `Persona`
  - `JTBD`
  - `Top task`
  - `Who / What / Where / When / Why`
  - `Entry point`
  - `Primary decision`
  - `Primary action`
  - `Earned-place check`
  - `Empty state`
  - `Error state`
  - `Long-data state`
  - `Mobile risk`
  - `Theme risk`
  - `Focus/motion risk`
  - `Redaction/security check`
  - `Unsupported action check`
  - `Follow-up route`
  - `Component/group fit`
  - `Evidence class`
  - `Public support promise`
  - `Runtime/package impact`
  - `Notes`
- Guardrail recommendation: parse route scorecards, compare against `Phoenix.Router.routes(Lockspire.Web.AdminRouter)` plus the query workflow exception, assert non-empty required fields, assert public-boundary denylists, assert Operate queue scorecards do not imply retry/discard/approve/deny/logout-now/worker controls, and assert follow-up route references are known or explicitly justified.
- Preferred UX tone remains calm, exact, consequence-oriented, and domain-accurate. Scorecards should protect operators from backend implementation leakage; they should expose protocol/domain nouns only when they help an operator make a safe decision.
- The dirty admin diffs are candidates to judge, not work to bless. Scorecards should be free to say a candidate pattern is good, weak, or out of scope.
</specifics>

<deferred>
## Deferred Ideas

- Public PhoenixStorybook or Storybook route remains deferred to FUTURE-01 only if the internal lab stops scaling.
- Visual snapshot/browser automation remains deferred to later proof phases and requires explicit maintainer approval before package/config/browser artifacts are added.
- Optional AI/persona judge prompts may be documented as maintainer evidence later, but they are not deterministic Phase 121 guardrails.
- Worktree/branch cleanup or splitting dirty admin work from Docker/demo work is not part of this context phase. It can be considered before implementation commits if needed.

### Reviewed Todos (not folded)

None.
</deferred>
