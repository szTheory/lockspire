# v1.25 Support-Burden Reduction Requirements

**Defined:** 2026-05-25
**Status:** Active
**Core Value:** A Phoenix team can become a trustworthy OAuth/OIDC provider inside its existing app without inventing the dangerous parts itself.

## Milestone Goal

Reduce advanced setup ambiguity on already-shipped trust surfaces so adopters can configure, diagnose, and support Lockspire with explicit product truth instead of maintainers' implicit knowledge.

## v1 Requirements

### JWKS Rotation Diagnostics

- [ ] **JWKS-01**: A host team using remote `jwks_uri` key material can tell when Lockspire considers the configuration supported, stale, or broken, with concrete remediation guidance.
- [ ] **JWKS-02**: An operator can distinguish key-rotation failures caused by issuer metadata, JWKS content, cache freshness, or unsupported rollover posture without reading source code.

### Advanced Setup Guidance

- [x] **GUIDE-01**: A host team enabling mTLS client authentication can identify the required certificate extraction prerequisites, explicit host responsibilities, and supported deployment patterns before rollout.
- [x] **GUIDE-02**: A host team protecting Phoenix API routes can follow one canonical setup path for `VerifyToken -> EnforceSenderConstraints -> RequireToken`, including the expected `401 invalid_token` and `403 insufficient_scope` behavior.
- [x] **GUIDE-03**: An operator configuring logout propagation can understand the current back-channel durability, front-channel best-effort semantics, and required metadata/setup prerequisites from one coherent support story.

### Support Truth Alignment

- [x] **TRUTH-01**: Canonical docs, operator/admin wording, and any doctor or diagnostic surfaces describe the same supported truth for `jwks_uri` rotation, mTLS setup, logout propagation, and protected-route configuration.
- [x] **TRUTH-02**: Advanced setup guidance clearly states Lockspire-owned behavior versus host-owned or infrastructure-owned behavior so support boundaries stay explicit.

### Proof

- [ ] **PROOF-01**: Repo-native automated proof covers representative advanced-setup misconfiguration and remediation cases for `jwks_uri` rotation and at least one other shipped high-friction setup surface.
- [ ] **PROOF-02**: Release-contract or documentation-truth proof fails if the published support story drifts from the shipped advanced setup behavior.

## Future Requirements

### Deferred Follow-On Candidates

- **FUTURE-01**: Broader auth-method parity or new protocol families if real adopter evidence emerges after support burden is reduced.
- **FUTURE-02**: More ambitious operator UX around advanced setup readiness dashboards if the narrower diagnostics milestone still leaves material support drag.

## Out Of Scope

| Feature | Reason |
|---------|--------|
| New protocol families or major auth-method expansion | This milestone is about support-cost reduction on shipped surfaces, not breadth. |
| Hosted-auth, CIAM, SAML, or LDAP expansion | Violates the embedded-library boundary and current product thesis. |
| Reframing front-channel logout as reliable delivery | Would overstate Lockspire's actual runtime guarantees. |
| New protected-resource product surfaces beyond the shipped Phoenix route pipeline | The priority is clarifying and proving the current path, not expanding it. |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| JWKS-01 | Phase 91 | Pending |
| JWKS-02 | Phase 91 | Pending |
| GUIDE-01 | Phase 92 | Complete |
| GUIDE-02 | Phase 92 | Complete |
| GUIDE-03 | Phase 92 | Complete |
| TRUTH-01 | Phase 92 | Complete |
| TRUTH-02 | Phase 92 | Complete |
| PROOF-01 | Phase 93 | Pending |
| PROOF-02 | Phase 93 | Pending |

**Coverage:**
- v1 requirements: 9 total
- Mapped to phases: 9
- Unmapped: 0

---
*Requirements defined: 2026-05-25*
*Last updated: 2026-05-25 after milestone definition*
