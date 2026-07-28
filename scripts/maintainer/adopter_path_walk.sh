#!/usr/bin/env bash
set -uo pipefail

# ---------------------------------------------------------------------------
# mix adopter.walk -- walks the documented Lockspire adopter path end to end:
# generates a stock Phoenix host app, wires the installer, migrates, boots,
# and drives an authorization-code + PKCE flow, recording a step-by-step,
# source-attributed report and a single pass/fail verdict.
#
# Deliberately `set -uo pipefail` and NOT `set -e`: a FAIL step must be
# recorded and the walk must keep going so later steps still get evidence.
# The one place this script fails fast is the preflight, which runs its
# required-command probe in an isolated subshell with `set -e`.
#
# See docs/install-and-onboard.md for the guide this harness proves.
# ---------------------------------------------------------------------------

WORKDIR="tmp/adopter-walk"
FROM_STEP="00"
KEEP=0
FORCE=0
PORT=4200
PREFLIGHT_ONLY=0

usage() {
  cat <<'EOF'
Usage: adopter_path_walk.sh [--workdir DIR] [--from-step NN] [--keep] [--force] [--port N] [--preflight-only] [-h|--help]

Walks the documented Lockspire adopter path end to end: generates a stock
Phoenix host app, wires the installer, migrates, boots, and drives an
authorization-code + PKCE flow -- recording a step-by-step report and a
single pass/fail verdict.

Flags:
  --workdir DIR      Directory the walk generates the host app into (default: tmp/adopter-walk).
  --from-step NN     Resume from step NN, skipping steps whose resume marker
                      places them earlier in the walk.
  --keep             Leave the booted host server running after the walk finishes,
                      so a maintainer can poke the app by hand. This is the ONLY
                      thing --keep means. The evidence tree (workdir, generated
                      host app, server log, step markers) survives every run,
                      with or without this flag.
  --force            Re-run steps even if a `.walk/steps/<step-id>.done` marker
                      says they already completed.
  --port N           Port the generated host app binds (default: 4200).
  --preflight-only   Run only the prerequisite probes, then print the report and exit.
  -h, --help         Show this help.

Examples:
  bash scripts/maintainer/adopter_path_walk.sh
  bash scripts/maintainer/adopter_path_walk.sh --preflight-only
  bash scripts/maintainer/adopter_path_walk.sh --from-step 04 --keep
EOF
}

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --workdir)
      if [[ "$#" -lt 2 ]]; then
        echo "Missing value for --workdir" >&2
        usage >&2
        exit 1
      fi
      WORKDIR="$2"
      shift 2
      ;;
    --from-step)
      if [[ "$#" -lt 2 ]]; then
        echo "Missing value for --from-step" >&2
        usage >&2
        exit 1
      fi
      FROM_STEP="$2"
      shift 2
      ;;
    --keep)
      KEEP=1
      shift
      ;;
    --force)
      FORCE=1
      shift
      ;;
    --port)
      if [[ "$#" -lt 2 ]]; then
        echo "Missing value for --port" >&2
        usage >&2
        exit 1
      fi
      PORT="$2"
      shift 2
      ;;
    --preflight-only)
      PREFLIGHT_ONLY=1
      shift
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if ! command -v git >/dev/null 2>&1; then
  echo "git is required to locate the Lockspire repo root" >&2
  exit 1
fi

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$REPO_ROOT"

# Every archive-touching command (mix local.hex, mix local.rebar,
# mix archive.install, mix phx.new) must see this before it runs, so the
# maintainer's own global phx_new installer archive is never replaced (D-06).
export MIX_ARCHIVES="$REPO_ROOT/.harness/archives"

# Database configuration resolves in the repo's established order (D-13).
# LOCKSPIRE_WALK_DB_NAME never defaults to lockspire_test or
# lockspire_adoption_demo -- the walk starts no database of its own beyond
# its own isolated one.
WALK_DB_HOST="${LOCKSPIRE_WALK_DB_HOST:-${PGHOST:-127.0.0.1}}"
WALK_DB_PORT="${LOCKSPIRE_WALK_DB_PORT:-${PGPORT:-5432}}"
WALK_DB_USER="${LOCKSPIRE_WALK_DB_USER:-${PGUSER:-$(whoami)}}"
WALK_DB_PASSWORD="${LOCKSPIRE_WALK_DB_PASSWORD:-${PGPASSWORD:-}}"
WALK_DB_NAME="${LOCKSPIRE_WALK_DB_NAME:-lockspire_adopter_walk_dev}"

HOST_APP_DIR="$WORKDIR/host_app"
SERVER_LOG="$WORKDIR/server.log"
SERVER_PID=""

declare -a RESULTS=()
PASS_COUNT=0
FAIL_COUNT=0

record_result() {
  local level="$1"
  local label="$2"
  local detail="$3"

  RESULTS+=("[$level] $label: $detail")

  case "$level" in
    PASS) PASS_COUNT=$((PASS_COUNT + 1)) ;;
    FAIL) FAIL_COUNT=$((FAIL_COUNT + 1)) ;;
  esac
}

# A missing prerequisite is never a walk FAIL -- it exits through this
# distinctly named path with its own exit code (2, vs a RED walk's 1) before
# any record_result call ever happens, so it can never land in the report or
# the defect ledger (D-14).
fail_prerequisite() {
  local name="$1"
  local detail="$2"

  echo "[PREREQUISITE] ${name}: ${detail}" >&2
  exit 2
}

