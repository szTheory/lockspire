# Roadmap: Lockspire

## Milestones

- ◆ **v1.46 Embedded Host Integration Reliability** — approved 2026-10-22; Phases 167–170; Phase 167 complete; Phase 168 Plan 01 complete and Plan 02 ready to execute.
- ✅ [v1.45 DCR Lifetime Enforcement](milestones/v1.45-ROADMAP.md) — completed 2026-10-22; Phases 162–166, 40 plans, 18/18 requirements; package publication separate.
- ✅ [v1.44 Adopter Polish & Verified 1.6.0](milestones/v1.44-ROADMAP.md) — completed 2026-10-20; Phases 158–161; shipped in Lockspire 1.6.0.
- ✅ [v1.43 Signing Key Encryption at Rest](milestones/v1.43-ROADMAP.md) — completed 2026-10-16; Phases 155–157; closes CR-01; no OAuth/OIDC behavior change.
- ✅ [v1.42 Admin UI Clarity & Workflow Refinement](milestones/v1.42-ROADMAP.md) — completed 2026-10-15; Phases 151–154; no protocol changes or package release.
- ✅ [v1.41 Product Language & Repository Clarity](milestones/v1.41-ROADMAP.md) — completed 2026-10-11; Phases 148–150; planning and documentation, no package release.
- ✅ [v1.40 Admin Operator UI Refinement](milestones/v1.40-ROADMAP.md) — completed 2026-10-10; Phases 144–147.
- ✅ [v1.39 Verified 1.5.1 Release](milestones/v1.39-ROADMAP.md) — completed 2026-10-08; Lockspire 1.5.1 published.
- ✅ [v1.38 Repository Baseline & Reconciliation](milestones/v1.38-ROADMAP.md) — completed 2026-10-06; planning closeout, no package publication.
- ✅ [v1.37 Prime-Time Readiness Ratchet](milestones/v1.37-ROADMAP.md) — shipped 2026-08-28 as Lockspire 1.5.0.

Earlier milestone history is indexed in [MILESTONES.md](MILESTONES.md) and preserved under `.planning/milestones/`.

## Current Milestone: v1.46 Embedded Host Integration Reliability

**Goal:** A Phoenix host can install, mount and securely use Lockspire's admin LiveViews through one supported integration, with reliable connections and navigation and executable proof.

**Approval:** The user approved all 15 requirements and this four-phase roadmap on 2026-10-22. Phase 167 is complete after automated verification and delegated evidence review; zero human UAT checks remain. Phase 168 Plan 01 is complete after focused automated entry checks; Plans 02 and 03 remain.

**Scope:** Mechanical host integration and automated verification. Keep accounts, staff identity, login UX, layouts, branding and product policy host-owned. Preserve public protocol behavior and security defaults. No visual redesign or subjective UI signoff.

**Research:** [v1.46 summary](research/v1.46-host-integration/SUMMARY.md). Phase 167 freshly reproduced the forward-only failure and verified native host routing. Research itself makes no new runtime or exploit claim; runtime evidence is recorded in the phase verification and UAT ledger.

## Phases

- [x] **Phase 167: Host-Expanded Admin Routing** — Hosts mount the complete existing admin surface without copying route declarations. (completed 2026-10-22)
- [ ] **Phase 168: Host-Owned LiveView Authorization** — Host staff checks protect HTTP, connected entry, reconnect and admin navigation boundaries.
- [ ] **Phase 169: Install and Upgrade Convergence** — Generated hosts, safe upgrades, diagnostics, docs and the demo use the same supported integration.
- [ ] **Phase 170: Packaged Host and Compatibility Proof** — Candidate-package and exact-version runtime checks establish the complete integration in required CI.

## Phase Details

### Phase 167: Host-Expanded Admin Routing

**Goal**: A Phoenix host can use one reusable route integration to open and navigate every existing admin task at its supported configured mount, while public and consent routes remain independent.
**Depends on**: Nothing within v1.46; builds on the completed v1.45 source baseline.
**Requirements**: MNT-01, MNT-02, MNT-03, MNT-04
**Success Criteria** (what must be TRUE):
  1. A host declares the admin integration once in its own router and receives the complete existing path/LiveView/action inventory, including detail, new/edit and policy/rotation task URLs, without a duplicated route list. (MNT-01, MNT-03)
  2. Authorized staff can connect, navigate and reconnect at the default and nested custom mount, and at root if already supported; links, query/task URLs and redirects retain the configured prefix. (MNT-02)
  3. Admin routes resolve before the public forward, and public OAuth/OIDC and host-owned consent routes retain their intended access and behavior. (MNT-04)
  4. The recorded forward-only join failure has a fresh regression reproduction, and the same host-path case succeeds through the new route integration using native Phoenix routing. (MNT-01, MNT-02)

