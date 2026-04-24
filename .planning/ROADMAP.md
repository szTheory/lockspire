# Roadmap: Lockspire

## Shipped Milestones

- [x] **v1.3 milestone** - completed 2026-04-24 ([archive](milestones/v1.3-ROADMAP.md), [requirements](milestones/v1.3-REQUIREMENTS.md)); delivered the four-phase PAR Policy milestone with all 8 plans complete, all 6 requirements closed, and consolidated integration proof for global/client/effective policy enforcement.
- [x] **v1.2 milestone** - completed 2026-04-24 ([archive](milestones/v1.2-ROADMAP.md), [requirements](milestones/v1.2-REQUIREMENTS.md), [audit](milestones/v1.2-MILESTONE-AUDIT.md)); delivered the three-phase PAR foundation milestone with all 8 plans complete, all 5 requirements closed, and the deferred Release Please runtime warning removed without widening the preview support contract.
- [x] **v1.1 milestone** - completed 2026-04-24 ([archive](milestones/v1.1-ROADMAP.md), [requirements](milestones/v1.1-REQUIREMENTS.md), [audit](milestones/v1.1-MILESTONE-AUDIT.md)); delivered the seven-phase release-hardening milestone with all 15 plans complete, all 9 v1.1 requirements closed, and protected release proof/traceability reconciled.
- [x] **v1.0 milestone** - completed 2026-04-23 ([archive](milestones/v1.0-ROADMAP.md)); delivered the six-phase embedded OAuth/OIDC provider scope with all 25 plans completed and 42 recorded tasks.

## Active Milestone

## v1.4 JAR and Request Objects

**Status:** Planning  
**Phases:** 21-24  
**Total Plans:** 3  
**Requirements:** JAR-01, JAR-02, JAR-03, JAR-05, JAR-06

### Overview

This milestone expands Lockspire's interoperability by adding support for JWT Secured Authorization Requests (JAR - [RFC 9101](https://datatracker.ietf.org/doc/html/rfc9101)). It will focus on JAR-by-value support, request object signing and validation, and integration with the existing PAR path.

### Phase 21: JAR Foundation and Request Validation

**Goal**: Implement the core logic for parsing and validating JWT request objects, including signature verification and security claims checks.

**Plans:** 3 plans

Plans:
- [ ] 21-01-PLAN.md — JAR Data Structure and Initial Parsing
- [ ] 21-02-PLAN.md — Signature Verification
- [ ] 21-03-PLAN.md — Security Claims Validation

### Phase 22: Request Object Integration

**Goal**: Integrate request objects into the authorization path, allowing them to be passed by value in `/authorize` and via PAR.

### Phase 23: JAR Operator UX and Discovery

**Goal**: Expose JAR capabilities in discovery metadata and provide operator controls for required-JAR policies.

### Phase 24: Verification and Milestone Closure

**Goal**: Final end-to-end verification and traceability for Milestone v1.4.

## Reference

- Milestone archive: [`.planning/milestones/v1.3-ROADMAP.md`](milestones/v1.3-ROADMAP.md)
- Requirements archive: [`.planning/milestones/v1.3-REQUIREMENTS.md`](milestones/v1.3-REQUIREMENTS.md)
- Milestone ledger: [`.planning/MILESTONES.md`](MILESTONES.md)
- Sigra ecosystem note: [`.planning/ECOSYSTEM-SIGRA.md`](ECOSYSTEM-SIGRA.md)
