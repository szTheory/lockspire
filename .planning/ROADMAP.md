# Roadmap: Lockspire

## Shipped Milestones

- [x] **v1.6 milestone** - completed 2026-04-28 ([archive](milestones/v1.6-ROADMAP.md), [requirements](milestones/v1.6-REQUIREMENTS.md), [audit](milestones/v1.6-MILESTONE-AUDIT.md)); delivered the three-phase Device Authorization Grant milestone with all 10 plans complete, all 9 requirements closed, and generated-host end-to-end proof for `/device/code -> /verify -> /token`.
- [x] **v1.5 milestone** - completed 2026-04-27 ([archive](milestones/v1.5-ROADMAP.md), [requirements](milestones/v1.5-REQUIREMENTS.md)); delivered Dynamic Client Registration RFC 7591/7592 with 27/27 requirements closed.
- [x] **v1.4 milestone** - completed 2026-04-26 ([archive](milestones/v1.4-ROADMAP.md), [requirements](milestones/v1.4-REQUIREMENTS.md)); delivered the four-phase JAR and request-object milestone with all 18 plans complete, all 5 shipped requirements closed, and JAR-04 preserved as deferred.
- [x] **v1.3 milestone** - completed 2026-04-24 ([archive](milestones/v1.3-ROADMAP.md), [requirements](milestones/v1.3-REQUIREMENTS.md)); delivered the four-phase PAR Policy milestone with all 8 plans complete, all 6 requirements closed, and consolidated integration proof for global/client/effective policy enforcement.
- [x] **v1.2 milestone** - completed 2026-04-24 ([archive](milestones/v1.2-ROADMAP.md), [requirements](milestones/v1.2-REQUIREMENTS.md), [audit](milestones/v1.2-MILESTONE-AUDIT.md)); delivered the three-phase PAR foundation milestone with all 8 plans complete, all 5 requirements closed, and the deferred Release Please runtime warning removed without widening the preview support contract.
- [x] **v1.1 milestone** - completed 2026-04-24 ([archive](milestones/v1.1-ROADMAP.md), [requirements](milestones/v1.1-REQUIREMENTS.md), [audit](milestones/v1.1-MILESTONE-AUDIT.md)); delivered the seven-phase release-hardening milestone with all 15 plans complete, all 9 v1.1 requirements closed, and protected release proof/traceability reconciled.
- [x] **v1.0 milestone** - completed 2026-04-23 ([archive](milestones/v1.0-ROADMAP.md)); delivered the six-phase embedded OAuth/OIDC provider scope with all 25 plans completed and 42 recorded tasks.

## Active Milestone

**v1.7 DPoP Core for Public and CLI Clients** — raise the real-integrator trust story by shipping a truthful DPoP core across the Lockspire-owned token and protected-resource surfaces, without widening the embedded-library shape.

**Granularity:** standard
**Phases:** 4 (Phase 33 — Phase 36; numbering continues from v1.6 close at Phase 32)
**Requirements:** 14 (DPoP-01 — DPoP-14), all mapped, no orphans.

### Phases

- [x] **Phase 33: DPoP Proof Validation and Replay State** - completed 2026-04-28; delivered DPoP proof parsing, JOSE validation, thumbprint derivation, durable replay detection, and explicit client/server DPoP policy state.
- [x] **Phase 34: Token Issuance and Refresh/Device Binding** - Thread DPoP through authorization-code, refresh-token, and device-code exchange so Lockspire can issue DPoP-bound tokens with stable binding semantics. (completed 2026-04-28)
- [x] **Phase 35: Owned Endpoint Consumption and Truthful Surface** - Make `userinfo`, discovery, docs, and operator/DCR configuration truthful and usable for the shipped DPoP slice. (completed 2026-04-28)
- [ ] **Phase 36: End-to-End Proof and Milestone Closure** - Add cross-flow executable proof, close traceability, and leave the repo ready for the next adoption-hardening or deeper protocol milestone.

### Phase Details

#### Phase 33: DPoP Proof Validation and Replay State
**Goal**: Lockspire can validate inbound DPoP proofs safely and durably enough that later issuance and protected-resource use do not depend on process-local assumptions.
**Depends on**: v1.6 close (Phase 32); no in-milestone dependencies.
**Requirements**: DPoP-01, DPoP-02, DPoP-03, DPoP-04
**Success Criteria** (what must be TRUE):
  1. Lockspire has a protocol module that parses and validates DPoP proofs against method, target URI, signing key, required claims, and bounded issuance time skew.
  2. Replay detection for proof `jti` values is durable or otherwise repo-proven across nodes and process restarts for the supported time window; replayed proofs are rejected deterministically.
  3. Client and server policy state can explicitly opt into DPoP mode without changing existing bearer clients by default.
  4. Tests cover valid proof, invalid signature, bad `htm`, bad `htu`, stale proof, missing required claims, and replayed `jti`.
