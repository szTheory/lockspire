# v1.30 Architecture Research - Adoption Demo Docker DX & Repo Hygiene

**Domain:** Repo-local Phoenix adoption demo for an embedded OAuth/OIDC authorization-server library.
**Researched:** 2026-06-04
**Overall confidence:** HIGH for repo integration points; MEDIUM for Docker Compose behavior where based on current Docker documentation.

## Scope

This document answers how v1.30 should integrate with the existing Lockspire repo architecture. It is not a redesign of Lockspire's protocol core, admin UI, or host seams.

The adoption demo lives at `examples/adoption_demo`. It currently has a manual host run path on `http://127.0.0.1:4100`, an app-only `docker-compose.yml` that assumes an external Traefik network and `adoption-demo.localhost`, and config that accepts host/port/database env vars but hard-codes the Lockspire issuer to `http://127.0.0.1:4100/lockspire`. v1.30 should turn that into a reliable Docker path with direct port defaults, optional Traefik, conflict-resistant names/ports, startup guidance, and cleanup/hygiene proof.

## Architectural Recommendation

Keep v1.30 as a demo-operations and repo-hygiene milestone. Do not add Lockspire runtime product APIs, do not change protocol behavior, and do not move the demo toward a hosted auth-service architecture.

The right integration shape is:

```
repo root
  docs/adoption-demo.md                  operator/user-facing demo contract
  scripts/demo/adoption_smoke.py         black-box proof, base-URL driven
  scripts/maintainer/repo_hygiene_check.sh
                                          release/repo cleanliness gate
  .github/workflows/ci.yml               host-run smoke remains canonical CI proof

examples/adoption_demo
  docker-compose.yml                     local Docker topology and defaults
  Dockerfile.dev                         dev app image, live-reload friendly
  config/config.exs                      single source for app URL, issuer, DB env
  mix.exs                                app aliases; no Docker-specific product logic
  priv/repo/seeds.exs                    demo data printed/documented, not duplicated silently
```

The Docker path should be a first-class local maintainer path, while CI should continue proving the same black-box smoke against a host-run Phoenix process unless the milestone explicitly adds a separate Docker smoke job. This avoids making GitHub Actions depend on Docker Compose semantics for protocol proof while still making local Docker reliable.

## New / Modified Components

| Component | Change | Responsibility |
|-----------|--------|----------------|
| `examples/adoption_demo/docker-compose.yml` | Replace Traefik-only app service with a default app + Postgres topology. Keep Traefik behind an explicit profile or override. | Own local container graph, conflict-resistant names, default direct host port, DB health, app env wiring. |
| `examples/adoption_demo/Dockerfile.dev` | Keep as dev image, but align with `mix.exs` Elixir requirement or repo CI versions. Optionally add `postgresql-client` only if container startup waits with `pg_isready`. | Own OS packages and app boot command support, not app config. |
| `examples/adoption_demo/config/config.exs` | Make endpoint bind IP, endpoint URL, and Lockspire issuer derive from the same env-driven base URL. | Own runtime config precedence for local host run and Docker run. |
| `examples/adoption_demo/mix.exs` | Keep `ecto.setup` as canonical DB prep. Add a demo-print alias only if implemented as a Mix task/module, not shell glue. | Own Mix-level demo preparation commands. |
| `docs/adoption-demo.md` | Add default Docker run, optional Traefik run, env vars, smoke command, cleanup commands, seeded accounts/clients, and URLs. | Own human-facing contract; no hidden tribal knowledge. |
| `scripts/demo/adoption_smoke.py` | Keep `LOCKSPIRE_DEMO_BASE_URL` as the only URL input. Add clearer failure output only if needed. | Own black-box protocol/admin proof against whatever URL docs advertise. |
| `scripts/maintainer/repo_hygiene_check.sh` | Add repo-local generated-artifact and Docker-leftover checks. Keep CI mode limited to repo-owned deterministic checks. | Own release-prep cleanliness, not demo orchestration. |
| `.github/workflows/ci.yml` | Preserve existing `Adoption Demo Smoke` job. Add Docker config validation or Docker smoke only after local compose is stable. | Own automated proof that docs/config/smoke stay aligned. |

