# Domain Pitfalls

**Domain:** v1.30 Adoption Demo Docker DX & Repo Hygiene
**Researched:** 2026-06-04
**Overall confidence:** HIGH for repo-specific findings, MEDIUM for general Docker/Traefik ergonomics.

## Critical Pitfalls

Mistakes that make the demo fail for first adopters, create false smoke-test confidence, or destroy useful maintainer evidence.

### Pitfall 1: Hard-Coded Issuer And Callback Drift

**What goes wrong:** The demo can start on a non-default port or hostname, but OIDC metadata, redirect URIs, seeded clients, and the smoke test disagree about the canonical URL. `examples/adoption_demo/config/config.exs` currently derives `Endpoint.url` from `LOCKSPIRE_DEMO_HOST` and `PORT`, while `:lockspire` still hard-codes `issuer: "http://127.0.0.1:4100/lockspire"`. `scripts/demo/adoption_smoke.py` then asserts discovery issuer and endpoint URLs equal `LOCKSPIRE_DEMO_BASE_URL + "/lockspire"` and uses `BASE_URL + "/oauth/callback"` as the redirect URI.

**Why it happens:** Docker DX encourages configurable `PORT`, Traefik hostname routing, and alternative base URLs, but OAuth/OIDC requires exact issuer and redirect URI consistency. Changing only Compose ports or only `LOCKSPIRE_DEMO_BASE_URL` creates a split-brain demo.

**Consequences:** Discovery smoke fails, authorization callback fails exact redirect matching, cookies may target the wrong host, and maintainers waste time debugging protocol behavior that is actually environment drift.

**Prevention:**
- Introduce one canonical `LOCKSPIRE_DEMO_BASE_URL` for the browser-visible origin, and derive Phoenix `url`, Lockspire `issuer`, smoke defaults, startup output, and seeded redirect URIs from it.
- Keep container listen port separate from public base URL: `PORT` should mean internal Phoenix port, while published host port and Traefik hostname map to `LOCKSPIRE_DEMO_BASE_URL`.
- Add a release-readiness or demo config test that proves discovery `issuer`, `authorization_endpoint`, `device_authorization_endpoint`, seeded public-client redirect URI, and smoke `BASE_URL` all share the same origin.
- Make the startup banner print the exact smoke command when the user overrides the base URL, e.g. `LOCKSPIRE_DEMO_BASE_URL=http://adoption-demo.localhost python3 scripts/demo/adoption_smoke.py`.

**Detection:** `/.well-known/openid-configuration` returns `issuer` with `127.0.0.1:4100` while the app is being accessed through another host or port; auth-code exchange fails with invalid redirect URI; smoke fails at the discovery assertions.

**Phase to address:** Phase 1, "Demo URL Contract & Config Unification."

**Repo traps:** `examples/adoption_demo/config/config.exs` has two separate URL truths today; `scripts/demo/adoption_smoke.py` requires exact equality; v1.27's route-protection smoke depends on `BASE_URL + "/oauth/callback"`.

### Pitfall 2: Docker Path Still Assumes Host Postgres

**What goes wrong:** A maintainer runs `docker compose up` expecting app plus database, but the container tries to connect to `localhost:5432` inside the app container. The current Compose file has only `web`; `config.exs` defaults DB host to `localhost` and may inherit `PGHOST` or host user values that are meaningless inside Compose.

**Why it happens:** The pre-Docker local instructions rely on host Postgres. Moving the app into a container without adding a database service and container-specific defaults preserves the old assumption invisibly.

**Consequences:** First run fails with database connection errors, or worse, connects to an unintended developer Postgres when env vars leak into Compose. This undercuts the milestone's main value: no host Postgres assumption.

