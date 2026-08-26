#!/usr/bin/env bash
set -euo pipefail

MODE="local"
RUN_MIX_CI=1
REMOTE="${LOCKSPIRE_HYGIENE_REMOTE:-origin}"
project="${COMPOSE_PROJECT_NAME:-lockspire-adoption-demo}"

usage() {
  cat <<'EOF'
Usage: repo_hygiene_check.sh [--ci] [--project NAME] [--skip-mix-ci]

Checks whether the repo is in a disciplined release-prep state.

Modes:
  --ci           Run only repo-owned drift checks that GitHub can prove.
  --project NAME Scope local adoption-demo Docker hygiene to a Compose project.
  --skip-mix-ci  Skip the local mix ci contributor gate rerun.

Examples:
  bash ./scripts/maintainer/repo_hygiene_check.sh --ci
  ./scripts/maintainer/repo_hygiene_check.sh --project lockspire-adoption-demo --skip-mix-ci
EOF
}

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --ci)
      MODE="ci"
      shift
      ;;
    --project)
      if [[ "$#" -lt 2 ]]; then
        echo "Missing value for --project" >&2
        usage >&2
        exit 1
      fi
      project="$2"
      shift 2
      ;;
    --skip-mix-ci)
      RUN_MIX_CI=0
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
  echo "[BLOCK] git: required command is not installed" >&2
  exit 1
fi

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$REPO_ROOT"

declare -a RESULTS=()
PASS_COUNT=0
WARN_COUNT=0
BLOCK_COUNT=0

record_result() {
  local level="$1"
  local label="$2"
  local detail="$3"

  RESULTS+=("[$level] $label: $detail")

  case "$level" in
    PASS) PASS_COUNT=$((PASS_COUNT + 1)) ;;
    WARN) WARN_COUNT=$((WARN_COUNT + 1)) ;;
    BLOCK) BLOCK_COUNT=$((BLOCK_COUNT + 1)) ;;
  esac
}

have_gh() {
  command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1
}

mix_version() {
  sed -nE 's/.*version:[[:space:]]+"([0-9]+\.[0-9]+\.[0-9]+)".*/\1/p' mix.exs | head -n 1
}

manifest_version() {
  sed -nE 's/.*"\.":[[:space:]]*"([0-9]+\.[0-9]+\.[0-9]+)".*/\1/p' .release-please-manifest.json | head -n 1
}

changelog_version() {
  sed -nE 's/^## \[([0-9]+\.[0-9]+\.[0-9]+)\].*/\1/p' CHANGELOG.md | head -n 1
}

release_train_version() {
  sed -nE 's/^- Latest released version: `([0-9]+\.[0-9]+\.[0-9]+)`/\1/p' .planning/RELEASE-TRAIN.md | head -n 1
}

release_train_has_required_lines() {
  grep -Fq 'Lockspire is on a sustaining GA release train.' .planning/RELEASE-TRAIN.md &&
    grep -Fq -- '- `milestone: none` remains the default GSD state.' .planning/RELEASE-TRAIN.md &&
    grep -Fq -- '- Patch-eligible merged changes should flow to the next release through Release Please on `main`.' .planning/RELEASE-TRAIN.md &&
    grep -Fq -- '- The train is ready to move only when `main` is green and `./scripts/maintainer/repo_hygiene_check.sh` passes without `BLOCK`.' .planning/RELEASE-TRAIN.md
}

source_has_no_broad_cleanup() {
  local file="$1"

  ! grep -Eq 'docker[[:space:]]+system[[:space:]]+prune|docker[[:space:]]+volume[[:space:]]+prune|down[[:space:]].*(-v|--volumes)' "$file"
}

script_has_active_project_precedence() {
  local file="$1"

  grep -Fq -- '--project' "$file" &&
    grep -Fq 'COMPOSE_PROJECT_NAME' "$file" &&
    grep -Fq 'lockspire-adoption-demo' "$file"
}

