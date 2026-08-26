#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "usage: $0 (--baseline|--ci|--fast|--integration) OUTPUT.json" >&2
  exit 64
}

mode=${1:-}
output=${2:-}
[[ -n "$output" ]] || usage

case "$mode" in
  --baseline|--ci|--fast|--integration) ;;
  *) usage ;;
esac

mkdir -p "$(dirname "$output")"
records=()
overall_status=0

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
    run_partition fast "MIX_ENV=test mix test.coverage"
    ;;
  --integration)
    run_partition integration "MIX_ENV=test mix test.integration"
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
