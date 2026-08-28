#!/bin/sh
set -eu

output=$(MIX_ENV=dev mix xref graph --format cycles --label compile-connected 2>&1) || {
  status=$?
  printf '%s\n' "$output"
  exit "$status"
}

printf '%s\n' "$output"

if printf '%s' "$output" | grep -q 'Cycle of length'; then
  exit 1
fi
