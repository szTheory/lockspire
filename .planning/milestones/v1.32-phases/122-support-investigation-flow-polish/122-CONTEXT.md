# Phase 122: support-investigation-flow-polish - Context

**Gathered:** 2026-06-28 (assumptions mode, research-expanded)
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 122 polishes the four existing Support investigation routes for token and consent workflows:
`/admin/tokens`, `/admin/tokens/:id`, `/admin/consents`, and `/admin/consents/:id`.
It makes those pages read as calm operator support workflows instead of metadata inventories.

This phase does not add admin routes, protocol behavior, storage schemas, token/consent capabilities,
host-owned account or policy logic, public theming, public component APIs, route-extension hooks,
bulk actions, reveal/export/debug controls, or supported browser/design-system product surface.
Use existing Admin APIs by default: list/get tokens, revoke token, revoke token family, list/get
consents, and revoke consent.
</domain>

<decisions>
## Implementation Decisions

### Phase Boundary And Architecture

- **D-01:** Polish only the four existing Support LiveViews with existing Admin token and consent APIs. Do not add new support routes, storage behavior, host hooks, public customization surfaces, or unsupported controls. This keeps Phase 122 aligned with Phase 121 route scorecard truth and the embedded-library boundary.
- **D-02:** Keep URL filters, assigns, event handling, and validation state in the LiveViews; keep reusable structure and wrapping in Phoenix function components; keep domain reads and mutations behind `Lockspire.Admin.Tokens` and `Lockspire.Admin.Consents`. Do not introduce raw Ecto queries in LiveViews.
- **D-03:** A narrow internal helper/read-model layer is allowed only if planner finds that duplicated LiveView summary predicates would otherwise put security-sensitive state decisions in templates. Such helpers must remain internal, redaction-safe, and presentation-neutral; they must not become a new public Admin API or host extension seam.

### Investigation Hierarchy

- **D-04:** Each Support page must use this spine: compact `page_hero` for route context, exact `decision_summary` before dense content, then filters/lists/details/actions. Do not make metrics, tables, or raw metadata the first decision surface.
- **D-05:** Use the exact Phase 122 decision-summary item sets:
  - Token index: `Selected filters`, `Token health`, `Family pressure`, `Smallest safe action`
  - Token detail: `Token health`, `Family lineage`, `Reuse pressure`, `Smallest safe action`
  - Consent index: `Selected filters`, `Grant status`, `Scope context`, `Smallest safe action`
  - Consent detail: `Grant status`, `Scope context`, `Client/account pivot`, `Revocation consequence`
- **D-06:** Keep the Support mental model case-oriented rather than backend-oriented. The pages should answer, in order: which workflow/case context, what health or grant state, what family/scope/client/account pivot explains it, what smallest safe action exists, and what consequence follows.
- **D-07:** Use explicit Support vocabulary: `Filter tokens`, `Review token`, `Revoke token`, `Revoke token family`, `Filter consent grants`, `Review stored grant`, and `Revoke consent grant`. Avoid generic or misleading labels such as `Submit`, `Manage`, `Open`, `Continue`, one-word `Revoke`, `decode JWT`, `hash`, `database row`, `kill session`, or `disconnect app`.

### Dense Rows And Pivots

- **D-08:** Convert token and consent index rows toward `dense_resource_row` rather than raw tables, a new support-row component, or lightly patched `resource_item` rows. This matches the Phase 121/122 component fit and makes status/context lead identifiers under dense data.
- **D-09:** Token index rows should lead with token health/status plus token type, then show redacted client, account, family, lifecycle timestamp, and visible `Review token` action. Consent index rows should lead with grant status plus grant kind, then show client/account, scope summary, relevant timestamp, and visible `Review stored grant` action.
- **D-10:** Use `long_value`, `timestamp` or equivalent wrapping, redacted handles, status text, semantic tokens, and mobile stacking for long account IDs, client IDs, family handles, grant handles, scopes, URLs, and timestamps. No row may expose token plaintext, refresh-token plaintext, token hashes, client secrets, verifier material, cookies, authorization codes, user-code material, or raw sensitive account values.
- **D-11:** Do not use responsive tables as the primary Phase 122 experience. Tables are deferred until a future phase makes sorting, pagination, true column comparison, selectable bulk work, or operator preference controls the primary job.
- **D-12:** Do not create `support_investigation_row` in Phase 122 unless implementation proves `dense_resource_row` cannot express the required anatomy without unsafe duplication. Prefer compounding the existing design system over speculative component growth.

