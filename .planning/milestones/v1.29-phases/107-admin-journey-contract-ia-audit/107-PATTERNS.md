# Phase 107: Admin Journey Contract & IA Audit - Patterns

**Phase:** 107 - Admin Journey Contract & IA Audit
**Created:** 2026-06-03

## Pattern Mapping Complete

This pattern map identifies the closest existing code and document analogs for the Phase 107 route contract, IA audit, docs alignment, and deterministic proof work.

## Source Artifacts To Modify Or Create

| Planned Artifact | Role | Closest Existing Analog | Pattern To Reuse |
|------------------|------|-------------------------|------------------|
| `.planning/phases/107-admin-journey-contract-ia-audit/107-ROUTE-JOURNEY-CONTRACT.md` | Phase-local route contract and IA audit matrix | `.planning/phases/106-admin.../106-CONTEXT.md`, `.planning/research/v1.29-admin-ui-journey-design-polish.md` | Markdown sections with explicit decisions, canonical references, route/audit tables, and evidence notes |
| `docs/operator-admin.md` | Operator-facing journey vocabulary and route ownership docs | Existing "Admin navigation model" and "Logout propagation workflow" sections | Plain-language operator workflow bullets that stay subordinate to `docs/supported-surface.md` |
| `test/lockspire/web/live/admin/design_system_contract_test.exs` | Deterministic contract proof | Existing route/docs alignment, no-inline-style, CSS primitive tests | Source-based ExUnit assertions over router/docs/contract files instead of browser-only checks |
| `lib/lockspire/web/admin_router.ex` | Authoritative route surface | Existing Phoenix router declarations | Read-only source of routes; do not change route surface in Phase 107 |
| `lib/lockspire/web/live/admin_layout_live.ex` | Top-level journey navigation | Existing `nav_groups` assign | Read-only source for Orient/Configure/Support/Operate labels and nav grouping |

## Existing Code Patterns

### Admin Router As Route Truth

`Lockspire.Web.AdminRouter` uses simple `live/3` declarations under a single `scope "/"`. Contract tests can read the source and assert that every mounted route appears in the route contract.

Important nuance: `/clients/:client_id/edit?workflow=logout-propagation` is not a router path. It is a query-driven workflow resolved in `ClientsLive.Show` through `resolve_form_mode(:edit, %{"workflow" => "logout-propagation"})`. The route contract still needs to include it because `107-UI-SPEC.md` names it as an operator workflow.

### Admin Layout Journey Labels

`Lockspire.Web.Live.AdminLayoutLive` already groups navigation into:

- Orient
- Configure
- Support
- Operate

The plan should not introduce new nav labels. Contract tests should assert that these exact labels appear in docs and in the journey contract.

### Docs Pattern

`docs/operator-admin.md` is concise, operator-facing, and explicitly subordinate to `docs/supported-surface.md`. Phase 107 docs work should preserve that shape:

- keep protocol support truth out of this doc
- keep host-owned staff auth/role/policy boundary explicit
- align journey vocabulary with the contract
- preserve the logout split between browser destinations and RP cleanup endpoints

### Contract Test Pattern

`test/lockspire/web/live/admin/design_system_contract_test.exs` already reads files with `File.read!/1`, uses `Path.wildcard/1`, and asserts source strings. Phase 107 should add tests in the same style:

- load `107-ROUTE-JOURNEY-CONTRACT.md`
- load `lib/lockspire/web/admin_router.ex`
- assert every route path has a contract row
- assert exact journey labels
- assert required contract fields or table headers
- assert DCR/logout vocabulary splits in both contract and docs

If assertions become too large, create a nearby test module under `test/lockspire/web/live/admin/`, but the lower-friction choice is extending the existing contract test.

## Weak-Spot Code Analog Evidence

The audit should classify these as likely weak or adequate based on current source shape:

| Surface | Source | Pattern Observation |
|---------|--------|---------------------|
| Interactions | `lib/lockspire/web/live/admin/interactions_live/index.ex` | Simple table with ID, client, status, created. Useful but raw-list oriented. |
| Device authorizations | `lib/lockspire/web/live/admin/device_authorizations_live/index.ex` | Uses `lockspire-admin-list` and short empty state. Likely mobile/action-context risk. |
| Logout deliveries | `lib/lockspire/web/live/admin/logout_deliveries_live/index.ex` | Simple table for delivery ID, client, channel, status, attempts, created. Needs audit focus on retry/discard pressure. |
| Consents | `lib/lockspire/web/live/admin/consents_live/index.ex`, `show.ex` | Has filters and revoke confirmation. Audit for support persona clarity and pivot context. |
| Tokens | `lib/lockspire/web/live/admin/tokens_live/index.ex`, `show.ex` | Has filters and family revoke distinction. Audit for incident-first clarity and mobile long identifiers. |
| Client workspace | `lib/lockspire/web/live/admin/clients_live/show.ex` | Strong but dense. Audit action grouping, mobile wrapping, logout/DCR vocabulary, and destructive action separation. |

## Strong Baseline Analog Evidence

The audit should preserve these patterns instead of asking later phases to redesign them from scratch:

| Surface | Source | Pattern To Preserve |
|---------|--------|---------------------|
| Overview | `lib/lockspire/web/live/admin/overview_live/index.ex` | Hero plus summary metrics and journey cards that route by urgency/task. |
| DCR onboarding | `lib/lockspire/web/live/admin/dcr_live/index.ex` | Partner onboarding copy linking policy, IATs, self-registered clients, and RAT support. |
| Shared components | `lib/lockspire/web/components/admin_components.ex` | Section cards, buttons, action bars, resource lists, confirmation panels, empty states, badges, timestamps. |
| Admin shell | `lib/lockspire/web/live/admin_layout_live.ex` | Stable journey navigation groups. |

## Constraints For Planner

- Do not edit admin route behavior in Phase 107 unless needed for deterministic proof.
- Do not add a UI dependency, icon set, Tailwind, shadcn, or theming engine.
- Do not introduce runtime coupling to screenshot files.
- Keep contract and tests deterministic.
- If the route contract lives under `.planning/phases/107...`, tests may read that planning file directly because Phase 107 is a planning/audit phase and the test exists to fence the milestone contract.

## Verification Hooks

Recommended assertions:

- `107-ROUTE-JOURNEY-CONTRACT.md` exists.
- Contract contains required headers: Route, Primary journey, Persona, JTBD, Entry point, Primary decision, Primary action, Empty state, Risk state, Follow-up route, Evidence, Desktop assessment, Mobile assessment.
- Contract contains `Orient`, `Configure`, `Support`, `Operate`.
- Contract contains `DCR onboarding`, `DCR policy`, `post-logout redirect URIs`, and `logout propagation URIs`.
- Contract contains every route from `AdminRouter`, plus the query workflow `/clients/:client_id/edit?workflow=logout-propagation`.
- `docs/operator-admin.md` contains the same top-level journey vocabulary and vocabulary split.

## PATTERN MAPPING COMPLETE
