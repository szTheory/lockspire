# Milestone v1.15: JWKS URI & Private Key JWT Client Authentication

**Status:** Planned
**Phases:** 59-62
**Total Plans:** 13

## Overview

v1.15 closes the strongest remaining confidential-client authentication gap in Lockspire’s embedded-provider surface. The milestone keeps the scope narrow: accept guarded `jwks_uri` registration where appropriate, harden remote JWKS resolution, upgrade `private_key_jwt` from structural validation to full cryptographic verification across Lockspire-owned direct client-auth surfaces, and publish the resulting surface truthfully in metadata, docs, telemetry, and release-proof tests.

## Phases

### Phase 59: Registration, Policy & Metadata Truth
**Goal**: Clients and operators can configure the `private_key_jwt` slice truthfully, and discovery/endpoint metadata advertise only what Lockspire will actually verify.
**Depends on**: None (v1.14 completed)
**Requirements**: REG-01, REG-02, REG-03, META-01, META-02
**Plans**: 3 plans

Plans:

- [x] 59-01: DCR and RFC 7592 `jwks_uri` intake/update rules for the narrow client-auth slice
- [x] 59-02: Admin/policy truth for `private_key_jwt` and assertion signing algorithms
- [x] 59-03: Discovery, revocation, and introspection auth-method metadata alignment

**Success criteria:**
1. A confidential client can register or update `jwks_uri` only within the supported `private_key_jwt` slice.
2. `jwks` and `jwks_uri` stay mutually exclusive with explicit validation errors.
3. Discovery and endpoint metadata advertise `private_key_jwt` and signing algorithms only where the repo will enforce them.

**Details:**
This phase defines the milestone’s contract. It keeps the remote-key story bounded to Lockspire’s direct client-auth wedge and aligns DCR, admin policy, and RFC 8414-style metadata truth before the fetcher or verifier work begins.

### Phase 60: Guarded Remote JWKS Resolution
**Goal**: Lockspire can retrieve client key material from `jwks_uri` safely enough to stay embedded and trustworthy.
**Depends on**: Phase 59
**Requirements**: JWKS-01, JWKS-02, JWKS-03
**Plans**: 3 plans

Plans:

- [ ] 60-01: Harden `Lockspire.JwksFetcher` request policy and failure model
- [ ] 60-02: Enforce network-target safety and response-size boundaries
- [ ] 60-03: Cache TTL, refresh, and key-rotation recovery behavior

**Success criteria:**
1. Unsafe `jwks_uri` targets are rejected before sensitive outbound fetches are made.
2. Redirects, oversized payloads, and slow upstreams fail closed as `invalid_client` outcomes.
3. A client can rotate keys at `jwks_uri` without re-registration, using a bounded refresh path.

**Details:**
This phase turns the existing fetcher into a security boundary rather than a convenience helper. The objective is not general remote-ingestion infrastructure; it is a narrow, testable key-resolution path for client authentication only.

### Phase 61: Shared Private Key JWT Verification
**Goal**: All Lockspire-owned direct client-auth surfaces enforce full `private_key_jwt` verification consistently.
**Depends on**: Phase 60
**Requirements**: PKJWT-01, PKJWT-02, PKJWT-03, PKJWT-04, PKJWT-05, PKJWT-06, OBS-01
**Plans**: 4 plans

Plans:

- [ ] 61-01: Split `ClientAuth` into lookup, key resolution, signature verification, and claims validation stages
- [ ] 61-02: Enforce issuer-bound audience, algorithm allowlists, TTL/skew, and replay ordering
- [ ] 61-03: Wire verified `private_key_jwt` behavior across token-adjacent direct-client endpoints
- [ ] 61-04: Telemetry, audit, and redaction proof for auth failures and replay outcomes

**Success criteria:**
1. An attacker-signed or unsigned `client_assertion` can no longer pass Lockspire’s `private_key_jwt` path.
2. `iss`, `sub`, `aud`, `exp`, `iat`/`nbf`, and `jti` are all enforced with repo-proven failure behavior.
3. Every endpoint that already reuses `ClientAuth` handles registered `private_key_jwt` clients consistently.

**Details:**
This is the core milestone phase. It converts today’s partial implementation into a truthful one by making signature trust, claim validation, and replay handling explicit and shared rather than endpoint-specific.

### Phase 62: Docs, Verification & Closure
**Goal**: The shipped client-auth surface is understandable, executable, and release-truthful.
**Depends on**: Phase 61
**Requirements**: DOC-01, V-01, V-02, V-03
**Plans**: 3 plans

Plans:

- [ ] 62-01: Integrator docs and SECURITY truth for `jwks_uri` and `private_key_jwt`
- [ ] 62-02: End-to-end and negative-path verification across representative direct-client endpoints
- [ ] 62-03: Release-contract, traceability, and milestone-closure proof

**Success criteria:**
1. Integrators can understand the supported `jwks_uri` / `private_key_jwt` slice from docs alone.
2. Verification proves positive-path auth, negative-path rejection, and remote-key rotation behavior.
3. Planning, docs, and metadata all describe the same shipped surface with no widened claims.

**Details:**
This phase closes the milestone the same way Lockspire closes other trust-sensitive work: executable proof first, then support-surface truth, then milestone bookkeeping.

---

## Milestone Summary

**Decimal Phases:**

- None

**Key Decisions:**

- Keep the milestone limited to `jwks_uri` plus `private_key_jwt`; do not widen into `client_secret_jwt`, mTLS, or federation trust chains.
- Use issuer-identifier audience validation for `private_key_jwt` in response to the January 2025 OpenID Foundation disclosure rather than permissive endpoint-based audience matching.
- Reuse Lockspire’s shared `ClientAuth` seam so one hardened implementation raises trust across all direct-client endpoint surfaces that already depend on it.

**Issues To Resolve:**

- The existing `private_key_jwt` path validates TTL and replay but not cryptographic signature trust.
- The existing `JwksFetcher` needs stricter fetch safety before it can back a security-sensitive auth flow.
- Discovery and endpoint metadata must become explicit about signing algorithms wherever JWT client authentication is supported.

**Issues Deferred:**

- `client_secret_jwt`
- mTLS client authentication
- signed metadata / federation-style key trust

---

_For current project status, see `.planning/STATE.md`_
