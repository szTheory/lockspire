# Phase 107: Admin Journey Contract & IA Audit - Research

**Phase:** 107 - Admin Journey Contract & IA Audit
**Researched:** 2026-06-03
**Status:** Ready for planning

## Research Complete

Phase 107 should be planned as a contract-and-proof phase, not a page-polish implementation phase. The highest-leverage output is a repo-local route journey contract plus deterministic tests and documentation alignment that later phases can consume.

## Inputs Read

- `.planning/phases/107-admin-journey-contract-ia-audit/107-CONTEXT.md`
- `.planning/phases/107-admin-journey-contract-ia-audit/107-UI-SPEC.md`
- `.planning/REQUIREMENTS.md`
- `.planning/STATE.md`
- `.planning/research/v1.29-admin-ui-journey-design-polish.md`
- `lib/lockspire/web/admin_router.ex`
- `lib/lockspire/web/live/admin_layout_live.ex`
- `test/lockspire/web/live/admin/design_system_contract_test.exs`
- `docs/operator-admin.md`
- `tmp/admin-ui-polish/` screenshot inventory

## Route Surface

`Lockspire.Web.AdminRouter` is the authoritative source for route coverage. The planned contract must cover these mounted routes:

- `/` and `/overview`
- `/clients`
- `/clients/:client_id`
- `/clients/:client_id/edit`
- `/clients/:client_id/redirects`
- `/clients/:client_id/logout-uris`
- `/clients/:client_id/edit?workflow=logout-propagation`
- `/clients/:client_id/par-policy`
- `/clients/:client_id/security-profile`
- `/clients/:client_id/rotate-secret`
- `/clients/:client_id/rotate-registration-access-token`
- `/policies`
- `/policies/par`
- `/policies/security-profile`
- `/policies/dpop`
- `/policies/dcr`
- `/keys`
- `/keys/:id`
- `/dcr`
- `/iats`
- `/iats/new`
- `/consents`
- `/consents/:id`
- `/tokens`
- `/tokens/:id`
- `/interactions`
- `/device_authorizations`
- `/logouts`

The router only mounts LiveViews under the admin scope. The host-owned boundary remains unchanged: Lockspire owns protocol/operator state after the request reaches these LiveViews; the host owns staff authentication, MFA, role checks, tenant policy, layouts, and branding.

## Current IA Baseline

`Lockspire.Web.Live.AdminLayoutLive` already exposes the v1.29 journey model:

- Orient: Overview
- Configure: Clients, Security, Keys, DCR
- Support: Consents, Tokens
- Operate: Device Auth, Interactions, Logouts

The planner should preserve this model and avoid inventing new top-level journey names. `107-UI-SPEC.md` locks the exact top-level names as Orient, Configure, Support, and Operate.

## Existing Proof Surface

`test/lockspire/web/live/admin/design_system_contract_test.exs` is the right place to extend deterministic proof. It already checks:

- namespaced `lockspire-admin-*` button classes
- shared CSS utility class presence
- final v1.28 CSS primitives
- broad route/docs alignment
- no inline layout styles on admin LiveViews

Phase 107 proof should extend this style rather than adding a runtime UI framework. New proof should cover route journey contract completeness, exact journey vocabulary, docs alignment, route coverage from `AdminRouter`, no inline layout styles, and the DCR/logout vocabulary splits.

## Evidence Inventory

`tmp/admin-ui-polish/` contains v1.28 desktop/mobile screenshots that should be accepted as audit evidence:

- Overview: `v128-overview-desktop.png`, `v128-overview-mobile.png`
- Clients: `v128-clients-desktop.png`, `v128-clients-mobile.png`
- Client workspace: `v128-client-workspace-desktop.png`, `v128-client-workspace-mobile.png`
- Policies: `v128-policies-desktop.png`, `v128-policies-mobile.png`
- DCR policy: `v128-dcr-policy-desktop.png`, `v128-dcr-policy-mobile.png`
- DCR onboarding: `dcr-desktop.png`, `v128-dcr-mobile.png`
- IATs: `v128-iats-desktop.png`, `v128-iats-mobile.png`
- Consents: `v128-consents-desktop.png`, `v128-consents-mobile.png`
- Tokens: `v128-tokens-desktop.png`, `v128-tokens-mobile.png`
- Interactions: `v128-interactions-desktop.png`, `v128-interactions-mobile.png`
- Device authorizations: `v128-device-authorizations-desktop.png`, `v128-device-authorizations-mobile.png`
- Logout deliveries: `v128-logouts-desktop.png`, `v128-logouts-mobile.png`
- Keys: `v128-keys-desktop.png`, `v128-keys-mobile.png`

The screenshot directory is currently untracked under `tmp/`; plans should treat it as input evidence, not as source to commit unless a later proof phase explicitly captures screenshot artifacts.

## Audit Findings To Plan For

Strong or already adequate baseline surfaces:

- Overview is a reasonable Orient cockpit and should be preserved as the top-level route into tasks and urgency.
- DCR onboarding copy already connects policy, IATs, self-registered clients, and RAT rotation.
- Client workspace already separates identity, posture, credentials, endpoint, logout, DCR/RAT, and lifecycle sections.
- DCR policy and logout propagation copy already contain the most important vocabulary splits.

Likely weak or high-risk audit targets:

- Support and operations pages still lean on raw list/table density and need route-level evidence about primary decision, primary action, empty state, and pivots.
- Interactions, device authorizations, and logout deliveries have simple page titles/copy and are likely weaker for incident triage.
- Consents and tokens have filters and detail pages, but the audit should verify whether the operator job and next safe action are explicit enough.
- Client detail action grouping is dense and mobile-sensitive because redirect/logout URIs, policy overrides, credentials, DCR/RAT actions, and lifecycle actions compete for attention.
- Long IDs, URLs, timestamps, token family identifiers, and logout URIs are the main mobile no-overflow risks.

## Vocabulary Decisions

The plan must preserve these exact terms:

- Use `DCR onboarding` for partner intake, IATs, self-registered clients, and RAT support.
- Use `DCR policy` for issuer registration posture and allowed registration methods.
- Use `post-logout redirect URIs` for browser destinations after logout.
- Use `logout propagation URIs` for back-channel and front-channel RP cleanup endpoints.

`docs/operator-admin.md` already distinguishes post-logout redirects from logout propagation. The plan should require docs and contract proof to keep this wording aligned with LiveView copy and route contracts.

## Recommended Artifact Shape

Create one repo-local contract artifact for the route journey and IA audit. A markdown artifact is sufficient and keeps this phase implementation-light. The artifact should be under the phase directory or another project-local planning location and include one row per route with:

- Route
- Primary journey
- Persona
- JTBD
- Entry point
- Primary decision
- Primary action
- Empty state
- Risk state
- Follow-up route
- Evidence
- Desktop assessment: strong, adequate, or weak
- Mobile assessment: strong, adequate, or weak
- Audit notes

The artifact should explicitly map each route to one of the v1.29 requirements `JOURNEY-01` through `JOURNEY-06`.

## Planning Implications

Plan as three narrow work slices:

1. Create the route journey contract and IA audit artifact from `AdminRouter`, `107-UI-SPEC.md`, route code, docs, and screenshot evidence.
2. Align operator admin docs and any lightweight route vocabulary references so the docs use the same journey names, route jobs, and DCR/logout wording.
3. Extend deterministic contract tests to prove route coverage, contract completeness, journey vocabulary, docs alignment, and no style-framework drift.

Avoid page-level redesign tasks in Phase 107. Later phases own component/token upgrades, weak-spot page polish, demo seeds, screenshots, and final browser/mobile proof.

## Risks And Constraints

- Do not add Tailwind, shadcn, a theming engine, a standalone admin service, a developer portal, or new protocol surfaces.
- Do not broaden host-owned operator authentication or account UX.
- Do not treat every route as equally weak; the audit should preserve strong v1.28 evidence so later work stays focused.
- Keep planned tests deterministic and source-based where possible. Browser screenshot and mobile overflow proof belongs mainly to later phases unless a light audit note is enough here.
- The route contract must not drift from `Lockspire.Web.AdminRouter`; tests should catch additions/removals.

## Validation Architecture

Validation should be source-first and deterministic:

- Contract file exists and contains every route from `lib/lockspire/web/admin_router.ex`.
- Every contract row has exactly one primary journey and that value is one of `Orient`, `Configure`, `Support`, or `Operate`.
- Every route row has non-empty persona, JTBD, entry point, primary decision, primary action, empty state, risk state, follow-up route, evidence, desktop assessment, and mobile assessment fields.
- The contract includes the exact vocabulary strings `DCR onboarding`, `DCR policy`, `post-logout redirect URIs`, and `logout propagation URIs`.
- `docs/operator-admin.md` includes the same top-level journey vocabulary and the same DCR/logout split.
- `test/lockspire/web/live/admin/design_system_contract_test.exs` or a nearby contract test fails if admin routes drift from the contract.
- Existing no-inline-style and namespaced CSS checks remain in force.

Recommended verification commands:

- `mix test test/lockspire/web/live/admin/design_system_contract_test.exs`
- `mix test test/lockspire/web/live/admin`
- `mix test`

## Open Questions For Planner

- Whether the contract artifact should live only in `.planning/phases/107-admin-journey-contract-ia-audit/` or also have a docs-facing counterpart. The conservative choice is phase-local contract plus docs alignment in `docs/operator-admin.md`.
- Whether to create a dedicated test module for journey contract proof or extend `design_system_contract_test.exs`. The conservative choice is extending the existing contract test unless the assertions become too large.

## RESEARCH COMPLETE
