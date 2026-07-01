# Phase 108: Design-System Token & Component Upgrade - Context

**Gathered:** 2026-06-04 (assumptions mode with sub-agent research)
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 108 upgrades the admin design-system foundation for v1.29. It refines `Lockspire.Web.Admin.CSS` tokens, expands `Lockspire.Web.Components.AdminComponents` around repeated Phoenix function-component primitives, performs only clear behavior-neutral migrations, and adds deterministic contract fences so future admin work reuses shared primitives.

This phase does not redesign weak support/operations pages, introduce Tailwind, create a host theming engine, split Lockspire into a standalone admin service, change protocol behavior, or alter the host-owned staff authentication/layout/branding seam. Phase 109 owns weak-page IA and page-level polish; Phase 110 owns full screenshot/browser/mobile evidence.
</domain>

<decisions>
## Implementation Decisions

### Token Architecture

- **D-01:** Keep `Lockspire.Web.Admin.CSS` as the single embedded admin CSS/token source for Phase 108.
- **D-02:** Upgrade the existing `--ls-*` custom properties in place into a more semantic token set covering surface/text/border/status colors, spacing, control size, radius, shadow, typography, focus, z-index, and motion.
- **D-03:** Do not split CSS files, add Tailwind/shadcn, require host asset-pipeline work, generate a copied CSS asset, or introduce a host theme system in v1.29.
- **D-04:** Retire raw component-rule hex drift where practical by moving non-token alert/confirmation/status borders and similar values behind semantic tokens before adding stricter tests.
- **D-05:** Record CSP-compatible CSS delivery as a future concern because the admin layout currently emits inline CSS; Phase 108 should not solve that unless the implementation can do so without adding install DX friction.

### Component API

- **D-06:** Expand `Lockspire.Web.Components.AdminComponents` as the library-owned admin component API, using Phoenix function components with explicit `attr` and `slot` declarations.
- **D-07:** Keep all existing component APIs compatible; do not rename or remove current primitives during Phase 108.
- **D-08:** Add repeated structural and safety primitives, not domain workflow components. LiveViews keep page intent; components render consistent layout, state, and action structure.
- **D-09:** Ship or refine these Phase 108 primitives where implementation confirms reuse: `page_hero`, `metric_grid`/metric card helper, `task_card` or `attention_card`, `filter_bar`, improved `resource_item`/row slots, `copy_once_secret_panel`, `action_group`/safe destructive grouping, `help_text` or `result_count`, `empty_notice`, and long-value display helpers.
- **D-10:** Do not generate host-editable admin components. Host apps own operator auth, layouts, branding, tenant policy, and product authorization before the admin router; Lockspire owns this admin operator surface after it is mounted.

### Migration Strategy

- **D-11:** Use a foundation-first migration with narrow opportunistic cleanup.
- **D-12:** Replace repeated raw page structures only where reuse is obvious and behavior-neutral, such as hero blocks, metric grids, secret reveal panels, and structurally identical filter shells.
- **D-13:** Preserve strong v1.28/v1.29 baseline routes instead of re-litigating them. Overview, DCR onboarding, policy, keys, and much of client workspace are source material for primitives, not targets for broad redesign.
- **D-14:** Defer support/operations weak-page recomposition to Phase 109: interactions, device authorizations, logout deliveries, tokens, consents, IATs, and client-detail action grouping.
- **D-15:** Do not treat tables as categorically wrong in Phase 108. Provide better row/list/table primitives now; let Phase 109 decide route-specific information architecture.

### Verification And Contract Fences

- **D-16:** Extend `test/lockspire/web/live/admin/design_system_contract_test.exs` as the primary deterministic Phase 108 fence.
- **D-17:** Add fast static/source checks for required token categories, reduced-motion contract, no inline layout styles, namespaced admin classes, raw hex drift outside token declarations, and canonical component/class coverage.
- **D-18:** Add small rendered component assertions only where the output contract is structural and useful; do not turn component tests into brittle full HTML snapshots.
- **D-19:** Keep browser screenshots, full mobile no-overflow proof, visual regression, and route-wide click-through evidence in Phase 110.
- **D-20:** Do not add a Node/CSS parser/lint stack unless regex/static tests become unmaintainable.