**Plans**: 3 plans
- [x] 33-01: Add DPoP proof parser/validator and JWK thumbprint helpers
- [x] 33-02: Add replay-state storage contract and repository-backed replay TTL enforcement
- [x] 33-03: Add client/server DPoP policy state plus unit and repository proof

#### Phase 34: Token Issuance and Refresh/Device Binding
**Goal**: The token endpoint can issue and rotate DPoP-bound tokens on the Lockspire-owned grant paths without breaking the existing bearer default.
**Depends on**: Phase 33
**Requirements**: DPoP-05, DPoP-06, DPoP-07, DPoP-08
**Success Criteria** (what must be TRUE):
  1. Authorization-code exchange can require and validate a DPoP proof for DPoP-mode clients and issue an access token whose `cnf` binds to the proof key thumbprint.
  2. Refresh-token exchange preserves DPoP binding semantics and rejects refresh attempts that do not present a proof bound to the expected key.
  3. Device-code exchange supports DPoP mode for public and CLI-oriented clients without widening the host-owned verification seam.
  4. Successful DPoP token responses are truthfully shaped, including `token_type: "DPoP"`, while bearer clients remain unchanged.
**Plans**: 3 plans
- [x] 34-01-PLAN.md — Add the shared token-endpoint DPoP context plus truthful auth-code issuance and durable `cnf` persistence
- [x] 34-02-PLAN.md — Add atomic refresh-token binding checks, DPoP-aware rotation, and `invalid_grant` collapse for proof-key mismatch
- [x] 34-03-PLAN.md — Reuse the shared issuance path for device-code DPoP redemption and generated-host integration proof

#### Phase 35: Owned Endpoint Consumption and Truthful Surface
**Goal**: The Lockspire-owned protected-resource and support surfaces agree with the shipped DPoP slice.
**Depends on**: Phase 34
**Requirements**: DPoP-09, DPoP-10, DPoP-11
**Success Criteria** (what must be TRUE):
  1. `userinfo` accepts DPoP-bound access tokens only when the accompanying proof validates against the token's stored confirmation state.
  2. Discovery advertises the DPoP slice truthfully and only because the mounted repo-proven surface supports it.
  3. Admin and DCR flows can explicitly place clients into bearer or DPoP mode without repo-internal edits.
**Plans**: 3 plans
- [x] 35-01: Add DPoP-aware userinfo validation and response tests
- [x] 35-02: Update discovery metadata, supported-surface docs, and release contract tests
- [x] 35-03: Add operator and DCR configuration for client token mode

#### Phase 36: End-to-End Proof and Milestone Closure
**Goal**: The shipped DPoP slice is end-to-end provable, traceable, and cleanly bounded so the next milestone can choose adoption hardening or deeper protocol scope from a stable base.
**Depends on**: Phase 35
**Requirements**: DPoP-12, DPoP-13, DPoP-14
**Success Criteria** (what must be TRUE):
  1. End-to-end tests prove at least one browser-style authorization-code DPoP flow and one CLI/device-oriented DPoP flow.
  2. Introspection and docs reflect the shipped binding truth, including `cnf` on active DPoP-bound tokens where appropriate.
  3. REQUIREMENTS.md traceability closes at 100%, milestone docs stay truthful, and `.planning/EPIC.md` is synchronized with milestone outcomes.
**Plans**: 3 plans
- [ ] 36-01: Add auth-code DPoP end-to-end proof
- [x] 36-02: Add device/CLI DPoP end-to-end proof and introspection alignment
- [x] 36-03: Close docs, traceability, and milestone verification

### Progress

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 33. DPoP Proof Validation and Replay State | 3/3 | Complete | 2026-04-28 |
| 34. Token Issuance and Refresh/Device Binding | 3/3 | Complete    | 2026-04-28 |
| 35. Owned Endpoint Consumption and Truthful Surface | 3/3 | Complete | 2026-04-28 |
| 36. End-to-End Proof and Milestone Closure | 3/3 | Complete | 2026-04-28 |

## Reference

- Latest milestone archive: [`.planning/milestones/v1.6-ROADMAP.md`](milestones/v1.6-ROADMAP.md)
- Latest requirements archive: [`.planning/milestones/v1.6-REQUIREMENTS.md`](milestones/v1.6-REQUIREMENTS.md)
- Milestone ledger: [`.planning/MILESTONES.md`](MILESTONES.md)
- Epic arc: [`.planning/EPIC.md`](EPIC.md)
- Sigra ecosystem note: [`.planning/ECOSYSTEM-SIGRA.md`](ECOSYSTEM-SIGRA.md)
