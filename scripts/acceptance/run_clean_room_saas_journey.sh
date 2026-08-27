#!/usr/bin/env bash

# The Phase 133 acceptance lab intentionally owns exactly two roles: the embedded
# provider host and its confidential SaaS client. It is not a reusable supervisor.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
RUN_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/lockspire-clean-room.XXXXXX")"
ORIGINAL_EXIT=0

cleanup() {
  ORIGINAL_EXIT=$?

  if [[ -d "${RUN_ROOT}" ]]; then
    rm -rf -- "${RUN_ROOT}"
  fi

  printf '%s\n' "cleanup complete"
  trap - EXIT INT TERM
  exit "${ORIGINAL_EXIT}"
}

trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

python3 "${ROOT_DIR}/scripts/acceptance/clean_room/processes.py" \
  --run-root "${RUN_ROOT}" \
  "$@"