**Prevention:**
- Add a `db` service using PostgreSQL 14+ with a named volume and healthcheck.
- In Compose, set `LOCKSPIRE_DEMO_DB_HOST=db`, `LOCKSPIRE_DEMO_DB_USER`, `LOCKSPIRE_DEMO_DB_PASSWORD`, `LOCKSPIRE_DEMO_DB_NAME`, and `LOCKSPIRE_DEMO_DB_PORT=5432` explicitly instead of relying on inherited `PG*`.
- Gate app startup on database readiness with `depends_on: condition: service_healthy` plus a startup command that runs `mix ecto.setup` or an idempotent migration/seed path.
- Keep local, non-Docker docs valid by documenting the host Postgres path separately from the Docker path.

**Detection:** `mix ecto.setup` succeeds on host but `docker compose up` fails with `tcp connect localhost:5432`; container logs show user from host `$USER` rather than a demo DB user.

**Phase to address:** Phase 1, "Default Docker Compose App + DB."

**Repo traps:** `examples/adoption_demo/config/config.exs` falls back through `PGUSER`, `USER`, `PGHOST`, and `localhost`; `docs/adoption-demo.md` only documents local host commands today.

### Pitfall 3: Phoenix Binds To Loopback Inside The Container

**What goes wrong:** The container starts, but Traefik or host port publishing cannot reach Phoenix because the endpoint binds to `{127, 0, 0, 1}` inside the container. The current Compose comment says Phoenix must bind to `0.0.0.0`, but `config.exs` hard-codes loopback.

**Why it happens:** Phoenix host-local development normally binds to loopback for safety. Container-to-container and host-to-container traffic requires binding to all interfaces inside the container.

**Consequences:** Traefik returns a gateway error or connection refused, direct `localhost:${port}` requests fail, and the startup path looks broken even though `mix phx.server` is running.

**Prevention:**
- Use an env-controlled bind mode: default host-local can remain loopback, but Docker Compose must set an explicit `LOCKSPIRE_DEMO_BIND_IP=0.0.0.0` or equivalent parsed into `{0, 0, 0, 0}`.
- Add a smoke preflight that curls the public base URL from outside the container, not only `mix phx.server` logs.
- Keep `PORT` as the internal Phoenix port when using Traefik; do not require publishing that same port on the host for hostname routing.

**Detection:** Container logs show `Running AdoptionDemoWeb.Endpoint ... http://127.0.0.1:4000`; `docker compose exec web curl http://127.0.0.1:4000` works but `curl http://127.0.0.1:${published_port}` or Traefik host fails.

**Phase to address:** Phase 1, "Default Docker Compose App + DB."

**Repo traps:** `examples/adoption_demo/docker-compose.yml` sets `PORT=4000` and Traefik service port 4000; `config.exs` still binds to `{127, 0, 0, 1}`.

### Pitfall 4: Compose Project Name And Volume Collisions Across Local Projects

**What goes wrong:** Multiple local demo projects named `adoption_demo` create indistinguishable containers, networks, and named volumes, or one checkout reuses another checkout's `_build`/`deps` cache. Docker Compose prefixes resources by project, and project name precedence includes `-p`, `COMPOSE_PROJECT_NAME`, top-level `name:`, and directory basename.

**Why it happens:** The demo lives under a generic `examples/adoption_demo` directory. Without an explicit, configurable project name, Compose derives names from the project directory. Named volumes like `deps_volume` and `build_volume` then become project-scoped but still collide between same-basename checkouts.

**Consequences:** Stale Elixir artifacts survive source changes, one checkout's `docker compose down -v` removes another checkout's volumes, and maintainers see nondeterministic behavior when testing multiple libraries.

**Prevention:**
- Add a top-level Compose `name:` with an interpolated default such as `${LOCKSPIRE_DEMO_COMPOSE_PROJECT:-lockspire_adoption_demo}` and document overriding it.
- Include the selected project name in startup output and cleanup commands.
- Name cache volumes through Compose project scoping, but provide a cache-reset command that targets the active project only.
- Avoid `container_name`; it disables Compose's project-scoped naming and makes parallel runs harder.

**Detection:** `docker compose ps` or Docker Desktop shows containers from another checkout; `_build` errors persist after source changes; `docker volume ls` has multiple similarly named adoption demo volumes.

**Phase to address:** Phase 2, "Conflict-Resistant Ports, Project Names, and Cache Controls."

