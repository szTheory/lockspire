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
REPORT_JSON=""

usage() {
  cat <<'EOF'
Usage: adopter_path_walk.sh [--workdir DIR] [--from-step NN] [--keep] [--force] [--port N] [--preflight-only] [--report-json PATH] [-h|--help]

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
  --report-json PATH Where to write the machine-readable JSON report (default:
                      WORKDIR/.walk/report.json). Always written, on every code path
                      that prints the human-readable report.
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
    --report-json)
      if [[ "$#" -lt 2 ]]; then
        echo "Missing value for --report-json" >&2
        usage >&2
        exit 1
      fi
      REPORT_JSON="$2"
      shift 2
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

# The report path defaults inside WORKDIR, which .gitignore already ignores, and is always
# written -- never gated behind an opt-in flag (D-50).
if [[ -z "$REPORT_JSON" ]]; then
  REPORT_JSON="$WORKDIR/.walk/report.json"
fi

# RECORD_STREAM is truncated once here, at startup, so each invocation's report describes
# that invocation alone -- never a prior run's rows bleeding into a resumed one's report.
mkdir -p "$WORKDIR/.walk"
RECORD_STREAM="$WORKDIR/.walk/records.nul"
: >"$RECORD_STREAM"

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

# The walk's own base URL and Lockspire mount path -- installer defaults, since step-02-install
# never passes --mount-path. step-03a's config completion needs a real issuer; step-03b's router
# wiring and later plans' flow driver need the same mount path.
WALK_BASE_URL="http://127.0.0.1:${PORT}"
MOUNT_PATH="/lockspire"

# Fixed, obviously non-production walk credentials -- a cross-plan contract
# consumed unchanged by the flow driver (plan 126-03) and the secret-absence
# assertion (plan 126-06). Never substitute different values here without
# updating plan 126-06's ledger secret-absence criterion.
export LOCKSPIRE_WALK_EMAIL="walker@adopter.test"
export LOCKSPIRE_WALK_PASSWORD="walk-adopter-password-2026"

declare -a RESULTS=()
PASS_COUNT=0
FAIL_COUNT=0
RESOLVED_ELIXIR=""
RESOLVED_OTP=""
RESOLVED_POSTGRESQL=""
RESOLVED_PHX_NEW=""

