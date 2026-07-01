# Technology Stack: v1.30 Adoption Demo Docker DX & Repo Hygiene

**Project:** Lockspire
**Milestone:** v1.30 Adoption Demo Docker DX & Repo Hygiene
**Researched:** 2026-06-04
**Overall confidence:** HIGH for Docker Compose/Phoenix/Traefik mechanics; MEDIUM for exact script naming because implementation should fit maintainer taste during planning.

## Recommendation

Make `examples/adoption_demo/docker-compose.yml` the single default Docker entrypoint for the repo-local adoption demo. It should start a Phoenix/Bandit app container plus a PostgreSQL service, publish the demo on `127.0.0.1:${LOCKSPIRE_DEMO_PORT:-4100}`, and keep Traefik hostname routing behind an explicit profile. Do not make Traefik, conformance-suite Docker lanes, TLS, or production release images part of this milestone.

The stack change is mostly configuration discipline:

- Docker Compose v2 with a stable default project name and `.env.example`/optional `.env` overrides.
- `postgres:14` or `postgres:14-alpine` with a named data volume scoped by the Compose project.
- Phoenix/Bandit bound to `0.0.0.0` inside Docker, with generated URL/issuer values derived from one external base URL.
- Optional Traefik labels/network only when `--profile traefik` or `COMPOSE_PROFILES=traefik` is enabled.
- Maintainer shell scripts that wrap Compose commands, print URLs/accounts/smoke commands, and run repo hygiene checks without broadening CI/conformance behavior.

## Current Repo State

| File | Current State | Required Change |
| --- | --- | --- |
| `docs/adoption-demo.md` | Host-machine `mix deps.get`, `mix ecto.setup`, `mix phx.server`; assumes local Postgres. | Document Docker as the default path, retain bare-metal path as optional, list env overrides and cleanup commands. |
| `examples/adoption_demo/docker-compose.yml` | One `web` service, Traefik-only network, no Postgres, no direct port publish. | Add `db`, default local port publishing, healthcheck-gated app startup, named volumes, project/env interpolation, optional Traefik profile. |
| `examples/adoption_demo/Dockerfile.dev` | Elixir 1.15.7/Erlang 26 Alpine, build tools, npm, git, inotify; runs `mix deps.get && mix phx.server`. | Keep dev image shape; prefer moving setup/migration/start orchestration into a small checked-in entrypoint script or Compose `command`. Avoid production image work. |
| `examples/adoption_demo/config/config.exs` | HTTP binds to `{127,0,0,1}`; DB defaults to host `localhost`; Lockspire issuer hard-coded to `http://127.0.0.1:4100/lockspire`. | Bind to `0.0.0.0` in Docker, preserve loopback for bare-metal if desired, derive endpoint URL and `:lockspire, :issuer` from `LOCKSPIRE_DEMO_BASE_URL`. |
| `tools/traefik/docker-compose.yml` | Traefik v2.10 on external `local-dev-proxy`; publishes `80` and `8080`. | Keep optional. Add docs/script support to create the external network and start Traefik only for hostname routing. Do not make it required for the demo. |
| `scripts/maintainer/repo_hygiene_check.sh` | Release-train gate: version drift, release docs, worktree state, CI status, optional `mix ci`. | Add repo-local generated-artifact/Docker-leftover checks or pair with a new cleanup script; do not make Docker daemon availability mandatory in `--ci`. |

## Recommended Stack Additions

### Docker Compose Project Model

