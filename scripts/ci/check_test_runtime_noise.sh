#!/usr/bin/env bash

set -u -o pipefail
umask 077

mode=${1:---focused}

case "$mode" in
  --focused)
    test_targets=(
      test/lockspire/key_cache_test.exs
      test/lockspire/storage/repository_test.exs
      test/lockspire/protocol/jarm_test.exs
      test/lockspire/protocol/device_authorization_test.exs
      test/lockspire/protocol/dcr_telemetry_redaction_test.exs
    )
    ;;
  --fast)
    test_targets=()
    ;;
  *)
    echo "usage: $0 [--focused|--fast]" >&2
    exit 64
    ;;
esac

output_file=$(mktemp "${TMPDIR:-/tmp}/lockspire-test-runtime-noise.XXXXXX")
trap 'rm -f "$output_file"' EXIT

set +e
mix test "${test_targets[@]}" >"$output_file" 2>&1
test_status=$?
set -e

if [ "$test_status" -ne 0 ]; then
  echo "Test command failed (output withheld to avoid exposing test credentials or tokens)." >&2
  exit "$test_status"
fi

noise_found=0

reject_noise() {
  local label=$1
  local pattern=$2

  if grep -Eqi "$pattern" "$output_file"; then
    echo "Routine runtime noise detected: $label (matching diagnostic redacted)." >&2
    noise_found=1
  fi
}

reject_noise "KeyCache startup failure" 'Failed to refresh KeyCache'
reject_noise "Ecto query debug output" '\[[[:space:]]*debug\][[:space:]]+QUERY'
# Telemetry emits this warning across multiple lines (the first identifies a handler,
# then a following line says it is a local function), so a single-line
# `telemetry.*local function` expression false-greens the fast suite.
reject_noise "telemetry local-function handler warning" 'local function'

if [ "$noise_found" -ne 0 ]; then
  exit 1
fi

echo "Runtime-noise contract passed ($mode)."
