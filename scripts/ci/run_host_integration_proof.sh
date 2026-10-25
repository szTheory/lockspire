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
# Validate every existing component before mkdir, stale-receipt deletion, or
# staging. This is a single-user invocation boundary, not a filesystem-race guard.
if ! stage_dir=$(python3 - "$repo_root" "$receipt_dir" <<'PY'
from pathlib import Path
import sys
try:
    repo = Path(sys.argv[1]).resolve(strict=True)
    # Command substitution strips trailing newlines; never validate one path
    # and then hand the shell a different path.
    if "\n" in sys.argv[2] or "\r" in sys.argv[2]:
        raise ValueError
    requested = Path(sys.argv[2])
    parts = requested.parts
    if not sys.argv[2].startswith(".artifacts/") or requested.is_absolute() or len(parts) < 2 or parts[0] != ".artifacts" or ".." in parts:
        raise ValueError
    current = repo
    for part in parts:
        current = current / part
        if current.is_symlink() or (current.exists() and not current.is_dir()):
            raise ValueError
    artifact_root = (repo / ".artifacts").resolve()
    destination = current.resolve()
    if destination == artifact_root or not destination.is_relative_to(artifact_root):
        raise ValueError
except (OSError, RuntimeError, ValueError):
    print("receipt directory must be below .artifacts", file=sys.stderr)
    raise SystemExit(1)
print(destination)
PY
); then
  exit 64
fi
if [[ "$pair" == locked ]]; then
  expected_phoenix=1.8.13
  expected_live_view=1.2.10
  lifecycle_selector=locked_admin_routes_lifecycle
  test_cwd=$repo_root
  db_name=lockspire_proof_locked_$(python3 -c 'import uuid; print(uuid.uuid4().hex[:20])')
else
  expected_phoenix=1.8.5
  expected_live_view=1.1.28
  lifecycle_selector=floor_admin_host_runtime
  test_cwd=$repo_root/compatibility/phoenix_1_8_live_view_1_1
  db_name=lockspire_proof_floor_$(python3 -c 'import uuid; print(uuid.uuid4().hex[:20])')
fi
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
pair_budget=900
mix_bin=mix
test_journey_bin=""
test_validator_bin=""
if [[ "${LOCKSPIRE_PROOF_TEST_MODE:-false}" == true ]]; then
  pair_budget=${LOCKSPIRE_PROOF_TEST_TIMEOUT_SECONDS:-900}
  [[ "$pair_budget" =~ ^[1-9][0-9]*$ ]] || usage
  mix_bin=${LOCKSPIRE_PROOF_TEST_MIX_BIN:?test mode requires a fake Mix executable}
  test_journey_bin=${LOCKSPIRE_PROOF_TEST_JOURNEY_BIN:?test mode requires a fake journey executable}
  test_validator_bin=${LOCKSPIRE_PROOF_TEST_VALIDATOR_BIN:?test mode requires a fake validator executable}
elif [[ -n "${LOCKSPIRE_PROOF_TEST_MIX_BIN:-}${LOCKSPIRE_PROOF_TEST_JOURNEY_BIN:-}${LOCKSPIRE_PROOF_TEST_VALIDATOR_BIN:-}${LOCKSPIRE_PROOF_TEST_TIMEOUT_SECONDS:-}" ]]; then
  echo "fake proof tools require LOCKSPIRE_PROOF_TEST_MODE=true" >&2
  exit 64
