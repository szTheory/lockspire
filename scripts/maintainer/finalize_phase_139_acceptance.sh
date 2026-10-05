#!/usr/bin/env bash
set -euo pipefail

usage() {
  printf '%s\n' \
    'Usage: finalize_phase_139_acceptance.sh post-transition --phase 139 [--publish <exact-sha>]' >&2
  exit 64
}

[[ "$#" -eq 3 || "$#" -eq 5 ]] || usage
[[ "$1" == "post-transition" && "$2" == "--phase" && "$3" == "139" ]] || usage
if [[ "$#" -eq 5 ]]; then
  [[ "$4" == "--publish" && "$5" =~ ^[0-9a-f]{40}$ ]] || usage
  PUBLISH_SHA="$5"
else
  PUBLISH_SHA=""
fi

fail() {
  printf 'phase 139 acceptance: %s\n' "$1" >&2
  exit 1
}

if [[ -n "${LOCKSPIRE_ACCEPTANCE_TEST_MODE+x}" ||
      -n "${LOCKSPIRE_ACCEPTANCE_TEST_STOP_AFTER_LANDING+x}" ||
      -n "${LOCKSPIRE_ACCEPTANCE_TEST_BARRIER+x}" ||
      -n "${LOCKSPIRE_ACCEPTANCE_HYGIENE_SCRIPT+x}" ]]; then
  fail "legacy test-only environment is not supported"
fi

require_oid() {
  [[ "$1" =~ ^[0-9a-f]{40}$ ]] || fail "$2 is not an exact lowercase object id"
}

ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || fail "not inside a Git repository"
[[ "$(pwd -P)" == "$(cd "$ROOT" && pwd -P)" ]] || fail "command must run from the repository root"
GIT_DIR="$(git -C "$ROOT" rev-parse --path-format=absolute --git-dir)"
COMMON_DIR="$(git -C "$ROOT" rev-parse --path-format=absolute --git-common-dir)"
[[ "$GIT_DIR" == "$COMMON_DIR" ]] || fail "linked worktrees cannot perform final acceptance"

LOCK="$COMMON_DIR/lockspire-phase-139-acceptance.lock"
if ! mkdir "$LOCK" 2>/dev/null; then
  fail "another final acceptance is active"
fi
EXACT_CHECKOUT_PARENT=""
EXACT_CHECKOUT=""

remove_exact_acceptance_checkout() {
  [[ -n "$EXACT_CHECKOUT" ]] || return 0
  if [[ -d "$EXACT_CHECKOUT" ]]; then
    git -C "$ROOT" worktree remove "$EXACT_CHECKOUT" >/dev/null 2>&1 || return 1
  fi
  EXACT_CHECKOUT=""
  if [[ -n "$EXACT_CHECKOUT_PARENT" ]]; then
    rmdir "$EXACT_CHECKOUT_PARENT" 2>/dev/null || return 1
    EXACT_CHECKOUT_PARENT=""
  fi
}

cleanup() {
  if ! remove_exact_acceptance_checkout; then
    printf 'phase 139 acceptance: temporary exact checkout could not be removed: %s\n' \
      "${EXACT_CHECKOUT:-$EXACT_CHECKOUT_PARENT}" >&2
  fi
  rmdir "$LOCK" 2>/dev/null || true
}
on_signal() {
  local status="$1"
  trap - EXIT HUP INT TERM
  cleanup
  exit "$status"
}
trap cleanup EXIT
trap 'on_signal 129' HUP
trap 'on_signal 130' INT
trap 'on_signal 143' TERM

HOST_RECEIPT="$COMMON_DIR/gsd-lifecycle/post-completion-finalizer.json"
LEDGER=".planning/phases/138-baseline-inventory-evidence-taxonomy/baseline-inventory-2026-08-28.md"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
STATE_HELPER="$ROOT/tools/gsd-capabilities/lockspire-phase-finalizer/post-completion-finalizer-state.cjs"

resolve_gsd_tools() {
  local candidate
  for candidate in \
    "${GSD_TOOLS:-}" \
    "$ROOT/gsd-core/bin/gsd-tools.cjs" \
    "$ROOT/.codex/gsd-core/bin/gsd-tools.cjs" \
    "$ROOT/.claude/gsd-core/bin/gsd-tools.cjs" \
    "$HOME/.codex/gsd-core/bin/gsd-tools.cjs" \
    "$HOME/.claude/gsd-core/bin/gsd-tools.cjs" \
    "$HOME/.hermes/gsd-core/bin/gsd-tools.cjs" \
    "$HOME/.cursor/gsd-core/bin/gsd-tools.cjs" \
    "$HOME/.gemini/gsd-core/bin/gsd-tools.cjs" \
    "$HOME/.copilot/gsd-core/bin/gsd-tools.cjs" \
    "$HOME/.agents/gsd-core/bin/gsd-tools.cjs"; do
    if [[ -n "$candidate" && -f "$candidate" && ! -L "$candidate" ]]; then
      printf '%s' "$candidate"
      return 0
    fi
  done
  return 1
}

