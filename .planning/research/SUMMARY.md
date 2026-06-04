# Project Research Summary

**Project:** Lockspire
**Domain:** Repo-local Phoenix adoption demo Docker DX and repo hygiene
**Researched:** 2026-06-04
**Confidence:** HIGH

## Executive Summary

v1.30 is a demo-operations milestone for an embedded Phoenix OAuth/OIDC authorization-server library. The product work is not new protocol surface or admin UI expansion; it is making the representative host app in `examples/adoption_demo` boring to start, easy to prove, hard to collide with other local projects, and clean enough to serve as the base for the next admin UI pass.

The recommended approach is one default Docker path: app plus PostgreSQL through Docker Compose, direct host-port access on `127.0.0.1:${LOCKSPIRE_DEMO_PORT:-4100}`, and Traefik hostname routing only behind an explicit opt-in profile or override. One canonical `LOCKSPIRE_DEMO_BASE_URL` must drive Phoenix endpoint URL, Lockspire issuer, seeded redirect/callback truth, startup output, docs, and the smoke command.

The highest risks are environment drift and cleanup damage: hard-coded issuer/callback URLs, container loopback binding, accidental host Postgres dependency, global Docker resource collisions, and over-broad hygiene that deletes useful UI evidence. Mitigate these by landing the URL/config contract first, adding a Compose-managed database with explicit env wiring, parameterizing project names/ports/hostnames, keeping cleanup allowlisted and non-destructive by default, and proving the active URL with the existing black-box smoke.

## Key Findings

### Recommended Stack

Use the existing Phoenix/Elixir stack and add only local demo infrastructure. Do not add production Docker packaging, Kubernetes, conformance lanes, new OAuth/OIDC behavior, Redis, pgAdmin, or a required standalone auth-service shape.

**Core technologies:**
- Docker Compose v2: local app/database topology, project isolation, env interpolation, profiles, healthchecks, named volumes.
- `postgres:14` or `postgres:14-alpine`: Compose-managed demo database with named volume and `pg_isready` healthcheck.
- Phoenix/Bandit: app binds `0.0.0.0` in Docker while preserving loopback host-local defaults.
- Traefik v2.10: optional local hostname routing through `tools/traefik`, never required for default startup.
- Bash/Mix demo helpers: thin repo-root wrappers or Mix task for start/stop/info/reset/smoke output; keep `scripts/demo/adoption_smoke.py` as proof, not orchestration.
- `scripts/maintainer/repo_hygiene_check.sh`: extend the existing PASS/WARN/BLOCK gate for demo leftovers without making CI depend on Docker daemon state.

### Expected Features

**Must have (table stakes):**
- One documented repo-root Docker command starts the adoption demo app and database without host Postgres.
- Compose includes `web` and `db`, DB healthcheck, named Postgres/deps/_build volumes, explicit DB env, and direct `127.0.0.1` port publishing.
- Startup performs idempotent create/migrate/seed, waits for HTTP readiness, then prints active base URL, issuer, discovery, JWKS, admin, verify, developer apps, callback/protected API URLs, seeded accounts, seeded clients, and the exact smoke command.
- Ports, base URL, Compose project name, and optional Traefik hostname are configurable.
- `scripts/demo/adoption_smoke.py` passes against the active `LOCKSPIRE_DEMO_BASE_URL`.
- Stop/reset/cleanup commands are scoped to the active Compose project.
- Hygiene reports demo containers/volumes, generated demo artifacts, stale logs/screenshots, and dirty tracked state with clear remediation.
- `docs/adoption-demo.md` makes Docker the default path and keeps the host-local Mix/Postgres path as a fallback.

**Should have (differentiators):**
- `info` or `--print` command to reprint URLs/accounts/clients/smoke command for a running demo.
- `doctor` preflight for Docker daemon, Compose plugin, chosen ports, Traefik network, and expected files.
- Optional smoke wrapper that preserves the existing Python smoke output.
- Log-tail helper scoped to the active Compose project.
- Structured `--json` readiness output only after the plain text contract is stable.

**Defer:**
- Browser screenshot automation for startup; leave screenshots to the next admin UI polish milestone.
- Cross-repo local development platform conventions.
- Required Traefik, TLS/certificate automation, production release image, Kubernetes/Helm/Terraform.
- New protocol flows, admin workflows, hosted auth, SAML, LDAP, or CIAM breadth.

### Architecture Approach

