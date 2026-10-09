# Roadmap: Lockspire

## Milestones

- 📋 **v1.40 Admin Operator UI Refinement** — Phases 144–147; Phase 144 complete with four executed plans, passed independent verification, and a stable synthetic preview. Phase 145 is next.
- ✅ **[v1.39 Verified 1.5.1 Release](milestones/v1.39-ROADMAP.md)** — Phases 142–143; Lockspire 1.5.1 shipped 2026-10-08. Phase 143's exact-head PR #119 merge-authorization gap was acknowledged at closeout; see the archived audit.
- ✅ **[v1.38 Repository Baseline & Reconciliation](milestones/v1.38-ROADMAP.md)** — Phases 138–141 (completed 2026-10-06; planning closeout only, no package publication; known closeout items are in STATE.md).
- ✅ **[v1.37 Prime-Time Readiness Ratchet](milestones/v1.37-ROADMAP.md)** — Phases 131–137 (shipped 2026-08-28 as Lockspire 1.5.0).

Earlier milestone history is indexed in [MILESTONES.md](MILESTONES.md) and preserved under `.planning/milestones/`.

## Overview

Refine the existing embedded LiveView operator UI through four complete delivery boundaries: prove shared improvements on working client-configuration and support-investigation journeys; extend them through Configure and onboarding; make Support, Orient, and read-only Operate states and consequences truthful; then confirm coherence across the full surface and leave a stable preview for optional feedback. Phase 144 established the isolated host-mounted synthetic demo, confirmed current source and served styles, and refreshed all 29 existing route/workflow observations before editing. Its preview recipe, connected representative jobs, and explicit coverage limits are retained in the phase evidence. Each implementation phase must carry responsive, keyboard, theme, domain-copy, redaction, and reduced-motion behavior in its changed pages; Phase 147 owns final cross-surface acceptance. Use existing components, `--ls-*` tokens, and valid historical UI work. Keep the feedback preview stable and run mutating checks against separate disposable data. Scope excludes new protocol or service capability, host-owned account UX, invented queue controls, a new frontend stack, paid/open-ended visual judges, and any reexecution of the archived Phase 143 release decision.

## Phases

- [x] **Phase 144: Working Preview and Representative Journeys** - Open the actual mounted UI and deliver shared refinements on complete client-configuration and token/consent-investigation workflows. Completed 2026-10-09.
- [ ] **Phase 145: Configure and Onboard** - Carry the proven patterns through supported client, policy, credential, DCR, and key workflows.
- [ ] **Phase 146: Support, Orient, and Operate** - Make investigation, revocation, overview, and read-only operations clear and truthful, including failed or unknown observations.
- [ ] **Phase 147: Surface Coherence and Working Preview** - Confirm responsive, accessible, themed, and motion behavior across the surface with bounded evidence and a stable optional-feedback preview.

<details>
<summary>✅ v1.39 Verified 1.5.1 Release — completed 2026-10-08 with an acknowledged verification gap</summary>

- [x] Phase 142: Merge the Corrected Main Baseline — 4/4 plans; verification passed 11/11.
- Phase 143: Publish and Verify Lockspire 1.5.1 — 6/6 plans executed; public artifact verified; `gaps_found` (16/18) for the unrecorded exact-head PR #119 merge decision. User acknowledged this historical gap; milestone closeout proceeded with an override.

</details>

<details>
<summary>✅ v1.38 Repository Baseline & Reconciliation (completed 2026-10-06)</summary>

- [x] Phases 138–141: 73 plans; completed with acknowledged Phase 139/140 verification gaps.

</details>

<details>
<summary>✅ v1.37 Prime-Time Readiness Ratchet (Phases 131–137) — shipped 2026-08-28</summary>

- [x] Phases 131–137: 58/58 plans complete; released as Lockspire 1.5.0.

</details>

## v1.40 Admin Operator UI Refinement

### Phase 144: Working Preview and Representative Journeys

