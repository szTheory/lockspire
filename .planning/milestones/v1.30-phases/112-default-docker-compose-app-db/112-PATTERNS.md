# Phase 112: Default Docker Compose App + DB - Patterns

## PATTERN MAPPING COMPLETE

| Planned File | Role | Closest Analog | Pattern To Reuse |
|--------------|------|----------------|------------------|
| `examples/adoption_demo/docker-compose.yml` | Demo-local Compose topology | Existing `examples/adoption_demo/docker-compose.yml`; `tools/traefik/docker-compose.yml` | Keep repo-local Docker concerns out of library runtime; use named volumes and explicit networks/env. |
| `examples/adoption_demo/Dockerfile.dev` | Developer image | Existing `examples/adoption_demo/Dockerfile.dev` | Install build tools, Hex, and Rebar once; keep source bind-mounted for iteration. |
| `examples/adoption_demo/bin/docker-start` | Demo startup wrapper | `scripts/conformance/run_fapi2_suite.sh`; `.github/workflows/ci.yml` adoption-demo job | Shell scripts use `set -euo pipefail`, explicit env, wait loops, clear stderr on timeout. |
| `docs/adoption-demo.md` | Narrow command documentation | Existing `docs/adoption-demo.md` | State demo boundary first, then give concrete commands. Keep full docs expansion for Phase 114. |

## Existing Patterns

### Shell Wait Loops

`.github/workflows/ci.yml` waits for Postgres with a bounded `pg_isready` loop. The startup wrapper should use the same shape for Docker-local Postgres readiness.

### Base URL Readiness

`scripts/demo/adoption_smoke.py` treats `LOCKSPIRE_DEMO_BASE_URL` as the public URL truth and waits for `/` to return HTTP 200. The startup wrapper should use the same env var for readiness, with a simpler `curl` loop.

### Demo State

`examples/adoption_demo/priv/repo/seeds.exs` is intentionally repeatable for demo proof state by truncating Lockspire-owned tables before reseeding. Startup should reuse it rather than adding a second seed source.

### Boundary Discipline

Prior adoption-demo plans avoid turning demo proof into a public support claim. Phase 112 plans should keep Docker under `examples/adoption_demo` and docs narrow.
