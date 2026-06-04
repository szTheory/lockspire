# Phase 113: Conflict Controls & Optional Traefik - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md - this log preserves the analysis.

**Date:** 2026-06-04
**Phase:** 113-conflict-controls-optional-traefik
**Mode:** assumptions
**Areas analyzed:** Direct Docker Conflict Surface, Base URL Propagation, Database Exposure And Reset Scope, Optional Traefik Mode

## Assumptions Presented

### Direct Docker Conflict Surface

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| The default Docker path should stay direct host-port, with Compose-level configuration for the project name, public app port, and base URL rather than changes to Lockspire protocol/runtime APIs. | Confident | `.planning/phases/112-default-docker-compose-app-db/112-CONTEXT.md`; `.planning/STATE.md`; `examples/adoption_demo/docker-compose.yml`; `examples/adoption_demo/config/config.exs` |

### Base URL Propagation

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Any configured public port or hostname must be reflected by `LOCKSPIRE_DEMO_BASE_URL`, and docs/startup/smoke examples should instruct users to set that single value instead of deriving URLs from `PORT`. | Confident | `.planning/phases/111-demo-url-contract-config-unification/111-CONTEXT.md`; `examples/adoption_demo/config/config.exs`; `examples/adoption_demo/bin/docker-start`; `scripts/demo/adoption_smoke.py` |

### Database Exposure And Reset Scope

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| PostgreSQL should remain internal-only by default, and any reset path must target the active Compose project's `db_data`, `deps_volume`, and `build_volume` only, not global Docker volumes or hard-coded default-project volumes. | Confident | `.planning/REQUIREMENTS.md`; `examples/adoption_demo/docker-compose.yml` |

### Optional Traefik Mode

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Traefik should be an opt-in Compose mode that attaches the demo web service to the existing `local-dev-proxy` external network and uses configurable hostname/router/service label values; the default Compose command must not depend on that network existing. | Likely | `.planning/STATE.md`; `.planning/phases/112-default-docker-compose-app-db/112-CONTEXT.md`; `.planning/REQUIREMENTS.md`; `tools/traefik/docker-compose.yml`; Docker Compose docs; Traefik v2.10 Docker provider docs |

## Corrections Made

No corrections - all assumptions confirmed.

## External Research

- Docker Compose profiles: services without profiles remain enabled by default; optional profile services can be enabled with `--profile` or `COMPOSE_PROFILES`. Source: https://docs.docker.com/compose/how-tos/profiles/
- Docker Compose external networks: external networks must already exist before `docker compose up`, which supports documenting or narrowly automating `local-dev-proxy` creation for Traefik mode. Source: https://docs.docker.com/compose/how-tos/networking/
- Docker Compose interpolation: Compose values can be interpolated, and label interpolation should use equal-sign syntax for arbitrary label keys. Source: https://docs.docker.com/reference/compose-file/interpolation/
- Traefik v2.10 Docker provider: Docker routing configuration is read from labels; the load-balancer server port label should be specified when the provider cannot infer the intended port. Source: https://doc.traefik.io/traefik/v2.10/providers/docker/
