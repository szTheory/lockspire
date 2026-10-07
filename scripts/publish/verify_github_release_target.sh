#!/usr/bin/env bash
set -euo pipefail

fail() {
  printf 'GitHub release target verification: %s\n' "$1" >&2
  exit 1
}

if [[ "$#" != 3 ]]; then
  fail "usage: $0 TAG REMOTE_URL VERIFIED_SHA"
fi

tag_name="$1"
remote_url="$2"
verified_sha="$3"

[[ -n "$tag_name" ]] || fail "tag name is required"
[[ "$remote_url" != -* && -n "$remote_url" ]] || fail "remote URL is invalid"
[[ "$verified_sha" =~ ^[0-9a-f]{40}$ ]] || fail "verified source SHA must be a lowercase 40-character commit"
git check-ref-format "refs/tags/$tag_name" || fail "tag name is invalid"

tag_ref="refs/tags/$tag_name"
if ! remote_refs="$(git ls-remote "$remote_url" "$tag_ref" "$tag_ref^{}")"; then
  fail "could not read remote tag ref"
fi

direct_sha=""
peeled_sha=""
while IFS=$'\t' read -r object_sha ref_name; do
  [[ -n "$ref_name" ]] || continue
  [[ "$object_sha" =~ ^[0-9a-f]{40}$ ]] || fail "remote returned a malformed object ID"

  case "$ref_name" in
    "$tag_ref")
      [[ -z "$direct_sha" ]] || fail "remote returned duplicate tag refs"
      direct_sha="$object_sha"
      ;;
    "$tag_ref^{}")
      [[ -z "$peeled_sha" ]] || fail "remote returned duplicate peeled tag refs"
      peeled_sha="$object_sha"
      ;;
  esac
done <<< "$remote_refs"

[[ -n "$direct_sha" ]] || fail "remote tag ref is missing"
resolved_sha="${peeled_sha:-$direct_sha}"
[[ "$resolved_sha" == "$verified_sha" ]] ||
  fail "tag $tag_name resolves to $resolved_sha, not verified source $verified_sha"

printf 'tag %s resolves to verified commit %s\n' "$tag_name" "$verified_sha"
