---
phase: "153"
slug: "configure-support-page-refinement"
status: draft
shadcn_initialized: false
preset: none
created: "2026-10-12"
---

# Phase 153 — UI Design Contract

> Visual and interaction contract for the Configure and Support cleanup. The route map also records the 151/152 decisions inherited by the full 30-route review.

## Design System

| Property | Value |
|----------|-------|
| Tool | Manual — Lockspire's Phoenix components and tokenized BEM CSS |
| Preset | Not applicable |
| Component library | `Phoenix.Component` with `Lockspire.Web.Components.AdminComponents` |
| Icon library | None; visible text labels carry meaning and no icon dependency is needed |
| Font | Familjen Grotesk for headings, Inter for UI/body, JetBrains Mono for identifiers; existing system fallbacks; no bundled fonts or external font fetch |

The visual source of truth is `brandbook/tokens/tokens.css`, with the shipped equivalent in `Lockspire.Web.Admin.CSS`. Keep the Signal Cyan identity and the established semantic aliases. Do not add a component library, a parallel token set, or a new font dependency.

Evidence applied: the Impeccable review found grouped navigation and direct routes useful, while duplicate headings and implementation-provenance notes competed with the task. It also identified a real contrast miss for muted text on the muted surface; this contract fixes that combination without changing the intentionally Inter-led body type. The user's screenshot feedback additionally sets a concrete minimum inset for the theme select chevron.

## Component Inventory

Enumerated by `rg -c '^  def [a-z0-9_]+\(assigns\) do$' lib/lockspire/web/components/admin_components.ex && rg -n 'version:' mix.exs | head -1` — 32 components — `Lockspire.Web.Components.AdminComponents` (internal)@1.5.1 — 2026-10-12.

This is a non-exhaustive set of proven patterns, not an allowlist. Use an existing component when it fits the user task; do not add a nested card just because a card component exists.

| Component | Import path | Notes |
|-----------|-------------|-------|
| `page_hero/1` | `Lockspire.Web.Components.AdminComponents` | Refactor to remove its required eyebrow from the API and rendered markup before reuse; render only a distinct title, useful supporting sentence, summary, and actions. |
| `entity_header/1` | `Lockspire.Web.Components.AdminComponents` | Client/key identity, current state, and direct context return; avoid a second title that restates the page H1. |
| `pane/1`, `section_card/1` | `Lockspire.Web.Components.AdminComponents` | Use for meaningfully separate sections; avoid card-inside-card and decorative containers. |
| `workflow_shell/1` | `Lockspire.Web.Components.AdminComponents` | Focused form task, concise help, errors, and primary/secondary actions. |
| `form_field/1`, `error_summary/1`, `error_list/1` | `Lockspire.Web.Components.AdminComponents` | Keep labels, decision-relevant help, and errors associated with the control. Preserve submitted values on validation failures. |
| `radio_group/1`, `checkbox_group/1`, `multi_value_control/1` | `Lockspire.Web.Components.AdminComponents` | Single choice, bounded multiple choice, and open-ended multiple values. Share labels, errors, compact spacing and native form semantics. |
| `filter_bar/1` | `Lockspire.Web.Components.AdminComponents` | Keep filters visible and grouped; include a clear/reset action when supported. |
| `admin_button/1`, `action_bar/1`, `action_group/1` | `Lockspire.Web.Components.AdminComponents` | Apply the existing primary/secondary/danger semantics below. |
| `confirmation_panel/1` | `Lockspire.Web.Components.AdminComponents` | State target, exact scope, and supported consequence before the existing confirmation. |
| `description_list/1`, `decision_summary/1` | `Lockspire.Web.Components.AdminComponents` | Prefer for a small set of decision facts; omit repeated metrics and provenance. |
| `resource_list/1`, `resource_item/1`, `dense_resource_row/1`, `lifecycle_row/1` | `Lockspire.Web.Components.AdminComponents` | Use for records when identity, state, consequence, and next pivot matter together. |
| `responsive_table/1` | `Lockspire.Web.Components.AdminComponents` | Reserve for genuinely comparable rows/columns; preserve readable labels in the narrow layout. |
| `status_badge/1`, `status_cluster/1`, `badge_group/1`, `alert/1` | `Lockspire.Web.Components.AdminComponents` | Status always has text; color reinforces but never carries meaning alone. |
| `empty_state/1`, `long_value/1`, `copy_once_secret_panel/1`, `policy_nav/1` | `Lockspire.Web.Components.AdminComponents` | Empty results, wrapping long values, one-time credential handling, and in-policy navigation. |