prepare_host_receipt() {
  local gsd_tools hooks
  [[ ! -e "$HOST_RECEIPT" ]] || return 0
  [[ -f "$STATE_HELPER" && ! -L "$STATE_HELPER" ]] || fail "project finalizer state helper is unavailable"
  gsd_tools="$(resolve_gsd_tools)" || fail "GSD runtime tools are unavailable"
  hooks="$(node "$gsd_tools" loop render-hooks plan:pre --raw)" || fail "plan-pre lifecycle discovery failed"
  printf '%s' "$hooks" | node "$STATE_HELPER" prepare 139 >/dev/null ||
    fail "plan-pre receipt preparation failed"
}

resolve_sealed_candidate() {
  python3 - "$ROOT" "$HOST_RECEIPT" <<'PY'
import hashlib, json, os, re, stat, subprocess, sys
root, path = sys.argv[1:]
try:
    st = os.lstat(path)
    if not stat.S_ISREG(st.st_mode) or stat.S_IMODE(st.st_mode) != 0o600 or st.st_size > 1024 * 1024:
        raise ValueError("unsafe host receipt")
    with open(path, "r", encoding="utf-8") as stream:
        receipt = json.load(stream)
    if receipt.get("schemaVersion") != 1 or receipt.get("status") != "pending":
        raise ValueError("host receipt is not sealed and pending")
    if receipt.get("phase") != "139" or receipt.get("point") != "plan:pre":
        raise ValueError("host receipt has the wrong phase or lifecycle point")
    after = receipt.get("after")
    candidate = after.get("head") if isinstance(after, dict) else None
    if not isinstance(candidate, str) or len(candidate) != 40 or candidate.lower() != candidate:
        raise ValueError("host receipt candidate is malformed")
    if any(c not in "0123456789abcdef" for c in candidate):
        raise ValueError("host receipt candidate is malformed")
    head = subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=root, text=True).strip()
    porcelain = subprocess.check_output(
        ["git", "status", "--porcelain=v1", "-z", "--untracked-files=all"], cwd=root
    )
    if candidate != head or after.get("porcelainSha256") != hashlib.sha256(porcelain).hexdigest():
        raise ValueError("sealed repository state changed")
    changed = set()
    for record in porcelain.split(b"\0"):
        if record:
            changed.add(record[3:].decode("utf-8", "strict"))
    recovery = receipt.get("recovery")
    if recovery is None:
        if changed != {".planning/PROJECT.md", ".planning/STATE.md"}:
            raise ValueError("sealed transition contains unexpected paths")
    else:
        expected_paths = [
            ".planning/PROJECT.md",
            ".planning/STATE.md",
            ".planning/ROADMAP.md",
            ".planning/REQUIREMENTS.md",
        ]
        protocol = recovery.get("protocol")
        if (protocol not in {"phase-140-recovery-v1", "phase-140-recovery-v2"} or
                not re.fullmatch(r"[0-9a-f]{40}", recovery.get("baselineSha", ""))):
            raise ValueError("recovery receipt is malformed")
        if protocol == "phase-140-recovery-v1":
            if set(recovery) != {"protocol", "baselineSha", "preservedWorktree"}:
                raise ValueError("legacy recovery receipt is malformed")
        else:
            if (set(recovery) != {"protocol", "baselineSha", "supersedesSha256", "preservedWorktree"} or
                    not re.fullmatch(r"[0-9a-f]{64}", recovery.get("supersedesSha256", ""))):
                raise ValueError("supersession receipt is malformed")
            common = subprocess.check_output(
                ["git", "rev-parse", "--path-format=absolute", "--git-common-dir"], cwd=root, text=True
            ).strip()
            archive = os.path.join(common, "gsd-lifecycle", "receipt-archive",
                                   recovery["supersedesSha256"] + ".json")
            archive_stat = os.lstat(archive)
            if not stat.S_ISREG(archive_stat.st_mode) or stat.S_IMODE(archive_stat.st_mode) != 0o600:
                raise ValueError("superseded receipt archive is unsafe")
            with open(archive, "rb") as stream:
                archived_bytes = stream.read()
            if hashlib.sha256(archived_bytes).hexdigest() != recovery["supersedesSha256"]:
                raise ValueError("superseded receipt archive digest")
            prior = json.loads(archived_bytes)
            if prior.get("recovery", {}).get("protocol") == "phase-140-recovery-v2":
                raise ValueError("nested supersession lineage is unsupported")
            prior_head = prior.get("after", {}).get("head") if isinstance(prior.get("after"), dict) else None
            prior_transform = prior.get("transformation") if isinstance(prior, dict) else None
            prior_evidence = {
                "protocol": "gsd-transition-v1",
                "writer": prior.get("writer"),
                "before": prior.get("before"),
                "after": prior.get("after"),
            }
            if prior.get("recovery"):
                prior_evidence["recovery"] = prior["recovery"]
            if (prior.get("schemaVersion") != 1 or prior.get("status") != "pending" or
                    prior.get("phase") != "139" or prior.get("point") != "plan:pre" or
                    prior.get("hooks") != receipt.get("hooks") or
                    prior.get("hooksSha256") != receipt.get("hooksSha256") or
                    not isinstance(prior_head, str) or not re.fullmatch(r"[0-9a-f]{40}", prior_head) or
                    not isinstance(prior_transform, dict) or
                    prior_transform.get("protocol") != "gsd-transition-v1" or
                    prior_transform.get("allowedPaths") != expected_paths or
                    prior_transform.get("sha256") != hashlib.sha256(
                        json.dumps(prior_evidence, ensure_ascii=False, separators=(",", ":")).encode()
                    ).hexdigest()):
                raise ValueError("superseded receipt lineage")
            if subprocess.run(["git", "merge-base", "--is-ancestor", prior_head, candidate],
                              cwd=root, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL).returncode != 0:
                raise ValueError("superseded receipt candidate is not an ancestor")
        expected = recovery.get("preservedWorktree")
        if not isinstance(expected, list):
            raise ValueError("recovery worktree receipt is malformed")
        observed = []
        for record in porcelain.split(b"\0"):
            if not record:
                continue
            status = record[:2].decode("ascii")
            relative = record[3:].decode("utf-8", "strict")
            allowed = (re.fullmatch(r"\.planning/phases/[0-9]{3}-[^/]+/[A-Za-z0-9._-]+\.md", relative) or
                       re.fullmatch(r"docs/[A-Za-z0-9._-]+\.(?:md|txt)", relative))
            if protocol == "phase-140-recovery-v2" and re.fullmatch(
                    r"\.planning/debug/[a-z0-9][a-z0-9-]*\.md", relative):
                allowed = True
            if record[2:3] != b" " or not allowed or status not in {" M", "??"}:
                raise ValueError("recovery contains a non-planning worktree change")
            target = os.path.join(root, relative)
            info = os.lstat(target)
            if not stat.S_ISREG(info.st_mode):
                raise ValueError("recovery worktree entry is not a regular file")
            with open(target, "rb") as stream:
                data = stream.read()
            observed.append({"path": relative, "status": status, "mode": stat.S_IMODE(info.st_mode),
                             "size": len(data), "sha256": hashlib.sha256(data).hexdigest()})
        observed.sort(key=lambda entry: entry["path"])
        if observed != expected:
            raise ValueError("preserved planning worktree changed after sealing")
    print(candidate)
