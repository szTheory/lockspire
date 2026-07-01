# Phase 103: Admin UI Journey Contract + Design System Foundation - Context

**Gathered:** 2026-06-03  
**Status:** Ready for execution

## Phase Boundary

Phase 103 locks the operator journey model and builds the reusable admin UI primitives needed by later page-level polish. It must preserve the current admin router, embedded-library boundary, and protocol behavior. It treats the previous overview/nav/security/DCR/demo-seed polish already in the worktree as the baseline.

**In scope:** journey contract docs, reusable admin components, BEM-style CSS primitives, focus/disabled/reduced-motion behavior, form/action/data-display primitives, and contract tests proving the primitives exist and generic/raw patterns do not return in the first migrated surfaces.

**Out of scope:** protocol behavior, storage migrations, host theming engine, Tailwind migration, and major page recomposition beyond the foundation targets needed to prove the primitives.

## Decisions

- Use `Lockspire.Web.Components.AdminComponents` as the admin component API.
- Keep `Lockspire.Web.Admin.CSS` as the single CSS source for now, organized into BEM-ish component blocks and modifiers.
- Preserve existing class names where current screens/tests rely on them, but add canonical component classes for new work.
- Do not introduce JS dependencies for motion. Use CSS transitions on `transform`/`opacity`, guard with `prefers-reduced-motion`, and keep animation subtle.
- First migration targets are low-risk but high-signal: clients index row/filter styling, IAT screens, and shared action/description primitives. Client detail recomposition is Phase 104.

## Operator Journey Contract

Primary jobs:

- Platform setup proof: overview, clients, policies, keys.
- Partner/client onboarding: DCR, IATs, self-registered clients, client detail/RAT rotation.
- Security posture review: policies, exception lists, key readiness, client effective posture.
- Support incident investigation: tokens, consents, refresh reuse, client/account cross-links.
- Runtime operations triage: interactions, device auth, logout deliveries.

Navigation model:

- Orient: Overview.
- Configure: Clients, Security, Keys, DCR.
- Support: Consents, Tokens.
- Operate: Device Auth, Interactions, Logouts.

## Canonical References

- `.planning/REQUIREMENTS.md` — v1.28 requirements and traceability.
- `.planning/ROADMAP.md` — v1.28 phase sequence.
- `lib/lockspire/web/admin_css.ex` — admin design tokens and component styles.
- `lib/lockspire/web/components/admin_components.ex` — shared component API.
- `lib/lockspire/web/live/admin_layout_live.ex` — top-level shell and navigation.
- `docs/operator-admin.md` — operator ownership and journey docs.

## Verification

- `MIX_ENV=test mix compile --warnings-as-errors`
- Focused admin LiveView tests.
- Design-system contract tests.
- Browser screenshot spot check for migrated surfaces at desktop and mobile widths.
