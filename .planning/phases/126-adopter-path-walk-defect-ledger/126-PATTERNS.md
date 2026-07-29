# Phase 126: Adopter Path Walk & Defect Ledger - Pattern Map

**Mapped:** 2026-07-28
**Files analyzed:** 7 (4 new, 3 modified)
**Analogs found:** 7 / 7

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `scripts/maintainer/adopter_path_walk.sh` (NEW) | maintainer harness script | batch / step-machine | `scripts/maintainer/repo_hygiene_check.sh` | exact (same tier, same accumulator+verdict flow) |
| ^ clean-room generation portion | maintainer harness script | file-I/O + subprocess | `scripts/publish/verify_install_truth.sh:66-88` | role-match (reject its cleanup + `--no-*` flags) |
| ^ boot-and-drive portion | maintainer harness script | process lifecycle | `.github/workflows/ci.yml:312-329` | exact |
| `scripts/maintainer/adopter_path_flow.py` (NEW) | HTTP flow driver | request-response over HTTP | `scripts/demo/adoption_smoke.py` | exact (copy, do not edit source) |
| `mix.exs` aliases (MODIFIED) | config | n/a | `mix.exs:94-98` (`conformance.phase37`) | exact |
| `.gitignore` (MODIFIED) | config | n/a | `.gitignore:10` (`/tmp/`) | exact |
| `.planning/phases/126-.../126-DEFECT-LEDGER.md` (NEW) | committed evidence doc | n/a | `.planning/milestones/v1.9-MILESTONE-AUDIT.md` | role-match |
| `test/lockspire/maintainer/adopter_walk_contract_test.exs` (NEW) | contract test | file-content assertion | `test/lockspire/adoption_demo_docker_contract_test.exs` | exact |
| `test/lockspire/maintainer/defect_ledger_contract_test.exs` (NEW) | contract test | file-content assertion | `test/lockspire/adoption_demo_docker_contract_test.exs` + `release_readiness_contract_test.exs` | exact |

---

## Pattern Assignments

### `scripts/maintainer/adopter_path_walk.sh` (maintainer harness, batch step-machine)

**Primary analog:** `scripts/maintainer/repo_hygiene_check.sh`

**Shebang + strict mode** (`repo_hygiene_check.sh:1-2`) — **DEVIATE HERE**:

```bash
#!/usr/bin/env bash
set -euo pipefail      # <-- hygiene uses this; the walk MUST use `set -uo pipefail`
```

Per RESEARCH Pitfall 10 / D-18, the walk uses `set -uo pipefail` (no `-e`) so a FAIL step does not
abort the run. Reserve `set -e` for the preflight, run in a subshell.

**Flag parsing + usage heredoc** (`repo_hygiene_check.sh:4-55`) — copy verbatim shape:

```bash
MODE="local"
RUN_MIX_CI=1
REMOTE="${LOCKSPIRE_HYGIENE_REMOTE:-origin}"

usage() {
  cat <<'EOF'
Usage: repo_hygiene_check.sh [--ci] [--project NAME] [--skip-mix-ci]

Checks whether the repo is in a disciplined release-prep state.

Modes:
  --ci           Run only repo-owned drift checks that GitHub can prove.
  --project NAME Scope local adoption-demo Docker hygiene to a Compose project.
  --skip-mix-ci  Skip the local mix ci contributor gate rerun.

Examples:
  bash ./scripts/maintainer/repo_hygiene_check.sh --ci
EOF
}

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --ci)
      MODE="ci"
      shift
      ;;
    --project)
      if [[ "$#" -lt 2 ]]; then
        echo "Missing value for --project" >&2
        usage >&2
        exit 1
      fi
      project="$2"
      shift 2
      ;;
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

Walk flags per D-19/D-12: `--workdir DIR`, `--from-step NN`, `--keep`, `--port N`, `--force`, `-h`.
Note the two-arg form (`shift 2` with a `$# -lt 2` guard) is the established value-flag idiom.

**Required-command preflight** (`repo_hygiene_check.sh:57-60`, and `verify_install_truth.sh:8-14`
for the loop form):

```bash
if ! command -v git >/dev/null 2>&1; then
  echo "[BLOCK] git: required command is not installed" >&2
  exit 1
fi
```

```bash
for cmd in curl jq mix sed; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "Error: required command '$cmd' is not installed."
    exit 1
  fi
done
```

