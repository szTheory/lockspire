# Phase 112: Default Docker Compose App + DB - Context

**Gathered:** 2026-06-04 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 112 provides the boring default Docker path for the adoption demo: a repo-local app plus PostgreSQL Compose topology, explicit database environment wiring, project-scoped Docker volumes, idempotent database setup, and HTTP readiness proof before reporting the demo ready.

This phase must not make Traefik required, build the full URL/account/client startup banner, add reprint commands, introduce cleanup or hygiene lanes, add full Docker smoke to CI, create production Docker packaging, or change OAuth/OIDC protocol behavior.
</domain>

<decisions>
## Implementation Decisions

### Compose Topology

- **D-01:** Use `examples/adoption_demo/docker-compose.yml` as the default repo-local demo Compose file, converting it from a Traefik-only web service into a direct app-plus-PostgreSQL default path.
- **D-02:** Keep the default Docker path direct-host-port first. Optional Traefik labels/networking belong to Phase 113 and must not be required for Phase 112 startup.

### PostgreSQL Service

- **D-03:** Add a PostgreSQL 14+ service to the adoption-demo Compose topology with explicit `POSTGRES_*` settings and matching `LOCKSPIRE_DEMO_DB_*` wiring for the Phoenix container.
- **D-04:** Keep PostgreSQL internal-only by default in Phase 112. Do not publish host port `5432`; configurable host exposure is Phase 113.
- **D-05:** Give PostgreSQL a Compose healthcheck and a named demo data volume scoped to the Compose project.

### Build Artifact Isolation

- **D-06:** Preserve container-local named volumes for `/app/deps` and `/app/_build` so Linux container artifacts do not collide with host Mix artifacts.
- **D-07:** Keep source bind-mounted for repo-local maintainer iteration; this is a developer adoption demo path, not a production release image.

### Startup And Readiness

- **D-08:** Replace `Dockerfile.dev`'s bare `mix deps.get && mix phx.server` startup with a small demo-owned startup script or equivalent command path that waits for PostgreSQL, installs dependencies, prepares the database, starts Phoenix, waits for the public demo URL to return HTTP 200, and only then reports readiness.
- **D-09:** Make database preparation idempotent for repeated container starts. Reuse the existing migration and seed assets, but avoid a repeated-start failure from a plain `mix ecto.create` when the database already exists.
- **D-10:** Treat `examples/adoption_demo/priv/repo/seeds.exs` as repeatable demo state. It already truncates Lockspire-owned tables before reseeding and should remain the single seed source unless planning finds a narrow startup-specific need.
- **D-11:** Phase 112 readiness output should be minimal: enough to prove the container waited for HTTP readiness. Full URL/account/client/smoke banner output is Phase 114.

### URL And Bind Contract

- **D-12:** Preserve the Phase 111 split: `LOCKSPIRE_DEMO_BASE_URL` is the browser-visible origin used by endpoint URL generation, issuer, seeds, and smoke; `LOCKSPIRE_DEMO_BIND_IP` controls only listener binding.
- **D-13:** In Docker mode, set `LOCKSPIRE_DEMO_BIND_IP=0.0.0.0` and use `LOCKSPIRE_DEMO_BASE_URL` for the host-visible direct URL. Do not infer bind IP from the base URL.

### Verification Boundary

- **D-14:** Add deterministic repo proof for the Compose contract and startup/readiness path where practical. Do not require full Docker smoke in CI during Phase 112; CI Docker proof is explicitly deferred unless a later phase proves it stable enough.

### the agent's Discretion

- The exact script name and shell structure for startup/readiness are at the agent's discretion, provided it stays demo-owned and easy to invoke from Compose.
- The exact default database username/password/database values are at the agent's discretion, provided they are explicit, artificial, and wired consistently through Postgres and Phoenix environment variables.
- The exact readiness endpoint can be `/` unless planning identifies an existing healthier route; the readiness check must use the public demo base URL.

### Folded Todos

No matching pending todos were found for Phase 112.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