Do not add a new Lockspire module under `lib/lockspire`. v1.30 is outside the library runtime boundary.

## Docker Networking Shape

### Default Path: Direct Port

Default compose should work without Traefik:

```
host browser / smoke
  http://127.0.0.1:${LOCKSPIRE_DEMO_PORT:-4100}
        | published port
adoption demo web container
  binds 0.0.0.0:${LOCKSPIRE_DEMO_INTERNAL_PORT:-4000}
        | Docker network DNS
postgres container
  hostname: db
  port: 5432
```

Recommended defaults:

| Setting | Default | Why |
|---------|---------|-----|
| Compose project name | `lockspire-adoption-demo` via top-level `name:` or documented `COMPOSE_PROJECT_NAME` | Prevents generic `adoption_demo_*` collisions across local projects. |
| Host HTTP port | `4100` | Preserves existing docs and smoke default. |
| Container HTTP port | `4000` | Phoenix container convention; avoids coupling container internals to host port. |
| DB service | `db` | Stable Docker DNS name for `LOCKSPIRE_DEMO_DB_HOST`. |
| DB host port | Not published by default | Avoids conflict with host Postgres and CI's `5432`. Publish only through opt-in debug env/override. |
| Volumes | Project-scoped named volumes for Postgres, deps, and `_build` | Keeps Linux build artifacts off macOS while making `docker compose down -v` cleanup predictable. |

The web service should set `LOCKSPIRE_DEMO_DB_HOST=db`, `LOCKSPIRE_DEMO_DB_PORT=5432`, and DB credentials matching the Postgres service. It should also set `PHX_SERVER=true`, `LOCKSPIRE_DEMO_BIND_IP=0.0.0.0`, `PORT=${LOCKSPIRE_DEMO_INTERNAL_PORT:-4000}`, and `LOCKSPIRE_DEMO_BASE_URL=http://127.0.0.1:${LOCKSPIRE_DEMO_PORT:-4100}`.

### Optional Traefik Path

Traefik must be opt-in. The current compose file requires an external `local-dev-proxy` network, which makes the default path fail for users who do not already run that proxy.

Use one of these patterns:

1. A `traefik` profile in the same compose file for labels and external network attachment.
2. A small `docker-compose.traefik.yml` override that maintainers pass explicitly.

The direct port should remain enabled even when Traefik is used unless the docs explicitly show how to disable it. Traefik labels should interpolate the hostname and router/service names from env:

| Env var | Default |
|---------|---------|
| `LOCKSPIRE_DEMO_TRAEFIK_HOST` | `adoption-demo.localhost` |
| `LOCKSPIRE_DEMO_TRAEFIK_NETWORK` | `local-dev-proxy` |

Avoid hard-coded Traefik router names like `adoption-demo` if multiple checkouts can run at once. Compose project scoping and env-derived labels should keep names distinct.

## Config and Data Flow

The central v1.30 fix is to make one externally visible base URL flow through Phoenix endpoint URL, Lockspire issuer, seeded redirect URIs if they are derived at runtime, docs, and smoke.

```
developer shell / compose .env
  LOCKSPIRE_DEMO_PORT
  LOCKSPIRE_DEMO_HOST
  LOCKSPIRE_DEMO_BASE_URL
  LOCKSPIRE_DEMO_DB_*
        |
docker-compose.yml interpolation
        |
container environment
        |
examples/adoption_demo/config/config.exs
  Endpoint http bind ip/port
  Endpoint url scheme/host/port
  Lockspire issuer = <base_url>/lockspire
        |
runtime discovery
        |
scripts/demo/adoption_smoke.py asserts issuer/endpoints match BASE_URL
```

`scripts/demo/adoption_smoke.py` already asserts:

- discovery `issuer == LOCKSPIRE_DEMO_BASE_URL + "/lockspire"`
- authorization endpoint matches the base URL
- device verification URI matches the base URL
- redirect URI uses the base URL

