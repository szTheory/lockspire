# Phase 123: Operate Queue Flow Polish - Research

**Researched:** 2026-06-29  
**Domain:** Phoenix LiveView admin queue UI polish for read-only OAuth/OIDC operation surfaces  
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

The following locked scope, discretion, and deferred items are copied from `.planning/phases/123-operate-queue-flow-polish/123-CONTEXT.md`. [VERIFIED: 123-CONTEXT.md]

### Locked Decisions

#### Phase Boundary

Phase 123 polishes only the existing Operate queues: `/admin/interactions`, `/admin/device_authorizations`, and `/admin/logouts`. The work is page IA, queue scanability, redaction-safe data shaping, responsive/theme/focus/motion polish, and deterministic proof for OPERATE-01, OPERATE-02, and OPERATE-03.

This phase must not add new admin routes, public lab routes, browser-tooling product surface, host customization seams, retry/discard/approve/deny/logout-now/requeue controls, worker controls, protocol behavior, storage schema changes, or public support-contract expansion.

#### Route And Surface Boundary

- **D-01:** Polish only the existing Operate routes `/admin/interactions`, `/admin/device_authorizations`, and `/admin/logouts`, plus internal proof/tests. Do not add `/admin/operate`, detail routes, public lab/browser-proof routes, public theming/design-system routes, or new support-surface claims.
- **D-02:** Preserve the embedded Phoenix library shape: host apps mount and guard `Lockspire.Web.AdminRouter`; Lockspire owns protocol/operator state after the host-guarded router; the host owns staff authentication, MFA, roles, tenant policy, outer layout, branding, and access framing.
- **D-03:** Treat Operate queues as read-only support-review surfaces, not command centers. Defer retry, discard, approve, deny, logout-now, requeue, pause/resume, and worker-control affordances unless a later phase first designs backed Admin domain APIs, authorization semantics, audit logging, telemetry, and docs.

#### Queue Anatomy And Operator JTBD

- **D-04:** Use logout deliveries as the strongest existing scan pattern, then align interactions and device authorizations toward the same pressure-first anatomy where it improves scanability. Prefer the existing `page_hero`, `pane`, `metric_grid`, `summary_stat`, `resource_list`, `dense_resource_row`, `status_badge`, `long_value`, and `empty_state` primitives.
- **D-05:** Do not convert these queues to responsive tables or a data grid in Phase 123. The current job is fast incident/support scanning, not column comparison, sorting, bulk selection, or operator preference controls.
- **D-06:** Do not create `operate_queue_row` or `operate_queue_page` by default. A small internal function component is allowed only if duplication across the three queues becomes error-prone and the component preserves route-specific domain language through explicit attrs/slots.
- **D-07:** The Operate persona is a support engineer/provider operator who enters through Operate routes or overview pivots when authorization work looks stuck, device flow is pending/expired, or logout propagation failed/retried. The pages should answer: what is waiting, risky, expired, complete, or terminal; which client/account/endpoint explains it; what durable non-secret identifier supports follow-up; and what safe support/configuration pivot exists.

#### Applicable Data And Redaction

- **D-08:** Use queue-specific internal Admin Operate read models or tightly equivalent private helpers, backed by existing domain/storage reads. Keep shaping presentation-neutral and internal; do not create a new public Admin API or host extension seam for this polish phase.
- **D-09:** Logout delivery rows may show delivery id, redacted client handle, channel, endpoint URL, attempts, status pressure, HTTP status or failure class when useful, last activity, and support note. They must not expose logout token JTI as an operator-facing secret surrogate, Oban job IDs as the primary support concept, raw response bodies, cookies, endpoint secrets, live tenant hostnames, or SQL/worker internals.
- **D-10:** Interaction rows may show interaction id, redacted client/account handles, prompt, status pressure, created/age, and expiry. They must not expose authorization codes, request object internals, cookies, session tokens, nonce/state values, PKCE material, raw params, or raw sensitive return values.
- **D-11:** Device authorization rows may show redacted client/account handles, redacted durable authorization handle, status, expiry, poll interval/next poll or updated-at-derived activity. They must never expose raw `device_code`, `user_code`, hashes, raw `verification_handle`, authorization codes, token material, PKCE material, state, nonce, raw params, or backend storage details.
- **D-12:** Prefer `Lockspire.Redaction.handle/2`, `AdminComponents.long_value`, text status labels, semantic status badges, and redaction tests over raw identifiers. If sensitive storage fields are touched, preserve or add Ecto `redact: true` and `load_in_query: false` where appropriate.

#### UI, UX, Brand, And Microcopy

- **D-13:** Keep copy calm, exact, low-anxiety, and consequence-oriented. Use Lockspire domain nouns: operator, account, client, interaction, device authorization, logout delivery, endpoint, status, expiry, attempts, support note. Avoid backend-leaking terms such as SQL row, Oban job, worker internals, raw hash, database failure, code material, or request object unless the operator truly needs them.
- **D-14:** Enforce these design pillars for changed Operate pages: accessibility, responsive reflow, information architecture, security/redaction, theme parity, reduced-motion safety, visible focus, performance/tooling weight, maintainability, docs truth, maintainer DX, operator psychology, brand consistency, microcopy quality, and component fit.
- **D-15:** Use the current `brandbook/` as visual truth where it conflicts with older prompt-era guidance. Continue using shipped `--ls-*` tokens, Signal Cyan/Deep Cyan contrast rules, text status labels, no color-only state, focus rings that are never removed, and reduced-motion behavior that neutralizes nonessential transitions.
- **D-16:** Hide backend implementation details behind operator-facing JTBD. The UI should expose what the operator can safely know or do: observe, correlate, and pivot. It should not reveal the internal mechanism unless the mechanism is the operator's actual support object.

#### Verification And DX

- **D-17:** Prove OPERATE-02 with a deterministic source/API fence: no new Operate mutation delegates in `Lockspire.Admin`, no `phx-click`/`phx-submit` command controls on the three queues, and no actionable retry/discard/approve/deny/logout-now/requeue/worker-control affordances.
- **D-18:** Use focused LiveView/rendered HTML tests with existing `HtmlAssertions`/LazyHTML helpers as the primary proof. Cover empty, dense, incident, expired, retryable, discarded, skipped, rendered, completed, long-value, redaction, no-table-overload, no-unsupported-action, duplicate-ID, ARIA target, generic-CTA, theme-token, and reduced-motion claims where changed.
- **D-19:** Expand `AdminLab`/component stress fixtures only when this phase changes shared row/status/long-value primitives. Keep lab proof internal and maintainer-only.
- **D-20:** Browser/axe/manual evidence is supplemental when CSS/layout changes are material; it must stay maintainer-only, redaction-safe, and outside Hex/runtime/public support surface. Do not make screenshots or browser reports the primary assertion mechanism.