except Exception as error:
    print(f"phase 139 acceptance: {error}", file=sys.stderr)
    raise SystemExit(1)
PY
}

verify_sealed_state_unchanged() {
  local candidate="$1"
  [[ "$(git -C "$ROOT" rev-parse HEAD)" == "$candidate" ]] || fail "HEAD changed after sealing"
  [[ "$(resolve_sealed_candidate)" == "$candidate" ]] || fail "sealed transition changed"
}

fast_forward_main() {
  local candidate="$1" old_main remote_main observed
  git -C "$ROOT" fetch --no-tags origin refs/heads/main:refs/remotes/origin/main >/dev/null
  old_main="$(git -C "$ROOT" rev-parse refs/heads/main 2>/dev/null)" || fail "local main is missing"
  remote_main="$(git -C "$ROOT" rev-parse refs/remotes/origin/main 2>/dev/null)" || fail "origin/main is missing"
  require_oid "$old_main" "local main"
  require_oid "$remote_main" "origin/main"
  git -C "$ROOT" merge-base --is-ancestor "$old_main" "$candidate" || fail "local main is not an ancestor of the sealed candidate"
  git -C "$ROOT" merge-base --is-ancestor "$remote_main" "$candidate" || fail "origin/main is not an ancestor of the sealed candidate"
  if [[ "$old_main" != "$candidate" ]]; then
    git -C "$ROOT" update-ref refs/heads/main "$candidate" "$old_main"
  fi
  verify_sealed_state_unchanged "$candidate"
  git -C "$ROOT" push origin "$candidate:refs/heads/main" >/dev/null
  git -C "$ROOT" fetch --no-tags origin refs/heads/main:refs/remotes/origin/main >/dev/null
  observed="$(git -C "$ROOT" rev-parse refs/remotes/origin/main)"
  [[ "$(git -C "$ROOT" rev-parse HEAD)" == "$candidate" &&
     "$(git -C "$ROOT" rev-parse refs/heads/main)" == "$candidate" &&
     "$observed" == "$candidate" ]] || fail "HEAD, local main, and origin/main did not converge"
}

ACCEPTANCE_RECEIPT="$COMMON_DIR/lockspire-phase-139-acceptance-v1.json"
OLD_ACCEPTANCE_BASE=""
OLD_ACCEPTANCE_RECEIPT_SHA256=""
HISTORICAL_SOURCE="5d10ce2219c2e687cf9573c8b280abfb118a47d8"
HISTORICAL_CI_RUN="33141161205"
HISTORICAL_RELEASE_RUN="33141484467"
HISTORICAL_VERSION="1.5.0"
HISTORICAL_CHECKSUM="30c1f56f0f356be727269ba1a6c1b6be85a3c6c6bc224d781a7c136241ed90de"
HISTORICAL_TAG="lockspire-v1.5.0"

