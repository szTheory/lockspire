# Adoption demo

Lockspire includes a small Phoenix host app at `examples/adoption_demo`.

The demo is not a new product surface or Hex package content. It is a repo-local adopter proof that boots a representative SaaS host, mounts Lockspire, seeds realistic OAuth clients, and exercises the library over HTTP.

## What it proves

- OIDC discovery and JWKS publish from a mounted embedded Lockspire provider.
- Host-owned login, account resolution, claims, and consent handoff for authorization code + PKCE.
- Host-guarded operator access to the Lockspire admin router.
- Device authorization approval through a host-owned `/verify` page.
- Issued-token behavior through Lockspire `userinfo`, plus protected-route rejection for an anonymous host API request.

The canonical support contract still lives in `docs/supported-surface.md`; the demo is an executable confidence check for adoption DX.

## Run it with Docker

Docker is the default maintainer path. It starts the Phoenix/Bandit demo and PostgreSQL without relying on host Postgres.

From the repo root:

```sh
docker compose -f examples/adoption_demo/docker-compose.yml up --build
```

When the app is ready, open `http://127.0.0.1:4100`.

## Startup output

After HTTP readiness succeeds, startup prints the same information as `examples/adoption_demo/bin/docker-info`:

- the active base URL, issuer, discovery, JWKS, admin, device verification, developer apps, OAuth callback, and protected API URLs;
- safe seeded account and OAuth client shapes;
- the direct smoke command for the active public URL;
- the reprint command for a running Docker service.

`LOCKSPIRE_DEMO_BASE_URL is the single public URL truth` for the printed URLs, Phoenix endpoint URL, Lockspire issuer, seeded local URLs, docs examples, and smoke proof. Keep it aligned with the URL you use in the browser.

To reprint the banner without recreating containers:

```sh
docker compose -f examples/adoption_demo/docker-compose.yml exec web ./bin/docker-info
```

## Run the smoke

Use the thin shell wrapper for maintainer smoke checks:

```sh
LOCKSPIRE_DEMO_BASE_URL=http://127.0.0.1:4100 scripts/demo/adoption_smoke.sh
```

The wrapper prints the active target and delegates to `scripts/demo/adoption_smoke.py`, which remains the black-box OAuth/OIDC proof. The Python smoke waits for the server, drives browser-like cookies through login and consent, exchanges real tokens, approves a device-code request, and calls the protected demo API. CI runs the Python proof in the `Adoption Demo Smoke` job.

## Stop the demo

Stop containers without deleting project volumes:

```sh
docker compose -f examples/adoption_demo/docker-compose.yml down
```

Use this when you want to keep the demo database, Mix deps, and build cache for the next run.

## Reset demo volumes

To reset only this demo project's database and container build caches:

```sh
examples/adoption_demo/bin/docker-reset
```

For a named project, pass the same project name used at startup:

```sh
examples/adoption_demo/bin/docker-reset --project lockspire-adoption-demo-alt
```

The reset helper removes only the active project's `db_data`, `deps_volume`, and `build_volume` Docker volumes. It does not run broad Docker prune commands.

## Cleanup boundary

Phase 115 owns broader cleanup and hygiene commands for generated demo artifacts, Docker leftovers, and dirty local state. Phase 114 documents the boundary only: use `docker compose ... down` for stop, `examples/adoption_demo/bin/docker-reset` for active-project demo volumes, and avoid broad cleanup commands unless Phase 115 adds and verifies them.

## Environment overrides

| Variable | Default | Purpose |
| --- | --- | --- |
| `COMPOSE_PROJECT_NAME` | `lockspire-adoption-demo` from Compose file | Isolates container, network, and volume names when multiple checkouts run side by side. |
| `LOCKSPIRE_DEMO_APP_PORT` | `4100` | Host and container HTTP port for direct Docker mode. |
| `LOCKSPIRE_DEMO_BASE_URL` | `http://127.0.0.1:${LOCKSPIRE_DEMO_APP_PORT:-4100}` | Browser-visible public URL truth for endpoint generation, issuer, startup output, docs, and smoke. |
| `LOCKSPIRE_DEMO_DB_HOST_PORT` | `5432` in the DB-host override | Optional host port for PostgreSQL inspection when `docker-compose.db-host.yml` is used. |
| `LOCKSPIRE_DEMO_TRAEFIK_HOST` | `lockspire-demo.localhost` | Hostname used by the optional Traefik router. |
| `LOCKSPIRE_DEMO_TRAEFIK_ROUTER` | `lockspire-adoption-demo` | Optional Traefik router label name. |
| `LOCKSPIRE_DEMO_TRAEFIK_SERVICE` | `lockspire-adoption-demo` | Optional Traefik service label name. |
| `LOCKSPIRE_DEMO_TRAEFIK_NETWORK` | `local-dev-proxy` | External Docker network used only by the Traefik override. |

