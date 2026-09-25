# Lockspire Roadmap

## Milestones

- ✅ **[v1.37 Prime-Time Readiness Ratchet](milestones/v1.37-ROADMAP.md)** — Phases 131-137 (shipped 2026-08-28 as Lockspire 1.5.0)
- 🚧 **v1.38 Repository Baseline & Reconciliation** — Phases 138-141 (planned)

Earlier milestone history is indexed in [MILESTONES.md](MILESTONES.md) and preserved under `.planning/milestones/`.

## Phases

- [x] **Phase 138: Baseline Inventory & Evidence Taxonomy** - Establish the exact local, remote, and maintained-record evidence on which every later disposition relies. (completed 2026-09-25)
- [x] **Phase 139: Required Truth Reconciliation** - Reconcile the exact-SHA acceptance, release, hygiene, and planning truth using existing repository controls. (completed 2026-09-25)
- [ ] **Phase 140: Bounded Operational Loose-End Triage** - Decide and resolve only evidence-backed operational loose ends without broad cleanup or feature work.
- [ ] **Phase 141: Maintenance-Baseline Closure** - Publish the final evidence-backed baseline record and return Lockspire to its sustaining GA release train.

## Phase Details

### Phase 138: Baseline Inventory & Evidence Taxonomy

**Goal**: Maintainers have one current, non-destructive evidence inventory for local/remote Git state and every maintained operational follow-up.
**Depends on**: Nothing (first phase)
**Requirements**: BASE-01, BASE-02, TRIAGE-01, TRIAGE-02, LOOSE-01
**Success Criteria** (what must be TRUE):

  1. A maintainer can refresh origin references and show whether local `main` is clean and synchronized with `origin/main`, including the exact divergence when it is not.
  2. A maintainer can inspect every relevant branch, tag, and worktree in a dated inventory with an explicit proposed keep, remove, or defer disposition.
  3. A maintainer can inspect every open pull request and issue and find a current evidence-backed disposition for each, without equating a healthy baseline with an empty queue.
  4. A maintainer can locate todos, audit and verification findings, debug or handoff artifacts, roadmap notes, and other maintained follow-up records in one complete inventory.

**Plans**: 38/38 plans executed; Phase 138 verification passed (G-138-98 closed)

Plans:

**Wave 37** *(gap closure)*

- [x] 138-37-PLAN.md — Add claim-specific negative evidence and explicit review states for the prohibition ledger.

**Wave 38** *(gap closure; blocked on 138-37; includes maintainer review checkpoint)*

- [x] 138-38-PLAN.md — Resolve every remaining claim and enforce a zero-pending closure gate.

**Wave 35** *(gap closure)*

- [x] 138-35-PLAN.md — Repair the two Phase 138 lifecycle receipt fixtures and retain fail-closed recovery proof.

**Wave 36** *(gap closure)*

- [x] 138-36-PLAN.md — Record evidence tiers and truthful dispositions for every Phase 138 prohibition; claim-level resolution remains open.

**Wave 34** *(zero-human UAT gap closure; blocked on 138-33)*

- [x] 138-34-PLAN.md — Convert all remaining Phase 138 UAT checks to automated coverage and add only the portable finalizer-router contract to recurring CI.

**Wave 30** *(gap closure; blocked on 138-29)*

- [x] 138-30-PLAN.md — Bind GSD closeout decisions and performance rows to exact summary semantics.

**Wave 31** *(gap closure; blocked on Wave 30)*

- [x] 138-31-PLAN.md — Redact lowercase-run opaque credentials across every evidence sink.

**Wave 32** *(gap closure; blocked on Wave 31)*

- [x] 138-32-PLAN.md — Publish one truthful pre-verifier ledger and validate it against the host-sealed post-transition receipt.

**Wave 33** *(gap closure; blocked on Wave 32; final gap plan and lifecycle activation)*

- [x] 138-33-PLAN.md — Install the tracked two-hook capability and prove pending-state recovery blocks later routing.

Required Phase 138 gap handoff:

`$gsd-execute-phase 138 --gaps-only --interactive`

This executes only the newly planned Waves 37–38: Plan 37 adds claim-specific evidence and a separate resolution state for the 108 prohibition claims; Plan 38 records explicit delegated maintainer outcomes and enforces a zero-pending closure gate. All 108 outcomes are complete and the phase verification passed. The earlier Waves 30–36 were not rerun by `--gaps-only`.

- [x] 138-26-PLAN.md
- [x] 138-27-PLAN.md
- [x] 138-28-PLAN.md
- [x] 138-29-PLAN.md

**Wave 24** *(gap closure; blocked on 138-23)*

- [x] 138-24-PLAN.md — Correct exact GitHub OID validation and fail-closed maintained-record classification with adversarial fixtures.

**Wave 25** *(gap closure; blocked on Wave 24)*

- [x] 138-25-PLAN.md — Recollect and immutably republish the canonical ledger from the corrected clean base.

- [x] 138-22-PLAN.md
- [x] 138-23-PLAN.md

- [x] 138-17-PLAN.md
- [x] 138-18-PLAN.md
- [x] 138-19-PLAN.md
- [x] 138-20-PLAN.md
- [x] 138-21-PLAN.md

- [x] 138-12-PLAN.md
- [x] 138-13-PLAN.md
- [x] 138-14-PLAN.md
- [x] 138-15-PLAN.md
- [x] 138-16-PLAN.md

- [x] 138-04-PLAN.md
- [x] 138-05-PLAN.md
- [x] 138-06-PLAN.md

**Wave 1**

- [x] 138-01-PLAN.md — Prove safe Git baseline collection, then inventory branches, tags, and worktrees.

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 138-02-PLAN.md — Enumerate every open pull request and issue through complete redaction-safe pagination.

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 138-03-PLAN.md — Inventory maintained follow-ups and generate the canonical dated live ledger.

**Wave 7** *(gap closure; blocked on 138-06)*

- [x] 138-07-PLAN.md — Buffer and validate both GitHub namespaces before rendering actionable dispositions.

**Wave 8** *(gap closure; blocked on Wave 7)*

- [x] 138-08-PLAN.md — Fail branch, tag, and worktree domains closed when stable evidence IDs cannot be generated.

**Wave 9** *(gap closure; blocked on Wave 8)*

- [x] 138-09-PLAN.md — Preserve maintained selector failures and make hostile tracked paths NUL-safe and render-safe.

**Wave 10** *(gap closure; blocked on Wave 9)*

- [x] 138-10-PLAN.md — Prove live writer safety and implement fail-closed immutable-snapshot drift classification.

**Wave 11** *(gap closure; blocked on Wave 10)*

- [x] 138-11-PLAN.md — Publish the ledger-only immutable snapshot and hand its bounded currentness relation to the normal verifier.

### Phase 139: Required Truth Reconciliation

**Goal**: Maintainers can rely on one exact-SHA, repository-owned acceptance and release truth across gates, workflows, planning, and release records.
**Depends on**: Phase 138
**Requirements**: CI-08, QUAL-05, HYGIENE-05, HYGIENE-06, TRUTH-03, TRUTH-04, TRUTH-05
**Success Criteria** (what must be TRUE):

  1. Repository-owned acceptance checks enforce `mix ci` and repository hygiene for the reconciled baseline, including no unresolved hygiene `BLOCK` and an explicit disposition for every `WARN`.
  2. Repository-owned acceptance logic identifies the exact synchronized `main` SHA and fails closed without canonical same-SHA CI and Release no-publish evidence. The live evidence itself is accepted at the Phase 140 entry gate.
  3. A maintainer can distinguish required acceptance from supplemental OIDF evidence, whose retained findings are redacted and explicitly non-certifying.
  4. A maintainer can trace the current public release from its source SHA through CI, release run, tag, package checksum, Hex package, and maintained release records without rewriting historical evidence.
  5. Maintained planning and release records agree on the current milestone and release posture, while Release Please ownership, protected exact-ref publishing, full-SHA action pins, and manifest-bound artifact proof remain intact.