**Goal**: Operators can complete representative Configure and Support jobs in a working host-mounted UI whose shared visual and interaction patterns are ready to carry forward.
**Depends on**: Nothing in v1.40; v1.39 is already archived and its acknowledged verification gap is non-blocking.
**Requirements**: UIB-01, UIB-02, UIB-03
**Success Criteria** (what must be TRUE):
  1. Maintainer can open a host-mounted preview with synthetic records and inspect a refreshed inventory of all 28 admin routes plus the logout-propagation query workflow, with the current source, served styling path, and baseline observations identified.
  2. Operator can complete a client-configuration task on the mounted pages with a clear primary action, readable hierarchy, relevant validation, and coherent form and action groups.
  3. Operator can find a token or consent grant, inspect its context, and reach the relevant supported next action through a complete mounted investigation journey.
  4. Maintainer can compare representative before/after views and apply the demonstrated page, type, spacing, control, and domain-language patterns through existing shared components and tokens.

**Plans**: 4/4 plans complete
Plans:
**Wave 1**
- [x] 144-01-PLAN.md — Isolated host preview and fresh before-edit 29-workflow baseline

**Wave 2** *(blocked on Wave 1 completion)*
- [x] 144-02-PLAN.md — Complete client inventory, detail, metadata save and error journey

**Wave 3** *(blocked on Wave 2 completion)*
- [x] 144-03-PLAN.md — Token investigation and distinct token/family consequences

**Wave 4** *(blocked on Wave 3 completion)*
- [x] 144-04-PLAN.md — Consent investigation and bounded served-browser proof

**UI hint**: yes

Planning note: Read [PRODUCT.md](../PRODUCT.md) and [UI-MILESTONE-PREFLIGHT.md](UI-MILESTONE-PREFLIGHT.md); establish the phase UI contract using Impeccable Operate guidance and the confirmed code-first preference, with installed Emil design/motion skills only where useful. Resolve the documented browser-baseline unknown before relying on screenshots. Implement representative complete jobs in this phase, not only a contract or scorecard refresh. Keep the host preview stable; use separate disposable data for mutating checks.

### Phase 145: Configure and Onboard

**Goal**: Operators can configure supported clients, policies, credentials, onboarding, and keys through a coherent, safe workflow.
**Depends on**: Phase 144
**Requirements**: UIC-01, UIC-02, UIC-03, UIC-04, UIC-05, UIC-06
**Success Criteria** (what must be TRUE):
  1. Operator can find, inspect, create, and edit a client while retaining client context, seeing the primary action, and correcting field-specific validation errors.
  2. Operator can set supported redirect, logout, and issuer/client security options with clear destination meanings, inherited versus overridden values, and truthful save or failure feedback.
  3. Operator can issue or rotate a supported client credential, understand the consequence, and complete its one-time handoff without a later redisclosure path.
  4. Operator can complete DCR onboarding and initial-access-token tasks with distinct token purposes, lifecycle, scope, and expiry made clear.
  5. Operator can inspect signing-key state and complete already-supported key actions with accurate consequence and outcome feedback.

**Plans**: TBD
**UI hint**: yes

Planning note: Carry Phase 144's proven patterns into each changed Configure journey, including narrow/zoomed layout, keyboard and focus behavior, light/dark/system appearance, clear copy, redaction, and reduced motion. Preserve the host seam and supported security defaults.

### Phase 146: Support, Orient, and Operate

**Goal**: Operators can investigate authorizations and operational state, distinguish missing evidence from healthy emptiness, and take only the supported action with a truthful result.
**Depends on**: Phase 145
**Requirements**: UIS-01, UIS-02, UIS-03, UIO-01, UIO-02, UIO-03
**Success Criteria** (what must be TRUE):
  1. Operator can filter token and consent inventories, inspect a record, and follow client or authorization pivots while retaining enough context to continue the investigation.
  2. Operator can read lifecycle, family, timestamp, and complete authorized diagnostic identifiers while credentials remain redacted.
  3. Operator can distinguish token, consent-grant, and refresh-family revocations, confirm the exact supported consequence, recover from failure, and see the actual resulting state.
  4. Operator can tell a successful empty token, consent, or device inventory from an unavailable observation; failed loads retain context and an existing recovery path, and the overview never presents unknown as measured zero or healthy.
  5. Operator can use the overview to choose a next task and inspect interaction, device, logout, and client propagation evidence with legible state and useful pivots; operation queues remain read-only.

