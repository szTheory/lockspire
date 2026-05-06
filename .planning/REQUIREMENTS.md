# Requirements: Lockspire v1.15 — JWKS URI & Private Key JWT Client Authentication

**Defined:** 2026-05-06
**Milestone:** v1.15 JWKS URI & Private Key JWT Client Authentication
**Core Value:** A Phoenix team can become a trustworthy OAuth/OIDC provider inside its existing app without inventing the dangerous parts itself.

**Milestone goal:** Close the strongest remaining confidential-client authentication gap by adding safe `jwks_uri` support and repo-proven `private_key_jwt` validation across Lockspire-owned direct client-auth surfaces without widening the embedded-library shape.

## v1.15 Requirements

Each requirement is atomic, testable, and traceable to a phase. Phase numbering continues from v1.14 (closed at Phase 58); v1.15 starts at Phase 59.

### Registration & Policy Truth

- [ ] **REG-01**: Dynamic registration and RFC 7592 client-management flows accept `jwks_uri` for confidential clients using `token_endpoint_auth_method=private_key_jwt`, enforce `jwks` xor `jwks_uri`, and reject unsupported combinations with explicit `invalid_client_metadata` reasons.
- [ ] **REG-02**: `jwks_uri` acceptance is bounded to `https` URLs and Lockspire’s narrow client-auth slice; the milestone does not widen into generic remote metadata ingestion, software statements, or federation trust chains.
- [ ] **REG-03**: Operator policy and admin surfaces truthfully expose whether `private_key_jwt` is allowed for self-registered clients and which signing algorithms the issuer will accept for JWT client assertions.

### Secure Remote JWKS Resolution

- [ ] **JWKS-01**: Remote JWKS retrieval is SSRF-guarded: `https` only, redirects disabled, retries disabled on the synchronous auth path, response body size capped, and connection/read timeouts kept intentionally low.
- [ ] **JWKS-02**: Remote JWKS retrieval resolves only publicly routable network targets and rejects loopback, link-local, private-network, and otherwise unsafe address destinations before making the request.
- [ ] **JWKS-03**: Successful `jwks_uri` retrievals are cached with explicit TTL behavior, and verification is allowed one forced refresh path on key miss or signature mismatch so normal client key rotation does not require re-registration.

### Shared Private Key JWT Verification

- [ ] **PKJWT-01**: `Lockspire.Protocol.ClientAuth` performs full cryptographic verification of `client_assertion` signatures using the registered client key material from inline `jwks` or resolved `jwks_uri`.
- [ ] **PKJWT-02**: `private_key_jwt` rejects `alg=none`, symmetric algorithms, and unsupported signing algorithms; accepted algorithms stay aligned with the issuer’s published metadata and security posture.
- [ ] **PKJWT-03**: Client assertion claim validation requires `iss` and `sub` to equal the authenticated `client_id`, requires a valid `exp`, enforces bounded assertion lifetime, and validates `iat`/`nbf` with controlled skew handling.
- [ ] **PKJWT-04**: Lockspire validates `aud` for `private_key_jwt` against the issuer identifier string rather than permissive endpoint-based audience matching, and the rule is documented as an explicit security choice for the milestone.
- [ ] **PKJWT-05**: Durable `jti` replay protection remains required, but replay state is only recorded after signature and claim validation succeed so invalid assertions cannot poison the replay store.
- [ ] **PKJWT-06**: The shared direct-client auth seam accepts registered `private_key_jwt` consistently across Lockspire-owned direct client-auth surfaces, including token, pushed authorization, device authorization, token exchange, revocation, introspection, and CIBA backchannel authentication flows that already depend on `ClientAuth`.

### Discovery, Docs & Observability

