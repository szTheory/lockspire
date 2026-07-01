---
phase: 113-conflict-controls-optional-traefik
verified: 2026-06-04T21:33:21Z
status: passed
score: 11/11 must-haves verified
overrides_applied: 0
---

# Phase 113: Conflict Controls & Optional Traefik Verification Report

**Phase Goal:** conflict controls and optional Traefik for the adoption demo while preserving direct Docker defaults.
**Verified:** 2026-06-04T21:33:21Z
**Status:** passed
**Re-verification:** No - initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Default startup and reset share the `lockspire-adoption-demo` Compose project name, and maintainer overrides still work through `COMPOSE_PROJECT_NAME` or `-p` without changing Lockspire runtime code. | VERIFIED | `docker-compose.yml` sets `name: lockspire-adoption-demo`; rendered default config reports `name=lockspire-adoption-demo` and project-scoped volumes; rendered `--project-name lockspire-adoption-demo-alt` reports alternate name and volume prefixes. Reset defaults to `${COMPOSE_PROJECT_NAME:-lockspire-adoption-demo}` and accepts `--project`. |
| 2 | Maintainer can choose the public direct Docker app port while Phoenix `PORT` and the host port mapping stay aligned. | VERIFIED | Rendered alternate config with `LOCKSPIRE_DEMO_APP_PORT=4101` has published `4101`, target `4101`, and `PORT=4101`; source interpolation is in `examples/adoption_demo/docker-compose.yml:12-22`. |
| 3 | `LOCKSPIRE_DEMO_BASE_URL` remains the browser-visible URL truth for docs, startup output, and smoke commands. | VERIFIED | Compose injects `LOCKSPIRE_DEMO_BASE_URL`; `docker-start` prints and waits on `BASE_URL`; docs show alternate direct and Traefik smoke commands using `LOCKSPIRE_DEMO_BASE_URL`; smoke script reads the same env var. |
| 4 | Default PostgreSQL remains internal-only with no host `5432` publication. | VERIFIED | Default rendered config has `db_ports=null`; `examples/adoption_demo/docker-compose.yml:30-42` defines no `db.ports`. |
| 5 | Host PostgreSQL access is available only through an explicit opt-in override and configurable host port. | VERIFIED | `examples/adoption_demo/docker-compose.db-host.yml:1-4` adds only `db.ports`; rendered override with `LOCKSPIRE_DEMO_DB_HOST_PORT=15432` maps `127.0.0.1:15432 -> 5432` and leaves app `LOCKSPIRE_DEMO_DB_PORT=5432`. |
| 6 | Reset removes only the active demo project's `db_data`, `deps_volume`, and `build_volume` resources. | VERIFIED | `examples/adoption_demo/bin/docker-reset:55-58` runs `docker compose --project-name "$project" ... down` and removes only `"${project}_${suffix}"` for the three allowlisted suffixes; executable and `sh -n` passes. |
| 7 | Default direct Docker startup does not require Traefik or an external proxy network. | VERIFIED | Default rendered config has `has_traefik=false`; `docker-compose.yml` contains no Traefik labels or external proxy network. |
| 8 | Maintainer can opt into Traefik hostname routing with an explicit Compose override. | VERIFIED | `examples/adoption_demo/docker-compose.traefik.yml` is a separate override; docs instruct adding `-f examples/adoption_demo/docker-compose.traefik.yml`. |
| 9 | Only the web service joins the external Traefik proxy network; the database stays project-internal. | VERIFIED | Rendered Traefik config has `web_networks={"default":null,"traefik_proxy":null}` and `db_networks={"default":null}`; source attaches only `web` to `traefik_proxy`. |
| 10 | Traefik hostname, router name, service name, proxy network, and backend service port are configurable. | VERIFIED | Rendered Traefik config with custom env values produces `proxy_name=lockspire-alt-proxy` and labels for `lockspire-alt.localhost`, `lockspire-alt-router`, `lockspire-alt-service`, and backend port `4102`. |
| 11 | Traefik smoke examples pass the configured hostname through `LOCKSPIRE_DEMO_BASE_URL`. | VERIFIED | `docs/adoption-demo.md:81-104` shows Traefik startup and smoke using `LOCKSPIRE_DEMO_BASE_URL=http://lockspire-demo.localhost`. |

