# Phase 118: Primitive & Meta-Component Upgrade - Context

**Gathered:** 2026-06-25 (assumptions mode with subagent research)
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 118 upgrades shared admin components so page polish compounds through reusable Phoenix function-component building blocks. It covers DS-02, DS-03, and DS-04: architectural/meta-component primitives, intentional status semantics, production form/help/error/workflow primitives, and component stress proof.

This phase does not add OAuth/OIDC protocol behavior, storage schemas, supported admin routes, public theming, PhoenixStorybook, a browser proof stack, a standalone admin service, or host-owned operator authentication/layout/branding behavior.
</domain>

<decisions>
## Implementation Decisions

### Component Architecture

- **D-01:** Extend `Lockspire.Web.Components.AdminComponents` with slot-based structural meta-components as the Phase 118 default. The target set is architectural panes, entity headers, workflow shells, status/action clusters, lifecycle rows, dense resource rows, and responsive table/list alternatives.
- **D-02:** Keep Phoenix function components with explicit `attr` and `slot` declarations as the shared admin design-system shape. LiveViews continue to own URL state, filtering, loading, mutations, and page intent.
- **D-03:** Do not introduce domain workflow components that hide OAuth/OIDC policy or mutation behavior. Reusable components should render structure, hierarchy, status, actions, rows, fields, confirmations, empty states, and long values; domain-specific behavior stays in LiveViews and admin/context modules.
- **D-04:** Do not use LiveComponents for ordinary markup reuse. A LiveComponent in this phase requires a concrete local-state plus event-handling reason that cannot stay cleanly in the parent LiveView.
- **D-05:** Keep existing component APIs backward-compatible. Add attrs/slots or new wrappers rather than renaming/removing current primitives such as `page_hero`, `filter_bar`, `resource_item`, `action_group`, `status_badge`, `form_field`, `confirmation_panel`, and `empty_state`.
- **D-06:** Tables remain acceptable for true comparison or tabular scanning, but Phase 118 should provide table/list alternatives and dense resource row primitives so Phase 119 can avoid mobile overflow and raw table drift on Support and Operate pages.

### Status Semantics

- **D-07:** Upgrade `status_badge` around explicit domain-aware status metadata. Keep the simple function-component API, but add a `:domain` or `:context` attr for ambiguous statuses and derive label, tone, non-color cue, and optional title from one pattern-matched mapping.
- **D-08:** No real Configure, Support, or Operate status currently rendered by admin pages may fall through to disabled styling. Disabled fallback remains only for truly unknown values and should be covered by a contract test.
- **D-09:** Use a small semantic tone set: `:healthy`, `:waiting`, `:warning`, `:danger`, `:disabled`, `:completed`, and `:provenance`. Avoid unbounded color meanings.
- **D-10:** Treat provenance states such as `:operator` and `:self_registered` as origin/provenance, not health. Treat waiting states such as `:pending`, `:pending_login`, `:pending_consent`, `:enqueued`, `:attempted`, and approved-but-not-consumed device states as waiting, not disabled. Treat completed states such as `:completed`, `:consumed`, `:used`, `:succeeded`, `:rendered`, and `:skipped` as completed. Reserve danger for security incidents or terminal operational failures such as `:reuse_detected` and discarded logout work. Use warning for operator-attention states such as `:retiring`, `:retryable`, and `:denied`.
- **D-11:** Status badges must carry meaning through text and/or non-color cues, not color alone. Light, dark, and system themes must use the brandbook semantic status aliases rather than one-off colors.

### Form And Workflow Primitives