validate_acceptance_receipt() {
  python3 - "$@" <<'PY'
import datetime
import json
import os
import re
import stat
import sys

(kind, source, candidate, repository, historical_source, historical_ci,
 historical_release, historical_version, historical_checksum, historical_tag) = sys.argv[1:]

def fail(message):
    raise ValueError(message)

def exact_keys(value, keys, label):
    if not isinstance(value, dict) or set(value) != set(keys):
        fail(f"{label} keys")

def positive_integer(value, label):
    if isinstance(value, bool) or not isinstance(value, int) or value <= 0:
        fail(label)

def nonnegative_integer(value, label):
    if isinstance(value, bool) or not isinstance(value, int) or value < 0:
        fail(label)

if kind == "durable":
    st = os.lstat(source)
    if (not stat.S_ISREG(st.st_mode) or stat.S_IMODE(st.st_mode) != 0o600 or
            st.st_size <= 0 or st.st_size > 1024 * 1024):
        fail("receipt type, mode, or size")
    with open(source, "r", encoding="utf-8") as stream:
        receipt = json.load(stream)
else:
    receipt = json.loads(source)

common_keys = {
    "schema", "baseline_sha", "local_gate", "hygiene", "required_ci",
    "release_no_publish", "warn_dispositions", "supplemental_oidf"
}
durable_keys = common_keys | {
    "inventory_relation", "historical_release", "captured_at", "repository"
}
exact_keys(receipt, durable_keys if kind == "durable" else common_keys, "receipt")
if receipt["schema"] != "lockspire-phase-139-acceptance-v1" or receipt["baseline_sha"] != candidate:
    fail("receipt identity")

exact_keys(receipt["local_gate"], {"status", "exunit_tests"}, "local gate")
if receipt["local_gate"]["status"] != "pass":
    fail("local gate status")
positive_integer(receipt["local_gate"]["exunit_tests"], "local gate count")

exact_keys(receipt["hygiene"], {"status", "pass", "warn", "block"}, "hygiene")
if receipt["hygiene"]["status"] != "pass" or receipt["hygiene"]["block"] != 0:
    fail("hygiene status")
positive_integer(receipt["hygiene"]["pass"], "hygiene pass count")
nonnegative_integer(receipt["hygiene"]["warn"], "hygiene warn count")
nonnegative_integer(receipt["hygiene"]["block"], "hygiene block count")

ci_names = [
    "Dialyzer", "Release Hygiene Drift", "Fast Checks",
    "Minimum Supported Elixir/OTP", "Integration Checks",
    "Complete Coverage Evidence", "Adoption Demo Smoke"
]
release_graph = {
    "Maintain Release Please PR": "success",
    "Validate exact main head and CI evidence": "skipped",
    "Prove exact package before publication": "skipped",
    "Publish verified release to Hex": "skipped",
    "Verify public install truth": "skipped",
}

def validate_run(run, label, expected_jobs, outcome=None):
    keys = {"status", "run_id", "event", "conclusion", "url", "jobs"}
    if outcome is not None:
        keys.add("outcome")
    exact_keys(run, keys, label)
    if run["status"] != "pass" or run["event"] != "push" or run["conclusion"] != "success":
        fail(f"{label} status")
    if outcome is not None and run["outcome"] != outcome:
        fail(f"{label} outcome")
    positive_integer(run["run_id"], f"{label} run id")
    if not isinstance(run["url"], str) or not re.fullmatch(r"https://[^\s]+", run["url"]):
        fail(f"{label} url")
    if not isinstance(run["jobs"], list) or len(run["jobs"]) != len(expected_jobs):
        fail(f"{label} job count")
    observed = {}
    for job in run["jobs"]:
        exact_keys(job, {"name", "status", "conclusion"}, f"{label} job")
        name = job["name"]
        if name in observed or job["status"] != "completed":
            fail(f"{label} job shape")
        observed[name] = job["conclusion"]
    if observed != expected_jobs:
        fail(f"{label} job graph")

validate_run(receipt["required_ci"], "required CI", {name: "success" for name in ci_names})
validate_run(receipt["release_no_publish"], "release", release_graph, "no_publish")

dispositions = receipt["warn_dispositions"]
if not isinstance(dispositions, list) or len(dispositions) != receipt["hygiene"]["warn"]:
    fail("WARN disposition count")
labels = set()
for disposition in dispositions:
    exact_keys(disposition, {"label", "disposition"}, "WARN disposition")
    label, value = disposition["label"], disposition["disposition"]
    if (not isinstance(label, str) or not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9 ._/-]{0,127}", label) or
            label in labels or not isinstance(value, str) or
            not re.fullmatch(r"[a-z0-9][a-z0-9._-]{0,63}", value)):
        fail("WARN disposition shape")
    labels.add(label)

if receipt["supplemental_oidf"] != {
    "classification": "supplemental_non_certifying", "required_gate": False
}:
    fail("supplemental classification")

if kind == "durable":
    if receipt["inventory_relation"] != {"status": "verified"} or receipt["repository"] != repository:
        fail("durable repository relation")
    if not re.fullmatch(r"[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+", repository):
        fail("repository syntax")
    if receipt["historical_release"] != {
        "source_sha": historical_source,
        "ci_run_id": int(historical_ci),
        "release_run_id": int(historical_release),
        "version": historical_version,
        "checksum": historical_checksum,
        "tag": historical_tag,
        "status": "verified",
    }:
        fail("historical release")
    captured = receipt["captured_at"]
    if not isinstance(captured, str) or not re.fullmatch(r"\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z", captured):
        fail("captured timestamp syntax")
    datetime.datetime.strptime(captured, "%Y-%m-%dT%H:%M:%SZ")
