# Phase 113: Conflict Controls & Optional Traefik - Pattern Map

**Mapped:** 2026-06-04
**Files analyzed:** 6
**Analogs found:** 6 / 6

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `examples/adoption_demo/docker-compose.yml` | config | request-response + file-I/O | `examples/adoption_demo/docker-compose.yml` | exact |
| `examples/adoption_demo/docker-compose.traefik.yml` | config | request-response | `tools/traefik/docker-compose.yml` | role-match |
| `examples/adoption_demo/docker-compose.db-host.yml` | config | request-response | `examples/adoption_demo/docker-compose.yml` | role-match |
| `examples/adoption_demo/bin/docker-reset` | utility | batch + file-I/O | `examples/adoption_demo/bin/docker-start`; `scripts/maintainer/repo_hygiene_check.sh` | role-match |
| `docs/adoption-demo.md` | documentation | transform | `docs/adoption-demo.md` | exact |
| `test/lockspire/adoption_demo_docker_contract_test.exs` | test | batch + transform | `test/lockspire/release_readiness_contract_test.exs`; `test/lockspire/web/live/admin/design_system_contract_test.exs` | role-match |

## Pattern Assignments

### `examples/adoption_demo/docker-compose.yml` (config, request-response + file-I/O)

**Analog:** `examples/adoption_demo/docker-compose.yml`

**Core service topology pattern** (lines 1-11):
```yaml
services:
  web:
    build:
      context: ../..
      dockerfile: examples/adoption_demo/Dockerfile.dev
    depends_on:
      db:
        condition: service_healthy
    command: ["./bin/docker-start"]
    ports:
      - "4100:4100"
```

**Volume isolation pattern** (lines 12-16):
```yaml
volumes:
  - ../..:/workspace
  # Isolate Linux build artifacts from host artifacts.
  - deps_volume:/workspace/examples/adoption_demo/deps
  - build_volume:/workspace/examples/adoption_demo/_build
```

**Environment contract pattern** (lines 17-26):
```yaml
environment:
  PHX_SERVER: "true"
  PORT: "4100"
  LOCKSPIRE_DEMO_BASE_URL: "http://127.0.0.1:4100"
  LOCKSPIRE_DEMO_BIND_IP: "0.0.0.0"
  LOCKSPIRE_DEMO_DB_HOST: "db"
  LOCKSPIRE_DEMO_DB_PORT: "5432"
  LOCKSPIRE_DEMO_DB_NAME: "lockspire_adoption_demo"
  LOCKSPIRE_DEMO_DB_USER: "lockspire"
  LOCKSPIRE_DEMO_DB_PASSWORD: "lockspire"
```

**Database internal-only pattern** (lines 28-40):
```yaml
db:
  image: postgres:14
  environment:
    POSTGRES_DB: "lockspire_adoption_demo"
    POSTGRES_USER: "lockspire"
    POSTGRES_PASSWORD: "lockspire"
  healthcheck:
    test: ["CMD-SHELL", "pg_isready -U lockspire -d lockspire_adoption_demo"]
    interval: 5s
    timeout: 5s
    retries: 12
  volumes:
    - db_data:/var/lib/postgresql/data
```

**Named volume pattern** (lines 42-45):
```yaml
volumes:
  db_data:
  deps_volume:
  build_volume:
```

**Planner notes:**
- Replace hard-coded `4100:4100`, `PORT: "4100"`, and default base URL with Compose interpolation.
- Keep `db` without `ports:` in the default file.
- Keep app and DB on the default internal Compose network unless an opt-in override attaches `web` elsewhere.

---

### `examples/adoption_demo/docker-compose.traefik.yml` (config, request-response)

**Analog:** `tools/traefik/docker-compose.yml`

**Existing external proxy network pattern** (lines 14-19):
```yaml
networks:
  - local-dev-proxy

networks:
  local-dev-proxy:
    external: true
```

