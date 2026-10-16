# Phase 153: Configure & Support Page Refinement — Research

**Researched:** 2026-10-12  
**Domain:** Phoenix LiveView admin UI, information design, accessible design-system refinement  
**Confidence:** HIGH for in-repo implementation seams and constraints; MEDIUM for route-by-route visual judgments pending a fresh rendered review.

## User Constraints

The approved Phase 153 UI-SPEC and task direction constrain implementation:

- Use plain reader-facing language, avoid visible “operator,” remove redundant provenance notes, duplicate page-purpose copy, eyebrows and kickers, and keep necessary protocol terms only where they affect a choice. [CITED: `153-UI-SPEC.md`, Shared hierarchy and User-facing language; parent task direction]
- Reuse Phoenix components, the existing Signal Cyan semantic tokens, and existing fonts; add no third-party dependency, parallel token set, font fetch, or unnecessary motion. [CITED: `153-UI-SPEC.md`, Design System and Layout, spacing, theme, and accessibility; `brandbook/notes/decision-log.md` D2–D5]
- Make one page-level title, put task-relevant facts before secondary context, use one open canvas and only useful grouping, and preserve intentional primary/secondary/danger action meaning. [CITED: `153-UI-SPEC.md`, Page and Interaction Contract; `.planning/phases/151-focused-client-registration-settings/151-CONTEXT.md` D-05]
- Keep `/admin/clients/new` in the 30-route rendered review; all existing scorecards remain covered. Phase 153 may change Phase 151/152 surfaces only to correct a rendered regression. [CITED: `153-UI-SPEC.md`, Route coverage and first-view order]
- Keep client registration's copy-once lifecycle, secrets and private material redacted, exact revocation scope, protocol semantics, host-owned auth/layout/branding/product policy, and read-only interaction/device/logout queues unchanged. CR-01 key-storage design stays separate. [CITED: `.planning/REQUIREMENTS.md`, SAFE-01 and Out of Scope; `151-CONTEXT.md` D-02/D-04/D-06; `152-CONTEXT.md`, Decisions and Scope boundary]
- The synthetic Billingo adopter is demo data, not a real customer. Do not place credentials or production-looking identifiers in rendered proof. [CITED: `.planning/REQUIREMENTS.md`, Delivery Rules; project/task context]

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| UI-01 | Each of the 29 existing admin route scorecards has a clearly identifiable user job, a useful page title, and an information order that puts the decision or next task before secondary context. Remove duplicate page/section titles and generic introductions when they repeat information. | The route-scorecard registry derives paths from `AdminRouter` and appends the logout-propagation workflow; the UI-SPEC supplies a 30-route first-view contract. Shared shell title and `page_hero/1` establish the heading seam. |
| UI-02 | User-facing labels and help use plain, consistent language grounded in staff users' goals. Remove backend/provenance commentary that does not help a decision; explain necessary protocol terms in context, and describe unfamiliar state in terms of its supported consequence and next action. Do not use “operator” as visible audience copy or generic UI filler. | `153-UI-SPEC.md` contains route wording rules; Phase 152 decision records bound the reuse, logout, read-state and queue language. |
| UI-06 | Pages use the existing components and design tokens to improve hierarchy, spacing, scanability, and control affordances. Remove metric rows, nested containers, and helper text that do not help the current task. Correct the theme selector's demonstrated right-edge caret spacing. | `AdminComponents`, `Admin.CSS`, brandbook tokens/accessibility notes, and CSS contract tests expose direct reuse and verification seams. |

Requirements are quoted verbatim from `.planning/REQUIREMENTS.md` lines 11, 12, and 16. The delivery contract also says the current route scorecards are 29; the rendered inventory is now 30 entries because Phase 151 added `/admin/clients/new`. Treat the current 30-route table in the approved UI-SPEC as the browser-review inventory, and retain the 29 historical scorecards as judgment input. [VERIFIED: `.planning/REQUIREMENTS.md:11-16,21`; quote: “Each of the 29 existing admin route scorecards”; “All 29 admin route scorecards receive a current rendered review.”; `test/support/lockspire/web/admin_proof/route_scorecards.ex:4-5,51-57`; quote: `@workflow_exception "/admin/clients/:client_id/edit?workflow=logout-propagation"`; `lib/lockspire/web/admin_router.ex:12-13`; quote: `live("/clients/new", Lockspire.Web.Live.Admin.ClientsLive.Index, :new)`; `[CITED: 153-UI-SPEC.md, Route coverage and first-view order]`]

## Summary