record_result() {
  local level="$1"
  local label="$2"
  local detail="$3"

  RESULTS+=("[$level] $label: $detail")

  # NUL is the one byte that cannot appear in level/label/detail -- detail strings already
  # carry `"`, section signs, `%`, parentheses, and interpolated mix-compile output that can
  # contain newlines and backslashes. Passing content as printf ARGUMENTS (never inside the
  # format string) is injection-proof; scripts/maintainer/adopter_walk_report.py reads this
  # stream back and converts it to JSON -- no JSON is ever constructed in bash.
  printf '%s\0%s\0%s\0' "$level" "$label" "$detail" >>"$RECORD_STREAM"

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

# BSD/GNU `sed -i` portability split, same shape as
# scripts/publish/verify_install_truth.sh:76-81.
sed_i() {
  if [[ "$OSTYPE" == "darwin"* ]]; then
    sed -i '' "$@"
  else
    sed -i "$@"
  fi
}

# Inserts multi-line text immediately before the last unindented "end" in a file -- the
# module-closing `end` of a freshly generated Phoenix router.ex, which is always column 0.
# Deliberately head/tail/grep-based rather than `awk -v` with an embedded newline: the BSD awk
# shipped on maintainer laptops (the "one true awk", not gawk) rejects a `-v` string containing a
# literal newline ("newline in string"), so this must not depend on GNU awk semantics.
insert_before_final_module_end() {
  local file="$1"
  local text="$2"
  local line_no

  line_no="$(grep -n '^end$' "$file" | tail -n 1 | cut -d: -f1)"

  if [[ -z "$line_no" ]]; then
    line_no=$(($(wc -l <"$file") + 1))
  fi

  local tmp="${file}.walk-tmp"

  head -n $((line_no - 1)) "$file" >"$tmp"
  printf '%s\n' "$text" >>"$tmp"
  tail -n +"$line_no" "$file" >>"$tmp"
  mv "$tmp" "$file"
}

# Extracts the body of priv/templates/lockspire.install/router.ex's `lockspire_routes/1` macro
# from the already-rendered generated file -- the literal text a human reader would paste, per
# RESEARCH Pitfall 4. Since 127-05 the template renders `defmacro lockspire_routes(_opts \\ [])
# do quote do ... end end`, so the body lives between the `quote do` line (four-space indent) and
# its own matching `end` (also four-space indent) -- every construct inside the quote block sits
# at six or more spaces, so the first four-space `end` after `quote do` is always the match, never
# an interior pipeline/scope/defp end.
extract_lockspire_routes_body() {
  local generated_helper="$1"

  awk '
    /^    quote do$/ {
      capture = 1
      next
    }
    capture && /^    end$/ {
      capture = 0
      next
    }
    capture { print }
  ' "$generated_helper"
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

# step-00b-phx-new: install the pinned, isolated phx_new archive and generate
# a stock host app -- Ecto, HTML, LiveView, mailer, and assets all kept
# (ADOPT-02, D-05). Never strip a generator capability here.
run_step_00b_phx_new() {
  local step_id="step-00b-phx-new"

  should_run "$step_id" || return 0

  mkdir -p "$WORKDIR"

  if ! mix local.hex --force --if-missing >/dev/null 2>&1; then
    record_result "FAIL" "$step_id" "mix local.hex --force --if-missing failed"
    return
  fi

  if ! mix local.rebar --force >/dev/null 2>&1; then
    record_result "FAIL" "$step_id" "mix local.rebar --force failed"
    return
  fi

  # Pinned and forced (D-06): archives are keyed one entry per app name, so
  # an unpinned or unforced install either drifts or blocks on a replace
  # prompt even with stdin closed.
  if ! mix archive.install hex phx_new 1.8.9 --force >/dev/null 2>&1; then
    record_result "FAIL" "$step_id" "mix archive.install hex phx_new 1.8.9 --force failed"
    return
  fi

  # D-07: this is the only reliable way to assert the resolved installer
  # version. Application.spec(:phx_new, :vsn) returns nil for archives and
  # Mix.Local.archives_path/0 does not exist on Elixir 1.19 -- do not use
  # either.
  local installer_version
  installer_version="$(mix phx.new --version 2>&1 | tr -d '\r' | tail -n 1)"
  RESOLVED_PHX_NEW="$installer_version"

  if [[ "$installer_version" != "Phoenix installer v1.8.9" ]]; then
    fail_prerequisite "phx_new" "expected 'Phoenix installer v1.8.9', resolved '${installer_version}'"
  fi

  if [[ -e "$HOST_APP_DIR" ]]; then
    if [[ "$FORCE" -ne 1 ]]; then
      record_result "FAIL" "$step_id" "refusing to regenerate: ${HOST_APP_DIR} already exists without a resume marker (pass --force to override)"
      return
    fi

    # --force moves the prior host aside rather than deleting it -- D-20's "the evidence tree
    # is never deleted" posture applies to every generation, superseded or not. A timestamped
    # destination keeps each prior host inspectable and never collides with itself, even across
    # two --force runs in the same second (the trailing $$ breaks the tie).
    local superseded_dir="${HOST_APP_DIR}.superseded.$(date -u +%Y%m%dT%H%M%SZ).$$"
    mv "$HOST_APP_DIR" "$superseded_dir"
  fi

  # --install is a correctness requirement (D-09), not an optimization:
  # without the esbuild/tailwind binaries the dev endpoint's watcher child
  # re-raises past the endpoint supervisor's restart budget. No `--no-*`
  # capability-stripping flag is ever passed here (ADOPT-02, D-05).
  local phx_new_log="$WORKDIR/phx_new.log"

  if ! (cd "$WORKDIR" && mix phx.new host_app --database postgres --install) >"$phx_new_log" 2>&1; then
    record_result "FAIL" "$step_id" "mix phx.new host_app --database postgres --install failed (see ${phx_new_log})"
    return
  fi

  local dev_config="$HOST_APP_DIR/config/dev.exs"

  # Port and DB wiring patch (RESEARCH assumption A2, D-12/D-13): default
  # port 4200, never 4100 (pinned elsewhere in this repo). phx.new 1.8.9's
  # dev.exs template ships no explicit http port key at all -- inject one
  # rather than assuming a "port: 4000" literal exists to replace.
  sed_i -e "s/http: \[ip: {127, 0, 0, 1}\]/http: [ip: {127, 0, 0, 1}, port: ${PORT}]/" "$dev_config"
  sed_i -e "s/hostname: \"localhost\"/hostname: \"${WALK_DB_HOST}\"/" "$dev_config"
  sed_i -e "s/username: \"postgres\"/username: \"${WALK_DB_USER}\"/" "$dev_config"
  sed_i -e "s/password: \"postgres\"/password: \"${WALK_DB_PASSWORD}\"/" "$dev_config"
  sed_i -e "s/database: \"host_app_dev\"/database: \"${WALK_DB_NAME}\"/" "$dev_config"

  # Generate a fresh secret_key_base for this run. Never copy the committed
  # examples/adoption_demo/config/config.exs literal (T-126-04).
  local secret
  secret="$(cd "$HOST_APP_DIR" && mix phx.gen.secret 2>/dev/null | tail -n 1)"

  if [[ -n "$secret" ]]; then
    # `#` (never emitted by mix phx.gen.secret's base64 output) instead of `/` as the sed
    # delimiter: a `/`-delimited substitution intermittently broke here whenever the generated
    # secret itself contained a `/` (a normal, frequent occurrence in base64 output) -- confirmed
    # empirically ("bad flag in substitute command" from the extra unescaped delimiter).
    sed_i -e "s#secret_key_base: \"[^\"]*\"#secret_key_base: \"${secret}\"#" "$dev_config"
  fi

  record_result "PASS" "$step_id" "generated stock Phoenix 1.8.9 host app (Ecto/HTML/LiveView/mailer/assets) at ${HOST_APP_DIR}"
  mark_done "$step_id"
}

# step-00c-gen-auth: the strongest ADOPT-02 claim available -- Phoenix's own
# default authentication, with --live mandatory so the generator's
# interactive prompt never hangs the harness (D-21/D-22).
run_step_00c_gen_auth() {
  local step_id="step-00c-gen-auth"

  should_run "$step_id" || return 0

  local gen_auth_log="$WORKDIR/phx_gen_auth.log"

  if ! (cd "$HOST_APP_DIR" && mix phx.gen.auth Accounts User users --live) >"$gen_auth_log" 2>&1; then
    record_result "FAIL" "$step_id" "mix phx.gen.auth Accounts User users --live failed (see ${gen_auth_log})"
    return
  fi

  # phx.gen.auth adds bcrypt_elixir ~> 3.0 (a C NIF -- why step-00a-preflight
  # probes cc/make, D-26) and prompts the adopter to re-fetch dependencies.
  if ! (cd "$HOST_APP_DIR" && mix deps.get) >>"$gen_auth_log" 2>&1; then
    record_result "FAIL" "$step_id" "mix deps.get failed after phx.gen.auth (see ${gen_auth_log})"
    return
  fi

  record_result "PASS" "$step_id" "generated phx.gen.auth Accounts/User/users --live login seam"
  mark_done "$step_id"
}

# step-00d-seed-user: a password-capable, confirmed user via the generator's
# own context functions in the exact D-23 order. Never hand-insert a
# hashed_password -- a direct insert silently produces a password-less user.
# The host app's OWN phx.gen.auth migrations must be applied first; this is
# distinct from -- and precedes -- guide section 4's Lockspire migration
# step landed in a later plan.
run_step_00d_seed_user() {
  local step_id="step-00d-seed-user"

  should_run "$step_id" || return 0

  local seed_log="$WORKDIR/seed_user.log"

  if ! (cd "$HOST_APP_DIR" && mix ecto.create) >"$seed_log" 2>&1; then
    record_result "FAIL" "$step_id" "mix ecto.create failed for the generated host's own database (see ${seed_log})"
    return
  fi

  if ! (cd "$HOST_APP_DIR" && mix ecto.migrate) >>"$seed_log" 2>&1; then
    record_result "FAIL" "$step_id" "mix ecto.migrate failed for the generated host's own phx.gen.auth migrations (see ${seed_log})"
    return
  fi

  # WALK_DB_NAME is a fixed name (D-13), so the database survives between runs and a
  # regenerated host meets an existing users row -- looking the user up by email first and
  # reusing it when present keeps a `--force` regeneration idempotent instead of failing the
  # `{:ok, user} = register_user(...)` match on a duplicate email. A per-run database name is
  # never the fix here: that would change the walk's recorded environment truth (D-13) and
  # leak databases across runs. The token / magic-link / password sequence itself stays
  # unchanged either way.
  local seed_script
  seed_script="$(
    cat <<'ELIXIR'
email = System.fetch_env!("LOCKSPIRE_WALK_EMAIL")
password = System.fetch_env!("LOCKSPIRE_WALK_PASSWORD")

user =
  case HostApp.Accounts.get_user_by_email(email) do
    nil ->
      {:ok, new_user} = HostApp.Accounts.register_user(%{email: email})
      new_user

    existing_user ->
      existing_user
  end

{encoded, user_token} = HostApp.Accounts.UserToken.build_email_token(user, "login")
HostApp.Repo.insert!(user_token)
{:ok, {user, _}} = HostApp.Accounts.login_user_by_magic_link(encoded)
{:ok, {_user, _}} = HostApp.Accounts.update_user_password(user, %{password: password})
IO.puts("adopter-walk: seeded password-capable user")
ELIXIR
  )"

  if ! (cd "$HOST_APP_DIR" && mix run -e "$seed_script") >>"$seed_log" 2>&1; then
    record_result "FAIL" "$step_id" "seeding ${LOCKSPIRE_WALK_EMAIL} failed (see ${seed_log})"
    return
  fi

  record_result "PASS" "$step_id" "seeded confirmed password-capable user ${LOCKSPIRE_WALK_EMAIL}"
  mark_done "$step_id"
}

# step-01-add-dep: guide §1 "Add Lockspire" -- insert {:lockspire, path: $REPO_ROOT} into the
# generated host's mix.exs deps list. Never a Hex pin (D-04): a pin would prove the last release
# rather than the branch Phases 127-129 are repairing. Since 127-02, Lockspire's own mix.exs
# ranges ecto_sql (">= 3.13.5 and < 4.0.0") instead of pinning "~> 3.13.5", so a stock
# `mix phx.new --database postgres` host's own already-resolved ecto/ecto_sql versions now
# satisfy Lockspire's requirement without an unlock step (closes ADOPT-D15).
run_step_01_add_dep() {
  should_run "step-01-add-dep" || return 0

  local mix_exs="$HOST_APP_DIR/mix.exs"

  if ! grep -Fq ':lockspire, path:' "$mix_exs"; then
    sed_i -e "s#{:phoenix,#{:lockspire, path: \"${REPO_ROOT}\"},\n      {:phoenix,#" "$mix_exs"
  fi

  local add_dep_log="$WORKDIR/step_01_add_dep.log"

  if ! (cd "$HOST_APP_DIR" && mix deps.get) >"$add_dep_log" 2>&1; then
    local error_detail
    # Prefer the resolver's own "Because ..." incompatibility line over incidental local
    # noise (e.g. a transient Hex ETS cache warning) that may precede it in the log.
    error_detail="$(grep -m 1 '^Because ' "$add_dep_log" || true)"
    [[ -z "$error_detail" ]] && error_detail="$(head -n 1 "$add_dep_log")"
    record_result "FAIL" "step-01-add-dep" "§1 Add Lockspire: mix deps.get failed (${error_detail})"
    return
  fi

  if ! (cd "$HOST_APP_DIR" && mix compile) >>"$add_dep_log" 2>&1; then
    local error_detail
    error_detail="$(head -n 1 "$add_dep_log")"
    record_result "FAIL" "step-01-add-dep" "§1 Add Lockspire: mix compile failed (${error_detail})"
    return
  fi

  record_result "PASS" "step-01-add-dep" "§1 Add Lockspire: mix deps.get resolved :lockspire from ${REPO_ROOT}"
  mark_done "step-01-add-dep"
}

# step-02-install: guide §2 "Generate the host seam" -- mix lockspire.install with no flags. The
# generated defaults are what a real adopter gets; passing --storage-prefix/--oban-prefix here
# would hide a real schema failure instead of recording it (RESEARCH Open Question 4).
run_step_02_install() {
  should_run "step-02-install" || return 0

  local install_log="$WORKDIR/step_02_install.log"

  if ! (cd "$HOST_APP_DIR" && mix lockspire.install) >"$install_log" 2>&1; then
    local error_detail
    error_detail="$(head -n 1 "$install_log")"
    record_result "FAIL" "step-02-install" "§2 Generate the host seam: mix lockspire.install failed (${error_detail})"
    return
  fi

  if [[ ! -f "$HOST_APP_DIR/.lockspire/install_manifest.json" ]]; then
    record_result "FAIL" "step-02-install" "§2 Generate the host seam: mix lockspire.install exited 0 but .lockspire/install_manifest.json is missing"
    return
  fi

  # ADOPT-D16 is closed as of 127-06: priv/templates/lockspire.install/authorized_apps/
  # index.html.heex now uses Elixir string interpolation (#{consent.grant.id}) instead of a
  # nested EEx tag inside a HEEx {...} attribute expression, so the generated
  # authorized_apps_html/index.html.heex compiles as rendered -- no harness patch is applied
  # here any longer.

  record_result "PASS" "step-02-install" "§2 Generate the host seam: mix lockspire.install exited 0 and wrote .lockspire/install_manifest.json"
  mark_done "step-02-install"
}

# step-03a-config-import: guide §3 "Wire the generated files" (first instruction) --
# import_config "lockspire.exs" from the host's main config entrypoint. Since 127-06 the
# installer's own config template already emits a mount-path-consistent issuer suffix,
# known_scopes, signing_alg, and a self-describing secret_key_base placeholder on its own
# (ADOPT-D04's template half is closed); what remains is genuinely walk-specific value
# substitution -- a real reachable issuer host, a freshly generated secret, and the "read:walk"
# scope this harness's own proof needs -- never an adopter-facing defect.
run_step_03a_config_import() {
  should_run "step-03a-config-import" || return 0

  local host_config="$HOST_APP_DIR/config/config.exs"
  local lockspire_config="$HOST_APP_DIR/config/lockspire.exs"

  if [[ ! -f "$lockspire_config" ]]; then
    record_result "FAIL" "step-03a-config-import" "§3 Wire the generated files: config/lockspire.exs is missing (step-02-install did not complete)"
    return
  fi

  if ! grep -Fq 'import_config "lockspire.exs"' "$host_config"; then
    printf '\nimport_config "lockspire.exs"\n' >>"$host_config"
  fi

  local compile_log="$WORKDIR/step_03a_config_import.log"

  if ! (cd "$HOST_APP_DIR" && mix compile) >"$compile_log" 2>&1; then
    local error_detail
    error_detail="$(head -n 1 "$compile_log")"
    record_result "FAIL" "step-03a-config-import" "§3 Wire the generated files: host fails to compile after import_config lockspire.exs (${error_detail})"
    return
  fi

  local missing_keys=()

  if ! grep -Fq 'oban:' "$lockspire_config"; then
    missing_keys+=("oban:")
  fi

  if grep -Fq 'issuer: "https://example.com' "$lockspire_config"; then
    missing_keys+=("a real reachable issuer host")
  fi

  if grep -Fq 'secret_key_base: "REPLACE_ME_WITH_A_MIX_PHX_GEN_SECRET_VALUE"' "$lockspire_config"; then
    missing_keys+=("a real secret_key_base")
  fi

  if ! grep -Fq 'read:walk' "$lockspire_config"; then
    missing_keys+=("read:walk in known_scopes")
  fi

  if [[ "${#missing_keys[@]}" -eq 0 ]]; then
    record_result "PASS" "step-03a-config-import" "§3 Wire the generated files: import_config lockspire.exs is sufficient to boot"
    mark_done "step-03a-config-import"
    return
  fi

  local missing_list
  missing_list="$(
    IFS=,
    echo "${missing_keys[*]}"
  )"
  record_result "FAIL" "step-03a-config-import" "§3 Wire the generated files: config/lockspire.exs still needs ${missing_list} before a real walk can boot against it -- none of these are adopter-facing; they are values only this harness's own proof run needs (ADOPT-D04)"

  # LOCKSPIRE_WALK_WORKAROUND: ADOPT-D04
  # 127-06 closed the template half of this defect: the config template now emits a
  # mount-path-consistent issuer suffix, known_scopes, signing_alg, and a self-describing
  # secret_key_base placeholder on its own. Each substitution below is guarded independently by
  # whether that specific value still needs replacing, rather than by one unrelated key's
  # presence -- the previous guard tested only whether `known_scopes` was absent, which the
  # template now always emits, so it silently skipped the issuer substitution the walk still
  # needs (the template's own issuer is still a placeholder "https://example.com" host that no
  # running walk can reach).
  if grep -Fq 'issuer: "https://example.com' "$lockspire_config"; then
    sed_i -e "s#issuer: \"https://example.com#issuer: \"${WALK_BASE_URL}#" "$lockspire_config"
  fi

  if grep -Fq 'secret_key_base: "REPLACE_ME_WITH_A_MIX_PHX_GEN_SECRET_VALUE"' "$lockspire_config"; then
    local lockspire_secret
    lockspire_secret="$(cd "$HOST_APP_DIR" && mix phx.gen.secret 2>/dev/null | tail -n 1)"

    if [[ -z "$lockspire_secret" ]]; then
      lockspire_secret="$(date +%s%N)-lockspire-walk-fallback-secret"
    fi

    # Never copy the committed examples/adoption_demo/config/config.exs secret literal
    # (T-126-04); replace the template's own placeholder rather than appending a second key.
    sed_i -e "s#secret_key_base: \"REPLACE_ME_WITH_A_MIX_PHX_GEN_SECRET_VALUE\"#secret_key_base: \"${lockspire_secret}\"#" "$lockspire_config"
  fi

  if ! grep -Fq 'read:walk' "$lockspire_config"; then
    # "read:walk" is the scope this harness's own step-03e-protected-route and
    # adopter_path_flow.py invented for the /api/walk/summary proof -- no adopter requests it.
    # known_scopes is what AuthorizationRequest checks an unrecognized scope against, so
    # omitting it here caused a real "scope is unknown" failure at step-06b-flow, confirmed
    # against a real generated host.
    sed_i -e 's#known_scopes: \["openid", "email", "profile"\]#known_scopes: ["openid", "email", "profile", "read:walk"]#' "$lockspire_config"
  fi

  if ! grep -Fq 'oban:' "$lockspire_config"; then
    sed_i -E -e "s#oban_prefix: \"[^\"]*\"#&,\n  oban: [queues: false, plugins: false]#" "$lockspire_config"
  fi

  mark_done "step-03a-config-import"
}

