#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "usage: run_verifier_upgrade_proof.sh --pair locked|floor --receipt-dir .artifacts/phase178/ci-locked|ci-floor [--test-mode]" >&2
}

pair=''
receipt_dir=''
test_mode=false
while (($#)); do
  case "$1" in
    --pair) (($# >= 2)) || { usage; exit 2; }; pair=$2; shift 2 ;;
    --receipt-dir) (($# >= 2)) || { usage; exit 2; }; receipt_dir=$2; shift 2 ;;
    --test-mode) test_mode=true; shift ;;
    *) usage; exit 2 ;;
  esac
done

case "$pair" in locked|floor) ;; *) echo "invalid verifier dependency pair" >&2; exit 2 ;; esac
[[ -n "$receipt_dir" ]] || { usage; exit 2; }

repo_root=$(git rev-parse --show-toplevel 2>/dev/null) || { echo "verifier proof requires the repository root" >&2; exit 2; }
runner_revision=$(git rev-parse HEAD 2>/dev/null) || { echo "verifier proof requires a committed runner revision" >&2; exit 2; }
[[ "$runner_revision" =~ ^[0-9a-f]{40,64}$ ]] || { echo "verifier runner revision is invalid" >&2; exit 2; }
runner="$repo_root/scripts/acceptance/clean_room_verifier_upgrade.py"
frozen_inputs="$repo_root/.planning/phases/178-packaged-upgrade-proof-delivery-handoff/178-FROZEN-INPUTS.json"