Phase 153 is a bounded presentation refinement across the existing Configure and Support LiveViews. Its largest leverage point is `AdminComponents.page_hero/1`: it currently requires and emits a journey eyebrow, while the shared shell already owns the page H1. Refactor the shared component API and every call site together, then simplify route copy and content order using the approved 30-route table. Keep distinct section headings when they introduce different content; do not replace every heading with a blank hero or remove useful state and decision context. [VERIFIED: `lib/lockspire/web/components/admin_components.ex:50-73`; quote: `attr(:eyebrow, :string, required: true)` and `<p class="lockspire-admin-eyebrow">`; `lib/lockspire/web/live/admin_layout_live.ex:150-165`; quote: `<h1>{@page_title}</h1>`; `[CITED: 153-UI-SPEC.md, Shared hierarchy]`]

The supporting work is route-specific language, hierarchy, card/list choice, whitespace and theme-control inset. Keep Phase 151 client creation and Phase 152 overview/read-queue improvements intact unless a current rendered regression is found. No new runtime capability, OAuth change, queue action, dependency, or host integration is needed. Existing ExUnit/LiveView integration tests, route and CSS contracts, and the synthetic browser demo form the verification path; screenshots and viewport/theme sweep belong to Phase 154's evidence contract. [CITED: `.planning/ROADMAP.md`, Phases 153–154; `.planning/REQUIREMENTS.md`, SAFE-01 and PROOF-01]

**Primary recommendation:** Plan shared component/theme fixes first, then group Configure policy/key/onboarding routes and Support inventory/detail routes into independently testable vertical slices, with copy and rendered-state review anchored to the approved route table.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Route title, page hierarchy, copy, and sections | Phoenix LiveView / server-rendered HEEx | Browser DOM | Each route assigns `page_title` in the shared shell and renders its content through Phoenix components; presentation stays at the LiveView surface. |
| Shared hero, fields, panels, actions, badges, long values | Phoenix function components | CSS | Reuse `AdminComponents`; component markup supplies semantics and shared classes. |
| Spacing, colors, focus, theme, and responsive layout | Admin CSS semantic tokens | Browser rendering | `Admin.CSS.get/0` is embedded by the shell; semantic aliases support themes without page-local color systems. |
| Truthful state, policy meaning, and safe actions | Existing Admin/domain read paths and route handlers | LiveView copy | UI language may describe only existing stored records, loaded policy and handlers; this phase must not expand behavior. |
| Route rendered review and proof | Test/support route registry + demo browser | ExUnit/LiveView | Existing route contracts can prove source/structure; the served synthetic app is needed to review actual appearance and browser behavior. |

## Standard Stack

### Core

| Library / surface | Version | Purpose | Why standard |
|-------------------|---------|---------|--------------|
| Elixir / Phoenix LiveView | Current project lock resolves Phoenix `1.8.13` and LiveView `1.2.10` | Render server-driven admin pages and shared components | Existing UI, route behavior, and tests use this stack. The AGENTS guide's listed versions are older than the current lock; plan against `mix.lock`. [VERIFIED: `mix.lock:38-41`; quote: `"phoenix": {:hex, :phoenix, "1.8.13"` and `"phoenix_live_view": {:hex, :phoenix_live_view, "1.2.10"`; `mix.exs:12-15`; quote: `version: "1.5.1"` and `elixir: "~> 1.18"]` |
| `Lockspire.Web.Components.AdminComponents` | In-repo | Shared page hero, panels, actions, fields, status, records, empty/error and secret displays | Already used by admin route LiveViews; avoid new primitives when current components fit. [VERIFIED: `lib/lockspire/web/components/admin_components.ex:1-124`; exact component names include `page_hero/1`, `section_card/1`, `pane/1`, `entity_header/1`] |
| `Lockspire.Web.Admin.CSS` + brandbook `--ls-*` tokens | In-repo | Shared responsive/theme styles and semantic design values | CSS is embedded in the admin shell and token contract tests compare the implementation to the brandbook. [VERIFIED: `lib/lockspire/web/live/admin_layout_live.ex:60-63`; quote: `Phoenix.HTML.raw(Lockspire.Web.Admin.CSS.get())`; `test/lockspire/web/live/admin/design_system/css_contract_test.ex:14-24`] |
| ExUnit, LiveViewTest, route/CSS contract tests | In-repo | Blocking UI and safety regression coverage | Existing route-specific integration tests already prove copy, state, action, error, redaction and lifecycle behaviors. [VERIFIED: `test/lockspire/web/live/admin/design_system/route_contract_test.ex:7-58`; quote: `assert_read_only_operate_surfaces!()` and `assert_redaction_boundary!()`] |

