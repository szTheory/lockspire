# v1.30 Requirements: Adoption Demo Docker DX & Repo Hygiene

**Defined:** 2026-06-04
**Core Value:** A Phoenix SaaS team can become a trustworthy OAuth/OIDC provider inside its existing app without inventing the dangerous parts itself.

## Goal

Make the repo-local adoption demo easy to start, hard to conflict with other local projects, and clean enough to serve as the stable base for the next admin UI polish milestone.

## v1.30 Requirements

### Demo URL Contract

- [x] **URL-01**: The adoption demo has one canonical `LOCKSPIRE_DEMO_BASE_URL` for the browser-visible origin.
- [x] **URL-02**: Phoenix endpoint URL generation and the Lockspire issuer derive from the same base URL.
- [x] **URL-03**: Seeded redirect, callback, and verification URLs align with the configured base URL after demo setup.
- [x] **URL-04**: The smoke script continues to use `LOCKSPIRE_DEMO_BASE_URL` as its only external URL input and fails clearly on issuer or endpoint drift.
- [x] **URL-05**: Docker mode binds Phoenix to a container-reachable interface without changing the safe loopback default for host-local runs.

### Default Docker Demo

- [x] **DOCKER-01**: A documented repo-root command starts the adoption demo with Docker without relying on host Postgres.
- [x] **DOCKER-02**: The default Compose topology includes Phoenix/Bandit and PostgreSQL 14+ services with explicit database environment wiring.
- [x] **DOCKER-03**: PostgreSQL has a healthcheck and a project-scoped named data volume.
- [x] **DOCKER-04**: The Phoenix container uses project-scoped `deps` and `_build` volumes so host and container build artifacts do not collide.
- [x] **DOCKER-05**: Startup creates, migrates, and seeds the database idempotently before reporting the demo ready.
- [x] **DOCKER-06**: Startup waits for the public demo URL to return a healthy HTTP response before printing the ready banner.

### Conflict Controls

- [x] **CONFLICT-01**: The demo Compose project name is configurable so multiple local Lockspire checkouts or sibling library demos can run without resource-name collisions.
- [x] **CONFLICT-02**: The public app port is configurable and all printed URLs, docs, and smoke commands use the configured base URL.
- [x] **CONFLICT-03**: PostgreSQL does not publish host port `5432` by default; any host database port exposure is opt-in and configurable.
- [x] **CONFLICT-04**: Cache reset targets only the active demo Compose project's database, `deps`, and `_build` volumes.
- [x] **TRAEFIK-01**: Traefik hostname routing is optional and never required for the default Docker path.
- [x] **TRAEFIK-02**: Optional Traefik mode documents or automates the required external network and uses configurable hostname/router/service labels.

### Operator-Ready Output And Proof

- [x] **INFO-01**: Successful startup prints the active base URL, issuer URL, discovery URL, JWKS URL, admin URL, device verification URL, developer apps URL, OAuth callback URL, protected API URL, and exact smoke command.
- [x] **INFO-02**: Successful startup prints seeded demo accounts `alice`, `bob`, and `ops`, including roles/account emails and the fact that `ops` is the operator account.
- [x] **INFO-03**: Successful startup prints seeded OAuth client IDs and demo client shapes without exposing real secrets, tokens, private keys, authorization codes, refresh tokens, or cookies.
- [x] **INFO-04**: A maintainer can reprint the current URL/account/client/smoke information without recreating containers.
- [x] **SMOKE-01**: The existing black-box smoke passes against the direct Docker URL using `LOCKSPIRE_DEMO_BASE_URL`.
- [x] **SMOKE-02**: If optional Traefik mode is enabled, the same smoke can run against the Traefik hostname URL.
- [ ] **SMOKE-03**: CI keeps the existing adoption-demo smoke proof and adds only deterministic Docker validation unless a later phase proves full Docker smoke is stable enough for CI.

### Hygiene And Cleanup

