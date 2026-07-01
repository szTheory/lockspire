---
phase: 115
slug: repo-hygiene-gate-scoped-cleanup
status: complete
created: 2026-06-24
---

# Phase 115: Repo Hygiene Gate & Scoped Cleanup - Research

## User Constraints (from CONTEXT.md)

- Split shell architecture: repo hygiene in `scripts/maintainer/repo_hygiene_check.sh`, demo lifecycle cleanup in `examples/adoption_demo/bin/`. [VERIFIED: .planning/phases/115-repo-hygiene-gate-scoped-cleanup/115-CONTEXT.md]
- No Mix task, Makefile, production runtime module, protocol/admin UI behavior, production Docker packaging, or public support expansion. [VERIFIED: .planning/phases/115-repo-hygiene-gate-scoped-cleanup/115-CONTEXT.md]
- Stop preserves volumes; reset deletes only active project `db_data`, `deps_volume`, and `build_volume`; cleanup defaults dry-run and requires explicit execute. [VERIFIED: .planning/phases/115-repo-hygiene-gate-scoped-cleanup/115-CONTEXT.md]
- No `docker system prune`, `docker volume prune`, broad `docker compose down -v`, or host-wide cleanup. [VERIFIED: .planning/phases/115-repo-hygiene-gate-scoped-cleanup/115-CONTEXT.md]
- Docker labels may support reporting/discovery only; destructive deletion must use explicit allowlists. [VERIFIED: .planning/phases/115-repo-hygiene-gate-scoped-cleanup/115-CONTEXT.md]
- Local Docker unavailable is `WARN`; running active-project demo containers are `BLOCK`; `--ci` never inspects Docker. [VERIFIED: .planning/phases/115-repo-hygiene-gate-scoped-cleanup/115-CONTEXT.md]
- Preserve `tmp/admin-ui-polish/` by default. [VERIFIED: .planning/phases/115-repo-hygiene-gate-scoped-cleanup/115-CONTEXT.md]
- Output must be calm, exact, action-oriented, and redacted. [VERIFIED: .planning/phases/115-repo-hygiene-gate-scoped-cleanup/115-CONTEXT.md]

## Project Constraints (from AGENTS.md)

- Lockspire is an embedded OAuth/OIDC authorization server library for Phoenix and Elixir; this phase must preserve the embedded-library shape. [VERIFIED: AGENTS.md]
- Host-owned seams include account resolution, claims, login redirects, branding, and product policy; this phase must not move those into Lockspire. [VERIFIED: AGENTS.md]
- Strong internal boundaries remain required between protocol core, storage, generators, Plug/Phoenix integration, and LiveView/admin surfaces. [VERIFIED: AGENTS.md]
- Security defaults to preserve include PKCE S256 by default, exact redirect validation, hashed client secrets, single-use short-lived codes, refresh rotation, no implicit flow, no `alg=none`, and redacted logs/operator surfaces. [VERIFIED: AGENTS.md]

## Research Summary

Phase 115 should be implemented as a repo-local shell and contract-test phase, not as Elixir runtime functionality. The current repo already has the right seams: `repo_hygiene_check.sh` has `--ci`, local-only checks, `record_result`, and PASS/WARN/BLOCK accounting; `docker-reset` already resolves the active project and removes only `${project}_db_data`, `${project}_deps_volume`, and `${project}_build_volume`; adoption-demo contract tests already inspect Compose config and shell source. [VERIFIED: scripts/maintainer/repo_hygiene_check.sh] [VERIFIED: examples/adoption_demo/bin/docker-reset] [VERIFIED: test/lockspire/adoption_demo_docker_contract_test.exs]

The recommended implementation is three small lanes: add or document a stop helper that runs project-scoped `docker compose down` without `--volumes`; keep reset as the active-project rebuild lane; add a dry-run-first cleanup helper for stopped demo containers, allowlisted active-project volumes, and allowlisted generated artifacts. Local hygiene should report Docker state when the daemon is reachable, warn when it is not, and block only running active-project containers or deterministic repo contract drift. [VERIFIED: .planning/phases/115-repo-hygiene-gate-scoped-cleanup/115-CONTEXT.md]

