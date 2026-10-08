#!/usr/bin/env bash
set -euo pipefail

readonly freeze_name="Lockspire protected release main freeze"
readonly expected_repo="${GH_REPO:?GH_REPO is required}"

fail() {
  printf 'release main freeze: %s\n' "$1" >&2
  exit 1
}

require_admin_api() {
  : "${GH_TOKEN:?GH_TOKEN is required}"
  [[ "$expected_repo" =~ ^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$ ]] || fail "invalid GH_REPO"
}

validate_ruleset() {
  local ruleset_id="$1"
  local ruleset effective_rules

  [[ "$ruleset_id" =~ ^[0-9]+$ ]] || fail "ruleset id must be numeric"

  ruleset="$(gh api "repos/$expected_repo/rulesets/$ruleset_id?includes_parents=false")" ||
    fail "could not read the temporary freeze ruleset"

  jq -e \
    --argjson id "$ruleset_id" \
    --arg name "$freeze_name" \
    --arg repo "$expected_repo" \
    '
      .id == $id and
      .name == $name and
      .source_type == "Repository" and
      .source == $repo and
      .target == "branch" and
      .enforcement == "active" and
      .bypass_actors == [] and
      .conditions.ref_name.include == ["refs/heads/main"] and
      (.conditions.ref_name.exclude // []) == [] and
      (.rules | length) == 1 and
      .rules[0].type == "update" and
      (
        # The repository ruleset API omits the default-false parameter from
        # readback. Require false when GitHub returns the parameter, and still
        # require the active update rule and empty bypass list above.
        (.rules[0] | has("parameters") | not) or
        (.rules[0].parameters.update_allows_fetch_and_merge == false)
      )
    ' <<< "$ruleset" >/dev/null || fail "freeze ruleset is not the exact active no-bypass main update lock"

  effective_rules="$(gh api "repos/$expected_repo/rules/branches/main")" ||
    fail "could not read active rules for main"

  jq -e \
    --argjson id "$ruleset_id" \
    --arg repo "$expected_repo" \
    'any(.[];
      .type == "update" and
      .ruleset_id == $id and
      .ruleset_source_type == "Repository" and
      .ruleset_source == $repo
    )' <<< "$effective_rules" >/dev/null || fail "GitHub does not report this freeze as active on main"
}

create_freeze() {
  local rulesets existing_count payload created ruleset_id

  require_admin_api
  : "${GITHUB_OUTPUT:?GITHUB_OUTPUT is required}"

  rulesets="$(gh api --paginate --slurp "repos/$expected_repo/rulesets?per_page=100")" ||
    fail "could not list repository rulesets"
  existing_count="$(jq --arg name "$freeze_name" '[.[][]? | select(.name == $name)] | length' <<< "$rulesets")" ||
    fail "could not inspect repository rulesets"
  [[ "$existing_count" == "0" ]] || fail "a freeze with the reserved name already exists; inspect and clear stale state before retrying"

  payload="$(jq -cn \
    --arg name "$freeze_name" \
    '{
      name: $name,
      target: "branch",
      enforcement: "active",
      bypass_actors: [],
      conditions: {ref_name: {include: ["refs/heads/main"], exclude: []}},
      rules: [{type: "update", parameters: {update_allows_fetch_and_merge: false}}]
    }')"

  created="$(printf '%s' "$payload" | gh api --method POST "repos/$expected_repo/rulesets" --input -)" ||
    fail "GitHub could not create the temporary main freeze"
  ruleset_id="$(jq -er '.id | select(type == "number")' <<< "$created")" ||
    fail "GitHub created a freeze but did not return a numeric ruleset id; inspect repository rulesets before retrying"

  # Record the ID before read-back so the always-run cleanup can remove a
  # malformed or partially applied ruleset created by this job.
  printf 'ruleset_id=%s\n' "$ruleset_id" >> "$GITHUB_OUTPUT"
  validate_ruleset "$ruleset_id"
  printf 'main update freeze %s is active with no bypass actors\n' "$ruleset_id"
}

