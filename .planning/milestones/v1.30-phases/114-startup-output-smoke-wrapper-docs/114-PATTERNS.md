# Phase 114: Startup Output, Smoke Wrapper & Docs - Pattern Map

**Mapped:** 2026-06-24
**Files analyzed:** 8
**Analogs found:** 8 / 8

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `examples/adoption_demo/bin/docker-start` | utility | request-response | `examples/adoption_demo/bin/docker-start` | exact |
| `examples/adoption_demo/bin/docker-info` | utility | transform | `examples/adoption_demo/bin/docker-start` + `examples/adoption_demo/bin/docker-reset` | role-match |
| `scripts/demo/adoption_smoke.sh` | utility | request-response | `examples/adoption_demo/bin/docker-reset` + `scripts/demo/adoption_smoke.py` | role-match |
| `scripts/demo/adoption_smoke.py` | utility | request-response | `scripts/demo/adoption_smoke.py` | exact |
| `docs/adoption-demo.md` | documentation | transform | `docs/adoption-demo.md` | exact |
| `test/lockspire/adoption_demo_docker_contract_test.exs` | test | request-response | `test/lockspire/adoption_demo_docker_contract_test.exs` | exact |
| `examples/adoption_demo/docker-compose.yml` | config | request-response | `examples/adoption_demo/docker-compose.yml` | exact |
| `examples/adoption_demo/docker-compose.traefik.yml` | config | request-response | `examples/adoption_demo/docker-compose.traefik.yml` | exact |

## Pattern Assignments

### `examples/adoption_demo/bin/docker-start` (utility, request-response)

**Analog:** `examples/adoption_demo/bin/docker-start`

**Imports / script header pattern** (lines 1-9):

```sh
#!/usr/bin/env sh
set -eu

BASE_URL="${LOCKSPIRE_DEMO_BASE_URL:-http://127.0.0.1:4100}"
BASE_URL="${BASE_URL%/}"
DB_HOST="${LOCKSPIRE_DEMO_DB_HOST:-db}"
DB_PORT="${LOCKSPIRE_DEMO_DB_PORT:-5432}"
DB_NAME="${LOCKSPIRE_DEMO_DB_NAME:-lockspire_adoption_demo}"
DB_USER="${LOCKSPIRE_DEMO_DB_USER:-lockspire}"
```

**Core startup/readiness pattern** (lines 85-97):

```sh
wait_for_postgres
mix deps.get
create_database
mix ecto.migrate --migrations-path ../../priv/repo/migrations
seed_database

mix phx.server &
server_pid="$!"

wait_for_http
echo "Adoption demo ready at ${BASE_URL}"

wait "$server_pid"
```

**Error handling pattern** (lines 59-73):

```sh
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

**Apply to Phase 114:** Replace or follow the ready line with `./bin/docker-info` after `wait_for_http`. Keep database setup and readiness untouched.

---

### `examples/adoption_demo/bin/docker-info` (utility, transform)

**Analogs:** `examples/adoption_demo/bin/docker-start`, `examples/adoption_demo/bin/docker-reset`, `examples/adoption_demo/config/config.exs`, `examples/adoption_demo/lib/adoption_demo/accounts.ex`, `examples/adoption_demo/priv/repo/seeds.exs`

**Script header and base URL pattern** (docker-start lines 1-5):

```sh
#!/usr/bin/env sh
set -eu

BASE_URL="${LOCKSPIRE_DEMO_BASE_URL:-http://127.0.0.1:4100}"
BASE_URL="${BASE_URL%/}"
```

**Argument/usage style if needed** (docker-reset lines 4-15):

```sh
usage() {
  cat <<'USAGE'
Usage: examples/adoption_demo/bin/docker-reset [--project NAME]

Reset only the active adoption demo Docker volumes:
  db_data deps_volume build_volume

The default project is COMPOSE_PROJECT_NAME, or lockspire-adoption-demo when
COMPOSE_PROJECT_NAME is not set. Pass --project NAME to match docker compose
--project-name NAME / -p NAME startup.
USAGE
}
```

**URL truth pattern** (config lines 6-21, 63-66):

```elixir
demo_base_url =
  "LOCKSPIRE_DEMO_BASE_URL"
  |> System.get_env("http://127.0.0.1:4100")
  |> String.trim()
  |> String.trim_trailing("/")

config :adoption_demo, :demo_base_url, demo_base_url

config :lockspire,
  repo: AdoptionDemo.Repo,
  issuer: demo_base_url <> "/lockspire",
  mount_path: "/lockspire",
