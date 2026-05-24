# Lockspire Milestone v1.23 Requirements

## Milestone

**Version:** `v1.23`  
**Name:** `DCR Logout Metadata`

**Goal:** Let self-service clients manage Lockspire's existing logout propagation metadata through DCR and RFC 7592 while preserving the current logout support truth model.

## v1 Requirements

### DCR Intake

- [ ] **DCR-01**: A self-service client can submit `backchannel_logout_uri` during RFC 7591 registration when the value is a valid supported absolute URI for Lockspire's shipped logout propagation slice.
- [ ] **DCR-02**: A self-service client can submit `backchannel_logout_session_required` during RFC 7591 registration and Lockspire stores it with the correct boolean semantics.
- [ ] **DCR-03**: A self-service client can submit `frontchannel_logout_uri` during RFC 7591 registration when the value is a valid supported absolute URI for Lockspire's shipped logout propagation slice.
- [ ] **DCR-04**: A self-service client can submit `frontchannel_logout_session_required` during RFC 7591 registration and Lockspire stores it with the correct boolean semantics.
- [ ] **DCR-05**: A registrant receives RFC-shaped `invalid_client_metadata` failures when any logout propagation metadata is malformed, unsupported, or semantically invalid.

### Registration Management

- [ ] **DCRM-01**: A self-service client can read its stored logout propagation metadata through RFC 7592 management responses.
- [ ] **DCRM-02**: A self-service client can replace its stored logout propagation metadata through RFC 7592 update flows without breaking full-replace semantics or registration access token rotation.
- [ ] **DCRM-03**: DCR management preserves existing provenance, auditability, and operator/admin truth while exposing the same persisted logout metadata across self-service and operator views.

### Proof And Support Truth

- [ ] **PROOF-01**: Repo-native automated tests cover positive and negative registration plus management cases for the four logout propagation metadata fields.
- [ ] **PROOF-02**: Public docs and operator guidance state that DCR now manages existing logout propagation metadata while preserving Lockspire's current asymmetry: back-channel logout is durable and front-channel logout is best effort only.

## Future Requirements

- [ ] **FUTURE-01**: Add `client_secret_jwt` support on Lockspire-owned direct-client endpoints after v1.23 if adopter pull justifies it.
- [ ] **FUTURE-02**: Add more advanced operator and doctor coverage for logout propagation, `jwks_uri` rotation, mTLS, and protected-route setup if support burden becomes the next real friction point.

## Out Of Scope

- Full federation metadata ingestion.
- Any new logout runtime beyond the already-shipped back-channel and front-channel behavior.
- Reframing front-channel logout as reliable remote success.
- Hosted-auth, CIAM, or broader third-party compatibility expansion.
- Expanding this milestone into unrelated DCR features.

## Traceability

- `Phase 85` covers `DCR-01` through `DCR-05` and `DCRM-01`.
- `Phase 86` covers `DCRM-02`, `DCRM-03`, and `PROOF-01`.
- `Phase 87` covers `PROOF-02`.
