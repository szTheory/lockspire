# Phase 123: Operate Queue Flow Polish - Context

**Gathered:** 2026-06-29 (assumptions mode with research expansion)
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 123 polishes only the existing Operate queues: `/admin/interactions`, `/admin/device_authorizations`, and `/admin/logouts`. The work is page IA, queue scanability, redaction-safe data shaping, responsive/theme/focus/motion polish, and deterministic proof for OPERATE-01, OPERATE-02, and OPERATE-03.

This phase must not add new admin routes, public lab routes, browser-tooling product surface, host customization seams, retry/discard/approve/deny/logout-now/requeue controls, worker controls, protocol behavior, storage schema changes, or public support-contract expansion.
</domain>

<decisions>
## Implementation Decisions

### Route And Surface Boundary

- **D-01:** Polish only the existing Operate routes `/admin/interactions`, `/admin/device_authorizations`, and `/admin/logouts`, plus internal proof/tests. Do not add `/admin/operate`, detail routes, public lab/browser-proof routes, public theming/design-system routes, or new support-surface claims.
- **D-02:** Preserve the embedded Phoenix library shape: host apps mount and guard `Lockspire.Web.AdminRouter`; Lockspire owns protocol/operator state after the host-guarded router; the host owns staff authentication, MFA, roles, tenant policy, outer layout, branding, and access framing.
- **D-03:** Treat Operate queues as read-only support-review surfaces, not command centers. Defer retry, discard, approve, deny, logout-now, requeue, pause/resume, and worker-control affordances unless a later phase first designs backed Admin domain APIs, authorization semantics, audit logging, telemetry, and docs.

### Queue Anatomy And Operator JTBD

- **D-04:** Use logout deliveries as the strongest existing scan pattern, then align interactions and device authorizations toward the same pressure-first anatomy where it improves scanability. Prefer the existing `page_hero`, `pane`, `metric_grid`, `summary_stat`, `resource_list`, `dense_resource_row`, `status_badge`, `long_value`, and `empty_state` primitives.
- **D-05:** Do not convert these queues to responsive tables or a data grid in Phase 123. The current job is fast incident/support scanning, not column comparison, sorting, bulk selection, or operator preference controls.
- **D-06:** Do not create `operate_queue_row` or `operate_queue_page` by default. A small internal function component is allowed only if duplication across the three queues becomes error-prone and the component preserves route-specific domain language through explicit attrs/slots.
- **D-07:** The Operate persona is a support engineer/provider operator who enters through Operate routes or overview pivots when authorization work looks stuck, device flow is pending/expired, or logout propagation failed/retried. The pages should answer: what is waiting, risky, expired, complete, or terminal; which client/account/endpoint explains it; what durable non-secret identifier supports follow-up; and what safe support/configuration pivot exists.

### Applicable Data And Redaction

- **D-08:** Use queue-specific internal Admin Operate read models or tightly equivalent private helpers, backed by existing domain/storage reads. Keep shaping presentation-neutral and internal; do not create a new public Admin API or host extension seam for this polish phase.
- **D-09:** Logout delivery rows may show delivery id, redacted client handle, channel, endpoint URL, attempts, status pressure, HTTP status or failure class when useful, last activity, and support note. They must not expose logout token JTI as an operator-facing secret surrogate, Oban job IDs as the primary support concept, raw response bodies, cookies, endpoint secrets, live tenant hostnames, or SQL/worker internals.
- **D-10:** Interaction rows may show interaction id, redacted client/account handles, prompt, status pressure, created/age, and expiry. They must not expose authorization codes, request object internals, cookies, session tokens, nonce/state values, PKCE material, raw params, or raw sensitive return values.
- **D-11:** Device authorization rows may show redacted client/account handles, redacted durable authorization handle, status, expiry, poll interval/next poll or updated-at-derived activity. They must never expose raw `device_code`, `user_code`, hashes, raw `verification_handle`, authorization codes, token material, PKCE material, state, nonce, raw params, or backend storage details.
- **D-12:** Prefer `Lockspire.Redaction.handle/2`, `AdminComponents.long_value`, text status labels, semantic status badges, and redaction tests over raw identifiers. If sensitive storage fields are touched, preserve or add Ecto `redact: true` and `load_in_query: false` where appropriate.