**Plans**: 3/3 plans complete

Plans:
**Wave 1**
- [x] 167-01-PLAN.md — Reproduce the forwarded join failure, verify the native host-route tracer and settle compile/session/config contracts.

**Wave 2** *(blocked on Wave 1 completion)*
- [x] 167-02-PLAN.md — Connect every existing admin action at default, nested and root mounts with prefixed navigation and fresh rejoins.

**Wave 3** *(blocked on Wave 2 completion)*
- [x] 167-03-PLAN.md — Fence exact ordered route/action parity and prove independent public/host-consent routing.

**UI hint**: yes
**UI scope**: Routing and connected lifecycle only; preserve the existing visual contract and vocabulary. No visual design deliverable or manual UI signoff.
**Planning constraints**: Settle public API signature, route inventory ownership, session naming, host hook composition, path normalization, root-layout/session options and old AdminRouter compatibility with executable evidence. Required authorization wiring must be explicit and fail closed from the start; Phase 168 owns its complete behavioral denial proof. Do not patch private Phoenix join internals. Add focused route and connected-mount tests during this phase.

### Phase 168: Host-Owned LiveView Authorization

**Goal**: A host can apply its current staff policy to the admin surface on HTTP and LiveView entry without handing identity or permission ownership to Lockspire.
**Depends on**: Phase 167
**Requirements**: HAUTH-01, HAUTH-02, HAUTH-03, HAUTH-04
**Success Criteria** (what must be TRUE):
  1. Unauthenticated and unauthorized HTTP visitors receive the host's denial before admin data is rendered or a protected action runs; authorized staff reach the requested page. (HAUTH-01)
  2. The required host hook runs before disconnected and connected admin mounts, resolves current host authority and denies invalid identities; absent required wiring is refused instead of allowing access. (HAUTH-02)
  3. Navigation from public/consent sessions into admin cannot skip its host checks, and every admin destination remains within the protected session with its required hooks. (HAUTH-03)
  4. Reconnecting with an invalid session or withdrawn host authority is denied, while currently authorized staff reconnect successfully. (HAUTH-04)

**Plans**: 3/3 plans executed

Plans:
**Wave 1**
- [x] 168-01-PLAN.md — Current host policy at HTTP, disconnected and connected admin entry; required wiring refusal.

**Wave 2** *(blocked on Wave 1 completion)*
- [x] 168-02-PLAN.md — Cached-session connected rejoin with current session, identity and staff-policy checks.

**Wave 3** *(blocked on Wave 2 completion)*
- [x] 168-03-PLAN.md — Protected cross-session/admin navigation, native patches and automated evidence closure.

**UI hint**: yes
**UI scope**: Access and navigation mechanics only; no visual redesign or subjective UI signoff.
**Planning constraints**: Resolve staff identity through the host seam; conn.assigns or a copied session boolean is not current connected authority. Tests must distinguish disconnected HTTP, connected mount, cross-session navigation and reconnect. Keep native host logout/disconnect and event-policy responsibilities explicit; no promise of continuous permission revocation, new account store, role engine or resource ACL system.

### Phase 169: Install and Upgrade Convergence

**Goal**: A new or existing Phoenix host can adopt the canonical admin integration safely, understand its remaining host responsibilities and diagnose incomplete wiring.
**Depends on**: Phase 168
**Requirements**: HDX-01, HDX-02, HDX-03, HDX-04
**Success Criteria** (what must be TRUE):
  1. A fresh generated installation compiles with explicit route/session, endpoint/browser and host-authorization wiring; an unfinished host staff-policy seam cannot become an allow-all default. (HDX-01)
  2. Existing generated hosts receive a concrete migration from forward-only admin wiring; dry runs preserve bytes, repeated upgrades are safe, drift is refused and host-owned authorization/configuration is preserved. (HDX-02)
  3. `mix lockspire.verify` distinguishes complete canonical route/action/session/hook wiring from incomplete, shadowed or legacy forward-only mounts, with actionable secret-safe guidance that identifies its structural-policy limits. (HDX-03)
  4. The demo and maintained generated/clean-room hosts consume the same reusable admin declarations, and installation, upgrade, admin and supported-surface guidance match that executable path. (HDX-04)

**Plans**: TBD
**UI hint**: yes
**UI scope**: Generated integration, diagnostic and guidance changes only; preserve host-owned layouts and branding. Read PRODUCT.md before any necessary admin-visible copy change; no copy overhaul or manual signoff.
**Planning constraints**: Preserve manifest/file-transaction ownership and drift checks. Do not silently overwrite editable host hooks, claim arbitrary host policy is proven by static introspection, or keep duplicate demo routes as a fallback that masks the supported path. Add install/upgrade/verify regression tests in this phase.

### Phase 170: Packaged Host and Compatibility Proof