**Score:** 11/11 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `examples/adoption_demo/docker-compose.yml` | Direct Docker Compose conflict controls | VERIFIED | Exists, substantive, contains top-level project name, configurable app port, base URL, no default DB host port, no Traefik labels. |
| `examples/adoption_demo/docker-compose.db-host.yml` | Opt-in database host-port exposure | VERIFIED | Exists, substantive, adds loopback DB port mapping with `LOCKSPIRE_DEMO_DB_HOST_PORT`. |
| `examples/adoption_demo/docker-compose.traefik.yml` | Opt-in Traefik routing override | VERIFIED | Exists, substantive, defines labels and external proxy network only for `web`. |
| `examples/adoption_demo/bin/docker-reset` | Active-project scoped reset helper | VERIFIED | Exists, executable, shell syntax passes, scoped to active project and three named volume suffixes. |
| `docs/adoption-demo.md` | Conflict-control, reset, and Traefik instructions | VERIFIED | Documents project controls, app/base URL alignment, DB override, scoped reset, optional Traefik network/helper/override, and smoke commands. |
| `test/lockspire/adoption_demo_docker_contract_test.exs` | Deterministic Compose/reset/docs contract proof | VERIFIED | Defines `Lockspire.AdoptionDemoDockerContractTest`; invokes only `docker compose config --format json` and source/docs assertions; focused suite passes. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `docker-compose.yml` | `docker-reset` | Shared project namespace | WIRED | `gsd-sdk verify.key-links` verified `lockspire-adoption-demo`; rendered project names match reset defaults and overrides. |
| `docker-compose.yml` | adoption demo config/startup | `PORT` and `LOCKSPIRE_DEMO_BASE_URL` env | WIRED | Compose sets both env vars; config and startup script consume them. |
| `docker-compose.db-host.yml` | `db` service | Opt-in ports mapping | WIRED | Override renders loopback host port to container `5432`; default config has no DB ports. |
| `docker-reset` | Docker Compose project volumes | Active project namespace | WIRED | Reset uses `--project-name "$project"` and removes only `"${project}_db_data"`, `"${project}_deps_volume"`, `"${project}_build_volume"`. |
| `docker-compose.traefik.yml` | `tools/traefik/docker-compose.yml` | Shared external proxy network | WIRED | Override defines external `traefik_proxy` with configurable network name; docs start the repo-local Traefik helper. |
| `docker-compose.traefik.yml` | `docker-compose.yml` | Override extends `web` and uses app port | WIRED | Traefik override extends only `web` and backend label uses `${LOCKSPIRE_DEMO_APP_PORT:-4100}`. |
| `docs/adoption-demo.md` | `scripts/demo/adoption_smoke.py` | Hostname base URL env | WIRED | Docs pass `LOCKSPIRE_DEMO_BASE_URL=http://lockspire-demo.localhost`; smoke script consumes `LOCKSPIRE_DEMO_BASE_URL`. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| `docker-compose.yml` | `LOCKSPIRE_DEMO_APP_PORT`, `LOCKSPIRE_DEMO_BASE_URL` | Compose env interpolation rendered by Docker Compose | Yes | FLOWING |
| `docker-compose.db-host.yml` | `LOCKSPIRE_DEMO_DB_HOST_PORT` | Compose env interpolation rendered by Docker Compose | Yes | FLOWING |
| `docker-compose.traefik.yml` | Traefik host/router/service/network/app port env vars | Compose env interpolation rendered by Docker Compose | Yes | FLOWING |
| `docker-reset` | active project name | `COMPOSE_PROJECT_NAME` or `--project` | Yes | FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Focused Docker contract test suite | `mix test test/lockspire/adoption_demo_docker_contract_test.exs --seed 0` | 11 tests, 0 failures. Pre-existing local Postgres connection errors were logged by unrelated app startup hooks, but the focused suite completed successfully. | PASS |
| Default direct Compose render | `docker compose -f examples/adoption_demo/docker-compose.yml config --format json` | Rendered `name=lockspire-adoption-demo`, app `4100:4100`, `db_ports=null`, scoped volume names, and no Traefik content. | PASS |
| Alternate direct app port render | `LOCKSPIRE_DEMO_APP_PORT=4101 LOCKSPIRE_DEMO_BASE_URL=http://127.0.0.1:4101 docker compose --project-name lockspire-adoption-demo-alt -f examples/adoption_demo/docker-compose.yml config --format json` | Rendered alternate project, app `4101:4101`, `PORT=4101`, base URL `http://127.0.0.1:4101`, and alternate volume names. | PASS |
| DB host opt-in render | `LOCKSPIRE_DEMO_DB_HOST_PORT=15432 docker compose -f examples/adoption_demo/docker-compose.yml -f examples/adoption_demo/docker-compose.db-host.yml config --format json` | Rendered DB port `127.0.0.1:15432 -> 5432`; app DB port remains `5432`. | PASS |
| Traefik opt-in render | `LOCKSPIRE_DEMO_APP_PORT=4102 ... docker compose -f examples/adoption_demo/docker-compose.yml -f examples/adoption_demo/docker-compose.traefik.yml config --format json` | Rendered web on default plus proxy network, db only on default, external proxy name `lockspire-alt-proxy`, and configured labels. | PASS |
| Reset helper syntax and mode | `test -x examples/adoption_demo/bin/docker-reset && sh -n examples/adoption_demo/bin/docker-reset` | Executable and shell syntax valid. | PASS |