### Closed States, Errors, And Destructive Actions

- **D-13:** Keep the current idempotent backend Admin commands for stale/racy submits, but render closed or impossible admin UI states as closed: disabled or de-emphasized controls, clear adjacent explanation, and no active-looking destructive CTA for already-revoked token/grant or no-family cases.
- **D-14:** Detail pages keep inline confirmation panels, not separate confirmation routes or modals. Separate routes/modals are deferred for future bulk, multi-object, typed-confirm, or highly complex destructive workflows.
- **D-15:** Revocation panel predicates must be explicit and redaction-safe. Do not key closed state only off `status == :revoked`; `reuse_detected_at` can make status `:reuse_detected` even when `revoked_at` exists. Do not render family revoke as available when no family exists.
- **D-16:** Confirmation and error copy must be specific, consequence-oriented, accessible, and backend-safe:
  - Missing checkbox: `Select the confirmation checkbox to revoke this token.`, `Select the confirmation checkbox to revoke this refresh family.`, or `Select the confirmation checkbox to revoke this consent grant.`
  - Already revoked token: `This token is already revoked. No further token action is available.`
  - Already revoked consent: `This consent grant is already revoked. It no longer authorizes future remembered-consent reuse.`
  - No family: `This token is not part of a refresh family, so family-wide revocation is unavailable.`
  - Failure: `Revocation could not be confirmed. The token may still be active; reload this Support workflow before retrying.` Use the same shape for consent.
- **D-17:** Render validation and mutation errors through `error_summary`, `error_list`, or equivalent alert/error semantics, not plain paragraphs. Closed notices should be calm status/info copy, not urgent alerts.
- **D-18:** Family revocation copy must not imply host logout, account suspension, consent revocation, worker control, plaintext recovery, or broader protocol behavior than the backed Admin API actually performs. Do not say `active tokens revoked` if the backend count is unrevoked records rather than a pre-action active count.

### UI/UX And Design-System Principles

- **D-19:** Treat Support operators as working under possible incident or account-support pressure. Favor first-scan clarity, low-anxiety copy, non-color status labels, visible focus, stable hit areas, and state/consequence before implementation detail.
- **D-20:** Apply design pillars for Phase 122: accessibility, responsive reflow, information architecture, security/redaction, theme parity, reduced motion, performance/tooling weight, maintainability, docs truth, operator psychology, brand consistency, microcopy, and component fit.
- **D-21:** Preserve the v1.31/v1.32 design-system boundary: Phoenix function components, `lockspire-admin-*` BEM classes, `--ls-*` design tokens, internal lab/proof only, no Tailwind/shadcn, no public Storybook/design-system route, no public theming API, and no host component registry.
- **D-22:** Where older prompt-era visual guidance conflicts with current planning or `brandbook/`, the newer `brandbook/` wins. Specifically, support light/dark/system behavior, use shipped `--ls-*` tokens, keep light-mode action text contrast-safe with Deep Cyan, and retain the prompt voice only where it reinforces calm, exact operator tooling.

### Claude's Discretion

Planner and executor may choose helper names, exact private function boundaries, and test module organization, provided the four-route boundary, exact decision-summary item sets, redaction posture, closed-state behavior, and existing-component preference are preserved.

### Folded Todos

No matching pending todos were found for Phase 122.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