## Page and Interaction Contract

### Shared hierarchy

- Render exactly one page-level H1 from the admin shell. It names the resource or the user's task. Use section headings only when they introduce different information. Do not add an eyebrow or kicker above a heading.
- Start each route with the minimum context needed to orient the user: the selected client/key where applicable, one concise purpose sentence only when it changes a decision, and an obvious return path. Do not add a generic introduction before content that already makes the task clear.
- Order content by job: identity/current state → decision-relevant facts → the form, record, or next action → secondary context. For lists, show useful filters and exact result scope before records. For detail views, show the record's state and implication before dense metadata.
- Use one unboxed page canvas, with a panel only where grouping improves scanability. Do not wrap panels in another panel. Use a description list for a handful of facts, a resource list for actionable records, and a semantic table only when users compare the same fields across many records.
- Keep related safe actions visible. Never create competing primary actions without a distinct task reason. Do not hide decision-critical choices or consequences behind hover, a tooltip, a menu, or an unexplained icon.
- Remove implementation provenance such as “measured from inventory” and generic “review context” explanations. Do not relocate low-value copy into a tooltip. Keep factual source/unavailable information only when it changes trust in the value or the next action.

### User-facing language

- Write for a staff member configuring a provider or helping an application team, including someone who does not work with OAuth every day. Use short, concrete sentences and familiar verbs. Each helper line must answer what a choice does, why it matters, or what to do next; otherwise remove it.
- Call the registered integration a **client** where it identifies the OAuth object or matches a field/API term; explain once in plain context that it is the application connecting to this provider. Use “application” in general prose when that reads more naturally. Keep one term consistent within a page.
- Prefer “provider default” or “Lockspire default” to “issuer-wide” or unexplained “issuer” when describing a setting inherited by clients. Preserve “issuer” when a protocol endpoint/claim must be identified; give a plain-language cue beside it.
- Keep required protocol terms accurate, but introduce them with their practical meaning: examples include exact browser callback URLs (redirect URIs), app self-registration (Dynamic Client Registration/DCR), and key-bound access tokens (DPoP). Explain PAR, FAPI, JWKS, and token types only on routes where the term changes a setup or review decision. Do not expand acronyms into another paragraph of protocol jargon.
- Prefer the concrete route names “Security settings,” “Signing keys,” “Consent grants,” “Tokens,” “Authorization interactions,” “Device authorization requests,” and “Logout deliveries” over “posture,” “incident,” or generic “activity.” Distinguish a saved grant, a token record, and a delivery record from a user session or security conclusion.
- Never use “operator” as visible audience copy. Keep existing grouped navigation labels where they orient the user's job; they are navigation categories, not audience descriptions.
- State only what the stored record or loaded policy proves. Keep inherited and client-specific settings distinct and show the effective value when the existing view can calculate it. A missing optional value is “Not set” or “Not recorded” only where that accurately describes the source; a failed read is “Unavailable,” never “None.”

### Route coverage and first-view order

This is the current 30-route inventory: the 28 mounted routes plus the logout-propagation query workflow in the Phase 121 scorecards, with Phase 151's dedicated `/admin/clients/new` route added. All 30 receive a current rendered review. The root/overview and three read-only queues inherit Phase 152's title, count/filter, redaction, and read-state decisions. Client creation and task context inherit Phase 151. Phase 153 refines the remaining Configure and Support routes and may change an inherited route only to correct a rendered regression against those decisions.