| Addition | Recommendation | Why |
| --- | --- | --- |
| Compose project name | Use `name: ${LOCKSPIRE_DEMO_COMPOSE_PROJECT:-lockspire-adoption-demo}` in `examples/adoption_demo/docker-compose.yml`; scripts may also pass `-p "$project"` for explicit override. | Docker Compose uses project names to group and isolate resources. This directly addresses collisions when multiple local admin UI demos are running. |
| Env interpolation | Add `examples/adoption_demo/.env.example`; let maintainers copy to `.env`, or have scripts load `--env-file examples/adoption_demo/.env` when present. | Compose automatically uses `.env` in the project directory for interpolation when no `--env-file` is supplied, and `COMPOSE_PROJECT_NAME` maps to `-p`. Keep this as local-only config. |
| Profiles | Put Traefik-specific service/labels/network behavior behind `profiles: ["traefik"]` or a Compose override selected by a script. Default `docker compose up` should include only app and db. | Compose services without profiles are always enabled; profiled services are ignored unless enabled. This keeps direct port mode boring and conflict-resistant. |
| Port mapping | Publish Phoenix as `"127.0.0.1:${LOCKSPIRE_DEMO_PORT:-4100}:4000"`. Do not publish Postgres by default; optionally publish `"127.0.0.1:${LOCKSPIRE_DEMO_DB_PORT_PUBLISHED:-15432}:5432"` behind a debug opt-in only if needed. | Docker warns that unqualified port mappings bind to all interfaces. The demo is local DX, not a network service. |

Recommended `.env.example` variables:

```dotenv
LOCKSPIRE_DEMO_COMPOSE_PROJECT=lockspire-adoption-demo
LOCKSPIRE_DEMO_PORT=4100
LOCKSPIRE_DEMO_BASE_URL=http://127.0.0.1:4100
LOCKSPIRE_DEMO_DB_NAME=lockspire_adoption_demo
LOCKSPIRE_DEMO_DB_USER=lockspire
LOCKSPIRE_DEMO_DB_PASSWORD=lockspire
LOCKSPIRE_DEMO_TRAEFIK_HOST=adoption-demo.localhost
LOCKSPIRE_DEMO_TRAEFIK_NETWORK=local-dev-proxy
```

Use `LOCKSPIRE_DEMO_BASE_URL` as the source of truth for external browser/API URLs. In direct mode it is `http://127.0.0.1:${LOCKSPIRE_DEMO_PORT:-4100}`. In Traefik mode it is `http://${LOCKSPIRE_DEMO_TRAEFIK_HOST:-adoption-demo.localhost}`.

### App + Postgres Compose Flow

Use two always-on services:

| Service | Image/Build | Key Configuration |
| --- | --- | --- |
| `db` | `postgres:14-alpine` | `POSTGRES_DB`, `POSTGRES_USER`, `POSTGRES_PASSWORD`; healthcheck with `pg_isready`; named volume `postgres_data:/var/lib/postgresql/data`; no default host port. |
| `web` | `build: { context: ., dockerfile: Dockerfile.dev }` | Depends on `db: { condition: service_healthy }`; bind mount `.` to `/app`; named volumes for `/app/deps` and `/app/_build`; env points DB host to `db`; `PORT=4000`; `LOCKSPIRE_DEMO_BIND_IP=0.0.0.0`; external URL from `LOCKSPIRE_DEMO_BASE_URL`; local port publish to `127.0.0.1`. |

The app startup command should run the minimum needed setup each time:

```sh
mix deps.get
mix ecto.setup
mix phx.server
```

That is acceptable for a repo-local DX container because `deps` and `_build` are named volumes. If `ecto.setup` becomes too destructive after repeated runs, switch to an idempotent sequence such as `mix ecto.create || true && mix ecto.migrate && mix run priv/repo/seeds.exs && mix phx.server`; keep that logic in one shell script so Compose YAML stays readable.

Do not add an app release image, multi-stage production Dockerfile, Kubernetes manifests, testcontainers, pgAdmin, Redis, or Oban-specific infrastructure. The demo currently configures Oban queues/plugins as disabled, and this milestone is about local adoption proof, not production deployment.

### Phoenix, Bandit, and Issuer Configuration

Change `examples/adoption_demo/config/config.exs` so Docker and bare-metal can both work from env:

| Setting | Recommendation | Rationale |
| --- | --- | --- |
| HTTP listen IP | `LOCKSPIRE_DEMO_BIND_IP=0.0.0.0` in Docker; default can remain `127.0.0.1` for bare-metal. Parse into tuple safely. | Containers must listen on all container interfaces for Docker port publishing/Traefik. Bare-metal should stay loopback-local. |
| Internal port | Keep container `PORT=4000`; keep bare-metal default `4100`. | Separates stable in-container port from externally configurable host port. |
| Endpoint `url` | Derive `scheme`, `host`, and `port` from `LOCKSPIRE_DEMO_BASE_URL`, not from separate host/port env vars. | Phoenix uses endpoint `:url` for generated URLs; one base URL avoids redirect/discovery drift. |
| Lockspire issuer | `issuer: "#{base_url}/lockspire"` where `base_url` is normalized without trailing slash. | OIDC discovery, JWKS, authorization redirects, seeded client URIs, smoke tests, and admin links must agree exactly on issuer. |
| DB host | Docker env sets `LOCKSPIRE_DEMO_DB_HOST=db`; bare-metal keeps `localhost`. | Removes host Postgres requirement from default Docker path. |

This repo has hard-coded seeded redirect and return URLs in `examples/adoption_demo/priv/repo/seeds.exs` (`http://127.0.0.1:4100/...`). v1.30 should update seeds to derive demo URLs from the same base URL or ensure Docker mode seeds are regenerated with the chosen base URL. Otherwise Traefik mode will boot but auth-code callbacks and admin/operator flows will still point at the direct-port issuer.

Implementation target:

```elixir
base_url =
  System.get_env("LOCKSPIRE_DEMO_BASE_URL") ||
    "http://127.0.0.1:#{System.get_env("PORT") || "4100"}"

%URI{scheme: scheme, host: host, port: uri_port} = URI.parse(base_url)
external_port = uri_port || if scheme == "https", do: 443, else: 80
```

Then use `scheme`, `host`, `external_port` for endpoint `url`, and `base_url <> "/lockspire"` for issuer. Keep `LOCKSPIRE_DEMO_BASE_URL` documented as a required override whenever ports or Traefik hostnames change.

### Optional Traefik Profile

Keep `tools/traefik/docker-compose.yml` as the local shared proxy tool, but do not require it for the adoption demo. The clean path is:

1. Default mode: `docker compose up` from `examples/adoption_demo` starts `web` and `db`, URL `http://127.0.0.1:4100`.
2. Optional proxy mode: script creates `local-dev-proxy` if missing, starts `tools/traefik`, then starts the adoption demo with `COMPOSE_PROFILES=traefik` and `LOCKSPIRE_DEMO_BASE_URL=http://adoption-demo.localhost`.

Traefik labels on `web` should be parameterized:

```yaml
labels:
  traefik.enable: "true"
  traefik.docker.network: "${LOCKSPIRE_DEMO_TRAEFIK_NETWORK:-local-dev-proxy}"
  traefik.http.routers.lockspire-adoption-demo.rule: "Host(`${LOCKSPIRE_DEMO_TRAEFIK_HOST:-adoption-demo.localhost}`)"
  traefik.http.services.lockspire-adoption-demo.loadbalancer.server.port: "4000"
```

Network guidance:

- Keep the normal app/db network private to the Compose project.
- Attach `web` to the external Traefik network only in the Traefik profile/override.
- Do not attach `db` to the Traefik network.
- Traefik is configured with `exposedByDefault=false`, so labels are required and should be present only for the intended web service.

The current `tools/traefik/docker-compose.yml` uses `traefik:v2.10`. This can stay pinned for a small local tool. Upgrading to Traefik v3 is not necessary for this milestone and would add unrelated compatibility churn.

### Maintainer Script Shape

Add one or two small Bash wrappers instead of asking maintainers to memorize Compose flags:

