# Lockspire Roadmap

## Current Milestone: v1.31 Admin Design-System Stress Test

**Goal:** Systematically strengthen the Lockspire admin/operator design system so foundations, primitives, component groups, weak pages, fixtures, and browser evidence all move forward together without regressions.

**Milestone posture:** This is an admin/operator UI and design-system quality milestone. It preserves OAuth/OIDC protocol behavior, storage schemas, host-owned operator authentication, the embedded-library shape, and the supported admin router boundary.

## Phase Plan

| Phase | Name | Requirements | Focus |
|-------|------|--------------|-------|
| 116 | 2/2 | Complete    | 2026-06-25 |
| 117 | 2/2 | Complete    | 2026-06-25 |
| 118 | 3/3 | Complete   | 2026-06-26 |
| 119 | 4/4 | Complete    | 2026-06-26 |
| 120 | 3/3 | Complete    | 2026-06-26 |

## Phase Details

### Phase 116: Inventory, Rubric & Lab Contract

**Goal:** Lock the exact component, group, page, route, and workflow inventory before implementation so the design-system stress test is systematic and repeatable.

**Requirements:** LAB-01, LAB-03

**Success criteria:**

1. The inventory derives routes from `Lockspire.Web.AdminRouter` and explicitly includes the query-driven client logout-propagation workflow.
2. The component inventory lists primitives, meta-components, production usage points, missing states, and known exceptions.
3. The visual/UX rubric names Lockspire brand principles from `brandbook/`, including architectural structure, restrained Signal Cyan, calm operator hierarchy, light/dark/system parity, and no generic security tropes.
4. The component lab contract states that the lab is maintainer/demo/test-only and does not create a new supported admin route or public API.

**Implementation notes:**

- Treat Phase 107 route vocabulary, Phase 108 component primitives, Phase 109 weak-page polish, and Phase 110 browser evidence as baseline inputs.
- Do not add PhoenixStorybook in this phase; record it as a rejected/default-deferred alternative unless later evidence forces a change.

**Plans:** 2/2 plans complete

Plans:
**Wave 1**

- [x] 116-01-PLAN.md — Source-derived route/workflow inventory and brandbook visual rubric

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 116-02-PLAN.md — Component/group inventory and maintainer-only lab contract

### Phase 117: Component Lab, Fixtures & Foundation Hardening

**Goal:** Build the lightweight stress surface and harden foundations before touching production pages.

**Requirements:** LAB-02, DS-01, DS-05, PROOF-01

**Success criteria:**

1. The stress surface renders real admin components and component groups across normal, empty, error, disabled, destructive, long-value, dense-data, light, dark, system, and reduced-motion states.
2. Demo/test fixtures cover healthy, warning, incident, disabled, self-registered, expired, revoked, reuse-detected, copy-once, empty, dense, and long-value states without storing or exposing plaintext secrets.
3. Admin CSS explicitly supports light color-scheme behavior, preserves semantic dark-mode remapping, strengthens dark surface/elevation readability, and keeps Signal Cyan restrained on light surfaces.
4. Motion uses explicit transition properties, short purposeful feedback, no broad `transition: all`, and reduced-motion-safe active states.

**Implementation notes:**

- Prefer a Lockspire-owned Phoenix component stress module or demo-only page over a packaged route.
- Add browser harness scaffolding here if adopting Playwright + axe; keep it outside Hex package files and documented as maintainer proof tooling.

**Plans:** 2/2 plans complete

Plans:
**Wave 1**

- [x] 117-01-PLAN.md — Test-support component lab fixtures, stress surface, and redaction proof
- [x] 117-02-PLAN.md — Admin CSS light/dark/system and motion foundation hardening

### Phase 118: Primitive & Meta-Component Upgrade

**Goal:** Improve shared components so page polish compounds through reusable building blocks instead of repeated local markup.

**Requirements:** DS-02, DS-03, DS-04

**Success criteria:**

1. Shared components expose backward-compatible attrs/slots for architectural panes, entity headers, workflow shells, status/action clusters, lifecycle rows, dense resource rows, and table/list alternatives.
2. Status badges intentionally classify all real Configure, Support, and Operate statuses used by current admin pages.
3. Forms use shared field, help, error, and workflow primitives wherever practical; any exception is documented and covered by tests.
4. Component stress tests cover disabled links, destructive action groups, dense filters, secondary navigation, empty tables/lists, repeated badges, and generated long values.

**Implementation notes:**

- Keep Phoenix function components as the default. Use LiveComponents only where stateful reuse is genuinely needed.
- Preserve existing component call sites while enabling better group-level composition.

**Plans:** 3/3 plans complete

Plans:
**Wave 1**

- [x] 118-01-PLAN.md — Structural primitive/meta-component upgrade for DS-02

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 118-02-PLAN.md — Domain-aware status semantics for DS-03

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 118-03-PLAN.md — Form/workflow primitive adoption proof, exception inventory, and stress/lab coverage for DS-04

### Phase 119: Weak-Page Application & IA/Copy Pass

**Goal:** Apply the strengthened design system to the highest-drift routes and verify each page/group serves its operator job.

**Requirements:** FLOW-01, FLOW-02, FLOW-03, FLOW-04, FLOW-05

**Success criteria:**

1. Client detail separates identity, posture, credentials, endpoints, DCR/RAT, support pivots, and destructive lifecycle actions into clearer panes/groups.
2. DCR policy separates gate, allowlist, lifetime, auth-method, and risk decisions without changing policy semantics.
3. IAT index/new, token detail, consent detail, device authorization, interaction, and logout queue surfaces state page job, primary decision, empty state, risk state, and next safe action.
4. Logout and operation queues remain truthful about read-only support unless existing domain APIs back an action.
5. Microcopy is concise, domain-accurate, calm, and consequence-oriented without high-anxiety or generic wording.

