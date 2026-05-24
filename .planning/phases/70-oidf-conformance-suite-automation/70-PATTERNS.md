# Phase 70: OIDF Conformance Suite Automation - Pattern Map

**Mapped:** 2024-05-15
**Files analyzed:** 3
**Analogs found:** 3 / 3

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `scripts/conformance/run_fapi2_suite.sh` | utility | batch | `scripts/conformance/run_phase37_suite.sh` | exact |
| `.github/workflows/oidf-conformance.yml` | config | automation | `.github/workflows/oidf-conformance.yml` | exact |
| `docs/maintainer-conformance.md` | docs | none | `docs/maintainer-conformance.md` | exact |

## Pattern Assignments

### `scripts/conformance/run_fapi2_suite.sh` (utility, batch)

**Analog:** `scripts/conformance/run_phase37_suite.sh`

**Environment pattern** (lines 3-15):
```bash
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PLAN_PATH="${ROOT_DIR}/scripts/conformance/phase37-plan.json"
ARTIFACT_DIR="${LOCKSPIRE_PHASE37_ARTIFACT_DIR:-${ROOT_DIR}/.artifacts/conformance/phase37}"
EXPORT_DIR="${ARTIFACT_DIR}/exports"
LOG_DIR="${ARTIFACT_DIR}/logs"
MODE="${LOCKSPIRE_PHASE37_MODE:-local}"
SKIP_SUITE="${LOCKSPIRE_PHASE37_SKIP_SUITE:-false}"
SUITE_BASE_URL="${OIDF_CONFORMANCE_SERVER:-https://localhost.emobix.co.uk:8443/}"
SUITE_MTLS_URL="${OIDF_CONFORMANCE_SERVER_MTLS:-https://localhost.emobix.co.uk:8444/}"
SUITE_IMAGE_TAG="${OIDF_IMAGE_TAG:-latest}"
WORK_DIR="$(mktemp -d "${TMPDIR:-/tmp}/lockspire-phase37-suite.XXXXXX")"
FIXTURE_PID=""
SOURCE_SUITE_DIR=""
```

**Teardown pattern** (lines 17-34):
```bash
cleanup() {
  local exit_code=$?

  if [[ -n "${FIXTURE_PID}" ]]; then
    kill "${FIXTURE_PID}" >/dev/null 2>&1 || true
    wait "${FIXTURE_PID}" >/dev/null 2>&1 || true
  fi

  if [[ -f "${WORK_DIR}/docker-compose-prebuilt.yml" ]]; then
    IMAGE_TAG="${SUITE_IMAGE_TAG}" docker compose -f "${WORK_DIR}/docker-compose-prebuilt.yml" down -v >/dev/null 2>&1 || true
  fi

  if [[ -n "${SOURCE_SUITE_DIR}" ]]; then
    docker compose -f "${SOURCE_SUITE_DIR}/docker-compose.yml" down -v >/dev/null 2>&1 || true
  fi

  rm -rf "${WORK_DIR}"
  exit "${exit_code}"
}
trap cleanup EXIT
```

**Local Phoenix Fixture pattern** (lines 80-140):
```bash
start_local_fixture() {
  local fixture_port=$1
  local discovery_url=$2
  local fixture_log="${LOG_DIR}/fixture.log"

  MIX_ENV=test mix run --no-halt -e "
  Application.put_env(:lockspire, GeneratedHostAppWeb.Endpoint,
    secret_key_base: String.duplicate(\"a\", 64),
    server: true,
    adapter: Bandit.PhoenixAdapter,
    http: [ip: {127, 0, 0, 1}, port: \${fixture_port}],
    url: [scheme: \"http\", host: \"host.docker.internal\", port: \${fixture_port}]
  )
  Application.put_env(:lockspire, :repo, Lockspire.TestRepo)
  # ... setup logic ...
  Process.sleep(:infinity)
  " >"${fixture_log}" 2>&1 &

  FIXTURE_PID=$!
}
```

**Python Config Generator pattern** (lines 208-283):
```bash
python3 - <<'PY' "${PLAN_PATH}" "${WORK_DIR}/provider-config.json" "${WORK_DIR}/plan-strings.txt" "${PROVIDER_DISCOVERY_URL}" "${PROVIDER_BASE_URL}"
import json
import sys
from pathlib import Path

plan_path = Path(sys.argv[1])
config_path = Path(sys.argv[2])
# ... JSON generation script ...
PY
```

---

### `.github/workflows/oidf-conformance.yml` (config, automation)

**Analog:** `.github/workflows/oidf-conformance.yml`

**Postgres Database Service pattern** (lines 15-26):
```yaml
    services:
      postgres:
        image: postgres:16
        env:
          POSTGRES_DB: lockspire_test
          POSTGRES_USER: lockspire
          POSTGRES_PASSWORD: lockspire
        ports:
          - 5432:5432
        options: >-
          --health-cmd "pg_isready -U lockspire -d lockspire_test"
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
```

**Environment Setup pattern** (lines 28-34):
```yaml
    env:
      MIX_ENV: test
      LOCKSPIRE_TEST_DB_HOST: 127.0.0.1
      LOCKSPIRE_TEST_DB_PORT: "5432"
      LOCKSPIRE_TEST_DB_USER: lockspire
      LOCKSPIRE_TEST_DB_PASSWORD: lockspire
      LOCKSPIRE_TEST_DB_NAME: lockspire_test
```

**Suite Execution Step pattern** (lines 92-93):
```yaml
      - name: Run hosted maintainer lane
        run: bash scripts/conformance/run_phase37_suite.sh
```

---

## Shared Patterns

### Test Dependency Assurance
**Source:** `scripts/conformance/run_phase37_suite.sh`
**Apply to:** Any new suite automation script
```bash
for cmd in docker python3 curl mix; do
  require_command "${cmd}"
done
```

## Metadata

**Analog search scope:** `scripts/conformance/`, `.github/workflows/`
**Files scanned:** 3
**Pattern extraction date:** 2024-05-15
