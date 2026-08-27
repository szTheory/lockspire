# Requirements: Lockspire v1.37 Prime-Time Readiness Ratchet

**Defined:** 2026-08-26
**Core Value:** A Phoenix team can become a trustworthy OAuth/OIDC provider inside its existing app without inventing the dangerous parts itself.

## v1.37 Requirements

### Executable Installation

- [x] **INST-01**: A Phoenix adopter can invoke the generated Lockspire router helper and receive real host, guarded-admin, consent, and public protocol routes in the documented order.
- [x] **INST-02**: A Phoenix adopter can render a host-branded consent LiveView backed by real Lockspire interaction state and the supported completion flow.
- [x] **INST-03**: A Phoenix adopter can install and upgrade Lockspire migrations idempotently without undocumented dependency paths, overwritten host files, or silent migration-version collisions.
- [x] **INST-04**: A Phoenix adopter receives every required Lockspire configuration seam, including logout behavior, and `mix lockspire.verify` reports missing configuration with executable remediation.
- [x] **INST-05**: A newly generated host can run its default Lockspire tests under default secure configuration, while FAPI-specific proof remains explicitly opt-in.
- [x] **INST-06**: A Phoenix adopter can compile and adapt the generated `%Lockspire.Host.Claims{}` example using the real `subject`, `id_token`, and `userinfo` fields.

### Public API and Resource Server Truth

- [x] **API-01**: A resource-server adopter can read normalized subject, scopes, audiences, expiration, and confirmation data through additive `Lockspire.AccessToken` accessors without depending on raw JWT claim shapes.
- [x] **API-02**: A Phoenix adopter can register the client shapes Lockspire advertises and supports, including OIDC `openid`, `private_key_jwt`, and device-only clients, while redirect-based clients retain exact URI validation.
- [x] **API-03**: A resource-server adopter can use durable DPoP replay protection through the configured Lockspire repository by default and can inject a compatible custom store when needed.
- [x] **API-04**: A Phoenix adopter can follow resource-server documentation whose code, access-token contract, authorization boundary, and deprecation guidance match shipped behavior.

### Clean-Room SaaS Journey

- [x] **E2E-01**: A clean Phoenix/Ecto SaaS host can install packaged Lockspire, apply documented host-owned edits, migrate, verify, test, and boot without internal Lockspire modules or hand-written replacement routes.
- [x] **E2E-02**: A separate-origin confidential Phoenix client can persist random state, nonce, and PKCE material, complete authorization, exchange the code, and reject callback state mismatches.
- [x] **E2E-03**: The external client can validate discovery, JWKS, ID-token signature, issuer, audience, nonce, and userinfo subject before calling an audience-and-scope-protected SaaS API.
- [x] **E2E-04**: The external client can rotate refresh tokens, trigger old-token reuse detection and family-wide revocation, and exercise authenticated introspection and revocation with truthful JWT lifetime semantics.
- [x] **E2E-05**: The clean-room journey rejects redirect drift, authorization-code reuse, state and nonce mismatch, missing tokens, wrong audiences, and insufficient scopes with the documented outcomes.
- [x] **E2E-06**: The clean-room journey completes a DPoP nonce challenge and retry, then rejects replay of the identical proof without exposing secrets or tokens in logs or retained artifacts.

### Architecture Topology

- [ ] **ARCH-01**: Maintainers can run an executable dependency check that reports zero Lockspire runtime/export dependency cycles while preserving existing public nested module names.
- [ ] **ARCH-02**: Protocol modules depend only on neutral core/application and storage ports, never on Phoenix web delivery or operator-admin modules.
- [ ] **ARCH-03**: DCR and operator workflows share one neutral client metadata and lifecycle service while preserving their existing public result shapes and security behavior.
- [ ] **ARCH-04**: Architecture fitness tests fail when dependency direction, public/internal boundaries, or zero-cycle topology regress.

### Cohesive Internals

- [ ] **COH-01**: Maintainers can navigate aggregate-specific Ecto implementations behind the existing `Lockspire.Storage.Ecto.Repository` facade instead of one monolithic adapter.
- [ ] **COH-02**: Authorization-code redemption, refresh reuse handling, DCR-plus-audit writes, and key transitions remain atomic under rollback and concurrency proof after the storage split.
- [ ] **COH-03**: Token grant internals separate authentication, resource selection, issuance, persistence, polling, and observability responsibilities behind the stable token facade.
- [ ] **COH-04**: Internal collaborators receive explicit dependency bundles instead of capability sniffing or runtime `Mix.env()` behavior, while current injection compatibility remains supported.
- [ ] **COH-05**: Characterization tests prove that refactoring preserves endpoint responses, errors, tokens, audit events, and telemetry across authorization-code, refresh, device, CIBA, and token-exchange paths.

### Static Analysis and Sustainable Proof