| Route | Page title / task language | First decision-relevant content |
|-------|----------------------------|---------------------------------|
| `/admin` | Overview | Same page and title as `/admin/overview`; review-worthy signals first, then grouped journeys. |
| `/admin/overview` | Overview | Identical content to the mounted root; no repeated “Overview” label or provider-overview heading. |
| `/admin/clients` | Clients | Inventory filters and client records; “Create client” is the one primary route action. |
| `/admin/clients/new` | Create client | Focused registration form with concise client-application context, a safe return to the filtered inventory, validation recovery, and the existing copy-once credential result. Do not repeat the page title or explanation inside the form. |
| `/admin/clients/:client_id` | Client details | Client identity, effective settings, credentials/endpoints and lifecycle state; then task pivots. Never show a secret or unrelated queue. |
| `/admin/clients/:client_id/edit` | Edit client | Client identity and routine fields; keep endpoint, security-policy, and credential workflows separate. |
| `/admin/clients/:client_id/redirects` | Redirect URLs | Exact callback destinations and the exact-match requirement beside the field; then save. |
| `/admin/clients/:client_id/logout-uris` | After logout | Browser destinations used after sign-out; distinguish them from notification endpoints. |
| `/admin/clients/:client_id/edit?workflow=logout-propagation` | Notify the app at sign-out | Separate server and browser delivery settings; explain each channel once and keep browser return URLs distinct. |
| `/admin/clients/:client_id/par-policy` | Authorization request settings | Current client choice, provider default, and the resulting behavior before the save control. Explain PAR in context. |
| `/admin/clients/:client_id/security-profile` | Client security settings | Inherited/selected choice and its effective result; show required prerequisites and unavailable policy separately. |
| `/admin/clients/:client_id/rotate-secret` | Rotate client secret | Identify the client and exact rotation effect; then the existing explicit confirmation and copy-once result. |
| `/admin/clients/:client_id/rotate-registration-access-token` | Replace registration token | Identify which client the token manages, what happens to the old token, and the existing one-time secret handling. |
| `/admin/policies` | Provider settings | The available defaults and their current values; each link names the policy area plainly. |
| `/admin/policies/par` | Client authorization request settings | Provider default, which clients inherit it, relevant exceptions, then the save action. Expand PAR once in supporting text if shown. |
| `/admin/policies/security-profile` | Default security settings | Current default and readiness facts; explain what the check covers and what it cannot establish. |
| `/admin/policies/dpop` | Default token proof settings | Whether clients may use bearer tokens or must use key-bound tokens, which clients inherit the default, then save. Explain DPoP once. |
| `/admin/policies/dcr` | App registration settings | Whether applications may self-register and what restrictions apply; then save. Define DCR on first use only. |
| `/admin/keys` | Signing keys | Active/upcoming/retiring key states and their safe lifecycle next steps; keep key rows scannable. |
| `/admin/keys/:id` | Signing key details | Key identity, current lifecycle state, and only the transition(s) available for that state. Never expose private material. |
| `/admin/dcr` | App self-registration | The adopter's next setup task and required access token step; keep protocol metadata secondary. |
| `/admin/iats` | App setup tokens | Token state, scope/expiry facts, and the create action; no plaintext for previously created tokens. |
| `/admin/iats/new` | Create an app setup token | Scope/expiry controls, concise consequence, primary create action, then the existing one-time token handoff. |
| `/admin/consents` | Consent grants | Search/filter and exact result scope before grants; clarify active/revoked state without inferring user intent. |
| `/admin/consents/:id` | Consent grant details | Grant identity and status, authorized scope/decision facts, then the existing revoke action and its exact consequence. |
| `/admin/tokens` | Tokens | Search/filter and token lifecycle states; keep reuse meaning factual and exact. |
| `/admin/tokens/:id` | Token details | Token type, state, client and family context (redacted); separate single-token revocation from family-wide revocation. |
| `/admin/interactions` | Authorization interactions | Inherit Phase 152's neutral history title, accurate states, filters, read-only behavior, and distinct load/empty/error states. |
| `/admin/device_authorizations` | Device authorization requests | Inherit Phase 152's plain status descriptions and read-only boundary; never render user/device codes. |
| `/admin/logouts` | Logout deliveries | Inherit Phase 152's channel/outcome distinctions; never claim a delivery ended the remote user session or add queue controls. |

