---
phase: 108
slug: design-system-token-component-upgrade
status: complete
created: 2026-06-04
source: inline-research-after-subagent-model-failure
---

# Phase 108 Research: Design-System Token & Component Upgrade

## RESEARCH COMPLETE

Phase 108 should be planned as a foundation-first design-system upgrade, not as a broad admin UI redesign. The codebase already has a working embedded CSS source, a small Phoenix function-component module, and deterministic contract tests. The highest-leverage plan is to make the existing primitives semantic and reusable, then migrate only the clearest repeated raw markup.

## What To Know Before Planning

### Current Implementation Shape

- `lib/lockspire/web/admin_css.ex` is the single embedded admin CSS source. It defines `--ls-*` custom properties and `lockspire-admin-*` classes, and is injected by `lib/lockspire/web/live/admin_layout_live.ex`.
- Current tokens are useful but partly low-level: numeric spacing (`--ls-space-1` etc.), brand/gray scales, status bg/text pairs, radii, shadows, and transitions. Phase 108 needs semantic aliases/categories rather than a theming engine.
- `--ls-transition-bounce` exists but conflicts with the Phase 108 motion contract. Replace the public bouncy concept with duration/easing/property tokens.
- Raw hex drift exists outside token declarations in alert and confirmation border rules: `#fde68a`, `#fecaca`, and `#bae6fd`. Move these behind semantic tokens before adding a strict raw-hex fence.
- Existing reduced-motion CSS already sets near-zero animation/transition duration and neutralizes active button transforms. Phase 108 should preserve and test that explicitly.
- `lib/lockspire/web/components/admin_components.ex` already owns shared admin Phoenix function components: status badges, section cards, admin buttons, action bars, alerts, description lists, summary stats, resource lists/items, badge groups, confirmation panels, empty states, policy nav, timestamps, and error lists.
- Several Phase 108 target primitives exist as raw CSS/markup rather than components: page hero sections, summary grids, secret reveal panels, filter forms/result counts, resource/list variants, and table/list rows.
- `test/lockspire/web/live/admin/design_system_contract_test.exs` is the right deterministic fence. It already checks namespaced classes, CSS primitive definitions, route/docs journey alignment, and no inline layout styles.

### Strong Source Patterns To Preserve

- `OverviewLive.Index` and `DcrLive.Index` have the strongest reusable shape: hero, primary action, metrics, task/attention cards, and route-next-action links.
- `ClientsLive.Index`, `TokensLive.Index`, and `ConsentsLive.Index` show repeated filter shell patterns: URL-owned form state, field stack, action bar, result-count help text, empty state, and resource/list output.
- `ClientsLive.Index`, `ClientsLive.Show`, and `RotateSecretComponent` show copy-once secret reveal markup. This should become one component so secrets and RATs avoid page-specific reveal structure.
- `InteractionsLive.Index` and `LogoutDeliveriesLive.Index` still use raw tables. Do not redesign these pages in Phase 108, but add row/table/long-value primitives Phase 109 can consume.
- `DeviceAuthorizationsLive.Index` uses a generic `lockspire-admin-list`; it is a good future Phase 109 target after Phase 108 provides a responsive row primitive.

### Planning Constraints

- Keep all existing component APIs backward-compatible. Add new components and optional slots; do not rename existing public helpers.
- Keep LiveViews responsible for URL state, data loading, and page intent. Components should render structure, state, actions, and safety treatment.
- Keep all admin CSS classes under `lockspire-admin-*`.
- Do not introduce Tailwind, shadcn, an icon set, a host theming engine, generated host-editable components, or a split asset pipeline.
- Do not solve inline CSS/CSP delivery unless it falls out without install-DX cost. The phase should only ensure route markup avoids inline layout styles.
- Use small rendered component assertions where structural output matters; avoid brittle full snapshots.
- Browser screenshots, mobile no-overflow proof, visual regression, and route-wide click-through remain Phase 110 scope.

## Recommended Plan Shape

### Plan 01: Token Contract And Static Fences

Upgrade `Lockspire.Web.Admin.CSS` tokens in place and extend the deterministic contract tests before broad component migration.

Key work:

- Add semantic token categories for surface, text, border, status, spacing, control size, radius, shadow, typography, focus, z-index, and motion.
- Keep existing numeric/scale tokens as compatibility aliases where needed.
- Move alert and confirmation border hex colors behind semantic tokens.
- Replace `--ls-transition-bounce` with public motion duration/easing/property tokens.
- Make button transitions use motion tokens consistently.
- Extend contract tests for required token categories, reduced-motion behavior, active-transform neutralization, raw hex outside token declarations, and no inline layout styles across admin LiveViews.

Verification emphasis:

- `mix test test/lockspire/web/live/admin/design_system_contract_test.exs`
- `mix compile --warnings-as-errors`

### Plan 02: Shared Component Primitives

Expand `Lockspire.Web.Components.AdminComponents` with backward-compatible Phoenix function components that wrap the repeated structural patterns.

Target components:

