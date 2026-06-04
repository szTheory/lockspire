# Lockspire Roadmap

## Active Milestone: v1.30 Adoption Demo Docker DX & Repo Hygiene

**Goal:** Make the repo-local adoption demo easy to start, hard to conflict with other local projects, and clean enough to serve as the stable base for the next admin UI polish milestone.

**Phases:** 5
**Requirements:** 35
**Numbering:** continues from v1.29; starts at Phase 111.

| Phase | Name | Goal | Requirements |
|-------|------|------|--------------|
| 111 | Demo URL Contract & Config Unification | Make `LOCKSPIRE_DEMO_BASE_URL` the single browser-visible URL truth for endpoint URL generation, Lockspire issuer, seeded redirects, smoke proof, and Docker bind behavior. Status: complete 2026-06-04. | URL-01..05 |
| 112 | Default Docker Compose App + DB | Provide the boring default Docker path: app plus PostgreSQL, explicit DB env, project-scoped volumes, idempotent setup, and HTTP readiness. Status: complete 2026-06-04. | DOCKER-01..06 |
| 113 | Conflict Controls & Optional Traefik | Make local Docker conflict-resistant with configurable project names, ports, cache reset, and opt-in Traefik hostname routing. Status: complete 2026-06-04. | CONFLICT-01..04, TRAEFIK-01..02 |
| 114 | Startup Output, Smoke Wrapper & Docs | Print the useful URLs/accounts/clients/smoke command, keep proof base-URL driven, and make Docker the documented default path. | INFO-01..04, SMOKE-01..02, DOCS-01..02 |
| 115 | Repo Hygiene Gate & Scoped Cleanup | Add non-destructive local hygiene and cleanup for demo-owned Docker/resources/artifacts while preserving CI determinism and product boundaries. | SMOKE-03, CLEAN-01..03, HYGIENE-01..04, BOUNDARY-01..02 |

## Phase Details

### Phase 111: Demo URL Contract & Config Unification

Make one public base URL drive every browser-visible demo URL. This phase lands before Docker topology changes so the later compose, Traefik, startup-output, docs, and smoke work consume one URL contract instead of patching around hard-coded issuer drift.

**Success criteria:**

- `LOCKSPIRE_DEMO_BASE_URL` is the canonical external URL for the adoption demo.
- Phoenix endpoint URL generation and the Lockspire issuer derive from that same base URL.
- Seeded redirect, callback, and verification URLs align after demo setup.
- `scripts/demo/adoption_smoke.py` remains base-URL driven and catches issuer or endpoint drift clearly.
- Docker can bind Phoenix to a container-reachable interface without weakening host-local loopback defaults.

**Requirements:** URL-01, URL-02, URL-03, URL-04, URL-05
**Plans:** 2/2 plans complete

Plans:
**Wave 1**

- [x] 111-01-PLAN.md - Configure one demo base URL for endpoint/issuer and explicit bind IP.

**Wave 2**

- [x] 111-02-PLAN.md - Derive seeded/UI URLs and sharpen smoke drift proof.

### Phase 112: Default Docker Compose App + DB

Replace the current Traefik-only, app-only compose path with a default app + PostgreSQL local demo stack that does not rely on host Postgres.

**Success criteria:**

- A repo-root command starts the Docker adoption demo without host Postgres.
- Compose includes Phoenix/Bandit and PostgreSQL 14+ with explicit database wiring.
- PostgreSQL has a healthcheck and project-scoped named data volume.
- Phoenix uses project-scoped `deps` and `_build` volumes.
- Startup creates, migrates, seeds, and waits for public HTTP readiness before reporting ready.

**Requirements:** DOCKER-01, DOCKER-02, DOCKER-03, DOCKER-04, DOCKER-05, DOCKER-06
**Plans:** 2/2 plans complete

Plans:
**Wave 1**

- [x] 112-01-PLAN.md - Create the default repo-root Docker Compose topology for the adoption demo.

**Wave 2**

- [x] 112-02-PLAN.md - Add idempotent database setup and public HTTP readiness to the Docker adoption demo startup.

### Phase 113: Conflict Controls & Optional Traefik

Make the Docker path robust when this repo runs alongside other local Elixir libraries with admin UIs. Traefik stays useful but optional.

**Success criteria:**

- Compose project name and public app port are configurable.
- Printed URLs, docs, and smoke commands use the configured base URL.
- Postgres host port exposure is absent by default and opt-in when needed.
- Cache reset targets only the active demo project volumes.
- Optional Traefik mode documents or automates its external network and uses configurable hostname/router/service labels.

**Requirements:** CONFLICT-01, CONFLICT-02, CONFLICT-03, CONFLICT-04, TRAEFIK-01, TRAEFIK-02
**Plans:** 2/2 plans complete

Plans:
**Wave 1**

- [x] 113-01-PLAN.md - Make direct Docker project, port, DB host exposure, and reset controls deterministic.