- `.planning/PROJECT.md`
- `.planning/REQUIREMENTS.md`
- `.planning/ROADMAP.md`
- `.planning/STATE.md`
- `.planning/METHODOLOGY.md`
- `.planning/phases/122-support-investigation-flow-polish/122-UI-SPEC.md`
- `.planning/phases/121-route-scorecards-judgment-contract/121-CONTEXT.md`
- `.planning/phases/121-route-scorecards-judgment-contract/121-ROUTE-SCORECARDS.md`
- `.planning/phases/107-admin-journey-contract-ia-audit/107-CONTEXT.md`
- `.planning/phases/108-design-system-token-component-upgrade/108-CONTEXT.md`
- `.planning/phases/109-weak-spot-page-polish/109-CONTEXT.md`
- `.planning/phases/116-inventory-rubric-lab-contract/116-CONTEXT.md`
- `.planning/phases/118-primitive-meta-component-upgrade/118-CONTEXT.md`
- `.planning/phases/119-weak-page-application-ia-copy-pass/119-CONTEXT.md`
- `.planning/phases/120-browser-proof-docs-regression-audit/120-CONTEXT.md`
- `lib/lockspire/web/admin_router.ex`
- `lib/lockspire/web/components/admin_components.ex`
- `lib/lockspire/web/admin_css.ex`
- `lib/lockspire/web/live/admin/tokens_live/index.ex`
- `lib/lockspire/web/live/admin/tokens_live/show.ex`
- `lib/lockspire/web/live/admin/consents_live/index.ex`
- `lib/lockspire/web/live/admin/consents_live/show.ex`
- `lib/lockspire/admin/tokens.ex`
- `lib/lockspire/admin/consents.ex`
- `test/lockspire/web/live/admin/tokens_live_test.exs`
- `test/lockspire/web/live/admin/consents_live_test.exs`
- `test/support/lockspire/web/admin_proof/html_assertions.ex`
- `test/support/lockspire/web/admin_lab/fixtures.ex`
- `test/support/lockspire/web/admin_lab/stress_surface.ex`
- `brandbook/README.md`
- `brandbook/tokens/tokens.json`
- `brandbook/tokens/tokens.css`
- `brandbook/notes/accessibility-checks.md`
- `brandbook/notes/decision-log.md`
- `prompts/Oauth server jtbd and domain.md`
- `prompts/lockspire-operator-admin-ia-and-workflows.md`
- `prompts/lockspire-operator-ux-liveview.md`
- `prompts/lockspire-host-app-integration-seam.md`
- `prompts/lockspire-elixir-oss-library-practices.md`
- `prompts/lockspire-security-posture-and-threat-model.md`

External research references applied:

- Phoenix contexts: https://phoenix.hexdocs.pm/contexts.html
- Phoenix LiveView lifecycle and forms: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html and https://hexdocs.pm/phoenix_live_view/form-bindings.html
- Phoenix function components: https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html
- Phoenix LiveDashboard router: https://hexdocs.pm/phoenix_live_dashboard/Phoenix.LiveDashboard.Router.html
- Oban Web embedded dashboard pattern: https://github.com/oban-bg/oban_web and https://oban.pro/docs/web/overview.html
- GOV.UK design principles: https://www.gov.uk/guidance/government-design-principles
- Cloudscape empty states, filters, and table/detail patterns: https://cloudscape.design/patterns/general/empty-states/ and https://cloudscape.design/patterns/general/filter-patterns/ and https://cloudscape.design/patterns/resource-management/view/table-view/
- GitLab Pajamas table/filter/empty state patterns: https://design.gitlab.com/components/table and https://design.gitlab.com/components/filter and https://design.gitlab.com/patterns/empty-states
- Shopify Polaris resource list and empty state: https://polaris-react.shopify.com/components/lists/resource-list and https://polaris-react.shopify.com/components/layout-and-structure/empty-state
- W3C error identification: https://www.w3.org/WAI/WCAG22/Understanding/error-identification.html
- W3C responsive reflow: https://www.w3.org/WAI/WCAG21/Understanding/reflow.html
- OAuth token revocation and introspection: https://datatracker.ietf.org/doc/html/rfc7009 and https://datatracker.ietf.org/doc/html/rfc7662
- OAuth 2.0 Security Best Current Practice: https://datatracker.ietf.org/doc/rfc9700/
- Keycloak admin consent/offline-token revocation reference: https://www.keycloak.org/docs/latest/server_admin/index.html and https://www.keycloak.org/docs-api/latest/rest-api/index.html
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `Lockspire.Web.AdminRouter` already exposes the four Phase 122 Support routes and keeps route truth source-derived.
- `Lockspire.Web.Components.AdminComponents` already provides `page_hero`, `decision_summary`, `entity_header`, `pane`, `resource_list`, `dense_resource_row`, `long_value`, `status_badge`, `description_list`, `filter_bar`, `form_field`, `confirmation_panel`, `action_group`, `error_summary`, `error_list`, `empty_state`, `timestamp`, and `admin_button`.
- `Lockspire.Web.Admin.CSS` already carries the `lockspire-admin-*` BEM/token surface, responsive stacking, status semantics, and long-value wrapping foundations.
- `Lockspire.Admin.Tokens` already computes token status, token handles, family tokens, family status, family active/revoked counts, and family reuse signal.
- `Lockspire.Admin.Consents` already provides durable consent grant/client data for index/detail and backed revocation.
- Current token and consent LiveView tests already check route exposure, redaction, generic CTA avoidance, links, long-value classes, confirmation forms, and key copy.
- `AdminProof.HtmlAssertions` already checks duplicate IDs, described-by targets, labels, generic CTA text, denied text, links, and unsupported controls.