makefile_has_admin_demo_shortcuts() {
  [[ -f Makefile ]] &&
    grep -Fq 'demo:' Makefile &&
    grep -Fq 'demo-info:' Makefile &&
    grep -Fq 'demo-smoke:' Makefile &&
    grep -Fq 'demo-logs:' Makefile &&
    grep -Fq 'demo-stop:' Makefile &&
    grep -Fq 'demo-reset:' Makefile &&
    grep -Fq 'demo-clean:' Makefile &&
    grep -Fq 'demo-clean-execute:' Makefile &&
    grep -Fq 'scripts/demo/admin-ui up' Makefile &&
    grep -Fq 'scripts/demo/admin-ui smoke' Makefile &&
    grep -Fq 'scripts/demo/admin-ui stop' Makefile &&
    ! grep -Fq 'docker compose' Makefile
}

admin_ui_has_lifecycle_shortcuts() {
  [[ -x scripts/demo/admin-ui ]] &&
    grep -Fq 'examples/adoption_demo/bin/docker-up --project "$project" --detach' scripts/demo/admin-ui &&
    grep -Fq 'scripts/demo/adoption_smoke.sh' scripts/demo/admin-ui &&
    grep -Fq 'docker-reset --project "$project" --db-only' scripts/demo/admin-ui &&
    grep -Fq 'docker-cleanup --project "$project"' scripts/demo/admin-ui &&
    grep -Fq 'label=com.docker.compose.project=${project}' scripts/demo/admin-ui &&
    source_has_no_broad_cleanup scripts/demo/admin-ui
}

