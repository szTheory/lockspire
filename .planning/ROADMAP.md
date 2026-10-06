# Lockspire Roadmap

## Milestones

- 🔄 **v1.39 Verified 1.5.1 Release** — Phases 142–143 (active; publish only after exact-main checks and protected verification pass).
- ✅ **[v1.38 Repository Baseline & Reconciliation](milestones/v1.38-ROADMAP.md)** — Phases 138–141 (completed 2026-10-06; planning closeout only, no package publication; known closeout items are in STATE.md).
- ✅ **[v1.37 Prime-Time Readiness Ratchet](milestones/v1.37-ROADMAP.md)** — Phases 131–137 (shipped 2026-08-28 as Lockspire 1.5.0).

Earlier milestone history is indexed in [MILESTONES.md](MILESTONES.md) and preserved under `.planning/milestones/`.

## Phases

<details>
<summary>🔄 v1.39 Verified 1.5.1 Release (active)</summary>

- [ ] **Phase 142: Merge the Corrected Main Baseline** — Merge the corrected Phase 141 release record through review and prove the resulting exact `main` revision is ready for release.
- [ ] **Phase 143: Publish and Verify Lockspire 1.5.1** — Use the protected release workflow to publish and verify the exact 1.5.1 artifact, or record the failing gate and keep the milestone open.

### Phase 142: Merge the Corrected Main Baseline

**Goal**: Maintainers merge the reviewed Phase 141 correction so `main` truthfully identifies 1.5.0 as the latest public package until 1.5.1 has public proof, then establish a green, exact-current-main release candidate.
**Depends on**: None
**Requirements**: TRUTH-06, CI-09
**Success Criteria** (what must be TRUE):

1. The correction lands through the normal reviewed PR path, and release records continue to identify 1.5.0 as latest until a verified 1.5.1 publication exists.
2. The post-merge local `main` and refreshed `origin/main` resolve to the same full commit SHA, and the canonical required CI run passes for that SHA.
3. The exact-SHA repository-hygiene check reports no `BLOCK`, with every `WARN` disposition recorded; supplemental OIDF/FAPI results remain outside the release gate.

**Plans**: 0 plans

### Phase 143: Publish and Verify Lockspire 1.5.1

**Goal**: Maintainers publish Lockspire 1.5.1 from the approved exact `main` revision through the protected workflow and record the matching public package proof.
**Depends on**: Phase 142
**Requirements**: REL-01, REL-02, REL-03
**Success Criteria** (what must be TRUE):

1. The protected workflow validates that the 1.5.1 source is the exact current `main` SHA and has its own matching successful canonical CI run before publication.
2. The workflow publishes the same manifest-verified artifact it proved before publication; public Hex checksum, `lockspire-v1.5.1` release target, and clean-room install proof all match that artifact and source.
3. `.planning/RELEASE-TRAIN.md` records the actual public version, source SHA, canonical CI run, protected publish run, package checksum, GitHub release, and install-truth result.
4. If any gate fails, publication or milestone completion stops, the evidence and blocker are recorded, and no record says 1.5.1 shipped.

**Plans**: 0 plans

</details>

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
