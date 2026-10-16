# Roadmap: Lockspire

## Milestones

- ✅ [v1.43 Signing Key Encryption at Rest](milestones/v1.43-ROADMAP.md) — completed 2026-10-16; Phases 155–157; closes CR-01; no OAuth/OIDC behavior change.
- ✅ [v1.42 Admin UI Clarity & Workflow Refinement](milestones/v1.42-ROADMAP.md) — completed 2026-10-15; Phases 151–154; no protocol changes or package release.
- ✅ [v1.41 Product Language & Repository Clarity](milestones/v1.41-ROADMAP.md) — completed 2026-10-11; Phases 148–150; planning and documentation, no package release.
- ✅ [v1.40 Admin Operator UI Refinement](milestones/v1.40-ROADMAP.md) — completed 2026-10-10; Phases 144–147.
- ✅ [v1.39 Verified 1.5.1 Release](milestones/v1.39-ROADMAP.md) — completed 2026-10-08; Lockspire 1.5.1 published.
- ✅ [v1.38 Repository Baseline & Reconciliation](milestones/v1.38-ROADMAP.md) — completed 2026-10-06; planning closeout, no package publication.
- ✅ [v1.37 Prime-Time Readiness Ratchet](milestones/v1.37-ROADMAP.md) — shipped 2026-08-28 as Lockspire 1.5.0.

Earlier milestone history is indexed in [MILESTONES.md](MILESTONES.md) and preserved under `.planning/milestones/`.

## Current Direction

No milestone is active. v1.43 closed CR-01 (private signing keys encrypted at rest under a rotatable host KEK). Start the next milestone with `/gsd-new-milestone`; carry-forward candidates are listed under Requirements → Active in [PROJECT.md](PROJECT.md).

## Phases

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