PY
}

acceptance_already_complete() {
  local candidate repository advertised current_local current_remote
  [[ -e "$ACCEPTANCE_RECEIPT" ]] || return 1
  candidate="$(jq -er '.baseline_sha' "$ACCEPTANCE_RECEIPT" 2>/dev/null)" ||
    fail "existing acceptance receipt is malformed or unsafe"
  repository="$(jq -er '.repository' "$ACCEPTANCE_RECEIPT" 2>/dev/null)" ||
    fail "existing acceptance receipt is malformed or unsafe"
  [[ "$repository" =~ ^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$ ]] ||
    fail "existing acceptance repository is malformed"
  require_oid "$candidate" "existing acceptance candidate"
  validate_acceptance_receipt durable "$ACCEPTANCE_RECEIPT" "$candidate" "$repository" \
    "$HISTORICAL_SOURCE" "$HISTORICAL_CI_RUN" "$HISTORICAL_RELEASE_RUN" \
    "$HISTORICAL_VERSION" "$HISTORICAL_CHECKSUM" "$HISTORICAL_TAG" >/dev/null 2>&1 ||
    fail "existing acceptance receipt is malformed or unsafe"
  OLD_ACCEPTANCE_BASE="$candidate"
  OLD_ACCEPTANCE_RECEIPT_SHA256="$(python3 - "$ACCEPTANCE_RECEIPT" <<'PY'
import hashlib, pathlib, sys
print(hashlib.sha256(pathlib.Path(sys.argv[1]).read_bytes()).hexdigest())
PY
)" || fail "existing acceptance receipt cannot be fingerprinted"
  [[ ! -e "$HOST_RECEIPT" ]] || return 1
  advertised="$(git -C "$ROOT" ls-remote origin refs/heads/main 2>/dev/null | awk 'NR == 1 { print $1 }')"
  current_local="$(git -C "$ROOT" rev-parse refs/heads/main 2>/dev/null)" ||
    fail "local main is unavailable"
  current_remote="$(git -C "$ROOT" rev-parse refs/remotes/origin/main 2>/dev/null)" ||
    fail "origin/main is unavailable"
  if [[ "$current_local" != "$candidate" || "$current_remote" != "$candidate" || "$advertised" != "$candidate" ]]; then
    [[ "$(git -C "$ROOT" rev-parse HEAD 2>/dev/null)" == "$current_local" &&
       "$advertised" == "$current_remote" ]] || fail "stale acceptance base has divergent main refs"
    CANDIDATE="$candidate"
    REPOSITORY="$repository"
    git -C "$ROOT" merge-base --is-ancestor "$candidate" "$current_local" ||
      fail "local main does not extend the recorded accepted SHA"
    git -C "$ROOT" merge-base --is-ancestor "$candidate" "$current_remote" ||
      fail "origin/main does not extend the recorded accepted SHA"
    return 1
  fi
  CANDIDATE="$candidate"
  REPOSITORY="$repository"
  wait_for_exact_acceptance
  verify_historical_release_chain
  acceptance_receipt_matches_exact "$ACCEPTANCE_RECEIPT" "$EXACT_ACCEPTANCE" ||
    fail "existing acceptance receipt disagrees with fresh exact-SHA evidence"
  printf 'phase 139 acceptance: already complete at %s\n' "$candidate"
  return 0
}

acceptance_receipt_matches_exact() {
  python3 - "$1" "$2" <<'PY'
import json
import sys

path, exact_json = sys.argv[1:]
common_keys = {
    "schema", "baseline_sha", "local_gate", "hygiene", "required_ci",
    "release_no_publish", "warn_dispositions", "supplemental_oidf"
}
with open(path, "r", encoding="utf-8") as stream:
    durable = json.load(stream)
exact = json.loads(exact_json)
if {key: durable[key] for key in common_keys} != exact:
    raise SystemExit(1)
PY
}

create_exact_acceptance_checkout() {
  EXACT_CHECKOUT_PARENT="$(mktemp -d "${TMPDIR:-/tmp}/lockspire-phase-139-acceptance.XXXXXX")" || return 1
  EXACT_CHECKOUT="$EXACT_CHECKOUT_PARENT/repository"
  if ! git -C "$ROOT" worktree add --detach "$EXACT_CHECKOUT" "$CANDIDATE" >/dev/null; then
    rmdir "$EXACT_CHECKOUT_PARENT" 2>/dev/null || true
    EXACT_CHECKOUT_PARENT=""
    EXACT_CHECKOUT=""
    return 1
  fi
}

