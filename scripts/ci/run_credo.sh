#!/usr/bin/env bash

set -u -o pipefail
umask 077

set +e
output=$(mix credo --strict 2>&1)
credo_status=$?
set -e

printf '%s\n' "$output"

if [ "$credo_status" -ne 0 ]; then
  exit "$credo_status"
fi

if [[ "$output" == *"Some source files were not parsed in the time allotted"* ]]; then
  echo "Credo did not parse every configured source file; refusing to continue." >&2
  exit 1
fi
