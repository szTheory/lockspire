# Roadmap: Lockspire

## Milestones

- 🚧 **v1.45 DCR Lifetime Enforcement** — Phases 162–166; requirements and roadmap approved 2026-10-20.

- ✅ [v1.44 Adopter Polish & Verified 1.6.0](milestones/v1.44-ROADMAP.md) — completed 2026-10-20; Phases 158–161; shipped in Lockspire 1.6.0.
- ✅ [v1.43 Signing Key Encryption at Rest](milestones/v1.43-ROADMAP.md) — completed 2026-10-16; Phases 155–157; closes CR-01; no OAuth/OIDC behavior change.
- ✅ [v1.42 Admin UI Clarity & Workflow Refinement](milestones/v1.42-ROADMAP.md) — completed 2026-10-15; Phases 151–154; no protocol changes or package release.
- ✅ [v1.41 Product Language & Repository Clarity](milestones/v1.41-ROADMAP.md) — completed 2026-10-11; Phases 148–150; planning and documentation, no package release.
- ✅ [v1.40 Admin Operator UI Refinement](milestones/v1.40-ROADMAP.md) — completed 2026-10-10; Phases 144–147.
- ✅ [v1.39 Verified 1.5.1 Release](milestones/v1.39-ROADMAP.md) — completed 2026-10-08; Lockspire 1.5.1 published.
- ✅ [v1.38 Repository Baseline & Reconciliation](milestones/v1.38-ROADMAP.md) — completed 2026-10-06; planning closeout, no package publication.
- ✅ [v1.37 Prime-Time Readiness Ratchet](milestones/v1.37-ROADMAP.md) — shipped 2026-08-28 as Lockspire 1.5.0.

Earlier milestone history is indexed in [MILESTONES.md](MILESTONES.md) and preserved under `.planning/milestones/`.

## Current Direction

v1.45 activates the [approved DCR scope](research/dcr-lifetimes/SCOPE.md), using the completed [Phase 153 audit](milestones/v1.42-phases/153-configure-support-page-refinement/153-LIFETIME-TRUTH.md) and [focused research](research/dcr-lifetimes/SUMMARY.md). Lockspire 1.6.1 remains the latest verified public package. This roadmap was approved on 2026-10-20. Phases 162–165 are complete; Phase 166 owns final cross-phase lifetime, security and guidance proof.

**Mandatory dependency:** Phase 162 must finish the selected semantics and compatibility contract before any Phase 163–166 implementation plan. A roadmap approval approves this sequencing and scope, not an unresolved timeout, legacy backfill or rejection policy. Every implementation phase includes focused boundary and regression tests; Phase 166 owns the final cross-phase proof. Preserve existing security defaults, host ownership and historical records. Package publication is separate.

## Phases

### v1.45 DCR Lifetime Enforcement — Approved

- [x] Phase 162: Lifetime Semantics & Upgrade Contract (completed 2026-10-20)
- [x] Phase 163: App Lifetime & Compatible Host Storage (completed 2026-10-20)
- [x] Phase 164: Client-Secret Expiry & Atomic Rotation (completed 2026-10-21)
- [x] Phase 165: Management-Token Lifecycle & Recovery (completed 2026-10-21)
- [ ] Phase 166: End-to-End Lifetime, Security & Guidance Proof

### Phase 162: Lifetime Semantics & Upgrade Contract

**Goal:** Host maintainers have one selected, standards-grounded expiry and upgrade contract before implementation planning.
**Depends on:** Approved v1.45 scope and focused research; no implementation dependency
**Requirements:** DCR-02, DCR-03, DCR-04
**Plans:** 1/1 complete; independently verified 2026-10-20 (design contract only)

**Success criteria:**

