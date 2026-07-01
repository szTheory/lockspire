# Phase 122: Support Investigation Flow Polish - Research

**Researched:** 2026-06-28
**Domain:** Phoenix LiveView admin Support workflow polish for OAuth/OIDC token and consent investigation
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

Source for this entire section: [VERIFIED: 122-CONTEXT.md]

### Locked Decisions

#### D-01 — Phase 122 scope is the existing Support token/consent investigation surface only

This phase is limited to:

- `/admin/tokens`
- `/admin/tokens/:id`
- `/admin/consents`
- `/admin/consents/:id`

No new admin routes, storage behavior, host hooks, public customization surface, unsupported controls, bulk actions, reveal/export/debug controls, or protocol capabilities belong in this phase.

#### D-02 — LiveViews stay route owners; reusable structure belongs in function components

Keep URL filters, assigns, events, validation, and Admin API calls in the existing LiveViews.

Use shared function components only for reusable presentation structure and interaction primitives, especially:

- `decision_summary`
- `entity_header`
- `dense_resource_row`
- `long_value`
- `confirmation_panel`
- existing form/error/action primitives

Do not introduce a route-specific component layer unless a repeated pattern is clearly shared across token and consent pages.

#### D-03 — Domain reads and mutations must stay behind existing Admin APIs

Use existing Admin boundaries:

- `Lockspire.Admin.Tokens`
- `Lockspire.Admin.Consents`
- existing `Lockspire.Admin` delegations

Do not add raw Ecto queries in LiveViews.

Do not add token or consent capabilities. This is a support-flow clarity phase, not a domain expansion phase.

#### D-04 — A narrow helper/read-model layer is allowed only for page summary logic

It is acceptable to add private helper functions or a narrow internal read-model helper when duplicated summary predicates would otherwise put security-sensitive decisions directly in templates.

This helper layer may classify display-only support states such as:

- already revoked
- expired
- reuse detected
- no refresh family
- selected filters summary
- smallest safe action
- revocation consequence copy

It must not bypass Admin APIs or become a new mutation path.

#### D-05 — The page spine is fixed: compact orientation first, then filters/lists/details/actions

Each of the four pages should read as:

1. compact `page_hero`
2. exact page-appropriate `decision_summary`
3. filters or entity header
4. dense support evidence
5. confirmation/action panel where relevant

The goal is a calm support workflow, not a metadata inventory.

#### D-06 — Token index decision summary items are fixed

Token index must summarize:

- `Selected filters`
- `Token health`
- `Family pressure`
- `Smallest safe action`

#### D-07 — Token detail decision summary items are fixed

Token detail must summarize:

- `Token health`
- `Family lineage`
- `Reuse pressure`
- `Smallest safe action`

#### D-08 — Consent index decision summary items are fixed

Consent index must summarize:

- `Selected filters`
- `Grant status`
- `Scope context`
- `Smallest safe action`

#### D-09 — Consent detail decision summary items are fixed

Consent detail must summarize:

- `Grant status`
- `Scope context`
- `Client/account pivot`
- `Revocation consequence`

#### D-10 — Support labels must use explicit investigation vocabulary

Use support workflow labels such as:

- `Filter tokens`
- `Review token`
- `Revoke token`
- `Revoke token family`
- `Filter consent grants`
- `Review stored grant`
- `Revoke consent grant`

Avoid generic labels like `Submit`, `Details`, `Manage`, `Open`, `View`, `Delete`, `Disable`, or labels that imply unsupported domain behavior.

#### D-11 — Index rows should become dense support rows, not responsive tables

Token and consent index rows should move toward `dense_resource_row` when it reduces custom markup.

Rows should lead with the support question:

- token row: health/status and token type first, then redacted client/account/family, timestamp, and `Review token`
- consent row: grant status/kind first, then client/account/scope/timestamp, and `Review stored grant`

Do not use responsive tables as the primary support experience.

#### D-12 — Long and sensitive values must be rendered through safe primitives

Use:

- `long_value`
- `timestamp`
- redacted handles
- status text
- semantic tokens
- mobile stacking styles

Never render plaintext tokens, token hashes, secrets, verifiers, cookies, auth codes, user-code material, or raw sensitive account values.

#### D-13 — Confirmation panels must make closed states explicit

For already revoked tokens/consents, expired/non-actionable states, and missing refresh family:

- render controls disabled or de-emphasized
- include adjacent explanation copy
- keep backend commands idempotent
- avoid presenting an action that looks newly available when it is already closed

#### D-14 — Closed-state predicates must be explicit, not just `status == :revoked`

Token UI cannot rely only on `status == :revoked`, because a token with `reuse_detected_at` can still be security-relevant even when `revoked_at` is present.

Use explicit predicates for:

- `revoked_at` present
- `reuse_detected_at` present
- refresh family present/missing
- family-wide action availability

#### D-15 — Missing confirmation errors have fixed copy

Use exact missing-checkbox messages:

- `Select the confirmation checkbox to revoke this token.`
- `Select the confirmation checkbox to revoke this refresh family.`
- `Select the confirmation checkbox to revoke this consent grant.`

#### D-16 — Already-revoked and no-family explanatory copy is fixed

Use exact closed-state copy:

- token already revoked: `This token is already revoked. No further token action is available.`
- consent already revoked: `This consent grant is already revoked. It no longer authorizes future remembered-consent reuse.`
- no refresh family: `This token is not part of a refresh family, so family-wide revocation is unavailable.`

#### D-17 — Backend mutation failure copy must not sound final

For a failed token revocation command, use this shape:

`Revocation could not be confirmed. The token may still be active; reload this Support workflow before retrying.`

Use the same shape for consent:

`Revocation could not be confirmed. The consent grant may still be active; reload this Support workflow before retrying.`

Do not say only `failed`, `try again`, or imply the action definitely did or did not happen.

#### D-18 — Family revocation copy must be precise about what is counted

If the UI references a count from the backend, do not call it "active tokens" unless the backend count is actually active, unexpired, unrevoked tokens.

Prefer copy such as:

- `This revokes currently unrevoked tokens in the refresh family.`
- `Reuse evidence means family-wide revocation is the safest available token action.`

#### D-19 — Error rendering must use accessible error primitives

Validation and mutation errors should render through `error_summary`, `error_list`, or equivalent alert/error semantics.

Closed-state informational notices should be calm explanatory text, not urgent alerts.

#### D-20 — Do not imply host-owned or unsupported effects

Support copy must not imply:

- host logout
- account suspension
- consent revocation outside stored Lockspire grant records
- background worker control
- plaintext token recovery
- broader protocol-side behavior not implemented in existing Admin APIs

#### D-21 — Preserve the v1.31/v1.32 design-system boundary