**Sources:** Docker documents the project-name precedence and resource prefixing behavior in the Compose CLI reference and application model.

### Pitfall 5: Over-Broad Hygiene Deletes Useful Evidence

**What goes wrong:** A cleanup script removes all `tmp/` content, all untracked files, Docker volumes, or screenshots/logs without distinguishing generated throwaway artifacts from evidence the previous admin UI milestones intentionally left for maintainer review. Current `git status` already shows untracked `tmp/admin-ui-polish/*.png`, `tmp/adoption_demo.log`, and exploratory `tmp/test_*.exs` files.

**Why it happens:** Repo hygiene often starts as "make `git status` clean." In this repo, some untracked artifacts are meaningful evidence, while some are stale local debris. A destructive cleanup path would erase context that v1.29 retrospective says browser and screenshot evidence relied on.

**Consequences:** Maintainers lose screenshot proof needed for UI comparisons; audit closeout becomes unverifiable; a cleanup command deletes user-created files outside its ownership boundary.

**Prevention:**
- Split hygiene into `check`, `list`, and `clean` modes; default to non-destructive reporting.
- Maintain an explicit allowlist of cleanup-owned paths such as `tmp/adoption-demo-docker/`, Compose logs created by the demo helper, and project-scoped Docker resources.
- Treat `tmp/admin-ui-polish/` as evidence, not disposable, unless a command flag explicitly names it.
- Never run `git clean -fdx` or broad `rm -rf tmp/*` from maintainer scripts.
- Print exact paths and Docker resources before deletion; require a confirmation flag such as `--force` for deletion.

**Detection:** Hygiene check output says only "dirty tree" without classifying untracked files; cleanup command would match `tmp/admin-ui-polish`; script uses `git clean`, `find tmp -delete`, or `docker system prune`.

**Phase to address:** Phase 4, "Repo Hygiene Gate and Scoped Cleanup Lane."

**Repo traps:** `.planning/RETROSPECTIVE.md` says browser/screenshot proof matters; `.planning/phases/*` reference `tmp/admin-ui-polish`; `scripts/maintainer/repo_hygiene_check.sh` currently blocks on any dirty tree without artifact classification.

## Moderate Pitfalls

### Pitfall 6: Traefik Is Required Instead Of Optional

**What goes wrong:** The default Compose path fails unless an external `local-dev-proxy` network and Traefik stack already exist. The current adoption demo Compose file attaches only to `local-dev-proxy` and marks it external; the Traefik Compose file also requires that network and binds host ports 80 and 8080.

**Why it happens:** Hostname routing is valuable for running multiple local projects, but making it the only path inverts the dependency. The default demo should work with plain Docker Compose first.

**Consequences:** First run fails with missing network errors; users who already have something on ports 80 or 8080 cannot start the Traefik helper; maintainers confuse proxy setup errors with app setup errors.

**Prevention:**
- Make direct port publishing the default path.
- Put Traefik labels/network behind an override file or Compose profile, e.g. `--profile traefik`.
- Provide a `tools/traefik` helper that creates its network idempotently and supports configurable host ports for 80 and 8080.
- Document that Traefik is an optional conflict-avoidance path, not required to run the demo.

**Detection:** `docker compose up` fails with `network local-dev-proxy declared as external, but could not be found`; Traefik fails because host port 80 or 8080 is allocated.

**Phase to address:** Phase 2, "Conflict-Resistant Ports, Project Names, and Optional Traefik."

**Sources:** Docker's Traefik guide describes hostname routing through a shared network and labels, and notes the service port forwarded by Traefik does not need host exposure.

### Pitfall 7: Static Traefik Labels Collide Between Projects

**What goes wrong:** Two apps define the same Traefik router/service names or hostname, so one route shadows the other or Traefik reports duplicate router definitions. The current labels hard-code `adoption-demo` router/service names and `Host(`adoption-demo.localhost`)`.

**Why it happens:** Traefik labels are global within the Docker provider view. Compose project scoping helps container names, but label names and hostname rules still need per-project uniqueness when several demos run behind one proxy.