CI should remain daemon-free for hygiene and should prove source contracts: no broad prune/delete commands, cleanup dry-run default, explicit allowlists, docs/script command agreement, redaction, and existing adoption smoke preservation. The existing CI still runs the Python black-box adoption smoke against host Postgres and should not be replaced by full Docker smoke in this phase. [VERIFIED: .github/workflows/ci.yml] [VERIFIED: .planning/REQUIREMENTS.md]

**Primary recommendation:** add `examples/adoption_demo/bin/docker-stop` and `examples/adoption_demo/bin/docker-cleanup`, extend `scripts/maintainer/repo_hygiene_check.sh` with local-only demo Docker/artifact checks plus CI source contracts, then update docs/tests so start -> smoke -> stop -> cleanup -> hygiene is enforceable without host-wide deletion. [VERIFIED: .planning/phases/115-repo-hygiene-gate-scoped-cleanup/115-CONTEXT.md]

## Recommended Architecture

| Capability | Owner | Implementation Guidance | Provenance |
|---|---|---|---|
| Stop demo | `examples/adoption_demo/bin/` | Use the same project resolution as reset and call `docker compose --project-name "$project" -f examples/adoption_demo/docker-compose.yml down` with no `--volumes`. | [VERIFIED: examples/adoption_demo/bin/docker-reset] [CITED: https://docs.docker.com/reference/cli/docker/compose/down/] |
| Reset active project | `examples/adoption_demo/bin/docker-reset` | Preserve current semantics: stop project containers, then remove exactly `${project}_db_data`, `${project}_deps_volume`, `${project}_build_volume`. | [VERIFIED: examples/adoption_demo/bin/docker-reset] |
| Cleanup dry run | new `examples/adoption_demo/bin/docker-cleanup` | Default to reporting exact resources; require `--execute` for deletion; accept `--project NAME`; delete only allowlisted generated files and active-project resource names. | [VERIFIED: .planning/phases/115-repo-hygiene-gate-scoped-cleanup/115-CONTEXT.md] |
| Local hygiene | `scripts/maintainer/repo_hygiene_check.sh` | Add demo Docker and artifact checks under `local_checks` or an adjacent local-only helper so `--ci` never queries Docker. | [VERIFIED: scripts/maintainer/repo_hygiene_check.sh] [VERIFIED: .planning/phases/115-repo-hygiene-gate-scoped-cleanup/115-CONTEXT.md] |
| CI hygiene | `repo_owned_checks` plus ExUnit contracts | Keep deterministic checks only: script syntax, docs alignment, static allowlists, no forbidden Docker commands, no broadened support claims. | [VERIFIED: scripts/maintainer/repo_hygiene_check.sh] [VERIFIED: .github/workflows/ci.yml] |
| Smoke proof | existing smoke scripts | Preserve `scripts/demo/adoption_smoke.py` as the only OAuth/OIDC black-box proof and `scripts/demo/adoption_smoke.sh` as the maintainer wrapper. | [VERIFIED: scripts/demo/adoption_smoke.py] [VERIFIED: scripts/demo/adoption_smoke.sh] |

Recommended local lifecycle:

```sh
docker compose -f examples/adoption_demo/docker-compose.yml up --build
LOCKSPIRE_DEMO_BASE_URL=http://127.0.0.1:4100 scripts/demo/adoption_smoke.sh
examples/adoption_demo/bin/docker-stop
examples/adoption_demo/bin/docker-cleanup --execute
./scripts/maintainer/repo_hygiene_check.sh --skip-mix-ci
```

All commands should accept or respect the active Compose project name via `--project`, `COMPOSE_PROJECT_NAME`, and the Compose file default `name: lockspire-adoption-demo`. Docker Compose documents project-name precedence as `-p`, `COMPOSE_PROJECT_NAME`, top-level `name:`, project directory basename, then current directory basename. [CITED: https://docs.docker.com/compose/how-tos/project-name/] [CITED: https://docs.docker.com/compose/how-tos/environment-variables/envvars/]

## Alternatives Considered

| Alternative | Rejected Because | Provenance |
|---|---|---|
| Add a Mix task such as `mix lockspire.demo.cleanup` | Mix tasks are public command modules under `Mix.Tasks.*` and can be documented/listed through Mix; this phase is repo-local maintainer DX, not public Lockspire API. | [CITED: https://mix.hexdocs.pm/Mix.Task.html] [VERIFIED: .planning/phases/115-repo-hygiene-gate-scoped-cleanup/115-CONTEXT.md] |
| Add a Makefile facade | Context explicitly rejects a Makefile and current repo patterns use direct shell helpers for demo lifecycle. | [VERIFIED: .planning/phases/115-repo-hygiene-gate-scoped-cleanup/115-CONTEXT.md] |
| Use labels as the destructive cleanup selector | Compose labels are good metadata, but the locked decision requires exact allowlists for destructive deletion. | [CITED: https://docs.docker.com/reference/compose-file/services/] [CITED: https://docs.docker.com/reference/compose-file/volumes/] [VERIFIED: .planning/phases/115-repo-hygiene-gate-scoped-cleanup/115-CONTEXT.md] |
| Use `docker compose down --volumes` for reset/cleanup | `--volumes` removes named volumes declared in the Compose file and anonymous volumes attached to containers; the phase requires explicit active-project volume deletion only. | [CITED: https://docs.docker.com/reference/cli/docker/compose/down/] [VERIFIED: .planning/phases/115-repo-hygiene-gate-scoped-cleanup/115-CONTEXT.md] |
| Use `docker system prune` or `docker volume prune` | Docker documents these as host-wide unused-resource cleanup commands; the phase requires scoped repo/demo cleanup. | [CITED: https://docs.docker.com/reference/cli/docker/system/prune/] [CITED: https://docs.docker.com/reference/cli/docker/volume/prune/] |
| Add full Docker smoke to CI | Requirement `SMOKE-03` says CI keeps existing smoke proof and adds only deterministic Docker validation unless later proof makes full Docker smoke stable enough. | [VERIFIED: .planning/REQUIREMENTS.md] |

## Implementation Targets

| File | Likely Change | Why |
|---|---|---|
| `scripts/maintainer/repo_hygiene_check.sh` | Add demo Docker/resource/artifact checks, CI source-contract checks, and calm remediation strings. | Existing hygiene gate owns PASS/WARN/BLOCK and CI/local split. [VERIFIED: scripts/maintainer/repo_hygiene_check.sh] |
| `examples/adoption_demo/bin/docker-reset` | Keep or lightly refactor shared project parsing; do not broaden reset into cleanup. | Existing reset already satisfies active-project volume allowlist shape. [VERIFIED: examples/adoption_demo/bin/docker-reset] |
| `examples/adoption_demo/bin/docker-stop` | New helper if planner chooses an explicit stop command. | `CLEAN-01` needs a stop command that preserves volumes. [VERIFIED: .planning/REQUIREMENTS.md] |
| `examples/adoption_demo/bin/docker-cleanup` | New dry-run-first helper with `--execute`, `--project`, allowlisted Docker resources, and allowlisted generated artifacts. | `CLEAN-03`, `HYGIENE-03`, and context require scoped cleanup. [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: .planning/phases/115-repo-hygiene-gate-scoped-cleanup/115-CONTEXT.md] |
| `docs/adoption-demo.md` | Replace Phase 115 placeholder with final stop/reset/cleanup/hygiene commands and preservation/deletion semantics. | Phase 114 deliberately left cleanup implementation docs to Phase 115. [VERIFIED: docs/adoption-demo.md] |
| `test/lockspire/adoption_demo_docker_contract_test.exs` | Add contracts for stop/cleanup scripts, allowlists, forbidden Docker commands, docs command agreement, and redaction. | This file already owns adoption-demo Docker/source/docs contracts. [VERIFIED: test/lockspire/adoption_demo_docker_contract_test.exs] |
| `test/lockspire/release_readiness_contract_test.exs` | Add/adjust release hygiene contracts for `--ci` Docker independence and repo-local boundary claims. | This file already references the hygiene script and CI workflow. [VERIFIED: test/lockspire/release_readiness_contract_test.exs] |
| `.github/workflows/ci.yml` | At most add deterministic script/contract checks; do not add Docker daemon inspection to hygiene. | CI already runs `repo_hygiene_check.sh --ci` and adoption smoke with host Postgres. [VERIFIED: .github/workflows/ci.yml] |

Allowlisted generated artifacts should start narrowly: `tmp/adoption_demo.log`, `examples/adoption_demo/_build`, and `examples/adoption_demo/deps`; `tmp/admin-ui-polish/` must be reported as preserved or ignored by default, not removed. [VERIFIED: .planning/phases/115-repo-hygiene-gate-scoped-cleanup/115-CONTEXT.md] [VERIFIED: .github/workflows/ci.yml]

## Validation Architecture

Nyquist validation is enabled in `.planning/config.json`, so plans should include test-first contract additions before implementation. [VERIFIED: .planning/config.json]

| Requirement | Validation |
|---|---|
| `CLEAN-01` | ExUnit source contract proves stop helper exists or docs command is exact, uses project resolution, and omits `--volumes`/`-v`. [VERIFIED: .planning/REQUIREMENTS.md] |
| `CLEAN-02` | Existing reset contract should remain green and should continue proving only `db_data`, `deps_volume`, and `build_volume` suffixes are removed. [VERIFIED: test/lockspire/adoption_demo_docker_contract_test.exs] |
| `CLEAN-03` | New source/output tests prove cleanup dry-run default, `--execute` requirement, allowlisted resource names, and no broad prune/delete commands. [VERIFIED: .planning/phases/115-repo-hygiene-gate-scoped-cleanup/115-CONTEXT.md] |
| `HYGIENE-01` | Unit/source tests prove local hygiene reports demo Docker leftovers and artifacts using PASS/WARN/BLOCK labels and remediation commands. [VERIFIED: scripts/maintainer/repo_hygiene_check.sh] |
| `HYGIENE-02` | Contract test or shell stub proves `repo_hygiene_check.sh --ci` source path does not call `docker`, `docker compose`, `docker volume`, or daemon checks. [VERIFIED: .planning/REQUIREMENTS.md] |
| `HYGIENE-03` | Contract test proves `tmp/admin-ui-polish/` is not in cleanup deletion allowlists and is described as preserved. [VERIFIED: .planning/phases/115-repo-hygiene-gate-scoped-cleanup/115-CONTEXT.md] |
| `HYGIENE-04` | Local manual validation should run start -> smoke -> stop -> cleanup -> hygiene; CI should verify the deterministic pieces only. [VERIFIED: .planning/REQUIREMENTS.md] |
| `SMOKE-03` | CI continues existing Python adoption smoke and adds deterministic Docker validation only. [VERIFIED: .github/workflows/ci.yml] |
| `BOUNDARY-01..02` | Release/adoption contract tests assert no new `lib/mix/tasks`, no protocol/admin UI behavior changes, no production Docker packaging claims, and docs keep demo as repo-local proof. [VERIFIED: AGENTS.md] [VERIFIED: .planning/REQUIREMENTS.md] |

Recommended commands:

```sh
sh -n examples/adoption_demo/bin/docker-stop
sh -n examples/adoption_demo/bin/docker-cleanup
bash -n scripts/maintainer/repo_hygiene_check.sh
python3 -m py_compile scripts/demo/adoption_smoke.py
mix test test/lockspire/adoption_demo_docker_contract_test.exs --seed 0
mix test test/lockspire/release_readiness_contract_test.exs --seed 0
bash ./scripts/maintainer/repo_hygiene_check.sh --ci
```

Local Docker proof is useful but should be non-blocking for CI: Docker CLI and daemon are currently available locally as Docker `29.5.2`, but local availability must not become a CI hygiene requirement. [VERIFIED: docker --version] [VERIFIED: docker info] [VERIFIED: .planning/phases/115-repo-hygiene-gate-scoped-cleanup/115-CONTEXT.md]

## Threats And Footguns

- Broad cleanup commands can delete unrelated developer state; `docker system prune` removes unused host containers/networks/images/build cache and optionally volumes, while `docker volume prune --all` can remove unused named volumes. [CITED: https://docs.docker.com/reference/cli/docker/system/prune/] [CITED: https://docs.docker.com/reference/cli/docker/volume/prune/]
- `docker compose down --volumes` is too broad for stop because it removes named volumes declared in the Compose file. [CITED: https://docs.docker.com/reference/cli/docker/compose/down/]
- Project mismatch is the main safety risk: cleanup/reset must operate on the same project name as startup, respecting `--project`, `COMPOSE_PROJECT_NAME`, and default `name: lockspire-adoption-demo`. [CITED: https://docs.docker.com/compose/how-tos/project-name/] [VERIFIED: examples/adoption_demo/docker-compose.yml]
- Docker labels can overmatch or drift; use labels only to report discovered resources, then delete only explicit active-project names. [CITED: https://docs.docker.com/reference/compose-file/services/] [CITED: https://docs.docker.com/reference/compose-file/volumes/] [VERIFIED: .planning/phases/115-repo-hygiene-gate-scoped-cleanup/115-CONTEXT.md]
- CI flakiness will increase if `--ci` inspects a daemon or depends on host-local Docker state; CI should verify checked-in contracts instead. [VERIFIED: .planning/phases/115-repo-hygiene-gate-scoped-cleanup/115-CONTEXT.md] [VERIFIED: .github/workflows/ci.yml]
- Cleanup output must not print secrets, tokens, private keys, authorization codes, refresh tokens, cookies, or unredacted sensitive values; prior `docker-info` tests already enforce this style for demo output. [VERIFIED: AGENTS.md] [VERIFIED: test/lockspire/adoption_demo_docker_contract_test.exs]
- Deleting `tmp/admin-ui-polish/` would erase next-pass admin UI evidence; preserve it by default and exclude it from cleanup allowlists. [VERIFIED: .planning/phases/115-repo-hygiene-gate-scoped-cleanup/115-CONTEXT.md]
- Adding Mix tasks or public docs that frame cleanup as supported Lockspire product behavior would broaden the package surface. Hex package docs show package configuration is public package metadata and Mix tasks are normal project commands, so repo-local shell scripts are the safer boundary. [CITED: https://hex.pm/docs/publish] [CITED: https://mix.hexdocs.pm/Mix.Task.html]

## Sources

Primary repo sources:

- `AGENTS.md` - embedded-library boundary, stack, security defaults. [VERIFIED: AGENTS.md]
- `.planning/REQUIREMENTS.md` - `SMOKE-03`, `CLEAN-01..03`, `HYGIENE-01..04`, `BOUNDARY-01..02`. [VERIFIED: .planning/REQUIREMENTS.md]
- `.planning/ROADMAP.md` and `.planning/STATE.md` - Phase 115 milestone boundary and prior v1.30 decisions. [VERIFIED: .planning/ROADMAP.md] [VERIFIED: .planning/STATE.md]
- `.planning/phases/115-repo-hygiene-gate-scoped-cleanup/115-CONTEXT.md` - locked cleanup/hygiene decisions. [VERIFIED: .planning/phases/115-repo-hygiene-gate-scoped-cleanup/115-CONTEXT.md]
- Phase 111-114 context/summaries/patterns - URL truth, Docker topology, conflict controls, startup output, smoke wrapper, docs boundary. [VERIFIED: .planning/phases/111-demo-url-contract-config-unification/111-CONTEXT.md] [VERIFIED: .planning/phases/112-default-docker-compose-app-db/112-CONTEXT.md] [VERIFIED: .planning/phases/113-conflict-controls-optional-traefik/113-CONTEXT.md] [VERIFIED: .planning/phases/114-startup-output-smoke-wrapper-docs/114-PATTERNS.md]
- Current scripts, docs, tests, and CI files named in the phase prompt. [VERIFIED: codebase grep/read]

Official external sources:

- Docker Compose project names: https://docs.docker.com/compose/how-tos/project-name/
- Docker Compose environment variables and project-name precedence: https://docs.docker.com/compose/how-tos/environment-variables/envvars/
- Docker Compose `down`: https://docs.docker.com/reference/cli/docker/compose/down/
- Docker Compose service labels: https://docs.docker.com/reference/compose-file/services/
- Docker Compose volume labels/names: https://docs.docker.com/reference/compose-file/volumes/
- Docker volume prune: https://docs.docker.com/reference/cli/docker/volume/prune/
- Docker system prune: https://docs.docker.com/reference/cli/docker/system/prune/
- Mix tasks: https://mix.hexdocs.pm/Mix.Task.html
- Hex package publishing/files: https://hex.pm/docs/publish
- Phoenix testing docs: https://phoenix.hexdocs.pm/testing.html
- Phoenix CI article: https://www.phoenixframework.org/blog/improving-testing-and-continuous-integration-in-phoenix

Research confidence: HIGH for repo-local implementation targets because they are directly verified against checked-in files; MEDIUM for Docker and Mix/Phoenix semantics because they are cited from official documentation through web lookup on 2026-06-24. [VERIFIED: codebase grep/read] [CITED: https://docs.docker.com/compose/how-tos/project-name/] [CITED: https://mix.hexdocs.pm/Mix.Task.html]