# step-03b-router-call: guide §3 "Wire the generated files" -- follow the guide literally: import
# the generated HostAppWeb.Router.Lockspire module and call lockspire_routes/0 in the router
# body. lockspire_routes/0 returns a heredoc String, not a quoted macro, so calling it defines
# zero routes and raises no compile error -- the expected observation is that exact
# counter-intuitive shape (RESEARCH Pitfall 4). A clean compile is never recorded as PASS here.
run_step_03b_router_call() {
  should_run "step-03b-router-call" || return 0

  local host_router="$HOST_APP_DIR/lib/host_app_web/router.ex"
  local generated_helper="$HOST_APP_DIR/lib/host_app_web/router/lockspire.ex"

  if [[ ! -f "$generated_helper" ]]; then
    record_result "FAIL" "step-03b-router-call" "§3 Wire the generated files: lib/host_app_web/router/lockspire.ex is missing (step-02-install did not complete)"
    return
  fi

  if ! grep -Fq 'import HostAppWeb.Router.Lockspire' "$host_router"; then
    insert_before_final_module_end "$host_router" "$(printf '  import HostAppWeb.Router.Lockspire\n\n  lockspire_routes()')"
  fi

  local compile_log="$WORKDIR/step_03b_router_call.log"

  if ! (cd "$HOST_APP_DIR" && mix compile) >"$compile_log" 2>&1; then
    local error_detail
    error_detail="$(head -n 1 "$compile_log")"
    record_result "FAIL" "step-03b-router-call" "§3 Wire the generated files: calling lockspire_routes() failed to compile (${error_detail})"
    return
  fi

  local routes_log="$WORKDIR/step_03b_router_call_routes.log"
  (cd "$HOST_APP_DIR" && mix phx.routes) >"$routes_log" 2>&1 || true

  # A plain `grep -F "${MOUNT_PATH}"` over the whole log is not a real-route check: `mix
  # phx.routes` also emits compile warnings whose *file paths* contain the mount-path substring
  # (e.g. "lib/host_app_web/controllers/lockspire_verification_html/index.html.heex" contains
  # "/lockspire" even though zero real routes were registered) -- confirmed against a real
  # generated host, where this false-positive substring match masked ADOPT-D01's real,
  # documented-and-expected zero-routes outcome. Only an actual route-table row (leading
  # whitespace, an HTTP verb or `*`, then the mount path) counts as a route.
  if grep -Eq "^[[:space:]]*(GET|POST|PUT|PATCH|DELETE|WS|\\*)[[:space:]]+${MOUNT_PATH}" "$routes_log"; then
    record_result "PASS" "step-03b-router-call" "§3 Wire the generated files: calling lockspire_routes() as documented defines the Lockspire mount"
    mark_done "step-03b-router-call"
    return
  fi

  record_result "FAIL" "step-03b-router-call" "§3 Wire the generated files: calling lockspire_routes() as documented compiles clean, zero routes defined (ADOPT-D01 -- the generated helper returns a String, not a quoted macro)"
  mark_done "step-03b-router-call"
}

