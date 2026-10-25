# Roadmap: Lockspire

## Milestones

- ✅ [v1.47 OAuth/OIDC Core Interoperability & Hardening](milestones/v1.47-ROADMAP.md) — completed 2026-10-25; Phases171–174, 10 plans, 14/14 requirements; accepted main173059a1; package publication separate.
- ✅ [v1.46 Embedded Host Integration Reliability](milestones/v1.46-ROADMAP.md) — completed 2026-10-24; Phases 167–170, 16 plans, 15/15 requirements; package publication separate.
- ✅ [v1.45 DCR Lifetime Enforcement](milestones/v1.45-ROADMAP.md) — completed 2026-10-22; Phases 162–166, 40 plans, 18/18 requirements; package publication separate.
- ✅ [v1.44 Adopter Polish & Verified 1.6.0](milestones/v1.44-ROADMAP.md) — completed 2026-10-20; Phases 158–161; shipped in Lockspire 1.6.0.
- ✅ [v1.43 Signing Key Encryption at Rest](milestones/v1.43-ROADMAP.md) — completed 2026-10-16; Phases 155–157; closes CR-01; no OAuth/OIDC behavior change.
- ✅ [v1.42 Admin UI Clarity & Workflow Refinement](milestones/v1.42-ROADMAP.md) — completed 2026-10-15; Phases 151–154; no protocol changes or package release.
- ✅ [v1.41 Product Language & Repository Clarity](milestones/v1.41-ROADMAP.md) — completed 2026-10-11; Phases 148–150; planning and documentation, no package release.
- ✅ [v1.40 Admin Operator UI Refinement](milestones/v1.40-ROADMAP.md) — completed 2026-10-10; Phases 144–147.
- ✅ [v1.39 Verified 1.5.1 Release](milestones/v1.39-ROADMAP.md) — completed 2026-10-08; Lockspire 1.5.1 published.
- ✅ [v1.38 Repository Baseline & Reconciliation](milestones/v1.38-ROADMAP.md) — completed 2026-10-06; planning closeout, no package publication.
- ✅ [v1.37 Prime-Time Readiness Ratchet](milestones/v1.37-ROADMAP.md) — shipped 2026-08-28 as Lockspire 1.5.0.

## Next Milestone

No new milestone is selected. Run `$gsd-new-milestone` to refresh evidence, choose scope and create fresh requirements. SEC-01 client-authentication key isolation/rotation remains preferred provisional v1.48; continue phase numbering after174. [Ranking and triggers](MILESTONE-ARC.md).

## Completed Backlog Scope

### Completed scope: Repository Readability & Docs Polish

**Goal:** Make Lockspire's repository a joy to navigate: clarify what each major directory is for, remove only verified stale clutter, and give adopters and maintainers a clear, accurate route through the README and canonical documentation.
**Requirements:** LANG-01, LANG-02, LANG-03, DOC-01, DOC-02, DOC-03, REPO-01, REPO-02 (scheduled in Phases 148–150).
**Status:** Delivered in v1.41 through Phases 148–150. Retain this entry as history; do not schedule the scope again.

**Captured direction:**

- Audit the top-level and nested directory tree by ownership and lifecycle. Review agent-managed worktree folders such as `.claude/worktrees/agent-ace643b0f744cfe0b`, scratch/output directories, and the long compatibility-fixture path before deciding whether anything should move, be renamed, ignored, or removed. Check active worktree/agent ownership and all CI/test references before changing paths.
- Reshape the README around adopter and maintainer jobs: evaluate Lockspire's fit and boundaries, install it into an existing Phoenix app, follow the supported-surface contract, and operate or maintain a deployment. Use LatticeStripe's reader-first docs ladder and JTBD route map as inspiration while keeping Lockspire's product scope and voice.
- Audit guide navigation, links, setup steps, and claims against the current code and `docs/supported-surface.md`; keep generated outputs, fixtures, brand assets, planning records, and maintained documentation clearly distinguished.
