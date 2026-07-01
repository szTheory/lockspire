# Phase 109: Weak-Spot Page Polish - Research

**Researched:** 2026-06-04
**Domain:** Phoenix LiveView admin UI polish for OAuth/OIDC operator support and operations surfaces
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

Phase 109 brings support, operations, configure, and onboarding weak spots up to the v1.29 journey and design-system standard. It prioritizes Tokens, Consents, Interactions, Device Authorizations, Logout Deliveries, DCR/IAT, Keys, and client-detail action grouping, with strongest attention on scanability, mobile behavior, safe actions, and next-step routing.

This phase consumes the Phase 107 journey contract, the Phase 108 component primitives, and the approved Phase 109 UI design contract. It must not restart the admin UI design, introduce a new UI framework, broaden protocol behavior, change storage semantics, expose secret material, or move host-owned operator auth/layout/branding into Lockspire. [VERIFIED: .planning/phases/109-weak-spot-page-polish/109-CONTEXT.md]

### the agent's Discretion

No explicit discretionary section was present in `109-CONTEXT.md`; implementers may decide exact page markup and helper function extraction only where it honors the locked route contracts, Phase 108 primitive API, and existing domain APIs. [VERIFIED: .planning/phases/109-weak-spot-page-polish/109-CONTEXT.md]

### Deferred Ideas (OUT OF SCOPE)