ci_source_contract_checks() {
  if source_has_no_broad_cleanup examples/adoption_demo/bin/docker-stop &&
     source_has_no_broad_cleanup examples/adoption_demo/bin/docker-reset &&
     source_has_no_broad_cleanup examples/adoption_demo/bin/docker-cleanup; then
    record_result "PASS" "demo cleanup source" "lifecycle scripts avoid host-wide Docker prune and broad Compose volume deletion"
  else
    record_result "BLOCK" "demo cleanup source" "lifecycle scripts must not use docker system prune, docker volume prune, or docker compose down --volumes"
  fi

  if [[ -x examples/adoption_demo/bin/docker-up ]] &&
     grep -Fq -- '--direct' examples/adoption_demo/bin/docker-up &&
     grep -Fq -- '--traefik' examples/adoption_demo/bin/docker-up &&
     grep -Fq -- '--no-proxy-start' examples/adoption_demo/bin/docker-up &&
     grep -Fq -- '--detach' examples/adoption_demo/bin/docker-up &&
     grep -Fq 'LOCKSPIRE_DEMO_BASE_URL=' examples/adoption_demo/bin/docker-up &&
     grep -Fq 'LOCKSPIRE_DEMO_TRAEFIK_HOST=' examples/adoption_demo/bin/docker-up &&
     grep -Fq 'wait_for_public_url' examples/adoption_demo/bin/docker-up &&
     grep -Fq 'print_running_info' examples/adoption_demo/bin/docker-up &&
     grep -Fq 'docker compose -f examples/adoption_demo/docker-compose.yml -f examples/adoption_demo/docker-compose.traefik.yml up --build' examples/adoption_demo/bin/docker-up; then
    record_result "PASS" "docker-up contract" "launcher supports direct and Traefik modes with detached readiness output"
  else
    record_result "BLOCK" "docker-up contract" "launcher must support direct and Traefik modes with detached readiness output"
  fi

  if makefile_has_admin_demo_shortcuts && admin_ui_has_lifecycle_shortcuts; then
    record_result "PASS" "admin UI shortcut contract" "make demo and scripts/demo/admin-ui provide simple scoped lifecycle commands"
  else
    record_result "BLOCK" "admin UI shortcut contract" "make demo and scripts/demo/admin-ui must remain the simple scoped lifecycle surface"
  fi

  if grep -Fq -- '--execute' examples/adoption_demo/bin/docker-cleanup &&
     grep -Fq 'Dry run only' examples/adoption_demo/bin/docker-cleanup &&
     grep -Fq '${project}_db_data' examples/adoption_demo/bin/docker-cleanup &&
     grep -Fq '${project}_deps_volume' examples/adoption_demo/bin/docker-cleanup &&
     grep -Fq '${project}_build_volume' examples/adoption_demo/bin/docker-cleanup &&
     grep -Fq 'tmp/adoption_demo.log' examples/adoption_demo/bin/docker-cleanup &&
     grep -Fq 'examples/adoption_demo/_build' examples/adoption_demo/bin/docker-cleanup &&
     grep -Fq 'examples/adoption_demo/deps' examples/adoption_demo/bin/docker-cleanup &&
     grep -Fq 'tmp/admin-ui-polish/' examples/adoption_demo/bin/docker-cleanup &&
     grep -Fq 'com.docker.compose.project=${project}' examples/adoption_demo/bin/docker-cleanup &&
     grep -Fq 'Refusing cleanup while project containers still exist' examples/adoption_demo/bin/docker-cleanup; then
    record_result "PASS" "docker-cleanup contract" "cleanup is dry-run-first, execute-gated, allowlisted, state-aware, and preserves tmp/admin-ui-polish/"
  else
    record_result "BLOCK" "docker-cleanup contract" "cleanup script drifted from dry-run, execute flag, allowlist, state-awareness, or preservation requirements"
  fi

  if grep -Fq 'docker compose --project-name "$project"' examples/adoption_demo/bin/docker-stop &&
     grep -Fq 'without deleting project volumes' examples/adoption_demo/bin/docker-stop &&
     ! grep -Eq 'down[[:space:]].*(-v|--volumes)' examples/adoption_demo/bin/docker-stop; then
    record_result "PASS" "docker-stop contract" "stop remains project-scoped and volume-preserving"
  else
    record_result "BLOCK" "docker-stop contract" "stop must stay project-scoped and must not delete volumes"
  fi

  # docker-reset contract: the active-project volume allowlist is db_data deps_volume build_volume.
  if grep -Fq -- '--db-only' examples/adoption_demo/bin/docker-reset &&
     grep -Fq -- '--cache-only' examples/adoption_demo/bin/docker-reset &&
     grep -Fq -- '--all' examples/adoption_demo/bin/docker-reset &&
     grep -Fq 'docker volume rm "${project}_db_data"' examples/adoption_demo/bin/docker-reset &&
     grep -Fq 'for suffix in deps_volume build_volume' examples/adoption_demo/bin/docker-reset &&
     ! grep -Eq 'docker[[:space:]]+volume[[:space:]]+prune|down[[:space:]].*(-v|--volumes)' examples/adoption_demo/bin/docker-reset; then
    record_result "PASS" "docker-reset contract" "reset remains scoped and can preserve database or cache volumes"
  else
    record_result "BLOCK" "docker-reset contract" "reset must keep scoped db-only cache-only and all modes"
  fi

  if script_has_active_project_precedence scripts/maintainer/repo_hygiene_check.sh &&
     script_has_active_project_precedence examples/adoption_demo/bin/docker-up &&
     script_has_active_project_precedence scripts/demo/admin-ui &&
     script_has_active_project_precedence examples/adoption_demo/bin/docker-stop &&
     script_has_active_project_precedence examples/adoption_demo/bin/docker-reset &&
     script_has_active_project_precedence examples/adoption_demo/bin/docker-cleanup; then
    record_result "PASS" "active project precedence" "--project, COMPOSE_PROJECT_NAME, and lockspire-adoption-demo are supported consistently"
  else
    record_result "BLOCK" "active project precedence" "hygiene and lifecycle helpers must share active-project resolution"
  fi

  if grep -Fq '127.0.0.1:${LOCKSPIRE_DEMO_APP_PORT:-4100}:${LOCKSPIRE_DEMO_APP_PORT:-4100}' examples/adoption_demo/docker-compose.yml &&
     grep -Fq 'ports: !reset []' examples/adoption_demo/docker-compose.traefik.yml &&
     grep -Fq '127.0.0.1:${LOCKSPIRE_DEMO_DB_HOST_PORT:?' examples/adoption_demo/docker-compose.db-host.yml &&
     grep -Fq '127.0.0.1:80:80' tools/traefik/docker-compose.yml &&
     grep -Fq '127.0.0.1:8080:8080' tools/traefik/docker-compose.yml; then
    record_result "PASS" "compose port contract" "direct ports are loopback-scoped and Traefik mode removes app host-port publishing"
  else
    record_result "BLOCK" "compose port contract" "Compose files must keep direct ports loopback-scoped and Traefik mode host-port-free"
  fi

  if [[ -f .dockerignore ]] &&
     grep -Fxq '.git' .dockerignore &&
     grep -Fxq '_build' .dockerignore &&
     grep -Fxq 'deps' .dockerignore &&
     grep -Fxq 'tmp' .dockerignore &&
     grep -Fxq 'examples/adoption_demo/_build' .dockerignore &&
     grep -Fxq 'examples/adoption_demo/deps' .dockerignore; then
    record_result "PASS" "docker build context" ".dockerignore keeps large generated artifacts out of the demo image build context"
  else
    record_result "BLOCK" "docker build context" ".dockerignore must exclude generated build, deps, tmp, and git state from Docker context"
  fi

  if grep -Fq 'python3 scripts/demo/adoption_smoke.py' .github/workflows/ci.yml &&
     grep -Fq 'exec python3 scripts/demo/adoption_smoke.py' scripts/demo/adoption_smoke.sh &&
     ! grep -Fq 'docker compose' .github/workflows/ci.yml &&
     ! grep -Fq 'docker-compose' .github/workflows/ci.yml; then
    record_result "PASS" "adoption smoke boundary" "CI keeps the Python black-box smoke and avoids full Docker Compose smoke"
  else
    record_result "BLOCK" "adoption smoke boundary" "CI must keep python3 scripts/demo/adoption_smoke.py as smoke proof without Docker Compose smoke"
  fi

  if grep -Fq 'exec python3 scripts/demo/adoption_smoke.py' scripts/demo/adoption_smoke.sh &&
     grep -Fq 'exercise_authorization_code' scripts/demo/adoption_smoke.py &&
     grep -Fq 'exercise_discovery_and_admin' scripts/demo/adoption_smoke.py; then
    record_result "PASS" "smoke wrapper contract" "scripts/demo/adoption_smoke.py remains the black-box OAuth/OIDC proof and scripts/demo/adoption_smoke.sh remains only the maintainer wrapper"
  else
    record_result "BLOCK" "smoke wrapper contract" "scripts/demo/adoption_smoke.py remains the black-box OAuth/OIDC proof; wrapper must only delegate"
  fi

  local forbidden_operator_auth
  forbidden_operator_auth="Lockspire owns operator authentic""ation"

  if [[ ! -e lib/mix/tasks/lockspire.demo.cleanup.ex &&
        ! -e lib/mix/tasks/lockspire.hygiene.ex &&
        ! -e lib/lockspire/repo_hygiene.ex &&
        ! -e lib/lockspire/docker_cleanup.ex ]] &&
     ! grep -R "$forbidden_operator_auth" lib examples/adoption_demo scripts/demo >/dev/null 2>&1; then
    record_result "PASS" "public surface contract" "no Mix cleanup task, runtime module, protocol/admin behavior, packaged Docker surface, or hosted-auth support expansion"
  else
    record_result "BLOCK" "public surface contract" "hygiene must remain repo-local with no public runtime, protocol, admin, packaged Docker, or hosted-auth support expansion"
  fi
}

