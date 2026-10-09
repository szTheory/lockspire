# Lockspire Roadmap

## Milestones

- ✅ **[v1.39 Verified 1.5.1 Release](milestones/v1.39-ROADMAP.md)** — Phases 142–143; Lockspire 1.5.1 shipped 2026-10-08. Phase 143's exact-head PR #119 merge-authorization gap was acknowledged at closeout; see the archived audit.
- ✅ **[v1.38 Repository Baseline & Reconciliation](milestones/v1.38-ROADMAP.md)** — Phases 138–141 (completed 2026-10-06; planning closeout only, no package publication; known closeout items are in STATE.md).
- ✅ **[v1.37 Prime-Time Readiness Ratchet](milestones/v1.37-ROADMAP.md)** — Phases 131–137 (shipped 2026-08-28 as Lockspire 1.5.0).

Earlier milestone history is indexed in [MILESTONES.md](MILESTONES.md) and preserved under `.planning/milestones/`.

## Phases

<details>
<summary>✅ v1.39 Verified 1.5.1 Release — completed 2026-10-08 with an acknowledged verification gap</summary>

- [x] Phase 142: Merge the Corrected Main Baseline — 4/4 plans; verification passed 11/11.
- [ ] Phase 143: Publish and Verify Lockspire 1.5.1 — 6/6 plans executed; public artifact verified; `gaps_found` (16/18) for the unrecorded exact-head PR #119 merge decision. User acknowledged this historical gap; milestone closeout proceeded with an override.

</details>

<details>
<summary>✅ v1.38 Repository Baseline & Reconciliation (completed 2026-10-06)</summary>

- [x] Phases 138–141: 73 plans; completed with acknowledged Phase 139/140 verification gaps.

</details>

<details>
<summary>✅ v1.37 Prime-Time Readiness Ratchet (Phases 131–137) — shipped 2026-08-28</summary>

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