wait_for_exact_acceptance() {
  local hygiene_script="$SCRIPT_DIR/repo_hygiene_check.sh" output acceptance_status=0
  local -a exact_command=(bash "$hygiene_script" --accept-sha "$CANDIDATE" --wait-seconds 1800 --format json)
  [[ -f "$hygiene_script" && ! -L "$hygiene_script" ]] || fail "hygiene command is not a regular file"
  create_exact_acceptance_checkout || fail "clean exact-SHA checkout could not be prepared"
  if [[ -d "$ROOT/deps" ]]; then
    if output="$(cd "$EXACT_CHECKOUT" && env "MIX_DEPS_PATH=$ROOT/deps" "${exact_command[@]}")"; then
      :
    else
      acceptance_status=$?
    fi
  else
    if output="$(cd "$EXACT_CHECKOUT" && env "${exact_command[@]}")"; then
      :
    else
      acceptance_status=$?
    fi
  fi
  if (( acceptance_status != 0 )); then
    case "$acceptance_status" in
      129|130|143) on_signal "$acceptance_status" ;;
      *)
        remove_exact_acceptance_checkout || true
        fail "exact-SHA hygiene acceptance did not pass"
        ;;
    esac
  fi
  if ! validate_acceptance_receipt exact "$output" "$CANDIDATE" "" \
    "$HISTORICAL_SOURCE" "$HISTORICAL_CI_RUN" "$HISTORICAL_RELEASE_RUN" \
    "$HISTORICAL_VERSION" "$HISTORICAL_CHECKSUM" "$HISTORICAL_TAG" >/dev/null 2>&1; then
    remove_exact_acceptance_checkout || true
    fail "exact-SHA hygiene receipt was malformed or incomplete"
  fi
  EXACT_ACCEPTANCE="$output"
  remove_exact_acceptance_checkout || fail "clean exact-SHA checkout could not be removed"
}

verify_historical_release_chain() {
  local release_train="$ROOT/.planning/RELEASE-TRAIN.md"
  local milestones="$ROOT/.planning/MILESTONES.md"
  [[ -f "$release_train" && ! -L "$release_train" && -f "$milestones" && ! -L "$milestones" ]] ||
    fail "maintained historical release records are unavailable"
  for value in "$HISTORICAL_SOURCE" "$HISTORICAL_CI_RUN" "$HISTORICAL_RELEASE_RUN" \
               "$HISTORICAL_VERSION" "$HISTORICAL_CHECKSUM" "$HISTORICAL_TAG"; do
    grep -Fq "$value" "$release_train" || fail "release train historical chain is incomplete"
    grep -Fq "$value" "$milestones" || fail "milestone historical chain is incomplete"
  done

  REPOSITORY="$(gh repo view --json nameWithOwner --jq '.nameWithOwner' 2>/dev/null)" ||
    fail "repository identity could not be resolved"
  [[ "$REPOSITORY" =~ ^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$ ]] || fail "repository identity is malformed"

  local ci release tag hex
  ci="$(gh api "repos/$REPOSITORY/actions/runs/$HISTORICAL_CI_RUN" 2>/dev/null)" ||
    fail "historical CI evidence is unavailable"
  release="$(gh api "repos/$REPOSITORY/actions/runs/$HISTORICAL_RELEASE_RUN" 2>/dev/null)" ||
    fail "historical Release evidence is unavailable"
  tag="$(gh api "repos/$REPOSITORY/releases/tags/$HISTORICAL_TAG" 2>/dev/null)" ||
    fail "historical release tag evidence is unavailable"
  hex="$(curl --silent --show-error --fail --location \
    "https://hex.pm/api/packages/lockspire/releases/$HISTORICAL_VERSION" 2>/dev/null)" ||
    fail "historical Hex evidence is unavailable"

  jq -e --argjson id "$HISTORICAL_CI_RUN" --arg sha "$HISTORICAL_SOURCE" '
    .id == $id and .head_sha == $sha and .event == "push" and .status == "completed" and .conclusion == "success"
  ' >/dev/null 2>&1 <<<"$ci" || fail "historical CI evidence does not match maintained truth"
  jq -e --argjson id "$HISTORICAL_RELEASE_RUN" --arg sha "$HISTORICAL_SOURCE" '
    .id == $id and .head_sha == $sha and .event == "workflow_dispatch" and .status == "completed" and .conclusion == "success"
  ' >/dev/null 2>&1 <<<"$release" || fail "historical Release evidence does not match maintained truth"
  jq -e --arg tag "$HISTORICAL_TAG" --arg sha "$HISTORICAL_SOURCE" '
    .tag_name == $tag and .target_commitish == $sha
  ' >/dev/null 2>&1 <<<"$tag" || fail "historical release tag does not match maintained truth"
  jq -e --arg version "$HISTORICAL_VERSION" --arg checksum "$HISTORICAL_CHECKSUM" '
    .version == $version and .checksum == $checksum
  ' >/dev/null 2>&1 <<<"$hex" || fail "historical Hex package does not match maintained truth"
}