Walk adapts this to a `fail_prerequisite` function emitting a distinctly-named `PREREQUISITE` error
(D-14) that exits before any `record_result` — a missing tool must never land in the ledger.

**Repo-root resolution** (`repo_hygiene_check.sh:62-63`, identical in `adoption_smoke.sh:39-40`):

```bash
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$REPO_ROOT"
```

This is the value written into the generated `mix.exs` as `{:lockspire, path: "<REPO_ROOT>"}` (D-04),
and the base for `MIX_ARCHIVES="$REPO_ROOT/.harness/archives"` (D-06).

**Accumulator** (`repo_hygiene_check.sh:65-82`) — copy, dropping WARN (D-17: binary verdict):

```bash
declare -a RESULTS=()
PASS_COUNT=0
WARN_COUNT=0
BLOCK_COUNT=0

record_result() {
  local level="$1"
  local label="$2"
  local detail="$3"

  RESULTS+=("[$level] $label: $detail")

  case "$level" in
    PASS) PASS_COUNT=$((PASS_COUNT + 1)) ;;
    WARN) WARN_COUNT=$((WARN_COUNT + 1)) ;;
    BLOCK) BLOCK_COUNT=$((BLOCK_COUNT + 1)) ;;
  esac
}
```

Walk uses `PASS`/`FAIL` only, and `label` is the step ID + guide section (D-17):
`record_result PASS "step-03b-router" "§3 wire: routes defined"`.

**Predicate helper functions** (`repo_hygiene_check.sh:107-118`) — the established shape for a check
is a named boolean function, called inside an `if`, never inline:

```bash
release_train_has_required_lines() {
  grep -Fq 'Lockspire is on a sustaining GA release train.' .planning/RELEASE-TRAIN.md &&
    grep -Fq -- '- `milestone: none` remains the default GSD state.' .planning/RELEASE-TRAIN.md
}

source_has_no_broad_cleanup() {
  local file="$1"

  ! grep -Eq 'docker[[:space:]]+system[[:space:]]+prune' "$file"
}
```

**Check → record idiom** (`repo_hygiene_check.sh:253-268`) — every step body follows this exactly:

```bash
  if grep -Fq 'exec python3 scripts/demo/adoption_smoke.py' scripts/demo/adoption_smoke.sh &&
     grep -Fq 'exercise_authorization_code' scripts/demo/adoption_smoke.py; then
    record_result "PASS" "smoke wrapper contract" "scripts/demo/adoption_smoke.py remains the black-box OAuth/OIDC proof"
  else
    record_result "BLOCK" "smoke wrapper contract" "wrapper must only delegate"
  fi
```

Walk form (D-18/D-19 resume markers folded in):

```bash
if should_run step-04-migrate; then
  if run_in_host mix ecto.migrate; then
    record_result "PASS" "step-04-migrate" "§4: mix ecto.migrate exited 0"
    mark_done step-04-migrate
  else
    record_result "FAIL" "step-04-migrate" "§4: <error class>"
  fi
fi
```

**Report + summary + verdict exit** (`repo_hygiene_check.sh:507-521`) — copy the printf shape:

```bash
printf 'Lockspire repo hygiene report (%s)\n' "$MODE"
printf '%s\n' "${RESULTS[@]}"
printf 'Summary: %s PASS, %s WARN, %s BLOCK\n' "$PASS_COUNT" "$WARN_COUNT" "$BLOCK_COUNT"

if [[ "$BLOCK_COUNT" -gt 0 ]]; then
  echo "Result: not ready"
  exit 1
fi

if [[ "$WARN_COUNT" -gt 0 ]]; then
  echo "Result: proceed with caution"
  exit 0
fi

echo "Result: safe to start release prep"
```

Walk verdict: `Summary: %s PASS, %s FAIL`, then `Result: adopter path is RED` / `GREEN` (D-17).

**Top-level invocation ordering** (`repo_hygiene_check.sh:497-505`) — grouped check functions called
at file bottom, mode-gated:

```bash
  local_demo_docker_hygiene_checks
  local_demo_artifact_hygiene_checks
}

repo_owned_checks

if [[ "$MODE" != "ci" ]]; then
  local_checks
fi
```

---

**Secondary analog (clean-room generation):** `scripts/publish/verify_install_truth.sh:66-88`

