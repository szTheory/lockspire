# Phase 125: Browser Proof, Docs & Adversarial Ratchet - Context

**Gathered:** 2026-06-30 (assumptions mode + subagent research)
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 125 closes v1.32 by proving the page-first admin IA and interaction-model polish is repeatable, accessible, responsive, and bounded. It covers PROOF-01, PROOF-02, and PROOF-03: redaction-safe ugly fixtures, deterministic guardrails, browser/manual evidence, operator docs, and final adversarial review.

This phase does not add OAuth/OIDC protocol behavior, storage schemas, public admin routes, public design-system/lab routes, public theming, host-owned authentication/layout seams, package/browser tooling support, CI browser gates, or new queue/client/token mutation capabilities. Route truth remains `Lockspire.Web.AdminRouter` plus exactly `/admin/clients/:client_id/edit?workflow=logout-propagation`.
</domain>

<decisions>
## Implementation Decisions

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

### Claude's Discretion

Planner may choose exact helper names, proof artifact name, command grouping, and route-test organization as long as D-01 through D-17 remain true. Prefer small, reusable test-support helpers and focused route proof over adding a second proof system or expanding an already-large omnibus test with page-specific details.

### Folded Todos

No matching pending todos were found for Phase 125.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

- `.planning/PROJECT.md`
- `.planning/REQUIREMENTS.md`
- `.planning/ROADMAP.md`
- `.planning/STATE.md`
- `.planning/METHODOLOGY.md`
- `.planning/phases/120-browser-proof-docs-regression-audit/120-CONTEXT.md`
- `.planning/phases/120-browser-proof-docs-regression-audit/120-BROWSER-PROOF.md`
- `.planning/phases/121-route-scorecards-judgment-contract/121-CONTEXT.md`
- `.planning/phases/121-route-scorecards-judgment-contract/121-ROUTE-SCORECARDS.md`
- `.planning/phases/122-support-investigation-flow-polish/122-CONTEXT.md`
- `.planning/phases/122-support-investigation-flow-polish/122-UI-SPEC.md`
- `.planning/phases/122-support-investigation-flow-polish/122-VERIFICATION.md`
- `.planning/phases/123-operate-queue-flow-polish/123-CONTEXT.md`
- `.planning/phases/123-operate-queue-flow-polish/123-UI-SPEC.md`
- `.planning/phases/123-operate-queue-flow-polish/123-OPERATE-PROOF.md`
- `.planning/phases/123-operate-queue-flow-polish/123-VERIFICATION.md`
- `.planning/phases/124-configure-onboarding-propagation-pass/124-CONTEXT.md`
- `.planning/phases/124-configure-onboarding-propagation-pass/124-UI-SPEC.md`
- `.planning/phases/124-configure-onboarding-propagation-pass/124-VERIFICATION.md`
- `docs/operator-admin.md`
- `docs/supported-surface.md`
- `brandbook/README.md`
- `brandbook/tokens/tokens.json`
- `brandbook/notes/accessibility-checks.md`
- `brandbook/notes/decision-log.md`
- `prompts/lockspire-operator-admin-ia-and-workflows.md`
- `prompts/lockspire-operator-ux-liveview.md`
- `prompts/lockspire-elixir-oss-library-practices.md`
- `prompts/lockspire-release-engineering-and-ci.md`
- `prompts/lockspire-host-app-integration-seam.md`
- `test/support/lockspire/web/admin_lab/fixtures.ex`
- `test/support/lockspire/web/admin_lab/stress_surface.ex`
- `test/support/lockspire/web/admin_proof/html_assertions.ex`
- `test/support/lockspire/web/admin_proof/route_scorecards.ex`
- `test/lockspire/web/live/admin/design_system_component_stress_test.exs`
- `test/lockspire/web/live/admin/design_system_contract_test.exs`
- `lib/lockspire/web/admin_router.ex`
- `lib/lockspire/web/admin_css.ex`
- `lib/lockspire/web/components/admin_components.ex`
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `Lockspire.Web.AdminProof.HtmlAssertions` already proves duplicate IDs, ARIA target references, explicit label targets, link hrefs, generic CTA denial, unsupported interactive controls, and denied text.
- `Lockspire.Web.AdminProof.RouteScorecards` already derives route truth from `Lockspire.Web.AdminRouter` plus the single logout-propagation workflow exception and parses Phase 121 scorecards.
- `Lockspire.Web.AdminLab.Fixtures` and `Lockspire.Web.AdminLab.StressSurface` already provide internal redaction-safe component stress coverage for clients, tokens, consents, keys, DCR/IAT, operations, structural rows, status matrix, theme modes, and motion modes.
- `design_system_contract_test.exs` already houses global CSS/token/theme/motion/route/docs/package-boundary guardrails across prior admin UI phases.
- Focused admin LiveView tests under `test/lockspire/web/live/admin/**` already prove Support, Operate, and Configure route rendering, redaction, copy-once, closed-state, and unsupported-action behavior.