The `121-ROUTE-SCORECARDS.md` remains the source for each route's detailed job, error/empty/long-data case, and security pivot. This table sets its common presentation contract; it does not authorize new data, capabilities, or mutation routes.

### Forms, actions, and consequences

- Small fixed single-choice client settings also use the shared native radio group; retain exact values, inherited policy semantics, explicit saves, effective previews, keyboard behavior and field-associated help/errors.
- Inline validation tells the user how to correct a value in a complete sentence. Only a separated summary repeats the field label. Whole-second guidance provides an illustrative conversion and explains when to choose a value; never turn a stored setting into a false promise of enforced expiry. Current DCR lifetime truth is recorded in `153-LIFETIME-TRUTH.md`.
- Terminal records retain their outcome and useful context, with unavailable forms and empty action panels omitted. An embedded confirmation uses the parent's heading and spacing without another bordered card. Success/read-error notices remain truthful and visible.
- Shared client/task sections use the normal detail spacing. Scope a confirmation error to the exact known setup-token row; unknown-target and service failures remain global.
- By default, extrapolate feedback through shared components, then run a bounded autonomous source/rendered pass and desktop/mobile confirmation before optional user feedback. Preserve the checklist and evidence; cheap recurring control regressions run in existing CI. Phase-wide screen-reader/zoom acceptance remains with Phase 154.

- October 13 control-choice feedback: use radios for a few mutually exclusive settings; use checkboxes for a small fixed set of allowed values; use a single continuous token field for open-ended or large lists. Apply the shared patterns to equivalent fields instead of introducing bespoke controls. Custom callback schemes and host/scopes lists remain open-ended; exact URL lists retain newline parsing.
- Put concise, choice-specific guidance immediately beneath the choice. Do not repeat a selected value as “Current choice” or hide short essential guidance in a comparison disclosure. JWT method requirements remain inline, including private-key signature support and shared-secret restrictions.
- Preserve scalar CSV names, blank lists, exact case/order, custom values, validation, explicit Save and required scopes. The shared token field supports pasted lists, exact deduplication, keyboard suggestions/removal, labels and live announcements. Request acknowledgements use edit revisions, so LiveView previews preserve newer edits and drafts without auto-saving.
- All policy navigation links use the same LiveView navigation behavior and retain the section-nav viewport anchor, including All settings and browser history. Provide enough workspace height for short destinations; keyboard activation focuses the new current section without moving the viewport.
- October 13 evening follow-up: do not add a hidden summary that only repeats visible editable fields. Token suggestion menus reopen on input/empty-field clicks even when already focused. When all suggestions are selected, the entry clearly invites a custom value and remains usable; suggestions are not an enforced enum.
- Numeric settings use matching browser and server validation. DCR lifetime values are whole seconds from zero through the PostgreSQL integer ceiling; blank preserves existing unset/default behavior. Inline errors update while editing without moving focus; a failed explicit submit may focus its error summary. Keep help/error associations and user input intact. Do not equate unset with unlimited unless the protocol implementation proves that meaning.
- Use the Phase 151 action rule on every route: **primary** is the principal safe task (save, create, or rotate when its preconditions are satisfied); **secondary** is navigation, alternate, or read-recovery; **danger** is a consequential destructive action. Styling does not change handler behavior.
- Use a specific verb and object in each primary label, such as “Save client settings,” “Save redirect URLs,” or “Create app setup token.” Keep a single primary action in a form. A read-only page need not invent a primary button.
- Place each field label immediately before its control. Show help only when it resolves a choice; use the field's plain-language outcome, not a backend identifier. Associate errors with the field and summary, preserve entered values on rejection, and focus the error summary/invalid field using existing behavior.
- Before any existing destructive confirmation, name the affected object, the exact scope (one token versus its family, one consent grant, one client, or one key transition), and the supported effect. Keep confirmation explicit and avoid alarmist claims. Do not broaden or combine revocation scopes.
- On credential create/rotation, preserve copy-once presentation and clearing behavior. Never put plaintext in URLs, logs, browser screenshots, or copied demo notes. Do not add a second display of an already acknowledged secret.
- Interactions, device-authorization, and logout delivery history remain read-only. “Retry” means re-read only where supported; never make it look like retrying a protocol transaction or delivery.

