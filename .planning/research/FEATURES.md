# Feature Landscape

**Domain:** Repo-local Phoenix adoption demo Docker/developer experience and hygiene
**Project:** Lockspire v1.30 Adoption Demo Docker DX & Repo Hygiene
**Researched:** 2026-06-04
**Overall confidence:** HIGH for repo-grounded recommendations; MEDIUM for Docker/Traefik ergonomics because implementation details should be revalidated during planning.

## Executive Recommendation

v1.30 should require one boring default path: from the Lockspire repo root, a maintainer can start the adoption demo with Docker, get a seeded database and Phoenix app without host Postgres, see the useful URLs/accounts/routes/smoke command in the terminal, run the existing black-box smoke against the printed base URL, and tear everything down without leaving the repo dirty. This is adoption-demo DX only; do not add OAuth/OIDC protocol surface or broaden the embedded-library boundary.

The most important product behavior is not "Docker exists"; it is "the demo tells the maintainer exactly what is running and how to prove it." Current docs still lead with manual `mix deps.get`, `mix ecto.setup`, and `mix phx.server`; the existing compose file exposes only the app service through an external Traefik network and does not define Postgres. Current config can read DB env vars and `PORT`, while the smoke script can target `LOCKSPIRE_DEMO_BASE_URL`. That is enough foundation for a testable v1.30 slice, but the canonical entrypoint, readiness, seeded-truth output, cleanup, and hygiene contracts need to be explicit.

Make conflict handling a first-class requirement. The maintainer's problem is running several local Elixir OSS libraries with admin UIs at once. The default lane should avoid hard-coded global names and fixed host ports where practical, and it should surface exact commands/env vars for project name, app port, Postgres port, and optional Traefik hostname routing. Traefik should be optional, not required for the default path.

## Table Stakes

Features users expect. Missing = v1.30 has not solved the stated milestone.

| Feature | Why Expected | Complexity | Testable Requirement |
|---------|--------------|------------|----------------------|
| Repo-root demo launcher | The current documented path requires source-diving into `examples/adoption_demo` and manual host setup. | Medium | A single repo-root command starts the adoption demo app and database dependencies and exits non-zero with actionable text when Docker is unavailable. |
| Compose-managed Postgres | The milestone explicitly says the default Docker path must not rely on host Postgres. | Medium | `docker compose` for the demo includes a Postgres service, healthcheck, persistent named volume, and app DB env wiring; no local `PGHOST=localhost` dependency is needed. |
| App readiness gate | Phoenix can start before dependencies, migrations, or seeds are actually usable. | Medium | Startup waits for Postgres health, runs create/migrate/seed idempotently, then waits for HTTP 200 on `/` before printing "ready". |
| Idempotent seed/reset behavior | Demo users need repeatable seeded accounts and clients without manual DB surgery. | Medium | Re-running the launcher after a previous run leaves the same seeded accounts, OAuth clients, signing keys, and admin routes usable; reset path intentionally rebuilds the DB. |
| Printed base URLs | Maintainers should not infer ports, hostnames, or mount paths from config. | Low | Successful startup prints the active base URL, issuer URL, discovery URL, JWKS URL, admin URL, verify URL, developer apps URL, OAuth callback URL, protected API URL, and Traefik URL when enabled. |
| Printed seeded accounts | `seeds.exs` defines `alice`, `bob`, and `ops`; docs already list them. The terminal should be the source of immediate demo truth. | Low | Startup output lists `alice`, `bob`, and `ops` with roles and account emails, and identifies `ops` as the operator account for `/lockspire/admin`. |
| Printed seeded OAuth clients | The smoke and docs depend on stable demo clients. | Low | Startup output lists at least `acme-ledger-public`, `acme-tv-device`, `acme-ledger-backend`, and whether each is public/confidential/device/backend oriented; confidential demo secrets are named only when safe and explicitly demo-only. |
| Printed smoke command | The existing black-box smoke is the best "prove it works" affordance. | Low | Startup output prints the exact `LOCKSPIRE_DEMO_BASE_URL=... python3 scripts/demo/adoption_smoke.py` command for the active URL. |
| Smoke script URL compatibility | Conflict-resistant ports and hostnames require smoke to follow the printed base URL. | Low | Smoke passes when `LOCKSPIRE_DEMO_BASE_URL` is set to the direct Docker port URL and when set to the optional Traefik hostname URL. |
| Port conflict handling | Running many local Phoenix admin UIs makes fixed `4100`, `5432`, `80`, or `8080` bindings fragile. | Medium | Demo supports env-configurable project name, app host port, Postgres host port if exposed, and Traefik hostname; startup detects occupied required ports before compose up or prints the alternate command. |
| Optional Traefik lane | Existing repo has `tools/traefik/docker-compose.yml`; user explicitly wants optional Traefik. | Medium | Default demo works without Traefik. A documented optional command joins a Traefik network and serves `http://adoption-demo.localhost` or an env-configured hostname. |
| Compose project isolation | Docker resource names collide across repos if project names are hard-coded. | Low | All demo commands accept `COMPOSE_PROJECT_NAME` or a Lockspire-specific wrapper env var and use it consistently for containers, networks, and volumes. |
| Cleanup lane | The milestone asks for cleanup of generated demo artifacts, Docker leftovers, and dirty local state. | Medium | A repo-root cleanup command stops/removes demo containers and optionally volumes/build artifacts, without deleting unrelated user files or other projects' Docker resources. |
| Repo hygiene gate integration | Existing `repo_hygiene_check.sh` already blocks dirty release prep but does not know about demo leftovers. | Medium | Hygiene reports demo Docker leftovers, generated adoption-demo artifacts, stale screenshots/logs under repo-owned temp paths, and dirty tracked state using PASS/WARN/BLOCK levels. |
| Clean repo after demo proof | The next admin UI pass needs a clean base. | Medium | Running start, smoke, stop, cleanup, and hygiene in sequence leaves `git status --porcelain` clean except for pre-existing unrelated user files. |
| Docs as executable handoff | Current `docs/adoption-demo.md` is accurate for manual start, but v1.30 needs the Docker lane to be the canonical maintainer path. | Low | Docs include the default Docker start, optional Traefik start, smoke, stop, reset, cleanup, env override table, and troubleshooting for port conflicts/readiness failures. |