```

**Route inventory to print** (router lines 35-45, 49-51, 62-69):

```elixir
get("/", PageController, :home)
get("/developer/apps", DeveloperController, :index)
get("/oauth/callback", OAuthCallbackController, :show)
get("/verify", DeviceVerificationController, :show)

scope "/lockspire/admin" do
  pipe_through([:browser, :operator])
  forward("/", Lockspire.Web.AdminRouter)
end

forward("/lockspire", Lockspire.Web.Router)
get("/billing/summary", ApiController, :billing_summary)
```

**Account allowlist source** (accounts lines 4-31):

```elixir
@accounts %{
  "alice" => %{
    login: "alice",
    email: "alice@acme.test",
    operator?: false
  },
  "bob" => %{
    login: "bob",
    email: "bob@globex.test",
    operator?: false
  },
  "ops" => %{
    login: "ops",
    email: "ops@acme.test",
    operator?: true
  }
}
```

**Client allowlist source** (seeds lines 88-135, 137-190):

```elixir
%Client{
  client_id: "acme-ledger-public",
  client_type: :public,
  allowed_grant_types: ["authorization_code", "refresh_token"],
  token_endpoint_auth_method: :none,
  pkce_required: true
}

%Client{
  client_id: "acme-tv-device",
  client_type: :public,
  allowed_grant_types: ["urn:ietf:params:oauth:grant-type:device_code"],
  token_endpoint_auth_method: :none,
  pkce_required: true
}

%Client{
  client_id: "acme-ledger-backend",
  client_secret_hash: Lockspire.Security.Policy.hash_client_secret("demo-backend-secret"),
  client_type: :confidential,
  token_endpoint_auth_method: :client_secret_basic,
  pkce_required: true
}

%Client{
  client_id: "northstar-dcr-self-registered",
  client_type: :confidential,
  provenance: :self_registered,
  token_endpoint_auth_method: :client_secret_basic,
  pkce_required: true
}

%Client{
  client_id: "legacy-disabled-reporter",
  client_type: :confidential,
  active: false,
  token_endpoint_auth_method: :client_secret_basic,
  pkce_required: true
}
```

**Redaction boundary** (seeds lines 66-83, 121-124, 137-165, 273-345):

```elixir
key = JOSE.JWK.generate_key({:rsa, 2048})
private_jwk_encrypted: :erlang.term_to_binary(Map.put(jwk, "kid", "adoption-demo-rs256"))

client_secret_hash: Lockspire.Security.Policy.hash_client_secret("demo-backend-secret")
registration_access_token_hash: Lockspire.Security.Policy.hash_token("demo-rat-northstar")

token_hash: Lockspire.Security.Policy.hash_token("demo-access-active")
token_type: :access_token
token_type: :refresh_token
```

**Apply to Phase 114:** The new script should compute all public URLs from trimmed `BASE_URL`, print the smoke command exactly with `LOCKSPIRE_DEMO_BASE_URL=${BASE_URL}`, print only the account/client allowlist, and never shell out to seed, inspect DB rows, or print secret/hash/token/private-key fields.

---

### `scripts/demo/adoption_smoke.sh` (utility, request-response)

**Analogs:** `examples/adoption_demo/bin/docker-reset`, `scripts/demo/adoption_smoke.py`

**Shell wrapper style** (docker-reset lines 1-3, 19-39):

```sh
#!/usr/bin/env sh
set -eu

while [ "$#" -gt 0 ]; do
  case "$1" in
    -h | --help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done
```

**Repo-root discovery pattern** (docker-reset lines 42-53):

```sh
if ! command -v git >/dev/null 2>&1; then
  echo "git is required to locate the Lockspire repo root" >&2
  exit 1
fi

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$REPO_ROOT"
```

**Smoke base URL contract** (adoption_smoke.py lines 14, 349-354):

```python
BASE_URL = os.environ.get("LOCKSPIRE_DEMO_BASE_URL", "http://127.0.0.1:4100").rstrip("/")

def main():
    wait_until_ready()
    exercise_discovery_and_admin()
    exercise_authorization_code()
    exercise_device_flow()
    print("adoption demo smoke passed")
```

**Error handling pattern** (adoption_smoke.py lines 357-362):

```python
if __name__ == "__main__":
    try:
        main()
    except Exception as exc:
        print(f"adoption demo smoke failed: {exc}", file=sys.stderr)
        sys.exit(1)