### Layout, spacing, theme, and accessibility

Use the existing page max width and component shapes. Keep forms in the existing readable form width (600px maximum); allow inventories/details to use the wider shell when comparison benefits from it. Reflow controls and rows instead of shrinking text. On narrow screens, use one content column and stack related actions in task order.

| Token | Value | Usage |
|-------|-------|-------|
| xs | 4px | Icon/label gaps and compact inline spacing |
| sm | 8px | Related inline controls and compact groups |
| md | 16px | Default field/row gap and control padding |
| lg | 24px | Section spacing and panel padding |
| xl | 32px | Major content group separation |
| 2xl | 48px | Page-level separation only |
| 3xl | 64px | No routine use in this dense admin UI |

Exceptions: existing control dimensions, component insets, and token values outside the normative gap scale may remain when they are part of a proven component. Do not introduce off-scale layout gaps. The theme select specifically needs a clear caret inset: keep at least 16px between the chevron and the control's right border, reserve enough right padding so text cannot collide with it, and preserve the native/visible select affordance in system/light/dark modes.

| Role | Size | Weight | Line Height |
|------|------|--------|-------------|
| Body / row | 14px | 400 | 1.5 |
| Label / metadata | 12px | 600 | 1.2 |
| Section heading | 16px | 600 | 1.25 |
| Page title / key value | 24px | 600 | 1.2 |

Use only regular (400) and semibold (600) for phase content. Preserve the brandbook font roles and use tabular numerals for counts. Do not make text smaller to fit; long URLs, scopes, IDs, and error details wrap/break within their own container.

| Role | Value | Usage |
|------|-------|-------|
| Dominant surface | `--ls-surface-page` (`#f8fafc` light; existing remap in dark) | Open page canvas; semantic role rather than a pixel-ratio test |
| Supporting surface | `--ls-surface-panel` (`#ffffff` light), `--ls-surface-muted` (`#f1f5f9` light) | Focused panels/field surfaces only where grouping helps |
| Accent | `--ls-text-accent` (`#0e7490` light; `#22d3ee` dark) | Principal safe action, current navigation, and a small number of meaningful links |
| Destructive | Existing danger semantic tokens | Confirmed consequential action and its state only |

Do not force a literal 60/30/10 pixel distribution: the existing semantic surfaces and sparse, decision-bearing state color matter more than a numeric area formula. Accent is not applied to every interactive element. Use success/warning/danger tokens for truthful states with text labels. Normal text must meet WCAG AA 4.5:1 and non-text controls/focus indicators at least 3:1 against adjacent surfaces. In particular, do not place the existing muted gray `#64748b` on the muted surface `#f1f5f9` where its contrast falls below 4.5:1; use the body token or a compliant existing semantic value. Keep keyboard focus visible with the existing 2px ring and 3px offset; never remove outline without an equally visible replacement.

All changed routes must be operable by keyboard at 200% zoom and at 320px viewport width: no clipped labels/actions or page-level horizontal overflow, controls remain labeled, order remains logical, and focus does not jump on read refresh. Keep state perceivable without color, preserve `prefers-reduced-motion`, and support light, dark, and system themes. Do not add animation unless it provides real feedback/orientation.

## Copywriting Contract