### Supporting

| Surface | Purpose | When to use |
|---------|---------|-------------|
| Impeccable and Emil design-engineering review | Visual/copy critique of the actual rendered task flow | Use the approved UI spec and `2026-10-11` critique to guide, then adversarially review each changed live route; don't treat a detector's empty output as a clean visual audit. [CITED: `.impeccable/critique/2026-10-11T17-47-19Z__ire-web-live-admin-overview-live-index-ex-d708f649.md`, Detector and browser evidence; `.planning/REQUIREMENTS.md`, Delivery Rules] |
| Existing demo and browser surface | Confirm rendered result, theme select inset, actual page spacing, and route-specific content | Use synthetic data; no mutations that create real credentials and no screenshots with plaintext credentials. [CITED: `.planning/REQUIREMENTS.md`, Delivery Rules; `153-UI-SPEC.md`, Registry Safety and Route coverage] |

### Alternatives Considered

| Instead of | Could use | Tradeoff |
|------------|-----------|----------|
| Existing components and CSS tokens | New UI library, icon package, font, or tooltip framework | Adds dependencies and parallel conventions with no required capability; rejected by the approved spec. Keep labels textual and essential explanations inline. [CITED: `153-UI-SPEC.md`, Design System and Registry Safety] |
| Existing `page_hero/1` | Keep redundant eyebrow or replace it with more visible boilerplate | Preserves visual clutter; refactor the shared component and migrate all call sites. Use a distinct section title only when it helps the task. [CITED: `153-UI-CHECK.md`, Visuals; `153-UI-SPEC.md`, Component Inventory] |
| Native theme `<select>` with better right padding | Custom dropdown/chevron widget | A custom widget increases keyboard, theme, and assistive-tech behavior surface. Keep the native select and prove the requested 16px visible inset in the rendered browser. [CITED: `153-UI-SPEC.md`, Layout, spacing, theme, and accessibility] |

No packages are installed by this phase; Package Legitimacy Audit is not applicable. [CITED: `153-UI-SPEC.md`, Registry Safety]

## Architecture Patterns

### Route and component groupings for plan slices

The route set clusters naturally by shared implementation seams. Keep each slice narrow enough to test independently, and run the full route inventory review after shared APIs change.

| Slice | Route/component group | Recommended emphasis |
|-------|-----------------------|----------------------|
| A — shared shell and primitives | `AdminComponents.page_hero/1`, its HEEx call sites, `Admin.CSS`, theme select, CSS/route contract tests | Remove eyebrow from API and markup; retain a distinct title only when it introduces a useful section; correct select right inset; update affected component contract tests. Do not change shell ownership of H1, navigation grouping, saved theme behavior, or native select semantics. |
| B — Configure settings and onboarding | `/admin/policies` and its PAR, security-profile, DPoP, DCR routes; `/admin/dcr`; `/admin/iats` and `/admin/iats/new`; `/admin/keys` and key detail | Explain defaults, inheritance, registration gates and key lifecycle in plain terms where they affect a choice; remove redundant “review” text and unsupported inference; preserve confirmation and copy-once flows. |
| C — Client/security records | Client inventory, new-registration route, client workspace/edit/redirect/logout/policy/credential routes | Most client-task work is inherited from Phase 151; limit this slice to spec-backed shared hierarchy/copy regressions and include the new-registration route in final rendered review. Preserve filter return context and secret-clearing lifecycle. |
| D — Support records | Consent and token inventories/details; inherited Phase 152 overview and three read-only queues | Explain records in terms of what they establish and the next safe pivot; preserve exact single-record versus family revocation and Phase 152 read-state/queue contracts. No new queue controls. |

These are planning seams, not additional scope: a route should only be edited if its rendered page fails an approved contract. The route source explicitly registers `/clients/new` before `/clients/:client_id`, and the route registry appends a logout-propagation query workflow to mounted router paths. [VERIFIED: `lib/lockspire/web/admin_router.ex:10-15`; exact quote: `live("/clients/new", Lockspire.Web.Live.Admin.ClientsLive.Index, :new)` precedes `live("/clients/:client_id", ...)`; `test/support/lockspire/web/admin_proof/route_scorecards.ex:4-5,51-57`; exact workflow route is quoted in Phase Requirements]

### Pattern 1: Shared hero without mandatory eyebrow