- **D-12:** Make slot-based `form_field` the default chrome for routine production configuration fields and filter fields where practical. It owns label, help, required marker, error text, and accessible help/error IDs; the page still renders the actual Phoenix input/select/textarea explicitly.
- **D-13:** Preserve idiomatic LiveView form behavior: form-level `phx-change` and `phx-submit`, stable input IDs/names, existing `to_form`/changeset behavior where present, and page-owned validation/mutation semantics.
- **D-14:** Add narrow workflow primitives only where they clarify existing destructive, lifecycle, confirmation, and copy-once flows. Good candidates are confirmation checkbox/help structure, workflow form shell, and lifecycle action grouping layered on `confirmation_panel`, `copy_once_secret_panel`, `action_group`, and `admin_button`.
- **D-15:** Do not wrap every input in a high-level Lockspire input component in Phase 118. That would increase migration risk, fight existing explicit HEEx/Phoenix form patterns, and make unusual confirmation/copy-once workflows harder to read.
- **D-16:** Complex checkbox confirmations, lifecycle action forms, and copy-once secret/RAT/IAT flows may remain page-local or use workflow primitives when field wrappers reduce clarity. Every exception must be named in contract proof or focused LiveView tests.
- **D-17:** Error handling should pair error summaries with field-level errors when validation is user-correctable. Inputs with errors should connect help/error copy through `aria-describedby` and use `aria-invalid` only for validated invalid states.
- **D-18:** Secret and token material stays copy-once or redacted. Form, confirmation, test fixture, screenshot, log, and docs surfaces must never expose client secrets, registration access token plaintext, initial access token plaintext after creation, refresh/access token plaintext, authorization codes, cookies, private keys, verifier material, user codes, or unredacted sensitive values.

### Stress Proof And Verification

- **D-19:** Extend the existing test-only admin lab fixtures and ExUnit-rendered stress surface for Phase 118 proof. Do not add a public/admin route, PhoenixStorybook, Playwright, axe, or package files in this phase.
- **D-20:** Component stress proof should cover disabled links, destructive action groups, dense filters, secondary navigation, empty table/list alternatives, repeated badges, generated long values, domain-aware status semantics, and form/workflow primitives.
- **D-21:** Prefer focused rendered assertions over brittle full HTML snapshots. Assert user-visible labels, stable `lockspire-admin-*` classes, accessibility hooks, redaction boundaries, and fixture coverage rather than exact wholesale markup.
- **D-22:** Keep the lab classified as `test_only` / `internal_lab`, excluded from `Lockspire.Web.AdminRouter`, public supported-surface docs, and Hex package files.
- **D-23:** Phase 120 owns mounted/browser/viewport/theme/reduced-motion/axe/screenshot evidence after primitives and weak-page applications stabilize.

### Claude's Discretion

Planner may choose exact function names if they preserve the intent above. Prefer plain, descriptive names that match current component vocabulary over abstract design-system jargon. Good examples: `pane`, `entity_header`, `workflow_shell`, `status_cluster`, `lifecycle_row`, `dense_resource_row`, and `responsive_table`.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase Scope
- `.planning/ROADMAP.md` - Phase 118 goal, success criteria, and v1.31 boundary.
- `.planning/REQUIREMENTS.md` - DS-02, DS-03, DS-04, and Phase 118 traceability.
- `.planning/STATE.md` - v1.31 defaults and current phase state.
- `.planning/METHODOLOGY.md` - assumption-first, research-first, and one-shot recommendation lenses.

### Prior Phase Contracts
- `.planning/phases/116-inventory-rubric-lab-contract/116-CONTEXT.md` - route/component/lab/brand boundary decisions.
- `.planning/phases/116-inventory-rubric-lab-contract/116-COMPONENT-GROUP-INVENTORY.md` - canonical primitive API, production usage points, missing states, and Phase 118 candidates.
- `.planning/phases/116-inventory-rubric-lab-contract/116-VISUAL-UX-RUBRIC.md` - brand, accessibility, motion, status, and operator UX gates.
- `.planning/phases/116-inventory-rubric-lab-contract/116-LAB-CONTRACT.md` - internal lab boundary, fixture safety, and supported-surface limits.
- `.planning/phases/117-component-lab-fixtures-foundation-hardening/117-PATTERNS.md` - lab fixture/stress-surface patterns.
- `.planning/phases/117-component-lab-fixtures-foundation-hardening/117-01-SUMMARY.md` - Phase 117 lab fixture and stress-surface delivery summary.
- `.planning/phases/117-component-lab-fixtures-foundation-hardening/117-02-SUMMARY.md` - Phase 117 light/dark/system and motion foundation summary.
- `.planning/phases/108-design-system-token-component-upgrade/108-CONTEXT.md` - prior primitive/token/component decisions.
- `.planning/phases/109-weak-spot-page-polish/109-CONTEXT.md` - weak-page, redaction, destructive action, and microcopy decisions.

