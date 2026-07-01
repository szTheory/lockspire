# Phase 108: Design-System Token & Component Upgrade - Patterns

**Phase:** 108 - Design-System Token & Component Upgrade
**Created:** 2026-06-04

## Pattern Mapping Complete

Phase 108 modifies the existing admin CSS, shared component module, and deterministic design-system contract tests. It should reuse the shipped Phoenix-native admin patterns and avoid route behavior changes.

## Source Artifacts To Modify

| Planned Artifact | Role | Closest Existing Analog | Pattern To Reuse |
|------------------|------|-------------------------|------------------|
| `lib/lockspire/web/admin_css.ex` | Embedded admin CSS token and class source | Existing `--ls-*` tokens and `lockspire-admin-*` BEM-ish classes | Add semantic aliases in place; keep low-level tokens compatible; keep all selectors namespaced |
| `lib/lockspire/web/components/admin_components.ex` | Shared Phoenix admin function components | `section_card/1`, `admin_button/1`, `resource_item/1`, `confirmation_panel/1`, `empty_state/1` | Use explicit `attr` and `slot`; structural components only; preserve existing function signatures |
| `test/lockspire/web/live/admin/design_system_contract_test.exs` | Deterministic design-system fence | Existing source-string assertions over CSS/components/LiveViews | Extend static checks for token categories, reduced motion, raw hex drift, primitive coverage, and no inline styles |
| `lib/lockspire/web/live/admin/overview_live/index.ex` | Strong hero/metric/task source and narrow migration target | Current raw hero and summary grid markup | Replace only obvious hero/metric structures with shared primitives |
| `lib/lockspire/web/live/admin/dcr_live/index.ex` | Strong onboarding hero/metric/task source and narrow migration target | Current raw hero, summary grid, and section-card task cards | Replace only obvious hero/metric structures with shared primitives |
| `lib/lockspire/web/live/admin/clients_live/index.ex` | Filter/resource/secret reveal source and migration target | URL-owned form, `resource_item`, raw `lockspire-admin-secret-reveal` | Use `filter_bar`, improved row primitives, and `copy_once_secret_panel` without changing params/events |
| `lib/lockspire/web/live/admin/tokens_live/index.ex` | Support filter/list duplication source | URL-owned form and `lockspire-admin-token-list` | Use layout-only filter primitive; do not redesign support IA in Phase 108 |
| `lib/lockspire/web/live/admin/consents_live/index.ex` | Support filter/list duplication source | URL-owned form and `lockspire-admin-consent-list` | Use layout-only filter primitive; do not redesign support IA in Phase 108 |
| `lib/lockspire/web/live/admin/clients_live/rotate_secret_component.ex` | Copy-once secret treatment source | Raw `lockspire-admin-secret-reveal` markup | Replace with `copy_once_secret_panel`; preserve secret visibility semantics |
| `lib/lockspire/web/live/admin/clients_live/show.ex` | RAT reveal and dense action-group source | Raw `lockspire-admin-secret-reveal`, confirmation panels, action bars | Only replace copy-once/action primitives where behavior-neutral |

## Existing Code Patterns

### Embedded CSS Token Source

`Lockspire.Web.Admin.CSS` keeps CSS inside an Elixir module and exposes `get/0`. The plan should edit this file directly and avoid adding host asset pipeline requirements.

Important existing categories:

- Spacing: `--ls-space-1` through `--ls-space-12`
- Typography: `--ls-font-sans`, `--ls-font-mono`
- Colors: brand, gray, and status bg/text tokens
- Radius: `--ls-radius-sm` through `--ls-radius-xl`
- Shadow: `--ls-shadow-sm` through `--ls-shadow-lg`
- Motion: `--ls-transition-fast`, `--ls-transition-bounce`

Phase 108 should add semantic categories such as surface, text, border, focus, control size, typography size/weight/line-height, z-index, and motion duration/easing/property tokens. Keep current low-level tokens as compatibility aliases rather than deleting them.

### Raw Hex Drift