**What:** Keep the page H1 in `AdminLayoutLive.shell/1`. Refactor `page_hero/1` so eyebrow is absent from its API and markup, then migrate all usages. Keep only content that helps the route: an appropriately distinct section title, short useful sentence, decision summary or actions. The UI-SPEC specifically calls for this API refactor before reuse. [VERIFIED: `admin_components.ex:50-73`; quote: `<h2>{@title}</h2>`; `[CITED: 153-UI-SPEC.md`, Component Inventory; `153-UI-CHECK.md`, Visuals]

**When to use:** Any route that still uses the shared hero, including inherited routes if they render regressions.

**Example shape:**

```heex
<AdminComponents.page_hero title="Signing keys" body={@useful_context}>
  <:actions>...</:actions>
</AdminComponents.page_hero>
```

The example is illustrative; the component API must be changed and its call sites compiled together. Do not quote as a required production string unless a route contract selects it. [CITED: `153-UI-SPEC.md`, Shared hierarchy and Component Inventory]

### Pattern 2: Review evidence, then write user language

**What:** For each route, verify the underlying record/policy facts and current action handler before editing the label. State the record or loaded value, supported consequence, and next available route/action. If the evidence is unavailable, preserve `Unavailable`; don't substitute `None`, zero, “healthy,” compromise, or remote sign-out claims. [CITED: `153-UI-SPEC.md`, User-facing language and Forms, actions, and consequences; `152-CONTEXT.md`, Decisions]

**When to use:** Policy inheritance, token/consent state, key readiness, DCR, logout delivery, and client-specific overrides.

**Example:** Phase 152 established the factual form “an already-used refresh token was presented again” and family revocation as the consequence; the view must not call the user compromised or imply which person/client caused it. [CITED: `152-CONTEXT.md`, Decisions]

### Pattern 3: Use the component that matches the task

Use a description list for a handful of decision facts, a resource list for actionable records, and a semantic table only for truly comparable fields. Keep one open page canvas, avoid nested panels, preserve visible actions, and place form help beside the choice it explains. [CITED: `153-UI-SPEC.md`, Shared hierarchy and Component Inventory]

### Anti-Patterns to Avoid

- **Eyebrow-and-title stacks:** shell H1, journey eyebrow, and repeated title compete. Remove eyebrow and keep only a distinct section title when needed.
- **“Measured from…” notes, “Current issuer setting” labels, or `role="status"` provenance:** these narrate implementation rather than user's decision; remove them rather than hiding them in tooltips. [CITED: Impeccable critique, Prioritized issues 2–3; `153-UI-SPEC.md`, Copywriting Contract]
- **Protocol prose dumps:** expand an acronym only where the user must choose or understand a practical consequence; avoid turning helper text into a protocol glossary. [CITED: `153-UI-SPEC.md`, User-facing language]
- **A card per fact or card-inside-card:** decorative borders increase density without establishing useful grouping. [CITED: `153-UI-SPEC.md`, Shared hierarchy]
- **Arbitrary action styling or hidden primary choices:** preserve the Phase151 safe-task action hierarchy; styling must match handler semantics.
- **One-shot multi-file component migration:** changing `page_hero/1` without updating every call site causes compile failures or leaves uneven UI. Search all calls and test route surfaces after the API edit.
- **Fixing observed UX by changing protocol behavior:** UI-only scope; never alter authorization semantics, host ownership, revocation boundaries, or queue mutability. [CITED: `REQUIREMENTS.md`, SAFE-01 and Out of Scope]
- **Native select with a border-hugging arrow:** existing horizontal padding is `var(--ls-space-3)` (12px); Phase UI contract requires at least 16px visible arrow inset. Adjust the right inset and test the native affordance, not only a source-text assertion. [VERIFIED: `lib/lockspire/web/admin_css.ex:287-295`; quote: `padding: var(--ls-space-2) var(--ls-space-3);`; `[CITED: 153-UI-SPEC.md`, theme select requirement]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| New shared UI kit | Third-party component package, custom icon system, or parallel token palette | `AdminComponents`, `Admin.CSS`, and brandbook semantic tokens | The project has established shared primitives; new dependency and competing design sources are explicitly excluded. |
| Theme selection | Custom JavaScript dropdown | Existing labeled native `<select>` and shell theme synchronization | It already handles theme state, saved preferences, patches, and accessible labels; this phase only addresses visual inset. [VERIFIED: `admin_layout_live.ex:64-80,125-147,159-166`] |
| Explanations | Tooltip for every removed line | Inline help only when it changes a decision; otherwise remove | Hover-only disclosure hides essential info and keeps noise around. [CITED: `153-UI-SPEC.md`, Copywriting Contract] |
| Route coverage inventory | New test-only route list that can drift | `RouteScorecards.expected_routes/0` plus the current approved route map | Runtime mounted routes and workflow exceptions are combined by the existing registry. [VERIFIED: `route_scorecards.ex:51-57`; quote: `Phoenix.Router.routes(Lockspire.Web.AdminRouter)` pipeline and `workflow_exceptions()`] |
| Visual comparison | Paid AI visual-judge API or external screenshot service | Local demo/browser proof plus Impeccable/Emil review | No paid visual API/dependency is approved; keep evidence local, synthetic and reviewable. [CITED: `REQUIREMENTS.md`, Out of Scope and Delivery Rules] |