| Script | Purpose | Suggested Behavior |
| --- | --- | --- |
| `scripts/demo/adoption_demo_up.sh` | Start app+db and print operator-ready URLs. | `set -euo pipefail`; verify `docker compose`; resolve repo root; load optional env file; compute base URL; run `docker compose -f examples/adoption_demo/docker-compose.yml up --build`; optionally support `--detached`, `--traefik`, `--project-name`, `--port`. |
| `scripts/demo/adoption_demo_down.sh` or `--down` flag | Stop demo and optionally remove volumes. | Run the same Compose project selection; `down` by default, `down -v` only with an explicit `--volumes`/`--reset` flag. |
| `scripts/maintainer/repo_hygiene_check.sh` additions | Report generated artifacts and Docker leftovers. | In local mode only, warn/block on tracked/ignored demo artifacts that should be cleaned; optionally warn if a `lockspire-adoption-demo` Compose project is still running. In `--ci`, avoid Docker daemon dependence. |

Startup output should print:

```text
Lockspire adoption demo
Base URL: http://127.0.0.1:4100
Issuer:   http://127.0.0.1:4100/lockspire
Admin:    http://127.0.0.1:4100/admin/lockspire
Smoke:    LOCKSPIRE_DEMO_BASE_URL=http://127.0.0.1:4100 python3 scripts/demo/adoption_smoke.py

Seeded accounts:
  alice / alice@acme.test
  bob   / bob@globex.test
  ops   / ops@acme.test
```

The script should not run the black-box smoke automatically in the normal `up` path; print the exact command. A separate `--smoke` flag is acceptable if it runs after the app is healthy.

### Repo Hygiene

The existing hygiene script already treats dirty worktrees as `BLOCK` in local mode and runs repo-owned drift checks in CI. v1.30 should add focused checks for this milestone:

- `PASS/WARN/BLOCK` if known generated demo directories are present in tracked paths or ignored paths that should be cleaned before UI work: `examples/adoption_demo/deps`, `examples/adoption_demo/_build`, `examples/adoption_demo/assets/node_modules` if generated, `tmp/adoption_demo.log`, screenshot/browser artifacts if they are generated by local proof.
- `WARN` if Docker Compose projects matching `lockspire-adoption-demo*` are running locally, with a cleanup command.
- `PASS` if no dangling adoption demo volumes/containers are detected; `WARN`, not `BLOCK`, unless the project explicitly selected a cleanup gate.
- `--ci` should remain Docker-free unless CI intentionally starts the demo in a dedicated job. GitHub runners should not fail because Docker state inspection is unavailable.

Prefer a cleanup lane such as:

```sh
./scripts/demo/adoption_demo_down.sh --volumes
rm -rf examples/adoption_demo/deps examples/adoption_demo/_build tmp/adoption_demo.log
./scripts/maintainer/repo_hygiene_check.sh --skip-mix-ci
```

Do not have the hygiene script delete files by default. It should report and print explicit cleanup commands.

## Alternatives Considered

| Category | Recommended | Alternative | Why Not |
| --- | --- | --- | --- |
| Default access path | Direct host port on `127.0.0.1:4100` | Traefik-only hostname | Requires shared port 80 and external network; conflicts with other local projects. |
| Database | Compose-managed Postgres 14 named volume | Host Postgres | Current docs depend on host state; milestone goal explicitly removes that default dependency. |
| URL configuration | Single `LOCKSPIRE_DEMO_BASE_URL` drives endpoint URL, issuer, seeds, smoke | Separate host/port/issuer env vars | Easy for OIDC discovery, redirect URIs, and smoke tests to disagree. |
| Traefik integration | Optional profile/override labels | Required service in demo Compose | Pulls Docker socket and port 80 into the default path; bad local default. |
| Docker image | Dev image with bind mount and named deps/build volumes | Production release image | v1.30 is adoption-demo DX, not deployment packaging. |
| Script model | Thin repo scripts around Compose | Makefile-only or long docs-only commands | Scripts can print the exact URLs/accounts/smoke command and normalize project/env behavior. |
| Hygiene cleanup | Report plus explicit cleanup command | Auto-delete from hygiene check | Risky in dirty worktrees; violates maintainer trust. |