# Resume machinery (D-19): a step is done once its marker file exists. The
# evidence tree these markers live in is never deleted by any code path (D-20).
mark_done() {
  local step_id="$1"

  mkdir -p "$WORKDIR/.walk/steps"
  : > "$WORKDIR/.walk/steps/${step_id}.done"
}

step_done() {
  local step_id="$1"

  [[ -f "$WORKDIR/.walk/steps/${step_id}.done" ]]
}

# Extracts the sortable "NNletter" ordering key from a step id, e.g.
# "step-00a-preflight" -> "00a", "step-04-migrate" -> "04".
step_order_key() {
  local step_id="$1"

  printf '%s\n' "${step_id#step-}" | grep -oE '^[0-9]+[a-z]*'
}

# should_run returns non-zero (do not run) when --from-step places this step
# before the resume point, or when the step's marker already exists and
# --force was not passed -- in the latter case it still records a PASS so a
# resumed run's report accounts for every step, per ADOPT-03.
should_run() {
  local step_id="$1"
  local key num

  key="$(step_order_key "$step_id")"
  num="${key:0:2}"

  if [[ "$num" < "$FROM_STEP" ]]; then
    return 1
  fi

  if step_done "$step_id" && [[ "$FORCE" -ne 1 ]]; then
    record_result "PASS" "$step_id" "skipped (already done)"
    return 1
  fi

  return 0
}

port_is_bound() {
  local port="$1"

  if (exec 3<>"/dev/tcp/127.0.0.1/${port}") 2>/dev/null; then
    return 0
  fi

  return 1
}

# Isolated in a subshell with `set -e` so the first missing command short
# circuits the loop -- the only place this script uses abort-on-error.
preflight_required_commands() {
  (
    set -e
    for cmd in git mix python3 cc make; do
      command -v "$cmd" >/dev/null 2>&1
    done
  )
}

preflight_postgres_reachable() {
  command -v pg_isready >/dev/null 2>&1 &&
    pg_isready -h "$WALK_DB_HOST" -p "$WALK_DB_PORT" -U "$WALK_DB_USER" >/dev/null 2>&1
}

# RESEARCH assumption A5: the walk's Postgres role must be able to create a
# database, not merely reach the server, so a permissions problem surfaces as
# PREREQUISITE rather than as a Lockspire defect later in the walk.
preflight_can_create_database() {
  command -v psql >/dev/null 2>&1 || return 1

  local result
  result="$(PGPASSWORD="$WALK_DB_PASSWORD" psql -h "$WALK_DB_HOST" -p "$WALK_DB_PORT" -U "$WALK_DB_USER" -tAc \
    "select (rolcreatedb or rolsuper) from pg_roles where rolname = current_user" postgres 2>/dev/null || true)"

  [[ "$(printf '%s' "$result" | tr -d '[:space:]')" == "t" ]]
}

run_preflight() {
  if preflight_required_commands; then
    record_result "PASS" "step-00a-preflight" "required commands present: git, mix, python3, cc, make"
  else
    for cmd in git mix python3 cc make; do
      if ! command -v "$cmd" >/dev/null 2>&1; then
        fail_prerequisite "$cmd" "required command is not installed (cc/make are required by the bcrypt_elixir NIF phx.gen.auth injects)"
      fi
    done
  fi

  if preflight_postgres_reachable; then
    record_result "PASS" "step-00a-preflight" "PostgreSQL reachable at ${WALK_DB_HOST}:${WALK_DB_PORT} as ${WALK_DB_USER}"
  else
    fail_prerequisite "postgres" "PostgreSQL is not reachable at ${WALK_DB_HOST}:${WALK_DB_PORT} as ${WALK_DB_USER} (pg_isready failed)"
  fi

  if preflight_can_create_database; then
    record_result "PASS" "step-00a-preflight" "${WALK_DB_USER} can create databases at ${WALK_DB_HOST}:${WALK_DB_PORT}"
  else
    fail_prerequisite "postgres-create-database" "${WALK_DB_USER} lacks CREATE DATABASE privilege against ${WALK_DB_HOST}:${WALK_DB_PORT}"
  fi

  if port_is_bound "$PORT"; then
    fail_prerequisite "port" "port ${PORT} is already bound; pass --port to choose another or stop whatever is listening"
  else
    record_result "PASS" "step-00a-preflight" "port ${PORT} is free"
  fi
}

# The only trap in this script -- it terminates the server pid this run
# started and does nothing else. It never deletes the workdir, the
# generated host app, the server log, or any step marker (D-20).
cleanup() {
  if [[ -n "$SERVER_PID" ]]; then
    kill "$SERVER_PID" 2>/dev/null || true
  fi
}

trap cleanup EXIT INT TERM

print_report() {
  printf 'Adopter path walk report\n'
  printf '%s\n' "${RESULTS[@]}"
  printf 'Summary: %s PASS, %s FAIL\n' "$PASS_COUNT" "$FAIL_COUNT"

  if [[ "$FAIL_COUNT" -gt 0 ]]; then
    echo "Result: adopter path is RED"
    exit 1
  fi

  echo "Result: adopter path is GREEN"
}

run_preflight

if [[ "$PREFLIGHT_ONLY" -eq 1 ]]; then
  print_report
  exit 0
fi

# Pre-guide and guide steps (step-00b onward) are added by later plans in
# this phase; the skeleton above is what they plug into via
# should_run/record_result/mark_done.

print_report
