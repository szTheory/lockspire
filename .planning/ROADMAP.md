# Lockspire Roadmap

## Current Milestone: v1.32 Admin Page IA & Interaction Model Polish

**Goal:** Make the admin/operator UI feel deliberately composed page by page, with judgment-level IA, component-group, copy, interaction, and responsive polish that advances from v1.31 without regressions.

**Milestone posture:** This is an admin/operator UI and design-system quality milestone. It preserves OAuth/OIDC protocol behavior, storage schemas, host-owned operator authentication, the embedded-library shape, the supported admin router boundary, and the maintainer-only lab/proof boundary.

**Research anchors:** Phoenix function components with attrs/slots remain the default shared UI shape; LiveView JS remains the preferred browser-behavior escape hatch before custom hooks; WAI-ARIA APG patterns guide accessible custom interactions; GOV.UK-style user-need and top-task thinking informs page IA; Emil Kowalski-style motion guidance informs restrained, origin-aware, reduced-motion-safe micro-interactions.

## Phase Plan

| Phase | Name | Requirements | Focus |
|-------|------|--------------|-------|
| 121 | 3/3 | Complete    | 2026-06-28 |
| 122 | 3/3 | Complete    | 2026-06-28 |
| 123 | 5/5 | Complete    | 2026-06-29 |
| 124 | 6/6 | Complete    | 2026-06-30 |
| 125 | 4/6 | In Progress|  |

## Phase Details

### Phase 121: Route Scorecards & Judgment Contract

**Goal:** Lock the page-first judgment rubric and scorecard inventory before changing more UI, so every later page edit has a clear operator job and regression target.

**Requirements:** IA-01, IA-02, IA-03

**Success criteria:**

1. Every `Lockspire.Web.AdminRouter` route plus the documented logout-propagation query workflow has a scorecard with persona, JTBD, top task, primary decision, earned-place check, empty/error/long-data states, mobile/theme/focus risk, and follow-up route.
2. The judgment rubric explicitly asks whether each page, section, action, and component group is redundant, least-surprising, user-flow-oriented, visually intentional, and on-brand.
3. Source/rendered guardrails fail on missing scorecards, unsupported actions, generic CTA drift, unearned page sections, or public lab/theming/storybook creep.
4. Existing uncommitted ad hoc admin coherence work is classified as baseline candidate work without mixing unrelated Docker/adoption-demo changes into v1.32 planning truth.

**Implementation notes:**

- Extend the v1.31 route/component/lab inventories rather than replacing them.
- Keep scorecards deterministic markdown/source artifacts; do not require runtime LLM review.
- Do not run destructive `.planning/phases` cleanup while legacy tracked phase directories remain active in the worktree.

### Phase 122: Support Investigation Flow Polish

**Goal:** Make token and consent investigation pages read like calm support workflows instead of metadata inventories.

**Requirements:** SUPPORT-01, SUPPORT-02, SUPPORT-03

**Success criteria:**

1. Token index and detail pages make selected filters, token health, family lineage, reuse pressure, and smallest safe action scannable under long and dense data.
2. Consent index and detail pages make selected filters, grant status, scope context, client/account pivots, and revocation consequences scannable under long and dense data.
3. Revocation panels use consistent confirmation forms, consequence copy, disabled/already-revoked states, and accessible errors.
4. Support pages avoid plaintext token/secret exposure, generic failure copy, redundant metadata dumps, and page-level overflow at narrow widths.

**Implementation notes:**

- Prefer shared `decision_summary`, `entity_header`, `dense_resource_row`, `long_value`, `confirmation_panel`, and form primitives when they reduce page complexity.
- Keep domain behavior inside existing Admin APIs; this phase should not add token or consent capabilities.

### Phase 123: Operate Queue Flow Polish

**Goal:** Make operation queues clear under stress while truthfully preserving their read-only support boundary.

**Requirements:** OPERATE-01, OPERATE-02, OPERATE-03

**Success criteria:**

1. Interactions, device authorizations, and logout deliveries expose status pressure, channel or prompt, client, subject, age, expiry or last activity, attempts, endpoint, and support note where applicable.
2. Empty, dense, incident, expired, retryable, discarded, skipped, rendered, completed, and long-value states remain understandable without tables squashing content.
3. No retry, discard, approve, deny, logout-now, or worker-control UI appears unless backed by an existing domain API and explicitly in scope.
4. Light, dark, system, reduced-motion, keyboard focus, and mobile layouts are covered by rendered/source proof.

**Implementation notes:**

- Treat logout deliveries as the strongest existing pattern, then align interactions and device authorizations where it improves scanability.
- Preserve operation queues as support-review surfaces, not command centers.

### Phase 124: Configure Onboarding Propagation Pass

**Goal:** Propagate the strongest v1.32 page patterns into Configure flows without broadening public APIs or rebuilding the admin shell.

**Requirements:** CONFIG-01, CONFIG-02, CONFIG-03

**Success criteria:**

1. Clients, DCR onboarding, IATs, keys, and policy pages share a deliberate hierarchy for current posture, next safe action, support pivot, and risky action.
2. DCR/IAT copy-once and partner handoff flows clearly separate policy posture, intake token creation, self-registered client review, and RAT rotation.
3. Dangerous Configure actions use confirmation forms, consequence copy, and action grouping consistent with token, consent, key, and client lifecycle behavior.
4. Configure pages remain on-brand, mobile-safe, accessible, and bounded to existing LiveView/Admin API behavior.

**Implementation notes:**

- Promote only patterns proven by Support/Operate work; avoid speculative new components.
- Keep the host-owned boundary explicit: Lockspire does not own staff auth, tenant policy, host layout, or developer portal UX.

### Phase 125: Browser Proof, Docs & Adversarial Ratchet

