# Phase 116 Component And Group Inventory

This inventory locks LAB-01 as a two-tier contract: canonical `Lockspire.Web.Components.AdminComponents` API plus production usage, known exceptions, missing states, and Phase 118 candidates. It records design-system pressure without implementing new runtime components in Phase 116.

Phoenix function components with attrs/slots remain the default design-system shape. LiveViews keep page intent, URL state, loading behavior, and mutations. Phase 116 does not introduce domain-specific workflow components.

## Canonical Primitive API

| Function component | Attrs/slots shape | Primary CSS classes | Supported states and fallback behavior |
|--------------------|-------------------|---------------------|----------------------------------------|
| `status_badge` | `attr :status` | `lockspire-admin-badge`, status variants | Known atoms render semantic labels; unknown atoms fall back to disabled badge copy. |
| `section_card` | `title`, `subtitle`, `inner_block` | `lockspire-admin-card` | Structural section wrapper for content groups. |
| `page_hero` | `eyebrow`, `title`, `body`, `summary`, `actions` | `lockspire-admin-hero`, `lockspire-admin-page-hero` | Route heading, summary, and action grouping. |
| `pane` | `title`, `subtitle`, `status`, `actions`, `inner_block` | `lockspire-admin-pane` | Structural pane wrapper for grouped admin content. |
| `entity_header` | `eyebrow`, `title`, `subtitle`, `identifier`, `status`, `actions`, `meta` | `lockspire-admin-entity-header` | Entity heading with long identifier, status cluster, and actions. |
| `workflow_shell` | `title`, `help`, `errors`, `body`, `actions`, `inner_block` | `lockspire-admin-workflow-shell` | Workflow chrome while LiveViews keep form and mutation behavior. |
| `status_cluster` | `inner_block` | `lockspire-admin-status-cluster` | Wrapping group for repeated status badges. |
| `metric_grid` | `wide`, `inner_block` | `lockspire-admin-summary-grid`, `lockspire-admin-metric-grid` | Dense metric layout with wide variant. |
| `decision_summary` | `item` slot with `label`, `value`, `detail`, `tone` | `lockspire-admin-decision-summary` | Compact decision summary for policy and operator posture pages. |
| `task_card` | `title`, `subtitle`, `state`, `actions`, `inner_block` | `lockspire-admin-task-card` | Workflow task grouping with optional state text. |
| `filter_bar` | `action`, `method`, `fields`, `help`, `actions` | `lockspire-admin-filter-bar` | Search/filter form shell. |
| `admin_button` | `variant`, `type`, `href`, `disabled`, `rest`, `inner_block` | `lockspire-admin-btn` variants | Link, disabled link, and button rendering share variant styling. |
| `form_field` | `id`, `label`, `help`, `errors`, `required`, `inner_block` | `lockspire-admin-field`, `lockspire-admin-field-errors` | Help/error IDs and required marker for production form primitive pressure. |
| `error_summary` | `title`, `errors` | `lockspire-admin-error-summary` | Alert summary appears only when errors exist. |
| `action_bar` | `inner_block` | `lockspire-admin-action-bar` | Routine action grouping. |
| `alert` | `variant`, `title`, `rest`, `inner_block` | `lockspire-admin-alert` variants | Info/warning/danger semantic messaging. |
| `description_list` | `item` slot with label | `lockspire-admin-description-list` | Key-value detail groups. |
| `summary_stat` | `value`, `label` | `lockspire-admin-summary-stat` | Metric summary item. |
| `resource_list` | `inner_block` | `lockspire-admin-resource-list` | List wrapper for resource rows. |
| `resource_item` | `href`, `title`, `subtitle`, `meta`, `status`, `actions` | `lockspire-admin-resource-list__item` | Dense row with metadata, status cluster, and actions. |
| `dense_resource_row` | `title`, `subtitle`, `meta`, `status`, `actions` | `lockspire-admin-dense-resource-row` | Compact row for Support and Operate dense data. |
| `lifecycle_row` | `title`, `state`, `domain`, `timestamp`, `actor`, `consequence`, `actions` | `lockspire-admin-lifecycle-row` | Lifecycle state/action row with consequence copy. |
| `responsive_table` | `caption`, `thead`, `tbody`, `list`, `empty` | `lockspire-admin-responsive-table` | Table wrapper with narrow list and empty alternatives. |
| `copy_once_secret_panel` | `title`, `body`, `value`, `redacted`, `label` | `lockspire-admin-copy-once-secret` | Shows copy-once value or redacted placeholder. |
| `long_value` | `value`, `kind`, `redacted` | `lockspire-admin-long-value` | Wraps IDs, URLs, tokens, timestamps, and mono values; redacted fallback. |
| `action_group` | `primary`, `secondary`, `destructive` | `lockspire-admin-action-group` | Separates primary, secondary, and destructive actions. |
| `badge_group` | `inner_block` | `lockspire-admin-badge-group` | Status cluster grouping. |
| `confirmation_panel` | `title`, `variant`, `errors`, `body`, `actions` | `lockspire-admin-confirmation-panel` | Warning/danger confirmation shell. |
| `empty_state` | `title`, `body` | `lockspire-admin-empty` | Empty state copy and body. |
| `policy_nav` | generated items | `lockspire-admin-secondary-nav` | Policy section navigation. |
| `timestamp` | `value` | `lockspire-admin-tabular` | ISO datetime or "Not recorded" fallback. |
| `error_list` | `errors` | `lockspire-admin-errors` | Inline list for formatted errors. |

