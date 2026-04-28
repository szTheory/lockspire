# Requirements: Lockspire

**Defined:** 2026-04-28
**Core Value:** A Phoenix team can become a trustworthy OAuth/OIDC provider inside its existing app without inventing the dangerous parts itself.

## v1 Requirements

### Protocol Conformance

- [ ] **CONF-01**: Implement strict numeric type enforcement (integer vs string) for token timestamps (iat, exp, auth_time).
- [ ] **CONF-02**: Enforce exact `redirect_uri` matching for authorization requests per OIDC specifications.
- [ ] **CONF-03**: Enforce strict validation of `prompt=none`, `max_age`, and `nonce` parameters.
- [ ] **CONF-04**: Setup verifiable automated integration with the OIDF Conformance Test Suite.

### Session and Logout

- [ ] **SLO-01**: Add durable Session ID (`sid`) tracking to interaction and token records.
- [ ] **SLO-02**: Implement `GET /end_session` (RP-Initiated Logout) with host-owned session clearing seam.
- [ ] **SLO-03**: Implement Back-Channel Logout webhook dispatch (server-to-server POST) via `req`.
- [ ] **SLO-04**: Implement Front-Channel Logout asynchronous iframe rendering on host return.

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
| CONF-01 | Phase 37 | Pending |
| CONF-02 | Phase 37 | Pending |
| CONF-03 | Phase 37 | Pending |
| CONF-04 | Phase 37 | Pending |
| SLO-01 | Phase 38 | Pending |
| SLO-02 | Phase 38 | Pending |
| SLO-03 | Phase 39 | Pending |
| SLO-04 | Phase 39 | Pending |
| AUTHZ-01 | Phase 40 | Pending |
| AUTHZ-02 | Phase 40 | Pending |

**Coverage:**
- v1 requirements: 10 total
- Mapped to phases: 10
- Unmapped: 0 ✓

---
*Requirements defined: 2026-04-28*
*Last updated: 2026-04-28 after roadmap creation*