**Goal**: Maintainers can establish the delivered admin integration's behavior from the candidate package and supported runtime versions through reproducible automated checks.
**Depends on**: Phase 169
**Requirements**: HPROOF-01, HPROOF-02, HPROOF-03
**Success Criteria** (what must be TRUE):
  1. A clean-room host installed from the actual candidate package completes connected admin operation, navigation, reconnect and denial cases at default/custom mounts, while anonymous public protocol access remains available as intended. (HPROOF-01)
  2. Real client/socket evidence covers host endpoint session, browser assets and host-path signing without duplicated demo routes; server-side lifecycle tests are identified separately from transport proof. (HPROOF-01)
  3. Route/session, connected authorization and navigation regressions execute on both the current locked pair and exact Phoenix 1.8.5 / LiveView 1.1.28, with exact versions and runtime outcomes recorded. (HPROOF-02)
  4. Required CI executes the bounded integration checks, fails visibly on regressions and emits redaction-safe evidence tied to its source/package, without depending on manual visual approval. (HPROOF-03)

**Plans**: TBD
**UI hint**: yes
**UI scope**: Automated connection/navigation proof only; no screenshots-as-design-approval requirement or subjective UI signoff.
**Planning constraints**: Reuse the existing test/clean-room/demo and CI seams; introduce no new auth framework or dependency merely for this repair. Freeze exact commands and matrix during phase planning. Tests are added throughout earlier phases; this phase integrates candidate-package, transport and compatibility proof. Publication, merge and remote ref updates remain separate workflows.

## Verification and Scope Boundaries

- Every phase owns focused automated regressions and identifies exact machine gates during planning. UI hints identify existing LiveView surfaces, not a request for new design work; reuse existing UI contracts.
- Final evidence combines route inventory/action parity, server lifecycle/denial checks, actual client/socket operation, safe install/upgrade, structural diagnostics and exact supported-version runtime checks. No one layer substitutes for all others.
- Preserve host ownership and current secure OAuth/OIDC defaults. Do not add multi-mount, tenant-router, reverse-proxy-prefix or continuous authorization support by inference.
- Refresh repository/CI state before implementation and ship decisions. Planning is currently on feat/164-client-secret-lifetimes; this roadmap does not merge or publish the v1.45 candidate or establish a clean-main baseline.
- Existing historical Phase 142/143 directories, archived v1.45 proof, deferred records and unrelated user state.json changes remain preserved. Phase 167 supplies the native route repair; Phase 169 still owns migration/demo convergence for the historical Phase 144 forwarding workaround.

## Progress

**Execution Order:** 167 → 168 → 169 → 170. Phase 167 is complete (3/3 plans, four requirements, zero human UAT checks); Phases 168–170 have not started.

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 167. Host-Expanded Admin Routing | v1.46 | 3/3 | Complete    | 2026-10-22 |
| 168. Host-Owned LiveView Authorization | v1.46 | 3/3 | In Progress | — |
| 169. Install and Upgrade Convergence | v1.46 | 0/TBD | Not started | — |
| 170. Packaged Host and Compatibility Proof | v1.46 | 0/TBD | Not started | — |

**Coverage:** 15/15 requirements mapped exactly once; MNT-01 through MNT-04 complete in Phase 167. One phase closed; the remaining eleven requirements retain their later owners. Follow [VERIFICATION-POLICY.md](VERIFICATION-POLICY.md) for automated acceptance and durable closure records.

## Completed Backlog Scope

### Completed scope: Repository Readability & Docs Polish

**Goal:** Make Lockspire's repository a joy to navigate: clarify what each major directory is for, remove only verified stale clutter, and give adopters and maintainers a clear, accurate route through the README and canonical documentation.
**Requirements:** LANG-01, LANG-02, LANG-03, DOC-01, DOC-02, DOC-03, REPO-01, REPO-02 (scheduled in Phases 148–150).
**Status:** Delivered in v1.41 through Phases 148–150. Retain this entry as history; do not schedule the scope again.

**Captured direction:**

- Audit the top-level and nested directory tree by ownership and lifecycle. Review agent-managed worktree folders such as `.claude/worktrees/agent-ace643b0f744cfe0b`, scratch/output directories, and the long compatibility-fixture path before deciding whether anything should move, be renamed, ignored, or removed. Check active worktree/agent ownership and all CI/test references before changing paths.
- Reshape the README around adopter and maintainer jobs: evaluate Lockspire's fit and boundaries, install it into an existing Phoenix app, follow the supported-surface contract, and operate or maintain a deployment. Use LatticeStripe's reader-first docs ladder and JTBD route map as inspiration while keeping Lockspire's product scope and voice.
- Audit guide navigation, links, setup steps, and claims against the current code and `docs/supported-surface.md`; keep generated outputs, fixtures, brand assets, planning records, and maintained documentation clearly distinguished.
