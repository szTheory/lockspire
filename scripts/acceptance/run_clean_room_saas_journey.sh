#!/usr/bin/env bash

# The Phase 133 acceptance lab intentionally owns exactly two roles: the embedded
# provider host and its confidential SaaS client. It is not a reusable supervisor.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

if [[ "${1:-}" == "--probe" ]]; then
  RUN_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/lockspire-clean-room.XXXXXX")"
  cleanup() {
    local status=$?
    rm -rf -- "${RUN_ROOT}"
    printf '%s\n' "cleanup complete"
    exit "${status}"
  }
  trap cleanup EXIT
  python3 "${ROOT_DIR}/scripts/acceptance/clean_room/processes.py" --run-root "${RUN_ROOT}" "$@"
else
  exec python3 "${ROOT_DIR}/scripts/acceptance/clean_room_saas_journey.py" "$@"
fi