## Reusable Operator Building Blocks

| Group | Includes | Production usage points |
|-------|----------|-------------------------|
| Primitives | `status_badge`, `admin_button`, `form_field`, `error_summary`, `alert`, `timestamp`, `error_list` | Client, key, token, consent, IAT, DCR, policy, support, and operate forms and rows. |
| Recurring meta-components | `page_hero`, `pane`, `entity_header`, `workflow_shell`, `section_card`, `metric_grid`, `decision_summary`, `task_card`, `filter_bar`, `action_bar`, `description_list`, `summary_stat`, `resource_list`, `resource_item`, `dense_resource_row`, `lifecycle_row`, `responsive_table`, `action_group`, `badge_group`, `status_cluster`, `confirmation_panel`, `empty_state`, `long_value`, `copy_once_secret_panel`, `policy_nav` | Overview, DCR, policies, keys, clients, support, tokens, consents, interactions, device authorizations, and logout deliveries. |
| CSS-only patterns | Table wrappers, detail sections, code blocks, client workspace grids, status clusters, theme selector, mobile form shells | `lib/lockspire/web/admin_css.ex`, admin LiveViews, and HEEx templates. |
| Direct-markup exceptions | Remaining page-local buttons, raw field wrappers, queue rows, table rows, page-local detail sections, destructive confirmations, and mobile-sensitive action clusters | Configure, Support, and Operate routes that predate the shared primitives. |
| Tested/lab-only fixtures | `DesignSystemComponentStressTest.StressSurface` and future Phase 117 lab fixtures | ExUnit-rendered proof only; not mounted through `AdminRouter`. |

## Production Usage Points

- Overview and DCR use `page_hero`, `metric_grid`, `summary_stat`, `task_card`, and journey card structures.
- Clients use `filter_bar`, `resource_item`, `action_group`, `copy_once_secret_panel`, `confirmation_panel`, endpoint form patterns, and long-value handling.
- Policies and keys use `policy_nav`, `section_card`, `description_list`, `status_badge`, `confirmation_panel`, and lifecycle action grouping.
- IAT, DCR, and registration management routes use form shells, copy-once panels, status badges, and redaction copy.
- Support routes use `filter_bar`, `resource_item`, `long_value`, `status_badge`, `confirmation_panel`, and investigation detail groups.
- Operate routes use `metric_grid`, `summary_stat`, `resource_item`, `long_value`, and queue rows with read-only support truth.

## Missing States

The inventory exposes missing state coverage for normal, empty, error, disabled, destructive, long-value, dense-data, light, dark, system, reduced-motion, focus, and mobile states. Later phases must prove these states in the lab and browser evidence instead of treating a single happy path as coverage.

Known exceptions to resolve or document:

- Contract keywords for later proof: Production usage points, direct-markup exceptions, Missing states, Phase 118 candidates, status fallback pressure, and form primitive pressure.
- Direct button/action markup still appears where a route has not moved to `admin_button` and `action_group`.
- Form/error patterns are split between shared `form_field`/`error_summary` and page-local wrappers.
- Page-local detail sections remain in client, token, consent, key, and policy surfaces.
- Queue rows for interactions, device authorizations, and logouts need route-specific pressure proof.
- Remaining tables need table/list alternatives for narrow screens.
- Long-value handling gaps remain for URLs, client IDs, account IDs, token handles, thumbprints, scopes, and timestamps.
- Status fallback pressure exists when real Configure, Support, and Operate status atoms fall through to disabled styling.
- Redaction boundaries must stay explicit for copy-once and hashed/handle-only proof.
- Disabled states, destructive confirmations, and mobile-sensitive layouts need hostile fixture coverage.

## Phase 118 Candidates

Phase 118 candidates are reusable meta-components, not Phase 116 implementations:

- architectural panes
- entity headers
- workflow shells
- status/action clusters
- lifecycle rows
- dense resource rows
- table/list alternatives

These candidates should absorb repeated structure while keeping domain-specific workflow behavior inside LiveViews.

## DS Pressure

DS-03 status fallback pressure: real Configure, Support, and Operate statuses should not silently render as disabled unless disabled is the intended meaning.

DS-04 form primitive pressure: production forms should use shared field, help, error, copy-once, and workflow primitives where practical, or document tested exceptions.