**Key insight:** Most complexity is interpretive, not component engineering. Fix the shared title seam once, then make small evidence-backed edits at the LiveView that owns the user's task.

## Common Pitfalls

### Pitfall 1: Shared hero refactor leaves stale call sites

**What goes wrong:** Removing the required `eyebrow` attr breaks all HEEx calls that still pass `eyebrow=...`, or leaves title stacks untouched elsewhere.

**Why it happens:** `page_hero/1` is shared across routes; page markup is spread across `.ex` and `.heex` templates.

**How to avoid:** Enumerate every `page_hero` call before changing the signature; update templates and tests in the same slice; compile and run focused LiveView tests plus the relevant route smoke. [VERIFIED: `rg`-enumerated current sources; `AdminComponents.page_hero/1` definition at lines 50-73]

**Warning signs:** A source-only test passes but compilation or rendered pages retain “Configure/Support” eyebrow rows.

### Pitfall 2: Copy cleanup crosses the evidence boundary

**What goes wrong:** Simpler language overstates what a stored record proves, conflates a delivery with sign-out, or turns a key prerequisite check into an external-verifier guarantee.

**How to avoid:** Keep one verification fact beside any changed consequential copy; preserve exact distinctions and read failure states already documented in Phase 152. [CITED: `152-CONTEXT.md`, Decisions; `153-UI-SPEC.md`, User-facing language]

### Pitfall 3: Inherited route edits regress Phase 151/152 results

**What goes wrong:** The broad sweep reintroduces duplicated registration copy, removes the filtered inventory return, reveals a secret in screenshot state, changes action hierarchy, or alters queue filters/read-only behavior.

**How to avoid:** Treat the prior summaries and tests as regression contracts; route changes to inherited pages require a demonstrated visual regression. Include `/admin/clients/new` in the rendered route matrix. [CITED: `151-01-SUMMARY.md`, Accomplishments and D-02/D-03 coverage; `152-05-SUMMARY.md`, Decisions Made; `153-UI-SPEC.md`, Route coverage]

### Pitfall 4: Source assertions substitute for visual proof

**What goes wrong:** CSS has the expected value but native select caret remains edge-hugging; panels still feel cramped or the actual section order remains awkward.

**How to avoid:** Keep CSS/LiveView assertions fast and blocking; use the served demo to visually inspect the affected route in real light/dark/system themes. Phase154 owns screenshots and the complete responsive/zoom sweep. [CITED: `153-UI-SPEC.md`, Layout and UI Considerations; `.planning/ROADMAP.md`, Phase154 criteria]

### Pitfall 5: Route count is confused with scorecard count

**What goes wrong:** Evidence covers 29 historical scorecards but skips the new registration route, or duplicates root/overview and misses an actual route.

**How to avoid:** Use the source-derived current route set plus workflow exception, reconcile against the 30-row approved UI table, and mark one current rendered result per path. The scorecard implementation computes expected paths from mounted Phoenix routes and appends the query-workflow exception. [VERIFIED: `route_scorecards.ex:51-57`; quote: `Phoenix.Router.routes()` and `Enum.++(workflow_exceptions())`; `[CITED: 153-UI-SPEC.md`, current 30-route inventory]

## Code Examples

### Shared component and tests

The current component renders eyebrow, title, body, optional summary and actions in that order; shell owns the page-level title. [VERIFIED: `admin_components.ex:50-73`; quote `<h2>{@title}</h2>`; `admin_layout_live.ex:157-165`; quote `<h1>{@page_title}</h1>`]

```elixir
# After removing the eyebrow attr/rendering, this source-level shape remains:
<AdminComponents.page_hero title={@distinct_section_title} body={@decision_context}>
  <:actions>...</:actions>
</AdminComponents.page_hero>
```

