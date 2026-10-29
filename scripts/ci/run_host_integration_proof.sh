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
cleanup_early_raw_root() {
  local original_status=$? cleanup_status=0
  trap - EXIT
  if [[ -n "${raw_root:-}" && -d "$raw_root" ]]; then
    rm -rf -- "$raw_root" || {
      echo "host integration proof cleanup failed" >&2
      cleanup_status=125
    }
  fi
  if ((cleanup_status != 0)); then exit "$cleanup_status"; fi
  exit "$original_status"
}
trap cleanup_early_raw_root EXIT
chmod 700 "$raw_root"
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
bounded_result=''
bounded_status=0
cleanup_record_emitted=false
run_bounded() {
  limit=$1
  stage=$2
  shift 2
  remaining=$((deadline - SECONDS))
  ((remaining > 0)) || remaining=0
  if ((limit > 0 && limit < remaining)); then remaining=$limit; fi
  bounded_launcher_status=0
  bounded_file=$(mktemp "$raw_root/result.XXXXXX")
  python3 - "$remaining" "$stage" "${command_cwd:-$repo_root}" "$@" >"$bounded_file" 2>/dev/null <<'PY' &
import json, os, re, selectors, signal, subprocess, sys, time
sys.path.insert(0, os.path.join(os.getcwd(), "scripts", "acceptance", "clean_room"))
from package_input import _OWNED_IDENTITIES, owned_session_state, start_owned_session, stop_process_group
sys.path.insert(0, os.path.join(os.getcwd(), "scripts", "acceptance"))
from clean_room_admin_journey import FAILURE_RECORD_SCHEMA, safe_browser_failure_summary, validate_failure_record
class Interrupted(Exception): pass
def interrupt(signum, _frame): raise Interrupted(signum)
for sig in (signal.SIGTERM, signal.SIGINT): signal.signal(sig, interrupt)
process = None
identity = None
selector = None
streams = {}
status = 125
stopped = True
reason = "runner_failure"
native_exit = None
output_limit = 4 * 1024 * 1024
try:
    deadline = time.monotonic() + int(sys.argv[1])
    if int(sys.argv[1]) <= 0:
        raise subprocess.TimeoutExpired((), 0)
    process = start_owned_session(sys.argv[4:], cwd=sys.argv[3], env=dict(os.environ),
        stdin=subprocess.DEVNULL, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
        start_new_session=True, close_fds=True)
    identity = _OWNED_IDENTITIES.get(process.pid)
    selector = selectors.DefaultSelector()
    streams = {process.stdout: bytearray(), process.stderr: bytearray()}
    for stream in streams:
        selector.register(stream, selectors.EVENT_READ)
    total = 0
    while selector.get_map():
        remaining = deadline - time.monotonic()
        if remaining <= 0:
            raise subprocess.TimeoutExpired(process.args, int(sys.argv[1]))
        for key, _ in selector.select(min(remaining, 0.25)):
            chunk = os.read(key.fileobj.fileno(), 65536)
            if not chunk:
                selector.unregister(key.fileobj)
                continue
            if total + len(chunk) > output_limit:
                reason = "output_limit_exceeded"
                status = 125
                streams = {process.stdout: bytearray(), process.stderr: bytearray()}
                raise Interrupted(signal.SIGTERM)
            streams[key.fileobj].extend(chunk)
            total += len(chunk)
    status = process.wait(timeout=max(0.1, deadline - time.monotonic()))
    status = status if status >= 0 else 128 - status
    reason = "native_exit"
except (subprocess.TimeoutExpired, Interrupted) as error:
    if isinstance(error, subprocess.TimeoutExpired):
        status = 124
        reason = "timeout"
    elif reason != "output_limit_exceeded":
        status = 143
        reason = "interrupted"
except BaseException:
    status = 125
finally:
    if selector is not None:
        selector.close()
    if process is not None:
        try:
            grace = (14 if int(sys.argv[1]) > 6 else 1) if reason in {"timeout", "interrupted", "output_limit_exceeded"} else 3
            # The factory's signal handler may already have drained and
            # forgotten this child. Only its original RAM pin plus independent
            # exact group absence can accept that completed cleanup.
            if (identity is not None and process.pid not in _OWNED_IDENTITIES
                    and owned_session_state(identity) == "absent"):
                stopped = True
            else:
                stopped = stop_process_group(process, grace=grace)
        except BaseException:
            stopped = False
        native_exit = process.poll()
stdout = bytes(streams.get(getattr(process, "stdout", None), b""))
stderr = bytes(streams.get(getattr(process, "stderr", None), b""))
for stream in (getattr(process, "stdout", None), getattr(process, "stderr", None)):
    if stream is not None:
        stream.close()
result = {"schema": "lockspire-admin-command-result-v1", "status": status,
          "native_exit": native_exit, "stopped": stopped, "reason": reason}
def unique_object(pairs):
    value = {}
    for key, item in pairs:
        if key in value:
            raise ValueError
        value[key] = item
    return value
if sys.argv[2] == "browser":
    record = cleanup = None
    primary_count = cleanup_count = 0
    browser = []
    try:
        text = stderr.decode("utf-8", "strict")
        malformed = False
    except UnicodeError:
        text = ""
        malformed = True
    for line in text.splitlines():
        for prefix, kind in (("admin proof failure record: ", "primary"), ("admin proof cleanup record: ", "cleanup")):
            if not line.startswith(prefix):
                continue
            if kind == "primary": primary_count += 1
            else: cleanup_count += 1
            try: selected = validate_failure_record(json.loads(line[len(prefix):], object_pairs_hook=unique_object))
            except (TypeError, ValueError, RecursionError): selected = None
            if selected is None or (kind == "cleanup" and selected["stage"] != "cleanup"):
                malformed = True
            elif kind == "primary": record = selected
            else: cleanup = selected
        prefix = "browser proof failed: "
        if line.startswith(prefix) and len(browser) < 8:
            try: summary = safe_browser_failure_summary(json.loads(line[len(prefix):], object_pairs_hook=unique_object))
            except (TypeError, ValueError, RecursionError): summary = safe_browser_failure_summary(None)
            browser.append(summary)
    if reason == "output_limit_exceeded":
        record = {"schema": FAILURE_RECORD_SCHEMA, "stage": "diagnostics", "reason": "output_limit_exceeded"}
    elif record is None or malformed or primary_count != 1 or cleanup_count > 1:
        record = {"schema": FAILURE_RECORD_SCHEMA, "stage": "diagnostics",
                  "reason": "failure_record_malformed" if malformed or primary_count > 1 or cleanup_count > 1 else "failure_record_missing"}
    result.update(failure_record=record, cleanup_record=cleanup, browser_diagnostics=browser)
elif sys.argv[2] == "package_identity":
    try:
        value = json.loads(stdout.decode("utf-8", "strict"), object_pairs_hook=unique_object)
        selected = {key: value[key] for key in ("version", "archive_sha256", "tree_sha256")}
        if (type(selected["version"]) is str and len(selected["version"]) <= 64 and
                re.fullmatch(r"[0-9]+\.[0-9]+\.[0-9]+(?:[-+][0-9A-Za-z.-]+)?", selected["version"]) and
                all(re.fullmatch(r"[0-9a-f]{64}", selected[key]) for key in ("archive_sha256", "tree_sha256"))):
            result["identity"] = selected
    except (KeyError, TypeError, ValueError, RecursionError): pass
elif sys.argv[2] == "runtime_observation":
    try: text = stdout.decode("utf-8", "strict")
    except UnicodeError: text = ""
    rows = re.findall(r"(?m)^PAIR_RUNTIME\|([0-9]+\.[0-9]+(?:\.[0-9]+)?)\|([0-9]+\.[0-9]+(?:\.[0-9]+)?)\|([0-9]+\.[0-9]+(?:\.[0-9]+)?)\|([0-9]+)$", text)
    if rows and all(len(value) <= 32 for value in rows[-1]):
        result["runtime"] = dict(zip(("phoenix", "live_view", "elixir", "otp"), rows[-1]))
elif sys.argv[2] == "lifecycle":
    try: text = stdout.decode("utf-8", "strict")
    except UnicodeError: text = ""
    rows = re.findall(r"(?m)^\s*(\d+) tests?,\s*(\d+) failures?", text)
    rows += [(count, "0") for count in re.findall(r"(?m)^Result:\s*(\d+) passed\s*$", text)]
    if rows and all(len(value) <= 6 for value in rows[-1]):
        result["counts"] = {"tests": int(rows[-1][0]), "failures": int(rows[-1][1])}
# Only freshly constructed typed metadata reaches this exclusive0600 channel.
# All unknown child streams and exception values remain in this process's RAM.
print(json.dumps(result, sort_keys=True))
PY
  bounded_pid=$!
  wait "$bounded_pid" || bounded_launcher_status=$?
  bounded_pid=""
  read_bounded_result
  return "$bounded_status"
}
read_bounded_result() {
  bounded_result=$(<"$bounded_file")
  rm -f -- "$bounded_file"
  bounded_status=$(python3 -c 'import json,sys; print(json.load(sys.stdin)["status"])' 2>/dev/null <<<"$bounded_result") || bounded_status=125
  bounded_stopped=$(python3 -c 'import json,sys; print("true" if json.load(sys.stdin).get("stopped") is True else "false")' 2>/dev/null <<<"$bounded_result") || bounded_stopped=false
  bounded_reason=$(python3 -c 'import json,sys; print(json.load(sys.stdin).get("reason","runner_failure"))' 2>/dev/null <<<"$bounded_result") || bounded_reason=runner_failure
  if [[ "$bounded_stopped" != true || "$bounded_launcher_status" != 0 ]]; then
    bounded_status=125
  fi
  if ((bounded_status != 0)); then
    python3 -c 'import json,sys
stages={"package_build":"candidate","package_identity":"candidate","runtime_observation":"runtime_observation","database_migrate":"database_migrate","lifecycle":"lifecycle","browser":"browser","receipt":"receipt","cleanup":"cleanup"}
try: row=json.load(sys.stdin)
except (ValueError,TypeError): row={}
native=row.get("native_exit"); status=row.get("status"); reason=row.get("reason")
value={"schema":"lockspire-admin-command-status-v1","stage":stages.get(sys.argv[1],"diagnostics"),"native_exit":native if type(native) is int and -255 <= native <= 255 else None,"status":status if type(status) is int and 0 <= status <= 255 else 125,"reason":reason if type(reason) is str and reason in {"native_exit","timeout","interrupted","output_limit_exceeded","runner_failure"} else "runner_failure","cleanup":"stopped" if row.get("stopped") is True and sys.argv[2] == "0" else "unconfirmed"}
print("host integration command status: "+json.dumps(value,sort_keys=True),file=sys.stderr)
' "$stage" "$bounded_launcher_status" <<<"$bounded_result"
  fi
}
run_in_test() { local command_cwd=$test_cwd; run_bounded "$@"; }
emit_lifecycle_diagnostic() {
  python3 -c 'import json,sys
from pathlib import Path
sys.path.insert(0,str(Path.cwd()/"scripts"/"acceptance"/"clean_room"))
from redaction import safe_failure_summary
try: count=json.load(sys.stdin).get("counts",{}).get("failures",0)
except (TypeError,ValueError): count=0
if type(count) is not int or not 0 <= count <= 999999: count=0
summary=safe_failure_summary(stage="lifecycle",scenario="all",event="assertion_failure" if count else "runner_failure",field="count",count=count)
print("host integration lifecycle diagnostic: "+json.dumps(summary,sort_keys=True),file=sys.stderr)
' <<<"$bounded_result"
}
emit_failure_record() {
  local stage=$1 reason=$2
  case "$stage:$reason" in
    candidate:candidate_unavailable|provider_preparation:provider_preparation_failed|database_create:database_creation_failed|database_migrate:database_migration_failed|runtime_observation:runtime_observation_failed|host_startup:host_startup_failed|lifecycle:lifecycle_failed|browser:browser_proof_failed|receipt:receipt_invalid|receipt:receipt_write_failed|cleanup:cleanup_failed|diagnostics:failure_record_missing|diagnostics:failure_record_malformed|diagnostics:output_limit_exceeded) ;;
    *) stage=diagnostics; reason=failure_record_malformed ;;
  esac
  if [[ "$stage" == cleanup ]]; then
    [[ "$cleanup_record_emitted" == false ]] || return 0
    cleanup_record_emitted=true
  fi
  local prefix='host integration failure record'
  if [[ "$stage" == cleanup ]]; then prefix='host integration cleanup record'; fi
  printf '%s: {"schema":"lockspire-admin-proof-failure-v1","stage":"%s","reason":"%s"}\n' "$prefix" "$stage" "$reason" >&2
}
emit_browser_diagnostic() {
  local diagnostics
  diagnostics=$(python3 -c 'import json,sys
from pathlib import Path
sys.path.insert(0,str(Path.cwd()/"scripts"/"acceptance"))
from clean_room_admin_journey import FAILURE_RECORD_SCHEMA,safe_browser_failure_summary,validate_failure_record
try: payload=json.load(sys.stdin)
except (TypeError,ValueError): payload={}
record=validate_failure_record(payload.get("failure_record"))
cleanup=validate_failure_record(payload.get("cleanup_record"))
if record is None: record={"schema":FAILURE_RECORD_SCHEMA,"stage":"diagnostics","reason":"failure_record_malformed"}
print("host integration failure record: "+json.dumps(record,sort_keys=True))
if cleanup is not None and cleanup["stage"] == "cleanup": print("host integration cleanup record: "+json.dumps(cleanup,sort_keys=True))
for summary in payload.get("browser_diagnostics",[])[:8]: print("host integration browser diagnostic: "+json.dumps(safe_browser_failure_summary(summary),sort_keys=True))
' <<<"$bounded_result")
  if [[ "$diagnostics" == *"host integration cleanup record: "* ]]; then
    cleanup_record_emitted=true
  fi
  [[ -z "$diagnostics" ]] || printf '%s\n' "$diagnostics" >&2
}
extract_stdout() {
  python3 -c 'import json,sys
value=json.load(sys.stdin)
if "runtime" in value: print("PAIR_RUNTIME|"+"|".join(value["runtime"][key] for key in ("phoenix","live_view","elixir","otp")))
elif "counts" in value: print(str(value["counts"]["tests"])+" tests, "+str(value["counts"]["failures"])+" failures")
' <<<"$bounded_result"
}
cleanup_owned() {
  original_status=$?
  trap '' TERM INT
  if [[ -n "${bounded_pid:-}" ]]; then
    kill -TERM "$bounded_pid" 2>/dev/null || true
    bounded_launcher_status=0
    wait "$bounded_pid" 2>/dev/null || bounded_launcher_status=$?
    bounded_pid=""
    read_bounded_result
    if [[ "$stage" == browser ]]; then emit_browser_diagnostic; fi
    if [[ "$bounded_stopped" != true || "$bounded_launcher_status" != 0 ]]; then
      emit_failure_record cleanup cleanup_failed
      original_status=125
    fi
  fi
  # Only the generated lifecycle database belongs to this wrapper.
  cleanup_status=0
  deadline=$((SECONDS + 10))
  if [[ "${database_created:-false}" == true ]]; then
    run_in_test 6 cleanup env MIX_ENV=test LOCKSPIRE_TEST_DB_NAME="$db_name" "$mix_bin" ecto.drop --repo Lockspire.TestRepo --force || cleanup_status=$?
  fi
  if ((cleanup_status != 0)); then emit_failure_record cleanup cleanup_failed; fi
  if ((cleanup_status == 125)); then original_status=125; fi
  rm -rf -- "$raw_root" || { emit_failure_record cleanup cleanup_failed; cleanup_status=1; }
  if ((original_status != 0)); then exit "$original_status"; fi
  if ((cleanup_status != 0)); then echo "host integration proof cleanup failed" >&2; exit 1; fi
}
trap cleanup_owned EXIT
trap 'exit 143' TERM
trap 'exit 130' INT
fail_stage() {
  local failed_stage=$1 failure_status=$2
  if [[ "${bounded_reason:-}" == output_limit_exceeded ]]; then
    emit_failure_record diagnostics output_limit_exceeded
  else case "$failed_stage" in
    package_build|package_identity) emit_failure_record candidate candidate_unavailable ;;
    lifecycle_runtime) emit_failure_record runtime_observation runtime_observation_failed ;;
    lifecycle_setup) emit_failure_record database_migrate database_migration_failed ;;
    lifecycle_tests) emit_lifecycle_diagnostic; emit_failure_record lifecycle lifecycle_failed ;;
    browser_*) emit_browser_diagnostic ;;
    receipt_validation_*) emit_failure_record receipt receipt_invalid ;;
    *) emit_failure_record diagnostics failure_record_malformed ;;
  esac; fi
  if [[ "${bounded_stopped:-true}" != true || "${bounded_launcher_status:-0}" != 0 ]]; then
    emit_failure_record cleanup cleanup_failed
  fi
  exit "$failure_status"
}
if [[ "${LOCKSPIRE_PROOF_TEST_TRANSPORT:-false}" == true ]]; then
  if [[ "${LOCKSPIRE_PROOF_TEST_MODE:-false}" != true || -z "$test_journey_bin" ]]; then
    emit_failure_record diagnostics failure_record_malformed
    exit 64
  fi
  status=0
  run_bounded "$pair_budget" browser "$test_journey_bin" || status=$?
  if ((status != 0)); then
    fail_stage browser_transport "$status"
  fi
  exit 0