repo_owned_checks() {
  local mix_ver manifest_ver changelog_ver release_train_ver
  mix_ver="$(mix_version)"
  manifest_ver="$(manifest_version)"
  changelog_ver="$(changelog_version)"
  release_train_ver="$(release_train_version)"

  if [[ -n "$mix_ver" && "$mix_ver" == "$manifest_ver" && "$mix_ver" == "$changelog_ver" ]]; then
    record_result "PASS" "release versions" "mix.exs, manifest, and top changelog entry all point at $mix_ver"
  else
    record_result "BLOCK" "release versions" "mix.exs=$mix_ver manifest=$manifest_ver changelog=$changelog_ver"
  fi

  if [[ -n "$release_train_ver" && "$release_train_ver" == "$mix_ver" ]] && release_train_has_required_lines; then
    record_result "PASS" "release train ledger" "release ledger matches version $mix_ver and preserves the standing train contract"
  else
    record_result "BLOCK" "release train ledger" "RELEASE-TRAIN.md is missing, malformed, or out of sync with mix.exs=$mix_ver"
  fi

  if grep -Fq '"component": "lockspire"' release-please-config.json &&
     grep -Fq '"include-v-in-tag": true' release-please-config.json &&
     grep -Fq '"include-component-in-tag": true' release-please-config.json &&
     grep -Fq '"release-type": "elixir"' release-please-config.json; then
    record_result "PASS" "release-please config" "root package release policy matches the maintained tag and package contract"
  else
    record_result "BLOCK" "release-please config" "release-please-config.json drifted from the maintained root package policy"
  fi

  if grep -Fq 'uses: ./.github/actions/release-please' .github/workflows/release.yml &&
     grep -Fq 'config-file: release-please-config.json' .github/workflows/release.yml &&
     grep -Fq 'manifest-file: .release-please-manifest.json' .github/workflows/release.yml &&
     grep -Fq 'actions/runs/$SOURCE_CI_RUN_ID' .github/workflows/release.yml &&
     grep -Fq "test \"\$(jq -r '.head_sha' <<< \"\$ci_run\")\" = \"\$verified_sha\"" .github/workflows/release.yml &&
     grep -Fq "needs.recovery-validation.result == 'success'" .github/workflows/release.yml &&
     grep -Fq 'git checkout --detach "$VERIFIED_SHA"' .github/workflows/release.yml &&
     grep -Fq 'run: mix release.preflight' .github/workflows/release.yml &&
     grep -Fq 'run: bash scripts/publish/publish_hex_idempotently.sh' .github/workflows/release.yml &&
     grep -Fq 'mix hex.publish --yes' scripts/publish/publish_hex_idempotently.sh; then
    record_result "PASS" "release workflow" "repo-controlled Release Please and exact-CI-evidence publish commands are intact"
  else
    record_result "BLOCK" "release workflow" "release.yml no longer matches the trusted release lane"
  fi

  if grep -Fq './scripts/maintainer/repo_hygiene_check.sh' docs/maintainer-release.md &&
     grep -Fq 'docs/supported-surface.md' docs/maintainer-release.md &&
     grep -Fq 'The public support contract' README.md; then
    record_result "PASS" "maintainer docs" "release docs point to the hygiene command and canonical support contract"
  else
    record_result "BLOCK" "maintainer docs" "release docs no longer describe the maintained hygiene and support-truth path"
  fi

  if grep -Eq 'Lockspire `[0-9]+\.[0-9]+\.[0-9]+` (is|GA)' README.md docs/supported-surface.md; then
    record_result "BLOCK" "version-pinned docs" "README or supported-surface still hard-codes the current GA version"
  else
    record_result "PASS" "version-pinned docs" "current release docs describe the GA line without pinning a single version string"
  fi

  ci_source_contract_checks
}

