#!/usr/bin/env bash
set -euo pipefail

package_name=lockspire
package_tar=${1:?package tar is required}
manifest=${2:?release manifest is required}
source_sha=${3:?source SHA is required}

python3 scripts/publish/release_artifact.py verify-local \
  --tar "$package_tar" \
  --manifest "$manifest" \
  --source-sha "$source_sha"

version=$(jq -er '.version' "$manifest")
local_checksum=$(jq -er '.artifact.sha256' "$manifest")
[[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+([.-][0-9A-Za-z.-]+)?$ ]]
[[ "$local_checksum" =~ ^[0-9a-f]{64}$ ]]

release_response="$(mktemp)"

cleanup() {
  rm -f "$release_response"
}

trap cleanup EXIT

release_url="https://hex.pm/api/packages/${package_name}/releases/${version}"
http_status="$(
  curl --silent --show-error --location \
    --output "$release_response" \
    --write-out '%{http_code}' \
    "$release_url"
)"

case "$http_status" in
  200)
    python3 scripts/publish/release_artifact.py verify-hex \
      --manifest "$manifest" \
      --response "$release_response"

    if [[ "$(jq -r '.has_docs' "$release_response")" == "true" ]]; then
      echo "Hex package ${package_name} ${version} and its docs already match the verified artifact."
    else
      echo "Hex package ${package_name} ${version} already matches; publishing missing docs only."
      mix hex.publish docs --yes
    fi
    ;;
  404)
    elixir scripts/publish/upload_hex_artifact.exs "$package_tar"
    mix hex.publish docs --yes
    ;;
  *)
    echo "Hex release lookup failed closed with HTTP ${http_status}." >&2
    exit 1
    ;;
esac
