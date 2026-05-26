#!/usr/bin/env bash
set -euo pipefail

MODE="local"
RUN_MIX_CI=1
REMOTE="${LOCKSPIRE_HYGIENE_REMOTE:-origin}"

usage() {
  cat <<'EOF'
Usage: repo_hygiene_check.sh [--ci] [--skip-mix-ci]

Checks whether the repo is in a disciplined release-prep state.

Modes:
  --ci           Run only repo-owned drift checks that GitHub can prove.
  --skip-mix-ci  Skip the local mix ci contributor gate rerun.
EOF
}

for arg in "$@"; do
  case "$arg" in
    --ci)
      MODE="ci"
      ;;
    --skip-mix-ci)
      RUN_MIX_CI=0
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $arg" >&2
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

repo_owned_checks() {
  local mix_ver manifest_ver changelog_ver
  mix_ver="$(mix_version)"
  manifest_ver="$(manifest_version)"
  changelog_ver="$(changelog_version)"

  if [[ -n "$mix_ver" && "$mix_ver" == "$manifest_ver" && "$mix_ver" == "$changelog_ver" ]]; then
    record_result "PASS" "release versions" "mix.exs, manifest, and top changelog entry all point at $mix_ver"
  else
    record_result "BLOCK" "release versions" "mix.exs=$mix_ver manifest=$manifest_ver changelog=$changelog_ver"
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
     grep -Fq 'run: mix release.preflight' .github/workflows/release.yml &&
     grep -Fq 'run: mix hex.publish --yes' .github/workflows/release.yml; then
    record_result "PASS" "release workflow" "repo-controlled Release Please and protected publish commands are intact"
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
