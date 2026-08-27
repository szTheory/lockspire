# Lockspire Roadmap

## Current Milestone: v1.37 Prime-Time Readiness Ratchet

**Goal:** Make Lockspire's documented embedded-provider path genuinely installable, prove it through a separate SaaS client and resource-server journey, and tighten the architecture and executable quality gates around that truth.

## Phases

- [x] **Phase 131: Executable Installation** — Make the generated Phoenix adoption path run intact from the packaged library. (completed 2026-08-26)
- [x] **Phase 132: Public API and Resource-Server Truth** — Align supported APIs, resource-server behavior, and documentation with what Lockspire actually ships. (completed 2026-08-26)
- [x] **Phase 133: Clean-Room SaaS Journey** — Prove the complete provider, external client, and protected-resource flow over HTTP. (completed 2026-08-27)
- [x] **Phase 134: Architecture Topology** — Enforce a one-directional, cycle-free dependency graph with neutral shared services. (completed 2026-08-27)
- [ ] **Phase 135: Cohesive Internals** — Split storage and grant orchestration into maintainable collaborators without behavioral drift.
- [ ] **Phase 136: Static Analysis and Sustainable Proof** — Make implementation and tests easier to read while retaining meaningful quality evidence.
- [ ] **Phase 137: CI, Conformance, and Release Proof** — Make security, coverage, conformance, and artifact verification reproducible release evidence.

## Phase Details

### Phase 131: Executable Installation

**Goal**: A Phoenix SaaS team can install the packaged library and use the documented generated integration path without replacing Lockspire internals.
**Depends on**: Nothing
**Requirements**: INST-01, INST-02, INST-03, INST-04, INST-05, INST-06
**Success Criteria** (what must be TRUE):

  1. A generated host mounts real host, guarded-admin, consent, and public protocol routes in the documented order.
  2. A host-branded consent LiveView renders real interaction state and completes consent through the supported Lockspire flow.
  3. Install and upgrade copy only missing migrations, preserve host-owned files, and report migration version collisions clearly.
  4. Generated configuration and `mix lockspire.verify` expose every required seam with actionable missing-config remediation.
  5. A new generated host passes its default secure test suite and compiles the documented claims example; FAPI proof is explicitly opt-in.

**Plans**: 7/7 plans executed

- [x] 131-07-PLAN.md

- [x] 131-01-PLAN.md
- [x] 131-02-PLAN.md
- [x] 131-03-PLAN.md
- [x] 131-04-PLAN.md
- [x] 131-05-PLAN.md
- [x] 131-06-PLAN.md

**UI hint**: yes

### Phase 132: Public API and Resource-Server Truth

**Goal**: Adopters can use documented client and resource-server APIs without relying on raw claims or unsupported implementation details.
**Depends on**: Phase 131
**Requirements**: API-01, API-02, API-03, API-04
**Success Criteria** (what must be TRUE):

  1. Resource servers read normalized token subject, scopes, audiences, expiration, and confirmation data through additive `Lockspire.AccessToken` accessors.
  2. Client registration accepts every advertised supported shape, including OIDC, `private_key_jwt`, and device-only clients, while redirect-based flows retain exact URI checks.
  3. DPoP replay protection persists durably through the configured Lockspire repository by default and accepts a compatible custom store.
  4. Resource-server documentation, examples, authorization boundary, and deprecation guidance match shipped behavior.

**Plans**: TBD

### Phase 133: Clean-Room SaaS Journey

**Goal**: A separate-origin SaaS client can safely consume an embedded Lockspire provider and protected API from the built package.
**Depends on**: Phase 132
**Requirements**: E2E-01, E2E-02, E2E-03, E2E-04, E2E-05, E2E-06
**Success Criteria** (what must be TRUE):

  1. A clean Phoenix/Ecto host installs packaged Lockspire, applies only documented host-owned edits, migrates, verifies, tests, and boots without internal modules or replacement routes.
  2. A separate-origin confidential client persists random state, nonce, and PKCE material, completes authorization, and rejects callback state mismatches.
  3. The client validates discovery, JWKS, ID-token signature and claims, and userinfo subject before calling an audience-and-scope-protected API.
  4. Refresh rotation, reuse-triggered family revocation, authenticated introspection, and revocation work with truthful JWT lifetime semantics.
  5. The journey rejects documented redirect, code, token, audience, scope, nonce, and DPoP replay failures without retaining or logging secrets or tokens.