**Consequences:** `http://adoption-demo.localhost` reaches the wrong checkout, dashboard routes are ambiguous, and smoke tests hit stale containers.

**Prevention:**
- Interpolate hostname and router/service label names from a sanitized project slug, e.g. `${LOCKSPIRE_DEMO_HOSTNAME:-lockspire-adoption-demo.localhost}` and `${LOCKSPIRE_DEMO_TRAEFIK_ROUTER:-lockspire-adoption-demo}`.
- Validate with `docker compose config` in docs or scripts so unset variables do not become empty label names.
- Print the active Traefik hostname in the startup banner and smoke command.

**Detection:** Traefik dashboard shows duplicate router/service names; browser reaches another local app at the same hostname; smoke assertions fail against unexpected HTML.

**Phase to address:** Phase 2, "Conflict-Resistant Ports, Project Names, and Optional Traefik."

**Sources:** Docker Compose interpolation uses shell and `.env` values with defined precedence; unset interpolation can produce empty strings, so `docker compose config --environment` is useful for validation.

### Pitfall 8: Docker Cache Invalidation Is Either Too Sticky Or Too Slow

**What goes wrong:** `deps/` and `_build/` are hidden behind Docker volumes for Mac/Linux binary isolation, but they outlive dependency, Elixir, OTP, or compile-target changes. The inverse mistake is removing volumes on every run, making the demo painfully slow.

**Why it happens:** The current `Dockerfile.dev` intentionally does not copy source or run `deps.get`; Compose mounts the app directory and overlays `/app/deps` and `/app/_build` with named volumes. That is correct for Mac bind-mount performance and Linux binaries, but stale volumes need a targeted reset story.

**Consequences:** Old BEAM artifacts create confusing compile/runtime errors, Phoenix assets or generated code lag source changes, or maintainers avoid the Docker path because every boot redownloads dependencies.

**Prevention:**
- Keep `deps` and `_build` in Docker-managed volumes, not host bind mounts.
- Add a documented `cache-reset` command that runs `docker compose down` plus removal of only the active project's `deps` and `_build` volumes.
- Include Elixir/OTP image tag and `mix.lock` checksum in startup diagnostics or a lightweight preflight so stale-cache symptoms are easier to recognize.
- Avoid anonymous volumes for durable caches if the cleanup lane needs to list and target them clearly; named project-scoped volumes are easier to inspect.

**Detection:** Errors mention incompatible NIFs or stale protocol consolidation; changing `mix.lock` does not fetch expected deps; deleting all Docker volumes fixes the issue.

**Phase to address:** Phase 2, "Conflict-Resistant Ports, Project Names, and Cache Controls."

**Sources:** Docker bind-mount docs note that bind mounts are tied to host filesystem behavior and can obscure container contents; Docker volumes are better for managed persistent state.

### Pitfall 9: Bind Mount Semantics Differ Across Mac And Linux

**What goes wrong:** The demo works on one maintainer's machine but not another's because bind mount paths, file notifications, permissions, or generated host artifacts behave differently between Docker Desktop's Linux VM and native Linux Docker.

**Why it happens:** Docker Desktop transparently shares host paths into a Linux VM, while native Linux uses the host filesystem directly. The current setup bind-mounts the entire demo directory to `/app`; generated files, `_build`, `deps`, node assets, and logs need clear ownership.

**Consequences:** Live reload misses changes, generated files are root-owned on Linux, host `deps` are accidentally shadowed, or cleanup deletes files the container created with unexpected ownership.

**Prevention:**
- Keep `_build` and `deps` as Docker volumes to avoid host/container binary mixing.
- Direct generated logs/screenshots for Docker runs into a known `tmp/adoption-demo-docker/` path, not arbitrary repo paths.
- Prefer explicit `type: bind` mounts over terse syntax when adding new mounts, so source/target/read-only intent is visible.
- Avoid writing repo source from inside the container except normal Phoenix code reload reads.

**Detection:** Host files become owned by root; LiveView reload works on macOS but not Linux; `deps` from host appears inside container despite volume declarations.

