# Lockspire Roadmap

## Current Milestone: v1.36 Structural Quality Ratchet

**Goal:** Raise Lockspire's correctness, release safety, architectural clarity, static-analysis signal, compatibility proof, and readability through high-yield structural improvements without new public behavior.

## Phases

- [ ] **Phase 126: Trusted Release Path** — Bind publication to exact successful CI evidence and harden the release supply chain.
- [x] **Phase 127: Executable Quality Baselines** — Make lint, coverage, and minimum supported versions required and reproducible.
- [x] **Phase 128: Runtime Dependency Truth** — Repair host-Repo/storage boundaries and route persistence through explicit ports.
- [x] **Phase 129: Token Endpoint Cohesion** — Decompose grant orchestration and centralize token/key policy with zero Dialyzer warnings.
- [ ] **Phase 130: Readable Code & Sustainable Proof** — Consolidate test infrastructure, split oversized contracts, synchronize docs, and clean repository artifacts.

## Phase Details

### Phase 126: Trusted Release Path

**Goal:** A release is publishable only when its exact immutable main commit has passed CI, and the published package is independently installable.
**Requirements:** RELEASE-01, RELEASE-02, RELEASE-03, SUPPLY-01, SUPPLY-02, CI-01
**Success criteria:**

1. Release-PR merge waits for a successful CI run whose `head_sha` is the exact publish ref.
2. Manual recovery validates immutable main ancestry and matching CI metadata without shell-injecting inputs.
3. GitHub release, Hex publish, and post-publish install truth form one auditable flow.
4. Release automation dependencies, actions, images, timeouts, workflow lint, shell lint, and lock checks fail safely.

### Phase 127: Executable Quality Baselines

**Goal:** Quality and compatibility claims are measured in required CI lanes rather than held as conventions.
**Requirements:** STATIC-01, COVER-01, COMPAT-01, COMPAT-02
**Plans:** 3/3 plans executed

Plans:

- [x] 127-01-PLAN.md — Make Credo parse coverage fail closed through the existing qa gate.
- [x] 127-02-PLAN.md — Exercise PostgreSQL 14 and compile an exact Phoenix/LiveView lower-bound fixture.
- [x] 127-03-PLAN.md — Ratchet the measured built-in ExUnit coverage floor in Fast Checks.

**Success criteria:**

1. Credo cannot silently skip source files.
2. CI enforces the measured repository coverage baseline.
3. The minimum BEAM lane exercises PostgreSQL 14.
4. A committed fixture compiles against Phoenix 1.8.5 and LiveView 1.1.28.

### Phase 128: Runtime Dependency Truth

**Goal:** Ordinary host repos and Lockspire storage adapters are never confused, and persistence boundaries are executable.
**Requirements:** RUNTIME-01, RUNTIME-02, ARCH-01, ARCH-02, ARCH-03
**Plans:** 6/6 plans executed

Plans:

- [x] 128-01-PLAN.md — Prove CIBA Push JWT and ID-token issuance with an ordinary host Repo.
- [x] 128-02-PLAN.md — Correct authorization and token-lifecycle storage defaults.
- [x] 128-03-PLAN.md — Correct signing, JWT client-authentication, and DPoP storage defaults.
- [x] 128-04-PLAN.md — Move DCR and IAT persistence behind explicit ports.
- [x] 128-05-PLAN.md — Make transaction, audit, logout, and named-Oban boundaries explicit.
- [x] 128-06-PLAN.md — Route admin reads through services and enforce architecture fitness tests.

**Success criteria:**

1. Protocol fallback paths work with an ordinary host Ecto Repo, including CIBA Push JWT/ID token issuance.
2. Narrow ports own client, logout, IAT, transaction, and audit operations required by protocol/admin services.
3. DCR and admin modules do not reach through those boundaries with direct schema queries.
4. AST/runtime fitness tests fail on future boundary violations.

### Phase 129: Token Endpoint Cohesion

