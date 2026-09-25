#!/usr/bin/env bash
set -euo pipefail

MODE="local"
RUN_MIX_CI=1
REMOTE="${LOCKSPIRE_HYGIENE_REMOTE:-origin}"
REPOSITORY="${LOCKSPIRE_HYGIENE_REPOSITORY:-}"
project="${COMPOSE_PROJECT_NAME:-lockspire-adoption-demo}"
PROJECT_EXPLICIT=0
ACCEPT_SHA=""
WAIT_SECONDS=300
OUTPUT_FORMAT="text"

declare -a WARN_DISPOSITION_INPUTS=()
WARN_DISPOSITION_INPUT_COUNT=0

usage() {
  cat <<'EOF'
Usage: repo_hygiene_check.sh [--ci] [--project NAME] [--skip-mix-ci]
       repo_hygiene_check.sh --accept-sha SHA [--wait-seconds SECONDS]
                             [--warn-disposition LABEL=DISPOSITION] [--format json]

Checks whether the repo is in a disciplined release-prep state.

Modes:
  --ci           Run only repo-owned drift checks that GitHub can prove.
  --project NAME Scope local adoption-demo Docker hygiene to a Compose project.
  --skip-mix-ci  Skip the local mix ci contributor gate rerun.
  --accept-sha SHA
                 Prove local and GitHub acceptance for one synchronized main SHA.
  --wait-seconds SECONDS
                 Bound polling for exact workflow runs (default: 300).
  --warn-disposition LABEL=DISPOSITION
                 Record one bounded disposition for an exact-mode WARN label.
  --format json  Emit the allowlisted exact-acceptance JSON receipt.

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
      PROJECT_EXPLICIT=1
      shift 2
      ;;
    --skip-mix-ci)
      RUN_MIX_CI=0
      shift
      ;;
    --accept-sha)
      if [[ "$#" -lt 2 ]]; then
        echo "Missing value for --accept-sha" >&2
        usage >&2
        exit 1
      fi
      ACCEPT_SHA="$2"
      shift 2
      ;;
    --wait-seconds)
      if [[ "$#" -lt 2 ]]; then
        echo "Missing value for --wait-seconds" >&2
        usage >&2
        exit 1
      fi
      WAIT_SECONDS="$2"
      shift 2
      ;;
    --warn-disposition)
      if [[ "$#" -lt 2 ]]; then
        echo "Missing value for --warn-disposition" >&2
        usage >&2
        exit 1
      fi
      WARN_DISPOSITION_INPUTS+=("$2")
      WARN_DISPOSITION_INPUT_COUNT=$((WARN_DISPOSITION_INPUT_COUNT + 1))
      shift 2
      ;;
    --format)
      if [[ "$#" -lt 2 ]]; then
        echo "Missing value for --format" >&2
        usage >&2
        exit 1
      fi
      OUTPUT_FORMAT="$2"
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
  echo "[BLOCK] git: required command is not installed" >&2
  exit 1
fi

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$REPO_ROOT"

declare -a RESULTS=()
declare -a WARN_LABELS=()
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
    WARN)
      WARN_COUNT=$((WARN_COUNT + 1))
      WARN_LABELS+=("$label")
      ;;
    BLOCK) BLOCK_COUNT=$((BLOCK_COUNT + 1)) ;;
  esac
}

acceptance_block() {
  record_result "BLOCK" "$1" "$2"
  return 1
}