```

**Apply to Phase 114:** If added, keep this wrapper thin: normalize `LOCKSPIRE_DEMO_BASE_URL`, echo the active target, then `exec python3 scripts/demo/adoption_smoke.py`. Do not parse callbacks, token JSON, cookies, CSRF, or device codes in shell.

---

### `scripts/demo/adoption_smoke.py` (utility, request-response)

**Analog:** `scripts/demo/adoption_smoke.py`

**Imports pattern** (lines 1-11):

```python
#!/usr/bin/env python3
import base64
import hashlib
import http.client
import json
import os
import re
import sys
import time
from http.cookies import SimpleCookie
from urllib.parse import parse_qs, urlencode, urljoin, urlparse
```

**Base URL and readiness pattern** (lines 14, 125-140):

```python
BASE_URL = os.environ.get("LOCKSPIRE_DEMO_BASE_URL", "http://127.0.0.1:4100").rstrip("/")

def wait_until_ready():
    deadline = time.time() + 45
    browser = Browser(BASE_URL)

    while time.time() < deadline:
        try:
            response = browser.request("GET", "/")
            if response["status"] == 200:
                return
        except OSError:
            pass

        time.sleep(1)

    raise AssertionError(f"demo app did not become ready at {BASE_URL}")
```

**Core proof pattern** (lines 157-188, 190-289, 292-346):

```python
def exercise_discovery_and_admin():
    discovery = browser.request("GET", "/lockspire/.well-known/openid-configuration")
    assert_equal(discovery_json["issuer"], BASE_URL + "/lockspire", "discovery issuer")
    jwks = browser.request("GET", "/lockspire/jwks")
    denied = browser.request("GET", "/lockspire/admin")
    logged_in = login(browser, "ops", "/lockspire/admin")

def exercise_authorization_code():
    authorize_params = {
        "client_id": "acme-ledger-public",
        "redirect_uri": BASE_URL + "/oauth/callback",
        "code_challenge_method": "S256",
    }
    token = browser.request("POST", "/lockspire/token", {...})
    userinfo = browser.request("GET", "/lockspire/userinfo", headers={...})
    authed_api = Browser(BASE_URL).request("GET", "/api/billing/summary", headers={...})

def exercise_device_flow():
    issued = browser.request("POST", "/lockspire/device/code", {"client_id": "acme-tv-device", ...})
    assert_equal(issued_json["verification_uri"], BASE_URL + "/verify", "device verification_uri")
```

**Apply to Phase 114:** Prefer no behavioral changes. If startup output or wrapper references this file, keep `LOCKSPIRE_DEMO_BASE_URL` as the only external URL input.

---

### `docs/adoption-demo.md` (documentation, transform)

**Analog:** `docs/adoption-demo.md`

**Docker-first structure pattern** (lines 17-25):

```markdown
## Run it with Docker

From the repo root:

```sh
docker compose -f examples/adoption_demo/docker-compose.yml up --build
```

This starts the Phoenix/Bandit demo and PostgreSQL for the repo-local adoption demo. Then open `http://127.0.0.1:4100`.
```

**Environment override pattern** (lines 40-54):

```markdown
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
```

**Optional Traefik pattern** (lines 67-105):

```markdown
Traefik hostname routing is optional. The default Docker command above does not
need Traefik or an external proxy network.

```sh
LOCKSPIRE_DEMO_BASE_URL=http://lockspire-demo.localhost \
docker compose -f examples/adoption_demo/docker-compose.yml \
  -f examples/adoption_demo/docker-compose.traefik.yml up --build
```

Run the smoke against the same hostname origin:

```sh
LOCKSPIRE_DEMO_BASE_URL=http://lockspire-demo.localhost python3 scripts/demo/adoption_smoke.py
```
```

**Account/client docs pattern** (lines 135-149):

```markdown
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
```

**Apply to Phase 114:** Expand this file, keeping Docker first and host-local fallback second. Add reprint command, startup banner meaning, stop/reset/cleanup notes, smoke wrapper if created, and troubleshooting. Do not document real secret values.

---

### `test/lockspire/adoption_demo_docker_contract_test.exs` (test, request-response)

**Analog:** `test/lockspire/adoption_demo_docker_contract_test.exs`

**Imports/module attributes pattern** (lines 1-9):

```elixir
defmodule Lockspire.AdoptionDemoDockerContractTest do
  use ExUnit.Case, async: false

  @repo_root Path.expand("../..", __DIR__)
  @compose_file "examples/adoption_demo/docker-compose.yml"
  @db_host_compose_file "examples/adoption_demo/docker-compose.db-host.yml"
  @traefik_compose_file "examples/adoption_demo/docker-compose.traefik.yml"
  @docker_reset_path Path.join(@repo_root, "examples/adoption_demo/bin/docker-reset")
  @adoption_demo_docs_path Path.join(@repo_root, "docs/adoption-demo.md")