The default Compose project is `lockspire-adoption-demo`. To run a second checkout beside it, use Docker Compose's standard project controls:

```sh
COMPOSE_PROJECT_NAME=lockspire-adoption-demo-alt docker compose -f examples/adoption_demo/docker-compose.yml up --build
```

or:

```sh
docker compose --project-name lockspire-adoption-demo-alt -f examples/adoption_demo/docker-compose.yml up --build
```

The direct Docker port is configurable. Keep `LOCKSPIRE_DEMO_BASE_URL` aligned with the browser-visible URL:

```sh
LOCKSPIRE_DEMO_APP_PORT=4101 \
LOCKSPIRE_DEMO_BASE_URL=http://127.0.0.1:4101 \
docker compose -f examples/adoption_demo/docker-compose.yml up --build
```

For that alternate port, run the smoke with the same browser-visible base URL:

```sh
LOCKSPIRE_DEMO_BASE_URL=http://127.0.0.1:4101 scripts/demo/adoption_smoke.sh
```

PostgreSQL stays internal-only by default. To inspect it from host tools, opt in with the DB host override and choose a host port:

```sh
LOCKSPIRE_DEMO_DB_HOST_PORT=15432 \
docker compose -f examples/adoption_demo/docker-compose.yml \
  -f examples/adoption_demo/docker-compose.db-host.yml up --build
```

The app still talks to PostgreSQL on the internal Compose service port `5432`.

## Optional Traefik hostname

Traefik hostname routing is optional. The default Docker command above does not need Traefik or an external proxy network.

If you already use the repo-local Traefik helper, create or reuse the shared external network:

```sh
docker network create "${LOCKSPIRE_DEMO_TRAEFIK_NETWORK:-local-dev-proxy}"
```

Start the helper in one shell:

```sh
docker compose -f tools/traefik/docker-compose.yml up --build
```

Then start the demo with the explicit Traefik override and pass the hostname origin through `LOCKSPIRE_DEMO_BASE_URL`:

```sh
LOCKSPIRE_DEMO_BASE_URL=http://lockspire-demo.localhost \
docker compose -f examples/adoption_demo/docker-compose.yml \
  -f examples/adoption_demo/docker-compose.traefik.yml up --build
```

The Traefik override attaches only the `web` service to the external proxy network. PostgreSQL stays on the project-internal network.

Run the smoke against the same hostname origin:

```sh
LOCKSPIRE_DEMO_BASE_URL=http://lockspire-demo.localhost scripts/demo/adoption_smoke.sh
```

## Run it host-local

Host-local Mix/Postgres remains a fallback for maintainers who intentionally want to run outside Docker.

From the repo root:

```sh
cd examples/adoption_demo
mix deps.get
mix ecto.setup
mix phx.server
```

Then open `http://127.0.0.1:4100`.

Seeded demo accounts:

| Login | Role | Account |
| --- | --- | --- |
| `alice` | SaaS user | `alice@acme.test` |
| `bob` | SaaS user | `bob@globex.test` |
| `ops` | Operator | `ops@acme.test` |

Seeded OAuth clients:

| Client ID | Shape |
| --- | --- |
| `acme-ledger-public` | Authorization code + PKCE public client |
| `acme-tv-device` | Device authorization client |
| `acme-ledger-backend` | Confidential backend client with `client_secret_basic` |

## Troubleshooting

### Port conflict

If `4100` is already in use, choose a different direct port and set the matching browser-visible base URL:

```sh
LOCKSPIRE_DEMO_APP_PORT=4101 \
LOCKSPIRE_DEMO_BASE_URL=http://127.0.0.1:4101 \
docker compose -f examples/adoption_demo/docker-compose.yml up --build
```

Use a different `COMPOSE_PROJECT_NAME` when another checkout is already using the default project resources.

### Readiness failure

The Docker entrypoint waits for PostgreSQL, prepares the database idempotently, starts Phoenix/Bandit, and waits for the configured `LOCKSPIRE_DEMO_BASE_URL`. If readiness fails, check the container logs and confirm the base URL resolves from the host:

```sh
docker compose -f examples/adoption_demo/docker-compose.yml logs web
```

Then reprint the expected URLs after the service is healthy:

```sh
docker compose -f examples/adoption_demo/docker-compose.yml exec web ./bin/docker-info
```

### Traefik network

If the Traefik override fails with a missing network error, create the external network named by `LOCKSPIRE_DEMO_TRAEFIK_NETWORK` before starting the demo:

```sh
docker network create "${LOCKSPIRE_DEMO_TRAEFIK_NETWORK:-local-dev-proxy}"
```

Direct Docker mode does not require this network.

### Base URL drift

If startup output, issuer, redirects, and smoke target disagree, align `LOCKSPIRE_DEMO_BASE_URL` with the URL you type into the browser. For direct Docker it should usually match the selected host port, such as `http://127.0.0.1:4101`. For optional Traefik it should use the hostname origin, such as `http://lockspire-demo.localhost`.