**Goal:** Grant orchestration is understandable behind the stable facade, while shared security policy has one fail-closed implementation.
**Requirements:** RUNTIME-03, RUNTIME-04, ARCH-04, STATIC-02
**Plans:** 8/8 plans executed

Plans:

- [x] 129-01-PLAN.md — Extract authorization-code coordination as the tracer and establish the lifetime policy.
- [x] 129-02-PLAN.md — Route every token duration through the shared policy with exact-value proof.
- [x] 129-03-PLAN.md — Introduce the fail-closed private JWK decoder and migrate access, ID, and JARM signing.
- [x] 129-04-PLAN.md — Complete private JWK decoder adoption across introspection, logout, and JAR.
- [x] 129-05-PLAN.md — Extract device-code polling and atomic redemption behind the facade.
- [x] 129-06-PLAN.md — Extract CIBA poll and Push issuance behind the facade.
- [x] 129-07-PLAN.md — Resolve every Dialyzer warning at its type or control-flow root.
- [x] 129-08-PLAN.md — Enforce zero-warning Dialyzer as a cached required CI job.

**Success criteria:**

1. Grant-specific coordinators reduce `TokenExchange` complexity without changing its public API or structs.
2. One internal policy owns existing token lifetime defaults.
3. Every signing path uses one fail-closed private-key decoder.
4. Dialyzer is a cached required CI gate with zero warnings and no blanket ignore file.

### Phase 130: Readable Code & Sustainable Proof

**Goal:** The repository is a joy to read and its quality proof is cheaper to maintain without deleting evidence.
**Requirements:** TEST-01, TEST-02, CI-02, READ-01, READ-02, CLEAN-01
**Plans:** 8 plans

Plans:
- [ ] 130-01-PLAN.md — Restore a green, warning-free test and compatibility baseline
- [ ] 130-02-PLAN.md — Centralize database and configuration isolation helpers
- [ ] 130-03-PLAN.md — Split token endpoint tests by grant capability
- [ ] 130-04-PLAN.md — Split release proof by automation, hygiene, and support truth
- [ ] 130-05-PLAN.md — Split admin design proof by CSS, routes, and evidence
- [ ] 130-06-PLAN.md — Measure CI partitions and remove only proven duplicate work
- [ ] 130-07-PLAN.md — Normalize runtime filenames and remove planning archaeology
- [ ] 130-08-PLAN.md — Synchronize docs, clean artifacts, and run final proof

**Success criteria:**

1. Shared test helpers own sandbox and application-env restoration patterns.
2. Large token, release, and admin contract tests are split along capability boundaries.
3. CI timing evidence justifies any duplicate test-work removal.
4. Runtime planning markers and obsolete scratch files are gone; retained screenshots have a documented policy.
5. Docs and walkthrough contracts derive from current source/public structures.

## Requirement Coverage

| Phase | Requirements | Count |
|-------|--------------|-------|
| 126 | RELEASE-01, RELEASE-02, RELEASE-03, SUPPLY-01, SUPPLY-02, CI-01 | 6 |
| 127 | STATIC-01, COVER-01, COMPAT-01, COMPAT-02 | 4 |
| 128 | RUNTIME-01, RUNTIME-02, ARCH-01, ARCH-02, ARCH-03 | 5 |
| 129 | RUNTIME-03, RUNTIME-04, ARCH-04, STATIC-02 | 4 |
| 130 | TEST-01, TEST-02, CI-02, READ-01, READ-02, CLEAN-01 | 6 |

**Total:** 25/25 requirements mapped.

## Shipped Milestones

Full prior milestone details live in `.planning/milestones/`, including [v1.35 CI/CD Efficiency And Release Hygiene](milestones/v1.35-ROADMAP.md), [v1.34 Prefix-Isolated Storage](milestones/v1.34-ROADMAP.md), and [v1.33 OSS Adoption Trust](milestones/v1.33-ROADMAP.md).