- [ ] **META-01**: Discovery metadata truthfully advertises `private_key_jwt` support for the token endpoint and publishes `token_endpoint_auth_signing_alg_values_supported` whenever that method is supported.
- [ ] **META-02**: Revocation and introspection metadata truthfully advertise their supported client authentication methods and associated signing algorithms whenever `private_key_jwt` is accepted there.
- [ ] **DOC-01**: SECURITY and integrator-facing docs explain the supported `jwks_uri` / `private_key_jwt` slice, including remote-fetch boundaries, audience expectations, key rotation behavior, and explicit out-of-scope exclusions.
- [ ] **OBS-01**: Telemetry, audit, and logs capture failure reasons for remote JWKS retrieval, signature validation, audience mismatch, and replay detection without leaking client assertions or private key material.

### Verification & Closure

- [ ] **V-01**: End-to-end proof covers self-registered or operator-created clients using inline `jwks` and `jwks_uri` to authenticate with `private_key_jwt` on representative Lockspire-owned direct-client endpoints.
- [ ] **V-02**: Negative-path proof covers redirect rejection, unsafe-address rejection, wrong audience, expired assertion, bad signature, unsupported algorithm, replay, and stale-cache rotation recovery behavior.
- [ ] **V-03**: Milestone v1.15 closes with 100% traceability, truthful discovery/docs alignment, and release-contract proof for the shipped client-auth surface only.

## Future Requirements

Acknowledged but deferred beyond v1.15.

### Client Authentication Expansion

- **AUTH-FUT-01**: `client_secret_jwt` support with truthful metadata and symmetric-key policy controls.
- **AUTH-FUT-02**: Signed or otherwise stronger remote JWKS metadata trust models (`signed_jwks_uri`, federation-style metadata, or equivalent).
- **AUTH-FUT-03**: Background JWKS prefetch / proactive refresh scheduling if production evidence shows synchronous refresh is insufficient.

### Broader Security Surface

- **AUTH-FUT-04**: mTLS client authentication or certificate-bound access tokens.
- **AUTH-FUT-05**: Multi-issuer compatibility knobs for legacy endpoint-based `aud` handling if a future ecosystem need justifies the risk budget.

## Out of Scope

Explicitly excluded to keep v1.15 narrow and truthful.

| Feature | Reason |
|---------|--------|
| `client_secret_jwt` | Broadens the auth-method matrix without delivering the same trust gain as asymmetric client assertions in this milestone. |
| mTLS client authentication | Conflicts with Lockspire’s embedded Phoenix deployment shape and pushes correctness into edge proxy infrastructure. |
| Signed metadata / federation trust chains | Expands into trust-distribution problems far beyond the narrow DCR and direct-client auth wedge. |
| Generic outbound fetch framework | v1.15 needs a single-purpose guarded JWKS fetch path, not a reusable remote-ingestion platform. |
| Host-owned remote key resolution | The dangerous part belongs inside Lockspire so the host app does not have to reimplement security-sensitive fetch and validation logic. |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| REG-01 | Phase 59 | Planned |
| REG-02 | Phase 59 | Planned |
| REG-03 | Phase 59 | Planned |
| JWKS-01 | Phase 60 | Planned |
| JWKS-02 | Phase 60 | Planned |
| JWKS-03 | Phase 60 | Planned |
| PKJWT-01 | Phase 61 | Planned |
| PKJWT-02 | Phase 61 | Planned |
| PKJWT-03 | Phase 61 | Planned |
| PKJWT-04 | Phase 61 | Planned |
| PKJWT-05 | Phase 61 | Planned |
| PKJWT-06 | Phase 61 | Planned |
| META-01 | Phase 59 | Planned |
| META-02 | Phase 59 | Planned |
| DOC-01 | Phase 62 | Planned |
| OBS-01 | Phase 61 | Planned |
| V-01 | Phase 62 | Planned |
| V-02 | Phase 62 | Planned |
| V-03 | Phase 62 | Planned |

**Coverage:**
- v1.15 requirements: 19 total
- Mapped to phases: 19
- Unmapped: 0