1. A decision matrix selects unset/zero/positive meanings, time precision and equality boundary, policy-change timing and renewal rules for all three lifetimes.
2. An endpoint/consumer inventory selects app-expiry effects on authorization, issuance, refresh, management and existing tokens, with safe error mappings and explicit offline-validation limits.
3. An upgrade contract selects legacy-date treatment, custom-storage changes, migration/activation order, mixed-version deployment and rollback limits.
4. Management expiry and recovery choices address the registration lockout risk; concrete acceptance examples cover the selected behavior and all previously open decisions are resolved before implementation plans.

### Phase 163: App Lifetime & Compatible Host Storage

**Goal:** New and existing Phoenix hosts can store and enforce the selected app lifetime through an explicit schema and storage upgrade path.
**Depends on:** Phase 162
**Requirements:** DCR-05, DCR-06, DCR-13, DCR-14
**Plans:** 14/14 plans complete; independently verified 2026-10-20

Plans:
**Wave 1**
- [x] 163-01-PLAN.md — Register, persist and evaluate one authoritative app

**Wave 2** *(blocked on Wave 1 completion)*
- [x] 163-02-PLAN.md — Declare adapter lifetime support and shared transaction authority

**Wave 3** *(blocked on Wave 2 completion)*
- [x] 163-03-PLAN.md — Enforce app eligibility at authentication without losing clocks

**Wave 4** *(blocked on Wave 3 completion)*
- [x] 163-04-PLAN.md — Enforce browser and PAR boundaries with lock-free rendering
- [x] 163-05-PLAN.md — Guard device and CIBA request creation and host approval
- [x] 163-06-PLAN.md — Redeem codes under current authority and issue one consistent expiry
- [x] 163-10-PLAN.md — Enforce online token consumers without changing offline verification
- [x] 163-11-PLAN.md — Apply app-state management gates and safe legacy promotion

**Wave 5** *(blocked on Wave 4 completion)*
- [x] 163-07-PLAN.md — Rotate refresh tokens under current app authority

**Wave 6** *(blocked on Wave 5 completion)*
- [x] 163-08-PLAN.md — Enforce device/CIBA poll and queued push at final issuance

**Wave 7** *(blocked on Wave 6 completion)*
- [x] 163-09-PLAN.md — Validate RFC 8693 requester, subject and actor apps independently

**Wave 8** *(blocked on Wave 7 completion)*
- [x] 163-12-PLAN.md — Prove actual PostgreSQL waits, stale identity rejection and rollback

**Wave 9** *(blocked on Wave 8 completion)*
- [x] 163-13-PLAN.md — Prove additive migrations with isolated pre-lifetime and candidate packages

**Wave 10** *(blocked on Wave 9 completion)*
- [x] 163-14-PLAN.md — Ship accurate host guidance and close app/storage proof coverage

**Success criteria:**

1. New registrations persist the selected effective lifetime; request-time app eligibility follows the Phase 162 consumer inventory, including clients without shared secrets.
2. Existing registrations upgrade under the approved legacy treatment; no guessed historical date silently activates rejection, and supported deployment/rollback procedures have executable coverage.
3. Fresh generated schema and custom storage satisfy the selected contract; missing capabilities produce the documented outcome.
4. Focused tests demonstrate app-expiry boundaries, disabled-versus-expired behavior and the selected issued-token behavior without relying on a pruning job.

### Phase 164: Client-Secret Expiry & Atomic Rotation

**Goal:** Apps can rely on shared-secret expiry metadata matching authentication and operator rotation.
**Depends on:** Phase 163
**Requirements:** DCR-07, DCR-08, DCR-09
**Plans:** 6/6 canonical plans complete; independent verification passed 26/26 (2026-10-21).

Plans:
**Wave 1**
- [x] 164-01-PLAN.md — Trace finite secret issuance through storage, metadata and Basic authentication; complete policy boundaries.

**Wave 2** *(blocked on Wave 1 completion)*
- [x] 164-02-PLAN.md — Enforce every authentication method and final code/refresh authority.
- [x] 164-03-PLAN.md — Commit current-policy secret rotation, legacy promotion and audit atomically.

