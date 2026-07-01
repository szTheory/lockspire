# Phase 122: support-investigation-flow-polish - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md — this log preserves the analysis.

**Date:** 2026-06-28
**Phase:** 122-support-investigation-flow-polish
**Mode:** assumptions, research-expanded
**Areas analyzed:** Phase boundary, investigation hierarchy, dense rows and pivots, closed states and errors, prompts and brandbook synthesis

## Assumptions Presented

### Phase Boundary

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Phase 122 should only polish the four existing Support LiveViews and reuse existing Admin token/consent APIs; it should not add routes, storage behavior, token/consent capabilities, or host-owned policy. | Confident | `.planning/ROADMAP.md`, `.planning/phases/122-support-investigation-flow-polish/122-UI-SPEC.md`, `lib/lockspire/web/admin_router.ex`, `lib/lockspire/admin/tokens.ex`, `lib/lockspire/admin/consents.ex` |

### Investigation Hierarchy

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Each Support page should lead with workflow context plus a compact `decision_summary` using the exact Phase 122 item sets before long metadata panes or lists. | Confident | `.planning/phases/122-support-investigation-flow-polish/122-UI-SPEC.md`, `lib/lockspire/web/live/admin/tokens_live/index.ex`, `lib/lockspire/web/live/admin/tokens_live/show.ex`, `lib/lockspire/web/live/admin/consents_live/index.ex`, `lib/lockspire/web/live/admin/consents_live/show.ex` |

### Dense Rows And Pivots

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Index rows should move toward `dense_resource_row` when adding health/status, family/scope context, and review actions, while keeping redacted handles and `long_value` for all long identifiers. | Likely | `.planning/phases/121-route-scorecards-judgment-contract/121-ROUTE-SCORECARDS.md`, `.planning/phases/122-support-investigation-flow-polish/122-UI-SPEC.md`, `lib/lockspire/web/components/admin_components.ex`, `lib/lockspire/web/admin_css.ex` |

### Closed States And Errors

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Revocation panels should keep existing backed mutations but render revoked/no-family/error states as closed or blocked support states: disabled/de-emphasized buttons, final consequence copy, and accessible `error_summary`/`error_list` or alert treatment. | Confident | `.planning/phases/122-support-investigation-flow-polish/122-UI-SPEC.md`, `lib/lockspire/web/components/admin_components.ex`, `lib/lockspire/web/live/admin/tokens_live/show.ex`, `lib/lockspire/web/live/admin/consents_live/show.ex`, `test/lockspire/admin/tokens_test.exs`, `test/lockspire/admin/consents_test.exs` |

## User Expansion

After the initial assumptions were presented, the user requested a deeper one-shot research pass across all assumptions, including:

- pros, cons, and tradeoffs for each plausible approach;
- idiomatic Elixir, Plug, Ecto, Phoenix, and LiveView practice;
- lessons from successful libraries/apps in the OAuth/admin/support-console ecosystem, including other languages/frameworks where useful;
- developer experience and principle-of-least-surprise analysis;
- UI/UX, graphic design, JTBD, user psychology, accessibility, performance, theme, motion, microcopy, and design-system lenses where applicable;
- use of relevant `prompts/` content, with newer `brandbook/` content taking precedence for visual guidance.

## Research Tracks

### Embedded Phoenix Architecture And Admin-Surface Boundary

Compared four approaches:

- Polish existing four LiveViews with existing Admin APIs.
- Add richer Admin query/domain APIs for summaries/support states.
- Create new support-specific routes/workflows.
- Expose host extension/config hooks for Support screens.

Recommendation: polish the existing four LiveViews and APIs. Allow only a narrow internal helper/read-model escape hatch if duplicated summary predicates would put security-sensitive decisions in templates. Do not add routes, public APIs, host hooks, or raw Ecto queries in LiveViews.

Key outside lessons:

- Phoenix contexts keep data access and validation in contexts rather than views.
- Phoenix LiveView keeps URL params, assigns, events, and form submissions in LiveViews.
- Phoenix function components with attrs/slots are the idiomatic reusable rendering layer.
- LiveDashboard and Oban Web keep admin surfaces host-mounted while the library owns bounded operational state.

### Support JTBD, Investigation Hierarchy, And Decision Summaries

Compared four approaches:

- Exact `decision_summary` before dense content.
- Richer hero summaries only.
- Metrics-first dashboard treatment.
- Table/list-first with summary secondary.

Recommendation: compact hero, exact `decision_summary`, then filters/lists/details/actions. Metrics-first and table-first optimize for monitoring or browsing, not resolving a support case under pressure.

Route language:

- `/admin/tokens`: `Filter tokens`, token lifecycle records, active/revoked/expired/reuse-detected events.
- `/admin/tokens/:id`: `Review token`, token health, refresh family lineage, `Revoke token`, `Revoke token family`.
- `/admin/consents`: `Filter consent grants`, stored grants, scope context.
- `/admin/consents/:id`: `Review stored grant`, `Revoke consent grant`, stops future remembered-consent reuse.

Anti-copy:

- Avoid `Submit`, `Manage`, `Open`, `decode JWT`, `hash`, `database row`, `kill session`, `disconnect app`, or any implication that Lockspire can recover token plaintext.

### Dense Investigation Rows

Compared four approaches:

- Convert index rows to `dense_resource_row`.
- Keep `resource_item` and strengthen copy/order.
- Use responsive tables with list fallback.
- Create a new `support_investigation_row`.

Recommendation: use `dense_resource_row` with strict row anatomy, not tables or a new component. Tables are best deferred until comparison, sorting, pagination, or bulk work becomes the primary job. A new component is premature until repetition proves `dense_resource_row` insufficient.

### Revocation Panels, Closed States, Errors, And Support-Safe Mutations

Compared four approaches:

- Keep backed mutations, disable/block impossible or closed UI actions.
- Keep active idempotent controls with explanatory copy.
- Split destructive actions into separate confirmation routes/modals.
- Add richer backend state/errors to drive panels.

Recommendation: A plus narrow D. Keep backend commands idempotent for races and stale events, but render the admin UI as closed for already-revoked/no-family states. Use inline confirmation panels, redaction-safe predicates, disabled/de-emphasized controls, and accessible error summaries/lists. Do not add separate routes or modals in Phase 122.

Important footguns:

- Backend idempotent does not mean UI-active.
- `reuse_detected_at` can make status `:reuse_detected` even when `revoked_at` is present.
- `aria-disabled` alone does not block activation.
- Do not render family revoke against `not recorded`.
- Do not say `active tokens revoked` if the backend count is unrevoked records rather than pre-action active count.
- Do not imply host logout, account suspension, consent revocation, worker control, or plaintext recovery.

### Prompts And Brandbook Synthesis

Applicable project principles:

- Host owns account/login/policy/branding; Lockspire owns protocol/operator state.
- Admin is a calm, first-class operator product, not backend table exposure.
- Support jobs include consent/token inspection, family lineage, revocation, and incident answers.
- Support pages should answer context, state, pivot, smallest safe action, and consequence in that order.
- Security posture requires strong redaction, no raw token/hash/plaintext leakage, and no fake support controls.

Conflict resolution:

- `brandbook/` wins over older prompt-era visual guidance for visual tokens and theme behavior.
- Admin follows light/dark/system rather than forced dark.
- Light-mode action text uses contrast-safe Deep Cyan.
- Shipped `--ls-*` tokens are the admin vocabulary.
- Older prompt guidance still applies for voice: calm, exact, low-anxiety, no fear/security clichés, and operator-tool clarity.

## External Research

- Phoenix contexts: https://phoenix.hexdocs.pm/contexts.html
- Phoenix LiveView lifecycle/forms/components: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html, https://hexdocs.pm/phoenix_live_view/form-bindings.html, https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html
- Phoenix LiveDashboard router: https://hexdocs.pm/phoenix_live_dashboard/Phoenix.LiveDashboard.Router.html
- Oban Web: https://github.com/oban-bg/oban_web and https://oban.pro/docs/web/overview.html
- GOV.UK design principles: https://www.gov.uk/guidance/government-design-principles
- Cloudscape empty states/filtering/table patterns: https://cloudscape.design/patterns/general/empty-states/, https://cloudscape.design/patterns/general/filter-patterns/, https://cloudscape.design/patterns/resource-management/view/table-view/
- GitLab Pajamas table/filter/empty states: https://design.gitlab.com/components/table, https://design.gitlab.com/components/filter, https://design.gitlab.com/patterns/empty-states
- Shopify Polaris resource list/empty state: https://polaris-react.shopify.com/components/lists/resource-list, https://polaris-react.shopify.com/components/layout-and-structure/empty-state
- W3C error identification and reflow: https://www.w3.org/WAI/WCAG22/Understanding/error-identification.html, https://www.w3.org/WAI/WCAG21/Understanding/reflow.html
- OAuth token revocation/introspection/security BCP: https://datatracker.ietf.org/doc/html/rfc7009, https://datatracker.ietf.org/doc/html/rfc7662, https://datatracker.ietf.org/doc/rfc9700/
- Keycloak admin consent/offline-token revocation: https://www.keycloak.org/docs/latest/server_admin/index.html, https://www.keycloak.org/docs-api/latest/rest-api/index.html

## Corrections Made

No corrections were requested after the research pass. The expanded research strengthened the original assumptions and converted the single Likely row-shape assumption into a locked recommendation to use `dense_resource_row` for Phase 122 index pages unless implementation proves it insufficient.
