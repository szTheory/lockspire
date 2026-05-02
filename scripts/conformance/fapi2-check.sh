#!/bin/bash
set -euo pipefail

BASE_URL="${LOCKSPIRE_BASE_URL:-http://127.0.0.1:4000/lockspire}"
CLIENT_ID="${LOCKSPIRE_CLIENT_ID:-}"
TMP_BODY="$(mktemp)"
trap 'rm -f "$TMP_BODY"' EXIT

GREEN="$(printf '\033[32m')"
RED="$(printf '\033[31m')"
YELLOW="$(printf '\033[33m')"
RESET="$(printf '\033[0m')"

if [ -z "$CLIENT_ID" ]; then
  printf '%sFAIL%s LOCKSPIRE_CLIENT_ID is required\n' "$RED" "$RESET" >&2
  printf 'Set LOCKSPIRE_CLIENT_ID to a registered client that inherits or requires FAPI 2.0.\n' >&2
  exit 1
fi

authorize_url="${BASE_URL}/authorize?client_id=${CLIENT_ID}&response_type=code&redirect_uri=https%3A%2F%2Fexample.com%2Fcb&scope=openid&code_challenge=abc&code_challenge_method=S256"
token_url="${BASE_URL}/token"
userinfo_url="${BASE_URL}/userinfo"

failures=0

print_result() {
  local status="$1"
  local message="$2"

  if [ "$status" = "PASS" ]; then
    printf '%sPASS%s %s\n' "$GREEN" "$RESET" "$message"
  else
    printf '%sFAIL%s %s\n' "$RED" "$RESET" "$message"
    failures=$((failures + 1))
  fi
}

printf '%sFAPI 2.0 boundary probe%s\n' "$YELLOW" "$RESET"
printf 'Base URL: %s\n' "$BASE_URL"
printf 'Client ID: %s\n\n' "$CLIENT_ID"

authorize_headers="$(mktemp)"
trap 'rm -f "$TMP_BODY" "$authorize_headers"' EXIT

authorize_code="$(
  curl -sS -D "$authorize_headers" -o /dev/null -w "%{http_code}" \
    "$authorize_url"
)"
authorize_location="$(grep -i '^location:' "$authorize_headers" | tail -1 | tr -d '\r' | cut -d' ' -f2-)"

if [ "$authorize_code" = "302" ] && printf '%s' "$authorize_location" | grep -q 'error=invalid_request'; then
  print_result "PASS" "Direct /authorize without request_uri was rejected"
else
  print_result "FAIL" "Direct /authorize without request_uri was not rejected as expected (status=${authorize_code})"
fi

token_code="$(
  curl -sS -o "$TMP_BODY" -w "%{http_code}" \
    -X POST "$token_url" \
    -H 'content-type: application/x-www-form-urlencoded' \
    --data "grant_type=authorization_code&code=placeholder&redirect_uri=https%3A%2F%2Fexample.com%2Fcb&code_verifier=placeholder&client_id=${CLIENT_ID}"
)"
token_body="$(cat "$TMP_BODY")"

if [ "$token_code" = "400" ] && printf '%s' "$token_body" | grep -q 'invalid_dpop_proof'; then
  print_result "PASS" "POST /token without DPoP was rejected"
else
  print_result "FAIL" "POST /token without DPoP was not rejected as expected (status=${token_code})"
fi

userinfo_code="$(
  curl -sS -o "$TMP_BODY" -w "%{http_code}" \
    "$userinfo_url" \
    -H 'authorization: Bearer fake-token'
)"
userinfo_body="$(cat "$TMP_BODY")"

if [ "$userinfo_code" = "401" ] && printf '%s' "$userinfo_body" | grep -q 'invalid_token'; then
  print_result "PASS" "GET /userinfo with a Bearer token and no DPoP was rejected"
else
  print_result "FAIL" "GET /userinfo with a Bearer token and no DPoP was not rejected as expected (status=${userinfo_code})"
fi

printf '\n'

if [ "$failures" -eq 0 ]; then
  printf '%sAll FAPI 2.0 boundary probes passed.%s\n' "$GREEN" "$RESET"
  printf 'Next: run the OIDF suite described in docs/maintainer-conformance.md for definitive conformance verification.\n'
  exit 0
else
  printf '%s%d probe(s) failed.%s\n' "$RED" "$failures" "$RESET" >&2
  printf 'Check docs/maintainer-conformance.md for setup, prerequisites, and the OIDF suite workflow.\n' >&2
  exit 1
fi
