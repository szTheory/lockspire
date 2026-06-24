# Phase 114: Startup Output, Smoke Wrapper & Docs - Research

**Researched:** 2026-06-24
**Domain:** Lockspire adoption-demo Docker DX, startup information, smoke proof, and maintainer docs
**Confidence:** HIGH

## User Constraints

No `114-CONTEXT.md` exists in `.planning/phases/114-startup-output-smoke-wrapper-docs`; research scope is constrained by `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`, `.planning/STATE.md`, prior phase artifacts, and AGENTS.md. [VERIFIED: codebase grep]

### Locked Decisions

- v1.30 is an adoption-demo Docker DX and repo-hygiene milestone, not a new protocol or admin UI polish milestone. [VERIFIED: .planning/STATE.md]
- Default local demo access is direct host-port Docker, with Traefik optional. [VERIFIED: .planning/STATE.md]
- `LOCKSPIRE_DEMO_BASE_URL` is the single public URL truth for endpoint URL, issuer, seeds, docs, startup output, and smoke proof. [VERIFIED: .planning/STATE.md]
- Phase 113 kept direct Docker as the default path, PostgreSQL host-port exposure absent by default, reset scoped to active-project volumes, and optional Traefik isolated in an override file. [VERIFIED: .planning/STATE.md]

### the agent's Discretion

- Choose the exact implementation shape for the startup info printer and smoke wrapper, as long as it stays repo-local, reuses the existing base URL contract, and preserves redaction. [VERIFIED: .planning/ROADMAP.md]

### Deferred Ideas

- Structured JSON readiness output, full Docker smoke in CI, production Docker release images, browser screenshot automation, and broader cross-repo proxy conventions are deferred or future work. [VERIFIED: .planning/REQUIREMENTS.md]

## Summary

Phase 114 should make the already-working adoption demo self-describing by extending the existing Docker startup path, not by changing OAuth/OIDC runtime behavior. [VERIFIED: examples/adoption_demo/bin/docker-start] The current `docker-start` script prepares the database, starts Phoenix, waits for HTTP readiness at `LOCKSPIRE_DEMO_BASE_URL`, and prints only `Adoption demo ready at ...`; this is the correct insertion point for a full, redacted info banner. [VERIFIED: examples/adoption_demo/bin/docker-start]