**Wave 3** *(blocked on Wave 2 completion)*
- [x] 164-04-PLAN.md — Guard authenticated polling and RFC requester while preserving token and queued-work validity.

**Wave 4** *(blocked on Wave 3 completion)*
- [x] 164-05-PLAN.md — Prove actual PostgreSQL wait, replacement, competing-rotation and rollback schedules.

**Wave 5** *(blocked on Wave 4 completion)*
- [x] 164-06-PLAN.md — Prove observed-event redaction, accurate guidance and integrated validation gates.

**Success criteria:**

1. Registration responses and persisted secret expiry match the selected unset/zero/positive and non-secret behavior.
2. Basic, post and secret-JWT paths enforce the same secret deadline; JWT assertion timing and replay controls remain independently effective.
3. Rotation writes replacement secret material and expiry atomically under the selected policy; old-secret use, concurrent requests and failed-write rollback follow the contract.

### Phase 165: Management-Token Lifecycle & Recovery

**Goal:** Clients can manage registrations under the selected token lifecycle, with explicit authorized recovery and safe rotation.
**Depends on:** Phase 164
**Requirements:** DCR-10, DCR-11, DCR-12
**Plans:** 7/7 canonical plans complete (18 tasks; 7 dependency-aware waves); independently verified 37/37 must-have truths on 2026-10-21. The supplemental regression-fix summary is not an additional plan.

Plans:
**Wave 1**
- [x] 165-01-PLAN.md — Prove finite management GET, current-state operation gates and safe Bearer errors.

**Wave 2** *(blocked on Wave 1 completion)*
- [x] 165-02-PLAN.md — Issue validated finite/unlimited management credentials and truthful wire metadata.

**Wave 3** *(blocked on Wave 2 completion)*
- [x] 165-03-PLAN.md — Enforce required PUT body identity and commit atomic current-policy replacements.

**Wave 4** *(blocked on Wave 3 completion)*
- [x] 165-04-PLAN.md — Recover through the existing host path and prove adapter, legacy and rollback behavior.

**Wave 5** *(blocked on Wave 4 completion)*
- [x] 165-05-PLAN.md — Prove actual PostgreSQL waits, stale requests, competing replacements and rollback.

**Wave 6** *(blocked on Wave 5 completion)*
- [x] 165-06-PLAN.md — Observe redacted, correctly attributed events and prove confirmed one-time operator recovery.

**Wave 7** *(blocked on Waves 5–6 completion)*
- [x] 165-07-PLAN.md — Update affected guidance and complete phase validation, regression repairs and independent verification.

**Execution constraints:** Verify the production GET tracer before expansion. Reuse existing schema, adapter authority, host permission and one-time reveal boundaries. Race and observability lanes are ordered because both mutate the same dedicated PostgreSQL database/server-policy singleton. Phase 166 retains final packaged cross-phase, CI/security and complete guidance proof; publication is separate.

**Success criteria:**

1. Issuance stores the chosen management-token lifetime, including the chosen finite/unlimited behavior.
2. Read, update and delete enforce the selected credential and app state with safe errors; authorized operator recovery works without bypassing the approved permissions.
3. Rotation replaces hash and lifecycle atomically; stale pre-rotation requests and competing replacements cannot restore or retain credentials contrary to the selected contract.

### Phase 166: End-to-End Lifetime, Security & Guidance Proof

**Goal:** Adopters and maintainers can reproduce complete lifetime journeys and follow guidance that matches the verified behavior.
**Depends on:** Phase 165
**Requirements:** DCR-15, DCR-16, DCR-17, DCR-18, DCR-19
**Plans:** 12 plans

Plans:
**Wave 1**
- [ ] 166-01-PLAN.md — Packaged registration/use tracer and compact evidence map

**Wave 2** *(blocked on Wave 1 completion)*
- [ ] 166-02-PLAN.md — Candidate provenance and stale-reuse negatives
- [ ] 166-03-PLAN.md — Deterministic nonmasking lifetime interactions