fi
deadline=$((started + pair_budget))
run_bounded() {
  limit=$1
  log=$2
  shift 2
  remaining=$((deadline - SECONDS))
  ((remaining > 0)) || { echo "pair proof exceeded its 900 second budget" >&2; return 124; }
  if ((limit > 0 && limit < remaining)); then remaining=$limit; fi
  python3 - "$remaining" "$log" "${command_cwd:-$repo_root}" "$@" <<'PY' &
import os, signal, subprocess, sys
sys.path.insert(0, os.path.join(os.getcwd(), "scripts", "acceptance", "clean_room"))
from package_input import stop_process_group
class Interrupted(Exception): pass
def interrupt(signum, _frame): raise Interrupted(signum)
for sig in (signal.SIGTERM, signal.SIGINT): signal.signal(sig, interrupt)
with open(sys.argv[2], "wb") as output:
    process = subprocess.Popen(sys.argv[4:], cwd=sys.argv[3], stdin=subprocess.DEVNULL, stdout=output, stderr=subprocess.STDOUT, start_new_session=True, close_fds=True)
    try:
        status = process.wait(timeout=int(sys.argv[1]))
    except (subprocess.TimeoutExpired, Interrupted) as error:
        for sig in (signal.SIGTERM, signal.SIGINT): signal.signal(sig, signal.SIG_IGN)
        stop_process_group(process, grace=14 if int(sys.argv[1]) > 6 else 1)
        if isinstance(error, subprocess.TimeoutExpired):
            print("bounded child timed out", file=sys.stderr)
            raise SystemExit(124)
        raise SystemExit(128 + error.args[0])
raise SystemExit(status if status >= 0 else 128 - status)
PY
  bounded_pid=$!
  local child_status=0
  wait "$bounded_pid" || child_status=$?
  bounded_pid=""
  return "$child_status"
}
run_in_test() { local command_cwd=$test_cwd; run_bounded "$@"; }
cleanup_owned() {
  original_status=$?
  trap '' TERM INT
  if [[ -n "${bounded_pid:-}" ]]; then
    kill -TERM "$bounded_pid" 2>/dev/null || true
    wait "$bounded_pid" 2>/dev/null || true
  fi
  # Only the generated lifecycle database belongs to this wrapper. Cleanup is
  # independently bounded after the pair budget, and raw log removal always runs.
  cleanup_status=0
  deadline=$((SECONDS + 10))
  run_in_test 6 "$private_logs/database-drop.log" env MIX_ENV=test LOCKSPIRE_TEST_DB_NAME="$db_name" "$mix_bin" ecto.drop --repo Lockspire.TestRepo --force || cleanup_status=$?
  rm -rf -- "$raw_root" || cleanup_status=1
  if ((original_status != 0)); then exit "$original_status"; fi
  if ((cleanup_status != 0)); then echo "host integration proof cleanup failed" >&2; exit 1; fi
}
trap cleanup_owned EXIT
trap 'exit 143' TERM
trap 'exit 130' INT
fail_stage() { stage=$1; status=$2; echo "host integration proof failed at $stage (exit $status)" >&2; exit "$status"; }
emit_lifecycle_diagnostic() {
  python3 - "$private_logs/tests.log" <<'PY' || {
import json, re, sys
from pathlib import Path
sys.path.insert(0, str(Path.cwd() / "scripts" / "acceptance" / "clean_room"))
from redaction import safe_failure_summary
try:
    text = Path(sys.argv[1]).read_text(encoding="utf-8", errors="replace")
except OSError:
    text = ""
matches = re.findall(r"(?m)^\s*\d+ tests?,\s*(\d+) failures?", text)
token = matches[-1] if matches else ""
if token and len(token) <= 6:
    try:
        failures = int(token)
    except ValueError:
        failures = 0
else:
    failures = 0
event = "assertion_failure" if failures else "runner_failure"
try:
    summary = safe_failure_summary(stage="lifecycle", scenario="all", event=event, field="count", count=failures)
except Exception:
    summary = {"stage": "lifecycle", "scenario": "all", "event": "runner_failure", "field": "count", "count": 0}
print("host integration lifecycle diagnostic: " + json.dumps(summary, sort_keys=True), file=sys.stderr)
PY
  printf '%s\n' 'host integration lifecycle diagnostic: {"count":0,"event":"runner_failure","field":"count","scenario":"all","stage":"lifecycle"}' >&2
  }
}
emit_browser_diagnostic() {
  python3 - "$private_logs/browser-$1.log" <<'PY' || {
import json, sys
from pathlib import Path
sys.path.insert(0, str(Path.cwd() / "scripts" / "acceptance"))
from clean_room_admin_journey import BROWSER_COUNTS, BROWSER_FAILURES, FULL_OBSERVATIONS, FULL_REQUIRED, safe_browser_failure_summary
try:
    lines = Path(sys.argv[1]).read_text(encoding="utf-8", errors="replace").splitlines()
except OSError:
    lines = []
summary = None
for line in reversed(lines):
    prefix = "browser proof failed: "
    if not line.startswith(prefix):
        continue
    try:
        summary = safe_browser_failure_summary(json.loads(line[len(prefix):]))
    except (json.JSONDecodeError, TypeError, ValueError):
        continue
    break
if summary is None:
    summary = safe_browser_failure_summary({})
else:
    observed = json.loads(line[len(prefix):])
    case_ids = set(FULL_REQUIRED)
    case_failures = set(BROWSER_FAILURES) | {"failure_unrecognized"}
    outcomes = {"passed", "failed", "unknown"}
    count_fields = BROWSER_COUNTS | {"params_checks", "http_checks", "staff_checks"}
    def safe_enum(value, allowed, fallback):
        return value if isinstance(value, str) and value in allowed else fallback
    def safe_values(value, allowed):
        if not isinstance(value, list):
            return []
        return sorted({item for item in value if isinstance(item, str) and item in allowed})
    first = observed.get("first_case")
    if isinstance(first, dict):
        summary["first_case"] = {
            "id": safe_enum(first.get("id"), case_ids, "unknown"),
            "failure": safe_enum(first.get("failure"), case_failures, "failure_unrecognized"),
            "outcome": safe_enum(first.get("outcome"), outcomes, "unknown"),
            "count_fields": safe_values(first.get("count_fields"), count_fields),
            "observation_fields": safe_values(first.get("observation_fields"), set(FULL_OBSERVATIONS)),
        }
    failed_cases = observed.get("failed_cases")
    if isinstance(failed_cases, list):
        retained = []
        for item in failed_cases[:8]:
            if not isinstance(item, dict):
                continue
            retained.append({
                "id": safe_enum(item.get("id"), case_ids, "unknown"),
                "failure": safe_enum(item.get("failure"), case_failures, "failure_unrecognized"),
                "false_evidence": safe_values(item.get("false_evidence"), set(FULL_OBSERVATIONS)),
            })
        if retained:
            summary["failed_cases"] = retained
print("host integration browser diagnostic: " + json.dumps(summary, sort_keys=True), file=sys.stderr)
PY
  printf '%s\n' 'host integration browser diagnostic: {"counts":{},"failure":"failure_missing","observations":{},"outcome":"unknown","stage":"unknown"}' >&2
  }
}
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
run_bounded 0 "$private_logs/package-build.log" "$mix_bin" hex.build --output "$candidate_tar" || status=$?
((status == 0)) || fail_stage package_build "$status"
[[ -s "$candidate_tar" ]] || fail_stage package_identity 1
export LOCKSPIRE_PACKAGE_ROOT=$package_dir
candidate_sha=$(python3 - "$candidate_tar" <<'PY'
import hashlib, sys
with open(sys.argv[1], "rb") as handle: print(hashlib.file_digest(handle, "sha256").hexdigest())
PY
)
status=0
run_bounded 0 "$private_logs/package-identity.log" python3 scripts/acceptance/clean_room/package_input.py --inspect --package-tar "$candidate_tar" --package-sha256 "$candidate_sha" || status=$?
((status == 0)) || fail_stage package_identity "$status"
identity=$(<"$private_logs/package-identity.log")
candidate_version=$(python3 -c 'import json,sys; print(json.load(sys.stdin)["version"])' <<<"$identity")
candidate_sha=$(python3 -c 'import json,sys; print(json.load(sys.stdin)["archive_sha256"])' <<<"$identity")
candidate_tree=$(python3 -c 'import json,sys; print(json.load(sys.stdin)["tree_sha256"])' <<<"$identity")
source_revision=${GITHUB_SHA:-$(git rev-parse HEAD)}
[[ "$source_revision" =~ ^[0-9a-f]{40,64}$ && -n "$candidate_version" && "$candidate_sha" =~ ^[0-9a-f]{64}$ && "$candidate_tree" =~ ^[0-9a-f]{64}$ ]] || fail_stage package_identity 1
runtime_expression='Application.load(:phoenix); Application.load(:phoenix_live_view); IO.puts("PAIR_RUNTIME|" <> to_string(Application.spec(:phoenix, :vsn)) <> "|" <> to_string(Application.spec(:phoenix_live_view, :vsn)) <> "|" <> System.version() <> "|" <> to_string(:erlang.system_info(:otp_release)))'
status=0
run_in_test 0 "$private_logs/runtime.log" env MIX_ENV=test LOCKSPIRE_TEST_DB_NAME="$db_name" "$mix_bin" run --no-start -e "$runtime_expression" || status=$?
((status == 0)) || fail_stage lifecycle_runtime "$status"
runtime_line=$(grep -E '^PAIR_RUNTIME\|' "$private_logs/runtime.log" | tail -n 1 || true)
IFS='|' read -r _ actual_phoenix actual_live_view actual_elixir actual_otp <<<"$runtime_line"
[[ "$actual_phoenix" == "$expected_phoenix" && "$actual_live_view" == "$expected_live_view" && -n "$actual_elixir" && -n "$actual_otp" ]] || fail_stage lifecycle_runtime 1
if [[ "$pair" == locked ]]; then setup_task=test.setup; else setup_task=lockspire.test.setup; fi
status=0
run_in_test 0 "$private_logs/setup.log" env MIX_ENV=test LOCKSPIRE_TEST_DB_NAME="$db_name" "$mix_bin" "$setup_task" || status=$?
((status == 0)) || fail_stage lifecycle_setup "$status"
status=0
if [[ "$pair" == locked ]]; then
  run_in_test 0 "$private_logs/tests.log" env MIX_ENV=test LOCKSPIRE_TEST_DB_NAME="$db_name" "$mix_bin" test test/lockspire/web/admin_routes_compile_test.exs test/lockspire/web/admin_route_inventory_test.exs test/lockspire/web/admin_route_separation_test.exs test/lockspire/web/live/admin/admin_route_integration_test.exs || status=$?