## Differentiators

Nice-to-have within v1.30 only if table stakes are already stable.

| Feature | Value Proposition | Complexity | Testable Requirement |
|---------|-------------------|------------|----------------------|
| `--print` or `info` command | Lets maintainers recover URLs/accounts/routes after the demo is already running. | Low | Command prints the same URL/account/client/smoke block without recreating containers. |
| Structured readiness JSON | Helps future automation consume the active URL and smoke command without scraping text. | Medium | Optional `--json` emits base URL, endpoints, accounts, clients, compose project, and smoke command. |
| Direct admin route inventory | Helps UI polish passes jump to relevant admin pages. | Low | Output includes core admin routes: overview, clients, policies, DCR/IAT, support tokens, support consents, operations queues, keys, and client detail seed examples. |
| Preflight doctor | Reduces failed startup loops from missing Docker, unavailable Traefik network, or occupied ports. | Medium | `doctor` command checks Docker daemon, compose plugin, required files, chosen ports, external Traefik network when requested, and DB volume ownership before startup. |
| Smoke wrapper | Avoids remembering Python invocation and base URL env var. | Low | Repo-root command runs the existing smoke against the active demo URL and preserves the smoke script's failure details. |
| Log tail helper | Shortens diagnosis when Phoenix or DB readiness fails. | Low | Command tails app and DB logs scoped to the active compose project. |

## Future Work

Valuable later, but do not make v1.30 depend on them.

| Feature | Why Defer | What to Do Instead |
|---------|-----------|-------------------|
| Full local development platform across all Elixir OSS libraries | Requires cross-repo conventions and may overfit Lockspire's repo. | Make Lockspire configurable and collision-resistant; document env vars other repos can mirror. |
| Required Traefik for all demo traffic | Adds Docker socket and port 80 assumptions, and makes the simplest path more fragile. | Keep Traefik optional and default to direct localhost port routing. |
| Browser automation screenshots in startup | Startup should be fast and deterministic; screenshot proof belongs to UI polish phases. | Print URLs and keep the black-box smoke as the required functional proof. |
| New admin UI polish | The milestone explicitly prepares the base for the next polish pass. | Only expose and document existing routes/states seeded by the demo. |
| New protocol flows or clients | Scope is adoption demo DX, not OAuth/OIDC breadth. | Use existing authorization code + PKCE, device flow, userinfo, discovery, JWKS, and protected API smoke. |
| Production Docker packaging | Adoption demo is repo-local proof, not Hex package or deployment surface. | Keep Docker assets under demo/tools paths and label docs as local maintainer/demo only. |

## Anti-Features