**Wave 3** *(blocked on Wave 2 completion)*
- [ ] 166-04-PLAN.md — Observed PostgreSQL waits, contention and rollback proof

**Wave 4** *(blocked on Wave 3 completion)*
- [ ] 166-05-PLAN.md — Public selector decision and production issuance seam

**Wave 5** *(blocked on Wave 4 completion)*
- [ ] 166-06-PLAN.md — Selected management/replacement and shared authority

**Wave 6** *(blocked on Wave 5 completion)*
- [ ] 166-07-PLAN.md — Positive events and safe failure diagnostics

**Wave 7** *(blocked on Wave 6 completion)*
- [ ] 166-08-PLAN.md — Configured adapter and executed copyable host example

**Wave 8** *(blocked on Wave 7 completion)*
- [ ] 166-09-PLAN.md — Complete fresh and legacy HTTP lifetime journeys

**Wave 9** *(blocked on Wave 8 completion)*
- [ ] 166-10-PLAN.md — Active required CI counts and sanitized receipt retention

**Wave 10** *(blocked on Wave 9 completion)*
- [ ] 166-11-PLAN.md — Evidence-backed adopter/operator guidance

**Wave 11** *(blocked on Wave 10 completion)*
- [ ] 166-12-PLAN.md — Final scoped security, live CI and conditional umbrella closure

**Success criteria:**

1. Deterministic cross-phase tests cover before/at/after expiry, unset/zero/positive settings, changed policies, rotation and disabled/expired apps for all three lifetimes.
2. Real PostgreSQL race and rollback tests confirm the selected ordering for expiry, disablement, stale authorization and rotation.
3. A packaged clean-room journey proves registration, use, expiry and rotation; fresh install, legacy upgrade and custom-storage evidence is linked to the Phase 162 contract.
4. Required CI and scoped security review pass across changed surfaces, with preserved security defaults and redaction.
5. Configuration, storage, migration and operator guidance match executable results; changed admin copy follows PRODUCT.md vocabulary and retired-wording contracts.

### v1.45 Progress

| Phase | Plans complete | Status | Completed |
|-------|----------------|--------|-----------|
| 162. Lifetime Semantics & Upgrade Contract | 1/1 | Complete | 2026-10-20 |
| 163. App Lifetime & Compatible Host Storage | 14/14 | Complete | 2026-10-20 |
| 164. Client-Secret Expiry & Atomic Rotation | 6/6 | Complete | 2026-10-21 |
| 165. Management-Token Lifecycle & Recovery | 7/7 | Complete | 2026-10-21 |
| 166. End-to-End Lifetime, Security & Guidance Proof | 0/TBD | Not started | — |

**Coverage:** 18/18 requirements assigned exactly once; 0 unmapped. Thirteen requirements are independently complete through Phase 165; five Phase 166 proof requirements remain pending.

<details>
<summary>✅ v1.44 Adopter Polish & Verified 1.6.0 (Phases 158–161) — completed 2026-10-20</summary>

- [x] Phase 158: Mix Task Repo Start (3/3 plans).
- [x] Phase 159: Key-Encryption Key Setup DX (3/3 plans).
- [x] Phase 160: Admin Key Protection & Missing-KEK Copy (2/2 plans).
- [x] Phase 161: Docs & Verified 1.6.0 Release (9/9 plans).

**Audit:** 13/13 requirements, 6/6 integration links and 4/4 flows; no blockers. See [archived details](milestones/v1.44-ROADMAP.md).

</details>

<details>
<summary>✅ v1.43 Signing Key Encryption at Rest (Phases 155–157) — completed 2026-10-16</summary>

