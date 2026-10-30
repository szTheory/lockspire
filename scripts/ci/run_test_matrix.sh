#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "usage: $0 (--baseline|--ci|--fast|--integration) OUTPUT.json [COVERAGE_DIR SOURCE_SHA]" >&2
  exit 64
}

mode=${1:-}
output=${2:-}
[[ -n "$output" ]] || usage
coverage_dir=${3:-}
source_sha=${4:-}

if [[ -n "$coverage_dir" || -n "$source_sha" ]]; then
  [[ -n "$coverage_dir" && "$source_sha" =~ ^[0-9a-f]{40}$ ]] || usage
fi

case "$mode" in
  --baseline|--ci|--fast|--integration) ;;
  *) usage ;;
esac

mkdir -p "$(dirname "$output")"
records=()
overall_status=0
last_partition_status=0

sha256_file() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | awk '{print $1}'
  else
    shasum -a 256 "$1" | awk '{print $1}'
  fi
}

write_coverage_receipt() {
  local partition=$1
  local coverdata=$2
  local receipt=$3
  local checksum
  checksum=$(sha256_file "$coverdata")

  python3 - "$partition" "$source_sha" "$(basename "$coverdata")" "$checksum" "$receipt" <<'PY'
import json
import sys
from pathlib import Path

partition, source_sha, filename, checksum, receipt = sys.argv[1:]
payload = {
    "schema_version": 1,
    "partition": partition,
    "source_sha": source_sha,
    "coverdata": filename,
    "sha256": checksum,
}
Path(receipt).write_text(json.dumps(payload, sort_keys=True, separators=(",", ":")) + "\n")
PY
}

run_coverage_partition() {
  local partition=$1
  local command=$2
  local raw_dir coverdata

  if [[ -z "$coverage_dir" ]]; then
    run_partition "$partition" "$command"
    return
  fi

  raw_dir="${coverage_dir}/raw"
  mkdir -p "$raw_dir"
  coverdata="${raw_dir}/${partition}.coverdata"
  rm -f "$coverdata"
  run_partition "$partition" "LOCKSPIRE_COVERAGE_OUTPUT='${raw_dir}' ${command} --cover --export-coverage ${partition}"

  if [[ -f "$coverdata" ]]; then
    mkdir -p "$coverage_dir"
    mv "$coverdata" "${coverage_dir}/${partition}.coverdata"
    write_coverage_receipt \
      "$partition" \
      "${coverage_dir}/${partition}.coverdata" \
      "${coverage_dir}/${partition}.json"
  elif [[ $overall_status -eq 0 ]]; then
    echo "${partition} coverage export is missing" >&2
    overall_status=1
  fi
}

run_partition() {
  local name=$1
  local command=$2
  local started elapsed status
  started=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  SECONDS=0

  if sh -c "$command"; then
    status=0
  else
    status=$?
  fi

  elapsed=$SECONDS
  records+=("{\"name\":\"${name}\",\"command\":\"${command}\",\"elapsed_seconds\":${elapsed},\"exit_status\":${status},\"started_at\":\"${started}\"}")
  printf '%s: %ss (exit %s)\n' "$name" "$elapsed" "$status"
  if [[ $status -ne 0 && $overall_status -eq 0 ]]; then
    overall_status=$status
  fi
  last_partition_status=$status

  return 0
}

case "$mode" in
  --baseline)
    run_partition fast "MIX_ENV=test mix test.fast"
    run_partition integration "MIX_ENV=test mix test.integration"
    run_partition aggregate "MIX_ENV=test mix test.phase3"
    ;;
  --ci)
    run_partition integration "MIX_ENV=test mix test.integration"
    ;;
  --fast)
    run_coverage_partition fast "MIX_ENV=test mix do test.setup + test"
    ;;
  --integration)
    expected_source=${LOCKSPIRE_EXPECTED_CANDIDATE_SOURCE_REVISION:-${source_sha:-$(git rev-parse HEAD)}}
    [[ "$expected_source" =~ ^[0-9a-f]{40,64}$ ]] || {
      echo "authenticated lifetime package candidate source revision is invalid" >&2
      exit 2
    }
    if [[ -n "$source_sha" ]]; then
      [[ "${LOCKSPIRE_EXPECTED_FROZEN_RUNNER_REVISION:-}" == "$source_sha" ]] || {
        echo "authenticated lifetime package runner does not match the selected source checkout" >&2
        exit 2
      }
      for required in LOCKSPIRE_FROZEN_INPUTS LOCKSPIRE_EXPECTED_FROZEN_MANIFEST_SHA256 \
        LOCKSPIRE_EXPECTED_CANDIDATE_SOURCE_REVISION LOCKSPIRE_EXPECTED_CANDIDATE_ARCHIVE_SHA256 \
        LOCKSPIRE_EXPECTED_CANDIDATE_TREE_SHA256; do
        if [[ -z "${!required:-}" ]]; then
          echo "authenticated lifetime package owner input is missing: ${required}" >&2
          exit 2
        fi
      done
    fi
    run_coverage_partition integration "MIX_ENV=test mix do test.setup + test --only integration --exclude lifetime_package"
    leg_dir=$(mktemp -d "${TMPDIR:-/tmp}/lockspire-lifetime-legs.XXXXXX")
    trap 'rm -rf "$leg_dir"' EXIT
    mkdir -p .artifacts/ci/client-lifetimes
    rm -f .artifacts/ci/client-lifetimes/receipt.json .artifacts/ci/client-lifetimes/validation.json
    run_partition lifetimes \
      "LOCKSPIRE_LIFETIME_SOURCE_REVISION='$expected_source' LOCKSPIRE_LIFETIME_RECEIPT_DIR='$leg_dir' MIX_ENV=test mix test --only lifetime_package test/integration/client_lifetime_packaged_journey_test.exs test/integration/app_lifetime_packaged_upgrade_test.exs"
    if [[ $last_partition_status -eq 0 ]]; then
      run_partition lifetime_receipts \
        "python3 scripts/acceptance/client_lifetime_receipts.py --fresh '$leg_dir/fresh.json' --custom '$leg_dir/custom.json' --legacy '$leg_dir/legacy.json' --receipt .artifacts/ci/client-lifetimes/receipt.json --validation .artifacts/ci/client-lifetimes/validation.json --expected-source '$expected_source'"
    fi
    run_partition clean_room "MIX_ENV=test mix test.clean-room.e2e"
    ;;
esac

printf '{"generated_at":"%s","mode":"%s","partitions":[%s]}\n' \
  "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" "$mode" "$(IFS=,; echo "${records[*]}")" > "$output"

if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then
  {
    echo "## Lockspire test timing"
    printf '%s\n' "${records[@]}"
  } >> "$GITHUB_STEP_SUMMARY"
fi

exit "$overall_status"
