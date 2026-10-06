# Lockspire Roadmap

## Milestones

- ✅ **[v1.38 Repository Baseline & Reconciliation](milestones/v1.38-ROADMAP.md)** — Phases 138–141 (completed 2026-10-06; planning closeout only, no package publication; known closeout items are in STATE.md).
- ✅ **[v1.37 Prime-Time Readiness Ratchet](milestones/v1.37-ROADMAP.md)** — Phases 131–137 (shipped 2026-08-28 as Lockspire 1.5.0).

Earlier milestone history is indexed in [MILESTONES.md](MILESTONES.md) and preserved under `.planning/milestones/`.

## Phases

<details>
<summary>✅ v1.38 Repository Baseline & Reconciliation (completed 2026-10-06)</summary>

- [x] Phase 138: Baseline Inventory & Evidence Taxonomy — 38/38 plans; verification report passed.
- [x] Phase 139: Required Truth Reconciliation — 16/16 plans; `gaps_found` report retained and acknowledged at closeout.
- [x] Phase 140: Bounded Operational Loose-End Triage — 18/18 plans; historical 30/32 report retained, with terminal CI-06/CI-07 acceptance linked from Phase 141.
- [x] Phase 141: Maintenance-Baseline Closure — 1/1 plan; verification report passed.

Closeout acknowledged one halted Phase 139 verification-repair task and the `gaps_found` reports for Phases 139 and 140. See the [closeout record](MILESTONES.md) and [STATE.md](STATE.md). The latest public package remains 1.5.0.

</details>

<details>
<summary>✅ v1.37 Prime-Time Readiness Ratchet (Phases 131–137) — SHIPPED 2026-08-28</summary>

- [x] Phases 131–137: 58/58 plans complete; released as Lockspire 1.5.0.

</details>

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
