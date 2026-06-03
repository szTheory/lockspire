# Phase 107: admin-journey-contract-ia-audit - Context

**Gathered:** 2026-06-03 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 107 defines the admin journey contract and IA audit for the v1.29 admin UI polish milestone. It maps every admin route to one primary operator journey, persona, job, decision, safe action, empty state, risk state, and follow-up route before page implementation work begins.

This phase produces implementation-ready route contracts, audit findings, vocabulary decisions, and proof expectations. It must not broaden protocol behavior, change host-owned operator authentication, introduce a new UI framework, or perform the page-level polish reserved for later v1.29 phases.
</domain>

<decisions>
## Implementation Decisions

### Contract Artifact Shape

- **D-01:** Create a repo-local route journey contract and IA audit artifact before changing admin LiveView code. The contract should use `Lockspire.Web.AdminRouter` as the authoritative route surface and include the route fields locked by `107-UI-SPEC.md`.

### Journey Vocabulary

- **D-02:** Use the four top-level journey names exactly: Orient, Configure, Support, and Operate.
- **D-03:** Assign every admin route to exactly one primary journey and one primary operator job, while allowing secondary pivots in audit notes or follow-up route fields.

### Audit Evidence

- **D-04:** Treat the v1.28 screenshot inventory in `tmp/admin-ui-polish/` plus route code, docs, and browser notes as valid audit evidence.
- **D-05:** Classify each route as strong, adequate, or weak for desktop/mobile behavior and operator clarity before recommending implementation work.

### Weak-Spot Priority

- **D-06:** Prioritize audit findings for support, operations, raw-list/table, mobile, and action-grouping surfaces first: logout deliveries, device authorizations, interactions, tokens, consents, DCR/IAT, and client-detail action grouping.
- **D-07:** Preserve already-strong v1.28 overview, DCR, policy, client workspace, and key lifecycle patterns as baseline evidence instead of re-litigating them.

### Disambiguation Rules

- **D-08:** Lock the vocabulary split between DCR onboarding and DCR policy. DCR onboarding covers partner intake, IATs, self-registered clients, and RAT support; DCR policy covers issuer registration posture and allowed registration methods.
- **D-09:** Lock the vocabulary split between post-logout redirect URIs and logout propagation URIs. Post-logout redirect URIs are browser destinations; logout propagation URIs are RP cleanup endpoints for back-channel and front-channel logout.

### Verification Shape

- **D-10:** Extend deterministic contract proof instead of adding a UI framework or runtime dependency. Proof should cover route/doc alignment, journey vocabulary, all-route contract coverage, no inline layout styles, and route contract completeness.

### Folded Todos

No matching pending todos were found for Phase 107.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

- `.planning/ROADMAP.md` — Phase 107 scope and success criteria.
- `.planning/REQUIREMENTS.md` — v1.29 JOURNEY-01..06 requirements and milestone boundaries.
- `.planning/PROJECT.md` — project boundary, embedded-library posture, and current v1.29 milestone intent.
- `.planning/STATE.md` — current milestone position and prior-state notes.
- `.planning/METHODOLOGY.md` — assumption-first recommendation mode and high-threshold escalation lenses.
- `.planning/phases/107-admin-journey-contract-ia-audit/107-UI-SPEC.md` — approved UI design contract, route journey contract fields, copy rules, and route ownership table.
- `.planning/phases/103-admin-ui-journey-contract-design-system-foundation/103-CONTEXT.md` — v1.28 admin journey and design-system foundation decisions.
- `.planning/phases/106-demo-seeds-docs-screenshots-and-contract-verification/106-CONTEXT.md` — v1.28 screenshot, docs, seeds, and design-system verification decisions.
- `lib/lockspire/web/admin_router.ex` — authoritative admin route surface.
- `lib/lockspire/web/live/admin_layout_live.ex` — current Orient / Configure / Support / Operate navigation groups.
- `lib/lockspire/web/components/admin_components.ex` — shared Phoenix admin component API.
- `lib/lockspire/web/admin_css.ex` — existing `lockspire-admin-*` BEM/design-token CSS source.
- `docs/operator-admin.md` — current operator journey docs and host-owned boundary wording.
- `test/lockspire/web/live/admin/design_system_contract_test.exs` — existing deterministic admin UI contract fence.
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `Lockspire.Web.AdminRouter` already lists the mounted admin route surface, including overview, clients, client detail/edit workflows, policies, DCR, IATs, consents, tokens, interactions, device authorizations, logouts, and keys.
- `Lockspire.Web.Live.AdminLayoutLive` already groups navigation by Orient, Configure, Support, and Operate, matching the v1.29 journey model.
- `Lockspire.Web.Components.AdminComponents` already provides reusable status badges, cards, buttons, action bars, alerts, description lists, resource lists, confirmation panels, empty states, policy navigation, timestamps, and error lists.
- `Lockspire.Web.Admin.CSS` already centralizes BEM/design-token admin classes, focus states, navigation behavior, cards, tables, badges, forms, responsive wrapping, and reduced-motion-oriented transition primitives.
- `tmp/admin-ui-polish/` already contains v1.28 desktop/mobile screenshot evidence for the main admin surfaces.

### Established Patterns

- Admin docs should explain operator workflows and ownership boundaries while remaining subordinate to `docs/supported-surface.md`.
- Admin implementation should preserve `lockspire-admin-*` classes and avoid Tailwind, shadcn, inline layout styles, one-off class naming, and unrelated protocol behavior.
- Deterministic contract tests are already used for broad admin UI regression fences: class naming, inline style prevention, required CSS primitives, route/doc alignment, and journey link presence.
- Lockspire owns protocol/operator state after requests reach the admin router; host applications own staff sessions, MFA, role checks, tenant policy, layouts, branding, and product authorization.

### Integration Points

- New contract/audit artifacts should use `lib/lockspire/web/admin_router.ex` for route enumeration and `107-UI-SPEC.md` for required contract fields.
- Documentation alignment should update or validate `docs/operator-admin.md` without duplicating `docs/supported-surface.md`.
- Contract proof should build on `test/lockspire/web/live/admin/design_system_contract_test.exs`.
- Later page polish should consume the audit classifications to focus Phase 109 on support, operations, mobile, and action grouping.
</code_context>

<specifics>
## Specific Ideas

- The route contract should include: route, primary journey, persona, JTBD, entry point, primary decision, primary action, empty state, risk state, follow-up route, and evidence.
- The audit should explicitly call out DCR onboarding versus DCR policy and post-logout redirect URIs versus logout propagation URIs.
- The audit should identify strong, adequate, and weak surfaces rather than treating every page as equally in need of redesign.
</specifics>

<deferred>
## Deferred Ideas

None — analysis stayed within the Phase 107 journey contract and IA audit scope.
</deferred>