**Plans**: 1/6 plans executed

Plans:

- [x] 133-01-PLAN.md — Establish package provenance, two-process supervision, redaction, and teardown foundations.
- [x] 133-02-PLAN.md — Install and boot the package-clean provider with public bootstrap and protected API.
- [x] 133-03-PLAN.md — Build durable bearer/DPoP client transactions, strict OIDC validation, and the server-owned DPoP session backend.
- [x] 133-04-PLAN.md — Complete the separate-origin code+PKCE, OIDC, userinfo, and protected-resource journey.
- [x] 133-05-PLAN.md — Prove lifecycle truth and the real-HTTP negative matrix.
- [x] 133-06-PLAN.md — Prove durable DPoP replay rejection and wire the full command into CI.

### Phase 134: Architecture Topology

**Goal**: Lockspire's public module structure remains compatible while its runtime dependencies have an explicit, enforceable direction.
**Depends on**: Phase 133
**Requirements**: ARCH-01, ARCH-02, ARCH-03, ARCH-04
**Success Criteria** (what must be TRUE):

  1. Maintainers can run a dependency check that reports no runtime or export cycles while existing nested public module names continue working.
  2. Protocol code reaches only neutral core/application and storage ports, never Phoenix delivery or operator-admin code.
  3. DCR and operator workflows use one neutral client metadata and lifecycle service without changing public result shapes or security behavior.
  4. Fitness tests reject dependency-direction, public/internal-boundary, and topology regressions.

**Plans**: 11 plans

Plans:

- [x] 134-01-PLAN.md — Prove neutral direct/DCR metadata and atomic creation.
- [x] 134-02-PLAN.md — Unify RFC 7592 and operator client lifecycle operations.
- [x] 134-03-PLAN.md — Invert mounted discovery route capability out of protocol.
- [x] 134-04-PLAN.md — Break the config/security/prefix cycle with explicit inputs.
- [x] 134-05-PLAN.md — Break authorization-request/request-object coupling.
- [x] 134-06-PLAN.md — Make shared DPoP validation endpoint-neutral.
- [x] 134-07-PLAN.md — Introduce neutral token result primitives.
- [x] 134-08-PLAN.md — Move refresh and RFC 8693 onto neutral token results.
- [x] 134-09-PLAN.md — Convert token grant leaves and shared support.
- [x] 134-10-PLAN.md — Complete the compatible cycle-free token facade.
- [x] 134-11-PLAN.md — Enforce zero cycles, direction, ownership, and compatibility permanently.

### Phase 135: Cohesive Internals

**Goal**: Storage and grant internals are navigable, explicit, and behaviorally stable behind their existing public facades.
**Depends on**: Phase 134
**Requirements**: COH-01, COH-02, COH-03, COH-04, COH-05
**Success Criteria** (what must be TRUE):

  1. Maintainers can locate aggregate-specific Ecto behavior behind the existing `Lockspire.Storage.Ecto.Repository` facade instead of navigating one monolithic adapter.
  2. Code redemption, refresh reuse, DCR-plus-audit writes, and key transitions retain their atomic rollback and concurrency behavior.
  3. The stable token facade delegates authentication, resource selection, issuance, persistence, polling, and observability to focused collaborators.
  4. Internal collaborators use explicit dependency bundles without capability sniffing or runtime environment branching, while existing injection remains compatible.
  5. Characterization proof preserves endpoint responses, errors, tokens, audit events, and telemetry for authorization-code, refresh, device, CIBA, and token-exchange flows.

**Plans**: 2/9 plans executed

Plans:

- [x] 135-01-PLAN.md — Characterize five token flows and critical storage atomicity before movement.
- [x] 135-02-PLAN.md — Establish Ecto support and extract audited client/policy aggregates.
- [ ] 135-03-PLAN.md — Extract interaction, consent, and atomic PAR aggregates.
- [ ] 135-04-PLAN.md — Extract device, CIBA, and durable replay-security aggregates.
- [ ] 135-05-PLAN.md — Complete token, logout, IAT, and signing-key aggregate ownership.
- [ ] 135-06-PLAN.md — Normalize legacy token injection into an explicit dependency bundle.
- [ ] 135-07-PLAN.md — Extract client authentication, resource selection, and polling collaborators.
- [ ] 135-08-PLAN.md — Extract issuance, persistence, and observability and compose all five grants.
- [ ] 135-09-PLAN.md — Enforce cohesion/compatibility fitness and run the complete project gate.

### Phase 136: Static Analysis and Sustainable Proof

**Goal**: Maintainers can trust concise, behavior-focused quality evidence and read the codebase without avoidable noise or archaeology.
**Depends on**: Phase 135
**Requirements**: QUAL-01, QUAL-02, QUAL-03, QUAL-04
**Success Criteria** (what must be TRUE):

  1. Credo evaluates every library source file, and each remaining suppression is local, named, and justified.
  2. Admin and release proof expresses capabilities and behavior without giant injected macros, assertion-count contracts, or obsolete phase history.
  3. Successful routine test runs have no KeyCache startup errors, Ecto query flood, or local telemetry-handler warnings while failure and redaction assertions still work.
  4. Compilation, strict Credo, zero-warning Dialyzer, ExDoc, package build, and focused integration proof remain green during structural work.

**Plans**: TBD

### Phase 137: CI, Conformance, and Release Proof

**Goal**: A release carries reproducible security, coverage, conformance, and package-install evidence from immutable inputs.
**Depends on**: Phase 136
**Requirements**: CI-01, CI-02, CI-03, CONF-01, CONF-02, REL-01, REL-02
**Success Criteria** (what must be TRUE):

  1. CI scans both public and admin routers with low-severity fail-closed Sobelow, truthful once-per-suite coverage aggregation of at least 84%, and dependency/cycle checks.
  2. Maintainers can run OIDC/FAPI conformance evidence from pinned images, revisions, downloads, and checksums, with a scheduled supplemental lane retaining redacted evidence.
  3. Before publish, release automation proves clean-room installation through a minimal HTTP journey against the built artifact; after publish, it repeats against the exact public version.
  4. A published package's Hex checksum matches the produced artifact and a redacted manifest records pinned runtime and tooling versions.

**Plans**: TBD

## Requirement Coverage

| Phase | Requirements | Count |
|-------|--------------|-------|
| 131 | INST-01, INST-02, INST-03, INST-04, INST-05, INST-06 | 6 |
| 132 | API-01, API-02, API-03, API-04 | 4 |
| 133 | E2E-01, E2E-02, E2E-03, E2E-04, E2E-05, E2E-06 | 6 |
| 134 | ARCH-01, ARCH-02, ARCH-03, ARCH-04 | 4 |
| 135 | COH-01, COH-02, COH-03, COH-04, COH-05 | 5 |
| 136 | QUAL-01, QUAL-02, QUAL-03, QUAL-04 | 4 |
| 137 | CI-01, CI-02, CI-03, CONF-01, CONF-02, REL-01, REL-02 | 7 |

**Total:** 36/36 requirements mapped.

## Progress

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 131. Executable Installation | 7/7 | Complete    | 2026-08-26 |
| 132. Public API and Resource-Server Truth | 4/4 | Complete    | 2026-08-26 |
| 133. Clean-Room SaaS Journey | 6/6 | Complete    | 2026-08-27 |
| 134. Architecture Topology | 11/11 | Complete    | 2026-08-27 |
| 135. Cohesive Internals | 2/9 | In Progress|  |
| 136. Static Analysis and Sustainable Proof | 0/TBD | Not started | - |
| 137. CI, Conformance, and Release Proof | 0/TBD | Not started | - |