Only use `page_hero` where a separate hero section earns space. The no-eyebrow API change should compile against every migrated caller and leave one page H1. Add/adjust LiveView assertions for exact helpful copy and absence of duplicate title/provenance rather than pinning large CSS class substrings. [CITED: `153-UI-CHECK.md`, Visuals; `153-UI-SPEC.md`, Shared hierarchy]

### Theme inset

CSS currently sets uniform 12px horizontal padding on the native select. The approved contract asks for a minimum 16px from the chevron to the border. Use the existing 16px spacing token for the right-side inset while preserving the left inset, visible native arrow, label, focus ring, and 320px behavior; confirm actual browser geometry. [VERIFIED: `admin_css.ex:287-299`; exact existing padding quoted under Anti-Patterns; `[CITED: 153-UI-SPEC.md`, theme selector contract]

## Route and Verification Map

| Group | Existing source/test seams | Focused verification |
|-------|---------------------------|-----------------------|
| Shared page shell and theme control | `admin_components.ex`, `admin_layout_live.ex`, `admin_css.ex`; `design_system/css_contract_test.exs`, `theme_sync_test.exs` | Test no required/rendered eyebrow for page hero; semantic tokens and focus/motion/responsive contracts; ensure theme select remains labeled/system-light-dark and visually insets arrow. |
| Client routes, including `/admin/clients/new` | `clients_live/index.ex`, `form_component.ex`, `show.ex`; `clients_live_test.exs`, `clients_live/show_test.exs`, `admin_router_test.exs` | Existing tests cover one title, normalized filters, submission errors, copy-once/clearing, client context, exact route ordering and actions. Re-run when shared calls or inherited copy changes. |
| Provider settings | `policies_live/index.ex`, `par.ex`, `security_profile.ex`, `dpop.ex`, `dcr.ex` and DCR HEEx; `policies_live/*_test.exs` | Keep defaults/inheritance distinctions, unavailable vs loaded values, policy persistence and rejected-save recovery; assert copy changes without altering form names/handler effects. |
| Signing keys and app registration | `keys_live/index.ex`, `keys_live/show.ex`, `dcr_live/index.ex`, `iat_live/*`; `keys_live_test.exs`, `dcr_live_test.exs`, `iat_live_test.exs` | State/transition facts, confirmation, private key redaction, registration gates and one-time setup token handling. |
| Support records | `consents_live/index/show.ex`, `tokens_live/index/show.ex`; `consents_live_test.exs`, `tokens_live_test.exs` | Filter scope, state/consequence copy, independent read errors, redaction, single-record vs family revocation. |
| Overview/read-only queues inherited | `overview_live/index.ex`, interactions/device/logout LiveViews; corresponding four tests | Re-run only if touched; preserve exact count/filter, facts, empty/error distinction, secret redaction, and no mutation event/control. |
| Route/style guardrails | `test/support/lockspire/web/admin_proof/route_scorecards.ex`; `route_contract_test.exs`, `css_contract_test.exs`, `inventory_contract_test.exs` | Current mounted route set, source boundaries, route actions, queue read-only, package boundary and tokens. Add route appearance coverage only if it gives stable recurring value. |

The route contract currently reads a historical Phase 144 browser inventory and asserts it is a subset of current routes; that does not itself prove that each current route was recently rendered. Use `expected_routes/0` and the approved UI table for the review matrix, rather than interpreting this test as 30-route visual coverage. [VERIFIED: `test/lockspire/web/live/admin/design_system/route_contract_test.exs:11-39`; quote: `MapSet.subset?(historical_routes, current_routes)`]

## State of the Art

This phase does not introduce a new technical platform. The current implementation already uses Phoenix components, tokenized BEM CSS, native controls, and server-rendered LiveViews; the contract is to improve consistency within those conventions. [VERIFIED: `153-UI-SPEC.md`, Design System; `admin_layout_live.ex:60-63`; `css_contract_test.exs:6-24`]

**Deprecated/outdated for this phase:**

- Mandatory admin hero eyebrows and generic “review this…” content are being removed by the approved UI contract, not replaced with another marketing-style intro. [CITED: `153-UI-CHECK.md`, Visuals; `153-UI-SPEC.md`, Copywriting Contract]
- Muted text `#64748b` on muted `#f1f5f9` is below the contract's normal-text 4.5:1 threshold; use an existing compliant semantic text value. [CITED: `brandbook/notes/accessibility-checks.md`, Light mode; `153-UI-SPEC.md`, contrast rule]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The demo/browser remains available to executor for rendered confirmation, while test commands run in the project environment. | Route and Verification Map | If unavailable, complete ExUnit and source review; rendered proof must be recorded as an environment limitation, not claimed. |
| A2 | No route outside the approved 30-route contract needs a new route or new data to improve its presentation. | Summary | Adding capability would breach scope and could change security semantics. |

