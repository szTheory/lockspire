# Roadmap: Lockspire

## Shipped Milestones

- [x] **v1.0 milestone** - completed 2026-04-23 ([archive](milestones/v1.0-ROADMAP.md)); delivered the six-phase embedded OAuth/OIDC provider scope with all 25 plans completed and 42 recorded tasks. Public release posture remains `v0.1` preview pending repo-wide QA cleanup, trusted Hex publish verification, and repeated green release gates.

## Active Milestone

### v1.1 Release Hardening

**Status:** All v1.1 plans complete; fresh milestone audit rerun pending
**Phases:** 7-13
**Total Plans:** 14 completed, 0 pending

**Overview**

Lockspire’s next milestone is intentionally polish-first. The library already has the core embedded provider wedge; the current velocity bottleneck is release trust, not missing baseline OAuth/OIDC surface. This milestone focuses on making QA, release automation, and supported-surface claims boring and repeatable while keeping new protocol scope out.

### Phase 7: Repo Truth QA

**Goal**: Get repo-visible quality gates green from actual source state so preview releases do not rely on carve-outs or undocumented exceptions.
**Depends on**: Phase 6 archive
**Plans**: 4 plans

Plans:

- [x] 07-01: Clean runtime and security-sensitive source so strict Credo passes from source truth
- [x] 07-02: Make `mix qa` truthful for Mix tasks and generators by fixing Dialyzer scope and warning sources
- [x] 07-03: Keep `mix test.integration` and `mix test.phase3` deterministic, sharp, and non-duplicative
- [x] 07-04: Align `mix ci`, docs, workflows, and contract tests around the maintained contributor gate

**Details:**
This phase closes the repo-truth gap between the documented release bar and what the current tree actually passes. It should prefer boring fixes, small contract clarifications, and explicit gate ownership over new feature work.

### Phase 8: Trusted Release Path

**Goal**: Prove that release automation, maintainer steps, and protected Hex publish workflow all match each other.
**Depends on**: Phase 7
**Plans**: 3 plans

Plans:

- [x] 08-01: Verify and harden the trusted release workflow, protected environment, and secret wiring
- [x] 08-02: Align package metadata, release automation, and maintainer docs to one reviewable publish path
- [x] 08-03: Add or tighten automated release-readiness checks that fail when workflow and docs drift

**Details:**
This phase is about trustable release mechanics, not public `1.0` claims. The outcome should be a preview release path that is easy to audit and hard to accidentally bypass.

### Phase 9: Preview Posture Lock

**Goal**: Freeze the public preview posture around what the repo proves today and document PAR as the next milestone candidate without starting it here or implying current v1.1 support.
**Depends on**: Phase 8
**Plans**: 2 plans

Plans:

- [x] 09-01: Tighten supported-surface, security, and onboarding docs to the proven preview scope
- [x] 09-02: Record PAR as the next protocol-expansion milestone, explicitly not implemented in v1.1, and close remaining preview-posture drift tests

**Details:**
This phase keeps public claims honest, prevents accidental scope inflation, and creates a clean handoff into the later PAR milestone.

### Phase 10: Contributor Gate Recovery

**Goal**: Restore the maintained contributor gate to repo truth and record phase-level closure for the release-gate requirements that the audit reopened.
**Depends on**: Phase 9 plus `v1.1-MILESTONE-AUDIT.md`
**Plans**: 2 plans
**Requirements**: GATE-01, GATE-02, GATE-03
**Gap Closure**: Closes the broken maintained contributor gate flow plus the missing Phase 07 requirement-verification record.

Plans:

- [x] 10-01: Restore the broken contributor gate and capture a fresh end-to-end rerun record
- [x] 10-02: Backfill Phase 07 verification artifacts and close GATE traceability

**Details:**
This phase should fix the formatting drift that currently stops `mix ci` inside `mix qa`, rerun the maintained repo-truth gate end to end, and write the verification artifacts needed to close the reopened Phase 07 requirements defensibly.

### Phase 11: Trusted Release Proof Closure