Use Phoenix function components, `lockspire-admin-*` classes, and `--ls-*` tokens.

Do not add:

- Tailwind
- shadcn
- Storybook
- public theming APIs
- host design registries
- public component documentation

The component lab/proof surface remains internal only.

#### D-22 — Responsive behavior must avoid page-level overflow and color-only state

Support pages must remain usable at narrow widths.

Plan for:

- stacked rows
- wrapping filters
- non-overlapping actions
- long identifiers with safe wrapping
- status text alongside color
- visible focus and error states

Do not rely on color alone to express destructive, revoked, expired, or reuse-detected states.

### the agent's Discretion

- Exact helper names and whether summary logic remains private functions in each LiveView or moves into a tiny shared display helper.
- Exact phrasing for non-locked summary details, as long as it stays calm, support-oriented, and does not imply unsupported behavior.
- Exact CSS refinements, as long as they stay inside existing admin CSS/token boundaries.
- Whether to add focused tests in existing LiveView test files or shared admin design contract tests, as long as `SUPPORT-01` through `SUPPORT-03` are covered.

### Deferred Ideas (OUT OF SCOPE)

- A new `/admin/support` route or cross-resource support dashboard.
- Host extension hooks for support workflow customization.
- New responsive table primitive work.
- A dedicated `support_investigation_row` component.
- Modal or route-based confirmation flows.
- Public Storybook/PhoenixStorybook publishing.
- Public design-system documentation, public theming, or host registry APIs.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| SUPPORT-01 | Support operator can use token index/detail to understand selected filters, token health, token family context, smallest safe action, and incident pressure without plaintext secrets or redundant dumps. [VERIFIED: .planning/REQUIREMENTS.md] | Existing token routes and tests are in `tokens_live/index.ex`, `tokens_live/show.ex`, and `tokens_live_test.exs`; planner should add decision summaries, dense index rows, closed-state predicates, redacted values, and exact confirmation copy while keeping mutations behind `Lockspire.Admin.Tokens`. [VERIFIED: codebase] |
| SUPPORT-02 | Support operator can use consent index/detail to understand selected filters, grant status, scope context, client/account pivots, and revocation consequences without secret material or misleading domain implications. [VERIFIED: .planning/REQUIREMENTS.md] | Existing consent routes and tests are in `consents_live/index.ex`, `consents_live/show.ex`, and `consents_live_test.exs`; planner should add decision summaries, dense index rows, redacted pivots, and exact revoke panel states while keeping mutations behind `Lockspire.Admin.Consents`. [VERIFIED: codebase] |
| SUPPORT-03 | Empty, no-match, revoked, expired, reuse-detected, long identifier, dense result, validation-error, and already-revoked states have concise consequence copy. [VERIFIED: .planning/REQUIREMENTS.md] | Existing admin component/test infrastructure covers `empty_state`, `long_value`, `dense_resource_row`, `confirmation_panel`, `error_summary`, `error_list`, and admin proof assertions; planner should extend route-specific tests for these states rather than add new tooling. [VERIFIED: codebase] |
</phase_requirements>

## Summary

Phase 122 should be planned as a focused Phoenix LiveView presentation and copy polish over four existing Support routes, not as a domain or storage expansion. [VERIFIED: 122-CONTEXT.md] The current code already has the required component primitives, route modules, Admin API boundaries, fixtures, and route-specific tests; the main work is to reshape token/consent index and detail pages into decision-first workflows with dense rows, safe long values, exact destructive-action copy, and accessible errors. [VERIFIED: codebase]

The riskiest planning area is not layout; it is preserving security meaning while simplifying the UI. [VERIFIED: 122-CONTEXT.md] Token state must not collapse to `status == :revoked` because current Admin status computation can classify a token as `:reuse_detected` before `:revoked`, even when `revoked_at` is present. [VERIFIED: codebase] Planner tasks should require explicit predicates for `revoked_at`, `reuse_detected_at`, and family presence, and should verify no plaintext tokens, hashes, secrets, verifiers, cookies, auth codes, or raw sensitive account values render. [VERIFIED: 122-CONTEXT.md]

**Primary recommendation:** Use existing LiveView modules plus existing admin function components; add narrow private display helpers only where summary/closed-state predicates would otherwise duplicate fragile security logic in templates. [VERIFIED: 122-CONTEXT.md]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|--------------|----------------|-----------|
| Support route ownership | Frontend Server / LiveView | Browser / Client | Admin routes are existing Phoenix LiveViews, and URL filters/events/assigns stay in those LiveViews. [VERIFIED: codebase] [VERIFIED: 122-CONTEXT.md] |
| Token/consent domain reads | API / Backend | Database / Storage | Reads must go through `Lockspire.Admin.Tokens`, `Lockspire.Admin.Consents`, or `Lockspire.Admin` delegations, which then use storage/repository code. [VERIFIED: codebase] [VERIFIED: 122-CONTEXT.md] |
| Token/consent revocation | API / Backend | Database / Storage | Mutations already exist as Admin API calls; this phase must not add capabilities or raw LiveView Ecto writes. [VERIFIED: codebase] [VERIFIED: 122-CONTEXT.md] |
| Decision summary display | Frontend Server / LiveView | Component Layer | Summary values come from route assigns/helper predicates and render through `decision_summary`. [VERIFIED: codebase] [VERIFIED: 122-CONTEXT.md] |
| Dense rows and long value wrapping | Component Layer | CSS / Browser | `dense_resource_row`, `long_value`, `status_badge`, and admin CSS already provide reusable structure and wrapping behavior. [VERIFIED: codebase] |
| Accessible confirmation/errors | Component Layer | LiveView Events | `confirmation_panel`, `error_summary`, and `error_list` exist; LiveViews own submit events and error assigns. [VERIFIED: codebase] |
| Operator authentication/authorization | Host App | Router Mount Boundary | Lockspire admin routes are host-guarded, and Lockspire does not own staff auth, MFA, roles, IP policy, or staff sessions. [VERIFIED: AGENTS.md] [VERIFIED: docs/operator-admin.md] |

## Project Constraints (from AGENTS.md)