check_main_sha() {
  local authorized_sha="$1"
  local recovery_ref="$2"
  local verified_sha="$3"
  local remote_main_sha hosted_main_sha authorized_sha_from_api

  [[ "$authorized_sha" =~ ^[0-9a-f]{40}$ ]] || fail "authorized SHA must be lowercase full SHA"
  [[ "$recovery_ref" =~ ^[0-9a-f]{40}$ ]] || fail "recovery ref must be lowercase full SHA"
  [[ "$verified_sha" =~ ^[0-9a-f]{40}$ ]] || fail "verified SHA must be lowercase full SHA"

  git fetch --no-tags origin refs/heads/main || fail "could not fetch current origin/main"
  remote_main_sha="$(git rev-parse --verify 'FETCH_HEAD^{commit}')" || fail "could not resolve fetched main"
  hosted_main_sha="$(gh api "repos/$expected_repo/git/ref/heads/main" --jq '.object.sha')" ||
    fail "could not read the hosted main ref"
  authorized_sha_from_api="$(gh api "repos/$expected_repo/actions/variables/LOCKSPIRE_PHASE143_AUTHORIZED_SHA" --jq '.value')" ||
    fail "could not read the current publication authorization"

  [[ "$remote_main_sha" =~ ^[0-9a-f]{40}$ ]] || fail "fetched main did not resolve to a lowercase full SHA"
  [[ "$hosted_main_sha" =~ ^[0-9a-f]{40}$ ]] || fail "hosted main did not resolve to a lowercase full SHA"
  [[ "$authorized_sha_from_api" =~ ^[0-9a-f]{40}$ ]] || fail "hosted authorization is absent or malformed"
  [[ "$remote_main_sha" == "$hosted_main_sha" ]] || fail "origin and hosted main refs disagree"
  [[ "$remote_main_sha" == "$authorized_sha" ]] || fail "current main differs from the workflow authorization"
  [[ "$remote_main_sha" == "$authorized_sha_from_api" ]] || fail "current main differs from the hosted authorization"
  [[ "$remote_main_sha" == "$recovery_ref" ]] || fail "current main differs from the recovery ref"
  [[ "$remote_main_sha" == "$verified_sha" ]] || fail "current main differs from the verified source SHA"
}

preflight() {
  local ruleset_id="$1"
  local authorized_sha="$2"
  local recovery_ref="$3"
  local verified_sha="$4"

  require_admin_api
  validate_ruleset "$ruleset_id"
  check_main_sha "$authorized_sha" "$recovery_ref" "$verified_sha"
  # Repeat both read-backs immediately before package upload. The main freeze
  # serializes normal updates while the equality check binds all release inputs.
  validate_ruleset "$ruleset_id"
  check_main_sha "$authorized_sha" "$recovery_ref" "$verified_sha"
}

delete_freeze() {
  local ruleset_id="$1"
  local rulesets remaining

  require_admin_api
  validate_ruleset "$ruleset_id"
  gh api --method DELETE "repos/$expected_repo/rulesets/$ruleset_id" >/dev/null ||
    fail "could not remove the temporary main freeze; main remains locked until an administrator resolves it"

  rulesets="$(gh api --paginate --slurp "repos/$expected_repo/rulesets?per_page=100")" ||
    fail "could not verify freeze removal"
  remaining="$(jq --argjson id "$ruleset_id" '[.[][]? | select(.id == $id)] | length' <<< "$rulesets")" ||
    fail "could not inspect freeze removal"
  [[ "$remaining" == "0" ]] || fail "freeze still appears in repository rulesets"
  printf 'removed temporary main freeze %s\n' "$ruleset_id"
}

publish_with_freeze() {
  local ruleset_id="$1"
  local authorized_sha="$2"
  local recovery_ref="$3"
  local verified_sha="$4"
  local package_tar="$5"
  local manifest="$6"
  local hex_api_key

  hex_api_key="${HEX_API_KEY:?HEX_API_KEY is required}"
  unset HEX_API_KEY

  preflight "$ruleset_id" "$authorized_sha" "$recovery_ref" "$verified_sha"
  bash scripts/publish/release_tag_guard.sh preflight \
    "${TAG_FREEZE_RULESET_ID:?TAG_FREEZE_RULESET_ID is required}" \
    "${RELEASE_TAG:?RELEASE_TAG is required}" \
    "$verified_sha"

  # Keep the rules-management token away from the Hex publisher, and keep the
  # Hex credential away from the ruleset and GitHub API checks above.
  export HEX_API_KEY="$hex_api_key"
  unset GH_TOKEN
  bash scripts/publish/publish_hex_idempotently.sh "$package_tar" "$manifest" "$verified_sha"
}

command="${1:-}"
case "$command" in
  create)
    create_freeze
    ;;
  preflight)
    [[ "$#" == "5" ]] || fail "usage: $0 preflight RULESET_ID AUTHORIZED_SHA RECOVERY_REF VERIFIED_SHA"
    preflight "$2" "$3" "$4" "$5"
    printf 'frozen main matches the exact authorized release SHA\n'
    ;;
  publish)
    [[ "$#" == "7" ]] || fail "usage: $0 publish RULESET_ID AUTHORIZED_SHA RECOVERY_REF VERIFIED_SHA PACKAGE_TAR MANIFEST"
    publish_with_freeze "$2" "$3" "$4" "$5" "$6" "$7"
    ;;
  delete)
    [[ "$#" == "2" ]] || fail "usage: $0 delete RULESET_ID"
    delete_freeze "$2"
    ;;
  *)
    fail "expected create, preflight, publish, or delete"
    ;;
esac