# step-03b-router-paste: guide §3 "Wire the generated files" -- apply the other documented
# reading a human would take: paste lockspire_routes/1's own extracted quote body directly into
# the host router, in place of calling the macro. Since 127-05 the emitted body is
# self-contained -- it defines its own namespaced :lockspire_require_operator pipeline rather
# than referencing an undefined :require_operator one -- so a direct paste is expected to
# compile cleanly (ADOPT-D02 is closed). This sub-step always restores the router from backup
# before returning, whichever way it goes, so step-03b-router-wire starts from a known point.
run_step_03b_router_paste() {
  should_run "step-03b-router-paste" || return 0

  local host_router="$HOST_APP_DIR/lib/host_app_web/router.ex"
  local generated_helper="$HOST_APP_DIR/lib/host_app_web/router/lockspire.ex"

  if [[ ! -f "$generated_helper" ]]; then
    record_result "FAIL" "step-03b-router-paste" "§3 Wire the generated files: lib/host_app_web/router/lockspire.ex is missing (step-02-install did not complete)"
    return
  fi

  mkdir -p "$WORKDIR/.walk"
  local backup="$WORKDIR/.walk/router_pre_paste.bak"
  cp "$host_router" "$backup"

  # "In place of calling the macro" is literal: step-03b-router-call already wired a
  # lockspire_routes() call into this router, and since 127-05 that call injects the whole
  # route table -- including live_session :lockspire_consent. Pasting the body while the call
  # is still present defines that live_session twice, which Phoenix.LiveView.Router rejects
  # with "attempting to redefine live_session :lockspire_consent". That is an artifact of
  # walking both readings against one router, not something an adopter following either
  # reading alone would ever hit, so the call is dropped for the duration of the paste. The
  # backup restored below puts it back.
  sed_i -E -e '/^[[:space:]]*lockspire_routes\(\)[[:space:]]*$/d' "$host_router"

  local pasted_body
  pasted_body="$(extract_lockspire_routes_body "$generated_helper")"
  insert_before_final_module_end "$host_router" "$pasted_body"

  local compile_log="$WORKDIR/step_03b_router_paste.log"

  if (cd "$HOST_APP_DIR" && mix compile) >"$compile_log" 2>&1; then
    record_result "PASS" "step-03b-router-paste" "§3 Wire the generated files: pasting lockspire_routes/1's own quote body directly into the host router compiles -- the emitted body defines its own namespaced :lockspire_require_operator pipeline rather than referencing an undefined one"
  else
    local error_detail
    error_detail="$(head -n 1 "$compile_log")"
    record_result "FAIL" "step-03b-router-paste" "§3 Wire the generated files: pasting lockspire_routes/1's own quote body fails to compile (${error_detail})"
  fi

  cp "$backup" "$host_router"
  mark_done "step-03b-router-paste"
}

# step-03b-router-wire: guide §3 "Wire the generated files" -- since 127-05, calling
# lockspire_routes() (already wired into the host router by step-03b-router-call) injects the
# entire real route table on its own: its own deny-closed :lockspire_require_operator pipeline,
# the ordered admin/public forwards, and the browser-piped interaction routes and consent
# LiveView (ADOPT-D02 and ADOPT-D03 are both closed -- no harness rewiring is required any
# longer). The one value the template still deliberately leaves for the host to supply is the
# consent live_session's on_mount: hook (127-05, D-11) -- specific to the host's own
# account/session implementation. This step's only remaining job is patching that one value into
# the generated helper (never inserting a wrapper of its own, which would nest a second
# live_session around the same route and fail to compile) and confirming the whole route table,
# including the consent route's on_mount hook, actually works.
run_step_03b_router_wire() {
  should_run "step-03b-router-wire" || return 0

  local generated_helper="$HOST_APP_DIR/lib/host_app_web/router/lockspire.ex"

  if [[ ! -f "$generated_helper" ]]; then
    record_result "FAIL" "step-03b-router-wire" "§3 Wire the generated files: lib/host_app_web/router/lockspire.ex is missing (step-02-install did not complete)"
    return
  fi

  if ! grep -Fq 'on_mount: [{HostAppWeb.UserAuth, :mount_current_scope}]' "$generated_helper"; then
    # LOCKSPIRE_WALK_WORKAROUND: ADOPT-D18
    # priv/templates/lockspire.install/router.ex (127-05, D-11) emits the consent route's own
    # live_session block from the template, deliberately leaving on_mount: for the host to
    # supply. Without it, a bare live_session never gets a live-view-populated session assign --
    # the :browser pipeline's fetch_current_scope_for_user plug only reaches conn.assigns for
    # ordinary Plug-based controller routes, never a LiveView socket's own assigns -- so
    # Lockspire.Web.ConsentLive's account-resolver call always sees current_scope as unset and
    # treats an actually-logged-in adopter as anonymous -- confirmed against a real generated
    # host: the consent page rendered "Sign in is required" for a user whose own session cookie
    # was already valid (proven by the root layout showing their email in the nav bar on the
    # same response). This patches only the value the template omits, into the generated host's
    # own copy of the helper file (never priv/templates/lockspire.install/router.ex, and never a
    # second live_session wrapper of the harness's own -- the template already wraps the route,
    # so a second wrapper would nest and fail to compile).
    sed_i -e 's/live_session :lockspire_consent do/live_session :lockspire_consent, on_mount: [{HostAppWeb.UserAuth, :mount_current_scope}] do/' "$generated_helper"
  fi

  local compile_log="$WORKDIR/step_03b_router_wire.log"

  if ! (cd "$HOST_APP_DIR" && mix compile) >"$compile_log" 2>&1; then
    local error_detail
    error_detail="$(head -n 1 "$compile_log")"
    record_result "FAIL" "step-03b-router-wire" "§3 Wire the generated files: real wiring still fails to compile (${error_detail})"
    return
  fi

  local routes_log="$WORKDIR/step_03b_router_wire_routes.log"
  (cd "$HOST_APP_DIR" && mix phx.routes) >"$routes_log" 2>&1 || true

  local missing_route=""

  # See step-03b-router-call's own comment: a bare substring grep over mix phx.routes output
  # false-positives on compile-warning file paths containing the mount-path substring, so this
  # must match an actual route-table row, not any line mentioning the mount path.
  if ! grep -Eq "^[[:space:]]*(GET|POST|PUT|PATCH|DELETE|WS|\\*)[[:space:]]+${MOUNT_PATH}" "$routes_log"; then
    missing_route="Lockspire mount"
  elif ! grep -Fq 'InteractionController' "$routes_log"; then
    missing_route="interaction routes"
  elif ! grep -Fq 'ConsentLive' "$routes_log"; then
    missing_route="consent LiveView route"
  fi

  if [[ -n "$missing_route" ]]; then
    record_result "FAIL" "step-03b-router-wire" "§3 Wire the generated files: real wiring compiled but mix phx.routes is missing the ${missing_route}"
    return
  fi

  record_result "PASS" "step-03b-router-wire" "§3 Wire the generated files: Lockspire mount, interaction routes, and consent LiveView route (with the host-supplied on_mount: hook) are all defined"
  mark_done "step-03b-router-wire"
}