- Lockspire is an embedded OAuth/OIDC authorization server library for Phoenix and Elixir, not a standalone hosted auth service. [VERIFIED: AGENTS.md]
- Build Lockspire as a separate companion library and preserve the embedded-library shape. [VERIFIED: AGENTS.md]
- Keep strong boundaries between protocol core, storage, generators, Plug/Phoenix integration, and LiveView/admin surfaces. [VERIFIED: AGENTS.md]
- Keep the host seam explicit and narrow: account resolution, claims, login redirects, branding, and product policy belong to the host app. [VERIFIED: AGENTS.md]
- Do not broaden v1 into SAML, LDAP/AD federation, hosted auth, or a full CIAM suite. [VERIFIED: AGENTS.md]
- Project stack targets Phoenix `1.8.5`, LiveView `1.1.28`, Ecto SQL `3.13.5`, PostgreSQL `14+`, Bandit `1.6.1`, Oban `2.21.x`, and OpenTelemetry `1.6.0`; current lockfile resolves Phoenix `1.8.7`, LiveView `1.1.30`, Ecto SQL `3.13.5`, Postgrex `0.22.2`, Bandit `1.11.1`, Oban `2.21.1`, and OpenTelemetry API `1.5.0`. [VERIFIED: AGENTS.md] [VERIFIED: mix.lock]
- Security defaults to preserve include PKCE S256 required by default, exact redirect URI validation, client secrets hashed at rest, short-lived single-use authorization codes, refresh token rotation with family-wide revocation on reuse, no implicit flow, no `alg=none`, and strong redaction in logs/operator surfaces. [VERIFIED: AGENTS.md]
- Planning references are `.planning/PROJECT.md`, `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`, `.planning/STATE.md`, and `.planning/research/SUMMARY.md`. [VERIFIED: AGENTS.md]

## Standard Stack

### Core