fi
command -v node >/dev/null 2>&1 || { emit_failure_record browser browser_proof_failed; exit 1; }
node -e 'const [major,minor]=process.versions.node.split(".").map(Number); if (major < 22 || (major === 22 && minor < 15)) process.exit(1)' >/dev/null 2>&1 || { emit_failure_record browser browser_proof_failed; exit 1; }
chrome=""
if [[ -x "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" ]]; then
  chrome="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
else
  for candidate in google-chrome chromium chromium-browser; do
    candidate_path=$(command -v "$candidate" 2>/dev/null || true)
    if [[ -n "$candidate_path" ]] && "$candidate_path" --version >/dev/null 2>&1; then chrome=$candidate_path; break; fi
  done
fi
[[ -n "$chrome" && -x "$chrome" ]] || { emit_failure_record browser browser_proof_failed; exit 1; }
"$chrome" --version >/dev/null 2>&1 || { emit_failure_record browser browser_proof_failed; exit 1; }
status=0
package_dir=$raw_root/package
mkdir -m 700 "$package_dir"
candidate_version=$(sed -nE 's/^[[:space:]]*version: "([^"]+)".*/\1/p' mix.exs | head -n 1)
candidate_tar=$package_dir/lockspire-$candidate_version.tar
source_revision=${GITHUB_SHA:-$(git rev-parse HEAD)}
[[ "$source_revision" =~ ^[0-9a-f]{40,64}$ ]] || fail_stage package_identity 1
run_bounded 0 package_build "$mix_bin" hex.build --output "$candidate_tar" || status=$?
((status == 0)) || fail_stage package_build "$status"
[[ -s "$candidate_tar" ]] || fail_stage package_identity 1
export LOCKSPIRE_PACKAGE_ROOT=$package_dir
candidate_sha=$(python3 - "$candidate_tar" <<'PY'
import hashlib, sys
with open(sys.argv[1], "rb") as handle: print(hashlib.file_digest(handle, "sha256").hexdigest())
PY
)
status=0
run_bounded 0 package_identity python3 scripts/acceptance/clean_room/package_input.py --inspect --package-tar "$candidate_tar" --package-sha256 "$candidate_sha" --source-revision "$source_revision" || status=$?
((status == 0)) || fail_stage package_identity "$status"
identity=$(python3 -c 'import json,sys; value=json.load(sys.stdin)["identity"]; print(json.dumps(value,sort_keys=True))' <<<"$bounded_result") || fail_stage package_identity 1
candidate_version=$(python3 -c 'import json,sys; print(json.load(sys.stdin)["version"])' <<<"$identity")
candidate_sha=$(python3 -c 'import json,sys; print(json.load(sys.stdin)["archive_sha256"])' <<<"$identity")
candidate_tree=$(python3 -c 'import json,sys; print(json.load(sys.stdin)["tree_sha256"])' <<<"$identity")
[[ -n "$candidate_version" && "$candidate_sha" =~ ^[0-9a-f]{64}$ && "$candidate_tree" =~ ^[0-9a-f]{64}$ ]] || fail_stage package_identity 1
runtime_expression='Application.load(:phoenix); Application.load(:phoenix_live_view); IO.puts("PAIR_RUNTIME|" <> to_string(Application.spec(:phoenix, :vsn)) <> "|" <> to_string(Application.spec(:phoenix_live_view, :vsn)) <> "|" <> System.version() <> "|" <> to_string(:erlang.system_info(:otp_release)))'
status=0
run_in_test 0 runtime_observation env MIX_ENV=test LOCKSPIRE_TEST_DB_NAME="$db_name" "$mix_bin" run --no-start -e "$runtime_expression" || status=$?
((status == 0)) || fail_stage lifecycle_runtime "$status"
runtime_line=$(extract_stdout | python3 -c 'import re,sys; lines=[x for x in sys.stdin.read().splitlines() if x.startswith("PAIR_RUNTIME|")]; m=re.fullmatch(r"PAIR_RUNTIME\|([0-9]+\.[0-9]+(?:\.[0-9]+)?)\|([0-9]+\.[0-9]+(?:\.[0-9]+)?)\|([0-9]+\.[0-9]+(?:\.[0-9]+)?)\|([0-9]+)",lines[-1]) if lines else None; print("|".join(m.groups()) if m else "")')
[[ -n "$runtime_line" ]] || fail_stage lifecycle_runtime 1
IFS='|' read -r actual_phoenix actual_live_view actual_elixir actual_otp <<<"$runtime_line"
[[ "$actual_phoenix" == "$expected_phoenix" && "$actual_live_view" == "$expected_live_view" && -n "$actual_elixir" && -n "$actual_otp" ]] || fail_stage lifecycle_runtime 1
if [[ "$pair" == locked ]]; then setup_task=test.setup; else setup_task=lockspire.test.setup; fi
status=0
database_created=true
run_in_test 0 database_migrate env MIX_ENV=test LOCKSPIRE_TEST_DB_NAME="$db_name" "$mix_bin" "$setup_task" || status=$?
((status == 0)) || fail_stage lifecycle_setup "$status"
status=0
if [[ "$pair" == locked ]]; then
  run_in_test 0 lifecycle env MIX_ENV=test LOCKSPIRE_TEST_DB_NAME="$db_name" "$mix_bin" test test/lockspire/web/admin_routes_compile_test.exs test/lockspire/web/admin_route_inventory_test.exs test/lockspire/web/admin_route_separation_test.exs test/lockspire/web/live/admin/admin_route_integration_test.exs || status=$?