**Plans**: 9/9 plans executed

Plans:

**Wave 1**

- [x] 139-01-PLAN.md — Prove one exact-SHA hygiene and workflow acceptance path end to end.

**Wave 2** *(after tracer proof)*

- [x] 139-02-PLAN.md — Restore the demonstrated shell-lint and proof-quality gates.
- [x] 139-03-PLAN.md — Pin Release no-publish structure and the complete action-reference surface.
- [x] 139-04-PLAN.md — Reconcile maintained planning, release, hygiene, and supplemental truth.

**Wave 3** *(after local gate repair)*

- [x] 139-05-PLAN.md — Refresh the immutable inventory and bind Phase 139 lifecycle/main currentness.

**Wave 4** *(after exact hygiene and currentness contracts)*

- [x] 139-06-PLAN.md — Land sealed repository writes on main and retain final live acceptance externally.

**Wave 5** *(after every implementation expansion)*

- [x] 139-07-PLAN.md — Activate the two-boundary Phase 139 finalizer and durable recovery path.

**Wave 6** *(verification gap closure; after 139-07)*

- [x] 139-08-PLAN.md — Bind every non-host verification gap and all nineteen completed-plan prohibitions to focused executable proof.

**Wave 7** *(terminal lifecycle gap closure; after 139-08)*

- [x] 139-09-PLAN.md — Prove the supported Phase 139 lifecycle portably in required CI and retain live exact-SHA acceptance as the blocking transition gate.

### Phase 140: Bounded Operational Loose-End Triage

**Goal**: Maintainers close only safe, evidence-backed maintenance gaps and retain a clear, recoverable disposition for everything else.
**Depends on**: Phase 139
**Requirements**: CI-06, CI-07, BASE-03, TRIAGE-03, LOOSE-02, LOOSE-03
**Success Criteria** (what must be TRUE):

  1. A maintainer can see exactly why every credible finding is fixed now, deferred with a trigger, retained as historical evidence, already resolved, or out of scope.
  2. Any authorized cleanup names exact targets and leaves uncommitted work, intentional refs, and historical release evidence intact.
  3. Each dependency-update pull request has its own compatibility, security, and required-gate assessment rather than being handled as part of a bulk campaign.
  4. Blockers, regressions, contradictions, stale actionable artifacts, and small high-confidence maintenance gaps are closed when proof supports it; speculative or feature-sized work is explicitly deferred.

**Plans**: TBD

**Entry gate**: The existing blocking Phase 140 `plan:pre` hook must first produce and validate the Phase 139 exact-SHA acceptance receipt. CI-06 and CI-07 remain pending until that receipt proves synchronized refs and canonical same-SHA workflow results. This ordering lets Phase 139 verify the repository-owned acceptance contract, transition normally, and have the live evidence gate run before any Phase 140 planning begins.

### Phase 141: Maintenance-Baseline Closure

**Goal**: Maintainers receive a durable final-baseline handoff and Lockspire resumes its sustaining GA release train without false completion claims.
**Depends on**: Phase 140
**Requirements**: BASE-04, BASE-05
**Success Criteria** (what must be TRUE):

  1. A maintainer can inspect a dated baseline record connecting final Git state, local gates, required workflow runs, release evidence, loose-end dispositions, and explicit deferrals to exact SHAs and sources.
  2. GSD project, roadmap, requirements, state, and milestone records describe the same completed v1.38 posture and the next sustaining GA release-train action.
  3. A maintainer can distinguish verified closure from deferred conformance, feature, cleanup, or release-publication work that remains outside this milestone.

**Plans**: TBD

## Progress

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 138. Baseline Inventory & Evidence Taxonomy | 38/38 | Complete    | 2026-09-25 |
| 139. Required Truth Reconciliation | 9/9 | In Progress|  |
| 140. Bounded Operational Loose-End Triage | 0/TBD | Not started | - |
| 141. Maintenance-Baseline Closure | 0/TBD | Not started | - |