Raw hex values currently appear in token declarations, plus alert and confirmation border declarations. The non-token values that should move behind semantic tokens are:

- Alert warning border: `#fde68a`
- Alert danger border: `#fecaca`
- Alert info border: `#bae6fd`
- Danger button hover border: `#fecaca`
- Confirmation warning border: `#fde68a`
- Confirmation danger border: `#fecaca`

Add the raw-hex contract after these are tokenized.

### Reduced Motion

The CSS already includes:

- `@media (prefers-reduced-motion: reduce)`
- near-zero animation/transition duration
- active button transform neutralization

Keep this behavior, but make it explicit in tests. The public token contract should not preserve `--ls-transition-bounce`.

### Shared Components

`AdminComponents` already follows Phoenix function component idioms:

- `attr(...)` declarations for component inputs
- `slot(...)` declarations for flexible markup
- private class helpers such as `button_class/1`, `alert_class/1`, and `confirmation_panel_class/1`
- structure-only helpers with route data owned by LiveViews

New components should follow the same pattern. Prefer slot-based primitives over domain-specific components.

## Migration Analog Map

| Primitive | Existing Source | Migration Pattern |
|-----------|-----------------|-------------------|
| `page_hero` | raw `<section class="lockspire-admin-hero">` in overview, DCR, policies | Add component with `eyebrow`, `title`, optional body/actions/summary slots; migrate strong source routes first |
| `metric_grid` | raw `lockspire-admin-summary-grid` plus `summary_stat` markup | Add wrapper component around existing summary stat class; keep `summary_stat/1` compatible |
| `task_card` / `attention_card` | `section_card` dashboard cards on overview and DCR | Add structural primitive only if it reduces repeated page-card intent; otherwise document `section_card` as accepted attention card |
| `filter_bar` | forms in clients, tokens, consents | Layout-only wrapper with slots for fields, result/help text, and actions; forms still own method/action/params |
| `resource_item` / row | `resource_item/1`, `lockspire-admin-token-list`, `lockspire-admin-consent-list`, `lockspire-admin-list` | Improve slots/classes for title/subtitle/meta/status/actions and long wrapping; do not redesign weak lists |
| `copy_once_secret_panel` | `lockspire-admin-secret-reveal` in clients index, rotate secret, client show RAT reveal | Centralize title/body/value/redacted states; never log or test raw secret evidence |
| `action_group` | `action_bar/1`, confirmation actions | Add role-aware grouping for primary/secondary/destructive actions; mobile stacking via CSS |
| `long_value` | `lockspire-admin-display-value`, `lockspire-admin-tabular`, `lockspire-admin-code-block` | Add component/class for IDs, URLs, timestamps, token families, redacted values with `overflow-wrap:anywhere` |

## Constraints For Planner

- Do not add new dependencies.
- Do not create host-editable components or a theming API.
- Do not rename or remove existing component functions.
- Do not change admin route behavior, query params, events, protocol semantics, or storage behavior.
- Do not rework weak support/operations page IA; provide primitives for Phase 109.
- Do not make screenshots or browser proof blocking for Phase 108.

## Verification Hooks

Recommended assertions in `design_system_contract_test.exs`:

- CSS contains semantic token prefixes/categories: `--ls-surface-`, `--ls-text-`, `--ls-border-`, `--ls-status-`, `--ls-space-`, `--ls-control-`, `--ls-radius-`, `--ls-shadow-`, `--ls-font-`, `--ls-focus-`, `--ls-z-`, `--ls-motion-`.
- CSS contains `@media (prefers-reduced-motion: reduce)` and active transform neutralization.
- Raw hex matches are allowed only on lines that declare `--ls-` tokens.
- Component source contains new function names and `attr`/`slot` declarations for required primitives.
- CSS contains primitive classes for hero, metrics, task/attention card, filter bar, resource row, empty state, confirmation panel, copy-once secret panel, long values, status cluster, and action group.
- All admin LiveViews remain free of `style=`.

## PATTERN MAPPING COMPLETE
