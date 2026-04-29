# Requirements: Lockspire

**Defined:** 2026-04-29
**Core Value:** A Phoenix team can become a trustworthy OAuth/OIDC provider inside its existing app without inventing the dangerous parts itself.

## v1 Requirements

### Authorization

- [ ] **AUTHZ-01**: Add RSA/EC encryption keypairs (`enc`) to `Storage.KeyStore` and JWKS endpoints.
- [ ] **AUTHZ-02**: Implement nested JWT validation (Sign-then-Encrypt) in `Protocol.Jar` using `JOSE.JWE` and `JOSE.JWS`.

## v2 Requirements

*(None)*

## Out of Scope

| Feature | Reason |
|---------|--------|
| Implicit Flow / Form Post | Deprecated by OAuth 2.1 due to token leakage. |
| Stateful OP Sessions in Core | Host app must own the web session; Lockspire relies on a handoff seam. |
| Custom Logout Protocols | Stick to OIDC Back-Channel Logout to ensure interoperability. |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| AUTHZ-01 | Phase 40 | Pending |
| AUTHZ-02 | Phase 40 | Pending |

**Coverage:**
- v1 requirements: 2 total
- Mapped to phases: 2
- Unmapped: 0 ✓

---
*Requirements defined: 2026-04-29*
*Last updated: 2026-04-29 after milestone archive*