- `page_hero` with eyebrow, title, body, optional summary slot, optional actions slot.
- `metric_grid` and a metric item helper or slot contract around existing `summary_stat`.
- `task_card` or `attention_card` for journey/task cards.
- `filter_bar` that owns layout only and renders form fields/actions/result copy through slots.
- Improved `resource_item` slots for subtitle, metadata, status cluster, and actions; preserve existing API.
- `copy_once_secret_panel` for client secret, IAT plaintext, and RAT plaintext.
- `action_group` for primary/secondary/destructive grouping and mobile stacking.
- `empty_notice` or richer `empty_state` action slot.
- `long_value` for IDs, URLs, subjects, clients, token families, timestamps, and redacted values.

Component API notes:

- Use explicit `attr` and `slot` declarations for all new components.
- Keep text labels visible; Phase 108 uses no icon-only actions.
- Favor slots over domain-specific assigns for route-owned data.
- Do not create domain workflow components such as `token_incident_card` or `logout_delivery_row`.

Verification emphasis:

- Add focused component-render tests or source contract tests for exported function names, classes, and structural output.
- Keep tests resilient to copy changes unless copy is part of the UI contract.

### Plan 03: Behavior-Neutral Migrations

Replace only obvious repeated raw structures after token and component contracts exist.

Good Phase 108 migrations:

- `OverviewLive.Index` and `DcrLive.Index` hero blocks to `page_hero`.
- Raw summary stat grids to `metric_grid`/metric primitives on overview, DCR, and policy posture pages.
- `ClientsLive.Index`, `TokensLive.Index`, and `ConsentsLive.Index` filter shells to `filter_bar` while preserving URL-driven forms.
- `ClientsLive.Index`, `RotateSecretComponent`, and RAT reveal markup in `ClientsLive.Show` to `copy_once_secret_panel`.
- Obvious action bars to `action_group` where destructive grouping is relevant.
- Long identifier/timestamp displays to `long_value` where safe and behavior-neutral.

Avoid in Phase 108:

- Reworking interactions, device authorizations, logout deliveries, tokens, consents, or IATs into new IA.
- Removing tables categorically.
- Changing route data loading, params, events, or protocol semantics.

Verification emphasis:

- Existing admin LiveView tests for migrated routes.
- Contract tests proving primitive usage and no inline layout styles.
- Compile with warnings as errors.

## Risk Register

| Risk | Why It Matters | Mitigation |
|------|----------------|------------|
| Component overreach | Domain workflow components would make Phase 109 less flexible and blur LiveView ownership. | Keep components structural and slot-based. |
| Token churn | Renaming/removing existing low-level tokens can regress CSS broadly. | Add semantic aliases in place and migrate rules incrementally. |
| Brittle tests | Full HTML snapshots would fail on harmless copy/layout changes. | Prefer source/static fences and small structural render assertions. |
| Scope creep into weak-page polish | Phase 109 owns route-specific IA fixes. | Migrate only obvious repeated markup and defer weak-page recomposition. |
| Secret exposure | Copy-once material may accidentally be rendered or tested as raw evidence. | Centralize reveal panels and avoid logging/documenting raw secret values. |
| CSP distraction | Inline CSS delivery is a real future concern but not this phase's DX target. | Record as deferred unless a no-friction improvement emerges. |

## Validation Architecture

Phase 108 can be validated with the existing ExUnit/Phoenix test stack. No Node/CSS parser is needed unless regex/static checks become unmaintainable.

### Automated Checks

- `mix test test/lockspire/web/live/admin/design_system_contract_test.exs`
- Targeted LiveView tests for migrated routes, such as:
  - `mix test test/lockspire/web/live/admin/overview_live_test.exs`
  - `mix test test/lockspire/web/live/admin/clients_live_test.exs`
  - `mix test test/lockspire/web/live/admin/tokens_live_test.exs`
  - `mix test test/lockspire/web/live/admin/consents_live_test.exs`
- `mix compile --warnings-as-errors`

### Required Contract Assertions

- Required semantic token categories exist.
- Reduced-motion media rule exists and neutralizes active transforms.
- Raw hex values appear only in token declarations.
- All shared primitive classes are namespaced with `lockspire-admin-*`.
- Admin LiveViews do not contain `style=`.
- Canonical primitive coverage exists for hero, metric grid/stat, task/attention card, filter bar, resource row, empty state, confirmation panel, copy-once secret panel, long-value display, status cluster, and action group.
- New component APIs use `attr` and `slot` declarations.

### Manual Checks

Manual browser or screenshot proof is not required for Phase 108 completion. Phase 110 owns screenshot inventory, final mobile overflow proof, and browser click-through evidence.

## Open Planning Notes

- The planner should decide whether Phase 108 needs two or three plan files. Three is cleaner: token/tests, component API, then migrations.
- If time or risk pressure requires trimming, keep Plan 01 and Plan 02 complete and reduce Plan 03 to only hero/metric/secret reveal migrations.
- The implementation should not commit to a public theming API; semantic tokens are internal repeatability primitives for the embedded admin surface.