The planner should prescribe one reusable POSIX shell info script, for example `examples/adoption_demo/bin/docker-info`, that computes URLs from `LOCKSPIRE_DEMO_BASE_URL`, prints seeded accounts from the stable account fixture truth, prints safe client IDs/shapes from the seeded demo client truth, and prints the exact `LOCKSPIRE_DEMO_BASE_URL=... python3 scripts/demo/adoption_smoke.py` command. [VERIFIED: examples/adoption_demo/lib/adoption_demo/accounts.ex] [VERIFIED: examples/adoption_demo/priv/repo/seeds.exs] `docker-start` should call that script only after HTTP readiness succeeds, and maintainers should be able to reprint it in a running container with `docker compose exec web ./bin/docker-info` or host-locally by invoking the script with the same environment. [CITED: https://docs.docker.com/reference/cli/docker/compose/exec/]

**Primary recommendation:** Add a redacted reusable demo-info script, call it from `docker-start` after readiness, add a tiny smoke wrapper that delegates to the existing Python smoke with the active base URL, then expand `docs/adoption-demo.md` and contract tests around those stable strings. [VERIFIED: scripts/demo/adoption_smoke.py]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|--------------|----------------|-----------|
| Startup info banner | Docker / Local Tooling | Phoenix config truth | Startup is emitted by `examples/adoption_demo/bin/docker-start`; URL values must mirror Phoenix/Lockspire config derived from `LOCKSPIRE_DEMO_BASE_URL`. [VERIFIED: examples/adoption_demo/bin/docker-start] |
| Reprint current demo info | Docker / Local Tooling | Host shell fallback | Compose `exec` can run a command inside the existing `web` service, while host-local users can call the same script with env defaults. [CITED: https://docs.docker.com/reference/cli/docker/compose/exec/] |
| Smoke wrapper | Local Tooling | Python smoke script | The existing black-box proof is `scripts/demo/adoption_smoke.py`; wrappers should set/display `LOCKSPIRE_DEMO_BASE_URL` and delegate, not duplicate browser/token flow logic. [VERIFIED: scripts/demo/adoption_smoke.py] |
| Demo URL construction | Phoenix / Config | Docker env | `examples/adoption_demo/config/config.exs` parses `LOCKSPIRE_DEMO_BASE_URL`, stores `:demo_base_url`, and derives Endpoint `url` plus Lockspire issuer. [VERIFIED: examples/adoption_demo/config/config.exs] |
| Seeded account truth | Phoenix demo host | Startup script | `alice`, `bob`, and `ops` are hard-coded demo host accounts; `ops` has `operator?: true`. [VERIFIED: examples/adoption_demo/lib/adoption_demo/accounts.ex] |
| Seeded client truth | Lockspire storage seed data | Startup script | Seeded clients live in `priv/repo/seeds.exs`; startup output should print only IDs and shapes, not hashes or plaintext secrets. [VERIFIED: examples/adoption_demo/priv/repo/seeds.exs] |
| Maintainer docs | Documentation | Contract tests | `docs/adoption-demo.md` is already the adoption-demo human contract and is covered by `AdoptionDemoDockerContractTest`. [VERIFIED: docs/adoption-demo.md] [VERIFIED: test/lockspire/adoption_demo_docker_contract_test.exs] |

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| INFO-01 | Startup prints active base URL, issuer, discovery, JWKS, admin, verification, developer apps, callback, protected API, and exact smoke command. | Existing route inventory defines these paths; compute from `BASE_URL="${LOCKSPIRE_DEMO_BASE_URL:-http://127.0.0.1:4100}"` after trimming `/`. [VERIFIED: examples/adoption_demo/lib/adoption_demo_web/router.ex] |
| INFO-02 | Startup prints seeded accounts `alice`, `bob`, and `ops`, including roles/account emails and identifying `ops` as operator. | Account fixture has exact login/email/name/operator fields. [VERIFIED: examples/adoption_demo/lib/adoption_demo/accounts.ex] |
| INFO-03 | Startup prints seeded OAuth client IDs and demo shapes without exposing sensitive material. | Seed file includes safe IDs and auth shapes plus sensitive hashes/tokens/private JWK material that must not be printed. [VERIFIED: examples/adoption_demo/priv/repo/seeds.exs] |
| INFO-04 | Maintainer can reprint current information without recreating containers. | Docker Compose `exec` runs commands inside a running service; a reusable script enables reprint. [CITED: https://docs.docker.com/reference/cli/docker/compose/exec/] |
| SMOKE-01 | Existing smoke passes against direct Docker URL using `LOCKSPIRE_DEMO_BASE_URL`. | Phase 112 proved direct Docker smoke with `LOCKSPIRE_DEMO_BASE_URL=http://127.0.0.1:4100`. [VERIFIED: .planning/phases/112-default-docker-compose-app-db/112-02-SUMMARY.md] |
| SMOKE-02 | Optional Traefik mode uses the same smoke against the Traefik hostname URL. | Phase 113 docs and override route hostname mode through `LOCKSPIRE_DEMO_BASE_URL=http://lockspire-demo.localhost`. [VERIFIED: .planning/phases/113-conflict-controls-optional-traefik/113-02-SUMMARY.md] |
| DOCS-01 | Docs present Docker as default maintainer path with host-local fallback. | Current docs already have Docker first and host-local fallback; Phase 114 should expand and clarify. [VERIFIED: docs/adoption-demo.md] |
| DOCS-02 | Docs cover default startup, optional Traefik, smoke, stop, reset, cleanup, env overrides, troubleshooting. | Current docs cover startup, Traefik, smoke, reset, env overrides partially; stop, cleanup, and troubleshooting need expansion. [VERIFIED: docs/adoption-demo.md] |
</phase_requirements>

## Project Constraints (from AGENTS.md)

- Build Lockspire as a separate companion library, not a Sigra module. [VERIFIED: AGENTS.md]
- Preserve the embedded-library shape; do not turn this into a required standalone auth service. [VERIFIED: AGENTS.md]
- Keep strong internal boundaries between protocol core, storage, generators, Plug/Phoenix integration, and LiveView/admin surfaces. [VERIFIED: AGENTS.md]
- Treat the host seam as explicit and narrow: account resolution, claims, login redirects, branding, and product policy belong to the host app. [VERIFIED: AGENTS.md]
- Do not broaden v1 into SAML, LDAP/AD federation, hosted auth, or a full CIAM suite. [VERIFIED: AGENTS.md]
- Preserve security defaults: PKCE S256 required by default, exact redirect URI matching, hashed client secrets, short-lived single-use authorization codes, refresh token rotation, no implicit flow, no `alg=none`, and strong redaction. [VERIFIED: AGENTS.md]
- Use the project stack: Phoenix, Phoenix LiveView, Ecto SQL, PostgreSQL 14+, Bandit, Oban, and OpenTelemetry. [VERIFIED: AGENTS.md]

## Standard Stack

### Core

| Library / Tool | Version | Purpose | Why Standard |
|----------------|---------|---------|--------------|
| POSIX `sh` scripts | `/usr/bin/env sh` in existing scripts | Startup, info, reset, and wrapper commands | Existing demo scripts use portable `sh`, `set -eu`, bounded loops, and traps. [VERIFIED: examples/adoption_demo/bin/docker-start] |
| Docker Compose | local `v5.1.3`; existing files use Compose v2 syntax | Direct Docker and optional Traefik orchestration | `docker compose config` resolves/validates the model and existing tests already use it. [VERIFIED: test/lockspire/adoption_demo_docker_contract_test.exs] [CITED: https://docs.docker.com/reference/cli/docker/compose/config/] |
| Python standard library | local `3.14.4` | Existing black-box smoke proof | Smoke uses only stdlib modules such as `http.client`, `urllib.parse`, and `http.cookies`; do not add browser packages. [VERIFIED: scripts/demo/adoption_smoke.py] |
| Phoenix | lockfile `1.8.7`, constraint `~> 1.8.5` | Demo host app and endpoint URL config | Endpoint `:url` accepts scheme/host/port and current config derives it from `LOCKSPIRE_DEMO_BASE_URL`. [VERIFIED: mix.lock] [CITED: https://hexdocs.pm/phoenix/Phoenix.Endpoint.html] |
| Ecto SQL / PostgreSQL | `ecto_sql 3.13.5`, `postgres:14` image | Demo database setup and seed truth | Existing Compose uses internal PostgreSQL 14 and setup runs migrations plus seeds. [VERIFIED: mix.lock] [VERIFIED: examples/adoption_demo/docker-compose.yml] |

### Supporting

| Library / Tool | Version | Purpose | When to Use |
|----------------|---------|---------|-------------|
| `curl` | installed in demo image | HTTP readiness check | Keep in `docker-start` readiness loop; do not use it as smoke replacement. [VERIFIED: examples/adoption_demo/Dockerfile.dev] |
| `pg_isready` | installed through `postgresql-client` in demo image | DB readiness check | Keep before `mix ecto.create/migrate/seed`. [VERIFIED: examples/adoption_demo/bin/docker-start] |
| ExUnit + Jason | existing test deps | Compose/docs/source contract tests | Extend `Lockspire.AdoptionDemoDockerContractTest` for info script/docs/smoke-wrapper assertions. [VERIFIED: test/lockspire/adoption_demo_docker_contract_test.exs] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| POSIX shell info script | Mix task | Mix task can read Elixir fixtures directly, but it starts more application/config machinery; shell matches current Docker entrypoint and is enough for static safe output. [VERIFIED: examples/adoption_demo/bin/docker-start] |
| Existing Python smoke | Playwright/browser automation | Existing smoke already proves login, consent, token exchange, userinfo, protected API, and device flow; browser automation is deferred. [VERIFIED: scripts/demo/adoption_smoke.py] |
| Compose `exec` reprint | Restart container to see banner again | Restarting recreates startup conditions and violates INFO-04; `exec` targets a running service. [CITED: https://docs.docker.com/reference/cli/docker/compose/exec/] |

**Installation:**

```bash
# No new packages should be installed for Phase 114.
```

## Package Legitimacy Audit

No external packages should be installed in Phase 114. [VERIFIED: mix.exs] The planner should reject new npm, PyPI, Hex, or OS package additions unless the implementation discovers a hard blocker and reruns package legitimacy verification. [VERIFIED: .planning/REQUIREMENTS.md]

| Package | Registry | Age | Downloads | Source Repo | Verdict | Disposition |
|---------|----------|-----|-----------|-------------|---------|-------------|
| none | — | — | — | — | OK | No install needed |

**Packages removed due to [SLOP] verdict:** none
**Packages flagged as suspicious [SUS]:** none

## Architecture Patterns

### System Architecture Diagram

```text
Maintainer shell
  |
  | docker compose up / host-local mix phx.server
  v
examples/adoption_demo/bin/docker-start
  |
  | wait for PostgreSQL -> mix deps.get -> ecto.create/reuse -> migrate -> seed
  v
Start Phoenix/Bandit in background
  |
  | curl ${LOCKSPIRE_DEMO_BASE_URL}/ until ready
  v
examples/adoption_demo/bin/docker-info
  |
  | compute URLs from BASE_URL
  | read stable account/client truth embedded in script or generated from known fixtures
  | redact secrets/hashes/tokens/private keys
  v
Human-readable banner:
  URLs + accounts + clients + exact smoke command
  |
  +--> Maintainer runs scripts/demo/adoption_smoke.py with same BASE_URL
  |
  +--> Maintainer reprints through docker compose exec web ./bin/docker-info
```

### Recommended Project Structure

```text
examples/adoption_demo/
├── bin/
│   ├── docker-start       # existing DB/setup/readiness entrypoint; call info after readiness
│   ├── docker-info        # new redacted URL/account/client/smoke output
│   └── docker-reset       # existing active-project reset helper
├── docker-compose.yml     # existing direct Docker default
├── docker-compose.traefik.yml
└── priv/repo/seeds.exs    # seeded client truth; do not expose secret fields

scripts/demo/
├── adoption_smoke.py      # existing black-box proof
└── adoption_smoke.sh      # optional thin wrapper that prints/sets active base URL and delegates

docs/
└── adoption-demo.md       # Docker-first maintainer docs
```

### Pattern 1: Reusable Redacted Info Printer

**What:** Put all printable URLs/accounts/clients/smoke command in one script and call it from startup and reprint workflows. [VERIFIED: examples/adoption_demo/bin/docker-start]

**When to use:** Use after successful HTTP readiness and for `docker compose exec web ./bin/docker-info`. [CITED: https://docs.docker.com/reference/cli/docker/compose/exec/]

**Example:**

```sh
# Source: existing docker-start style and Docker Compose exec docs
BASE_URL="${LOCKSPIRE_DEMO_BASE_URL:-http://127.0.0.1:4100}"
BASE_URL="${BASE_URL%/}"

echo "Adoption demo ready"
echo "Base URL: ${BASE_URL}"
echo "Issuer: ${BASE_URL}/lockspire"
echo "Discovery: ${BASE_URL}/lockspire/.well-known/openid-configuration"
echo "JWKS: ${BASE_URL}/lockspire/jwks"
echo "Admin: ${BASE_URL}/lockspire/admin"
echo "Device verification: ${BASE_URL}/verify"
echo "Developer apps: ${BASE_URL}/developer/apps"
echo "OAuth callback: ${BASE_URL}/oauth/callback"
echo "Protected API: ${BASE_URL}/api/billing/summary"
echo "Smoke: LOCKSPIRE_DEMO_BASE_URL=${BASE_URL} python3 scripts/demo/adoption_smoke.py"
```

### Pattern 2: Static Redaction Allowlist

**What:** Print known-safe fields through an allowlist: login, role, email, client ID, client type, auth method, grant shape, PKCE requirement, and relevant demo purpose. [VERIFIED: examples/adoption_demo/lib/adoption_demo/accounts.ex] [VERIFIED: examples/adoption_demo/priv/repo/seeds.exs]

**When to use:** Use for startup output and docs tables. [VERIFIED: .planning/REQUIREMENTS.md]

**Example:**

```text
Accounts:
  alice  SaaS user   alice@acme.test
  bob    SaaS user   bob@globex.test
  ops    Operator    ops@acme.test  (operator account)

OAuth clients:
  acme-ledger-public   public, authorization_code + PKCE, token auth none
  acme-tv-device       public, device authorization, token auth none
  acme-ledger-backend  confidential, authorization_code + PKCE, client_secret_basic (secret not shown)
```

### Pattern 3: Wrapper Delegates To Existing Smoke

**What:** A smoke wrapper should compute/display the active base URL, then run `python3 scripts/demo/adoption_smoke.py`; it should not duplicate smoke internals. [VERIFIED: scripts/demo/adoption_smoke.py]

**When to use:** Use for maintainer ergonomics and exact startup output command. [VERIFIED: .planning/REQUIREMENTS.md]

**Example:**

```sh
# Source: existing smoke env contract
BASE_URL="${LOCKSPIRE_DEMO_BASE_URL:-http://127.0.0.1:4100}"
BASE_URL="${BASE_URL%/}"
echo "Running adoption demo smoke against ${BASE_URL}"
LOCKSPIRE_DEMO_BASE_URL="${BASE_URL}" python3 scripts/demo/adoption_smoke.py
```

### Anti-Patterns to Avoid

- **Printing seed stdout directly:** `seeds.exs` contains secret hashes, token hashes, private JWK storage, and demo plaintext secret inputs; startup should keep successful seed stdout suppressed and print only allowlisted info. [VERIFIED: examples/adoption_demo/priv/repo/seeds.exs]
- **Deriving URLs from `PORT`:** The public browser-visible origin is `LOCKSPIRE_DEMO_BASE_URL`, especially for Traefik hostname mode. [VERIFIED: examples/adoption_demo/docker-compose.yml] [VERIFIED: examples/adoption_demo/docker-compose.traefik.yml]
- **Adding protocol helpers for demo output:** Endpoint and issuer truth already exist in config; Phase 114 is local tooling/docs. [VERIFIED: examples/adoption_demo/config/config.exs]
- **Making Traefik required:** Optional Traefik remains behind `docker-compose.traefik.yml`; default Docker must stay direct. [VERIFIED: examples/adoption_demo/docker-compose.traefik.yml]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| OAuth/OIDC proof flow | New smoke engine or custom browser framework | Existing `scripts/demo/adoption_smoke.py` | It already proves discovery, JWKS, admin guard, auth code + PKCE, token exchange, userinfo, protected API, and device flow. [VERIFIED: scripts/demo/adoption_smoke.py] |
| Docker model validation | YAML string parser | `docker compose config --format json` in ExUnit | Compose docs say config merges files, resolves variables, and canonicalizes shorthand. [CITED: https://docs.docker.com/reference/cli/docker/compose/config/] |
| Reprint from running container | Container restart or log scraping | `docker compose exec web ./bin/docker-info` | Compose exec is designed to run commands in running services. [CITED: https://docs.docker.com/reference/cli/docker/compose/exec/] |
| URL truth | Separate issuer/discovery/callback config | `LOCKSPIRE_DEMO_BASE_URL` + path suffixes | Current config and smoke already use this single source. [VERIFIED: examples/adoption_demo/config/config.exs] |
| Secret redaction | Regex scrub over arbitrary seed output | Explicit safe allowlist | Seed data contains many sensitive field names and values; allowlist output is easier to verify. [VERIFIED: examples/adoption_demo/priv/repo/seeds.exs] |

**Key insight:** Phase 114 is an observability and proof wrapper around a working demo, so the safest plan is to centralize printable truth and delegate runtime proof to the existing smoke script. [VERIFIED: .planning/phases/112-default-docker-compose-app-db/112-02-SUMMARY.md]

## Common Pitfalls

### Pitfall 1: Stale Banner Values

**What goes wrong:** Startup prints URLs that do not match the active port or Traefik hostname. [VERIFIED: .planning/REQUIREMENTS.md]
**Why it happens:** Banner strings are hard-coded instead of computed from `LOCKSPIRE_DEMO_BASE_URL`. [VERIFIED: examples/adoption_demo/config/config.exs]
**How to avoid:** Compute every URL from trimmed `BASE_URL="${LOCKSPIRE_DEMO_BASE_URL:-http://127.0.0.1:4100}"`; never use `PORT` for external URL output. [VERIFIED: examples/adoption_demo/docker-compose.yml]
**Warning signs:** Contract tests pass for default port but fail for `LOCKSPIRE_DEMO_APP_PORT=4101` or Traefik hostname. [VERIFIED: test/lockspire/adoption_demo_docker_contract_test.exs]

### Pitfall 2: Secret Leakage In Startup Logs

**What goes wrong:** Startup output exposes client secrets, token hashes, private JWK material, authorization codes, refresh/access tokens, or cookies. [VERIFIED: .planning/REQUIREMENTS.md]
**Why it happens:** Scripts print raw seed output or inspect database rows generically. [VERIFIED: examples/adoption_demo/priv/repo/seeds.exs]
**How to avoid:** Print only static safe allowlist values and add source assertions that forbidden strings are absent from the new script and docs examples. [VERIFIED: AGENTS.md]
**Warning signs:** New output includes `client_secret`, `token_hash`, `private_jwk`, `authorization code`, `refresh_token`, `access_token`, or `cookie`. [VERIFIED: examples/adoption_demo/priv/repo/seeds.exs]

### Pitfall 3: Reprint Command Recreates State

**What goes wrong:** INFO-04 is implemented by rerunning setup/startup, which can reseed or restart containers. [VERIFIED: .planning/REQUIREMENTS.md]
**Why it happens:** Info printing is embedded only in `docker-start`. [VERIFIED: examples/adoption_demo/bin/docker-start]
**How to avoid:** Put output in `docker-info`; have `docker-start` call it and document `docker compose exec web ./bin/docker-info`. [CITED: https://docs.docker.com/reference/cli/docker/compose/exec/]
**Warning signs:** Docs tell maintainers to run `docker compose up` again only to see account/client info. [VERIFIED: docs/adoption-demo.md]

### Pitfall 4: Wrapper Duplicates Smoke Logic

**What goes wrong:** A shell wrapper reimplements portions of login/token/device flow and diverges from CI proof. [VERIFIED: scripts/demo/adoption_smoke.py]
**Why it happens:** The wrapper is treated as a second smoke implementation instead of command ergonomics. [VERIFIED: .planning/REQUIREMENTS.md]
**How to avoid:** Wrapper should set/display `LOCKSPIRE_DEMO_BASE_URL` and exec the existing Python script. [VERIFIED: scripts/demo/adoption_smoke.py]
**Warning signs:** New shell code parses callbacks, token JSON, cookies, or CSRF tokens. [VERIFIED: scripts/demo/adoption_smoke.py]

## Code Examples

Verified patterns from current repo and official sources:

### Docker Startup Readiness Pattern

```sh
# Source: examples/adoption_demo/bin/docker-start
wait_for_http() {
  attempt=1

  while [ "$attempt" -le 60 ]; do
    if curl -fsS "${BASE_URL}/" >/dev/null 2>&1; then
      return 0
    fi

    attempt=$((attempt + 1))
    sleep 1
  done

  echo "Adoption demo did not become ready at ${BASE_URL}" >&2
  return 1
}
```

### Compose Contract Test Pattern

```elixir
# Source: test/lockspire/adoption_demo_docker_contract_test.exs
System.cmd(
  "docker",
  ["compose"] ++ args ++ ["config", "--format", "json"],
  cd: @repo_root,
  env: env,
  stderr_to_stdout: true
)
```

### Existing Smoke Base URL Contract

```python
# Source: scripts/demo/adoption_smoke.py
BASE_URL = os.environ.get("LOCKSPIRE_DEMO_BASE_URL", "http://127.0.0.1:4100").rstrip("/")
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Hard-coded demo issuer/callback URLs | `LOCKSPIRE_DEMO_BASE_URL` drives endpoint URL, issuer, seeds, developer UI, and smoke | Phase 111, 2026-06-04 | Startup output must use the same base URL contract. [VERIFIED: .planning/phases/111-demo-url-contract-config-unification/111-02-SUMMARY.md] |
| Host-local Postgres dependency | Default Docker Compose `web` + internal `db` | Phase 112, 2026-06-04 | Docs should present Docker as default. [VERIFIED: .planning/phases/112-default-docker-compose-app-db/112-01-SUMMARY.md] |
| Minimal ready line only | Full self-describing banner | Phase 114 target | Banner should be printed after readiness. [VERIFIED: .planning/ROADMAP.md] |
| Required/default Traefik | Optional Traefik override | Phase 113, 2026-06-04 | Smoke command must use hostname only when `LOCKSPIRE_DEMO_BASE_URL` is set to hostname. [VERIFIED: .planning/phases/113-conflict-controls-optional-traefik/113-02-SUMMARY.md] |

**Deprecated/outdated:**

- Source-diving for URLs/accounts/clients is no longer acceptable for Phase 114 success. [VERIFIED: .planning/ROADMAP.md]
- Printing or documenting real secret material is explicitly out of scope. [VERIFIED: .planning/REQUIREMENTS.md]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | A POSIX shell `docker-info` script is preferable to a Mix task for this phase. [ASSUMED] | Standard Stack / Architecture Patterns | If the team wants Elixir-derived data instead, planner should swap implementation to a Mix task while preserving the same output contract. |

## Open Questions

1. **Should `northstar-dcr-self-registered` and `legacy-disabled-reporter` appear in startup output?**
   - What we know: Success criteria says seeded OAuth client IDs and demo shapes; seed file contains five clients, while smoke/docs focus on three primary demo clients. [VERIFIED: examples/adoption_demo/priv/repo/seeds.exs]
   - What's unclear: Whether startup should list all five clients or only the primary maintainer demo shapes. [ASSUMED]
   - Recommendation: Print all seeded client IDs with concise safe shapes, but visually group the three maintainer-flow clients first. [ASSUMED]

2. **Should stop/cleanup docs point to Phase 115 commands before they exist?**
   - What we know: DOCS-02 asks docs to cover stop, reset, cleanup, and troubleshooting; cleanup implementation is Phase 115. [VERIFIED: .planning/REQUIREMENTS.md]
   - What's unclear: Whether Phase 114 should document a placeholder cleanup section or only explain current reset/stop commands and say cleanup lands in Phase 115. [ASSUMED]
   - Recommendation: Document stop and existing reset concretely; include cleanup as a Phase 115-scoped note only if no cleanup command exists yet. [ASSUMED]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Elixir / Mix | Compile/tests/docs | ✓ | Elixir 1.19.5, Mix 1.19.5 | Use CI versions if local mismatch matters. [VERIFIED: local command] |
| Erlang/OTP | Compile/tests | ✓ | OTP 28 | Use CI setup-beam pinned versions for release proof. [VERIFIED: local command] |
| Docker | Compose render/runtime proof | ✓ | Docker 29.5.2 | Static source tests if daemon unavailable. [VERIFIED: local command] |
| Docker Compose | Direct and Traefik demo proof | ✓ | v5.1.3 | ExUnit skips Compose assertions if docker is unavailable. [VERIFIED: local command] |
| Python 3 | Existing smoke | ✓ | 3.14.4 | CI Ubuntu Python if local unavailable. [VERIFIED: local command] |
| PostgreSQL service | Host-local smoke / CI | Provided by Compose or CI service | `postgres:14` in Compose, `postgres:16` in CI | Compose-managed DB is default. [VERIFIED: examples/adoption_demo/docker-compose.yml] [VERIFIED: .github/workflows/ci.yml] |

**Missing dependencies with no fallback:** none found. [VERIFIED: local command]

**Missing dependencies with fallback:** none found. [VERIFIED: local command]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit with existing `Lockspire.AdoptionDemoDockerContractTest`; Python stdlib smoke compile/runtime. [VERIFIED: test/lockspire/adoption_demo_docker_contract_test.exs] |
| Config file | `mix.exs`; adoption demo `examples/adoption_demo/mix.exs`. [VERIFIED: mix.exs] |
| Quick run command | `mix test test/lockspire/adoption_demo_docker_contract_test.exs --seed 0` [VERIFIED: prior phase summaries] |
| Full suite command | `mix test.fast` plus adoption-demo smoke runtime where Docker is available. [VERIFIED: mix.exs] |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| INFO-01 | Startup/info output contains all required URLs and exact smoke command | source + runtime log | `rg -n "Discovery|JWKS|Operator admin|Device verification|Developer apps|OAuth callback|Protected API|adoption_smoke.py" examples/adoption_demo/bin/docker-info` | ❌ Wave 0 |
| INFO-02 | Output lists `alice`, `bob`, `ops`, emails, and `ops` operator marker | source contract | `rg -n "alice@acme.test|bob@globex.test|ops@acme.test|operator account" examples/adoption_demo/bin/docker-info` | ❌ Wave 0 |
| INFO-03 | Output lists client IDs/shapes and excludes sensitive material | source contract | `rg -n "acme-ledger-public|acme-tv-device|acme-ledger-backend" examples/adoption_demo/bin/docker-info && test "$(rg -n "demo-backend-secret|demo-rat-secret|token_hash|private_jwk|authorization code|refresh token|access token|cookie" examples/adoption_demo/bin/docker-info | wc -l | tr -d ' ')" = "0"` | ❌ Wave 0 |
| INFO-04 | Reprint command works without recreating containers | runtime/manual | `docker compose -f examples/adoption_demo/docker-compose.yml exec web ./bin/docker-info` | ❌ Wave 0 |
| SMOKE-01 | Existing smoke passes against direct Docker URL | runtime/manual | `LOCKSPIRE_DEMO_BASE_URL=http://127.0.0.1:4100 python3 scripts/demo/adoption_smoke.py` | ✅ |
| SMOKE-02 | Existing smoke passes against Traefik hostname when enabled | runtime/manual | `LOCKSPIRE_DEMO_BASE_URL=http://lockspire-demo.localhost python3 scripts/demo/adoption_smoke.py` | ✅ |
| DOCS-01 | Docs present Docker first and host-local fallback | docs contract | `mix test test/lockspire/adoption_demo_docker_contract_test.exs --seed 0` | ✅ |
| DOCS-02 | Docs cover startup, Traefik, smoke, stop, reset, cleanup, env overrides, troubleshooting | docs contract | `mix test test/lockspire/adoption_demo_docker_contract_test.exs --seed 0` | ✅, needs expansion |

### Sampling Rate

- **Per task commit:** `mix test test/lockspire/adoption_demo_docker_contract_test.exs --seed 0` and `sh -n` for any new shell script. [VERIFIED: prior phase summaries]
- **Per wave merge:** `mix test.fast`, `python3 -m py_compile scripts/demo/adoption_smoke.py`, and `docker compose ... config --format json`. [VERIFIED: mix.exs]
- **Phase gate:** Direct Docker startup log contains the full banner and `LOCKSPIRE_DEMO_BASE_URL=http://127.0.0.1:4100 python3 scripts/demo/adoption_smoke.py` passes; Traefik smoke is run if optional Traefik is enabled. [VERIFIED: .planning/REQUIREMENTS.md]

### Wave 0 Gaps

- [ ] `examples/adoption_demo/bin/docker-info` — reusable redacted info printer for INFO-01..04. [VERIFIED: examples/adoption_demo/bin]
- [ ] Optional `scripts/demo/adoption_smoke.sh` or `examples/adoption_demo/bin/docker-smoke` — thin smoke wrapper for maintainer ergonomics. [ASSUMED]
- [ ] Extend `test/lockspire/adoption_demo_docker_contract_test.exs` — source/docs contracts for info output, redaction, reprint command, and troubleshooting docs. [VERIFIED: test/lockspire/adoption_demo_docker_contract_test.exs]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V2 Authentication | yes | Preserve host-owned login and `ops` operator guard; no auth behavior changes. [VERIFIED: AGENTS.md] |
| V3 Session Management | yes | Existing Phoenix session/cookie behavior remains inside smoke proof; do not print cookies. [VERIFIED: scripts/demo/adoption_smoke.py] |
| V4 Access Control | yes | `ops` is operator; `/lockspire/admin` remains host-guarded by `RequireOperator`. [VERIFIED: examples/adoption_demo/lib/adoption_demo_web/plugs/require_operator.ex] |
| V5 Input Validation | yes | `LOCKSPIRE_DEMO_BASE_URL` is validated in config; scripts should trim only and rely on existing config for app boot validation. [VERIFIED: examples/adoption_demo/config/config.exs] |
| V6 Cryptography | yes | Do not print private JWKs, token material, client secrets, or signing material; do not change signing algorithms. [VERIFIED: AGENTS.md] |
| V8 Data Protection | yes | Startup logs must not include sensitive data; OWASP ASVS includes avoiding sensitive data in logs. [CITED: https://owasp.org/www-project-application-security-verification-standard/] |

### Known Threat Patterns for Demo Startup Output

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Secret leakage in logs | Information Disclosure | Static allowlist output plus negative source assertions for real secret values, token material, private key material, auth codes, and cookie strings; auth-method labels such as `client_secret_basic` are safe to print when no secret value is shown. [VERIFIED: .planning/REQUIREMENTS.md] |
| Base URL spoof/drift | Spoofing/Tampering | Print and smoke exactly the active `LOCKSPIRE_DEMO_BASE_URL`; direct and Traefik commands must set the same value they prove. [VERIFIED: scripts/demo/adoption_smoke.py] |
| Operator account ambiguity | Elevation of Privilege | Clearly label `ops` as operator account and `alice`/`bob` as SaaS users. [VERIFIED: examples/adoption_demo/lib/adoption_demo/accounts.ex] |
| Reprint mutates state | Tampering | Reprint script must only print info; no `mix ecto.*`, no `docker compose up`, no seed execution. [ASSUMED] |

## Sources

### Primary (HIGH confidence)

- `AGENTS.md` - project boundaries, stack, product priorities, and redaction requirements. [VERIFIED: codebase grep]
- `.planning/REQUIREMENTS.md` - Phase 114 requirements INFO-01..04, SMOKE-01..02, DOCS-01..02. [VERIFIED: codebase grep]
- `.planning/ROADMAP.md` - Phase 114 goal and success criteria. [VERIFIED: codebase grep]
- `.planning/STATE.md` - locked milestone decisions and current phase state. [VERIFIED: codebase grep]
- Prior phase summaries for 111, 112, 113 - established base URL, Docker startup, direct/Traefik Compose contracts. [VERIFIED: codebase grep]
- `examples/adoption_demo/bin/docker-start` - startup wrapper and readiness behavior. [VERIFIED: codebase grep]
- `scripts/demo/adoption_smoke.py` - black-box proof and base URL contract. [VERIFIED: codebase grep]
- `examples/adoption_demo/lib/adoption_demo/accounts.ex` and `examples/adoption_demo/priv/repo/seeds.exs` - account/client truth and sensitive fields. [VERIFIED: codebase grep]
- `test/lockspire/adoption_demo_docker_contract_test.exs` - existing Compose/docs contract-test pattern. [VERIFIED: codebase grep]

### Secondary (MEDIUM confidence)

- Docker Compose interpolation docs - variable substitution/default patterns. [CITED: https://docs.docker.com/compose/how-tos/environment-variables/variable-interpolation/]
- Docker Compose config docs - `config` merges files, resolves variables, and renders canonical model. [CITED: https://docs.docker.com/reference/cli/docker/compose/config/]
- Docker Compose exec docs - command execution in running services. [CITED: https://docs.docker.com/reference/cli/docker/compose/exec/]
- Phoenix Endpoint docs - Endpoint `:url` behavior. [CITED: https://hexdocs.pm/phoenix/Phoenix.Endpoint.html]
- OWASP ASVS project page - basis for web application security verification and sensitive-data verification context. [CITED: https://owasp.org/www-project-application-security-verification-standard/]

### Tertiary (LOW confidence)

- Implementation preference for shell script over Mix task is an engineering judgment based on current repo style. [ASSUMED]

## Metadata

**Confidence breakdown:**

- Standard stack: HIGH - existing repo stack and local tool availability verified; no new packages recommended. [VERIFIED: local command]
- Architecture: HIGH - insertion points and contracts are visible in current scripts, docs, routes, and tests. [VERIFIED: codebase grep]
- Pitfalls: HIGH - redaction and URL drift risks are explicit in requirements and visible in seed/config files. [VERIFIED: .planning/REQUIREMENTS.md]

**Research date:** 2026-06-24
**Valid until:** 2026-07-24 for repo-local patterns; recheck Docker/Phoenix docs if Compose or dependency versions change. [ASSUMED]