#### Ecosystem Lessons Applied

- **D-21:** Copy Phoenix LiveDashboard and Oban Web's embedded-router lesson: admin/operator surfaces can be first-class while still being host-mounted and protected by the host app.
- **D-22:** Copy Oban Web and Sidekiq's command-console lesson only when backed by explicit action APIs and access semantics. For Phase 123, take their status/pressure visibility lesson, not their mutation controls.
- **D-23:** Learn from Keycloak-style breadth that broad admin/theming/support surfaces become a long-term product and semver burden. Lockspire should stay narrow, embedded, and explicit.
- **D-24:** Learn from GOV.UK, Cloudscape, GitLab, WAI-ARIA, and WCAG: start from user needs, make status compact and textual, avoid false affordances, use conventional accessible components, support reflow and reduced motion, and make dense operational UI scannable without hiding risk.

### the agent's Discretion

Planner may choose exact helper names, test organization, fixture builders, and whether queue-specific shaping lives in private LiveView helpers or a narrow internal read-model module. Preserve the route boundary, read-only truth, redaction posture, existing-component preference, route-specific domain language, and deterministic proof stack.

### Deferred Ideas (OUT OF SCOPE)

- A cross-queue `/admin/operate` cockpit or per-queue detail routes.
- Public/admin-mounted component lab, browser proof route, Storybook, theming API, or host component registry.
- Action-capable queue console with retry, discard, approve, deny, logout-now, requeue, pause/resume, or worker-control semantics.
- Storage-level projections/selects solely for UI polish, unless later leak tests prove full-domain reads are the main hazard.
- Responsive tables/data grids for Operate queues, unless a future phase makes sorting/filtering/pagination/column comparison the primary job.
- Public support-surface expansion for browser tooling, screenshots, traces, lab fixtures, or design-system internals.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| OPERATE-01 | Operator can scan interactions, device authorizations, and logout delivery queues by status pressure, channel/prompt, client, subject, age, expiry or last activity, and durable non-secret identifiers without table-like overload. [VERIFIED: .planning/REQUIREMENTS.md] | Existing queue LiveViews already use `metric_grid`, `summary_stat`, `resource_list`, `dense_resource_row`, `status_badge`, and `long_value`; logout deliveries have the strongest pressure/support-note pattern to align from. [VERIFIED: codebase] |
| OPERATE-02 | Operate queue pages truthfully remain read-only unless a backed domain API exists; no retry, discard, approve, deny, or worker-control UI is introduced by polish alone. [VERIFIED: .planning/REQUIREMENTS.md] | Current Operate LiveViews have no `handle_event/3`, `phx-click`, or `phx-submit` command controls, and tests already assert unsupported control text is absent. [VERIFIED: codebase] |
| OPERATE-03 | Operate queue pages remain usable at mobile widths, in light/dark/system themes, with reduced motion, keyboard focus, empty states, dense states, long URLs, and incident states. [VERIFIED: .planning/REQUIREMENTS.md] | Admin CSS already defines theme modes, reduced-motion rules, responsive dense-row stacking, long-value wrapping, and focus rings; tests can extend existing design-system contracts and route render assertions. [VERIFIED: codebase] |
</phase_requirements>

## Summary

Phase 123 should be planned as a narrow polish pass over exactly `Lockspire.Web.Live.Admin.InteractionsLive.Index`, `Lockspire.Web.Live.Admin.DeviceAuthorizationsLive.Index`, and `Lockspire.Web.Live.Admin.LogoutDeliveriesLive.Index`, plus focused tests and only conditional shared component/CSS fixture work. [VERIFIED: 123-CONTEXT.md] [VERIFIED: codebase]

The existing code already has the right structural primitives and route boundary: `AdminRouter` exposes `/interactions`, `/device_authorizations`, and `/logouts`; each page renders through the admin shell with Operate navigation; and the current rows are non-table dense resource rows. [VERIFIED: codebase] Logout deliveries currently provide the best model because they include status pressure, channel, endpoint, attempts, last activity, and support note copy; interactions and device authorizations should be aligned toward that anatomy without erasing route-specific nouns. [VERIFIED: codebase] [VERIFIED: 123-CONTEXT.md]

The most important planning constraint is the read-only truth fence. [VERIFIED: 123-CONTEXT.md] There is no existing in-scope Admin mutation API for retry, discard, approve, deny, logout-now, requeue, pause/resume, or worker control on these pages, so the plan must not create UI affordances for those actions. [VERIFIED: codebase] [VERIFIED: 123-CONTEXT.md]

**Primary recommendation:** Use page-local private helpers or a narrow internal read model to shape queue rows, extend the three existing LiveView tests for state/redaction/no-action/no-table proof, and touch shared components/CSS/AdminLab only if row wrapping or status semantics truly need shared changes. [VERIFIED: codebase] [VERIFIED: 123-CONTEXT.md]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|--------------|----------------|-----------|
| Host-mounted admin route containment | Frontend Server (Phoenix router/LiveView) | Host app auth boundary | `Lockspire.Web.AdminRouter` owns route truth after the host has guarded the mount; staff auth/MFA/roles remain host-owned. [VERIFIED: AGENTS.md] [VERIFIED: docs/operator-admin.md] |
| Queue state retrieval | API / Backend | Database / Storage | Current pages read durable interaction/device/logout state through existing `Repository` or `Lockspire.Admin` list paths; Phase 123 should not add storage schema or public APIs. [VERIFIED: codebase] [VERIFIED: 123-CONTEXT.md] |
| Queue row shaping and pressure copy | Frontend Server (LiveView) | API / Backend | The existing LiveViews already transform domain structs into rendered summaries; shaping must remain presentation-neutral and internal. [VERIFIED: codebase] [VERIFIED: 123-CONTEXT.md] |
| Dense row/status/long-value rendering | Browser / Client HTML+CSS generated by LiveView | Frontend Server components | `AdminComponents` and `admin_css.ex` own reusable markup/classes for dense rows, badges, wrapping, themes, focus, and reduced motion. [VERIFIED: codebase] |
| Redaction and safe identifiers | API / Backend helper | Frontend Server display | `Lockspire.Redaction.handle/2` produces durable non-secret handles; queue rows should pass sensitive identifiers through it before rendering. [VERIFIED: codebase] [VERIFIED: 123-CONTEXT.md] |
| Proof and guardrails | Test tier | Maintainer-only lab | Existing LiveView tests, LazyHTML `HtmlAssertions`, design-system contract tests, and AdminLab fixtures are the primary evidence path; browser evidence is supplemental only. [VERIFIED: codebase] [VERIFIED: 123-CONTEXT.md] |