### Motion, Mobile, And Readability

- **D-21:** Define a small CSS-only motion contract with semantic duration/easing/property tokens. Motion is allowed only for feedback, focus/hover affordance, and state continuity.
- **D-22:** Remove decorative or bouncy motion. Scale/translate should be rare, and active transforms must be neutralized under `prefers-reduced-motion`.
- **D-23:** Do not add a broad LiveView JS animation layer. Phoenix.LiveView.JS transitions remain acceptable later for targeted disclosure/confirm/flash flows if all classes obey the motion contract.
- **D-24:** Add mobile/readability primitives for Phase 109 to consume: long values with `overflow-wrap:anywhere`, timestamp/mono variants, badge/status clusters, responsive rows, queue-row-ready metadata slots, compact filter bars, metric/attention summaries, pivot links, and safe action groups.
- **D-25:** Do not rely on horizontal table scrolling as the long-term mobile answer for operator incident pages, but do not redesign those pages in Phase 108.

### Folded Todos

No matching pending todos were found for Phase 108.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

- `.planning/PROJECT.md` - embedded-library boundary, v1.29 intent, and current project posture.
- `.planning/REQUIREMENTS.md` - DESIGN-01..06 requirements and Phase 108 traceability.
- `.planning/ROADMAP.md` - Phase 108/109/110 scope split.
- `.planning/STATE.md` - current milestone status and preserved decisions.
- `.planning/METHODOLOGY.md` - assumption-first and high-threshold escalation lenses.
- `.planning/phases/103-admin-ui-journey-contract-design-system-foundation/103-CONTEXT.md` - prior admin component/CSS foundation decisions.
- `.planning/phases/106-demo-seeds-docs-screenshots-and-contract-verification/106-CONTEXT.md` - design-system proof and screenshot inventory decisions.
- `.planning/phases/107-admin-journey-contract-ia-audit/107-CONTEXT.md` - route journey contract and IA audit decisions.
- `.planning/phases/107-admin-journey-contract-ia-audit/107-ROUTE-JOURNEY-CONTRACT.md` - route-by-route operator journey and weak-spot priority set.
- `.planning/phases/107-admin-journey-contract-ia-audit/107-PATTERNS.md` - current admin route/component patterns.
- `lib/lockspire/web/admin_css.ex` - current single embedded admin CSS/token source.
- `lib/lockspire/web/components/admin_components.ex` - shared Phoenix admin component API.
- `lib/lockspire/web/live/admin_layout_live.ex` - admin shell and inline CSS delivery.
- `lib/lockspire/web/live/admin/overview_live/index.ex` - strong page hero/metric/dashboard pattern source.
- `lib/lockspire/web/live/admin/dcr_live/index.ex` - strong DCR onboarding hero/metric/task pattern source.
- `lib/lockspire/web/live/admin/clients_live/index.ex` - existing filter/resource/secret reveal patterns.
- `lib/lockspire/web/live/admin/tokens_live/index.ex` - support filter/list duplication and Phase 109 weak-page input.
- `lib/lockspire/web/live/admin/consents_live/index.ex` - support filter/list duplication and Phase 109 weak-page input.
- `lib/lockspire/web/live/admin/interactions_live/index.ex` - weak raw table operations surface.
- `lib/lockspire/web/live/admin/device_authorizations_live/index.ex` - weak queue/list operations surface.
- `lib/lockspire/web/live/admin/logout_deliveries_live/index.ex` - weak raw table operations surface.
- `test/lockspire/web/live/admin/design_system_contract_test.exs` - existing deterministic design-system fence.
- `prompts/lockspire-operator-ux-liveview.md` - LiveView idioms: thin LiveViews, function components, URL state, restrained JS.
- `prompts/lockspire-operator-admin-ia-and-workflows.md` - operator jobs, calm admin tone, incident-response expectations.
- `prompts/lockspire-phoenix-system-design.md` - Phoenix-native architecture and library boundaries.
- `prompts/lockspire-elixir-oss-library-practices.md` - OSS library DX and least-surprise practices.
- `prompts/lockspire_brand_book.md` - calm, precise, structured admin/product tone.
- `https://phoenix-live-view.hexdocs.pm/Phoenix.Component.html` - official function component attr/slot contract.
- `https://phoenix-live-view.hexdocs.pm/Phoenix.LiveView.JS.html` - official targeted JS command/transition reference.
- `https://docs.djangoproject.com/en/dev/ref/contrib/admin/#theming-support` - CSS-variable admin theming precedent and cautionary admin customization model.
- `https://guides.rubyonrails.org/v7.2/engines.html#assets` - namespaced mounted-engine asset precedent.
- `https://developer.mozilla.org/en-US/docs/Web/CSS/Reference/At-rules/@media/prefers-reduced-motion` - reduced-motion accessibility baseline.
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `Lockspire.Web.Admin.CSS` already centralizes admin CSS, BEM-ish `lockspire-admin-*` classes, spacing/color/radius/shadow/font tokens, focus states, responsive behavior, and reduced-motion handling.
- `Lockspire.Web.Components.AdminComponents` already provides function components for badges, section cards, admin buttons, action bars, alerts, description lists, summary stats, resource lists/items, badge groups, confirmation panels, empty states, policy nav, timestamps, and error lists.
- `test/lockspire/web/live/admin/design_system_contract_test.exs` already proves namespaced button classes, required CSS primitives, route/docs journey alignment, route contract coverage, and no inline layout styles.
- Overview and DCR pages already demonstrate the target operator-product feel: hero, metrics, task cards, and next-action links.