# step-03c-resolver: guide §3 "Wire the generated files" -- implement the generated
# AccountResolver host seam. This is host-owned work (AGENTS.md): resolve_account/2,
# build_claims/2, and the login redirect are written into the generated host app, never into
# lib/lockspire/ or priv/templates/lockspire.install/. current_account/1 needs no host code --
# it already pattern-matches the current_scope.user assign mix phx.gen.auth --live sets.
run_step_03c_resolver() {
  local step_id="step-03c-resolver"

  should_run "$step_id" || return 0

  local resolver_file="$HOST_APP_DIR/lib/host_app/lockspire/account_resolver.ex"

  if [[ ! -f "$resolver_file" ]]; then
    record_result "FAIL" "$step_id" "§3 Wire the generated files: lib/host_app/lockspire/account_resolver.ex is missing (step-02-install did not complete)"
    return
  fi

  # ADOPT-D11 (owning phase 128): the guide's §3 resolver bullet list names what to implement --
  # current-account lookup, account lookup by subject reference, claim building, login redirect
  # -- but supplies no worked example, no subject-reference format contract, and no claim map
  # shape. The only guidance in the shipped template is the text inside its own raise.
  record_result "FAIL" "$step_id" "§3 Wire the generated files: the guide names resolve_account/2 and build_claims/2 to implement but supplies no worked example, subject-reference format contract, or claim map shape -- only the raise text inside the template itself (ADOPT-D11, owning phase 128)"

  local generated_login_path="/users/log-in"

  # Writes only into the generated host at $resolver_file -- never into
  # priv/templates/lockspire.install/account_resolver.ex or lib/lockspire/. Implements
  # resolve_account/2 (subject reference is the seeded user's id, rendered as a string) and
  # build_claims/2 (emits the seeded user's email claim, the exact value
  # scripts/maintainer/adopter_path_flow.py asserts at <mount>/userinfo). The resolver template's
  # own login-redirect default (127-06) already matches mix phx.gen.auth Accounts User users
  # --live's real login route, so no harness patch of this generated file's login path is
  # applied any longer.
  cat >"$resolver_file" <<'ELIXIR'
defmodule HostApp.Lockspire.AccountResolver do
  @moduledoc false

  @behaviour Lockspire.Host.AccountResolver

  alias Lockspire.Host.Claims
  alias Lockspire.Host.InteractionResult

  @impl true
  def resolve_current_account(conn_or_socket, context) do
    case current_account(conn_or_socket) do
      nil -> {:redirect, redirect_for_login(conn_or_socket, context)}
      account -> {:ok, account}
    end
  end

  @impl true
  def resolve_account(account_reference, _context) do
    id =
      case account_reference do
        value when is_integer(value) -> value
        value when is_binary(value) -> String.to_integer(value)
      end

    case HostApp.Repo.get(HostApp.Accounts.User, id) do
      nil -> {:error, :not_found}
      user -> {:ok, user}
    end
  end

  @impl true
  def build_claims(account, _context) do
    claims = %{"email" => account.email}

    {:ok, %Claims{subject: to_string(account.id), id_token: claims, userinfo: claims}}
  end

  @impl true
  def redirect_for_login(_conn_or_socket, context) do
    # Matches mix phx.gen.auth Accounts User users --live's own login route -- the same default
    # priv/templates/lockspire.install/account_resolver.ex ships since 127-06.
    %InteractionResult{
      login_path: "/users/log-in",
      return_to: Map.get(context, :return_to) || Map.get(context, "return_to"),
      params: %{
        "interaction_id" => Map.get(context, :interaction_id) || Map.get(context, "interaction_id")
      }
    }
  end

  defp current_account(%Plug.Conn{assigns: %{current_scope: %{user: user}}}) when not is_nil(user),
    do: user

  defp current_account(%Plug.Conn{assigns: %{current_scope: scope}}) do
    case Map.get(scope, :user) || Map.get(scope, "user") do
      nil -> nil
      user -> user
    end
  end

  defp current_account(%Phoenix.LiveView.Socket{assigns: %{current_scope: %{user: user}}})
       when not is_nil(user),
       do: user

  defp current_account(%Phoenix.LiveView.Socket{assigns: %{current_scope: scope}}) do
    case Map.get(scope, :user) || Map.get(scope, "user") do
      nil -> nil
      user -> user
    end
  end

  defp current_account(_conn_or_socket), do: nil
end
ELIXIR

  local compile_log="$WORKDIR/step_03c_resolver.log"

  if ! (cd "$HOST_APP_DIR" && mix compile) >"$compile_log" 2>&1; then
    local error_detail
    error_detail="$(head -n 1 "$compile_log")"
    record_result "FAIL" "$step_id" "§3 Wire the generated files: generated host fails to compile after implementing the resolver (${error_detail})"
    return
  fi

  local post_routes_log="$WORKDIR/step_03c_resolver_routes_post.log"
  (cd "$HOST_APP_DIR" && mix phx.routes) >"$post_routes_log" 2>&1 || true

  if ! grep -Fq "$generated_login_path" "$post_routes_log"; then
    record_result "FAIL" "$step_id" "§3 Wire the generated files: the configured login path ${generated_login_path} does not resolve to a route in mix phx.routes"
    return
  fi

  record_result "PASS" "$step_id" "§3 Wire the generated files: resolve_account/2 and build_claims/2 are implemented in the generated host and emit the seeded user's email claim; the login path ${generated_login_path} resolves to a real route"
  mark_done "$step_id"
}

# step-03d-app-tree: guide §3 "Wire the generated files" -- application-start ordering and
# supervision children a working install actually needs. Neither the installer nor the guide
# names either half: :lockspire declares mod: {Lockspire.Application, []} and is a plain
# dependency of the host, so OTP starts it before the host application (and therefore before the
# host Repo), and the installer's config template emits no oban: key, so Lockspire's default
# queues are live and immediately try to reach a Repo that has not started.
run_step_03d_app_tree() {
  local step_id="step-03d-app-tree"

  should_run "$step_id" || return 0

  local precheck_log="$WORKDIR/step_03d_precheck.log"

  if ! (cd "$HOST_APP_DIR" && mix compile) >"$precheck_log" 2>&1; then
    local error_detail
    error_detail="$(head -n 1 "$precheck_log")"
    record_result "FAIL" "$step_id" "§3 Wire the generated files: generated host does not compile ahead of application-start wiring (${error_detail})"
    return
  fi

  # ADOPT-D05 (owning phase 127 for the installer half, phase 128 for the guide half): merged
  # into one precisely attributed entry rather than two vague ones, per RESEARCH Pitfall 3.
  record_result "FAIL" "$step_id" "§3 Wire the generated files: nothing in the installer or the guide tells the host to order Lockspire's application start behind its own Repo or to add Lockspire's supervision children -- :lockspire starts before the host Repo, and its default Oban queues are live because the installer's config template emits no oban: key (ADOPT-D05, owning phase 127 for the installer half and phase 128 for the guide half)"

  local mix_exs="$HOST_APP_DIR/mix.exs"

  if ! grep -Fq 'included_applications: [:lockspire]' "$mix_exs"; then
    # LOCKSPIRE_WALK_WORKAROUND: ADOPT-D05
    # :lockspire is a plain dependency of the host, so OTP starts its application (and therefore
    # its supervision tree) before the host's own application -- and before the host Repo.
    # included_applications suppresses that automatic start so the host can order its own Repo
    # first. :oban and :cachex must still be named directly in extra_applications -- they are
    # regular (not included) applications, and Application.ensure_all_started/1 never walks an
    # included application's own dependency chain, so leaving them out means Oban's own registry
    # and Cachex's own supervisor never start. Both fixes follow
    # examples/adoption_demo/mix.exs:17-23.
    sed_i -e 's/extra_applications: \[:logger, :runtime_tools\]/extra_applications: [:logger, :runtime_tools, :oban, :cachex]/' "$mix_exs"
    sed_i -e 's/mod: {HostApp.Application, \[\]},/mod: {HostApp.Application, []},\n      included_applications: [:lockspire],/' "$mix_exs"
  fi

  local app_file="$HOST_APP_DIR/lib/host_app/application.ex"

  if [[ ! -f "$app_file" ]]; then
    record_result "FAIL" "$step_id" "§3 Wire the generated files: lib/host_app/application.ex is missing (step-00b-phx-new did not complete)"
    return
  fi

  if ! grep -Fq 'Lockspire.Oban' "$app_file"; then
    # LOCKSPIRE_WALK_WORKAROUND: ADOPT-D05
    # Add Lockspire's three supervision children -- the named Oban runtime built from its own
    # runtime config, the JWKS cache child spec, and the key cache -- to the generated host's
    # supervision tree after the host Repo, following
    # examples/adoption_demo/lib/adoption_demo/application.ex:9-14. The queue-disabling oban:
    # config key was already added in step-03a-config-import under ADOPT-D04; no second marker
    # is added here for that half of the fix.
    sed_i -e 's/HostApp.Repo,/HostApp.Repo,\n      {Lockspire.Oban, Lockspire.Oban.runtime_config!()},\n      Cachex.child_spec(name: :lockspire_jwks_cache),\n      Lockspire.KeyCache,/' "$app_file"
  fi

  local boot_log="$WORKDIR/step_03d_boot.log"

  if ! (cd "$HOST_APP_DIR" && mix run -e 'IO.puts("boot ok")') >"$boot_log" 2>&1; then
    local error_detail
    error_detail="$(head -n 1 "$boot_log")"
    record_result "FAIL" "$step_id" "§3 Wire the generated files: generated host still fails to boot after application-start wiring (${error_detail})"
    return
  fi

  record_result "PASS" "$step_id" "§3 Wire the generated files: generated host boots with included_applications: [:lockspire] ordering the host Repo first and Lockspire's supervision children (Oban, JWKS cache, key cache) wired after it"
  mark_done "$step_id"
}

