#!/usr/bin/env bash

set -euo pipefail
umask 077

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PREPARE="${ROOT_DIR}/scripts/conformance/prepare_oidf_suite.sh"
EVIDENCE="${ROOT_DIR}/scripts/conformance/build_redacted_evidence.py"
LOCK="${ROOT_DIR}/scripts/conformance/oidf-suite-lock.json"

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
    docker compose -f "$compose_file" down -v >/dev/null 2>&1 || true
  fi
  python3 "$EVIDENCE" --lock "$LOCK" --profile "$profile" --plan "$plan" --status "$status" --classification "$classification" --output "$artifact_dir"
  rm -rf "$work_dir"
  exit "$exit_code"
}
trap finish EXIT

if [[ "$skip_suite" == "true" ]]; then
  exit 0
fi

"$PREPARE" --output-dir "$work_dir/prepared"
compose_file="$work_dir/prepared/docker-compose.locked.yml"
docker compose -f "$compose_file" up -d
status="passed"
classification="success"