**Goal:** Prove the page-first polish is repeatable, accessible, responsive, and bounded.

**Requirements:** PROOF-01, PROOF-02, PROOF-03

**Plans:** 4/6 plans executed

Plans:
**Wave 1**

- [x] 125-01-PLAN.md — Shared fixture and component stress proof
- [x] 125-02-PLAN.md — Global deterministic guardrail contracts

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 125-03-PLAN.md — Support and Operate route proof ratchet
- [x] 125-04-PLAN.md — Configure client, credential, key, and DCR proof
- [ ] 125-05-PLAN.md — Orient and policy route proof ratchet

**Wave 3** *(blocked on Wave 2 completion)*

- [ ] 125-06-PLAN.md — Maintainer proof artifact and operator docs closeout

**Success criteria:**

1. Redaction-safe fixtures cover ugly Support, Operate, and Configure states including empty, one item, many items, long IDs, long URLs, dense data, missing fields, incidents, disabled, expired, revoked, reuse-detected, copy-once, stale/read-only, theme modes, reduced motion, and mobile widths.
2. Automated guardrails cover scorecard drift, unsupported action drift, redaction drift, generic CTA drift, focus/label references, duplicate IDs, long-value handling, theme token usage, and no-page-overflow claims for changed pages.
3. Browser/manual evidence covers representative v1.32 routes at 320px, 390px, 768px, 1024px, and 1440px across light, dark, system, reduced motion, keyboard focus, empty, dense, and long-data states.
4. Operator docs explain the page-first improvement loop, scorecards, proof boundary, and maintainer-only lab/judge/browser evidence without creating public support claims.
5. Final adversarial review checks for aesthetic overfit, inaccessible custom behavior, generic admin-template drift, host integration weight, screenshot-only quality, and accidental support-surface expansion.

**Implementation notes:**

- Browser tooling remains maintainer proof unless separately approved and documented as non-runtime, non-Hex surface.
- AI/persona judge prompts may be documented as optional maintainer evidence, but CI and release gates stay deterministic.

## Shipped Milestones

- [v1.31 Admin Design-System Stress Test](milestones/v1.31-ROADMAP.md) — shipped 2026-06-26; phases 116-120; route/component/lab inventory, redaction-safe fixtures, shared admin primitives, weak-page IA/copy polish, source-derived browser proof, deterministic guardrails, bounded operator docs, and final adversarial signoff now strengthen the admin/operator design system without protocol, storage, host-seam, public lab, theming, or browser-tooling creep.
- [v1.30 Adoption Demo Docker DX & Repo Hygiene](milestones/v1.30-ROADMAP.md) — shipped 2026-06-24; phases 111-115; the repo-local adoption demo now has one public URL contract, a direct Docker app+PostgreSQL path, conflict-resistant project/port controls, optional Traefik routing, redacted startup/reprint output, wrapper-driven smoke proof, scoped stop/reset/cleanup helpers, Docker-free CI hygiene, and no broadened protocol or hosted-auth surface.
- [v1.29 Admin UI Journey & Design-System Deep Polish](milestones/v1.29-ROADMAP.md) — shipped 2026-06-04; phases 107-110; route-by-route admin journeys, shared BEM/design-token primitives, weak-spot support/operations/configuration polish, demo seed truth, docs, screenshots, contract tests, and 390px mobile no-page-overflow proof now align across the admin operator surface.
- [v1.28 Admin UI Operator Experience Polish](milestones/v1.28-ROADMAP.md) — shipped 2026-06-03; phases 103-106; admin UI operator journeys, shared BEM/design-token primitives, client/support/operations/security/DCR/key workflow polish, demo seed truth, operator docs, screenshots, and design-system contract tests now align as one coherent operator product.
- [v1.27 Phoenix Resource Server Token Acceptance](milestones/v1.27-ROADMAP.md) — shipped 2026-06-03; phases 97-102; `Lockspire.Plug.VerifyToken` narrowed to RFC 9068 `at+jwt`, default access-token issuance flipped to `:jwt`, sender-constraint proof delivered, adoption-demo re-wired, and generated-host scaffolding updated.
- [v1.26 Host Integration & Operator Boundary Hardening](milestones/v1.26-ROADMAP.md) — shipped 2026-05-27; phases 94-96; generated host scaffolding now shows a host-guarded admin-only mount, account/claims integration stays narrow and host-owned, first-client bootstrap guidance is clearer, and adopter docs include a compact SaaS adoption recipe without adding protocol breadth.
- [v1.25 Support-Burden Reduction](milestones/v1.25-ROADMAP.md) — shipped 2026-05-26; phases 91-93; remote `jwks_uri` diagnostics, advanced-setup support truth, and regression proof now align across runtime, doctor, admin, and docs without broadening Lockspire's embedded-library scope.
- [v1.24 client_secret_jwt](milestones/v1.24-ROADMAP.md) — shipped 2026-05-25; phases 88-90; Lockspire supports a narrow `client_secret_jwt` direct-client slice on shipped Lockspire-owned endpoints with sealed verifier material, strict HS256/replay/audience posture, and truthful DCR/discovery/admin/docs support.
- [v1.23 DCR Logout Metadata](milestones/v1.23-ROADMAP.md) — shipped 2026-05-24; phases 85-87; self-service clients can create, read, and replace Lockspire's existing logout propagation metadata through DCR and RFC 7592 without widening the logout truth model.
- [v1.22 DPoP Nonce Support](milestones/v1.22-ROADMAP.md) — shipped 2026-05-24; phases 82-84; automatic `DPoP-Nonce` challenge and retry support covers Lockspire-owned `/token`, Lockspire-owned protected resources, and the shipped host Phoenix protected-route pipeline.

## Archives

Full shipped milestone details live in `.planning/milestones/`.
