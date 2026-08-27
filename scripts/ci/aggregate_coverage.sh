#!/usr/bin/env bash

set -euo pipefail

usage() {
  echo "usage: $0 --expected-sha SHA --input DIR --output DIR" >&2
  exit 64
}

expected_sha=""
input_dir=""
output_dir=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --expected-sha)
      expected_sha=${2:-}
      shift 2
      ;;
    --input)
      input_dir=${2:-}
      shift 2
      ;;
    --output)
      output_dir=${2:-}
      shift 2
      ;;
    *) usage ;;
  esac
done

[[ "$expected_sha" =~ ^[0-9a-f]{40}$ ]] || usage
[[ -d "$input_dir" && -n "$output_dir" ]] || usage

for command in python3 mix; do
  command -v "$command" >/dev/null 2>&1 || {
    echo "required command is unavailable: $command" >&2
    exit 1
  }
done

if [[ -e "$output_dir" ]]; then
  echo "coverage output already exists: $output_dir" >&2
  exit 1
fi

mkdir -p "$output_dir/cover"

python3 - "$input_dir" "$output_dir/cover" "$expected_sha" <<'PY'
import hashlib
import json
from pathlib import Path
import re
import shutil
import sys

input_dir = Path(sys.argv[1]).resolve()
cover_dir = Path(sys.argv[2]).resolve()
expected_sha = sys.argv[3]
expected = {"fast", "integration"}

manifests = sorted(input_dir.rglob("*.json"))
coverage_manifests = []

for path in manifests:
    try:
        payload = json.loads(path.read_text())
    except (OSError, json.JSONDecodeError):
        continue
    if isinstance(payload, dict) and "partition" in payload and "coverdata" in payload:
        coverage_manifests.append((path, payload))

partitions = [payload.get("partition") for _path, payload in coverage_manifests]
if len(coverage_manifests) != 2 or set(partitions) != expected or len(set(partitions)) != 2:
    raise SystemExit("coverage input must contain exactly one fast and one integration manifest")

all_coverdata = sorted(input_dir.rglob("*.coverdata"))
if len(all_coverdata) != 2:
    raise SystemExit("coverage input must contain exactly two coverdata files")

for manifest_path, payload in coverage_manifests:
    if set(payload) != {"schema_version", "partition", "source_sha", "coverdata", "sha256"}:
        raise SystemExit(f"unexpected coverage manifest fields: {manifest_path.name}")
    if payload["schema_version"] != 1 or payload["source_sha"] != expected_sha:
        raise SystemExit(f"coverage source mismatch: {manifest_path.name}")
    partition = payload["partition"]
    filename = payload["coverdata"]
    if filename != f"{partition}.coverdata" or not re.fullmatch(r"[a-z]+\.coverdata", filename):
        raise SystemExit(f"invalid coverdata name: {filename}")
    source = manifest_path.parent / filename
    if not source.is_file() or source.is_symlink():
        raise SystemExit(f"missing regular coverdata: {filename}")
    digest = hashlib.sha256(source.read_bytes()).hexdigest()
    if digest != payload["sha256"] or not re.fullmatch(r"[0-9a-f]{64}", digest):
        raise SystemExit(f"coverage checksum mismatch: {filename}")
    shutil.copyfile(source, cover_dir / filename)
PY

report_log="$output_dir/coverage-report.log"
env \
  LOCKSPIRE_COVERAGE_AGGREGATE=true \
  LOCKSPIRE_COMPLETE_COVERAGE=true \
  LOCKSPIRE_COVERAGE_OUTPUT="$output_dir/cover" \
  MIX_ENV=test \
  mix test.coverage | tee "$report_log"

percentage=$(awk '/\|[[:space:]]+[0-9]+\.[0-9]+%[[:space:]]+\| Total/ {gsub(/%/, "", $2); value=$2} END {print value}' "$report_log")

python3 - "$expected_sha" "$percentage" "$output_dir/coverage-receipt.json" <<'PY'
import json
from pathlib import Path
import sys

source_sha, percentage, receipt = sys.argv[1:]
payload = {
    "schema_version": 1,
    "source_sha": source_sha,
    "partitions": ["fast", "integration"],
    "threshold": 84.0,
    "coverage": float(percentage) if percentage else None,
}
Path(receipt).write_text(json.dumps(payload, sort_keys=True, separators=(",", ":")) + "\n")
PY

echo "Complete Mix coverage evidence saved to $output_dir"
