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

From the repo root:

```sh
docker compose -f examples/adoption_demo/docker-compose.yml up --build
```

This starts the Phoenix/Bandit demo and PostgreSQL for the repo-local adoption demo. Then open `http://127.0.0.1:4100`.

The default Compose project is `lockspire-adoption-demo`. To run a second checkout
beside it, use Docker Compose's standard project controls:

```sh
COMPOSE_PROJECT_NAME=lockspire-adoption-demo-alt docker compose -f examples/adoption_demo/docker-compose.yml up --build
```

or:

```sh
docker compose --project-name lockspire-adoption-demo-alt -f examples/adoption_demo/docker-compose.yml up --build
```

The direct Docker port is configurable. Keep `LOCKSPIRE_DEMO_BASE_URL` aligned
with the browser-visible URL; it is the URL truth for endpoint generation,
Lockspire issuer, docs examples, and smoke proof.

```sh
LOCKSPIRE_DEMO_APP_PORT=4101 \
LOCKSPIRE_DEMO_BASE_URL=http://127.0.0.1:4101 \
docker compose -f examples/adoption_demo/docker-compose.yml up --build
```

For that alternate port, run the smoke with the same browser-visible base URL:

```sh
LOCKSPIRE_DEMO_BASE_URL=http://127.0.0.1:4101 python3 scripts/demo/adoption_smoke.py
```

PostgreSQL stays internal-only by default. To inspect it from host tools, opt in
with the DB host override and choose a host port:

```sh
LOCKSPIRE_DEMO_DB_HOST_PORT=15432 \
docker compose -f examples/adoption_demo/docker-compose.yml \
  -f examples/adoption_demo/docker-compose.db-host.yml up --build
```

The app still talks to PostgreSQL on the internal Compose service port `5432`.

To reset only this demo project's database and container build caches, run:

```sh
examples/adoption_demo/bin/docker-reset
```

For a named project, pass the same project name used at startup:

```sh
examples/adoption_demo/bin/docker-reset --project lockspire-adoption-demo-alt
```

The reset helper removes only the active project's `db_data`, `deps_volume`, and
`build_volume` Docker volumes.

## Run it host-local

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

## Run the black-box smoke

Start the demo server, then run:

```sh
python3 scripts/demo/adoption_smoke.py
```

The script waits for the server, drives browser-like cookies through login and consent, exchanges real tokens, approves a device-code request, and calls the protected demo API. CI runs the same smoke in the `Adoption Demo Smoke` job.