## Project Constraints (from AGENTS.md)

- Preserve Lockspire as an embedded OAuth/OIDC authorization server companion library for Phoenix/Elixir, not a standalone auth service or Sigra module. [VERIFIED: AGENTS.md]
- Keep host seams explicit and narrow: account resolution, claims, login redirects, branding, and product policy belong to the host app. [VERIFIED: AGENTS.md]
- Keep strong internal boundaries between protocol core, storage, generators, Plug/Phoenix integration, and LiveView/admin surfaces. [VERIFIED: AGENTS.md]
- Do not broaden v1 into SAML, LDAP/AD federation, hosted auth, or a full CIAM suite. [VERIFIED: AGENTS.md]
- Preserve security defaults including PKCE S256, exact redirect URI validation, hashed client secrets, short-lived single-use codes, refresh rotation, no implicit flow, no `alg=none`, and strong redaction. [VERIFIED: AGENTS.md]
- Use the existing Phoenix/LiveView/Ecto/PostgreSQL/Bandit/Oban/OpenTelemetry stack; Phase 123 should not add public theming, Storybook, browser tooling, or fake operation controls. [VERIFIED: AGENTS.md] [VERIFIED: 123-CONTEXT.md]

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Phoenix | `1.8.7` locked; `1.8.8` recent Hex release on 2026-06-10. [VERIFIED: mix.lock] [VERIFIED: Hex registry] | Router/shell foundation for embedded admin routes. [VERIFIED: codebase] | Existing stack and `AdminRouter` route truth use Phoenix. [VERIFIED: AGENTS.md] [VERIFIED: codebase] |
| Phoenix LiveView | `1.1.30` locked; `1.2.4` recent Hex release on 2026-06-29. [VERIFIED: mix.lock] [VERIFIED: Hex registry] | Server-rendered admin pages and function components. [VERIFIED: codebase] | Existing Operate pages and `AdminComponents` use LiveView/function components; official docs support attrs/slots and deterministic component rendering. [VERIFIED: codebase] [CITED: https://phoenix-live-view.hexdocs.pm/1.1.30/Phoenix.Component.html] |
| Ecto SQL | `3.13.5` locked; `3.14.0` recent Hex release on 2026-05-19. [VERIFIED: mix.lock] [VERIFIED: Hex registry] | Storage access and schema/query layer for queue state. [VERIFIED: codebase] | Existing repositories and test setup use Ecto/PostgreSQL; Ecto field options support redaction/loading boundaries if sensitive fields are touched. [VERIFIED: codebase] [CITED: https://ecto.hexdocs.pm/3.13.5/Ecto.Schema.html] |
| PostgreSQL/Postgrex | PostgreSQL CLI `14.17`; `postgrex` `0.22.2` locked and released 2026-05-12. [VERIFIED: environment probe] [VERIFIED: mix.lock] [VERIFIED: Hex registry] | Test database and storage adapter. [VERIFIED: config/test.exs] | Lockspire storage is Postgres-backed through `Lockspire.TestRepo` and repository modules. [VERIFIED: codebase] |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| LazyHTML | `0.1.11` locked and released 2026-04-02. [VERIFIED: mix.lock] [VERIFIED: Hex registry] | HTML parsing/querying in proof helpers. [VERIFIED: codebase] | Use through `Lockspire.Web.AdminProof.HtmlAssertions`; do not add browser-only proof for primary assertions. [VERIFIED: codebase] [VERIFIED: 123-CONTEXT.md] |
| Oban | `2.21.1` locked and released 2026-03-26. [VERIFIED: mix.lock] [VERIFIED: Hex registry] | Existing logout delivery worker substrate. [VERIFIED: mix.lock] | Treat as backend delivery mechanism only; do not expose worker controls in Phase 123. [VERIFIED: 123-CONTEXT.md] |
| Bandit | `1.11.1` locked and released 2026-05-13. [VERIFIED: mix.lock] [VERIFIED: Hex registry] | Phoenix endpoint server dependency. [VERIFIED: mix.exs] | No direct Phase 123 work expected. [VERIFIED: codebase] |
| OpenTelemetry API | `1.5.0` locked and released 2025-10-17. [VERIFIED: mix.lock] [VERIFIED: Hex registry] | Telemetry API dependency. [VERIFIED: mix.exs] | No new telemetry surface is in scope unless a later backed API phase designs it. [VERIFIED: 123-CONTEXT.md] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Existing dense resource rows | Responsive tables/data grid | Rejected for Phase 123 because the locked job is support scanning, not column comparison/sorting/bulk selection. [VERIFIED: 123-CONTEXT.md] |
| Page-local helpers | New `operate_queue_row` or `operate_queue_page` component | Default against new component; allow only if duplication becomes error-prone and explicit attrs/slots preserve route-specific language. [VERIFIED: 123-CONTEXT.md] |
| Rendered source tests | Browser/axe/screenshot proof as primary gate | Rejected as primary proof; browser evidence is supplemental and maintainer-only when CSS/layout changes are material. [VERIFIED: 123-CONTEXT.md] |

**Installation:**

```bash
# No new packages are recommended for Phase 123.
```

**Version verification:** Existing dependency versions were verified from `mix.lock`, `mix.exs`, and `mix hex.info` output on 2026-06-29. [VERIFIED: mix.lock] [VERIFIED: Hex registry]

## Package Legitimacy Audit

No external packages should be installed for Phase 123, so the package legitimacy gate is not triggered. [VERIFIED: 123-CONTEXT.md]

| Package | Registry | Age | Downloads | Source Repo | Verdict | Disposition |
|---------|----------|-----|-----------|-------------|---------|-------------|
| none | n/a | n/a | n/a | n/a | n/a | No install planned. [VERIFIED: 123-CONTEXT.md] |

**Packages removed due to [SLOP] verdict:** none. [VERIFIED: 123-CONTEXT.md]  
**Packages flagged as suspicious [SUS]:** none. [VERIFIED: 123-CONTEXT.md]

## Architecture Patterns

### System Architecture Diagram

```mermaid
flowchart TD
  HostGuard[Host app operator auth/MFA/roles] --> AdminRouter[Lockspire.Web.AdminRouter]
  AdminRouter --> Interactions[/admin/interactions LiveView]
  AdminRouter --> Devices[/admin/device_authorizations LiveView]
  AdminRouter --> Logouts[/admin/logouts LiveView]
  Interactions --> InteractionRead[Repository.list_interactions]
  Devices --> DeviceRead[Admin.list_device_authorizations]
  Logouts --> LogoutRead[Repository.list_all_logout_deliveries]
  InteractionRead --> InteractionShape[Page-local pressure/redaction helpers]
  DeviceRead --> DeviceShape[Page-local pressure/redaction helpers]
  LogoutRead --> LogoutShape[Existing delivery pressure/support note helpers]
  InteractionShape --> Components[AdminComponents dense_resource_row/status_badge/long_value]
  DeviceShape --> Components
  LogoutShape --> Components
  Components --> CSS[admin_css tokens, wrapping, themes, focus, reduced motion]
  CSS --> Operator[Read-only operator support review]
  Operator --> Proof[LiveView tests + HtmlAssertions + conditional design contracts]
```

The diagram reflects current route/data flow plus the recommended shaping/proof flow; it does not add new routes, storage APIs, or mutation controls. [VERIFIED: codebase] [VERIFIED: 123-CONTEXT.md]

### Recommended Project Structure

```text
lib/lockspire/web/live/admin/
├── interactions_live/index.ex              # Align interaction row pressure, age, prompt, expiry copy.
├── device_authorizations_live/index.ex     # Align device row pressure, poll/expiry/activity context, redacted handle.
└── logout_deliveries_live/index.ex         # Preserve strongest pattern; add only missing safe status/failure context if needed.

lib/lockspire/web/components/
└── admin_components.ex                     # Touch only if shared dense row/status/long_value behavior needs a real shared change.

lib/lockspire/web/
└── admin_css.ex                            # Touch only if rendered proof shows row wrapping/theme/focus gaps.

test/lockspire/web/live/admin/
├── interactions_live_test.exs              # Add dense/expired/long/redaction/no-action proofs.
├── device_authorizations_live_test.exs     # Add poll/expiry/incident/long/redaction/no-action proofs.
├── logout_deliveries_live_test.exs         # Add retryable/discarded/skipped/rendered/completed/long proofs.
├── design_system_contract_test.exs         # Extend only for shared CSS/component contract changes.
└── design_system_component_stress_test.exs # Extend only if AdminLab shared primitives change.

test/support/lockspire/web/admin_lab/
├── fixtures.ex                             # Extend only for shared primitive stress states.
└── stress_surface.ex                       # Extend only for shared primitive stress states.
```

This structure follows current files discovered in the repo and the locked phase boundary. [VERIFIED: codebase] [VERIFIED: 123-CONTEXT.md]

### Pattern 1: Logout Delivery As Strongest Queue Anatomy

**What:** Use a pressure-first row with title, status subtitle, durable id, redacted client, channel, endpoint URL, attempts, last activity, and support note. [VERIFIED: codebase]  
**When to use:** Use this as the reference for `/admin/logouts` and as the alignment target for interactions/device authorizations where the fields exist safely. [VERIFIED: 123-CONTEXT.md]

**Example:**

```elixir
# Source: lib/lockspire/web/live/admin/logout_deliveries_live/index.ex [VERIFIED: codebase]
<AdminComponents.dense_resource_row
  title={"#{channel_label(delivery.channel)} logout delivery"}
  subtitle={delivery_pressure(delivery)}
>
  <:meta>
    <span>Delivery <AdminComponents.long_value value={delivery.delivery_id} kind={:id} /></span>
    <span>Client <AdminComponents.long_value value={redacted_handle(:client, delivery.client_id)} kind={:id} /></span>
    <span>Endpoint <AdminComponents.long_value value={delivery.target_uri} kind={:url} /></span>
    <span>Attempts {delivery.attempt_count}</span>
    <span class="lockspire-admin-dense-resource-row__note">{delivery_support_note(delivery)}</span>
  </:meta>
  <:status>
    <AdminComponents.status_badge status={delivery.status} />
  </:status>
</AdminComponents.dense_resource_row>
```

### Pattern 2: Route-Specific Private Helpers Before New Shared Components

**What:** Keep helpers like `redacted_handle/2`, `formatted_timestamp/1`, `prompt_label/1`, pressure-copy functions, and count functions private to each LiveView unless duplication becomes error-prone. [VERIFIED: codebase] [VERIFIED: 123-CONTEXT.md]  
**When to use:** Use for queue-specific status pressure and support copy because route nouns differ across interaction, device authorization, and logout delivery. [VERIFIED: 123-CONTEXT.md]

**Planning note:** Device authorizations currently expose `effective_poll_interval_seconds`, `next_poll_allowed_at`, and `expires_at`, but the current domain struct does not expose `inserted_at` or `updated_at`, so "last activity" for devices should come from available lifecycle/poll fields unless the planner explicitly chooses an internal read model. [VERIFIED: codebase]

### Pattern 3: Rendered HTML Proof With LazyHTML Helpers

**What:** Use focused LiveView tests plus `HtmlAssertions` for duplicate IDs, ARIA targets, generic CTA text, denied sensitive text, and unsupported interactive controls. [VERIFIED: codebase]  
**When to use:** Use this for every changed Operate route; add design contract tests only if shared primitives or CSS change. [VERIFIED: 123-CONTEXT.md]

**Example:**

```elixir
# Source: test/lockspire/web/live/admin/interactions_live_test.exs and HtmlAssertions [VERIFIED: codebase]
HtmlAssertions.assert_no_duplicate_ids(page_html)
HtmlAssertions.assert_describedby_targets_exist(page_html)
HtmlAssertions.assert_no_generic_cta_text(page_html)
HtmlAssertions.assert_no_interactive_controls(page_html,
  text: ["Retry", "Discard", "Approve", "Deny", "Logout now", "Worker control", "Requeue"]
)
refute page_html =~ "<table"
refute page_html =~ "phx-click"
refute page_html =~ "phx-submit"
```

### Anti-Patterns to Avoid

- **Command-center creep:** Adding controls for retry, discard, approve, deny, logout-now, requeue, pause/resume, or worker control would violate the locked read-only boundary. [VERIFIED: 123-CONTEXT.md]
- **Backend leakage:** Showing raw `device_code`, `user_code`, hashes, raw `verification_handle`, `logout_token_jti`, `oban_job_id`, raw request/object internals, cookies, state/nonce, PKCE material, raw responses, SQL rows, or worker internals would violate redaction and operator-language constraints. [VERIFIED: 123-CONTEXT.md] [VERIFIED: codebase]
- **Table-shaped overload:** Converting queue rows into tables/data grids conflicts with the locked support-scanning job and mobile requirements. [VERIFIED: 123-CONTEXT.md]
- **Unnecessary shared abstraction:** Creating `operate_queue_row` or `operate_queue_page` by default conflicts with D-06 and risks flattening route-specific language. [VERIFIED: 123-CONTEXT.md]
- **Browser proof as product surface:** Screenshots, browser reports, and lab surfaces must remain maintainer-only and outside public support/Hex/runtime surface. [VERIFIED: 123-CONTEXT.md] [VERIFIED: docs/operator-admin.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Queue row layout | Custom page-local table/grid system | `resource_list` + `dense_resource_row` + existing CSS | Existing primitives already provide wrapping, mobile stacking, status slot, meta slot, and no-table proof. [VERIFIED: codebase] |
| Status visuals | Color-only badges or bespoke status CSS | `status_badge` with text labels and existing status tones | WCAG requires non-color state signals, and current badge metadata covers Operate statuses including pending, attempted, retryable, discarded, succeeded, rendered, skipped, approved, consumed, denied, and expired. [VERIFIED: codebase] [CITED: https://www.w3.org/WAI/WCAG22/Understanding/use-of-color.html] |
| Long identifier/URL wrapping | Manual truncation or fixed-width CSS | `long_value` with `kind: :id`, `:url`, `:timestamp`, or `:text` | Existing CSS sets `overflow-wrap: anywhere` and `word-break: break-word`. [VERIFIED: codebase] |
| Redacted durable handles | Custom masking/truncation | `Lockspire.Redaction.handle/2` | Existing helper generates stable non-secret handles and tests already use redaction assertions. [VERIFIED: codebase] |
| Read-only action proof | Manual visual review only | `HtmlAssertions.assert_no_interactive_controls/2` plus source grep fences | Existing helper checks `phx-click`, `phx-submit`, and unsupported control text deterministically. [VERIFIED: codebase] |
| Function component mechanics | New UI framework or LiveComponent for static rows | Phoenix function components with attrs/slots | Phoenix LiveView official docs support reusable function components with `attr/3` and `slot/3`; current admin UI uses this pattern. [CITED: https://phoenix-live-view.hexdocs.pm/1.1.30/Phoenix.Component.html] [VERIFIED: codebase] |

**Key insight:** Phase 123 is not missing infrastructure; it is missing enough route-specific pressure copy, safe field selection, and state coverage in tests for the existing infrastructure. [VERIFIED: codebase] [VERIFIED: 123-CONTEXT.md]

## Common Pitfalls

### Pitfall 1: Unsupported Actions Sneak In Through Helpful Copy

**What goes wrong:** Status words like retryable, denied, discarded, or approved become active-looking buttons, links, or command labels. [VERIFIED: 123-CONTEXT.md]  
**Why it happens:** Queue status terms overlap with tempting operator commands, but the current phase has no backed action semantics. [VERIFIED: 123-CONTEXT.md]  
**How to avoid:** Use status badges and support notes for state, never action controls; add source/rendered tests for banned controls and `phx-*` command bindings. [VERIFIED: codebase] [VERIFIED: 123-CONTEXT.md]  
**Warning signs:** New `handle_event/3`, `Admin.retry_*`, `Admin.discard_*`, `Admin.approve_*`, `Admin.deny_*`, `phx-click`, or `phx-submit` appears in Operate queue files. [VERIFIED: codebase]

### Pitfall 2: Device Authorization "Last Activity" Is Not Currently a Simple Field

**What goes wrong:** The planner asks implementation to show `updated_at` on device authorization rows, but the current `DeviceAuthorization` domain struct does not carry timestamps from the Ecto record. [VERIFIED: codebase]  
**Why it happens:** `DeviceAuthorizationRecord` has timestamps, but `to_domain/2` maps lifecycle and poll fields without `inserted_at`/`updated_at`. [VERIFIED: codebase]  
**How to avoid:** Use `effective_poll_interval_seconds`, `next_poll_allowed_at`, `approved_at`, `denied_at`, `consumed_at`, `expired_at`, and `expires_at`, or explicitly plan a narrow internal read-model change if updated-at-derived activity is required. [VERIFIED: codebase] [VERIFIED: 123-CONTEXT.md]  
**Warning signs:** UI code reaches for `auth.updated_at` or raw storage fields directly. [VERIFIED: codebase]

### Pitfall 3: Redaction Regressions From "Useful" Queue Evidence

**What goes wrong:** Raw device codes, user codes, hashes, verification handles, logout token JTIs, Oban IDs, auth request internals, state/nonce, PKCE material, or raw response bodies appear in HTML/tests/docs. [VERIFIED: 123-CONTEXT.md]  
**Why it happens:** The domain/storage structs contain sensitive or backend-internal fields adjacent to safe fields. [VERIFIED: codebase]  
**How to avoid:** Shape rows from the explicit allowed fields in D-09 through D-12 and assert forbidden substrings are absent in rendered HTML. [VERIFIED: 123-CONTEXT.md] [VERIFIED: codebase]  
**Warning signs:** Tests insert realistic token-looking strings, raw hashes, endpoint secrets, or production-looking hostnames. [VERIFIED: 123-CONTEXT.md]

### Pitfall 4: Dense Rows Become A Table By Another Name

**What goes wrong:** Rows accumulate too many same-weight metadata chips, causing squashed content and weak mobile scanning. [VERIFIED: .planning/REQUIREMENTS.md]  
**Why it happens:** Queue requirements include many fields, but the operator job is pressure-first triage rather than column comparison. [VERIFIED: 123-CONTEXT.md]  
**How to avoid:** Keep title/subtitle/status first, group secondary metadata, use `long_value`, and put support notes in a full-width note style when needed. [VERIFIED: codebase]  
**Warning signs:** New fixed widths, `white-space: nowrap`, table markup, or page-level overflow appears. [VERIFIED: codebase]

### Pitfall 5: Brittle Age Copy In Tests

**What goes wrong:** Tests assert exact minute-level age strings against wall-clock `DateTime.utc_now/0`, causing flake near minute boundaries. [ASSUMED]  
**Why it happens:** Phase 123 asks for age pressure, but current LiveViews mostly render timestamps, not relative age strings. [VERIFIED: codebase] [VERIFIED: .planning/REQUIREMENTS.md]  
**How to avoid:** Prefer deterministic helpers with fixed `now` in tests, or assert stable category copy such as "Created", "Expires", "Last activity", "Waiting for login", or "Expired before completion" rather than exact elapsed minutes. [ASSUMED]  
**Warning signs:** Tests depend on current wall-clock deltas. [ASSUMED]

## Code Examples

### Status Pressure Helper Shape

```elixir
# Source: lib/lockspire/web/live/admin/logout_deliveries_live/index.ex [VERIFIED: codebase]
defp delivery_pressure(%{status: status}) when status in [:pending, :enqueued],
  do: "Waiting for the protocol worker to attempt delivery."

defp delivery_pressure(%{status: :retryable}),
  do: "Retryable failure; verify the RP endpoint and preserve the delivery record."

defp delivery_pressure(%{status: status}) when status in [:discarded, :skipped],
  do: "Terminal queue outcome; use the record as support truth."
```

### Redacted Handle Pattern

```elixir
# Source: existing Operate LiveViews [VERIFIED: codebase]
defp redacted_handle(_type, nil), do: "Not recorded"
defp redacted_handle(type, value), do: Redaction.handle(type, value)
```

### LiveViewTest Rendered HTML Pattern

```elixir
# Source: Phoenix LiveViewTest docs and current tests [CITED: https://phoenix-live-view.hexdocs.pm/1.1.30/Phoenix.LiveViewTest.html] [VERIFIED: codebase]
assert {:ok, _view, html} = live(conn_for_admin(), "/admin/device_authorizations")
page_html = Regex.replace(~r/<style>.*?<\/style>/s, html, "")

HtmlAssertions.assert_no_duplicate_ids(page_html)
HtmlAssertions.assert_no_interactive_controls(page_html, text: unsupported_queue_control_text())
```

### Ecto Sensitive Field Safety If Storage Is Touched

```elixir
# Source: Ecto.Schema docs; use only if Phase 123 touches sensitive Ecto fields. [CITED: https://ecto.hexdocs.pm/3.13.5/Ecto.Schema.html]
field :secret_value, :string, redact: true, load_in_query: false
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Raw table/metadata inventory for admin weak spots | Page-first route scorecards plus dense rows and deterministic guardrails | Phase 121/122, 2026-06-28. [VERIFIED: 121-ROUTE-SCORECARDS.md] [VERIFIED: 122-RESEARCH.md] | Plan each queue by persona/JTBD, not by database row shape. [VERIFIED: 121-ROUTE-SCORECARDS.md] |
| Browser screenshots as de facto proof | Source/rendered guardrails as primary proof, browser/manual evidence supplemental | Phase 120/121 decisions. [VERIFIED: .planning/STATE.md] | Keep Phase 123 proof repo-native and maintainer-only. [VERIFIED: 123-CONTEXT.md] |
| Generic admin actions | Verb-plus-noun, backed-action labels only | Phase 122 UI contract. [VERIFIED: 122-UI-SPEC.md] | Use "Review interactions/device authorizations/logout deliveries" and avoid generic/unsupported controls. [VERIFIED: 123-CONTEXT.md] |
| Color-only status | Textual `status_badge` labels plus semantic tones | Phase 118/121 contracts and WCAG. [VERIFIED: codebase] [CITED: https://www.w3.org/WAI/WCAG22/Understanding/use-of-color.html] | Incident/retry/expired states must remain understandable in all themes. [VERIFIED: .planning/REQUIREMENTS.md] |

**Deprecated/outdated:**

- Adding a public lab, Storybook, or browser-proof route for this phase is out of scope and would expand supported surface. [VERIFIED: 123-CONTEXT.md]
- Treating Operate queues as worker consoles is out of scope until a later phase designs backed APIs, authorization, audit, telemetry, and docs. [VERIFIED: 123-CONTEXT.md]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Exact relative age strings can make tests brittle unless helpers accept fixed time or assertions stay category-level. [ASSUMED] | Common Pitfalls | Planner may over-specify wall-clock assertions and create flaky tests. |

## Open Questions

1. **Should Phase 123 introduce an internal read-model module or keep private LiveView helpers?**  
   - What we know: D-08 allows queue-specific internal read models or tightly equivalent private helpers. [VERIFIED: 123-CONTEXT.md]  
   - What's unclear: The implementation may decide duplication is tolerable after writing the three row-shaping helpers. [VERIFIED: 123-CONTEXT.md]  
   - Recommendation: Start with page-local private helpers; promote only if duplication becomes error-prone across all three pages. [VERIFIED: 123-CONTEXT.md]
2. **Should logout rows show HTTP status or failure class?**  
   - What we know: D-09 allows HTTP status or failure class when useful, and `LogoutDelivery` carries `http_status` and `failure_reason`. [VERIFIED: 123-CONTEXT.md] [VERIFIED: codebase]  
   - What's unclear: Current UI does not show either field, and raw response bodies remain forbidden. [VERIFIED: codebase] [VERIFIED: 123-CONTEXT.md]  
   - Recommendation: Add concise failure class/status only when tests prove retryable/incident state is clearer, and never render raw response content. [VERIFIED: 123-CONTEXT.md]
3. **Is browser/manual evidence needed in Phase 123 or can it defer to Phase 125?**  
   - What we know: Phase 123 success criteria mention rendered/source proof, and D-20 says browser/axe/manual evidence is supplemental when CSS/layout changes are material. [VERIFIED: ROADMAP.md] [VERIFIED: 123-CONTEXT.md]  
   - What's unclear: Whether implementation will touch CSS enough to require a browser note. [VERIFIED: codebase]  
   - Recommendation: Plan deterministic tests as required; add a maintainer-only browser/manual checkpoint only if CSS/layout changes are non-trivial. [VERIFIED: 123-CONTEXT.md]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Elixir | Mix/ExUnit/LiveView tests | yes | 1.19.5 with Erlang/OTP 28. [VERIFIED: environment probe] | none needed. |
| Mix | Test aliases and dependency tasks | yes | 1.19.5. [VERIFIED: environment probe] | none needed. |
| PostgreSQL client/local DB target | Ecto sandbox tests | yes | `psql` 14.17. [VERIFIED: environment probe] | Configure `LOCKSPIRE_TEST_DB_*` env vars if local default DB is unavailable. [VERIFIED: config/test.exs] |
| Hex registry access | Existing dependency version verification | yes | `mix hex.info` returned package metadata. [VERIFIED: Hex registry] | Use `mix.lock` if offline. [VERIFIED: mix.lock] |
| Context7 CLI | Preferred documentation lookup fallback | no | `ctx7` not found. [VERIFIED: environment probe] | Used official HexDocs/W3C URLs directly. [CITED: https://phoenix-live-view.hexdocs.pm/1.1.30/Phoenix.Component.html] |

**Missing dependencies with no fallback:** none for planning/research. [VERIFIED: environment probe]  
**Missing dependencies with fallback:** Context7 CLI is missing; official docs were fetched directly. [VERIFIED: environment probe] [CITED: https://phoenix-live-view.hexdocs.pm/1.1.30/Phoenix.Component.html]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit + Phoenix.LiveViewTest + LazyHTML assertions. [VERIFIED: mix.exs] [VERIFIED: codebase] |
| Config file | `config/test.exs` uses `Lockspire.TestRepo` with Ecto SQL sandbox. [VERIFIED: config/test.exs] |
| Quick run command | `MIX_ENV=test mix test test/lockspire/web/live/admin/interactions_live_test.exs test/lockspire/web/live/admin/device_authorizations_live_test.exs test/lockspire/web/live/admin/logout_deliveries_live_test.exs` [VERIFIED: command run] |
| Full suite command | `MIX_ENV=test mix test.fast` [VERIFIED: mix.exs] |

### Phase Requirements -> Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| OPERATE-01 | Rows expose status pressure, channel/prompt, client, subject, age/expiry/activity, attempts/endpoint/support note where applicable, and durable non-secret identifiers without table overload. [VERIFIED: .planning/REQUIREMENTS.md] | LiveView render tests plus route-specific fixtures | `MIX_ENV=test mix test test/lockspire/web/live/admin/interactions_live_test.exs test/lockspire/web/live/admin/device_authorizations_live_test.exs test/lockspire/web/live/admin/logout_deliveries_live_test.exs` | yes. [VERIFIED: codebase] |
| OPERATE-02 | No unsupported retry/discard/approve/deny/logout-now/requeue/worker command UI or new Operate mutation delegates. [VERIFIED: .planning/REQUIREMENTS.md] | Source grep guard plus rendered HTML assertions | Same quick command plus a design/source contract if implementation adds shared fences. [VERIFIED: codebase] | yes; likely needs extension. [VERIFIED: codebase] |
| OPERATE-03 | Empty, dense, incident, expired, retryable, discarded, skipped, rendered, completed, long-value, theme, focus, mobile, and reduced-motion states remain understandable. [VERIFIED: .planning/REQUIREMENTS.md] | LiveView state tests plus conditional design-system/component-stress tests | Quick command plus `MIX_ENV=test mix test test/lockspire/web/live/admin/design_system_contract_test.exs test/lockspire/web/live/admin/design_system_component_stress_test.exs` if shared CSS/components change. [VERIFIED: codebase] | yes. [VERIFIED: codebase] |

### Sampling Rate

- **Per task commit:** Run the three focused Operate LiveView tests. [VERIFIED: command run]
- **Per wave merge:** Run focused Operate tests plus design-system contract/stress tests if shared primitives/CSS/AdminLab fixtures change. [VERIFIED: codebase] [VERIFIED: 123-CONTEXT.md]
- **Phase gate:** Run `MIX_ENV=test mix test.fast` before verification. [VERIFIED: mix.exs]

### Wave 0 Gaps

- [ ] Extend `test/lockspire/web/live/admin/interactions_live_test.exs` for pressure subtitles, prompt, subject/client redaction, created/age/expiry context, expired/completed/denied states, long interaction id/client/account values, no table, and no unsupported controls. [VERIFIED: codebase] [VERIFIED: 123-CONTEXT.md]
- [ ] Extend `test/lockspire/web/live/admin/device_authorizations_live_test.exs` for pressure subtitles, poll interval/next poll or available activity context, approved/denied/expired/consumed states, raw code/hash/verification-handle absence, long values, no table, and no unsupported controls. [VERIFIED: codebase] [VERIFIED: 123-CONTEXT.md]
- [ ] Extend `test/lockspire/web/live/admin/logout_deliveries_live_test.exs` for discarded, skipped, rendered, succeeded/completed, retryable incident, long endpoint URL, optional HTTP/failure class if added, support note, no worker/internal leaks, no table, and no unsupported controls. [VERIFIED: codebase] [VERIFIED: 123-CONTEXT.md]
- [ ] Add source/API fence asserting no new Operate mutation delegates or queue command controls if the existing tests do not already cover the final implementation surface. [VERIFIED: 123-CONTEXT.md]
- [ ] Extend `AdminLab` fixtures/stress surface and design-system contract tests only if shared primitives/CSS change. [VERIFIED: 123-CONTEXT.md] [VERIFIED: codebase]

**Current baseline proof:** The focused Operate test command passed with `9 tests, 0 failures` on 2026-06-29; it emitted an existing non-fatal KeyCache startup error before `Lockspire.TestRepo` started. [VERIFIED: command run]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V2 Authentication | no for implementation; host app owns operator authentication before `AdminRouter`. [VERIFIED: docs/operator-admin.md] | Do not add Lockspire staff auth, MFA, or roles. [VERIFIED: AGENTS.md] |
| V3 Session Management | no for implementation; host app owns staff sessions. [VERIFIED: docs/operator-admin.md] | Do not add session behavior or host logout controls in Operate LiveViews. [VERIFIED: docs/operator-admin.md] [VERIFIED: 123-CONTEXT.md] |
| V4 Access Control | yes at route/action boundary. [VERIFIED: 123-CONTEXT.md] | Keep pages read-only; do not add routes or mutation controls without backed Admin API, authorization semantics, audit logging, telemetry, and docs. [VERIFIED: 123-CONTEXT.md] |
| V5 Input Validation | yes for URL/request safety only if filters or read-model params are introduced. [VERIFIED: 123-CONTEXT.md] | Avoid new URL state unless explicitly needed; keep any params normalized in LiveView helpers. [VERIFIED: 123-CONTEXT.md] |
| V6 Cryptography | yes as a non-change constraint. [VERIFIED: AGENTS.md] | Do not touch protocol crypto, token material, auth codes, PKCE, state, nonce, device/user codes, logout token JTI, or secret storage. [VERIFIED: AGENTS.md] [VERIFIED: 123-CONTEXT.md] |
| V7 Error Handling and Logging | yes for support copy and redaction. [VERIFIED: 123-CONTEXT.md] | Use calm operator copy and rendered forbidden-text assertions; do not expose backend internals or raw sensitive failures. [VERIFIED: 123-CONTEXT.md] |

### Known Threat Patterns for Phoenix LiveView Operate Queues

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Raw OAuth/OIDC or device-flow material rendered in queue rows | Information Disclosure | Use allowed field lists, `Redaction.handle/2`, `long_value`, and forbidden-text assertions. [VERIFIED: 123-CONTEXT.md] [VERIFIED: codebase] |
| Read-only support page appears to authorize mutation | Elevation of Privilege / Tampering | No `handle_event`, `phx-click`, `phx-submit`, command labels, or new Operate mutation delegates. [VERIFIED: codebase] [VERIFIED: 123-CONTEXT.md] |
| Backend worker internals become support concepts | Information Disclosure / Repudiation | Show endpoint/channel/attempt/status pressure, not Oban job IDs, SQL rows, raw worker errors, or raw response bodies. [VERIFIED: 123-CONTEXT.md] |
| Long endpoint or identifier causes mobile overflow and hides incident context | Denial of Service / Usability Failure | Use `long_value`, existing wrapping CSS, dense row stacking below 720px, and WCAG Reflow-aligned proof. [VERIFIED: codebase] [CITED: https://www.w3.org/WAI/WCAG22/Understanding/reflow.html] |
| Status is conveyed only by badge color | Information Disclosure / Usability Failure | Keep text labels and support/consequence copy; use semantic status badges with visible labels. [VERIFIED: codebase] [CITED: https://www.w3.org/WAI/WCAG22/Understanding/use-of-color.html] |

## Sources

### Primary (HIGH confidence)

- `AGENTS.md` - project boundary, stack, priorities, and security defaults. [VERIFIED: AGENTS.md]
- `.planning/phases/123-operate-queue-flow-polish/123-CONTEXT.md` - locked phase decisions, boundaries, data rules, verification rules, and deferred ideas. [VERIFIED: 123-CONTEXT.md]
- `.planning/REQUIREMENTS.md` - OPERATE-01/02/03 requirement text and phase mapping. [VERIFIED: .planning/REQUIREMENTS.md]
- `.planning/ROADMAP.md` - Phase 123 goal, success criteria, and milestone boundary. [VERIFIED: .planning/ROADMAP.md]
- `.planning/STATE.md` - prior decisions around no fake controls, deterministic guardrails, and v1.32 state. [VERIFIED: .planning/STATE.md]
- Codebase files: `AdminRouter`, the three Operate LiveViews, `AdminComponents`, `admin_css.ex`, domain/storage records, route tests, `HtmlAssertions`, design-system tests, and AdminLab fixtures. [VERIFIED: codebase]

### Secondary (MEDIUM confidence)

- Phoenix LiveView component docs v1.1.30 - function components, attrs, slots. [CITED: https://phoenix-live-view.hexdocs.pm/1.1.30/Phoenix.Component.html]
- Phoenix LiveViewTest docs v1.1.30 - `render_component/3`, `rendered_to_string/1`, `live/2`, and event-test behavior. [CITED: https://hexdocs.pm/phoenix_live_view/1.1.30/Phoenix.LiveViewTest.html]
- Ecto Schema docs v3.13.5 - `redact: true` and `load_in_query: false` field options. [CITED: https://ecto.hexdocs.pm/3.13.5/Ecto.Schema.html]
- W3C WCAG Understanding docs - Reflow, Use of Color, Focus Visible, and Animation from Interactions. [CITED: https://www.w3.org/WAI/WCAG22/Understanding/reflow.html] [CITED: https://www.w3.org/WAI/WCAG22/Understanding/use-of-color.html] [CITED: https://www.w3.org/WAI/WCAG22/Understanding/focus-visible.html] [CITED: https://www.w3.org/WAI/WCAG22/Understanding/animation-from-interactions.html]
- Hex registry checks for existing packages and release dates. [VERIFIED: Hex registry]

### Tertiary (LOW confidence)

- Assumption A1 about exact relative-age test brittleness. [ASSUMED]

## Metadata

**Confidence breakdown:**

- Standard stack: HIGH - existing dependencies were verified from `mix.exs`, `mix.lock`, environment probes, and Hex registry output. [VERIFIED: mix.exs] [VERIFIED: mix.lock] [VERIFIED: Hex registry]
- Architecture: HIGH - route/data/render/proof paths were verified directly in repo files. [VERIFIED: codebase]
- Pitfalls: HIGH for boundary/redaction/no-action/mobile pitfalls because they are locked in context and current code; LOW for exact age-test brittleness because it is a planning caution rather than a repo fact. [VERIFIED: 123-CONTEXT.md] [VERIFIED: codebase] [ASSUMED]

**Research date:** 2026-06-29  
**Valid until:** 2026-07-29 for local architecture; re-check HexDocs/Hex registry if dependency versions change before implementation. [ASSUMED]
