# Requirements: Lockspire

**Defined:** 2026-04-24
**Milestone:** v1.2 PAR Foundation
**Core Value:** A Phoenix team can become a trustworthy OAuth/OIDC provider inside its existing app without inventing the dangerous parts itself.

## v1.2 Requirements

### PAR Intake

- [ ] **PAR-01**: OAuth clients can submit a pushed authorization request to a dedicated PAR endpoint using Lockspire's supported direct-call client authentication rules and receive a server-issued `request_uri` plus `expires_in`.

### Authorization Lifecycle

- [ ] **PAR-02**: OAuth clients can complete the existing authorization code + PKCE flow by presenting a PAR-issued `request_uri`, and Lockspire enforces expiry, client binding, and replay-resistant single use for that reference.

### Discovery and Support Truth

- [ ] **PAR-03**: Integrators can discover PAR support through truthful metadata and docs that advertise only the implemented PAR slice and do not imply request-object-by-value, dynamic registration, or device-flow support.

### Verification

- [ ] **PAR-04**: Maintainers have automated protocol, security, and integration coverage for PAR success, expiry, wrong-client usage, replay rejection, and discovery truth before the milestone can close.

### Release Hygiene

- [ ] **RELS-04**: Maintainers can run the checked-in preview release path without the known deprecated GitHub Actions runtime warning while keeping release automation and maintainer docs aligned.

## v2+ Requirements

### Request Objects and Policy

- **JAR-01**: Clients can send signed or encrypted request objects by value or through richer PAR/JAR interoperability modes.
- **PAR-05**: Operators can require PAR globally or per client when stronger request-path policy is needed.

### Additional Protocol Breadth

- **DCR-01**: Developers can self-register OAuth clients through dynamic client registration.
- **DEVICE-01**: Devices can complete OAuth authorization through the device authorization grant.

## Out of Scope

| Feature | Reason |
|---------|--------|
| Dynamic client registration in v1.2 | Expands client trust and operator scope beyond the narrow PAR wedge. |
| Device authorization flow in v1.2 | Introduces a separate interaction model instead of extending the existing browser authorization path. |
| Sender-constrained token modes in v1.2 | Valuable later, but not required to prove the PAR extension cleanly. |
| Generic external `request_uri` support in v1.2 | The milestone should only support request references issued by Lockspire's PAR endpoint. |
| JAR-by-value support in v1.2 | PAR is the intended narrow first step; broader request-object work would blur scope and docs. |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| PAR-01 | Phase 14 | Pending |
| PAR-02 | Phase 15 | Pending |
| PAR-03 | Phase 15 | Pending |
| PAR-04 | Phase 16 | Pending |
| RELS-04 | Phase 16 | Pending |

**Coverage:**
- v1.2 requirements: 5 total
- Mapped to phases: 5
- Unmapped: 0 ✓

---
*Requirements defined: 2026-04-24*
*Last updated: 2026-04-24 after creating the v1.2 roadmap*