That makes the smoke script the right drift detector for issuer/config mistakes. The config must be changed to satisfy that contract under Docker and host-local runs.

## Env Var Precedence

Use explicit precedence in `config/config.exs`; do not rely on implicit Compose behavior inside Elixir.

### Recommended URL Precedence

1. `LOCKSPIRE_DEMO_BASE_URL` if set. This is the canonical override for smoke, issuer, and generated external links.
2. Otherwise derive from `LOCKSPIRE_DEMO_SCHEME`, `LOCKSPIRE_DEMO_HOST`, and external port.
3. External port precedence: `LOCKSPIRE_DEMO_PORT`, then `PORT`, then `4100` for host-local compatibility.
4. Bind port precedence: `PORT`, then `LOCKSPIRE_DEMO_INTERNAL_PORT`, then `4100` for host-local runs. In compose, set `PORT=4000`.
5. Bind IP precedence: `LOCKSPIRE_DEMO_BIND_IP`, then `127.0.0.1`. In compose, set `LOCKSPIRE_DEMO_BIND_IP=0.0.0.0`.

This preserves manual `mix phx.server` behavior while letting Docker bind correctly.

### Recommended Database Precedence

Keep the existing DB precedence because it is already host-friendly:

1. `LOCKSPIRE_DEMO_DB_USER`, `LOCKSPIRE_DEMO_DB_PASSWORD`, `LOCKSPIRE_DEMO_DB_HOST`, `LOCKSPIRE_DEMO_DB_PORT`, `LOCKSPIRE_DEMO_DB_NAME`
2. `PGUSER`, `PGPASSWORD`, `PGHOST`, `PGPORT`
3. local defaults

Compose should always pass the first tier so it never accidentally talks to host Postgres.

### Docker Compose Precedence Notes

Current Docker Compose documentation supports Bash-like interpolation defaults such as `${VAR:-default}` and recognizes predefined variables including `COMPOSE_PROJECT_NAME` and `COMPOSE_PROFILES`. Compose also has explicit environment precedence rules for values injected into containers. Use those features only for compose-file defaults; keep the app's final runtime precedence in `config/config.exs` so local Mix, CI, and Docker behave consistently.

## Script Responsibilities

### `scripts/demo/adoption_smoke.py`

Owns proof, not orchestration.

Keep it as a black-box test that takes `LOCKSPIRE_DEMO_BASE_URL` and drives HTTP flows. Do not make it start Docker or Phoenix. It should remain usable against:

- manual host run at `http://127.0.0.1:4100`
- direct Docker run at `http://127.0.0.1:${LOCKSPIRE_DEMO_PORT}`
- Traefik run at `http://adoption-demo.localhost`
- CI host-run app

If v1.30 adds anything here, add better diagnostics: print the base URL on failure and include the last response body/status. Avoid Docker-specific branching.

### Startup URL Printing

Prefer a small repo-local script or Mix task owned by the demo, not ad hoc shell scattered through compose. The output should include:

- home URL
- Lockspire issuer
- discovery URL
- admin URL
- developer apps URL
- device verification URL
- seeded accounts
- seeded clients
- smoke command with the exact base URL

Implementation options, ranked:

1. A Mix alias/task run after `ecto.setup`, for example `mix demo.info`, because it can read the same app config as Phoenix.
2. A `scripts/demo/adoption_info.sh` helper that computes the same values from env.
3. Inline `echo` in the compose command.

Use option 1 if feasible. Option 3 is acceptable only as a thin fallback because it tends to drift from config.

### `repo_hygiene_check.sh`

Owns cleanliness checks and release-prep blocking. It should not start containers.

Add local-mode checks for:

- checked-in or dirty generated demo artifacts under `examples/adoption_demo/deps`, `examples/adoption_demo/_build`, `examples/adoption_demo/.DS_Store`, and nested `.DS_Store`
- stale Docker containers/volumes for the demo project
- optional warning if a demo compose project is running
- docs mention the canonical Docker command and smoke command