# step-03e-protected-route: guide §3/§6 -- wire the optional protected host API route so
# ADOPT-04 gets its second, host-owned acceptance layer. Reproduces
# docs/protect-phoenix-api-routes.md's canonical plug order exactly: VerifyToken (scope-restricted
# to read:walk), EnforceSenderConstraints, RequireToken. No replay-store module is required --
# dpop_replay_store is required: false.
run_step_03e_protected_route() {
  local step_id="step-03e-protected-route"

  should_run "$step_id" || return 0

  local host_router="$HOST_APP_DIR/lib/host_app_web/router.ex"

  if [[ ! -f "$host_router" ]]; then
    record_result "FAIL" "$step_id" "§3 Wire the generated files: lib/host_app_web/router.ex is missing (step-00b-phx-new did not complete)"
    return
  fi

  local controller_file="$HOST_APP_DIR/lib/host_app_web/controllers/walk_api_controller.ex"

  if [[ ! -f "$controller_file" ]]; then
    # ADOPT-D19 (owning phase 128): docs/protect-phoenix-api-routes.md's "Access-token assigns
    # contract" documents conn.assigns.access_token (%Lockspire.AccessToken{}) as exposing
    # top-level `subject`, `scope`, `audience`, `expires_at`, and `cnf` fields. The real struct
    # (lib/lockspire/access_token.ex) has no such fields -- only `token`, `claims`, `client_id`,
    # `authorization_scheme`, `binding_type`, `binding_requirements`, `error`, and
    # `binding_verified`. Following the documented contract literally raises
    # `** (KeyError) key :subject not found` on the very first real request, confirmed against a
    # real generated host with a real issued access token. The actual subject and scope live
    # inside `access_token.claims["sub"]` / `access_token.claims["scope"]`.
    cat >"$controller_file" <<'ELIXIR'
defmodule HostAppWeb.WalkApiController do
  @moduledoc """
  Host-owned controller behind the :lockspire_protected_api pipeline (docs/protect-phoenix-api-routes.md).
  Reflects only the subject and granted scope from conn.assigns.access_token -- never the raw
  bearer token itself.
  """
  use HostAppWeb, :controller

  def show(conn, _params) do
    access_token = conn.assigns.access_token

    # LOCKSPIRE_WALK_WORKAROUND: ADOPT-D19
    # docs/protect-phoenix-api-routes.md documents access_token.subject/access_token.scope as
    # top-level fields on %Lockspire.AccessToken{}; the real struct has neither -- only a
    # `claims` map. Phase 128 must correct the guide (or add real accessor functions) so this
    # workaround is never how an adopter has to actually read these values.
    json(conn, %{
      access_token: %{
        subject: access_token.claims["sub"],
        scope: access_token.claims["scope"]
      }
    })
  end
end
ELIXIR
  fi

  if ! grep -Fq 'BEGIN LOCKSPIRE_PROTECTED_PIPELINE' "$host_router"; then
    # D-30: the guide presents the protected route as an optional adopter step, so the walk
    # performs only what the guide instructs -- never narrowing or dropping the scope
    # restriction to make the later assertion easier.
    local protected_body
    protected_body="$(
      printf '  # BEGIN LOCKSPIRE_PROTECTED_PIPELINE\n  pipeline :lockspire_protected_api do\n    plug Lockspire.Plug.VerifyToken, scopes: ["read:walk"]\n    plug Lockspire.Plug.EnforceSenderConstraints\n    plug Lockspire.Plug.RequireToken\n  end\n  # END LOCKSPIRE_PROTECTED_PIPELINE\n\n  scope "/api", HostAppWeb do\n    pipe_through [:api, :lockspire_protected_api]\n\n    get "/walk/summary", WalkApiController, :show\n  end'
    )"
    insert_before_final_module_end "$host_router" "$protected_body"
  fi

  local compile_log="$WORKDIR/step_03e_protected_route.log"

  if ! (cd "$HOST_APP_DIR" && mix compile) >"$compile_log" 2>&1; then
    local error_detail
    error_detail="$(head -n 1 "$compile_log")"
    record_result "FAIL" "$step_id" "§3 Wire the generated files: protected host API route wiring fails to compile (${error_detail})"
    return
  fi

  local routes_log="$WORKDIR/step_03e_protected_route_routes.log"
  (cd "$HOST_APP_DIR" && mix phx.routes) >"$routes_log" 2>&1 || true

  if ! grep -Fq '/api/walk/summary' "$routes_log"; then
    record_result "FAIL" "$step_id" "§3 Wire the generated files: /api/walk/summary is not present in mix phx.routes after wiring the protected pipeline"
    return
  fi

  record_result "PASS" "$step_id" "§3/§6 Wire the generated files: /api/walk/summary is wired behind the canonical VerifyToken -> EnforceSenderConstraints -> RequireToken pipeline, scope-restricted to read:walk"
  mark_done "$step_id"
}

# step-04-migrate: guide §4 "Run migrations" -- run the documented `mix ecto.create` and bare
# `mix ecto.migrate` exactly as written. No --migrations-path flag is added here: the point of
# this step is to observe what the documented command actually does, never to make it succeed.
# Its own exit code is never treated as the assertion (RESEARCH Pitfall 8) -- the verdict is
# deferred to step-05-verify, the independent detector, so this step can never record PASS.
run_step_04_migrate() {
  should_run "step-04-migrate" || return 0

  local migrate_log="$WORKDIR/step_04_migrate.log"

  (cd "$HOST_APP_DIR" && mix ecto.create) >"$migrate_log" 2>&1 || true
  (cd "$HOST_APP_DIR" && mix ecto.migrate) >>"$migrate_log" 2>&1
  local migrate_exit=$?

  # Never PASS here: the generated host's own phx.gen.auth migration was already applied by
  # step-00d-seed-user, so the documented bare `mix ecto.migrate` has nothing of its own left to
  # run and exits 0 having applied zero of Lockspire's migrations -- Lockspire's migrations live
  # under Lockspire's own priv/repo/migrations, never the host's default migrations path, so no
  # bare `mix ecto.migrate` invocation can ever reach them. A zero exit code here proves nothing
  # about Lockspire's migration state; step-05-verify is the honest detector.
  record_result "FAIL" "step-04-migrate" "§4 Run migrations: the documented \`mix ecto.create\` + bare \`mix ecto.migrate\` exited ${migrate_exit} against the host's own already-migrated database -- it ran zero of Lockspire's migrations, and its exit code alone proves nothing about Lockspire's migration state (see step-05-verify)"
  mark_done "step-04-migrate"
}

