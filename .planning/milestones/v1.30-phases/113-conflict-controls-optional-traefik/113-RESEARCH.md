# Phase 113: Conflict Controls & Optional Traefik - Research

**Researched:** 2026-06-04
**Domain:** Docker Compose local demo conflict controls, optional Traefik routing, Phoenix adoption demo DX
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

### Direct Docker Conflict Surface

- **D-01:** Keep the default Docker path direct host-port first. Phase 113 should add conflict controls at the Compose/demo-environment layer, not by adding Lockspire runtime or public library APIs.
- **D-02:** Make the Compose project name configurable for the adoption demo so multiple local checkouts or sibling library demos do not collide on container, network, or named-volume resources.
- **D-03:** Make the public app port configurable in Compose, with the Phoenix container `PORT` and the host port mapping staying aligned.

### Base URL Propagation

- **D-04:** Treat `LOCKSPIRE_DEMO_BASE_URL` as the single browser-visible URL truth for any configured public port or hostname. Documentation, startup output, and smoke commands should instruct maintainers to set this value rather than deriving browser URLs from `PORT`.
- **D-05:** Preserve the Phase 111 split: `LOCKSPIRE_DEMO_BASE_URL` drives endpoint URL generation, Lockspire issuer, seeded local URLs, and smoke proof; `LOCKSPIRE_DEMO_BIND_IP` controls only listener binding.
- **D-06:** Keep `scripts/demo/adoption_smoke.py` on its existing contract: it should continue to consume `LOCKSPIRE_DEMO_BASE_URL` as the external URL input. Any new examples or wrappers should pass the configured base URL through that variable.

### Database Exposure And Reset Scope

- **D-07:** Keep PostgreSQL internal-only by default. Do not publish host port `5432` on the default Docker path.
- **D-08:** If host PostgreSQL access is added, make it opt-in and configurable through demo-owned Compose environment, not a default port binding.
- **D-09:** Add a cache reset path that targets only the active adoption-demo Compose project's `db_data`, `deps_volume`, and `build_volume` resources. It must not delete global Docker volumes or hard-code the default project name.

### Optional Traefik Mode

- **D-10:** Keep Traefik opt-in. The default `docker compose up` path must not depend on an external Traefik network existing.
- **D-11:** Use Docker Compose profiles and/or an explicit override file for Traefik mode so the direct Docker services remain always enabled and the Traefik-only additions activate only when requested.
- **D-12:** When Traefik mode is enabled, attach only the web service to the shared external proxy network while keeping the database on the project-internal network.
- **D-13:** Make Traefik hostname, router name, service name, and proxy network configurable so multiple demos can coexist without label collisions.
- **D-14:** Specify the Traefik service load-balancer port explicitly for the Phoenix container when labels are added, so routing does not depend on ambiguous port detection.

### Verification Boundary

- **D-15:** Add deterministic proof for Compose interpolation/profile/port/reset behavior where practical. Optional Traefik smoke should be possible locally, but full Docker smoke in CI remains deferred unless Phase 114 or 115 proves it stable enough.

### the agent's Discretion

- The exact env var names for Compose project, app port, optional database host port, Traefik hostname, router, service, and network are at the agent's discretion, provided they are demo-scoped, documented, and unsurprising.
- The exact reset command shape is at the agent's discretion, provided it is scoped to the active Compose project and the three demo-owned cache/data volumes.
- The exact Traefik implementation shape is at the agent's discretion: a profile in the existing Compose file, a separate override file, or a small demo-owned helper script are all acceptable if default startup remains direct and network-independent.

### Deferred Ideas (OUT OF SCOPE)

