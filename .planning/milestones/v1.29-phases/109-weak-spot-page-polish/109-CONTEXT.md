# Phase 109: Weak-Spot Page Polish - Context

**Gathered:** 2026-06-04 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 109 brings support, operations, configure, and onboarding weak spots up to the v1.29 journey and design-system standard. It prioritizes Tokens, Consents, Interactions, Device Authorizations, Logout Deliveries, DCR/IAT, Keys, and client-detail action grouping, with strongest attention on scanability, mobile behavior, safe actions, and next-step routing.

This phase consumes the Phase 107 journey contract, the Phase 108 component primitives, and the approved Phase 109 UI design contract. It must not restart the admin UI design, introduce a new UI framework, broaden protocol behavior, change storage semantics, expose secret material, or move host-owned operator auth/layout/branding into Lockspire.
</domain>

<decisions>
## Implementation Decisions

### Support Investigation Surfaces

- **D-01:** Treat Tokens and Consents as Support investigation pages, not generic object lists.
- **D-02:** Preserve their existing URL-driven account/client/status filters while improving the page job statement, result context, summary metrics or status strips, responsive rows, and safe review pivots.
- **D-03:** Use shared Phase 108 primitives where they fit: `page_hero`, `filter_bar`, `metric_grid` or summary strip, `resource_list`, `resource_item`, `long_value`, `empty_state` or equivalent empty notice, `confirmation_panel`, and `action_group`.
- **D-04:** Replace generic action labels on touched support surfaces with verb-plus-noun labels from the UI contract, such as `Filter tokens`, `Review token`, `Revoke token family`, `Filter consent grants`, and `Review stored grant`.
- **D-05:** Keep support pages anchored on account, client, status, token family, consent grant, timestamps, and next safe action without implying token plaintext or client secret recovery.

### Operations Queue Surfaces

- **D-06:** Recompose Logout Deliveries, Device Authorizations, and Interactions as Operate queue views rather than raw-table/plain-list first content.
- **D-07:** Lead each operations page with status bucket summaries for waiting, retrying, failed, expired, pending, approved, denied, completed, discarded, or equivalent current domain states.
- **D-08:** Render queue records as responsive resource rows that expose client, status, age or relevant timestamp, durable identifier, endpoint or subject/account context when available, and the next safe review action.
- **D-09:** Add retry/discard affordance polish only where current domain APIs already support the action; do not invent new protocol operations or storage behavior in a UI polish phase.
- **D-10:** Long identifiers, URLs, timestamps, client IDs, interaction IDs, delivery IDs, and user-code-adjacent values must use `long_value` or equivalent wrapping treatment so 390px mobile views avoid page-level horizontal scrolling.

### Configure Weak Spots

- **D-11:** Treat DCR/IAT, Keys, and client detail as targeted grouping/readability polish, not wholesale redesigns.
- **D-12:** Preserve stronger v1.28/v1.29 DCR and key lifecycle patterns while tightening DCR onboarding vocabulary, IAT inventory/minting context, key long-value readability, safe mutation entry points, and mobile wrapping.
- **D-13:** Keep the locked vocabulary split: `DCR onboarding` covers partner intake, IATs, self-registered clients, and RAT support; `DCR policy` covers issuer registration posture.
- **D-14:** Upgrade IAT minting to use the shared copy-once secret panel and route copy that makes plaintext shown-once behavior explicit without persisting or re-showing the secret.
- **D-15:** Rework client-detail actions into distinct `action_group` sections for routine configuration, credential/RAT rotation, DCR context, endpoint/logout settings, PAR/security posture, and lifecycle/destructive actions.

### Security And Redaction

- **D-16:** Do not add protocol behavior, broaden admin capabilities, or change durable OAuth/OIDC truth as part of Phase 109.
- **D-17:** Never expose client secrets, registration access tokens, initial access token plaintext after creation, refresh/access token plaintext, user codes, verifier material, or raw credentials in list rows, detail pages, confirmations, logs, docs, or screenshots.
- **D-18:** Destructive and risky confirmations must name enough non-secret durable context for the operator to avoid acting on the wrong resource: client, subject/account, token family, grant, endpoint, delivery ID, key ID, status, and consequence where available.
- **D-19:** Risky actions must remain visually distinct and confirmation-backed; routine edits, credential rotation, RAT rotation, retry/discard, revoke, retire, and lifecycle/destructive actions should not be collapsed into one undifferentiated action strip.

### Verification Boundary

