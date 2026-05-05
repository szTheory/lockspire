# v1.12 Token Exchange Roadmap

## Phases
- [x] **Phase 48: Protocol Foundation & Storage** - Parse RFC 8693 requests, validate tokens, and persist lineage
- [x] **Phase 49: Host Policy Behaviour** - Expose the host application behaviour for authorization logic
- [x] **Phase 50: Delegation & Act Claims** - Implement act claim generation and depth limits for delegation

## Phase Details

### Phase 48: Protocol Foundation & Storage
**Goal**: The server can receive and parse Token Exchange requests, and store the resulting tokens securely.
**Depends on**: Phase 47
**Requirements**: TE-01, TE-02, TE-05
**Success Criteria** (what must be TRUE):
  1. A client can send a token exchange request and the server responds or rejects it correctly.
  2. The requested scope is strictly bounded to the original `subject_token` scopes.
  3. Exchanged tokens are stored with a lineage trace (grant_id) to the original token.
**Plans**: TBD

### Phase 49: Host Policy Behaviour
**Goal**: Host applications can authorize or reject token exchanges based on domain logic.
**Depends on**: Phase 48
**Requirements**: TE-03
**Success Criteria** (what must be TRUE):
  1. Developers can configure a `Lockspire.TokenExchangeValidator` behaviour module.
  2. Exchanges are denied by default if the behaviour explicitly rejects or is unconfigured.
  3. The behaviour is passed the `subject_token` and `actor_token` context to differentiate Impersonation vs Delegation.
**Plans**: 2 plans
- [ ] 49-01-PLAN.md — Introduce the Token Exchange Validator behaviour and default deny implementation.
- [ ] 49-02-PLAN.md — Integrate the host validator into the exchange flow and securely mint structured JWTs.

### Phase 50: Delegation & Act Claims
**Goal**: Exchanged tokens correctly reflect delegation chains via act claims.
**Depends on**: Phase 49
**Requirements**: TE-04
**Success Criteria** (what must be TRUE):
  1. Exchanged tokens resulting from a delegation (actor_token present) contain the `act` claim.
  2. Token bloat is prevented by enforcing a `max_delegation_depth` configuration.
**Plans**: 2 plans
- [ ] 50-01-PLAN.md — Introduce max_delegation_depth configurations to ServerPolicy and Client models.
- [ ] 50-02-PLAN.md — Implement act claim extraction and enforce delegation depth limits during Token Exchange.

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 48. Protocol Foundation & Storage | 0/3 | Not started | - |
| 49. Host Policy Behaviour | 0/2 | Not started | - |
| 50. Delegation & Act Claims | 0/2 | Not started | - |
te | 2026-05-05 |