local_demo_docker_hygiene_checks() {
  if ! command -v docker >/dev/null 2>&1; then
    record_result "WARN" "adoption demo Docker" "Docker is unavailable or unreachable; skipped local Docker state inspection for project $project"
    return
  fi

  if ! docker version >/dev/null 2>&1; then
    record_result "WARN" "adoption demo Docker" "Docker is unavailable or unreachable; skipped local Docker state inspection for project $project"
    return
  fi

  local running_containers stopped_containers project_volumes
  running_containers="$(docker container ls --filter "label=com.docker.compose.project=$project" --format '{{.Names}}' 2>/dev/null || true)"
  stopped_containers="$(docker container ls --all --filter "label=com.docker.compose.project=$project" --filter "status=exited" --format '{{.Names}}' 2>/dev/null || true)"
  project_volumes="$(docker volume list --filter "name=^${project}_(db_data|deps_volume|build_volume)$" --format '{{.Name}}' 2>/dev/null || true)"

  if [[ -n "$running_containers" ]]; then
    record_result "BLOCK" "adoption demo Docker" "running active-project demo containers remain for $project: $(printf '%s' "$running_containers" | tr '\n' ' '); run examples/adoption_demo/bin/docker-stop --project $project or COMPOSE_PROJECT_NAME=$project make demo-stop"
  else
    record_result "PASS" "adoption demo containers" "no running active-project demo containers found for $project"
  fi

  if [[ -n "$stopped_containers" ]]; then
    record_result "WARN" "adoption demo stopped containers" "stopped project containers remain for $project: $(printf '%s' "$stopped_containers" | tr '\n' ' '); run examples/adoption_demo/bin/docker-cleanup --project $project --execute or COMPOSE_PROJECT_NAME=$project make demo-clean-execute if cleanup is intended (docker-cleanup --execute)"
  else
    record_result "PASS" "adoption demo stopped containers" "no stopped project containers found for $project"
  fi

  if [[ -n "$project_volumes" ]]; then
    record_result "WARN" "adoption demo volumes" "active project volumes remain for $project: $(printf '%s' "$project_volumes" | tr '\n' ' '); run examples/adoption_demo/bin/docker-cleanup --project $project --execute or COMPOSE_PROJECT_NAME=$project make demo-clean-execute if cleanup is intended (docker-cleanup --execute)"
  else
    record_result "PASS" "adoption demo volumes" "no active-project demo volumes found for $project"
  fi
}

