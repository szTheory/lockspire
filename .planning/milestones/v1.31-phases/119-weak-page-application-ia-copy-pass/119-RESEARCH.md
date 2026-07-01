# Phase 119: Weak-Page Application & IA/Copy Pass - Research

**Researched:** 2026-06-26  
**Domain:** Phoenix LiveView admin IA, copy, and design-system application for OAuth/OIDC operator surfaces  
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

Everything in this section is copied from `.planning/phases/119-weak-page-application-ia-copy-pass/119-CONTEXT.md`; it is the locked planning boundary for this phase. [VERIFIED: .planning/phases/119-weak-page-application-ia-copy-pass/119-CONTEXT.md]

### Locked Decisions

### Component Adoption Boundary

- **D-01:** Phase 119 should consume existing `Lockspire.Web.Components.AdminComponents` primitives instead of inventing a second design-system layer. Use the Phase 118 structural primitives where they materially improve scanability or safety: `pane`, `entity_header`, `workflow_shell`, `status_cluster`, `lifecycle_row`, `dense_resource_row`, `responsive_table`, `action_group`, `form_field`, `long_value`, and `copy_once_secret_panel`.
- **D-02:** LiveViews keep page intent, URL state, form shape, validation, event handlers, and mutation semantics. Do not introduce domain workflow components, broad LiveComponents, new router entries, a Storybook/lab route, or host-editable admin component APIs in this phase.
- **D-03:** This is not a full route rewrite. Preserve already-stable Phase 109 support and operate behavior where the existing page job, safe action, redaction, and destructive confirmation story is already clear.

### Client Detail IA

- **D-04:** Re-group client detail around the existing operator concepts: identity/current status, effective posture, credentials and assertion-key posture, endpoints and logout, DCR/RAT context, support pivots, and lifecycle/destructive actions. Use structural primitives to make those groups scan as intentional panes or rows rather than one large card with many local sections.
- **D-05:** Preserve existing action destinations and events: routine edit, redirect URI edit, post-logout redirect URI edit, logout propagation query workflow, PAR policy edit, security profile edit, secret rotation, RAT rotation, and `toggle_client`. The planner may change markup/chrome, but not the route/event contract.
- **D-06:** Keep the locked vocabulary split visible on client detail: post-logout redirect URIs are browser destinations; logout propagation URIs are RP cleanup endpoints. Keep DCR onboarding, self-registered-client provenance, and RAT support distinct from DCR policy.

### DCR Policy Workflow

- **D-07:** Keep DCR policy as one submitted policy form with the existing `phx-submit="save_policy"` behavior and current `policy[...]` field names. Visual grouping should not split persistence or rename params.
- **D-08:** Visually separate DCR policy decisions into gate, allowlist, lifetime, auth-method, and risk/posture groups using shared workflow/field chrome. Preserve current policy semantics, casts, validation, private-key-jwt/client-secret-jwt posture copy, and `Admin.put_dcr_policy/1` persistence behavior.
- **D-09:** Do not add new registration modes, auth methods, policy values, automatic risk actions, or storage changes. This route clarifies existing DCR policy decisions; it does not expand Dynamic Client Registration behavior.

### Support And Operate Surfaces

- **D-10:** Token detail and consent detail should receive targeted primitive/copy alignment only where it improves incident hierarchy or mobile/readability. Preserve existing destructive confirmation panels, `Admin.revoke_token/2`, `Admin.revoke_token_family/2`, and `Admin.revoke_consent/2` behavior.
- **D-11:** IAT index/new should keep the existing DCR onboarding job, copy-once IAT secret behavior, metrics, resource rows, redaction, and revocation semantics. Replace remaining raw field wrappers with shared field/workflow primitives where practical without changing submitted field names.
- **D-12:** Device authorization, interaction, and logout delivery queues remain read-only operator queues. They may clarify page job, primary decision, empty/risk state, non-secret context, and next safe action, but must not add retry, discard, approval, logout, or worker-control UI unless existing domain APIs already back the action.
- **D-13:** Where an Operate page renders resource-list rows inside `lockspire-admin-table-wrap` without a real table, migrate to a clearer non-table structure such as `pane`, `resource_list`, or `dense_resource_row` instead of preserving table-like chrome for list content.

### Microcopy, Redaction, And Guardrails

- **D-14:** Microcopy should be concise, domain-accurate, calm under operator stress, and consequence-oriented. Avoid fear language and generic security-dashboard wording.
- **D-15:** Touched pages must continue to avoid plaintext or unredacted sensitive material: client secrets, RAT plaintext after rotation state, IAT plaintext after creation state, access/refresh token plaintext, authorization codes, cookies, private keys, verifier material, user codes, and raw credential material.
- **D-16:** Verification should extend deterministic LiveView/component/design-system contracts and focused route tests for touched pages. Phase 120 owns the full browser, viewport, theme, reduced-motion, docs, and regression audit proof.

### the agent's Discretion

Planner and executor may choose exact pane titles, grouping order, helper names, and whether a stable support detail page needs light structural migration or only copy/test alignment, provided D-01 through D-16 remain true.

### Deferred Ideas (OUT OF SCOPE)