### Source And Tests
- `lib/lockspire/web/components/admin_components.ex` - shared Phoenix admin component API.
- `lib/lockspire/web/admin_css.ex` - embedded `lockspire-admin-*` BEM/design-token CSS.
- `test/support/lockspire/web/admin_lab/fixtures.ex` - internal redaction-safe fixture data.
- `test/support/lockspire/web/admin_lab/stress_surface.ex` - internal component stress renderer.
- `test/lockspire/web/live/admin/design_system_component_stress_test.exs` - rendered stress proof and lab boundary tests.
- `test/lockspire/web/live/admin/design_system_contract_test.exs` - deterministic admin design-system contract proof.
- `lib/lockspire/web/live/admin/clients_live/form_component.ex` - major production form pressure point.
- `lib/lockspire/web/live/admin/policies_live/dcr.ex` and `lib/lockspire/web/live/admin/policies_live/dcr.html.heex` - DCR policy form pressure point.
- `lib/lockspire/web/live/admin/tokens_live/index.ex` and `lib/lockspire/web/live/admin/consents_live/index.ex` - filter field and dense Support row pressure points.
- `lib/lockspire/web/live/admin/tokens_live/show.ex`, `lib/lockspire/web/live/admin/consents_live/show.ex`, `lib/lockspire/web/live/admin/keys_live/action_component.ex`, and `lib/lockspire/web/live/admin/clients_live/rotate_secret_component.ex` - destructive/confirmation workflow pressure points.
- `lib/lockspire/web/live/admin/device_authorizations_live/index.ex`, `lib/lockspire/web/live/admin/interactions_live/index.ex`, and `lib/lockspire/web/live/admin/logout_deliveries_live/index.ex` - Operate status and dense row pressure points.

### Prompt And Brand Research
- `prompts/lockspire-operator-ux-liveview.md` - Phoenix LiveView architecture, function component, form, URL-state, and testing guidance.
- `prompts/lockspire-operator-admin-ia-and-workflows.md` - operator jobs, IA, tone, incident response, and workflow expectations.
- `prompts/lockspire-phoenix-system-design.md` - Phoenix/Elixir architecture and process-state boundaries.
- `prompts/lockspire-elixir-oss-library-practices.md` - Elixir library DX, explicit APIs, and support boundaries.
- `prompts/lockspire-auth-domain-language-field-guide.md` - domain nouns/events/verbs and admin language.
- `prompts/Oauth server jtbd and domain.md` - OAuth/OIDC JTBD and domain model guidance.
- `prompts/lockspire-security-posture-and-threat-model.md` - redaction, secret, and operator-safety posture.
- `brandbook/README.md` - current brandbook package and token boundary.
- `brandbook/tokens/tokens.json` - canonical `--ls-*` token truth.
- `brandbook/notes/decision-log.md` - Signal Cyan, light/dark/system, typography, and package decisions.
- `brandbook/notes/accessibility-checks.md` - contrast, focus, non-color status, and motion checks.