if [[ "$test_mode" == true ]]; then
  [[ "${LOCKSPIRE_VERIFIER_TEST_MODE:-}" == "1" ]] || { echo "test mode is disabled" >&2; exit 2; }
  [[ "$receipt_dir" == /* && "$receipt_dir" != *".."* ]] || { echo "unsafe test receipt path" >&2; exit 2; }
  test_temp=$(cd "${TMPDIR:-/tmp}" 2>/dev/null && pwd -P) || { echo "temporary directory is unavailable" >&2; exit 2; }
  [[ "$receipt_dir" == "$test_temp"/* ]] || { echo "test receipts must stay under the temporary directory" >&2; exit 2; }
  fake_runner=${LOCKSPIRE_VERIFIER_TEST_RUNNER:-}
  [[ -n "$fake_runner" && -f "$fake_runner" && ! -L "$fake_runner" ]] || { echo "test runner is unavailable" >&2; exit 2; }
  [[ "$fake_runner" == "$test_temp"/* ]] || { echo "test runner must stay under the temporary directory" >&2; exit 2; }
  fake_python=${LOCKSPIRE_VERIFIER_TEST_PYTHON:-python3}
  [[ "$fake_python" == /* && -x "$fake_python" ]] || { echo "test interpreter is unavailable" >&2; exit 2; }
  command=("$fake_python" "$fake_runner" --pair "$pair")
  timeout_seconds=${LOCKSPIRE_VERIFIER_TEST_TIMEOUT:-2}
  [[ "$timeout_seconds" =~ ^[1-9][0-9]?$ ]] || { echo "invalid test timeout" >&2; exit 2; }
  overall_timeout_seconds=${LOCKSPIRE_VERIFIER_TEST_OVERALL_TIMEOUT:-1500}
  [[ "$overall_timeout_seconds" =~ ^[1-9][0-9]?$ ]] || { echo "invalid test overall timeout" >&2; exit 2; }
else
  [[ "$receipt_dir" != *".."* && "$receipt_dir" != /* ]] || { echo "unsafe verifier receipt path" >&2; exit 2; }
  [[ "$receipt_dir" == ".artifacts/phase178/ci-$pair" ]] || { echo "verifier receipt path does not match its dependency pair" >&2; exit 2; }
  current="$repo_root"
  IFS='/' read -r -a path_parts <<< "$receipt_dir"
  for part in "${path_parts[@]}"; do
    current="$current/$part"
    [[ ! -L "$current" ]] || { echo "verifier receipt path contains a symlink" >&2; exit 2; }
  done
  [[ ! -e "$repo_root/$receipt_dir" ]] || { echo "verifier receipt path is stale or already owned" >&2; exit 2; }
  [[ ! -e "$repo_root/$receipt_dir/validated" ]] || { echo "validated output path is stale" >&2; exit 2; }
  command=(python3 "$runner")
  timeout_seconds=3600
  overall_timeout_seconds=1500
  [[ -f "$frozen_inputs" && ! -L "$frozen_inputs" ]] || { echo "authenticated frozen candidate inputs are unavailable" >&2; exit 2; }
  python3 "$repo_root/scripts/acceptance/clean_room/verifier_delivery.py" \
    --check frozen --phase-dir "$repo_root/.planning/phases/178-packaged-upgrade-proof-delivery-handoff" \
    >/dev/null || { echo "authenticated frozen candidate inputs failed validation" >&2; exit 2; }
  export LOCKSPIRE_FROZEN_INPUTS="$frozen_inputs"
  frozen_pins=$(python3 - "$frozen_inputs" <<'PY'
import json
import re
import sys
from pathlib import Path
try:
    manifest = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
    owner = manifest["candidate_owner"]
    runner = manifest["runner_revision"]
    revision = owner["source_revision"]
except (OSError, ValueError, KeyError, TypeError):
    raise SystemExit(2)
if (not isinstance(revision, str) or not re.fullmatch(r"[0-9a-f]{40,64}", revision)
        or not isinstance(runner, str) or not re.fullmatch(r"[0-9a-f]{40,64}", runner)):
    raise SystemExit(2)
print(runner + " " + revision)
PY
  ) || { echo "authenticated candidate source pin is unavailable" >&2; exit 2; }
  read -r frozen_runner_revision candidate_source_revision <<< "$frozen_pins"
  [[ "$frozen_runner_revision" == "$runner_revision" ]] || { echo "frozen verifier runner differs from current HEAD" >&2; exit 2; }
fi

# Validate every path and freshness condition above before the first mutation.
deadline=$((SECONDS + overall_timeout_seconds))
if [[ "$test_mode" != true ]]; then
  mkdir -p "$repo_root/.artifacts/phase178"
  mkdir -m 700 "$repo_root/$receipt_dir"
fi

run_owned() {
  local label=$1
  shift
  local status=0
  local helper_pid=''
  local remaining=$((deadline - SECONDS))
  local selected_timeout=$timeout_seconds
  local selected_label=$label
  if ((remaining <= 0)); then
    echo "verifier overall timeout before $label; no child started; diagnostics withheld" >&2
    return 124
  fi
  if ((remaining < selected_timeout)); then
    selected_timeout=$remaining
    selected_label="overall/$label"
  fi
  handle_signal() {
    local signal_name=$1 signal_status=$2 child_status=0
    if [[ -n "$helper_pid" ]]; then
      kill -"$signal_name" "$helper_pid" 2>/dev/null || true
      if wait "$helper_pid" 2>/dev/null; then child_status=0; else child_status=$?; fi
      helper_pid=''
      if ((child_status == 125)); then exit 125; fi
    fi
    exit "$signal_status"
  }
  trap 'handle_signal TERM 143' TERM
  trap 'handle_signal INT 130' INT
  python3 - "$selected_timeout" "$selected_label" "$test_mode" "$@" <<'PY' &
import os
import errno
import signal
import subprocess
import sys
import time

timeout = int(sys.argv[1])
label = sys.argv[2]
test_mode = sys.argv[3] == "true"
command = sys.argv[4:]
child = None
force_group_denial = test_mode and os.environ.get("LOCKSPIRE_VERIFIER_TEST_FORCE_GROUP_DENIAL") == "1"
cleanup_failure = "unconfirmed"

def stop_group(process):
    global cleanup_failure
    if force_group_denial:
        cleanup_failure = "test-group-denial"
        try:
            process.terminate()
            process.wait(timeout=2)
        except (ProcessLookupError, subprocess.TimeoutExpired):
            pass
        return False
    try:
        os.killpg(process.pid, signal.SIGTERM)
    except ProcessLookupError:
        pass
    except PermissionError:
        cleanup_failure = "group-signal-permission-denied"
        try:
            process.terminate()
        except ProcessLookupError:
            pass
        try:
            process.wait(timeout=2)
            return False
        except subprocess.TimeoutExpired:
            try:
                process.kill()
                process.wait(timeout=2)
                return False
            except (ProcessLookupError, subprocess.TimeoutExpired):
                return False
    deadline = time.monotonic() + 2
    while time.monotonic() < deadline:
        try:
            os.killpg(process.pid, 0)
        except ProcessLookupError:
            return True
        except PermissionError:
            cleanup_failure = "group-probe-permission-denied"
            try:
                process.terminate()
                process.wait(timeout=2)
                return False
            except (ProcessLookupError, subprocess.TimeoutExpired):
                return False
        time.sleep(0.05)
    try:
        os.killpg(process.pid, signal.SIGKILL)
    except ProcessLookupError:
        pass
    except PermissionError:
        cleanup_failure = "group-kill-permission-denied"
        return False
    try:
        os.killpg(process.pid, 0)
        return False
    except ProcessLookupError:
        return True

def interrupted(signum, _frame):
    if child is not None and not stop_group(child):
        print(f"verifier child cleanup unconfirmed at {label} ({cleanup_failure}); diagnostics withheld", file=sys.stderr)
        sys.exit(125)
    sys.exit(128 + signum)

signal.signal(signal.SIGTERM, interrupted)
signal.signal(signal.SIGINT, interrupted)
try:
    stage = "child-start"
    child = subprocess.Popen(command, stdin=subprocess.DEVNULL, stdout=subprocess.PIPE,
                              stderr=subprocess.PIPE, start_new_session=True)
    stage = "child-capture"
    test_mode and os.environ.get("LOCKSPIRE_VERIFIER_TEST_PID_FILE") and open(
        os.environ["LOCKSPIRE_VERIFIER_TEST_PID_FILE"], "w", encoding="ascii").write(str(child.pid))
    try:
        child.communicate(timeout=timeout)
    except subprocess.TimeoutExpired:
        stopped = stop_group(child)
        child.wait()
        if not stopped:
            print(f"verifier child cleanup unconfirmed at {label} ({cleanup_failure}); diagnostics withheld", file=sys.stderr)
            sys.exit(125)
        print(f"verifier child timeout at {label}; diagnostics withheld", file=sys.stderr)
        sys.exit(124)
    stopped = stop_group(child)
    if not stopped:
        print(f"verifier child cleanup unconfirmed at {label} ({cleanup_failure}); diagnostics withheld", file=sys.stderr)
        sys.exit(125)
    if child.returncode:
        print(f"verifier child failed at {label}; diagnostics withheld", file=sys.stderr)
        sys.exit(1)
except OSError as error:
    reason = {errno.ENOENT: "not_found", errno.EACCES: "permission_denied", errno.E2BIG: "argument_limit",
              errno.ENOEXEC: "not_executable", errno.EINVAL: "invalid_argument", errno.EAGAIN: "resource_limit",
              errno.EPERM: "permission_denied", errno.ENOMEM: "resource_limit"}.get(error.errno, "other")
    print(f"verifier child failed at {label}/{stage} ({reason}); diagnostics withheld", file=sys.stderr)
    sys.exit(127)
PY
  helper_pid=$!
  if wait "$helper_pid"; then status=0; else status=$?; fi
  helper_pid=''
  trap - TERM INT
  if ((status != 0)); then return "$status"; fi
}

if [[ "$test_mode" == true ]]; then
  if run_owned fake-child "${command[@]}"; then
    echo "test-only child output cannot create or validate a package receipt" >&2
    exit 78
  else
    exit $?
  fi
fi

run_group() {
  local scope=$1 store=$2
  local status=0
  run_owned "$scope/$pair/$store" "${command[@]}" --pair "$pair" --store "$store" \
    --group "$scope" --receipt-dir "$repo_root/$receipt_dir/$scope" || status=$?
  ((status == 0)) || exit "$status"
}

run_group core all
run_group rollout all
run_group recovery all
run_group endpoints builtin
run_group contention delegated
run_group atomicity delegated
run_group issuance delegated
run_group disclosure delegated
if [[ "$pair" == locked ]]; then
  run_group legacy-control builtin
  run_group release-rpc builtin
fi

validation_status=0
run_owned "validate/$pair" "${command[@]}" --pair "$pair" --store all \
  --validate-receipts "$repo_root/$receipt_dir" \
  --expected-runner-revision "$runner_revision" \
  --expected-candidate-source-revision "${candidate_source_revision:-$runner_revision}" || validation_status=$?
((validation_status == 0)) || exit "$validation_status"

python3 - "$repo_root/$receipt_dir/validated/index.json" <<'PY'
import json
import sys
from pathlib import Path
payload = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
if payload.get("failed_cases") != 0 or payload.get("passed_cases", 0) <= 0:
    raise SystemExit(1)
print(json.dumps({"pair": payload["pair"], "validated_receipts": payload["executed_receipts"],
                  "passed_cases": payload["passed_cases"], "failed_cases": payload["failed_cases"],
                  "runner_revision": payload["runner_revision"]}, sort_keys=True))
PY