## What Not To Add

- No conformance-suite Docker lane changes.
- No new OAuth/OIDC protocol behavior.
- No standalone hosted auth service shape.
- No production Dockerfile, release image, Kubernetes/Helm, Terraform, TLS automation, or certificate management.
- No pgAdmin/Adminer unless a later operator milestone proves a need.
- No Redis or Oban infrastructure for the demo; existing demo config disables Oban queues/plugins.
- No default Postgres host port exposure.
- No hard-coded `container_name`; it defeats Compose project isolation.
- No Traefik requirement for the default demo path.
- No `.env` committed with secrets/state; commit `.env.example` only.

## Implementation Checklist for Roadmap

1. **Compose default app+db**
   - Add `db` service, healthcheck, named `postgres_data`.
   - Convert `web` to depend on healthy db.
   - Publish `127.0.0.1:${LOCKSPIRE_DEMO_PORT:-4100}:4000`.
   - Keep `deps_volume` and `build_volume`.

2. **Config URL consistency**
   - Add base URL parsing helper in `config.exs`.
   - Bind Docker app to `0.0.0.0`.
   - Derive endpoint `url` and Lockspire issuer from one base URL.
   - Update demo seeds/smoke/docs to honor the same base URL.

3. **Traefik opt-in**
   - Move labels/network to profile or override.
   - Document/create external network.
   - Keep `tools/traefik` separate.

4. **Scripts and docs**
   - Add demo up/down wrappers.
   - Print base URL, issuer, admin route, seeded accounts, and smoke command.
   - Rewrite `docs/adoption-demo.md` around Docker default and bare-metal fallback.

5. **Repo hygiene**
   - Add local checks for generated demo artifacts and Docker leftovers.
   - Keep `--ci` deterministic and Docker-daemon independent.
   - Add a documented cleanup lane.

## Sources

- Docker Compose application model: project names group and isolate resources; Compose can deploy the same file more than once with distinct names. HIGH confidence. https://docs.docker.com/compose/intro/compose-application-model/
- Docker Compose CLI/env vars: `COMPOSE_PROJECT_NAME` maps to `-p`; `COMPOSE_PROFILES` maps to `--profile`; `.env` is used by default when no `--env-file` is supplied. HIGH confidence. https://docs.docker.com/reference/cli/docker/compose/ and https://docs.docker.com/compose/how-tos/environment-variables/envvars/
- Docker Compose services reference: `env_file`, `ports`, `volumes`, `healthcheck`, `depends_on.condition: service_healthy`, and `profiles`. HIGH confidence. https://docs.docker.com/reference/compose-file/services/
- Docker Compose profiles reference: unprofiled services are always enabled; profiled services are ignored unless enabled. HIGH confidence. https://docs.docker.com/reference/compose-file/profiles/
- Traefik Docker provider v2.10: Docker labels configure routing; `exposedByDefault=false` ignores unlabeled containers; `traefik.docker.network` overrides the network used to reach a container; service port labels route to a specific internal port. HIGH confidence. https://doc.traefik.io/traefik/v2.10/providers/docker/
- Phoenix Endpoint v1.8 docs: `:url` controls generated URLs, accepts `host`, `scheme`, `path`, and `port`; `:server` starts the web server; `:url` is relevant behind reverse proxies. HIGH confidence. https://hexdocs.pm/phoenix/Phoenix.Endpoint.html
- Repo source read on 2026-06-04: `.planning/PROJECT.md`, `docs/adoption-demo.md`, `examples/adoption_demo/docker-compose.yml`, `examples/adoption_demo/Dockerfile.dev`, `examples/adoption_demo/config/config.exs`, `tools/traefik/docker-compose.yml`, `scripts/maintainer/repo_hygiene_check.sh`. HIGH confidence.