**Archive install + generation** (`verify_install_truth.sh:66-75`) — copy the mechanics, **reject**
both the missing `MIX_ARCHIVES` isolation and the `--no-*` flags:

```bash
echo "==> Generating clean-room Phoenix host app..."
cd "$TMP_DIR"
mix local.hex --force
mix local.rebar --force
# Accept 'Y' to any prompt if needed, though --force should suffice
mix archive.install hex phx_new --force

mix phx.new host_app --no-assets --no-ecto --no-html --no-mailer
```

Corrections required (D-05/D-06/D-07):
- `export MIX_ARCHIVES="$REPO_ROOT/.harness/archives"` before any archive command
- `mix archive.install hex phx_new 1.8.9 --force` (pinned)
- assert `mix phx.new --version` == `Phoenix installer v1.8.9`
- `mix phx.new host_app --database postgres --install` — **no** `--no-*` flags

**Dependency injection into the generated `mix.exs`** (`verify_install_truth.sh:76-81`) — the sed
portability pattern is the reusable part:

```bash
if [[ "$OSTYPE" == "darwin"* ]]; then
  sed -i '' -e "s/{:phoenix,/{:lockspire, \"$EXPECTED_VERSION\"},\n      {:phoenix,/" mix.exs
else
  sed -i -e "s/{:phoenix,/{:lockspire, \"$EXPECTED_VERSION\"},\n      {:phoenix,/" mix.exs
fi
```

The walk writes `{:lockspire, path: "$REPO_ROOT"}` instead (D-04). The same BSD/GNU `sed -i` split is
needed again for the `config/dev.exs` port patch (RESEARCH assumption A2).

**ANTI-PATTERN — do not copy** (`verify_install_truth.sh:4-6`, forbidden by D-20):

```bash
echo "==> Setting up verification environment..."
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT
```

Use a stable `tmp/adopter-walk/` workdir with no `rm -rf` trap. The only trap is the pid kill below.

---

**Tertiary analog (boot-and-drive):** `.github/workflows/ci.yml:312-329`

```bash
mkdir -p tmp
cd examples/adoption_demo
mix phx.server > ../../tmp/adoption_demo.log 2>&1 &
server_pid=$!
cd ../..

set +e
python3 scripts/demo/adoption_smoke.py
smoke_status=$?
kill "$server_pid" 2>/dev/null || true

if [ "$smoke_status" -ne 0 ]; then
  cat tmp/adoption_demo.log
  exit "$smoke_status"
fi
```

Walk adaptation (D-11 + the orphan-process mitigation from RESEARCH Runtime State Inventory):
redirect to `$WORKDIR/server.log`, add `trap 'kill "$server_pid" 2>/dev/null || true' EXIT INT TERM`
(pid only — never `rm -rf`), and replace the `exit "$smoke_status"` with a `record_result FAIL` so
step-07/step-08 still reach the summary.

**Postgres env-var convention** (`.github/workflows/ci.yml:38-58`) — the walk resolves its DB config
in this shape (D-13), with `PGHOST`/`PGPORT`/`PGUSER` fallbacks:

```yaml
      postgres:
        image: postgres:16
        env:
          POSTGRES_DB: lockspire_test
          POSTGRES_USER: lockspire
          POSTGRES_PASSWORD: lockspire
        options: >-
          --health-cmd "pg_isready -U lockspire -d lockspire_test"
    env:
      LOCKSPIRE_TEST_DB_HOST: 127.0.0.1
      LOCKSPIRE_TEST_DB_PORT: "5432"
      LOCKSPIRE_TEST_DB_USER: lockspire
      LOCKSPIRE_TEST_DB_PASSWORD: lockspire
```

Walk uses `LOCKSPIRE_WALK_DB_{HOST,PORT,USER,PASSWORD,NAME}` and a walk-specific database name that
never collides with `lockspire_test` or `lockspire_adoption_demo`.

---

### `scripts/maintainer/adopter_path_flow.py` (HTTP driver, request-response)

**Analog:** `scripts/demo/adoption_smoke.py` — **copy from, never edit** (`repo_hygiene_check.sh:262-268`
is a BLOCK-level contract on its contents).

**Imports + module constants** (`adoption_smoke.py:1-15`) — stdlib only, no third-party imports:

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