```

**Source contract pattern** (lines 111-132):

```elixir
test "reset helper targets only the active demo project volumes" do
  source = File.read!(@docker_reset_path)

  assert source =~ "lockspire-adoption-demo"
  assert source =~ "COMPOSE_PROJECT_NAME"
  assert source =~ "--project"
  assert source =~ ~r/docker compose .*--project-name "\$project".* down/

  refute source =~ "docker volume prune"
  refute source =~ "docker system prune"
  refute source =~ "docker compose down -v"
  refute source =~ "adoption_demo_"
end
```

**Docs contract pattern** (lines 134-159):

```elixir
test "docs explain direct conflict controls and scoped reset" do
  docs = File.read!(@adoption_demo_docs_path)

  assert docs =~ "COMPOSE_PROJECT_NAME"
  assert docs =~ "LOCKSPIRE_DEMO_APP_PORT"
  assert docs =~ "LOCKSPIRE_DEMO_BASE_URL"
  assert docs =~ "examples/adoption_demo/bin/docker-reset"
  assert docs =~
           "LOCKSPIRE_DEMO_BASE_URL=http://127.0.0.1:4101 python3 scripts/demo/adoption_smoke.py"
end
```

**Compose config helper pattern** (lines 161-189):

```elixir
defp with_compose_config(args, opts \\ [], fun) do
  case compose_config(args, opts) do
    {:ok, config} ->
      fun.(config)

    :skip ->
      IO.puts("Skipping adoption demo Docker contract assertions: docker compose is unavailable")
  end
end

defp compose_config(args, opts) do
  env = Keyword.get(opts, :env, [])

  case System.cmd(
         "docker",
         ["compose"] ++ args ++ ["config", "--format", "json"],
         cd: @repo_root,
         env: env,
         stderr_to_stdout: true
       ) do
    {json, 0} -> {:ok, Jason.decode!(json)}
    {output, _status} -> raise output
  end
rescue
  ErlangError -> :skip
end
```

**Apply to Phase 114:** Add `@docker_info_path` and optional `@adoption_smoke_wrapper_path`. Assert required strings exist, active base URL trimming is present, startup calls `./bin/docker-info` after readiness, docs include reprint/stop/reset/troubleshooting, and forbidden sensitive values are absent from `docker-info` and docs.

---

### `examples/adoption_demo/docker-compose.yml` (config, request-response)

**Analog:** `examples/adoption_demo/docker-compose.yml`

**Compose service pattern** (lines 1-23):

```yaml
name: lockspire-adoption-demo

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
      - "${LOCKSPIRE_DEMO_APP_PORT:-4100}:${LOCKSPIRE_DEMO_APP_PORT:-4100}"
    environment:
      PHX_SERVER: "true"
      PORT: "${LOCKSPIRE_DEMO_APP_PORT:-4100}"
      LOCKSPIRE_DEMO_BASE_URL: "${LOCKSPIRE_DEMO_BASE_URL:-http://127.0.0.1:${LOCKSPIRE_DEMO_APP_PORT:-4100}}"
      LOCKSPIRE_DEMO_BIND_IP: "0.0.0.0"
```

**DB/internal volume pattern** (lines 30-47):

```yaml
db:
  image: postgres:14
  environment:
    POSTGRES_DB: "lockspire_adoption_demo"
    POSTGRES_USER: "lockspire"
    POSTGRES_PASSWORD: "lockspire"
  healthcheck:
    test: ["CMD-SHELL", "pg_isready -U lockspire -d lockspire_adoption_demo"]
  volumes:
    - db_data:/var/lib/postgresql/data

volumes:
  db_data:
  deps_volume:
  build_volume:
```

**Apply to Phase 114:** No Compose topology change should be necessary. If tests/docs touch it, preserve direct Docker as default, command `./bin/docker-start`, project-scoped volumes, and `LOCKSPIRE_DEMO_BASE_URL` environment truth.

---

### `examples/adoption_demo/docker-compose.traefik.yml` (config, request-response)

**Analog:** `examples/adoption_demo/docker-compose.traefik.yml`

**Optional override pattern** (lines 1-16):

```yaml
services:
  web:
    labels:
      - "traefik.enable=true"
      - "traefik.docker.network=${LOCKSPIRE_DEMO_TRAEFIK_NETWORK:-local-dev-proxy}"
      - "traefik.http.routers.${LOCKSPIRE_DEMO_TRAEFIK_ROUTER:-lockspire-adoption-demo}.rule=Host(`${LOCKSPIRE_DEMO_TRAEFIK_HOST:-lockspire-demo.localhost}`)"
      - "traefik.http.routers.${LOCKSPIRE_DEMO_TRAEFIK_ROUTER:-lockspire-adoption-demo}.service=${LOCKSPIRE_DEMO_TRAEFIK_SERVICE:-lockspire-adoption-demo}"
      - "traefik.http.services.${LOCKSPIRE_DEMO_TRAEFIK_SERVICE:-lockspire-adoption-demo}.loadbalancer.server.port=${LOCKSPIRE_DEMO_APP_PORT:-4100}"
    networks:
      - default
      - traefik_proxy