### UI, UX, Brand, And Microcopy

- **D-13:** Keep copy calm, exact, low-anxiety, and consequence-oriented. Use Lockspire domain nouns: operator, account, client, interaction, device authorization, logout delivery, endpoint, status, expiry, attempts, support note. Avoid backend-leaking terms such as SQL row, Oban job, worker internals, raw hash, database failure, code material, or request object unless the operator truly needs them.
- **D-14:** Enforce these design pillars for changed Operate pages: accessibility, responsive reflow, information architecture, security/redaction, theme parity, reduced-motion safety, visible focus, performance/tooling weight, maintainability, docs truth, maintainer DX, operator psychology, brand consistency, microcopy quality, and component fit.
- **D-15:** Use the current `brandbook/` as visual truth where it conflicts with older prompt-era guidance. Continue using shipped `--ls-*` tokens, Signal Cyan/Deep Cyan contrast rules, text status labels, no color-only state, focus rings that are never removed, and reduced-motion behavior that neutralizes nonessential transitions.
- **D-16:** Hide backend implementation details behind operator-facing JTBD. The UI should expose what the operator can safely know or do: observe, correlate, and pivot. It should not reveal the internal mechanism unless the mechanism is the operator's actual support object.

### Verification And DX

- **D-17:** Prove OPERATE-02 with a deterministic source/API fence: no new Operate mutation delegates in `Lockspire.Admin`, no `phx-click`/`phx-submit` command controls on the three queues, and no actionable retry/discard/approve/deny/logout-now/requeue/worker-control affordances.
- **D-18:** Use focused LiveView/rendered HTML tests with existing `HtmlAssertions`/LazyHTML helpers as the primary proof. Cover empty, dense, incident, expired, retryable, discarded, skipped, rendered, completed, long-value, redaction, no-table-overload, no-unsupported-action, duplicate-ID, ARIA target, generic-CTA, theme-token, and reduced-motion claims where changed.
- **D-19:** Expand `AdminLab`/component stress fixtures only when this phase changes shared row/status/long-value primitives. Keep lab proof internal and maintainer-only.
- **D-20:** Browser/axe/manual evidence is supplemental when CSS/layout changes are material; it must stay maintainer-only, redaction-safe, and outside Hex/runtime/public support surface. Do not make screenshots or browser reports the primary assertion mechanism.

### Ecosystem Lessons Applied

- **D-21:** Copy Phoenix LiveDashboard and Oban Web's embedded-router lesson: admin/operator surfaces can be first-class while still being host-mounted and protected by the host app.
- **D-22:** Copy Oban Web and Sidekiq's command-console lesson only when backed by explicit action APIs and access semantics. For Phase 123, take their status/pressure visibility lesson, not their mutation controls.
- **D-23:** Learn from Keycloak-style breadth that broad admin/theming/support surfaces become a long-term product and semver burden. Lockspire should stay narrow, embedded, and explicit.
- **D-24:** Learn from GOV.UK, Cloudscape, GitLab, WAI-ARIA, and WCAG: start from user needs, make status compact and textual, avoid false affordances, use conventional accessible components, support reflow and reduced motion, and make dense operational UI scannable without hiding risk.

### Claude's Discretion

Planner may choose exact helper names, test organization, fixture builders, and whether queue-specific shaping lives in private LiveView helpers or a narrow internal read-model module. Preserve the route boundary, read-only truth, redaction posture, existing-component preference, route-specific domain language, and deterministic proof stack.

### Folded Todos

No matching pending todos were found for Phase 123.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