BASE_URL = os.environ.get("LOCKSPIRE_DEMO_BASE_URL", "http://lockspire-demo.localhost").rstrip("/")
```

Walk driver: take `--base-url` (or `LOCKSPIRE_WALK_BASE_URL`), defaulting to `http://127.0.0.1:4200`
(D-12). Keep the `.rstrip("/")`.

**`Browser` class — cookie jar + redirect chasing** (`adoption_smoke.py:18-78`) — copy verbatim:

```python
class Browser:
    def __init__(self, base_url):
        self.base = base_url.rstrip("/")
        self.origin = urlparse(self.base)
        self.cookies = {}

    def request(self, method, target, data=None, headers=None, follow=False):
        url = urljoin(self.base + "/", target)
        for _ in range(8):
            response = self._single_request(method, url, data, headers)
            if not follow or response["status"] not in (301, 302, 303, 307, 308):
                return response

            location = response["headers"].get("location")
            if not location:
                return response

            url = urljoin(url, location)
            if response["status"] == 303 or method.upper() != "GET":
                method, data = "GET", None

        raise AssertionError("too many redirects")

    def _single_request(self, method, url, data, headers):
        parsed = urlparse(url)
        body = None
        request_headers = dict(headers or {})

        if isinstance(data, dict):
            body = urlencode(data).encode()
            request_headers.setdefault("content-type", "application/x-www-form-urlencoded")
        elif isinstance(data, bytes):
            body = data

        if self.cookies:
            request_headers["cookie"] = "; ".join(f"{key}={value}" for key, value in self.cookies.items())

        conn = http.client.HTTPConnection(parsed.hostname, parsed.port or 80, timeout=10)
        path = parsed.path or "/"
        if parsed.query:
            path += "?" + parsed.query

        conn.request(method.upper(), path, body=body, headers=request_headers)
        resp = conn.getresponse()
        raw_body = resp.read()
        header_pairs = resp.getheaders()
        conn.close()

        for name, value in header_pairs:
            if name.lower() == "set-cookie":
                cookie = SimpleCookie()
                cookie.load(value)
                for key, morsel in cookie.items():
                    self.cookies[key] = morsel.value

        return {
            "status": resp.status,
            "headers": {name.lower(): value for name, value in header_pairs},
            "body": raw_body.decode("utf-8", "replace"),
            "url": url,
        }
```

**Assertion helpers** (`adoption_smoke.py:81-122`) — copy verbatim; body truncation at 600 chars is
the established error-detail budget:

```python
def assert_status(response, expected, label):
    if response["status"] != expected:
        raise AssertionError(f"{label}: expected HTTP {expected}, got {response['status']}\n{response['body'][:600]}")


def assert_contains(response, needle, label):
    if needle not in response["body"]:
        raise AssertionError(f"{label}: missing {needle!r}\n{response['body'][:600]}")


def assert_equal(actual, expected, label):
    if actual != expected:
        raise AssertionError(
            f"{label}: expected {expected!r}, got {actual!r} "
            f"(LOCKSPIRE_DEMO_BASE_URL={BASE_URL!r})"
        )


def location(response):
    value = response["headers"].get("location")
    if not value:
        raise AssertionError(f"missing location header on HTTP {response['status']}")
    return value


def code_challenge(verifier):
    digest = hashlib.sha256(verifier.encode()).digest()
    return base64.urlsafe_b64encode(digest).rstrip(b"=").decode()


def json_body(response, label):
    try:
        return json.loads(response["body"])
    except json.JSONDecodeError as exc:
        raise AssertionError(f"{label}: invalid JSON: {exc}\n{response['body'][:600]}")
```

**CSRF scrape** (`adoption_smoke.py:99-103`) — **must be replaced**, not copied (D-25 + Pitfall 5).
The existing pattern misses LiveView output:

```python
def csrf(body):
    match = re.search(r'name="_csrf_token"\s+value="([^"]+)"', body)
    if not match:
        raise AssertionError("missing CSRF token")
    return match.group(1)
```

Replacement (from RESEARCH Code Examples), with the `<meta name="csrf-token">` fallback for
`ConsentLive`, which emits no form token at all:

```python
_FORM_TOKEN = re.compile(r'name="_csrf_token"[^>]*\bvalue="([^"]+)"')
_META_TOKEN = re.compile(r'<meta[^>]*name="csrf-token"[^>]*content="([^"]+)"')

def csrf(body, label="page"):
    for pattern in (_FORM_TOKEN, _META_TOKEN):
        match = pattern.search(body)
        if match:
            return match.group(1)
    raise AssertionError(f"{label}: missing CSRF token")
```

