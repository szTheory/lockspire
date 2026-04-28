# Requirements: Lockspire v1.7 — DPoP Core for Public and CLI Clients

**Defined:** 2026-04-28
**Milestone:** v1.7 DPoP Core for Public and CLI Clients
**Core Value:** A Phoenix team can become a trustworthy OAuth/OIDC provider inside its existing app without inventing the dangerous parts itself.

**Milestone goal:** Raise the real-client trust story by shipping a truthful DPoP core across the Lockspire-owned token and protected-resource surfaces, without widening beyond the embedded Phoenix library shape.

## v1.7 Requirements

Each requirement is atomic, testable, and traceable to a phase. Phase numbering continues from v1.6 (closed at Phase 32); v1.7 starts at Phase 33.

### Proof Validation and Replay Protection

- [x] **DPoP-01**: Lockspire validates DPoP proofs for supported endpoints against required JOSE header and claim semantics, including signature validity, `htm`, `htu`, `iat`, and `jti`.
- [x] **DPoP-02**: Lockspire computes and persists the proof key thumbprint used to bind issued tokens.
- [x] **DPoP-03**: Replayed DPoP proofs are rejected within the supported replay window with deterministic, RFC-shaped errors.
- [x] **DPoP-04**: DPoP enablement is explicit in policy or client state; existing bearer clients remain bearer by default.

### Token Issuance and Binding

- [x] **DPoP-05**: `POST /token` supports DPoP-bound authorization-code exchange for DPoP-mode clients and returns truthful DPoP token responses.
- [x] **DPoP-06**: DPoP-bound access tokens persist confirmation (`cnf`) state that is sufficient for later validation on Lockspire-owned endpoints.
- [x] **DPoP-07**: Refresh-token exchange preserves DPoP binding semantics and rejects refresh attempts that present the wrong proof key or no valid proof.
- [x] **DPoP-08**: Device-code exchange supports DPoP mode for public and CLI-oriented clients without widening the host-owned verification seam.

### Owned Endpoint Consumption and Surface Truth

- [ ] **DPoP-09**: `userinfo` accepts DPoP-bound access tokens only when the accompanying proof validates against the token's stored binding state.
- [ ] **DPoP-10**: Discovery metadata and support docs advertise only the shipped DPoP slice, including truthful supported proof signing algorithms and endpoint behavior.
- [ ] **DPoP-11**: Operator and DCR flows can explicitly configure client token mode for bearer vs DPoP without repo-internal edits.

### Proof, Observability, and Closure

- [ ] **DPoP-12**: End-to-end tests prove at least one authorization-code DPoP flow and one public/CLI-oriented DPoP flow.
- [ ] **DPoP-13**: Introspection and related runtime surfaces expose truthful DPoP-bound token state where needed, including `cnf` on active DPoP-bound tokens.
- [ ] **DPoP-14**: The v1.7 milestone closes with synchronized docs, traceability, and an updated epic-arc record so future milestone selection builds from current repo truth.

## Future Requirements

Acknowledged but deferred beyond v1.7. Tracked but not in the current roadmap.

### Sender-Constrained Depth

- **SCON-FUT-01**: Support mTLS-bound access tokens for enterprise deployments that can tolerate PKI and certificate-management complexity.
- **SCON-FUT-02**: Add DPoP nonce support if real-client experience or interop pressure proves it necessary for the supported slice.
- **SCON-FUT-03**: Extend DPoP-aware validation helpers beyond Lockspire-owned endpoints into a host-consumable protected-resource seam.

### Adjacent Protocol Depth

- **JAR-FUT-01**: Support JAR decryption (the deferred v1.4 JAR-04 requirement) if the next protocol milestone needs deeper request-object compatibility.
- **DCR-FUT-01**: Support SSRF-guarded `jwks_uri` outbound fetch for DCR if partner demand justifies the complexity.

### Product and Release Hardening

- **ADOPT-FUT-01**: Define and satisfy the 1.0 support bar: repeated green releases, stable support expectations, and maintained runbooks.
- **ADOPT-FUT-02**: Add compatibility and onboarding hardening for a broader set of Phoenix host-app shapes if that becomes a real adoption bottleneck.

## Out of Scope

Explicitly excluded. Documented to prevent scope creep and keep public support claims truthful.

| Feature | Reason |
|---------|--------|
| mTLS-bound tokens in v1.7 | Valuable later, but too heavy for the next embedded-library milestone and not the best fit for public/CLI clients. |
| Full FAPI or certification-profile work in v1.7 | A different maturity/certification effort; not the next highest-leverage step toward real integrator readiness. |
| Generic host-app protected-resource middleware | Lockspire should first prove the DPoP slice on the endpoints it owns before widening into arbitrary host resource-server helpers. |
| Hosted auth / external token service language | Violates the embedded-library product shape. |
| SAML, LDAP, or workforce-identity breadth | Expands the project into CIAM/workforce territory instead of sharpening the current OAuth/OIDC provider wedge. |
| Reworking all existing clients to DPoP by default | Too risky and not truthful to the current preview posture; rollout must be explicit and opt-in. |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| DPoP-01 | Phase 33 | Completed |
| DPoP-02 | Phase 33 | Completed |
| DPoP-03 | Phase 33 | Completed |
| DPoP-04 | Phase 33 | Completed |
| DPoP-05 | Phase 34 | Completed |
| DPoP-06 | Phase 34 | Completed |
| DPoP-07 | Phase 34 | Pending |
| DPoP-08 | Phase 34 | Completed |
| DPoP-09 | Phase 35 | Pending |
| DPoP-10 | Phase 35 | Pending |
| DPoP-11 | Phase 35 | Pending |
| DPoP-12 | Phase 36 | Pending |
| DPoP-13 | Phase 36 | Pending |
| DPoP-14 | Phase 36 | Pending |

**Coverage:**
- v1.7 requirements: 14 total
- Mapped to phases: 14
- Unmapped: 0

---
*Requirements defined: 2026-04-28*
*Last updated: 2026-04-28 after Phase 33 completion.*