else
  run_in_test 0 lifecycle env MIX_ENV=test LOCKSPIRE_TEST_DB_NAME="$db_name" "$mix_bin" test test/admin_host_runtime_test.exs || status=$?
fi
((status == 0)) || fail_stage lifecycle_tests "$status"
test_counts=$(extract_stdout | python3 -c 'import re,sys; text=sys.stdin.read(); rows=re.findall(r"(?m)^\s*(\d+) tests?,\s*(\d+) failures?",text); rows += [(m,"0") for m in re.findall(r"(?m)^Result:\s*(\d+) passed\s*$",text)]; print("|".join(rows[-1]) if rows else "0|0")')
IFS='|' read -r test_count test_failures <<<"$test_counts"
[[ "$test_count" =~ ^[1-9][0-9]*$ ]] || fail_stage lifecycle_tests 1
[[ "$test_failures" == 0 ]] || fail_stage lifecycle_tests 1
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
  run_bounded 180 browser "${journey_command[@]}" --pair "$pair" --mount "$mount" --scenario full --receipt "$raw_receipt" --run-id "$run_id" --package-tar "$candidate_tar" --package-sha256 "$candidate_sha" --package-source-revision "$source_revision" || status=$?
  if ((status != 0)); then
    fail_stage "browser_$index" "$status"
  fi
  status=0
  run_bounded 15 receipt "${validator_command[@]}" --check "$raw_receipt" --expected-run-id "$run_id" --expected-source "$source_revision" --expected-pair "$pair" --expected-mount "$mount" --expected-archive "$candidate_sha" --expected-tree "$candidate_tree" --expected-version "$candidate_version" --expected-scenario-set full || status=$?
  ((status == 0)) || fail_stage "receipt_validation_$index" "$status"
  install -m 600 "$raw_receipt" "$stage_dir/$pair-$suffix.json"
done
elapsed=$((SECONDS - started))
printf 'Host integration proof passed: pair=%s tests=%s mounts=3 duration=%ss source=%s\n' "$pair" "$test_count" "$elapsed" "$source_revision"