Keep `--ci` deterministic and repo-owned. CI can check docs/config strings and generated artifact absence, but should not depend on local Docker daemon state.

## Docs Responsibilities

`docs/adoption-demo.md` should become the single human entry point.

Required sections:

| Section | Must include |
|---------|--------------|
| What it proves | Preserve current protocol/admin proof list. |
| Run with Docker | `cd examples/adoption_demo && docker compose up --build`, expected URL, startup output. |
| Run with custom port/name | `LOCKSPIRE_DEMO_PORT=... COMPOSE_PROJECT_NAME=... docker compose up --build`. |
| Run with Traefik | Explicit opt-in profile/override command, required external network, hostname. |
| Run manually | Preserve current Mix/Postgres path. |
| Smoke | `LOCKSPIRE_DEMO_BASE_URL=... python3 scripts/demo/adoption_smoke.py` from repo root. |
| Seeded data | Accounts and OAuth clients already listed. |
| Cleanup | `docker compose down`, `docker compose down -v`, artifact cleanup, hygiene command. |

Docs should not describe Traefik as the default. The default should be direct `127.0.0.1` access.

## CI and Smoke Proof

The existing `.github/workflows/ci.yml` has a dedicated `Adoption Demo Smoke` job:

- starts Postgres as a GitHub Actions service
- installs demo dependencies
- compiles with warnings as errors
- runs `mix ecto.setup`
- starts `mix phx.server`
- runs `python3 scripts/demo/adoption_smoke.py`

Keep this job as the canonical protocol/admin proof. It already exercises the same base URL default that the manual path uses.

Recommended v1.30 additions:

| Proof | Where | Rationale |
|-------|-------|-----------|
| `docker compose config` validation | CI, likely in `adoption-demo` job or release-hygiene job | Proves compose syntax/interpolation without starting Docker services. |
| App config test for issuer/base URL derivation | Demo test or root release contract test | Catches reintroduced hard-coded issuer. |
| Hygiene `--ci` check for generated demo artifacts | `release-hygiene` job | Prevents checked-in deps/_build/.DS_Store drift. |
| Optional Docker smoke job | Later in the milestone only if runtime cost is acceptable | Proves local Docker path but adds CI time and Docker-specific flakes. |

Do not replace the current host-run smoke with Docker smoke. The host-run job is simpler and closer to the library's embedded-Phoenix contract.

## Build Order

1. **Config contract first**
   - Make `config/config.exs` derive endpoint URL and Lockspire issuer from one base URL contract.
   - Preserve host-local defaults.
   - Add a narrow config test or smoke assertion path that fails on hard-coded issuer drift.

2. **Default compose topology**
   - Add Postgres service.
   - Make web depend on healthy DB.
   - Use direct port publishing with configurable host port.
   - Pass first-tier `LOCKSPIRE_DEMO_DB_*` env vars.
   - Keep deps/_build as named volumes.

3. **Startup and setup ergonomics**
   - Ensure container startup runs `mix deps.get`, `mix ecto.setup` or equivalent idempotent create/migrate/seed path, then `mix phx.server`.
   - Add demo URL/credential output from a Mix task or helper.
   - Avoid requiring maintainers to remember separate DB setup commands for Docker.

4. **Optional Traefik path**
   - Move hard-coded Traefik labels/network behind a profile or override.
   - Keep direct port path working.
   - Document network prerequisites and hostname override.

5. **Docs**
   - Update `docs/adoption-demo.md` around the new default Docker path.
   - Include conflict-resistant examples and cleanup.
   - Keep manual path and smoke path.

6. **Hygiene**
   - Extend `repo_hygiene_check.sh` with deterministic generated-artifact checks.
   - Add local Docker leftover warnings/blocks with project-name awareness.
   - Keep `--ci` free of local Docker state.

7. **CI proof**
   - Add compose config validation and hygiene checks.
   - Preserve current `Adoption Demo Smoke`.
   - Add Docker smoke only if the compose path has stabilized and job time is acceptable.

This order prevents the known failure mode where Docker starts successfully but discovery advertises the wrong issuer. Issuer/base URL correctness must land before compose and docs advertise the path.

