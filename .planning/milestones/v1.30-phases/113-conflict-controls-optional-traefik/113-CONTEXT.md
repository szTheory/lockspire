# Phase 113: Conflict Controls & Optional Traefik - Context

**Gathered:** 2026-06-04 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 113 makes the adoption-demo Docker path conflict-resistant for maintainers running multiple local Lockspire checkouts or sibling Elixir library demos. It covers configurable Compose project names, configurable public app ports, optional and configurable PostgreSQL host-port exposure, active-project-scoped cache reset, and opt-in Traefik hostname routing.

This phase must not make Traefik required, add the full startup URL/account/client banner, add reprint commands, introduce broad repo hygiene cleanup, add full Docker smoke to CI, create production Docker packaging, or change OAuth/OIDC protocol behavior.
</domain>

<decisions>
## Implementation Decisions

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

### Folded Todos

No matching pending todos were found for Phase 113.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

- `.planning/PROJECT.md` - v1.30 milestone intent, embedded-library boundary, and current adoption-demo Docker DX focus.
- `.planning/REQUIREMENTS.md` - CONFLICT-01..04, TRAEFIK-01..02, and v1.30 boundaries.
- `.planning/ROADMAP.md` - Phase 113 scope and split across Phases 114-115.
- `.planning/STATE.md` - current milestone state and locked decisions that direct Docker is default and Traefik is optional.
- `.planning/METHODOLOGY.md` - assumption-first, research-first, high-threshold escalation, and one-shot recommendation lenses.
- `.planning/phases/111-demo-url-contract-config-unification/111-CONTEXT.md` - locked base URL, issuer, seed URL, smoke, and bind-interface decisions Phase 113 must preserve.
- `.planning/phases/112-default-docker-compose-app-db/112-CONTEXT.md` - locked direct Docker, app-plus-PostgreSQL topology, internal-only DB default, named volumes, idempotent startup, and readiness decisions.
- `examples/adoption_demo/docker-compose.yml` - current direct app-plus-PostgreSQL Compose topology, hard-coded port/base URL, and named volumes.
- `examples/adoption_demo/bin/docker-start` - current Docker startup, readiness wait, and minimal ready output.
- `examples/adoption_demo/config/config.exs` - current `LOCKSPIRE_DEMO_BASE_URL`, `LOCKSPIRE_DEMO_BIND_IP`, `PORT`, and database env wiring.
- `examples/adoption_demo/mix.exs` - current `ecto.setup` and `ecto.reset` aliases.
- `scripts/demo/adoption_smoke.py` - existing base-URL-driven black-box smoke proof.
- `docs/adoption-demo.md` - current Docker default, host-local fallback, seeded account/client, and smoke documentation.
- `tools/traefik/docker-compose.yml` - existing local Traefik helper, `traefik:v2.10`, dashboard, Docker provider, and `local-dev-proxy` external network.
- Docker Compose docs, profiles - confirms core services should remain unprofiled and optional profile services can be enabled with `--profile` or `COMPOSE_PROFILES`.
- Docker Compose docs, networking - confirms external networks must already exist before `docker compose up` and can be used to connect multiple Compose projects.
- Docker Compose docs, interpolation - confirms Compose values, including labels in equal-sign syntax, can use variable interpolation.
- Traefik v2.10 Docker provider docs - confirms routing configuration comes from Docker labels and the load-balancer server port label should be specified when port detection is ambiguous.
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `examples/adoption_demo/docker-compose.yml` already defines the default `web` and `db` services, source mount, internal PostgreSQL service, and named `db_data`, `deps_volume`, and `build_volume` resources.
- `examples/adoption_demo/bin/docker-start` already normalizes `LOCKSPIRE_DEMO_BASE_URL`, waits for PostgreSQL, prepares the database, starts Phoenix, waits for HTTP readiness, and prints the active base URL.
- `examples/adoption_demo/config/config.exs` already validates `LOCKSPIRE_DEMO_BASE_URL`, derives endpoint URL and Lockspire issuer from it, reads `PORT`, and keeps `LOCKSPIRE_DEMO_BIND_IP` separate.
- `scripts/demo/adoption_smoke.py` already treats `LOCKSPIRE_DEMO_BASE_URL` as the only external URL input and asserts issuer/endpoint/callback/device-verification alignment.
- `tools/traefik/docker-compose.yml` already provides the repo's local Traefik helper and shared external network name.

### Established Patterns

- The adoption demo is repo-local proof, not a production Docker package or public Lockspire API surface.
- Exact URL alignment matters because Lockspire preserves exact redirect URI matching and discovery/issuer truth.
- Default Docker startup should stay boring and direct; optional proxy mode is useful local DX only.
- Cache/build artifacts are intentionally isolated as Compose named volumes so container Linux artifacts do not collide with host Mix artifacts.

### Integration Points

- Compose project naming should affect the adoption-demo project resources without changing the Phoenix app or Lockspire configuration semantics.
- Port configurability must align the host `ports:` mapping, container `PORT`, and `LOCKSPIRE_DEMO_BASE_URL`.
- Optional database host-port exposure, if planned, belongs in Compose configuration rather than application config.
- Optional Traefik labels must target the web service and the configured internal Phoenix port while leaving the database unexposed.
- Reset commands must resolve the active project name before deleting volumes, so they operate on the same Compose namespace as startup.
</code_context>

<specifics>
## Specific Ideas

- Prefer keeping `http://127.0.0.1:4100` as the default direct Docker base URL.
- Prefer project names and Traefik router/service names that include a Lockspire/adoption-demo prefix by default, while allowing overrides.
- Prefer documenting `docker network create local-dev-proxy` for optional Traefik mode rather than running broad network setup implicitly, unless planning finds a narrow helper that is safer and clearer.
- Prefer reset semantics equivalent to deleting only the active project's `db_data`, `deps_volume`, and `build_volume` volumes.
</specifics>

<deferred>
## Deferred Ideas

- Full startup banner with active URL set, seeded accounts, seeded clients, and exact smoke command - Phase 114.
- Reprint command for current demo information - Phase 114.
- Expanded adoption-demo docs covering default startup, optional Traefik, smoke, stop, reset, cleanup, overrides, and troubleshooting - mostly Phase 114, with Phase 113 limited to conflict-control and Traefik setup truth needed for planning.
- Repo hygiene gate, broad scoped cleanup lane, Docker leftover checks, CI/local hygiene split, and no-BLOCK cleanup proof - Phase 115.
- Full Docker smoke in CI - future requirement if local Docker proof is stable and non-flaky.
- Production Docker release images or deployment packaging - future distribution milestone only.

### Reviewed Todos (not folded)

No matching pending todos were found.
</deferred>

---

*Phase: 113-conflict-controls-optional-traefik*
*Context gathered: 2026-06-04*