Keep v1.30 outside Lockspire runtime modules. The local Docker path is a first-class maintainer path, but CI should continue using the existing host-run adoption smoke unless a later phase intentionally adds a Docker smoke job. The architectural center is a single external URL contract flowing through Compose env, Phoenix endpoint config, Lockspire issuer, seeds, docs, startup output, and smoke.

**Major components:**
1. `examples/adoption_demo/docker-compose.yml` - local `web` + `db` topology, direct port default, project-scoped volumes, optional Traefik profile/override.
2. `examples/adoption_demo/config/config.exs` - env precedence for bind IP/port, public base URL, endpoint `url`, issuer, and DB settings.
3. Demo startup/info scripts or Mix task - idempotent setup, readiness wait, and generated URL/account/client/smoke output.
4. `scripts/demo/adoption_smoke.py` - black-box proof against the printed base URL; no Docker orchestration.
5. `docs/adoption-demo.md` - canonical human contract for Docker, Traefik, smoke, reset, cleanup, env overrides, and host-local fallback.
6. `scripts/maintainer/repo_hygiene_check.sh` - non-destructive repo hygiene classification and cleanup guidance.

### Critical Pitfalls

1. **Hard-coded issuer/callback drift** - derive endpoint URL, Lockspire issuer, seeded redirect URIs, docs, banner, and smoke from `LOCKSPIRE_DEMO_BASE_URL`.
2. **Docker still assumes host Postgres** - add a Compose `db` service, explicit `LOCKSPIRE_DEMO_DB_*` env, healthcheck, and setup command.
3. **Phoenix binds loopback inside container** - set `LOCKSPIRE_DEMO_BIND_IP=0.0.0.0` in Compose while defaulting host-local runs to `127.0.0.1`.
4. **Docker project/volume/Traefik collisions** - parameterize Compose project name, ports, hostname, router/service labels; avoid `container_name`; keep DB host port unexposed by default.
5. **Over-broad cleanup destroys evidence** - hygiene should report by category and cleanup only allowlisted demo-owned paths/resources with explicit reset flags.
6. **Startup banner lies or leaks** - generate output from config truth and seeds; print client IDs and demo logins, not client secrets, tokens, private keys, auth codes, or cookies.

## Implications for Roadmap

Based on research, suggested phase structure:

### Phase 1: Demo URL Contract and Config Unification
**Rationale:** URL truth is the root dependency. Compose, Traefik, seeds, docs, and smoke all fail noisily if issuer/callback/base URL drift remains.
**Delivers:** `LOCKSPIRE_DEMO_BASE_URL` parsing, Docker bind IP support, endpoint `url` and Lockspire issuer derived from one base URL, seed/smoke/doc alignment checks.
**Addresses:** configurable base URL/port/hostname, smoke URL compatibility.
**Avoids:** hard-coded issuer drift, callback mismatch, loopback container binding.

### Phase 2: Default Docker Compose App + DB
**Rationale:** The milestone's default path must remove host Postgres dependency before polishing scripts or docs.
**Delivers:** `db` service, healthcheck-gated `web`, explicit DB env, named Postgres/deps/_build volumes, direct `127.0.0.1:${LOCKSPIRE_DEMO_PORT:-4100}:4000` publishing, idempotent setup command.
**Uses:** Docker Compose v2, PostgreSQL 14, Phoenix/Bandit dev image.
**Implements:** local app/database topology for the adoption demo only.

### Phase 3: Conflict Controls and Optional Traefik
**Rationale:** Multiple local Elixir admin demos are the concrete adopter friction. Project/port/hostname controls should land before final docs so commands are truthful.
**Delivers:** configurable Compose project name, app port, optional DB debug port if needed, cache reset, Traefik profile/override, parameterized Traefik labels/network/hostname, preflight/doctor if included.
**Addresses:** port conflicts, Compose resource collisions, optional hostname routing.
**Avoids:** required Traefik, static router label collisions, stale `_build`/`deps` volume confusion.

### Phase 4: Startup Output, Smoke Wrapper, and Docs
**Rationale:** The demo is useful only if maintainers can immediately see what is running and how to prove it.
**Delivers:** repo-root launcher/info output, readiness wait, seeded account/client display, exact smoke command, optional smoke wrapper, updated `docs/adoption-demo.md` with Docker default, host-local fallback, Traefik, env overrides, stop/reset/cleanup.
**Addresses:** printed URLs/accounts/clients/routes, smoke proof, executable handoff.
**Avoids:** source-diving, stale banner values, secret leakage, smoke proving only the wrong origin.