## Anti-Patterns to Avoid

### Traefik as the Default

**What goes wrong:** New users run `docker compose up` and fail because `local-dev-proxy` does not exist.
**Prevention:** Direct port is default; Traefik is opt-in.

### Hard-Coded Issuer

**What goes wrong:** Discovery, token validation, redirect URIs, and smoke diverge when the demo runs on any URL other than `127.0.0.1:4100`.
**Prevention:** One base URL contract drives endpoint URL and `config :lockspire, :issuer`.

### Publishing Postgres on `5432` by Default

**What goes wrong:** The demo conflicts with host Postgres, CI service Postgres, or another local project.
**Prevention:** Keep DB internal by default. Publish only through an opt-in debug override.

### Docker-Orchestrating Smoke Script

**What goes wrong:** The smoke test becomes less reusable and harder to run against manual, Docker, Traefik, and CI paths.
**Prevention:** Smoke only takes `LOCKSPIRE_DEMO_BASE_URL` and speaks HTTP.

### Cleanup Hidden in Docs Only

**What goes wrong:** Generated `deps`, `_build`, `.DS_Store`, containers, and volumes continue to dirty release prep.
**Prevention:** Put checks in `repo_hygiene_check.sh`; docs explain remediation.

## Component Boundaries

| Boundary | Rule |
|----------|------|
| Demo config vs Lockspire library | Demo may configure Lockspire issuer/mount path; Lockspire library code should not change. |
| Compose vs app config | Compose supplies env and topology; `config.exs` decides final runtime values. |
| Docs vs scripts | Docs show commands; scripts prove or report. Do not make docs the only source of startup truth. |
| Smoke vs orchestration | Smoke tests HTTP behavior only. Docker/Phoenix startup remains outside it. |
| Hygiene vs cleanup | Hygiene reports and blocks/warns; cleanup commands stay explicit unless a separate cleanup script is introduced. |
| CI vs local Docker | CI proves protocol smoke and static compose validity; local Docker proves maintainer ergonomics. |

## Phase-Specific Research Flags

| Topic | Flag | Recommendation |
|-------|------|----------------|
| Compose profiles with external networks | MEDIUM confidence | Verify with `docker compose config` locally because profile + external network validation can be surprising. |
| Startup idempotency | HIGH risk if skipped | Ensure repeated container starts do not fail on existing DB/seeds. Prefer `ecto.create --quiet` tolerant handling or existing alias behavior if it is idempotent enough. |
| Phoenix bind vs URL split | HIGH importance | `http.ip` must bind `0.0.0.0` in Docker, while external URL should remain `127.0.0.1:<host-port>` or Traefik host. |
| Docker leftover detection | MEDIUM confidence | Use Compose project labels/names; do not block unrelated containers. |
| Elixir image version | MEDIUM confidence | `Dockerfile.dev` uses Elixir 1.15.7 while demo requires `~> 1.18` and CI uses 1.19.5/OTP 28. Align the image before relying on Docker as the default path. |

## Sources

- Repo source: `.planning/PROJECT.md`
- Repo source: `examples/adoption_demo/docker-compose.yml`
- Repo source: `examples/adoption_demo/Dockerfile.dev`
- Repo source: `examples/adoption_demo/config/config.exs`
- Repo source: `examples/adoption_demo/mix.exs`
- Repo source: `docs/adoption-demo.md`
- Repo source: `scripts/demo/adoption_smoke.py`
- Repo source: `scripts/maintainer/repo_hygiene_check.sh`
- Repo source: `.github/workflows/ci.yml`
- Docker Docs, Compose interpolation: https://docs.docker.com/reference/compose-file/interpolation/
- Docker Docs, Compose environment variables: https://docs.docker.com/compose/environment-variables/
- Docker Docs, predefined Compose env vars: https://docs.docker.com/compose/how-tos/environment-variables/envvars/
- Docker Docs, service `depends_on` and healthchecks: https://docs.docker.com/reference/compose-file/services/
