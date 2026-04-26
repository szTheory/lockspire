# Roadmap: Lockspire

## Shipped Milestones

- [x] **v1.3 milestone** - completed 2026-04-24 ([archive](milestones/v1.3-ROADMAP.md), [requirements](milestones/v1.3-REQUIREMENTS.md)); delivered the four-phase PAR Policy milestone with all 8 plans complete, all 6 requirements closed, and consolidated integration proof for global/client/effective policy enforcement.
- [x] **v1.2 milestone** - completed 2026-04-24 ([archive](milestones/v1.2-ROADMAP.md), [requirements](milestones/v1.2-REQUIREMENTS.md), [audit](milestones/v1.2-MILESTONE-AUDIT.md)); delivered the three-phase PAR foundation milestone with all 8 plans complete, all 5 requirements closed, and the deferred Release Please runtime warning removed without widening the preview support contract.
- [x] **v1.1 milestone** - completed 2026-04-24 ([archive](milestones/v1.1-ROADMAP.md), [requirements](milestones/v1.1-REQUIREMENTS.md), [audit](milestones/v1.1-MILESTONE-AUDIT.md)); delivered the seven-phase release-hardening milestone with all 15 plans complete, all 9 v1.1 requirements closed, and protected release proof/traceability reconciled.
- [x] **v1.0 milestone** - completed 2026-04-23 ([archive](milestones/v1.0-ROADMAP.md)); delivered the six-phase embedded OAuth/OIDC provider scope with all 25 plans completed and 42 recorded tasks.

## Active Milestone

## v1.4 JAR and Request Objects

**Status:** Executing  
**Phases:** 21-24  
**Total Plans:** 3 (Phase 21)  
**Requirements:** 6 (`JAR-01`-`JAR-06`)

### Overview

This milestone expands Lockspire's interoperability by adding support for JWT Secured Authorization Requests (JAR - [RFC 9101](https://datatracker.ietf.org/doc/html/rfc9101)). It will focus on JAR-by-value support, request object signing and validation, and integration with the existing PAR path.

### Phase 21: JAR Foundation and Request Validation

**Goal**: Implement the core logic for parsing and validating JWT request objects, including signature verification and security claims checks.  
**Depends on**: Milestone v1.3 archive  
**Plans**: 3 plans  
**Requirements**: `JAR-01`, `JAR-02`, `JAR-03`

Plans:

- [x] 21-01: Define JAR data structure and unverified decoding logic
- [x] 21-02: Implement signature verification using client keys
- [x] 21-03: Implement RFC 9101 security claims validation

### Phase 22: Request Object Integration

**Goal**: Integrate request objects into the authorization path, allowing them to be passed by value in `/authorize` and via PAR.

**Depends on**: Phase 21 (JAR Foundation)
**Plans**: 7 plans
**Requirements**: `JAR-01`

Plans:

- [x] 22-01: Jar primitive hardening (WR-01 typ-check, WR-02 aud-list strict, WR-03 :max_age opt)
- [x] 22-02: Add Lockspire.Config.jar_max_age_seconds/0 accessor (default 600)
- [x] 22-03: Create Lockspire.JarTestHelpers test-support module
- [x] 22-04: RequestObject orchestrator + AuthorizationRequest splice + protocol-seam reason-code matrix
- [ ] 22-05: PushedAuthorizationRequest /par splice + D-10 ClientAuth-and-JAR independence proofs
- [x] 22-06: AuthorizeController browser-boundary proofs (rejection page + redirect-safe handoff)
- [x] 22-07: Phase 15 e2e surgical extension (one new JAR-via-PAR-via-/authorize branch per D-21)

### Phase 23: JAR Operator UX and Discovery

**Goal**: Expose JAR capabilities in discovery metadata and provide operator controls for required-JAR policies.

**Plans:** 6 plans

**Requirements:** `JAR-05`, `JAR-06`

Plans:

- [ ] 23-01-PLAN.md — Publish truthful JAR discovery metadata
- [ ] 23-02-PLAN.md — Persist the global JAR policy default
- [ ] 23-03-PLAN.md — Resolve and administer global JAR enforcement
- [ ] 23-04-PLAN.md — Persist and validate client JAR overrides
- [ ] 23-05-PLAN.md — Add the global JAR policy admin page
- [ ] 23-06-PLAN.md — Add client JAR override workflow and docs

### Phase 24: Verification and Milestone Closure

**Goal**: Final end-to-end verification and traceability for Milestone v1.4.

### Phase 24: Verification and Milestone Closure

**Goal**: Final end-to-end verification and traceability for Milestone v1.4.

**Depends on**: Phase 23 (JAR Operator UX and Discovery)

**Plans:** 2 closure plans

**Requirements:** `JAR-01`, `JAR-02`, `JAR-03`, `JAR-05`, `JAR-06`

Plans:

- [x] 24-01-PLAN.md — Produce final verification and validation reports for v1.4
- [x] 24-02-PLAN.md — Reconcile traceability, planning state, and milestone closeout records

Success criteria:

1. Every shipped JAR requirement has exact traceability to implementation and tests, with JAR-04 remaining deferred.
2. The milestone closure evidence is durable, aligned with the verification/validation artifacts, and recorded in the phase 24 summaries.
3. The roadmap and state reflect the completed milestone without presenting Phase 24 as an open next action.

## Reference

- Milestone archive: [`.planning/milestones/v1.3-ROADMAP.md`](milestones/v1.3-ROADMAP.md)
- Requirements archive: [`.planning/milestones/v1.3-REQUIREMENTS.md`](milestones/v1.3-REQUIREMENTS.md)
- Milestone ledger: [`.planning/MILESTONES.md`](MILESTONES.md)
- Sigra ecosystem note: [`.planning/ECOSYSTEM-SIGRA.md`](ECOSYSTEM-SIGRA.md)
