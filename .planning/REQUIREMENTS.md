# Requirements: Lockspire v1.48 Client Authentication Key Isolation & Rotation

**Defined:** 2026-10-25
**Status:** All 18 requirements approved by the owner with “lgtm” on 2026-10-25; roadmap approved on 2026-10-25. Phases 175–177 independently verified 15/18 requirements; the remaining three are pending Phase 178. Generic edge and non-authoritative prohibition flags remain visible in their reports.
**Core Value:** A Phoenix team can become a trustworthy OAuth/OIDC provider inside its existing app without inventing the dangerous parts itself.
**Research:** [SEC-01 synthesis](research/v1.48-client-auth-key-isolation/SUMMARY.md).

## v1.48 Requirements

### Qualified baseline and compatibility contract

- [x] **VBASE-01**: Maintainer can begin product implementation only after retained-delivery reconciliation and fresh exact-main acceptance through the existing helper, including local contributor checks, matching required CI/Release evidence and explicit resource custody.
- [x] **VBASE-02**: Maintainer can inspect a finite acceptance contract covering format/key configuration, every verifier writer/reader, legacy ciphertext age, mixed-version rollout/rollback and supported storage adapters; unresolved policy changes stop dependent implementation.

### Independent verifier key custody

- [x] **SEC-01**: Host can encrypt newly persisted client-secret-JWT verifier material with dedicated rotatable keys independent of endpoint/session secrets and signing-key KEKs.
- [x] **SEC-02**: Host can explicitly select current/read keys and compatibility/write mode; malformed or missing required key configuration fails clearly without silently falling back or unexpectedly breaking unrelated host authentication at boot.
- [x] **SEC-03**: Host can reject tampered, malformed, unknown-key/version and cross-client/purpose verifier envelopes through authenticated, text-safe storage and redacted fail-closed errors.
- [x] **SEC-04**: Operator and registration callers can create or rotate credentials through every existing shared-secret writer with a coherent persisted hash/verifier pair, preserving one-time secret handoff and configured client/secret lifetimes.
- [x] **SEC-05**: Integrator can authenticate with dedicated-key verifiers across all existing supported direct-client endpoints while retaining HS256, issuer audience, required JTI/replay protection and the current PAR/FAPI exclusions.

### Upgrade and rotation compatibility

- [x] **VUP-01**: Existing hosts can read usable legacy Plug.Crypto verifier rows during explicit compatibility and deliberately reject them afterward; aged/unreadable rows have a qualified disposition, with no silent age bypass or change to configured credential expiry.
- [x] **VUP-02**: Host operator can follow and verify a reader-first rolling deployment with explicit writer activation and truthful code/config rollback limits, so old nodes never encounter an unsupported write format in the supported sequence.
- [x] **VUP-03**: Host operator can introduce a new verifier key, rewrap existing material and retire an old key without changing partner secrets, endpoint/session secrets or signing-key custody.

### Safe maintenance, status and recovery

- [x] **VOPS-01**: Maintainer can preview, apply and check verifier rewrap through repo-safe tooling that is idempotent, reports partial failures/conflicts and returns a failing outcome when the requested completion/readiness condition is not met.
- [x] **VOPS-02**: Host can rewrap through its supported client/transaction store without overwriting concurrent secret rotation or client updates; ciphertext and audit commit atomically while hashes, expiry, rotation timestamps and other client fields remain unchanged.
- [x] **VOPS-03**: Operator can inspect redacted status for all stored verifier material, including inactive/expired and non-JWT-method clients; unknown, malformed, unreadable or uninspected rows cannot be presented as ready, and local status does not claim fleet-wide configuration parity.
- [x] **VOPS-04**: Operator can identify affected clients after missing/lost-key failure and recover through restoring a valid key or the existing authorized secret-rotation/reprovision path, while affected JWT authentication fails closed and unrelated supported authentication remains intact.

### Proof and delivery

- [x] **VPROOF-01**: Security reviewer can verify that verifier plaintext, encryption keys and ciphertext stay out of logs, SQL diagnostics, telemetry, audit, operator reports and protocol responses across success and failure paths.
- [ ] **VPROOF-02**: Maintainer can reproduce source-bound package-installed fresh/legacy-upgrade, mixed-key/version, rotation, rejection and recovery journeys on the existing supported dependency pairs, including actual PostgreSQL concurrency/rollback and a supported configured-store composition; unavailable cases remain explicit failures or blockers.
- [ ] **VDELIV-01**: Reviewer can assess a completed milestone audit, focused security/code review and passing required candidate contributor/CI gates, with install/upgrade/support guidance matching verified behavior and no new dependency or public protocol scope.
- [ ] **VDELIV-02**: Next maintainer can resume from a dated delivery/main-acceptance and resource-custody handoff, with unknown work preserved and the rolling ranking refreshed to retain UI quality next and its completed interview.