write_live_receipt() {
  local inventory_relation captured_at replace_stale=0 observed_old_digest
  inventory_relation="$(bash "$SCRIPT_DIR/baseline_inventory.sh" \
    --verify-phase-139-posttransition-relation "$LEDGER" >/dev/null && printf '%s' verified)" ||
    fail "inventory relation changed during acceptance"
  verify_sealed_state_unchanged "$CANDIDATE"
  git -C "$ROOT" fetch --no-tags origin refs/heads/main:refs/remotes/origin/main >/dev/null
  [[ "$(git -C "$ROOT" rev-parse HEAD)" == "$CANDIDATE" &&
     "$(git -C "$ROOT" rev-parse refs/heads/main)" == "$CANDIDATE" &&
     "$(git -C "$ROOT" rev-parse refs/remotes/origin/main)" == "$CANDIDATE" ]] ||
    fail "repository moved during live acceptance"

  if [[ -e "$ACCEPTANCE_RECEIPT" ]]; then
    if validate_acceptance_receipt durable "$ACCEPTANCE_RECEIPT" "$CANDIDATE" "$REPOSITORY" \
      "$HISTORICAL_SOURCE" "$HISTORICAL_CI_RUN" "$HISTORICAL_RELEASE_RUN" \
      "$HISTORICAL_VERSION" "$HISTORICAL_CHECKSUM" "$HISTORICAL_TAG" >/dev/null 2>&1; then
      acceptance_receipt_matches_exact "$ACCEPTANCE_RECEIPT" "$EXACT_ACCEPTANCE" ||
        fail "existing acceptance receipt disagrees with fresh exact-SHA evidence"
      return 0
    fi
    [[ -n "$OLD_ACCEPTANCE_BASE" && -n "$OLD_ACCEPTANCE_RECEIPT_SHA256" &&
       "$OLD_ACCEPTANCE_BASE" != "$CANDIDATE" ]] ||
      fail "existing acceptance receipt is malformed or changed during acceptance"
    validate_acceptance_receipt durable "$ACCEPTANCE_RECEIPT" "$OLD_ACCEPTANCE_BASE" "$REPOSITORY" \
      "$HISTORICAL_SOURCE" "$HISTORICAL_CI_RUN" "$HISTORICAL_RELEASE_RUN" \
      "$HISTORICAL_VERSION" "$HISTORICAL_CHECKSUM" "$HISTORICAL_TAG" >/dev/null 2>&1 ||
      fail "prior acceptance receipt is malformed or unsafe"
    observed_old_digest="$(python3 - "$ACCEPTANCE_RECEIPT" <<'PY'
import hashlib, pathlib, sys
print(hashlib.sha256(pathlib.Path(sys.argv[1]).read_bytes()).hexdigest())
PY
)" || fail "prior acceptance receipt cannot be fingerprinted"
    [[ "$observed_old_digest" == "$OLD_ACCEPTANCE_RECEIPT_SHA256" ]] ||
      fail "prior acceptance receipt changed during acceptance"
    replace_stale=1
  fi

  captured_at="$(date -u +'%Y-%m-%dT%H:%M:%SZ')"
  python3 - "$COMMON_DIR" "$ACCEPTANCE_RECEIPT" "$CANDIDATE" "$captured_at" "$REPOSITORY" \
    "$inventory_relation" "$HISTORICAL_SOURCE" "$HISTORICAL_CI_RUN" "$HISTORICAL_RELEASE_RUN" \
    "$HISTORICAL_VERSION" "$HISTORICAL_CHECKSUM" "$HISTORICAL_TAG" "$EXACT_ACCEPTANCE" \
    "$replace_stale" "$OLD_ACCEPTANCE_BASE" "$OLD_ACCEPTANCE_RECEIPT_SHA256" <<'PY'
import hashlib, json, os, stat, sys, tempfile
(directory, target, candidate, captured, repository, relation, source, ci_run,
 release_run, version, checksum, tag, exact, replace_stale, old_base, old_digest) = sys.argv[1:]
directory = os.path.abspath(directory)
if os.path.dirname(os.path.abspath(target)) != directory:
    raise RuntimeError("acceptance target escaped Git common directory")