validate_acceptance_sha() {
  if [[ ! "$ACCEPT_SHA" =~ ^[0-9a-f]{40}$ ]]; then
    acceptance_block "acceptance SHA" "must be one lowercase full 40-hex commit identity"
    return
  fi

  if [[ "$MODE" != "local" || "$RUN_MIX_CI" != "1" || "$OUTPUT_FORMAT" != "json" || "$PROJECT_EXPLICIT" != "0" ]]; then
    acceptance_block "acceptance invocation" "exact acceptance requires local mode, mix ci, and --format json"
    return
  fi

  if [[ ! "$WAIT_SECONDS" =~ ^[0-9]+$ ]] || ((10#$WAIT_SECONDS > 3600)); then
    acceptance_block "acceptance wait" "wait seconds must be an integer between 0 and 3600"
    return
  fi

  if [[ -z "$REPOSITORY" ]]; then
    if ! REPOSITORY="$(gh repo view --json nameWithOwner --jq '.nameWithOwner' 2>/dev/null)"; then
      acceptance_block "acceptance repository" "repository identity could not be resolved"
      return
    fi
  fi

  if [[ ! "$REPOSITORY" =~ ^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$ ]]; then
    acceptance_block "acceptance repository" "repository identity is malformed"
    return
  fi
}

validate_acceptance_identity() {
  local head main remote_main

  if ! git fetch "$REMOTE" --prune >/dev/null 2>&1; then
    acceptance_block "acceptance identity" "remote main refresh failed"
    return
  fi

  if ! head="$(git rev-parse HEAD 2>/dev/null)" ||
     ! main="$(git rev-parse main 2>/dev/null)" ||
     ! remote_main="$(git rev-parse "$REMOTE/main" 2>/dev/null)"; then
    acceptance_block "acceptance identity" "HEAD, local main, and remote main must all resolve"
    return
  fi

  if [[ "$head" != "$ACCEPT_SHA" || "$main" != "$ACCEPT_SHA" || "$remote_main" != "$ACCEPT_SHA" ]]; then
    acceptance_block "acceptance identity" "HEAD, local main, and remote main must equal the acceptance SHA"
    return
  fi
}

run_exact_local_gate() {
  local before_sha after_sha checkout_status test_count

  if ! checkout_status="$(git status --porcelain 2>/dev/null)"; then
    acceptance_block "acceptance checkout" "working tree status could not be observed"
    return
  fi

  if [[ -n "$checkout_status" ]]; then
    acceptance_block "acceptance checkout" "working tree must be clean"
    return
  fi

  before_sha="$(git rev-parse HEAD 2>/dev/null || true)"
  if ! test_count="$(
    output_file="$(mktemp "${TMPDIR:-/tmp}/lockspire-mix-ci.XXXXXX")" || exit 1
    trap 'rm -f -- "$output_file"' EXIT
    trap 'exit 129' HUP
    trap 'exit 130' INT
    trap 'exit 143' TERM
    mix ci >"$output_file" 2>&1 || exit 1
    sed -nE 's/.*(^|[^0-9])([0-9]+) tests?, [0-9]+ failures?.*/\2/p' "$output_file" | tail -n 1
  )"; then
    acceptance_block "local gate" "mix ci returned nonzero"
    return
  fi

  if [[ -z "$test_count" || "$test_count" == "0" ]]; then
    acceptance_block "local gate" "mix ci did not prove that ExUnit executed tests"
    return
  fi

  after_sha="$(git rev-parse HEAD 2>/dev/null || true)"
  if [[ "$before_sha" != "$ACCEPT_SHA" || "$after_sha" != "$ACCEPT_SHA" ]]; then
    acceptance_block "local gate" "HEAD changed while mix ci ran"
    return
  fi

  LOCAL_TEST_COUNT="$test_count"
  record_result "PASS" "local gate" "mix ci passed with executed ExUnit tests at the acceptance SHA"
}

exact_demo_docker_hygiene_checks() {
  local running_containers stopped_containers project_volumes

  if ! command -v docker >/dev/null 2>&1 || ! docker version >/dev/null 2>&1; then
    record_result "WARN" "adoption demo Docker" "Docker state could not be observed"
    return
  fi

  if ! running_containers="$(docker container ls --filter "label=com.docker.compose.project=$project" --format '{{.Names}}' 2>/dev/null)" ||
     ! stopped_containers="$(docker container ls --all --filter "label=com.docker.compose.project=$project" --filter "status=exited" --format '{{.Names}}' 2>/dev/null)" ||
     ! project_volumes="$(docker volume list --filter "name=^${project}_(db_data|deps_volume|build_volume)$" --format '{{.Name}}' 2>/dev/null)"; then
    acceptance_block "adoption demo Docker" "Docker state observation failed"
    return
  fi

  if [[ -n "$running_containers" ]]; then
    record_result "BLOCK" "adoption demo containers" "active-project containers are running"
  else
    record_result "PASS" "adoption demo containers" "no active-project containers are running"
  fi

  if [[ -n "$stopped_containers" ]]; then
    record_result "WARN" "adoption demo stopped containers" "stopped active-project containers remain"
  else
    record_result "PASS" "adoption demo stopped containers" "no stopped active-project containers remain"
  fi

  if [[ -n "$project_volumes" ]]; then
    record_result "WARN" "adoption demo volumes" "active-project volumes remain"
  else
    record_result "PASS" "adoption demo volumes" "no active-project volumes remain"
  fi
}

collect_exact_workflow_run() {
  local workflow="$1" selected_id="" response candidate_count candidate_id candidate_status endpoint deadline
  endpoint="repos/$REPOSITORY/actions/workflows/$workflow/runs?branch=main&event=push&head_sha=$ACCEPT_SHA&per_page=100"
  deadline=$((SECONDS + 10#$WAIT_SECONDS))

  while :; do
    if ! response="$(gh api "$endpoint" 2>/dev/null)" ||
       ! jq -e '.workflow_runs | type == "array"' >/dev/null 2>&1 <<<"$response"; then
      acceptance_block "workflow evidence" "workflow run response was unavailable or malformed"
      return
    fi

    candidate_count="$(jq -r '.workflow_runs | length' <<<"$response")"
    if [[ "$candidate_count" != "1" ]]; then
      acceptance_block "workflow evidence" "exact workflow candidate set must contain exactly one run"
      return
    fi

    candidate_id="$(jq -r '.workflow_runs[0].id // empty' <<<"$response")"
    if [[ ! "$candidate_id" =~ ^[0-9]+$ ]]; then
      acceptance_block "workflow evidence" "workflow run identity was missing or malformed"
      return
    fi

    if [[ -n "$selected_id" && "$candidate_id" != "$selected_id" ]]; then
      acceptance_block "workflow evidence" "workflow run identity changed during polling"
      return
    fi
    selected_id="$candidate_id"
    candidate_status="$(jq -r '.workflow_runs[0].status // empty' <<<"$response")"

    if [[ "$candidate_status" == "completed" ]]; then
      COLLECTED_RUN="$(jq -c '.workflow_runs[0]' <<<"$response")"
      return 0
    fi

    case "$candidate_status" in
      queued | in_progress | waiting | pending | requested) ;;
      *)
        acceptance_block "workflow evidence" "workflow run status was missing or invalid"
        return
        ;;
    esac

    if ((SECONDS >= deadline)); then
      acceptance_block "workflow evidence" "bounded workflow polling expired before completion"
      return
    fi
    sleep 1
  done
}

validate_workflow_run() {
  local run="$1" expected_id="$2" expected_name="$3" expected_path="$4"

  if ! jq -e \
    --argjson workflow_id "$expected_id" \
    --arg name "$expected_name" \
    --arg path "$expected_path" \
    --arg repository "$REPOSITORY" \
    --arg sha "$ACCEPT_SHA" '
      (.id | type) == "number" and .id > 0 and
      .name == $name and .path == $path and .workflow_id == $workflow_id and
      .repository.full_name == $repository and .event == "push" and
      .head_branch == "main" and .status == "completed" and
      .conclusion == "success" and .head_sha == $sha and
      (.html_url | type == "string" and startswith("https://"))
    ' >/dev/null 2>&1 <<<"$run"; then
    acceptance_block "workflow identity" "workflow metadata did not match the exact acceptance contract"
    return
  fi
}

collect_run_jobs() {
  local run_id="$1" page=1 response response_total page_count collected_count=0
  local expected_total="" jobs='[]'

  while :; do
    if ! response="$(gh api "repos/$REPOSITORY/actions/runs/$run_id/jobs?per_page=100&page=$page" 2>/dev/null)" ||
       ! jq -e '
         (.total_count | type) == "number" and .total_count >= 0 and
         (.jobs | type) == "array" and
         all(.jobs[]; (.name | type) == "string" and (.status | type) == "string" and (.conclusion | type) == "string")
       ' >/dev/null 2>&1 <<<"$response"; then
      acceptance_block "workflow jobs" "workflow job page was unavailable, malformed, or incomplete"
      return
    fi

    response_total="$(jq -r '.total_count' <<<"$response")"
    if [[ -z "$expected_total" ]]; then
      expected_total="$response_total"
    elif [[ "$response_total" != "$expected_total" ]]; then
      acceptance_block "workflow jobs" "workflow job total changed during pagination"
      return
    fi

    page_count="$(jq -r '.jobs | length' <<<"$response")"
    jobs="$(jq -cn --argjson current "$jobs" --argjson page "$(jq -c '.jobs' <<<"$response")" '$current + $page')"
    collected_count=$((collected_count + page_count))

    if ((collected_count == expected_total)); then
      COLLECTED_JOBS="$jobs"
      return 0
    fi
    if ((collected_count > expected_total || page_count == 0)); then
      acceptance_block "workflow jobs" "workflow job pagination did not match its declared total"
      return
    fi
    page=$((page + 1))
  done
}

validate_required_ci_run() {
  local workflow_meta workflow_id

  if ! workflow_meta="$(gh api "repos/$REPOSITORY/actions/workflows/ci.yml" 2>/dev/null)" ||
     ! workflow_id="$(jq -er '.id | select(type == "number" and . > 0)' <<<"$workflow_meta" 2>/dev/null)"; then
    acceptance_block "required CI" "canonical CI workflow identity was unavailable or malformed"
    return
  fi

  if ! collect_exact_workflow_run "ci.yml" ||
     ! validate_workflow_run "$COLLECTED_RUN" "$workflow_id" "CI" ".github/workflows/ci.yml"; then
    return 1
  fi

  REQUIRED_CI_RUN="$COLLECTED_RUN"
}

validate_required_ci_jobs() {
  local run_id required count
  run_id="$(jq -r '.id' <<<"$REQUIRED_CI_RUN")"
  if ! collect_run_jobs "$run_id"; then
    return 1
  fi

  for required in \
    "Dialyzer" \
    "Release Hygiene Drift" \
    "Fast Checks" \
    "Minimum Supported Elixir/OTP" \
    "Integration Checks" \
    "Complete Coverage Evidence" \
    "Adoption Demo Smoke"; do
    count="$(jq -r --arg name "$required" '[.[] | select(.name == $name and .status == "completed" and .conclusion == "success")] | length' <<<"$COLLECTED_JOBS")"
    if [[ "$count" != "1" ]]; then
      acceptance_block "required CI jobs" "required CI job graph was missing, duplicated, or unsuccessful"
      return
    fi
  done

  if [[ "$(jq -r 'length' <<<"$COLLECTED_JOBS")" != "7" ]]; then
    acceptance_block "required CI jobs" "required CI job graph contained unexpected jobs"
    return
  fi

  REQUIRED_CI_JOBS="$(jq -c 'map({name, status, conclusion}) | sort_by(.name)' <<<"$COLLECTED_JOBS")"
  record_result "PASS" "required CI" "canonical CI and every required job passed at the acceptance SHA"
}

validate_no_publish_release_run() {
  local workflow_meta workflow_id run_id name expected count

  if ! workflow_meta="$(gh api "repos/$REPOSITORY/actions/workflows/release.yml" 2>/dev/null)" ||
     ! workflow_id="$(jq -er '.id | select(type == "number" and . > 0)' <<<"$workflow_meta" 2>/dev/null)"; then
    acceptance_block "release no-publish" "Release workflow identity was unavailable or malformed"
    return
  fi

  if ! collect_exact_workflow_run "release.yml" ||
     ! validate_workflow_run "$COLLECTED_RUN" "$workflow_id" "Release" ".github/workflows/release.yml"; then
    return 1
  fi
  RELEASE_RUN="$COLLECTED_RUN"
  run_id="$(jq -r '.id' <<<"$RELEASE_RUN")"
  if ! collect_run_jobs "$run_id"; then
    return 1
  fi
  RELEASE_JOBS="$(jq -c 'map({name, status, conclusion}) | sort_by(.name)' <<<"$COLLECTED_JOBS")"

  while IFS='|' read -r name expected; do
    count="$(jq -r --arg name "$name" --arg conclusion "$expected" '[.[] | select(.name == $name and .status == "completed" and .conclusion == $conclusion)] | length' <<<"$RELEASE_JOBS")"
    if [[ "$count" != "1" ]]; then
      acceptance_block "release no-publish" "Release job graph did not prove the intentional no-publish shape"
      return
    fi
  done <<'EOF'
Maintain Release Please PR|success
Validate exact main head and CI evidence|skipped
Prove exact package before publication|skipped
Publish verified release to Hex|skipped
Verify public install truth|skipped
EOF

  if [[ "$(jq -r 'length' <<<"$RELEASE_JOBS")" != "5" ]]; then
    acceptance_block "release no-publish" "Release job graph contained unexpected jobs"
    return
  fi

  record_result "PASS" "release no-publish" "push Release succeeded with every protected publication job skipped"
}

require_warn_dispositions() {
  local input label disposition known warn_label seen_label seen_index
  local seen_count=0
  local dispositions='[]'
  local -a seen_labels=()
  local -a seen_dispositions=()

  if [[ "$WARN_DISPOSITION_INPUT_COUNT" -gt 0 ]]; then
    for input in "${WARN_DISPOSITION_INPUTS[@]}"; do
      if [[ "$input" != *=* ]]; then
        acceptance_block "WARN dispositions" "every disposition must use LABEL=DISPOSITION"
        return
      fi
      label="${input%%=*}"
      disposition="${input#*=}"
      if [[ -z "$label" || ! "$disposition" =~ ^[a-z0-9][a-z0-9._-]{0,63}$ ]]; then
        acceptance_block "WARN dispositions" "labels and dispositions must be nonempty and disposition values must use the bounded token format"
        return
      fi
      known=0
      for warn_label in "${WARN_LABELS[@]+"${WARN_LABELS[@]}"}"; do
        [[ "$label" == "$warn_label" ]] && known=1
      done
      if [[ "$known" != "1" ]]; then
        acceptance_block "WARN dispositions" "unknown WARN disposition label was supplied"
        return
      fi

      if [[ "$seen_count" -gt 0 ]]; then
        for seen_label in "${seen_labels[@]}"; do
          if [[ "$label" == "$seen_label" ]]; then
            acceptance_block "WARN dispositions" "duplicate WARN disposition labels are not accepted"
            return
          fi
        done
      fi

      seen_labels+=("$label")
      seen_dispositions+=("$disposition")
      seen_count=$((seen_count + 1))
    done
  fi

  for warn_label in "${WARN_LABELS[@]+"${WARN_LABELS[@]}"}"; do
    known=0
    if [[ "$seen_count" -gt 0 ]]; then
      for seen_label in "${seen_labels[@]}"; do
        [[ "$warn_label" == "$seen_label" ]] && known=1
      done
    fi
    if [[ "$known" != "1" ]]; then
      acceptance_block "WARN dispositions" "every WARN requires exactly one disposition"
      return
    fi
  done

  if [[ "$seen_count" -gt 0 ]]; then
    while IFS=$'\t' read -r label seen_index; do
      [[ -z "$label" ]] && continue
      dispositions="$(jq -cn --argjson current "$dispositions" --arg label "$label" --arg disposition "${seen_dispositions[$seen_index]}" '$current + [{label:$label, disposition:$disposition}]')"
    done < <(
      for seen_index in "${!seen_labels[@]}"; do
        printf '%s\t%s\n' "${seen_labels[$seen_index]}" "$seen_index"
      done | LC_ALL=C sort
    )
  fi

  WARN_DISPOSITIONS_JSON="$dispositions"
}

emit_acceptance_receipt() {
  local ci_id ci_url release_id release_url
  ci_id="$(jq -r '.id' <<<"$REQUIRED_CI_RUN")"
  ci_url="$(jq -r '.html_url' <<<"$REQUIRED_CI_RUN")"
  release_id="$(jq -r '.id' <<<"$RELEASE_RUN")"
  release_url="$(jq -r '.html_url' <<<"$RELEASE_RUN")"

  jq -cn \
    --arg schema "lockspire-phase-139-acceptance-v1" \
    --arg baseline_sha "$ACCEPT_SHA" \
    --argjson tests "$LOCAL_TEST_COUNT" \
    --argjson pass "$PASS_COUNT" \
    --argjson warn "$WARN_COUNT" \
    --argjson block "$BLOCK_COUNT" \
    --argjson ci_id "$ci_id" \
    --arg ci_url "$ci_url" \
    --argjson ci_jobs "$REQUIRED_CI_JOBS" \
    --argjson release_id "$release_id" \
    --arg release_url "$release_url" \
    --argjson release_jobs "$RELEASE_JOBS" \
    --argjson dispositions "$WARN_DISPOSITIONS_JSON" '
      {
        schema: $schema,
        baseline_sha: $baseline_sha,
        local_gate: {status: "pass", exunit_tests: $tests},
        hygiene: {status: "pass", pass: $pass, warn: $warn, block: $block},
        required_ci: {status: "pass", run_id: $ci_id, event: "push", conclusion: "success", url: $ci_url, jobs: $ci_jobs},
        release_no_publish: {status: "pass", outcome: "no_publish", run_id: $release_id, event: "push", conclusion: "success", url: $release_url, jobs: $release_jobs},
        warn_dispositions: $dispositions,
        supplemental_oidf: {classification: "supplemental_non_certifying", required_gate: false}
      }
    '
}

run_exact_acceptance() {
  local command
  for command in gh jq mix; do
    if ! command -v "$command" >/dev/null 2>&1; then
      acceptance_block "acceptance tools" "a required exact-acceptance command is unavailable"
      return
    fi
  done

  if ! validate_acceptance_sha ||
     ! validate_acceptance_identity ||
     ! run_exact_local_gate ||
     ! validate_acceptance_identity ||
     ! validate_required_ci_run ||
     ! validate_required_ci_jobs ||
     ! validate_acceptance_identity ||
     ! validate_no_publish_release_run ||
     ! validate_acceptance_identity; then
    return 1
  fi

  exact_demo_docker_hygiene_checks

  if [[ "$BLOCK_COUNT" -gt 0 ]]; then
    return 1
  fi

  if ! require_warn_dispositions; then
    return 1
  fi

  validate_acceptance_identity || return 1
  emit_acceptance_receipt
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
  # Trailing content is tolerated so the line can carry Release Please's
  # `x-release-please-version` marker. Without `.*` the marker would be left in
  # the captured value and every comparison against mix.exs would fail.
  sed -nE 's/^- Latest released version: `([0-9]+\.[0-9]+\.[0-9]+)`.*/\1/p' .planning/RELEASE-TRAIN.md | head -n 1
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
     grep -Fq 'mix release.preflight' .github/workflows/release.yml &&
     grep -Fq 'bash scripts/publish/publish_hex_idempotently.sh' .github/workflows/release.yml &&
     grep -Fq 'upload_hex_artifact.exs "$package_tar"' scripts/publish/publish_hex_idempotently.sh &&
     grep -Fq 'Hex.API.Release.publish("hexpm", bytes' scripts/publish/upload_hex_artifact.exs; then
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

if [[ -n "$ACCEPT_SHA" ]]; then
  if [[ "$BLOCK_COUNT" -eq 0 ]] && run_exact_acceptance; then
    exit 0
  fi

  printf 'Lockspire repo hygiene report (exact acceptance)\n'
  printf '%s\n' "${RESULTS[@]}"
  printf 'Summary: %s PASS, %s WARN, %s BLOCK\n' "$PASS_COUNT" "$WARN_COUNT" "$BLOCK_COUNT"
  echo "Result: not ready"
  exit 1
fi

if [[ "$OUTPUT_FORMAT" != "text" || "$WAIT_SECONDS" != "300" || "$WARN_DISPOSITION_INPUT_COUNT" -gt 0 ]]; then
  echo "Exact-acceptance options require --accept-sha" >&2
  exit 1
fi

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