## Qualification-driven scope reconciliation (2026-10-24)

All six authorization/PAR requirements remain pending. Phase 171 qualifies the following cases without marking downstream behavior accepted: AUTHR-01 reuses A171-001; AUTHR-02 reuses A171-002 and retains A171-003 as a correction; AUTHR-03 reuses A171-004, A171-005 and A171-006; PARB-01 reuses P171-001, P171-002 and P171-003; PARB-02 reuses P171-004 and retains P171-005 as a correction; PARB-03 reuses P171-006 source-host metadata proof. See the frozen Phase 171 matrix for exact requests, expected projections, evidence identities and owners.

The A171-003 correction is limited to unsupported `response_mode` returning HTTP 400 without OAuth Error Response parameters. The P171-005 correction is limited to a valid pushed reference using pushed `openid email` despite outer `scope=profile`; the linked-clause interpretation is documented in `171-QUALIFICATION-DECISIONS.md`. Existing proofs carry forward without duplicate corrections. Neither unavailable optional profile wrapper is treated as product evidence or as a selected-case blocker. CPROOF-01/02 and DELIV-01/02 remain for Phase 174, including each actual correction's RED/GREEN proof, applicable negative/security coverage and packaged-host proof.


## Future Requirements

- **UI quality candidate:** Whole-UI inventory and complete layered coverage for Apps setup/configuration and Tokens/Consents investigation, adoption-demo dev/test `phoenix_storybook`, observed before/after improvements, reliable blocking checks, measured budgets and same-PR maintenance. [Q1–Q10 and final confirmation](research/ui-quality-engine/MILESTONE-PROPOSAL.md) remain accepted; no UI version or phase IDs are scheduled here.
- **OPS-03:** Paged signing-key maintenance dry-run/status improvements only after measured scale evidence.
- **KEK-04:** Host-controlled KMS/Vault seam only after concrete adopter custody/outage requirements.
- **Token lifecycle resilience:** Only for a reproduced gap or material unproved invariant; preserve existing family-wide reuse revocation.

## Out of Scope

| Feature | Reason |
|---|---|
| UI redesign, Storybook installation or broad admin work | Separate next candidate with completed interview; do not bolt it onto key custody. |
| KMS/Vault service, generic secrets platform or required external process | No adopter trigger; preserve embedded host ownership and small dependency closure. |
| New algorithms, authentication methods, PAR/FAPI JWT support or protocol families | SEC-01 changes at-rest custody, not the supported authentication surface. |
| Changes to configured app/credential lifetimes or automatic legacy-age bypass | Requires qualified behavior and explicit policy disposition; migration must not silently grant authority. |
| Signing-envelope format change, new client schema or automatic secret rotation | Not required by the recommended in-place text-safe design; re-scope through GSD if evidence disproves that premise. |
| Arbitrary custom-store compatibility | Prove the declared supported composition and fail unsupported capability explicitly; no direct-repository fallback. |
| Fleet key distribution/coordination and recovery without a key | Host owns deployment/custody; local checks cannot guarantee node parity or decrypt irrecoverable data. |
| Public package publication | Milestone delivery uses the normal PR/main train; publication stays with Release Please and protected exact-ref publishing. |

## Traceability

Each approved requirement maps exactly once to the approved roadmap, continuing after Phase 174. Phases 175–177 are independently verified complete; Phase 178 remains pending.

| Requirement | Phase | Status |
|---|---|---|
| VBASE-01 | Phase 175 | Complete |
| VBASE-02 | Phase 175 | Complete |
| SEC-01 | Phase 176 | Complete |
| SEC-02 | Phase 176 | Complete |
| SEC-03 | Phase 176 | Complete |
| SEC-04 | Phase 176 | Complete |
| SEC-05 | Phase 176 | Complete |
| VUP-01 | Phase 176 | Complete |
| VUP-02 | Phase 176 | Complete |
| VUP-03 | Phase 177 | Complete |
| VOPS-01 | Phase 177 | Complete |
| VOPS-02 | Phase 177 | Complete |
| VOPS-03 | Phase 177 | Complete |
| VOPS-04 | Phase 177 | Complete |
| VPROOF-01 | Phase 177 | Complete |
| VPROOF-02 | Phase 178 | Requalification pending |
| VDELIV-01 | Phase 178 | Pending |
| VDELIV-02 | Phase 178 | Pending |

**Coverage:** 18 requirements; 18 mapped exactly once; 0 unmapped; 15 verified complete and 3 pending/requalification. Roadmap approved 2026-10-25. Phase 178 Plan 10 evidence remains valid for its exact 1,076-input frozen closure; the expanded 1,077-input closure requires refreshed source-bound evidence before VPROOF-02 can be marked complete.

---
*Last updated: 2026-10-27 after Phase 178 main-base synchronization; VPROOF-02 is pending requalification for the expanded selected-input closure.*