### Probe Execution

| Probe | Command | Result | Status |
| --- | --- | --- | --- |
| None | Probe discovery not applicable; phase plans declare Compose render and ExUnit checks, not `probe-*.sh` scripts. | No probes to run. | SKIP |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| `CONFLICT-01` | `113-01-PLAN.md` | Demo Compose project name is configurable to avoid resource-name collisions. | SATISFIED | Top-level `name`; rendered default and alternate project/volume names; docs show `COMPOSE_PROJECT_NAME` and `--project-name`. |
| `CONFLICT-02` | `113-01-PLAN.md`, `113-02-PLAN.md` | Public app port is configurable and printed URLs, docs, and smoke commands use configured base URL. | SATISFIED | Rendered app port/base URL alignment; docs direct and Traefik smoke commands pass `LOCKSPIRE_DEMO_BASE_URL`; startup consumes `BASE_URL`. |
| `CONFLICT-03` | `113-01-PLAN.md` | PostgreSQL does not publish host `5432` by default; host exposure is opt-in and configurable. | SATISFIED | Default render has no DB ports; override renders loopback `15432 -> 5432`. |
| `CONFLICT-04` | `113-01-PLAN.md` | Cache reset targets only active demo Compose project's database, `deps`, and `_build` volumes. | SATISFIED | Reset helper defaults/overrides active project and removes only `db_data`, `deps_volume`, and `build_volume`. |
| `TRAEFIK-01` | `113-02-PLAN.md` | Traefik hostname routing is optional and never required for default Docker path. | SATISFIED | Default render has no Traefik labels or proxy network; docs say Traefik is optional. |
| `TRAEFIK-02` | `113-02-PLAN.md` | Optional Traefik mode documents or automates required external network and uses configurable hostname/router/service labels. | SATISFIED | Override renders configurable labels/network; docs show `docker network create`, repo-local Traefik helper, override startup, env vars, and smoke command. |

No orphaned Phase 113 requirements found: `.planning/REQUIREMENTS.md` maps exactly `CONFLICT-01`, `CONFLICT-02`, `CONFLICT-03`, `CONFLICT-04`, `TRAEFIK-01`, and `TRAEFIK-02` to Phase 113, and all six appear in plan frontmatter.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| None | - | - | - | No unreferenced `TBD`, `FIXME`, or `XXX` markers; no placeholder implementations; no prune/global reset commands. Matches for `traefik.http` and `local-dev-proxy` are intended Traefik labels/docs or negative test assertions. |

### Human Verification Required

None. This phase's user-facing behavior is Compose/docs configuration. The required outcomes were verified through rendered Compose config, source inspection, and focused contract tests without starting services.

### Gaps Summary

No gaps found. Direct Docker remains the default path, app and DB conflict controls are explicit, reset is active-project scoped, and Traefik is isolated to an opt-in override with configurable routing labels and documented hostname smoke usage.

---

_Verified: 2026-06-04T21:33:21Z_
_Verifier: the agent (gsd-verifier)_
