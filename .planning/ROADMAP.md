# Roadmap: Lockspire

## Overview

Lockspire will be built as a focused six-phase first milestone. The sequence starts by locking down the embedded-library boundary and host seam, then ships the authorization core, completes the OIDC and token lifecycle path, builds the operator/admin product, hardens security and observability, and finishes with install DX and release readiness. Every v1 requirement is mapped exactly once so planning can proceed phase by phase without losing scope discipline.

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [x] **Phase 1: Foundation and Host Seam** - Establish Lockspire's library boundaries, storage seams, and host-owned integration path
- [x] **Phase 2: Authorization Core** - Deliver client registration, authorization code + PKCE, consent, and token exchange
- [ ] **Phase 3: OIDC and Token Lifecycle** - Add discovery, JWKS, userinfo, refresh rotation, revocation, and introspection
- [ ] **Phase 4: Operator Product** - Build the admin workflows for clients, consents, tokens, and keys
- [ ] **Phase 5: Security and Observability Hardening** - Enforce secure defaults, auditability, redaction, and negative-path coverage
- [ ] **Phase 6: Install DX and Release Readiness** - Finish generators, canonical onboarding, CI/CD, and release discipline

## Phase Details

### Phase 1: Foundation and Host Seam
**Goal**: Create the embedded-library skeleton, durable storage boundaries, explicit host seams, and editable host integration path that all later protocol work depends on.
**Depends on**: Nothing
**Requirements**: INTE-01, INTE-02, INTE-03, INTE-04
**Success Criteria** (what must be TRUE):
  1. A host Phoenix app can mount Lockspire without standing up a separate auth service.
  2. Account resolution, login redirects, and claim enrichment are represented as explicit host-owned seams.
  3. Generated host modules exist for interaction and consent handoff, and remain editable by the host app.
  4. Library boundaries clearly separate protocol core, storage, generators, and web/admin delivery.
**Plans**: 3 plans

Plans:
- [x] 01-01: Establish library structure, public API boundaries, and configuration model
- [x] 01-02: Define Ecto/Postgres domain and adapter seams for clients, consents, interactions, tokens, and keys
- [x] 01-03: Generate host-owned integration modules and mount path for login/consent handoff

### Phase 2: Authorization Core
**Goal**: Implement the first complete provider flow: client management inputs, authorization code + PKCE, consent decisions, and code exchange for access tokens.
**Depends on**: Phase 1
**Requirements**: AUTH-01, AUTH-02, AUTH-03, AUTH-04, AUTH-05
**Success Criteria** (what must be TRUE):
  1. An operator can register a client with redirect URIs, scopes, grant types, and client-type settings.
  2. A third-party client can begin an authorization code flow using PKCE S256.
  3. Unsafe or mismatched authorization requests are rejected with clear protocol-safe behavior.
  4. An authenticated account can approve or deny requested scopes through the consent handoff.
  5. A valid authorization code can be exchanged for an access token.
**Plans**: 4 plans

Plans:
- [x] 02-01: Implement client registration and authorization request validation
- [x] 02-02: Build durable interaction, consent, and authorization-code state plus protocol orchestration
- [x] 02-03: Wire `/authorize`, consent UI/finalization, and generated host surfaces for the end-to-end flow
- [x] 02-04: Implement token exchange for access tokens with durable state transitions

### Phase 3: OIDC and Token Lifecycle
**Goal**: Complete the interoperable provider surface with OIDC metadata, JWKS, userinfo, and durable token lifecycle management.
**Depends on**: Phase 2
**Requirements**: OIDC-01, OIDC-02, OIDC-03, TOKN-01, TOKN-02, TOKN-03
**Success Criteria** (what must be TRUE):
  1. Third-party developers can discover provider metadata and keys from standard OIDC endpoints.
  2. OpenID clients receive correct OIDC token material and can fetch user claims through userinfo.
  3. Refresh tokens rotate on use and reuse detection revokes the token family.
  4. Revocation and introspection endpoints expose the supported token lifecycle actions safely.
**Plans**: 3 plans

Plans:
- [ ] 03-01: Implement discovery, issuer metadata, and JWKS publication
- [ ] 03-02: Implement ID token and userinfo support with host claim enrichment
- [ ] 03-03: Implement refresh rotation, revocation, introspection, and lifecycle persistence

### Phase 4: Operator Product
**Goal**: Make Lockspire operable through a calm LiveView-native admin surface for clients, consents, tokens, and keys.
**Depends on**: Phase 3
**Requirements**: OPER-01, OPER-02, OPER-03, OPER-04
**Success Criteria** (what must be TRUE):
  1. Operators can manage client lifecycle and rotate credentials from the admin UI.
  2. Accounts or operators can review and revoke consent grants.
  3. Operators can inspect active tokens and refresh-family lineage without shelling into production.
  4. Operators can view and act on key lifecycle states through product workflows.
**Plans**: 3 plans

Plans:
- [ ] 04-01: Build client-management screens and credential rotation workflows
- [ ] 04-02: Build consent-management and token-inspection workflows
- [ ] 04-03: Build key-lifecycle screens and operator navigation across admin areas

### Phase 5: Security and Observability Hardening
**Goal**: Enforce the security posture, emit durable observability signals, and prove negative-path behavior across the protocol and operator surfaces.
**Depends on**: Phase 4
**Requirements**: SECU-01, SECU-02, SECU-03, SECU-04
**Success Criteria** (what must be TRUE):
  1. Secure defaults are enforced across clients, authorization flows, token exchange, and key handling.
  2. Telemetry and audit events exist for the key protocol and operator lifecycle transitions.
  3. Secrets and sensitive token material are redacted in logs and operator-visible surfaces.
  4. Negative-path tests cover malformed, replayed, mismatched, denied, and downgrade-oriented requests.
**Plans**: 3 plans

Plans:
- [ ] 05-01: Enforce security invariants and downgrade-resistant configuration defaults
- [ ] 05-02: Implement telemetry, audit emission, and operator-safe redaction behavior
- [ ] 05-03: Add negative-path and threat-driven coverage across protocol and admin flows

### Phase 6: Install DX and Release Readiness
**Goal**: Make Lockspire credible to adopt and maintain through polished generators, canonical onboarding, CI/CD, and release discipline.
**Depends on**: Phase 5
**Requirements**: RELS-01, RELS-02
**Success Criteria** (what must be TRUE):
  1. A fresh Phoenix host app can follow one canonical onboarding path and complete a real authorization flow.
  2. Generated setup code, docs, and examples align with the actual integration seams and security posture.
  3. CI, changelog, release workflow, and publishing discipline are versioned and repeatable.
  4. Release-readiness checks exist for a security-sensitive OSS library.
**Plans**: 3 plans

Plans:
- [ ] 06-01: Polish generators, install flow, and executable onboarding docs
- [ ] 06-02: Establish CI/CD, changelog, and release/publish workflows
- [ ] 06-03: Finalize release-readiness checks, maintainer guidance, and conformance prep

## Progress

**Execution Order:**
Phases execute in numeric order: 1 → 2 → 3 → 4 → 5 → 6

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Foundation and Host Seam | 3/3 | Completed | 2026-04-23 |
| 2. Authorization Core | 4/4 | Completed | 2026-04-23 |
| 3. OIDC and Token Lifecycle | 0/3 | Not started | - |
| 4. Operator Product | 0/3 | Not started | - |
| 5. Security and Observability Hardening | 0/3 | Not started | - |
| 6. Install DX and Release Readiness | 0/3 | Not started | - |