- Full admin screenshot inventory across every route.
- Final route-wide click-through evidence and docs regression proof.
- Demo seed expansion for healthy, warning, incident, disabled, self-registered, retryable, revoked, expired, long-value, and copy-once states.
- Browser screenshot inventory and final proof artifacts for every admin route.
- Visual regression stack or third-party UI framework.
- Host theming engine, Tailwind, shadcn, external component registry, or JS animation dependency.
- New protocol operations, storage semantics, or admin capabilities beyond current Lockspire behavior. [VERIFIED: .planning/phases/109-weak-spot-page-polish/109-CONTEXT.md]
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| OPS-01 | Support pages help operators investigate by account, client, status, incident, and next safe action without leaking secret material. | Use `page_hero`, URL filters, summary metrics, `resource_item`, `long_value`, and redaction assertions on token/consent routes. [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: codebase grep] |
| OPS-02 | Operations pages make waiting, retrying, failed, expired, and completed protocol state scannable without raw-table overload. | Replace logout/interactions tables and device list with status bucket summaries plus resource rows using existing read APIs only. [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: codebase grep] |
| OPS-03 | Long identifiers, client names, URLs, timestamps, statuses, and counts stay readable on mobile without incoherent overlap or page-level horizontal scrolling. | Use existing `long_value` and CSS `overflow-wrap:anywhere`; MDN documents this as a way to break otherwise unbreakable strings to prevent overflow. [CITED: https://developer.mozilla.org/en-US/docs/Web/CSS/Reference/Properties/overflow-wrap] |
| OPS-04 | Risky actions remain visually distinct, confirmation-backed, and copy-clear about consequence and reversibility. | Keep `confirmation_panel`, danger buttons, checkbox confirmation, and consequence-specific copy for token, consent, key, IAT, RAT, and client lifecycle actions. [VERIFIED: codebase grep] |
| OPS-05 | Support and operations pages provide pivot context by client, account/subject, token family, consent, session, or delivery identifier when that context exists. | Existing domain views expose token family/account/client, consent account/client/scopes, interactions account/client/expiration, device client/status/expiration, and logout delivery client/target/status/attempts. [VERIFIED: codebase grep] |
| CONFIG-01 | Client detail and edit workflows group identity, posture, endpoints, credentials, DCR/RAT context, logout, and lifecycle actions in predictable mobile-safe order. | Rework `clients_live/show.ex` action bars into `action_group` sections for routine, security posture, endpoint/logout, credentials/RAT, and lifecycle/destructive actions. [VERIFIED: codebase grep] |
| CONFIG-02 | Security, DCR, IAT, and key lifecycle pages expose current posture, exception pressure, and next actions with consistent page structure. | Preserve DCR/keys lifecycle behavior while adding page hero/job copy, summary buckets, `copy_once_secret_panel` on IAT minting, and long-value wrapping. [VERIFIED: codebase grep] |
</phase_requirements>

## Summary

Phase 109 is a UI recomposition phase, not a behavior phase: use the existing Phoenix LiveView stack, Phase 108 function components, and `Lockspire.Web.Admin.CSS` tokens/classes; do not add packages, route surfaces, storage fields, or protocol operations. [VERIFIED: .planning/phases/109-weak-spot-page-polish/109-CONTEXT.md] [VERIFIED: codebase grep]

The highest-value planning split is by operator journey: Support pages (`/admin/tokens`, `/admin/consents`) need investigation context, filters, result summaries, safe pivots, and secret-redaction proof; Operate pages (`/admin/logouts`, `/admin/device_authorizations`, `/admin/interactions`) need status bucket summaries and responsive queue rows; Configure pages (`/admin/dcr`, `/admin/iats`, `/admin/keys`, `/admin/clients/:client_id`) need targeted vocabulary, copy-once, long-value, and action-group polish. [VERIFIED: .planning/phases/107-admin-journey-contract-ia-audit/107-ROUTE-JOURNEY-CONTRACT.md] [VERIFIED: .planning/phases/109-weak-spot-page-polish/109-UI-SPEC.md]

**Primary recommendation:** Plan Phase 109 as three implementation waves: Support investigation rows/details, Operations queue recomposition, Configure/IAT/keys/client action grouping, with a fourth verification wave extending deterministic LiveView and design-system contract tests. [VERIFIED: codebase grep]

## Project Constraints (from AGENTS.md)

- Lockspire is an embedded OAuth/OIDC authorization server library for Phoenix/Elixir, not a standalone auth service. [VERIFIED: AGENTS.md]
- Host apps own accounts, login UX, layouts, branding, account resolution, claims, login redirects, and product policy. [VERIFIED: AGENTS.md]
- Preserve boundaries between protocol core, storage, generators, Plug/Phoenix integration, and LiveView/admin surfaces. [VERIFIED: AGENTS.md]
- Do not broaden v1 into SAML, LDAP/AD federation, hosted auth, or full CIAM. [VERIFIED: AGENTS.md]
- Preserve security defaults: PKCE S256 by default, exact redirect matching, hashed client secrets, short-lived single-use codes, refresh rotation with family revocation on reuse, no implicit flow, no `alg=none`, and redaction in logs/operator surfaces. [VERIFIED: AGENTS.md]
- Stack targets are Phoenix, Phoenix LiveView, Ecto SQL, PostgreSQL 14+, Bandit, Oban, and OpenTelemetry. Current lockfile versions differ slightly from AGENTS baseline and should be treated as implementation truth unless the planner creates an explicit dependency task. [VERIFIED: AGENTS.md] [VERIFIED: mix deps]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|--------------|----------------|-----------|
| Support investigation page structure | Frontend Server (LiveView) | API / Backend | LiveViews own rendering, filters, and safe pivots; `Lockspire.Admin` owns durable token/consent views and revocation operations. [VERIFIED: codebase grep] |
| Operations queue scanability | Frontend Server (LiveView) | Database / Storage | Existing pages read repository/admin data; Phase 109 should summarize and render state without new storage semantics. [VERIFIED: codebase grep] |
| Destructive confirmation UX | Frontend Server (LiveView) | API / Backend | Confirmation panels and forms live in LiveView; actual revocation/rotation/lifecycle functions remain in Admin/protocol modules. [VERIFIED: codebase grep] |
| Secret redaction and copy-once display | Frontend Server (LiveView) | API / Backend | UI must never render durable plaintext; backend already returns copy-once values only at mint/rotation moments. [VERIFIED: codebase grep] |
| Mobile no-overflow behavior | Browser / Client CSS | Frontend Server (LiveView) | CSS `overflow-wrap:anywhere`, responsive rows, and stacked action groups own mobile behavior; LiveViews must use the right classes/components. [VERIFIED: codebase grep] [CITED: https://developer.mozilla.org/en-US/docs/Web/CSS/Reference/Properties/overflow-wrap] |

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `phoenix` | locked `1.8.7`; configured `~> 1.8.5` | Phoenix router, endpoint, LiveView host infrastructure | Existing project framework; no framework change in this phase. [VERIFIED: mix deps] [VERIFIED: Hex registry] |
| `phoenix_live_view` | locked `1.1.30`; latest stable seen `1.1.31`; `1.2.0-rc.3` is release-candidate | Server-rendered LiveViews, HEEx, function components, LiveView tests | Existing admin UI is LiveView; official docs define function components with `attr` and `slot` validation. [VERIFIED: mix deps] [VERIFIED: Hex registry] [CITED: https://phoenix-live-view.hexdocs.pm/Phoenix.Component.html] |
| `ecto_sql` | locked `3.13.5`; latest seen `3.14.0` | SQL storage and migrations | Existing durable stores are Ecto/PostgreSQL-backed; Phase 109 should read existing data only. [VERIFIED: mix deps] [VERIFIED: Hex registry] |
| `postgrex` | locked `0.22.2` | PostgreSQL adapter | Existing test/repo stack uses PostgreSQL adapter semantics. [VERIFIED: mix deps] |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `bandit` | locked `1.11.1` | HTTP server | Existing Phoenix server; no Phase 109 changes expected. [VERIFIED: mix deps] [VERIFIED: Hex registry] |
| `oban` | locked `2.21.1` | Logout delivery jobs and background workflow context | Use only as existing logout propagation context; do not add retry/discard UI unless backed by current APIs. [VERIFIED: mix deps] [VERIFIED: codebase grep] |
| `opentelemetry_api` | locked `1.5.0` | Telemetry API | Existing observability dependency; Phase 109 should not add new telemetry unless behavior changes, which is out of scope. [VERIFIED: mix deps] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Existing Phoenix function components | Tailwind/shadcn/external UI registry | Out of scope and contradicts locked decisions. [VERIFIED: .planning/phases/109-weak-spot-page-polish/109-CONTEXT.md] |
| Deterministic ExUnit/source tests | Full visual regression stack | Full screenshot inventory is Phase 110 scope. [VERIFIED: .planning/phases/109-weak-spot-page-polish/109-CONTEXT.md] |
| Resource rows and summaries | Raw tables as primary UI | Raw tables are the known weak spot for operations pages and mobile scanability. [VERIFIED: .planning/phases/107-admin-journey-contract-ia-audit/107-ROUTE-JOURNEY-CONTRACT.md] |

**Installation:**

No new packages. Use the current `mix.exs` and `mix.lock`. [VERIFIED: mix deps]

## Package Legitimacy Audit

No external packages should be installed in Phase 109, so the Package Legitimacy Gate is not applicable. [VERIFIED: .planning/phases/109-weak-spot-page-polish/109-CONTEXT.md]

**Packages removed due to slopcheck [SLOP] verdict:** none; no package installation is recommended. [VERIFIED: research scope]
**Packages flagged as suspicious [SUS]:** none; no package installation is recommended. [VERIFIED: research scope]

## Architecture Patterns

### System Architecture Diagram

```text
Host-mounted /admin route
  -> Phoenix LiveView route
    -> handle_params/3 normalizes URL filters where applicable
    -> Lockspire.Admin or Repository read API loads durable metadata
    -> LiveView derives page-local status buckets and pivot context
    -> AdminComponents render page_hero + filter_bar + metric_grid + resource_list/resource_item
      -> long_value wraps IDs/URLs/timestamps
      -> confirmation_panel/action_group separates risky actions
    -> Existing Admin/protocol API performs confirmed mutation only where already supported
```

This flow matches LiveView's lifecycle: `mount/3`, then `handle_params/3`, then `render/1`, with connected LiveViews receiving events through `phx-` bindings. [CITED: https://phoenix-live-view.hexdocs.pm/Phoenix.LiveView.html#module-life-cycle]

### Recommended Project Structure

```text
lib/lockspire/web/live/admin/
├── tokens_live/                 # Support token investigation list/detail
├── consents_live/               # Support consent investigation list/detail
├── logout_deliveries_live/      # Operate logout propagation queue
├── device_authorizations_live/  # Operate device-code queue
├── interactions_live/           # Operate authorization interaction queue
├── dcr_live/                    # Configure DCR onboarding
├── iat_live/                    # Configure IAT inventory/minting
├── keys_live/                   # Configure key lifecycle
└── clients_live/show.ex         # Client detail action grouping
```

Keep shared primitives in `lib/lockspire/web/components/admin_components.ex` and responsive CSS in `lib/lockspire/web/admin_css.ex`. [VERIFIED: codebase grep]

### Pattern 1: Page-Owned Data, Shared Structural Components

**What:** LiveViews derive domain-specific summaries and pass rendered content into generic function components. Phoenix function components support declared `attr` and `slot` contracts, including named slots for composition. [CITED: https://phoenix-live-view.hexdocs.pm/Phoenix.Component.html]

**When to use:** Use for all Phase 109 target routes. Keep domain logic and status bucketing in the page module when it is page-specific; extract only if two or more pages share exact logic. [VERIFIED: codebase grep]

**Example:**

```elixir
<AdminComponents.page_hero eyebrow="Support" title="Token investigation">
  <:summary>
    <span>Filtered by account, client, and status</span>
  </:summary>
</AdminComponents.page_hero>

<AdminComponents.resource_item title={client_name} href={token_path}>
  <:meta>
    <AdminComponents.long_value kind={:id} value={family_handle} />
  </:meta>
  <:status>
    <AdminComponents.status_badge status={status} />
  </:status>
</AdminComponents.resource_item>
```

Source: existing `AdminComponents` APIs and Phoenix.Component docs. [VERIFIED: codebase grep] [CITED: https://phoenix-live-view.hexdocs.pm/Phoenix.Component.html]

### Pattern 2: URL-Driven Filters Stay Explicit

**What:** Token and consent indexes already normalize URL params and pass them into `Admin.list_tokens/1` and `Admin.list_consents/1`; preserve this pattern and only improve labels, summaries, and rows. [VERIFIED: codebase grep]

**When to use:** Use for `/admin/tokens` and `/admin/consents`; do not hide filters inside a generic component that owns domain criteria. [VERIFIED: .planning/phases/109-weak-spot-page-polish/109-CONTEXT.md]

### Pattern 3: Status Buckets Before Queue Rows

**What:** Operations pages should compute counts by domain status before rendering records. Logout statuses include `:pending`, `:enqueued`, `:delivered`, `:failed`, `:retryable`, and `:discarded`; interactions include active `:pending_login` and `:pending_consent` plus closed `:completed`, `:denied`, and `:expired`; device authorization statuses are supplied by `DeviceAuthorization.statuses/0` and current UI/tests show `:pending`. [VERIFIED: codebase grep]

**When to use:** Use for `/admin/logouts`, `/admin/device_authorizations`, and `/admin/interactions`. [VERIFIED: .planning/phases/109-weak-spot-page-polish/109-UI-SPEC.md]

### Anti-Patterns to Avoid

- **Generic action labels:** Replace newly touched `Apply`, `Mint IAT`, `Cancel`, `Revoke`, `Rotate secret`, and `Rotate RAT` with noun-specific labels where the UI contract requires it. [VERIFIED: .planning/phases/109-weak-spot-page-polish/109-UI-SPEC.md] [VERIFIED: codebase grep]
- **Raw table first content:** Logout deliveries and interactions currently render tables; make resource rows and status summaries the primary scanning UI. [VERIFIED: codebase grep]
- **Secret-like pivot context:** Show durable handles, hashed/display handles, client IDs, subject/account IDs, timestamps, statuses, endpoint URLs, and redacted placeholders only; do not show plaintext tokens, user codes, client secrets, RATs, IAT secrets, or verifier material. [VERIFIED: AGENTS.md] [VERIFIED: .planning/phases/109-weak-spot-page-polish/109-UI-SPEC.md]
- **Invented operations:** Retry/discard polish must be omitted unless current domain APIs support it; current grep found revocation/rotation/key lifecycle APIs but no admin-facing logout retry/discard API. [VERIFIED: codebase grep]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Component abstraction | New UI framework or custom mini-framework | `Lockspire.Web.Components.AdminComponents` | Phase 108 already provides `page_hero`, `filter_bar`, `metric_grid`, `resource_item`, `long_value`, `action_group`, `confirmation_panel`, and `copy_once_secret_panel`. [VERIFIED: codebase grep] |
| Long ID/URL wrapping | Ad hoc `<code>` styles per page | `long_value` and CSS `overflow-wrap:anywhere` | MDN documents `overflow-wrap` as preventing overflow for otherwise unbreakable strings. [CITED: https://developer.mozilla.org/en-US/docs/Web/CSS/Reference/Properties/overflow-wrap] |
| Confirmation flows | Browser-only confirm strings for complex destructive work | `confirmation_panel` with checkbox and danger action | Existing token, consent, key, client secret, and RAT flows use server-confirmed forms/events. [VERIFIED: codebase grep] |
| Secret reveal panels | Ad hoc code blocks | `copy_once_secret_panel` | Existing component centralizes copy-once/redacted presentation. [VERIFIED: codebase grep] |
| LiveView event tests | Manual event bypass where form inputs exist | `live/2`, `element/3`, `form/3`, `render_submit/1`, `render_click/1` | LiveViewTest documents these helpers and warns against bypassing rendered form validation unnecessarily. [CITED: https://phoenix-live-view.hexdocs.pm/Phoenix.LiveViewTest.html] |

**Key insight:** The hard part is not CSS invention; it is preserving OAuth/OIDC truth and redaction while making existing durable state scannable. [VERIFIED: AGENTS.md] [VERIFIED: .planning/phases/109-weak-spot-page-polish/109-CONTEXT.md]

## Common Pitfalls

### Pitfall 1: Turning UI Polish Into Protocol Behavior

**What goes wrong:** Planner adds retry/discard, new state transitions, new filters, or new storage fields to satisfy copy. [VERIFIED: .planning/phases/109-weak-spot-page-polish/109-CONTEXT.md]

**Why it happens:** Operations queue copy asks for next actions, but current APIs may only support read-only inspection for some queues. [VERIFIED: codebase grep]

**How to avoid:** Plan read-only summaries first; add action affordances only for existing functions. [VERIFIED: codebase grep]

**Warning signs:** Tasks mention migrations, new repository callbacks, or new protocol modules for Phase 109. [VERIFIED: .planning/phases/109-weak-spot-page-polish/109-CONTEXT.md]

### Pitfall 2: Leaking Secrets Through "Useful Context"

**What goes wrong:** Rows or confirmation panels include token hashes, user-code hashes, raw user codes, client secrets, IAT/RAT plaintext after creation, or verifier material. [VERIFIED: AGENTS.md] [VERIFIED: .planning/phases/109-weak-spot-page-polish/109-UI-SPEC.md]

**Why it happens:** Support pages need pivots, and developers may confuse durable identifiers with recoverable credentials. [VERIFIED: .planning/phases/109-weak-spot-page-polish/109-CONTEXT.md]

**How to avoid:** Assert forbidden strings in focused tests; reuse redacted display text and `copy_once_secret_panel`. [VERIFIED: codebase grep]

**Warning signs:** Tests or screenshots include `token_hash`, `device_code_hash`, `user_code_hash`, `client_secret`, `registration_access_token`, or IAT plaintext outside the immediate copy-once result panel. [VERIFIED: codebase grep]

### Pitfall 3: Mobile Overflow Hidden Inside Nested Lists

**What goes wrong:** Long client IDs, URLs, key IDs, delivery IDs, interaction IDs, token family handles, or timestamps force page-level horizontal scroll. [VERIFIED: .planning/phases/109-weak-spot-page-polish/109-UI-SPEC.md]

**Why it happens:** Existing pages often render raw `<code>` or table cells; tables may still scroll even when the primary mobile experience should not. [VERIFIED: codebase grep]

**How to avoid:** Replace primary weak-page lists/tables with `resource_item`; wrap long values with `long_value`; preserve table wrappers only as fallback where a table remains. [VERIFIED: codebase grep]

**Warning signs:** New markup adds `<code>{id}</code>` or `<td>{url}</td>` without `long_value` or a wrapping class. [VERIFIED: codebase grep]

### Pitfall 4: Broad Snapshot Tests Instead Of Contract Tests

**What goes wrong:** Tests become brittle full HTML snapshots or try to prove Phase 110 screenshot inventory early. [VERIFIED: .planning/phases/109-weak-spot-page-polish/109-CONTEXT.md]

**Why it happens:** UI polish is visual, but current project proof pattern is deterministic source and focused LiveView tests. [VERIFIED: test/lockspire/web/live/admin/design_system_contract_test.exs]

**How to avoid:** Extend existing focused tests with labels, primitive class presence, redaction, no generic CTA labels, and no inline/admin-class drift. [VERIFIED: codebase grep]

**Warning signs:** Plan adds Playwright visual regression or route-wide screenshot proof as a blocking Phase 109 deliverable. [VERIFIED: .planning/phases/109-weak-spot-page-polish/109-CONTEXT.md]

## Code Examples

### Status Bucket Helper

```elixir
defp status_counts(records) do
  Enum.frequencies_by(records, & &1.status)
end
```

Use page-local helpers like this for operations queue summaries; do not persist derived counts. [VERIFIED: codebase grep]

### Long Value In Resource Rows

```elixir
<AdminComponents.resource_item title={delivery.client_id}>
  <:meta>
    <AdminComponents.long_value kind={:id} value={delivery.delivery_id} />
    <AdminComponents.long_value kind={:url} value={delivery.target_uri} />
  </:meta>
  <:status>
    <AdminComponents.status_badge status={delivery.status} />
  </:status>
</AdminComponents.resource_item>
```

Source: existing `resource_item`, `long_value`, and logout delivery fields. [VERIFIED: codebase grep]

### Copy-Once IAT Result

```elixir
<AdminComponents.copy_once_secret_panel
  title="Initial access token minted"
  body="Copy it now. Lockspire does not store or re-show plaintext initial access tokens."
  label="Initial access token"
  value={@iat_secret}
/>
```

Source: existing component and IAT mint flow. [VERIFIED: codebase grep]

### LiveView Test Pattern

```elixir
{:ok, view, html} = live(conn_for_admin(), "/admin/iats/new")
refute html =~ "Secret revealed"

html_after_mint =
  view
  |> form("form", %{"single_use" => "true", "expires_in_days" => "30"})
  |> render_submit()

assert html_after_mint =~ "copy once"
```

LiveViewTest supports `live/2`, `element/3`, `render_click/1`, `form/3`, and `render_submit/1`; it warns that bypassing visible form inputs with direct submit values can miss form-name regressions. [CITED: https://phoenix-live-view.hexdocs.pm/Phoenix.LiveViewTest.html]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Raw table/list first operations pages | Status summaries plus responsive resource rows | Locked by Phase 109 UI contract on 2026-06-04 | Planner should prioritize queue scanability before per-record density. [VERIFIED: .planning/phases/109-weak-spot-page-polish/109-UI-SPEC.md] |
| Ad hoc copy-once code block | `copy_once_secret_panel` | Phase 108 component foundation | IAT minting should align with client secret/RAT copy-once treatment. [VERIFIED: codebase grep] |
| Dense undifferentiated client action bar | Multiple `action_group` sections | Phase 109 decision D-15 | Routine edits, credentials, DCR/RAT, endpoints/logout, posture, and destructive lifecycle actions should not compete in one strip. [VERIFIED: .planning/phases/109-weak-spot-page-polish/109-CONTEXT.md] |

**Deprecated/outdated:**

- Newly touched generic labels `Apply`, `Cancel`, `Revoke`, `Mint IAT`, `Rotate secret`, and `Rotate RAT` are outdated for Phase 109 because the UI contract requires visible verb-plus-noun labels. [VERIFIED: .planning/phases/109-weak-spot-page-polish/109-UI-SPEC.md] [VERIFIED: codebase grep]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Phase 109 uses deterministic no-overflow proxy tests as the default mobile proof; focused manual/browser 390px proof is required only if CSS layout primitives change. [RESOLVED] | Validation Architecture | If shared CSS layout primitives change and browser proof is skipped, mobile overflow could be under-tested. |

## Open Questions (RESOLVED)

1. **RESOLVED: Does the planner want a small browser/mobile smoke proof despite Phase 110 owning screenshots?**
   - What we know: Phase 109 says focused mobile/no-overflow proof where feasible; Phase 110 owns broad screenshots. [VERIFIED: .planning/phases/109-weak-spot-page-polish/109-CONTEXT.md]
   - Selected strategy: Phase 109 uses deterministic no-overflow proxy tests for `long_value`, responsive `resource_item`, filter wrapping, and stacked `action_group` usage on target routes. [RESOLVED]
   - Browser/manual proof trigger: focused 390px proof is required only if implementation changes shared CSS layout primitives such as resource-row layout, long-value wrapping, filter layout, or action-group stacking. [RESOLVED]
   - Scope boundary: broad screenshot inventory, route-wide browser click-through, docs proof, and demo-seed coverage remain Phase 110 scope. [RESOLVED]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Elixir | Compile/tests | yes | 1.19.5 / OTP 28 | none needed. [VERIFIED: local command] |
| Mix | Compile/tests | yes | 1.19.5 | none needed. [VERIFIED: local command] |
| PostgreSQL client | Ecto-backed LiveView tests | yes | `psql` 14.17 | existing test repo setup. [VERIFIED: local command] |
| Node/npm | Optional browser/mobile proof if planner chooses it | yes | Node 22.14.0 / npm 11.1.0 | Prefer ExUnit/source tests for Phase 109. [VERIFIED: local command] |
| Context7 CLI | Documentation lookup | no | not installed | Used official HexDocs/MDN/OWASP pages directly. [VERIFIED: local command] |

**Missing dependencies with no fallback:** none for the recommended Phase 109 plan. [VERIFIED: local command]

**Missing dependencies with fallback:** Context7 CLI missing; official docs were fetched via web. [VERIFIED: local command] [CITED: https://phoenix-live-view.hexdocs.pm/Phoenix.Component.html]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit plus Phoenix.LiveViewTest from `phoenix_live_view` locked `1.1.30`. [VERIFIED: mix deps] |
| Config file | `test/test_helper.exs` and project test setup. [VERIFIED: codebase grep] |
| Quick run command | `mix test test/lockspire/web/live/admin/design_system_contract_test.exs --max-failures 1` [VERIFIED: local command] |
| Full suite command | `mix test` [VERIFIED: mix.exs] |

### Phase Requirements -> Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| OPS-01 | Token/consent support pages show investigation context and no secrets | LiveView unit/integration | `mix test test/lockspire/web/live/admin/tokens_live_test.exs test/lockspire/web/live/admin/consents_live_test.exs --max-failures 1` | yes [VERIFIED: filesystem] |
| OPS-02 | Operations pages show status buckets and rows | LiveView unit/integration | `mix test test/lockspire/web/live/admin/logout_deliveries_live_test.exs test/lockspire/web/live/admin/device_authorizations_live_test.exs test/lockspire/web/live/admin/interactions_live_test.exs --max-failures 1` | yes [VERIFIED: filesystem] |
| OPS-03 | Long values use wrapping primitives/classes | Source contract + focused LiveView assertions | `mix test test/lockspire/web/live/admin/design_system_contract_test.exs --max-failures 1` | yes [VERIFIED: filesystem] |
| OPS-04 | Risky actions are danger/confirmation-backed with consequence copy | LiveView unit/integration | `mix test test/lockspire/web/live/admin/tokens_live_test.exs test/lockspire/web/live/admin/consents_live_test.exs test/lockspire/web/live/admin/keys_live_test.exs test/lockspire/web/live/admin/iat_live_test.exs --max-failures 1` | yes [VERIFIED: filesystem] |
| OPS-05 | Support/operations pages show pivot context | Focused route tests | same as OPS-01 and OPS-02 commands | yes [VERIFIED: filesystem] |
| CONFIG-01 | Client detail actions are grouped and mobile-safe | LiveView unit/integration + source contract | `mix test test/lockspire/web/live/admin/clients_live/show_test.exs --max-failures 1` | yes [VERIFIED: filesystem] |
| CONFIG-02 | DCR/IAT/keys show posture and next actions | LiveView unit/integration | `mix test test/lockspire/web/live/admin/iat_live_test.exs test/lockspire/web/live/admin/keys_live_test.exs --max-failures 1` | yes [VERIFIED: filesystem] |

### Sampling Rate

- **Per task commit:** Run the focused route test for the touched surface plus `mix test test/lockspire/web/live/admin/design_system_contract_test.exs --max-failures 1`. [VERIFIED: local command]
- **Per wave merge:** Run all touched admin LiveView tests listed in the test map. [VERIFIED: filesystem]
- **Phase gate:** Run `mix test`. [VERIFIED: mix.exs]

### Wave 0 Gaps

- [ ] Extend `test/lockspire/web/live/admin/design_system_contract_test.exs` for Phase 109-specific generic CTA, primitive usage, `long_value`, and no-inline-style checks. [VERIFIED: codebase grep]
- [ ] Extend focused route tests with Phase 109 labels, summaries, redaction, action grouping, and confirmation copy. [VERIFIED: filesystem]
- [ ] Add deterministic no-overflow proxy assertions for `lockspire-admin-long-value`, responsive `resource_item`, and stacked `action_group` use on target routes. [ASSUMED]

## Security Domain

### Applicable ASVS Categories

OWASP ASVS 5.0.0 is the current stable ASVS version according to OWASP's project page. [CITED: https://owasp.org/www-project-application-security-verification-standard/]

| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V2 Authentication | no direct change | Host owns staff authentication; preserve embedded boundary. [VERIFIED: AGENTS.md] |
| V3 Session Management | no direct change | Host/Phoenix session handling unchanged. [VERIFIED: AGENTS.md] |
| V4 Access Control | yes, boundary preservation | Do not add Lockspire-owned staff roles or tenant policy. [VERIFIED: AGENTS.md] |
| V5 Input Validation | yes | Existing URL filter normalization and existing Admin/Repository APIs; no new query semantics. [VERIFIED: codebase grep] |
| V6 Cryptography | yes, redaction/lifecycle display only | Never hand-roll crypto or expose private key/token/secret material; keys page shows public JWK metadata only. [VERIFIED: AGENTS.md] [VERIFIED: codebase grep] |
| V9 Communications | yes for endpoint display | Display logout/client URLs as configuration context only; no network action unless existing domain API supports it. [VERIFIED: codebase grep] |
| V14 Configuration | yes | Preserve DCR policy/onboarding vocabulary and key/client posture separation. [VERIFIED: .planning/phases/109-weak-spot-page-polish/109-CONTEXT.md] |

### Known Threat Patterns for Phoenix LiveView Admin UI

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Secret disclosure in rendered HTML | Information Disclosure | Redaction tests plus `copy_once_secret_panel` only for immediate mint/rotation output. [VERIFIED: codebase grep] |
| Wrong-resource destructive action | Tampering | Confirmation panels must name non-secret durable context and consequence. [VERIFIED: .planning/phases/109-weak-spot-page-polish/109-UI-SPEC.md] |
| UI suggests unsupported retry/discard operation | Tampering / Repudiation | Only render mutation controls backed by current Admin/protocol APIs. [VERIFIED: codebase grep] |
| XSS via long IDs/URLs | Tampering / Information Disclosure | Keep HEEx interpolation and components; do not mark user/domain values raw. Phoenix HEEx is the existing rendering mechanism. [VERIFIED: codebase grep] [CITED: https://phoenix-live-view.hexdocs.pm/Phoenix.Component.html] |
| Motion/accessibility regression | Denial of Service | Preserve `prefers-reduced-motion`; MDN documents it as a user preference to reduce non-essential motion. [CITED: https://developer.mozilla.org/en-US/docs/Web/CSS/Reference/At-rules/@media/prefers-reduced-motion] |

## Sources

### Primary (HIGH confidence)

- `.planning/phases/109-weak-spot-page-polish/109-CONTEXT.md` - locked decisions, canonical refs, deferred scope. [VERIFIED: filesystem]
- `.planning/phases/109-weak-spot-page-polish/109-UI-SPEC.md` - approved Phase 109 UI contract. [VERIFIED: filesystem]
- `.planning/phases/107-admin-journey-contract-ia-audit/107-ROUTE-JOURNEY-CONTRACT.md` - route journeys and weak-spot audit. [VERIFIED: filesystem]
- `lib/lockspire/web/components/admin_components.ex` and `lib/lockspire/web/admin_css.ex` - component/CSS API truth. [VERIFIED: codebase grep]
- Target LiveViews/tests under `lib/lockspire/web/live/admin/` and `test/lockspire/web/live/admin/`. [VERIFIED: codebase grep]
- Official Phoenix LiveView docs: `Phoenix.Component`, `Phoenix.LiveView`, `Phoenix.LiveViewTest`, `Phoenix.LiveView.JS`. [CITED: https://phoenix-live-view.hexdocs.pm/Phoenix.Component.html]
- MDN `overflow-wrap` and `prefers-reduced-motion`. [CITED: https://developer.mozilla.org/en-US/docs/Web/CSS/Reference/Properties/overflow-wrap] [CITED: https://developer.mozilla.org/en-US/docs/Web/CSS/Reference/At-rules/@media/prefers-reduced-motion]
- OWASP ASVS project page. [CITED: https://owasp.org/www-project-application-security-verification-standard/]

### Secondary (MEDIUM confidence)

- Hex registry metadata from `mix hex.info` for Phoenix, Phoenix LiveView, Ecto SQL, Bandit, Oban, and OpenTelemetry API. [VERIFIED: Hex registry]

### Tertiary (LOW confidence)

- Assumption that deterministic no-overflow proxy tests are sufficient unless CSS layout primitives change. [ASSUMED]

## Metadata

**Confidence breakdown:**

- Standard stack: HIGH - current versions verified by `mix deps` and Hex registry; no new packages. [VERIFIED: mix deps] [VERIFIED: Hex registry]
- Architecture: HIGH - route/component ownership verified from project context and codebase. [VERIFIED: codebase grep]
- Pitfalls: HIGH - pitfalls come from locked Phase 109 decisions and observed weak-page code. [VERIFIED: .planning/phases/109-weak-spot-page-polish/109-CONTEXT.md] [VERIFIED: codebase grep]

**Research date:** 2026-06-04
**Valid until:** 2026-07-04 for local architecture; re-check HexDocs/Hex versions if planning changes dependencies. [ASSUMED]
