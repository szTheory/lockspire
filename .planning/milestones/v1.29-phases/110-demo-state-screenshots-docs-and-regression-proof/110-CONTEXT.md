# Phase 110: demo-state-screenshots-docs-and-regression-proof - Context

**Gathered:** 2026-06-04 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 110 closes the v1.29 admin UI journey and design-system polish milestone with durable proof. It expands or verifies demo state, captures desktop/mobile screenshots, updates operator docs, records browser click-through evidence, and pins regression contracts for the final admin route surface.

This phase must not redesign admin routes, add protocol behavior, broaden admin capabilities, introduce a new UI framework, migrate away from the existing BEM/design-token system, or move host-owned staff authentication, MFA, role checks, tenant policy, layouts, branding, or product authorization into Lockspire.
</domain>

<decisions>
## Implementation Decisions

### Closeout Shape

- **D-01:** Treat Phase 110 as a milestone closeout and proof phase, not as another UI polish or route redesign phase. Phase 107 route contracts, Phase 108 design-system primitives, Phase 109 weak-page polish, and the approved `110-UI-SPEC.md` are locked inputs.

### Demo State

- **D-02:** Keep `examples/adoption_demo/priv/repo/seeds.exs` as the single repeatable source of screenshot and click-through demo state.
- **D-03:** Inventory the current seed matrix first, then add only missing proof states needed by CONFIG-03 and `110-UI-SPEC.md`: healthy, warning, incident, disabled, self-registered, retryable, revoked, expired, long-value, and copy-once states.
- **D-04:** Seed values must stay deterministic, obviously artificial, and redaction-safe. Do not persist plaintext client secrets, access/refresh tokens, IAT plaintext after creation, RAT plaintext after rotation, user codes, verifier material, or credential material into docs, screenshot inventory, logs, or browser evidence.

### Screenshot And Browser Evidence

- **D-05:** Create a Phase 110 route-complete screenshot and browser evidence inventory rather than only refreshing the v1.28 top-level screenshot list.
- **D-06:** Use `Lockspire.Web.AdminRouter` plus the Phase 107 query-driven logout propagation workflow as route truth for proof coverage.
- **D-07:** Keep screenshot files under `tmp/admin-ui-polish/` as milestone evidence only. Runtime code and docs should not depend on those files.
- **D-08:** Screenshot rows must record route, viewport, journey, demo state covered, screenshot path, and browser note. Missing proof must be explicit and route-specific, not silently omitted.
- **D-09:** Browser click-through proof should start from overview, visit each route group, exercise safe read-only navigation, and record confirmation workflows without executing production-like irreversible actions.
- **D-10:** Mobile proof targets 390px width and must catch page-level horizontal overflow, overlapping text, long-value wrapping failures, clipped controls, and incoherent action stacking.

### Docs And Contract Fences

- **D-11:** Keep `docs/operator-admin.md` focused on the final Orient / Configure / Support / Operate journey model and host-owned boundary.
- **D-12:** Keep `docs/operator-admin.md` subordinate to `docs/supported-surface.md`; do not turn it into a duplicate protocol support matrix or standalone hosted-auth-service guide.
- **D-13:** Extend deterministic contract tests rather than introducing a visual-regression stack. The primary fence remains `test/lockspire/web/live/admin/design_system_contract_test.exs`, with focused admin LiveView tests where route rendering behavior matters.
- **D-14:** Regression proof should cover journey vocabulary, route inventory, reusable primitive/design-token conventions, reduced-motion contract, no inline layout styles, no generic newly touched CTA labels, docs alignment, screenshot inventory completeness, demo seed state coverage, and redaction/copy-once safety.

### Verification Bundle

- **D-15:** Phase 110 closure should run and record compile proof, docs/diff truth, admin LiveView tests, design-system contract tests, seeded browser click-through, screenshot inventory proof, and mobile no-page-overflow proof.
- **D-16:** If browser or screenshot proof cannot run in the environment, keep the inventory row and record a concrete gap reason plus the command or manual evidence needed to close it.

### Folded Todos

No matching pending todos were found for Phase 110.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