**Readiness poll** (`adoption_smoke.py:125-139`) — copy, retarget to the discovery endpoint:

```python
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

Walk: poll `GET /lockspire/.well-known/openid-configuration` and additionally require
`GET /lockspire/jwks` to publish ≥ 1 key before `step-07` (RESEARCH Open Question 1).

**Login helper** (`adoption_smoke.py:142-154`) — the demo's flat-param shape is **wrong** for
`phx.gen.auth` (Pitfall 7). Structure is the analog; params must nest under `user[...]`:

```python
def login(browser, account, return_to="/", interaction_id=None):
    page = browser.request("GET", "/login")
    assert_status(page, 200, "login page")

    params = {
        "_csrf_token": csrf(page["body"]),
        "login": account,
        "return_to": return_to,
    }
    if interaction_id:
        params["interaction_id"] = interaction_id

    return browser.request("POST", "/login", params)
```

Walk replacement — path `/users/log-in`, nested params, and `return_to` navigated by the driver
itself because `log_in_user/3` ignores the query param:

```python
def login(browser, email, password):
    page = browser.request("GET", "/users/log-in")
    assert_status(page, 200, "login page")
    return browser.request("POST", "/users/log-in", {
        "_csrf_token": csrf(page["body"], "login page"),
        "user[email]": email,
        "user[password]": password,
    })
```

**Core authorization-code + PKCE sequence** (`adoption_smoke.py:221-290`) — this is the highest-value
excerpt; adapt with walk-specific `client_id`, no `resource` param, and no admin/CSS assertions:

```python
def exercise_authorization_code():
    browser = Browser(BASE_URL)
    verifier = "demo-pkce-verifier"
    state = "smoke-state"
    authorize_params = {
        "response_type": "code",
        "client_id": "billingo-dashboard-public",
        "redirect_uri": BASE_URL + "/oauth/callback",
        "scope": "openid email profile read:billing",
        "state": state,
        "nonce": "smoke-nonce",
        "prompt": "consent",
        "code_challenge": code_challenge(verifier),
        "code_challenge_method": "S256",
        "resource": BILLING_RESOURCE,
    }

    start = browser.request("GET", "/lockspire/authorize?" + urlencode(authorize_params))
    assert_status(start, 302, "authorize starts login handoff")

    handoff = urlparse(location(start))
    handoff_params = parse_qs(handoff.query)
    interaction_id = handoff_params["interaction_id"][0]
    return_to = handoff_params["return_to"][0]

    logged_in = login(browser, "alice", return_to, interaction_id)
    assert_status(logged_in, 302, "account login")

    resumed = browser.request("GET", location(logged_in))
    assert_status(resumed, 302, "interaction resume")

    consent = browser.request("GET", location(resumed))
    assert_status(consent, 200, "consent page")
    assert_contains(consent, "Approve access", "consent page")

    completed = browser.request(
        "POST",
        f"/lockspire/interactions/{interaction_id}/complete",
        {"_csrf_token": csrf(consent["body"]), "decision": "approve", "remember": "true"},
    )
    assert_status(completed, 302, "consent approval")

    callback_url = urljoin(BASE_URL + "/", location(completed))
    callback = urlparse(callback_url)
    callback_without_query = callback._replace(query="", fragment="").geturl()
    assert_equal(callback_without_query, BASE_URL + "/oauth/callback", "authorization callback redirect_uri")
    callback_params = parse_qs(callback.query)
    assert_equal(callback_params["state"][0], state, "authorization callback state")
    code = callback_params["code"][0]

    token = browser.request(
        "POST",
        "/lockspire/token",
        {
            "grant_type": "authorization_code",
            "client_id": "billingo-dashboard-public",
            "redirect_uri": BASE_URL + "/oauth/callback",
            "code": code,
            "code_verifier": verifier,
            "resource": BILLING_RESOURCE,
        },
    )
    assert_status(token, 200, "token exchange")
    token_json = json_body(token, "token exchange")
    assert token_json["access_token"]
    assert token_json["id_token"]