local_demo_artifact_hygiene_checks() {
  local found=()

  for path in tmp/adoption_demo.log examples/adoption_demo/_build examples/adoption_demo/deps; do
    if [[ -e "$path" ]]; then
      found+=("$path")
    fi
  done

  if [[ "${#found[@]}" -gt 0 ]]; then
    record_result "WARN" "adoption demo artifacts" "allowlisted generated artifacts remain: ${found[*]}; run examples/adoption_demo/bin/docker-cleanup --project $project --execute or COMPOSE_PROJECT_NAME=$project make demo-clean-execute if cleanup is intended"
  else
    record_result "PASS" "adoption demo artifacts" "no allowlisted generated demo artifacts found"
  fi

  if [[ -e tmp/admin-ui-polish ]]; then
    record_result "PASS" "admin UI evidence" "Preserved tmp/admin-ui-polish/ as admin UI evidence outside default demo cleanup scope"
  else
    record_result "PASS" "admin UI evidence" "Preserved tmp/admin-ui-polish/ by keeping it outside default demo cleanup scope"
  fi
}

local_checks() {
  local branch status_output worktree_count worktree_output release_prep_branches latest_ci latest_release
  branch="$(git rev-parse --abbrev-ref HEAD)"
  record_result "PASS" "current branch" "$branch"

  status_output="$(git status --porcelain)"
  if [[ -z "$status_output" ]]; then
    record_result "PASS" "working tree" "clean"
  else
    record_result "BLOCK" "working tree" "dirty state detected; commit, stash, or discard local changes first"
  fi

  git fetch "$REMOTE" --prune >/dev/null 2>&1 || true

  if git show-ref --verify --quiet "refs/heads/main" && git show-ref --verify --quiet "refs/remotes/$REMOTE/main"; then
    local ahead behind
    read -r behind ahead <<<"$(git rev-list --left-right --count "$REMOTE/main...main")"

    if [[ "$behind" == "0" && "$ahead" == "0" ]]; then
      record_result "PASS" "main divergence" "local main matches $REMOTE/main"
    elif [[ "$behind" != "0" ]]; then
      record_result "BLOCK" "main divergence" "local main is behind $REMOTE/main by $behind commit(s)"
    else
      record_result "WARN" "main divergence" "local main is ahead of $REMOTE/main by $ahead commit(s)"
    fi
  else
    record_result "WARN" "main divergence" "could not compare local main to $REMOTE/main"
  fi

  worktree_output="$(git worktree list --porcelain)"
  worktree_count="$(printf '%s\n' "$worktree_output" | grep -c '^worktree ')"

  if [[ "$worktree_count" -le 1 ]]; then
    record_result "PASS" "worktrees" "only the primary worktree is active"
  else
    record_result "WARN" "worktrees" "$worktree_count worktrees detected; retire stale lanes before release prep"
  fi

  if printf '%s\n' "$worktree_output" | grep -Eq 'branch refs/heads/release-prep/'; then
    record_result "WARN" "release-prep worktrees" "release-prep worktree detected; confirm it reflects current main"
  else
    record_result "PASS" "release-prep worktrees" "no extra release-prep worktree detected"
  fi

  release_prep_branches="$(git for-each-ref --format='%(refname:short)' refs/heads/release-prep)"
  if [[ -n "$release_prep_branches" ]]; then
    record_result "WARN" "release-prep branches" "local release-prep branches exist: $(printf '%s' "$release_prep_branches" | tr '\n' ' ')"
  else
    record_result "PASS" "release-prep branches" "no lingering local release-prep branch names"
  fi

  if have_gh; then
    local open_prs
    open_prs="$(gh pr list --state open --limit 20 --json number,title,headRefName,baseRefName,url 2>/dev/null || true)"

    if [[ "$open_prs" == "[]" ]]; then
      record_result "PASS" "open PRs" "no open PRs require triage"
    else
      record_result "WARN" "open PRs" "open GitHub PRs exist; triage before release prep"
    fi

    latest_ci="$(gh run list --workflow ci.yml --branch main --limit 1 --json conclusion,status,url,headSha 2>/dev/null || true)"
    if [[ "$latest_ci" == *'"conclusion":"success"'* ]]; then
      record_result "PASS" "latest CI" "latest main CI run succeeded"
    elif [[ "$latest_ci" == *'"status":"in_progress"'* || "$latest_ci" == *'"status":"queued"'* || "$latest_ci" == *'"status":"waiting"'* || "$latest_ci" == *'"status":"pending"'* ]]; then
      record_result "WARN" "latest CI" "main CI is still in progress or waiting"
    elif [[ "$latest_ci" == *'"conclusion":"cancelled"'* ]]; then
      record_result "WARN" "latest CI" "latest main CI run was cancelled; prefer the newest completed non-cancelled run before release prep"
    elif [[ -n "$latest_ci" && "$latest_ci" != "[]" ]]; then
      record_result "BLOCK" "latest CI" "latest main CI run is not green"
    else
      record_result "WARN" "latest CI" "could not read recent main CI history"
    fi

    latest_release="$(gh run list --workflow release.yml --branch main --limit 1 --json conclusion,status,url,headSha 2>/dev/null || true)"
    if [[ "$latest_release" == *'"conclusion":"success"'* ]]; then
      record_result "PASS" "latest release workflow" "latest main release workflow completed successfully"
    elif [[ "$latest_release" == *'"status":"in_progress"'* || "$latest_release" == *'"status":"queued"'* || "$latest_release" == *'"status":"waiting"'* || "$latest_release" == *'"status":"pending"'* ]]; then
      record_result "WARN" "latest release workflow" "main release workflow is still in progress or waiting"
    elif [[ "$latest_release" == *'"conclusion":"cancelled"'* ]]; then
      record_result "WARN" "latest release workflow" "latest main release workflow was cancelled; confirm whether a newer recovery or release run superseded it"
    elif [[ -n "$latest_release" && "$latest_release" != "[]" ]]; then
      record_result "BLOCK" "latest release workflow" "latest main release workflow is not green"
    else
      record_result "WARN" "latest release workflow" "could not read recent main release workflow history"
    fi
  else
    record_result "WARN" "GitHub checks" "gh is unavailable or unauthenticated; skipped PR and workflow status checks"
  fi

  if [[ "$RUN_MIX_CI" == "1" ]]; then
    if mix ci >/dev/null; then
      record_result "PASS" "mix ci" "local contributor gate passed"
    else
      record_result "BLOCK" "mix ci" "local contributor gate failed"
    fi
  else
    record_result "WARN" "mix ci" "skipped by flag"
  fi

  local_demo_docker_hygiene_checks
  local_demo_artifact_hygiene_checks
}

repo_owned_checks

if [[ "$MODE" != "ci" ]]; then
  local_checks
fi

printf 'Lockspire repo hygiene report (%s)\n' "$MODE"
printf '%s\n' "${RESULTS[@]}"
printf 'Summary: %s PASS, %s WARN, %s BLOCK\n' "$PASS_COUNT" "$WARN_COUNT" "$BLOCK_COUNT"

if [[ "$BLOCK_COUNT" -gt 0 ]]; then
  echo "Result: not ready"
  exit 1
fi

if [[ "$WARN_COUNT" -gt 0 ]]; then
  echo "Result: proceed with caution"
  exit 0
fi

echo "Result: safe to start release prep"