- `.planning/PROJECT.md` - embedded-library boundary, v1.29 milestone intent, and current project posture.
- `.planning/REQUIREMENTS.md` - CONFIG-03 and PROOF-01..04 Phase 110 requirements.
- `.planning/ROADMAP.md` - Phase 110 scope and closeout success criteria.
- `.planning/STATE.md` - current milestone status and Phase 110 readiness.
- `.planning/METHODOLOGY.md` - assumption-first and high-threshold escalation lenses.
- `.planning/phases/107-admin-journey-contract-ia-audit/107-CONTEXT.md` - route journey and IA audit decisions.
- `.planning/phases/107-admin-journey-contract-ia-audit/107-ROUTE-JOURNEY-CONTRACT.md` - authoritative route journey contract and audit matrix.
- `.planning/phases/107-admin-journey-contract-ia-audit/107-PATTERNS.md` - route proof and contract-test patterns.
- `.planning/phases/108-design-system-token-component-upgrade/108-CONTEXT.md` - shared primitive, token, migration, and contract-fence decisions.
- `.planning/phases/109-weak-spot-page-polish/109-CONTEXT.md` - Phase 109 weak-page polish decisions and Phase 110 proof deferrals.
- `.planning/phases/110-demo-state-screenshots-docs-and-regression-proof/110-UI-SPEC.md` - approved Phase 110 UI and proof contract.
- `.planning/phases/106-demo-seeds-docs-screenshots-and-contract-verification/106-CONTEXT.md` - v1.28 closeout precedent for seeds, docs, screenshots, and contracts.
- `.planning/phases/106-demo-seeds-docs-screenshots-and-contract-verification/106-SCREENSHOTS.md` - existing screenshot inventory format and evidence pattern.
- `examples/adoption_demo/priv/repo/seeds.exs` - repeatable adoption-demo seed state.
- `docs/operator-admin.md` - operator journey and host-boundary guide.
- `docs/supported-surface.md` - canonical support-surface truth that operator docs remain subordinate to.
- `lib/lockspire/web/admin_router.ex` - authoritative mounted admin route surface.
- `lib/lockspire/web/live/admin_layout_live.ex` - Orient / Configure / Support / Operate navigation groups.
- `lib/lockspire/web/components/admin_components.ex` - shared Phoenix admin component API.
- `lib/lockspire/web/admin_css.ex` - single embedded admin CSS/token source and responsive behavior.
- `test/lockspire/web/live/admin/design_system_contract_test.exs` - primary deterministic admin UI contract fence.
- `test/lockspire/web/live/admin/*_test.exs` - focused admin LiveView tests for route rendering and copy behavior.
- `scripts/demo/adoption_smoke.py` - existing browser-like adoption demo smoke pattern.
- `tmp/admin-ui-polish/` - existing browser screenshot evidence directory.
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `examples/adoption_demo/priv/repo/seeds.exs` already seeds a meaningful v1.28/v1.29 baseline: public, confidential, self-registered, disabled, and long-name clients; active/upcoming/retiring/retired keys; remembered/revoked consents; active/revoked/expired/reuse-detected tokens; pending/denied interactions; pending/approved/expired device authorizations; active/revoked/used IATs; and succeeded/retryable/rendered logout deliveries.
- `tmp/admin-ui-polish/` already contains broad v1.28 desktop/mobile screenshots for overview, clients, client workspace, policies, DCR policy, DCR onboarding, IATs, keys, tokens, consents, interactions, device authorizations, and logout deliveries.
- `docs/operator-admin.md` already states the four journey groups, DCR onboarding versus DCR policy, post-logout redirect URIs versus logout propagation URIs, and the host-owned operator-auth boundary.
- `test/lockspire/web/live/admin/design_system_contract_test.exs` already fences route/docs alignment, route contract coverage, journey vocabulary, design tokens, reduced motion, shared primitives, no raw inline styles, no unnamespaced button markup, Phase 109 primitive usage, redaction, and risky action copy.
- Focused admin LiveView tests already exist for overview, clients, policies, tokens, consents, interactions, device authorizations, IATs, keys, and logout deliveries.

### Established Patterns

- Screenshot evidence is planning/milestone evidence, not product runtime state.
- Deterministic ExUnit source and render assertions are the repo-native regression style for broad admin UI contract proof.
- Browser evidence should be explicit but bounded: prove route coverage, safe navigation, redaction, confirmation framing, focus/readability, and mobile overflow without adding a new frontend testing stack unless planning finds one already present and low-friction.
- Admin docs should explain operator workflows and ownership boundaries while remaining subordinate to `docs/supported-surface.md`.
- Lockspire owns protocol/operator state after requests reach the mounted admin router; the host owns staff sessions, MFA, role checks, tenant policy, layouts, branding, and product-specific authorization.

### Integration Points

- Demo state changes integrate through `examples/adoption_demo/priv/repo/seeds.exs`.
- Screenshot inventory and browser evidence should live in the Phase 110 planning directory and reference `tmp/admin-ui-polish/` paths.
- Documentation alignment integrates through `docs/operator-admin.md` and must remain consistent with `docs/supported-surface.md`.
- Route truth comes from `lib/lockspire/web/admin_router.ex` and the special Phase 107 logout propagation workflow.
- Contract proof integrates through `test/lockspire/web/live/admin/design_system_contract_test.exs` plus focused admin LiveView tests where rendered proof is more valuable than source-string proof.
</code_context>

<specifics>
## Specific Ideas

- Prefer one `110-SCREENSHOTS.md` or similarly named proof inventory with one row per approved admin route and workflow, including desktop/mobile screenshot paths, journey label, seeded state, and browser note.
- Treat v1.28 screenshots as baseline evidence to refresh, replace, or expand after Phase 109 changes; do not assume they are final v1.29 proof without route-by-route inventory.
- Include detail and workflow routes in Phase 110 proof, not only top-level navigation entries.
- Use route-derived screenshot names such as `admin-tokens-desktop.png` and `admin-tokens-mobile.png`.
- Add deterministic tests that fail when a route lacks desktop proof, mobile proof, journey label, demo state, or browser note in the Phase 110 inventory.
- Keep proof commands explicit in the final plan summary so milestone closeout can distinguish code-test success from screenshot/browser proof success.
</specifics>

<deferred>
## Deferred Ideas

- Visual regression stack or screenshot-diff infrastructure beyond Phase 110 inventory proof.
- Tailwind, shadcn, external component registry, host theming engine, or screenshot-only CSS.
- New protocol operations, storage semantics, or admin capabilities.
- Standalone admin service or Lockspire-owned staff authentication/authorization.
- Product marketing pages, developer portal UI, or host-owned branding/layout work.

### Reviewed Todos (not folded)

No matching pending todos were found.
</deferred>
