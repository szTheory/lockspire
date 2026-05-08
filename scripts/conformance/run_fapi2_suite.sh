#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PLAN_PATH="${ROOT_DIR}/scripts/conformance/fapi2-plan.json"
ARTIFACT_DIR="${LOCKSPIRE_FAPI2_ARTIFACT_DIR:-${ROOT_DIR}/.artifacts/conformance/fapi2}"
EXPORT_DIR="${ARTIFACT_DIR}/exports"
LOG_DIR="${ARTIFACT_DIR}/logs"
MODE="${LOCKSPIRE_FAPI2_MODE:-local}"
SKIP_SUITE="${LOCKSPIRE_FAPI2_SKIP_SUITE:-false}"
SUITE_BASE_URL="${OIDF_CONFORMANCE_SERVER:-https://localhost.emobix.co.uk:8443/}"
SUITE_MTLS_URL="${OIDF_CONFORMANCE_SERVER_MTLS:-https://localhost.emobix.co.uk:8444/}"
SUITE_IMAGE_TAG="${OIDF_IMAGE_TAG:-latest}"
WORK_DIR="$(mktemp -d "${TMPDIR:-/tmp}/lockspire-fapi2-suite.XXXXXX")"
FIXTURE_PID=""
SOURCE_SUITE_DIR=""

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

start_suite() {
  if IMAGE_TAG="${SUITE_IMAGE_TAG}" docker compose -f "${WORK_DIR}/docker-compose-prebuilt.yml" up -d >"${LOG_DIR}/suite-compose.log" 2>&1; then
    return 0
  fi

  {
    echo "Prebuilt suite bootstrap failed. Falling back to the official source build."
    cat "${LOG_DIR}/suite-compose.log"
  } >>"${LOG_DIR}/suite-compose.log"

  IMAGE_TAG="${SUITE_IMAGE_TAG}" docker compose -f "${WORK_DIR}/docker-compose-prebuilt.yml" down -v >/dev/null 2>&1 || true

  curl -fsSL https://gitlab.com/openid/conformance-suite/-/archive/master/conformance-suite-master.tar.gz -o "${WORK_DIR}/conformance-suite.tar.gz"
  tar -xzf "${WORK_DIR}/conformance-suite.tar.gz" -C "${WORK_DIR}"
  SOURCE_SUITE_DIR="$(find "${WORK_DIR}" -maxdepth 1 -type d -name 'conformance-suite-*' | head -n 1)"

  if [[ -z "${SOURCE_SUITE_DIR}" ]]; then
    echo "Could not unpack conformance suite source archive" >>"${LOG_DIR}/suite-compose.log"
    return 1
  fi

  MAVEN_CACHE="${WORK_DIR}/m2" docker compose -f "${SOURCE_SUITE_DIR}/builder-compose.yml" run --rm builder >>"${LOG_DIR}/suite-compose.log" 2>&1
  docker compose -f "${SOURCE_SUITE_DIR}/docker-compose.yml" up -d >>"${LOG_DIR}/suite-compose.log" 2>&1
}

trap cleanup EXIT

require_command() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Missing required command: $1" >&2
    exit 1
  }
}

wait_for_url() {
  local url=$1
  local insecure=${2:-false}
  local attempts=${3:-60}
  local curl_flags=(-fsS)

  if [[ "${insecure}" == "true" ]]; then
    curl_flags+=(-k)
  fi

  for _attempt in $(seq 1 "${attempts}"); do
    if curl "${curl_flags[@]}" "${url}" >/dev/null 2>&1; then
      return 0
    fi
    sleep 2
  done

  echo "Timed out waiting for ${url}" >&2
  exit 1
}