Features to explicitly not build for v1.30.

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| Adding SAML, LDAP, hosted auth, or CIAM behavior | Violates Lockspire's v1 boundary and has no relationship to demo startup friction. | Preserve protocol surface; improve only the existing demo workflows. |
| Making the demo a required standalone auth service | Conflicts with the embedded Phoenix library value proposition. | Keep the demo as a representative host app that mounts Lockspire. |
| Hard-coded global Docker names | Causes exactly the port/name collision pain this milestone exists to remove. | Parameterize compose project, service names via compose, ports, and hostnames. |
| Always binding Postgres to host `5432` | Collides with host Postgres and other demos. | Prefer internal compose networking; expose DB port only when explicitly requested and configurable. |
| Cleanup that deletes broad Docker resources | Maintainers may run several repos at once. | Scope cleanup by compose project name and repo-owned artifact paths only. |
| Storing real secrets or normalizing demo secrets as production guidance | Demo credentials are intentionally fake and copy-once semantics matter elsewhere. | Mark any printed secret as demo-only; keep redaction posture in operator surfaces. |
| Silencing smoke failures behind a wrapper | The smoke script's assertion labels are useful. | Preserve detailed failure output and add only URL/project context around it. |

## Feature Dependencies

```text
Compose-managed Postgres -> Readiness gate -> Printed ready output -> Smoke wrapper/docs
Configurable base URL/port/hostname -> Printed URLs -> Smoke URL compatibility
Seed/reset behavior -> Printed accounts/clients -> Admin route inventory -> UI polish readiness
Compose project isolation -> Cleanup lane -> Hygiene gate -> Clean repo proof
Optional Traefik network -> Traefik URL output -> Traefik smoke compatibility
```

## MVP Recommendation

Prioritize:

1. Default repo-root Docker startup with app + Postgres, migrations/seeds, readiness wait, and direct localhost URL.
2. Conflict-resistant configuration for compose project name, app port, DB exposure, base URL/issuer, and optional Traefik hostname.
3. Startup output that prints active URLs/routes, seeded accounts, seeded clients, and the exact smoke command.
4. Smoke compatibility and wrapper proof against the active base URL.
5. Stop/reset/cleanup commands scoped to the active compose project.
6. Hygiene gate additions for demo leftovers and dirty generated artifacts.
7. Docs updated so the Docker lane is canonical and manual `mix phx.server` is secondary.

Defer:

- Structured JSON output until plain text startup output is stable.
- Browser screenshot capture until the next admin UI polish milestone.
- Cross-repo Traefik conventions until Lockspire's own optional Traefik path is proven.

## Suggested Acceptance Criteria

Use these as roadmap-ready, testable requirements.

| ID | Requirement |
|----|-------------|
| DX-START-01 | From a clean checkout with Docker running, one documented repo-root command starts Postgres and the Phoenix adoption demo without host Postgres. |
| DX-START-02 | Startup performs dependency install/build as needed inside Docker volumes, creates/migrates/seeds the DB, waits for `/` to return 200, then prints a ready banner. |
| DX-START-03 | Re-running startup is idempotent and does not duplicate seed data or require manual DB cleanup. |
| DX-PRINT-01 | Ready output prints direct base URL, issuer, discovery, JWKS, admin, verify, developer apps, OAuth callback, protected API, and smoke command. |
| DX-PRINT-02 | Ready output prints seeded accounts `alice`, `bob`, and `ops` with roles/account emails and identifies the operator login for admin access. |
| DX-PRINT-03 | Ready output prints seeded client IDs and demo client shapes aligned with `seeds.exs` and `docs/adoption-demo.md`. |
| DX-CONFLICT-01 | App host port is configurable and smoke/docs use the configured base URL instead of assuming `127.0.0.1:4100`. |
| DX-CONFLICT-02 | Compose project name is configurable so multiple local library demos can run without container/network/volume name collisions. |
| DX-CONFLICT-03 | Postgres does not bind to host `5432` by default; any exposed DB port is opt-in and configurable. |
| DX-TRAEFIK-01 | Optional Traefik mode works only when requested and prints the hostname URL plus any required network/bootstrap command. |
| DX-SMOKE-01 | Existing `scripts/demo/adoption_smoke.py` passes against the direct Docker URL using `LOCKSPIRE_DEMO_BASE_URL`. |
| DX-SMOKE-02 | If Traefik mode is enabled, the same smoke passes against the Traefik hostname URL. |
| DX-CLEAN-01 | Stop command stops the demo without deleting volumes by default. |
| DX-CLEAN-02 | Reset command intentionally rebuilds the DB/seed state for the active compose project only. |
| DX-CLEAN-03 | Cleanup command removes demo containers/networks/volumes and repo-owned generated demo artifacts, scoped by project name and documented paths. |
| DX-HYGIENE-01 | `scripts/maintainer/repo_hygiene_check.sh` reports PASS/WARN/BLOCK for demo Docker leftovers and repo-owned generated artifacts. |
| DX-HYGIENE-02 | After start -> smoke -> stop -> cleanup, hygiene can pass without BLOCK from demo leftovers. |
| DX-DOCS-01 | `docs/adoption-demo.md` describes default Docker start, optional Traefik, smoke, stop, reset, cleanup, env overrides, and troubleshooting. |
| DX-BOUNDARY-01 | No new OAuth/OIDC protocol behavior, admin workflow behavior, or host seam behavior is introduced by the demo DX work. |