```

Note: `login(browser, "alice", return_to, interaction_id)` handles the handoff by passing
`return_to` into the login POST. The walk cannot — `phx.gen.auth` ignores it (Pitfall 7) — so after
the login POST the driver must `browser.request("GET", return_to)` itself.

**Two-layer token proof** (`adoption_smoke.py:292-320`) — this is the ADOPT-04 template, already
asserting userinfo + anonymous-401 + authed-200 + claim inspection:

```python
    userinfo = browser.request(
        "GET",
        "/lockspire/userinfo",
        headers={"authorization": "Bearer " + token_json["access_token"]},
    )
    assert_status(userinfo, 200, "userinfo accepts issued access token")
    userinfo_json = json_body(userinfo, "userinfo")
    assert userinfo_json["email"] == "alice@billingo.test"

    # BEGIN LOCKSPIRE_PROTECTED_PIPELINE
    # pipeline :lockspire_protected_api do
    #   plug Lockspire.Plug.VerifyToken, scopes: ["read:billing"], audience: "https://api.billingo.test/billing", enforce_audience: true
    #   plug Lockspire.Plug.EnforceSenderConstraints,
    #     dpop_replay_store: MyAppWeb.ProtectedApiReplayStore
    #   plug Lockspire.Plug.RequireToken
    # end
    # END LOCKSPIRE_PROTECTED_PIPELINE

    anonymous_api = Browser(BASE_URL).request("GET", "/api/billing/summary")
    assert_status(anonymous_api, 401, "protected API rejects anonymous request")

    authed_api = Browser(BASE_URL).request(
        "GET",
        "/api/billing/summary",
        headers={"authorization": "Bearer " + token_json["access_token"]},
    )
    assert_status(authed_api, 200, "protected API accepts issued at+jwt")
    authed_api_json = json_body(authed_api, "billing summary")
    assert BILLING_RESOURCE in authed_api_json["access_token"]["audience"]
```

Note the fresh `Browser(BASE_URL)` for the API calls — no cookie jar, so the 200 is proven by the
bearer token alone. Copy that detail; it is what makes ADOPT-04's claim real.

**`main()` + failure exit** (`adoption_smoke.py:380-393`) — copy verbatim shape:

```python
def main():
    wait_until_ready()
    exercise_discovery_and_admin()
    exercise_authorization_code()
    exercise_device_flow()
    print("adoption demo smoke passed")


if __name__ == "__main__":
    try:
        main()
    except Exception as exc:
        print(f"adoption demo smoke failed: {exc}", file=sys.stderr)
        sys.exit(1)
```

**Wrapper delegation** — if a `.sh` wrapper is added, `scripts/demo/adoption_smoke.sh:34-47` is the
exact shape (git-root resolution, base-URL normalization, `exec python3 …`). Per D-01 the walk's
entry point is the `mix adopter.walk` alias, so a separate wrapper is likely unnecessary.

---

### `mix.exs` — one alias line (config)

**Analog:** `mix.exs:94-98` — the only existing alias that shells out to a maintainer script:

```elixir
      "conformance.phase37": [
        "test.setup",
        "test --include integration test/integration/phase37_protocol_strictness_e2e_test.exs",
        "cmd bash scripts/conformance/run_phase37_suite.sh"
      ],
```

New entry (D-01), added to `aliases/0` and **not** to `ci:` (`mix.exs:117-126`):

```elixir
      "adopter.walk": ["cmd bash scripts/maintainer/adopter_path_walk.sh"],
```

Deps list (`mix.exs:56-67`) is untouched — this phase adds no packages.

---

### `.gitignore` — add `.harness/` (config)

**Analog:** `.gitignore:1-12`, which already covers the workdir via `/tmp/`:

```
/_build/
/deps/
/examples/*/_build/
/examples/*/deps/
/.elixir_ls/
/.DS_Store
**/.DS_Store
/.bg-shell/
/doc/
/tmp/
/.gsd/
/priv/plts/
```

Add `/.harness/` alongside `/tmp/` (D-08). `tmp/adopter-walk/` needs no new entry.

---

### `.planning/phases/126-.../126-DEFECT-LEDGER.md` (committed evidence doc)

**Analog:** `.planning/milestones/v1.9-MILESTONE-AUDIT.md` — the precedent for a committed,
YAML-front-mattered evidence document under `.planning/` (D-36/D-38):

```markdown
---
milestone: v1.9
audited: 2026-04-29T20:30:00Z
status: passed
scores:
  requirements: 2/2
  phases: 1/1
gaps:
  requirements: []
tech_debt: []
---

# Milestone v1.9 Audit

