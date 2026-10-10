# Roadmap: Lockspire

## Milestones

- ✅ **[v1.40 Admin Operator UI Refinement](milestones/v1.40-ROADMAP.md)** — Completed 2026-10-10; Phases 144–147, 21 plans, 24 requirements. Override closeout: three verification reports stale, Phase 146 `human_needed`; see the [audit](milestones/v1.40-MILESTONE-AUDIT.md).
- ✅ **[v1.39 Verified 1.5.1 Release](milestones/v1.39-ROADMAP.md)** — Phases 142–143; Lockspire 1.5.1 shipped 2026-10-08 with an acknowledged PR #119 merge-authorization gap.
- ✅ **[v1.38 Repository Baseline & Reconciliation](milestones/v1.38-ROADMAP.md)** — Phases 138–141; completed 2026-10-06 as planning closeout, without package publication.
- ✅ **[v1.37 Prime-Time Readiness Ratchet](milestones/v1.37-ROADMAP.md)** — Phases 131–137; shipped 2026-08-28 as Lockspire 1.5.0.

Earlier milestone history is indexed in [MILESTONES.md](MILESTONES.md) and preserved under `.planning/milestones/`.

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
