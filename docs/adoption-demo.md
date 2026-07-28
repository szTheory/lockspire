# Adoption Demo

Lockspire includes a small Phoenix host app at `examples/adoption_demo`. It exists so maintainers can launch a realistic host app, open the Lockspire operator UI, and smoke the OAuth/OIDC path without wiring a separate project.

Docker is the default maintainer path. It starts Phoenix/Bandit plus PostgreSQL, keeps state scoped to one Compose project, and prints the URLs worth opening. The demo is repo-local adopter proof, not a production deployment guide, not hosted authentication, and not an expansion beyond `docs/supported-surface.md`. The canonical support contract still lives in `docs/supported-surface.md`.

The normal browser path uses Traefik hostname routing instead of a fixed localhost port. Do not open `127.0.0.1:4100` unless you intentionally started direct mode and the launcher printed that exact URL.

## Quick Start

From the repo root:

```sh
make demo
```

Open:

```text
http://lockspire-demo.localhost/lockspire/admin
```

Login with the host-owned demo account if prompted:

```text
ops
```

Useful next commands:

```sh
make demo-smoke
make demo-logs
make demo-stop
```

## What Starts

The demo starts a Phoenix SaaS host with Lockspire mounted as the embedded provider. The ready output leads with the operator job:

- Operator admin: `http://lockspire-demo.localhost/lockspire/admin`
- Login: `ops` if prompted
- Smoke: `make demo-smoke`
- Logs: `make demo-logs`
- Stop: `make demo-stop`

Additional routes are available through `make demo-info`:

| Job | URL | Login |
| --- | --- | --- |
| Home | `http://lockspire-demo.localhost` | none |
| Operator admin | `http://lockspire-demo.localhost/lockspire/admin` | `ops` |
| Developer apps | `http://lockspire-demo.localhost/developer/apps` | `alice` |
| Device verification | `http://lockspire-demo.localhost/verify` | `alice` or `bob` |

Seeded accounts:

| Login | Role | Account |
| --- | --- | --- |
| `alice` | SaaS user | `alice@acme.test` |
| `bob` | SaaS user | `bob@globex.test` |
| `ops` | Operator | `ops@acme.test` |

Seeded OAuth clients include `acme-ledger-public`, `acme-tv-device`, and `acme-ledger-backend`.

## Daily Commands

| Command | Use When | Effect |
| --- | --- | --- |
| `make demo` | Start the UI | Starts detached, waits for readiness, prints admin-first URLs. |
| `make demo-info` | You need the routes again | Reprints URLs, seeded accounts, client shapes, and smoke commands. |
| `make demo-smoke` | You want proof | Runs `scripts/demo/adoption_smoke.sh` against the running demo URL. |
| `make demo-logs` | Startup or runtime looks odd | Follows the demo web logs. |
| `make demo-stop` | You are done for now | Stops containers and preserves volumes. |
| `make demo-reset` | You want fresh seeded DB state | Removes only the active project's `db_data` volume. |
| `make demo-clean` | You want cleanup preview | Dry run; prints allowlisted cleanup candidates. |
| `make demo-clean-execute` | You already stopped the project | Removes only allowlisted demo resources. |

The Make targets delegate to `scripts/demo/admin-ui`, which delegates to the lower-level `examples/adoption_demo/bin/docker-*` scripts. The lower-level scripts remain available when you need explicit flags:

```sh
examples/adoption_demo/bin/docker-up
examples/adoption_demo/bin/docker-up --direct
examples/adoption_demo/bin/docker-stop
examples/adoption_demo/bin/docker-reset --db-only
examples/adoption_demo/bin/docker-reset --cache-only
examples/adoption_demo/bin/docker-reset --all
examples/adoption_demo/bin/docker-cleanup --execute
```

## Startup Output

After HTTP readiness succeeds, startup prints the same information as `examples/adoption_demo/bin/docker-info`, with the admin URL and `ops` login first.

`LOCKSPIRE_DEMO_BASE_URL` is the single public URL truth for endpoint generation, issuer, seeded URLs, startup output, docs, and smoke proof. Keep it aligned with the URL you type into the browser.

Reprint the banner:

```sh
make demo-info
```

Raw Compose reprint commands still work:

```sh
docker compose --project-name lockspire-adoption-demo -f examples/adoption_demo/docker-compose.yml exec web ./bin/docker-info
```

If the demo was started with an alternate Compose project:

```sh
docker compose --project-name lockspire-adoption-demo-alt -f examples/adoption_demo/docker-compose.yml exec web ./bin/docker-info
```

## Smoke It

Run:

```sh
make demo-smoke
```

The wrapper delegates to `scripts/demo/adoption_smoke.py`, which remains the black-box OAuth/OIDC proof. It checks discovery, JWKS, anonymous admin login redirect, operator admin access, non-operator denial, authorization code + PKCE, device authorization, userinfo, and the protected demo API.

