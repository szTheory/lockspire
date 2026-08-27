#!/usr/bin/env bash

set -euo pipefail
umask 077

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PREPARE="${ROOT_DIR}/scripts/conformance/prepare_oidf_suite.sh"
EVIDENCE="${ROOT_DIR}/scripts/conformance/build_redacted_evidence.py"
LOCK="${ROOT_DIR}/scripts/conformance/oidf-suite-lock.json"
INVOKE="${ROOT_DIR}/scripts/conformance/invoke_oidf_plan.py"

[[ $# -eq 8 ]] || { echo "invalid profile invocation" >&2; exit 64; }
[[ "$1" == "--profile" && "$3" == "--plan" && "$5" == "--artifact-dir" && "$7" == "--skip-suite" ]] || exit 64
profile=$2
plan=$4
artifact_dir=$6
skip_suite=$8
work_dir="$(mktemp -d "${TMPDIR:-/tmp}/lockspire-oidf-${profile}.XXXXXX")"
status="failed"
classification="infrastructure_failure"
compose_file=""
provider_config="${LOCKSPIRE_OIDF_PROVIDER_CONFIG:-}"
provider_config_json="${LOCKSPIRE_OIDF_PROVIDER_CONFIG_JSON:-}"
prepare_command="$PREPARE"
compose_command="docker"
runner_path=""

if [[ "${LOCKSPIRE_OIDF_ALLOW_TEST_DOUBLES:-false}" == "true" ]]; then
  prepare_command="${LOCKSPIRE_OIDF_TEST_PREPARE:-$prepare_command}"
  compose_command="${LOCKSPIRE_OIDF_TEST_COMPOSE:-$compose_command}"
  runner_path="${LOCKSPIRE_OIDF_TEST_RUNNER:-}"
fi

finish() {
  local exit_code=$?
  if [[ "$skip_suite" == "true" ]]; then
    status="integration_only"
    classification="integration_only"
  elif [[ $exit_code -eq 0 ]]; then
    status="passed"
    classification="success"
  fi
  if [[ -n "$compose_file" ]]; then
    "$compose_command" compose -f "$compose_file" down -v >/dev/null 2>&1 || true
  fi
  evidence_exit=0
  python3 "$EVIDENCE" --lock "$LOCK" --profile "$profile" --plan "$plan" --status "$status" --classification "$classification" --output "$artifact_dir" || evidence_exit=$?
  rm -rf "$work_dir"
  if [[ $evidence_exit -ne 0 ]]; then
    exit "$evidence_exit"
  fi
  exit "$exit_code"
}
trap finish EXIT

if [[ "$skip_suite" == "true" ]]; then
  exit 0
fi

if [[ -n "$provider_config" && -n "$provider_config_json" ]]; then
  echo "set only one OIDF provider configuration input" >&2
  exit 65
fi

if [[ -z "$provider_config" && -n "$provider_config_json" ]]; then
  provider_config="$work_dir/provider.json"
  printf '%s' "$provider_config_json" >"$provider_config"
  chmod 600 "$provider_config"
  unset LOCKSPIRE_OIDF_PROVIDER_CONFIG_JSON
  provider_config_json=""
fi

[[ -n "$provider_config" && -f "$provider_config" ]] || {
  echo "LOCKSPIRE_OIDF_PROVIDER_CONFIG must name a regular JSON file" >&2
  exit 65
}

python3 - "$provider_config" <<'PY'
import json
import sys

with open(sys.argv[1], encoding="utf-8") as source:
    config = json.load(source)
if not isinstance(config, dict):
    raise SystemExit("OIDF provider configuration must be a JSON object")
PY

"$prepare_command" --output-dir "$work_dir/prepared"
compose_file="$work_dir/prepared/docker-compose.locked.yml"
"$compose_command" compose -f "$compose_file" up -d --wait --wait-timeout 120
if [[ -z "$runner_path" ]]; then
  runner_path="$work_dir/prepared/suite/scripts/run-test-plan.py"
fi

mkdir -m 700 "$work_dir/raw"
classification="suite_failure"
set +e
python3 "$INVOKE" \
  --runner "$runner_path" \
  --plan "$plan" \
  --provider-config "$provider_config" \
  --export-dir "$work_dir/raw/export" \
  >"$work_dir/raw/suite-output.log" 2>&1
suite_exit=$?
set -e
if [[ $suite_exit -ne 0 ]]; then
  if [[ $suite_exit -eq 70 ]]; then
    classification="infrastructure_failure"
    echo "OIDF suite runner setup failed; raw output remains ephemeral" >&2
  else
    echo "OIDF suite reported a profile failure; raw output remains ephemeral" >&2
  fi
  exit "$suite_exit"
fi

status="passed"
classification="success"
