#!/usr/bin/env bash
set -euo pipefail
usage() { echo "usage: $0 --pair locked|floor --receipt-dir DIR" >&2; exit 64; }
pair=""
receipt_dir=""
while (($#)); do
  case "$1" in
    --pair) [[ -z "$pair" && $# -ge 2 ]] || usage; pair=$2; shift 2 ;;
    --receipt-dir) [[ -z "$receipt_dir" && $# -ge 2 ]] || usage; receipt_dir=$2; shift 2 ;;
    *) usage ;;
  esac
done
[[ "$pair" == locked || "$pair" == floor ]] || usage
[[ -n "$receipt_dir" ]] || usage
repo_root=$(git rev-parse --show-toplevel)
cd "$repo_root"
export MIX_ENV=test
case "$receipt_dir" in .artifacts/*) ;; *) echo "receipt directory must be below .artifacts" >&2; exit 64 ;; esac
if [[ "$pair" == locked ]]; then
  expected_phoenix=1.8.13
  expected_live_view=1.2.10
  test_cwd=$repo_root
  db_name=lockspire_proof_locked_$(python3 -c 'import uuid; print(uuid.uuid4().hex[:20])')
else
  expected_phoenix=1.8.5
  expected_live_view=1.1.28
  test_cwd=$repo_root/compatibility/phoenix_1_8_live_view_1_1
  db_name=lockspire_proof_floor_$(python3 -c 'import uuid; print(uuid.uuid4().hex[:20])')
fi
case "$receipt_dir" in /*) stage_dir=$receipt_dir ;; *) stage_dir=$repo_root/$receipt_dir ;; esac
mkdir -p "$stage_dir"
for name in lifecycle.json "$pair-lockspire.json" "$pair-nested.json" "$pair-root.json"; do
  if [[ -e "$stage_dir/$name" ]]; then rm -f -- "$stage_dir/$name"; fi
done
for path in "$stage_dir"/*; do
  [[ -e "$path" ]] || continue
  echo "receipt directory contains an unexpected entry" >&2
  exit 64
done
raw_root=$(mktemp -d "${TMPDIR:-/tmp}/lockspire-host-proof.XXXXXX")
chmod 700 "$raw_root"
private_logs=$raw_root/logs
mkdir -m 700 "$private_logs"
trap 'rm -rf -- "$raw_root"' EXIT
started=$SECONDS
deadline=$((started + 900))
run_bounded() {
  limit=$1
  log=$2
  shift 2
  remaining=$((deadline - SECONDS))
  ((remaining > 0)) || { echo "pair proof exceeded its 900 second budget" >&2; return 124; }
  if ((limit > 0 && limit < remaining)); then remaining=$limit; fi
  python3 - "$remaining" "$log" "$@" <<'PY'
import os, signal, subprocess, sys
with open(sys.argv[2], "wb") as output:
    process = subprocess.Popen(sys.argv[3:], stdin=subprocess.DEVNULL, stdout=output, stderr=subprocess.STDOUT, start_new_session=True, close_fds=True)
    try:
        status = process.wait(timeout=int(sys.argv[1]))
    except subprocess.TimeoutExpired:
        try:
            os.killpg(process.pid, signal.SIGTERM)
            process.wait(timeout=5)
        except (OSError, subprocess.TimeoutExpired):
            try: os.killpg(process.pid, signal.SIGKILL)
            except OSError: pass
            process.wait()
        print("bounded child timed out", file=sys.stderr)
        raise SystemExit(124)
raise SystemExit(status if status >= 0 else 128 - status)
PY
}
fail_stage() { stage=$1; status=$2; echo "host integration proof failed at $stage (exit $status)" >&2; exit "$status"; }
command -v node >/dev/null 2>&1 || { echo "host integration proof requires installed Node.js >=22.15" >&2; exit 1; }
node -e 'const [major,minor]=process.versions.node.split(".").map(Number); if (major < 22 || (major === 22 && minor < 15)) process.exit(1)' >/dev/null 2>&1 || { echo "host integration proof requires installed Node.js >=22.15 with built-in WebSocket" >&2; exit 1; }
chrome=""
if [[ -x "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" ]]; then
  chrome="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
else
  for candidate in google-chrome chromium chromium-browser; do
    candidate_path=$(command -v "$candidate" 2>/dev/null || true)
    if [[ -n "$candidate_path" ]] && "$candidate_path" --version >/dev/null 2>&1; then chrome=$candidate_path; break; fi
  done
fi
[[ -n "$chrome" && -x "$chrome" ]] || { echo "host integration proof requires an installed Chrome-compatible browser" >&2; exit 1; }
"$chrome" --version >/dev/null 2>&1 || { echo "installed browser preflight failed" >&2; exit 1; }
status=0
package_dir=$raw_root/package
mkdir -m 700 "$package_dir"
candidate_version=$(sed -nE 's/^[[:space:]]*version: "([^"]+)".*/\1/p' mix.exs | head -n 1)
candidate_tar=$package_dir/lockspire-$candidate_version.tar
run_bounded 0 "$private_logs/package-build.log" mix hex.build --output "$candidate_tar" || status=$?
((status == 0)) || fail_stage package_build "$status"
[[ -s "$candidate_tar" ]] || fail_stage package_identity 1
export LOCKSPIRE_PACKAGE_ROOT=$package_dir
candidate_sha=$(python3 - "$candidate_tar" <<'PY'
import hashlib, sys
with open(sys.argv[1], "rb") as handle: print(hashlib.file_digest(handle, "sha256").hexdigest())
PY
)
identity=$(python3 scripts/acceptance/clean_room/package_input.py --inspect --package-tar "$candidate_tar" --package-sha256 "$candidate_sha") || fail_stage package_identity 1
candidate_version=$(python3 -c 'import json,sys; print(json.load(sys.stdin)["version"])' <<<"$identity")
candidate_sha=$(python3 -c 'import json,sys; print(json.load(sys.stdin)["archive_sha256"])' <<<"$identity")
candidate_tree=$(python3 -c 'import json,sys; print(json.load(sys.stdin)["tree_sha256"])' <<<"$identity")
source_revision=${GITHUB_SHA:-$(git rev-parse HEAD)}
[[ "$source_revision" =~ ^[0-9a-f]{40,64}$ && -n "$candidate_version" && "$candidate_sha" =~ ^[0-9a-f]{64}$ && "$candidate_tree" =~ ^[0-9a-f]{64}$ ]] || fail_stage package_identity 1
runtime_expression='Application.load(:phoenix); Application.load(:phoenix_live_view); IO.puts("PAIR_RUNTIME|" <> to_string(Application.spec(:phoenix, :vsn)) <> "|" <> to_string(Application.spec(:phoenix_live_view, :vsn)) <> "|" <> System.version() <> "|" <> to_string(:erlang.system_info(:otp_release)))'
status=0
(cd "$test_cwd" && run_bounded 0 "$private_logs/runtime.log" env MIX_ENV=test LOCKSPIRE_TEST_DB_NAME="$db_name" mix run --no-start -e "$runtime_expression") || status=$?
((status == 0)) || fail_stage lifecycle_runtime "$status"
runtime_line=$(grep -E '^PAIR_RUNTIME\|' "$private_logs/runtime.log" | tail -n 1 || true)
IFS='|' read -r _ actual_phoenix actual_live_view actual_elixir actual_otp <<<"$runtime_line"
[[ "$actual_phoenix" == "$expected_phoenix" && "$actual_live_view" == "$expected_live_view" && -n "$actual_elixir" && -n "$actual_otp" ]] || fail_stage lifecycle_runtime 1
if [[ "$pair" == locked ]]; then setup_task=test.setup; else setup_task=lockspire.test.setup; fi
status=0
(cd "$test_cwd" && run_bounded 0 "$private_logs/setup.log" env MIX_ENV=test LOCKSPIRE_TEST_DB_NAME="$db_name" mix "$setup_task") || status=$?
((status == 0)) || fail_stage lifecycle_setup "$status"
status=0
if [[ "$pair" == locked ]]; then
  (cd "$test_cwd" && run_bounded 0 "$private_logs/tests.log" env MIX_ENV=test LOCKSPIRE_TEST_DB_NAME="$db_name" mix test test/lockspire/web/admin_routes_compile_test.exs test/lockspire/web/admin_route_inventory_test.exs test/lockspire/web/admin_route_separation_test.exs test/lockspire/web/live/admin/admin_route_integration_test.exs) || status=$?
else
  (cd "$test_cwd" && run_bounded 0 "$private_logs/tests.log" env MIX_ENV=test LOCKSPIRE_TEST_DB_NAME="$db_name" mix test test/admin_host_runtime_test.exs) || status=$?
fi
((status == 0)) || fail_stage lifecycle_tests "$status"
test_count=$(python3 - "$private_logs/tests.log" <<'PY'
import re, sys
text = open(sys.argv[1], encoding="utf-8", errors="replace").read()
matches = re.findall(r"(?m)^\s*(\d+) tests?,\s*\d+ failures?", text)
matches += re.findall(r"(?m)^Result:\s*(\d+) passed\s*$", text)
print(matches[-1] if matches else "0")
PY
)
[[ "$test_count" =~ ^[1-9][0-9]*$ ]] || fail_stage lifecycle_tests 1
dirty_source=$(git status --porcelain --untracked-files=no | grep -q . && echo true || echo false)
python3 - "$stage_dir/lifecycle.json" "$source_revision" "$dirty_source" "$candidate_version" "$candidate_sha" "$candidate_tree" "$pair" "$expected_phoenix" "$expected_live_view" "$actual_elixir" "$actual_otp" "$test_count" <<'PY'
import json, os, sys, tempfile
path, source, dirty, version, archive, tree, pair, phoenix, live_view, elixir, otp, count = sys.argv[1:]
value = {"schema_version": 1, "source_revision": source, "source_dirty": dirty == "true", "candidate": {"version": version, "archive_sha256": archive, "tree_sha256": tree}, "pair": pair, "runtime": {"phoenix": phoenix, "live_view": live_view, "elixir": elixir, "otp": otp}, "evidence_kind": "shared_host_lifecycle", "tests_passed": int(count), "result": "passed"}
fd, temporary = tempfile.mkstemp(prefix=".lifecycle.", dir=os.path.dirname(path))
with os.fdopen(fd, "w", encoding="utf-8") as handle:
    json.dump(value, handle, sort_keys=True, separators=(",", ":")); handle.write("\n"); handle.flush(); os.fsync(handle.fileno())
os.replace(temporary, path)
PY
export CLEAN_ROOM_CACHE_ROOT=$repo_root/tmp/host-integration-cache
journey_script=$repo_root/scripts/acceptance/clean_room_admin_journey.py
validator_script=$repo_root/scripts/acceptance/clean_room/admin_receipts.py
for index in 0 1 2; do
  if [[ "$index" == 0 ]]; then mount=/lockspire; suffix=lockspire; elif [[ "$index" == 1 ]]; then mount=/teams/ops/identity; suffix=nested; else mount=/; suffix=root; fi
  run_id=$(python3 -c 'import uuid; print(uuid.uuid4())')
  raw_receipt=$raw_root/$pair-$suffix.json
  status=0
  run_bounded 180 "$private_logs/browser-$index.log" python3 "$journey_script" --pair "$pair" --mount "$mount" --scenario full --receipt "$raw_receipt" --run-id "$run_id" --package-tar "$candidate_tar" --package-sha256 "$candidate_sha" || status=$?
  ((status == 0)) || fail_stage "browser_$index" "$status"
  status=0
  run_bounded 15 "$private_logs/validate-$index.log" python3 "$validator_script" --check "$raw_receipt" --expected-run-id "$run_id" --expected-source "$source_revision" --expected-pair "$pair" --expected-mount "$mount" --expected-archive "$candidate_sha" --expected-tree "$candidate_tree" --expected-version "$candidate_version" --expected-scenario-set full || status=$?
  ((status == 0)) || fail_stage "receipt_validation_$index" "$status"
  install -m 600 "$raw_receipt" "$stage_dir/$pair-$suffix.json"
done
elapsed=$((SECONDS - started))
printf 'Host integration proof passed: pair=%s tests=%s mounts=3 duration=%ss source=%s\n' "$pair" "$test_count" "$elapsed" "$source_revision"
