#!/usr/bin/env bash
set -euo pipefail

package_name=lockspire
version="$(sed -nE 's/^[[:space:]]*version:[[:space:]]*"([^"]+)".*/\1/p' mix.exs | head -1)"
[[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]

package_tar="${package_name}-${version}.tar"
test -f "$package_tar"
local_checksum="$(sha256sum "$package_tar" | awk '{print $1}')"
[[ "$local_checksum" =~ ^[0-9a-f]{64}$ ]]

release_response="$(mktemp)"
trap 'rm -f "$release_response"' EXIT

release_url="https://hex.pm/api/packages/${package_name}/releases/${version}"
http_status="$(
  curl --silent --show-error --location \
    --output "$release_response" \
    --write-out '%{http_code}' \
    "$release_url"
)"

case "$http_status" in
  200)
    published_checksum="$(jq -er '.checksum' "$release_response")"
    [[ "$published_checksum" =~ ^[0-9a-f]{64}$ ]]
    test "$published_checksum" = "$local_checksum"

    if [[ "$(jq -r '.has_docs' "$release_response")" == "true" ]]; then
      echo "Hex package ${package_name} ${version} and its docs already match the verified artifact."
    else
      echo "Hex package ${package_name} ${version} already matches; publishing missing docs only."
      mix hex.publish docs --yes
    fi
    ;;
  404)
    mix hex.publish --yes
    ;;
  *)
    echo "Hex release lookup failed closed with HTTP ${http_status}." >&2
    exit 1
    ;;
esac