- [ ] **QUAL-01**: Credo evaluates every library source file without file-wide suppression; any local suppression is named, narrow, and justified.
- [ ] **QUAL-02**: Admin and release proof uses small capability-oriented helpers and behavioral assertions instead of giant injected test macros, assertion-count contracts, or obsolete phase archaeology.
- [ ] **QUAL-03**: Happy-path test runs emit no KeyCache startup errors, routine Ecto query flood, or local telemetry-handler warnings while failure and redaction log assertions remain effective.
- [ ] **QUAL-04**: Compilation, strict Credo, zero-warning Dialyzer, ExDoc, package build, and focused integration proof remain green through all structural changes.

### CI, Conformance, and Release Proof

- [ ] **CI-01**: CI scans both public and admin routers with fail-closed Sobelow at low severity and rejects missing-router scans or unexplained broad ignores.
- [ ] **CI-02**: CI executes fast and integration tests once each, aggregates exported coverage, and enforces a truthful complete-suite floor of at least 84%.
- [ ] **CI-03**: CI fails on unused locked dependencies and new compile-connected cycles, and the adoption demo receives controlled dependency updates without changing minimum-version fixtures.
- [ ] **CONF-01**: Maintainers can run OIDC/FAPI conformance evidence from immutable suite images, source revisions, downloads, and checksums rather than mutable `latest` or `master` inputs.
- [ ] **CONF-02**: A scheduled repo-native conformance lane retains redacted evidence and remains supplemental until measured reliability justifies any stronger gate or certification claim.
- [ ] **REL-01**: Release automation proves a clean-room install, migration, verification, boot, and minimal HTTP journey against the built artifact before publish and the exact public version after publish.
- [ ] **REL-02**: Maintainers can verify that the published Hex checksum matches the produced artifact and can inspect a retained redacted release manifest with pinned runtime/tooling versions.

## Future Requirements

### Certification and Operator Experience

- **CERT-01**: Maintainers can pursue formal external OIDF certification after the reproducible conformance lane has stable evidence and an intentionally supported certification profile.
- **ADMIN-01**: Operators can receive another visual and interaction review when maintainer review capacity is available and concrete operator evidence identifies a bounded improvement target.

## Out of Scope

| Feature | Reason |
|---------|--------|
| New OAuth/OIDC grants or endpoints | The milestone proves and hardens the already-supported product wedge rather than widening protocol breadth. |
| Breaking public API removals or shape changes | v1.37 is additive and deprecation-only; existing v1.x adopters remain compatible. |
| Admin visual redesign or manual screenshot approval | The user cannot review visual work now, and integration/readiness gaps have higher leverage. |
| Formal certification claim | Reproducible evidence and reliability history must precede any external certification statement. |
| Immediate revocation of already-issued self-contained JWTs at offline resource servers | Offline JWT validation remains bounded by token lifetime unless a future explicit online-enforcement design is adopted. |
| Hosted auth, standalone service deployment, SAML, LDAP/AD, or CIAM breadth | These violate Lockspire's embedded Phoenix library boundary. |
| Host-owned accounts, sessions, login, branding, tenant policy, or operator authentication | These remain explicit host application responsibilities. |

## Traceability

Roadmap phase mapping is populated during milestone roadmapping.

| Requirement | Phase | Status |
|-------------|-------|--------|
| INST-01 | 131 | Complete |
| INST-02 | 131 | Complete |
| INST-03 | 131 | Complete |
| INST-04 | 131 | Complete |
| INST-05 | 131 | Complete |
| INST-06 | 131 | Complete |
| API-01 | 132 | Complete |
| API-02 | 132 | Complete |
| API-03 | 132 | Complete |
| API-04 | 132 | Complete |
| E2E-01 | 133 | Complete |
| E2E-02 | 133 | Complete |
| E2E-03 | 133 | Complete |
| E2E-04 | 133 | Complete |
| E2E-05 | 133 | Complete |
| E2E-06 | 133 | Complete |
| ARCH-01 | 134 | Pending |
| ARCH-02 | 134 | Pending |
| ARCH-03 | 134 | Pending |
| ARCH-04 | 134 | Pending |
| COH-01 | 135 | Pending |
| COH-02 | 135 | Pending |
| COH-03 | 135 | Pending |
| COH-04 | 135 | Pending |
| COH-05 | 135 | Pending |
| QUAL-01 | 136 | Pending |
| QUAL-02 | 136 | Pending |
| QUAL-03 | 136 | Pending |
| QUAL-04 | 136 | Pending |
| CI-01 | 137 | Pending |
| CI-02 | 137 | Pending |
| CI-03 | 137 | Pending |
| CONF-01 | 137 | Pending |
| CONF-02 | 137 | Pending |
| REL-01 | 137 | Pending |
| REL-02 | 137 | Pending |

**Coverage:**

- v1.37 requirements: 36 total
- Mapped to phases: 36
- Unmapped: 0

---
*Requirements defined: 2026-08-26*
*Last updated: 2026-08-26 after initial definition*