- `.planning/ROADMAP.md`
- `.planning/REQUIREMENTS.md`
- `.planning/STATE.md`
- `.planning/METHODOLOGY.md`
- `.planning/phases/119-weak-page-application-ia-copy-pass/119-CONTEXT.md`
- `.planning/phases/120-browser-proof-docs-regression-audit/120-CONTEXT.md`
- `.planning/phases/121-route-scorecards-judgment-contract/121-CONTEXT.md`
- `.planning/phases/121-route-scorecards-judgment-contract/121-ROUTE-SCORECARDS.md`
- `.planning/phases/122-support-investigation-flow-polish/122-CONTEXT.md`
- `docs/operator-admin.md`
- `docs/supported-surface.md`
- `lib/lockspire/web/admin_router.ex`
- `lib/lockspire/web/live/admin/interactions_live/index.ex`
- `lib/lockspire/web/live/admin/device_authorizations_live/index.ex`
- `lib/lockspire/web/live/admin/logout_deliveries_live/index.ex`
- `lib/lockspire/web/components/admin_components.ex`
- `lib/lockspire/web/admin_css.ex`
- `lib/lockspire/domain/interaction.ex`
- `lib/lockspire/domain/device_authorization.ex`
- `lib/lockspire/domain/logout_delivery.ex`
- `test/lockspire/web/live/admin/interactions_live_test.exs`
- `test/lockspire/web/live/admin/device_authorizations_live_test.exs`
- `test/lockspire/web/live/admin/logout_deliveries_live_test.exs`
- `test/lockspire/web/live/admin/design_system_contract_test.exs`
- `test/lockspire/web/live/admin/design_system_component_stress_test.exs`
- `test/support/lockspire/web/admin_proof/html_assertions.ex`
- `test/support/lockspire/web/admin_lab/fixtures.ex`
- `test/support/lockspire/web/admin_lab/stress_surface.ex`
- `prompts/lockspire-operator-admin-ia-and-workflows.md`
- `prompts/lockspire-operator-ux-liveview.md`
- `prompts/lockspire-auth-domain-language-field-guide.md`
- `prompts/lockspire-oauth-oidc-implementation-playbook.md`
- `prompts/lockspire-host-app-integration-seam.md`
- `prompts/lockspire-security-posture-and-threat-model.md`
- `prompts/lockspire-ecto-token-and-audit-model.md`
- `prompts/lockspire-release-engineering-and-ci.md`
- `brandbook/README.md`
- `brandbook/tokens/tokens.json`
- `brandbook/notes/accessibility-checks.md`
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `Lockspire.Web.AdminRouter` already exposes the three Operate routes without detail routes or grouping routes.
- Existing Operate LiveViews already use `page_hero`, `pane`, `metric_grid`, `summary_stat`, `resource_list`, `dense_resource_row`, `status_badge`, `long_value`, and `empty_state`.
- `LogoutDeliveriesLive.Index` is the strongest current pattern for status pressure, channel, endpoint URL, attempts, last activity, and support note.
- `InteractionsLive.Index` and `DeviceAuthorizationsLive.Index` already use non-table dense rows and redacted handles, but Phase 123 can strengthen route-specific subtitles, pressure copy, age/expiry/poll context, and incident/empty-state language.
- `HtmlAssertions` already supports duplicate ID, ARIA target, generic CTA, denied text, and unsupported interactive control assertions.
- `AdminLab.Fixtures` already includes operations, dense data, warning/incident, theme, and reduced-motion fixture categories that can be extended if shared primitives change.

### Established Patterns

- Admin UI remains Phoenix function component based; LiveComponents are not needed for static read-only queue rows.
- LiveViews load and shape screen state; contexts/storage own durable domain behavior. Do not move domain rules into templates.
- URL state belongs in `handle_params/3` when the user can share or recover it. Phase 123 does not require new URL state unless implementation adds filters in scope, which is not currently recommended.
- Tables are intentionally avoided for Support/Operate scan flows unless sorting, pagination, comparison, or bulk action becomes the primary job.
- Redaction-safe handles, `long_value`, status badges, and text labels are the standard way to show durable identifiers without exposing secret material.