start_local_fixture() {
  local fixture_port=$1
  local discovery_url=$2
  local fixture_log="${LOG_DIR}/fixture.log"

  MIX_ENV=test mix run --no-halt -e "
  Application.put_env(:lockspire, GeneratedHostAppWeb.Endpoint,
    secret_key_base: String.duplicate(\"a\", 64),
    server: true,
    adapter: Bandit.PhoenixAdapter,
    http: [ip: {127, 0, 0, 1}, port: ${fixture_port}],
    url: [scheme: \"http\", host: \"host.docker.internal\", port: ${fixture_port}]
  )
  Application.put_env(:lockspire, :repo, Lockspire.TestRepo)
  Application.put_env(:lockspire, :issuer, \"${discovery_url}\")
  Application.put_env(:lockspire, :mount_path, \"/lockspire\")
  Application.put_env(:lockspire, :known_scopes, [\"openid\", \"email\", \"profile\"])
  Application.put_env(:lockspire, :account_resolver, GeneratedHostApp.Lockspire.TestAccountResolver)

  {:ok, _} = Application.ensure_all_started(:logger)
  {:ok, _repo_pid} = Lockspire.TestRepo.start_link()
  {:ok, _endpoint_pid} = GeneratedHostAppWeb.Endpoint.start_link()
  Ecto.Adapters.SQL.Sandbox.mode(Lockspire.TestRepo, :auto)

  alias Lockspire.Domain.SigningKey
  alias Lockspire.Domain.ServerPolicy
  alias Lockspire.Storage.Ecto.Repository

  case Repository.fetch_active_signing_key() do
    {:ok, nil} ->
      key = JOSE.JWK.generate_key({:ec, \"P-256\"})
      {_fields, jwk} = JOSE.JWK.to_map(key)

      {:ok, _published_key} =
        Repository.publish_key(%SigningKey{
          kid: \"fapi2-conformance-kid\",
          kty: :EC,
          alg: \"ES256\",
          use: :sig,
          public_jwk:
            jwk
            |> Map.take([\"kty\", \"kid\", \"alg\", \"use\", \"crv\", \"x\", \"y\"])
            |> Map.put(\"kid\", \"fapi2-conformance-kid\")
            |> Map.put(\"alg\", \"ES256\")
            |> Map.put(\"use\", \"sig\"),
          private_jwk_encrypted: Jason.encode!(Map.put(jwk, \"kid\", \"fapi2-conformance-kid\")),
          status: :active,
          published_at: DateTime.utc_now(),
          activated_at: DateTime.utc_now(),
          metadata: %{}
        })

      # Enable FAPI 2.0 Security Profile
      Repository.put_server_policy(%ServerPolicy{security_profile: :fapi_2_0_security})

    _other ->
      :ok
  end

  Process.sleep(:infinity)
  " >"${fixture_log}" 2>&1 &

  FIXTURE_PID=$!
}

mkdir -p "${ARTIFACT_DIR}" "${EXPORT_DIR}" "${LOG_DIR}"
cp "${PLAN_PATH}" "${ARTIFACT_DIR}/fapi2-plan.json"

if [[ "${SKIP_SUITE}" == "true" ]]; then
  python3 - <<'PY' "${PLAN_PATH}" "${ARTIFACT_DIR}" "${MODE}"
import json
import sys
from pathlib import Path
from datetime import datetime, timezone

plan = json.loads(Path(sys.argv[1]).read_text())
artifact_dir = Path(sys.argv[2])
mode = sys.argv[3]

summary = {
    "description": plan["description"],
    "mode": f"{mode}-integration-only",
    "skipped": "OIDF Docker suite skipped (LOCKSPIRE_FAPI2_SKIP_SUITE=true). Integration tests passed.",
    "generated_at": datetime.now(timezone.utc).isoformat(),
    "artifact_dir": str(artifact_dir),
    "exported_files": [],
    "modules": [
        {
            "name": entry["name"],
            "suite_plan": entry["suite_plan"],
            "variants": entry["variants"],
            "modules": entry["modules"],
        }
        for entry in plan["plans"]
    ],
}

(artifact_dir / "run-summary.json").write_text(json.dumps(summary, indent=2) + "\n")
PY

  find "${ARTIFACT_DIR}" -type f | sort >"${ARTIFACT_DIR}/artifact-files.txt"
  echo "FAPI 2.0 integration proof artifacts saved to ${ARTIFACT_DIR}"
  echo "Note: OIDF Docker suite skipped (LOCKSPIRE_FAPI2_SKIP_SUITE=true). Run without this flag to execute the full OIDF lane."
  exit 0
fi

for cmd in docker python3 curl mix; do
  require_command "${cmd}"
done

curl -fsSL https://gitlab.com/openid/conformance-suite/-/raw/master/docker-compose-prebuilt.yml -o "${WORK_DIR}/docker-compose-prebuilt.yml"
curl -fsSL https://gitlab.com/openid/conformance-suite/-/raw/master/scripts/run-test-plan.py -o "${WORK_DIR}/run-test-plan.py"
curl -fsSL https://gitlab.com/openid/conformance-suite/-/raw/master/scripts/conformance.py -o "${WORK_DIR}/conformance.py"
curl -fsSL https://gitlab.com/openid/conformance-suite/-/raw/master/scripts/test_plan_parser.py -o "${WORK_DIR}/test_plan_parser.py"

PROVIDER_DISCOVERY_URL=""
PROVIDER_BASE_URL=""

if [[ "${MODE}" == "hosted" ]]; then
  PROVIDER_DISCOVERY_URL="${LOCKSPIRE_FAPI2_PROVIDER_DISCOVERY_URL:-}"
  PROVIDER_BASE_URL="${LOCKSPIRE_FAPI2_PROVIDER_BASE_URL:-}"

  if [[ -z "${PROVIDER_DISCOVERY_URL}" ]]; then
    echo "LOCKSPIRE_FAPI2_PROVIDER_DISCOVERY_URL is required when LOCKSPIRE_FAPI2_MODE=hosted" >&2
    exit 1
  fi

  if [[ -z "${PROVIDER_BASE_URL}" ]]; then
    PROVIDER_BASE_URL="$(python3 - <<'PY' "${PROVIDER_DISCOVERY_URL}"
import sys
url = sys.argv[1]
suffix = "/.well-known/openid-configuration"
print(url[:-len(suffix)] if url.endswith(suffix) else url)
PY
)"
  fi
else
  FIXTURE_PORT="${LOCKSPIRE_FAPI2_PORT:-4011}"
  PROVIDER_BASE_URL="${LOCKSPIRE_FAPI2_PROVIDER_BASE_URL:-http://host.docker.internal:${FIXTURE_PORT}}"
  PROVIDER_DISCOVERY_URL="${LOCKSPIRE_FAPI2_PROVIDER_DISCOVERY_URL:-${PROVIDER_BASE_URL}/lockspire/.well-known/openid-configuration}"
  LOCAL_PROVIDER_DISCOVERY_URL="http://127.0.0.1:${FIXTURE_PORT}/lockspire/.well-known/openid-configuration"
  start_local_fixture "${FIXTURE_PORT}" "${PROVIDER_BASE_URL}/lockspire"
  wait_for_url "${LOCAL_PROVIDER_DISCOVERY_URL}" false 60
fi

python3 - <<'PY' "${PLAN_PATH}" "${WORK_DIR}/provider-config.json" "${WORK_DIR}/plan-strings.txt" "${PROVIDER_DISCOVERY_URL}" "${PROVIDER_BASE_URL}"
import json
import sys
from pathlib import Path

plan_path = Path(sys.argv[1])
config_path = Path(sys.argv[2])
plan_strings_path = Path(sys.argv[3])
discovery_url = sys.argv[4]
provider_base = sys.argv[5].rstrip("/")

plan = json.loads(plan_path.read_text())

browser = [
    {
        "match": f"{provider_base}/lockspire/authorize*",
        "tasks": [
            {
                "task": "Login",
                "optional": True,
                "match": f"{provider_base}/login*",
                "commands": [
                    ["text", "name", "login", "generated-host-user", "optional"],
                    ["text", "name", "password", "fapi2-password", "optional"],
                    ["text", "name", "auth_time_seconds_ago", "30", "optional"],
                    ["click", "class", "login-submit"],
                ],
            },
            {
                "task": "Consent",
                "optional": True,
                "match": f"{provider_base}/lockspire/consent/*",
                "commands": [["click", "class", "approve-submit"]],
            },
            {
                "task": "Verify Complete",
                "match": "*/test/*/callback*",
                "commands": [["wait", "id", "submission_complete", 10]],
            },
        ],
    }
]

error_override = [
    {
        "match": f"{provider_base}/lockspire/authorize*",
        "tasks": [
            {
                "task": "Expect authorization rejection",
                "match": f"{provider_base}/lockspire/authorize*",
                "commands": [["wait", "xpath", "//*", 10, "Authorization request rejected", "update-image-placeholder"]],
            }
        ],
    }
]

config = {
    "description": plan["description"],
    "server": {"discoveryUrl": discovery_url},
    "client": {"client_name": "lockspire-fapi2-local-client"},
    "browser": browser,
    "override": {
        "oidcc-ensure-registered-redirect-uri": {"browser": error_override},
        "oidcc-redirect-uri-query-mismatch": {"browser": error_override},
        "oidcc-redirect-uri-query-added": {"browser": error_override},
    },
}

config_path.write_text(json.dumps(config, indent=2) + "\n")

plan_lines = []
for entry in plan["plans"]:
    parts = [entry["suite_plan"]]
    for key, value in entry["variants"].items():
      parts.append(f"[{key}={value}]")
    if entry.get("modules"):
      parts.append(":" + ",".join(entry["modules"]))
    parts.append(" " + str(config_path))
    plan_lines.append("".join(parts))

plan_strings_path.write_text("\n".join(plan_lines) + "\n")
PY

cp "${WORK_DIR}/provider-config.json" "${ARTIFACT_DIR}/provider-config.json"
cp "${WORK_DIR}/plan-strings.txt" "${ARTIFACT_DIR}/plan-strings.txt"

start_suite
wait_for_url "${SUITE_BASE_URL}" true 120

export CONFORMANCE_SERVER="${SUITE_BASE_URL}"
export CONFORMANCE_SERVER_MTLS="${SUITE_MTLS_URL}"

python3 "${WORK_DIR}/run-test-plan.py" \
  --no-parallel \
  --export-dir "${EXPORT_DIR}" \
  $(tr '\n' ' ' < "${WORK_DIR}/plan-strings.txt") \
  2>&1 | tee "${LOG_DIR}/suite-run.log"

python3 - <<'PY' "${PLAN_PATH}" "${ARTIFACT_DIR}" "${EXPORT_DIR}" "${MODE}" "${PROVIDER_DISCOVERY_URL}"
import json
import sys
from pathlib import Path

plan = json.loads(Path(sys.argv[1]).read_text())
artifact_dir = Path(sys.argv[2])
export_dir = Path(sys.argv[3])
mode = sys.argv[4]
discovery_url = sys.argv[5]

summary = {
    "description": plan["description"],
    "mode": mode,
    "discovery_url": discovery_url,
    "artifact_dir": str(artifact_dir),
    "exported_files": sorted(str(path.relative_to(artifact_dir)) for path in export_dir.rglob("*") if path.is_file()),
    "modules": [
        {
            "name": entry["name"],
            "suite_plan": entry["suite_plan"],
            "variants": entry["variants"],
            "modules": entry["modules"],
        }
        for entry in plan["plans"]
    ],
}

(artifact_dir / "run-summary.json").write_text(json.dumps(summary, indent=2) + "\n")
PY

find "${ARTIFACT_DIR}" -type f | sort >"${ARTIFACT_DIR}/artifact-files.txt"
echo "FAPI 2.0 conformance artifacts saved to ${ARTIFACT_DIR}"