**Existing Traefik Docker provider pattern** (lines 2-8):
```yaml
traefik:
  image: traefik:v2.10
  command:
    - "--api.insecure=true"
    - "--providers.docker=true"
    - "--providers.docker.exposedbydefault=false"
    - "--entrypoints.web.address=:80"
```

**Planner notes:**
- The new override should not define or start Traefik itself; it should attach only `web` to the external proxy network used by `tools/traefik/docker-compose.yml`.
- Use list/equal-sign label syntax for interpolated Traefik router/service label keys.
- Add explicit service port label, e.g. `traefik.http.services.${LOCKSPIRE_DEMO_TRAEFIK_SERVICE:-lockspire-adoption-demo}.loadbalancer.server.port=${LOCKSPIRE_DEMO_APP_PORT:-4100}`.
- Do not attach `db` to the external proxy network.

---

### `examples/adoption_demo/docker-compose.db-host.yml` (config, request-response)

**Analog:** `examples/adoption_demo/docker-compose.yml`

**DB service to extend** (lines 28-40):
```yaml
db:
  image: postgres:14
  environment:
    POSTGRES_DB: "lockspire_adoption_demo"
    POSTGRES_USER: "lockspire"
    POSTGRES_PASSWORD: "lockspire"
  healthcheck:
    test: ["CMD-SHELL", "pg_isready -U lockspire -d lockspire_adoption_demo"]
    interval: 5s
    timeout: 5s
    retries: 12
  volumes:
    - db_data:/var/lib/postgresql/data
```

**Planner notes:**
- If the plan includes host DB access, keep it in an opt-in override/profile rather than the default Compose file.
- Use a demo-scoped configurable host port, e.g. `${LOCKSPIRE_DEMO_DB_HOST_PORT:-5432}:5432`.
- Keep `LOCKSPIRE_DEMO_DB_PORT` inside the app as container/internal `5432`; host DB exposure is for maintainer tools, not app-to-DB wiring.

---

### `examples/adoption_demo/bin/docker-reset` (utility, batch + file-I/O)

**Analogs:** `examples/adoption_demo/bin/docker-start`; `scripts/maintainer/repo_hygiene_check.sh`

**Shell strictness pattern** (`examples/adoption_demo/bin/docker-start` lines 1-7):
```sh
#!/usr/bin/env sh
set -eu

BASE_URL="${LOCKSPIRE_DEMO_BASE_URL:-http://127.0.0.1:4100}"
BASE_URL="${BASE_URL%/}"
DB_HOST="${LOCKSPIRE_DEMO_DB_HOST:-db}"
DB_PORT="${LOCKSPIRE_DEMO_DB_PORT:-5432}"
```

**Bounded command/error pattern** (`examples/adoption_demo/bin/docker-start` lines 27-44):
```sh
create_database() {
  create_output="$(mktemp)"

  if mix ecto.create >"$create_output" 2>&1; then
    rm -f "$create_output"
    return 0
  fi

  if grep -qi "already exists" "$create_output"; then
    echo "Database ${DB_NAME} already exists; reusing it."
    rm -f "$create_output"
    return 0
  fi

  cat "$create_output" >&2
  rm -f "$create_output"
  return 1
}
```

**Repo-root normalization and argument parsing pattern** (`scripts/maintainer/repo_hygiene_check.sh` lines 20-46):
```bash
for arg in "$@"; do
  case "$arg" in
    --ci)
      MODE="ci"
      ;;
    --skip-mix-ci)
      RUN_MIX_CI=0
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $arg" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if ! command -v git >/dev/null 2>&1; then
  echo "[BLOCK] git: required command is not installed" >&2
  exit 1
fi

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$REPO_ROOT"
```

**Planner notes:**
- Prefer `#!/usr/bin/env sh` + `set -eu` if the helper can stay POSIX shell; use Bash only if arrays or Bash-specific traps are needed.
- Resolve the active project name from the same input used by startup, then remove only `${project}_db_data`, `${project}_deps_volume`, and `${project}_build_volume`.
- Never use `docker volume prune`, `docker system prune`, or a hard-coded default project prefix.

