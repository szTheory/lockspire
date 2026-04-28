# Requirements: v1.6 Device Authorization Grant (RFC 8628)

## Active Requirements

### CORE: Device Authorization Endpoint
- **DEV-01**: Implement `POST /device/code` endpoint to initiate device authorization.
- **DEV-02**: Generate high-entropy `device_code` and low-entropy `user_code` (Base20).
- **DEV-03**: Create Ecto schema and storage for tracking pending device codes with strict TTLs (5-10 minutes).

### HOST: Verification UI Seam
- **DEV-04**: Expose `GET /verify` and `POST /verify` integration seams for the host app to render consent/verification UI.
- **DEV-05**: Prevent auto-submit on `verification_uri_complete` to mitigate remote phishing.
- **DEV-06**: Provide documentation on rate-limiting the `/verify` endpoint for the host app (no built-in rate limiting).

### TOKEN: Polling & Issuance
- **DEV-07**: Implement `POST /token` support for `grant_type=urn:ietf:params:oauth:grant-type:device_code`.
- **DEV-08**: Handle `authorization_pending`, `slow_down`, and token issuance on the `/token` endpoint.
- **DEV-09**: Enforce polling intervals and prevent database crush via efficient Ecto queries.

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| DEV-01 | Phase 30 | Pending |
| DEV-02 | Phase 30 | Pending |
| DEV-03 | Phase 30 | Pending |
| DEV-04 | Phase 31 | Pending |
| DEV-05 | Phase 31 | Pending |
| DEV-06 | Phase 31 | Pending |
| DEV-07 | Phase 32 | Complete |
| DEV-08 | Phase 32 | Complete |
| DEV-09 | Phase 32 | Complete (32-01) |