else
  run_in_test 0 "$private_logs/tests.log" env MIX_ENV=test LOCKSPIRE_TEST_DB_NAME="$db_name" "$mix_bin" test test/admin_host_runtime_test.exs || status=$?
fi
((status == 0)) || { emit_lifecycle_diagnostic || true; fail_stage lifecycle_tests "$status"; }
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
python3 - "$stage_dir/lifecycle.json" "$source_revision" "$dirty_source" "$candidate_version" "$candidate_sha" "$candidate_tree" "$pair" "$lifecycle_selector" "$expected_phoenix" "$expected_live_view" "$actual_elixir" "$actual_otp" "$test_count" <<'PY'
import json, os, sys, tempfile
path, source, dirty, version, archive, tree, pair, selector, phoenix, live_view, elixir, otp, count = sys.argv[1:]
value = {"schema_version": 1, "source_revision": source, "source_dirty": dirty == "true", "candidate": {"version": version, "archive_sha256": archive, "tree_sha256": tree}, "pair": pair, "selector": selector, "runtime": {"phoenix": phoenix, "live_view": live_view, "elixir": elixir, "otp": otp}, "evidence_kind": "shared_host_lifecycle", "tests_passed": int(count), "result": "passed"}
fd, temporary = tempfile.mkstemp(prefix=".lifecycle.", dir=os.path.dirname(path))
with os.fdopen(fd, "w", encoding="utf-8") as handle:
    json.dump(value, handle, sort_keys=True, separators=(",", ":")); handle.write("\n"); handle.flush(); os.fsync(handle.fileno())
