---
phase: 112-default-docker-compose-app-db
status: passed
verified_at: 2026-06-04T19:18:00Z
requirements_verified: [DOCKER-01, DOCKER-02, DOCKER-03, DOCKER-04, DOCKER-05, DOCKER-06]
automated_checks:
  passed: 18
  failed: 0
human_verification: []
gaps: []
---

# Phase 112 Verification

## Verdict

Phase 112 passed verification. The adoption demo now has a default direct Docker
Compose path with Phoenix/Bandit plus PostgreSQL, explicit database wiring,
project-scoped volumes, idempotent database preparation, and public HTTP readiness
before the ready line.

## Requirement Traceability

| Requirement | Status | Evidence |
|-------------|--------|----------|
| DOCKER-01 | passed | `docs/adoption-demo.md` documents the repo-root `docker compose -f examples/adoption_demo/docker-compose.yml up --build` command and direct URL `http://127.0.0.1:4100`. Runtime proof reached readiness without host Postgres. |
| DOCKER-02 | passed | Rendered Compose includes `web` and `db`; `db` uses `postgres:14`; `web` sets explicit `LOCKSPIRE_DEMO_DB_*` values and depends on the healthy DB service. |
| DOCKER-03 | passed | Rendered Compose includes the PostgreSQL `pg_isready -U lockspire -d lockspire_adoption_demo` healthcheck and `db_data:/var/lib/postgresql/data`; no host `5432` port is published. |
| DOCKER-04 | passed | Compose mounts named `deps_volume` and `build_volume` under `/workspace/examples/adoption_demo/deps` and `/workspace/examples/adoption_demo/_build` while bind-mounting the repo at `/workspace`. |
| DOCKER-05 | passed | `examples/adoption_demo/bin/docker-start` waits for Postgres, runs `mix deps.get`, creates or reuses the DB, runs migrations, and runs the existing `priv/repo/seeds.exs` seed file before starting readiness reporting. |
| DOCKER-06 | passed | `bin/docker-start` starts Phoenix, waits for `curl -fsS "${LOCKSPIRE_DEMO_BASE_URL}/"`, and prints `Adoption demo ready at http://127.0.0.1:4100` only after HTTP readiness. |

## Must-Have Checks

- Plan 112-01 truths: passed.
- Plan 112-02 truths: passed.
- Phase 111 URL contract is preserved: `LOCKSPIRE_DEMO_BASE_URL` remains the public URL and `LOCKSPIRE_DEMO_BIND_IP=0.0.0.0` is used only for Docker listener binding.
- Optional Traefik, configurable project names/ports, reset/cleanup, full banner output, and CI Docker smoke remain deferred to later v1.30 phases.
- No OAuth/OIDC protocol behavior, admin workflow behavior, production Docker packaging, or hosted-auth service shape was added.

## Automated Evidence

- `docker compose -f examples/adoption_demo/docker-compose.yml config >/tmp/lockspire-phase112-compose.yml` passed.
- Rendered Compose assertions passed for `web`, `db`, `postgres:14`, `LOCKSPIRE_DEMO_DB_HOST: db`, `LOCKSPIRE_DEMO_BIND_IP: 0.0.0.0`, `LOCKSPIRE_DEMO_BASE_URL: http://127.0.0.1:4100`, `pg_isready`, `./bin/docker-start`, `condition: service_healthy`, and port `4100`.
- Rendered Compose negative assertions passed: no `5432:5432`, no `local-dev-proxy`, and no `traefik.http`.
- `test -x examples/adoption_demo/bin/docker-start` passed.
- `sh -n examples/adoption_demo/bin/docker-start` passed.
- Startup wrapper source assertions passed for `pg_isready`, `mix deps.get`, `mix ecto.create`, `mix ecto.migrate --migrations-path ../../priv/repo/migrations`, `mix run priv/repo/seeds.exs`, `mix phx.server`, `LOCKSPIRE_DEMO_BASE_URL`, `curl -fsS`, and `Adoption demo ready at`.
- Startup wrapper redaction assertions passed: no account/client secret/token/cookie/private-key/smoke-command terms in the wrapper source.
- Dockerfile assertions passed for `DEBIAN_FRONTEND=noninteractive`, `WORKDIR /workspace/examples/adoption_demo`, Hex/Rebar install, and no `MIX_ENV=prod`.
- Documentation assertions passed for the repo-root Docker command, direct URL, host-local fallback, and no Traefik/reset/cleanup language.
- `docker manifest inspect hexpm/elixir:1.18.4-erlang-28.5-ubuntu-noble-20260509.1` passed during execution.
- `docker compose -f examples/adoption_demo/docker-compose.yml up --build` reached `Adoption demo ready at http://127.0.0.1:4100` during execution.
- `LOCKSPIRE_DEMO_BASE_URL=http://127.0.0.1:4100 python3 scripts/demo/adoption_smoke.py` printed `adoption demo smoke passed` during execution.
- `gsd-sdk query verify.schema-drift 112` passed with `drift_detected: false`.
- Code review gate passed: `112-REVIEW.md` status `clean`.

## Issues And Deviations

- The planned legacy HexPM Alpine base image no longer resolved. The demo image now uses a valid HexPM Ubuntu Noble image, with equivalent build/readiness utilities installed through apt.
- `curl` and PostgreSQL client utilities were added to support HTTP readiness and `pg_isready`.
- Seed stdout is suppressed during Docker startup unless seeding fails, preserving the Phase 112 minimal-output contract.
- `DEBIAN_FRONTEND=noninteractive` was added after build-log review to keep apt package installation noninteractive.

## Human Verification

None required.

## Gaps

None.
