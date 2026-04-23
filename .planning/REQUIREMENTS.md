# Requirements: Lockspire

**Defined:** 2026-04-22
**Core Value:** A Phoenix team can become a trustworthy OAuth/OIDC provider inside its existing app without inventing the dangerous parts itself.

## v1 Requirements

Requirements for initial release. Each maps to roadmap phases.

### Integration

- [x] **INTE-01**: Host app can install Lockspire as a separate library and mount its routes without requiring a standalone service
- [x] **INTE-02**: Host app can implement an explicit account-resolution seam for login, account lookup, and claim enrichment
- [ ] **INTE-03**: Generated host code provides editable consent and interaction handoff modules that fit a normal Phoenix app
- [ ] **INTE-04**: Host app retains ownership of layouts, branding, login UX, and product-specific policy

### Authorization Core

- [x] **AUTH-01**: Operator can register a client with redirect URIs, grant types, scopes, and client type settings
- [x] **AUTH-02**: Third-party client can start an authorization code flow with PKCE S256
- [x] **AUTH-03**: Lockspire validates redirect URIs by exact match and rejects unsafe authorization requests
- [x] **AUTH-04**: Authenticated account can approve or deny a consent request for requested scopes
- [ ] **AUTH-05**: Third-party client can exchange a valid authorization code for an access token

### OIDC and Token Lifecycle

- [ ] **OIDC-01**: Third-party developer can discover provider metadata through the OIDC discovery endpoint
- [ ] **OIDC-02**: Third-party developer can fetch current signing keys through JWKS
- [ ] **OIDC-03**: OpenID clients receive correct OIDC token material and can fetch user claims through userinfo
- [ ] **TOKN-01**: Client can receive rotating refresh tokens with family-wide revocation on reuse detection
- [ ] **TOKN-02**: Operator or client can revoke supported tokens through the revocation endpoint
- [ ] **TOKN-03**: Authorized systems can inspect token state through introspection

### Operator and Consent Product

- [ ] **OPER-01**: Operator can create, review, update, disable, and rotate credentials for OAuth clients in an admin UI
- [ ] **OPER-02**: Account or operator can review and revoke existing consent grants
- [ ] **OPER-03**: Operator can inspect active token state and refresh-family lineage without shelling into production
- [ ] **OPER-04**: Operator can view key lifecycle state and perform publish, activate, and retire workflows

### Security and Observability

- [ ] **SECU-01**: Lockspire enforces secure defaults including PKCE by default, hashed client secrets, short-lived single-use codes, no implicit flow, and no `alg=none`
- [ ] **SECU-02**: Lockspire emits telemetry and audit events for authorization, token, client, key, consent, and security-relevant actions
- [ ] **SECU-03**: Lockspire redacts secrets and sensitive token material in logs and operator-visible surfaces
- [ ] **SECU-04**: Lockspire has negative-path coverage for malformed, replayed, mismatched, denied, and downgrade-oriented requests

### Release and Onboarding

- [ ] **RELS-01**: A Phoenix team can follow one canonical onboarding path and complete a real authorization flow in a fresh host app
- [ ] **RELS-02**: The repo ships executable docs, CI gates, changelog/release workflow, and publish discipline suitable for a security-sensitive OSS library

## v2 Requirements

Deferred to future release. Tracked but not in current roadmap.

### Advanced Protocol

- **ADVP-01**: Provider supports pushed authorization requests (PAR)
- **ADVP-02**: Provider supports dynamic client registration
- **ADVP-03**: Provider supports device authorization flow
- **ADVP-04**: Provider supports stronger sender-constrained token modes
- **ADVP-05**: Provider targets stronger conformance and certification profiles beyond the baseline release

## Out of Scope

Explicitly excluded. Documented to prevent scope creep.

| Feature | Reason |
|---------|--------|
| SAML IdP | Outside the focused OAuth/OIDC provider wedge |
| LDAP/AD federation | Enterprise federation scope that is not required for v1 |
| Hosted auth product | Conflicts with the embedded-library product shape |
| Full CIAM suite | Would dilute the narrow provider-side value proposition |
| Mandatory theming engine | Host apps should own branding and layouts directly |
| Standalone-service requirement | Increases activation and operating cost without helping the core target user |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| INTE-01 | Phase 1 | Pending |
| INTE-02 | Phase 1 | Pending |
| INTE-03 | Phase 1 | Pending |
| INTE-04 | Phase 1 | Pending |
| AUTH-01 | Phase 2 | Complete |
| AUTH-02 | Phase 2 | Complete |
| AUTH-03 | Phase 2 | Complete |
| AUTH-04 | Phase 2 | Complete |
| AUTH-05 | Phase 2 | Pending |
| OIDC-01 | Phase 3 | Pending |
| OIDC-02 | Phase 3 | Pending |
| OIDC-03 | Phase 3 | Pending |
| TOKN-01 | Phase 3 | Pending |
| TOKN-02 | Phase 3 | Pending |
| TOKN-03 | Phase 3 | Pending |
| OPER-01 | Phase 4 | Pending |
| OPER-02 | Phase 4 | Pending |
| OPER-03 | Phase 4 | Pending |
| OPER-04 | Phase 4 | Pending |
| SECU-01 | Phase 5 | Pending |
| SECU-02 | Phase 5 | Pending |
| SECU-03 | Phase 5 | Pending |
| SECU-04 | Phase 5 | Pending |
| RELS-01 | Phase 6 | Pending |
| RELS-02 | Phase 6 | Pending |

**Coverage:**
- v1 requirements: 25 total
- Mapped to phases: 25
- Unmapped: 0 ✓

---
*Requirements defined: 2026-04-22*
*Last updated: 2026-04-22 after initial definition*