**Wave 2**

- [x] 113-02-PLAN.md - Add opt-in Traefik hostname routing with configurable labels and network docs.

### Phase 114: Startup Output, Smoke Wrapper & Docs

Make the running demo self-describing. A maintainer should not need to source-dive to know where to click, which account to use, or how to prove the demo.

**Success criteria:**

- Successful startup prints all important URLs and the exact smoke command for the active base URL.
- Startup output lists seeded accounts and clearly identifies `ops` as the operator account.
- Startup output lists seeded OAuth clients and demo shapes without exposing sensitive material.
- Maintainers can reprint the current demo information without recreating containers.
- The existing smoke passes against direct Docker mode and optional Traefik mode.
- `docs/adoption-demo.md` presents Docker as the default maintainer path with host-local fallback and troubleshooting.

**Requirements:** INFO-01, INFO-02, INFO-03, INFO-04, SMOKE-01, SMOKE-02, DOCS-01, DOCS-02

### Phase 115: Repo Hygiene Gate & Scoped Cleanup

Close the milestone by making cleanup and repo state explicit, non-destructive by default, and suitable for starting the next admin UI pass from a clean base.

**Success criteria:**

- Stop, reset, and cleanup lanes are scoped to the active demo Compose project and allowlisted repo-owned artifacts.
- Local hygiene reports demo Docker leftovers and generated demo artifacts with PASS/WARN/BLOCK output.
- CI hygiene remains deterministic and does not require local Docker daemon state.
- Useful admin UI evidence such as `tmp/admin-ui-polish/` is preserved unless explicitly named.
- Start -> smoke -> stop -> cleanup -> hygiene can leave no demo-owned BLOCK findings.
- v1.30 does not broaden OAuth/OIDC protocol behavior, admin workflow behavior, production Docker packaging, hosted-auth shape, or public support claims.

**Requirements:** SMOKE-03, CLEAN-01, CLEAN-02, CLEAN-03, HYGIENE-01, HYGIENE-02, HYGIENE-03, HYGIENE-04, BOUNDARY-01, BOUNDARY-02

## Shipped Milestones

- [v1.29 Admin UI Journey & Design-System Deep Polish](milestones/v1.29-ROADMAP.md) — shipped 2026-06-04; phases 107-110; route-by-route admin journeys, shared BEM/design-token primitives, weak-spot support/operations/configuration polish, demo seed truth, docs, screenshots, contract tests, and 390px mobile no-page-overflow proof now align across the admin operator surface.
- [v1.28 Admin UI Operator Experience Polish](milestones/v1.28-ROADMAP.md) — shipped 2026-06-03; phases 103-106; admin UI operator journeys, shared BEM/design-token primitives, client/support/operations/security/DCR/key workflow polish, demo seed truth, operator docs, screenshots, and design-system contract tests now align as one coherent operator product.
- [v1.27 Phoenix Resource Server Token Acceptance](milestones/v1.27-ROADMAP.md) — shipped 2026-06-03; phases 97-102; Lockspire.Plug.VerifyToken narrowed to RFC 9068 at+jwt, default access-token issuance flipped to :jwt, sender-constraint proof delivered, adoption-demo re-wired, and generated-host scaffolding updated.
- [v1.26 Host Integration & Operator Boundary Hardening](milestones/v1.26-ROADMAP.md) — shipped 2026-05-27; phases 94-96; generated host scaffolding now shows a host-guarded admin-only mount, account/claims integration stays narrow and host-owned, first-client bootstrap guidance is clearer, and adopter docs now include a compact SaaS adoption recipe without adding protocol breadth.
- [v1.25 Support-Burden Reduction](milestones/v1.25-ROADMAP.md) — shipped 2026-05-26; phases 91-93; remote `jwks_uri` diagnostics, advanced-setup support truth, and regression proof now align across runtime, doctor, admin, and docs without broadening Lockspire's embedded-library scope.
- [v1.24 client_secret_jwt](milestones/v1.24-ROADMAP.md) — shipped 2026-05-25; phases 88-90; Lockspire now supports a narrow `client_secret_jwt` direct-client slice on the shipped Lockspire-owned endpoints with sealed verifier material, strict HS256/replay/audience posture, and truthful DCR/discovery/admin/docs support.
- [v1.23 DCR Logout Metadata](milestones/v1.23-ROADMAP.md) — shipped 2026-05-24; phases 85-87; self-service clients can now create, read, and replace Lockspire's existing logout propagation metadata through DCR and RFC 7592 without widening the current logout truth model.
- [v1.22 DPoP Nonce Support](milestones/v1.22-ROADMAP.md) — shipped 2026-05-24; phases 82-84; automatic `DPoP-Nonce` challenge and retry support now covers Lockspire-owned `/token`, Lockspire-owned protected resources, and the shipped host Phoenix protected-route pipeline.
