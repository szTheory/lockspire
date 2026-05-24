# Lockspire Roadmap

## Active Milestone

### v1.24 client_secret_jwt

**Status:** Planned 2026-05-24
**Phases:** 88-90
**Total Plans:** 9

**Goal:** Add a narrow `client_secret_jwt` authentication slice on Lockspire-owned direct-client endpoints while preserving strict replay, audience, algorithm, and support-truth posture.

## Proposed Phases

### Phase 88: Shared `client_secret_jwt` Runtime

**Goal**: Extend the shared direct-client authentication path so registered confidential clients can use `client_secret_jwt` consistently across the shipped Lockspire-owned direct-client endpoints.
**Requirements**: `AUTH-01`, `AUTH-02`
**Depends on**: None
**Plans**: 3 plans

Plans:

- [ ] 88-01: Add a narrow symmetric JWT verifier and explicit method routing in the shared direct-client auth pipeline
- [ ] 88-02: Enforce issuer-string audience, bounded lifetime, replay, and algorithm posture for `client_secret_jwt`
- [ ] 88-03: Prove valid and invalid `client_secret_jwt` behavior across representative Lockspire-owned direct-client surfaces

**Success criteria:**
1. A confidential client registered for `client_secret_jwt` can authenticate on the shared Lockspire-owned direct-client surfaces with one consistent runtime path.
2. Invalid signature, replay, audience, expiry, and algorithm cases fail closed as `invalid_client`.
3. JWT assertions are no longer implicitly routed through the `private_key_jwt` verifier.

### Phase 89: Registration, Discovery, And Admin Truth

**Goal**: Make operator, DCR, discovery, and admin truth match the shipped `client_secret_jwt` runtime slice without widening package boundaries or weakening secret posture.
**Requirements**: `REG-01`, `REG-02`, `META-01`
**Depends on**: Phase 88
**Plans**: 3 plans

Plans:

- [ ] 89-01: Extend client registration and DCR validation to accept coherent `client_secret_jwt` metadata for confidential clients only
- [ ] 89-02: Publish truthful discovery and endpoint auth-signing metadata for the new symmetric JWT slice
- [ ] 89-03: Align admin/operator surfaces with the same stored auth-method and signing-alg truth while preserving redaction

**Success criteria:**
1. Operator-created and self-service clients can persist coherent `client_secret_jwt` metadata without exposing raw secrets.
2. Discovery and endpoint metadata advertise `client_secret_jwt` only where the shared verifier actually runs.
3. Admin and DCR surfaces describe one consistent auth-method truth for the client record.

### Phase 90: Support Truth And Milestone Closure

**Goal**: Close the milestone with repo-native proof and documentation that describe the new symmetric JWT slice truthfully and narrowly.
**Requirements**: `META-02`, `PROOF-01`
**Depends on**: Phase 89
**Plans**: 3 plans

Plans:

- [ ] 90-01: Update the canonical support-surface and host/operator docs for the shipped `client_secret_jwt` slice
- [ ] 90-02: Add release-contract and support-truth proof that the docs and discovery metadata agree with runtime behavior
- [ ] 90-03: Complete milestone-close verification and capture any explicitly deferred follow-on support work

**Success criteria:**
1. `docs/supported-surface.md` and related guidance describe `client_secret_jwt` as a narrow direct-client slice, not a broader trust or FAPI expansion.
2. Repo-native tests pin runtime truth, metadata truth, and support-truth wording together.
3. The milestone closes with no ambiguity about what Lockspire now supports and what remains deferred.

## Milestone Summary

**Requirements mapped:** 7/7
**Coverage:** All covered
**Default next step:** `$gsd-plan-phase 88`

## Shipped Milestones

- [v1.23 DCR Logout Metadata](milestones/v1.23-ROADMAP.md) — shipped 2026-05-24; phases 85-87; 9 plans; self-service clients can now create, read, and replace Lockspire's existing logout propagation metadata through DCR and RFC 7592 without widening the current logout truth model.
- [v1.22 DPoP Nonce Support](milestones/v1.22-ROADMAP.md) — shipped 2026-05-24; phases 82-84; 8 plans; automatic `DPoP-Nonce` challenge and retry support now covers Lockspire-owned `/token`, Lockspire-owned protected resources, and the shipped host Phoenix protected-route pipeline.

## Next Candidate

- Support-burden reduction — improve advanced setup diagnostics and support-truth for `jwks_uri` rotation, mTLS, logout propagation, and protected-route setup if that becomes the next real friction point after `v1.24`.