networks:
  traefik_proxy:
    external: true
    name: "${LOCKSPIRE_DEMO_TRAEFIK_NETWORK:-local-dev-proxy}"
```

**Apply to Phase 114:** Keep Traefik optional. Docs and smoke examples must set `LOCKSPIRE_DEMO_BASE_URL=http://lockspire-demo.localhost` or the configured hostname when this override is used.

## Shared Patterns

### Single Base URL Truth

**Source:** `examples/adoption_demo/config/config.exs` and `examples/adoption_demo/docker-compose.yml`
**Apply to:** `docker-start`, `docker-info`, smoke wrapper, docs, contract tests

```elixir
demo_base_url =
  "LOCKSPIRE_DEMO_BASE_URL"
  |> System.get_env("http://127.0.0.1:4100")
  |> String.trim()
  |> String.trim_trailing("/")

config :lockspire,
  issuer: demo_base_url <> "/lockspire",
  mount_path: "/lockspire",
```

```yaml
LOCKSPIRE_DEMO_BASE_URL: "${LOCKSPIRE_DEMO_BASE_URL:-http://127.0.0.1:${LOCKSPIRE_DEMO_APP_PORT:-4100}}"
```

### Redaction Allowlist

**Source:** `examples/adoption_demo/lib/adoption_demo/accounts.ex`, `examples/adoption_demo/priv/repo/seeds.exs`
**Apply to:** `docker-info`, `docs/adoption-demo.md`, contract tests

Allowed output includes:

```text
alice / alice@acme.test / SaaS user
bob / bob@globex.test / SaaS user
ops / ops@acme.test / Operator / operator account
acme-ledger-public / public / authorization_code + PKCE / token auth none
acme-tv-device / public / device authorization / token auth none
acme-ledger-backend / confidential / authorization_code + PKCE / client_secret_basic / secret not shown
northstar-dcr-self-registered / confidential / self-registered DCR fixture / client_secret_basic / secret not shown
legacy-disabled-reporter / confidential / disabled fixture / client_secret_basic / secret not shown
```

Forbidden output should include negative assertions for source/docs:

```text
demo-backend-secret
demo-rat-secret
demo-disabled-secret
demo-rat-northstar
private_jwk
private_jwk_encrypted
token_hash
device_code_hash
user_code_hash
refresh token value
access token value
cookie value
```

### Source/Docs Contract Testing

**Source:** `test/lockspire/adoption_demo_docker_contract_test.exs`
**Apply to:** all Phase 114 local tooling and docs changes

```elixir
source = File.read!(@docker_reset_path)
assert source =~ "COMPOSE_PROJECT_NAME"
refute source =~ "docker volume prune"

docs = File.read!(@adoption_demo_docs_path)
assert docs =~ "LOCKSPIRE_DEMO_BASE_URL"
assert docs =~ "examples/adoption_demo/bin/docker-reset"
```

### Compose Rendering Contract

**Source:** `test/lockspire/adoption_demo_docker_contract_test.exs`
**Apply to:** Compose docs/tests if Phase 114 touches compose behavior

```elixir
System.cmd(
  "docker",
  ["compose"] ++ args ++ ["config", "--format", "json"],
  cd: @repo_root,
  env: env,
  stderr_to_stdout: true
)
```

## No Analog Found

All likely Phase 114 files have close analogs in the current codebase. The optional smoke wrapper has no exact shell wrapper next to `scripts/demo/adoption_smoke.py`, but `examples/adoption_demo/bin/docker-reset` provides the shell CLI style and `scripts/demo/adoption_smoke.py` provides the runtime contract.

## Metadata

**Analog search scope:** `examples/adoption_demo/bin`, `examples/adoption_demo/config`, `examples/adoption_demo/lib`, `examples/adoption_demo/priv/repo`, `scripts/demo`, `docs`, `test/lockspire`, Compose files under `examples/adoption_demo`
**Files scanned:** 14
**Pattern extraction date:** 2026-06-24
