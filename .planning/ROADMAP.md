# Roadmap: Lockspire

## Shipped Milestones

- [x] **v1.1 milestone** - completed 2026-04-24 ([archive](milestones/v1.1-ROADMAP.md), [requirements](milestones/v1.1-REQUIREMENTS.md), [audit](milestones/v1.1-MILESTONE-AUDIT.md)); delivered the seven-phase release-hardening milestone with all 15 plans complete, all 9 v1.1 requirements closed, and protected release proof/traceability reconciled. Residual tech debt is limited to missing `10/12/13-VALIDATION.md` files and the `release-please-action` Node 20 deprecation warning.
- [x] **v1.0 milestone** - completed 2026-04-23 ([archive](milestones/v1.0-ROADMAP.md)); delivered the six-phase embedded OAuth/OIDC provider scope with all 25 plans completed and 42 recorded tasks. Public release posture remains `v0.1` preview pending repo-wide QA cleanup, trusted Hex publish verification, and repeated green release gates.

## Active Milestone

### v1.2 PAR Foundation

**Status:** Not started; milestone initialized on 2026-04-24
**Phase range:** 14-16
**Requirements:** 5 mapped, 0 unmapped

**Milestone goal:** Add pushed authorization requests as a narrow extension of the existing authorization code + PKCE flow while keeping Lockspire embedded, truthful about scope, and boring to release.

### Phase 14: Pushed Request Intake

**Goal**: Add a dedicated PAR endpoint, reuse direct client authentication, and issue durable opaque `request_uri` references for pushed authorization requests.
**Depends on**: Phase 13 archive
**Plans**: 3 plans
**Requirements**: PAR-01

Plans:

- [ ] 14-01: Add pushed authorization request storage/domain lifecycle with opaque request URI issuance and expiry
- [ ] 14-02: Add the PAR web endpoint and reuse Lockspire's direct-call client authentication and request validation rules
- [ ] 14-03: Add protocol tests for PAR success and request-intake error handling

**Success criteria:**
1. A client can `POST` a valid pushed authorization request and receive `201 Created` with `request_uri` and `expires_in`.
2. The issued `request_uri` is generated opaquely and stored with the client binding and expiry needed for later resolution.
3. Invalid PAR submissions fail safely with standards-aligned error handling instead of creating partial request state.

### Phase 15: Authorization Consumption and Truthful Surface

**Goal**: Let `/authorize` consume PAR-issued request references safely and make discovery/docs truthful about exactly the supported PAR slice.
**Depends on**: Phase 14
**Plans**: 3 plans
**Requirements**: PAR-02, PAR-03

Plans:

- [ ] 15-01: Teach the authorization pipeline to resolve PAR-issued `request_uri` values with expiry, client-binding, and single-use enforcement
- [ ] 15-02: Publish truthful PAR discovery metadata and update support-facing docs without implying broader request-object or adjacent flow support
- [ ] 15-03: Add end-to-end tests for the PAR-backed authorization code + PKCE flow and truth-surface contract coverage

**Success criteria:**
1. A client can start with PAR and complete the existing authorization code + PKCE flow by presenting the issued `request_uri` at `/authorize`.
2. Expired, replayed, or wrong-client `request_uri` values are rejected safely and do not reopen the request path.
3. Discovery metadata publishes `pushed_authorization_request_endpoint` only when supported.
4. README, supported-surface docs, and related contract tests describe PAR as implemented without implying JAR-by-value, DCR, or device-flow support.

### Phase 16: Verification and Release Runtime Hygiene

**Goal**: Close milestone verification for the PAR wedge and remove the known deprecated release runtime warning without regressing the trusted preview release path.
**Depends on**: Phase 15
**Plans**: 2 plans
**Requirements**: PAR-04, RELS-04

Plans:

- [ ] 16-01: Verify PAR success and negative paths, then record milestone traceability and closure evidence
- [ ] 16-02: Remove the deprecated GitHub Actions release runtime warning while keeping release docs, workflow behavior, and preview posture aligned

**Success criteria:**
1. Automated coverage proves PAR success, expiry, replay rejection, client binding, and discovery truth.
2. Requirement traceability and verification artifacts are complete enough to close the milestone without inference gaps.
3. The checked-in preview release path no longer emits the known deprecated runtime warning.
4. Maintainer release guidance still matches the checked-in workflow after the runtime-hygiene change.

## Milestone Summary

**Key decisions:**

- Keep v1.2 narrow around PAR rather than broadening into JAR-by-value, DCR, device flow, or sender-constrained token work.
- Treat the release-runtime warning as milestone scope instead of indefinite background debt so the preview trust posture does not regress while PAR lands.
- Continue phase numbering from the archived v1.1 milestone, so v1.2 starts at Phase 14.

**Deferred tech debt:**

- Backfill `10-VALIDATION.md`, `12-VALIDATION.md`, and `13-VALIDATION.md` only if Nyquist completeness is explicitly required during milestone execution.

## Reference

- Milestone archive: [`.planning/milestones/v1.0-ROADMAP.md`](milestones/v1.0-ROADMAP.md)
- Requirements archive: [`.planning/milestones/v1.0-REQUIREMENTS.md`](milestones/v1.0-REQUIREMENTS.md)
- Latest archive set: [`.planning/milestones/v1.1-ROADMAP.md`](milestones/v1.1-ROADMAP.md), [`.planning/milestones/v1.1-REQUIREMENTS.md`](milestones/v1.1-REQUIREMENTS.md), [`.planning/milestones/v1.1-MILESTONE-AUDIT.md`](milestones/v1.1-MILESTONE-AUDIT.md)
- Milestone ledger: [`.planning/MILESTONES.md`](MILESTONES.md)
- Sigra ecosystem note: [`.planning/ECOSYSTEM-SIGRA.md`](ECOSYSTEM-SIGRA.md)