- `.planning/PROJECT.md` - v1.30 milestone intent, embedded-library boundary, and current Phase 112 focus.
- `.planning/REQUIREMENTS.md` - DOCKER-01..06 requirements and v1.30 boundaries.
- `.planning/ROADMAP.md` - Phase 112 scope and the split across Phases 113-115.
- `.planning/STATE.md` - current milestone state and locked v1.30 decisions.
- `.planning/METHODOLOGY.md` - assumption-first, least-surprise host seam, research-first defaults, high-threshold escalation, and one-shot recommendation lenses.
- `.planning/phases/111-demo-url-contract-config-unification/111-CONTEXT.md` - locked base URL, issuer, seed URL, smoke, and bind-interface decisions Phase 112 must preserve.
- `.planning/phases/110-demo-state-screenshots-docs-and-regression-proof/110-CONTEXT.md` - seed-state source and demo proof boundary decisions.
- `.planning/phases/106-demo-seeds-docs-screenshots-and-contract-verification/106-CONTEXT.md` - precedent for `examples/adoption_demo/priv/repo/seeds.exs` as repeatable proof state.
- `.planning/phases/101-adoption-demo-re-wire/101-CONTEXT.md` - adoption-demo smoke, callback, protected-route, and base-proof precedent.
- `examples/adoption_demo/docker-compose.yml` - current Traefik-only web service, named `deps`/`_build` volumes, and Docker bind intent.
- `examples/adoption_demo/Dockerfile.dev` - current demo container image and startup command to replace or wrap.
- `examples/adoption_demo/config/config.exs` - current `LOCKSPIRE_DEMO_BASE_URL`, `LOCKSPIRE_DEMO_BIND_IP`, DB env, endpoint, and issuer wiring.
- `examples/adoption_demo/mix.exs` - current dependencies and `ecto.setup`/`ecto.reset` aliases.
- `examples/adoption_demo/priv/repo/seeds.exs` - repeatable seeded demo clients, keys, consents, tokens, device authorizations, IATs, and logout state.
- `scripts/demo/adoption_smoke.py` - existing base-URL-driven black-box smoke and readiness wait.
- `.github/workflows/ci.yml` - current adoption-demo CI env, host Postgres service, setup, server boot, and smoke invocation.
- `docs/adoption-demo.md` - current host-local docs that later phases will expand around the Docker default.
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `examples/adoption_demo/docker-compose.yml` already defines the demo web service, build context, source mount, named `deps` and `_build` volumes, and `LOCKSPIRE_DEMO_BIND_IP=0.0.0.0`, but currently assumes an external Traefik network and has no database service.
- `examples/adoption_demo/Dockerfile.dev` already installs build tools, npm, git, inotify, Hex, and Rebar, and uses volume-mounted source for live iteration.
- `examples/adoption_demo/config/config.exs` already consumes `LOCKSPIRE_DEMO_DB_USER`, `LOCKSPIRE_DEMO_DB_PASSWORD`, `LOCKSPIRE_DEMO_DB_HOST`, `LOCKSPIRE_DEMO_DB_PORT`, `LOCKSPIRE_DEMO_DB_NAME`, `LOCKSPIRE_DEMO_BASE_URL`, `LOCKSPIRE_DEMO_BIND_IP`, and `PORT`.
- `examples/adoption_demo/mix.exs` already has an `ecto.setup` alias for create, migrate, and seed; this can inform the Docker setup path but should be made repeated-start safe.
- `scripts/demo/adoption_smoke.py` already waits for `LOCKSPIRE_DEMO_BASE_URL` `/` to return HTTP 200 and proves the base URL across discovery, callback, device verification, token exchange, userinfo, and protected API.

### Established Patterns

- The adoption demo is repo-local proof, not a public product surface or production deployment package.
- Demo state is centralized in `examples/adoption_demo/priv/repo/seeds.exs`, and prior phases treat that file as the repeatable source of admin screenshot and click-through state.
- CI currently proves the adoption demo with host-provisioned Postgres and the black-box Python smoke; Phase 112 should not destabilize that existing proof.
- Exact URL alignment matters because Lockspire preserves exact redirect URI matching and discovery/issuer truth.

### Integration Points

- Compose must connect the `web` service to a `db` service through `LOCKSPIRE_DEMO_DB_HOST` and matching Postgres credentials.
- The web container must keep `LOCKSPIRE_DEMO_BIND_IP=0.0.0.0` while preserving `LOCKSPIRE_DEMO_BASE_URL` as the external direct URL.
- Startup orchestration should live under `examples/adoption_demo/` or `scripts/demo/` and be invoked by `Dockerfile.dev` or Compose without broadening Lockspire library APIs.
- Deterministic verification can inspect Compose/startup files and, where locally available, run Docker manually; full CI Docker smoke remains out of Phase 112 unless later planning explicitly revises that boundary.
</code_context>

<specifics>
## Specific Ideas

- Prefer `postgres:14` or a newer 14+ image tag that satisfies the requirement without surprising maintainers.
- Prefer a named data volume such as `db_data` inside the Compose project, alongside existing `deps_volume` and `build_volume`.
- Prefer a startup script that starts Phoenix in the background, waits against `LOCKSPIRE_DEMO_BASE_URL`, prints a concise ready line, then waits on the Phoenix process.
- Keep any credentials artificial and demo-scoped, such as `lockspire` / `lockspire` / `lockspire_adoption_demo`.
</specifics>

<deferred>
## Deferred Ideas

- Configurable Compose project names, configurable public app port matrix, scoped cache reset, and optional Traefik hostname routing - Phase 113.
- Full startup banner with active base URL, issuer, discovery, JWKS, admin, device verification, developer apps, callback, protected API, exact smoke command, seeded accounts, and client IDs - Phase 114.
- Reprint command for current demo info - Phase 114.
- Expanded adoption-demo docs that make Docker the default maintainer path and cover Traefik, smoke, stop, reset, cleanup, overrides, and troubleshooting - Phase 114.
- Repo hygiene gate, scoped cleanup lanes, Docker leftover checks, and CI/local hygiene split - Phase 115.
- Full Docker smoke in CI - future requirement if local Docker proof is stable and non-flaky.
- Production Docker release images or deployment packaging - future distribution milestone only.

### Reviewed Todos (not folded)

No matching pending todos were found.
</deferred>

---

*Phase: 112-default-docker-compose-app-db*
*Context gathered: 2026-06-04*
