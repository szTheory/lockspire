#!/usr/bin/env bash
set -euo pipefail

readonly expected_repo="${GH_REPO:?GH_REPO is required}"
readonly server_url="${GITHUB_SERVER_URL:-https://github.com}"

fail() {
  printf 'release tag guard: %s\n' "$1" >&2
  exit 1
}

require_admin_api() {
  : "${GH_TOKEN:?GH_TOKEN is required}"
  [[ "$expected_repo" =~ ^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$ ]] || fail "invalid GH_REPO"
  [[ "$server_url" == https://* && "$server_url" != *[[:space:]]* ]] || fail "invalid GITHUB_SERVER_URL"
  command -v gh >/dev/null 2>&1 || fail "gh is required"
  command -v jq >/dev/null 2>&1 || fail "jq is required"
}

validate_tag() {
  local tag_name="$1"
  [[ -n "$tag_name" ]] || fail "tag name is required"
  git check-ref-format "refs/tags/$tag_name" || fail "tag name is invalid"
}

freeze_name() {
  printf 'Lockspire protected release tag freeze %s' "$1"
}

validate_ruleset() {
  local ruleset_id="$1"
  local tag_name="$2"
  local tag_ref="refs/tags/$tag_name"
  local name ruleset effective_rules

  [[ "$ruleset_id" =~ ^[0-9]+$ ]] || fail "ruleset id must be numeric"
  name="$(freeze_name "$tag_name")"

  ruleset="$(gh api "repos/$expected_repo/rulesets/$ruleset_id?includes_parents=false")" ||
    fail "could not read the temporary release tag freeze"

  # GitHub's repository-ruleset readback omits the default-false fetch/merge
  # parameter. Require false when the API returns it, while still requiring
  # the exact update and deletion rules, scope, and empty bypass list.
  jq -e \
    --argjson id "$ruleset_id" \
    --arg name "$name" \
    --arg repo "$expected_repo" \
    --arg tag_ref "$tag_ref" \
    '
      .id == $id and
      .name == $name and
      .source_type == "Repository" and
      .source == $repo and
      .target == "tag" and
      .enforcement == "active" and
      .bypass_actors == [] and
      .conditions.ref_name.include == [$tag_ref] and
      (.conditions.ref_name.exclude // []) == [] and
      (.rules | length) == 2 and
      any(.rules[];
        .type == "update" and
        (
          (has("parameters") | not) or
          (.parameters.update_allows_fetch_and_merge == false)
        )
      ) and
      any(.rules[]; .type == "deletion")
    ' <<< "$ruleset" >/dev/null || fail "tag freeze is not the exact active no-bypass update/deletion lock"

  effective_rules="$(gh api --paginate --slurp \
    "repos/$expected_repo/rulesets?per_page=100&includes_parents=false&targets=tag")" ||
    fail "could not read active tag rulesets"

  jq -e \
    --argjson id "$ruleset_id" \
    --arg repo "$expected_repo" \
    'any(.[][]?;
      .id == $id and
      .target == "tag" and
      .enforcement == "active" and
      .source_type == "Repository" and
      .source == $repo
    )' <<< "$effective_rules" >/dev/null || fail "GitHub does not report this freeze as active"
}

create_freeze() {
  local tag_name="$1"
  local name rulesets existing_count payload created ruleset_id

  require_admin_api
  validate_tag "$tag_name"
  : "${GITHUB_OUTPUT:?GITHUB_OUTPUT is required}"
  name="$(freeze_name "$tag_name")"

  rulesets="$(gh api --paginate --slurp "repos/$expected_repo/rulesets?per_page=100")" ||
    fail "could not list repository rulesets"
  existing_count="$(jq --arg name "$name" '[.[][]? | select(.name == $name)] | length' <<< "$rulesets")" ||
    fail "could not inspect repository rulesets"
  [[ "$existing_count" == "0" ]] ||
    fail "a tag freeze with the reserved name already exists; inspect and clear stale state before retrying"

  payload="$(jq -cn \
    --arg name "$name" \
    --arg tag_ref "refs/tags/$tag_name" \
    '{
      name: $name,
      target: "tag",
      enforcement: "active",
      bypass_actors: [],
      conditions: {ref_name: {include: [$tag_ref], exclude: []}},
      rules: [
        {type: "update", parameters: {update_allows_fetch_and_merge: false}},
        {type: "deletion"}
      ]
    }')"

  created="$(printf '%s' "$payload" | gh api --method POST \
    "repos/$expected_repo/rulesets" --input -)" ||
    fail "GitHub could not create the temporary release tag freeze"
  ruleset_id="$(jq -er '.id | select(type == "number")' <<< "$created")" ||
    fail "GitHub created a tag freeze but did not return a numeric ruleset id; inspect repository rulesets before retrying"

  # Record these before read-back so the always-run cleanup can remove any
  # malformed or partially applied rule created by this job.
  printf 'ruleset_id=%s\n' "$ruleset_id" >> "$GITHUB_OUTPUT"
  printf 'tag_name=%s\n' "$tag_name" >> "$GITHUB_OUTPUT"
  validate_ruleset "$ruleset_id" "$tag_name"
  printf 'release tag %s is protected against update and deletion\n' "$tag_name"
}

verify_tag() {
  local tag_name="$1"
  local verified_sha="$2"
  local remote_url="${server_url%/}/${expected_repo}.git"

  [[ "$verified_sha" =~ ^[0-9a-f]{40}$ ]] || fail "verified SHA must be lowercase full SHA"
  bash scripts/publish/verify_github_release_target.sh \
    "$tag_name" "$remote_url" "$verified_sha"
}

ensure_tag() {
  local ruleset_id="$1"
  local tag_name="$2"
  local verified_sha="$3"
  local ref_create_token="${REF_CREATE_TOKEN:?REF_CREATE_TOKEN is required}"
  local payload

  require_admin_api
  validate_tag "$tag_name"
  validate_ruleset "$ruleset_id" "$tag_name"
  [[ "$verified_sha" =~ ^[0-9a-f]{40}$ ]] || fail "verified SHA must be lowercase full SHA"

  payload="$(jq -cn \
    --arg ref "refs/tags/$tag_name" \
    --arg sha "$verified_sha" \
    '{ref: $ref, sha: $sha}')"

  # GitHub's create-reference endpoint is create-only. A racing ref creation
  # cannot be overwritten: the subsequent remote check must match this SHA.
  if printf '%s' "$payload" | GH_TOKEN="$ref_create_token" gh api --method POST \
    "repos/$expected_repo/git/refs" --input - >/dev/null 2>&1; then
    printf 'created release tag %s at the verified source SHA\n' "$tag_name"
  else
    printf 'create-only tag request did not create a ref; checking the exact existing target\n'
  fi

  verify_tag "$tag_name" "$verified_sha"
}

preflight() {
  local ruleset_id="$1"
  local tag_name="$2"
  local verified_sha="$3"

  require_admin_api
  validate_tag "$tag_name"
  validate_ruleset "$ruleset_id" "$tag_name"
  verify_tag "$tag_name" "$verified_sha"
  printf 'release tag %s remains protected at verified SHA %s\n' "$tag_name" "$verified_sha"
}

delete_freeze() {
  local ruleset_id="$1"
  local tag_name="$2"
  local rulesets remaining

  require_admin_api
  validate_tag "$tag_name"
  validate_ruleset "$ruleset_id" "$tag_name"
  gh api --method DELETE "repos/$expected_repo/rulesets/$ruleset_id" >/dev/null ||
    fail "could not remove the temporary tag freeze; inspect repository rulesets before retrying"

  rulesets="$(gh api --paginate --slurp "repos/$expected_repo/rulesets?per_page=100")" ||
    fail "could not verify tag freeze removal"
  remaining="$(jq --argjson id "$ruleset_id" '[.[][]? | select(.id == $id)] | length' <<< "$rulesets")" ||
    fail "could not inspect tag freeze removal"
  [[ "$remaining" == "0" ]] || fail "tag freeze still appears in repository rulesets"
  printf 'removed temporary release tag freeze %s\n' "$ruleset_id"
}

command="${1:-}"
case "$command" in
  create)
    [[ "$#" == 2 ]] || fail "usage: $0 create TAG"
    create_freeze "$2"
    ;;
  ensure)
    [[ "$#" == 4 ]] || fail "usage: $0 ensure RULESET_ID TAG VERIFIED_SHA"
    ensure_tag "$2" "$3" "$4"
    ;;
  preflight)
    [[ "$#" == 4 ]] || fail "usage: $0 preflight RULESET_ID TAG VERIFIED_SHA"
    preflight "$2" "$3" "$4"
    ;;
  delete)
    [[ "$#" == 3 ]] || fail "usage: $0 delete RULESET_ID TAG"
    delete_freeze "$2" "$3"
    ;;
  *)
    fail "expected create, ensure, preflight, or delete"
    ;;
esac
