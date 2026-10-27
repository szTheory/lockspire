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
runner="$repo_root/scripts/acceptance/clean_room_verifier_upgrade.py"

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
fi

# Validate every path and freshness condition above before the first mutation.
if [[ "$test_mode" != true ]]; then
  mkdir -p "$repo_root/.artifacts/phase178"
  mkdir -m 700 "$repo_root/$receipt_dir"
fi

run_owned() {
  local label=$1
  shift
  local status=0
  local helper_pid=''
  trap 'if [[ -n "$helper_pid" ]]; then kill -TERM "$helper_pid" 2>/dev/null || true; wait "$helper_pid" 2>/dev/null || true; fi; exit 143' TERM
  trap 'if [[ -n "$helper_pid" ]]; then kill -INT "$helper_pid" 2>/dev/null || true; wait "$helper_pid" 2>/dev/null || true; fi; exit 130' INT
  python3 - "$timeout_seconds" "$label" "$@" <<'PY' &
import os
import errno
import signal
import subprocess
import sys
import time

timeout = int(sys.argv[1])
label = sys.argv[2]
command = sys.argv[3:]
child = None

def stop_group(process):
    try:
        os.killpg(process.pid, signal.SIGTERM)
    except ProcessLookupError:
        pass
    except PermissionError:
        try:
            process.terminate()
        except ProcessLookupError:
            pass
        try:
            process.wait(timeout=2)
            return True
        except subprocess.TimeoutExpired:
            try:
                process.kill()
                process.wait(timeout=2)
                return True
            except (ProcessLookupError, subprocess.TimeoutExpired):
                return False
    deadline = time.monotonic() + 2
    while time.monotonic() < deadline:
        try:
            os.killpg(process.pid, 0)
        except ProcessLookupError:
            return True
        except PermissionError:
            if process.poll() is not None:
                return True
            try:
                process.terminate()
                process.wait(timeout=2)
                return True
            except (ProcessLookupError, subprocess.TimeoutExpired):
                return False
        time.sleep(0.05)
    try:
        os.killpg(process.pid, signal.SIGKILL)
    except ProcessLookupError:
        pass
    try:
        os.killpg(process.pid, 0)
        return False
    except ProcessLookupError:
        return True

def interrupted(signum, _frame):
    if child is not None:
        stop_group(child)
    sys.exit(128 + signum)

signal.signal(signal.SIGTERM, interrupted)
signal.signal(signal.SIGINT, interrupted)
try:
    stage = "child-start"
    child = subprocess.Popen(command, stdin=subprocess.DEVNULL, stdout=subprocess.PIPE,
                              stderr=subprocess.PIPE, start_new_session=True)
    stage = "child-capture"
    os.environ.get("LOCKSPIRE_VERIFIER_TEST_PID_FILE") and open(
        os.environ["LOCKSPIRE_VERIFIER_TEST_PID_FILE"], "w", encoding="ascii").write(str(child.pid))
    try:
        child.communicate(timeout=timeout)
    except subprocess.TimeoutExpired:
        stopped = stop_group(child)
        child.wait()
        print(f"verifier child timeout at {label}; diagnostics withheld", file=sys.stderr)
        sys.exit(124 if stopped else 125)
    stopped = stop_group(child)
    if not stopped:
        print(f"verifier child cleanup unconfirmed at {label}; diagnostics withheld", file=sys.stderr)
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
  --validate-receipts "$repo_root/$receipt_dir" || validation_status=$?
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
