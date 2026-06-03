# Phase 106: Demo Seeds, Docs, Screenshots, and Contract Verification - Context

**Gathered:** 2026-06-03 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 106 closes the v1.28 admin UI polish milestone with durable evidence. It packages and verifies the Phase 103-105 admin UI work through repeatable demo data, operator journey docs, browser screenshot inventory, and regression tests that fence the shared design-system contract.

**In scope:** adoption demo seed coverage for meaningful admin states, operator admin docs, desktop/mobile screenshot refresh or inventory, and design-system contract tests.

**Out of scope:** protocol behavior changes, storage migrations, new admin routes unless needed to verify already-scoped workflows, Tailwind migration, host theming, and new product capabilities beyond the v1.28 admin journey polish.
</domain>

<decisions>
## Implementation Decisions

### Closeout Shape
- **D-01:** Treat Phase 106 as final packaging and verification for existing Phase 103-105 admin work, not as a redesign pass. The plan should close docs, seeds, screenshots, and contracts around what is already in the worktree.

### Demo Seeds
- **D-02:** Keep `examples/adoption_demo/priv/repo/seeds.exs` as the repeatable source of screenshot and click-through state.
- **D-03:** Fill only meaningful seed gaps for admin states needed by screenshots and operator walkthroughs, including long names/URIs, DCR/self-registered clients, disabled or incident clients, token/consent states, device authorization states, logout delivery states, IAT states, and key lifecycle states.

### Docs
- **D-04:** Keep `docs/operator-admin.md` focused on the operator journey model and the Lockspire-owned versus host-owned boundary.
- **D-05:** Keep `docs/operator-admin.md` subordinate to `docs/supported-surface.md`; do not turn it into a second protocol support matrix or OAuth/OIDC reference.

### Screenshots
- **D-06:** Treat `tmp/admin-ui-polish/*.png` as the current visual evidence inventory.
- **D-07:** Refresh or add desktop/mobile screenshots for uncovered admin surfaces, especially screens not already represented by overview, clients, client workspace, policies, DCR, and keys captures.
- **D-08:** Screenshots are milestone evidence, not product runtime assets; do not introduce app dependencies on screenshot files.

### Contract Tests
- **D-09:** Expand `test/lockspire/web/live/admin/design_system_contract_test.exs` as the main design-system regression fence.
- **D-10:** Contract tests should continue checking for generic button classes, raw inline styles, required admin CSS primitives, key journey links, and unnamespaced button markup across polished admin LiveViews.

### Folded Todos
No matching pending todos were found for Phase 106.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

- `.planning/REQUIREMENTS.md` - v1.28 requirements and Phase 106 acceptance criteria.
- `.planning/ROADMAP.md` - v1.28 phase sequence and Phase 106 scope.
- `.planning/STATE.md` - current milestone status and closeout next action.
- `.planning/phases/103-admin-ui-journey-contract-design-system-foundation/103-CONTEXT.md` - admin journey and design-system foundation decisions.
- `examples/adoption_demo/priv/repo/seeds.exs` - repeatable demo admin-state data.
- `docs/operator-admin.md` - operator journey and host-boundary guide.
- `docs/supported-surface.md` - canonical support-surface truth that operator docs must not duplicate.
- `lib/lockspire/web/admin_css.ex` - admin design tokens and BEM-style CSS primitives.
- `lib/lockspire/web/components/admin_components.ex` - shared admin component API.
- `lib/lockspire/web/admin_router.ex` - admin route surface for screenshot and journey coverage.
- `test/lockspire/web/live/admin/design_system_contract_test.exs` - existing design-system contract fence.
- `tmp/admin-ui-polish/` - current browser screenshot evidence inventory.
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `Lockspire.Web.Components.AdminComponents` already exposes shared primitives for status badges, cards, admin buttons, action bars, alerts, description lists, summary stats, resource lists, badge groups, confirmation panels, empty states, policy navigation, timestamps, and error lists.
- `Lockspire.Web.Admin.CSS` already centralizes tokens and `lockspire-admin-*` BEM-style classes for shell, nav, cards, buttons, alerts, resource lists, forms, tables, status badges, and responsive/focus behavior.
- `examples/adoption_demo/priv/repo/seeds.exs` already seeds a wide operator-state matrix across clients, DCR, keys, consents, tokens, interactions, device authorizations, IATs, and logout deliveries.
- `tmp/admin-ui-polish/` already contains desktop/mobile screenshots for the main v1.28 surfaces and should be treated as the starting inventory.

### Established Patterns

- Admin docs should state operator workflows and ownership boundaries in plain language while deferring support-surface truth to `docs/supported-surface.md`.
- Tests already favor static contract checks for broad UI regressions that are cheap and deterministic: class naming, inline style prevention, required CSS primitives, and admin route/link presence.
- v1.28 preserves the embedded-library boundary: Lockspire owns protocol/operator state after the request reaches its router; the host owns staff authentication, authorization, sessions, MFA, branding, and product policy.

### Integration Points

- Seed changes integrate through the adoption demo repo seed script only; avoid runtime protocol/storage behavior changes.
- Documentation changes integrate through `docs/operator-admin.md` and should stay consistent with `docs/supported-surface.md`.
- Screenshot refresh should use the mounted admin routes from `Lockspire.Web.AdminRouter`.
- Contract proof should build on the existing admin LiveView test suite and `design_system_contract_test.exs`.
</code_context>

<specifics>
## Specific Ideas

- Prefer one closeout plan that inventories current screenshot coverage, fills seed/docs/test gaps, and records browser evidence.
- Keep screenshot coverage practical: prioritize every top-level admin journey and mobile coverage for dense screens instead of exhaustive modal/state permutations.
- Preserve the current BEM/design-token direction and shared component API; Phase 106 should harden it, not replace it.
</specifics>

<deferred>
## Deferred Ideas

None - analysis stayed within Phase 106 scope.

### Reviewed Todos (not folded)

No matching pending todos were found.
</deferred>
