# Phase 112: Default Docker Compose App + DB - Research

## RESEARCH COMPLETE

## Objective

Plan the default Docker path for the repo-local adoption demo so maintainers can start Phoenix/Bandit plus PostgreSQL without host Postgres while preserving the Phase 111 base-URL contract.

## Findings

### R-01: Compose should be promoted from app-only/Traefik-only to a direct default stack

`examples/adoption_demo/docker-compose.yml` already owns the demo web service, source mount, and `deps`/`_build` isolation. It currently assumes an external `local-dev-proxy` network and has no database service, so it cannot satisfy DOCKER-01/02 by itself.

Best plan: keep this file as the default Compose entrypoint but make the default service graph direct and self-contained: `web` plus `db`, host port on the web service, no required Traefik network.

### R-02: Repo-root startup needs a repo-root container mount

The adoption demo's `mix.exs` depends on Lockspire with `{:lockspire, path: "../.."}`. A container that mounts only `examples/adoption_demo` at `/app` cannot resolve that dependency correctly because `../..` points outside the mounted source.

Best plan: set the image workdir to the demo directory under a repo-root mount, for example `/workspace/examples/adoption_demo`, and mount the repository root at `/workspace`. Compose can still isolate `/workspace/examples/adoption_demo/deps` and `/workspace/examples/adoption_demo/_build` with named volumes.

### R-03: Database wiring already has the right env seam

`examples/adoption_demo/config/config.exs` reads `LOCKSPIRE_DEMO_DB_USER`, `LOCKSPIRE_DEMO_DB_PASSWORD`, `LOCKSPIRE_DEMO_DB_HOST`, `LOCKSPIRE_DEMO_DB_PORT`, and `LOCKSPIRE_DEMO_DB_NAME`. CI uses the same env family in `.github/workflows/ci.yml`.

Best plan: wire Compose Postgres `POSTGRES_DB`, `POSTGRES_USER`, and `POSTGRES_PASSWORD` to matching `LOCKSPIRE_DEMO_DB_*` values in `web`. Set `LOCKSPIRE_DEMO_DB_HOST=db` and `LOCKSPIRE_DEMO_DB_PORT=5432` for the Docker network.

### R-04: Repeated container starts need a wrapper, not the current alias as-is

`examples/adoption_demo/mix.exs` defines `ecto.setup` as `ecto.create`, migration, seed. The seed script truncates Lockspire tables and reseeds artificial proof state, so seed execution is repeatable. The create step is the weak point: a repeated `mix ecto.setup` can fail once the database already exists.

Best plan: add a demo-owned shell script that waits for Postgres, runs `mix deps.get`, runs `mix ecto.create` tolerating the already-exists case, then runs migrations and seeds explicitly. Keep this script local to the adoption demo or `scripts/demo/`.

### R-05: HTTP readiness should reuse the Phase 111 public URL contract

`scripts/demo/adoption_smoke.py` already waits for `LOCKSPIRE_DEMO_BASE_URL` `/` to return HTTP 200. Phase 112 only needs startup readiness, not the full smoke. A lightweight shell loop with `curl -fsS "$LOCKSPIRE_DEMO_BASE_URL/"` is enough before printing a minimal ready line.

Best plan: the startup script starts `mix phx.server` in the background, waits for the public base URL, prints a concise ready line, and then waits on the Phoenix process. Full URL/account/client/smoke banner output remains Phase 114.

## Validation Architecture

### Deterministic Source Checks

- `docker compose -f examples/adoption_demo/docker-compose.yml config` should show both `web` and `db` services.
- Compose config should include a `postgres:14` or newer 14+ image, a `pg_isready` healthcheck, and named volumes for database data, demo deps, and demo build artifacts.
- Compose config should not publish `5432:5432`.
- Compose config should set `LOCKSPIRE_DEMO_DB_HOST=db`, `LOCKSPIRE_DEMO_BIND_IP=0.0.0.0`, and a `LOCKSPIRE_DEMO_BASE_URL` direct URL.

### Runtime Checks

- With Docker available, `docker compose -f examples/adoption_demo/docker-compose.yml up --build` should start from the repo root without host Postgres.
- Startup should create or reuse the database, migrate, seed, wait for HTTP 200 at `LOCKSPIRE_DEMO_BASE_URL`, and print a minimal ready line.
- `python3 scripts/demo/adoption_smoke.py` should remain usable against the direct Docker URL, but full Docker smoke in CI is deferred.

## Implementation Notes

- Keep credentials artificial and demo-scoped.
- Keep Postgres host port unpublished by default.
- Keep the default Docker path direct; optional Traefik belongs to Phase 113.
- Keep documentation narrow in this phase: enough to expose the repo-root command, not the full Phase 114 demo guide.

## Sources

- `.planning/REQUIREMENTS.md`
- `.planning/ROADMAP.md`
- `.planning/phases/112-default-docker-compose-app-db/112-CONTEXT.md`
- `.planning/phases/111-demo-url-contract-config-unification/111-CONTEXT.md`
- `examples/adoption_demo/docker-compose.yml`
- `examples/adoption_demo/Dockerfile.dev`
- `examples/adoption_demo/config/config.exs`
- `examples/adoption_demo/mix.exs`
- `examples/adoption_demo/priv/repo/seeds.exs`
- `scripts/demo/adoption_smoke.py`
- `.github/workflows/ci.yml`
