# Phase 112: Default Docker Compose App + DB - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md - this log preserves the analysis.

**Date:** 2026-06-04
**Phase:** 112-default-docker-compose-app-db
**Mode:** assumptions
**Areas analyzed:** Compose Topology, PostgreSQL Service, Build Artifact Isolation, Startup Command, Phase Boundary

## Assumptions Presented

### Compose Topology

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Use `examples/adoption_demo/docker-compose.yml` as the default repo-local demo Compose file, but convert it from Traefik-only web service to a direct app-plus-Postgres default. | Confident | `.planning/ROADMAP.md`; `examples/adoption_demo/docker-compose.yml`; `docs/adoption-demo.md` |

### PostgreSQL Service

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Add a Postgres 14+ service in the same Compose file with internal-only networking by default, explicit `POSTGRES_*` plus `LOCKSPIRE_DEMO_DB_*` wiring, a healthcheck, and a project-scoped named data volume. | Confident | `.planning/REQUIREMENTS.md`; `.github/workflows/ci.yml`; `examples/adoption_demo/config/config.exs` |

### Build Artifact Isolation

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Preserve container-local `deps` and `_build` named volumes for Phoenix, and keep source bind-mounted for live repo-local iteration. | Confident | `examples/adoption_demo/docker-compose.yml`; `.planning/REQUIREMENTS.md`; `.github/workflows/ci.yml` |

### Startup Command

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Replace `Dockerfile.dev`'s bare `mix deps.get && mix phx.server` with a small demo-owned startup script that waits for Postgres, runs an idempotent create/migrate/seed sequence, waits for the public demo URL to return HTTP 200, then prints a minimal ready line for Phase 112. | Likely | `.planning/REQUIREMENTS.md`; `examples/adoption_demo/Dockerfile.dev`; `examples/adoption_demo/mix.exs`; `examples/adoption_demo/priv/repo/seeds.exs` |

### Phase Boundary

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Keep Phase 112's output intentionally minimal: no optional Traefik labels as the default path, no configurable project-name/port matrix beyond what the current env contract needs, no full URL/accounts/client startup banner, no cleanup lane, and no CI full Docker smoke. | Confident | `.planning/ROADMAP.md`; `.planning/REQUIREMENTS.md`; `.planning/phases/111-demo-url-contract-config-unification/111-CONTEXT.md` |

## Corrections Made

No corrections - all assumptions confirmed.