- [x] Phase 155: Crypto Core, Config Seam & Bandit Baseline (5/5 plans) — Bandit 1.13.1 hosts; KEK config seam; every new signing key sealed as an `LSK` envelope that all six consumers read.
- [x] Phase 156: Legacy Migration, KEK Rotation & Plaintext Refusal (3/3 plans) — locked, CAS-guarded re-encryption and KEK rotation, `--check` readiness, opt-in `legacy_plaintext: :reject`.
- [x] Phase 157: Host Surfaces, Redaction Sweep & Release Proof (6/6 plans) — fail-closed install KEK block, structural redaction sweep, upgrade-journey and CI proof, HexDocs upgrade guide.

**Audit:** [v1.43 milestone audit](milestones/v1.43-MILESTONE-AUDIT.md) — 16/16 requirements, 15/15 integration, 4/4 flows; `tech_debt`, no blockers; override closeout for stale 155/156 reports.

</details>

<details>
<summary>✅ v1.42 Admin UI Clarity & Workflow Refinement (Phases 151–154) — completed 2026-10-15</summary>

- [x] Phase 151: Focused Client Registration & Settings (2/2 plans) — its own registration route, focused app task pages, and a primary/secondary/danger action rule.
- [x] Phase 152: Overview & Queue State Clarity (5/5 plans) — overview counts open exact read-only queue subsets, with hedged reuse and sign-out evidence.
- [x] Phase 153: Configure & Support Page Refinement (7/7 plans) — plain language and clear page hierarchy across all 30 admin paths.
- [x] Phase 154: Responsive, Theme & Route Proof (7/7 plans) — contrast, focus and layout fixes with redaction-safe evidence across 7 widths and 3 themes.

**Audit:** [v1.42 milestone audit](milestones/v1.42-MILESTONE-AUDIT.md) — 9/9 requirements, no gaps; bounded UI polish and pre-existing debt accepted.

</details>

<details>
<summary>✅ v1.41 Product Language & Repository Clarity (Phases 148–150) — completed 2026-10-11</summary>

- [x] Phase 148: User-Facing Admin Language (7/7 plans) — task-centered copy that preserves OAuth/OIDC meaning and truthful outcomes.
- [x] Phase 149: Repository Ownership and Lifecycle (1/1 plan) — lifecycle map and evidence-backed preservation decisions.
- [x] Phase 150: Adopter and Maintainer Documentation (2/2 plans) — canonical adoption path and task-grouped HexDocs.

**Audit:** [v1.41 milestone audit](milestones/v1.41-MILESTONE-AUDIT.md) — no requirement or integration gaps; bounded maintenance debt accepted.

</details>

## Completed Backlog Scope

### Completed scope: Repository Readability & Docs Polish

**Goal:** Make Lockspire's repository a joy to navigate: clarify what each major directory is for, remove only verified stale clutter, and give adopters and maintainers a clear, accurate route through the README and canonical documentation.
**Requirements:** LANG-01, LANG-02, LANG-03, DOC-01, DOC-02, DOC-03, REPO-01, REPO-02 (scheduled in Phases 148–150).
**Status:** Delivered in v1.41 through Phases 148–150. Retain this entry as history; do not schedule the scope again.

**Captured direction:**

- Audit the top-level and nested directory tree by ownership and lifecycle. Review agent-managed worktree folders such as `.claude/worktrees/agent-ace643b0f744cfe0b`, scratch/output directories, and the long compatibility-fixture path before deciding whether anything should move, be renamed, ignored, or removed. Check active worktree/agent ownership and all CI/test references before changing paths.
- Reshape the README around adopter and maintainer jobs: evaluate Lockspire's fit and boundaries, install it into an existing Phoenix app, follow the supported-surface contract, and operate or maintain a deployment. Use LatticeStripe's reader-first docs ladder and JTBD route map as inspiration while keeping Lockspire's product scope and voice.
- Audit guide navigation, links, setup steps, and claims against the current code and `docs/supported-surface.md`; keep generated outputs, fixtures, brand assets, planning records, and maintained documentation clearly distinguished.