### External Research References
- `https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html` - function components, attrs, slots, and HEEx component contract.
- `https://hexdocs.pm/phoenix_live_view/Phoenix.LiveComponent.html` - prefer function components; LiveComponents only for local state plus events.
- `https://hexdocs.pm/phoenix_live_view/form-bindings.html` - form-level `phx-change` / `phx-submit` guidance.
- `https://www.w3.org/WAI/WCAG21/Understanding/use-of-color.html` - color must not be the only carrier of meaning.
- `https://design-system.service.gov.uk/components/error-summary/` - error summary and field-error recovery pattern.
- `https://design-system.service.gov.uk/components/error-message/` - field-level validation error pattern.
- `https://cloudscape.design/components/status-indicator/` - status indicator as resource/facet state, useful as design-system precedent.
- `https://carbondesignsystem.com/patterns/status-indicator-pattern/` - status indicators with text/symbol/shape beyond color.
- `https://paste.twilio.design/components/status-badge` - compact semantic status badge precedent.
- `https://atlassian.design/components/badge/badge/usage` - constrained semantic badge appearance precedent.
- `https://github.com/phenixdigital/phoenix_storybook` - PhoenixStorybook router/content integration and future-option tradeoffs.
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `AdminComponents` already exposes Phoenix function components for status badges, heroes, cards, metrics, task cards, filter bars, buttons, form fields, error summaries, alerts, description lists, resource lists/items, copy-once panels, long values, action groups, badge groups, confirmations, empty states, policy navigation, timestamps, and error lists.
- `Admin.CSS` already provides namespaced `lockspire-admin-*` styles, semantic status aliases, light/dark/system remapping, focus, reduced-motion, long-value wrapping, responsive rows, field styles, confirmation panels, and resource-list primitives.
- Phase 117 added `Lockspire.Web.AdminLab.Fixtures` and `Lockspire.Web.AdminLab.StressSurface` under `test/support`, giving Phase 118 a safe place to prove new primitives and hostile states without a supported route.
- `design_system_contract_test.exs` already includes source-contract patterns for component primitives, route/lab boundaries, semantic tokens, field CSS, and design-system drift.

### Established Patterns

- Lockspire admin UI remains Phoenix-native, embedded, library-owned, and mounted behind host-owned operator auth.
- Function components are the default reusable UI unit; LiveComponents are not used for basic layout organization.
- Admin UI copy stays calm, exact, consequence-oriented, and domain-accurate.
- The current visual system follows `brandbook/` over older prompt brand references: Signal Cyan is restrained, light-mode text/actions use Deep Cyan, dark mode remaps semantic aliases, and status meaning cannot rely on color alone.
- Maintainer evidence and lab fixtures are not public support truth.

### Integration Points

- Component/API work integrates through `lib/lockspire/web/components/admin_components.ex`.
- Visual/status/form behavior integrates through `lib/lockspire/web/admin_css.ex`.
- Stress proof integrates through `test/support/lockspire/web/admin_lab/*` and `test/lockspire/web/live/admin/design_system_component_stress_test.exs`.
- Contract proof integrates through `test/lockspire/web/live/admin/design_system_contract_test.exs`.
- Minimal production migrations may touch representative forms/rows/status call sites only when needed to prove the new primitive is practical and backward-compatible.
</code_context>

<specifics>
## Specific Ideas

- Use one status metadata helper rather than scattering status-tone decisions across pages. The helper can be private inside `AdminComponents` unless planning finds a strong testability reason to extract it.
- Consider `status_badge status={:pending} domain={:device_authorization}` or `context={:operate}` for ambiguous atoms. Keep old `status_badge status={...}` behavior for unambiguous existing calls.
- Pair badge tone with a cue or stable label so red/green/yellow are never the only distinction.
- Favor structural component names that describe the operator information shape, not internal backend modules.
- Keep form inputs explicit in HEEx so Phoenix form names, IDs, `phx-change`, and `phx-submit` stay transparent to maintainers.
- Use error summaries for user-correctable validation errors and field-level errors for exact repair instructions.
- Stress fixtures should include long client IDs, long URLs, dense scopes, repeated badge clusters, empty lists/tables, disabled links, destructive action groups, secondary navigation, copy-once placeholders, redacted handles, and status atoms from Configure/Support/Operate.
</specifics>

<deferred>
## Deferred Ideas

- PhoenixStorybook remains a future option if the component API grows beyond current admin-only needs or the internal lab becomes too bespoke.
- Mounted browser/viewport/focus/axe/screenshot proof belongs to Phase 120 after Phase 118 primitives and Phase 119 page applications settle.
- Public theming, host-editable component registries, standalone admin services, hosted auth, React/JS Storybook shells, and mounted public lab routes remain out of scope.

### Reviewed Todos (not folded)

No matching pending todos were found.
</deferred>

---

*Phase: 118-primitive-meta-component-upgrade*
*Context gathered: 2026-06-25*
