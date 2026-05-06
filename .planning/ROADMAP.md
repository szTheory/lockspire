# Lockspire Roadmap — Milestone v1.14

**Milestone:** v1.14: Advanced Authorization & Resource Targetting
**Status:** Planning
**Goal:** Deliver Resource Indicators (RFC 8707) and Rich Authorization Requests (RAR - RFC 9396) to enable fine-grained, targeted authorization for complex domain integrations.

## Phases

- [x] **Phase 54: Resource Indicators (RFC 8707)** - Implement targeted audience (`aud`) claims and resource parameter validation.
- [ ] **Phase 55: RAR Protocol Intake** - Enable `authorization_details` support in PAR and Authorization pipelines.
- [ ] **Phase 56: RAR Domain Validation & Storage** - Deliver Ecto-based validation framework and durable storage for rich authorization.
- [ ] **Phase 57: RAR Introspection & Verification** - Expose rich details to Resource Servers and verify end-to-end flows.
- [ ] **Phase 58: Milestone Closure & Discovery** - Truthful discovery updates, executable docs, and final stabilization.

## Phase Details

### Phase 54: Resource Indicators (RFC 8707)
**Goal**: Users and clients can request tokens targeted at specific Resource Servers.
**Depends on**: None (v1.13 completed)
**Requirements**: RES-01, RES-02, RES-03
**Success Criteria** (what must be TRUE):
  1. Client can include one or more `resource` URIs in authorization and token requests.
  2. Minted Access Tokens contain only the requested resource(s) in the `aud` claim.
  3. Token exchange (refresh) correctly intersects requested resources with originally granted scopes/resources.
**Plans**: 1 plans

### Phase 55: RAR Protocol Intake
**Goal**: Clients can submit structured authorization details via PAR and Authorization requests.
**Depends on**: Phase 54
**Requirements**: RAR-01
**Success Criteria** (what must be TRUE):
  1. Lockspire accepts and parses the `authorization_details` JSON array.
  2. PAR correctly persists RAR details for subsequent authorization.
  3. Authorization requests without PAR are rejected if RAR details are too large (URI length protection).
**Plans**: 3 plans
- [ ] 55-01-PLAN.md — Database and Domain extension for RAR intake.
- [ ] 55-02-PLAN.md — Protocol validation, parsing, and PAR persistence logic.
- [ ] 55-03-PLAN.md — End-to-end integration tests for RAR intake.

### Phase 56: RAR Domain Validation & Storage
**Goal**: Host apps can define and validate custom RAR types using idiomatic Elixir patterns.
**Depends on**: Phase 55
**Requirements**: RAR-02, RAR-03
**Success Criteria** (what must be TRUE):
  1. Host app can register Ecto-based validators for specific RAR `type` values.
  2. Invalid RAR payloads are rejected with RFC-compliant error messages.
  3. Validated RAR details are stored in the database and associated with the issued grant/token.
**Plans**: TBD
**UI hint**: yes

### Phase 57: RAR Introspection & Verification
**Goal**: Resource Servers can retrieve rich authorization details via introspection.
**Depends on**: Phase 56
**Requirements**: RAR-04, V-01, V-02
**Success Criteria** (what must be TRUE):
  1. The `/introspection` response includes the `authorization_details` array.
  2. Access Tokens remain compact (not bloated with full RAR JSON) while preserving the reference to the grant.
  3. E2E tests verify that a complex RAR request results in correct consent UI and token introspection.
**Plans**: TBD

### Phase 58: Milestone Closure & Discovery
**Goal**: The system truthfully advertises its new capabilities and provides clear integrator guidance.
**Depends on**: Phase 57
**Requirements**: META-01, META-02, DOC-01
**Success Criteria** (what must be TRUE):
  1. `.well-known/openid-configuration` includes `resource_indicators_supported` and `authorization_details_types_supported`.
  2. Documentation includes an executable example of a custom RAR "Payment Initiation" flow.
  3. All v1.14 requirements are validated and archived.
**Plans**: TBD

## Progress Table

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 54. Resource Indicators | 1/1 | Completed | 2026-05-05 |
| 55. RAR Protocol Intake | 0/3 | Active | - |
| 56. RAR Domain Validation | 0/1 | Not started | - |
| 57. RAR Introspection | 0/1 | Not started | - |
| 58. Milestone Closure | 0/1 | Not started | - |