## Open Questions

None for planning. The design contract is approved; implementation should use the agent's discretion within it and flag a concrete route/source conflict only if one is discovered.

## Environment Availability

Step 2.6 skipped: this phase needs no external service, package, or CLI beyond the project's existing Elixir/Mix test and local browser/demo proof surfaces. The approved contract adds no packages. [CITED: `153-UI-SPEC.md`, Registry Safety; `.planning/config.json`, workflow.nyquist_validation]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit + Phoenix LiveViewTest, versions resolved by project lock |
| Config file | `mix.exs`, test config and existing per-route ExUnit files |
| Quick run command | `MIX_ENV=test mix test <changed route test(s)> --max-failures 1` |
| Full suite command | `MIX_ENV=test mix test.fast` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| UI-01 | Every current route has one useful page title and task-first order, without duplicate hero/page title | LiveView render + route/browser review | `MIX_ENV=test mix test test/lockspire/web/live/admin/design_system/route_contract_test.exs test/lockspire/web/live/admin/overview_live_test.exs test/lockspire/web/live/admin/clients_live_test.exs` plus per-route changed tests | ✅ tests exist; add concise direct assertions for any changed view |
| UI-02 | Labels and help are plain, useful, consistent, and evidence-backed | LiveView render | Run changed route module tests; include state/error variants | ✅ route tests exist across Configure/Support |
| UI-06 | Component hierarchy, semantic token contrast, responsive CSS contract, and native theme select inset | CSS/component contract + browser | `MIX_ENV=test mix test test/lockspire/web/live/admin/design_system/css_contract_test.exs test/lockspire/web/live/admin/design_system/theme_sync_test.exs test/lockspire/web/live/admin/design_system/route_contract_test.exs` | ✅ contracts exist; add a stable CSS assertion for minimum right padding if absent, and browser check for actual arrow geometry |
| SAFE-01 regression boundary | Redaction, confirmations/revocation semantics, and read-only queue behavior survive shared UI edits | Route contract + affected LiveView integration tests | `MIX_ENV=test mix test test/lockspire/web/live/admin/design_system/route_contract_test.exs` and changed route modules | ✅ existing source contract and page tests |

The commands above use repo-native tests. Verification should follow the project's current Mix aliases if `test.fast` is the canonical fast suite; no browser package installation is necessary.

### Sampling Rate

- **Per task:** Run the owning LiveView/test module and relevant CSS/route contract after that task.
- **Per plan wave:** Run all affected Configure/Support modules plus `route_contract_test.exs` and `css_contract_test.exs`.
- **Phase gate:** Run focused affected tests and `MIX_ENV=test mix test.fast`; separately perform the approved current rendered review. Do not claim the slow suite passed unless it completes.
- Phase154 owns the final 30-route screenshot inventory and viewport/zoom/theme/keyboard proof, per roadmap dependency. [CITED: `.planning/ROADMAP.md`, Phase154 Success Criteria]

### Wave 0 Gaps

- The current route contract test checks source-derived route existence and that an older browser inventory is a subset, not that every current route rendered in this review. Create/update a human-readable route-review matrix or browser proof artifact for all 30 paths; keep it maintainer-only and synthetic. [VERIFIED: `route_contract_test.exs:11-39`; quote: `MapSet.subset?(historical_routes, current_routes)`; `[CITED: 153-UI-SPEC.md`, 30-route table]
- If the approved page-hero API changes, add/update a direct component/LiveView assertion that its markup does not emit a journey eyebrow; existing CSS contract checks do not currently assert hero semantics. [VERIFIED: `css_contract_test.exs:6-38`]
- Theme test coverage verifies preferences synchronize and storage errors are announced, but not the browser's visual caret-to-edge distance. A minimal CSS contract is appropriate; a one-time rendered check verifies the native control geometry. [VERIFIED: `theme_sync_test.exs:9-37`; `admin_css.ex:287-299`]

## Security Domain

### Applicable ASVS Categories

This is a display-only phase with existing safe mutation routes; threat mitigations are preservation tests, not new security mechanisms. No compliance certification is implied. [CITED: `AGENTS.md`, Security Defaults; `.planning/REQUIREMENTS.md`, SAFE-01]

