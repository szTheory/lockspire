# Requirements: v1.36 Structural Quality Ratchet

**Defined:** 2026-08-26
**Status:** Active

## Runtime Dependency Truth

- [x] **RUNTIME-01**: Protocol store fallbacks use the Lockspire storage adapter; `Config.repo` is used only for raw Ecto operations that an ordinary host Repo supports.
- [x] **RUNTIME-02**: CIBA Push can issue JWT access and ID tokens when the host configures an ordinary Ecto Repo.
- [ ] **RUNTIME-03**: One internal token-lifetime policy owns access, ID, and refresh defaults while preserving current values and behavior.
- [ ] **RUNTIME-04**: Private signing-key decoding is centralized, fail-closed, and reused across all supported signing paths.

## Architecture

- [x] **ARCH-01**: Executable fitness tests enforce the boundary between Ecto/query code, Lockspire storage adapters, and ordinary host repos.
- [x] **ARCH-02**: Client, logout, initial-access-token, transaction, and audit operations use explicit narrow internal ports where required.
- [x] **ARCH-03**: DCR persistence and admin reads go through protocol/admin services and ports rather than direct schema queries in protocol or LiveView modules.
- [ ] **ARCH-04**: `Lockspire.Protocol.TokenExchange` remains the stable facade while grant-specific coordinators own authorization-code, device-code, and CIBA flows.

## Static Analysis and Tests

- [x] **STATIC-01**: Credo analyzes every intended source file with no parser-timeout skips.
- [ ] **STATIC-02**: Dialyzer reports zero warnings without a blanket ignore file and runs as a required cached CI gate.
- [ ] **TEST-01**: Shared database and application-configuration isolation helpers replace repeated per-test setup patterns.
- [ ] **TEST-02**: Oversized token, release, and admin design-contract tests are split by capability without reducing coverage.
- [x] **COVER-01**: CI enforces a measured built-in ExUnit coverage floor based on the repository baseline.

## Release and CI Integrity

- [x] **RELEASE-01**: Publish automation accepts only an exact `main` head SHA with a successful matching CI run.
- [x] **RELEASE-02**: Recovery publishing requires an immutable main-reachable ref, matching successful CI evidence, and safely passed environment inputs.
- [x] **RELEASE-03**: One coherent release flow covers release PR, merge, exact-ref publish, GitHub release, Hex publish, and post-publish install truth.
- [x] **SUPPLY-01**: The local Release Please runtime is dependency-audited and covered by Dependabot.
- [x] **SUPPLY-02**: Dependency review fails closed; actions and service images are immutable; workflows have bounded timeouts.
- [x] **CI-01**: Actionlint and ShellCheck pass with zero warnings, and lock verification is non-mutating.
- [ ] **CI-02**: Duplicate test work is removed only where timing evidence proves it redundant.

## Compatibility and Readability

- [x] **COMPAT-01**: A minimum supported BEAM lane runs against PostgreSQL 14.
- [x] **COMPAT-02**: A committed compatibility fixture proves Phoenix 1.8.5 and LiveView 1.1.28 integration.
- [ ] **READ-01**: Runtime code no longer carries phase, plan, or acceptance-marker archaeology; durable RFC and security rationale remains.
- [ ] **READ-02**: Documentation and walkthrough contracts stay synchronized with real code and public structs.
- [ ] **CLEAN-01**: Obsolete scratch artifacts are removed and retained visual evidence has an explicit repository policy.

## Traceability

| Requirement | Phase |
|-------------|-------|
| RELEASE-01, RELEASE-02, RELEASE-03, SUPPLY-01, SUPPLY-02, CI-01 | 126 |
| STATIC-01, COVER-01, COMPAT-01, COMPAT-02 | 127 |
| RUNTIME-01, RUNTIME-02, ARCH-01, ARCH-02, ARCH-03 | 128 |
| RUNTIME-03, RUNTIME-04, ARCH-04, STATIC-02 | 129 |
| TEST-01, TEST-02, CI-02, READ-01, READ-02, CLEAN-01 | 130 |

**Coverage:** 25/25 requirements mapped.

## Out of Scope

- New OAuth/OIDC protocol features or public endpoints.
- Changes to supported public behavior, token semantics, or security defaults.
- SAML, LDAP/AD federation, hosted authentication, standalone-service deployment, or a CIAM suite.
- Host-owned accounts, login UX, layouts, branding, tenant policy, or operator authentication.
- A wholesale storage-repository rewrite or public theming/design-system surface.
