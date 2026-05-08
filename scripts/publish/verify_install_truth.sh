#!/usr/bin/env bash
set -euo pipefail

echo "==> Setting up verification environment..."
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

# Check required commands
for cmd in curl jq mix sed; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "Error: required command '$cmd' is not installed."
    exit 1
  fi
done

# Extract expected version from mix.exs
EXPECTED_VERSION=$(grep -oE 'version:\s+"[^"]+"' "$PWD/mix.exs" | cut -d'"' -f2)
if [ -z "$EXPECTED_VERSION" ]; then
  echo "Error: Could not extract expected version from mix.exs"
  exit 1
fi
echo "==> Expected version: $EXPECTED_VERSION"

echo "==> Querying Hex API for Lockspire package..."
MAX_RETRIES=12
RETRY_DELAY=10
FOUND=false

for i in $(seq 1 "$MAX_RETRIES"); do
  echo "  --> Attempt $i of $MAX_RETRIES..."
  HTTP_STATUS=$(curl -s -o "$TMP_DIR/hex_metadata.json" -w "%{http_code}" https://hex.pm/api/packages/lockspire || true)

  if [ "$HTTP_STATUS" -eq 200 ]; then
    # Check if the expected version is in the list of releases
    if jq -e ".releases[] | select(.version == \"$EXPECTED_VERSION\")" "$TMP_DIR/hex_metadata.json" > /dev/null; then
      echo "==> Version $EXPECTED_VERSION found in Hex API."
      FOUND=true
      break
    else
      echo "  --> Version $EXPECTED_VERSION not yet in Hex API. Retrying in ${RETRY_DELAY}s..."
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
DOCS_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$DOCS_URL" || true)

if [ "$DOCS_STATUS" -ne 200 ]; then
  echo "Error: Failed to fetch documentation at $DOCS_URL (HTTP $DOCS_STATUS)"
  exit 1
fi
echo "==> Hexdocs successfully verified."

echo "==> Generating clean-room Phoenix host app..."
cd "$TMP_DIR"
mix local.hex --force
mix local.rebar --force
# Accept 'Y' to any prompt if needed, though --force should suffice
mix archive.install hex phx_new --force

mix phx.new host_app --no-assets --no-ecto --no-html --no-mailer

cd host_app
echo "==> Injecting Lockspire dependency..."
if [[ "$OSTYPE" == "darwin"* ]]; then
  sed -i '' -e "s/{:phoenix,/{:lockspire, \"$EXPECTED_VERSION\"},\n      {:phoenix,/" mix.exs
else
  sed -i -e "s/{:phoenix,/{:lockspire, \"$EXPECTED_VERSION\"},\n      {:phoenix,/" mix.exs
fi

echo "==> Running mix deps.get..."
mix deps.get

echo "==> Running mix compile..."
mix compile

echo "==> Post-publish verification complete! Install Truth proven."