### Established Patterns

- The admin surface stays Phoenix-native and library-owned after the host-mounted admin route is reached.
- Host apps own staff authentication, MFA, role checks, tenant policy, app layouts, product branding, and product-specific authorization.
- Admin LiveViews should stay thin orchestration/presentation layers; reusable markup belongs in function components; protocol/domain behavior remains below the web layer.
- URL-driven filters are established on client, token, and consent indexes and should remain page-owned rather than being hidden in generic components.
- Existing tests favor deterministic, repo-native proof over screenshot-heavy routine unit gates.

### Integration Points

- Token work integrates through `lib/lockspire/web/admin_css.ex` and must remain scoped under the admin shell.
- Component work integrates through `lib/lockspire/web/components/admin_components.ex`.
- Low-risk migrations can touch strong source routes when markup replacement is behavior-neutral.
- Contract proof integrates through `test/lockspire/web/live/admin/design_system_contract_test.exs`.
- Phase 109 should consume the new row/filter/long-value/action/metric primitives for weak-page support and operations polish.
</code_context>

<specifics>
## Specific Ideas

- Prefer semantic token names over public raw color scales: surface, text, border, focus, control, success, warning, danger, info, muted, motion.
- Keep `admin_button`, `action_bar`, `resource_list`, `resource_item`, and `summary_stat` backward-compatible; evolve by adding wrappers or optional slots.
- `copy_once_secret_panel` should centralize client secret, IAT secret, and RAT reveal treatment so copy-once material is not rendered by ad hoc page markup.
- `long_value` or equivalent classes should support IDs, URLs, token-family identifiers, timestamps, and redacted values without layout breakage.
- Phase 108 contract tests should prove "uses/defines the primitive" and "does not drift into one-off styling"; they should not claim final visual quality.
- Record the inline CSS/CSP issue for a later delivery phase instead of letting it derail token architecture.
</specifics>

<deferred>
## Deferred Ideas

- Host-configurable theming engine or public CSS override API.
- Split CSS files or generated static admin CSS asset.
- CSP-compatible non-inline CSS delivery or nonce support, unless it falls out naturally without install DX cost.
- Broad weak-page redesign for interactions, device authorizations, logout deliveries, token/consent incident flows, IATs, and client-detail action grouping.
- Browser screenshot inventory, final mobile overflow proof, and visual regression proof across every route.
- LiveView JS transitions for disclosure/toast/modal behavior unless a later page-specific workflow needs them.

### Reviewed Todos (not folded)

No matching pending todos were found.
</deferred>
