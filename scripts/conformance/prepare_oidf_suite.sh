#!/usr/bin/env bash

set -euo pipefail
umask 077

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
LOCK_PATH="${ROOT_DIR}/scripts/conformance/oidf-suite-lock.json"
VALIDATOR="${ROOT_DIR}/scripts/conformance/oidf_inputs.py"

usage() {
  echo "usage: $0 --output-dir PATH" >&2
  exit 64
}

[[ $# -eq 2 && "$1" == "--output-dir" ]] || usage

output_dir=$(python3 -c 'from pathlib import Path; import sys; print(Path(sys.argv[1]).resolve())' "$2")
[[ "$output_dir" != "/" && ! -e "$output_dir" ]] || {
  echo "OIDF preparation requires a new non-root output directory" >&2
  exit 1
}

python3 "$VALIDATOR" --lock "$LOCK_PATH" --validate-only
mkdir -m 700 "$output_dir"
download_dir="$output_dir/downloads"
mkdir -m 700 "$download_dir"

download() {
  local url=$1
  local target=$2

  mkdir -p "$(dirname "$target")"
  curl --fail --location --silent --show-error --proto '=https' --tlsv1.2 "$url" --output "$target"
}

archive_url=$(python3 -c 'import json, sys; print(json.load(open(sys.argv[1]))["suite"]["archive"]["url"])' "$LOCK_PATH")
download "$archive_url" "$download_dir/conformance-suite.tar.gz"

while IFS=$'\t' read -r path url; do
  download "$url" "$download_dir/$path"
done < <(python3 - "$LOCK_PATH" <<'PY'
import json
import sys
for path, item in json.load(open(sys.argv[1]))["helpers"].items():
    print(f"{path}\t{item['url']}")
PY
)

python3 "$VALIDATOR" --lock "$LOCK_PATH" --verify-downloads "$download_dir"
python3 "$VALIDATOR" --lock "$LOCK_PATH" --normalize-compose \
  "$download_dir/docker-compose-prebuilt.yml" "$output_dir/docker-compose.locked.yml"
mkdir -m 700 -p "$output_dir/mongo/data"

suite_commit=$(python3 -c 'import json, sys; print(json.load(open(sys.argv[1]))["suite"]["commit"])' "$LOCK_PATH")
python3 "${ROOT_DIR}/scripts/conformance/extract_oidf_suite.py" \
  --archive "$download_dir/conformance-suite.tar.gz" \
  --commit "$suite_commit" \
  --output "$output_dir/suite"

for helper in scripts/run-test-plan.py scripts/conformance.py scripts/test_plan_parser.py; do
  cmp -s "$download_dir/$helper" "$output_dir/suite/$helper" || {
    echo "OIDF archive helper does not match its independently pinned download: $helper" >&2
    exit 1
  }
done

python3 - "$LOCK_PATH" "$output_dir/images.env" <<'PY'
import json
import sys
from pathlib import Path

lock = json.load(open(sys.argv[1]))
names = {"mongodb": "MONGODB_IMAGE", "nginx": "NGINX_IMAGE", "server": "SERVER_IMAGE"}
lines = [f"{names[name]}={item['repository']}@{item['digest']}" for name, item in lock["images"].items()]
Path(sys.argv[2]).write_text("\n".join(lines) + "\n", encoding="utf-8")
PY

echo "OIDF suite inputs prepared at $output_dir"
