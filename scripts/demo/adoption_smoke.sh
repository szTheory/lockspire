#!/usr/bin/env sh
set -eu

DEFAULT_BASE_URL="http://lockspire-demo.localhost"
DIRECT_BASE_URL="http://127.0.0.1:4100"

usage() {
  cat <<USAGE
Usage: scripts/demo/adoption_smoke.sh [--help]

Runs the adoption demo smoke against LOCKSPIRE_DEMO_BASE_URL.

Default Traefik hostname URL:
  scripts/demo/adoption_smoke.sh

Direct Docker fallback URL:
  LOCKSPIRE_DEMO_BASE_URL=${DIRECT_BASE_URL} scripts/demo/adoption_smoke.sh
USAGE
}

while [ "$#" -gt 0 ]; do
  case "$1" in
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

if ! command -v git >/dev/null 2>&1; then
  echo "git is required to locate the Lockspire repo root" >&2
  exit 1
fi

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$REPO_ROOT"

BASE_URL="${LOCKSPIRE_DEMO_BASE_URL:-$DEFAULT_BASE_URL}"
BASE_URL="${BASE_URL%/}"

echo "Running adoption demo smoke against ${BASE_URL}"
LOCKSPIRE_DEMO_BASE_URL="${BASE_URL}" exec python3 scripts/demo/adoption_smoke.py
