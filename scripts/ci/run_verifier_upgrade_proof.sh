#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "usage: run_verifier_upgrade_proof.sh --pair locked|floor --receipt-dir .artifacts/phase178/{ci,final}-PAIR [--frozen-manifest .artifacts/phase178/ci-candidate/178-FROZEN-INPUTS.json] [--expected-runner REV --expected-candidate-source REV --expected-archive-sha256 SHA --expected-tree-sha256 SHA --expected-manifest-sha256 SHA] [--test-mode]" >&2
}

pair=''
receipt_dir=''
test_mode=false
expected_runner=''
expected_candidate_source=''
expected_archive_sha256=''
expected_tree_sha256=''
expected_manifest_sha256=''
selected_manifest=''
while (($#)); do
  case "$1" in
    --pair) (($# >= 2)) || { usage; exit 2; }; pair=$2; shift 2 ;;
    --receipt-dir) (($# >= 2)) || { usage; exit 2; }; receipt_dir=$2; shift 2 ;;
    --expected-runner) (($# >= 2)) || { usage; exit 2; }; expected_runner=$2; shift 2 ;;
    --expected-candidate-source) (($# >= 2)) || { usage; exit 2; }; expected_candidate_source=$2; shift 2 ;;
    --expected-archive-sha256) (($# >= 2)) || { usage; exit 2; }; expected_archive_sha256=$2; shift 2 ;;
    --expected-tree-sha256) (($# >= 2)) || { usage; exit 2; }; expected_tree_sha256=$2; shift 2 ;;
    --expected-manifest-sha256) (($# >= 2)) || { usage; exit 2; }; expected_manifest_sha256=$2; shift 2 ;;
    --frozen-manifest) (($# >= 2)) || { usage; exit 2; }; selected_manifest=$2; shift 2 ;;
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
  [[ "$receipt_dir" == ".artifacts/phase178/ci-$pair" || "$receipt_dir" == ".artifacts/phase178/final-$pair" ]] || { echo "verifier receipt path does not match its dependency pair" >&2; exit 2; }
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
  if [[ -n "$selected_manifest" ]]; then
    [[ "$selected_manifest" == ".artifacts/phase178/ci-candidate/178-FROZEN-INPUTS.json" ]] || { echo "unsafe frozen manifest selection" >&2; exit 2; }
    frozen_inputs="$repo_root/$selected_manifest"
  fi
  current="$repo_root"
  IFS='/' read -r -a manifest_parts <<< "${frozen_inputs#"$repo_root/"}"
  for part in "${manifest_parts[@]}"; do
    current="$current/$part"
    [[ ! -L "$current" ]] || { echo "frozen manifest path contains a symlink" >&2; exit 2; }
  done
  [[ -f "$frozen_inputs" && ! -L "$frozen_inputs" ]] || { echo "authenticated frozen candidate inputs are unavailable" >&2; exit 2; }
  [[ "$expected_runner" =~ ^[0-9a-f]{40,64}$ && "$expected_candidate_source" =~ ^[0-9a-f]{40,64}$ \
     && "$expected_archive_sha256" =~ ^[0-9a-f]{64}$ && "$expected_tree_sha256" =~ ^[0-9a-f]{64}$ \
     && "$expected_manifest_sha256" =~ ^[0-9a-f]{64}$ ]] || { echo "independent frozen owner pins are unavailable" >&2; exit 2; }
  export LOCKSPIRE_EXPECTED_FROZEN_RUNNER_REVISION="$expected_runner"
  export LOCKSPIRE_EXPECTED_CANDIDATE_SOURCE_REVISION="$expected_candidate_source"
  export LOCKSPIRE_EXPECTED_CANDIDATE_ARCHIVE_SHA256="$expected_archive_sha256"
  export LOCKSPIRE_EXPECTED_CANDIDATE_TREE_SHA256="$expected_tree_sha256"
  export LOCKSPIRE_EXPECTED_FROZEN_MANIFEST_SHA256="$expected_manifest_sha256"
  export LOCKSPIRE_FROZEN_INPUTS="$frozen_inputs"
  # The pinned consumer checks actual checkout source/covered bytes against the
  # preserved runner. Later metadata commits need not restamp that runner.
  python3 "$repo_root/scripts/acceptance/clean_room/verifier_delivery.py" \
    --check frozen --phase-dir "$repo_root/.planning/phases/178-packaged-upgrade-proof-delivery-handoff" \
    --expected-runner "$expected_runner" --expected-candidate-source "$expected_candidate_source" \
    --expected-archive-sha256 "$expected_archive_sha256" --expected-tree-sha256 "$expected_tree_sha256" \
    --expected-manifest-sha256 "$expected_manifest_sha256" \
    >/dev/null || { echo "authenticated frozen candidate inputs failed validation" >&2; exit 2; }
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
  [[ "$frozen_runner_revision" == "$expected_runner" && "$candidate_source_revision" == "$expected_candidate_source" ]] || { echo "frozen owner differs from independent caller pins" >&2; exit 2; }
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
  python3 - "$selected_timeout" "$selected_label" "$test_mode" "$repo_root/scripts/acceptance/clean_room" "$@" <<'PY' &
import os
import errno
import json
from pathlib import Path
import shutil
import signal
import subprocess
import sys
import tempfile
import time

sys.path.insert(0, sys.argv[4])
from package_input import OwnedSessionSupervisor, PackageInputError, owned_session_state, signal_owned_session

timeout = int(sys.argv[1])
label = sys.argv[2]
test_mode = sys.argv[3] == "true"
command = sys.argv[5:]
child = None
force_group_denial = test_mode and os.environ.get("LOCKSPIRE_VERIFIER_TEST_FORCE_GROUP_DENIAL") == "1"
cleanup_failure = "unconfirmed"
registry = Path(tempfile.mkdtemp(prefix="lockspire-verifier-owned-"))
supervisor = OwnedSessionSupervisor(registry)
starting = False
pending_signal = None
stopping = False

def registered_groups():
    # Only the helper's OS-authenticated cache grants authority. Never parse
    # diagnostic files, even if a same-user child discovers or changes them.
    return set(supervisor.sessions)

def group_absent(pgid):
    global cleanup_failure
    identity = supervisor.sessions.get(pgid)
    if identity is None:
        cleanup_failure = "ownership-unconfirmed"
        return False
    state = owned_session_state(identity)
    if state == "unconfirmed":
        cleanup_failure = "ownership-unconfirmed"
    return state == "absent"

def signal_group(pgid, signum):
    global cleanup_failure
    identity = supervisor.sessions.get(pgid)
    if identity is None or not signal_owned_session(identity, signum):
        cleanup_failure = "ownership-unconfirmed"
        return False
    return True

def all_absent(process):
    global cleanup_failure
    process.poll()  # Reap the root before probing its process group.
    if supervisor.pending:
        cleanup_failure = "pending-owned-launch"
        return False
    groups = registered_groups()
    if groups is None:
        cleanup_failure = "invalid-owned-custody"
        return False
    return all(group_absent(pgid) for pgid in groups | {process.pid})

def stop_group(process):
    global cleanup_failure
    if force_group_denial:
        cleanup_failure = "test-group-denial"
        return False
    if not signal_group(process.pid, signal.SIGTERM):
        return False
    # Runtime deadline excludes bounded cleanup. Existing rollout cleanup gets
    # ten seconds plus reap/probe time; shared registered-session cleanup gets
    # five seconds independent of the number of children. Do not KILL its owner
    # after the old two seconds while it is still draining isolated sessions.
    deadline = time.monotonic() + 15
    while time.monotonic() < deadline:
        supervisor.service()  # Accept release/late registration during drain.
        if all_absent(process):
            return True
        if process.poll() is not None:
            # An exited supervisor no longer owns cleanup. Retained session
            # records, rather than its vanished root group, identify custody.
            groups = registered_groups()
            if groups is None:
                return False
            for pgid in groups:
                if not signal_group(pgid, signal.SIGTERM):
                    return False
            break
        time.sleep(0.05)
    groups = registered_groups()
    if groups is None:
        cleanup_failure = "invalid-owned-custody"
        return False
    for pgid in groups - {process.pid}:
        if not signal_group(pgid, signal.SIGKILL):
            return False
    if not signal_group(process.pid, signal.SIGKILL):
        return False
    try:
        process.wait(timeout=2)
    except subprocess.TimeoutExpired:
        return False
    deadline = time.monotonic() + 2
    while time.monotonic() < deadline:
        if all_absent(process):
            return True
        time.sleep(0.05)
    return False

def cleanup_unconfirmed():
    supervisor.close()
    print(f"verifier child cleanup unconfirmed at {label} ({cleanup_failure}); diagnostics withheld", file=sys.stderr)
    # Generated private path + numeric identities only; never command/output.
    print(f"verifier owned session custody retained: {registry}", file=sys.stderr)

def interrupted(signum, _frame):
    global pending_signal, stopping
    if starting:
        pending_signal = signum
        return
    if stopping:
        return
    stopping = True
    if child is not None and (not stop_group(child) or supervisor.refused):
        cleanup_unconfirmed()
        sys.exit(125)
    supervisor.close()
    shutil.rmtree(registry)
    sys.exit(128 + signum)

signal.signal(signal.SIGTERM, interrupted)
signal.signal(signal.SIGINT, interrupted)
try:
    stage = "child-start"
    starting = True
    environment = dict(os.environ, LOCKSPIRE_OWNED_SESSION_SOCKET=str(supervisor.endpoint))
    environment.pop("LOCKSPIRE_OWNED_SESSION_REGISTRY", None)
    child = subprocess.Popen(command, stdin=subprocess.DEVNULL, stdout=subprocess.PIPE,
                              stderr=subprocess.PIPE, start_new_session=True, env=environment)
    supervisor.admit_root(child)
    starting = False
    if pending_signal is not None:
        interrupted(pending_signal, None)
    stage = "child-capture"
    test_mode and os.environ.get("LOCKSPIRE_VERIFIER_TEST_PID_FILE") and open(
        os.environ["LOCKSPIRE_VERIFIER_TEST_PID_FILE"], "w", encoding="ascii").write(str(child.pid))
    try:
        execution_deadline = time.monotonic() + timeout
        while True:
            supervisor.service()
            remaining = execution_deadline - time.monotonic()
            if remaining <= 0:
                raise subprocess.TimeoutExpired("owned verifier stage", timeout)
            try:
                child.communicate(timeout=min(0.05, remaining))
                break
            except subprocess.TimeoutExpired:
                pass
    except subprocess.TimeoutExpired:
        stopping = True
        stopped = stop_group(child)
        if not stopped or supervisor.refused:
            cleanup_unconfirmed()
            sys.exit(125)
        supervisor.close()
        shutil.rmtree(registry)
        print(f"verifier child timeout at {label}; diagnostics withheld", file=sys.stderr)
        sys.exit(124)
    stopping = True
    stopped = stop_group(child)
    if not stopped or supervisor.refused:
        cleanup_unconfirmed()
        sys.exit(125)
    supervisor.close()
    shutil.rmtree(registry)
    if child.returncode:
        print(f"verifier child failed at {label}; diagnostics withheld", file=sys.stderr)
        sys.exit(1)
except (OSError, PackageInputError) as error:
    reason = {errno.ENOENT: "not_found", errno.EACCES: "permission_denied", errno.E2BIG: "argument_limit",
              errno.ENOEXEC: "not_executable", errno.EINVAL: "invalid_argument", errno.EAGAIN: "resource_limit",
              errno.EPERM: "permission_denied", errno.ENOMEM: "resource_limit"}.get(getattr(error, "errno", None), "other")
    print(f"verifier child failed at {label}/{stage} ({reason}); diagnostics withheld", file=sys.stderr)
    if child is not None:
        if not stop_group(child):
            cleanup_unconfirmed()
            sys.exit(125)
    supervisor.close()
    shutil.rmtree(registry)
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
  --expected-candidate-source-revision "${expected_candidate_source:-$runner_revision}" || validation_status=$?
((validation_status == 0)) || exit "$validation_status"

python3 - "$repo_root/$receipt_dir" "$pair" <<'PY' || { echo "validated raw receipt copies are unavailable" >&2; exit 2; }
import hashlib
import json
from pathlib import Path
import re
import shutil
import sys

root = Path(sys.argv[1])
pair = sys.argv[2]
index_path = root / "validated" / "index.json"
try:
    index = json.loads(index_path.read_text(encoding="utf-8"))
    cells = index["cells"]
    if index.get("pair") != pair or not isinstance(cells, list):
        raise ValueError
    target = root / "validated" / "raw"
    target.mkdir(mode=0o700)
    copies = []
    for cell in cells:
        scope, selected_pair, store = cell["scope"], cell["pair"], cell["store"]
        relative = Path(cell["receipt_path"])
        if (selected_pair != pair or not re.fullmatch(r"[a-z][a-z-]*", scope)
                or not re.fullmatch(r"[a-z][a-z-]*", store)
                or relative.is_absolute() or ".." in relative.parts):
            raise ValueError
        source = root / relative
        current = root
        for part in relative.parts:
            current = current / part
            if current.is_symlink():
                raise ValueError
        if not source.is_file():
            raise ValueError
        digest = hashlib.sha256(source.read_bytes()).hexdigest()
        if digest != cell["receipt_sha256"]:
            raise ValueError
        name = f"{scope}-{pair}-{store}.json"
        destination = target / name
        if destination.exists() or destination.is_symlink():
            raise ValueError
        shutil.copyfile(source, destination)
        copies.append({"scope": scope, "pair": pair, "store": store,
                       "path": f"raw/{name}", "sha256": digest})
    if len(copies) != index.get("executed_receipts"):
        raise ValueError
    with (root / "validated" / "raw-copies.json").open("x", encoding="utf-8") as output:
        json.dump({"schema": "lockspire-validated-raw-copies-v1", "pair": pair,
                   "copies": copies}, output, sort_keys=True, separators=(",", ":"))
        output.write("\n")
except (OSError, ValueError, KeyError, TypeError, json.JSONDecodeError):
    raise SystemExit(1)
PY

python3 "$repo_root/scripts/acceptance/clean_room/verifier_delivery.py" \
  --copy-upload-owner --upload-root "$repo_root/$receipt_dir/validated" \
  --expected-runner "$expected_runner" --expected-candidate-source "$expected_candidate_source" \
  --expected-archive-sha256 "$expected_archive_sha256" --expected-tree-sha256 "$expected_tree_sha256" \
  --expected-manifest-sha256 "$expected_manifest_sha256" \
  >/dev/null || { echo "validated candidate owner copies are unavailable" >&2; exit 2; }

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