## Current Repo Signals

| Signal | Finding | Confidence |
|--------|---------|------------|
| `docs/adoption-demo.md` | Documents manual local `mix deps.get`, `mix ecto.setup`, `mix phx.server`, seeded accounts, seeded clients, and smoke command. It does not yet describe Docker as canonical. | HIGH |
| `examples/adoption_demo/docker-compose.yml` | Existing compose file defines only a `web` service, uses an external `local-dev-proxy` network, and labels Traefik for `adoption-demo.localhost`. It does not include Postgres or a direct default non-Traefik path. | HIGH |
| `examples/adoption_demo/Dockerfile.dev` | Installs build tooling and runs `mix deps.get && mix phx.server`; it does not run DB setup. | HIGH |
| `examples/adoption_demo/config/config.exs` | DB config already reads `LOCKSPIRE_DEMO_DB_*`, `PG*`, and defaults to localhost; endpoint reads `PORT` and `LOCKSPIRE_DEMO_HOST`; Lockspire issuer is currently hard-coded to `http://127.0.0.1:4100/lockspire`. | HIGH |
| `examples/adoption_demo/priv/repo/seeds.exs` | Seeds realistic clients, policy, signing keys, and admin proof states. Startup output should be generated from this truth or contract-tested against it. | HIGH |
| `scripts/demo/adoption_smoke.py` | Already waits for readiness and supports `LOCKSPIRE_DEMO_BASE_URL`; covers discovery, JWKS, admin access, authorization code + PKCE, userinfo, protected API, and device flow. | HIGH |
| `scripts/maintainer/repo_hygiene_check.sh` | Existing gate reports PASS/WARN/BLOCK for release-train truth, dirty worktree, worktrees, branches, PR/CI status, and `mix ci`; it does not yet check demo Docker leftovers or generated demo artifacts. | HIGH |
| Local working tree | Existing untracked `tmp/admin-ui-polish/*`, `tmp/adoption_demo.log`, and scratch `.exs` files show exactly why hygiene/cleanup should detect repo-owned generated artifacts. | HIGH |

## Sources

- `.planning/PROJECT.md` - v1.30 goal, target features, boundaries, and current milestone context. Confidence: HIGH.
- `.planning/MILESTONES.md` - v1.29 shipped admin UI proof and historical adoption-demo/admin route context. Confidence: HIGH.
- `docs/adoption-demo.md` - current demo user instructions, seeded accounts/clients, and smoke contract. Confidence: HIGH.
- `examples/adoption_demo/docker-compose.yml` - existing compose/Traefik shape. Confidence: HIGH.
- `examples/adoption_demo/Dockerfile.dev` - existing Docker app startup behavior. Confidence: HIGH.
- `tools/traefik/docker-compose.yml` - optional local Traefik service and external network expectation. Confidence: HIGH.
- `examples/adoption_demo/config/config.exs` - current DB/endpoint/issuer configurability. Confidence: HIGH.
- `examples/adoption_demo/priv/repo/seeds.exs` - seeded clients, keys, policy, and demo state matrix. Confidence: HIGH.
- `examples/adoption_demo/lib/adoption_demo_web/router.ex` - demo route inventory and admin/protected API mounts. Confidence: HIGH.
- `scripts/demo/adoption_smoke.py` - black-box readiness and protocol/admin smoke behavior. Confidence: HIGH.
- `scripts/maintainer/repo_hygiene_check.sh` - existing hygiene report contract and local gate behavior. Confidence: HIGH.
