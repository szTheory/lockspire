# Phase 115: Repo Hygiene Gate & Scoped Cleanup - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md — this log preserves the analysis.

**Date:** 2026-06-24T17:20:36Z
**Phase:** 115-repo-hygiene-gate-scoped-cleanup
**Mode:** assumptions with research expansion
**Areas analyzed:** cleanup command scope, hygiene gate placement, generated artifact allowlist, verification boundary, Elixir/Phoenix idioms, Docker/SRE safety, cross-ecosystem DX lessons, Lockspire prompts/brand synthesis

## Assumptions Presented

### Cleanup Command Scope

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Phase 115 should add a cleanup lane that is demo-owned, non-destructive by default, and scoped to the active adoption demo Compose project plus explicit allowlisted repo artifacts; it should not broaden `docker-reset` into host-wide Docker cleanup. | Confident | `.planning/ROADMAP.md`, `.planning/phases/113-conflict-controls-optional-traefik/113-CONTEXT.md`, `examples/adoption_demo/bin/docker-reset`, `docs/adoption-demo.md` |

### Hygiene Gate Placement

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Demo Docker leftover and generated-artifact checks should extend `scripts/maintainer/repo_hygiene_check.sh`, with Docker/local filesystem checks running only in local mode and `--ci` remaining deterministic and Docker-daemon independent. | Confident | `scripts/maintainer/repo_hygiene_check.sh`, `.github/workflows/ci.yml`, `.planning/ROADMAP.md` |

### Artifact Allowlist

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Generated artifact cleanup and hygiene should use an explicit allowlist, preserving `tmp/admin-ui-polish/` by default while allowing demo-owned artifacts such as `tmp/adoption_demo.log` and adoption-demo build/dependency directories to be reported or removed when explicitly in scope. | Confident | `.planning/ROADMAP.md`, `.gitignore`, `.github/workflows/ci.yml`, current workspace artifact patterns |

### Verification Boundary

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Phase 115 verification should be contract-focused around scripts/docs/CI behavior, not full Docker runtime proof in CI or OAuth/OIDC/admin UI behavior changes. | Confident | `test/lockspire/adoption_demo_docker_contract_test.exs`, `test/lockspire/release_readiness_contract_test.exs`, `.planning/ROADMAP.md` |

## Corrections Made

### Research Expansion

- **Original assumption bundle:** Four confident assumptions were presented without external research because the first codebase analyzer found no research gaps.
- **User correction:** Discuss and consider all assumptions using subagents, including pros/cons/tradeoffs, Elixir/Phoenix ecosystem idioms, other library/framework lessons, DevOps/SRE cleanup safety, Lockspire prompts/brand guidance, JTBD/DX/UX, and one coherent recommendation set.
- **Resulting decision change:** The final context keeps the original direction but makes it more explicit:
  - split shell architecture instead of Mix tasks or Makefile;
  - deletion by explicit allowlist, with Docker labels used only for reporting/discovery;
  - cleanup defaults to dry-run and requires explicit execution;
  - local Docker daemon unavailable is `WARN`, not `BLOCK`;
  - running active-project demo containers are `BLOCK`;
  - `--ci` never inspects Docker;
  - `tmp/admin-ui-polish/` is preserved by default;
  - output must be calm, exact, action-oriented, and redacted.

## Alternatives Considered

### Command Architecture

| Option | Pros | Cons | Outcome |
|--------|------|------|---------|
| Repo-root Bash hygiene gate plus example-local shell cleanup wrappers | Least surprise for OSS maintainers, no compile/app boot needed, matches existing scripts, CI split is straightforward. | Shell parsing needs careful tests and allowlists. | Selected. |
| Mix tasks or aliases | Discoverable through Mix and idiomatic for shipped Elixir commands. | Bad fit for Docker/local cleanup because it may compile/load package code and risks public API confusion. | Rejected for this phase. |
| Makefile facade | Short familiar commands for some contributors. | Adds another command index and is not established in this repo. | Rejected. |
| Docker Compose wrappers as the only interface | Strong fit for runtime resources. | Cannot cover repo-wide hygiene or CI deterministic checks. | Use only for demo lifecycle helpers. |

### Docker Cleanup Mechanics

| Option | Pros | Cons | Outcome |
|--------|------|------|---------|
| Explicit allowlisted resource names | Transparent, testable, tight blast radius. | Requires updates when Compose resources change. | Selected for destructive deletion. |
| Compose label discovery | Robust for reporting containers/networks/volumes by project. | Can overmatch same-project collisions and is less transparent for deletion. | Selected for reporting/discovery only. |
| `docker compose down -v` | Simple official command. | Deletes all named volumes in merged Compose config and may broaden silently later. | Rejected for reset/cleanup. |
| `docker system prune` / `docker volume prune` | Removes broad local clutter. | Host-wide, destructive, unrelated to Lockspire ownership. | Rejected. |

### CI And Verification

| Option | Pros | Cons | Outcome |
|--------|------|------|---------|
| Docker-free CI hygiene | Stable, deterministic, checks repo truth only. | Does not catch local abandoned Docker resources. | Selected. |
| Full Docker smoke in CI | Stronger runtime proof. | Potential flake and outside Phase 115 unless later proven stable. | Deferred. |
| Contract tests for scripts/docs/allowlists | Fast, precise, stable. | Cannot prove every local Docker runtime edge. | Selected as primary proof. |

## External Research

- Docker Compose project names: project names isolate environments and can be set by `-p`, `COMPOSE_PROJECT_NAME`, or top-level `name`.
- Docker Compose `down`: removes project containers/networks by default; named volumes require explicit `-v`.
- Docker pruning: broad prune commands intentionally affect unused Docker resources and are too wide for Lockspire-owned cleanup.
- Docker Compose labels and volume filters: useful for local reporting/discovery, but deletion should remain explicit.
- Mix task and alias docs: Mix tasks are discoverable and public when placed under `lib/mix/tasks`, which makes them a poor fit for repo-local cleanup commands.
- Hex package docs: package file lists and public package shape should remain explicit; maintainer cleanup should not change shipped surface.
- Phoenix, Rails, Django, Doorkeeper, node-oidc-provider, and OpenIddict precedents support reproducible tests/docs, tight package/sample boundaries, and low-friction local DX rather than broad cleanup or product-surface expansion.

## Auto-Resolved

Not applicable.
