#!/usr/bin/env bash

set -euo pipefail
umask 077

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DEMO_DIR="${ROOT_DIR}/examples/adoption_demo"
EVIDENCE="${ROOT_DIR}/scripts/conformance/build_redacted_evidence.py"
LOCK="${ROOT_DIR}/scripts/conformance/oidf-suite-lock.json"

[[ $# -eq 1 && "$1" =~ ^(phase37|fapi2)$ ]] || {
  echo "usage: $0 phase37|fapi2" >&2
  exit 64
}

[[ "${LOCKSPIRE_OIDF_EPHEMERAL_DB:-}" == "true" ]] || {
  echo "refusing to prepare a database without LOCKSPIRE_OIDF_EPHEMERAL_DB=true" >&2
  exit 65
}

profile=$1
work_dir="$(mktemp -d "${TMPDIR:-/tmp}/lockspire-ephemeral-${profile}.XXXXXX")"
provider_config="${work_dir}/provider.json"
host_log="${work_dir}/host.log"
host_pid=""

case "$profile" in
  phase37)
    profile_runner="${ROOT_DIR}/scripts/conformance/run_phase37_suite.sh"
    plan="${ROOT_DIR}/scripts/conformance/phase37-plan.json"
    artifact_dir="${LOCKSPIRE_PHASE37_ARTIFACT_DIR:-${ROOT_DIR}/.artifacts/conformance/phase37}"
    signing_alg="RS256"
    ;;
  fapi2)
    profile_runner="${ROOT_DIR}/scripts/conformance/run_fapi2_suite.sh"
    plan="${ROOT_DIR}/scripts/conformance/fapi2-plan.json"
    artifact_dir="${LOCKSPIRE_FAPI2_ARTIFACT_DIR:-${ROOT_DIR}/.artifacts/conformance/fapi2}"
    signing_alg="PS256"
    ;;
esac

[[ ! -e "$artifact_dir" ]] || {
  echo "ephemeral conformance output must not already exist" >&2
  exit 65
}

cleanup() {
  exit_code=$?
  trap - EXIT INT TERM

  if [[ -n "$host_pid" ]]; then
    kill "$host_pid" >/dev/null 2>&1 || true
    wait "$host_pid" >/dev/null 2>&1 || true
  fi

  if [[ ! -f "${artifact_dir}/receipt.json" ]]; then
    python3 "$EVIDENCE" \
      --lock "$LOCK" \
      --profile "$profile" \
      --plan "$plan" \
      --status failed \
      --classification infrastructure_failure \
      --output "$artifact_dir" >/dev/null 2>&1 || true
  fi

  rm -rf "$work_dir"
  exit "$exit_code"
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

export LOCKSPIRE_DEMO_BIND_IP=0.0.0.0
export LOCKSPIRE_DEMO_BASE_URL=http://host.docker.internal:4100
export LOCKSPIRE_DEMO_SIGNING_ALG="$signing_alg"
export LOCKSPIRE_DEMO_DB_HOST="${LOCKSPIRE_TEST_DB_HOST:-127.0.0.1}"
export LOCKSPIRE_DEMO_DB_PORT="${LOCKSPIRE_TEST_DB_PORT:-5432}"
export LOCKSPIRE_DEMO_DB_USER="${LOCKSPIRE_TEST_DB_USER:-lockspire}"
export LOCKSPIRE_DEMO_DB_PASSWORD="${LOCKSPIRE_TEST_DB_PASSWORD:-lockspire}"
export LOCKSPIRE_DEMO_DB_NAME="${LOCKSPIRE_TEST_DB_NAME:-lockspire_test}"
export LOCKSPIRE_OIDF_PROFILE="$profile"
export LOCKSPIRE_OIDF_CONFIG_PATH="$provider_config"
export LOCKSPIRE_OIDF_PROVIDER_CONFIG="$provider_config"
export BASE_URL=https://nginx:8443

(
  cd "$DEMO_DIR"
  MIX_ENV=dev mix deps.get --check-locked
  MIX_ENV=dev mix ecto.setup
  MIX_ENV=dev mix run priv/repo/conformance_seeds.exs
  exec env MIX_ENV=dev mix phx.server >"$host_log" 2>&1
) &
host_pid=$!

for _attempt in $(seq 1 60); do
  if curl --fail --silent --show-error \
    http://127.0.0.1:4100/lockspire/.well-known/openid-configuration \
    >/dev/null 2>&1; then
    "$profile_runner"
    exit 0
  fi

  if ! kill -0 "$host_pid" >/dev/null 2>&1; then
    echo "throwaway Lockspire host stopped before becoming ready" >&2
    exit 70
  fi
  sleep 1
done

echo "throwaway Lockspire host did not become ready" >&2
exit 70