**Phase to address:** Phase 2, "Conflict-Resistant Ports, Project Names, and Cache Controls."

**Sources:** Docker bind-mount docs call out Docker Desktop's Linux VM behavior, host filesystem coupling, and bind mounts obscuring existing container directories.

### Pitfall 10: Startup Banner Lies Or Leaks

**What goes wrong:** The app starts but prints stale URLs, missing admin routes, wrong smoke command, or sensitive material. This milestone asks for startup output with URLs, admin routes, seeded accounts, and smoke command; getting that wrong creates a new source of truth.

**Why it happens:** Startup messages are often hand-written in shell wrappers and drift from seeds, config, and routes. Lockspire also has a strong redaction boundary, so printing secrets or raw tokens would violate established defaults.

**Consequences:** Maintainers poke the wrong URL, use stale seeded accounts, or leak client secrets into logs copied into bug reports.

**Prevention:**
- Generate startup output from the same env/config values used by the endpoint and Lockspire issuer.
- Print client IDs and seeded login names, but do not print client secrets, tokens, authorization codes, refresh tokens, private keys, or cookie values.
- Include admin route entry points such as `/lockspire/admin`, not a long route inventory that can drift from `AdminRouter`.
- Add a smoke or source test that asserts the banner includes the computed base URL and redacts known secret patterns.

**Detection:** Banner says `127.0.0.1:4100` while Docker maps another port; logs contain `client_secret`, `access_token`, `refresh_token`, or private JWK material.

**Phase to address:** Phase 3, "Startup Banner, Docs, and Smoke Alignment."

**Repo traps:** Seeded accounts are documented in `docs/adoption-demo.md`; client secret handling is a security default in `AGENTS.md`; admin routes were recently polished and should not be duplicated manually.

### Pitfall 11: Smoke Test Only Proves One Network Path

**What goes wrong:** CI or local direct-port smoke passes, but Traefik hostname mode fails; or Traefik smoke passes while direct port docs are broken. `adoption_smoke.py` currently supports `LOCKSPIRE_DEMO_BASE_URL`, but it assumes HTTPConnection to a single hostname/port and exact discovery/callback alignment.

**Why it happens:** Docker adds at least three network perspectives: inside the app container, from the host to a published port, and from the host through Traefik. A single default smoke run can leave one path untested.

**Consequences:** The advertised conflict-resistant mode regresses unnoticed; docs claim a smoke command that does not match the active base URL.

**Prevention:**
- Keep one smoke script but run it against both supported public origins where feasible: direct `http://127.0.0.1:${LOCKSPIRE_DEMO_HOST_PORT}` and optional `http://${LOCKSPIRE_DEMO_HOSTNAME}`.
- Add a fast `--check-url-contract` or equivalent mode if full browser-like flow is too expensive for both paths.
- Ensure Compose startup output prints the exact `LOCKSPIRE_DEMO_BASE_URL=...` invocation for the active path.

**Detection:** `python3 scripts/demo/adoption_smoke.py` passes at `127.0.0.1:4100`, but the printed Traefik URL returns a different discovery issuer or callback failure.

**Phase to address:** Phase 3, "Startup Banner, Docs, and Smoke Alignment."

**Repo traps:** The smoke asserts exact issuer and redirect values, which is good; the trap is not running it against every documented origin.

## Minor Pitfalls

### Pitfall 12: `.env` Precedence Surprises

**What goes wrong:** A maintainer has `PGHOST`, `PORT`, `COMPOSE_PROJECT_NAME`, or demo-specific values in their shell or root `.env`, and Compose silently uses them. The app then runs with surprising ports, DB settings, or project names.

**Prevention:** Provide `examples/adoption_demo/.env.example`, document the relevant variables, and recommend `docker compose --env-file .env` from the demo directory. Add a preflight or docs command using `docker compose config --environment` to show resolved values.

**Phase to address:** Phase 2, "Conflict-Resistant Ports, Project Names, and Cache Controls."

**Sources:** Docker Compose variable interpolation uses shell environment first, then `.env` in the working directory, then explicit env files.

