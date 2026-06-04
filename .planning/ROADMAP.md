# Lockspire Roadmap

## Active Milestone: v1.29 Admin UI Journey & Design-System Deep Polish

**Goal:** Take the shipped admin UI from coherent baseline to a deliberately mapped operator product where every route, component, and state supports a clear persona, job, next action, and safety boundary.

**Phases:** 4
**Requirements:** 24
**Numbering:** continues from v1.28; starts at Phase 107.

| Phase | Name | Goal | Requirements |
|-------|------|------|--------------|
| 107 | 3/3 | Complete    | 2026-06-04 |
| 108 | 3/3 | Complete   | 2026-06-04 |
| 109 | 6/6 | Complete    | 2026-06-04 |
| 110 | 5/5 | Complete    | 2026-06-04 |

## Phase Details

### Phase 107: Admin Journey Contract & IA Audit

Define personas, JTBD, route ownership, navigation intent, page acceptance rubric, and screenshot/browser audit findings. Focus on proving where the current v1.28 UI is strong, adequate, or weak before execution starts.

**Success criteria:**

- Every admin route has one primary journey and one primary operator job.
- Overview, navigation, page titles, and docs have a shared vocabulary.
- The audit identifies the least-polished support, operations, mobile, and action-grouping surfaces.
- DCR onboarding versus DCR policy and post-logout redirects versus logout propagation are explicitly disambiguated.
- The phase produces implementation-ready findings without broadening protocol scope.

**Plans:** 3/3 plans complete

Plans:
**Wave 1**

- [x] 107-01-PLAN.md — Create the route-by-route journey contract and IA audit matrix
- [x] 107-02-PLAN.md — Align the operator guide to the approved journey vocabulary and boundary wording

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 107-03-PLAN.md — Extend deterministic contract proof for route coverage, vocabulary, and style fences

### Phase 108: Design-System Token & Component Upgrade

Refine `Lockspire.Web.Admin.CSS` tokens and shared Phoenix admin components while preserving the existing BEM architecture. Add contract fences so future admin routes reuse primitives instead of accumulating one-off classes.

**Success criteria:**

- Shared components cover repeated page hero, task card, filter, metric, resource row, empty, confirmation, secret, status, and action-group patterns.
- Tokens cover spacing, control size, radius, shadow, typography, status color, focus, z-index, and motion.
- Reduced-motion behavior is defined and testable.
- Reusable components replace repeated raw page structures where the reuse is clear.
- Existing admin LiveViews continue to compile and avoid inline layout styles.

### Phase 109: Weak-Spot Page Polish

Prioritize pages that were less heavily iterated in v1.28: Tokens, Consents, Interactions, Device Authorizations, Logout Deliveries, DCR/IAT, Keys, and client-detail action grouping. Improve scanability, mobile behavior, safe actions, and next-step routing.

**Success criteria:**

- Support pages answer account/client/status/incident investigation questions clearly.
- Operations pages show waiting, retrying, failed, expired, and completed state without raw-table overload.
- Long identifiers, URLs, timestamps, and status badges remain readable on mobile.
- Support and operations pages expose useful pivot context without leaking secrets.
- Risky actions are visually distinct and confirmation-backed.

**Plans:** 6/6 plans complete

Plans:
**Wave 1**

- [x] 109-01-PLAN.md — Polish token support investigation index/detail
- [x] 109-02-PLAN.md — Polish consent support investigation index/detail
- [x] 109-03-PLAN.md — Recompose operations queues for logout, device, and interaction triage
- [x] 109-04-PLAN.md — Polish DCR onboarding and IAT inventory/minting
- [x] 109-05-PLAN.md — Polish keys and client-detail action grouping

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 109-06-PLAN.md — Add Phase 109 deterministic contract proof (completed 2026-06-04)

### Phase 110: Demo State, Screenshots, Docs, and Regression Proof

Expand demo seeds and proof artifacts so the final UI can be clicked through and visually inspected. Update operator docs and contract tests to pin the journey model and design-system conventions.

**Success criteria:**

- Demo seeds exercise healthy, warning, incident, disabled, self-registered, retryable, revoked, expired, long-value, and copy-once states.
- Desktop and mobile screenshots cover every admin route in the route surface.
- `docs/operator-admin.md` describes the final journey model and host-owned boundary.
- Compile, diff-check, admin LiveView tests, design-system contract tests, screenshot inventory, and browser evidence pass.

## Shipped Milestones

- [v1.28 Admin UI Operator Experience Polish](milestones/v1.28-ROADMAP.md) — shipped 2026-06-03; phases 103-106; admin UI operator journeys, shared BEM/design-token primitives, client/support/operations/security/DCR/key workflow polish, demo seed truth, operator docs, screenshots, and design-system contract tests now align as one coherent operator product.
- [v1.27 Phoenix Resource Server Token Acceptance](milestones/v1.27-ROADMAP.md) — shipped 2026-06-03; phases 97-102; Lockspire.Plug.VerifyToken narrowed to RFC 9068 at+jwt, default access-token issuance flipped to :jwt, sender-constraint proof delivered, adoption-demo re-wired, and generated-host scaffolding updated.
- [v1.26 Host Integration & Operator Boundary Hardening](milestones/v1.26-ROADMAP.md) — shipped 2026-05-27; phases 94-96; generated host scaffolding now shows a host-guarded admin-only mount, account/claims integration stays narrow and host-owned, first-client bootstrap guidance is clearer, and adopter docs now include a compact SaaS adoption recipe without adding protocol breadth.
- [v1.25 Support-Burden Reduction](milestones/v1.25-ROADMAP.md) — shipped 2026-05-26; phases 91-93; remote `jwks_uri` diagnostics, advanced-setup support truth, and regression proof now align across runtime, doctor, admin, and docs without broadening Lockspire's embedded-library scope.
- [v1.24 client_secret_jwt](milestones/v1.24-ROADMAP.md) — shipped 2026-05-25; phases 88-90; Lockspire now supports a narrow `client_secret_jwt` direct-client slice on the shipped Lockspire-owned endpoints with sealed verifier material, strict HS256/replay/audience posture, and truthful DCR/discovery/admin/docs support.
- [v1.23 DCR Logout Metadata](milestones/v1.23-ROADMAP.md) — shipped 2026-05-24; phases 85-87; self-service clients can now create, read, and replace Lockspire's existing logout propagation metadata through DCR and RFC 7592 without widening the current logout truth model.
- [v1.22 DPoP Nonce Support](milestones/v1.22-ROADMAP.md) — shipped 2026-05-24; phases 82-84; automatic `DPoP-Nonce` challenge and retry support now covers Lockspire-owned `/token`, Lockspire-owned protected resources, and the shipped host Phoenix protected-route pipeline.
