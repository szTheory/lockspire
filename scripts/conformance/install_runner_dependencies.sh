#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
LOCK_PATH="${ROOT_DIR}/scripts/conformance/runner-requirements.lock"

python3 -m pip install \
  --disable-pip-version-check \
  --no-input \
  --no-deps \
  --only-binary=:all: \
  --require-hashes \
  --requirement "$LOCK_PATH"

python3 - <<'PY'
from importlib.metadata import version

expected = {
    "anyio": "4.14.2",
    "certifi": "2026.7.22",
    "h11": "0.16.0",
    "httpcore": "1.0.9",
    "httpx": "0.28.1",
    "idna": "3.19",
    "pyparsing": "3.3.2",
}
actual = {name: version(name) for name in expected}
if actual != expected:
    raise SystemExit("OIDF runner dependency versions do not match the reviewed lock")
PY