os.replace(temporary, path)
PY
export CLEAN_ROOM_CACHE_ROOT=$repo_root/tmp/host-integration-cache
journey_script=$repo_root/scripts/acceptance/clean_room_admin_journey.py
validator_script=$repo_root/scripts/acceptance/clean_room/admin_receipts.py
if [[ -n "$test_journey_bin" ]]; then journey_command=("$test_journey_bin"); else journey_command=(python3 "$journey_script"); fi
if [[ -n "$test_validator_bin" ]]; then validator_command=("$test_validator_bin"); else validator_command=(python3 "$validator_script"); fi
for index in 0 1 2; do
  if [[ "$index" == 0 ]]; then mount=/lockspire; suffix=lockspire; elif [[ "$index" == 1 ]]; then mount=/teams/ops/identity; suffix=nested; else mount=/; suffix=root; fi
  run_id=$(python3 -c 'import uuid; print(uuid.uuid4())')
  raw_receipt=$raw_root/$pair-$suffix.json
  status=0
  run_bounded 180 "$private_logs/browser-$index.log" "${journey_command[@]}" --pair "$pair" --mount "$mount" --scenario full --receipt "$raw_receipt" --run-id "$run_id" --package-tar "$candidate_tar" --package-sha256 "$candidate_sha" || status=$?
  ((status == 0)) || { emit_browser_diagnostic "$index" || true; fail_stage "browser_$index" "$status"; }
  status=0
  run_bounded 15 "$private_logs/validate-$index.log" "${validator_command[@]}" --check "$raw_receipt" --expected-run-id "$run_id" --expected-source "$source_revision" --expected-pair "$pair" --expected-mount "$mount" --expected-archive "$candidate_sha" --expected-tree "$candidate_tree" --expected-version "$candidate_version" --expected-scenario-set full || status=$?
  ((status == 0)) || fail_stage "receipt_validation_$index" "$status"
  install -m 600 "$raw_receipt" "$stage_dir/$pair-$suffix.json"
done
elapsed=$((SECONDS - started))
printf 'Host integration proof passed: pair=%s tests=%s mounts=3 duration=%ss source=%s\n' "$pair" "$test_count" "$elapsed" "$source_revision"