## Verdict

`v1.9 JAR Decryption (JWE Support)` clears the milestone audit gate.

## Scope

- Milestone: `v1.9 JAR Decryption (JWE Support)`
- Phases in scope: `40`
- Completed requirements: `2` (AUTHZ-01, AUTHZ-02)

## Phase Verification Status

| Phase | Name | Verification | Result | Notes |
|-------|------|--------------|--------|-------|
| 40 | JWE Support for Request Objects | present | passed | JWE decryption tests pass. |
```

Ledger adaptation — front matter carries the run verdict and counts; the body carries one row/section
per defect with all six D-37 fields (ID, walk step ID, symptom, underlying error, source, owning
phase, workaround). Table columns map 1:1 onto the `| Phase | Name | Verification | Result | Notes |`
shape. Per RESEARCH Security V7: record error classes and step IDs only — never raw tokens, codes,
or the seeded password.

---

### `test/lockspire/maintainer/*_contract_test.exs` (contract tests, file-content assertion)

**Analog:** `test/lockspire/adoption_demo_docker_contract_test.exs:1-18` — module header + path
constants resolved relative to `__DIR__`:

```elixir
defmodule Lockspire.AdoptionDemoDockerContractTest do
  use ExUnit.Case, async: false

  @repo_root Path.expand("../..", __DIR__)
  @compose_file "examples/adoption_demo/docker-compose.yml"
  @makefile_path Path.join(@repo_root, "Makefile")
  @docker_info_path Path.join(@repo_root, "examples/adoption_demo/bin/docker-info")
  @dockerignore_path Path.join(@repo_root, ".dockerignore")
  @adoption_smoke_wrapper_path Path.join(@repo_root, "scripts/demo/adoption_smoke.sh")
```

Note: new tests live one directory deeper (`test/lockspire/maintainer/`), so use
`Path.expand("../../..", __DIR__)`. `release_readiness_contract_test.exs:20-21` shows the alternate
per-file form:

```elixir
  @maintainer_guide_path Path.expand("../../docs/maintainer-release.md", __DIR__)
  @release_workflow_path Path.expand("../../.github/workflows/ci.yml", __DIR__)
```

**Assertion body** (`adoption_demo_docker_contract_test.exs:19-51`) — `=~` for presence, `refute =~`
for forbidden content, `File.read!` for source-level contracts:

```elixir
  test "docker-info prints base URL derived startup links and exact smoke command" do
    output = docker_info_output("http://127.0.0.1:4101/")

    assert output =~ "Billingo + Lockspire demo"
    assert output =~ "Smoke: make demo-smoke"

    assert_ordered(output, [
      "Operator admin: http://127.0.0.1:4101/lockspire/admin",
      "Base URL: http://127.0.0.1:4101"
    ])

    refute output =~ "http://127.0.0.1:4101//"
    refute output =~ "python3 scripts/demo/adoption_smoke.py"
  end
```

```elixir
  test "docker-info prints seeded client allowlist without sensitive material" do
    output = docker_info_output()
    source = File.read!(@docker_info_path)
```

Walk contract tests map directly onto this:
- `refute source =~ ~r/--no-(ecto|html|assets|mailer)/` (ADOPT-02)
- `assert source =~ "MIX_ARCHIVES"` and `assert source =~ "phx_new 1.8.9"` (ADOPT-02)
- `refute source =~ ~r/trap .*rm -rf/` (ADOPT-03)
- `assert source =~ ".walk/steps"` and `assert source =~ "--from-step"` (ADOPT-03)
- marker↔ledger set equality: `Regex.scan(~r/LOCKSPIRE_WALK_WORKAROUND: (ADOPT-D\d+)/, source)`
  vs IDs parsed from the ledger (criterion 5)

`async: false` is used by the Docker contract test because it shells out; the walk contract tests are
pure `File.read!` and can be `async: true` (as `release_readiness_contract_test.exs:2` is).

---

## Shared Patterns

### Grep-able source markers as contracts
**Source:** `scripts/demo/adoption_smoke.py:301-308`
**Apply to:** `adopter_path_walk.sh`, `adopter_path_flow.py`, `126-DEFECT-LEDGER.md`

```python
    # BEGIN LOCKSPIRE_PROTECTED_PIPELINE
    # pipeline :lockspire_protected_api do
    #   plug Lockspire.Plug.VerifyToken, scopes: ["read:billing"], audience: "https://api.billingo.test/billing", enforce_audience: true
    #   plug Lockspire.Plug.EnforceSenderConstraints,
    #     dpop_replay_store: MyAppWeb.ProtectedApiReplayStore
    #   plug Lockspire.Plug.RequireToken
    # end
    # END LOCKSPIRE_PROTECTED_PIPELINE
```

D-40's `# LOCKSPIRE_WALK_WORKAROUND: ADOPT-Dnn` follows this exact convention: an uppercase
underscore token in a comment, enforced by a `grep -Fq` / `Regex.scan` contract elsewhere.

### `grep -Fq` contract enforcement
**Source:** `scripts/maintainer/repo_hygiene_check.sh:253-268, 303-309`
**Apply to:** any in-script assertion the walk makes about repo content

```bash
  if grep -Fq '"component": "lockspire"' release-please-config.json &&
     grep -Fq '"include-v-in-tag": true' release-please-config.json; then
    record_result "PASS" "release-please config" "root package release policy matches the maintained tag and package contract"
  else
    record_result "BLOCK" "release-please config" "release-please-config.json drifted from the maintained root package policy"
  fi
```

Note `-F` (fixed string) is the default; `-E` only where a real regex is needed
(`repo_hygiene_check.sh:117`). Prefer `-F`.

### Repo-root resolution before any relative path
**Source:** `scripts/maintainer/repo_hygiene_check.sh:57-63`, `scripts/demo/adoption_smoke.sh:34-40`
**Apply to:** `adopter_path_walk.sh`

```bash
if ! command -v git >/dev/null 2>&1; then
  echo "git is required to locate the Lockspire repo root" >&2
  exit 1
fi

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$REPO_ROOT"
```

Mandatory here because `mix adopter.walk` runs from the project root but the script must also work
when invoked directly, and `REPO_ROOT` is the literal value written into the generated `mix.exs`.

### Usage heredoc with a Modes/Examples block
**Source:** `scripts/maintainer/repo_hygiene_check.sh:9-24`, `scripts/demo/adoption_smoke.sh:6-19`
**Apply to:** `adopter_path_walk.sh`

Both use `cat <<'EOF'` (quoted delimiter, no expansion) with `Usage:` / description / flag list /
`Examples:`. `adoption_smoke.sh` uses an unquoted `<<USAGE` specifically so `${DIRECT_BASE_URL}`
interpolates — use the quoted form unless interpolation is needed.

---

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| — | — | — | Every file in this phase has an in-repo analog. |

Two areas have analogs whose *behavior* must be inverted rather than copied — the planner should
treat these as explicit deviations, not gaps:

| Area | Analog | Required deviation |
|------|--------|--------------------|
| Teardown | `verify_install_truth.sh:5-6` (`mktemp -d` + `trap 'rm -rf'`) | Stable `tmp/adopter-walk/` workdir, pid-only trap (D-20) |
| Strict mode | `repo_hygiene_check.sh:2` (`set -euo pipefail`) | `set -uo pipefail` so FAIL steps continue (D-18, Pitfall 10) |
| Generation flags | `verify_install_truth.sh:73` (`--no-assets --no-ecto --no-html --no-mailer`) | Stock defaults + `--database postgres --install` (D-05, ADOPT-02) |
| Archive install | `verify_install_truth.sh:71` (unpinned, global `MIX_ARCHIVES`) | Pinned `1.8.9` into `.harness/archives` (D-06/D-07) |
| CSRF scrape | `adoption_smoke.py:99-103` | Two-pattern fallback chain (D-25, Pitfall 5) |
| Login params | `adoption_smoke.py:142-154` (flat, `/login`) | Nested `user[...]`, `/users/log-in`, driver-navigated `return_to` (Pitfall 7) |
| Verdict levels | `repo_hygiene_check.sh` PASS/WARN/BLOCK | PASS/FAIL only, plus a non-ledger PREREQUISITE exit (D-14/D-17) |

---

## Metadata

**Analog search scope:** `scripts/maintainer/`, `scripts/publish/`, `scripts/demo/`,
`scripts/conformance/`, `.github/workflows/`, `test/lockspire/`, `.planning/milestones/`,
`mix.exs`, `.gitignore`
**Files scanned:** 12 (7 read in full or in targeted ranges)
**Pattern extraction date:** 2026-07-28
