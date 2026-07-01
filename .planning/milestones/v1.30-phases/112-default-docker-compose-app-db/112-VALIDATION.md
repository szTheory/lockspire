# Phase 112: Default Docker Compose App + DB - Validation

## Validation Architecture

### V-01 Compose Contract

Verify the default Compose file is self-contained for the adoption demo:

- `docker compose -f examples/adoption_demo/docker-compose.yml config` exits 0.
- The rendered config contains `web:` and `db:`.
- The rendered config contains a Postgres 14+ image.
- The rendered config contains a `pg_isready` healthcheck.
- The rendered config contains named volumes for database data, demo deps, and demo build artifacts.
- The rendered config does not contain `5432:5432`.

### V-02 Database Wiring

Verify the web service receives explicit database env:

- `LOCKSPIRE_DEMO_DB_HOST=db`
- `LOCKSPIRE_DEMO_DB_PORT=5432`
- `LOCKSPIRE_DEMO_DB_NAME=lockspire_adoption_demo`
- `LOCKSPIRE_DEMO_DB_USER=lockspire`
- `LOCKSPIRE_DEMO_DB_PASSWORD=lockspire`

### V-03 Startup Readiness

Verify startup owns setup and readiness:

- Startup script waits for Postgres before database commands.
- Startup tolerates an already-created database.
- Startup runs migrations from `../../priv/repo/migrations`.
- Startup runs `priv/repo/seeds.exs`.
- Startup starts Phoenix and waits for HTTP 200 at `LOCKSPIRE_DEMO_BASE_URL` before printing readiness.

### V-04 Boundary

Verify Phase 112 does not absorb later phases:

- No required Traefik external network in the default path.
- No cleanup/reset lane.
- No full URL/account/client banner.
- No production image or release packaging.
- No OAuth/OIDC protocol module changes.