The explicit smoke commands remain:

```sh
scripts/demo/adoption_smoke.sh
LOCKSPIRE_DEMO_BASE_URL=http://lockspire-demo.localhost scripts/demo/adoption_smoke.sh
LOCKSPIRE_DEMO_BASE_URL=http://127.0.0.1:4101 scripts/demo/adoption_smoke.sh
```

Expected success:

```text
adoption demo smoke passed
```

## Many Local Demos

Use hostname mode when running multiple local UI demos. It avoids app-specific host ports by routing through one shared Traefik proxy and keeps project resources isolated through `COMPOSE_PROJECT_NAME`.

If a shared local Traefik is already running, attach Lockspire to that proxy network instead of starting another proxy:

```sh
LOCKSPIRE_DEMO_TRAEFIK_NETWORK=proxy \
  examples/adoption_demo/bin/docker-up --no-proxy-start --host lockspire-demo.localhost
```

For another Lockspire demo instance, use a distinct project and hostname:

```sh
COMPOSE_PROJECT_NAME=lockspire-adoption-demo-alt \
  scripts/demo/admin-ui up --host lockspire-alt.localhost
```

Direct mode is still useful when you intentionally do not want a proxy:

```sh
examples/adoption_demo/bin/docker-up --direct --port 4101 --project lockspire-adoption-demo-alt
```

Use the same project name for follow-up commands:

```sh
scripts/demo/admin-ui --project lockspire-adoption-demo-alt stop
scripts/demo/admin-ui --project lockspire-adoption-demo-alt reset
scripts/demo/admin-ui --project lockspire-adoption-demo-alt cleanup
```

## Environment Overrides

Most maintainers should use `make demo`. These variables exist for explicit Compose and troubleshooting workflows:

| Variable | Default | Purpose |
| --- | --- | --- |
| `COMPOSE_PROJECT_NAME` | `lockspire-adoption-demo` | Compose project namespace for containers, networks, and volumes. |
| `LOCKSPIRE_DEMO_APP_PORT` | `4100` | Direct localhost port in direct mode; internal Phoenix container port in Traefik mode. It is not the browser URL in hostname mode. |
| `LOCKSPIRE_DEMO_BASE_URL` | mode-specific | Browser-visible public URL truth for issuer, redirects, startup output, docs, and smoke. |
| `LOCKSPIRE_DEMO_DB_HOST_PORT` | unset | Required only when using the DB host-port override. |
| `LOCKSPIRE_DEMO_TRAEFIK_HOST` | `lockspire-demo.localhost` | Hostname routed to the demo. |
| `LOCKSPIRE_DEMO_TRAEFIK_ROUTER` | project name from launcher | Traefik router label name. |
| `LOCKSPIRE_DEMO_TRAEFIK_SERVICE` | project name from launcher | Traefik service label name. |
| `LOCKSPIRE_DEMO_TRAEFIK_NETWORK` | `local-dev-proxy` | Shared external Docker network for local hostname routing. |

## Advanced Docker Details

The launcher starts or reuses the repo-local Traefik helper by default. If another Docker Traefik already owns `127.0.0.1:80` or `127.0.0.1:8080`, the launcher auto-reuses a compatible existing Docker Traefik when it can identify exactly one proxy network.

The repo-local Traefik helper is defined in `tools/traefik/docker-compose.yml`.

The Traefik override uses `examples/adoption_demo/docker-compose.traefik.yml`. In hostname mode it removes the app's direct host-port publishing and routes by `LOCKSPIRE_DEMO_TRAEFIK_HOST`.

If hostname routing reports a missing network, create it idempotently:

```sh
docker network inspect "${LOCKSPIRE_DEMO_TRAEFIK_NETWORK:-local-dev-proxy}" >/dev/null 2>&1 || \
  docker network create "${LOCKSPIRE_DEMO_TRAEFIK_NETWORK:-local-dev-proxy}"
```

If another proxy owns port 80/8080 and auto-detection is ambiguous, run Lockspire on that proxy's Docker network:

```sh
LOCKSPIRE_DEMO_TRAEFIK_NETWORK=proxy examples/adoption_demo/bin/docker-up --no-proxy-start --host lockspire-demo.localhost
```

The raw Compose command remains available for maintainers who want no launcher logic:

```sh
docker compose -f examples/adoption_demo/docker-compose.yml up --build
```

Direct app publishing is loopback-only. It does not expose the demo on every host interface.

PostgreSQL stays internal-only by default. To inspect it from host tools, opt in with the DB host override and choose a host port:

```sh
LOCKSPIRE_DEMO_DB_HOST_PORT=15432 \
docker compose -f examples/adoption_demo/docker-compose.yml \
  -f examples/adoption_demo/docker-compose.db-host.yml up --build
```

The app still talks to PostgreSQL on the internal Compose service port `5432`.