- Full browser, viewport, theme, reduced-motion, docs, and regression proof belongs to Phase 120.
- PhoenixStorybook, public component lab route, React/JS Storybook, public theming engine, and host-editable component registry remain out of scope.
- New retry/discard/approval/logout worker controls for operation queues are deferred unless a later phase adds explicit domain APIs.
- OAuth/OIDC protocol breadth, storage schema changes, hosted admin/service behavior, and public support-surface expansion are out of scope.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| FLOW-01 | Client detail uses clearer pane/group structure for identity, posture, credentials, endpoints, DCR/RAT, support pivots, and destructive lifecycle actions. | `ClientsLive.Show` still renders one large `section_card` with many `lockspire-admin-detail-section` groups; Phase 118 added `pane`, `entity_header`, `status_cluster`, `lifecycle_row`, and `action_group` for this exact grouping job. [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: codebase grep] |
| FLOW-02 | DCR policy uses a workflow structure that separates gate, allowlist, lifetime, auth-method, and risk decisions without changing policy semantics. | `PoliciesLive.Dcr` persists through `phx-submit="save_policy"`, `PolicyForm.changeset/2`, and `Admin.put_dcr_policy/1`; the HEEx currently mixes shared `form_field` and raw `lockspire-admin-field` wrappers in one vertical form. [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: codebase grep] |
| FLOW-03 | IAT index/new, token detail, consent detail, and operation queues render clear page jobs, primary decisions, empty states, risk states, and next safe actions. | IAT, token detail, consent detail, device authorization, interaction, and logout delivery pages already expose core state and tests; planning should add targeted primitive/copy alignment rather than reworking behavior. [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: codebase grep] |
| FLOW-04 | Read-only operation queues describe current supported actions truthfully and do not add retry/discard UI unless backed by existing domain APIs. | Existing operate pages render read-only rows; repository/Admin inspection found list/transition APIs but no admin-facing retry/discard/logout worker-control UI contract for these routes. [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: codebase grep] |
| FLOW-05 | UX microcopy is concise, domain-accurate, calm under operator stress, and names destructive consequences without fear language. | Phase 116/118 contracts require structured trust, OAuth/OIDC nouns, consequence copy, non-color status meaning, and redaction; W3C WCAG 2.1 SC 1.4.1 supports not relying on color alone for risk/status meaning. [VERIFIED: .planning/phases/116-inventory-rubric-lab-contract/116-VISUAL-UX-RUBRIC.md] [CITED: https://www.w3.org/WAI/WCAG21/Understanding/use-of-color.html] |
</phase_requirements>

## Summary

Phase 119 should be planned as a production application pass over already-built Phase 118 primitives, not as a new design-system or protocol phase. [VERIFIED: .planning/phases/119-weak-page-application-ia-copy-pass/119-CONTEXT.md] The strongest plan shape is four focused waves: client detail IA, DCR policy workflow grouping, IAT/support detail alignment, and read-only operate queue cleanup plus deterministic tests. [VERIFIED: codebase grep]

The main implementation risk is accidental behavior creep: DCR policy grouping must keep one `save_policy` form and current `policy[...]` names, client detail must preserve patch destinations and events, and operate queues must not imply retry/discard/approval actions unless existing domain APIs explicitly support them. [VERIFIED: codebase grep] LiveView's official docs support the local pattern: use function components with `attr`/`slot` for reusable structure, preserve form-level `phx-submit`/`phx-change` contracts, and test rendered elements/events with `Phoenix.LiveViewTest`. [CITED: https://phoenix-live-view.hexdocs.pm/1.1.30/Phoenix.Component.html] [CITED: https://phoenix-live-view.hexdocs.pm/form-bindings.html] [CITED: https://phoenix-live-view.hexdocs.pm/1.1.30/Phoenix.LiveViewTest.html]

**Primary recommendation:** Apply `entity_header`, `pane`, `workflow_shell`, `form_field`, `dense_resource_row`, `lifecycle_row`, `status_cluster`, `long_value`, and `action_group` to the named weak surfaces while preserving LiveView-owned events, params, and mutation semantics. [VERIFIED: .planning/phases/119-weak-page-application-ia-copy-pass/119-CONTEXT.md] [VERIFIED: codebase grep]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|--------------|----------------|-----------|
| Client detail pane/group IA | Frontend Server (LiveView) | API / Backend | `ClientsLive.Show` owns page structure, patch links, copy, and event wiring; existing Admin/protocol functions own client mutation behavior. [VERIFIED: codebase grep] |
| DCR policy grouping | Frontend Server (LiveView) | API / Backend | `PoliciesLive.Dcr` owns form markup and grouping while `PolicyForm.changeset/2` and `Admin.put_dcr_policy/1` own validation/persistence semantics. [VERIFIED: codebase grep] |
| IAT copy-once and inventory clarity | Frontend Server (LiveView) | Storage / Backend | IAT pages render inventory/minting and call `InitialAccessTokens`; plaintext is only rendered in copy-once creation state and tests already verify it is cleared. [VERIFIED: codebase grep] |
| Token and consent support detail hierarchy | Frontend Server (LiveView) | API / Backend | Detail pages own incident hierarchy and confirmation copy; `Admin.revoke_token/2`, `Admin.revoke_token_family/2`, and `Admin.revoke_consent/2` own durable actions. [VERIFIED: codebase grep] |
| Operate queue read-only truth | Frontend Server (LiveView) | Database / Storage | Queue pages read repository/Admin data and render non-secret rows; no plan task should add UI controls without an existing domain API. [VERIFIED: codebase grep] |
| Microcopy and redaction guardrails | Frontend Server (LiveView) | Browser / CSS | LiveViews supply words and safe context; `long_value`, status badges, CSS wrapping, and tests guard display safety. [VERIFIED: codebase grep] |

## Project Constraints (from AGENTS.md)

- Lockspire is an embedded OAuth/OIDC authorization server library for Phoenix and Elixir; it is not a required standalone auth service. [VERIFIED: AGENTS.md]
- Lockspire must remain a separate companion library, not a Sigra module. [VERIFIED: AGENTS.md]
- Host apps own accounts, login UX, layouts, branding, product-specific policy, account resolution, claims, and login redirects. [VERIFIED: AGENTS.md]
- Internal boundaries between protocol core, storage, generators, Plug/Phoenix integration, and LiveView/admin surfaces must remain strong. [VERIFIED: AGENTS.md]
- The v1 scope must not broaden into SAML, LDAP/AD federation, hosted auth, or a full CIAM suite. [VERIFIED: AGENTS.md]
- Security defaults to preserve include PKCE S256 required by default, exact-match redirect URI validation, hashed client secrets at rest, short-lived single-use authorization codes, refresh-token rotation with family-wide revocation on reuse, no implicit flow, no `alg=none`, and strong redaction in logs/operator surfaces. [VERIFIED: AGENTS.md]
- Stack targets are Phoenix `1.8.5`, Phoenix LiveView `1.1.28`, Ecto SQL `3.13.5`, PostgreSQL `14+`, Bandit `1.6.1`, Oban `2.21.x`, and OpenTelemetry `1.6.0`; current implementation lockfile versions are listed in Standard Stack and should be treated as source truth for this phase. [VERIFIED: AGENTS.md] [VERIFIED: mix deps]

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `phoenix` | locked `1.8.7`; Hex recent `1.8.8` published 2026-06-10 | Router, endpoint, and embedded Phoenix integration | Existing framework; no Phase 119 task should upgrade framework dependencies. [VERIFIED: mix deps] [VERIFIED: Hex registry] |
| `phoenix_live_view` | locked `1.1.30`; Hex recent `1.2.3` published 2026-06-16 | Server-rendered admin LiveViews, HEEx templates, components, and tests | Current admin UI is LiveView; official docs support function components, slots, form events, and LiveViewTest. [VERIFIED: mix deps] [VERIFIED: Hex registry] [CITED: https://phoenix-live-view.hexdocs.pm/1.1.30/Phoenix.Component.html] |
| `ecto_sql` | locked `3.13.5`; Hex recent `3.14.0` published 2026-05-19 | Existing SQL storage and validation context | DCR, client, token, consent, device, interaction, and logout records already use Ecto/PostgreSQL-backed storage. [VERIFIED: mix deps] [VERIFIED: Hex registry] [VERIFIED: codebase grep] |
| `postgrex` | locked `0.22.2`; Hex recent `0.22.2` published 2026-05-12 | PostgreSQL adapter | The project targets PostgreSQL 14+ and the local `psql` version is 14.17. [VERIFIED: mix deps] [VERIFIED: Hex registry] [VERIFIED: environment probe] |
| `Lockspire.Web.Components.AdminComponents` | local module | Admin primitives and meta-components | Phase 118 already added `pane`, `entity_header`, `workflow_shell`, `dense_resource_row`, `responsive_table`, `form_field`, `long_value`, and related CSS/tests. [VERIFIED: codebase grep] |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `bandit` | locked `1.11.1`; Hex recent `1.12.0` published 2026-06-06 | Phoenix HTTP server in the current stack | No Phase 119 work expected; keep as existing runtime dependency. [VERIFIED: mix deps] [VERIFIED: Hex registry] |
| `oban` | locked `2.21.1`; Hex recent `2.23.0` published 2026-05-27 | Background job context for logout propagation | Treat as read-only context for logout queues unless an existing admin/domain API supports a new action. [VERIFIED: mix deps] [VERIFIED: Hex registry] [VERIFIED: codebase grep] |
| `opentelemetry_api` | locked `1.5.0`; Hex recent `1.5.0` published 2025-10-17 | Telemetry API | No new instrumentation is required because Phase 119 should not change behavior. [VERIFIED: mix deps] [VERIFIED: Hex registry] [VERIFIED: .planning/phases/119-weak-page-application-ia-copy-pass/119-CONTEXT.md] |
| `Phoenix.LiveViewTest` | from `phoenix_live_view` `1.1.30` | Rendered LiveView/component test helpers | Use `live/2`, `element/3`, `form/3`, `render_submit/1`, `render_click/1`, and `rendered_to_string/1` for route and contract proof. [CITED: https://phoenix-live-view.hexdocs.pm/1.1.30/Phoenix.LiveViewTest.html] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Existing AdminComponents primitives | PhoenixStorybook or public component lab route | Explicitly out of scope; Phase 119 must not add public routes or a new dependency. [VERIFIED: .planning/phases/119-weak-page-application-ia-copy-pass/119-CONTEXT.md] |
| LiveView-owned form markup with shared field chrome | High-level domain workflow components | Out of scope because LiveViews must keep page intent, params, validation, events, and mutation semantics visible. [VERIFIED: .planning/phases/119-weak-page-application-ia-copy-pass/119-CONTEXT.md] |
| Deterministic ExUnit/source contracts | Full browser screenshot or axe proof | Phase 120 owns browser, viewport, theme, reduced-motion, docs, and regression proof. [VERIFIED: .planning/phases/119-weak-page-application-ia-copy-pass/119-CONTEXT.md] |

**Installation:**

```bash
# No new packages for Phase 119.
mix deps.get
```

No package install is recommended for this phase; use the locked project stack and local shared components. [VERIFIED: mix.exs] [VERIFIED: .planning/phases/119-weak-page-application-ia-copy-pass/119-CONTEXT.md]

## Package Legitimacy Audit

No external packages should be installed in Phase 119, so the Package Legitimacy Gate is not applicable. [VERIFIED: .planning/phases/119-weak-page-application-ia-copy-pass/119-CONTEXT.md] [VERIFIED: mix.exs]

| Package | Registry | Age | Downloads | Source Repo | Verdict | Disposition |
|---------|----------|-----|-----------|-------------|---------|-------------|
| none | — | — | — | — | — | No new package installation recommended. [VERIFIED: research scope] |

**Packages removed due to [SLOP] verdict:** none; no package installation is recommended. [VERIFIED: research scope]  
**Packages flagged as suspicious [SUS]:** none; no package installation is recommended. [VERIFIED: research scope]

## Architecture Patterns

### System Architecture Diagram

```text
Host-mounted /admin route
  -> Phoenix LiveView route
    -> mount/handle_params loads existing durable state
    -> page-local helpers derive status/risk/next-action copy
    -> AdminComponents render entity headers, panes, workflow shells, rows, fields, statuses, and long values
      -> CSS handles responsive wrapping, focus, status tone, and reduced-motion-safe structure
    -> existing phx-submit/phx-click events call existing Admin/protocol/storage APIs only
      -> no new route, schema, OAuth/OIDC behavior, retry/discard action, or secret exposure
```

This architecture matches the local LiveView code and the official LiveView model for server-rendered function components and event callbacks. [VERIFIED: codebase grep] [CITED: https://phoenix-live-view.hexdocs.pm/1.1.30/Phoenix.Component.html] [CITED: https://phoenix-live-view.hexdocs.pm/form-bindings.html]

### Recommended Project Structure

```text
lib/lockspire/web/
├── components/admin_components.ex          # shared structural primitives and rows
├── admin_css.ex                            # lockspire-admin-* BEM/design-token CSS
└── live/admin/
    ├── clients_live/show.ex                # FLOW-01 client detail IA
    ├── policies_live/dcr.html.heex         # FLOW-02 DCR one-form workflow grouping
    ├── policies_live/dcr/policy_form.ex    # FLOW-02 existing validation contract
    ├── iat_live/index.html.heex            # FLOW-03 IAT inventory
    ├── iat_live/new.html.heex              # FLOW-03 IAT mint/copy-once form
    ├── tokens_live/show.ex                 # FLOW-03 support token detail
    ├── consents_live/show.ex               # FLOW-03 support consent detail
    ├── device_authorizations_live/index.ex # FLOW-03/FLOW-04 operate queue
    ├── interactions_live/index.ex          # FLOW-03/FLOW-04 operate queue
    └── logout_deliveries_live/index.ex     # FLOW-03/FLOW-04 operate queue
```

The listed files are the current production integration points for Phase 119. [VERIFIED: codebase grep]

### Pattern 1: Page-Owned Data, Shared Structural Chrome

**What:** LiveViews keep domain state, params, events, and helper decisions; `AdminComponents` owns repeated structure such as panes, headers, rows, status clusters, fields, long values, and action grouping. [VERIFIED: .planning/phases/119-weak-page-application-ia-copy-pass/119-CONTEXT.md] [VERIFIED: codebase grep]

**When to use:** Use on client detail, DCR policy, IAT pages, support details, and operate queues when the shared primitive materially improves scanability or safety. [VERIFIED: .planning/phases/119-weak-page-application-ia-copy-pass/119-CONTEXT.md]

**Example:**

```elixir
<AdminComponents.pane
  title="Effective posture"
  subtitle="Issuer defaults and client overrides shown together."
>
  <AdminComponents.status_cluster>
    <AdminComponents.status_badge status={status_for(@client)} />
  </AdminComponents.status_cluster>
  <AdminComponents.description_list>
    <:item label="Effective PAR requirement">
      <strong>{verdict_for(@effective_par_policy)}</strong>
    </:item>
  </AdminComponents.description_list>
</AdminComponents.pane>
```

Source: local `AdminComponents.pane/1`, `status_cluster/1`, `status_badge/1`, and `description_list/1` component contracts. [VERIFIED: codebase grep]

### Pattern 2: One Form, Multiple Visual Decision Groups

**What:** DCR policy should render gate, allowlist, lifetime, auth-method, and risk/posture as visual panes or workflow groups inside one existing form. [VERIFIED: .planning/phases/119-weak-page-application-ia-copy-pass/119-CONTEXT.md]

**When to use:** Use on `policies_live/dcr.html.heex`; do not split persistence or rename fields. [VERIFIED: codebase grep]

**Example:**

```elixir
<form id="dcr-policy-form" class="lockspire-admin-form-stack" phx-submit="save_policy">
  <AdminComponents.workflow_shell title="Gate" help="Choose how registration requests are admitted.">
    <AdminComponents.form_field id="registration_policy" label="Registration gate">
      <select id="registration_policy" name="policy[registration_policy]">...</select>
    </AdminComponents.form_field>
  </AdminComponents.workflow_shell>

  <AdminComponents.workflow_shell title="Allowlist" help="Bound the metadata self-registered clients may request.">
    <AdminComponents.form_field id="dcr_allowed_scopes" label="Allowed scopes">
      <input id="dcr_allowed_scopes" name="policy[dcr_allowed_scopes]" />
    </AdminComponents.form_field>
  </AdminComponents.workflow_shell>
</form>
```

Source: official LiveView form bindings and local DCR form/event contract. [CITED: https://phoenix-live-view.hexdocs.pm/form-bindings.html] [VERIFIED: codebase grep]

### Pattern 3: Read-Only Queue Rows Without Table Chrome

**What:** Operate queues should show counts, status, non-secret pivots, and the next safe review context, but not wrap resource lists in table wrappers or imply operator controls. [VERIFIED: .planning/phases/119-weak-page-application-ia-copy-pass/119-CONTEXT.md] [VERIFIED: codebase grep]

**When to use:** Apply to interactions and logout deliveries first because they currently wrap `resource_list` rows in `lockspire-admin-table-wrap` despite not rendering a table. [VERIFIED: codebase grep]

**Example:**

```elixir
<AdminComponents.pane title="Review logout deliveries" subtitle="Read-only delivery context.">
  <AdminComponents.resource_list>
    <AdminComponents.dense_resource_row
      :for={delivery <- @deliveries}
      title={"#{delivery.channel} logout delivery"}
      subtitle="No worker control is available on this page."
    >
      <:meta>
        <span>Delivery <AdminComponents.long_value value={delivery.delivery_id} kind={:id} /></span>
        <span>Endpoint <AdminComponents.long_value value={delivery.target_uri} kind={:url} /></span>
      </:meta>
      <:status>
        <AdminComponents.status_badge status={delivery.status} />
      </:status>
    </AdminComponents.dense_resource_row>
  </AdminComponents.resource_list>
</AdminComponents.pane>
```

Source: local `dense_resource_row/1`, `resource_list/1`, `long_value/1`, and operate queue code. [VERIFIED: codebase grep]

### Anti-Patterns to Avoid

- **Splitting DCR policy persistence:** Multiple forms or renamed `policy[...]` fields would break the locked `save_policy` contract. [VERIFIED: .planning/phases/119-weak-page-application-ia-copy-pass/119-CONTEXT.md] [VERIFIED: codebase grep]
- **Adding unsupported queue actions:** Retry, discard, approval, logout, or worker-control UI is forbidden unless an existing domain API backs it. [VERIFIED: .planning/phases/119-weak-page-application-ia-copy-pass/119-CONTEXT.md] [VERIFIED: codebase grep]
- **Generic security-dashboard copy:** Phase 116 requires OAuth/OIDC nouns and structured trust, not fear-led or generic security-center wording. [VERIFIED: .planning/phases/116-inventory-rubric-lab-contract/116-VISUAL-UX-RUBRIC.md]
- **Secret-like support pivots:** Do not render client secrets, RAT/IAT plaintext after copy-once state, token hashes/plaintext, authorization codes, cookies, private keys, verifier material, user codes, or raw credential material. [VERIFIED: AGENTS.md] [VERIFIED: .planning/phases/119-weak-page-application-ia-copy-pass/119-CONTEXT.md]
- **Using color as the only risk signal:** Status/risk must be expressed through visible text, headings, labels, and consequence copy. [CITED: https://www.w3.org/WAI/WCAG21/Understanding/use-of-color.html] [VERIFIED: codebase grep]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Structural page groups | New local card/grid framework | `pane`, `entity_header`, `workflow_shell`, `lifecycle_row` | Phase 118 already added these primitives and CSS/test contracts. [VERIFIED: codebase grep] |
| Dense queue rows | Ad hoc div/table hybrids | `resource_list` plus `dense_resource_row` or existing `resource_item` | Phase 119 specifically targets non-table operate list chrome and mobile scanability. [VERIFIED: .planning/phases/119-weak-page-application-ia-copy-pass/119-CONTEXT.md] |
| Long identifiers and URLs | Per-page `<code>` wrapping rules | `long_value` | Existing CSS applies `overflow-wrap:anywhere` and mono styling for long values. [VERIFIED: codebase grep] |
| DCR form validation | New policy parser | Existing `PolicyForm.changeset/2` and `Admin.put_dcr_policy/1` | Current semantics and persistence must not change. [VERIFIED: codebase grep] |
| Destructive confirmation patterns | New modal/JS confirmation flow | `confirmation_panel`, `action_group`, existing forms/events | Token and consent details already use server-confirmed forms and tests. [VERIFIED: codebase grep] |
| LiveView event proof | Direct event bypass as the only test | `element/3`, `form/3`, `render_click/1`, `render_submit/1` | Official LiveViewTest docs prefer element-scoped triggering where possible because it validates rendered event bindings. [CITED: https://phoenix-live-view.hexdocs.pm/1.1.30/Phoenix.LiveViewTest.html] |

**Key insight:** Phase 119 planning should spend effort on information grouping and copy consequences, not on new capabilities; the design-system primitives and domain APIs already exist for the required surface. [VERIFIED: .planning/phases/119-weak-page-application-ia-copy-pass/119-CONTEXT.md] [VERIFIED: codebase grep]

## Common Pitfalls

### Pitfall 1: UI Polish Changes Semantics

**What goes wrong:** A visual grouping task renames DCR fields, splits the form, changes client action routes, or adds operation-queue buttons. [VERIFIED: .planning/phases/119-weak-page-application-ia-copy-pass/119-CONTEXT.md]  
**Why it happens:** The requested IA/copy pass touches pages that sit near policy and lifecycle actions. [VERIFIED: codebase grep]  
**How to avoid:** Keep every form/event/route contract in tests before changing markup. [VERIFIED: codebase grep]  
**Warning signs:** Plan tasks mention migrations, new router entries, new policy values, retry/discard UI, or new admin APIs. [VERIFIED: .planning/REQUIREMENTS.md]

### Pitfall 2: DCR Policy Becomes DCR Onboarding

**What goes wrong:** Policy copy collapses issuer registration posture into partner intake/IAT/RAT onboarding. [VERIFIED: .planning/phases/107-admin-journey-contract-ia-audit/107-ROUTE-JOURNEY-CONTRACT.md]  
**Why it happens:** DCR policy, DCR onboarding, IATs, self-registered clients, and RAT support are adjacent in navigation and domain language. [VERIFIED: .planning/phases/107-admin-journey-contract-ia-audit/107-ROUTE-JOURNEY-CONTRACT.md]  
**How to avoid:** Keep DCR policy as gate/allowlist/lifetime/auth-method/risk; keep IAT/RAT and self-registered provenance as onboarding/support context. [VERIFIED: .planning/phases/119-weak-page-application-ia-copy-pass/119-CONTEXT.md]  
**Warning signs:** Copy says the DCR policy page mints IATs, rotates RATs, or manages a specific self-registered client. [VERIFIED: codebase grep]

### Pitfall 3: Read-Only Queue Copy Implies Controls

**What goes wrong:** Logout, interaction, or device authorization pages describe retry/discard/approval/logout as available operator actions. [VERIFIED: .planning/REQUIREMENTS.md]  
**Why it happens:** Queue terms such as retrying, failed, discarded, approved, and pending naturally sound actionable. [VERIFIED: codebase grep]  
**How to avoid:** Use "review", "inspect", "verify upstream state", or "use existing protocol flow" copy unless a current API backs mutation. [VERIFIED: .planning/phases/119-weak-page-application-ia-copy-pass/119-CONTEXT.md]  
**Warning signs:** Tests for operate pages start asserting `phx-click`, `phx-submit`, or button labels on queue rows. [VERIFIED: codebase grep]

### Pitfall 4: Secret Leakage Through "Helpful" Detail

**What goes wrong:** Detail panes render token hashes, device/user code hashes, raw client secrets, RAT/IAT plaintext after creation, verifier material, or unredacted account/client IDs. [VERIFIED: AGENTS.md] [VERIFIED: codebase grep]  
**Why it happens:** Operators need pivots during incidents, but some values are credential material rather than safe identifiers. [VERIFIED: .planning/phases/119-weak-page-application-ia-copy-pass/119-CONTEXT.md]  
**How to avoid:** Use `Redaction.handle/2`, `long_value`, copy-once panels only in creation/rotation state, and focused negative assertions. [VERIFIED: codebase grep]  
**Warning signs:** New tests include raw fixture strings such as token hashes, user-code hashes, account IDs, or client secrets in expected HTML. [VERIFIED: codebase grep]

## Code Examples

Verified patterns from local source and official docs:

### Preserve DCR Submit Contract While Grouping Fields

```elixir
<form id="dcr-policy-form" class="lockspire-admin-form-stack" phx-submit="save_policy">
  <AdminComponents.workflow_shell title="Auth-method decisions">
    <AdminComponents.form_field
      id="dcr_allowed_token_endpoint_auth_methods"
      label="Allowed token endpoint auth methods"
      help="Comma-separated methods self-registered clients may request."
    >
      <input
        type="text"
        id="dcr_allowed_token_endpoint_auth_methods"
        name="policy[dcr_allowed_token_endpoint_auth_methods]"
        value={Enum.join(@policy.dcr_allowed_token_endpoint_auth_methods || [], ", ")}
      />
    </AdminComponents.form_field>
  </AdminComponents.workflow_shell>
</form>
```

Source: existing DCR form names and LiveView form binding guidance. [VERIFIED: codebase grep] [CITED: https://phoenix-live-view.hexdocs.pm/form-bindings.html]

### Test Rendered Events Instead Of Bypassing Markup

```elixir
assert {:ok, view, _html} = live(conn_for_admin(), "/admin/policies/dcr")

view
|> form("form[phx-submit=save_policy]", %{
  policy: %{registration_policy: "open", dcr_allowed_scopes: "openid, email"}
})
|> render_submit()
```

Source: existing DCR test and LiveViewTest docs. [VERIFIED: codebase grep] [CITED: https://phoenix-live-view.hexdocs.pm/1.1.30/Phoenix.LiveViewTest.html]

### Queue Read-Only Assertion

```elixir
html = rendered_to_string(Index.render(socket.assigns))

assert html =~ "Operate"
assert html =~ "lockspire-admin-long-value"
refute html =~ "<table"
refute html =~ "phx-click"
refute html =~ "phx-submit"
```

Source: existing logout delivery test pattern; extend the same idea when removing table-wrap drift. [VERIFIED: codebase grep]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| One large `section_card` with many local detail sections | `entity_header` plus focused `pane`/`lifecycle_row` groups | Phase 118 added primitives; Phase 119 applies them | Client detail can scan by operator concept without changing actions. [VERIFIED: codebase grep] |
| Raw field wrappers mixed with shared fields | `workflow_shell` plus `form_field` while preserving explicit inputs | Phase 118 added form/workflow primitives | DCR can group decisions while retaining `policy[...]` params. [VERIFIED: codebase grep] |
| Resource lists inside `lockspire-admin-table-wrap` | `resource_list` / `dense_resource_row` in non-table panes | Phase 119 target | Operate pages stop signaling a table when no table is rendered. [VERIFIED: codebase grep] |
| Status color as visual emphasis | Domain-aware status badge tones plus labels/titles | Phase 118 status semantics | Real Configure/Support/Operate statuses no longer fall through to disabled styling. [VERIFIED: codebase grep] |

**Deprecated/outdated:**

- `lockspire-admin-table-wrap` around non-table resource lists is now drift for operate queues and should be removed where no real `<table>` exists. [VERIFIED: .planning/phases/119-weak-page-application-ia-copy-pass/119-CONTEXT.md] [VERIFIED: codebase grep]
- High-anxiety phrases such as "extreme caution" should be replaced on touched pages with consequence-oriented copy such as "Open registration allows unauthenticated registration requests; keep allowlists narrow and lifetimes bounded." [VERIFIED: codebase grep] [VERIFIED: .planning/phases/119-weak-page-application-ia-copy-pass/119-CONTEXT.md]

## Assumptions Log

All claims in this research were verified or cited in this session; no `[ASSUMED]` claims are present. [VERIFIED: research log]

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| — | — | — | — |

## Open Questions (RESOLVED)

1. **How deeply should token and consent detail be restructured?**  
   - What we know: Phase 119 context says these pages need targeted primitive/copy alignment only where it improves hierarchy or readability. [VERIFIED: .planning/phases/119-weak-page-application-ia-copy-pass/119-CONTEXT.md]  
   - RESOLVED: Plan `119-03`, task `119-03-02`, uses targeted primitive/copy alignment only for incident hierarchy, mobile readability, and consequence scanning. It preserves `Admin.revoke_token/2`, `Admin.revoke_token_family/2`, `Admin.revoke_consent/2`, `phx-submit="revoke_token"`, `phx-submit="revoke_family"`, `phx-submit="revoke_consent"`, checkbox confirmation params, current assigns, redaction helpers, and missing-record handling. Exact pane titles and ordering remain executor discretion within D-10, D-14, and D-15. [VERIFIED: .planning/phases/119-weak-page-application-ia-copy-pass/119-03-PLAN.md]

2. **Should client detail add support pivots even if no dedicated route is linked today?**  
   - What we know: FLOW-01 names support pivots, and existing admin routes include token/consent/logouts support/operate surfaces. [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: codebase grep]  
   - RESOLVED: Plan `119-01`, task `119-01-01`, adds support pivots only to existing route/filter destinations already backed by current route tests. When no stable filter contract exists, the client detail renders non-mutating review context instead of inventing a route, query param, or mutation path. [VERIFIED: .planning/phases/119-weak-page-application-ia-copy-pass/119-01-PLAN.md]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Elixir | Compile/tests | yes | 1.19.5 with Erlang/OTP 28 | None needed. [VERIFIED: environment probe] |
| Mix | Dependencies/tests | yes | 1.19.5 | None needed. [VERIFIED: environment probe] |
| PostgreSQL CLI | Test database setup | yes | `psql` 14.17 | Existing test setup scripts manage DB; planner can still run focused rendered tests that use `TestRepo`. [VERIFIED: environment probe] [VERIFIED: mix.exs] |
| Hex package metadata | Version verification | yes | `mix hex.info` returned package data | Use existing `mix.lock`; no install/upgrade task. [VERIFIED: Hex registry] |

**Missing dependencies with no fallback:** none identified for research and planning. [VERIFIED: environment probe]  
**Missing dependencies with fallback:** Context7 CLI was not installed; official docs were fetched directly and cited by URL. [VERIFIED: environment probe] [CITED: https://phoenix-live-view.hexdocs.pm/1.1.30/Phoenix.Component.html]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit plus `Phoenix.LiveViewTest` from locked `phoenix_live_view` `1.1.30`. [VERIFIED: mix deps] [CITED: https://phoenix-live-view.hexdocs.pm/1.1.30/Phoenix.LiveViewTest.html] |
| Config file | `mix.exs`; aliases include `test.setup`, `test.fast`, and `qa`. [VERIFIED: mix.exs] |
| Quick run command | `mix test test/lockspire/web/live/admin/design_system_contract_test.exs test/lockspire/web/live/admin/clients_live/show_test.exs test/lockspire/web/live/admin/policies_live/dcr_test.exs test/lockspire/web/live/admin/iat_live_test.exs test/lockspire/web/live/admin/tokens_live_test.exs test/lockspire/web/live/admin/consents_live_test.exs test/lockspire/web/live/admin/device_authorizations_live_test.exs test/lockspire/web/live/admin/interactions_live_test.exs test/lockspire/web/live/admin/logout_deliveries_live_test.exs` [VERIFIED: codebase grep] |
| Full suite command | `mix test.fast` [VERIFIED: mix.exs] |

### Phase Requirements -> Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| FLOW-01 | Client detail panes/groups preserve identity, posture, credentials, endpoints, DCR/RAT, support pivots, and lifecycle/destructive actions. | LiveView + source contract | `mix test test/lockspire/web/live/admin/clients_live/show_test.exs test/lockspire/web/live/admin/design_system_contract_test.exs` | yes; extend assertions. [VERIFIED: codebase grep] |
| FLOW-02 | DCR policy groups gate/allowlist/lifetime/auth-method/risk inside one `save_policy` form with same fields. | LiveView form test | `mix test test/lockspire/web/live/admin/policies_live/dcr_test.exs test/lockspire/web/live/admin/design_system_contract_test.exs` | yes; extend assertions. [VERIFIED: codebase grep] |
| FLOW-03 | IAT, token detail, consent detail, and queues show page job, primary decision, empty/risk states, and next safe actions. | LiveView rendered tests | `mix test test/lockspire/web/live/admin/iat_live_test.exs test/lockspire/web/live/admin/tokens_live_test.exs test/lockspire/web/live/admin/consents_live_test.exs test/lockspire/web/live/admin/device_authorizations_live_test.exs test/lockspire/web/live/admin/interactions_live_test.exs test/lockspire/web/live/admin/logout_deliveries_live_test.exs` | yes; extend assertions. [VERIFIED: codebase grep] |
| FLOW-04 | Read-only operation queues do not add unsupported retry/discard UI. | Negative rendered assertions | `mix test test/lockspire/web/live/admin/device_authorizations_live_test.exs test/lockspire/web/live/admin/interactions_live_test.exs test/lockspire/web/live/admin/logout_deliveries_live_test.exs` | yes; extend assertions. [VERIFIED: codebase grep] |
| FLOW-05 | Copy is concise, accurate, calm, consequence-oriented, and avoids generic/fear wording. | Source contract + focused rendered tests | `mix test test/lockspire/web/live/admin/design_system_contract_test.exs` | yes; extend CTA/copy drift fences. [VERIFIED: codebase grep] |

### Sampling Rate

- **Per task commit:** Run the focused route test touched by the task plus `design_system_contract_test.exs`. [VERIFIED: mix.exs] [VERIFIED: codebase grep]
- **Per wave merge:** Run the quick command above for all touched Phase 119 surfaces. [VERIFIED: codebase grep]
- **Phase gate:** Run `mix test.fast` before `$gsd-verify-work`. [VERIFIED: mix.exs]

### Wave 0 Gaps

- [ ] Extend `test/lockspire/web/live/admin/design_system_contract_test.exs` with Phase 119 source fences for `pane`/`entity_header`/`workflow_shell` adoption, no non-table `lockspire-admin-table-wrap` drift, and copy/redaction guardrails on touched pages. [VERIFIED: codebase grep]
- [ ] Extend `test/lockspire/web/live/admin/clients_live/show_test.exs` for client detail panes/groups and support-pivot copy while preserving route/event contract. [VERIFIED: codebase grep]
- [ ] Extend `test/lockspire/web/live/admin/policies_live/dcr_test.exs` for one-form grouped DCR decisions and unchanged `save_policy` behavior. [VERIFIED: codebase grep]
- [ ] Extend IAT/support/operate route tests for empty state, risk state, next safe action, read-only truth, and redaction assertions as pages are touched. [VERIFIED: codebase grep]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V2 Authentication | no for Phase 119 | Host-owned operator authentication remains outside Lockspire admin UI changes. [VERIFIED: AGENTS.md] |
| V3 Session Management | no for Phase 119 | Phase 119 must not change staff sessions, cookies, or hosted auth behavior. [VERIFIED: AGENTS.md] [VERIFIED: .planning/phases/119-weak-page-application-ia-copy-pass/119-CONTEXT.md] |
| V4 Access Control | yes, preserve only | Do not add routes or new admin actions; keep mounted admin boundary and existing operation support truth. [VERIFIED: .planning/ROADMAP.md] [VERIFIED: codebase grep] |
| V5 Input Validation | yes | Preserve `PolicyForm.changeset/2`, existing client form validation, explicit field names, and LiveView form events. [VERIFIED: codebase grep] |
| V6 Cryptography | yes, preserve only | Do not expose secrets, RAT/IAT plaintext after copy-once state, token material, verifier material, private keys, or raw credentials. [VERIFIED: AGENTS.md] [VERIFIED: codebase grep] |
| V9 Communications | yes, preserve only | Keep exact redirect/logout URI vocabulary; do not blur browser post-logout redirect destinations with RP logout cleanup endpoints. [VERIFIED: .planning/phases/107-admin-journey-contract-ia-audit/107-ROUTE-JOURNEY-CONTRACT.md] |
| V14 Configuration | yes | DCR policy grouping must preserve issuer policy semantics and safe operator comprehension. [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: codebase grep] |

### Known Threat Patterns for Phoenix LiveView Admin UI

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Secret exposure through support/detail UI | Information Disclosure | Use redacted handles, `copy_once_secret_panel` only during creation/rotation, and negative rendered assertions. [VERIFIED: AGENTS.md] [VERIFIED: codebase grep] |
| Unauthorized capability implied by UI | Elevation of Privilege / Tampering | Render read-only operate queues unless existing domain APIs back mutations; assert absence of unsupported `phx-click`/`phx-submit`. [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: codebase grep] |
| Policy misconfiguration due to grouped form rewrite | Tampering | Keep one `save_policy` form, unchanged `policy[...]` field names, `PolicyForm.changeset/2`, and `Admin.put_dcr_policy/1`. [VERIFIED: codebase grep] |
| Status/risk misunderstood due to color-only UI | Spoofing / Information Disclosure | Use text labels, titles, headings, and copy in addition to semantic badge color. [CITED: https://www.w3.org/WAI/WCAG21/Understanding/use-of-color.html] [VERIFIED: codebase grep] |
| OAuth/OIDC vocabulary drift | Tampering / Repudiation | Keep DCR onboarding vs DCR policy and post-logout redirect URI vs logout propagation URI split visible. [VERIFIED: .planning/phases/107-admin-journey-contract-ia-audit/107-ROUTE-JOURNEY-CONTRACT.md] [CITED: https://www.rfc-editor.org/rfc/rfc7591.html] [CITED: https://www.rfc-editor.org/rfc/rfc7592.html] |

## Sources

### Primary (HIGH confidence)

- `AGENTS.md` - project boundaries, stack, security defaults, and product priorities. [VERIFIED: AGENTS.md]
- `.planning/phases/119-weak-page-application-ia-copy-pass/119-CONTEXT.md` - locked decisions, deferred scope, and integration points. [VERIFIED: .planning/phases/119-weak-page-application-ia-copy-pass/119-CONTEXT.md]
- `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`, `.planning/STATE.md` - FLOW requirements, phase success criteria, and milestone boundaries. [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: .planning/ROADMAP.md] [VERIFIED: .planning/STATE.md]
- Phase 107/116/118 planning artifacts - route jobs, component inventory, visual rubric, and primitive contracts. [VERIFIED: .planning/phases/107-admin-journey-contract-ia-audit/107-ROUTE-JOURNEY-CONTRACT.md] [VERIFIED: .planning/phases/116-inventory-rubric-lab-contract/116-COMPONENT-GROUP-INVENTORY.md] [VERIFIED: .planning/phases/118-primitive-meta-component-upgrade/118-UI-SPEC.md]
- Local source and tests under `lib/lockspire/web/live/admin`, `lib/lockspire/web/components/admin_components.ex`, `lib/lockspire/web/admin_css.ex`, and `test/lockspire/web/live/admin`. [VERIFIED: codebase grep]

### Secondary (MEDIUM confidence)

- Phoenix LiveView official docs for function components, attrs, slots, HEEx, and LiveViewTest. [CITED: https://phoenix-live-view.hexdocs.pm/1.1.30/Phoenix.Component.html] [CITED: https://phoenix-live-view.hexdocs.pm/1.1.30/Phoenix.LiveViewTest.html]
- Phoenix LiveView official current form-bindings docs for `phx-change`, `phx-submit`, form-level change handling, and form IDs. [CITED: https://phoenix-live-view.hexdocs.pm/form-bindings.html]
- W3C WCAG 2.1 Understanding SC 1.4.1 for non-color status meaning. [CITED: https://www.w3.org/WAI/WCAG21/Understanding/use-of-color.html]
- RFC 7591 and RFC 7592 for Dynamic Client Registration and registration management vocabulary. [CITED: https://www.rfc-editor.org/rfc/rfc7591.html] [CITED: https://www.rfc-editor.org/rfc/rfc7592.html]
- Hex registry metadata via `mix hex.info` for package currency. [VERIFIED: Hex registry]

### Tertiary (LOW confidence)

- None used as authoritative claims. [VERIFIED: research log]

## Metadata

**Confidence breakdown:**

- Standard stack: HIGH - local `mix.exs`, `mix.lock`, `mix deps`, and Hex metadata were checked; no new packages are recommended. [VERIFIED: mix.exs] [VERIFIED: mix deps] [VERIFIED: Hex registry]
- Architecture: HIGH - recommendations are derived from locked phase decisions, current LiveView source, current component contracts, and current route tests. [VERIFIED: .planning/phases/119-weak-page-application-ia-copy-pass/119-CONTEXT.md] [VERIFIED: codebase grep]
- Pitfalls: HIGH - pitfalls are directly tied to explicit locked decisions, existing tests, and inspected source boundaries. [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: codebase grep]
- External docs: MEDIUM - Context7 was unavailable, so official docs/RFC/W3C URLs were fetched directly and cited. [VERIFIED: environment probe] [CITED: https://phoenix-live-view.hexdocs.pm/1.1.30/Phoenix.Component.html]

**Research date:** 2026-06-26  
**Valid until:** 2026-07-26 for Phase 119 planning unless Phase 118 primitives or the admin route contracts change first. [VERIFIED: research scope]
