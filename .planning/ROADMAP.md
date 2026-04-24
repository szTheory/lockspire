# Roadmap: Lockspire

## Shipped Milestones

- [x] **v1.3 milestone** - completed 2026-04-24; delivered the four-phase PAR Policy milestone with all 8 plans complete, all 6 requirements closed, and consolidated integration proof for global/client/effective policy enforcement.
- [x] **v1.2 milestone** - completed 2026-04-24 ([archive](milestones/v1.2-ROADMAP.md), [requirements](milestones/v1.2-REQUIREMENTS.md), [audit](milestones/v1.2-MILESTONE-AUDIT.md)); delivered the three-phase PAR foundation milestone with all 8 plans complete, all 5 requirements closed, and the deferred Release Please runtime warning removed without widening the preview support contract.
- [x] **v1.1 milestone** - completed 2026-04-24 ([archive](milestones/v1.1-ROADMAP.md), [requirements](milestones/v1.1-REQUIREMENTS.md), [audit](milestones/v1.1-MILESTONE-AUDIT.md)); delivered the seven-phase release-hardening milestone with all 15 plans complete, all 9 v1.1 requirements closed, and protected release proof/traceability reconciled. Residual tech debt is limited to missing `10/12/13-VALIDATION.md` files and the `release-please-action` Node 20 deprecation warning.
- [x] **v1.0 milestone** - completed 2026-04-23 ([archive](milestones/v1.0-ROADMAP.md)); delivered the six-phase embedded OAuth/OIDC provider scope with all 25 plans completed and 42 recorded tasks. Public release posture remains `v0.1` preview pending repo-wide QA cleanup, trusted Hex publish verification, and repeated green release gates.

## Active Milestone

## v1.3 PAR Policy Controls

**Status:** Completed  
**Phases:** 17-20  
**Total Plans:** 8  
**Requirements:** 6 (`PARPOL-01`-`PARPOL-06`)

### Overview

This milestone raises Lockspire's maturity along the already-shipped PAR path instead of opening a new protocol family. The work stays narrow: add global and per-client PAR requirement controls, enforce the effective policy on the authorization path, expose the policy through operator/admin surfaces, and close with repo-truth proof that the implementation and public support contract still match.

### Phase 17: Effective PAR Policy Model

**Goal**: Add the durable policy model for PAR requirements at global and per-client scope, and define one effective-policy resolution path for runtime and admin consumers.  
**Depends on**: Phase 16 archive  
**Plans**: 2 plans  
**Requirements**: `PARPOL-01`, `PARPOL-02`

Plans:

- [x] 17-01: Add global PAR requirement configuration and durable policy plumbing
- [x] 17-02: Add per-client PAR requirement state plus effective-policy resolution tests

Success criteria:

1. Operators can express a global PAR requirement without changing host-owned account or login seams.
2. Lockspire can resolve one effective PAR policy for a given authorization request and client.
3. Runtime consumers and operator surfaces can rely on the same policy-resolution path.

### Phase 18: Authorization Path Enforcement

**Goal**: Enforce the effective PAR policy on `/authorize` while preserving the existing auth-code + PKCE path for clients that do not require PAR.  
**Depends on**: Phase 17  
**Plans**: 2 plans  
**Requirements**: `PARPOL-03`

Plans:

- [x] 18-01: Apply effective PAR policy in authorization validation and rejection paths
- [x] 18-02: Add integration proof for required-PAR and optional-PAR authorization flows

Success criteria:

1. Direct authorization requests are rejected when the effective policy requires PAR and no valid Lockspire-issued `request_uri` is supplied.
2. PAR-backed auth-code + PKCE flow succeeds unchanged for clients under required-PAR policy.
3. Clients not subject to a PAR requirement keep the existing supported browser flow.

### Phase 19: Operator UX and Truthful Surface

**Goal**: Expose PAR policy clearly through Lockspire's admin surfaces and keep public support wording truthful about the shipped request-path slice.  
**Depends on**: Phase 18  
**Plans**: 2 plans  
**Requirements**: `PARPOL-04`, `PARPOL-05`

Plans:

- [x] 19-01: Add admin workflows for viewing and managing global and per-client PAR policy
- [x] 19-02: Update discovery/docs/contract tests so support claims match the shipped policy slice

Success criteria:

1. Operators can inspect and manage PAR requirement state through the existing admin surface.
2. Discovery metadata and support-facing docs do not imply JAR-by-value, generic external `request_uri`, DCR, device flow, or hosted-auth support.
3. Repo-truth tests pin the supported policy slice tightly enough to catch documentation drift.

### Phase 20: Verification and Milestone Closure

**Goal**: Close the milestone with explicit protocol, integration, and operator-surface verification plus requirements traceability.  
**Depends on**: Phase 19  
**Plans**: 2 plans  
**Requirements**: `PARPOL-06`

Plans:

- [x] 20-01: Create consolidated end-to-end integration verification test for v1.3
- [x] 20-02: Reconcile traceability, verification artifacts, and milestone-close evidence

Success criteria:

1. Automated proof covers optional-PAR, required-PAR, and rejected direct-request scenarios.
2. Cross-phase evidence shows the policy model, enforcement, admin UX, and support truth are wired together correctly.
3. The milestone can close without reopening JAR, DCR, device flow, or release-lane scope.

## Reference

- Milestone archive: [`.planning/milestones/v1.0-ROADMAP.md`](milestones/v1.0-ROADMAP.md)
- Requirements archive: [`.planning/milestones/v1.0-REQUIREMENTS.md`](milestones/v1.0-REQUIREMENTS.md)
- Latest archive set: [`.planning/milestones/v1.2-ROADMAP.md`](milestones/v1.2-ROADMAP.md), [`.planning/milestones/v1.2-REQUIREMENTS.md`](milestones/v1.2-REQUIREMENTS.md), [`.planning/milestones/v1.2-MILESTONE-AUDIT.md`](milestones/v1.2-MILESTONE-AUDIT.md)
- Milestone ledger: [`.planning/MILESTONES.md`](MILESTONES.md)
- Sigra ecosystem note: [`.planning/ECOSYSTEM-SIGRA.md`](ECOSYSTEM-SIGRA.md)