# step-05-verify: guide §5 "Verify the install wiring" -- the honest detector for step-04's
# silent no-op. Captures mix lockspire.verify's stdout regardless of exit code (RESEARCH
# assumption A8: a host with still-broken wiring may make the task degrade rather than report
# cleanly, and an opaque crash with no captured output would produce an unattributable ledger
# row), then parses the pending-migration count and table-existence checks out of it rather than
# branching on the task's own exit status.
run_step_05_verify() {
  should_run "step-05-verify" || return 0

  local verify_pre_log="$WORKDIR/step_05_verify_pre.log"
  (cd "$HOST_APP_DIR" && mix lockspire.verify) >"$verify_pre_log" 2>&1 || true

  local pending_detail
  pending_detail="$(grep -A 1 'Pending Lockspire or Oban migrations detected' "$verify_pre_log" | tail -n 1 | sed -e 's/^ *//')"

  local comma_count pending_count
  comma_count="$(grep -o ',' <<<"$pending_detail" | wc -l | tr -d ' ')"
  pending_count=0
  if [[ -n "$pending_detail" ]]; then
    pending_count=$((comma_count + 1))
  fi

  local missing_tables=()
  grep -Fq 'core tables are missing' "$verify_pre_log" && missing_tables+=("lockspire_clients")
  grep -Fq 'oban_jobs is missing' "$verify_pre_log" && missing_tables+=("oban_jobs")

  local missing_tables_str="none"
  if [[ "${#missing_tables[@]}" -gt 0 ]]; then
    missing_tables_str="$(
      IFS=,
      echo "${missing_tables[*]}"
    )"
  fi

  # ADOPT-D07 (owning phase 127): mix lockspire.verify's independent Ecto.Migrator.with_repo/2
  # check -- never the migrate command's own exit code -- is what surfaces that the documented
  # §4 command applies none of Lockspire's migrations.
  record_result "FAIL" "step-05-verify" "§5 Verify the install wiring: mix lockspire.verify reports ${pending_count} pending Lockspire/Oban migration(s) and missing tables: ${missing_tables_str} -- the documented §4 migrate command's exit-zero result never applied Lockspire's own migrations (ADOPT-D07, owning phase 127)"

  local lockspire_migrations_path
  # --no-start: Application.app_dir/2 is a static code-path lookup that needs the app
  # compiled, not started. Booting the full supervision tree here (as a plain `mix run -e`
  # would) races this IO.puts against the just-wired ADOPT-D05 supervision tree's own async
  # Logger output (e.g. a KeyCache refresh warning), which can land after the path line and
  # get captured by `tail -n 1` instead of the real path -- confirmed empirically against a
  # real generated host.
  lockspire_migrations_path="$(cd "$HOST_APP_DIR" && mix run --no-start -e 'IO.puts(Application.app_dir(:lockspire, "priv/repo/migrations"))' 2>/dev/null | grep -E '/priv/repo/migrations$' | tail -n 1)"

  local migrate_workaround_log="$WORKDIR/step_05_migrate_workaround.log"

  # LOCKSPIRE_WALK_WORKAROUND: ADOPT-D07
  # The release-safe application-directory form -- Application.app_dir(:lockspire,
  # "priv/repo/migrations") -- is the only form of this path that resolves correctly inside a Mix
  # release (D-49). A source-tree relative form under the dependency's own checkout is forbidden
  # here: it is a path that does not exist in a compiled release, and using it in this harness
  # would teach adopters a pattern that breaks the moment they build one.
  if [[ -n "$lockspire_migrations_path" ]]; then
    (cd "$HOST_APP_DIR" && mix ecto.migrate --migrations-path "$lockspire_migrations_path") \
      >"$migrate_workaround_log" 2>&1 || true
  fi

  # Follow-up observation: because the explicit path above shares the single schema_migrations
  # table with the host's own migrations, a later `mix ecto.migrations` run against the default
  # migrations path will report Lockspire's own migration versions as applied but file-not-found
  # -- itself part of the evidence that neither the bare default-path form nor a forbidden
  # source-tree-relative form can ever discover Lockspire's migrations on their own.

  local verify_post_log="$WORKDIR/step_05_verify_post.log"
  (cd "$HOST_APP_DIR" && mix lockspire.verify) >"$verify_post_log" 2>&1 || true

  if grep -Fq 'Pending Lockspire or Oban migrations detected' "$verify_post_log"; then
    record_result "FAIL" "step-05-verify" "§5 Verify the install wiring: after applying the release-safe migrations workaround, mix lockspire.verify still reports pending migrations -- the migrations themselves do not apply, not merely the documented command"
  else
    record_result "PASS" "step-05-verify" "§5 Verify the install wiring: after applying the release-safe migrations workaround (Application.app_dir(:lockspire, \"priv/repo/migrations\")), mix lockspire.verify reports zero pending Lockspire/Oban migrations"
  fi

  mark_done "step-05-verify"
}

# step-06a-client: guide §6 "Create a client and prove the flow" -- follow the guide literally:
# mix lockspire.client.create. Since 127-03, lib/mix/tasks/lockspire.client.create.ex wraps its
# Clients.register_client/1 call in Ecto.Migrator.with_repo/2 (the same pattern
# mix lockspire.verify's migrations check already used), so the documented task now reaches a
# running repo in a stock host directly and no workaround remains.
run_step_06a_client() {
  should_run "step-06a-client" || return 0

  local client_doc_log="$WORKDIR/step_06a_client_documented.log"

  # "openid" is never passed as an allowed scope here -- Lockspire.Clients.register_client/1
  # rejects it as :invalid_scope by design (lib/lockspire/clients.ex), because
  # Lockspire.Protocol.AuthorizationRequest already treats "openid" as implicitly allowed for
  # every client regardless of its registered allowed_scopes (unknown_scope?/disallowed_scope?
  # both short-circuit true for "openid").
  if ! (cd "$HOST_APP_DIR" && mix lockspire.client.create \
    --client-type public \
    --redirect-uri "${WALK_BASE_URL}/oauth/callback" \
    --scope email --scope profile --scope read:walk \
    --grant-type authorization_code \
    --client-id adopter-walk-public) >"$client_doc_log" 2>&1; then
    local client_doc_detail
    client_doc_detail="$(grep -m 1 '^\*\* (' "$client_doc_log")"
    if [[ -z "$client_doc_detail" ]]; then
      client_doc_detail="$(tail -n 1 "$client_doc_log")"
    fi

    record_result "FAIL" "step-06a-client" "§6 Create a client and prove the flow: the documented \`mix lockspire.client.create\` failed (${client_doc_detail})"
    return
  fi

  record_result "PASS" "step-06a-client" "§6 Create a client and prove the flow: registered public client adopter-walk-public (scopes email,profile,read:walk; grant authorization_code; token_endpoint_auth_method=none) via the documented mix lockspire.client.create task"

  # D-47/ADOPT-D06 (owning phase 127 for the installer half, phase 128 for the guide half): no
  # documented step mints a signing key. Lockspire.Admin.generate_key/1 exists but only
  # examples/adoption_demo/priv/repo/seeds.exs:82 ever calls a key into existence, and that seed
  # bypasses the Admin API entirely by inserting an already-active key straight through storage.
  record_result "FAIL" "step-06a-client" "§6 Create a client and prove the flow: no documented step mints a signing key -- JWKS and token issuance have nothing to sign with after a stock install (ADOPT-D06, owning phase 127 for the installer half and phase 128 for the guide half)"

  local key_script
  key_script='
{:ok, key_view} = Lockspire.Admin.generate_key(:sig)
key_id = key_view.key.id

{:ok, %{"keys" => keys}} = Lockspire.Protocol.Jwks.public_jwk_set()

if keys != [] do
  IO.puts("adopter-walk: JWKS non-empty after generate_key/1 alone (one undocumented call sufficient for publication)")
else
  IO.puts("adopter-walk: JWKS empty after generate_key/1 alone -- calling publish_key/2 as well")
  {:ok, _published} = Lockspire.Admin.publish_key(key_id)
  {:ok, %{"keys" => keys_after_publish}} = Lockspire.Protocol.Jwks.public_jwk_set()

  if keys_after_publish == [] do
    IO.puts("adopter-walk: JWKS STILL empty after generate_key/1 + publish_key/2")
    System.halt(1)
  else
    IO.puts("adopter-walk: JWKS non-empty only after generate_key/1 + publish_key/2 (two undocumented calls required for publication)")
  end
end

# Publication (JWKS visibility) is a separate lifecycle stage from activation (signing
# eligibility): Lockspire.Storage.Ecto.Repository.fetch_active_signing_key/1 only ever
# selects status: :active, which neither generate_key/1 nor publish_key/2 alone reaches --
# confirmed against a real generated host: the token endpoint failed with
# ":signing_key_not_found" after only those two calls, even though JWKS already listed the key.
{:ok, _activated} = Lockspire.Admin.activate_key(key_id)
IO.puts("adopter-walk: key activated (a third undocumented call -- generate_key/1, publish_key/2, activate_key/2 -- is required before the key can actually sign a token, not merely appear in JWKS)")
'

  local key_result_log="$WORKDIR/step_06a_signing_key.log"

  # LOCKSPIRE_WALK_WORKAROUND: ADOPT-D06
  # Lockspire.Admin.generate_key/1 is the shipped public API for minting a signing key; whether it
  # alone is sufficient for JWKS to publish it is RESEARCH Open Question 1, asserted here rather
  # than assumed -- either outcome is recorded as evidence on the same ledger entry. A third call,
  # activate_key/2, is additionally required before the key is eligible to sign a real token (see
  # comment above) -- this is the same underlying "no documented step mints a usable signing key"
  # gap, refined with the activation evidence a live token exchange surfaced.
  if ! (cd "$HOST_APP_DIR" && mix run -e "$key_script") >"$key_result_log" 2>&1; then
    record_result "FAIL" "step-06a-client" "§6 Create a client and prove the flow: signing key setup failed even after Lockspire.Admin.generate_key/1, publish_key/2, and activate_key/2 (see ${key_result_log})"
    return
  fi

  local key_detail
  key_detail="$(tail -n 1 "$key_result_log")"

  record_result "PASS" "step-06a-client" "§6 Create a client and prove the flow: JWKS now reports a key -- ${key_detail}"
  mark_done "step-06a-client"
}