- **D-20:** Extend deterministic LiveView and design-system contract proof for touched Phase 109 routes instead of adding a UI framework, visual-regression stack, or broad screenshot inventory in this phase.
- **D-21:** Add focused assertions for journey labels, page job copy, verb-plus-noun action labels, shared primitive usage, no generic newly-touched CTA labels, no inline layout styles, namespaced admin classes, redaction, and destructive confirmation copy.
- **D-22:** Add focused mobile/no-overflow proof for Phase 109 target routes where feasible, especially tokens, consents, logout deliveries, device authorizations, interactions, IATs, keys, and client-detail action groups.
- **D-23:** Leave full route-wide screenshot inventory, docs regression proof, and final demo seed coverage to Phase 110 unless a focused Phase 109 screenshot is needed to trust a page-level change.

### Folded Todos

No matching pending todos were found for Phase 109.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

- `.planning/PROJECT.md` - embedded-library boundary, v1.29 intent, and current project posture.
- `.planning/REQUIREMENTS.md` - OPS-01..05 and CONFIG-01..02 Phase 109 requirements.
- `.planning/ROADMAP.md` - Phase 109 scope and Phase 110 proof boundary.
- `.planning/STATE.md` - current milestone status and Phase 109 UI-SPEC approval state.
- `.planning/METHODOLOGY.md` - assumption-first, research-first decisive defaults, and high-threshold escalation lenses.
- `.planning/phases/103-admin-ui-journey-contract-design-system-foundation/103-CONTEXT.md` - original admin journey and design-system foundation decisions.
- `.planning/phases/107-admin-journey-contract-ia-audit/107-CONTEXT.md` - route journey contract, vocabulary, and weak-spot priority decisions.
- `.planning/phases/107-admin-journey-contract-ia-audit/107-ROUTE-JOURNEY-CONTRACT.md` - route-by-route operator journey and weak/adequate/strong audit classifications.
- `.planning/phases/107-admin-journey-contract-ia-audit/107-PATTERNS.md` - current admin route/component patterns.
- `.planning/phases/108-design-system-token-component-upgrade/108-CONTEXT.md` - Phase 108 primitive, token, migration, and verification decisions.
- `.planning/phases/109-weak-spot-page-polish/109-UI-SPEC.md` - approved Phase 109 visual, interaction, copy, mobile, redaction, and verification contract.
- `lib/lockspire/web/components/admin_components.ex` - shared Phoenix admin component API.
- `lib/lockspire/web/admin_css.ex` - single embedded admin CSS/token source and responsive behavior.
- `lib/lockspire/web/live/admin/tokens_live/index.ex` - Support token investigation index target.
- `lib/lockspire/web/live/admin/tokens_live/show.ex` - Support token detail and revocation target.
- `lib/lockspire/web/live/admin/consents_live/index.ex` - Support consent investigation index target.
- `lib/lockspire/web/live/admin/consents_live/show.ex` - Support consent detail and revocation target.
- `lib/lockspire/web/live/admin/logout_deliveries_live/index.ex` - Operate logout propagation queue target.
- `lib/lockspire/web/live/admin/device_authorizations_live/index.ex` - Operate device authorization queue target.
- `lib/lockspire/web/live/admin/interactions_live/index.ex` - Operate authorization interaction queue target.
- `lib/lockspire/web/live/admin/dcr_live/index.ex` - DCR onboarding source/target.
- `lib/lockspire/web/live/admin/iat_live/index.html.heex` - IAT inventory target.
- `lib/lockspire/web/live/admin/iat_live/new.html.heex` - IAT minting and copy-once target.
- `lib/lockspire/web/live/admin/keys_live/index.ex` - key lifecycle list target.
- `lib/lockspire/web/live/admin/keys_live/show.ex` - key detail and lifecycle action target.
- `lib/lockspire/web/live/admin/clients_live/show.ex` - client-detail action grouping target.
- `test/lockspire/web/live/admin/design_system_contract_test.exs` - existing deterministic admin UI contract fence.
- `test/lockspire/web/live/admin/tokens_live_test.exs` - focused Support token route tests.
- `test/lockspire/web/live/admin/consents_live_test.exs` - focused Support consent route tests.
- `test/lockspire/web/live/admin/logout_deliveries_live_test.exs` - focused logout delivery route tests.
- `test/lockspire/web/live/admin/device_authorizations_live_test.exs` - focused device authorization route tests.
- `test/lockspire/web/live/admin/interactions_live_test.exs` - focused interaction route tests.
- `test/lockspire/web/live/admin/iat_live_test.exs` - focused IAT route tests.
- `test/lockspire/web/live/admin/keys_live_test.exs` - focused key route tests.
- `test/lockspire/web/live/admin/clients_live/show_test.exs` - focused client-detail tests.
- `prompts/lockspire-operator-ux-liveview.md` - LiveView idioms: thin LiveViews, function components, URL state, restrained JS.
- `prompts/lockspire-operator-admin-ia-and-workflows.md` - operator jobs, calm admin tone, incident-response expectations.
- `prompts/lockspire-phoenix-system-design.md` - Phoenix-native architecture and library boundaries.
- `prompts/lockspire-elixir-oss-library-practices.md` - OSS library DX and least-surprise practices.
- `prompts/lockspire_brand_book.md` - calm, precise, structured admin/product tone.
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `Lockspire.Web.Components.AdminComponents` already provides `page_hero`, `metric_grid`, `task_card`, `filter_bar`, `resource_list`, `resource_item`, `copy_once_secret_panel`, `long_value`, `action_group`, `confirmation_panel`, `status_badge`, `description_list`, `empty_state`, `admin_button`, and `action_bar`.
- `Lockspire.Web.Admin.CSS` already includes namespaced `lockspire-admin-*` styles for filters, metrics, task cards, resource rows, long values, action groups, confirmation panels, responsive stacking, overflow wrapping, focus states, and reduced-motion behavior.
- Tokens and consents indexes already use `filter_bar` and URL-driven filters, giving Phase 109 a narrow migration path toward richer Support investigation rows and summaries.
- Token and consent detail pages already use `description_list` and `confirmation_panel` for revocation flows; Phase 109 should enrich the context and copy rather than replace durable behavior.
- DCR already uses `metric_grid` and task-like onboarding panels, making it a source pattern for configure weak-spot polish.
- IAT inventory already uses `resource_list`/`resource_item`, and client detail already uses `copy_once_secret_panel` for RAT rotation, so the IAT mint flow can align with existing copy-once treatment.