### Established Patterns

- Admin proof favors deterministic ExUnit, LiveViewTest, LazyHTML/helper assertions, source contracts, and maintainer-only planning artifacts over public browser-tooling support.
- LiveViews own URL filters, loaded state, events, and validation/error state. Function components own repeatable UI structure, wrapping, slots, and semantic classes.
- Admin UI vocabulary is journey-led: Orient, Configure, Support, Operate.
- Route-level Support pages should expose operator decisions and durable redacted pivots, not raw database shape or protocol internals.
- Public support truth is bounded by `docs/supported-surface.md`; internal lab, scorecards, screenshots, and browser notes do not raise the support ceiling.

### Integration Points

- Add decision-summary rendering and derived summary helpers in the four Support LiveViews, unless a narrow internal helper is needed to avoid duplicated state predicates.
- Convert token and consent index row bodies toward `dense_resource_row` while preserving visible detail links/actions and accessible focus.
- Tighten token and consent detail confirmation panels around closed-state predicates, disabled semantics, `error_summary`/`error_list`, and consequence copy.
- Extend token and consent LiveView tests to cover exact summary labels, dense row class/anatomy, no raw identifiers or secret material, closed-state disabled/de-emphasized controls, already-revoked/no-family copy, accessible error semantics, and no generic CTA text.
- If CSS changes are needed, keep them inside `lib/lockspire/web/admin_css.ex` using existing tokens and BEM naming; do not introduce a new visual system or public theming contract.
</code_context>

<specifics>
## Specific Ideas

- Recommended page order:
  1. `page_hero` with `Support` eyebrow and selected workflow/case context.
  2. Exact `decision_summary` item set for the route.
  3. Filter bar or entity header/detail panes.
  4. Dense rows or detail panes.
  5. Corrective/destructive actions with consequence copy.
- Token row anatomy: `Active refresh token` or equivalent health/type title, status/type badges, redacted client/account/family, expiry or last lifecycle timestamp, `Review token`.
- Consent row anatomy: `Active remembered grant` or equivalent status/kind title, redacted client/account, scope summary, updated/revoked timestamp, `Review stored grant`.
- Recommended closed/error vocabulary is locked in D-16. Keep it short, calm, and stateful.
- Use backend names only when they are meaningful OAuth/operator domain language. Hide implementation details such as Ecto rows, token hashes, database failures, worker internals, and raw family IDs.
- Design detail guidance from the UI polish skill: keep type scale tight, use balanced headings and readable body copy where supported, use tabular numbers for dynamic counts, avoid `transition: all`, preserve minimum 40px hit areas, and keep hover/focus transitions explicit and reduced-motion safe.
</specifics>

<deferred>
## Deferred Ideas

- New `/admin/support/...` routes or guided case workspaces are deferred until evidence proves the four existing routes cannot support the operator workflow.
- Host extension/config hooks for Support screens are deferred until repeated adopter demand justifies a stable public seam.
- Responsive tables are deferred until sorting, pagination, true column comparison, selectable bulk work, or collection preferences become the primary operator job.
- A new `support_investigation_row` component is deferred until repeated Support/Operate route use proves `dense_resource_row` is insufficient.
- Separate destructive confirmation routes or modals are deferred until actions become bulk, multi-object, typed-confirm, or too complex for inline confirmation panels.
- Public Storybook/PhoenixStorybook, public design-system routes, browser automation product support, visual snapshot tooling, public theming, and host component registries remain out of scope.

### Reviewed Todos (not folded)

None.
</deferred>
