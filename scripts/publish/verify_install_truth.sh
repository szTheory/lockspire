#!/usr/bin/env bash
set -euo pipefail

manifest=${1:?release manifest is required}
source_sha=${2:?source SHA is required}
receipt=${3:-install-truth-receipt.json}

echo "==> Setting up exact-version verification..."
INSTALL_TRUTH_DIR=$(mktemp -d -t lockspire-install-truth.XXXXXX)
trap 'rm -rf "$INSTALL_TRUTH_DIR"' EXIT

# Check required commands
for cmd in curl jq mix python3; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "Error: required command '$cmd' is not installed."
    exit 1
  fi
done

EXPECTED_VERSION=$(jq -er '.version' "$manifest")
EXPECTED_CHECKSUM=$(jq -er '.artifact.sha256' "$manifest")
test "$(jq -er '.source_sha' "$manifest")" = "$source_sha"
echo "==> Expected version: $EXPECTED_VERSION"

echo "==> Querying Hex API for Lockspire package..."
MAX_RETRIES=12
RETRY_DELAY=10
FOUND=false

for i in $(seq 1 "$MAX_RETRIES"); do
  echo "  --> Attempt $i of $MAX_RETRIES..."
  HTTP_STATUS=$(curl --silent --show-error --location --retry 3 --retry-all-errors \
    -o "$INSTALL_TRUTH_DIR/hex_metadata.json" -w "%{http_code}" \
    "https://hex.pm/api/packages/lockspire/releases/$EXPECTED_VERSION" || true)

  if [ "$HTTP_STATUS" -eq 200 ]; then
    if python3 scripts/publish/release_artifact.py verify-hex \
      --manifest "$manifest" \
      --response "$INSTALL_TRUTH_DIR/hex_metadata.json"; then
      echo "==> Exact checksum for $EXPECTED_VERSION found in Hex API."
      FOUND=true
      break
    else
      echo "Error: Hex published metadata differs from the verified manifest." >&2
      exit 1
    fi
  else
    echo "  --> Failed to fetch Hex metadata (HTTP $HTTP_STATUS). Retrying in ${RETRY_DELAY}s..."
  fi
  sleep "$RETRY_DELAY"
done

if [ "$FOUND" != true ]; then
  echo "Error: Version $EXPECTED_VERSION not found on Hex after $(($MAX_RETRIES * $RETRY_DELAY)) seconds."
  exit 1
fi

echo "==> Verifying Hexdocs availability..."
DOCS_URL="https://hexdocs.pm/lockspire/$EXPECTED_VERSION/supported-surface.html"
# -L is required: hexdocs.pm/lockspire/... now 301-redirects to the
# per-package host lockspire.hexdocs.pm/..., so a non-following curl reports 301
# and fails the check even when the docs are published and reachable.
DOCS_STATUS=$(curl --silent --show-error --location --retry 3 --retry-all-errors -o /dev/null -w "%{http_code}" "$DOCS_URL" || true)

if [ "$DOCS_STATUS" -ne 200 ]; then
  echo "Error: Failed to fetch documentation at $DOCS_URL (HTTP $DOCS_STATUS)"
  exit 1
fi
echo "==> Hexdocs successfully verified."

echo "==> Running exact public package through the clean-room HTTP journey..."
bash scripts/acceptance/run_clean_room_saas_journey.sh \
  --hex-version "$EXPECTED_VERSION" \
  --package-sha256 "$EXPECTED_CHECKSUM" \
  --only happy_path

python3 scripts/publish/release_artifact.py receipt \
  --manifest "$manifest" \
  --stage postpublish \
  --output "$receipt"

echo "==> Post-publish checksum and HTTP install truth proven."