### Established Patterns

- Route truth is source-derived, not screenshot-derived or markdown-only.
- Phoenix function components, `lockspire-admin-*` BEM classes, and `--ls-*` design tokens are the supported admin implementation shape.
- LiveViews call existing Admin/domain APIs; route polish does not introduce raw Ecto queries, storage schema changes, or new public Admin APIs.
- Browser/manual evidence is maintainer-only and supplemental; source/rendered proof is the blocking path.
- Public docs remain subordinate to `docs/supported-surface.md` and must not raise the support ceiling.

### Integration Points

- Phase 125 plans should likely touch test support under `test/support/lockspire/web/admin_proof/**`, focused admin route tests, `design_system_contract_test.exs`, `design_system_component_stress_test.exs`, `docs/operator-admin.md`, and a new `.planning/phases/125-browser-proof-docs-adversarial-ratchet/125-V1.32-PROOF.md`.
- Existing dirty files in admin CSS/components/layout/lab are candidate evidence only. Planners/executors must inspect diffs before touching them, preserve unrelated user-owned changes, and stage only Phase 125-owned hunks.
</code_context>

<specifics>
## Specific Ideas

- Recommended proof stack:
  1. Global route/docs/package/CSS contracts in `design_system_contract_test.exs`.
  2. Reusable `AdminProof` helpers for sensitive text, source assertions, and browser-evidence parsing if duplication warrants extraction.
  3. Route-specific rendered LiveView tests for Support, Operate, and Configure page/JTBD proof.
  4. Internal AdminLab/component stress proof for primitive/status/theme/motion/redaction coverage.
  5. Maintainer-only `125-V1.32-PROOF.md` for route matrix, manual/browser notes, guardrail command outcomes, explicit gaps, sensitive-evidence denylist, and adversarial signoff.
  6. Bounded `docs/operator-admin.md` update for workflow and proof-boundary explanation.
- Representative browser/manual matrix should cover Orient, Configure, Support, Operate, and internal lab boundary across `320px`, `390px`, `768px`, `1024px`, `1440px`, light, dark, system, reduced motion, keyboard focus, empty, dense, long-data, incident, copy-once, stale/read-only, and no-page-overflow evidence. Do not require full cartesian coverage if the table explicitly maps each risk to representative rows.
- UI/UX review should preserve user-task language: Orient asks what needs attention; Configure asks what posture should change; Support asks what happened and what smallest safe action exists; Operate asks what protocol work is waiting, expired, failing, or safely reviewable.
- Microcopy should stay calm, exact, consequence-oriented, and domain-specific. Hide backend guts such as SQL rows, worker internals, hashes, raw protocol params, and storage fields unless they are the operator's actual safe support object.
- External research reinforced the local direction: Phoenix/LiveView favors component and LiveView tests; WAI/WCAG requires labels, focus, non-color status, and 320px reflow; Cloudscape/GitLab/Polaris reinforce compact text-backed status; Phoenix LiveDashboard/Oban Web model host-mounted admin surfaces; Django admin warns not to stretch generic admin hooks into process-centric product UI; Keycloak theming is a cautionary support-burden example.
</specifics>

<deferred>
## Deferred Ideas

- First-class Playwright/axe/screenshot/visual-regression automation: future optional maintainer tooling only after separate approval, package legitimacy review, artifact-scrubbing plan, and non-runtime/non-Hex boundary docs.
- Public component lab, Storybook/PhoenixStorybook route, public design-system docs/API, public theming engine, or host component registry: out of scope for v1.32 and deferred unless a future milestone deliberately accepts that product/support burden.
- Runtime AI/persona judge gate: out of scope. Optional prompts may be advisory maintainer evidence only.
- Full route x viewport x theme x motion screenshot cartesian matrix: out of scope unless future evidence shows representative coverage misses important regressions.
- `docs/supported-surface.md` edits: deferred unless Phase 125 implementation finds a concrete public-support ambiguity.

### Reviewed Todos (not folded)

None.
</deferred>
