# Lockspire Roadmap

## Active Milestone

### v1.25 Support-Burden Reduction

**Status:** Active
**Phases:** 91-93
**Total Plans:** 9

### Overview

This milestone narrows Lockspire's remaining product risk from missing protocol breadth to support burden on advanced setup edges. The work stays inside already-shipped surfaces and focuses on truthful diagnostics, clearer operator/host guidance, and proof that the support story matches runtime behavior.

### Phase 91: `jwks_uri` Rotation Diagnostics And Remediation Truth

**Goal**: Make Lockspire's remote-JWKS rotation story diagnosable and supportable without source-diving.
**Depends on**: None
**Plans**: 3 plans

Plans:

- [ ] 91-01: Audit the shipped remote-`jwks_uri` runtime and identify the concrete failure and rollover states that need first-class diagnostic truth
- [ ] 91-02: Add or tighten operator/doctor/runtime diagnostics so adopters can distinguish unsupported rotation posture from transient or data-shape failures
- [ ] 91-03: Prove the supported rotation and failure-path story through repo-native tests and verification artifacts

**Details:**
Phase 91 focuses on the highest-friction advanced setup surface still called out by the arc: remote `jwks_uri` key rotation. The phase should produce one explicit product truth for what Lockspire supports, how it signals stale or broken remote key state, and what operators are expected to do next.

### Phase 92: Advanced Setup Support Truth

**Goal**: Make the canonical mTLS, logout propagation, and protected-route setup story explicit and internally consistent across docs and operator truth surfaces.
**Depends on**: Phase 91
**Plans**: 3 plans

Plans:

- [x] 92-01: Reconcile mTLS extraction prerequisites and host/infrastructure responsibilities across docs and maintainer guidance
- [x] 92-02: Tighten the canonical protected-route and logout propagation setup story so support boundaries and runtime guarantees are unambiguous
- [x] 92-03: Align operator/admin wording, diagnostics, and support docs around one shared advanced-setup truth contract

**Details:**
Phase 92 turns the remaining advanced setup tribal knowledge into explicit support truth. It should leave Lockspire with one coherent story for certificate extraction, sender-constraint enforcement, logout propagation semantics, and the shipped Phoenix API route pipeline, including what Lockspire owns versus what the host app or deployment environment owns.

### Phase 93: Support-Truth Proof And Milestone Closure

**Goal**: Lock the new support story in place with regression proof and milestone-close verification.
**Depends on**: Phase 92
**Plans**: 3 plans

Plans:

- [ ] 93-01: Add release-contract and documentation-truth assertions for the advanced setup support contract
- [ ] 93-02: Verify representative misconfiguration, remediation, and negative-path behavior across the touched support surfaces
- [ ] 93-03: Complete milestone-close verification and capture any intentionally deferred follow-on support work

**Details:**
Phase 93 makes the support-burden reduction milestone durable. The closeout should fail loudly if docs, diagnostics, or runtime behavior drift apart again, and it should capture any remaining support-heavy follow-ons without reopening protocol-expansion scope.

## Shipped Milestones

- [v1.24 client_secret_jwt](milestones/v1.24-ROADMAP.md) — shipped 2026-05-25; phases 88-90; 9 plans; Lockspire now supports a narrow `client_secret_jwt` direct-client slice on the shipped Lockspire-owned endpoints with sealed verifier material, strict HS256/replay/audience posture, and truthful DCR/discovery/admin/docs support.
- [v1.23 DCR Logout Metadata](milestones/v1.23-ROADMAP.md) — shipped 2026-05-24; phases 85-87; 9 plans; self-service clients can now create, read, and replace Lockspire's existing logout propagation metadata through DCR and RFC 7592 without widening the current logout truth model.
- [v1.22 DPoP Nonce Support](milestones/v1.22-ROADMAP.md) — shipped 2026-05-24; phases 82-84; 8 plans; automatic `DPoP-Nonce` challenge and retry support now covers Lockspire-owned `/token`, Lockspire-owned protected resources, and the shipped host Phoenix protected-route pipeline.

## Next Candidate

- Stop or reassess after `v1.25` unless real adopter evidence shows another concrete friction wedge worth solving inside Lockspire's current embedded-library scope.