### Integration Points

- Route truth: `lib/lockspire/web/admin_router.ex`.
- Operate pages: `interactions_live/index.ex`, `device_authorizations_live/index.ex`, `logout_deliveries_live/index.ex`.
- Domain fields: `Interaction`, `DeviceAuthorization`, and `LogoutDelivery`.
- Storage reads: existing repository/Admin list paths; no new storage schema required.
- Proof: existing LiveView tests plus `HtmlAssertions`, design-system contract tests, component stress tests, and AdminLab fixtures.
- Docs: `docs/operator-admin.md` may need bounded maintainer/operator wording only if implementation changes visible workflow truth; `docs/supported-surface.md` should not be raised by this phase.
</code_context>

<specifics>
## Specific Ideas

- Recommended page spine:
  1. `page_hero` with `Operate` eyebrow and route-specific queue purpose.
  2. `pane` with read-only support-review subtitle.
  3. `metric_grid` status buckets.
  4. `resource_list` of `dense_resource_row` items.
  5. Empty states that say there is no queue work waiting for operator review.
- Row anatomy:
  - Logout delivery: status pressure, channel, endpoint, attempts, last activity, support note, redacted client, durable delivery id.
  - Interaction: status pressure, prompt, redacted client/account, created/age, expiry, durable interaction id.
  - Device authorization: status pressure, redacted client/account, redacted authorization handle, expiry, poll/next-poll or last-activity context.
- Microcopy should avoid generic CTAs and backend language. Prefer phrases like `Review interactions`, `Review device authorizations`, `Review logout deliveries`, `Waiting for login`, `Expired before completion`, `Retryable delivery failure`, and `Read-only support truth`.
- Do not ban status words such as `Retrying`, `Discarded`, `Approved`, or `Denied` when they describe state. Ban them only as actionable controls.
- External research anchors used during context gathering:
  - Phoenix function components and LiveView tests: `https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html`, `https://hexdocs.pm/phoenix_live_view/Phoenix.LiveViewTest.html`
  - Ecto redaction: `https://hexdocs.pm/ecto/Ecto.Schema.html`
  - Device flow: `https://datatracker.ietf.org/doc/html/rfc8628`
  - OIDC logout: `https://openid.net/specs/openid-connect-backchannel-1_0.html`, `https://openid.net/specs/openid-connect-frontchannel-1_0.html`
  - Embedded/job admin lessons: `https://hexdocs.pm/phoenix_live_dashboard`, `https://oban.pro/docs/web/overview.html`, `https://github.com/sidekiq/sidekiq/wiki/Error-Handling`
  - UI/accessibility lessons: `https://cloudscape.design/components/status-indicator/`, `https://cloudscape.design/patterns/resource-management/view/table-view/`, `https://www.gov.uk/service-manual`, `https://www.w3.org/WAI/ARIA/apg/`, `https://www.w3.org/WAI/WCAG22/Techniques/css/C39`
</specifics>

<deferred>
## Deferred Ideas

- A cross-queue `/admin/operate` cockpit or per-queue detail routes.
- Public/admin-mounted component lab, browser proof route, Storybook, theming API, or host component registry.
- Action-capable queue console with retry, discard, approve, deny, logout-now, requeue, pause/resume, or worker-control semantics.
- Storage-level projections/selects solely for UI polish, unless later leak tests prove full-domain reads are the main hazard.
- Responsive tables/data grids for Operate queues, unless a future phase makes sorting/filtering/pagination/column comparison the primary job.
- Public support-surface expansion for browser tooling, screenshots, traces, lab fixtures, or design-system internals.

### Reviewed Todos (not folded)

None.
</deferred>