## Cleanup Boundary

Cleanup removes only:

- active-project Docker volumes named `db_data`, `deps_volume`, and `build_volume`;
- `tmp/adoption_demo.log`;
- `examples/adoption_demo/_build`;
- `examples/adoption_demo/deps`.

`tmp/admin-ui-polish/` is preserved by default. Cleanup does not delete broad `tmp/`, unrelated ignored files, unrelated Docker resources, or host-wide Docker state. It never uses host-wide Docker prune commands or broad Compose volume deletion.

If project containers still exist, cleanup refuses to run and prints the matching stop command.

## Repo Hygiene

After stopping and cleaning up, check local demo state:

```sh
./scripts/maintainer/repo_hygiene_check.sh --project lockspire-adoption-demo --skip-mix-ci
```

CI source contracts use:

```sh
./scripts/maintainer/repo_hygiene_check.sh --ci
```

CI keeps the existing Python smoke proof plus deterministic Docker validation. It does not run the full Docker Compose lifecycle.

Local hygiene reports adoption-demo Docker leftovers and generated artifacts with `PASS`, `WARN`, and `BLOCK` findings. Running active-project demo containers are `BLOCK` findings because the demo lifecycle is unfinished.

The intended local lifecycle is start -> smoke -> stop -> cleanup -> hygiene:

```sh
make demo
make demo-smoke
make demo-stop
make demo-clean-execute
./scripts/maintainer/repo_hygiene_check.sh --project lockspire-adoption-demo --skip-mix-ci
```

After cleanup, hygiene should report no demo-owned `BLOCK` findings. Broader checks can still report unrelated repo state, such as a dirty working tree or external CI status.

## Run It Host-Local

Host-local Mix/Postgres remains a fallback for maintainers who intentionally want to run outside Docker.

From the repo root:

```sh
cd examples/adoption_demo
mix deps.get
mix ecto.setup
mix phx.server
```

Then open the host-local URL printed by Phoenix, usually `http://127.0.0.1:4100` when no other local demo owns that port.

## Troubleshooting

### Port Conflict

If `http://127.0.0.1:4100` shows another project, you are looking at a direct localhost port owned by that project. For normal Lockspire UI review, use hostname routing:

```sh
make demo
```

Open:

```text
http://lockspire-demo.localhost/lockspire/admin
```

If a shared Traefik already owns ports `80` and `8080`, attach to its Docker network:

```sh
LOCKSPIRE_DEMO_TRAEFIK_NETWORK=proxy \
  examples/adoption_demo/bin/docker-up --no-proxy-start --host lockspire-demo.localhost
```

For direct mode, let the launcher pick the next available port and use only the URL it prints:

```sh
examples/adoption_demo/bin/docker-up --direct
```

If you need an explicit port:

```sh
examples/adoption_demo/bin/docker-up --direct --port 4101 --project lockspire-adoption-demo-alt
```

For many demos at once, use hostname mode:

```sh
examples/adoption_demo/bin/docker-up --host lockspire-demo.localhost
```

### Readiness Failure

The Docker entrypoint waits for PostgreSQL, prepares the database idempotently, starts Phoenix/Bandit, and waits for the container-local `LOCKSPIRE_DEMO_READINESS_URL` defaulting to `http://127.0.0.1:${PORT}`. `LOCKSPIRE_DEMO_BASE_URL` remains the public issuer/browser URL printed in startup output and used by the smoke wrapper.

Check logs:

```sh
make demo-logs
```

Then reprint expected URLs after the service is healthy:

```sh
make demo-info
```

### Traefik Network

Direct Docker mode does not require the Traefik network. Hostname routing uses `LOCKSPIRE_DEMO_TRAEFIK_NETWORK`.

The preferred multi-project setup is one shared local Traefik bound to `127.0.0.1:80`, with each project attached to the proxy network and routed by a unique `*.localhost` hostname. Lockspire exposes only the `web` service to that network; PostgreSQL stays project-internal.

### Traefik Ports

The helper uses `127.0.0.1:80` and `127.0.0.1:8080`. If those are already owned by your shared local proxy, the launcher auto-reuses a compatible existing Docker Traefik when it can infer one network. If it cannot choose safely, pass the proxy network explicitly:

```sh
LOCKSPIRE_DEMO_TRAEFIK_NETWORK=proxy examples/adoption_demo/bin/docker-up --no-proxy-start --host lockspire-demo.localhost
```

If you do not want a proxy, use:

```sh
examples/adoption_demo/bin/docker-up --direct --port 4101
```

### Base URL Drift

If startup output, issuer, redirects, and smoke target disagree, align `LOCKSPIRE_DEMO_BASE_URL` with the URL you type into the browser. For direct Docker it should match the selected host port, such as `http://127.0.0.1:4101`. For Traefik it should use the hostname origin, such as `http://lockspire-demo.localhost`.