- Full startup banner with active URL set, seeded accounts, seeded clients, and exact smoke command - Phase 114.
- Reprint command for current demo information - Phase 114.
- Expanded adoption-demo docs covering default startup, optional Traefik, smoke, stop, reset, cleanup, overrides, and troubleshooting - mostly Phase 114, with Phase 113 limited to conflict-control and Traefik setup truth needed for planning.
- Repo hygiene gate, broad scoped cleanup lane, Docker leftover checks, CI/local hygiene split, and no-BLOCK cleanup proof - Phase 115.
- Full Docker smoke in CI - future requirement if local Docker proof is stable and non-flaky.
- Production Docker release images or deployment packaging - future distribution milestone only.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| CONFLICT-01 | Demo Compose project name configurable. | Use Compose project naming via `COMPOSE_PROJECT_NAME` or `-p`; Docker documents project naming for avoiding interference between shared/local projects. [CITED: https://docs.docker.com/compose/how-tos/project-name/] |
| CONFLICT-02 | Public app port configurable and URLs/smoke use configured base URL. | Current Compose hard-codes `4100:4100`, `PORT=4100`, and `LOCKSPIRE_DEMO_BASE_URL`; app config and smoke already consume `LOCKSPIRE_DEMO_BASE_URL`. [VERIFIED: codebase grep] |
| CONFLICT-03 | Postgres host port absent by default; opt-in/configurable if exposed. | Current adoption demo DB service has no `ports:` binding, so default is already internal-only; preserve that and add any host DB exposure through opt-in Compose override/profile only. [VERIFIED: codebase grep] |
| CONFLICT-04 | Reset only active demo project volumes. | Current named volumes render as project-scoped names such as `adoption_demo_db_data`; Compose volume labels also expose project/volume metadata. [VERIFIED: docker compose config] [CITED: https://docs.docker.com/reference/compose-file/volumes/] |
| TRAEFIK-01 | Optional hostname routing; default Docker path never requires Traefik. | Compose profiles keep unprofiled services enabled by default while profiled services activate only on request. [CITED: https://docs.docker.com/compose/how-tos/profiles/] |
| TRAEFIK-02 | Document/automate external network and configurable labels. | Docker documents external networks for connecting multiple Compose projects; Traefik Docker provider consumes labels for routers/services and supports explicit service port labels. [CITED: https://docs.docker.com/compose/how-tos/networking/] [CITED: https://doc.traefik.io/traefik/v2.0/routing/providers/docker/] |
</phase_requirements>

## Project Constraints (from AGENTS.md)

- Lockspire is an embedded OAuth/OIDC authorization server library for Phoenix/Elixir, not a standalone auth service. [VERIFIED: AGENTS.md]
- Phase 113 must preserve the embedded-library shape and avoid new Lockspire public runtime APIs for demo Docker conflict controls. [VERIFIED: AGENTS.md] [VERIFIED: 113-CONTEXT.md]
- Internal boundaries between protocol core, storage, generators, Plug/Phoenix integration, and LiveView/admin surfaces must remain strong; this phase belongs to repo-local demo tooling/docs. [VERIFIED: AGENTS.md]
- Host seams for account resolution, claims, login redirects, branding, and product policy remain host-owned and should not be broadened. [VERIFIED: AGENTS.md]
- Do not broaden v1 into SAML, LDAP/AD federation, hosted auth, or full CIAM. [VERIFIED: AGENTS.md]
- Preserve security defaults: PKCE S256 required, exact redirect URI validation, hashed client secrets, single-use short-lived auth codes, refresh rotation with family revocation, no implicit flow, no `alg=none`, and strong redaction. [VERIFIED: AGENTS.md]

## Summary

Phase 113 should be planned as a Compose/docs/tooling phase, not an Elixir protocol phase. The current adoption demo already has the right application seam: `LOCKSPIRE_DEMO_BASE_URL` is parsed into Phoenix endpoint URL generation and the Lockspire issuer, while `PORT` controls the listener and `LOCKSPIRE_DEMO_BIND_IP` controls only bind interface. [VERIFIED: codebase grep] The implementation work is therefore to make Compose and docs pass the configured values consistently, without changing Lockspire's protocol behavior. [VERIFIED: 113-CONTEXT.md]

Use Docker Compose's standard project-name and interpolation mechanisms for conflict controls. Compose project names are intended to isolate local/CI/shared-host environments, and precedence supports `-p`, `COMPOSE_PROJECT_NAME`, and top-level `name:`. [CITED: https://docs.docker.com/compose/how-tos/project-name/] Compose interpolation supports `${VAR:-default}` and applies to values, including equal-sign label syntax for labels. [CITED: https://docs.docker.com/reference/compose-file/interpolation/]

Traefik should remain opt-in and local-DX-only. Prefer a separate `docker-compose.traefik.yml` override, or a profile that is proven not to make default startup depend on the external proxy network. [VERIFIED: 113-CONTEXT.md] Because Compose docs state top-level elements are not affected by profiles, an override file is the lower-risk planning target for external Traefik network definitions. [CITED: https://docs.docker.com/reference/compose-file/profiles/] [ASSUMED]

**Primary recommendation:** Add demo-scoped Compose variables, an explicit Traefik override path, and a small reset helper that resolves the active project via Compose before deleting only `db_data`, `deps_volume`, and `build_volume`. [VERIFIED: codebase grep] [CITED: https://docs.docker.com/reference/cli/docker/compose/down/]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|--------------|----------------|-----------|
| Compose project naming | Docker Compose / local tooling | Documentation | Compose owns container/network/volume naming; app code should not know the project name. [CITED: https://docs.docker.com/compose/how-tos/project-name/] |
| Public app port | Docker Compose / local tooling | Phoenix endpoint config | Compose publishes host port and passes `PORT`; Phoenix consumes `PORT` as listener port. [VERIFIED: examples/adoption_demo/docker-compose.yml] [VERIFIED: examples/adoption_demo/config/config.exs] |
| Browser-visible base URL | Phoenix demo config | Docs/smoke script | App config, issuer, seeds, and smoke proof already consume `LOCKSPIRE_DEMO_BASE_URL`. [VERIFIED: examples/adoption_demo/config/config.exs] [VERIFIED: scripts/demo/adoption_smoke.py] |
| PostgreSQL host exposure | Docker Compose / local tooling | Documentation | The DB is a Compose service; default should stay internal and optional host mapping belongs in Compose override/profile. [VERIFIED: examples/adoption_demo/docker-compose.yml] |
| Reset active demo volumes | Local tooling | Docker Compose | Active project names namespace volumes; reset must remove only the active project volume resources. [VERIFIED: docker compose config] |
| Optional Traefik routing | Docker Compose override/profile | External Traefik helper | Traefik consumes Docker labels and shared network membership; Lockspire/Phoenix should only receive the base URL. [CITED: https://doc.traefik.io/traefik/v2.0/routing/providers/docker/] |

## Standard Stack

### Core

| Tool | Version | Purpose | Why Standard |
|------|---------|---------|--------------|
| Docker Compose CLI | local `v5.1.3` | Render/start the adoption demo stack and interpolate demo env vars. | Existing demo already uses Compose; official project-name/interpolation/profile/network primitives cover the phase requirements. [VERIFIED: local command] [CITED: https://docs.docker.com/compose/how-tos/project-name/] |
| Phoenix adoption demo | Phoenix `~> 1.8.5` in `examples/adoption_demo/mix.exs` | Host app that consumes `PORT`, `LOCKSPIRE_DEMO_BASE_URL`, and DB env. | Existing config already separates public URL from bind/listener concerns. [VERIFIED: examples/adoption_demo/mix.exs] [VERIFIED: examples/adoption_demo/config/config.exs] |
| Traefik Docker provider | repo helper uses `traefik:v2.10` | Optional local hostname routing. | Existing repo helper uses Docker provider with `exposedbydefault=false`; Traefik docs support label-driven routers/services. [VERIFIED: tools/traefik/docker-compose.yml] [CITED: https://doc.traefik.io/traefik/v2.0/routing/providers/docker/] |

### Supporting

| Tool | Version | Purpose | When to Use |
|------|---------|---------|-------------|
| `docker compose config` | local `v5.1.3` | Deterministic validation of interpolated Compose model without starting containers. | Use in tests/scripts to assert project name, ports, env, labels, networks, and absence/default of DB host port. [VERIFIED: local command] |
| Python `adoption_smoke.py` | local Python `3.14.4` available | Existing black-box smoke against configured base URL. | Keep for local proof and Phase 114 smoke wrapper; Phase 113 should only ensure examples pass `LOCKSPIRE_DEMO_BASE_URL`. [VERIFIED: scripts/demo/adoption_smoke.py] [VERIFIED: local command] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Compose project env var / `-p` | Hard-code top-level `name:` only | Top-level `name:` is lower precedence and less flexible for parallel checkouts. [CITED: https://docs.docker.com/compose/how-tos/project-name/] |
| Traefik override file | Single file with profiled web labels/network | Profiles can enable optional services, but top-level elements are always active, so an override file is easier to prove default network independence. [CITED: https://docs.docker.com/reference/compose-file/profiles/] [ASSUMED] |
| Scoped reset helper | `docker compose down -v` | `down -v` removes all named volumes declared in the Compose file; a helper can make the intent explicit and can validate the active project first. [CITED: https://docs.docker.com/reference/cli/docker/compose/down/] |

**Installation:** No new external packages should be installed for Phase 113. [VERIFIED: codebase grep]

## Package Legitimacy Audit

No external packages are recommended or installed in this phase. [VERIFIED: codebase grep]

| Package | Registry | Age | Downloads | Source Repo | slopcheck | Disposition |
|---------|----------|-----|-----------|-------------|-----------|-------------|
| None | — | — | — | — | Not run | No package install path |

**Packages removed due to slopcheck [SLOP] verdict:** none
**Packages flagged as suspicious [SUS]:** none

## Architecture Patterns

### System Architecture Diagram

```text
Maintainer shell
  |
  | docker compose -f examples/adoption_demo/docker-compose.yml up
  |   env: COMPOSE_PROJECT_NAME / LOCKSPIRE_DEMO_APP_PORT / LOCKSPIRE_DEMO_BASE_URL
  v
Docker Compose model
  |
  +--> web service
  |      - host port: ${LOCKSPIRE_DEMO_APP_PORT:-4100}
  |      - container PORT: same configured app port
  |      - LOCKSPIRE_DEMO_BASE_URL: browser-visible truth
  |      - internal DB host: db:5432
  |
  +--> db service
  |      - internal default network only
  |      - named db_data volume
  |
  +--> named volumes
         - db_data
         - deps_volume
         - build_volume

Optional Traefik override/profile
  |
  +--> attaches web to ${LOCKSPIRE_DEMO_TRAEFIK_NETWORK:-local-dev-proxy}
  +--> adds labels:
         traefik.enable=true
         traefik.http.routers.${router}.rule=Host(`${hostname}`)
         traefik.http.routers.${router}.service=${service}
         traefik.http.services.${service}.loadbalancer.server.port=${PORT}
```

### Recommended Project Structure

```text
examples/adoption_demo/
├── docker-compose.yml              # direct default Compose path
├── docker-compose.traefik.yml      # optional Traefik override, if chosen
├── bin/
│   ├── docker-start                # app startup/readiness output
│   └── docker-reset                # scoped active-project reset helper, if chosen
docs/
└── adoption-demo.md                # conflict-control and optional Traefik examples
test/
└── lockspire/
    └── adoption_demo_docker_contract_test.exs  # deterministic Compose/docs contract proof
```

### Pattern 1: Compose Env Interpolation

**What:** Use `${VAR:-default}` inside Compose values for host port, container `PORT`, base URL, and optional labels. [CITED: https://docs.docker.com/reference/compose-file/interpolation/]

**When to use:** Use for all demo-scoped knobs that need deterministic `docker compose config` proof. [VERIFIED: docker compose config]

**Example:**

```yaml
# Source: Docker Compose interpolation docs
services:
  web:
    ports:
      - "${LOCKSPIRE_DEMO_APP_PORT:-4100}:${LOCKSPIRE_DEMO_APP_PORT:-4100}"
    environment:
      PORT: "${LOCKSPIRE_DEMO_APP_PORT:-4100}"
      LOCKSPIRE_DEMO_BASE_URL: "${LOCKSPIRE_DEMO_BASE_URL:-http://127.0.0.1:${LOCKSPIRE_DEMO_APP_PORT:-4100}}"
```

### Pattern 2: Traefik Labels Use Equal-Sign Syntax

**What:** Use list/equal-sign labels when label keys need variable interpolation. [CITED: https://docs.docker.com/reference/compose-file/interpolation/]

**When to use:** Use for configurable router and service names. [VERIFIED: 113-CONTEXT.md]

**Example:**

```yaml
# Source: Docker Compose interpolation docs + Traefik Docker provider docs
labels:
  - "traefik.enable=true"
  - "traefik.http.routers.${LOCKSPIRE_DEMO_TRAEFIK_ROUTER:-lockspire-adoption-demo}.rule=Host(`${LOCKSPIRE_DEMO_TRAEFIK_HOST:-lockspire-demo.localhost}`)"
  - "traefik.http.routers.${LOCKSPIRE_DEMO_TRAEFIK_ROUTER:-lockspire-adoption-demo}.service=${LOCKSPIRE_DEMO_TRAEFIK_SERVICE:-lockspire-adoption-demo}"
  - "traefik.http.services.${LOCKSPIRE_DEMO_TRAEFIK_SERVICE:-lockspire-adoption-demo}.loadbalancer.server.port=${LOCKSPIRE_DEMO_APP_PORT:-4100}"
```

### Pattern 3: Scoped Reset by Active Compose Project

**What:** Resolve the active project and remove only the known demo volume resources. [VERIFIED: docker compose config]

**When to use:** Use for `CONFLICT-04`, not for general Docker cleanup. [VERIFIED: 113-CONTEXT.md]

**Example:**

```sh
# Source: Docker Compose down/volumes docs; command shape is planner guidance.
project="${COMPOSE_PROJECT_NAME:-lockspire-adoption-demo}"
docker compose -p "$project" -f examples/adoption_demo/docker-compose.yml down
docker volume rm \
  "${project}_db_data" \
  "${project}_deps_volume" \
  "${project}_build_volume"
```

### Anti-Patterns to Avoid

- **Deriving public URL from `PORT`:** `LOCKSPIRE_DEMO_BASE_URL` is the public URL truth and may be a hostname under Traefik. [VERIFIED: 113-CONTEXT.md]
- **Publishing DB `5432` by default:** Current Compose has no DB `ports:`; adding one by default would regress CONFLICT-03. [VERIFIED: examples/adoption_demo/docker-compose.yml]
- **Putting Traefik labels on the DB:** Only web should join the external proxy network. [VERIFIED: 113-CONTEXT.md]
- **Using map labels for interpolated label keys:** Compose interpolation applies to values, not arbitrary keys; use equal-sign list syntax. [CITED: https://docs.docker.com/reference/compose-file/interpolation/]
- **Using global `docker volume prune`:** Reset must target only active demo volumes. [VERIFIED: 113-CONTEXT.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Compose resource isolation | Custom container/volume naming logic | `COMPOSE_PROJECT_NAME` / `-p` | Compose already namespaces containers, networks, and named volumes by project. [CITED: https://docs.docker.com/compose/how-tos/project-name/] |
| Config rendering proof | Custom YAML parser | `docker compose config --format json` | Compose itself resolves interpolation, merges, profiles, ports, networks, and volumes. [VERIFIED: local command] |
| Local hostname routing | Custom Phoenix proxy/router behavior | Optional Traefik Docker labels | Traefik Docker provider is the existing local proxy helper and consumes labels. [VERIFIED: tools/traefik/docker-compose.yml] [CITED: https://doc.traefik.io/traefik/v2.0/routing/providers/docker/] |
| Volume cleanup discovery | Host-wide prune scripts | Active-project allowlist | Docker `down -v` and volume labels support scoped cleanup; host-wide pruning violates phase boundaries. [CITED: https://docs.docker.com/reference/cli/docker/compose/down/] [CITED: https://docs.docker.com/reference/compose-file/volumes/] |

**Key insight:** This phase is about using Compose's existing local-environment primitives correctly; custom Docker state discovery increases blast radius and makes reset harder to verify. [VERIFIED: 113-CONTEXT.md]

## Common Pitfalls

### Pitfall 1: Base URL / Port Drift

**What goes wrong:** Host port, container `PORT`, and `LOCKSPIRE_DEMO_BASE_URL` can disagree. [VERIFIED: examples/adoption_demo/docker-compose.yml]

**Why it happens:** Current Compose hard-codes all three values separately. [VERIFIED: examples/adoption_demo/docker-compose.yml]

**How to avoid:** Use one demo app-port env var for host mapping and `PORT`, while requiring docs/smoke examples to set `LOCKSPIRE_DEMO_BASE_URL` to the browser-visible URL. [VERIFIED: 113-CONTEXT.md]

**Warning signs:** `docker compose config` shows published port `4101` but `LOCKSPIRE_DEMO_BASE_URL` still contains `4100`. [VERIFIED: local command]

### Pitfall 2: Optional Traefik Makes Default Startup Fragile

**What goes wrong:** Default `docker compose up` can fail if it requires an external proxy network. [VERIFIED: 113-CONTEXT.md]

**Why it happens:** External networks are expected to exist before Compose connects services to them. [CITED: https://docs.docker.com/compose/how-tos/networking/]

**How to avoid:** Keep external Traefik network definitions in an opt-in override file, or prove profile behavior with `docker compose config` and local `up`. [CITED: https://docs.docker.com/compose/how-tos/profiles/] [ASSUMED]

**Warning signs:** Default config includes `local-dev-proxy` or web joins the external proxy network without an explicit Traefik mode. [VERIFIED: tools/traefik/docker-compose.yml]

### Pitfall 3: Interpolated Traefik Label Keys Do Not Expand

**What goes wrong:** Router/service names remain literal `${...}` or labels are missing. [CITED: https://docs.docker.com/reference/compose-file/interpolation/]

**Why it happens:** Compose interpolation does not apply to arbitrary YAML keys, including map-style labels. [CITED: https://docs.docker.com/reference/compose-file/interpolation/]

**How to avoid:** Use list labels with `KEY=VALUE` strings. [CITED: https://docs.docker.com/reference/compose-file/interpolation/]

**Warning signs:** `docker compose config --format json` contains label keys with `$` or missing `traefik.http.routers.<router>.*`. [VERIFIED: local command]

### Pitfall 4: Reset Deletes the Wrong Project

**What goes wrong:** A reset command deletes another checkout's volumes or all unused Docker volumes. [VERIFIED: 113-CONTEXT.md]

**Why it happens:** Hard-coded project names and prune-style commands ignore Compose project scoping. [VERIFIED: 113-CONTEXT.md]

**How to avoid:** Resolve or require the same project name used for startup and delete only `db_data`, `deps_volume`, and `build_volume` for that project. [VERIFIED: 113-CONTEXT.md] [VERIFIED: docker compose config]

**Warning signs:** Reset command includes `docker volume prune`, `docker system prune`, or a hard-coded `adoption_demo_` prefix. [VERIFIED: codebase grep]

## Code Examples

Verified patterns from official sources:

### Render Compose Config for Assertions

```sh
# Source: local verified Compose CLI behavior
LOCKSPIRE_DEMO_APP_PORT=4101 \
LOCKSPIRE_DEMO_BASE_URL=http://127.0.0.1:4101 \
docker compose -p lockspire-adoption-demo-alt \
  -f examples/adoption_demo/docker-compose.yml \
  config --format json
```

### Optional Traefik Network Setup

```sh
# Source: Docker Compose networking docs
docker network create "${LOCKSPIRE_DEMO_TRAEFIK_NETWORK:-local-dev-proxy}"
docker compose -f tools/traefik/docker-compose.yml up -d
LOCKSPIRE_DEMO_BASE_URL="http://${LOCKSPIRE_DEMO_TRAEFIK_HOST:-lockspire-demo.localhost}" \
docker compose \
  -f examples/adoption_demo/docker-compose.yml \
  -f examples/adoption_demo/docker-compose.traefik.yml \
  up --build
```

### Smoke Against Configured Base URL

```sh
# Source: existing smoke script contract
LOCKSPIRE_DEMO_BASE_URL=http://127.0.0.1:4101 python3 scripts/demo/adoption_smoke.py
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Hard-coded direct URL/port in Compose | Interpolated Compose values plus explicit base URL | Phase 113 target | Enables sibling demos and alternate checkouts to run concurrently. [VERIFIED: 113-CONTEXT.md] |
| Default Postgres host port binding | Internal-only DB with opt-in host mapping | Current default already internal-only | Avoids local `5432` conflicts. [VERIFIED: examples/adoption_demo/docker-compose.yml] |
| Required local proxy | Direct default plus optional Traefik override/profile | Phase 113 target | Keeps basic Docker startup independent of external network setup. [VERIFIED: 113-CONTEXT.md] |

**Deprecated/outdated:**

- Hard-coded `4100:4100` plus `PORT=4100` plus `LOCKSPIRE_DEMO_BASE_URL=http://127.0.0.1:4100` in Compose should be replaced with configurable defaults. [VERIFIED: examples/adoption_demo/docker-compose.yml]
- Any docs that tell maintainers to open `http://127.0.0.1:4100` without mentioning configured `LOCKSPIRE_DEMO_BASE_URL` are incomplete for Phase 113. [VERIFIED: docs/adoption-demo.md]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | A Traefik override file is lower risk than putting external network definitions in the base file behind a profile, because Compose docs state top-level elements are not affected by profiles. | Summary, Standard Stack, Common Pitfalls | Planner may choose a profile-only design that still works, but must prove default `docker compose up` does not require the external network. |
| A2 | Recommended env var names such as `LOCKSPIRE_DEMO_APP_PORT`, `LOCKSPIRE_DEMO_TRAEFIK_HOST`, `LOCKSPIRE_DEMO_TRAEFIK_ROUTER`, `LOCKSPIRE_DEMO_TRAEFIK_SERVICE`, and `LOCKSPIRE_DEMO_TRAEFIK_NETWORK` are unsurprising and acceptable. | Architecture Patterns, Code Examples | User may prefer alternate names; planner should keep names demo-scoped and document them. |

## Resolved Research Decisions

1. **Reset implementation**
   - Decision: Plan `examples/adoption_demo/bin/docker-reset` as a small shell helper plus docs. [ASSUMED]
   - Rationale: A helper makes CONFLICT-04 testable with source assertions and avoids copy/paste mistakes while still keeping reset scoped to the active Compose project and the three demo-owned volumes. [VERIFIED: 113-CONTEXT.md]
   - Planning consequence: Contract tests should inspect the helper for active-project handling, the `db_data`, `deps_volume`, and `build_volume` allowlist, and absence of global prune commands. [ASSUMED]

2. **DB host exposure shape**
   - Decision: Keep DB host exposure independent from Traefik mode by planning a separate opt-in override file such as `examples/adoption_demo/docker-compose.db-host.yml`. [ASSUMED]
   - Rationale: CONFLICT-03 requires default DB host exposure to remain absent, and D-08 requires any host access to be opt-in/configurable through demo-owned Compose configuration. Separating this override from Traefik prevents maintainers from publishing PostgreSQL merely because they enabled hostname routing. [VERIFIED: 113-CONTEXT.md]
   - Planning consequence: `LOCKSPIRE_DEMO_DB_HOST_PORT` controls only the host-side DB port in the opt-in DB override; app-to-DB wiring keeps `LOCKSPIRE_DEMO_DB_PORT=5432` as the internal container port. [ASSUMED]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Docker CLI | Compose config/render/start/reset validation | yes | `29.5.2` | None for Docker-path proof. [VERIFIED: local command] |
| Docker Compose CLI | Phase 113 primary implementation/validation | yes | `v5.1.3` | None for Compose-path proof. [VERIFIED: local command] |
| Mix / Elixir | Existing project tests and docs compile | yes | Mix `1.19.5`, OTP `28` | None for ExUnit proof. [VERIFIED: local command] |
| Python 3 | Existing adoption smoke | yes | `3.14.4` | Manual HTTP smoke only. [VERIFIED: local command] |
| Traefik runtime | Optional local hostname smoke | partial | helper references `traefik:v2.10`; image availability not probed | Document optional setup; skip full smoke if image/network unavailable. [VERIFIED: tools/traefik/docker-compose.yml] |
| Context7 CLI | Library docs lookup | no | — | Official docs/web sources used. [VERIFIED: local command] |

**Missing dependencies with no fallback:**

- None for research and deterministic Compose config proof. [VERIFIED: local command]

**Missing dependencies with fallback:**

- Context7 CLI is missing; official Docker/Traefik docs were used instead. [VERIFIED: local command]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit, plus `docker compose config --format json` shell assertions. [VERIFIED: test/test_helper.exs] |
| Config file | `.formatter.exs`, `.credo.exs`, `mix.exs`; no dedicated Compose test config exists. [VERIFIED: codebase grep] |
| Quick run command | `mix test test/lockspire/adoption_demo_docker_contract_test.exs` [ASSUMED] |
| Full suite command | `mix test.fast` [VERIFIED: mix.exs] |

### Phase Requirements -> Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| CONFLICT-01 | Configured project name changes rendered resource names. | unit/contract | `mix test test/lockspire/adoption_demo_docker_contract_test.exs --seed 0` | No, Wave 0 |
| CONFLICT-02 | Configured app port appears in host mapping, `PORT`, docs examples, and smoke command env. | unit/contract | `mix test test/lockspire/adoption_demo_docker_contract_test.exs --seed 0` | No, Wave 0 |
| CONFLICT-03 | Default DB service has no host `ports`; opt-in config uses configured host port only. | unit/contract | `mix test test/lockspire/adoption_demo_docker_contract_test.exs --seed 0` | No, Wave 0 |
| CONFLICT-04 | Reset command targets only active project `db_data`, `deps_volume`, and `build_volume`. | unit/contract | `mix test test/lockspire/adoption_demo_docker_contract_test.exs --seed 0` | No, Wave 0 |
| TRAEFIK-01 | Default Compose model has no Traefik dependency or external proxy network. | unit/contract | `mix test test/lockspire/adoption_demo_docker_contract_test.exs --seed 0` | No, Wave 0 |
| TRAEFIK-02 | Optional Traefik mode renders configurable hostname/router/service/network labels and explicit service port. | unit/contract | `mix test test/lockspire/adoption_demo_docker_contract_test.exs --seed 0` | No, Wave 0 |

### Sampling Rate

- **Per task commit:** `mix test test/lockspire/adoption_demo_docker_contract_test.exs` [ASSUMED]
- **Per wave merge:** `mix test.fast` plus `docker compose -f examples/adoption_demo/docker-compose.yml config --format json` [VERIFIED: mix.exs] [VERIFIED: local command]
- **Phase gate:** Full suite green before `$gsd-verify-work`; optional local Traefik smoke documented but not required for CI. [VERIFIED: 113-CONTEXT.md]

### Wave 0 Gaps

- [ ] `test/lockspire/adoption_demo_docker_contract_test.exs` - covers CONFLICT-01..04 and TRAEFIK-01..02 by invoking `docker compose config --format json`. [ASSUMED]
- [ ] `examples/adoption_demo/bin/docker-reset` or equivalent documented helper - covers CONFLICT-04. [ASSUMED]
- [ ] Optional `examples/adoption_demo/docker-compose.traefik.yml` - covers TRAEFIK-01/02 if planner chooses override-file design. [ASSUMED]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V2 Authentication | no | No authentication semantics change; preserve existing host-owned auth seams. [VERIFIED: 113-CONTEXT.md] |
| V3 Session Management | no | No session behavior change. [VERIFIED: 113-CONTEXT.md] |
| V4 Access Control | no | No admin/operator authorization change. [VERIFIED: 113-CONTEXT.md] |
| V5 Input Validation | yes | Validate env-derived URLs/ports through existing `LOCKSPIRE_DEMO_BASE_URL` parser and Compose config proof. [VERIFIED: examples/adoption_demo/config/config.exs] |
| V6 Cryptography | no | No key/token/algorithm behavior change. [VERIFIED: 113-CONTEXT.md] |
| V9 Communications | yes | Browser-visible URLs and optional proxy hostnames must preserve exact issuer/redirect URL alignment. [VERIFIED: AGENTS.md] [VERIFIED: examples/adoption_demo/config/config.exs] |
| V14 Configuration | yes | Compose/env configuration must avoid accidental DB host exposure and accidental Traefik requirement. [VERIFIED: 113-CONTEXT.md] |

### Known Threat Patterns for Docker Compose Demo DX

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Accidental DB host exposure | Information Disclosure | Keep DB `ports:` absent by default; place host DB port only in opt-in override/profile. [VERIFIED: examples/adoption_demo/docker-compose.yml] |
| Issuer/redirect URL drift | Spoofing/Tampering | Keep `LOCKSPIRE_DEMO_BASE_URL` as single browser-visible truth; smoke asserts discovery/endpoint/callback alignment. [VERIFIED: scripts/demo/adoption_smoke.py] |
| Reset deletes unrelated Docker resources | Denial of Service | Use active-project volume allowlist, never global prune. [VERIFIED: 113-CONTEXT.md] |
| Traefik routes wrong container port | Denial of Service | Set `traefik.http.services.<service>.loadbalancer.server.port` explicitly. [CITED: https://doc.traefik.io/traefik/v2.0/routing/providers/docker/] |

## Sources

### Primary (HIGH confidence)

- Docker Compose project names - https://docs.docker.com/compose/how-tos/project-name/
- Docker Compose predefined env vars - https://docs.docker.com/compose/how-tos/environment-variables/envvars/
- Docker Compose interpolation - https://docs.docker.com/reference/compose-file/interpolation/
- Docker Compose profiles - https://docs.docker.com/compose/how-tos/profiles/ and https://docs.docker.com/reference/compose-file/profiles/
- Docker Compose networking/external networks - https://docs.docker.com/compose/how-tos/networking/
- Docker Compose volumes/down - https://docs.docker.com/reference/compose-file/volumes/ and https://docs.docker.com/reference/cli/docker/compose/down/
- Traefik Docker provider labels and custom port - https://doc.traefik.io/traefik/v2.0/routing/providers/docker/
- Docker Traefik guide - https://docs.docker.com/guides/traefik/
- Local code: `examples/adoption_demo/docker-compose.yml`, `examples/adoption_demo/bin/docker-start`, `examples/adoption_demo/config/config.exs`, `scripts/demo/adoption_smoke.py`, `docs/adoption-demo.md`, `tools/traefik/docker-compose.yml`. [VERIFIED: codebase grep]

### Secondary (MEDIUM confidence)

- Local `docker compose config --format json` output for current adoption demo and Traefik helper. [VERIFIED: local command]

### Tertiary (LOW confidence)

- None.

## Metadata

**Confidence breakdown:**

- Standard stack: HIGH - no new packages; all tools are existing project/local dependencies and official Docker/Traefik docs were checked.
- Architecture: HIGH - current code clearly isolates Compose/demo tooling from Lockspire protocol/runtime code.
- Pitfalls: HIGH - pitfalls are directly tied to current hard-coded Compose values, official Compose interpolation/profile behavior, and locked context decisions.

**Research date:** 2026-06-04
**Valid until:** 2026-07-04 for Docker Compose/Traefik docs; recheck sooner if Docker Compose CLI behavior around profiles/external networks becomes a planner dependency.
