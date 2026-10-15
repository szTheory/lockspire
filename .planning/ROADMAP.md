# Roadmap: Lockspire

## Milestones

- 🚧 **v1.42 Admin UI Clarity & Workflow Refinement** — Phases 151–154 (planning; no protocol changes or package release implied).
- ✅ **v1.41 Product Language & Repository Clarity** — Phases 148–150 (completed 2026-10-11; planning and documentation, no package release).
- ✅ [v1.40 Admin Operator UI Refinement](milestones/v1.40-ROADMAP.md) — completed 2026-10-10; Phases 144–147.
- ✅ [v1.39 Verified 1.5.1 Release](milestones/v1.39-ROADMAP.md) — completed 2026-10-08; Lockspire 1.5.1 published.
- ✅ [v1.38 Repository Baseline & Reconciliation](milestones/v1.38-ROADMAP.md) — completed 2026-10-06; planning closeout, no package publication.
- ✅ [v1.37 Prime-Time Readiness Ratchet](milestones/v1.37-ROADMAP.md) — shipped 2026-08-28 as Lockspire 1.5.0.

Earlier milestone history is indexed in [MILESTONES.md](MILESTONES.md) and preserved under `.planning/milestones/`.

## Current Direction

v1.42 refines the existing admin UI around real staff tasks: focused client registration and settings, accurate overview and queue states, plain language, and coherent page hierarchy. Review all 29 route scorecards plus Phase 151's `/admin/clients/new` route (30 current paths) in the mounted synthetic demo. Preserve the embedded-library and host-owned boundaries, credential redaction, security behavior, and read-only operation queues. CR-01 remains a separate critical unresolved security issue.

## Phases

<details open>
<summary>🚧 v1.42 Admin UI Clarity & Workflow Refinement (Phases 151–154)</summary>

- [x] **Phase 151: Focused Client Registration & Settings** — Give client creation its own route, make client task paths focused, and apply clear action emphasis.
- [x] **Phase 152: Overview & Queue State Clarity** — Make overview signals and read-only queue outcomes accurate, understandable, and actionable within their existing limits.
- [x] **Phase 153: Configure & Support Page Refinement** — Apply plain language, clear page hierarchy, and purposeful shared components across all 30 current admin paths.
- [ ] **Phase 154: Responsive, Theme & Route Proof** — Finish changed views across viewport, zoom, theme, and keyboard states with redaction-safe rendered evidence and recurring automated checks.

</details>

<details>
<summary>✅ v1.41 Product Language & Repository Clarity (Phases 148–150) — completed 2026-10-11</summary>

- [x] Phase 148: User-Facing Admin Language (7/7 plans) — task-centered copy that preserves OAuth/OIDC meaning and truthful outcomes.
- [x] Phase 149: Repository Ownership and Lifecycle (1/1 plan) — lifecycle map and evidence-backed preservation decisions.
- [x] Phase 150: Adopter and Maintainer Documentation (2/2 plans) — canonical adoption path and task-grouped HexDocs.

**Audit:** [v1.41 milestone audit](milestones/v1.41-MILESTONE-AUDIT.md) — no requirement or integration gaps; bounded maintenance debt accepted.

</details>

## v1.42 Admin UI Clarity & Workflow Refinement

### Phase 151: Focused Client Registration & Settings

**Goal**: Staff can register a client and complete a client-specific task without wading through unrelated inventory content, while recognizing the page's main action.
**Depends on**: Nothing (first phase of v1.42).
**Requirements**: UI-04, UI-05
**Success Criteria** (what must be TRUE):
  1. From the client inventory, staff can open a dedicated registration page with one clear title, one concise explanation, a focused form, and a visible path back to the inventory.
  2. Client detail, edit, redirect, logout, policy, and credential tasks identify the client and the task at the top and provide a direct return path to its context.
  3. Across the admin routes, the principal safe task is visually primary, supporting navigation and recovery actions are quieter, and destructive actions state their consequence and require the existing confirmation.

**Plans:** 2/2 plans complete
Plans:
- [x] 151-01-PLAN.md — Dedicated client registration route and safe create outcomes
- [x] 151-02-PLAN.md — Focused client settings context and shared action hierarchy

**UI hint**: yes

### Phase 152: Overview & Queue State Clarity

**Goal**: Staff can understand current provider and queue signals without mistaking a failed read for an empty inventory or over-interpreting an event.
**Depends on**: Phase 151.
**Requirements**: UI-03
**Success Criteria** (what must be TRUE):
  1. Overview counts and links describe the same underlying records and status filters that the linked inventory pages show.
  2. Token reuse copy identifies the recorded reuse and supported family-wide consequence without claiming compromise; logout delivery copy explains what was attempted or failed and where to investigate next.
  3. Interaction, device authorization, and logout queues remain read-only, show meaningful record states, and distinguish unavailable data from healthy zero or empty results.

**Plans**: 5/5 plans complete
Plans:
- [x] 152-01-PLAN.md — Exact waiting-interaction pivot and historical wording
- [x] 152-02-PLAN.md — Exact pending-device and logout-review pivots
- [x] 152-03-PLAN.md — Device authorization request title and state clarity
- [x] 152-04-PLAN.md — Accurate logout-delivery outcomes
- [x] 152-05-PLAN.md — Plain overview facts and evidence-aware signal copy

**UI hint**: yes