**Implementation notes:**

- Start from the weakest/highest-drift surfaces identified during planning: client detail, DCR policy, IATs, support details, and operation queues.
- Avoid a full route rewrite. Change shared components first, then production pages where the shared pattern materially improves scanability or safety.

**Plans:** 4/4 plans complete

Plans:
**Wave 1**

- [x] 119-01-PLAN.md — Client detail IA and pane/group structure
- [x] 119-02-PLAN.md — DCR policy one-form workflow grouping

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 119-03-PLAN.md — IAT and support detail primitive/copy alignment

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 119-04-PLAN.md — Operate queue read-only cleanup and final source/copy guardrails

### Phase 120: Browser Proof, Docs & Regression Audit

**Goal:** Prove the design-system pass is idempotent, accessible, responsive, and documented.

**Requirements:** PROOF-02, PROOF-03, PROOF-04

**Success criteria:**

1. Browser proof covers 320px, 390px, 768px, 1024px, and 1440px widths across representative routes and light, dark, system, and reduced-motion modes.
2. Automated guardrails cover brand-token drift, raw color drift, responsive overflow, focus reachability, accessible labels/descriptions, duplicate IDs, contrast token pairs, plaintext secret leakage, and generic CTA drift.
3. Operator docs explain the strengthened design-system workflow, component lab boundary, theme behavior, and verification expectations without creating new public support claims.
4. Final adversarial review checks for host-app integration weight, inaccessible custom behavior, generic template UI drift, dark/mobile regressions, screenshot-only quality, and protocol/support-surface creep.

**Implementation notes:**

- Fresh browser evidence is required after CSS/component/page changes; do not rely on Phase 110 screenshots as current proof.
- If Playwright + axe proves too heavy during implementation, fall back to Elixir-only contracts plus manual browser evidence while preserving the same acceptance matrix.

**Plans:** 3/3 plans complete

Plans:
**Wave 1**

- [x] 120-01-PLAN.md — Browser proof route matrix, maintainer evidence artifact, and route-drift fix

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 120-02-PLAN.md — Automated PROOF-03 source, rendered component, and mounted route guardrails

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 120-03-PLAN.md — Operator workflow docs, support-boundary proof, and final adversarial signoff

## Shipped Milestones

- [v1.30 Adoption Demo Docker DX & Repo Hygiene](milestones/v1.30-ROADMAP.md) — shipped 2026-06-24; phases 111-115; the repo-local adoption demo now has one public URL contract, a direct Docker app+PostgreSQL path, conflict-resistant project/port controls, optional Traefik routing, redacted startup/reprint output, wrapper-driven smoke proof, scoped stop/reset/cleanup helpers, Docker-free CI hygiene, and no broadened protocol or hosted-auth surface.
- [v1.29 Admin UI Journey & Design-System Deep Polish](milestones/v1.29-ROADMAP.md) — shipped 2026-06-04; phases 107-110; route-by-route admin journeys, shared BEM/design-token primitives, weak-spot support/operations/configuration polish, demo seed truth, docs, screenshots, contract tests, and 390px mobile no-page-overflow proof now align across the admin operator surface.
- [v1.28 Admin UI Operator Experience Polish](milestones/v1.28-ROADMAP.md) — shipped 2026-06-03; phases 103-106; admin UI operator journeys, shared BEM/design-token primitives, client/support/operations/security/DCR/key workflow polish, demo seed truth, operator docs, screenshots, and design-system contract tests now align as one coherent operator product.
- [v1.27 Phoenix Resource Server Token Acceptance](milestones/v1.27-ROADMAP.md) — shipped 2026-06-03; phases 97-102; Lockspire.Plug.VerifyToken narrowed to RFC 9068 at+jwt, default access-token issuance flipped to :jwt, sender-constraint proof delivered, adoption-demo re-wired, and generated-host scaffolding updated.
- [v1.26 Host Integration & Operator Boundary Hardening](milestones/v1.26-ROADMAP.md) — shipped 2026-05-27; phases 94-96; generated host scaffolding now shows a host-guarded admin-only mount, account/claims integration stays narrow and host-owned, first-client bootstrap guidance is clearer, and adopter docs now include a compact SaaS adoption recipe without adding protocol breadth.
- [v1.25 Support-Burden Reduction](milestones/v1.25-ROADMAP.md) — shipped 2026-05-26; phases 91-93; remote `jwks_uri` diagnostics, advanced-setup support truth, and regression proof now align across runtime, doctor, admin, and docs without broadening Lockspire's embedded-library scope.
- [v1.24 client_secret_jwt](milestones/v1.24-ROADMAP.md) — shipped 2026-05-25; phases 88-90; Lockspire now supports a narrow `client_secret_jwt` direct-client slice on the shipped Lockspire-owned endpoints with sealed verifier material, strict HS256/replay/audience posture, and truthful DCR/discovery/admin/docs support.
- [v1.23 DCR Logout Metadata](milestones/v1.23-ROADMAP.md) — shipped 2026-05-24; phases 85-87; self-service clients can now create, read, and replace Lockspire's existing logout propagation metadata through DCR and RFC 7592 without widening the current logout truth model.
- [v1.22 DPoP Nonce Support](milestones/v1.22-ROADMAP.md) — shipped 2026-05-24; phases 82-84; automatic `DPoP-Nonce` challenge and retry support now covers Lockspire-owned `/token`, Lockspire-owned protected resources, and the shipped host Phoenix protected-route pipeline.