### Established Patterns

- The admin surface stays Phoenix-native, embedded, library-owned, and mounted inside a host app that owns staff authentication, authorization, layout, branding, MFA, tenant policy, and product-specific operator rules.
- Admin LiveViews should stay thin orchestration/presentation layers, with reusable structure in Phoenix function components and durable OAuth/OIDC truth below the web layer.
- Existing admin UI work uses deterministic tests and source-contract checks first; broad screenshot inventory and final docs proof are milestone proof work, not the default proof for every page-level change.
- Route vocabulary is locked to Orient, Configure, Support, and Operate, and each route has exactly one primary operator journey.
- DCR onboarding versus DCR policy and post-logout redirect URIs versus logout propagation URIs are locked vocabulary splits that must survive page copy changes.

### Integration Points

- Support polish integrates through `tokens_live` and `consents_live` index/show modules and their focused tests.
- Operations polish integrates through `logout_deliveries_live/index.ex`, `device_authorizations_live/index.ex`, `interactions_live/index.ex`, and their focused tests.
- Configure polish integrates through DCR, IAT, Keys, and `clients_live/show.ex` action grouping.
- Shared component and CSS adjustments integrate through `lib/lockspire/web/components/admin_components.ex` and `lib/lockspire/web/admin_css.ex`.
- Contract proof integrates through `test/lockspire/web/live/admin/design_system_contract_test.exs` plus focused LiveView tests for the touched routes.
</code_context>

<specifics>
## Specific Ideas

- Prefer page-level `page_hero` sections that state the journey label and operator job before dense lists or details.
- Use status bucket summaries to answer "what needs attention now?" before operations queue rows.
- Use `long_value kind={:id | :url | :timestamp | :mono}` for IDs, URLs, timestamps, token family identifiers, delivery IDs, interaction IDs, key IDs, and redacted values.
- Keep empty states concrete: what is absent, which filters can change, and which adjacent route is the safe pivot.
- Replace newly touched generic labels like `Apply`, `Mint IAT`, `Revoke`, and `Cancel` with noun-specific labels where the UI contract requires it.
- Keep icon-only actions out of Phase 109; operator actions should retain visible text labels.
- Use `action_group` on client detail to separate routine configuration from credential/RAT, endpoint/logout, security posture, and destructive lifecycle actions.
- Preserve current domain APIs unless a missing read-only field blocks the approved page contract; planning should identify those gaps explicitly rather than sneaking in protocol behavior.
</specifics>

<deferred>
## Deferred Ideas

- Full admin screenshot inventory across every route.
- Final route-wide click-through evidence and docs regression proof.
- Demo seed expansion for healthy, warning, incident, disabled, self-registered, retryable, revoked, expired, long-value, and copy-once states.
- Browser screenshot inventory and final proof artifacts for every admin route.
- Visual regression stack or third-party UI framework.
- Host theming engine, Tailwind, shadcn, external component registry, or JS animation dependency.
- New protocol operations, storage semantics, or admin capabilities beyond current Lockspire behavior.

### Reviewed Todos (not folded)

No matching pending todos were found.
</deferred>