---

### `docs/adoption-demo.md` (documentation, transform)

**Analog:** `docs/adoption-demo.md`

**Scope boundary pattern** (lines 3-6):
```markdown
Lockspire includes a small Phoenix host app at `examples/adoption_demo`.

The demo is not a new product surface or Hex package content. It is a repo-local adopter proof that boots a representative SaaS host, mounts Lockspire, seeds realistic OAuth clients, and exercises the library over HTTP.
```

**Docker command pattern** (lines 17-25):
~~~markdown
## Run it with Docker

From the repo root:

```sh
docker compose -f examples/adoption_demo/docker-compose.yml up --build
```

This starts the Phoenix/Bandit demo and PostgreSQL for the repo-local adoption demo. Then open `http://127.0.0.1:4100`.
~~~

**Smoke command pattern** (lines 56-64):
~~~markdown
## Run the black-box smoke

Start the demo server, then run:

```sh
python3 scripts/demo/adoption_smoke.py
```

The script waits for the server, drives browser-like cookies through login and consent, exchanges real tokens, approves a device-code request, and calls the protected demo API.
~~~

**Planner notes:**
- Keep docs narrow to conflict controls and optional Traefik setup truth; defer full banner/reprint/troubleshooting expansion to Phase 114.
- Document `LOCKSPIRE_DEMO_BASE_URL` as the browser-visible URL truth for alternate ports and Traefik hostnames.
- Include explicit opt-in commands for Traefik and optional DB host exposure if those files are created.

---

### `test/lockspire/adoption_demo_docker_contract_test.exs` (test, batch + transform)

**Analogs:** `test/lockspire/release_readiness_contract_test.exs`; `test/lockspire/web/live/admin/design_system_contract_test.exs`; `test/integration/install_generator_test.exs`

**Imports and module pattern** (`test/lockspire/release_readiness_contract_test.exs` lines 1-4):
```elixir
defmodule Lockspire.ReleaseReadinessContractTest do
  use ExUnit.Case, async: true

  import Lockspire.TestSupport.AdvancedSetupSupportTruth,
```

**Path module attribute pattern** (`test/lockspire/release_readiness_contract_test.exs` lines 20-25):
```elixir
@maintainer_guide_path Path.expand("../../docs/maintainer-release.md", __DIR__)
@release_workflow_path Path.expand("../../.github/workflows/release.yml", __DIR__)
@release_please_automerge_workflow_path Path.expand(
                                      "../../.github/workflows/release-please-automerge.yml",
                                      __DIR__
                                    )
```

**File content contract pattern** (`test/lockspire/release_readiness_contract_test.exs` lines 506-528):
```elixir
test "release prep docs keep evidence buckets separate and avoid checked-in publish-proof claims" do
  guide = File.read!(@maintainer_guide_path)
  readme = File.read!(@readme_path)
  security = File.read!(@security_policy_path)
  supported_surface = File.read!(@supported_surface_path)
  changelog = File.read!("CHANGELOG.md")
  repo_hygiene_script = File.read!(@repo_hygiene_script_path)

  assert guide =~ "Repo-owned proof:"
  assert guide =~ "GitHub settings proof:"
  assert guide =~ "Workflow-run proof:"
  assert guide =~ "Release candidate checklist"
  assert guide =~ "review-only evidence"
  assert supported_surface =~ "canonical public support contract"
  assert repo_hygiene_script =~ "Result: safe to start release prep"
  assert repo_hygiene_script =~ "Result: proceed with caution"
  assert repo_hygiene_script =~ "Result: not ready"
end
```

**Glob/file aggregate contract pattern** (`test/lockspire/web/live/admin/design_system_contract_test.exs` lines 82-92):
```elixir
test "admin LiveViews use namespaced Lockspire admin button classes" do
  offenders =
    @admin_live_glob
    |> Path.wildcard()
    |> Enum.filter(fn path ->
      content = File.read!(path)

      Regex.match?(~r/class="(?:button|[^"]*\sbutton(?:\s|"))/, content)
    end)

  assert offenders == []
end
```