| Element | Copy |
|---------|------|
| Primary CTA | Name the route's safe verb and object; on the client inventory use `Create client`. Routine client settings use `Save client settings`; route-specific saves identify what is being saved. |
| Empty state heading | `No {resource} found` for a successful empty inventory. |
| Empty state body | If filters are active, say that no records match and offer the existing clear-filter path. If no records exist, give one relevant next step, such as registering a client. Do not describe an empty filtered search as a globally empty system. |
| Error state | For reads: `Could not load {resource}. The current results are unavailable.` Offer a same-route read reload only where supported, labeled `Reload {resource}`. For submit errors, identify the field or attempted save, preserve input, and explain the available correction without claiming success. |
| Destructive confirmation | Existing action name + affected object + exact scope + supported consequence. Preserve each route's current confirmation and do not imply broader revocation, remote sign-out, or compromise. |

Use sentence case. Keep “measured from” provenance, repeated page-purpose prose, backend storage terms, and unchanging `role=status` notes out of user-facing copy. Necessary data freshness or source scope stays only when it changes how a person should interpret the value. Essential help is visible next to the choice; hover-only tooltips are not the place for instructions, consequences, or unfamiliar domain terms.

## UI Considerations

Applicable shape-rooted state considerations resolved: 8 covered, 0 backstop, 0 unresolved. Route-level rendered and sensitive-value proof is scheduled in Phase 154; this table is the implementation contract for those states.

| Category | Element(s) | Status | Resolution / Reason |
|----------|------------|--------|---------------------|
| empty | Client, policy, key, consent, token, and setup-token collections; forms | ✅ covered | A successful zero and a filter with zero matches have distinct copy and next steps; forms stay clearly unfilled rather than resembling failed reads. |
| loading | Route data, inherited defaults, inventory lists, and actions | ✅ covered | Show the existing loading state without temporary zero/default values; keep the navigation shell available. |
| error | Reads, policy inheritance, form submissions, and lifecycle transitions | ✅ covered | State which data/action is unavailable; keep errors distinct from empty/default, retain safe navigation, preserve form values, and do not show save controls when a required current policy cannot be confirmed. |
| populated | Inventory rows, client/key details, policy forms, and support records | ✅ covered | Lead with identity, actual state, and the next supported task; use the route-specific order above. |
| partial | Optional metadata, inherited settings, and independent data sources | ✅ covered | Mark only the absent/unavailable value; keep successfully loaded facts visible and avoid fabricated defaults. |
| overflow | Resource rows, navigation, forms, action groups, and tables | ✅ covered | Wrap or reflow long content; preserve semantic field labels and actions; do not clip or force page-level horizontal scrolling. |
| zero-one-many | All collection pages and route metrics | ✅ covered | Use accurate singular/plural text and spacing; a count matches its displayed/filter subset; no metrics that do not change a decision. |
| long-text | Client names/IDs, redirect/logout URLs, scopes, key IDs, and error details | ✅ covered | Preserve body size and wrap at safe boundaries; keep monospaced treatment only for exact identifiers/values. |

Open, prose-owned checks: keyboard order and visible focus, contrast, accessible form descriptions/errors, non-color status meaning, readable narrow/zoomed layouts, system/light/dark theme parity, and reduced motion. These are acceptance contracts, with Phase154 responsible for current rendered evidence and automated coverage where it has recurring regression value.

## Registry Safety

| Registry | Blocks Used | Safety Gate |
|----------|-------------|-------------|
| none | none | Not applicable. This Phoenix project uses its own components; no shadcn or third-party registry is initialized or introduced. |

No dependency is added.

## Checker Sign-Off

- [ ] Dimension 1 Copywriting: PASS
- [ ] Dimension 2 Visuals: PASS
- [ ] Dimension 3 Color: PASS
- [ ] Dimension 4 Typography: PASS
- [ ] Dimension 5 Spacing: PASS
- [x] Dimension 6 Registry Safety: PASS — no registry or dependency is used.
- [x] Dimension 7 Inventory Provenance: PASS — re-runnable command and resolved internal package version recorded.

**Approval:** pending