**Goal**: Close the trusted protected release path with the required external proof and record phase-level verification for the reopened release-path requirements.
**Depends on**: Phase 10
**Plans**: 2 plans
**Requirements**: RELS-01, RELS-02, RELS-03
**Gap Closure**: Closes the partial trusted protected publish flow plus the missing Phase 08 requirement-verification record.

Plans:

- [x] 11-01: Capture the approved protected release proof and reconcile any live GitHub environment drift
- [x] 11-02: Backfill Phase 08 verification artifacts and close RELS traceability

**Details:**
This phase gathered the required protected GitHub environment proof, recorded the approved `hex-publish` run evidence from the canonical `push` lane, and wrote the verification artifacts that close the reopened Phase 08 release-path requirements.

### Phase 12: Phase 11 Verification Closure

**Goal**: Write the missing Phase 11 verification rollup so the trusted release proof closure phase is fully verified and the milestone can pass re-audit without traceability caveats.
**Depends on**: Phase 11 plus `v1.1-MILESTONE-AUDIT.md`
**Plans**: 1 plan
**Requirements**: RELS-01, RELS-02, RELS-03
**Gap Closure**: Closes the missing Phase 11 verification artifact that leaves the trusted release requirements partial in the milestone audit.

Plans:

- [x] 12-01: Write `11-VERIFICATION.md`, re-anchor RELS traceability on Phase 11 evidence, and prepare the milestone for re-audit

**Details:**
This phase is intentionally narrow. It should consolidate the existing Phase 11 protected release proof, summaries, and prior Phase 08 verification evidence into a normal phase-level verification rollup without reopening product scope or altering the trusted release path itself.

### Phase 13: Milestone Closure Ledger Finalization

**Goal**: Close the final milestone handoff gap by writing the missing Phase 12 verification artifact and reconciling the canonical RELS ledger with the passed release-closure evidence.
**Depends on**: Phase 12 plus `v1.1-MILESTONE-AUDIT.md`
**Plans**: 1 plan
**Requirements**: RELS-01, RELS-02, RELS-03
**Gap Closure**: Closes the missing Phase 12 verification artifact plus the stale RELS requirement ledger rows that still block milestone closeout.

Plans:

- [x] 13-01: Write `12-VERIFICATION.md`, update `RELS-01` through `RELS-03` in `.planning/REQUIREMENTS.md`, and re-anchor the milestone closeout chain

**Details:**
This phase should stay process-only. It closes the last audit-reported contradiction between the passed Phase 11/12 closure evidence and the canonical planning ledger, then leaves the milestone ready for a fresh audit without reopening release workflow implementation.

## Next Milestone Candidate

After v1.1 gap closure work passes re-audit, the default next milestone is **v1.2 PAR Foundation**. It should extend the current authorization-code + PKCE path with pushed authorization requests before broader candidates like dynamic registration or device flow. PAR is not implemented and not supported in v1.1; it remains planning metadata only until the next milestone starts.

## Next Up

- Re-run `$gsd-audit-milestone` after Phase 13 closes the remaining verification/ledger handoff.
- Upgrade the pinned `googleapis/release-please-action` before the GitHub Node.js 20 runner deprecation cutoff.
- Defer optional Nyquist completeness cleanup for missing `10-VALIDATION.md` and `12-VALIDATION.md` until after v1.1 archive unless archive criteria are tightened.
- Keep dynamic client registration, device flow, sender-constrained tokens, and broader ecosystem expansion out of the v1.1 scope.
- Keep PAR out of current support-facing docs, examples, and feature claims until v1.2 work actually begins.

## Reference

- Milestone archive: [`.planning/milestones/v1.0-ROADMAP.md`](milestones/v1.0-ROADMAP.md)
- Requirements archive: [`.planning/milestones/v1.0-REQUIREMENTS.md`](milestones/v1.0-REQUIREMENTS.md)
- Active requirements: [`.planning/REQUIREMENTS.md`](REQUIREMENTS.md)
- Sigra ecosystem note: [`.planning/ECOSYSTEM-SIGRA.md`](ECOSYSTEM-SIGRA.md)
