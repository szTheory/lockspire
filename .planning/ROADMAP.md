# v1.20 Mutual TLS (RFC 8705) Roadmap

## Overview
This milestone delivers Mutual TLS (mTLS) for client authentication and sender-constrained tokens, closing the remaining high-leverage trust gap for "real integrator readiness" in high-security environments.

## Architecture & Sequencing
Lockspire will implement mTLS via an explicit extraction behaviour. To preserve host-owned network bounds and prevent proxy header spoofing vulnerabilities, extraction must be explicitly configured by the host app.

## Phases

### Phase 75: MTLS Extraction Foundation
**Goal**: Establish the `Lockspire.MTLS.Extractor` behaviour and safe extraction primitives.
**Plans:** 2/2 plans complete
- [x] 75-01-PLAN.md — Extractors Foundation (Behaviour, CowboyDirect, ProxyHeader)
- [x] 75-02-PLAN.md — MTLS Plug Enforcement

### Phase 76: MTLS Client Authentication
**Goal**: Support mTLS client authentication methods at the token and introspection endpoints.
- **Tasks**:
  - Implement `tls_client_auth` (PKI/CA-based).
  - Implement `self_signed_tls_client_auth` (JWKS-based).
  - Integrate extraction into client authentication resolution.

### Phase 77: Certificate-Bound Tokens
**Goal**: Bind access and refresh tokens to the client certificate.
- **Tasks**:
  - Generate `x5t#S256` token bindings based on the extracted client certificate.
  - Integrate with existing DPoPo `cnf` infrastructure to enforce certificate binding on token usage (e.g., at the `/userinfo` endpoint).

### Phase 78: MTLS Discovery, Documentation & Closure
**Goal**: Truthfully advertise MTLS capabilities and verify end-to-end functionality.
**Plans:** 1/1 plans complete
- [x] 78-01-PLAN.md — MTLS Discovery, Documentation & Closure