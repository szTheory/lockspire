#!/usr/bin/env bash
set -euo pipefail

fail() {
  printf 'GitHub release target verification: %s\n' "$1" >&2
  exit 1
}

if [[ "$#" -lt 3 || "$#" -gt 4 ]]; then
  fail "usage: $0 TAG REMOTE_URL VERIFIED_SHA [--if-present]"
fi

tag_name="$1"
remote_url="$2"
verified_sha="$3"
allow_missing=0

if [[ "$#" == 4 ]]; then
  [[ "$4" == "--if-present" ]] || fail "unknown option: $4"
  allow_missing=1
fi

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

if [[ -z "$direct_sha" ]]; then
  [[ -z "$peeled_sha" ]] || fail "remote returned a peeled tag without its tag ref"
  if [[ "$allow_missing" == 1 ]]; then
    printf 'tag %s is absent; prepublish tag check passed\n' "$tag_name"
    exit 0
  fi
  fail "remote tag ref is missing"
fi
resolved_sha="${peeled_sha:-$direct_sha}"
[[ "$resolved_sha" == "$verified_sha" ]] ||
  fail "tag $tag_name resolves to $resolved_sha, not verified source $verified_sha"

printf 'tag %s resolves to verified commit %s\n' "$tag_name" "$verified_sha"