**JSON decode helper pattern** (`test/integration/install_generator_test.exs` lines 374-379):
```elixir
defp load_manifest! do
  @fixture_root
  |> Path.join(".lockspire/install_manifest.json")
  |> File.read!()
  |> Jason.decode!()
end
```

**Planner notes:**
- Make this a focused contract test for rendered Compose JSON and docs/source assertions.
- Use `docker compose config --format json` only as deterministic render proof, not `docker compose up`.
- Since current project tests do not shell out to Docker, keep external command helpers small, skip with a clear message if `docker` is unavailable, or assert source/docs contracts when shell proof cannot run.

## Shared Patterns

### Base URL Truth
**Source:** `examples/adoption_demo/config/config.exs`
**Apply to:** Compose, docs, reset examples, smoke examples
```elixir
demo_base_url =
  "LOCKSPIRE_DEMO_BASE_URL"
  |> System.get_env("http://127.0.0.1:4100")
  |> String.trim()
  |> String.trim_trailing("/")

demo_uri = URI.parse(demo_base_url)
```
Lines 6-12.

```elixir
config :lockspire,
  repo: AdoptionDemo.Repo,
  issuer: demo_base_url <> "/lockspire",
  mount_path: "/lockspire",
```
Lines 63-66.

### Listener Bind Split
**Source:** `examples/adoption_demo/config/config.exs`
**Apply to:** Compose env values and docs
```elixir
demo_bind_ip =
  case System.get_env("LOCKSPIRE_DEMO_BIND_IP", "127.0.0.1") do
    "127.0.0.1" -> {127, 0, 0, 1}
    "0.0.0.0" -> {0, 0, 0, 0}
    other -> raise ArgumentError, "unsupported LOCKSPIRE_DEMO_BIND_IP=#{inspect(other)}"
  end
```
Lines 23-28.

```elixir
http: [
  ip: demo_bind_ip,
  port: String.to_integer(System.get_env("PORT") || "4100")
],
```
Lines 48-51.

### Smoke Uses Only Configured External URL
**Source:** `scripts/demo/adoption_smoke.py`
**Apply to:** Docs and optional local smoke commands
```python
BASE_URL = os.environ.get("LOCKSPIRE_DEMO_BASE_URL", "http://127.0.0.1:4100").rstrip("/")
```
Line 14.

```python
assert_equal(discovery_json["issuer"], BASE_URL + "/lockspire", "discovery issuer")
assert_equal(
    discovery_json["authorization_endpoint"],
    BASE_URL + "/lockspire/authorize",
    "authorization endpoint",
)
```
Lines 163-168.

### Default DB Internal-Only
**Source:** `examples/adoption_demo/docker-compose.yml`
**Apply to:** Default Compose and tests
```yaml
db:
  image: postgres:14
  environment:
    POSTGRES_DB: "lockspire_adoption_demo"
    POSTGRES_USER: "lockspire"
    POSTGRES_PASSWORD: "lockspire"
```
Lines 28-33. No `ports:` entry appears under `db`.

### Scoped Contract Tests
**Source:** `test/lockspire/release_readiness_contract_test.exs`
**Apply to:** New Docker contract test
```elixir
repo_hygiene_script = File.read!(@repo_hygiene_script_path)

assert repo_hygiene_script =~ "Result: safe to start release prep"
assert repo_hygiene_script =~ "Result: proceed with caution"
assert repo_hygiene_script =~ "Result: not ready"
```
Lines 512, 526-528.

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| None | - | - | All expected files have exact or role-match analogs. Traefik labels for the adoption demo are new, but the external network/helper pattern exists in `tools/traefik/docker-compose.yml`. |

## Metadata

**Analog search scope:** `examples/adoption_demo`, `docs`, `scripts`, `test`, `tools`
**Files scanned:** 220+ repo files from `rg --files`; 8 strong analog files read
**Pattern extraction date:** 2026-06-04