### Phase 153: Configure & Support Page Refinement

**Goal**: Staff can scan each Configure and Support page by its actual task, understand necessary protocol language in context, and find the relevant decision or next action quickly.
**Depends on**: Phases 151 and 152.
**Requirements**: UI-01, UI-02, UI-06
**Success Criteria** (what must be TRUE):
  1. A current review covers all 29 route scorecards plus `/admin/clients/new` (30 current paths); each page has a clear title, task-centered information order, and no duplicate heading or generic introduction that repeats it.
  2. Labels and help use consistent, user-facing language; low-value inventory provenance and implementation commentary are removed, and necessary OAuth/OIDC terms are explained where they affect a decision.
  3. The shared components and tokens create readable spacing, hierarchy, and control affordances without unnecessary metric rows or nested containers, and the theme selector caret has visible inset from the control edge.

**Plans**: 7/7 plans complete
Plans:
- [x] 153-00-PLAN.md — Redaction-safe visual baseline for all 30 current paths
- [x] 153-01-PLAN.md — Shared hierarchy, provider settings, and theme-select inset
- [x] 153-02-PLAN.md — Plain provider security and registration policy pages
- [x] 153-03-PLAN.md — Signing-key and adopter setup-token pages
- [x] 153-04-PLAN.md — Consent-grant and token support pages
- [x] 153-05-PLAN.md — Complete inherited hero caller migration and preserve client/queue contracts
- [x] 153-06-PLAN.md — Rendered review matrix for all 30 current admin paths

**UI hint**: yes

### Phase 154: Responsive, Theme & Route Proof

**Goal**: Changed admin journeys remain usable across screen sizes and preferences, with repeatable evidence that preserves sensitive values and existing security behavior.
**Depends on**: Phases 151–153.
**Requirements**: UI-07, PROOF-01, SAFE-01
**Success Criteria** (what must be TRUE):
  1. Changed pages remain readable and operable at narrow widths and 200% zoom in light, dark, and system themes, with sufficient contrast, labeled controls, visible keyboard focus, reduced-motion support, and no clipped content or actions.
  2. All 30 current paths have synthetic, redaction-safe baseline and final captures; capture each full page or, when a full-page image is too tall or unreadable, each meaningful section. Focused tests/browser checks prove affected tasks and recurring visual behavior.
  3. Automated checks confirm the cleanup leaves protocol behavior, security defaults, credential redaction and copy-once handling, revocation scopes, queue read-only boundaries, and host ownership unchanged; new checks join CI only when reliable and recurring.

**Plans**: 4/7 plans executed
Plans:
**Wave 1**
- [x] 154-01-PLAN.md — Local route-proof harness (agent-browser, local-only) and BrowserEvidence viewport widths
- [x] 154-02-PLAN.md — Shared control-border token and computed WCAG contrast contract
- [x] 154-03-PLAN.md — Bundled page contract on Orient and client-task routes

**Wave 2** *(blocked on Wave 1 completion)*
- [x] 154-04-PLAN.md — Page contract on Configure policy/registration/key routes; keys_live warning fix
- [ ] 154-05-PLAN.md — Page contract on Support/Operate routes; device-authorization warning fix

**Wave 3** *(blocked on Wave 2 completion)*
- [ ] 154-06-PLAN.md — 30-path responsive, theme, reduced-motion and keyboard sweep with shared fixes

**Wave 4** *(blocked on Wave 3 completion)*
- [ ] 154-07-PLAN.md — Final 30-path captures, browser evidence, and SAFE-01 gate

**UI hint**: yes

### Progress

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 151. Focused Client Registration & Settings | 2/2 | Complete    | 2026-10-15 |
| 152. Overview & Queue State Clarity | 5/5 | Complete    | 2026-10-15 |
| 153. Configure & Support Page Refinement | 7/7 | Complete    | 2026-10-15 |
| 154. Responsive, Theme & Route Proof | 4/7 | In Progress | - |

## Completed Backlog Scope

### Completed scope: Repository Readability & Docs Polish

**Goal:** Make Lockspire's repository a joy to navigate: clarify what each major directory is for, remove only verified stale clutter, and give adopters and maintainers a clear, accurate route through the README and canonical documentation.
**Requirements:** LANG-01, LANG-02, LANG-03, DOC-01, DOC-02, DOC-03, REPO-01, REPO-02 (scheduled in Phases 148–150).
**Status:** Delivered in v1.41 through Phases 148–150. Retain this entry as history; do not schedule the scope again.

**Captured direction:**

- Audit the top-level and nested directory tree by ownership and lifecycle. Review agent-managed worktree folders such as `.claude/worktrees/agent-ace643b0f744cfe0b`, scratch/output directories, and the long compatibility-fixture path before deciding whether anything should move, be renamed, ignored, or removed. Check active worktree/agent ownership and all CI/test references before changing paths.
- Reshape the README around adopter and maintainer jobs: evaluate Lockspire's fit and boundaries, install it into an existing Phoenix app, follow the supported-surface contract, and operate or maintain a deployment. Use LatticeStripe's reader-first docs ladder and JTBD route map as inspiration while keeping Lockspire's product scope and voice.
- Audit guide navigation, links, setup steps, and claims against the current code and `docs/supported-surface.md`; keep generated outputs, fixtures, brand assets, planning records, and maintained documentation clearly distinguished.
