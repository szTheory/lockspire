# Requirements: Lockspire v1.24 — client_secret_jwt

**Status:** Draft
**Defined:** 2026-05-24
**Milestone:** v1.24 client_secret_jwt
**Core Value:** A Phoenix team can become a trustworthy OAuth/OIDC provider inside its existing app without inventing the dangerous parts itself.

**Milestone goal:** Add a narrow `client_secret_jwt` client-authentication slice on Lockspire-owned direct-client endpoints while preserving hashed-at-rest secret handling, strict replay and audience rules, and truthful support posture.

## Capability Selection Rubric

| Capability family | Route-owner expectation | Bridge frequency | Permission / policy sensitivity | Support-matrix impact | Proof required | Package classification |
|-------------------|-------------------------|------------------|----------------------------------|-----------------------|----------------|------------------------|
| `client_secret_jwt` on shared direct-client endpoints | Lockspire-owned OAuth/OIDC direct-client endpoints only | low-frequency semantic | high | medium | repo-native automated proof | `core` |

## Packaging Ledger

| Surface | Classification | Notes |
|---------|----------------|-------|
| Shared `client_secret_jwt` verifier and auth-method resolution | `core` | Reuses the current shared direct-client auth pipeline. |
| Registration, DCR, discovery, and admin truth for `client_secret_jwt` | `core` | Required for a truthful shipped protocol surface. |
| Supported-surface and host/operator guidance updates | `example/docs-only` | Documentation only; no new runtime surface. |
| Generic JWT client-auth, broader secret-management tooling, or federation trust expansion | `defer` | Outside this milestone's narrow embedded-library wedge. |

## Proof Posture Gate

- **Merge-blocking hermetic proof:** protocol/runtime tests for valid and invalid `client_secret_jwt` assertions across representative direct-client endpoints; DCR/discovery/admin truth tests; release-contract doc truth.
- **Advisory proof:** none required beyond repo-native ExUnit coverage.
- **Doctor coverage:** defer unless a concrete runtime need emerges during implementation.
- **Support-matrix updates:** `docs/supported-surface.md` and related host/operator docs must state the narrow symmetric-JWT slice truthfully.

## Support Truth Gate

- **Denial/fallback behavior:** invalid or missing assertions fail closed as `invalid_client`; Lockspire does not silently fall back from `client_secret_jwt` to `client_secret_basic` or `client_secret_post`.
- **Missing prerequisite behavior:** clients without a configured confidential secret or without a declared signing algorithm cannot use `client_secret_jwt`.
- **Native rebuilds required:** none.
- **Rough-edge docs to publish:** audience rule, accepted signing algorithms, replay posture, FAPI non-claim, and direct-client endpoint scope.

## v1.24 Requirements

Each requirement is atomic, testable, and traceable to exactly one phase. Phase numbering continues from v1.23 (closed at Phase 87); v1.24 starts at Phase 88.

### Runtime Authentication

- [ ] **AUTH-01**: A confidential client registered for `client_secret_jwt` can authenticate successfully on Lockspire-owned shared direct-client endpoints using a valid signed assertion instead of `client_secret_basic` or `client_secret_post`.
- [ ] **AUTH-02**: Lockspire rejects malformed, replayed, expired, audience-mismatched, method-mismatched, or algorithm-disallowed `client_secret_jwt` assertions with standard `invalid_client` behavior across the shared direct-client surfaces.

### Registration And Metadata Truth

- [ ] **REG-01**: Operator-created and self-service confidential clients can register and persist `token_endpoint_auth_method=client_secret_jwt` only when the client metadata includes a supported `token_endpoint_auth_signing_alg` value that matches Lockspire's current issuer security posture.
- [ ] **REG-02**: Registration, RFC 7592 management, and admin/operator views preserve Lockspire's current secret-handling truth: raw client secrets and raw assertions are never exposed, and `client_secret_jwt` metadata stays coherent with the stored client auth method.

### Discovery And Security Posture

- [ ] **META-01**: Discovery and per-endpoint metadata publish `client_secret_jwt` and the corresponding signing-algorithm metadata only on endpoints that actually consume the shared direct-client verifier.
- [ ] **META-02**: Lockspire's public support contract and security posture remain truthful after the milestone: `client_secret_jwt` is documented as a narrow direct-client option and does not broaden FAPI, mTLS, or stronger-trust claims.

### Proof

- [ ] **PROOF-01**: Repo-native automated tests cover positive and negative `client_secret_jwt` runtime behavior plus registration, discovery, admin, and documentation truth for the shipped slice.

## Future Requirements

Acknowledged but deferred beyond v1.24.

### Future Direct-Client And Support Work

- **AUTH-FUT-01**: Broader symmetric JWT client-auth policy controls such as per-client secret rotation UX or wider algorithm-matrix support if real integrator demand emerges.
- **SUPPORT-FUT-01**: Advanced setup diagnostics and operator/doctor guidance for `jwks_uri` rotation, mTLS, protected-route setup, and other remaining support-burden edges.

## Out of Scope

Explicitly excluded to keep v1.24 narrow and coherent.

| Feature | Reason |
|---------|--------|
| Generic JWT client-auth beyond Lockspire-owned direct-client endpoints | This milestone is about one narrow direct-client slice, not a new general JWT auth framework. |
| Recoverable secret storage, secret escrow, or new secret-management surfaces | Lockspire's current secret-at-rest posture must remain intact. |
| Broader FAPI, mTLS, or certification claims | `client_secret_jwt` is a convenience auth method, not a stronger-trust expansion. |
| Hosted auth, federation, SAML, LDAP, or new package boundaries | All of these widen Lockspire beyond the embedded Phoenix provider wedge. |
| Support-burden work unrelated to truthful `client_secret_jwt` operation | Keep this milestone focused on the direct-client auth gap first. |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| AUTH-01 | Phase 88 | Pending |
| AUTH-02 | Phase 88 | Pending |
| REG-01 | Phase 89 | Pending |
| REG-02 | Phase 89 | Pending |
| META-01 | Phase 89 | Pending |
| META-02 | Phase 90 | Pending |
| PROOF-01 | Phase 90 | Pending |

**Coverage:**
- v1.24 requirements: 7 total
- Mapped to phases: 7
- Unmapped: 0