- [ ] **CLEAN-01**: A stop command stops the demo without deleting volumes by default.
- [ ] **CLEAN-02**: A reset command intentionally rebuilds database and cache state for the active Compose project only.
- [ ] **CLEAN-03**: A cleanup lane removes only allowlisted demo-owned Docker resources and generated demo artifacts.
- [ ] **HYGIENE-01**: The repo hygiene gate reports PASS/WARN/BLOCK for demo Docker leftovers and repo-owned generated artifacts in local mode.
- [ ] **HYGIENE-02**: The hygiene gate does not require a Docker daemon or inspect local Docker state in `--ci` mode.
- [ ] **HYGIENE-03**: Hygiene output preserves useful admin UI evidence such as `tmp/admin-ui-polish/` unless an explicit cleanup command names it.
- [ ] **HYGIENE-04**: Running start, smoke, stop, cleanup, and hygiene can leave no demo-owned BLOCK findings.

### Documentation And Boundaries

- [x] **DOCS-01**: `docs/adoption-demo.md` presents Docker as the default maintainer path and keeps host-local Mix/Postgres instructions as a fallback.
- [x] **DOCS-02**: Demo docs cover default startup, optional Traefik, smoke, stop, reset, cleanup, environment overrides, and troubleshooting for port/readiness failures.
- [ ] **BOUNDARY-01**: v1.30 does not introduce new OAuth/OIDC protocol behavior, admin workflow behavior, production Docker packaging, or hosted-auth service shape.
- [ ] **BOUNDARY-02**: The adoption demo remains repo-local proof and does not broaden Lockspire's public supported surface.

## Future Requirements

- Structured JSON readiness output for external automation.
- Cross-repo local development proxy conventions shared across multiple Elixir OSS libraries.
- Browser screenshot automation for the next admin UI polish milestone.
- Full Docker smoke in CI if local Docker proof is stable and not flaky.
- Production Docker release images or deployment packaging, if a future release/distribution milestone explicitly needs them.

## Out Of Scope

- **New protocol breadth:** no SAML, LDAP/AD federation, hosted auth, full CIAM, or new OAuth/OIDC flow expansion.
- **Admin UI polish:** v1.30 prepares the demo base; the next UI iteration should be a later milestone.
- **Required Traefik:** hostname routing is useful but must remain optional for local DX.
- **Host-wide Docker cleanup:** cleanup must be scoped to Lockspire demo resources and documented paths.
- **Production deployment packaging:** the adoption demo is repo-local proof, not a deployable Lockspire service.
- **Secret exposure in startup output:** demo output may print fake login names and client IDs, but not tokens, private keys, auth codes, cookies, or real client secrets.

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| URL-01 | 111 | Complete |
| URL-02 | 111 | Complete |
| URL-03 | 111 | Complete |
| URL-04 | 111 | Complete |
| URL-05 | 111 | Complete |
| DOCKER-01 | 112 | Complete |
| DOCKER-02 | 112 | Complete |
| DOCKER-03 | 112 | Complete |
| DOCKER-04 | 112 | Complete |
| DOCKER-05 | 112 | Complete |
| DOCKER-06 | 112 | Complete |
| CONFLICT-01 | 113 | Complete |
| CONFLICT-02 | 113 | Complete |
| CONFLICT-03 | 113 | Complete |
| CONFLICT-04 | 113 | Complete |
| TRAEFIK-01 | 113 | Complete |
| TRAEFIK-02 | 113 | Complete |
| INFO-01 | 114 | Complete |
| INFO-02 | 114 | Complete |
| INFO-03 | 114 | Complete |
| INFO-04 | 114 | Complete |
| SMOKE-01 | 114 | Complete |
| SMOKE-02 | 114 | Complete |
| SMOKE-03 | 115 | Pending |
| CLEAN-01 | 115 | Pending |
| CLEAN-02 | 115 | Pending |
| CLEAN-03 | 115 | Pending |
| HYGIENE-01 | 115 | Pending |
| HYGIENE-02 | 115 | Pending |
| HYGIENE-03 | 115 | Pending |
| HYGIENE-04 | 115 | Pending |
| DOCS-01 | 114 | Complete |
| DOCS-02 | 114 | Complete |
| BOUNDARY-01 | 115 | Pending |
| BOUNDARY-02 | 115 | Pending |

**Coverage:**

- v1.30 requirements: 35 total
- Mapped to phases: 35
- Unmapped: 0

---
*Requirements defined: 2026-06-04*
*Last updated: 2026-06-04 after v1.30 roadmap creation*
