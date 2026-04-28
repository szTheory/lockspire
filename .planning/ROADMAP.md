# Roadmap: Lockspire

## Phases

- [ ] **Phase 30: Core Device Authorization Endpoint & Storage** - The provider can receive device authorization requests, generate codes, and store them securely with TTLs.
- [x] **Phase 31: Host-Owned Verification UI Seam** - The host application has the integration seams and documentation needed to build a secure user verification UI. (completed 2026-04-28)
- [ ] **Phase 32: Polling & Token Issuance** - Devices can poll the token endpoint and receive tokens once the user authorizes the request.

## Phase Details

### Phase 30: Core Device Authorization Endpoint & Storage
**Goal**: The provider can receive device authorization requests, generate codes, and store them securely with TTLs.
**Depends on**: Nothing
**Requirements**: DEV-01, DEV-02, DEV-03
**Success Criteria** (what must be TRUE):
  1. Client can send a POST request to `/device/code` and receive a `device_code`, `user_code`, `verification_uri`, and `expires_in`.
  2. Codes are durably stored in Ecto with a TTL of 5-10 minutes.
  3. User codes are generated in a collision-resistant Base20 format.
**Plans**: TBD

### Phase 31: Host-Owned Verification UI Seam
**Goal**: The host application has the integration seams and documentation needed to build a secure user verification UI.
**Depends on**: Phase 30
**Requirements**: DEV-04, DEV-05, DEV-06
**Success Criteria** (what must be TRUE):
  1. Host app can resolve pending device authorizations using the low-entropy user code via provided context functions/seams.
  2. The integration explicitly requires user action to complete the flow, mitigating remote phishing.
  3. Documentation clearly guides the host app on implementing rate-limiting for the verification endpoints.
**Plans**: 4 plans
Plans:
- [ ] `31-01-PLAN.md` — Extend device-authorization lifecycle state and race-safe repository transitions for verification.
- [ ] `31-02-PLAN.md` — Generate the host-owned `/verify` router and controller starter seam with explicit anti-phishing behavior.
- [ ] `31-03-PLAN.md` — Publish the device-flow host guide and wire onboarding/supported-surface docs to the Phase 31 seam.
- [ ] `31-04-PLAN.md` — Add the narrow verification protocol API, prefill response field, and executable response-surface proof.
**UI hint**: yes

### Phase 32: Polling & Token Issuance
**Goal**: Devices can poll the token endpoint and receive tokens once the user authorizes the request.
**Depends on**: Phase 31
**Requirements**: DEV-07, DEV-08, DEV-09
**Success Criteria** (what must be TRUE):
  1. Devices receive `authorization_pending` when polling before user action.
  2. Devices receive `slow_down` if polling too frequently, respecting enforced intervals.
  3. Devices successfully receive access and refresh tokens once the host app marks the request as authorized.
**Plans**: 3 plans
Plans:
- [x] `32-01-PLAN.md` — Extend device-authorization storage with durable poll-window state, sticky `slow_down`, and single-winner consume semantics. (completed 2026-04-28)
- [ ] `32-02-PLAN.md` — Add the device grant branch to `TokenExchange` and reuse shared token issuance for RFC-shaped polling outcomes.
- [ ] `32-03-PLAN.md` — Prove the HTTP/discovery/docs contract and add end-to-end device-flow token redemption coverage.

## Progress

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 30. Core Device Authorization Endpoint & Storage | 0/3 | Not started | - |
| 31. Host-Owned Verification UI Seam | 4/4 | Complete   | 2026-04-28 |
| 32. Polling & Token Issuance | 1/3 | In Progress | - |

## Shipped Milestones

- [x] **v1.5 milestone** - completed 2026-04-27 ([archive](milestones/v1.5-ROADMAP.md), [requirements](milestones/v1.5-REQUIREMENTS.md)); delivered Dynamic Client Registration (DCR) RFC 7591/7592 with 27/27 requirements closed.
- [x] **v1.4 milestone** - completed 2026-04-26 ([archive](milestones/v1.4-ROADMAP.md), [requirements](milestones/v1.4-REQUIREMENTS.md)); delivered the four-phase JAR and request-object milestone with all 18 plans complete, all 5 shipped JAR requirements closed, and JAR-04 preserved as deferred.
- [x] **v1.3 milestone** - completed 2026-04-24 ([archive](milestones/v1.3-ROADMAP.md), [requirements](milestones/v1.3-REQUIREMENTS.md)); delivered the four-phase PAR Policy milestone with all 8 plans complete, all 6 requirements closed, and consolidated integration proof for global/client/effective policy enforcement.
- [x] **v1.2 milestone** - completed 2026-04-24 ([archive](milestones/v1.2-ROADMAP.md), [requirements](milestones/v1.2-REQUIREMENTS.md), [audit](milestones/v1.2-MILESTONE-AUDIT.md)); delivered the three-phase PAR foundation milestone with all 8 plans complete, all 5 requirements closed, and the deferred Release Please runtime warning removed without widening the preview support contract.
- [x] **v1.1 milestone** - completed 2026-04-24 ([archive](milestones/v1.1-ROADMAP.md), [requirements](milestones/v1.1-REQUIREMENTS.md), [audit](milestones/v1.1-MILESTONE-AUDIT.md)); delivered the seven-phase release-hardening milestone with all 15 plans complete, all 9 v1.1 requirements closed, and protected release proof/traceability reconciled.
- [x] **v1.0 milestone** - completed 2026-04-23 ([archive](milestones/v1.0-ROADMAP.md)); delivered the six-phase embedded OAuth/OIDC provider scope with all 25 plans completed and 42 recorded tasks.

## Reference

- Milestone archive: [`.planning/milestones/v1.5-ROADMAP.md`](milestones/v1.5-ROADMAP.md)
- Requirements archive: [`.planning/milestones/v1.5-REQUIREMENTS.md`](milestones/v1.5-REQUIREMENTS.md)
- Milestone ledger: [`.planning/MILESTONES.md`](MILESTONES.md)
- Sigra ecosystem note: [`.planning/ECOSYSTEM-SIGRA.md`](ECOSYSTEM-SIGRA.md)
