#!/usr/bin/env bash

set -u -o pipefail
umask 077

output_file=$(mktemp "${TMPDIR:-/tmp}/lockspire-credo.XXXXXX")
trap 'rm -f "$output_file"' EXIT

set +e
mix credo --strict 2>&1 | tee "$output_file"
credo_status=${PIPESTATUS[0]}
set -e

if [ "$credo_status" -ne 0 ]; then
  exit "$credo_status"
fi

if grep -Fq "Some source files were not parsed in the time allotted" "$output_file"; then
  echo "Credo did not parse every configured source file; refusing to continue." >&2
  exit 1
fi