**Plans**: TBD
**UI hint**: yes

Planning note: Carry responsive, keyboard/focus, theme, copy, redaction, and reduced-motion rules into every changed Support, Orient, and Operate state. Narrow error-state repairs through existing admin/service seams are in scope; new queue controls or protocol actions are not.

### Phase 147: Surface Coherence and Working Preview

**Goal**: The existing operator surface reads and behaves as one coherent interface, with bounded proof and a stable preview ready for optional user feedback.
**Depends on**: Phase 146
**Requirements**: UIQ-01, UIQ-02, UIQ-03, UIQ-04, UIQ-05, UIV-01, UIV-02, UIV-03, UIV-04
**Success Criteria** (what must be TRUE):
  1. Operator can use every changed journey at narrow, intermediate, and desktop widths and actual 200% browser zoom without clipped actions, lost diagnostic values, unreadably small text, or unintended page overflow.
  2. Operator can complete changed forms and confirmations by keyboard with associated labels and errors, visible/restored focus, and intact controls through busy, success, error, repeat-action, and LiveView patch cycles.
  3. Operator can read and distinguish controls and status in light, dark, and system appearance with AA contrast targets, non-color-only cues, one clear selected theme preference, consistent domain language, and prompt feedback that respects reduced motion.
  4. Maintainer can inspect fresh rendered evidence across all 29 existing scorecards, with deeper state/theme/viewport checks chosen by risk, and run focused regressions against delivered styling and behavior with visible failures/skips and reliable claimed CI coverage.
  5. User can open a stable, documented synthetic-data preview and compare representative before/after views under matching conditions; the handoff records one batched finding list, fixes, one confirmation pass, current operator guidance, and explicit remaining limits.

**Plans**: TBD
**UI hint**: yes

Planning note: This is a bounded finish, not a new proof bureaucracy. Preserve expected screenshot baselines during ordinary verification, use a separate disposable instance for mutating tests, retain redaction-safe evidence, and avoid paid judges or open-ended aesthetic loops. Final route coverage includes all 28 admin routes plus the logout-propagation query workflow; deepen cases by risk instead of multiplying every combination.

## Progress

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 144. Working Preview and Representative Journeys | v1.40 | 4/4 | Complete    | 2026-10-09 |
| 145. Configure and Onboard | v1.40 | 0/TBD | Not started | - |
| 146. Support, Orient, and Operate | v1.40 | 0/TBD | Not started | - |
| 147. Surface Coherence and Working Preview | v1.40 | 0/TBD | Not started | - |

## Backlog

### Phase 999.1: Repository Readability & Docs Polish (BACKLOG)

**Goal:** Make Lockspire's repository a joy to navigate: clarify what each major directory is for, remove only verified stale clutter, and give adopters and maintainers a clear, accurate route through the README and canonical documentation.
**Requirements:** None assigned; identify applicable requirements during backlog promotion.
**Plans:** 0 plans

**Captured direction:**

- Audit the top-level and nested directory tree by ownership and lifecycle. Review agent-managed worktree folders such as `.claude/worktrees/agent-ace643b0f744cfe0b`, scratch/output directories, and the long compatibility-fixture path before deciding whether anything should move, be renamed, ignored, or removed. Check active worktree/agent ownership and all CI/test references before changing paths.
- Reshape the README around adopter and maintainer jobs: evaluate Lockspire's fit and boundaries, install it into an existing Phoenix app, follow the supported-surface contract, and operate or maintain a deployment. Use LatticeStripe's reader-first docs ladder and JTBD route map as inspiration while keeping Lockspire's product scope and voice.
- Audit guide navigation, links, setup steps, and claims against the current code and `docs/supported-surface.md`; keep generated outputs, fixtures, brand assets, planning records, and maintained documentation clearly distinguished.

Plans:

- [ ] Define and scope plans during backlog promotion with `$gsd-review-backlog`.