### Pitfall 13: Cleanup Conflates Docker Resources With Git State

**What goes wrong:** The hygiene gate says the repo is dirty because Docker-created logs exist, then cleanup removes Docker volumes but leaves untracked files, or vice versa. Maintainers cannot tell which command fixes which problem.

**Prevention:** Separate checks into categories: git tracked changes, untracked generated files, Docker containers, Docker volumes, Docker networks, and stale logs/screenshots. Give one remediation command per category.

**Phase to address:** Phase 4, "Repo Hygiene Gate and Scoped Cleanup Lane."

### Pitfall 14: CI Hygiene Runs Local-Only Checks

**What goes wrong:** The CI mode of `repo_hygiene_check.sh` starts depending on Docker daemon state, local ports, `gh auth`, or local worktree cleanliness. CI becomes flaky or impossible to reproduce.

**Prevention:** Preserve the current `--ci` split: CI should check repo-owned drift only. Docker state, open local ports, dirty worktrees, and cleanup suggestions belong to local mode.

**Phase to address:** Phase 4, "Repo Hygiene Gate and Scoped Cleanup Lane."

**Repo traps:** The current script already separates `repo_owned_checks` from `local_checks`; extend that shape instead of mixing Docker checks into `--ci`.

### Pitfall 15: Documentation Replaces The Simple Host Path

**What goes wrong:** Docker docs become the only documented route, and users who prefer host Postgres or already have Elixir installed lose the simple `mix deps.get`, `mix ecto.setup`, `mix phx.server` path.

**Prevention:** Keep `docs/adoption-demo.md` split into "Docker quick start" and "Host-local path." Docker should be default for repeatability, not the only supported maintainer workflow.

**Phase to address:** Phase 3, "Startup Banner, Docs, and Smoke Alignment."

## Phase-Specific Warnings

| Phase Topic | Likely Pitfall | Mitigation |
|-------------|----------------|------------|
| Phase 1: Demo URL Contract & App+DB Compose | Hard-coded issuer, callback drift, loopback bind, no DB service | One `LOCKSPIRE_DEMO_BASE_URL`; explicit DB env; container bind IP; discovery/redirect config test |
| Phase 2: Conflict-Resistant Local Docker | Project-name collisions, port conflicts, Traefik-only setup, stale `_build`/`deps` volumes | Configurable Compose project name, host ports, optional Traefik profile, targeted cache reset |
| Phase 3: Startup Banner, Docs, Smoke | Banner drift, secret leakage, smoke only covers one origin | Generate output from config, redact secrets, print exact smoke command, smoke direct and optional Traefik origins |
| Phase 4: Repo Hygiene & Cleanup | Dirty tree over-blocks, cleanup deletes evidence, CI gets local-only checks | Classify artifacts, allowlist cleanup-owned paths, preserve `tmp/admin-ui-polish`, keep `--ci` repo-only |

## Sources

- Repo files: `.planning/PROJECT.md`, `docs/adoption-demo.md`, `examples/adoption_demo/docker-compose.yml`, `examples/adoption_demo/Dockerfile.dev`, `examples/adoption_demo/config/config.exs`, `tools/traefik/docker-compose.yml`, `scripts/demo/adoption_smoke.py`, `scripts/maintainer/repo_hygiene_check.sh`, `.planning/RETROSPECTIVE.md`.
- Docker Compose CLI reference: project name precedence and `-p` behavior. https://docs.docker.com/reference/cli/docker/compose/
- Docker Compose variable interpolation docs: `.env`, shell precedence, `--env-file`, and `docker compose config --environment`. https://docs.docker.com/compose/how-tos/environment-variables/variable-interpolation/
- Docker bind mount docs: host coupling, Docker Desktop VM behavior, bind mount obscuring behavior, and Compose bind mount syntax. https://docs.docker.com/engine/storage/bind-mounts/
- Docker Traefik development guide: hostname routing through labels, shared networks, and service-port forwarding without host exposure. https://docs.docker.com/guides/traefik/
