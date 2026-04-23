# Roadmap: Lockspire

## Shipped Milestones

- [x] **v1.0 milestone** - completed 2026-04-23 ([archive](milestones/v1.0-ROADMAP.md)); delivered the six-phase embedded OAuth/OIDC provider scope with all 25 plans completed and 42 recorded tasks. Public release posture remains `v0.1` preview pending repo-wide QA cleanup, trusted Hex publish verification, and repeated green release gates.

## Active Milestone

### v1.1 Release Hardening

**Status:** Planned 2026-04-23
**Phases:** 7-9
**Total Plans:** 9

**Overview**

Lockspire’s next milestone is intentionally polish-first. The library already has the core embedded provider wedge; the current velocity bottleneck is release trust, not missing baseline OAuth/OIDC surface. This milestone focuses on making QA, release automation, and supported-surface claims boring and repeatable while keeping new protocol scope out.

### Phase 7: Repo Truth QA

**Goal**: Get repo-visible quality gates green from actual source state so preview releases do not rely on carve-outs or undocumented exceptions.
**Depends on**: Phase 6 archive
**Plans**: 4 plans

Plans:

- [x] 07-01: Clean runtime and security-sensitive source so strict Credo passes from source truth
- [ ] 07-02: Make `mix qa` truthful for Mix tasks and generators by fixing Dialyzer scope and warning sources
- [ ] 07-03: Keep `mix test.integration` and `mix test.phase3` deterministic, sharp, and non-duplicative
- [ ] 07-04: Align `mix ci`, docs, workflows, and contract tests around the maintained contributor gate

**Details:**
This phase closes the repo-truth gap between the documented release bar and what the current tree actually passes. It should prefer boring fixes, small contract clarifications, and explicit gate ownership over new feature work.

### Phase 8: Trusted Release Path

**Goal**: Prove that release automation, maintainer steps, and protected Hex publish workflow all match each other.
**Depends on**: Phase 7
**Plans**: 3 plans

Plans:

- [ ] 08-01: Verify and harden the trusted release workflow, protected environment, and secret wiring
- [ ] 08-02: Align package metadata, release automation, and maintainer docs to one reviewable publish path
- [ ] 08-03: Add or tighten automated release-readiness checks that fail when workflow and docs drift

**Details:**
This phase is about trustable release mechanics, not public `1.0` claims. The outcome should be a preview release path that is easy to audit and hard to accidentally bypass.

### Phase 9: Preview Posture Lock

**Goal**: Freeze the public preview posture around what the repo proves today and document PAR as the next milestone without starting it here.
**Depends on**: Phase 8
**Plans**: 2 plans

Plans:

- [ ] 09-01: Tighten supported-surface, security, and onboarding docs to the proven preview scope
- [ ] 09-02: Record PAR as the next protocol-expansion milestone and close remaining preview-posture drift tests

**Details:**
This phase keeps public claims honest, prevents accidental scope inflation, and creates a clean handoff into the later PAR milestone.

## Next Milestone Candidate

After v1.1, the default next milestone is **v1.2 PAR Foundation**. It should extend the current authorization-code + PKCE path with pushed authorization requests before broader candidates like dynamic registration or device flow.

## Next Up

- Start execution with `$gsd-execute-phase 7`.
- Keep dynamic client registration, device flow, sender-constrained tokens, and broader ecosystem expansion out of the v1.1 scope.

## Reference

- Milestone archive: [`.planning/milestones/v1.0-ROADMAP.md`](milestones/v1.0-ROADMAP.md)
- Requirements archive: [`.planning/milestones/v1.0-REQUIREMENTS.md`](milestones/v1.0-REQUIREMENTS.md)
- Active requirements: [`.planning/REQUIREMENTS.md`](REQUIREMENTS.md)
- Sigra ecosystem note: [`.planning/ECOSYSTEM-SIGRA.md`](ECOSYSTEM-SIGRA.md)