| ASVS Category | Applies | Standard control for this phase |
|---------------|---------|--------------------------------|
| V2 Authentication | Yes, boundary preservation | Host retains staff authentication/MFA/roles; no auth behavior changes. |
| V3 Session Management | Yes, boundary preservation | Do not alter host staff sessions or OAuth protocol sessions while editing presentation. |
| V4 Access Control | Yes | Preserve host policy boundary and existing authorization/confirmation handlers. |
| V5 Input Validation | Yes | Keep existing form validation, normalized filter paths, exact routes and failed-submit states. |
| V6 Cryptography | Yes, preserve-only | Do not expose secrets/private key material; do not change cryptographic protocol or resolve CR-01 in this UI phase. |

### Known Threat Patterns for Embedded OAuth Admin UI

| Pattern | STRIDE | Standard mitigation |
|---------|--------|---------------------|
| Screenshot or visible copy leaks a one-time secret/token/user code/private key | Information disclosure | Synthetic values only; never capture credential-bearing result states; preserve redaction and copy-once lifecycle. |
| UI label overstates stored evidence or implies an unsupported operation | Information integrity / elevation | Review data read and handler before changing wording; keep queues read-only and exact consequences/scope. |
| Admin styling change hides focus or makes status color-only | Elevation / information disclosure | Preserve visible focus and text labels; test theme and contrast according to the brandbook contract. |
| UI cleanup moves host-owned login/branding/auth controls into Lockspire | Spoofing / elevation | Keep Lockspire's embedded-library/host-owned boundary explicit; only refine mounted admin content. |

## Project Constraints (from AGENTS.md)

- Keep Lockspire a separate embedded Phoenix/Elixir companion library; do not turn it into a standalone auth service or Sigra module.
- Preserve boundaries between protocol core, storage, generators, Plug/Phoenix integration, and admin/LiveView surfaces.
- Leave host account resolution, login redirects, claims, branding, and product policy to the host.
- Do not broaden into SAML, LDAP/AD federation, hosted auth, or full CIAM.
- Preserve PKCE S256 by default, exact redirect matching, hashed client secrets, short-lived single-use authorization codes, refresh rotation/family revocation, no implicit flow, no `alg=none`, and strong redaction.
- Keep calm admin workflows for clients, consents, tokens, and keys; no UI copy or styling change may weaken their safe behavior.

## Sources

### Primary — in-repo source of truth (HIGH confidence for current code)

- `AGENTS.md` — product and security boundaries.
- `.planning/REQUIREMENTS.md` UI-01/UI-02/UI-06/SAFE-01/PROOF-01 — approved phase scope and verification.
- `.planning/ROADMAP.md` Phases 151–154 — phase ownership and proof sequencing.
- `.planning/phases/153-configure-support-page-refinement/153-UI-SPEC.md` and `153-UI-CHECK.md` — approved design contract and checker pass.
- `.planning/phases/151-focused-client-registration-settings/151-CONTEXT.md` and summaries — registration, action, and secret lifecycle.
- `.planning/phases/152-overview-queue-state-clarity/152-CONTEXT.md`, `152-RESEARCH.md`, and summaries — factual state/queue boundaries.
- `.planning/milestones/v1.32-phases/121-route-scorecards-judgment-contract/121-ROUTE-SCORECARDS.md` — route JTBD, risk, and component fit.
- `.impeccable/critique/2026-10-11T17-47-19Z__ire-web-live-admin-overview-live-index-ex-d708f649.md` — prior visual findings and limitations.
- `brandbook/notes/decision-log.md`, `brandbook/notes/accessibility-checks.md`, `brandbook/tokens/tokens.css` — typography, color, theme and accessibility.
- `lib/lockspire/web/admin_router.ex`, `lib/lockspire/web/live/admin_layout_live.ex`, `lib/lockspire/web/components/admin_components.ex`, `lib/lockspire/web/admin_css.ex` — mounted routes, shell, component API, styles.
- `lib/lockspire/web/live/admin/**` and `test/lockspire/web/live/admin/**` — route behavior and focused tests.
- `test/support/lockspire/web/admin_proof/route_scorecards.ex`, `route_assertions.ex` — source-derived route inventory and structural guardrails.

### External

None required. This is an in-repo implementation pass with an approved design contract; no library choice or external API is under consideration.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — current project lock, source, and tests are available.
- Architecture: HIGH — component/shell/CSS seams are directly inspected.
- Pitfalls: HIGH — rooted in approved UI contract, route contracts, previous Impeccable critique, and Phase151/152 decision records.
- Rendered per-route details: MEDIUM — require a fresh run against the current served source, not the previous baseline capture.

**Research date:** 2026-10-12  
**Valid until:** 2026-11-12 for the stable in-repo architecture; re-check runtime lock versions before execution if dependencies change.
