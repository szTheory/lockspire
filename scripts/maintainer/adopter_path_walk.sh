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

# Extracts the body of priv/templates/lockspire.install/router.ex's `lockspire_routes/0` heredoc
# from the already-rendered generated file -- the literal text a human reader would paste, per
# RESEARCH Pitfall 4. The template renders the body between two lines that are exactly four
# spaces of indentation followed by a bare `"""`.
extract_lockspire_routes_body() {
  local generated_helper="$1"

  awk '
    /^    """$/ {
      marker_count++
      next
    }
    marker_count == 1 { print }
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

  if [[ "$installer_version" != "Phoenix installer v1.8.9" ]]; then
    fail_prerequisite "phx_new" "expected 'Phoenix installer v1.8.9', resolved '${installer_version}'"
  fi

  if [[ -e "$HOST_APP_DIR" ]]; then
    record_result "FAIL" "$step_id" "refusing to regenerate: ${HOST_APP_DIR} already exists without a resume marker (pass --force to override)"
    return
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
    sed_i -e "s/secret_key_base: \"[^\"]*\"/secret_key_base: \"${secret}\"/" "$dev_config"
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

  local seed_script
  seed_script="$(
    cat <<'ELIXIR'
email = System.fetch_env!("LOCKSPIRE_WALK_EMAIL")
password = System.fetch_env!("LOCKSPIRE_WALK_PASSWORD")

{:ok, user} = HostApp.Accounts.register_user(%{email: email})
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
# rather than the branch Phases 127-129 are repairing.
run_step_01_add_dep() {
  should_run "step-01-add-dep" || return 0

  local mix_exs="$HOST_APP_DIR/mix.exs"

  if ! grep -Fq ':lockspire, path:' "$mix_exs"; then
    sed_i -e "s#{:phoenix,#{:lockspire, path: \"${REPO_ROOT}\"},\n      {:phoenix,#" "$mix_exs"
  fi

  local add_dep_log="$WORKDIR/step_01_add_dep.log"

  if ! (cd "$HOST_APP_DIR" && mix deps.get) >"$add_dep_log" 2>&1; then
    local error_detail
    error_detail="$(head -n 1 "$add_dep_log")"
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

  record_result "PASS" "step-02-install" "§2 Generate the host seam: mix lockspire.install exited 0 and wrote .lockspire/install_manifest.json"
  mark_done "step-02-install"
}

# step-03a-config-import: guide §3 "Wire the generated files" (first instruction) --
# import_config "lockspire.exs" from the host's main config entrypoint. The installer's own
# config template emits a placeholder issuer and omits known_scopes, signing_alg,
# secret_key_base, and oban: (D-45); this step records that gap and then applies the smallest
# completion needed to keep walking, so later steps have a config that can actually boot.
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
  local key

  for key in known_scopes signing_alg secret_key_base oban:; do
    if ! grep -Fq "$key" "$lockspire_config"; then
      missing_keys+=("$key")
    fi
  done

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
  record_result "FAIL" "step-03a-config-import" "§3 Wire the generated files: config/lockspire.exs omits ${missing_list} and issuer is a placeholder -- imported config is not sufficient to boot (ADOPT-D04)"

  if ! grep -Fq 'known_scopes' "$lockspire_config"; then
    local lockspire_secret
    lockspire_secret="$(cd "$HOST_APP_DIR" && mix phx.gen.secret 2>/dev/null | tail -n 1)"

    if [[ -z "$lockspire_secret" ]]; then
      lockspire_secret="$(date +%s%N)-lockspire-walk-fallback-secret"
    fi

    # LOCKSPIRE_WALK_WORKAROUND: ADOPT-D04
    # The installer's config template emits a placeholder issuer and omits known_scopes,
    # signing_alg, secret_key_base, and oban:, all of which
    # examples/adoption_demo/config/config.exs:62-77 proves are required. Apply the smallest
    # completion that lets the walk keep moving -- never copy the committed demo secret_key_base
    # literal (T-126-04); generate a fresh one the same way step-00b-phx-new does.
    sed_i -e "s#issuer: \"https://example.com\"#issuer: \"${WALK_BASE_URL}${MOUNT_PATH}\"#" "$lockspire_config"
    sed_i -E -e "s#oban_prefix: \"[^\"]*\"#&,\n  known_scopes: [\"openid\", \"email\", \"profile\", \"read:billing\", \"write:reports\"],\n  signing_alg: \"RS256\",\n  secret_key_base: \"${lockspire_secret}\",\n  oban: [queues: false, plugins: false]#" "$lockspire_config"
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

  if grep -Fq "${MOUNT_PATH}" "$routes_log"; then
    record_result "PASS" "step-03b-router-call" "§3 Wire the generated files: calling lockspire_routes() as documented defines the Lockspire mount"
    mark_done "step-03b-router-call"
    return
  fi

  record_result "FAIL" "step-03b-router-call" "§3 Wire the generated files: calling lockspire_routes() as documented compiles clean, zero routes defined (ADOPT-D01 -- the generated helper returns a String, not a quoted macro)"
  mark_done "step-03b-router-call"
}

# step-03b-router-paste: guide §3 "Wire the generated files" -- apply the other documented
# reading a human would take: paste the heredoc's own contents into the host router. The pasted
# body's admin scope references a :require_operator pipeline no stock router defines, so this is
# expected to fail compilation with that exact error (RESEARCH Pitfall 4). This sub-step
# deliberately leaves the host non-compiling, so it restores the router before returning --
# step-03b-router-wire must start from a known point.
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

  local pasted_body
  pasted_body="$(extract_lockspire_routes_body "$generated_helper")"
  insert_before_final_module_end "$host_router" "$pasted_body"

  local compile_log="$WORKDIR/step_03b_router_paste.log"

  if (cd "$HOST_APP_DIR" && mix compile) >"$compile_log" 2>&1; then
    record_result "FAIL" "step-03b-router-paste" "§3 Wire the generated files: pasting lockspire_routes()'s body compiled unexpectedly -- expected the undefined :require_operator pipeline to fail compilation"
  else
    local error_detail
    error_detail="$(grep -m 1 -i 'pipeline' "$compile_log")"

    if [[ -z "$error_detail" ]]; then
      error_detail="$(head -n 1 "$compile_log")"
    fi

    record_result "FAIL" "step-03b-router-paste" "§3 Wire the generated files: pasting lockspire_routes()'s body fails to compile (${error_detail}) (ADOPT-D02 -- :require_operator is not defined in a stock host router)"
  fi

  cp "$backup" "$host_router"
  mark_done "step-03b-router-paste"
}

# step-03b-router-wire: guide §3 "Wire the generated files" -- apply the smallest real wiring
# that lets the walk reach step-04: define a stand-in :require_operator pipeline (ADOPT-D02's
# workaround) and route the session-/CSRF-dependent interaction routes and the consent LiveView
# through the host's :browser pipeline before the general forward (ADOPT-D03's workaround),
# following examples/adoption_demo/lib/adoption_demo_web/router.ex:53-59, the only place in the
# repo that gets this right.
run_step_03b_router_wire() {
  should_run "step-03b-router-wire" || return 0

  local host_router="$HOST_APP_DIR/lib/host_app_web/router.ex"
  local generated_helper="$HOST_APP_DIR/lib/host_app_web/router/lockspire.ex"

  if [[ ! -f "$generated_helper" ]]; then
    record_result "FAIL" "step-03b-router-wire" "§3 Wire the generated files: lib/host_app_web/router/lockspire.ex is missing (step-02-install did not complete)"
    return
  fi

  if ! grep -Fq 'pipeline :require_operator do' "$host_router"; then
    # LOCKSPIRE_WALK_WORKAROUND: ADOPT-D02
    # priv/templates/lockspire.install/router.ex references a :require_operator pipeline that no
    # stock mix phx.new router defines. The stand-in exists only in this throwaway generated
    # host, guards no real staff surface, and Phase 127 must remove the need for it.
    insert_before_final_module_end "$host_router" "$(printf '  pipeline :require_operator do\n  end')"
  fi

  if ! grep -Fq 'Lockspire.Web.AdminRouter' "$host_router"; then
    # LOCKSPIRE_WALK_WORKAROUND: ADOPT-D03
    # priv/templates/lockspire.install/router.ex forwards the mount path in a pipeline-less
    # scope, so the session- and CSRF-dependent interaction routes and the consent LiveView get
    # no fetch_session and no protect_from_forgery. Route them through the host's :browser
    # pipeline before the general forward, following
    # examples/adoption_demo/lib/adoption_demo_web/router.ex:53-59.
    local wired_body
    wired_body="$(
      printf '  scope "%s/admin" do\n    pipe_through [:browser, :require_operator]\n    forward "/", Lockspire.Web.AdminRouter\n  end\n\n  scope "%s" do\n    pipe_through [:browser]\n\n    get "/interactions/:interaction_id", Lockspire.Web.InteractionController, :show\n    post "/interactions/:interaction_id/complete", Lockspire.Web.InteractionController, :complete\n    live "/consent/:interaction_id", Lockspire.Web.ConsentLive, :show\n  end\n\n  scope "/" do\n    forward "%s", Lockspire.Web.Router\n  end' \
        "$MOUNT_PATH" "$MOUNT_PATH" "$MOUNT_PATH"
    )"
    insert_before_final_module_end "$host_router" "$wired_body"
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

  if ! grep -Fq "${MOUNT_PATH}" "$routes_log"; then
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

  record_result "PASS" "step-03b-router-wire" "§3 Wire the generated files: Lockspire mount, interaction routes, and consent LiveView route are all defined"
  mark_done "step-03b-router-wire"
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

run_step_00b_phx_new
run_step_00c_gen_auth
run_step_00d_seed_user

run_step_01_add_dep
run_step_02_install
run_step_03a_config_import
run_step_03b_router_call
run_step_03b_router_paste
run_step_03b_router_wire

# Guide steps step-04 onward are added by later plans in this phase; the
# skeleton and pre-guide steps above are what they plug into via
# should_run/record_result/mark_done.

print_report