| Library / Module | Version | Purpose | Why Standard |
|------------------|---------|---------|--------------|
| Phoenix | 1.8.7 locked, AGENTS target 1.8.5 | Hosts router, controllers, endpoint, and LiveView integration for admin pages. [VERIFIED: mix.lock] | Existing project dependency and admin route foundation. [VERIFIED: codebase] |
| Phoenix LiveView | 1.1.30 locked, AGENTS target 1.1.28 | Server-rendered interactive admin pages, `phx-submit`, `phx-change`, function components, and HEEx templates. [VERIFIED: mix.lock] [CITED: https://phoenix-live-view.hexdocs.pm/1.1.30/Phoenix.Component.html] | Existing token/consent Support routes are LiveViews. [VERIFIED: codebase] |
| `Lockspire.Web.Components.AdminComponents` | internal | Provides `page_hero`, `decision_summary`, `entity_header`, `dense_resource_row`, `long_value`, `confirmation_panel`, `error_summary`, `error_list`, `timestamp`, and related primitives. [VERIFIED: codebase] | Phase context and UI spec require these existing primitives before new components. [VERIFIED: 122-CONTEXT.md] [VERIFIED: 122-UI-SPEC.md] |
| `Lockspire.Admin.Tokens` | internal | Token index/detail reads and token/family revocation APIs. [VERIFIED: codebase] | Locked boundary for token Support behavior. [VERIFIED: 122-CONTEXT.md] |
| `Lockspire.Admin.Consents` | internal | Consent index/detail reads and consent revocation API. [VERIFIED: codebase] | Locked boundary for consent Support behavior. [VERIFIED: 122-CONTEXT.md] |
| Ecto SQL / Postgrex / PostgreSQL | Ecto SQL 3.13.5, Postgrex 0.22.2, PostgreSQL 14+ | Existing persistence layer for lifecycle tokens and consents. [VERIFIED: mix.lock] [VERIFIED: AGENTS.md] | LiveViews must not query storage directly; Admin APIs already delegate to repository functions. [VERIFIED: codebase] [VERIFIED: 122-CONTEXT.md] |

### Supporting

| Library / Module | Version | Purpose | When to Use |
|------------------|---------|---------|-------------|
| Phoenix.LiveViewTest | 1.1.30 with LiveView | Route/component rendering, event submission, and HTML assertions. [VERIFIED: mix.lock] [CITED: https://phoenix-live-view.hexdocs.pm/1.1.30/Phoenix.LiveViewTest.html] | Use for token/consent LiveView tests and submit events. [VERIFIED: codebase] |
| ExUnit | bundled with Elixir 1.19.5 locally | Test framework used by project tests. [VERIFIED: local environment] [VERIFIED: codebase] | Use existing `mix test` commands for focused and full verification. [VERIFIED: codebase] |
| LazyHTML | 0.1.11 | HTML parsing/assertion support in tests. [VERIFIED: mix.lock] | Use existing admin proof assertions and route tests; do not add browser test packages for this phase. [VERIFIED: codebase] |
| `Lockspire.Web.AdminProof.HtmlAssertions` | internal test helper | Duplicate id, aria target, label target, forbidden text, generic CTA, and selector assertions. [VERIFIED: codebase] | Extend route tests using this helper where possible. [VERIFIED: codebase] |
| Admin CSS tokens and BEM classes | internal | `lockspire-admin-*` classes and `--ls-*` tokens govern admin layout, color, focus, reduced motion, long values, and responsive stacking. [VERIFIED: codebase] | Use for any narrow-width or state styling; do not introduce Tailwind/shadcn/public theming. [VERIFIED: 122-CONTEXT.md] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Existing function components | New `support_investigation_row` component | Explicitly deferred and out of scope. [VERIFIED: 122-CONTEXT.md] |
| Existing route LiveViews | New `/admin/support` dashboard | Explicitly deferred and out of scope. [VERIFIED: 122-CONTEXT.md] |
| Existing admin CSS/tokens | Tailwind, shadcn, Storybook, public theming | Forbidden by phase and v1.31/v1.32 design boundary. [VERIFIED: 122-CONTEXT.md] [VERIFIED: .planning/STATE.md] |
| Existing Admin APIs | Raw Ecto queries in LiveViews | Forbidden by phase and would cross the domain boundary. [VERIFIED: 122-CONTEXT.md] |
| Existing ExUnit/LiveView tests | New Playwright/browser dependency | No new package or external browser dependency is required for the planned route/component assertions. [VERIFIED: codebase] |

**Installation:**

No new package installation is recommended for Phase 122. [VERIFIED: codebase] If dependencies are absent locally, use the existing project dependency command:

```bash
mix deps.get
```

**Version verification:**

Current versions were verified from `mix.lock`, `mix.exs`, and local tool output on 2026-06-28. [VERIFIED: mix.lock] [VERIFIED: local environment]

## Package Legitimacy Audit

No new external packages should be installed for this phase, so no new package requires Package Legitimacy Gate approval. [VERIFIED: 122-CONTEXT.md] Existing dependencies are already present in `mix.lock`. [VERIFIED: mix.lock]

| Package | Registry | Age | Downloads | Source Repo | Verdict | Disposition |
|---------|----------|-----|-----------|-------------|---------|-------------|
| none | n/a | n/a | n/a | n/a | n/a | No new packages recommended. [VERIFIED: 122-CONTEXT.md] |

**Packages removed due to [SLOP] verdict:** none. [VERIFIED: 122-CONTEXT.md]
**Packages flagged as suspicious [SUS]:** none. [VERIFIED: 122-CONTEXT.md]

## Architecture Patterns

### System Architecture Diagram

```text
Operator browser
  -> host-guarded AdminRouter
  -> token/consent LiveView route
      -> parse URL filters / form params
      -> build display-only summary predicates
      -> call Lockspire.Admin.Tokens or Lockspire.Admin.Consents
          -> repository / Ecto / PostgreSQL
      -> render AdminComponents primitives
          -> page_hero -> decision_summary -> filter_bar/entity_header
          -> dense_resource_row / description_list / long_value
          -> confirmation_panel / error_summary / error_list

Mutation branch:
confirmation checkbox submitted
  -> LiveView handle_event
  -> if missing confirmation: exact error copy through error primitive
  -> else Admin revoke API
      -> success: reload current support detail
      -> failure: non-final consequence copy

Closed-state branch:
revoked_at present OR no refresh family OR consent revoked_at present
  -> disabled/de-emphasized control
  -> adjacent calm explanatory copy
  -> backend remains idempotent
```

The diagram reflects the existing route/API/component boundaries and the locked phase constraints. [VERIFIED: codebase] [VERIFIED: 122-CONTEXT.md]

### Recommended Project Structure

```text
lib/lockspire/web/live/admin/
  tokens_live/index.ex        # token filters, decision summary, dense rows
  tokens_live/show.ex         # token detail summary, lineage, revoke panels
  consents_live/index.ex      # consent filters, decision summary, dense rows
  consents_live/show.ex       # consent detail summary, pivots, revoke panel

lib/lockspire/web/components/
  admin_components.ex         # existing reusable primitives only if needed
  admin_css.ex                # existing BEM/token CSS refinements only if needed

test/lockspire/web/live/admin/
  tokens_live_test.exs        # SUPPORT-01 and token half of SUPPORT-03
  consents_live_test.exs      # SUPPORT-02 and consent half of SUPPORT-03
  design_system_contract_test.exs          # source/CSS guardrails if needed
  design_system_component_stress_test.exs  # component primitive guardrails if needed
```

This structure matches files already present in the repository. [VERIFIED: codebase]

### Pattern 1: Route-Owned Decision Summary Helpers

**What:** Keep display-only summary classification in the route LiveView or a very narrow internal helper when duplication becomes risky. [VERIFIED: 122-CONTEXT.md]

**When to use:** Use it when a page needs to render fixed summary items or closed-state predicates without embedding security-sensitive conditionals across HEEx templates. [VERIFIED: 122-CONTEXT.md]

**Example:**

```elixir
# Source: existing AdminComponents slot API and phase decision-summary contract.
# [VERIFIED: codebase] [VERIFIED: 122-CONTEXT.md]
<AdminComponents.decision_summary>
  <:item label="Token health" value={token_health_label(@detail)} detail={token_health_detail(@detail)} />
  <:item label="Family lineage" value={family_lineage_label(@detail)} detail={family_lineage_detail(@detail)} />
  <:item label="Reuse pressure" value={reuse_pressure_label(@detail)} detail={reuse_pressure_detail(@detail)} />
  <:item label="Smallest safe action" value={token_safe_action_label(@detail)} detail={token_safe_action_detail(@detail)} />
</AdminComponents.decision_summary>
```

### Pattern 2: Dense Rows Lead With the Support Question

**What:** Token and consent index rows should use `dense_resource_row` instead of route-specific resource item markup when it reduces custom page complexity. [VERIFIED: 122-CONTEXT.md] [VERIFIED: codebase]

**When to use:** Use it for index rows where status, kind/type, redacted pivots, long identifiers, timestamps, and a single review action need to remain scannable under dense data. [VERIFIED: 122-UI-SPEC.md]

**Example:**

```elixir
# Source: existing dense_resource_row slot API.
# [VERIFIED: codebase]
<AdminComponents.dense_resource_row
  title={token_health_label(token)}
  subtitle={token_kind_label(token)}
>
  <:status><AdminComponents.status_badge status={token.status} /></:status>
  <:meta><AdminComponents.long_value value={token.client_handle} /></:meta>
  <:meta><AdminComponents.timestamp value={token.inserted_at} /></:meta>
  <:actions>
    <AdminComponents.admin_button navigate={~p"/admin/tokens/#{token.id}"} variant="secondary">
      Review token
    </AdminComponents.admin_button>
  </:actions>
</AdminComponents.dense_resource_row>
```

### Pattern 3: Closed-State Confirmation Panels

**What:** Confirmation panels should distinguish missing checkbox validation, already revoked state, no-family state, and backend uncertainty. [VERIFIED: 122-CONTEXT.md]

**When to use:** Use it on token detail single-token revoke, token detail family revoke, and consent detail revoke. [VERIFIED: 122-CONTEXT.md]

**Example:**

```elixir
# Source: locked copy and existing confirmation_panel/error primitives.
# [VERIFIED: 122-CONTEXT.md] [VERIFIED: codebase]
<AdminComponents.confirmation_panel
  id="revoke-token"
  title="Revoke token"
  tone="danger"
  errors={@revoke_token_errors}
>
  <p :if={token_already_revoked?(@detail)}>
    This token is already revoked. No further token action is available.
  </p>
  <.form :if={!token_already_revoked?(@detail)} for={@revoke_token_form} phx-submit="revoke_token">
    <AdminComponents.form_field field={@revoke_token_form[:confirm]} type="checkbox" label="Confirm token revocation" />
    <AdminComponents.admin_button variant="danger">Revoke token</AdminComponents.admin_button>
  </.form>
</AdminComponents.confirmation_panel>
```

### Pattern 4: Redaction-First Long Values

**What:** Long client, account, family, token, and scope values should render through redacted handles and wrapping primitives, not raw sensitive source fields. [VERIFIED: 122-CONTEXT.md] [VERIFIED: codebase]

**When to use:** Use it anywhere a token handle, client pivot, account pivot, scope list, family lineage, or selected-filter summary could overflow or disclose sensitive material. [VERIFIED: 122-UI-SPEC.md]

**Example:**

```elixir
# Source: existing long_value primitive and redaction requirement.
# [VERIFIED: codebase] [VERIFIED: 122-CONTEXT.md]
<AdminComponents.long_value value={redacted_account_handle(account_ref)} />
```

### Anti-Patterns to Avoid

- **Raw Ecto in LiveViews:** It crosses the locked Admin boundary and makes Support UI a domain behavior owner. [VERIFIED: 122-CONTEXT.md]
- **Responsive tables as primary Support UI:** The phase explicitly requires dense rows and mobile stacking rather than primary responsive tables. [VERIFIED: 122-CONTEXT.md]
- **`status == :revoked` as the only closed-state predicate:** Current token status logic can return `:reuse_detected` before `:revoked`; explicit `revoked_at` and `reuse_detected_at` predicates are required. [VERIFIED: codebase] [VERIFIED: 122-CONTEXT.md]
- **Plain paragraph errors for destructive actions:** Locked error handling requires `error_summary`, `error_list`, or equivalent alert/error semantics. [VERIFIED: 122-CONTEXT.md]
- **New customization surface:** Host hooks, public theming, public Storybook, and design registries are out of scope. [VERIFIED: 122-CONTEXT.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Support row layout | New row primitive or table system | `dense_resource_row`, `long_value`, `status_badge`, `timestamp` | Existing primitives already encode admin BEM/tokens and responsive stacking. [VERIFIED: codebase] |
| Revocation domain behavior | New token/consent mutation logic in LiveViews | `Lockspire.Admin.Tokens.revoke_token/2`, `Lockspire.Admin.Tokens.revoke_token_family/2`, `Lockspire.Admin.Consents.revoke_consent/2` | Phase is presentation/copy polish and must not add capabilities. [VERIFIED: codebase] [VERIFIED: 122-CONTEXT.md] |
| Error alert markup | Custom inline error paragraphs | `error_summary`, `error_list`, `confirmation_panel` errors | Existing primitives support consistent error semantics and tests. [VERIFIED: codebase] |
| Secret inspection | Reveal, export, decode, or debug controls | Redacted handles and non-secret summaries | Plaintext tokens, hashes, secrets, verifiers, cookies, auth codes, and user-code material must never render. [VERIFIED: 122-CONTEXT.md] |
| Filter persistence | New storage/session mechanism | Existing URL filters and LiveView assigns | Context locks filters/assigns/events in the route LiveViews. [VERIFIED: 122-CONTEXT.md] |
| External browser/test framework | New Playwright or visual tooling | Existing ExUnit, Phoenix.LiveViewTest, LazyHTML, and HtmlAssertions | Existing test stack already verifies rendered HTML contracts without new dependencies. [VERIFIED: codebase] |

**Key insight:** This phase is won by making existing support evidence easier to interpret, not by adding more evidence or actions. [VERIFIED: 122-CONTEXT.md]

## Common Pitfalls

### Pitfall 1: Reuse-Detected Revoked Tokens Look Actionable

**What goes wrong:** A token with both `reuse_detected_at` and `revoked_at` can be rendered as reuse-detected while the UI still shows a live revoke action. [VERIFIED: codebase]

**Why it happens:** `Lockspire.Admin.Tokens.token_status/2` classifies `reuse_detected_at` before `revoked_at`, so `status == :revoked` is not a sufficient closed-state predicate. [VERIFIED: codebase]

**How to avoid:** Use explicit predicates for `revoked_at`, `reuse_detected_at`, and family presence in summary and panel helpers. [VERIFIED: 122-CONTEXT.md]

**Warning signs:** Template conditionals compare only `@detail.status == :revoked` or only `token.status == :revoked`. [VERIFIED: codebase]

### Pitfall 2: Current Index Rows Remain Metadata Inventories

**What goes wrong:** Rows lead with IDs and secondary metadata instead of health/status, family pressure, grant status, or scope context. [VERIFIED: codebase] [VERIFIED: 122-CONTEXT.md]

**Why it happens:** Current token and consent index pages use `resource_item` markup rather than the locked dense support row shape. [VERIFIED: codebase]

**How to avoid:** Convert index rows toward `dense_resource_row`, with status/kind first and one explicit review action. [VERIFIED: 122-CONTEXT.md]

**Warning signs:** Selectors such as `.lockspire-admin-resource-list__item` remain the primary row contract for token/consent investigation rows. [VERIFIED: codebase]

### Pitfall 3: Selected Filters Leak Raw Account or Client Values

**What goes wrong:** Support summaries echo raw typed account/client filters that can include sensitive host account identifiers. [VERIFIED: codebase] [VERIFIED: 122-CONTEXT.md]

**Why it happens:** Current tests and pages render selected filter values directly for account/client filters. [VERIFIED: codebase]

**How to avoid:** Keep raw values in form controls when required for filtering, but render selected-filter summaries through redacted display helpers. [VERIFIED: 122-CONTEXT.md]

**Warning signs:** `Selected filters` text contains `acct_`, raw email-like values, raw client ids, or fixture forbidden substrings. [VERIFIED: codebase]

### Pitfall 4: Destructive-Action Errors Are Generic or Not Accessible

**What goes wrong:** Missing checkbox and backend errors appear as plain text, generic failure copy, or non-final copy that implies certainty. [VERIFIED: codebase] [VERIFIED: 122-CONTEXT.md]

**Why it happens:** Current token and consent show pages use route-specific paragraphs for errors and older generic confirmation messages. [VERIFIED: codebase]

**How to avoid:** Use the exact locked error strings and render them through `confirmation_panel` errors, `error_summary`, `error_list`, or equivalent alert/error semantics. [VERIFIED: 122-CONTEXT.md]

**Warning signs:** Text such as `Confirm the single-token action`, `Confirm the family-wide action`, `Token could not be revoked`, or `Consent could not be revoked` remains in show-page templates. [VERIFIED: codebase]

### Pitfall 5: Family Revocation Copy Overstates the Count

**What goes wrong:** The UI says a count means active tokens when the backend count represents unrevoked family records. [VERIFIED: codebase] [VERIFIED: 122-CONTEXT.md]

**Why it happens:** Repository family revocation updates records with `is_nil(revoked_at)`, while active status also depends on expiration and reuse context. [VERIFIED: codebase]

**How to avoid:** Use copy such as `currently unrevoked tokens in the refresh family` unless a true active/unexpired count is available. [VERIFIED: 122-CONTEXT.md]

**Warning signs:** Text says `every active token` or `active tokens` next to `family_revoked_count` or family revoke results. [VERIFIED: codebase]

### Pitfall 6: Narrow-Width Overflow Hides Support Evidence

**What goes wrong:** Long IDs, scopes, filters, or actions create page-level horizontal scrolling or overlapping controls. [VERIFIED: 122-UI-SPEC.md]

**Why it happens:** Dense data needs wrapping and stacked rows at narrow widths. [VERIFIED: 122-UI-SPEC.md] WCAG Reflow expects content to work without two-dimensional scrolling at 320 CSS pixels except for inherently two-dimensional content. [CITED: https://www.w3.org/WAI/WCAG21/Understanding/reflow.html]

**How to avoid:** Use `long_value`, existing dense row CSS, wrapping filters, full-width mobile buttons, and no primary responsive tables. [VERIFIED: codebase] [VERIFIED: 122-CONTEXT.md]

**Warning signs:** New CSS introduces fixed widths, `white-space: nowrap`, wide grids, or page-level overflow. [VERIFIED: codebase]

## Code Examples

Verified patterns from existing codebase and official docs:

### LiveView Form Events for Confirmation

Phoenix LiveView supports form-level `phx-change` and `phx-submit`, and submitted forms disable inputs/buttons until the server acknowledges the event. [CITED: https://phoenix-live-view.hexdocs.pm/1.1.30/form-bindings.html]

```elixir
# Source: Phoenix LiveView form bindings and existing show-page submit pattern.
# [CITED: https://phoenix-live-view.hexdocs.pm/1.1.30/form-bindings.html] [VERIFIED: codebase]
<.form for={@revoke_token_form} id="revoke-token-form" phx-submit="revoke_token">
  <AdminComponents.form_field
    field={@revoke_token_form[:confirm]}
    type="checkbox"
    label="Confirm token revocation"
  />
  <AdminComponents.admin_button variant="danger">Revoke token</AdminComponents.admin_button>
</.form>
```

### Component Slots for Decision Summaries

Phoenix function components receive assigns and can define attributes/slots for HEEx rendering. [CITED: https://phoenix-live-view.hexdocs.pm/1.1.30/Phoenix.Component.html]

```elixir
# Source: existing AdminComponents.decision_summary and LiveView component model.
# [VERIFIED: codebase] [CITED: https://phoenix-live-view.hexdocs.pm/1.1.30/Phoenix.Component.html]
<AdminComponents.decision_summary>
  <:item label="Selected filters" value={selected_filters_label(@filters)} />
  <:item label="Grant status" value={grant_status_label(@consents)} />
  <:item label="Scope context" value={scope_context_label(@consents)} />
  <:item label="Smallest safe action" value={consent_safe_action_label(@consents)} />
</AdminComponents.decision_summary>
```

### Route Tests Should Exercise Rendered Events

LiveViewTest supports event submission helpers and rendered HTML inspection for LiveView behavior. [CITED: https://phoenix-live-view.hexdocs.pm/1.1.30/Phoenix.LiveViewTest.html]

```elixir
# Source: existing route tests plus Phoenix.LiveViewTest render_submit support.
# [VERIFIED: codebase] [CITED: https://phoenix-live-view.hexdocs.pm/1.1.30/Phoenix.LiveViewTest.html]
assert render_submit(element(view, "#revoke-token-form"), %{"revoke_token" => %{"confirm" => "false"}}) =~
         "Select the confirmation checkbox to revoke this token."
```

### OAuth Revocation Copy Must Stay Non-Final on Failure

RFC 7009 states that a revocation request invalidates a token and may invalidate related tokens, and it also notes that a `503` response means the client must assume the token still exists. [CITED: https://datatracker.ietf.org/doc/html/rfc7009]

```elixir
# Source: locked phase copy and RFC 7009 uncertainty model.
# [VERIFIED: 122-CONTEXT.md] [CITED: https://datatracker.ietf.org/doc/html/rfc7009]
"Revocation could not be confirmed. The token may still be active; reload this Support workflow before retrying."
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Metadata-heavy admin pages | Decision-first Support pages using summaries, dense rows, and consequence copy | Phase 122 target | Planner should prioritize scanning and consequence framing over field enumeration. [VERIFIED: 122-CONTEXT.md] |
| Page-specific ad hoc markup | Phoenix function components with attrs/slots and admin primitives | Existing v1.31/v1.32 design boundary | Planner should reuse `AdminComponents` and admin CSS tokens. [VERIFIED: codebase] [CITED: https://phoenix-live-view.hexdocs.pm/1.1.30/Phoenix.Component.html] |
| Color-only or table-heavy status reading | Textual status plus responsive stacking and no page-level overflow | UI spec and WCAG Reflow guidance | Planner should keep status text visible and avoid primary responsive tables. [VERIFIED: 122-UI-SPEC.md] [CITED: https://www.w3.org/WAI/WCAG21/Understanding/reflow.html] |
| Refresh-token reuse as a generic revoked state | Rotation/reuse-detection pressure with family-wide consequences | OAuth 2.0 Security BCP and Lockspire security defaults | Planner should keep reuse evidence distinct from simple revoked/expired states. [VERIFIED: AGENTS.md] [CITED: https://datatracker.ietf.org/doc/rfc9700/] |

**Deprecated/outdated:**

- Generic CTA text such as `Submit`, `Open`, `View`, or `Details` is inappropriate for this phase; use locked investigation vocabulary. [VERIFIED: 122-CONTEXT.md]
- Generic destructive failure copy such as `Token could not be revoked` is insufficient; use locked non-final failure copy. [VERIFIED: 122-CONTEXT.md] [VERIFIED: codebase]
- Primary responsive tables are out of scope for these Support investigation pages. [VERIFIED: 122-CONTEXT.md]

## Assumptions Log

All claims in this research were verified against project files, local environment output, official docs, W3C guidance, or IETF RFCs. No `[ASSUMED]` claims are intentionally included. [VERIFIED: codebase]

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| none | No assumed claims. [VERIFIED: codebase] | n/a | n/a |

## Open Questions (RESOLVED)

1. **Should selected-filter summaries show redacted handles while form inputs keep raw filter values?**  
   What we know: the phase forbids raw sensitive account values, while current index tests assert visible raw account filter text. [VERIFIED: 122-CONTEXT.md] [VERIFIED: codebase]  
   What's unclear: whether raw filter values are acceptable inside editable form controls when the operator typed them. [VERIFIED: codebase]  
   RESOLVED: Keep submitted form values intact in editable controls so URL-owned filters remain functional, but require redacted display in decision summaries and dense rows. Fragment-level tests should inspect summary/row regions separately from form controls. [VERIFIED: 122-CONTEXT.md]

2. **Should list-load failures become visible page errors instead of empty lists?**  
   What we know: current token and consent index `load_*` helpers collapse Admin read failures to empty result lists. [VERIFIED: codebase]  
   What's unclear: the UI spec covers validation/mutation errors more explicitly than read failures. [VERIFIED: 122-UI-SPEC.md]  
   DEFERRED: Do not add a visible list-load error state in Phase 122 because there is no existing route-local way to force Admin read errors without widening Admin APIs or adding new capabilities. Keep empty/no-match coverage and mutation/validation error coverage inside existing LiveView/Admin boundaries. [VERIFIED: codebase]

3. **Should summary predicates live in each LiveView or a tiny shared helper?**  
   What we know: context allows a narrow helper/read-model layer only if duplicated summary predicates would otherwise put security-sensitive decisions in templates. [VERIFIED: 122-CONTEXT.md]  
   What's unclear: final duplication level after token and consent summaries are drafted. [VERIFIED: codebase]  
   RESOLVED: Start with private helpers in the existing token and consent LiveViews. Do not create a new module in this phase unless implementation proves duplicated predicate/copy logic spans token and consent detail pages and would otherwise move security-sensitive decisions into templates. [VERIFIED: 122-CONTEXT.md]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Elixir | Mix tests and Phoenix code | yes | 1.19.5 with Erlang/OTP 28 | none needed. [VERIFIED: local environment] |
| Mix | Dependency/test commands | yes | 1.19.5 | none needed. [VERIFIED: local environment] |
| PostgreSQL server | Ecto sandbox tests | yes | local `pg_isready` reports accepting connections on `/tmp:5432`; `psql` is 14.17. [VERIFIED: local environment] | none needed. [VERIFIED: config/test.exs] |
| Phoenix/Ecto dependencies | App compilation and tests | yes | locked in `mix.lock` | run `mix deps.get` if missing. [VERIFIED: mix.lock] |
| Browser automation | Not required for this phase | not required | n/a | Use rendered HTML tests and source/CSS contract tests. [VERIFIED: codebase] |

**Missing dependencies with no fallback:** none found for planning and verification. [VERIFIED: local environment]

**Missing dependencies with fallback:** none found. [VERIFIED: local environment]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit with Phoenix.LiveViewTest and LazyHTML support. [VERIFIED: codebase] [VERIFIED: mix.lock] |
| Config file | `test/test_helper.exs` excludes `integration: true` by default; `config/test.exs` configures SQL sandbox and `lockspire_test`. [VERIFIED: codebase] |
| Quick run command | `MIX_ENV=test mix test test/lockspire/web/live/admin/tokens_live_test.exs test/lockspire/web/live/admin/consents_live_test.exs` [VERIFIED: codebase] |
| Design contract command | `MIX_ENV=test mix test test/lockspire/web/live/admin/design_system_contract_test.exs test/lockspire/web/live/admin/design_system_component_stress_test.exs` [VERIFIED: codebase] |
| Full suite command | `MIX_ENV=test mix test.fast` [VERIFIED: mix.exs] |

### Phase Requirements -> Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| SUPPORT-01 | Token index/detail show selected filters, health, family context, reuse pressure, smallest safe action, safe long values, exact actions, and no plaintext secrets. [VERIFIED: .planning/REQUIREMENTS.md] | LiveView render/event tests plus HTML assertions | `MIX_ENV=test mix test test/lockspire/web/live/admin/tokens_live_test.exs` | yes. [VERIFIED: codebase] |
| SUPPORT-02 | Consent index/detail show selected filters, grant status, scope context, client/account pivots, revocation consequences, and no secret material. [VERIFIED: .planning/REQUIREMENTS.md] | LiveView render/event tests plus HTML assertions | `MIX_ENV=test mix test test/lockspire/web/live/admin/consents_live_test.exs` | yes. [VERIFIED: codebase] |
| SUPPORT-03 | Empty, no-match, revoked, expired, reuse-detected, long identifier, dense result, validation-error, and already-revoked states render concise consequence copy. [VERIFIED: .planning/REQUIREMENTS.md] | LiveView state fixtures, component stress, and design contract tests | `MIX_ENV=test mix test test/lockspire/web/live/admin/tokens_live_test.exs test/lockspire/web/live/admin/consents_live_test.exs test/lockspire/web/live/admin/design_system_component_stress_test.exs` | yes. [VERIFIED: codebase] |

### Sampling Rate

- **Per task commit:** `MIX_ENV=test mix test test/lockspire/web/live/admin/tokens_live_test.exs test/lockspire/web/live/admin/consents_live_test.exs` [VERIFIED: codebase]
- **Per wave merge:** `MIX_ENV=test mix test test/lockspire/web/live/admin/tokens_live_test.exs test/lockspire/web/live/admin/consents_live_test.exs test/lockspire/web/live/admin/design_system_contract_test.exs test/lockspire/web/live/admin/design_system_component_stress_test.exs` [VERIFIED: codebase]
- **Phase gate:** `MIX_ENV=test mix test.fast` before `$gsd-verify-work`. [VERIFIED: mix.exs]

### Wave 0 Gaps

- [ ] Extend `test/lockspire/web/live/admin/tokens_live_test.exs` for exact token decision summary labels, dense row selector, no raw sensitive selected-filter summary, exact missing-checkbox errors, already-revoked copy, no-family copy, disabled/de-emphasized closed controls, reuse-detected plus revoked predicate coverage, and family count wording. [VERIFIED: codebase] [VERIFIED: 122-CONTEXT.md]
- [ ] Extend `test/lockspire/web/live/admin/consents_live_test.exs` for exact consent decision summary labels, dense row selector, redacted pivots/scopes, exact missing-checkbox error, exact already-revoked copy, disabled/de-emphasized closed controls, and non-final backend failure copy if failure can be simulated. [VERIFIED: codebase] [VERIFIED: 122-CONTEXT.md]
- [ ] Add or update design contract assertions only if CSS changes touch dense rows, long values, confirmation panels, focus/error states, or page-level overflow protections. [VERIFIED: codebase] [VERIFIED: 122-UI-SPEC.md]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V2 Authentication | no for implementation; host app owns operator login/authentication. [VERIFIED: docs/operator-admin.md] | Preserve host-guarded AdminRouter boundary; do not add Lockspire staff auth. [VERIFIED: AGENTS.md] |
| V3 Session Management | no for implementation; host app owns staff sessions. [VERIFIED: docs/operator-admin.md] | Do not add session behavior in Support LiveViews. [VERIFIED: AGENTS.md] |
| V4 Access Control | yes at route/action boundary. [VERIFIED: docs/operator-admin.md] | Do not add routes, bulk actions, reveal/export/debug controls, or unsupported mutations. [VERIFIED: 122-CONTEXT.md] |
| V5 Input Validation | yes for filter and confirmation input. [VERIFIED: codebase] | Keep URL filters/events in LiveViews, use existing allowed status filters and form checkbox validation, and avoid raw Ecto. [VERIFIED: codebase] [VERIFIED: 122-CONTEXT.md] |
| V6 Cryptography | yes as a non-change constraint. [VERIFIED: AGENTS.md] | Do not touch token signing/encryption; preserve no plaintext tokens/secrets/hashes/verifiers/cookies/auth codes in UI. [VERIFIED: AGENTS.md] [VERIFIED: 122-CONTEXT.md] |
| V7 Error Handling and Logging | yes for destructive-action uncertainty and redaction. [VERIFIED: 122-CONTEXT.md] | Use non-final failure copy and accessible error primitives without secret values. [VERIFIED: 122-CONTEXT.md] |

### Known Threat Patterns for Phoenix LiveView Admin Support UI

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Plaintext token/hash/secret/verifier/cookie/auth-code exposure in rendered HTML | Information Disclosure | Redacted handles, `long_value`, forbidden text tests, and no reveal/export/debug controls. [VERIFIED: 122-CONTEXT.md] [VERIFIED: codebase] |
| Unsupported operator action appears available | Elevation of Privilege / Tampering | Only render actions backed by existing Admin APIs; no new routes, bulk actions, host logout, account suspension, or protocol behavior. [VERIFIED: 122-CONTEXT.md] |
| Reuse-detected revoked token gets a misleading single-token action | Tampering / Repudiation | Explicit predicates for `revoked_at`, `reuse_detected_at`, family presence, and smallest safe action. [VERIFIED: 122-CONTEXT.md] [VERIFIED: codebase] |
| Backend revocation failure copy implies certainty | Repudiation | Use locked copy: the token or consent grant may still be active and the operator should reload before retrying. [VERIFIED: 122-CONTEXT.md] RFC 7009 similarly treats some failure states as requiring the client to assume the token still exists. [CITED: https://datatracker.ietf.org/doc/html/rfc7009] |
| Introspection-style/internal state leaks on inactive or revoked objects | Information Disclosure | Do not dump raw internal metadata; keep Support pages to decision summaries and redacted evidence. [VERIFIED: 122-CONTEXT.md] RFC 7662 warns inactive responses should not reveal extra token information. [CITED: https://datatracker.ietf.org/doc/html/rfc7662] |
| Horizontal overflow hides destructive context or confirmation errors | Denial of Service / Usability Failure | Use WCAG Reflow-aligned wrapping/stacking and existing long-value CSS. [VERIFIED: codebase] [CITED: https://www.w3.org/WAI/WCAG21/Understanding/reflow.html] |

## Sources

### Primary (HIGH confidence)

- `AGENTS.md` - project boundary, stack targets, security defaults, and planning references. [VERIFIED: AGENTS.md]
- `.planning/phases/122-support-investigation-flow-polish/122-CONTEXT.md` - locked decisions, exact copy, discretion, and deferred scope. [VERIFIED: 122-CONTEXT.md]
- `.planning/phases/122-support-investigation-flow-polish/122-UI-SPEC.md` - component, typography, responsive, confirmation, and redaction contract. [VERIFIED: 122-UI-SPEC.md]
- `.planning/REQUIREMENTS.md` - SUPPORT-01, SUPPORT-02, SUPPORT-03 requirement descriptions. [VERIFIED: .planning/REQUIREMENTS.md]
- `.planning/ROADMAP.md` - Phase 122 goal and success criteria. [VERIFIED: .planning/ROADMAP.md]
- `.planning/STATE.md` - v1.32 focus, design boundary, and prior phase decisions. [VERIFIED: .planning/STATE.md]
- `lib/lockspire/web/live/admin/tokens_live/index.ex`, `tokens_live/show.ex`, `consents_live/index.ex`, `consents_live/show.ex` - current LiveView state and gaps. [VERIFIED: codebase]
- `lib/lockspire/web/components/admin_components.ex` and `admin_css.ex` - reusable primitives and responsive/error/long-value styles. [VERIFIED: codebase]
- `lib/lockspire/admin/tokens.ex`, `lib/lockspire/admin/consents.ex`, `lib/lockspire/admin.ex`, and storage repository code - Admin API boundaries and token/consent status behavior. [VERIFIED: codebase]
- `test/lockspire/web/live/admin/*` and `test/support/lockspire/web/*` - existing LiveView/design contract tests, fixtures, and proof assertions. [VERIFIED: codebase]
- `mix.exs`, `mix.lock`, `test/test_helper.exs`, `config/test.exs` - dependency/test configuration. [VERIFIED: codebase]
- `docs/operator-admin.md`, `docs/supported-surface.md`, and `brandbook/notes/*` - admin boundary and design-system history. [VERIFIED: codebase]

### Secondary (MEDIUM confidence)

- Phoenix LiveView `Phoenix.Component` docs - function component attrs/slots/HEEx model. [CITED: https://phoenix-live-view.hexdocs.pm/1.1.30/Phoenix.Component.html]
- Phoenix LiveView form bindings docs - `phx-submit`, `phx-change`, and submit loading semantics. [CITED: https://phoenix-live-view.hexdocs.pm/1.1.30/form-bindings.html]
- Phoenix LiveViewTest docs - rendered HTML and event test helpers. [CITED: https://phoenix-live-view.hexdocs.pm/1.1.30/Phoenix.LiveViewTest.html]
- W3C WCAG Reflow understanding doc - avoid two-dimensional scrolling at narrow widths except inherently two-dimensional content. [CITED: https://www.w3.org/WAI/WCAG21/Understanding/reflow.html]
- W3C WCAG Error Identification understanding doc - errors should be identified and described in text. [CITED: https://www.w3.org/WAI/WCAG22/Understanding/error-identification.html]
- RFC 7009 - OAuth 2.0 token revocation semantics and uncertainty on service failure. [CITED: https://datatracker.ietf.org/doc/html/rfc7009]
- RFC 9700 - OAuth 2.0 Security Best Current Practice for refresh token protection and rotation/reuse detection. [CITED: https://datatracker.ietf.org/doc/rfc9700/]
- RFC 7662 - OAuth 2.0 token introspection active-state and information disclosure considerations. [CITED: https://datatracker.ietf.org/doc/html/rfc7662]

### Tertiary (LOW confidence)

- None used as authoritative support. [VERIFIED: codebase]

## Metadata

**Confidence breakdown:**

- Standard stack: HIGH - versions were verified in `mix.lock`, `mix.exs`, and local tool output; no new packages are recommended. [VERIFIED: mix.lock] [VERIFIED: local environment]
- Architecture: HIGH - route, Admin API, component, CSS, test, and repository boundaries were verified in source files and match locked context. [VERIFIED: codebase] [VERIFIED: 122-CONTEXT.md]
- Pitfalls: HIGH - gaps are visible in current token/consent LiveViews and tests, and the status/family semantics are visible in Admin/repository code. [VERIFIED: codebase]
- External guidance: MEDIUM - official Phoenix, W3C, and IETF docs were checked, but Context7 MCP was unavailable in this session. [CITED: https://phoenix-live-view.hexdocs.pm/1.1.30/Phoenix.Component.html]

**Research date:** 2026-06-28
**Valid until:** 2026-07-28 for codebase planning; re-check official dependency docs if Phoenix LiveView or project dependencies change before implementation. [VERIFIED: codebase]