### Phase 5: Repo Hygiene Gate and Scoped Cleanup
**Rationale:** Hygiene should be last because it depends on knowing which artifacts and Docker resources the new demo path creates.
**Delivers:** local PASS/WARN/BLOCK checks for generated demo artifacts and Docker leftovers, cleanup/reset lane scoped by Compose project, Docker-free `--ci` behavior, documented remediation commands.
**Addresses:** clean repo before next admin UI pass.
**Avoids:** destructive broad cleanup, CI flakes from local Docker checks, conflating Docker state with git state.

### Phase Ordering Rationale

- URL/config contract comes first because every later phase consumes the public base URL.
- Compose app+DB comes before wrappers because scripts should wrap a working topology, not compensate for missing database/config behavior.
- Conflict controls and optional Traefik come before docs so the documented commands are final.
- Startup output and smoke alignment come before hygiene because they define what proof artifacts exist.
- Hygiene is last because it should classify actual generated outputs and Docker resources, not guessed ones.

### Research Flags

Phases likely needing deeper research during planning:
- **Phase 3:** Traefik label naming and Compose profile/override details need targeted validation with `docker compose config`, especially for multiple simultaneous checkouts.
- **Phase 5:** Cleanup ownership needs repo-specific path validation so useful `tmp/admin-ui-polish` evidence is preserved while demo-owned debris is reported.

Phases with standard patterns (skip research-phase):
- **Phase 1:** Phoenix endpoint URL config, URI parsing, and smoke equality checks are straightforward repo-local work.
- **Phase 2:** Docker Compose app+Postgres with healthcheck/named volumes is well-documented.
- **Phase 4:** Existing smoke script, seeds, docs, and route inventory provide enough repo truth for implementation.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | Grounded in repo reads plus official Docker Compose, Traefik, and Phoenix docs. Exact script names can be finalized during planning. |
| Features | HIGH | Table stakes map directly to `.planning/PROJECT.md`, current demo files, and the milestone's stated defaults. |
| Architecture | HIGH | Integration points are repo-local and avoid Lockspire runtime boundary changes. |
| Pitfalls | HIGH | Critical pitfalls are directly visible in current config, compose, docs, smoke, and hygiene behavior. |

**Overall confidence:** HIGH

### Gaps to Address

- Script shape: choose exact names and flags for start/stop/reset/info/smoke wrappers during requirements.
- Readiness implementation: decide whether URL printing is a Mix task, shell helper, or minimal Compose command output; prefer Mix task if it can read the same config truth.
- Seed URL derivation: verify whether seeded redirect/callback/client URLs can be made base-URL-driven cleanly or need an explicit reset requirement when `LOCKSPIRE_DEMO_BASE_URL` changes.
- CI Docker proof: decide whether v1.30 only validates `docker compose config` in CI or adds a full Docker smoke job after local proof stabilizes.
- Cleanup allowlist: define exact repo-owned generated paths; preserve admin UI screenshot/evidence directories unless explicitly requested.

## Sources

### Primary (HIGH confidence)
- `.planning/PROJECT.md` - v1.30 goal, target features, boundaries, and milestone context.
- `.planning/research/STACK.md` - Docker Compose/Phoenix/Traefik stack recommendations and current repo-state findings.
- `.planning/research/FEATURES.md` - table-stakes capabilities, differentiators, anti-features, and acceptance criteria.
- `.planning/research/ARCHITECTURE.md` - repo integration points, config/data flow, env precedence, script/docs/CI responsibilities.
- `.planning/research/PITFALLS.md` - critical/moderate/minor pitfalls and phase-specific warnings.
- Repo files cited by researchers: `docs/adoption-demo.md`, `examples/adoption_demo/docker-compose.yml`, `examples/adoption_demo/Dockerfile.dev`, `examples/adoption_demo/config/config.exs`, `examples/adoption_demo/priv/repo/seeds.exs`, `scripts/demo/adoption_smoke.py`, `scripts/maintainer/repo_hygiene_check.sh`, `tools/traefik/docker-compose.yml`.

### Secondary (MEDIUM/HIGH confidence)
- Docker Compose documentation - project model, CLI/env vars, services, profiles, healthchecks, port publishing, volume behavior.
- Traefik Docker provider v2.10 documentation - Docker labels, `exposedByDefault=false`, network selection, router/service configuration.
- Phoenix Endpoint documentation - endpoint `:url`, server binding, generated URL behavior behind local/proxy access.

---
*Research completed: 2026-06-04*
*Ready for roadmap: yes*