target_name = os.path.basename(target)
payload = json.loads(exact)
receipt = {
    "schema": "lockspire-phase-139-acceptance-v1",
    "baseline_sha": candidate,
    "inventory_relation": {"status": relation},
    "local_gate": payload["local_gate"],
    "hygiene": payload["hygiene"],
    "required_ci": payload["required_ci"],
    "release_no_publish": payload["release_no_publish"],
    "historical_release": {
        "source_sha": source, "ci_run_id": int(ci_run), "release_run_id": int(release_run),
        "version": version, "checksum": checksum, "tag": tag, "status": "verified"
    },
    "supplemental_oidf": payload["supplemental_oidf"],
    "warn_dispositions": payload["warn_dispositions"],
    "captured_at": captured,
    "repository": repository,
}
fd, temporary = tempfile.mkstemp(prefix=".lockspire-phase-139-acceptance.", dir=directory)
source_name = os.path.basename(temporary)
try:
    os.fchmod(fd, 0o600)
    with os.fdopen(fd, "w", encoding="utf-8") as stream:
        json.dump(receipt, stream, sort_keys=True, separators=(",", ":"))
        stream.write("\n")
        stream.flush()
        os.fsync(stream.fileno())
    directory_fd = os.open(directory, os.O_RDONLY | getattr(os, "O_DIRECTORY", 0))
    try:
        try:
            existing_stat = os.stat(target_name, dir_fd=directory_fd, follow_symlinks=False)
        except FileNotFoundError:
            existing_bytes = None
        else:
            if replace_stale != "1":
                raise RuntimeError("acceptance target appeared during publication")
            if (not stat.S_ISREG(existing_stat.st_mode) or stat.S_IMODE(existing_stat.st_mode) != 0o600):
                raise RuntimeError("prior acceptance target is unsafe")
            existing_fd = os.open(target_name, os.O_RDONLY | os.O_NOFOLLOW, dir_fd=directory_fd)
            with os.fdopen(existing_fd, "rb") as existing_stream:
                existing_bytes = existing_stream.read()
            if hashlib.sha256(existing_bytes).hexdigest() != old_digest:
                raise RuntimeError("prior acceptance target changed before replacement")
            prior = json.loads(existing_bytes)
            if prior.get("schema") != "lockspire-phase-139-acceptance-v1" or prior.get("baseline_sha") != old_base:
                raise RuntimeError("prior acceptance target does not match its authenticated base")
            archive_name = target_name + ".superseded-" + old_base
            try:
                archive_fd = os.open(
                    archive_name,
                    os.O_WRONLY | os.O_CREAT | os.O_EXCL | os.O_NOFOLLOW,
                    0o600,
                    dir_fd=directory_fd,
                )
            except FileExistsError:
                archive_fd = None
            if archive_fd is not None:
                with os.fdopen(archive_fd, "wb") as archive:
                    archive.write(existing_bytes)
                    archive.flush()
                    os.fsync(archive.fileno())
            else:
                archive_fd = os.open(archive_name, os.O_RDONLY | os.O_NOFOLLOW, dir_fd=directory_fd)
                with os.fdopen(archive_fd, "rb") as archive:
                    if archive.read() != existing_bytes:
                        raise RuntimeError("prior acceptance archive conflicts with the receipt")
            os.fsync(directory_fd)
            current_fd = os.open(target_name, os.O_RDONLY | os.O_NOFOLLOW, dir_fd=directory_fd)
            with os.fdopen(current_fd, "rb") as current_stream:
                if hashlib.sha256(current_stream.read()).hexdigest() != old_digest:
                    raise RuntimeError("prior acceptance target changed before replacement")
        os.replace(
            source_name,
            target_name,
            src_dir_fd=directory_fd,
            dst_dir_fd=directory_fd,
        )
        os.fsync(directory_fd)
        published_fd = os.open(
            target_name,
            os.O_RDONLY | os.O_NOFOLLOW,
            dir_fd=directory_fd,
        )
        with os.fdopen(published_fd, "r", encoding="utf-8") as published:
            published_stat = os.fstat(published.fileno())
            if (not stat.S_ISREG(published_stat.st_mode) or
                    stat.S_IMODE(published_stat.st_mode) != 0o600 or
                    json.load(published) != receipt):
                raise RuntimeError("published acceptance receipt failed descriptor validation")
    finally:
        os.close(directory_fd)
finally:
    if os.path.exists(temporary):
        os.unlink(temporary)
PY
  validate_acceptance_receipt durable "$ACCEPTANCE_RECEIPT" "$CANDIDATE" "$REPOSITORY" \
    "$HISTORICAL_SOURCE" "$HISTORICAL_CI_RUN" "$HISTORICAL_RELEASE_RUN" \
    "$HISTORICAL_VERSION" "$HISTORICAL_CHECKSUM" "$HISTORICAL_TAG" >/dev/null 2>&1 ||
    fail "new acceptance receipt failed validation"
}

if acceptance_already_complete; then
  exit 0
fi

prepare_host_receipt
PREAUTH="$(bash "$SCRIPT_DIR/baseline_inventory.sh" \
  --verify-phase-139-sealed-candidate-relation "$LEDGER")" || {
  printf '%s\n' "$PREAUTH"
  fail "sealed candidate authentication failed"
}
printf '%s\n' "$PREAUTH"
CANDIDATE="$(printf '%s\n' "$PREAUTH" | awk -F'|' \
  '$1 == "receipt_before_head" && $3 == "authorized_bookkeeping" { print $2 }')"
[[ "$(printf '%s\n' "$CANDIDATE" | sed '/^$/d' | wc -l | tr -d ' ')" -eq 1 ]] ||
  fail "sealed candidate authentication was ambiguous"
require_oid "$CANDIDATE" "sealed candidate"
[[ "$(resolve_sealed_candidate)" == "$CANDIDATE" ]] || fail "sealed candidate changed after authentication"
ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.1 MIX_ENV=test mix test test/lockspire/quality/phase_139_planning_consistency_test.exs ||
  fail "post-transition planning consistency test failed"
verify_sealed_state_unchanged "$CANDIDATE"
if [[ -z "$PUBLISH_SHA" ]]; then
  fail "candidate preparation is blocked until its exact SHA is explicitly published: candidate $CANDIDATE; no ref was changed; after approval, rerun with --publish $CANDIDATE"
fi
[[ "$PUBLISH_SHA" == "$CANDIDATE" ]] ||
  fail "--publish must name the exact sealed candidate SHA $CANDIDATE"
fast_forward_main "$CANDIDATE"
verify_sealed_state_unchanged "$CANDIDATE"
bash "$SCRIPT_DIR/baseline_inventory.sh" --verify-phase-139-posttransition-relation "$LEDGER"
wait_for_exact_acceptance
verify_historical_release_chain
write_live_receipt
node "$STATE_HELPER" complete 139 >/dev/null || fail "host receipt completion failed"