# Boots the generated host in the background, drives the flow driver (plan 126-03) against it,
# folds every [PASS]/[FAIL] result line the driver printed into this harness's own RESULTS
# accumulator in the order it printed them, and tears the server down unless --keep was passed.
# Reproduces .github/workflows/ci.yml:313-327's background-boot/pid-capture/log-redirect/drive/
# kill/print-log-on-failure shape. Has no step ID of its own -- step-06b-flow and
# step-06c-token-proof are the driver's own step IDs, folded in verbatim.
#
# Deliberately carries no `mark_done`/resume marker of its own, and this is by design, not an
# oversight -- do not "fix" it by adding one. The flow drive is the walk's actual proof: a
# marker here would let `--from-step 06` report "skipped (already done)" on a resume and
# produce a report with no flow evidence in it at all, which is exactly the silent-regression
# shape this whole harness exists to prevent.
run_step_06_boot_drive_flow() {
  if [[ "06" < "$FROM_STEP" ]]; then
    return 0
  fi

  mkdir -p "$WORKDIR"

  # PORT is passed explicitly, not left to dev.exs's compile-time port: value -- a stock
  # mix phx.new host's generated config/runtime.exs sets `http: [port: ...]` from
  # System.get_env("PORT", "4000") unconditionally (it is not gated behind config_env() ==
  # :prod), and runtime.exs is evaluated after dev.exs, so it silently wins even in MIX_ENV=dev
  # and would otherwise always bind port 4000 regardless of the walk's configured --port.
  (cd "$HOST_APP_DIR" && MIX_ENV=dev PORT="$PORT" mix phx.server) >"$SERVER_LOG" 2>&1 &
  SERVER_PID=$!

  local flow_log="$WORKDIR/flow_driver.log"

  python3 scripts/maintainer/adopter_path_flow.py \
    --base-url "$WALK_BASE_URL" \
    --mount "$MOUNT_PATH" \
    --client-id adopter-walk-public \
    --email "$LOCKSPIRE_WALK_EMAIL" \
    --password "$LOCKSPIRE_WALK_PASSWORD" \
    --protected-path /api/walk/summary \
    >"$flow_log" 2>&1
  local flow_exit=$?

  local driver_lines_found=0
  local driver_fail_count=0
  local level rest driver_step_id driver_detail

  while IFS= read -r line; do
    case "$line" in
      "[PASS] "*) level="PASS" ;;
      "[FAIL] "*) level="FAIL" ;;
      *) continue ;;
    esac

    rest="${line#\["${level}"\] }"
    driver_step_id="${rest%%:*}"
    driver_detail="${rest#*:}"
    driver_detail="${driver_detail# }"

    record_result "$level" "$driver_step_id" "$driver_detail"
    driver_lines_found=$((driver_lines_found + 1))

    if [[ "$level" == "FAIL" ]]; then
      driver_fail_count=$((driver_fail_count + 1))
    fi
  done <"$flow_log"

  if [[ "$driver_lines_found" -eq 0 ]] && [[ "$flow_exit" -ne 0 ]]; then
    # An unattributable crash: the driver exited non-zero without printing a single [PASS]/[FAIL]
    # line (e.g. an exception outside the AssertionError paths main() already catches). Record it
    # rather than silently dropping the walk's only evidence for this run (mirrors step-05-verify's
    # own "opaque crash must still yield attributable evidence" posture).
    record_result "FAIL" "step-06b-flow" "§6 prove the flow: adopter_path_flow.py exited ${flow_exit} without printing any step result line (see ${flow_log})"
    driver_fail_count=$((driver_fail_count + 1))
  fi

  if [[ "$driver_fail_count" -gt 0 ]]; then
    echo "--- ${SERVER_LOG} (flow driver reported a failure) ---"
    cat "$SERVER_LOG" 2>/dev/null || true
    echo "--- end ${SERVER_LOG} ---"
  fi

  if [[ "$KEEP" -eq 1 ]]; then
    echo "adopter-walk: --keep passed -- leaving the booted host running at ${WALK_BASE_URL}"
    echo "adopter-walk: WARNING -- port ${PORT} stays bound until you stop pid ${SERVER_PID} yourself; the next run's preflight will reject it"
    SERVER_PID=""
  else
    kill "$SERVER_PID" 2>/dev/null || true
    wait "$SERVER_PID" 2>/dev/null || true
    SERVER_PID=""
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

# Best effort, matching the same four keys as the ledger frontmatter (elixir, otp,
# postgresql, phx_new). A version probe failing must never fail the walk -- every command
# here is guarded so a missing tool just leaves its field null in the report rather than
# aborting.
collect_resolved_versions() {
  local elixir_version_output
  elixir_version_output="$(elixir --version 2>/dev/null | tail -n 1)" || true

  if [[ -n "$elixir_version_output" ]]; then
    RESOLVED_ELIXIR="$(printf '%s' "$elixir_version_output" | sed -E -e 's/^Elixir ([0-9][0-9.]*).*/\1/')"
    RESOLVED_OTP="$(printf '%s' "$elixir_version_output" | grep -oE 'Erlang/OTP [0-9]+' | sed -E -e 's#Erlang/OTP ##')"
  fi

  local psql_version_output
  psql_version_output="$(psql --version 2>/dev/null | tail -n 1)" || true

  if [[ -n "$psql_version_output" ]]; then
    RESOLVED_POSTGRESQL="$(printf '%s' "$psql_version_output" | sed -E -e 's/^psql \(PostgreSQL\) ([0-9][0-9.]*).*/\1/')"
  fi
}

# Reads RECORD_STREAM and writes REPORT_JSON via the committed Python emitter -- never
# constructs JSON in bash. Called from print_report() before its own `exit 1`, so both the
# preflight-only path and a completed run write the same report.
emit_report_json() {
  local report_dir
  report_dir="$(dirname "$REPORT_JSON")"
  mkdir -p "$report_dir"

  collect_resolved_versions

  python3 scripts/maintainer/adopter_walk_report.py \
    --records "$RECORD_STREAM" \
    --output "$REPORT_JSON" \
    --workdir "$WORKDIR" \
    --from-step "$FROM_STEP" \
    --force "$FORCE" \
    --keep "$KEEP" \
    --port "$PORT" \
    --preflight-only "$PREFLIGHT_ONLY" \
    --elixir "$RESOLVED_ELIXIR" \
    --otp "$RESOLVED_OTP" \
    --postgresql "$RESOLVED_POSTGRESQL" \
    --phx-new "$RESOLVED_PHX_NEW" \
    2>"$WORKDIR/.walk/report_emit_error.log" || echo "adopter-walk: WARNING -- failed to write ${REPORT_JSON} (see ${WORKDIR}/.walk/report_emit_error.log)" >&2
}

trap cleanup EXIT INT TERM

print_report() {
  emit_report_json

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

run_step_00b_phx_new
run_step_00c_gen_auth
run_step_00d_seed_user

run_step_01_add_dep
run_step_02_install
run_step_03a_config_import
run_step_03b_router_call
run_step_03b_router_paste
run_step_03b_router_wire
run_step_03c_resolver
run_step_03d_app_tree
run_step_03e_protected_route

run_step_04_migrate
run_step_05_verify

run_step_06a_client
run_step_06_boot_drive_flow

# Guide §7 "Upgrade only the managed scaffolding" and §8 "Finish the verification seam before
# shipping device login" are deliberately not walked -- §7 is an upgrade path rather than a
# first-install path, and §8's device /verify seam sits outside the authorization-code + PKCE
# path and out of this milestone. Recorded explicitly (D-16) so a reader can tell "out of scope"
# from "missed"; the "(not walked)" label deliberately keeps these two out of the ADOPT-03
# step-ID <-> guide-section mapping gate, and PASS never inflates FAIL_COUNT.
record_result "PASS" "step-07-upgrade (not walked)" "§7 Upgrade only the managed scaffolding: not walked -- an upgrade path for existing installs, not the first-install path this walk proves"
record_result "PASS" "step-08-verify-seam (not walked)" "§8 Finish the verification seam before shipping device login: not walked -- the device /verify seam sits outside the authorization-code + PKCE path and out of this milestone's scope"

print_report
