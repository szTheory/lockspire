#!/usr/bin/env bash
set -euo pipefail

SCOPE=""
OUTPUT=""
INVOCATION_DIR="$(pwd -P)"
REPLACE=0
VERIFY_SNAPSHOT_LEDGER=""
VERIFY_PREVERIFY_LEDGER=""
VERIFY_POST_TRANSITION_LEDGER=""
VERIFY_PHASE_139_PREVERIFY_LEDGER=""
VERIFY_PHASE_139_SEALED_CANDIDATE_LEDGER=""
VERIFY_PHASE_139_POST_TRANSITION_LEDGER=""
INVENTORY_REVIEW_PHASE="${LOCKSPIRE_INVENTORY_REVIEW_PHASE:-138}"
GITHUB_STATUS="not_applicable"
GITHUB_EXIT="not_run"
GITHUB_LIMITATION="GitHub collection was not requested."
GITHUB_REPOSITORY="unavailable"
GITHUB_PR_STATUS="not_applicable"
GITHUB_PR_EXIT="not_run"
GITHUB_PR_LIMITATION="Pull-request collection was not requested."
GITHUB_ISSUE_STATUS="not_applicable"
GITHUB_ISSUE_EXIT="not_run"
GITHUB_ISSUE_LIMITATION="Issue collection was not requested."
GITHUB_TEMP_DIR=""
GRAPHQL_FAILURE=""
GITHUB_ROW_FAILURE=""
GITHUB_OBJECT_ID_PATTERN='^([0-9A-Fa-f]{40}|[0-9A-Fa-f]{64})$'
REMOTE="${LOCKSPIRE_INVENTORY_REMOTE:-origin}"
STARTED_AT=""
FINISHED_AT=""
EVIDENCE_BASE_SHA="unavailable"
SNAPSHOT_HEAD_SHA="unavailable"
SNAPSHOT_MAIN_SHA="unavailable"
SNAPSHOT_REMOTE_MAIN_SHA="unavailable"
SNAPSHOT_REPOSITORY_IDENTITY="unavailable"
SNAPSHOT_SOURCE_SCOPES=""
PHASE_REVIEW_STATUS="unavailable"
PHASE_REVIEW_SHA256="unavailable"
GIT_RECEIPT_FINGERPRINT="not_applicable"
GITHUB_RECEIPT_FINGERPRINT="not_applicable"
MAINTAINED_RECEIPT_FINGERPRINT="not_applicable"
FETCH_EXIT="not_run"
FETCH_STATUS="unavailable"
FETCH_LIMITATION="Collection has not started."
BRANCH_STATUS="not_applicable"
BRANCH_EXIT="not_run"
BRANCH_LIMITATION="Branch collection was not requested."
TAG_STATUS="not_applicable"
TAG_EXIT="not_run"
TAG_LIMITATION="Tag collection was not requested."
WORKTREE_STATUS="not_applicable"
WORKTREE_EXIT="not_run"
WORKTREE_LIMITATION="Worktree collection was not requested."
SNAPSHOT_STATUS="unavailable"
GIT_BASELINE_STATUS="unavailable"
GIT_BASELINE_LIMITATION="Git baseline collection has not started."
SNAPSHOT_OBJECT_FORMAT="unavailable"
SNAPSHOT_DIVERGENCE=""
PORCELAIN_STATUS="unavailable"
MAINTAINED_STATUS="not_applicable"
MAINTAINED_EXIT="not_run"
MAINTAINED_LIMITATION="Maintained-record collection was not requested."
MAINTAINED_SELECTOR_OUTPUT=""
MAINTAINED_INCLUDED_OUTPUT=""
MAINTAINED_RECORD_OUTPUT=""
MAINTAINED_ROWS_OUTPUT=""
MAINTAINED_AGGREGATED_OUTPUT=""
MAINTAINED_TREEISH="HEAD"
MAINTAINED_USE_INDEX=0
RECHECK_OUTPUT=""
TEMP_OUTPUT=""
GIT_DOMAINS_OUTPUT=""
GITHUB_OUTPUT=""
MAINTAINED_OUTPUT=""
LOCK_DIR=""
LOCK_OWNED=0
OUTPUT_PARENT=""
OUTPUT_BASENAME=""
OUTPUT_TARGET_EXISTED=0
OUTPUT_TARGET_IDENTITY="absent"
OWNED_WORKTREE_PATHS=()
CANONICAL_LEDGER_RELATIVE_PATH=".planning/phases/138-baseline-inventory-evidence-taxonomy/baseline-inventory-2026-08-28.md"
# D-17 is deliberately an allowlist, not a repository-wide prose search.
MAINTAINED_SOURCE_FAMILIES=(
  "todos:.planning/todos/**" "debug:.planning/debug/**" "quick:.planning/quick/**"
  "threads:.planning/threads/**" "seeds:.planning/seeds/**"
  "active-records:.planning/phases/*/*-{REVIEW,AUDIT,VERIFICATION,UAT,HANDOFF,CHECKPOINT}*.md"
  "milestones:.planning/milestones/**" "continue:.continue-here.md"
  "roadmap:.planning/ROADMAP.md" "state:.planning/STATE.md" "project:.planning/PROJECT.md"
  "release-train:.planning/RELEASE-TRAIN.md" "development-train:.planning/DEVELOPMENT-TRAIN.md"
  "conformance:prompts/lockspire-release-readiness-and-conformance.md"
  "tracked-markers:lib test scripts docs"
)
# D-19 exclusions apply before a file can become an inventory row.
MAINTAINED_EXCLUDED_PATHS='(^|/)(deps|_build|cover|doc|\.artifacts|tmp|cache)(/|$)|(^|/)\.DS_Store$|(^|/)(\.codex|\.agents)/'
# Completeness vocabulary: complete, partial, unavailable, not_applicable.

usage() {
  cat <<'EOF'
Usage: baseline_inventory.sh [--scope git-baseline|git|github|maintained] --output PATH [--replace]
       baseline_inventory.sh --verify-snapshot-relation LEDGER
       baseline_inventory.sh --verify-preverify-relation LEDGER
       baseline_inventory.sh --verify-post-transition-relation LEDGER
       baseline_inventory.sh --verify-phase-139-preverify-relation LEDGER
       baseline_inventory.sh --verify-phase-139-sealed-candidate-relation LEDGER
       baseline_inventory.sh --verify-phase-139-posttransition-relation LEDGER

Collects a proposal-only Git evidence receipt. It refreshes origin metadata with
`git fetch --prune --tags REMOTE`; it never prunes local tags or performs cleanup.

Options:
  --scope git-baseline  Collect the current Git baseline receipt.
  --scope git           Also enumerate proposal-only branches, tags, and worktrees.
  --scope github        Enumerate open pull requests and issues through GraphQL cursors.
  --scope maintained    Enumerate allowlisted maintained follow-up records.
                        With no --scope, collect the complete Phase 138 ledger.
  --output PATH         Write the requested Markdown evidence ledger.
  --replace             Replace an existing output only after an atomic render.
  --verify-snapshot-relation LEDGER
                        Read-only proof of an immutable ledger plus authorized Phase 138 bookkeeping.
  --verify-preverify-relation LEDGER
                        Prove the fixed pre-verifier publication and consumed review receipt.
  --verify-post-transition-relation LEDGER
                        Prove post-transition authority from the sealed host lifecycle receipt.
  --verify-phase-139-preverify-relation LEDGER
                        Prove the Phase 139 ledger-only refresh at the pre-verifier boundary.
  --verify-phase-139-sealed-candidate-relation LEDGER
                        Authenticate the sealed Phase 139 candidate before any main mutation.
  --verify-phase-139-posttransition-relation LEDGER
                        Prove the sealed Phase 139 lifecycle after synchronized main advancement.
  --help                Show this help.
EOF
}

die() { printf '%s\n' "$(redacted_display_value "$*")" >&2; exit 1; }
utc_now() { date -u +"%Y-%m-%dT%H:%M:%SZ"; }
valid_github_object_id() { [[ "$1" =~ $GITHUB_OBJECT_ID_PATTERN ]]; }

normalize_utf8_bytes() {
  local value="$1" mode="${2:-markdown}" LC_ALL=C
  local length=${#value} index=0 byte=0 next1=0 next2=0 next3=0 width=0 valid=0
  while (( index < length )); do
    printf -v byte '%d' "'${value:index:1}"
    (( byte < 0 )) && byte=$((byte + 256))
    if (( byte < 128 )); then
      if (( byte == 9 || byte == 10 || byte == 13 )); then
        if [[ "$mode" == yaml ]]; then printf '%s' "${value:index:1}"; else printf '%%%02X' "$byte"; fi
      elif (( byte < 32 || byte == 127 )); then
        printf '%%%02X' "$byte"
      elif (( byte == 37 )) && [[ "$mode" == markdown ]]; then
        printf '%%25'
      else
        printf '%s' "${value:index:1}"
      fi
      index=$((index + 1))
      continue
    fi

    width=1
    valid=0
    if (( byte >= 194 && byte <= 223 && index + 1 < length )); then
      printf -v next1 '%d' "'${value:index+1:1}"
      (( next1 < 0 )) && next1=$((next1 + 256))
      if (( next1 >= 128 && next1 <= 191 )); then width=2; valid=1; fi
    elif (( byte >= 224 && byte <= 239 && index + 2 < length )); then
      printf -v next1 '%d' "'${value:index+1:1}"
      printf -v next2 '%d' "'${value:index+2:1}"
      (( next1 < 0 )) && next1=$((next1 + 256))
      (( next2 < 0 )) && next2=$((next2 + 256))
      if (( next2 >= 128 && next2 <= 191 )) && \
        { (( byte == 224 && next1 >= 160 && next1 <= 191 )) || \
          (( byte >= 225 && byte <= 236 && next1 >= 128 && next1 <= 191 )) || \
          (( byte == 237 && next1 >= 128 && next1 <= 159 )) || \
          (( byte >= 238 && byte <= 239 && next1 >= 128 && next1 <= 191 )); }; then
        width=3; valid=1
      fi
    elif (( byte >= 240 && byte <= 244 && index + 3 < length )); then
      printf -v next1 '%d' "'${value:index+1:1}"
      printf -v next2 '%d' "'${value:index+2:1}"
      printf -v next3 '%d' "'${value:index+3:1}"
      (( next1 < 0 )) && next1=$((next1 + 256))
      (( next2 < 0 )) && next2=$((next2 + 256))
      (( next3 < 0 )) && next3=$((next3 + 256))
      if (( next2 >= 128 && next2 <= 191 && next3 >= 128 && next3 <= 191 )) && \
        { (( byte == 240 && next1 >= 144 && next1 <= 191 )) || \
          (( byte >= 241 && byte <= 243 && next1 >= 128 && next1 <= 191 )) || \
          (( byte == 244 && next1 >= 128 && next1 <= 143 )); }; then
        width=4; valid=1
      fi
    fi

    if (( valid == 1 )); then
      if (( byte == 194 && next1 >= 128 && next1 <= 159 )); then
        printf '%%%02X%%%02X' "$byte" "$next1"
      else
        printf '%s' "${value:index:width}"
      fi
      index=$((index + width))
    else
      printf '%%%02X' "$byte"
      index=$((index + 1))
    fi
  done
}

display_normalize() { normalize_utf8_bytes "$1" markdown; }
yaml_display_normalize() { normalize_utf8_bytes "$1" yaml; }

safe_public_identifier_value() {
  local value="$1" remaining candidate length

  # This is a closed allowlist, not a readability heuristic. Keep every case
  # anchored so a safe prefix cannot bless a credential-bearing suffix.
  if [[ "$value" =~ ^[0-9A-Fa-f]{40}$ || "$value" =~ ^[0-9A-Fa-f]{64}$ ]]; then
    return 0
  fi
  if [[ "$value" =~ ^(REC|GIT-BR|GIT-TAG|GIT-WT)-[0-9a-f]{12}$ ]]; then
    return 0
  fi
  if [[ "$value" =~ ^[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[1-5][0-9A-Fa-f]{3}-[89AaBb][0-9A-Fa-f]{3}-[0-9A-Fa-f]{12}$ ]]; then
    return 0
  fi
  if [[ "$value" =~ ^(lockspire-)?v?[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z]+(\.[0-9A-Za-z]+)*)?(\+[0-9A-Za-z]+(\.[0-9A-Za-z]+)*)?$ ]]; then
    remaining="$value"
    while [[ "$remaining" =~ ([A-Za-z0-9_+=-]{32,}) ]]; do
      candidate="${BASH_REMATCH[1]}"
      remaining="${remaining#*"$candidate"}"
      if [[ "$candidate" =~ [A-Z] && "$candidate" =~ [a-z] && "$candidate" =~ [0-9] ]] &&
        ! safe_public_identifier_value "$candidate"; then
        return 1
      fi
    done
    return 0
  fi
  if [[ "$value" =~ ^LockspireRelease(Candidate)?(January|February|March|April|May|June|July|August|September|October|November|December)[0-9]{4}$ ]]; then
    return 0
  fi

  # Public HTTPS URLs are safe only if every credential-shaped component is
  # independently allowlisted. The URL wrapper itself grants no exemption.
  if [[ "$value" =~ ^https://[A-Za-z0-9.-]+(/[A-Za-z0-9._~:/?#@%+=,-]*)?$ ]]; then
    remaining="${value#https://}"
    while [[ "$remaining" =~ ([A-Za-z0-9_+=-]{32,}) ]]; do
      candidate="${BASH_REMATCH[1]}"
      remaining="${remaining#*"$candidate"}"
      length=${#candidate}
      if [[ "$candidate" =~ [A-Z] && "$candidate" =~ [a-z] && "$candidate" =~ [0-9] ]] &&
        ! safe_public_identifier_value "$candidate"; then
        return 1
      fi
      (( length > 0 )) || return 1
    done
    return 0
  fi

  return 1
}

credential_like_value() {
  local value="$1" remaining candidate length value_length=${#1}

  # This private predicate is the single credential policy for every final
  # Markdown, YAML, receipt, limitation, and diagnostic boundary. Canonical
  # identity and deduplication deliberately happen before callers reach here.
  if [[ "$value" == *[Tt][Oo][Kk][Ee][Nn]* ||
    "$value" == *[Ss][Ee][Cc][Rr][Ee][Tt]* ||
    "$value" == *[Pp][Aa][Ss][Ss][Ww][Oo][Rr][Dd]* ||
    "$value" == *[Aa][Uu][Tt][Hh][Oo][Rr][Ii][Zz][Aa][Tt][Ii][Oo][Nn]* ||
    "$value" == *[Gg][Hh][Pp]_* || "$value" == *[Gg][Ii][Tt][Hh][Uu][Bb]_[Pp][Aa][Tt]_* ]]; then
    return 0
  fi
  [[ "$value_length" -ge 16 ]] || return 1

  if [[ "$value" == *[Aa][Kk][Ii][Aa]????????????????* ||
    "$value" == *[Aa][Ss][Ii][Aa]????????????????* ||
    "$value" == *[Xx][Oo][Xx][BbAaPpRrSs]-* ||
    "$value" == *-----[Bb][Ee][Gg][Ii][Nn]*[Pp][Rr][Ii][Vv][Aa][Tt][Ee]*[Kk][Ee][Yy]-----* ||
    "$value" == *[Bb][Ee][Aa][Rr][Ee][Rr]' '* ||
    "$value" == *[Gg][Hh][OoUuSsRr]_* ]]; then
    return 0
  fi
  if [[ "$value" == *.*.* ]] &&
    [[ "$value" =~ (^|[^A-Za-z0-9_-])[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]{8,}([^A-Za-z0-9_-]|$) ]]; then
    return 0
  fi

  safe_public_identifier_value "$value" && return 1
  [[ "$value_length" -ge 32 ]] || return 1

  # Opaque candidates must be long and contain upper-case, lower-case, and a
  # digit. Exact Git object IDs stay useful even at their ordinary 40/64 widths.
  # Slash is a structural separator at the rendered URL/path boundary, so scan
  # each component independently instead of letting a readable URL prefix mask
  # an opaque credential carried in one component.
  remaining="$value"
  while [[ "$remaining" =~ ([A-Za-z0-9_+=-]{32,}) ]]; do
    candidate="${BASH_REMATCH[1]}"
    remaining="${remaining#*"$candidate"}"
    length=${#candidate}
    if safe_public_identifier_value "$candidate"; then
      continue
    fi
    [[ "$candidate" =~ [A-Z] ]] || continue
    [[ "$candidate" =~ [a-z] ]] || continue
    [[ "$candidate" =~ [0-9] ]] || continue
    return 0
  done

  return 1
}

redacted_display_value() {
  local value="$1"
  if credential_like_value "$value"; then
    printf '[REDACTED]'
    return
  fi
  printf '%s' "$value"
}

markdown_normalized_value() {
  local value
  value="$(redacted_display_value "$1")"
  if [[ "$value" == '[REDACTED]' ]]; then
    printf '%s' "$value"
    return
  fi
  value="${value//\\/\\\\}"
  value="${value//|/\\|}"
  value="${value//\`/\\\`}"
  value="${value//[/\\[}"
  value="${value//]/\\]}"
  value="${value//(/\\(}"
  value="${value//)/\\)}"
  printf '%s' "$value"
}

markdown_value() {
  markdown_normalized_value "$(display_normalize "$1")"
}

yaml_quoted_scalar() {
  local value
  value="$(yaml_display_normalize "$1")"
  value="$(redacted_display_value "$value")"
  printf '%s' "$value" | jq -Rs .
}

# GitHub values cross both structured-parser and Markdown-table boundaries. Keep this
# named seam so every remote field is normalized before it can become a delimiter.
github_field_value() {
  markdown_value "$1"
}

record_source_receipt() {
  local name="$1" status="$2" command="$3" exit_status="$4" limitation="$5"
  printf '| %s | %s | `%s` | %s | %s |\n' \
    "$(markdown_value "$name")" "$(markdown_value "$status")" \
    "$(markdown_value "$command")" "$(markdown_value "$exit_status")" \
    "$(markdown_value "$limitation")"
}

render_front_matter() {
  local repo_root="$1" head_sha="$2" main_sha="$3" remote_main_sha="$4"
  cat <<EOF
---
phase: 138
scope: $(yaml_quoted_scalar "$SCOPE")
status: $(yaml_quoted_scalar "$SNAPSHOT_STATUS")
collection_started_at: $(yaml_quoted_scalar "$STARTED_AT")
collection_finished_at: $(yaml_quoted_scalar "$FINISHED_AT")
repository: $(yaml_quoted_scalar "$repo_root")
repository_identity: $(yaml_quoted_scalar "$SNAPSHOT_REPOSITORY_IDENTITY")
declared_source_scopes: $(yaml_quoted_scalar "$SNAPSHOT_SOURCE_SCOPES")
local_head_sha: $(yaml_quoted_scalar "$head_sha")
evidence_base_sha: $(yaml_quoted_scalar "$EVIDENCE_BASE_SHA")
local_main_sha: $(yaml_quoted_scalar "$main_sha")
origin_main_sha: $(yaml_quoted_scalar "$remote_main_sha")
git_receipt_fingerprint: $(yaml_quoted_scalar "$GIT_RECEIPT_FINGERPRINT")
github_receipt_fingerprint: $(yaml_quoted_scalar "$GITHUB_RECEIPT_FINGERPRINT")
maintained_receipt_fingerprint: $(yaml_quoted_scalar "$MAINTAINED_RECEIPT_FINGERPRINT")
phase_review_status: $(yaml_quoted_scalar "$PHASE_REVIEW_STATUS")
phase_review_sha256: $(yaml_quoted_scalar "$PHASE_REVIEW_SHA256")
executed: $(yaml_quoted_scalar "no — inventory proposal only")
---

# Git baseline evidence receipt

Observed. Revalidation required before action. This receipt proposes no cleanup.

EOF
}

render_source_receipts() {
  printf '## Source receipts\n\n'
  printf '| Source | Status | Command | Exit status | Limitations |\n'
  printf '| --- | --- | --- | --- | --- |\n'
  record_source_receipt "origin metadata refresh" "$FETCH_STATUS" "git fetch --prune --tags $REMOTE" "$FETCH_EXIT" "$FETCH_LIMITATION"
  if [[ "$SCOPE" == git || -z "$SCOPE" ]]; then
    record_source_receipt "Git branches" "$BRANCH_STATUS" "git for-each-ref refs/heads refs/remotes" "$BRANCH_EXIT" "$BRANCH_LIMITATION"
    record_source_receipt "Git tags" "$TAG_STATUS" "git for-each-ref refs/tags" "$TAG_EXIT" "$TAG_LIMITATION"
    record_source_receipt "Git worktrees" "$WORKTREE_STATUS" "git worktree list --porcelain -z" "$WORKTREE_EXIT" "$WORKTREE_LIMITATION"
  fi
  if [[ "$SCOPE" == github || -z "$SCOPE" ]]; then
    record_source_receipt "GitHub open queues" "$GITHUB_STATUS" "gh api graphql --paginate (separate pullRequests and issues queries)" "$GITHUB_EXIT" "$GITHUB_LIMITATION"
  fi
  if [[ "$SCOPE" == maintained || -z "$SCOPE" ]]; then
    record_source_receipt "Maintained follow-up families" "$MAINTAINED_STATUS" "allowlisted git ls-files and tracked TODO/FIXME scan" "$MAINTAINED_EXIT" "$MAINTAINED_LIMITATION"
  fi
  printf '\n'
}

render_post_snapshot_currentness_relation() {
  printf '## Post-snapshot currentness relation\n\n'
  printf 'This ledger is an immutable snapshot bounded as of `%s` at `evidence_base_sha` `%s`; it does not claim to represent a later HEAD or pre-authorize later lifecycle writes.\n\n' \
    "$STARTED_AT" "$(markdown_value "$EVIDENCE_BASE_SHA")"
  printf 'After publishing this candidate in a ledger-only commit whose direct parent is its `evidence_base_sha`, rerun the production classifier from the repository root:\n\n'
  printf '```console\n'
  printf 'bash scripts/maintainer/baseline_inventory.sh --verify-snapshot-relation %s\n' "$CANONICAL_LEDGER_RELATIVE_PATH"
  printf '```\n\n'
  printf 'The command is read-only. It revalidates the immutable direct-parent relation, ledger-only diff, unchanged ledger blob, requested-HEAD and local-main ancestry, current source receipts, every later first-parent commit, and the working-tree projection. It discloses each observed post-snapshot row instead of assuming that HEAD stopped changing.\n\n'
  printf '`authorized_bookkeeping` means every observed row matched the exact ancestry, identity, subject, path, semantic-content, blob, and receipt rules. Any nonzero exit or `refresh_required` means the snapshot must be recollected from a new clean evidence base and published in a new ledger-only replacement commit; uncertainty must not be reinterpreted as authorized bookkeeping.\n\n'
  printf 'Rerun this classifier at the start of Phases 139 and 140, immediately before any Phase 140 mutation, during Phase 141 exact-SHA closure, and after any lifecycle write not present in the last disclosed table. All inventory dispositions remain proposal-only and require their named revalidation and maintainer authority before action.\n\n'
}

github_auth_receipt() {
  if ! command -v gh >/dev/null 2>&1 || ! command -v jq >/dev/null 2>&1; then
    GITHUB_STATUS="unavailable"
    GITHUB_EXIT="127"
    GITHUB_LIMITATION="GitHub collection requires authenticated gh and jq; no queue conclusion is available."
    return
  fi
  if ! gh auth status --hostname github.com >/dev/null 2>&1; then
    GITHUB_STATUS="unavailable"
    GITHUB_EXIT="auth_failed"
    GITHUB_LIMITATION="GitHub authentication failed; no empty, complete, or merge-ready conclusion is available."
    return
  fi
  if ! GITHUB_REPOSITORY="$(gh repo view --json nameWithOwner --jq .nameWithOwner 2>/dev/null)" || [[ ! "$GITHUB_REPOSITORY" =~ ^[^/[:space:]]+/[^/[:space:]]+$ ]]; then
    GITHUB_STATUS="unavailable"
    GITHUB_EXIT="repository_failed"
    GITHUB_LIMITATION="Canonical repository identity could not be resolved; GitHub sources are unavailable."
    return
  fi
  GITHUB_STATUS="complete"
  GITHUB_EXIT=0
  GITHUB_LIMITATION="Authenticated GitHub collection is in progress."
}

combine_graphql_pages() {
  local collection="$1" pages="$2" combined="$3" errors
  GRAPHQL_FAILURE=""
  errors="$(mktemp "${combined}.errors.XXXXXX")"
  jq -se --arg collection "$collection" '
    if length == 0 then error("no pages")
    elif any(.[]; has("errors") and ((.errors | type) != "array" or (.errors | length) > 0)) then error("graphql_errors")
    elif any(.[]; (.data.repository[$collection].nodes | type) != "array") then error("null_nodes")
    elif any(.[]; .data.repository[$collection].nodes[]? == null) then error("null_nodes")
    elif any(.[]; (.data.repository[$collection].pageInfo | type) != "object" or
                     (.data.repository[$collection].pageInfo.hasNextPage | type) != "boolean" or
                     (.data.repository[$collection].pageInfo | has("endCursor") | not)) then error("malformed_page_info")
    else [ .[] | .data.repository[$collection] ] as $pages |
      if any($pages[0:-1][]; (.pageInfo.hasNextPage | not) and
                              (.pageInfo.endCursor | type) == "string" and
                              (.pageInfo.endCursor | length) > 0) then error("post_terminal_page")
      elif any($pages[0:-1][]; (.pageInfo.hasNextPage | not)) then error("premature_terminal_page")
      elif any($pages[0:-1][]; (.pageInfo.endCursor | type) != "string" or
                                (.pageInfo.endCursor | length) == 0) then error("missing_page_cursor")
      elif (($pages[0:-1] | map(.pageInfo.endCursor)) | length) !=
           (($pages[0:-1] | map(.pageInfo.endCursor) | unique) | length) then error("repeated_page_cursor")
      elif $pages[-1].pageInfo.hasNextPage then error("premature_pagination")
      else
        ($pages | map(.nodes[]) | map({
          id, number, title, url, updatedAt, state, stateReason, isDraft, mergeStateStatus, reviewDecision,
          headRefName, headRefOid, baseRefName, baseRefOid,
          checkRollupState: ([.commits.nodes[]?.commit.statusCheckRollup.state?] | first // null)
        })) as $nodes |
        ($nodes | group_by(.id)) as $groups |
        ($groups | map(select((unique | length) > 1) | .[0].id)) as $contradictions |
        ($groups | map(select((unique | length) == 1))) as $corroborated |
        {page_count: ($pages | length),
         observed_identity_count: ($groups | length),
         item_count: ($corroborated | length),
         duplicate_count: ($corroborated | map(length - 1) | add // 0),
         contradiction_count: ($contradictions | length),
         duplicate_contradictions: ($contradictions | map("contradictory_duplicate_" + .)),
         terminal_page_info: $pages[-1].pageInfo,
         nodes: ($corroborated | map(.[0]) | sort_by(.number, .id, .url))}
      end
    end
  ' "$pages" > "$combined" 2> "$errors" || {
    if grep -q 'graphql_errors' "$errors"; then GRAPHQL_FAILURE="graphql_errors"
    elif grep -q 'null_nodes' "$errors"; then GRAPHQL_FAILURE="null_nodes"
    elif grep -q 'malformed_page_info' "$errors"; then GRAPHQL_FAILURE="malformed_page_info"
    elif grep -q 'post_terminal_page' "$errors"; then GRAPHQL_FAILURE="post_terminal_page"
    elif grep -q 'premature_terminal_page' "$errors"; then GRAPHQL_FAILURE="premature_terminal_page"
    elif grep -q 'missing_page_cursor' "$errors"; then GRAPHQL_FAILURE="missing_page_cursor"
    elif grep -q 'repeated_page_cursor' "$errors"; then GRAPHQL_FAILURE="repeated_page_cursor"
    elif grep -q 'premature_pagination' "$errors"; then GRAPHQL_FAILURE="premature_pagination"
    else GRAPHQL_FAILURE="malformed_json"; fi
    rm -f "$errors"
    return 1
  }
  rm -f "$errors"
}

validate_github_pr_metadata() {
  local combined="$1"
  jq -e --arg oid_pattern "$GITHUB_OBJECT_ID_PATTERN" '
    all(.nodes[];
      ((.id | type) == "string" and (.id | length) > 0) and
      ((.number | type) == "number" and .number > 0 and .number == (.number | floor)) and
      ((.title | type) == "string") and
      ((.url | type) == "string" and (.url | length) > 0) and
      ((.updatedAt | type) == "string" and (.updatedAt | length) > 0) and
      ((.state | type) == "string" and .state == "OPEN") and
      ((.isDraft | type) == "boolean") and
      ((.mergeStateStatus | type) == "string" and (.mergeStateStatus | length) > 0) and
      (((.reviewDecision | type) == "string") or .reviewDecision == null) and
      ((.headRefName | type) == "string" and (.headRefName | length) > 0) and
      ((.headRefOid | type) == "string" and (.headRefOid | test($oid_pattern))) and
      ((.baseRefName | type) == "string" and (.baseRefName | length) > 0) and
      ((.baseRefOid | type) == "string" and (.baseRefOid | test($oid_pattern))) and
      (((.checkRollupState | type) == "string") or .checkRollupState == null)
    )
  ' "$combined" >/dev/null
}

combine_pr_check_pages() {
  local pages="$1" combined="$2" errors
  GRAPHQL_FAILURE=""
  errors="$(mktemp "${combined}.errors.XXXXXX")"
  jq -se '
    def commits: .data.node.commits.nodes;
    def connection: .data.node.commits.nodes[0].commit.statusCheckRollup.contexts;
    if length == 0 then error("nested_no_pages")
    elif any(.[]; has("errors") and ((.errors | type) != "array" or (.errors | length) > 0)) then error("nested_graphql_errors")
    elif any(.[]; (commits | type) != "array" or (commits | length) == 0) then error("nested_missing_commit_oid")
    elif any(.[]; (commits | length) != 1) then error("nested_ambiguous_latest_commit")
    elif any(.[]; (commits[0].commit | type) != "object" or
                     (commits[0].commit.oid == null)) then error("nested_missing_commit_oid")
    elif any(.[]; (commits[0].commit.oid | type) != "string" or
                     (commits[0].commit.oid | test("^([0-9A-Fa-f]{40}|[0-9A-Fa-f]{64})$") | not)) then error("nested_malformed_commit_oid")
    elif any(.[]; (connection | type) != "object") then error("nested_missing_connection")
    elif any(.[]; (connection.nodes | type) != "array" or any(connection.nodes[]?; . == null)) then error("nested_null_nodes")
    elif any(.[]; (connection.totalCount | type) != "number" or connection.totalCount < 0 or connection.totalCount != (connection.totalCount | floor)) then error("nested_malformed_count")
    elif any(.[]; (connection.pageInfo | type) != "object" or
                     (connection.pageInfo.hasNextPage | type) != "boolean" or
                     (connection.pageInfo | has("endCursor") | not)) then error("nested_malformed_page_info")
    else [ .[] | connection ] as $pages |
      ([.[] | commits[0].commit.oid | ascii_downcase] | unique) as $commit_oids |
      if ($commit_oids | length) != 1 then error("nested_commit_oid_changed")
      elif any($pages[0:-1][]; (.pageInfo.hasNextPage | not) or
                              (.pageInfo.endCursor | type) != "string" or
                              (.pageInfo.endCursor | length) == 0) then error("nested_premature_terminal")
      elif $pages[-1].pageInfo.hasNextPage then error("nested_premature_pagination")
      elif (($pages[0:-1] | map(.pageInfo.endCursor)) | length) !=
           (($pages[0:-1] | map(.pageInfo.endCursor) | unique) | length) then error("nested_repeated_cursor")
      elif any($pages[]; .totalCount != $pages[0].totalCount) then error("nested_count_changed")
      else
        ($pages | map(.nodes[]) | map(
          if .__typename == "CheckRun" then
            {kind:"check_run", name:(.name // ""), state:(.status // null), conclusion:(if has("conclusion") then .conclusion else null end)}
          elif .__typename == "StatusContext" then
            {kind:"status_context", name:(.context // ""), state:(.state // null), conclusion:null}
          else
            {kind:(.__typename // "unknown"), name:"", state:null, conclusion:null}
          end
        )) as $contexts |
        if ($contexts | length) != $pages[0].totalCount then error("nested_count_mismatch")
        else {complete:true, commit_oid:$commit_oids[0], total_count:$pages[0].totalCount, page_count:($pages|length), contexts:$contexts, limitation:null}
        end
      end
    end
  ' "$pages" > "$combined" 2> "$errors" || {
    for failure in nested_graphql_errors nested_missing_commit_oid nested_ambiguous_latest_commit nested_malformed_commit_oid nested_commit_oid_changed nested_missing_connection nested_null_nodes nested_malformed_count nested_malformed_page_info nested_premature_terminal nested_premature_pagination nested_repeated_cursor nested_count_changed nested_count_mismatch nested_no_pages; do
      if grep -q "$failure" "$errors"; then GRAPHQL_FAILURE="$failure"; break; fi
    done
    [[ -n "$GRAPHQL_FAILURE" ]] || GRAPHQL_FAILURE="nested_malformed_json"
    rm -f "$errors"
    return 1
  }
  rm -f "$errors"
}

collect_pr_check_evidence() {
  local combined="$1" temp_dir="$2" query id number outer_head pages checks next failure failures="" row
  query='query($pullRequestId: ID!, $endCursor: String) { node(id: $pullRequestId) { ... on PullRequest { commits(last: 1) { nodes { commit { oid statusCheckRollup { contexts(first: 100, after: $endCursor) { totalCount nodes { __typename ... on CheckRun { name status conclusion } ... on StatusContext { context state } } pageInfo { hasNextPage endCursor } } } } } } } } }'
  while IFS= read -r row; do
    id="$(jq -r '.id' <<< "$row")"
    number="$(jq -r '.number' <<< "$row")"
    outer_head="$(jq -r '.headRefOid' <<< "$row")"
    pages="$temp_dir/pr-check-${number}-pages.json"
    checks="$temp_dir/pr-check-${number}.json"
    failure=""
    if ! gh api graphql --paginate -f query="$query" -f pullRequestId="$id" > "$pages" 2>/dev/null; then
      failure="nested_api_failed"
    elif ! combine_pr_check_pages "$pages" "$checks"; then
      failure="${GRAPHQL_FAILURE:-nested_malformed_json}"
    elif ! jq -e --arg expected "$outer_head" '(.commit_oid | ascii_downcase) == ($expected | ascii_downcase)' "$checks" >/dev/null; then
      failure="nested_head_mismatch"
    fi
    if [[ -n "$failure" ]]; then
      jq -n --arg limitation "$failure" '{complete:false,commit_oid:null,total_count:0,page_count:0,contexts:[],limitation:$limitation}' > "$checks"
      failures+="${number}:${failure}"$'\n'
    fi
    next="$temp_dir/open-prs-next.json"
    jq --arg id "$id" --slurpfile checks "$checks" '(.nodes[] | select(.id == $id) | .checks) = $checks[0]' "$combined" > "$next"
    mv "$next" "$combined"
  done < <(jq -c '.nodes[]' "$combined")
  next="$temp_dir/open-prs-next.json"
  if [[ -n "$failures" ]]; then
    jq --arg failures "$failures" '.nested_complete=false | .nested_failures=($failures | split("\n") | map(select(length > 0)))' "$combined" > "$next"
  else
    jq '.nested_complete=true | .nested_failures=[]' "$combined" > "$next"
  fi
  mv "$next" "$combined"
}

validate_github_rows() {
  local collection="$1" combined="$2"
  GITHUB_ROW_FAILURE=""
  if [[ "$collection" == pullRequests ]]; then
    jq -e --arg oid_pattern "$GITHUB_OBJECT_ID_PATTERN" '
      all(.nodes[];
        ((.id | type) == "string" and (.id | length) > 0) and
        ((.number | type) == "number" and .number > 0 and .number == (.number | floor)) and
        ((.title | type) == "string") and
        ((.url | type) == "string" and (.url | length) > 0) and
        ((.updatedAt | type) == "string" and (.updatedAt | length) > 0) and
        ((.state | type) == "string" and .state == "OPEN") and
        ((.isDraft | type) == "boolean") and
        ((.mergeStateStatus | type) == "string" and (.mergeStateStatus | length) > 0) and
        (((.reviewDecision | type) == "string") or .reviewDecision == null) and
        ((.headRefName | type) == "string" and (.headRefName | length) > 0) and
        ((.headRefOid | type) == "string" and (.headRefOid | test($oid_pattern))) and
        ((.baseRefName | type) == "string" and (.baseRefName | length) > 0) and
        ((.baseRefOid | type) == "string" and (.baseRefOid | test($oid_pattern))) and
        (((.checkRollupState | type) == "string") or .checkRollupState == null) and
        ((.checks | type) == "object") and
        ((.checks.complete | type) == "boolean") and
        (((.checks.complete == true) and ((.checks.commit_oid | type) == "string") and
           (.checks.commit_oid | test("^([0-9A-Fa-f]{40}|[0-9A-Fa-f]{64})$"))) or
         ((.checks.complete == false) and (.checks.commit_oid == null))) and
        ((.checks.total_count | type) == "number") and
        ((.checks.contexts | type) == "array") and
        all(.checks.contexts[];
          ((.kind | type) == "string") and
          ((.name | type) == "string") and
          (((.state | type) == "string") or .state == null) and
          (((.conclusion | type) == "string") or .conclusion == null)
        )
      )
    ' "$combined" >/dev/null || GITHUB_ROW_FAILURE="pull_requests_row_validation_failed"
  else
    jq -e '
      all(.nodes[];
        ((.id | type) == "string" and (.id | length) > 0) and
        ((.number | type) == "number" and .number > 0 and .number == (.number | floor)) and
        ((.title | type) == "string") and
        ((.url | type) == "string" and (.url | length) > 0) and
        ((.updatedAt | type) == "string" and (.updatedAt | length) > 0) and
        ((.state | type) == "string" and .state == "OPEN") and
        (((.stateReason | type) == "string") or .stateReason == null)
      )
    ' "$combined" >/dev/null || GITHUB_ROW_FAILURE="issues_row_validation_failed"
  fi
  [[ -z "$GITHUB_ROW_FAILURE" ]]
}

cleanup_github_temp() {
  [[ -n "$GITHUB_TEMP_DIR" ]] || return 0
  rm -f "$GITHUB_TEMP_DIR/open-pr-pages.json" "$GITHUB_TEMP_DIR/open-prs.json" \
    "$GITHUB_TEMP_DIR/open-issue-pages.json" "$GITHUB_TEMP_DIR/open-issues.json" \
    "$GITHUB_TEMP_DIR"/*.errors.*
  local nested_file
  for nested_file in "$GITHUB_TEMP_DIR"/pr-check-*; do
    [[ -e "$nested_file" ]] && rm -f "$nested_file"
  done
  rmdir "$GITHUB_TEMP_DIR" 2>/dev/null || true
  GITHUB_TEMP_DIR=""
}

summarize_pr_checks() {
  local checks="$1" count complete verdict limitation
  count="$(jq -r '.contexts | length' <<< "$checks" 2>/dev/null || printf 0)"
  complete="$(jq -r '.complete // false' <<< "$checks" 2>/dev/null || printf false)"
  limitation="$(jq -r '.limitation // "incomplete"' <<< "$checks" 2>/dev/null || printf incomplete)"
  if [[ "$complete" != true ]]; then
    printf 'unknown (%s observed; incomplete: %s)' "$count" "$(github_field_value "$limitation")"
    return
  fi
  verdict="$(jq -r '
    def terminal_failure:
      if .kind == "check_run" then
        .state == "COMPLETED" and (.conclusion == "FAILURE" or .conclusion == "TIMED_OUT" or .conclusion == "CANCELLED" or
          .conclusion == "ACTION_REQUIRED" or .conclusion == "STARTUP_FAILURE" or .conclusion == "STALE")
      elif .kind == "status_context" then .state == "FAILURE" or .state == "ERROR"
      else false end;
    def terminal_success:
      if .kind == "check_run" then .state == "COMPLETED" and .conclusion == "SUCCESS"
      elif .kind == "status_context" then .state == "SUCCESS"
      else false end;
    if any(.contexts[]; terminal_failure) then "failed"
    elif (.contexts | length) > 0 and all(.contexts[]; terminal_success) then "passed"
    else "unknown" end
  ' <<< "$checks" 2>/dev/null || printf unknown)"
  printf '%s (%s observed; complete)' "$verdict" "$count"
}

propose_pr_disposition() {
  local draft="$1" merge_state="$2" review="$3" head_sha="$4" base_sha="$5" checks="$6"
  if [[ "$draft" == true || "$merge_state" =~ ^(DIRTY|BLOCKED|BEHIND)$ || "$review" == CHANGES_REQUESTED || "$checks" == failed* ]]; then
    printf 'needs-work'
  elif [[ "$draft" == false && "$merge_state" == CLEAN && "$review" == APPROVED ]] &&
    valid_github_object_id "$head_sha" && valid_github_object_id "$base_sha" && [[ "$checks" == passed* ]]; then
    printf 'merge-ready'
  else
    printf 'defer'
  fi
}

render_github_rows() {
  local kind="$1" combined="$2" repository="$3" disposition_authority="$4"
  local row id number title url updated state draft merge review head_ref head_sha base_ref base_sha checks disposition prefix rationale
  if [[ "$disposition_authority" == true ]]; then
    rationale="Current authenticated GitHub evidence; revalidate before any action"
  else
    rationale="Aggregate GitHub evidence incomplete; observation retained without action authority"
  fi
  if [[ "$(jq -r '.item_count' "$combined")" == 0 ]]; then
    if [[ "$disposition_authority" != true ]]; then
      printf 'No safely renderable %s rows; collection remains partial and has no action authority.\n\n' "$kind"
    elif [[ "$kind" == issue ]]; then
      printf 'No open issues observed; query succeeded with 0 results.\n\n'
    else
      printf 'No open pull requests observed; query succeeded with 0 results.\n\n'
    fi
    return
  fi
  printf '| ID | Kind | Canonical subject | Observed state | Lifecycle | Proposed disposition | Evidence reference | Rationale | Confidence | Recheck proof | Required authority | Executed |\n'
  printf '| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |\n'
  if [[ "$kind" == pr ]]; then prefix="GH-PR"; else prefix="GH-ISSUE"; fi
  if [[ "$kind" == issue ]]; then
    while IFS= read -r row; do
      id="$(jq -r '.id' <<< "$row")"
      number="$(jq -r '.number' <<< "$row")"
      title="$(jq -r '.title' <<< "$row")"
      url="$(jq -r '.url' <<< "$row")"
      updated="$(jq -r '.updatedAt' <<< "$row")"
      state="$(jq -r '.state' <<< "$row")"
      if [[ "$disposition_authority" == true ]]; then
        disposition="$(propose_issue_disposition "$updated")"
      else
        disposition="defer"
      fi
      printf '| GH-ISSUE-%s | issue | [%s](%s) | updated `%s`; state `%s` | active | %s | `%s` | %s | direct_current | Revalidate current target, authority, and terminal proof | repository maintainer | no — inventory proposal only |\n' \
        "$number" "$(github_field_value "$title")" "$(github_field_value "$url")" "$(github_field_value "$updated")" "$(github_field_value "$state")" "$disposition" "$(github_field_value "$repository")" "$rationale"
    done < <(jq -c '.nodes[]' "$combined")
    printf '\n'
    return
  fi
  while IFS= read -r row; do
    id="$(jq -r '.id' <<< "$row")"
    number="$(jq -r '.number' <<< "$row")"
    title="$(jq -r '.title' <<< "$row")"
    url="$(jq -r '.url' <<< "$row")"
    updated="$(jq -r '.updatedAt' <<< "$row")"
    state="$(jq -r '.state' <<< "$row")"
    draft="$(jq -r '.isDraft' <<< "$row")"
    merge="$(jq -r '.mergeStateStatus' <<< "$row")"
    review="$(jq -r '.reviewDecision // ""' <<< "$row")"
    head_ref="$(jq -r '.headRefName' <<< "$row")"
    head_sha="$(jq -r '.headRefOid' <<< "$row")"
    base_ref="$(jq -r '.baseRefName' <<< "$row")"
    base_sha="$(jq -r '.baseRefOid' <<< "$row")"
    checks="$(jq -c '.checks' <<< "$row")"
    if [[ "$kind" == pr ]]; then
      checks="$(summarize_pr_checks "$checks")"
      if [[ "$disposition_authority" == true ]]; then
        disposition="$(propose_pr_disposition "$draft" "$merge" "$review" "$head_sha" "$base_sha" "$checks")"
      else
        disposition="defer"
      fi
    fi
    printf '| %s-%s | %s | [%s](%s) | updated `%s`; state `%s`; head `%s` @ `%s`; base `%s` @ `%s`; draft `%s`; merge `%s`; review `%s`; checks `%s` | active | %s | `%s` | %s | direct_current | Revalidate current target, authority, and terminal proof | repository maintainer | no — inventory proposal only |\n' \
      "$prefix" "$number" "$kind" "$(github_field_value "$title")" "$(github_field_value "$url")" "$(github_field_value "$updated")" "$(github_field_value "$state")" "$(github_field_value "$head_ref")" "$(github_field_value "$head_sha")" "$(github_field_value "$base_ref")" "$(github_field_value "$base_sha")" "$(github_field_value "$draft")" "$(github_field_value "$merge")" "$(github_field_value "$review")" "$checks" "$disposition" "$(github_field_value "$repository")" "$rationale"
  done < <(jq -c '.nodes[]' "$combined")
  printf '\n'
}

propose_issue_disposition() {
  local updated="$1"
  [[ -n "$updated" && "$updated" != null ]] && printf 'retain' || printf 'defer'
}

collect_github_collection() {
  local repository="$1" collection="$2" pages="$3" combined="$4" query status exit_status limitation
  if [[ "$collection" == pullRequests ]]; then
    query='query($owner: String!, $name: String!, $endCursor: String) { repository(owner: $owner, name: $name) { COLLECTION(first: 100, states: OPEN, after: $endCursor) { nodes { id number title url updatedAt state isDraft mergeStateStatus reviewDecision headRefName headRefOid baseRefName baseRefOid commits(last: 1) { nodes { commit { statusCheckRollup { state } } } } } pageInfo { hasNextPage endCursor } } } }'
  else
    query='query($owner: String!, $name: String!, $endCursor: String) { repository(owner: $owner, name: $name) { COLLECTION(first: 100, states: OPEN, after: $endCursor) { nodes { id number title url updatedAt state stateReason } pageInfo { hasNextPage endCursor } } } }'
  fi
  query="${query/COLLECTION/$collection}"
  if ! gh api graphql --paginate -f query="$query" -f owner="${repository%%/*}" -f name="${repository##*/}" > "$pages" 2>/dev/null; then
    status="unavailable"
    exit_status="api_failed"
    limitation="GitHub ${collection} query failed; no empty or complete conclusion is available."
  elif ! combine_graphql_pages "$collection" "$pages" "$combined"; then
    status="partial"
    exit_status="${GRAPHQL_FAILURE:-malformed_json}"
    limitation="GitHub ${collection} ${exit_status}; no empty or complete conclusion is available."
  elif [[ "$collection" == pullRequests ]] && ! validate_github_pr_metadata "$combined"; then
    status="partial"
    exit_status="pull_requests_row_validation_failed"
    limitation="GitHub ${collection} ${exit_status}; every normalized row must validate before nested collection."
  elif [[ "$collection" == pullRequests ]] && ! collect_pr_check_evidence "$combined" "${combined%/*}"; then
    status="partial"
    exit_status="nested_check_collection_failed"
    limitation="GitHub ${collection} ${exit_status}; nested check evidence is unavailable."
  elif ! validate_github_rows "$collection" "$combined"; then
    status="partial"
    exit_status="$GITHUB_ROW_FAILURE"
    limitation="GitHub ${collection} ${exit_status}; every normalized row must validate before publication."
  elif [[ "$(jq -r '.contradiction_count // 0' "$combined")" != 0 ]]; then
    status="partial"
    exit_status="$(jq -r '.duplicate_contradictions | join(",")' "$combined")"
    limitation="GitHub ${collection} contained contradictory duplicate identities (${exit_status}); only exact normalized copies corroborate."
    next="${combined}.validated"
    jq '.rows_validated=true' "$combined" > "$next" && mv "$next" "$combined"
  elif [[ "$collection" == pullRequests ]] && [[ "$(jq -r '.nested_complete' "$combined")" != true ]]; then
    status="partial"
    exit_status="$(jq -r '.nested_failures | join(",")' "$combined")"
    limitation="GitHub pullRequests nested check evidence is incomplete (${exit_status}); safe rows are retained without action authority."
    next="${combined}.validated"
    jq '.rows_validated=true' "$combined" > "$next" && mv "$next" "$combined"
  else
    status="complete"
    exit_status=0
    limitation="Authenticated cursor pagination completed with terminal pageInfo."
    next="${combined}.validated"
    jq '.rows_validated=true' "$combined" > "$next" && mv "$next" "$combined"
  fi
  if [[ "$collection" == pullRequests ]]; then
    GITHUB_PR_STATUS="$status"
    GITHUB_PR_EXIT="$exit_status"
    GITHUB_PR_LIMITATION="$limitation"
  else
    GITHUB_ISSUE_STATUS="$status"
    GITHUB_ISSUE_EXIT="$exit_status"
    GITHUB_ISSUE_LIMITATION="$limitation"
  fi
}

collect_github_pull_requests() {
  collect_github_collection "$1" pullRequests "$2/open-pr-pages.json" "$2/open-prs.json"
}

collect_github_issues() {
  collect_github_collection "$1" issues "$2/open-issue-pages.json" "$2/open-issues.json"
}

render_github_collection() {
  local collection="$1" heading="$2" combined="$3" status="$4" limitation="$5" disposition_authority="$6" kind
  printf '## %s\n\n' "$heading"
  if [[ "$status" != complete ]]; then
    printf 'Collection %s: %s\n\n' "$status" "$(github_field_value "$limitation")"
    if [[ ! -f "$combined" ]] || [[ "$(jq -r '.rows_validated // false' "$combined" 2>/dev/null)" != true ]]; then
      return 0
    fi
  fi
  printf -- '- Repository: `%s`; query scope: `%s(first: 100, states: OPEN, after: $endCursor)`\n' "$(github_field_value "$GITHUB_REPOSITORY")" "$collection"
  printf -- '- Auth status: `authenticated`; page count: `%s`; item count: `%s`; duplicate nodes corroborated: `%s`; contradictory identities: `%s`; terminal pageInfo: `hasNextPage=%s`\n\n' \
    "$(jq -r '.page_count' "$combined")" "$(jq -r '.item_count' "$combined")" "$(jq -r '.duplicate_count' "$combined")" "$(jq -r '.contradiction_count // 0' "$combined")" "$(jq -r '.terminal_page_info.hasNextPage' "$combined")"
  if [[ "$collection" == pullRequests ]]; then
    kind="pr"
  else
    kind="issue"
  fi
  render_github_rows "$kind" "$combined" "$GITHUB_REPOSITORY" "$disposition_authority"
}

collect_github_inventory() {
  local temp_dir disposition_authority=false
  [[ "$GITHUB_STATUS" == not_applicable ]] && github_auth_receipt
  if [[ "$GITHUB_STATUS" == unavailable ]]; then
    printf '## GitHub evidence\n\nCollection unavailable: %s\n\n' "$(github_field_value "$GITHUB_LIMITATION")"
    return
  fi
  GITHUB_TEMP_DIR="$(mktemp -d "${OUTPUT}.github.XXXXXX")"
  temp_dir="$GITHUB_TEMP_DIR"
  collect_github_pull_requests "$GITHUB_REPOSITORY" "$temp_dir"
  collect_github_issues "$GITHUB_REPOSITORY" "$temp_dir"
  if [[ "$GITHUB_PR_STATUS" == complete && "$GITHUB_ISSUE_STATUS" == complete ]]; then
    GITHUB_STATUS="complete"
    GITHUB_EXIT=0
    GITHUB_LIMITATION="Authenticated cursor pagination completed with terminal pageInfo for each namespace."
    disposition_authority=true
  else
    GITHUB_STATUS="partial"
    GITHUB_EXIT="pullRequests:${GITHUB_PR_EXIT};issues:${GITHUB_ISSUE_EXIT}"
    GITHUB_LIMITATION="Aggregate GitHub evidence incomplete; pullRequests=${GITHUB_PR_STATUS} (${GITHUB_PR_EXIT}); issues=${GITHUB_ISSUE_STATUS} (${GITHUB_ISSUE_EXIT}). No namespace has action authority."
  fi
  render_github_collection pullRequests "GitHub open pull requests" "$temp_dir/open-prs.json" "$GITHUB_PR_STATUS" "$GITHUB_PR_LIMITATION" "$disposition_authority"
  render_github_collection issues "GitHub open issues" "$temp_dir/open-issues.json" "$GITHUB_ISSUE_STATUS" "$GITHUB_ISSUE_LIMITATION" "$disposition_authority"
  cleanup_github_temp
}

collect_git_baseline() {
  local repo_root="$1" render_receipts="${2:-yes}"
  local head_sha="$SNAPSHOT_HEAD_SHA" main_sha="$SNAPSHOT_MAIN_SHA" remote_main_sha="$SNAPSHOT_REMOTE_MAIN_SHA"
  local porcelain="" divergence="" status_state="$GIT_BASELINE_STATUS" limitation="$GIT_BASELINE_LIMITATION"
  porcelain="$INITIAL_PORCELAIN"
  divergence="$SNAPSHOT_DIVERGENCE"
  aggregate_snapshot_status
  if [[ "$SNAPSHOT_STATUS" != complete ]]; then
    status_state="partial"
    limitation="One or more requested source receipts are partial or unavailable; do not infer a clean, synchronized, or successful-zero state."
  fi

  FINISHED_AT="$(utc_now)"
  render_front_matter "$repo_root" "$head_sha" "$main_sha" "$remote_main_sha"
  printf '## Collection provenance\n\n'
  printf -- '- Collection window: `%s` to `%s`\n' "$STARTED_AT" "$FINISHED_AT"
  printf -- '- Snapshot boundary: bounded as of `%s`; immutable refs and normalized source receipts are rechecked immediately before atomic publication.\n' "$STARTED_AT"
  printf -- '- Git version: `%s`\n' "$(markdown_value "$(git --version 2>/dev/null || printf unavailable)")"
  printf -- '- Working-tree porcelain v2: `%s`\n' "$(markdown_value "$porcelain")"
  printf -- '- Divergence command: `git rev-list --left-right --count main...%s/main`\n' "$(markdown_value "$REMOTE")"
  if [[ "$divergence" =~ ^([0-9]+)[[:space:]]([0-9]+)$ ]]; then
    printf -- '- Ahead of %s/main (local `main` only): `%s`; behind %s/main (remote only): `%s`\n' "$(markdown_value "$REMOTE")" "${BASH_REMATCH[1]}" "$(markdown_value "$REMOTE")" "${BASH_REMATCH[2]}"
  else
    printf -- '- Ahead/behind counts: unavailable (malformed or missing divergence input).\n'
  fi
  printf -- '- Completeness: `%s`\n' "$status_state"
  printf -- '- Limitation: %s\n\n' "$(markdown_value "$limitation")"
  if [[ "$render_receipts" == yes ]]; then
    render_source_receipts
  fi
}

receipt_fingerprint() {
  local label="$1" path="$2" digest
  digest="$(printf '%s\0' "$label" | cat - "$path" | git hash-object --stdin 2>/dev/null || true)"
  [[ "$digest" =~ ^([0-9a-fA-F]{40}|[0-9a-fA-F]{64})$ ]] || return 1
  printf '%s' "$digest"
}

register_owned_worktree_path() {
  local path="$1"
  [[ -n "$path" ]] || return 0
  OWNED_WORKTREE_PATHS+=("$path")
  if [[ "$path" == "$REPO_ROOT/"* ]]; then
    OWNED_WORKTREE_PATHS+=("${path#"$REPO_ROOT/"}")
  fi
}

porcelain_record_path() {
  local line="$1" path
  case "$line" in
    "? "*|"! "*) printf '%s' "${line:2}" ;;
    "1 "*) printf '%s' "$line" | cut -d ' ' -f9- ;;
    "2 "*) path="$(printf '%s' "$line" | cut -d ' ' -f10-)"; printf '%s' "${path%%$'\t'*}" ;;
    "u "*) printf '%s' "$line" | cut -d ' ' -f11- ;;
    *) return 1 ;;
  esac
}

is_owned_worktree_path() {
  local candidate="$1" owned candidate_parent canonical_candidate="$1"
  if [[ "$candidate" == /* ]]; then
    candidate_parent="$(dirname -- "$candidate")"
    if [[ -d "$candidate_parent" ]]; then
      canonical_candidate="$(cd -P "$candidate_parent" && pwd)/$(basename -- "$candidate")"
    fi
  fi
  for owned in "${OWNED_WORKTREE_PATHS[@]}"; do
    [[ "$candidate" == "$owned" || "$candidate" == "$owned/" || "$canonical_candidate" == "$owned" || "$canonical_candidate" == "$owned/" ]] && return 0
  done
  return 1
}

normalize_worktree_porcelain() {
  local raw="$1" line path
  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ -n "$line" ]] || continue
    if [[ "$line" == "# "* ]]; then
      printf '%s\n' "$line"
    elif path="$(porcelain_record_path "$line")" && is_owned_worktree_path "$path"; then
      :
    else
      printf '%s\n' "$line"
    fi
  done <<< "$raw" | LC_ALL=C sort
}

capture_worktree_projection() {
  local raw
  if ! raw="$(git status --porcelain=v2 --branch 2>/dev/null)"; then
    return 1
  fi
  normalize_worktree_porcelain "$raw"
}

valid_snapshot_sha() {
  local value="$1"
  case "$SNAPSHOT_OBJECT_FORMAT" in
    sha1) [[ "$value" =~ ^[0-9a-fA-F]{40}$ ]] ;;
    sha256) [[ "$value" =~ ^[0-9a-fA-F]{64}$ ]] ;;
    *) return 1 ;;
  esac
}

capture_snapshot_ref() {
  local ref="$1" value
  if value="$(git rev-parse "$ref" 2>/dev/null)" && valid_snapshot_sha "$value"; then
    printf '%s' "$value"
  else
    printf 'unavailable'
  fi
}

validate_worktree_porcelain() {
  local projection="$1" line oid_seen=0 head_seen=0
  while IFS= read -r line || [[ -n "$line" ]]; do
    case "$line" in
      "# branch.oid "*) valid_snapshot_sha "${line#\# branch.oid }" || return 1; oid_seen=1 ;;
      "# branch.head "?*) head_seen=1 ;;
      "# branch.upstream "?*) : ;;
      "# branch.ab +"[0-9]*" -"[0-9]*) [[ "$line" =~ ^#\ branch\.ab\ \+[0-9]+\ -[0-9]+$ ]] || return 1 ;;
      "1 "?*|"2 "?*|"u "?*|"? "?*|"! "?*) : ;;
      *) return 1 ;;
    esac
  done <<< "$projection"
  [[ "$oid_seen" -eq 1 && "$head_seen" -eq 1 ]]
}

capture_phase_review_receipt() {
  local review expected_phase phase status digest
  case "$INVENTORY_REVIEW_PHASE" in
    138)
      review=".planning/phases/138-baseline-inventory-evidence-taxonomy/138-REVIEW.md"
      expected_phase="138-baseline-inventory-evidence-taxonomy"
      ;;
    139)
      review=".planning/phases/139-required-truth-reconciliation/139-REVIEW.md"
      expected_phase="139-required-truth-reconciliation"
      ;;
    *) return 0 ;;
  esac
  PHASE_REVIEW_STATUS="unavailable"
  PHASE_REVIEW_SHA256="unavailable"
  [[ -f "$review" && ! -L "$review" ]] || return 0
  [[ "$(wc -c < "$review" | tr -d ' ')" -le 1048576 ]] || return 0
  phase="$(front_matter_value_from_file "$review" phase 2>/dev/null || true)"
  status="$(front_matter_value_from_file "$review" status 2>/dev/null || true)"
  [[ "$phase" == "$expected_phase" ]] || return 0
  case "$INVENTORY_REVIEW_PHASE:$status" in
    139:clean|138:clean|138:skipped|138:issues_found) : ;;
    *) return 0 ;;
  esac
  digest="$(python3 - "$review" <<'PY'
import hashlib
import pathlib
import sys
print(hashlib.sha256(pathlib.Path(sys.argv[1]).read_bytes()).hexdigest())
PY
)" || return 0
  [[ "$digest" =~ ^[0-9a-f]{64}$ ]] || return 0
  PHASE_REVIEW_STATUS="consumed"
  PHASE_REVIEW_SHA256="$digest"
}

capture_snapshot_identity() {
  STARTED_AT="$(utc_now)"
  if git fetch --prune --tags "$REMOTE" >/dev/null 2>&1; then
    FETCH_EXIT=0
    FETCH_STATUS="complete"
    FETCH_LIMITATION="None. Origin metadata refresh completed."
  else
    FETCH_EXIT=$?
    FETCH_STATUS="unavailable"
    FETCH_LIMITATION="Origin metadata refresh failed; synchronized or clean conclusions are unavailable."
  fi

  if ! SNAPSHOT_OBJECT_FORMAT="$(git rev-parse --show-object-format 2>/dev/null)" ||
    [[ "$SNAPSHOT_OBJECT_FORMAT" != sha1 && "$SNAPSHOT_OBJECT_FORMAT" != sha256 ]]; then
    SNAPSHOT_OBJECT_FORMAT="unavailable"
  fi
  SNAPSHOT_HEAD_SHA="$(capture_snapshot_ref HEAD)"
  SNAPSHOT_MAIN_SHA="$(capture_snapshot_ref main)"
  SNAPSHOT_REMOTE_MAIN_SHA="$(capture_snapshot_ref "$REMOTE/main")"
  if ! SNAPSHOT_REPOSITORY_IDENTITY="$(git rev-parse --show-toplevel 2>/dev/null)"; then
    SNAPSHOT_REPOSITORY_IDENTITY="unavailable"
  fi
  SNAPSHOT_SOURCE_SCOPES="${SCOPE:-git-baseline,git,github,maintained}"
  capture_phase_review_receipt
  EVIDENCE_BASE_SHA="$SNAPSHOT_HEAD_SHA"
  if INITIAL_PORCELAIN="$(capture_worktree_projection)"; then
    if validate_worktree_porcelain "$INITIAL_PORCELAIN"; then
      PORCELAIN_STATUS="complete"
    else
      INITIAL_PORCELAIN=""
      PORCELAIN_STATUS="unavailable"
    fi
  else
    snapshot_abort "Working-tree evidence unavailable during capture: git status --porcelain=v2 --branch failed"
  fi
  if ! SNAPSHOT_DIVERGENCE="$(git rev-list --left-right --count main..."$REMOTE/main" 2>/dev/null)" ||
    [[ ! "$SNAPSHOT_DIVERGENCE" =~ ^[0-9]+[[:space:]][0-9]+$ ]]; then
    SNAPSHOT_DIVERGENCE=""
  fi

  if [[ "$FETCH_STATUS" == complete ]] && valid_snapshot_sha "$SNAPSHOT_HEAD_SHA" &&
    valid_snapshot_sha "$SNAPSHOT_MAIN_SHA" && valid_snapshot_sha "$SNAPSHOT_REMOTE_MAIN_SHA" &&
    [[ "$PORCELAIN_STATUS" == complete && -n "$SNAPSHOT_DIVERGENCE" ]]; then
    GIT_BASELINE_STATUS="complete"
    GIT_BASELINE_LIMITATION="None. Source receipt is complete."
  else
    GIT_BASELINE_STATUS="partial"
    GIT_BASELINE_LIMITATION="Git baseline identity, divergence, or working-tree evidence is missing, malformed, or unavailable; do not infer a clean or synchronized state."
  fi
}

capture_source_receipt_fingerprints() {
  if [[ "$SCOPE" == git || -z "$SCOPE" ]]; then
    GIT_RECEIPT_FINGERPRINT="$(receipt_fingerprint git "$GIT_DOMAINS_OUTPUT")" || die "Git receipt fingerprint unavailable"
  fi
  if [[ "$SCOPE" == github || -z "$SCOPE" ]]; then
    GITHUB_RECEIPT_FINGERPRINT="$(receipt_fingerprint github "$GITHUB_OUTPUT")" || die "GitHub receipt fingerprint unavailable"
  fi
  if [[ "$SCOPE" == maintained || -z "$SCOPE" ]]; then
    MAINTAINED_RECEIPT_FINGERPRINT="$(receipt_fingerprint maintained "$MAINTAINED_OUTPUT")" || die "Maintained receipt fingerprint unavailable"
  fi
}

verify_snapshot_identity_unchanged() {
  local repo_root="$1" current
  current="$(capture_snapshot_ref HEAD)"
  [[ "$current" == "$SNAPSHOT_HEAD_SHA" ]] || snapshot_abort "Snapshot drift: HEAD changed before publication"
  current="$(capture_snapshot_ref main)"
  [[ "$current" == "$SNAPSHOT_MAIN_SHA" ]] || snapshot_abort "Snapshot drift: main changed before publication"
  current="$(capture_snapshot_ref "$REMOTE/main")"
  [[ "$current" == "$SNAPSHOT_REMOTE_MAIN_SHA" ]] || snapshot_abort "Snapshot drift: remote main changed before publication"
  if ! current="$(git rev-parse --show-toplevel 2>/dev/null)"; then current="unavailable"; fi
  [[ "$current" == "$SNAPSHOT_REPOSITORY_IDENTITY" && "$current" == "$repo_root" ]] || snapshot_abort "Snapshot drift: repository identity changed before publication"

  if [[ "$SCOPE" == git || -z "$SCOPE" ]]; then
    RECHECK_OUTPUT="$(mktemp "${OUTPUT}.recheck-git.XXXXXX")"
    collect_git_refs > "$RECHECK_OUTPUT"
    collect_git_tags >> "$RECHECK_OUTPUT"
    collect_git_worktrees >> "$RECHECK_OUTPUT"
    current="$(receipt_fingerprint git "$RECHECK_OUTPUT" || true)"; rm -f "$RECHECK_OUTPUT"; RECHECK_OUTPUT=""
    [[ "$current" == "$GIT_RECEIPT_FINGERPRINT" ]] || snapshot_abort "Snapshot drift: Git receipt changed before publication"
  fi
  if [[ "$SCOPE" == github || -z "$SCOPE" ]]; then
    RECHECK_OUTPUT="$(mktemp "${OUTPUT}.recheck-github.XXXXXX")"
    collect_github_inventory "$repo_root" > "$RECHECK_OUTPUT"
    current="$(receipt_fingerprint github "$RECHECK_OUTPUT" || true)"; rm -f "$RECHECK_OUTPUT"; RECHECK_OUTPUT=""
    [[ "$current" == "$GITHUB_RECEIPT_FINGERPRINT" ]] || snapshot_abort "Snapshot drift: GitHub receipt changed before publication"
  fi
  if [[ "$SCOPE" == maintained || -z "$SCOPE" ]]; then
    RECHECK_OUTPUT="$(mktemp "${OUTPUT}.recheck-maintained.XXXXXX")"
    collect_maintained_records > "$RECHECK_OUTPUT"
    current="$(receipt_fingerprint maintained "$RECHECK_OUTPUT" || true)"; rm -f "$RECHECK_OUTPUT"; RECHECK_OUTPUT=""
    [[ "$current" == "$MAINTAINED_RECEIPT_FINGERPRINT" ]] || snapshot_abort "Snapshot drift: maintained receipt changed before publication"
  fi

  if [[ "$PORCELAIN_STATUS" == complete ]]; then
    if ! current="$(capture_worktree_projection)" || ! validate_worktree_porcelain "$current"; then
      snapshot_abort "Working-tree evidence unavailable during pre-publication recheck: git status --porcelain=v2 --branch failed"
    fi
    [[ "$current" == "$INITIAL_PORCELAIN" ]] || snapshot_abort "Snapshot drift: working tree changed before publication"
  fi
}

snapshot_abort() {
  local message="$1"
  cleanup
  trap - EXIT HUP INT TERM
  die "$message"
}

acquire_output_lock() {
  local target="$1" attempts="${LOCKSPIRE_INVENTORY_LOCK_ATTEMPTS:-200}" attempt=0
  [[ "$attempts" =~ ^[1-9][0-9]*$ ]] || die "LOCKSPIRE_INVENTORY_LOCK_ATTEMPTS must be a positive integer"

  while (( attempt < attempts )); do
    if mkdir "$LOCK_DIR" 2>/dev/null; then
      LOCK_OWNED=1
      return 0
    fi
    attempt=$((attempt + 1))
    (( attempt < attempts )) && sleep 0.01
  done

  die "Another collector holds the target lock: $target"
}

regular_file_identity() {
  local path="$1"
  python3 - "$path" <<'PY'
import hashlib
import os
import stat
import sys

path = sys.argv[1]
st = os.lstat(path)
if not stat.S_ISREG(st.st_mode):
    raise SystemExit(1)
fd = os.open(path, os.O_RDONLY | getattr(os, "O_NOFOLLOW", 0))
try:
    digest = hashlib.sha256()
    while chunk := os.read(fd, 1024 * 1024):
        digest.update(chunk)
finally:
    os.close(fd)
print(f"{st.st_dev}:{st.st_ino}:{st.st_size}:{st.st_mtime_ns}:{digest.hexdigest()}")
PY
}

authorize_output_target() {
  if [[ -L "$OUTPUT" || ( -e "$OUTPUT" && ! -f "$OUTPUT" ) ]]; then
    die "Refusing publication: output must be an exact non-symlink regular file target: $OUTPUT"
  fi
  if [[ -e "$OUTPUT" ]]; then
    [[ "$REPLACE" -eq 1 ]] || die "Refusing to replace existing output without --replace: $OUTPUT"
    OUTPUT_TARGET_IDENTITY="$(regular_file_identity "$OUTPUT")" ||
      die "Refusing publication: output must be an exact non-symlink regular file target: $OUTPUT"
    OUTPUT_TARGET_EXISTED=1
  else
    OUTPUT_TARGET_IDENTITY="absent"
    OUTPUT_TARGET_EXISTED=0
  fi
}

publish_output_atomically() {
  python3 - "$OUTPUT_PARENT" "$(basename "$TEMP_OUTPUT")" "$OUTPUT_BASENAME" \
    "$OUTPUT_TARGET_EXISTED" "$OUTPUT_TARGET_IDENTITY" <<'PY'
import hashlib
import os
import stat
import sys

parent, source, target, existed, expected = sys.argv[1:]
flags = os.O_RDONLY | getattr(os, "O_DIRECTORY", 0) | getattr(os, "O_NOFOLLOW", 0)
directory_fd = os.open(parent, flags)

def identity(name):
    st = os.stat(name, dir_fd=directory_fd, follow_symlinks=False)
    if not stat.S_ISREG(st.st_mode):
        raise RuntimeError("output is no longer a non-symlink regular file")
    fd = os.open(name, os.O_RDONLY | getattr(os, "O_NOFOLLOW", 0), dir_fd=directory_fd)
    try:
        digest = hashlib.sha256()
        while chunk := os.read(fd, 1024 * 1024):
            digest.update(chunk)
    finally:
        os.close(fd)
    return f"{st.st_dev}:{st.st_ino}:{st.st_size}:{st.st_mtime_ns}:{digest.hexdigest()}"

try:
    try:
        current = identity(target)
    except FileNotFoundError:
        current = "absent"
    except RuntimeError as error:
        raise SystemExit(f"Refusing publication: {error}")

    if existed == "1" and current != expected:
        raise SystemExit("Refusing publication: output target changed while the lock was held")
    if existed == "0" and current != "absent":
        raise SystemExit("Refusing publication: absent output target appeared while the lock was held")

    source_stat = os.stat(source, dir_fd=directory_fd, follow_symlinks=False)
    if not stat.S_ISREG(source_stat.st_mode):
        raise SystemExit("Refusing publication: collector temporary output is not a regular file")
    os.replace(source, target, src_dir_fd=directory_fd, dst_dir_fd=directory_fd)
    os.fsync(directory_fd)
finally:
    os.close(directory_fd)
PY
}

stable_evidence_id() {
  local prefix="$1" kind="$2" subject="$3" digest
  if ! digest="$(printf '%s' "${kind}:${subject}" | git hash-object --stdin)"; then
    return 10
  fi
  [[ -n "$digest" ]] || return 11
  [[ "$digest" =~ ^([0-9a-fA-F]{40}|[0-9a-fA-F]{64})$ ]] || return 12
  printf '%s-%s' "$prefix" "${digest:0:12}"
}

sort_evidence_rows() {
  LC_ALL=C sort -t $'\t' -k1,1 -k2,2 -k3,3 -k4,4 -k3,3
}

render_git_inventory() {
  local heading="$1" receipt="$2" rows="$3" status="$4" limitation="$5"
  printf '## %s\n\n' "$heading"
  if [[ "$status" != complete ]]; then
    printf 'Collection %s: %s\n\n' "$status" "$(markdown_value "$limitation")"
  fi
  if [[ -z "$rows" ]]; then
    if [[ "$status" == complete ]]; then
      printf 'No %s observed; query succeeded with 0 results.\n\n' "$heading"
    fi
    return
  fi
  printf '| ID | Kind | Canonical subject | Observed state | Lifecycle | Proposed disposition | Evidence reference | Rationale | Confidence | Recheck proof | Required authority | Executed |\n'
  printf '| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |\n'
  while IFS=$'\t' read -r domain kind subject sha id; do
    [[ -n "$id" ]] || continue
    printf '| %s | %s | `%s` | observed SHA `%s` | active | defer | `%s` | Current non-destructive inventory | direct_current | Revalidate exact target before action | release steward | no — inventory proposal only |\n' \
      "$id" "$kind" "$(markdown_value "$subject")" "$(markdown_value "$sha")" "$receipt"
  done <<< "$rows"
  printf '\n'
}

render_worktree_inventory() {
  local rows_file="$1" status="$2" limitation="$3"
  printf '## Git worktrees\n\n'
  if [[ "$status" != complete ]]; then
    printf 'Collection %s: %s\n\n' "$status" "$(markdown_value "$limitation")"
  fi
  if [[ ! -s "$rows_file" ]]; then
    if [[ "$status" == complete ]]; then
      printf 'No Git worktrees observed; query succeeded with 0 results.\n\n'
    fi
    return
  fi
  printf '| ID | Kind | Canonical subject | Observed state | Lifecycle | Proposed disposition | Evidence reference | Rationale | Confidence | Recheck proof | Required authority | Executed |\n'
  printf '| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |\n'
  while IFS= read -r -d '' id &&
    IFS= read -r -d '' kind &&
    IFS= read -r -d '' subject &&
    IFS= read -r -d '' sha; do
    printf '| %s | %s | `%s` | observed SHA `%s` | active | defer | `%s` | Current non-destructive inventory | direct_current | Revalidate exact target before action | release steward | no — inventory proposal only |\n' \
      "$id" "$kind" "$(markdown_value "$subject")" "$(markdown_value "$sha")" \
      'git worktree list --porcelain -z'
  done < <(
    jq -j -s \
      'sort_by([.domain, .kind, .subject, .sha, .id]) | unique_by([.domain, .kind, .subject, .sha, .id]) | .[] | .id, "\u0000", .kind, "\u0000", .subject, "\u0000", .sha, "\u0000"' \
      "$rows_file"
  )
  printf '\n'
}

aggregate_snapshot_status() {
  SNAPSHOT_STATUS="complete"
  local status
  for status in "$FETCH_STATUS" "$GIT_BASELINE_STATUS" "$BRANCH_STATUS" "$TAG_STATUS" "$WORKTREE_STATUS" "$GITHUB_STATUS" "$MAINTAINED_STATUS"; do
    [[ "$status" == not_applicable || "$status" == complete ]] || SNAPSHOT_STATUS="partial"
  done
}

collect_git_refs() {
  local raw rows="" ref sha kind id malformed=0 id_failed=0
  if ! raw="$(git for-each-ref --format='%(refname)%09%(objectname)' refs/heads refs/remotes 2>/dev/null)"; then
    BRANCH_STATUS="unavailable"; BRANCH_EXIT="nonzero"; BRANCH_LIMITATION="Branch query failed; no empty or clean conclusion is available."
    render_git_inventory "Git branches" "git for-each-ref refs/heads refs/remotes" "" "$BRANCH_STATUS" "$BRANCH_LIMITATION"
    return
  fi
  while IFS=$'\t' read -r ref sha; do
    [[ -z "$ref$sha" ]] && continue
    if ! valid_snapshot_sha "$sha"; then malformed=1; continue; fi
    case "$ref" in
      refs/heads/*) kind="local_branch" ;;
      refs/remotes/*) kind="remote_branch" ;;
      *) malformed=1; continue ;;
    esac
    if id="$(stable_evidence_id "GIT-BR" "$kind" "$ref")"; then
      rows+=$'git\t'"${kind}"$'\t'"${ref}"$'\t'"${sha}"$'\t'"${id}"$'\n'
    else
      id_failed=1
    fi
  done <<< "$raw"
  if [[ "$id_failed" -eq 1 ]]; then
    BRANCH_STATUS="partial"; BRANCH_EXIT="stable_id_generation_failed"; BRANCH_LIMITATION="Stable evidence ID generation failed for one or more observed branches; git hash-object failed or returned an empty or malformed full object digest."
    if [[ "$malformed" -eq 1 ]]; then
      BRANCH_EXIT="malformed_output;stable_id_generation_failed"
      BRANCH_LIMITATION="Malformed branch output and stable evidence ID generation failure were observed; no complete or clean conclusion is available."
    fi
  elif [[ "$malformed" -eq 1 ]]; then
    BRANCH_STATUS="partial"; BRANCH_EXIT="malformed_output"; BRANCH_LIMITATION="Malformed or unknown Git receipt condition in branch output; no empty or clean conclusion is available."
  else
    BRANCH_STATUS="complete"; BRANCH_EXIT=0; BRANCH_LIMITATION="Branch query completed; an empty result is successful-zero evidence."
  fi
  rows="$(printf '%s' "$rows" | sort_evidence_rows | uniq)"
  render_git_inventory "Git branches" "git for-each-ref refs/heads refs/remotes" "$rows" "$BRANCH_STATUS" "$BRANCH_LIMITATION"
}

collect_git_tags() {
  local raw rows="" ref sha id malformed=0 id_failed=0
  if ! raw="$(git for-each-ref --format='%(refname)%09%(objectname)' refs/tags 2>/dev/null)"; then
    TAG_STATUS="unavailable"; TAG_EXIT="nonzero"; TAG_LIMITATION="Tag query failed; no empty or clean conclusion is available."
    render_git_inventory "Git tags" "git for-each-ref refs/tags" "" "$TAG_STATUS" "$TAG_LIMITATION"
    return
  fi
  while IFS=$'\t' read -r ref sha; do
    [[ -z "$ref$sha" ]] && continue
    if [[ ! "$ref" =~ ^refs/tags/.+ ]] || ! valid_snapshot_sha "$sha"; then malformed=1; continue; fi
    if id="$(stable_evidence_id "GIT-TAG" "tag" "$ref")"; then
      rows+=$'git\ttag\t'"${ref}"$'\t'"${sha}"$'\t'"${id}"$'\n'
    else
      id_failed=1
    fi
  done <<< "$raw"
  if [[ "$id_failed" -eq 1 ]]; then
    TAG_STATUS="partial"; TAG_EXIT="stable_id_generation_failed"; TAG_LIMITATION="Stable evidence ID generation failed for one or more observed tags; git hash-object failed or returned an empty or malformed full object digest."
    if [[ "$malformed" -eq 1 ]]; then
      TAG_EXIT="malformed_output;stable_id_generation_failed"
      TAG_LIMITATION="Malformed tag output and stable evidence ID generation failure were observed; no complete or clean conclusion is available."
    fi
  elif [[ "$malformed" -eq 1 ]]; then
    TAG_STATUS="partial"; TAG_EXIT="malformed_output"; TAG_LIMITATION="Malformed Git tag output; no empty or clean conclusion is available."
  else
    TAG_STATUS="complete"; TAG_EXIT=0; TAG_LIMITATION="Tag query completed; an empty result is successful-zero evidence."
  fi
  rows="$(printf '%s' "$rows" | sort_evidence_rows | uniq)"
  render_git_inventory "Git tags" "git for-each-ref refs/tags" "$rows" "$TAG_STATUS" "$TAG_LIMITATION"
}

finalize_worktree_stanza() {
  local path="$1" sha="$2" rows_file="$3" id
  [[ -n "$path" ]] || return 0
  [[ -n "$sha" ]] && valid_snapshot_sha "$sha" || return 20
  id="$(stable_evidence_id "GIT-WT" "worktree" "$path")" || return 21
  jq -nc \
    --arg domain git --arg kind worktree --arg subject "$path" --arg sha "$sha" --arg id "$id" \
    '{domain: $domain, kind: $kind, subject: $subject, sha: $sha, id: $id}' >> "$rows_file" || return 22
}

collect_git_worktrees() {
  local raw_file rows_file line path="" sha="" finalize_status=0 malformed=0 id_failed=0 structured_failed=0
  raw_file="$(mktemp "${TMPDIR:-/tmp}/lockspire-worktrees.raw.XXXXXX")"
  rows_file="$(mktemp "${TMPDIR:-/tmp}/lockspire-worktrees.rows.XXXXXX")"
  if ! git worktree list --porcelain -z > "$raw_file" 2>/dev/null; then
    WORKTREE_STATUS="unavailable"; WORKTREE_EXIT="nonzero"; WORKTREE_LIMITATION="Worktree query failed; no empty or clean conclusion is available."
    render_worktree_inventory "$rows_file" "$WORKTREE_STATUS" "$WORKTREE_LIMITATION"
    rm -f -- "$raw_file" "$rows_file"
    return
  fi
  while IFS= read -r -d '' line || [[ -n "$line" ]]; do
    case "$line" in
      "worktree "*)
        if [[ -n "$path" ]]; then
          malformed=1
          if finalize_worktree_stanza "$path" "$sha" "$rows_file"; then
            :
          else
            finalize_status=$?
            [[ "$finalize_status" -eq 20 ]] && malformed=1
            [[ "$finalize_status" -eq 21 ]] && id_failed=1
            [[ "$finalize_status" -eq 22 ]] && structured_failed=1
          fi
        fi
        path="${line#worktree }"; sha="" ;;
      "HEAD "*)
        if [[ -z "$path" || -n "$sha" ]]; then
          malformed=1
        fi
        sha="${line#HEAD }"; valid_snapshot_sha "$sha" || malformed=1 ;;
      "branch "*|detached|bare|locked*|prunable*)
        [[ -n "$path" ]] || malformed=1 ;;
      "")
        if finalize_worktree_stanza "$path" "$sha" "$rows_file"; then
          :
        else
          finalize_status=$?
          [[ "$finalize_status" -eq 20 ]] && malformed=1
          [[ "$finalize_status" -eq 21 ]] && id_failed=1
          [[ "$finalize_status" -eq 22 ]] && structured_failed=1
        fi
        path=""; sha="" ;;
      *) malformed=1 ;;
    esac
  done < "$raw_file"
  if [[ -n "$path" || -n "$sha" ]]; then
    malformed=1
    if finalize_worktree_stanza "$path" "$sha" "$rows_file"; then
      :
    else
      finalize_status=$?
      [[ "$finalize_status" -eq 20 ]] && malformed=1
      [[ "$finalize_status" -eq 21 ]] && id_failed=1
      [[ "$finalize_status" -eq 22 ]] && structured_failed=1
    fi
  fi
  if ! jq -e -s 'all(.[]; type == "object" and keys == ["domain", "id", "kind", "sha", "subject"] and .domain == "git" and .kind == "worktree" and (.subject | type) == "string" and (.subject | length) > 0 and (.sha | type) == "string" and (.id | type) == "string")' "$rows_file" >/dev/null 2>&1; then
    structured_failed=1
  fi
  if [[ "$structured_failed" -eq 1 ]]; then
    WORKTREE_STATUS="partial"; WORKTREE_EXIT="structured_record_failure"; WORKTREE_LIMITATION="Structured worktree record encoding or validation failed; no complete or clean conclusion is available."
  elif [[ "$id_failed" -eq 1 ]]; then
    WORKTREE_STATUS="partial"; WORKTREE_EXIT="stable_id_generation_failed"; WORKTREE_LIMITATION="Stable evidence ID generation failed for one or more observed worktrees; git hash-object failed or returned an empty or malformed full object digest."
    if [[ "$malformed" -eq 1 ]]; then
      WORKTREE_EXIT="malformed_output;stable_id_generation_failed"
      WORKTREE_LIMITATION="Malformed worktree stanza output was observed. Stable evidence ID generation failed for one or more observed worktrees; no complete or clean conclusion is available."
    fi
  elif [[ "$malformed" -eq 1 ]]; then
    WORKTREE_STATUS="partial"; WORKTREE_EXIT="malformed_output"; WORKTREE_LIMITATION="Malformed worktree stanza; no empty or clean conclusion is available."
  else
    WORKTREE_STATUS="complete"; WORKTREE_EXIT=0; WORKTREE_LIMITATION="Worktree query completed; an empty result is successful-zero evidence."
  fi
  render_worktree_inventory "$rows_file" "$WORKTREE_STATUS" "$WORKTREE_LIMITATION"
  rm -f -- "$raw_file" "$rows_file"
}

canonical_record_subject() {
  local path="$1"
  # Identity is a normalized tracked subject, never the discovery family or order.
  path="${path#./}"
  printf '%s' "$path" | LC_ALL=C tr '[:upper:]' '[:lower:]'
}

record_has_line() {
  local record_file="$1" pattern="$2"
  LC_ALL=C grep -Eq -- "$pattern" "$record_file"
}

record_has_markdown_heading() {
  local record_file="$1" heading="$2"
  awk -v wanted="$heading" '
    BEGIN {
      fence_char = ""; fence_len = 0; in_comment = 0
      in_front_matter = 0; found = 0
    }
    {
      line = $0
      if (NR == 1 && line == "---") { in_front_matter = 1; next }
      if (in_front_matter) {
        if (line == "---") in_front_matter = 0
        next
      }
      rendered = ""
      while (length(line) > 0) {
        if (in_comment) {
          close_at = index(line, "-->")
          if (close_at == 0) { line = ""; break }
          line = substr(line, close_at + 3)
          in_comment = 0
        } else {
          open_at = index(line, "<!--")
          if (open_at == 0) { rendered = rendered line; line = "" }
          else {
            rendered = rendered substr(line, 1, open_at - 1)
            line = substr(line, open_at + 4)
            in_comment = 1
          }
        }
      }
      line = rendered

      trimmed = line
      indent = 0
      while (substr(trimmed, 1, 1) == " " && indent < 4) {
        trimmed = substr(trimmed, 2)
        indent++
      }
      if (indent >= 4 || substr(trimmed, 1, 1) == "\t") next
      if (fence_char != "") {
        run = 0
        while (substr(trimmed, run + 1, 1) == fence_char) run++
        rest = substr(trimmed, run + 1)
        if (run >= fence_len && rest ~ /^[[:space:]]*$/) {
          fence_char = ""
          fence_len = 0
        }
        next
      }

      first = substr(trimmed, 1, 1)
      if (first == "`" || first == "~") {
        run = 0
        while (substr(trimmed, run + 1, 1) == first) run++
        if (run >= 3) { fence_char = first; fence_len = run; next }
      }

      sub(/[[:space:]]+$/, "", trimmed)
      if (trimmed == wanted) found = 1
    }
    END { exit(found ? 0 : 1) }
  ' "$record_file"
}

classify_active_record() {
  local path="$1" record_file="$2" status
  status="$(front_matter_value_from_file "$record_file" status 2>/dev/null || true)"

  case "$path" in
    *-REVIEW-FIX.md)
      record_has_line "$record_file" '^# .*Review Fix Report[[:space:]]*$' || return 1
      record_has_line "$record_file" '^## Fixed Issues[[:space:]]*$' || return 1
      case "$status" in
        all_fixed) printf 'resolved\talready-resolved\tdirect_current' ;;
        *) return 1 ;;
      esac
      ;;
    *-REVIEW.md)
      record_has_line "$record_file" '^# .*(Code )?Review( Report)?[[:space:]]*$' || return 1
      record_has_line "$record_file" '^## (Summary|Findings)[[:space:]]*$' || return 1
      case "$status" in
        issues_found) printf 'active\tfix-now\tdirect_current' ;;
        clean|skipped) printf 'resolved\talready-resolved\tdirect_current' ;;
        *) return 1 ;;
      esac
      ;;
    *-VERIFICATION.md)
      record_has_line "$record_file" '^# .*Verification( Report)?[[:space:]]*$' || return 1
      record_has_line "$record_file" '^## Goal Achievement[[:space:]]*$' || return 1
      case "$status" in
        gaps_found) printf 'active\tfix-now\tdirect_current' ;;
        passed) printf 'resolved\talready-resolved\tdirect_current' ;;
        *) return 1 ;;
      esac
      ;;
    *-UAT.md)
      record_has_markdown_heading "$record_file" '## Current Test' || return 1
      record_has_markdown_heading "$record_file" '## Tests' || return 1
      case "$status" in
        complete) printf 'resolved\talready-resolved\tdirect_current' ;;
        partial) printf 'active\tdefer-with-trigger\tdirect_current' ;;
        *) return 1 ;;
      esac
      ;;
    *) return 1 ;;
  esac
}

classify_record() {
  local family="$1" path="$2" record_file="$3" fragment="$4" lower archive_action
  lower="$(LC_ALL=C tr '[:upper:]' '[:lower:]' < "$record_file")"

  # Active lifecycle records are authorities by document structure and exact
  # frontmatter status, not by incidental prose in their first 80 lines.
  if [[ "$family" == active-records ]] &&
    classify_active_record "$path" "$record_file"; then
    return
  fi

  # Exact UAT suffixes without valid structured lifecycle evidence must stay
  # visible as ambiguous; their body prose cannot supply disposition authority.
  if [[ "$family" == active-records && "$path" == *-UAT.md ]]; then
    printf 'unclassified\tunclassified\tinferred'
    return
  fi

  # Archive expansion and lifecycle classification consume the same structured
  # authority. One positive action marker outranks incidental body prose;
  # contradictory structured markers remain unclassified and fail visible.
  if is_archive_family "$family"; then
    archive_action="$(structured_archive_action "$record_file")"
    case "$archive_action" in
      actionable) printf 'active\tfix-now\tdirect_current'; return ;;
      ambiguous) printf 'unclassified\tunclassified\tinferred'; return ;;
    esac
  fi

  # D-17 names these current planning authorities explicitly. Classify them only
  # when both their canonical singleton path and stable document structure agree;
  # a renamed, swapped, or draft-shaped lookalike remains ambiguous.
  case "${family}:${path}" in
    roadmap:.planning/ROADMAP.md)
      if record_has_line "$record_file" '^# Lockspire Roadmap[[:space:]]*$' &&
        record_has_line "$record_file" '^## Phases[[:space:]]*$'; then
        printf 'active\tdefer-with-trigger\tdirect_current'
      else
        printf 'unclassified\tunclassified\tinferred'
      fi
      return
      ;;
    state:.planning/STATE.md)
      if record_has_line "$record_file" '^# Project State[[:space:]]*$' &&
        record_has_line "$record_file" '^## Current Position[[:space:]]*$'; then
        printf 'active\tdefer-with-trigger\tdirect_current'
      else
        printf 'unclassified\tunclassified\tinferred'
      fi
      return
      ;;
    project:.planning/PROJECT.md)
      if record_has_line "$record_file" '^# Lockspire[[:space:]]*$' &&
        record_has_line "$record_file" '^## Current Milestone:[[:space:]]+.+$'; then
        printf 'active\tdefer-with-trigger\tdirect_current'
      else
        printf 'unclassified\tunclassified\tinferred'
      fi
      return
      ;;
    release-train:.planning/RELEASE-TRAIN.md)
      if record_has_line "$record_file" '^# Lockspire Release Train[[:space:]]*$' &&
        record_has_line "$record_file" '^## Current Baseline[[:space:]]*$'; then
        printf 'active\tdefer-with-trigger\tdirect_current'
      else
        printf 'unclassified\tunclassified\tinferred'
      fi
      return
      ;;
    development-train:.planning/DEVELOPMENT-TRAIN.md)
      if record_has_line "$record_file" '^# Lockspire Development Train[[:space:]]*$' &&
        record_has_line "$record_file" '^## Default Posture[[:space:]]*$'; then
        printf 'active\tdefer-with-trigger\tdirect_current'
      else
        printf 'unclassified\tunclassified\tinferred'
      fi
      return
      ;;
  esac

  # Threads are a bounded family rather than a singleton. Only the explicit
  # active cross-session status is authoritative; headings copied from another
  # planning family do not grant a disposition.
  if [[ "$family" == threads ]] &&
    record_has_line "$record_file" '^# .+[^[:space:]][[:space:]]*$' &&
    record_has_line "$record_file" '^\*\*Status:\*\*[[:space:]]+Active cross-session context[[:space:]]*$' &&
    record_has_line "$record_file" '^\*\*Purpose:\*\*[[:space:]]+.+$'; then
    printf 'active\tdefer-with-trigger\tcorroborated'
    return
  fi

  case "$lower" in
    *"terminal proof"*|*"already resolved"*) printf 'resolved\talready-resolved\tdirect_current' ;;
    *"retain historical"*|*"fulfilled archive"*) printf 'historical\tretain-historical\tcorroborated' ;;
    *"out of scope"*) printf 'incidental\tout-of-scope\tcorroborated' ;;
    *"fix-now"*|*"actionable"*) printf 'active\tfix-now\tdirect_current' ;;
    *"todo"*|*"fixme"*|*"follow-up"*|*"defer"*|*"trigger"*) printf 'active\tdefer-with-trigger\tcorroborated' ;;
    *) printf 'unclassified\tunclassified\tinferred' ;;
  esac
}

valid_maintained_taxonomy() {
  local lifecycle="$1" disposition="$2" confidence="$3"
  [[ "$lifecycle" =~ ^(active|resolved|historical|incidental)$ ]] || return 1
  [[ "$confidence" =~ ^(direct_current|corroborated|inferred)$ ]] || return 1
  [[ "$disposition" =~ ^(fix-now|defer-with-trigger|retain-historical|already-resolved|out-of-scope)$ ]]
}

summarize_archive_container() {
  local family="$1" directory="$2" count="$3" subject id
  subject="${family} archive container (${count} retained records)"
  id="$(stable_evidence_id REC archive "$subject")"
  maintained_record_json \
    "$id" archive_summary "$subject" "$family" historical retain-historical "$directory" \
    "Archive summary preserves fulfilled history; expansion requires unresolved, contradictory, ambiguous, or actionable evidence" \
    corroborated "Revalidate any expanded record before action" "repository maintainer"
}

maintained_record_json() {
  local id="$1" kind="$2" canonical_identity="$3" family="$4" lifecycle="$5"
  local disposition="$6" evidence="$7" rationale="$8" confidence="$9"
  local recheck="${10}" authority="${11}"
  id="$(display_normalize "$id")"
  kind="$(display_normalize "$kind")"
  canonical_identity="$(display_normalize "$canonical_identity")"
  family="$(display_normalize "$family")"
  lifecycle="$(display_normalize "$lifecycle")"
  disposition="$(display_normalize "$disposition")"
  evidence="$(display_normalize "$evidence")"
  rationale="$(display_normalize "$rationale")"
  confidence="$(display_normalize "$confidence")"
  recheck="$(display_normalize "$recheck")"
  authority="$(display_normalize "$authority")"
  jq -cn \
    --arg id "$id" \
    --arg kind "$kind" \
    --arg canonical_identity "$canonical_identity" \
    --arg subject "$canonical_identity" \
    --arg family "$family" \
    --arg observed_state "observed allowlisted source" \
    --arg lifecycle "$lifecycle" \
    --arg disposition "$disposition" \
    --arg evidence "$evidence" \
    --arg rationale "$rationale" \
    --arg confidence "$confidence" \
    --arg recheck "$recheck" \
    --arg authority "$authority" \
    --arg executed "no" \
    '{id:$id, kind:$kind, canonical_identity:$canonical_identity, subject:$subject,
      families:[$family], observed_state:$observed_state, lifecycle:$lifecycle,
      disposition:$disposition, evidence_refs:[$evidence], rationales:[$rationale],
      confidence:$confidence, rechecks:[$recheck], authority:$authority, executed:$executed}'
}

deduplicate_record_refs() {
  # Retain named semantics until the final field-specific Markdown encoding step.
  jq -cs '
    def nonempty_string: type == "string" and length > 0;
    def string_array: type == "array" and all(.[]; nonempty_string);
    def valid_record:
      type == "object" and
      (.id | nonempty_string) and (.kind | nonempty_string) and
      (.canonical_identity | type == "string") and (.subject | type == "string") and
      (.families | string_array) and (.observed_state | nonempty_string) and
      (.lifecycle | nonempty_string) and (.disposition | nonempty_string) and
      (.evidence_refs | string_array) and (.rationales | string_array) and
      (.confidence | nonempty_string) and (.rechecks | string_array) and
      (.authority | nonempty_string) and (.executed | nonempty_string);
    if all(.[]; valid_record) then
      group_by(.id)
      | map(
          . as $records
          | $records[0] as $first
          | if all($records[];
              .kind == $first.kind and
              .canonical_identity == $first.canonical_identity and
              .subject == $first.subject and
              .observed_state == $first.observed_state and
              .lifecycle == $first.lifecycle and
              .disposition == $first.disposition and
              .confidence == $first.confidence and
              .authority == $first.authority and
              .executed == $first.executed)
            then $first + {
              families: ([$records[].families[]] | unique | sort),
              evidence_refs: ([$records[].evidence_refs[]] | unique | sort),
              rationales: ([$records[].rationales[]] | unique | sort),
              rechecks: ([$records[].rechecks[]] | unique | sort)
            }
            else error("conflicting maintained semantics for " + $first.id)
            end
        )
      | sort_by(.subject, .id)
      | .[]
    else error("invalid maintained record")
    end
  '
}

render_maintained_inventory() {
  local rows_file="$1" record id kind subject observed_state lifecycle disposition evidence rationale confidence recheck authority executed
  printf '## Maintained Records\n\n'
  printf 'Observed maintained follow-up evidence. Revalidation required before action; every disposition is proposal-only.\n\n'
  printf '| ID | Kind | Canonical subject | Observed state | Lifecycle | Proposed disposition | Evidence reference | Rationale | Confidence | Recheck proof | Required authority | Executed |\n'
  printf '| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |\n'
  if [[ ! -s "$rows_file" ]]; then
    printf '| REC-NONE | source_receipt | No maintained records observed | no allowlisted rows | incidental | out-of-scope | `allowlisted source-family manifest` | Collection completed with no per-record evidence | direct_current | Revalidate source families before action | repository maintainer | no — inventory proposal only |\n\n'
    return
  fi
  while IFS= read -r record; do
    id="$(jq -er '.id' <<< "$record")" || return 1
    kind="$(jq -er '.kind' <<< "$record")" || return 1
    subject="$(jq -er '.subject' <<< "$record")" || return 1
    observed_state="$(jq -er '.observed_state' <<< "$record")" || return 1
    lifecycle="$(jq -er '.lifecycle' <<< "$record")" || return 1
    disposition="$(jq -er '.disposition' <<< "$record")" || return 1
    evidence="$(jq -er '.evidence_refs | join("; ")' <<< "$record")" || return 1
    rationale="$(jq -er '.rationales | join("; ")' <<< "$record")" || return 1
    confidence="$(jq -er '.confidence' <<< "$record")" || return 1
    recheck="$(jq -er '.rechecks | join("; ")' <<< "$record")" || return 1
    authority="$(jq -er '.authority' <<< "$record")" || return 1
    executed="$(jq -er '.executed' <<< "$record")" || return 1
    [[ -n "$id" ]] || continue
    printf '| %s | %s | `%s` | %s | %s | %s | `%s` | %s | %s | %s | %s | %s |\n' \
      "$(markdown_normalized_value "$id")" "$(markdown_normalized_value "$kind")" \
      "$(markdown_normalized_value "$subject")" "$(markdown_normalized_value "$observed_state")" \
      "$(markdown_normalized_value "$lifecycle")" "$(markdown_normalized_value "$disposition")" \
      "$(markdown_normalized_value "$evidence")" "$(markdown_normalized_value "$rationale")" \
      "$(markdown_normalized_value "$confidence")" "$(markdown_normalized_value "$recheck")" \
      "$(markdown_normalized_value "$authority")" "$(markdown_normalized_value "$executed")"
  done < "$rows_file"
  printf '\n'
}

render_maintained_receipts() {
  local receipts="$1"
  printf '## Maintained source-family receipts\n\n'
  printf '| Family | Status | Selector | Outcome |\n| --- | --- | --- | --- |\n'
  printf '%s' "$receipts"
  printf '\n'
}

maintained_receipt_row() {
  local family="$1" status="$2" selector="$3" outcome="$4"
  printf '| %s | %s | `%s` | %s |' \
    "$(markdown_value "$family")" "$(markdown_value "$status")" \
    "$(markdown_value "$selector")" "$(markdown_value "$outcome")"
}

is_excluded_maintained_path() { [[ "$1" =~ $MAINTAINED_EXCLUDED_PATHS ]]; }

is_archive_family() { [[ "$1" =~ ^(debug|quick|milestones)$ ]]; }

structured_archive_action() {
  local authoritative_blob="$1" has_action=0 has_terminal=0

  if LC_ALL=C grep -Eqi \
    '^[[:space:]]*([-*][[:space:]]+)?fix-now([[:space:][:punct:]]|$)|^[[:space:]]*(status|outcome|disposition):[[:space:]]*(actionable|unresolved|contradictory|ambiguous|blocked)([[:space:]]|$)|^#{1,6}[[:space:]]+(actionable|unresolved|contradictions?|ambiguous)([[:space:][:punct:]]|$)' \
    "$authoritative_blob"; then
    has_action=1
  fi

  if LC_ALL=C grep -Eqi \
    '^[[:space:]]*(status|outcome|disposition):[[:space:]]*(resolved|complete|completed|clean|passed|skipped|historical|incidental|already-resolved|retain-historical|out-of-scope)([[:space:]]|$)' \
    "$authoritative_blob"; then
    has_terminal=1
  fi

  if [[ "$has_action" -eq 1 && "$has_terminal" -eq 1 ]]; then
    printf 'ambiguous'
  elif [[ "$has_action" -eq 1 ]]; then
    printf 'actionable'
  else
    printf 'none'
  fi
}

requires_archive_expansion() {
  local authoritative_blob="$1" action
  # Historical plans and reviews routinely discuss ambiguous inputs or the
  # absence of contradictory claims. Those incidental words are not current
  # action authority. Expand only explicit disposition/status markers or a
  # dedicated actionable heading; scan the complete blob so late markers are
  # still authoritative while the rendered excerpt remains bounded.
  action="$(structured_archive_action "$authoritative_blob")"
  [[ "$action" != none ]]
}

phase_138_gaps_report_superseded() {
  local report="$1" summary plan
  [[ "$report" == .planning/phases/138-baseline-inventory-evidence-taxonomy/138-VERIFICATION.md ]] || return 1
  grep -q '^status: gaps_found$' "$MAINTAINED_RECORD_OUTPUT" || return 1
  grep -q 'Aggregate GitHub failure can retain' "$MAINTAINED_RECORD_OUTPUT" || return 1
  grep -q 'Capture immutable baseline refs before all collection' "$MAINTAINED_RECORD_OUTPUT" || return 1
  grep -q 'ID-generation failure silently drops' "$MAINTAINED_RECORD_OUTPUT" || return 1
  grep -q 'Use NUL-delimited Git output' "$MAINTAINED_RECORD_OUTPUT" || return 1

  for plan in 07 08 09 10; do
    summary=".planning/phases/138-baseline-inventory-evidence-taxonomy/138-${plan}-SUMMARY.md"
    git show "$MAINTAINED_TREEISH:$summary" 2>/dev/null | awk 'NR == 1 && $0 == "---" { front = 1; next } front && $0 == "---" { exit } front { print }' | grep -q '^status: complete$' || return 1
  done
}

front_matter_value_from_blob() {
  local commit="$1" path="$2" key="$3" raw
  raw="$(git show "$commit:$path" 2>/dev/null | awk -v key="$key" '
    NR == 1 && $0 == "---" { front = 1; next }
    front && $0 == "---" { exit }
    front && index($0, key ":") == 1 { sub("^[^:]+:[[:space:]]*", ""); print; count++ }
    END { if (count != 1) exit 1 }
  ')" || return 1
  if [[ "$raw" == \"* ]]; then
    printf '%s' "$raw" | jq -er 'if type == "string" then . else error("frontmatter value is not a string") end'
  else
    printf '%s' "$raw"
  fi
}

front_matter_value_from_file() {
  local path="$1" key="$2" raw
  [[ -f "$path" && -s "$path" ]] || return 1
  raw="$(awk -v key="$key" '
    NR == 1 && $0 == "---" { front = 1; next }
    front && $0 == "---" { exit }
    front && index($0, key ":") == 1 { sub("^[^:]+:[[:space:]]*", ""); print; count++ }
    END { if (count != 1) exit 1 }
  ' "$path")" || return 1
  if [[ "$raw" == \"* ]]; then
    printf '%s' "$raw" | jq -er 'if type == "string" then . else error("frontmatter value is not a string") end'
  else
    printf '%s' "$raw"
  fi
}

snapshot_ledger_source_declared() {
  local declared="$1" source="$2"
  [[ ",$declared," == *",$source,"* ]]
}

validate_snapshot_ledger_schema() {
  local commit="$1" ledger="$2" blob phase scope status started finished repository repository_identity
  local declared local_head evidence_base local_main origin_main executed source fingerprint object_format expected_declared
  local review_status review_sha review_status_count review_sha_count
  blob="$(git show "$commit:$ledger" 2>/dev/null)" || return 1
  [[ "$(printf '%s\n' "$blob" | grep -c '^---$')" -eq 2 ]] || return 1
  [[ "$(printf '%s\n' "$blob" | sed -n '1p')" == --- ]] || return 1
  printf '%s\n' "$blob" | awk '
    NR == 1 && $0 == "---" { front = 1; next }
    front && $0 == "---" { closed = 1; exit }
    END { exit !(front && closed) }
  ' || return 1

  phase="$(front_matter_value_from_blob "$commit" "$ledger" phase 2>/dev/null)" || return 1
  scope="$(front_matter_value_from_blob "$commit" "$ledger" scope 2>/dev/null)" || return 1
  status="$(front_matter_value_from_blob "$commit" "$ledger" status 2>/dev/null)" || return 1
  started="$(front_matter_value_from_blob "$commit" "$ledger" collection_started_at 2>/dev/null)" || return 1
  finished="$(front_matter_value_from_blob "$commit" "$ledger" collection_finished_at 2>/dev/null)" || return 1
  repository="$(front_matter_value_from_blob "$commit" "$ledger" repository 2>/dev/null)" || return 1
  repository_identity="$(front_matter_value_from_blob "$commit" "$ledger" repository_identity 2>/dev/null)" || return 1
  declared="$(front_matter_value_from_blob "$commit" "$ledger" declared_source_scopes 2>/dev/null)" || return 1
  local_head="$(front_matter_value_from_blob "$commit" "$ledger" local_head_sha 2>/dev/null)" || return 1
  evidence_base="$(front_matter_value_from_blob "$commit" "$ledger" evidence_base_sha 2>/dev/null)" || return 1
  local_main="$(front_matter_value_from_blob "$commit" "$ledger" local_main_sha 2>/dev/null)" || return 1
  origin_main="$(front_matter_value_from_blob "$commit" "$ledger" origin_main_sha 2>/dev/null)" || return 1
  executed="$(front_matter_value_from_blob "$commit" "$ledger" executed 2>/dev/null)" || return 1

  review_status_count="$(git show "$commit:$ledger" 2>/dev/null | grep -Ec '^phase_review_status:' || true)"
  review_sha_count="$(git show "$commit:$ledger" 2>/dev/null | grep -Ec '^phase_review_sha256:' || true)"
  [[ "$review_status_count" -eq "$review_sha_count" ]] || return 1
  if [[ "$review_status_count" -ne 0 ]]; then
    [[ "$review_status_count" -eq 1 ]] || return 1
    review_status="$(front_matter_value_from_blob "$commit" "$ledger" phase_review_status 2>/dev/null)" || return 1
    review_sha="$(front_matter_value_from_blob "$commit" "$ledger" phase_review_sha256 2>/dev/null)" || return 1
    if [[ "$review_status" == consumed ]]; then
      [[ "$review_sha" =~ ^[0-9a-f]{64}$ ]] || return 1
    else
      [[ "$review_status" == unavailable && "$review_sha" == unavailable ]] || return 1
    fi
  fi

  [[ "$phase" == 138 && "$status" == complete ]] || return 1
  [[ "$scope" == "" || "$scope" == git-baseline || "$scope" == git || "$scope" == github || "$scope" == maintained ]] || return 1
  expected_declared="${scope:-git-baseline,git,github,maintained}"
  [[ "$declared" == "$expected_declared" ]] || return 1
  [[ "$started" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$ ]] || return 1
  [[ "$finished" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$ ]] || return 1
  [[ "$finished" > "$started" || "$finished" == "$started" ]] || return 1
  [[ "$repository" == "$(git rev-parse --show-toplevel 2>/dev/null)" && "$repository_identity" == "$repository" ]] || return 1
  [[ "$executed" == "no — inventory proposal only" ]] || return 1

  object_format="$(git rev-parse --show-object-format 2>/dev/null)" || return 1
  case "$object_format" in
    sha1) [[ "$local_head" =~ ^[0-9a-fA-F]{40}$ && "$evidence_base" =~ ^[0-9a-fA-F]{40}$ && "$local_main" =~ ^[0-9a-fA-F]{40}$ ]] || return 1 ;;
    sha256) [[ "$local_head" =~ ^[0-9a-fA-F]{64}$ && "$evidence_base" =~ ^[0-9a-fA-F]{64}$ && "$local_main" =~ ^[0-9a-fA-F]{64}$ ]] || return 1 ;;
    *) return 1 ;;
  esac
  if [[ "$origin_main" != unavailable ]]; then
    case "$object_format" in
      sha1) [[ "$origin_main" =~ ^[0-9a-fA-F]{40}$ ]] || return 1 ;;
      sha256) [[ "$origin_main" =~ ^[0-9a-fA-F]{64}$ ]] || return 1 ;;
    esac
  fi

  for source in git github maintained; do
    fingerprint="$(front_matter_value_from_blob "$commit" "$ledger" "${source}_receipt_fingerprint" 2>/dev/null)" || return 1
    if snapshot_ledger_source_declared "$declared" "$source"; then
      case "$object_format" in
        sha1) [[ "$fingerprint" =~ ^[0-9a-fA-F]{40}$ ]] || return 1 ;;
        sha256) [[ "$fingerprint" =~ ^[0-9a-fA-F]{64}$ ]] || return 1 ;;
      esac
    else
      [[ "$fingerprint" == not_applicable ]] || return 1
    fi
  done
}

exact_path_set() {
  local actual="$1" required_pattern="$2" allowed_pattern="$3"
  [[ "$(printf '%s\n' "$actual" | sed '/^$/d' | grep -Ec "$required_pattern")" -eq 1 ]] || return 1
  ! printf '%s\n' "$actual" | sed '/^$/d' | grep -Evq "$allowed_pattern"
}

blob_is_nonempty_regular_file() {
  local commit="$1" path="$2" size
  [[ "$(git cat-file -t "$commit:$path" 2>/dev/null || true)" == blob ]] || return 1
  size="$(git cat-file -s "$commit:$path" 2>/dev/null || true)"
  [[ "$size" =~ ^[1-9][0-9]*$ ]]
}

commit_path_is_regular_write() {
  local commit="$1" path="$2" raw status
  raw="$(git diff-tree --no-commit-id --raw -r "$commit" -- "$path" 2>/dev/null | sed '/^$/d')"
  [[ "$(wc -l <<< "$raw" | tr -d ' ')" -eq 1 ]] || return 1
  status="$(awk '{print $5}' <<< "$raw")"
  [[ "$status" =~ ^[AM]$ ]] || return 1
  blob_is_nonempty_regular_file "$commit" "$path"
}

all_commit_paths_are_regular_writes() {
  local commit="$1" paths="$2" path
  while IFS= read -r path; do
    [[ -n "$path" ]] || continue
    commit_path_is_regular_write "$commit" "$path" || return 1
  done <<< "$paths"
}

blob_has_line() {
  local commit="$1" path="$2" pattern="$3"
  git show "$commit:$path" 2>/dev/null | LC_ALL=C grep -E -- "$pattern" >/dev/null
}

validate_phase_plan_document() {
  local commit="$1" path="$2" plan declared
  commit_path_is_regular_write "$commit" "$path" || return 1
  plan="$(basename "$path" | sed -E 's/^138-([0-9][0-9])-PLAN\.md$/\1/')"
  [[ "$plan" =~ ^[0-9][0-9]$ ]] || return 1
  [[ "$(front_matter_value_from_blob "$commit" "$path" phase 2>/dev/null)" == 138-baseline-inventory-evidence-taxonomy ]] || return 1
  declared="$(front_matter_value_from_blob "$commit" "$path" plan 2>/dev/null || true)"
  [[ "$declared" =~ ^[0-9]{1,2}$ ]] || return 1
  [[ "$(printf '%02d' "$((10#$declared))")" == "$plan" ]] || return 1
  blob_has_line "$commit" "$path" '^<objective>$' || return 1
  blob_has_line "$commit" "$path" '^<tasks>$' || return 1
  blob_has_line "$commit" "$path" '^<task type="(auto|tracer|checkpoint:[^"]+)"' || return 1
}

validate_phase_state_document() {
  local commit="$1" path="$2" expected_status="$3" parent old_phase old_status
  commit_path_is_regular_write "$commit" "$path" || return 1
  parent="$(git rev-parse "$commit^" 2>/dev/null)" || return 1
  old_phase="$(front_matter_value_from_blob "$parent" "$path" current_phase 2>/dev/null || true)"
  old_status="$(front_matter_value_from_blob "$parent" "$path" status 2>/dev/null || true)"
  [[ "$old_phase" == 138 && "$old_status" == executing ]] || return 1
  [[ "$(front_matter_value_from_blob "$commit" "$path" current_phase 2>/dev/null)" == 138 ]] || return 1
  case "$expected_status:$(front_matter_value_from_blob "$commit" "$path" status 2>/dev/null)" in
    executing_or_verifying:executing|executing_or_verifying:verifying) : ;;
    "$expected_status:$expected_status") : ;;
    *) return 1 ;;
  esac
  blob_has_line "$commit" "$path" '^# Project State$' || return 1
  blob_has_line "$commit" "$path" '^## Current Position$' || return 1
}

validate_phase_roadmap_document() {
  local commit="$1" path="$2" completion="$3" parent
  commit_path_is_regular_write "$commit" "$path" || return 1
  parent="$(git rev-parse "$commit^" 2>/dev/null)" || return 1
  blob_has_line "$parent" "$path" '^# .*[Rr]oadmap$' || return 1
  blob_has_line "$commit" "$path" '^# .*[Rr]oadmap$' || return 1
  blob_has_line "$commit" "$path" '^## Phases' || return 1
  blob_has_line "$commit" "$path" 'Phase 138' || return 1
  [[ "$completion" != yes ]] || blob_has_line "$commit" "$path" 'Phase 138.*([Cc]omplete|✅)'
}

validate_phase_requirements_document() {
  local commit="$1" path="$2" completion="$3" parent
  commit_path_is_regular_write "$commit" "$path" || return 1
  parent="$(git rev-parse "$commit^" 2>/dev/null)" || return 1
  blob_has_line "$parent" "$path" '^# .*Requirements' || return 1
  blob_has_line "$commit" "$path" '^# .*Requirements' || return 1
  blob_has_line "$commit" "$path" 'BASE-01' || return 1
  [[ "$completion" != yes ]] || blob_has_line "$commit" "$path" '(BASE-01.*([Cc]omplete|\[x\])|\[x\].*BASE-01)'
}

validate_state_contract_document() {
  local commit="$1" path="$2" expected_phase="$3" expected_status="$4"
  commit_path_is_regular_write "$commit" "$path" || return 1
  git show "$commit:$path" 2>/dev/null | jq -e \
    --arg phase "$expected_phase" \
    --arg status "$expected_status" '
      .contract == "1.0.0" and
      (.phases | type == "array") and
      any(.phases[]; .number == $phase and .status == $status)
    ' >/dev/null
}

validate_summary_companions() {
  local commit="$1" paths="$2" path
  while IFS= read -r path; do
    case "$path" in
      *-SUMMARY.md) : ;;
      *-PLAN.md) validate_phase_plan_document "$commit" "$path" || return 1 ;;
      .planning/STATE.md) validate_phase_state_document "$commit" "$path" executing_or_verifying || return 1 ;;
      .planning/ROADMAP.md) validate_phase_roadmap_document "$commit" "$path" no || return 1 ;;
      .planning/REQUIREMENTS.md) validate_phase_requirements_document "$commit" "$path" no || return 1 ;;
      .planning/state.json) validate_state_contract_document "$commit" "$path" 138 in_progress || return 1 ;;
      *) return 1 ;;
    esac
  done <<< "$paths"
}

validate_phase_summary_commit() {
  local commit="$1" paths="$2" summary plan declared_plan
  exact_path_set "$paths" '^\.planning/phases/138-baseline-inventory-evidence-taxonomy/138-[0-9][0-9]-SUMMARY\.md$' '^\.planning/phases/138-baseline-inventory-evidence-taxonomy/138-[0-9][0-9]-(PLAN|SUMMARY)\.md$|^\.planning/(STATE|ROADMAP|REQUIREMENTS)\.md$|^\.planning/state\.json$' || return 1
  all_commit_paths_are_regular_writes "$commit" "$paths" || return 1
  validate_summary_companions "$commit" "$paths" || return 1
  summary="$(printf '%s\n' "$paths" | grep -- '-SUMMARY.md$')"
  plan="$(basename "$summary" | sed -E 's/^138-([0-9][0-9])-SUMMARY\.md$/\1/')"
  declared_plan="$(front_matter_value_from_blob "$commit" "$summary" plan 2>/dev/null || true)"
  [[ "$declared_plan" =~ ^[0-9]{1,2}$ ]] || return 1
  declared_plan="$(printf '%02d' "$((10#$declared_plan))")"
  [[ "$(front_matter_value_from_blob "$commit" "$summary" phase 2>/dev/null)" == 138-baseline-inventory-evidence-taxonomy ]] || return 1
  [[ "$declared_plan" == "$plan" ]] || return 1
  [[ "$(front_matter_value_from_blob "$commit" "$summary" status 2>/dev/null)" == complete ]] || return 1
  blob_has_line "$commit" "$summary" '^requirements-completed:[[:space:]]*\[.*\][[:space:]]*$' || return 1
  blob_has_line "$commit" "$summary" "^# Phase 138 Plan ${plan#0}: .+ Summary$" || return 1
  for heading in '## Accomplishments' '## Task Commits' '## Files Created/Modified' '## Decisions Made' '## Deviations from Plan' '## Issues Encountered' '## Next Phase Readiness' '## Self-Check: PASSED'; do
    blob_has_line "$commit" "$summary" "^${heading}$" || return 1
  done
}

front_matter_indented_integer_from_blob() {
  local commit="$1" path="$2" key="$3"
  git show "$commit:$path" 2>/dev/null | awk -v key="$key" '
    NR == 1 && $0 == "---" { front = 1; next }
    front && $0 == "---" { exit }
    front && $0 ~ "^[[:space:]]+" key ":[[:space:]]*[0-9]+[[:space:]]*$" {
      sub("^[[:space:]]+" key ":[[:space:]]*", ""); print; count++
    }
    END { if (count != 1) exit 1 }
  '
}

commit_path_diff_lines_match() {
  local commit="$1" path="$2" removed_pattern="$3" added_pattern="$4" line
  while IFS= read -r line; do
    case "$line" in
      ---\ *|+++\ *) : ;;
      -|"+") : ;;
      -*) [[ "$line" =~ $removed_pattern ]] || return 1 ;;
      +*) [[ "$line" =~ $added_pattern ]] || return 1 ;;
    esac
  done < <(git diff --no-ext-diff --unified=0 "$commit^" "$commit" -- "$path" 2>/dev/null)
}

commit_path_diff_line_count() {
  local commit="$1" path="$2" prefix="$3"
  git diff --no-ext-diff --unified=0 "$commit^" "$commit" -- "$path" 2>/dev/null |
    awk -v prefix="$prefix" 'index($0, prefix) == 1 && $0 !~ /^(---|\+\+\+) / { count++ } END { print count + 0 }'
}

bounded_front_matter_from_blob() {
  local commit="$1" path="$2"
  git show "$commit:$path" 2>/dev/null | awk '
    NR == 1 && $0 == "---" { front = 1; next }
    front && $0 == "---" { closed++; front = 0; next }
    front { print }
    END { if (closed != 1) exit 1 }
  '
}

front_matter_string_list_from_blob() {
  local commit="$1" path="$2" key="$3" encoded raw decoded
  encoded="$(
    bounded_front_matter_from_blob "$commit" "$path" | awk -v key="$key" '
      index($0, key ":") == 1 {
        found++
        if (found != 1 || $0 !~ ("^" key ":[[:space:]]*$")) exit 1
        in_list = 1
        next
      }
      in_list && /^[^[:space:]]/ { in_list = 0 }
      in_list && /^  - / {
        sub(/^  - /, "")
        print
        entries++
        next
      }
      in_list && /^[[:space:]]*$/ { next }
      in_list { exit 1 }
      END { if (found != 1 || entries < 1) exit 1 }
    '
  )" || return 1
  while IFS= read -r raw; do
    [[ "$raw" == \"*\" ]] || return 1
    decoded="$(printf '%s' "$raw" | jq -er 'if type == "string" then . else error("frontmatter list value is not a string") end')" || return 1
    [[ -n "$decoded" && "$decoded" != *$'\n'* ]] || return 1
    printf '%s\n' "$decoded"
  done <<< "$encoded"
}

front_matter_nested_integer_from_blob() {
  local commit="$1" path="$2" parent_key="$3" key="$4"
  bounded_front_matter_from_blob "$commit" "$path" | awk -v parent_key="$parent_key" -v key="$key" '
    index($0, parent_key ":") == 1 {
      parents++
      if (parents != 1 || $0 !~ ("^" parent_key ":[[:space:]]*$")) exit 1
      in_parent = 1
      next
    }
    in_parent && /^[^[:space:]]/ { in_parent = 0 }
    in_parent && $0 ~ ("^  " key ":[[:space:]]*[0-9]+[[:space:]]*$") {
      sub("^  " key ":[[:space:]]*", "")
      sub(/[[:space:]]*$/, "")
      print
      values++
    }
    END { if (parents != 1 || values != 1) exit 1 }
  '
}

front_matter_nested_string_list_from_blob() {
  local commit="$1" path="$2" parent_key="$3" key="$4" encoded raw decoded
  encoded="$(
    bounded_front_matter_from_blob "$commit" "$path" | awk -v parent_key="$parent_key" -v key="$key" '
      index($0, parent_key ":") == 1 {
        parents++
        if (parents != 1 || $0 !~ ("^" parent_key ":[[:space:]]*$")) exit 1
        in_parent = 1
        next
      }
      in_parent && /^[^[:space:]]/ { in_parent = 0; in_list = 0 }
      in_parent && $0 ~ ("^  " key ":[[:space:]]*$") {
        lists++
        if (lists != 1) exit 1
        in_list = 1
        next
      }
      in_list && /^  [^[:space:]]/ { in_list = 0 }
      in_list && /^    - / {
        sub(/^    - /, "")
        print
        entries++
        next
      }
      in_list && /^[[:space:]]*$/ { next }
      in_list { exit 1 }
      END { if (parents != 1 || lists != 1 || entries < 1) exit 1 }
    '
  )" || return 1
  while IFS= read -r raw; do
    if [[ "$raw" == \"*\" ]]; then
      decoded="$(printf '%s' "$raw" | jq -er 'if type == "string" then . else error("frontmatter list value is not a string") end')" || return 1
    else
      decoded="$raw"
    fi
    [[ -n "$decoded" && "$decoded" != *$'\n'* ]] || return 1
    printf '%s\n' "$decoded"
  done <<< "$encoded"
}

normalize_gsd_duration() {
  printf '%s\n' "$1" | awk '{$1 = $1; print}'
}

front_matter_top_level_key_count() {
  local front="$1" key="$2"
  printf '%s\n' "$front" | awk -v key="$key" 'index($0, key ":") == 1 { count++ } END { print count + 0 }'
}

validate_gsd_closeout_summary() {
  local commit="$1" path="$2" plan="$3" parent blob front coverage_requirements key
  parent="$(git rev-parse "$commit^" 2>/dev/null)" || return 1
  ! git cat-file -e "$parent:$path" 2>/dev/null || return 1
  commit_path_is_regular_write "$commit" "$path" || return 1
  blob="$(git show "$commit:$path" 2>/dev/null)" || return 1
  [[ "$(printf '%s\n' "$blob" | grep -c '^---$')" -eq 2 ]] || return 1
  [[ "$(printf '%s\n' "$blob" | sed -n '1p')" == --- ]] || return 1
  front="$(bounded_front_matter_from_blob "$commit" "$path")" || return 1
  for key in phase plan status requirements-completed coverage; do
    [[ "$(front_matter_top_level_key_count "$front" "$key")" -eq 1 ]] || return 1
  done
  [[ "$(front_matter_value_from_blob "$commit" "$path" phase 2>/dev/null)" == 138-baseline-inventory-evidence-taxonomy ]] || return 1
  [[ "$(front_matter_value_from_blob "$commit" "$path" plan 2>/dev/null)" == "${plan#0}" || "$(front_matter_value_from_blob "$commit" "$path" plan 2>/dev/null)" == "$plan" ]] || return 1
  [[ "$(front_matter_value_from_blob "$commit" "$path" status 2>/dev/null)" == complete ]] || return 1
  printf '%s\n' "$front" | grep -Eq '^requirements-completed:[[:space:]]*\[BASE-01,[[:space:]]*BASE-02,[[:space:]]*TRIAGE-01,[[:space:]]*TRIAGE-02,[[:space:]]*LOOSE-01\][[:space:]]*$' || return 1
  coverage_requirements="$(printf '%s\n' "$front" | awk '
    /^coverage:[[:space:]]*$/ { coverage = 1; next }
    coverage && /^[^[:space:]]/ { exit }
    coverage && /^[[:space:]]+requirement:[[:space:]]*/ {
      sub("^[[:space:]]+requirement:[[:space:]]*", ""); print
    }
  ' | LC_ALL=C sort)"
  [[ "$coverage_requirements" == $'BASE-01\nBASE-02\nLOOSE-01\nTRIAGE-01\nTRIAGE-02' ]] || return 1
  blob_has_line "$commit" "$path" "^# Phase 138 Plan ${plan#0}: .+ Summary$" || return 1
  for heading in '## Accomplishments' '## Task Commits' '## Files Created/Modified' '## Decisions Made' '## Deviations from Plan' '## Issues Encountered' '## Next Phase Readiness' '## Self-Check: PASSED'; do
    blob_has_line "$commit" "$path" "^${heading}$" || return 1
  done
}

validate_gsd_closeout_roadmap() {
  local commit="$1" path="$2" plan="$3" parent old_count new_count old_total new_total
  parent="$(git rev-parse "$commit^" 2>/dev/null)" || return 1
  commit_path_is_regular_write "$commit" "$path" || return 1
  old_count="$(git show "$parent:$path" | sed -nE 's/^\*\*Plans\*\*:[[:space:]]*([0-9]+)\/([0-9]+) plans executed$/\1/p')"
  old_total="$(git show "$parent:$path" | sed -nE 's/^\*\*Plans\*\*:[[:space:]]*([0-9]+)\/([0-9]+) plans executed$/\2/p')"
  new_count="$(git show "$commit:$path" | sed -nE 's/^\*\*Plans\*\*:[[:space:]]*([0-9]+)\/([0-9]+) plans executed$/\1/p')"
  new_total="$(git show "$commit:$path" | sed -nE 's/^\*\*Plans\*\*:[[:space:]]*([0-9]+)\/([0-9]+) plans executed$/\2/p')"
  [[ "$old_count" =~ ^[0-9]+$ && "$new_count" =~ ^[0-9]+$ && "$old_total" == "$new_total" ]] || return 1
  [[ "$new_count" -eq "$((old_count + 1))" && "$new_count" -eq "$((10#$plan))" && "$new_total" -eq "$new_count" ]] || return 1
  blob_has_line "$parent" "$path" "^- \[ \] 138-${plan}-PLAN\.md([[:space:]]|$)" || return 1
  blob_has_line "$commit" "$path" "^- \[x\] 138-${plan}-PLAN\.md([[:space:]]|$)" || return 1
  blob_has_line "$parent" "$path" "^\| 138\. Baseline Inventory & Evidence Taxonomy \| ${old_count}/${old_total} \| In Progress\|[[:space:]]*\|$" || return 1
  blob_has_line "$commit" "$path" "^\| 138\. Baseline Inventory & Evidence Taxonomy \| ${new_count}/${new_total} \| In Progress\|[[:space:]]*\|$" || return 1
  [[ "$(commit_path_diff_line_count "$commit" "$path" -)" -eq 3 ]] || return 1
  [[ "$(commit_path_diff_line_count "$commit" "$path" +)" -eq 3 ]] || return 1
  commit_path_diff_lines_match "$commit" "$path" \
    "^-\\*\\*Plans\\*\\*:[[:space:]]*${old_count}/${old_total} plans executed$|^-\\- \\[ \\] 138-${plan}-PLAN\\.md|^-\\| 138\\. Baseline Inventory & Evidence Taxonomy \\| ${old_count}/${old_total} \\| In Progress\\|[[:space:]]*\\|$" \
    "^\\+\\*\\*Plans\\*\\*:[[:space:]]*${new_count}/${new_total} plans executed$|^\\+\\- \\[x\\] 138-${plan}-PLAN\\.md|^\\+\\| 138\\. Baseline Inventory & Evidence Taxonomy \\| ${new_count}/${new_total} \\| In Progress\\|[[:space:]]*\\|$"
}

validate_gsd_closeout_state() {
  local commit="$1" path="$2" plan="$3" summary="$4" parent old_count new_count old_total new_total state_head
  local canonical_commit state_decision summary_decisions decision_count unique_decision_count
  local summary_duration summary_tasks summary_files summary_file_count unique_summary_file_count
  local performance_row state_duration state_tasks state_files
  parent="$(git rev-parse "$commit^" 2>/dev/null)" || return 1
  commit_path_is_regular_write "$commit" "$path" || return 1
  [[ "$(front_matter_value_from_blob "$parent" "$path" current_phase 2>/dev/null)" == 138 ]] || return 1
  [[ "$(front_matter_value_from_blob "$commit" "$path" current_phase 2>/dev/null)" == 138 ]] || return 1
  [[ "$(front_matter_value_from_blob "$parent" "$path" status 2>/dev/null)" == executing ]] || return 1
  [[ "$(front_matter_value_from_blob "$commit" "$path" status 2>/dev/null)" == verifying ]] || return 1
  [[ "$(front_matter_value_from_blob "$commit" "$path" stopped_at 2>/dev/null)" == "Completed 138-${plan}-PLAN.md" ]] || return 1
  state_head="$(front_matter_value_from_blob "$commit" "$path" state_head 2>/dev/null)"
  [[ "$state_head" == "$parent" ]] || return 1
  old_count="$(front_matter_indented_integer_from_blob "$parent" "$path" completed_plans)" || return 1
  new_count="$(front_matter_indented_integer_from_blob "$commit" "$path" completed_plans)" || return 1
  old_total="$(front_matter_indented_integer_from_blob "$parent" "$path" total_plans)" || return 1
  new_total="$(front_matter_indented_integer_from_blob "$commit" "$path" total_plans)" || return 1
  [[ "$new_count" -eq "$((old_count + 1))" && "$new_count" -eq "$((10#$plan))" && "$old_total" == "$new_total" && "$new_total" -eq "$new_count" ]] || return 1
  blob_has_line "$commit" "$path" '^# Project State$' || return 1
  blob_has_line "$commit" "$path" '^## Current Position$' || return 1
  blob_has_line "$commit" "$path" '^Status:[[:space:]]+Phase complete — ready for verification$' || return 1
  blob_has_line "$commit" "$path" "^Stopped at:[[:space:]]+Completed 138-${plan}-PLAN\.md$" || return 1
  blob_has_line "$commit" "$path" "^\| Phase 138 P${plan#0} \|" || return 1
  canonical_commit="$(git rev-parse "$commit" 2>/dev/null)" || return 1
  if [[ "$canonical_commit" != c872cd23d4bee940ad34485d28de2791ee7f8245 || "$plan" != 29 ]]; then
    summary_decisions="$(front_matter_string_list_from_blob "$commit" "$summary" key-decisions)" || return 1
    decision_count="$(printf '%s\n' "$summary_decisions" | awk 'NF { count++ } END { print count + 0 }')"
    unique_decision_count="$(printf '%s\n' "$summary_decisions" | LC_ALL=C sort -u | awk 'NF { count++ } END { print count + 0 }')"
    [[ "$decision_count" -eq "$unique_decision_count" ]] || return 1
    state_decision="$(git diff --no-ext-diff --unified=0 "$commit^" "$commit" -- "$path" 2>/dev/null | awk '
      /^\+- \[Phase 138\]: / {
        sub(/^\+- \[Phase 138\]: /, "")
        print
        count++
      }
      END { if (count != 1) exit 1 }
    ')" || return 1
    [[ -n "$state_decision" ]] || return 1
    printf '%s\n' "$summary_decisions" | grep -Fqx -- "$state_decision" || return 1

    summary_duration="$(front_matter_value_from_blob "$commit" "$summary" duration 2>/dev/null)" || return 1
    summary_duration="$(normalize_gsd_duration "$summary_duration")"
    [[ -n "$summary_duration" ]] || return 1
    summary_tasks="$(front_matter_nested_integer_from_blob "$commit" "$summary" actuals tasks)" || return 1
    summary_files="$(front_matter_nested_string_list_from_blob "$commit" "$summary" key-files modified)" || return 1
    summary_file_count="$(printf '%s\n' "$summary_files" | awk -v summary="$summary" 'NF && $0 != summary { count++ } END { print count + 0 }')"
    unique_summary_file_count="$(printf '%s\n' "$summary_files" | LC_ALL=C sort -u | awk 'NF { count++ } END { print count + 0 }')"
    [[ "$unique_summary_file_count" -eq "$(printf '%s\n' "$summary_files" | awk 'NF { count++ } END { print count + 0 }')" ]] || return 1
    performance_row="$(git diff --no-ext-diff --unified=0 "$commit^" "$commit" -- "$path" 2>/dev/null | awk -v plan="${plan#0}" '
      $0 ~ ("^\\+\\| Phase 138 P" plan " \\| [^|]+ \\| [0-9]+ tasks \\| [0-9]+ files \\|$") {
        print
        count++
      }
      END { if (count != 1) exit 1 }
    ')" || return 1
    state_duration="$(printf '%s\n' "$performance_row" | awk -F'|' '{ value=$3; gsub(/^[[:space:]]+|[[:space:]]+$/, "", value); print value }')"
    state_tasks="$(printf '%s\n' "$performance_row" | awk -F'|' '{ value=$4; gsub(/^[[:space:]]+|[[:space:]]+tasks[[:space:]]*$/, "", value); print value }')"
    state_files="$(printf '%s\n' "$performance_row" | awk -F'|' '{ value=$5; gsub(/^[[:space:]]+|[[:space:]]+files[[:space:]]*$/, "", value); print value }')"
    state_duration="$(normalize_gsd_duration "$state_duration")"
    [[ "$state_duration" == "$summary_duration" ]] || return 1
    [[ "$state_tasks" =~ ^(0|[1-9][0-9]*)$ && "$summary_tasks" =~ ^(0|[1-9][0-9]*)$ && "$state_tasks" == "$summary_tasks" ]] || return 1
    [[ "$state_files" =~ ^(0|[1-9][0-9]*)$ && "$state_files" == "$summary_file_count" ]] || return 1
  fi
  [[ "$(commit_path_diff_line_count "$commit" "$path" -)" -eq 6 ]] || return 1
  [[ "$(commit_path_diff_line_count "$commit" "$path" +)" -eq 8 ]] || return 1
  commit_path_diff_lines_match "$commit" "$path" \
    '^-status:|^-stopped_at:|^-last_updated:|^-state_head:|^-[[:space:]]+completed_plans:|^-Status:|^-Last session:|^-Stopped at:' \
    "^\\+status:[[:space:]]*verifying$|^\\+stopped_at:[[:space:]]*Completed 138-${plan}-PLAN\\.md$|^\\+last_updated:|^\\+state_head:[[:space:]]*${parent}$|^\\+[[:space:]]+completed_plans:[[:space:]]*${new_count}$|^\\+Status:[[:space:]]+Phase complete — ready for verification$|^\\+- \\[Phase 138\\]:|^\\+Last session:|^\\+Stopped at:[[:space:]]+Completed 138-${plan}-PLAN\\.md$|^\\+\\| Phase 138 P${plan#0} \\|"
}

validate_gsd_closeout_state_contract() {
  local commit="$1" path="$2" parent old new
  parent="$(git rev-parse "$commit^" 2>/dev/null)" || return 1
  commit_path_is_regular_write "$commit" "$path" || return 1
  old="$(git show "$parent:$path" 2>/dev/null)" || return 1
  new="$(git show "$commit:$path" 2>/dev/null)" || return 1
  jq -e '.contract == "1.0.0" and any(.phases[]; .number == "138" and .status == "in_progress") and .next.command == "/gsd:progress --next" and .next.label == "Advance to the next step" and .next.reason == "Phase 138 of 4 · executing"' <<< "$old" >/dev/null || return 1
  jq -e '.contract == "1.0.0" and any(.phases[]; .number == "138" and .status == "in_progress") and .next.command == "/gsd:progress --next" and .next.label == "Advance to the next step (verify)" and .next.reason == "Phase 138 of 4 · ready to verify" and (.updated_at | test("^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}(\\.[0-9]+)?Z$"))' <<< "$new" >/dev/null || return 1
  [[ "$(jq -Sc 'del(.next, .updated_at)' <<< "$old")" == "$(jq -Sc 'del(.next, .updated_at)' <<< "$new")" ]]
}

validate_gsd_plan_closeout_commit() {
  local commit="$1" paths="$2" plan="$3" summary
  summary=".planning/phases/138-baseline-inventory-evidence-taxonomy/138-${plan}-SUMMARY.md"
  [[ "$paths" == ".planning/ROADMAP.md"$'\n'".planning/STATE.md"$'\n'"${summary}"$'\n'".planning/state.json" ]] || return 1
  all_commit_paths_are_regular_writes "$commit" "$paths" || return 1
  validate_gsd_closeout_summary "$commit" "$summary" "$plan" || return 1
  validate_gsd_closeout_roadmap "$commit" .planning/ROADMAP.md "$plan" || return 1
  validate_gsd_closeout_state "$commit" .planning/STATE.md "$plan" "$summary" || return 1
  validate_gsd_closeout_state_contract "$commit" .planning/state.json || return 1
}

validate_review_commit() {
  local commit="$1" path="$2" parent old_status current_status
  commit_path_is_regular_write "$commit" "$path" || return 1
  [[ "$(front_matter_value_from_blob "$commit" "$path" phase 2>/dev/null)" == 138-baseline-inventory-evidence-taxonomy ]] || return 1
  current_status="$(front_matter_value_from_blob "$commit" "$path" status 2>/dev/null || true)"
  [[ "$current_status" == clean || "$current_status" == skipped ]] || return 1
  blob_has_line "$commit" "$path" '^# Phase 138: .+Review( Report)?$' || return 1
  blob_has_line "$commit" "$path" '^## (Summary|Findings)$' || return 1
  parent="$(git rev-parse "$commit^" 2>/dev/null || true)"
  if git cat-file -e "$parent:$path" 2>/dev/null; then
    old_status="$(front_matter_value_from_blob "$parent" "$path" status 2>/dev/null || true)"
    [[ "$old_status" == issues_found && "$old_status" != "$current_status" ]] || return 1
  fi
}

validate_verification_commit() {
  local commit="$1" path="$2" parent parent_status
  commit_path_is_regular_write "$commit" "$path" || return 1
  [[ "$(front_matter_value_from_blob "$commit" "$path" phase 2>/dev/null)" == 138-baseline-inventory-evidence-taxonomy ]] || return 1
  [[ "$(front_matter_value_from_blob "$commit" "$path" status 2>/dev/null)" == passed ]] || return 1
  parent="$(git rev-parse "$commit^" 2>/dev/null)" || return 1
  parent_status="$(front_matter_value_from_blob "$parent" "$path" status 2>/dev/null || true)"
  if [[ "$parent_status" == passed ]]; then
    blob_has_line "$parent" "$path" '^gaps:[[:space:]]*(\[\]|0)[[:space:]]*$' || return 1
    blob_has_line "$parent" "$path" '^behavior_unverified:[[:space:]]*0[[:space:]]*$' || return 1
    blob_has_line "$parent" "$path" '^human_needed:[[:space:]]*false[[:space:]]*$' || return 1
    blob_has_line "$commit" "$path" '^[[:space:]]+previous_status:[[:space:]]+passed[[:space:]]*$' || return 1
    blob_has_line "$commit" "$path" '^[[:space:]]+gaps_remaining:[[:space:]]+\[\][[:space:]]*$' || return 1
    blob_has_line "$commit" "$path" '^[[:space:]]+regressions:[[:space:]]+\[\][[:space:]]*$' || return 1
  else
    verification_gap_report_is_superseded "$commit" "$path" || return 1
  fi
  blob_has_line "$commit" "$path" '^gaps:[[:space:]]*(\[\]|0)[[:space:]]*$' || return 1
  blob_has_line "$commit" "$path" '^behavior_unverified:[[:space:]]*0[[:space:]]*$' || return 1
  blob_has_line "$commit" "$path" '^human_needed:[[:space:]]*false[[:space:]]*$' || return 1
  blob_has_line "$commit" "$path" '^# Phase 138: .+Verification( Report)?$' || return 1
  blob_has_line "$commit" "$path" '^## Goal Achievement$' || return 1
}

validate_phase_completion_commit() {
  local commit="$1" paths="$2" state=.planning/STATE.md parent path state_head parent_stopped_at stopped_at
  exact_path_set "$paths" '^\.planning/STATE\.md$' '^\.planning/(ROADMAP|STATE|REQUIREMENTS)\.md$|^\.planning/state\.json$|^\.planning/phases/138-baseline-inventory-evidence-taxonomy/138-VERIFICATION\.md$' || return 1
  all_commit_paths_are_regular_writes "$commit" "$paths" || return 1
  parent="$(git rev-parse "$commit^" 2>/dev/null || true)"
  [[ "$(front_matter_value_from_blob "$parent" "$state" current_phase 2>/dev/null)" == 138 ]] || return 1
  [[ "$(front_matter_value_from_blob "$commit" "$state" current_phase 2>/dev/null)" == 139 ]] || return 1
  [[ "$(front_matter_value_from_blob "$parent" "$state" status 2>/dev/null)" == verifying ]] || return 1
  [[ "$(front_matter_value_from_blob "$commit" "$state" status 2>/dev/null)" == planning ]] || return 1
  [[ "$(front_matter_value_from_blob "$commit" "$state" current_phase_name 2>/dev/null)" == 'Required Truth Reconciliation' ]] || return 1
  parent_stopped_at="$(front_matter_value_from_blob "$parent" "$state" stopped_at 2>/dev/null || true)"
  stopped_at="$(front_matter_value_from_blob "$commit" "$state" stopped_at 2>/dev/null || true)"
  case "$stopped_at" in
    'Phase 138 complete, ready to plan Phase 139') : ;;
    *)
      [[ "$stopped_at" =~ ^Completed[[:space:]]138-[0-9][0-9]-PLAN\.md$ && "$parent_stopped_at" == "$stopped_at" ]] || return 1
      ;;
  esac
  state_head="$(front_matter_value_from_blob "$commit" "$state" state_head 2>/dev/null)"
  [[ "$state_head" == "$parent" ]] || return 1
  blob_has_line "$commit" "$state" '^# Project State$' || return 1
  blob_has_line "$commit" "$state" '^## Current Position$' || return 1
  blob_has_line "$commit" "$state" '^Phase:[[:space:]]+139([[:space:]]|$)' || return 1
  blob_has_line "$commit" "$state" '^Plan:[[:space:]]+Not started$' || return 1
  blob_has_line "$commit" "$state" '^Status:[[:space:]]+Ready to plan$' || return 1
  ! blob_has_line "$parent" "$state" '^Status:[[:space:]]+Ready to plan$' || return 1
  while IFS= read -r path; do
    case "$path" in
      .planning/STATE.md) : ;;
      .planning/ROADMAP.md) validate_phase_roadmap_document "$commit" "$path" yes || return 1 ;;
      .planning/REQUIREMENTS.md) validate_phase_requirements_document "$commit" "$path" yes || return 1 ;;
      .planning/state.json) validate_phase_completion_state_contract "$commit" "$path" || return 1 ;;
      .planning/phases/138-baseline-inventory-evidence-taxonomy/138-VERIFICATION.md)
        validate_verification_commit "$commit" "$path" || return 1 ;;
      *) return 1 ;;
    esac
  done <<< "$paths"
}

validate_phase_completion_state_contract() {
  local commit="$1" path="$2"
  commit_path_is_regular_write "$commit" "$path" || return 1
  git show "$commit:$path" 2>/dev/null | jq -e '
    .contract == "1.0.0" and
    (.phases | type == "array") and
    ([.phases[] | select(.number == "138" and .status == "complete")] | length) == 1 and
    ([.phases[] | select(.number == "139" and .status == "in_progress")] | length) == 1 and
    (.next.label | type == "string" and test("phase 139"; "i")) and
    (.next.reason | type == "string" and test("Phase 139"))
  ' >/dev/null
}

validate_transition_commit() {
  local commit="$1" paths="$2" parent project=.planning/PROJECT.md state=.planning/STATE.md status parent_state_head state_head
  [[ "$paths" == $'.planning/PROJECT.md\n.planning/STATE.md' ]] || return 1
  all_commit_paths_are_regular_writes "$commit" "$paths" || return 1
  parent="$(git rev-parse "$commit^" 2>/dev/null || true)"
  [[ "$(front_matter_value_from_blob "$parent" "$state" current_phase 2>/dev/null)" == 139 ]] || return 1
  [[ "$(front_matter_value_from_blob "$commit" "$state" current_phase 2>/dev/null)" == 139 ]] || return 1
  [[ "$(front_matter_value_from_blob "$parent" "$state" status 2>/dev/null)" == planning ]] || return 1
  status="$(front_matter_value_from_blob "$commit" "$state" status 2>/dev/null || true)"
  [[ "$status" == planning ]] || return 1
  parent_state_head="$(front_matter_value_from_blob "$parent" "$state" state_head 2>/dev/null)"
  state_head="$(front_matter_value_from_blob "$commit" "$state" state_head 2>/dev/null)"
  [[ -n "$parent_state_head" && "$state_head" == "$parent_state_head" ]] || return 1
  blob_has_line "$commit" "$state" '^# Project State$' || return 1
  blob_has_line "$commit" "$state" '^## Current Position$' || return 1
  blob_has_line "$commit" "$state" '^Status:[[:space:]]+Ready to plan$' || return 1
  blob_has_line "$parent" "$project" '^## Current Milestone:[[:space:]]+v1\.38([[:space:]]|$)' || return 1
  ! blob_has_line "$parent" "$project" '^Phase 138 completed the v1\.38 evidence foundation\.' || return 1
  blob_has_line "$commit" "$project" '^# Lockspire$' || return 1
  blob_has_line "$commit" "$project" '^## Current Milestone:[[:space:]]+v1\.38([[:space:]]|$)' || return 1
  blob_has_line "$commit" "$project" '^Phase 138 completed the v1\.38 evidence foundation\..*Phase 139 now owns' || return 1
  blob_has_line "$commit" "$project" '^\*Last updated:[[:space:]]+[0-9]{4}-[0-9]{2}-[0-9]{2} after Phase 138\*$' || return 1
}

validate_phase_139_plan_closeout_commit() {
  local commit="$1" paths="$2" plan="$3" summary state=.planning/STATE.md
  summary=".planning/phases/139-required-truth-reconciliation/139-${plan}-SUMMARY.md"
  [[ "$paths" == ".planning/ROADMAP.md"$'\n'".planning/STATE.md"$'\n'"${summary}"$'\n'".planning/state.json" ]] || return 1
  all_commit_paths_are_regular_writes "$commit" "$paths" || return 1
  [[ "$(front_matter_value_from_blob "$commit" "$summary" phase 2>/dev/null)" == 139-required-truth-reconciliation ]] || return 1
  [[ "$(front_matter_value_from_blob "$commit" "$summary" plan 2>/dev/null)" == "$plan" ]] || return 1
  [[ "$(front_matter_value_from_blob "$commit" "$summary" status 2>/dev/null)" == complete ]] || return 1
  blob_has_line "$commit" "$summary" '^## Self-Check: PASSED$' || return 1
  [[ "$(front_matter_value_from_blob "$commit" "$state" current_phase 2>/dev/null)" == 139 ]] || return 1
  [[ "$(front_matter_value_from_blob "$commit" "$state" stopped_at 2>/dev/null)" == "Completed 139-${plan}-PLAN.md" ]] || return 1
  blob_has_line "$commit" .planning/ROADMAP.md "^- \[x\] 139-${plan}-PLAN\.md" || return 1
  validate_phase_139_closeout_roadmap "$commit" .planning/ROADMAP.md "$plan" || return 1
  validate_phase_139_closeout_state "$commit" "$state" "$plan" || return 1
  validate_phase_139_closeout_state_contract "$commit" .planning/state.json "$plan"
}

validate_phase_139_closeout_roadmap() {
  local commit="$1" path="$2" plan="$3" parent old_count new_count
  parent="$(git rev-parse "$commit^" 2>/dev/null)" || return 1
  old_count="$(git show "$parent:$path" 2>/dev/null | awk '
    /^### Phase 139:/ { phase = 1; next }
    phase && /^### Phase [0-9]+:/ { phase = 0 }
    phase && /^\*\*Plans\*\*:[[:space:]]*[0-9]+\/7 plans executed$/ {
      value = $0; sub(/^\*\*Plans\*\*:[[:space:]]*/, "", value); sub(/\/7 plans executed$/, "", value)
      print value; count++
    }
    END { if (count != 1) exit 1 }
  ')" || return 1
  new_count="$(git show "$commit:$path" 2>/dev/null | awk '
    /^### Phase 139:/ { phase = 1; next }
    phase && /^### Phase [0-9]+:/ { phase = 0 }
    phase && /^\*\*Plans\*\*:[[:space:]]*[0-9]+\/7 plans executed$/ {
      value = $0; sub(/^\*\*Plans\*\*:[[:space:]]*/, "", value); sub(/\/7 plans executed$/, "", value)
      print value; count++
    }
    END { if (count != 1) exit 1 }
  ')" || return 1
  [[ "$old_count" -eq "$((10#$plan - 1))" && "$new_count" -eq "$((10#$plan))" ]] || return 1
  [[ "$(git show "$parent:$path" | grep -Ec "^- \\[ \\] 139-${plan}-PLAN\\.md([[:space:]]|$)")" -eq 1 ]] || return 1
  [[ "$(git show "$commit:$path" | grep -Ec "^- \\[x\\] 139-${plan}-PLAN\\.md([[:space:]]|$)")" -eq 1 ]] || return 1
  [[ "$(git show "$parent:$path" | grep -Ec "^\\| 139\\. Required Truth Reconciliation \\| ${old_count}/7 \\| In Progress\\|[[:space:]]*\\|$")" -eq 1 ]] || return 1
  [[ "$(git show "$commit:$path" | grep -Ec "^\\| 139\\. Required Truth Reconciliation \\| ${new_count}/7 \\| In Progress\\|[[:space:]]*\\|$")" -eq 1 ]] || return 1
  [[ "$(commit_path_diff_line_count "$commit" "$path" -)" -eq 3 ]] || return 1
  [[ "$(commit_path_diff_line_count "$commit" "$path" +)" -eq 3 ]] || return 1
  commit_path_diff_lines_match "$commit" "$path" \
    "^-\\*\\*Plans\\*\\*:[[:space:]]*${old_count}/7 plans executed$|^-\\- \\[ \\] 139-${plan}-PLAN\\.md|^-\\| 139\\. Required Truth Reconciliation \\| ${old_count}/7 \\| In Progress\\|[[:space:]]*\\|$" \
    "^\\+\\*\\*Plans\\*\\*:[[:space:]]*${new_count}/7 plans executed$|^\\+\\- \\[x\\] 139-${plan}-PLAN\\.md|^\\+\\| 139\\. Required Truth Reconciliation \\| ${new_count}/7 \\| In Progress\\|[[:space:]]*\\|$"
}

validate_phase_139_closeout_state() {
  local commit="$1" path="$2" plan="$3" parent summary old_count new_count old_total new_total expected_plan expected_status
  local state_decisions summary_decisions decision_count unique_decision_count summary_duration summary_tasks summary_files
  local summary_file_count unique_summary_file_count performance_row state_duration state_tasks state_files
  parent="$(git rev-parse "$commit^" 2>/dev/null)" || return 1
  summary=".planning/phases/139-required-truth-reconciliation/139-${plan}-SUMMARY.md"
  [[ "$(front_matter_value_from_blob "$parent" "$path" current_phase 2>/dev/null)" == 139 ]] || return 1
  [[ "$(front_matter_value_from_blob "$commit" "$path" current_phase 2>/dev/null)" == 139 ]] || return 1
  [[ "$(front_matter_value_from_blob "$parent" "$path" status 2>/dev/null)" == executing ]] || return 1
  expected_status=executing
  expected_plan="$((10#$plan + 1)) of 7"
  if [[ "$plan" == 07 ]]; then
    expected_status=verifying
    expected_plan='7 of 7'
  fi
  [[ "$(front_matter_value_from_blob "$commit" "$path" status 2>/dev/null)" == "$expected_status" ]] || return 1
  old_count="$(front_matter_indented_integer_from_blob "$parent" "$path" completed_plans)" || return 1
  new_count="$(front_matter_indented_integer_from_blob "$commit" "$path" completed_plans)" || return 1
  old_total="$(front_matter_indented_integer_from_blob "$parent" "$path" total_plans)" || return 1
  new_total="$(front_matter_indented_integer_from_blob "$commit" "$path" total_plans)" || return 1
  [[ "$old_total" -eq 40 && "$new_total" -eq 40 && "$old_count" -eq "$((32 + 10#$plan))" && "$new_count" -eq "$((33 + 10#$plan))" ]] || return 1
  [[ "$(front_matter_value_from_blob "$commit" "$path" state_head 2>/dev/null)" == "$parent" ]] || return 1
  blob_has_line "$commit" "$path" "^Plan:[[:space:]]+${expected_plan}$" || return 1
  if [[ "$plan" == 07 ]]; then
    blob_has_line "$commit" "$path" '^Status:[[:space:]]+Phase complete — ready for verification$' || return 1
  else
    blob_has_line "$commit" "$path" '^Status:[[:space:]]+Ready to execute$' || return 1
  fi

  summary_decisions="$(front_matter_string_list_from_blob "$commit" "$summary" key-decisions)" || return 1
  decision_count="$(printf '%s\n' "$summary_decisions" | awk 'NF { count++ } END { print count + 0 }')"
  unique_decision_count="$(printf '%s\n' "$summary_decisions" | LC_ALL=C sort -u | awk 'NF { count++ } END { print count + 0 }')"
  [[ "$decision_count" -eq "$unique_decision_count" ]] || return 1
  state_decisions="$(git diff --no-ext-diff --unified=0 "$commit^" "$commit" -- "$path" | awk '
    /^\+- \[Phase 139\]: / { sub(/^\+- \[Phase 139\]: /, ""); print; count++ }
    END { if (count < 1) exit 1 }
  ')" || return 1
  [[ "$(printf '%s\n' "$state_decisions" | awk 'NF { count++ } END { print count + 0 }')" -eq "$decision_count" ]] || return 1
  [[ "$(printf '%s\n' "$state_decisions" | LC_ALL=C sort)" == "$(printf '%s\n' "$summary_decisions" | LC_ALL=C sort)" ]] || return 1

  summary_duration="$(front_matter_value_from_blob "$commit" "$summary" duration 2>/dev/null)" || return 1
  summary_duration="$(normalize_gsd_duration "$summary_duration")"
  summary_tasks="$(front_matter_nested_integer_from_blob "$commit" "$summary" actuals tasks)" || return 1
  summary_files="$(front_matter_nested_string_list_from_blob "$commit" "$summary" key-files modified)" || return 1
  summary_file_count="$(printf '%s\n' "$summary_files" | awk -v summary="$summary" 'NF && $0 != summary { count++ } END { print count + 0 }')"
  unique_summary_file_count="$(printf '%s\n' "$summary_files" | LC_ALL=C sort -u | awk 'NF { count++ } END { print count + 0 }')"
  [[ "$unique_summary_file_count" -eq "$(printf '%s\n' "$summary_files" | awk 'NF { count++ } END { print count + 0 }')" ]] || return 1
  performance_row="$(git diff --no-ext-diff --unified=0 "$commit^" "$commit" -- "$path" | awk -v plan="${plan#0}" '
    $0 ~ ("^\\+\\| Phase 139 P" plan " \\| [^|]+ \\| [0-9]+ tasks \\| [0-9]+ files \\|$") { print; count++ }
    END { if (count != 1) exit 1 }
  ')" || return 1
  state_duration="$(printf '%s\n' "$performance_row" | awk -F'|' '{ value=$3; gsub(/^[[:space:]]+|[[:space:]]+$/, "", value); print value }')"
  state_tasks="$(printf '%s\n' "$performance_row" | awk -F'|' '{ value=$4; gsub(/^[[:space:]]+|[[:space:]]+tasks[[:space:]]*$/, "", value); print value }')"
  state_files="$(printf '%s\n' "$performance_row" | awk -F'|' '{ value=$5; gsub(/^[[:space:]]+|[[:space:]]+files[[:space:]]*$/, "", value); print value }')"
  [[ "$(normalize_gsd_duration "$state_duration")" == "$summary_duration" && "$state_tasks" == "$summary_tasks" && "$state_files" == "$summary_file_count" ]] || return 1
  commit_path_diff_lines_match "$commit" "$path" \
    '^-status:|^-stopped_at:|^-last_updated:|^-state_head:|^-[[:space:]]+completed_plans:|^-Plan:|^-Status:|^-Last session:|^-Stopped at:' \
    "^\\+status:[[:space:]]*${expected_status}$|^\\+stopped_at:[[:space:]]*Completed 139-${plan}-PLAN\\.md$|^\\+last_updated:|^\\+state_head:[[:space:]]*${parent}$|^\\+[[:space:]]+completed_plans:[[:space:]]*${new_count}$|^\\+Plan:[[:space:]]*${expected_plan}$|^\\+Status:|^\\+- \\[Phase 139\\]:|^\\+Last session:|^\\+Stopped at:[[:space:]]*Completed 139-${plan}-PLAN\\.md$|^\\+\\| Phase 139 P${plan#0} \\|"
}

validate_phase_139_closeout_state_contract() {
  local commit="$1" path="$2" plan="$3" parent old new expected_label expected_reason
  parent="$(git rev-parse "$commit^" 2>/dev/null)" || return 1
  old="$(git show "$parent:$path" 2>/dev/null)" || return 1
  new="$(git show "$commit:$path" 2>/dev/null)" || return 1
  if [[ "$plan" == 07 ]]; then
    expected_label='Advance to the next step (verify)'
    expected_reason='Phase 139 of 4 · ready to verify'
  else
    expected_label='Advance to the next step'
    expected_reason='Phase 139 of 4 · executing'
  fi
  jq -e --arg label "$expected_label" --arg reason "$expected_reason" '
    .contract == "1.0.0" and
    any(.phases[]; .number == "139" and .status == "in_progress") and
    .next.command == "/gsd:progress --next" and .next.label == $label and .next.reason == $reason and
    (.updated_at | test("^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}(\\.[0-9]+)?Z$"))
  ' <<< "$new" >/dev/null || return 1
  [[ "$(jq -Sc 'del(.next, .updated_at)' <<< "$old")" == "$(jq -Sc 'del(.next, .updated_at)' <<< "$new")" ]]
}

validate_phase_139_verification_commit() {
  local commit="$1" path="$2"
  [[ "$path" == .planning/phases/139-required-truth-reconciliation/139-VERIFICATION.md ]] || return 1
  commit_path_is_regular_write "$commit" "$path" || return 1
  [[ "$(front_matter_value_from_blob "$commit" "$path" phase 2>/dev/null)" == 139-required-truth-reconciliation ]] || return 1
  [[ "$(front_matter_value_from_blob "$commit" "$path" status 2>/dev/null)" == passed ]] || return 1
  blob_has_line "$commit" "$path" '^gaps:[[:space:]]*(\[\]|0)[[:space:]]*$' || return 1
  blob_has_line "$commit" "$path" '^behavior_unverified:[[:space:]]*0[[:space:]]*$' || return 1
  blob_has_line "$commit" "$path" '^human_needed:[[:space:]]*false[[:space:]]*$' || return 1
  blob_has_line "$commit" "$path" '^# Phase 139: .+Verification( Report)?$' || return 1
  blob_has_line "$commit" "$path" '^## Goal Achievement$'
}

validate_phase_139_completion_commit() {
  local commit="$1" paths="$2" state=.planning/STATE.md parent state_head path
  exact_path_set "$paths" '^\.planning/STATE\.md$' '^\.planning/(ROADMAP|STATE|REQUIREMENTS)\.md$|^\.planning/phases/139-required-truth-reconciliation/139-VERIFICATION\.md$' || return 1
  exact_path_set "$paths" '^\.planning/ROADMAP\.md$' '^\.planning/(ROADMAP|STATE|REQUIREMENTS)\.md$|^\.planning/phases/139-required-truth-reconciliation/139-VERIFICATION\.md$' || return 1
  all_commit_paths_are_regular_writes "$commit" "$paths" || return 1
  parent="$(git rev-parse "$commit^" 2>/dev/null)" || return 1
  [[ "$(front_matter_value_from_blob "$parent" "$state" current_phase 2>/dev/null)" == 139 ]] || return 1
  [[ "$(front_matter_value_from_blob "$parent" "$state" status 2>/dev/null)" == verifying ]] || return 1
  [[ "$(front_matter_value_from_blob "$commit" "$state" current_phase 2>/dev/null)" == 140 ]] || return 1
  [[ "$(front_matter_value_from_blob "$commit" "$state" current_phase_name 2>/dev/null)" == 'Bounded Operational Loose-End Triage' ]] || return 1
  [[ "$(front_matter_value_from_blob "$commit" "$state" status 2>/dev/null)" == planning ]] || return 1
  state_head="$(front_matter_value_from_blob "$commit" "$state" state_head 2>/dev/null)"
  [[ "$state_head" == "$parent" ]] || return 1
  blob_has_line "$commit" "$state" '^Phase:[[:space:]]+140([[:space:]]|$)' || return 1
  blob_has_line "$commit" "$state" '^Plan:[[:space:]]+Not started$' || return 1
  blob_has_line "$commit" "$state" '^Status:[[:space:]]+Ready to plan$' || return 1
  while IFS= read -r path; do
    case "$path" in
      .planning/STATE.md) validate_phase_139_completion_state "$commit" "$path" || return 1 ;;
      .planning/ROADMAP.md) validate_phase_139_completion_roadmap "$commit" "$path" || return 1 ;;
      .planning/REQUIREMENTS.md) validate_phase_139_completion_requirements "$commit" "$path" || return 1 ;;
      .planning/phases/139-required-truth-reconciliation/139-VERIFICATION.md)
        validate_phase_139_verification_commit "$commit" "$path" || return 1 ;;
      *) return 1 ;;
    esac
  done <<< "$paths"
}

validate_phase_139_completion_state() {
  local commit="$1" path="$2" parent old_completed new_completed old_total new_total old_phases new_phases total_phases
  parent="$(git rev-parse "$commit^" 2>/dev/null)" || return 1
  old_completed="$(front_matter_indented_integer_from_blob "$parent" "$path" completed_plans)" || return 1
  new_completed="$(front_matter_indented_integer_from_blob "$commit" "$path" completed_plans)" || return 1
  old_total="$(front_matter_indented_integer_from_blob "$parent" "$path" total_plans)" || return 1
  new_total="$(front_matter_indented_integer_from_blob "$commit" "$path" total_plans)" || return 1
  old_phases="$(front_matter_indented_integer_from_blob "$parent" "$path" completed_phases)" || return 1
  new_phases="$(front_matter_indented_integer_from_blob "$commit" "$path" completed_phases)" || return 1
  total_phases="$(front_matter_indented_integer_from_blob "$commit" "$path" total_phases)" || return 1
  [[ "$old_total" -gt 0 && "$new_total" -eq "$old_total" &&
     "$old_completed" -eq "$old_total" && "$new_completed" -eq "$new_total" ]] || return 1
  [[ "$old_phases" -eq 1 && "$new_phases" -eq 2 && "$total_phases" -eq 4 ]] || return 1
  blob_has_line "$commit" "$path" '^[[:space:]]+percent:[[:space:]]*50$' || return 1
  [[ "$(git show "$commit:$path" | grep -Ec '^Phase:[[:space:]]+140$')" -eq 1 ]] || return 1
  [[ "$(git show "$commit:$path" | grep -Ec '^Phase:')" -eq 1 ]] || return 1
  [[ "$(git show "$commit:$path" | grep -Ec '^Plan:[[:space:]]+Not started$')" -eq 1 ]] || return 1
  [[ "$(git show "$commit:$path" | grep -Ec '^Plan:')" -eq 1 ]] || return 1
  [[ "$(git show "$commit:$path" | grep -Ec '^Status:[[:space:]]+Ready to plan$')" -eq 1 ]] || return 1
  [[ "$(git show "$commit:$path" | grep -Ec '^Status:')" -eq 1 ]] || return 1
  [[ "$(git show "$commit:$path" | grep -Ec '^Last activity:[[:space:]]+[0-9]{4}-[0-9]{2}-[0-9]{2}[[:space:]]+—[[:space:]]+Phase 139 complete, transitioned to Phase 140$')" -eq 1 ]] || return 1
  [[ "$(git show "$commit:$path" | grep -Ec '^Last activity:')" -eq 1 ]] || return 1
  [[ "$(git show "$commit:$path" | grep -Ec '^Progress:[[:space:]]+\[█████░░░░░\][[:space:]]+50%$')" -eq 1 ]] || return 1
  [[ "$(git show "$commit:$path" | grep -Ec '^Progress:')" -eq 1 ]] || return 1
  [[ "$(git show "$commit:$path" | grep -Ec '^Stopped at:[[:space:]]+Phase 139 complete, ready to plan Phase 140$')" -eq 1 ]] || return 1
  [[ "$(git show "$commit:$path" | grep -Ec '^Stopped at:')" -eq 1 ]] || return 1
  commit_path_diff_lines_match "$commit" "$path" \
    '^-current_phase:|^-current_phase_name:|^-status:|^-stopped_at:|^-last_updated:|^-last_activity_desc:|^-state_head:|^-[[:space:]]+completed_phases:|^-[[:space:]]+percent:|^-Phase:|^-Plan:|^-Status:|^-Last activity:|^-Progress:|^-Stopped at:' \
    "^\\+current_phase:[[:space:]]*140$|^\\+current_phase_name:[[:space:]]*Bounded Operational Loose-End Triage$|^\\+status:[[:space:]]*planning$|^\\+stopped_at:[[:space:]]*Phase 139 complete, ready to plan Phase 140$|^\\+last_updated:|^\\+last_activity_desc:[[:space:]]*Phase 139 complete, transitioned to Phase 140$|^\\+state_head:[[:space:]]*${parent}$|^\\+[[:space:]]+completed_phases:|^\\+[[:space:]]+percent:|^\\+Phase:[[:space:]]*140$|^\\+Plan:[[:space:]]*Not started$|^\\+Status:[[:space:]]*Ready to plan$|^\\+Last activity:.*Phase 139 complete, transitioned to Phase 140$|^\\+Progress:[[:space:]]+\\[█████░░░░░\\][[:space:]]+50%$|^\\+Stopped at:[[:space:]]*Phase 139 complete, ready to plan Phase 140$"
}

validate_phase_139_completion_roadmap() {
  local commit="$1" path="$2" parent
  parent="$(git rev-parse "$commit^" 2>/dev/null)" || return 1
  [[ "$(git show "$parent:$path" | grep -Ec '^- \[ \] \*\*Phase 139: Required Truth Reconciliation\*\*')" -eq 1 ]] || return 1
  [[ "$(git show "$commit:$path" | grep -Ec '^- \[x\] \*\*Phase 139: Required Truth Reconciliation\*\*.*\(completed [0-9]{4}-[0-9]{2}-[0-9]{2}\)$')" -eq 1 ]] || return 1
  [[ "$(git show "$parent:$path" | grep -Ec '^[|] 139\. Required Truth Reconciliation [|] 9/9 [|] In Progress[|][[:space:]]*[|]$')" -eq 1 ]] || return 1
  [[ "$(git show "$commit:$path" | grep -Ec '^[|] 139\. Required Truth Reconciliation [|] 9/9 [|] Complete[[:space:]]+[|] [0-9]{4}-[0-9]{2}-[0-9]{2} [|]$')" -eq 1 ]] || return 1
  [[ "$(commit_path_diff_line_count "$commit" "$path" -)" -eq 2 && "$(commit_path_diff_line_count "$commit" "$path" +)" -eq 2 ]] || return 1
  commit_path_diff_lines_match "$commit" "$path" \
    '^-\- \[ \] \*\*Phase 139: Required Truth Reconciliation\*\*|^-[|] 139\. Required Truth Reconciliation [|] [0-9]+/[0-9]+ [|] In Progress[|]' \
    '^\+- \[x\] \*\*Phase 139: Required Truth Reconciliation\*\*.*\(completed [0-9]{4}-[0-9]{2}-[0-9]{2}\)$|^\+[|] 139\. Required Truth Reconciliation [|] [0-9]+/[0-9]+ [|] Complete[[:space:]]+[|] [0-9]{4}-[0-9]{2}-[0-9]{2} [|]'
}

validate_phase_139_completion_requirements() {
  local commit="$1" path="$2" parent ids id
  parent="$(git rev-parse "$commit^" 2>/dev/null)" || return 1
  ids='CI-08 QUAL-05 HYGIENE-05 HYGIENE-06 TRUTH-03 TRUTH-04 TRUTH-05'
  for id in $ids; do
    [[ "$(git show "$parent:$path" | grep -Ec "^- \\[ \\] \\*\\*${id}\\*\\*:")" -eq 1 ]] || return 1
    [[ "$(git show "$commit:$path" | grep -Ec "^- \\[x\\] \\*\\*${id}\\*\\*:")" -eq 1 ]] || return 1
    [[ "$(git show "$parent:$path" | grep -Ec "^[|] ${id} [|] Phase 139 [|] Pending [|]$")" -eq 1 ]] || return 1
    [[ "$(git show "$commit:$path" | grep -Ec "^[|] ${id} [|] Phase 139 [|] Complete [|]$")" -eq 1 ]] || return 1
  done
  for id in CI-06 CI-07; do
    [[ "$(git show "$parent:$path" | grep -Ec "^- \\[ \\] \\*\\*${id}\\*\\*:")" -eq 1 ]] || return 1
    [[ "$(git show "$commit:$path" | grep -Ec "^- \\[ \\] \\*\\*${id}\\*\\*:")" -eq 1 ]] || return 1
    [[ "$(git show "$parent:$path" | grep -Ec "^[|] ${id} [|] Phase 140 [|] Pending [|]$")" -eq 1 ]] || return 1
    [[ "$(git show "$commit:$path" | grep -Ec "^[|] ${id} [|] Phase 140 [|] Pending [|]$")" -eq 1 ]] || return 1
  done
  [[ "$(commit_path_diff_line_count "$commit" "$path" -)" -eq 14 && "$(commit_path_diff_line_count "$commit" "$path" +)" -eq 14 ]] || return 1
  commit_path_diff_lines_match "$commit" "$path" \
    '^-- \[ \] \*\*(CI-08|QUAL-05|HYGIENE-05|HYGIENE-06|TRUTH-03|TRUTH-04|TRUTH-05)\*\*:|^-[|] (CI-08|QUAL-05|HYGIENE-05|HYGIENE-06|TRUTH-03|TRUTH-04|TRUTH-05) [|] Phase 139 [|] Pending [|]' \
    '^\+- \[x\] \*\*(CI-08|QUAL-05|HYGIENE-05|HYGIENE-06|TRUTH-03|TRUTH-04|TRUTH-05)\*\*:|^\+[|] (CI-08|QUAL-05|HYGIENE-05|HYGIENE-06|TRUTH-03|TRUTH-04|TRUTH-05) [|] Phase 139 [|] Complete [|]'
}

worktree_path_diff_lines_match() {
  local path="$1" removed_pattern="$2" added_pattern="$3" line
  while IFS= read -r line; do
    case "$line" in
      ---\ *|+++\ *) : ;;
      -|"+") : ;;
      -*) [[ "$line" =~ $removed_pattern ]] || return 1 ;;
      +*) [[ "$line" =~ $added_pattern ]] || return 1 ;;
    esac
  done < <(git diff --no-ext-diff --unified=0 HEAD -- "$path" 2>/dev/null)
}

validate_phase_139_transition_commit() {
  local project=.planning/PROJECT.md state=.planning/STATE.md changed staged untracked
  changed="$(git diff --name-only --diff-filter=ACMR HEAD -- | sed '/^$/d' | LC_ALL=C sort)"
  staged="$(git diff --cached --name-only --diff-filter=ACMR -- | sed '/^$/d')"
  untracked="$(git ls-files --others --exclude-standard | sed '/^$/d')"
  [[ -z "$staged" && -z "$untracked" ]] || return 1
  [[ "$changed" == $'.planning/PROJECT.md\n.planning/STATE.md' ]] || return 1
  [[ -f "$project" && ! -L "$project" && -f "$state" && ! -L "$state" ]] || return 1
  [[ "$(front_matter_value_from_blob HEAD "$state" current_phase 2>/dev/null)" == 140 ]] || return 1
  [[ "$(front_matter_value_from_file "$state" current_phase 2>/dev/null)" == 140 ]] || return 1
  [[ "$(front_matter_value_from_file "$state" status 2>/dev/null)" == planning ]] || return 1
  grep -Eq '^# Lockspire$' "$project" || return 1
  grep -Eq '^## Current Milestone:[[:space:]]+v1\.38([[:space:]]|$)' "$project" || return 1
  grep -Eq '^\*Last updated:[[:space:]]+[0-9]{4}-[0-9]{2}-[0-9]{2} after Phase 139\*$' "$project" || return 1
  grep -Eq '^\*\*Current focus:\*\*[[:space:]]+Phase 140([[:space:]]|—|$)' "$state" || return 1
  worktree_path_diff_lines_match "$project" \
    '^-Phase 138 completed.*Phase 139|^-\*Last updated:.*after Phase 138\*$' \
    '^\+Phase 139 completed.*Phase 140|^\+\*Last updated:[[:space:]]+[0-9]{4}-[0-9]{2}-[0-9]{2} after Phase 139\*$' || return 1
  [[ "$(git diff --no-ext-diff --unified=0 HEAD -- "$project" | awk '/^-/ && $0 !~ /^--- / { removed++ } /^\+/ && $0 !~ /^\+\+\+ / { added++ } END { print removed + 0, added + 0 }')" == '2 2' ]] || return 1
  worktree_path_diff_lines_match "$state" \
    '^-See: \.planning/PROJECT\.md|^-\*\*Current focus:\*\* Phase 139|^-Last session:' \
    '^\+See: \.planning/PROJECT\.md|^\+\*\*Current focus:\*\* Phase 140|^\+Last session:' || return 1
  [[ "$(git diff --no-ext-diff --unified=0 HEAD -- "$state" | awk '/^-/ && $0 !~ /^--- / { removed++ } /^\+/ && $0 !~ /^\+\+\+ / { added++ } END { print removed + 0, added + 0 }')" == '3 3' ]]
}

validate_repeated_worktree_transition() {
  local project="$1" state="$2" ledger ledger_commit short changed
  ledger=.planning/phases/138-baseline-inventory-evidence-taxonomy/baseline-inventory-2026-08-28.md
  changed="$(git diff --name-only --diff-filter=ACMR HEAD -- | sed '/^$/d' | LC_ALL=C sort)"
  [[ "$changed" == $'.planning/PROJECT.md\n.planning/STATE.md' ]] || return 1
  ledger_commit="$(resolve_snapshot_ledger_commit "$ledger" HEAD 2>/dev/null)" || return 1
  short="$(git rev-parse --short=8 "$ledger_commit" 2>/dev/null)" || return 1
  grep -Eq '^Phase 138 completed the v1\.38 evidence foundation\..*at `'"${short}"'`.*Phase 139 now owns' "$project" || return 1
  grep -Eq '^\| Keep the v1\.38 baseline immutable .*Phase 139 consumes ledger `'"${short}"'` \|$' "$project" || return 1
  worktree_path_diff_lines_match "$project" \
    '^-Phase 138 completed.*Phase 139 now owns|^-\| Keep the v1\.38 baseline immutable .*Phase 139 consumes ledger|^-\*Last updated:.*after Phase 138\*$' \
    '^\+Phase 138 completed.*Phase 139 now owns|^\+\| Keep the v1\.38 baseline immutable .*Phase 139 consumes ledger|^\+\*Last updated:[[:space:]]+[0-9]{4}-[0-9]{2}-[0-9]{2} after Phase 138\*$' || return 1
  case "$(git diff --no-ext-diff --unified=0 HEAD -- "$project" | awk '/^-/ && $0 !~ /^--- / { removed++ } /^\+/ && $0 !~ /^\+\+\+ / { added++ } END { print removed + 0, added + 0 }')" in
    '2 2'|'3 3') : ;;
    *) return 1 ;;
  esac
  worktree_path_diff_lines_match "$state" \
    '^-See: \.planning/PROJECT\.md|^-\*\*Current focus:\*\* Phase 138|^-- Phase 139 must revalidate ledger|^-Last session:' \
    '^\+See: \.planning/PROJECT\.md|^\+\*\*Current focus:\*\* Phase 139|^\+- Phase 139 must revalidate ledger|^\+Last session:' || return 1
  case "$(git diff --no-ext-diff --unified=0 HEAD -- "$state" | awk '/^-/ && $0 !~ /^--- / { removed++ } /^\+/ && $0 !~ /^\+\+\+ / { added++ } END { print removed + 0, added + 0 }')" in
    '3 3'|'4 4') : ;;
    *) return 1 ;;
  esac
}

validate_worktree_transition() {
  local project=.planning/PROJECT.md state=.planning/STATE.md roadmap=.planning/ROADMAP.md requirements=.planning/REQUIREMENTS.md status
  [[ -f "$project" && -s "$project" && -f "$state" && -s "$state" && -f "$roadmap" && -s "$roadmap" && -f "$requirements" && -s "$requirements" ]] || return 1
  [[ "$(front_matter_value_from_blob HEAD "$state" current_phase 2>/dev/null)" == 139 ]] || return 1
  [[ "$(front_matter_value_from_blob HEAD "$state" status 2>/dev/null)" == planning ]] || return 1
  [[ "$(front_matter_value_from_file "$state" current_phase 2>/dev/null)" == 139 ]] || return 1
  status="$(front_matter_value_from_file "$state" status 2>/dev/null || true)"
  [[ "$status" == planning ]] || return 1
  grep -Eq '^# Project State$' "$state" || return 1
  grep -Eq '^## Current Position$' "$state" || return 1
  grep -Eq '^Status:[[:space:]]+Ready to plan$' "$state" || return 1
  blob_has_line HEAD "$project" '^## Current Milestone:[[:space:]]+v1\.38([[:space:]]|$)' || return 1
  grep -Eq '^# Lockspire$' "$project" || return 1
  grep -Eq '^## Current Milestone:[[:space:]]+v1\.38([[:space:]]|$)' "$project" || return 1
  grep -Eq '^Phase 138 completed the v1\.38 evidence foundation\..*Phase 139 now owns' "$project" || return 1
  grep -Eq '^\*Last updated:[[:space:]]+[0-9]{4}-[0-9]{2}-[0-9]{2} after Phase 138\*$' "$project" || return 1
  grep -Eq 'Phase 138.*([Cc]omplete|✅)' "$roadmap" || return 1
  grep -Eq '(BASE-01.*([Cc]omplete|\[x\])|\[x\].*BASE-01)' "$requirements" || return 1
  if blob_has_line HEAD "$project" '^Phase 138 completed the v1\.38 evidence foundation\.'; then
    validate_repeated_worktree_transition "$project" "$state"
  else
    return 0
  fi
}

verification_gap_report_is_superseded() {
  local commit="$1" verification="$2" parent summary plan
  parent="$(git rev-parse "$commit^" 2>/dev/null || true)"
  [[ -n "$parent" ]] || return 1
  [[ "$(front_matter_value_from_blob "$parent" "$verification" status 2>/dev/null)" == gaps_found ]] || return 1
  if git show "$parent:$verification" | grep -q 'Aggregate GitHub failure can retain' &&
    git show "$parent:$verification" | grep -q 'Capture immutable baseline refs before all collection' &&
    git show "$parent:$verification" | grep -q 'ID-generation failure silently drops' &&
    git show "$parent:$verification" | grep -q 'Use NUL-delimited Git output'; then
    for plan in 07 08 09 10; do
      summary=".planning/phases/138-baseline-inventory-evidence-taxonomy/138-${plan}-SUMMARY.md"
      [[ "$(front_matter_value_from_blob "$parent" "$summary" status 2>/dev/null)" == complete ]] || return 1
    done
    return 0
  fi
  if git show "$parent:$verification" | grep -Fq "The finalizer's completion boundary does not match the live GSD v1.13 phase.complete state transition." &&
    git show "$parent:$verification" | grep -Fq 'Live phase completion advances STATE to Phase 139/planning before the transition-owned worktree projection.' &&
    git show "$parent:$verification" | grep -Fq 'Update completion and transition validation to the observed GSD v1.13 state machine, then re-run the live gate.'; then
    return 0
  fi
  if git show "$parent:$verification" | grep -Fq 'The verification transition recognizes only the original four-gap predecessor, not the exact later completion-boundary gap report.' &&
    git show "$parent:$verification" | grep -Fq 'The freshly passed verification commit is fail-closed as unknown until the bounded predecessor contract is extended.' &&
    git show "$parent:$verification" | grep -Fq 'Authorize the exact completion-boundary gaps_found to passed transition and prove hostile variants remain rejected.'; then
    return 0
  fi
  if git show "$parent:$verification" | grep -Fq 'The post-transition validator requires a PROJECT current-focus line that the live v1.38 document does not contain.' &&
    git show "$parent:$verification" | grep -Fq 'The sealed receipt is valid, but its immutable completion parent cannot satisfy the modeled PROJECT precondition.' &&
    git show "$parent:$verification" | grep -Fq 'Bind PROJECT evolution to the live milestone heading, Phase 138 completion paragraph, Phase 139 ownership sentence, and transition footer.'; then
    return 0
  fi
  if git show "$parent:$verification" | grep -Fq 'The post-transition receipt validator misclassifies an early PROJECT heading when grep -q closes a pipe under pipefail.' &&
    git show "$parent:$verification" | grep -Fq 'The sealed receipt and lifecycle semantics are valid, but blob_has_line returns the upstream git show SIGPIPE status.' &&
    git show "$parent:$verification" | grep -Fq 'Consume complete blob output when matching lifecycle lines and prove large-document headings remain authorized.'; then
    return 0
  fi
  git show "$parent:$verification" | grep -Fq 'The immutable maintained-record fingerprint is reobserved from live HEAD even after exact lifecycle commits change the verification report.' || return 1
  git show "$parent:$verification" | grep -Fq 'The lifecycle chain is authorized, but its expected passed-verification projection is misreported as unrelated maintained-source drift.' || return 1
  git show "$parent:$verification" | grep -Fq 'Revalidate immutable maintained receipts from the ledger evidence base and leave every later commit to the exact lifecycle classifier.'
}

normalize_relation_git_domain() {
  local file="$1" subject="$2" observed_sha="$3" evidence_base="$4" normalized
  [[ -n "$observed_sha" && "$observed_sha" != "$evidence_base" ]] || return 0
  normalized="$(mktemp "${TMPDIR:-/tmp}/lockspire-relation-normalized.XXXXXX")" || return 1
  awk -v subject="\`$subject\`" -v observed="$observed_sha" -v base="$evidence_base" '
    index($0, subject) { gsub(observed, base) }
    { print }
  ' "$file" > "$normalized"
  mv -f "$normalized" "$file"
}

relation_sha_is_normalizable() {
  local ledger_commit="$1" observed_sha="$2" head="$3"
  [[ "$observed_sha" == "$head" ]] || {
    git merge-base --is-ancestor "$ledger_commit" "$observed_sha" 2>/dev/null &&
      git merge-base --is-ancestor "$observed_sha" "$head" 2>/dev/null
  }
}

ledger_git_domain_section() {
  local ledger_commit="$1" ledger="$2" heading="$3"
  git show "$ledger_commit:$ledger" 2>/dev/null | awk -v heading="## Git $heading" '
    $0 == heading { capture = 1 }
    capture && $0 ~ /^## / && $0 != heading { exit }
    capture { print }
  '
}

emit_git_relation_row() {
  local domain="$1" state="$2" detail="$3"
  printf 'git_topology|%s|%s|refresh_required|%s\n' \
    "$domain" "$state" "$(markdown_value "$detail")"
}

verify_git_snapshot_receipt() {
  local ledger_commit="$1" ledger="$2" evidence_base="$3" head="$4"
  local expected_fingerprint current_fingerprint receipt_dir branch_file tag_file worktree_file aggregate_file
  local current_main="" current_remote_main="" current_head="" current_branch="" current_branch_sha="" repo_root="" expected current domain failed=0
  expected_fingerprint="$(front_matter_value_from_blob "$ledger_commit" "$ledger" git_receipt_fingerprint 2>/dev/null || printf not_applicable)"
  [[ "$expected_fingerprint" != not_applicable ]] || return 0

  receipt_dir="$(mktemp -d "${TMPDIR:-/tmp}/lockspire-snapshot-git.XXXXXX")" || return 1
  branch_file="$receipt_dir/branches.md"
  tag_file="$receipt_dir/tags.md"
  worktree_file="$receipt_dir/worktrees.md"
  aggregate_file="$receipt_dir/git.md"

  BRANCH_STATUS="not_applicable"; BRANCH_EXIT="not_run"; BRANCH_LIMITATION="Branch relation query did not complete."
  TAG_STATUS="not_applicable"; TAG_EXIT="not_run"; TAG_LIMITATION="Tag relation query did not complete."
  WORKTREE_STATUS="not_applicable"; WORKTREE_EXIT="not_run"; WORKTREE_LIMITATION="Worktree relation query did not complete."
  collect_git_refs > "$branch_file"
  collect_git_tags > "$tag_file"
  collect_git_worktrees > "$worktree_file"

  current_main="$(git rev-parse main 2>/dev/null || true)"
  if [[ -n "$current_main" ]] && relation_sha_is_normalizable "$ledger_commit" "$current_main" "$head"; then
    normalize_relation_git_domain "$branch_file" refs/heads/main "$current_main" "$evidence_base" || failed=1
  fi
  current_remote_main="$(git rev-parse "refs/remotes/$REMOTE/main" 2>/dev/null || true)"
  if [[ -n "$current_remote_main" ]] && relation_sha_is_normalizable "$ledger_commit" "$current_remote_main" "$head"; then
    normalize_relation_git_domain "$branch_file" "refs/remotes/$REMOTE/main" "$current_remote_main" "$evidence_base" || failed=1
    if [[ "$(git symbolic-ref --quiet "refs/remotes/$REMOTE/HEAD" 2>/dev/null || true)" == "refs/remotes/$REMOTE/main" ]]; then
      normalize_relation_git_domain "$branch_file" "refs/remotes/$REMOTE/HEAD" "$current_remote_main" "$evidence_base" || failed=1
    fi
  fi
  current_branch="$(git symbolic-ref --quiet --short HEAD 2>/dev/null || true)"
  current_branch_sha="$(git rev-parse HEAD 2>/dev/null || true)"
  if [[ -n "$current_branch" && -n "$current_branch_sha" && "$current_branch" != main ]] &&
    relation_sha_is_normalizable "$ledger_commit" "$current_branch_sha" "$head"; then
    normalize_relation_git_domain "$branch_file" "refs/heads/$current_branch" "$current_branch_sha" "$evidence_base" || failed=1
  fi
  current_head="$(git rev-parse HEAD 2>/dev/null || true)"
  repo_root="$(git rev-parse --show-toplevel 2>/dev/null || true)"
  if [[ -n "$current_head" && -n "$repo_root" ]] && relation_sha_is_normalizable "$ledger_commit" "$current_head" "$head"; then
    normalize_relation_git_domain "$worktree_file" "$repo_root" "$current_head" "$evidence_base" || failed=1
  fi

  for domain in branches tags worktrees; do
    case "$domain" in
      branches) current="$branch_file"; state="$BRANCH_STATUS"; detail="$BRANCH_LIMITATION" ;;
      tags) current="$tag_file"; state="$TAG_STATUS"; detail="$TAG_LIMITATION" ;;
      worktrees) current="$worktree_file"; state="$WORKTREE_STATUS"; detail="$WORKTREE_LIMITATION" ;;
    esac
    if [[ "$state" != complete ]]; then
      emit_git_relation_row "$domain" unavailable "$detail"
      failed=1
      continue
    fi
    expected="$(ledger_git_domain_section "$ledger_commit" "$ledger" "$domain")"
    if [[ -z "$expected" || "$expected" != "$(cat "$current")" ]]; then
      emit_git_relation_row "$domain" mismatch "Observed $domain differ from the immutable Git receipt; recollection is required."
      failed=1
    fi
  done

  cat "$branch_file" "$tag_file" "$worktree_file" > "$aggregate_file"
  current_fingerprint="$(receipt_fingerprint git "$aggregate_file" 2>/dev/null || printf unavailable)"
  if [[ "$current_fingerprint" != "$expected_fingerprint" ]]; then
    if [[ "$failed" -eq 0 ]]; then
      emit_git_relation_row aggregate mismatch "The normalized Git receipt fingerprint differs from the immutable ledger."
    fi
    failed=1
  fi
  rm -rf "$receipt_dir"
  [[ "$failed" -eq 0 ]]
}

classify_lifecycle_commit() {
  local commit="$1" subject="$2" paths="$3"
  if [[ "$subject" =~ ^docs\(138-([0-9][0-9])\):[[:space:]]complete[[:space:]].+[[:space:]]plan$ ]]; then
    if validate_gsd_plan_closeout_commit "$commit" "$paths" "${BASH_REMATCH[1]}"; then
      printf 'gsd_plan_closeout'
      return
    fi
  fi
  if [[ "$subject" =~ ^docs\(138-[0-9][0-9]\):[[:space:]]complete[[:space:]].+[[:space:]]plan$ ]]; then
    validate_phase_summary_commit "$commit" "$paths" || return 1
    printf 'phase_summary'
    return
  fi
  if [[ "$subject" == "docs(phase-138): record clean code review" ]]; then
    [[ "$paths" == .planning/phases/138-baseline-inventory-evidence-taxonomy/138-REVIEW.md ]] || return 1
    validate_review_commit "$commit" "$paths" || return 1
    printf 'clean_review'
    return
  fi
  if [[ "$subject" == "docs(phase-138): record passed verification" ]]; then
    [[ "$paths" == .planning/phases/138-baseline-inventory-evidence-taxonomy/138-VERIFICATION.md ]] || return 1
    validate_verification_commit "$commit" "$paths" || return 1
    printf 'passed_verification'
    return
  fi
  if [[ "$subject" == "docs(phase-138): complete phase execution" ]]; then
    validate_phase_completion_commit "$commit" "$paths" || return 1
    printf 'phase_completion'
    return
  fi
  if [[ "$subject" == "docs(phase-138): transition to phase 139" ]]; then
    validate_transition_commit "$commit" "$paths" || return 1
    printf 'transition_bookkeeping'
    return
  fi
  if [[ "$subject" =~ ^docs\(139-([0-9][0-9])\):[[:space:]]complete[[:space:]].+[[:space:]]plan$ ]]; then
    validate_phase_139_plan_closeout_commit "$commit" "$paths" "${BASH_REMATCH[1]}" || return 1
    printf 'phase_139_plan_closeout'
    return
  fi
  if [[ "$subject" == "docs(phase-139): record passed verification" ]]; then
    validate_phase_139_verification_commit "$commit" "$paths" || return 1
    printf 'phase_139_passed_verification'
    return
  fi
  if [[ "$subject" == "docs(phase-139): complete phase execution" ]]; then
    validate_phase_139_completion_commit "$commit" "$paths" || return 1
    printf 'phase_139_completion'
    return
  fi
  return 1
}

verify_external_snapshot_receipts() {
  local ledger_commit="$1" ledger="$2" evidence_base="$3" head="$4" remote_sha github_fingerprint maintained_fingerprint observed
  verify_git_snapshot_receipt "$ledger_commit" "$ledger" "$evidence_base" "$head" || return 1
  remote_sha="$(front_matter_value_from_blob "$ledger_commit" "$ledger" origin_main_sha 2>/dev/null || printf unavailable)"
  if [[ "$remote_sha" != unavailable ]]; then
    observed="$(git ls-remote "$REMOTE" refs/heads/main 2>/dev/null | awk 'NR == 1 { print $1 }')"
    if [[ "${LOCKSPIRE_PHASE_139_MAIN_ADVANCE:-0}" == 1 ]]; then
      [[ "$observed" == "$head" ]] || return 1
      git merge-base --is-ancestor "$remote_sha" "$head" 2>/dev/null || return 1
    else
      [[ "$observed" == "$remote_sha" ]] || return 1
    fi
  fi
  github_fingerprint="$(front_matter_value_from_blob "$ledger_commit" "$ledger" github_receipt_fingerprint 2>/dev/null || printf not_applicable)"
  if [[ "$github_fingerprint" != not_applicable ]]; then
    local receipt_dir receipt_file saved_output
    receipt_dir="$(mktemp -d "${TMPDIR:-/tmp}/lockspire-snapshot-receipt.XXXXXX")" || return 1
    receipt_file="$receipt_dir/github.md"
    saved_output="$OUTPUT"
    OUTPUT="$receipt_dir/verify"
    GITHUB_STATUS="not_applicable"
    github_auth_receipt
    if [[ "$GITHUB_STATUS" != unavailable ]] && collect_github_inventory "$(git rev-parse --show-toplevel)" > "$receipt_file"; then
      observed="$(receipt_fingerprint github "$receipt_file" 2>/dev/null || printf unavailable)"
    else
      observed="unavailable"
    fi
    OUTPUT="$saved_output"
    rm -f "$receipt_file"
    rmdir "$receipt_dir" 2>/dev/null || true
    [[ "$observed" == "$github_fingerprint" ]] || return 1
  fi
  maintained_fingerprint="$(front_matter_value_from_blob "$ledger_commit" "$ledger" maintained_receipt_fingerprint 2>/dev/null)" || return 1
  if [[ "$maintained_fingerprint" != not_applicable ]]; then
    local maintained_dir maintained_file saved_output
    maintained_dir="$(mktemp -d "${TMPDIR:-/tmp}/lockspire-snapshot-maintained.XXXXXX")" || return 1
    maintained_file="$maintained_dir/maintained.md"
    saved_output="$OUTPUT"
    OUTPUT="$maintained_dir/verify"
    MAINTAINED_STATUS="not_applicable"
    if (
      export GIT_INDEX_FILE="$maintained_dir/index"
      git read-tree "$evidence_base" || exit 1
      MAINTAINED_TREEISH="$evidence_base"
      MAINTAINED_USE_INDEX=1
      collect_maintained_records
    ) > "$maintained_file"; then
      observed="$(receipt_fingerprint maintained "$maintained_file" 2>/dev/null || printf unavailable)"
    else
      observed="unavailable"
    fi
    OUTPUT="$saved_output"
    rm -rf "$maintained_dir"
    [[ "$observed" == "$maintained_fingerprint" ]] || return 1
  fi
}

verify_phase_review_receipt() {
  local ledger_commit="$1" ledger="$2" phase="${3:-138}" review status expected observed
  case "$phase" in
    138) review=".planning/phases/138-baseline-inventory-evidence-taxonomy/138-REVIEW.md" ;;
    139) review=".planning/phases/139-required-truth-reconciliation/139-REVIEW.md" ;;
    *) return 1 ;;
  esac
  status="$(front_matter_value_from_blob "$ledger_commit" "$ledger" phase_review_status 2>/dev/null || true)"
  expected="$(front_matter_value_from_blob "$ledger_commit" "$ledger" phase_review_sha256 2>/dev/null || true)"
  if [[ "$status" != consumed || ! "$expected" =~ ^[0-9a-f]{64}$ ]]; then
    printf 'review_receipt|unavailable|refresh_required\n'
    return 1
  fi
  if [[ ! -f "$review" || -L "$review" || "$(wc -c < "$review" 2>/dev/null || printf 1048577)" -gt 1048576 ]]; then
    printf 'review_receipt|mismatch|refresh_required\n'
    return 1
  fi
  observed="$(python3 - "$review" <<'PY'
import hashlib
import pathlib
import sys
print(hashlib.sha256(pathlib.Path(sys.argv[1]).read_bytes()).hexdigest())
PY
)" || observed=unavailable
  if [[ "$observed" != "$expected" ]]; then
    printf 'review_receipt|mismatch|refresh_required\n'
    return 1
  fi
  printf 'review_receipt|consumed|%s\n' "$expected"
}

verify_preverify_worktree_projection() {
  local ledger_commit="$1" ledger="$2" evidence_base="$3" status normalized expected line path paths=""
  status="$(git status --porcelain=v2 --branch 2>/dev/null)" || {
    printf 'working_tree|unavailable|refresh_required|Working-tree status query failed.\n'
    return 1
  }
  validate_worktree_porcelain "$status" || {
    printf 'working_tree|unavailable|refresh_required|Malformed porcelain-v2 status evidence.\n'
    return 1
  }
  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ -n "$line" && "$line" != "# "* ]] || continue
    path="$(porcelain_record_path "$line" 2>/dev/null)" || return 1
    paths+="$path"$'\n'
  done <<< "$status"
  paths="$(printf '%s' "$paths" | sed '/^$/d' | LC_ALL=C sort -u)"
  if [[ -n "$paths" && "$paths" != .planning/phases/138-baseline-inventory-evidence-taxonomy/138-VERIFICATION.md ]]; then
    printf 'working_tree|unknown|refresh_required|Unexpected pre-verifier worktree paths.\n'
    return 1
  fi
  expected="$(git show "$ledger_commit:$ledger" 2>/dev/null | sed -n 's/^- Working-tree porcelain v2: `\(.*\)`$/\1/p')"
  if [[ -n "$expected" ]]; then
    normalized="$(printf '%s\n' "$status" | sed -E "s/^# branch\.oid .*/# branch.oid $evidence_base/" | LC_ALL=C sort)"
    [[ "$(markdown_value "$normalized")" == "$expected" ]] || {
      printf 'working_tree|mismatch|refresh_required|Pre-verifier projection differs from the immutable ledger.\n'
      return 1
    }
  elif [[ -n "$paths" ]]; then
    printf 'working_tree|mismatch|refresh_required|Immutable ledger has no matching worktree projection.\n'
    return 1
  fi
  if [[ -n "$paths" ]]; then
    printf 'working_tree|preexisting_verification|authorized_bookkeeping|%s\n' "$paths"
  else
    printf 'working_tree|clean|authorized_bookkeeping|none\n'
  fi
}

resolve_gsd_tools() {
  local repository_root user_home candidate
  repository_root="$(git rev-parse --show-toplevel 2>/dev/null)" || return 1
  user_home="$(python3 - <<'PY'
import os
import pwd
print(pwd.getpwuid(os.getuid()).pw_dir)
PY
)" || return 1
  for candidate in \
    "$repository_root/gsd-core/bin/gsd-tools.cjs" \
    "$repository_root/.codex/gsd-core/bin/gsd-tools.cjs" \
    "$repository_root/.claude/gsd-core/bin/gsd-tools.cjs" \
    "$repository_root/tools/gsd-capabilities/lockspire-phase-finalizer/fixtures/gsd-core/bin/gsd-tools.cjs" \
    "$user_home/.codex/gsd-core/bin/gsd-tools.cjs" \
    "$user_home/.claude/gsd-core/bin/gsd-tools.cjs" \
    "$user_home/.hermes/gsd-core/bin/gsd-tools.cjs" \
    "$user_home/.cursor/gsd-core/bin/gsd-tools.cjs" \
    "$user_home/.gemini/gsd-core/bin/gsd-tools.cjs" \
    "$user_home/.copilot/gsd-core/bin/gsd-tools.cjs" \
    "$user_home/.agents/gsd-core/bin/gsd-tools.cjs"; do
    if [[ -f "$candidate" && ! -L "$candidate" ]]; then
      printf '%s' "$candidate"
      return 0
    fi
  done
  return 1
}

validate_post_transition_receipt() {
  local expected_phase="${1:-138}" common receipt gsd_tools before_head
  common="$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null)" || return 1
  receipt="$common/gsd-lifecycle/post-completion-finalizer.json"
  gsd_tools="$(resolve_gsd_tools)" || return 1
  before_head="$(python3 - "$receipt" "$gsd_tools" "$expected_phase" <<'PY'
import hashlib, json, os, pathlib, stat, subprocess, sys

def safe_excepthook(error_type, error, traceback):
    print(f'receipt validation failed: {error}', file=sys.stderr)
sys.excepthook = safe_excepthook

receipt_path = pathlib.Path(sys.argv[1])
tools_path = pathlib.Path(sys.argv[2]).resolve()
expected_phase = sys.argv[3]
root = pathlib.Path(subprocess.check_output(['git', 'rev-parse', '--show-toplevel'], text=True).strip())
allowed = ['.planning/PROJECT.md', '.planning/STATE.md', '.planning/ROADMAP.md', '.planning/REQUIREMENTS.md']
keys = [('project', allowed[0]), ('state', allowed[1]), ('roadmap', allowed[2]), ('requirements', allowed[3])]

st = receipt_path.lstat()
if not stat.S_ISREG(st.st_mode) or stat.S_IMODE(st.st_mode) != 0o600 or st.st_size <= 0 or st.st_size > 1048576:
    raise ValueError('receipt type, mode, or size')
receipt = json.loads(receipt_path.read_text())
expected_point = 'plan:pre' if expected_phase == '139' else 'execute:complete:post'
if receipt.get('schemaVersion') != 1 or receipt.get('status') != 'pending' or receipt.get('phase') != expected_phase or receipt.get('point') != expected_point:
    raise ValueError('receipt envelope')
writer = receipt.get('writer')
if not isinstance(writer, dict) or writer.get('protocol') != 'gsd-transition-v1' or writer.get('allowedPaths') != allowed:
    raise ValueError('writer')
core = tools_path.parent.parent
writer_paths = [
    ('workflow', 'workflows/transition.md'),
    ('executeWorkflow', 'workflows/execute-phase.md'),
    ('planWorkflow', 'workflows/plan-phase.md'),
    ('stateHelper', 'tools/gsd-capabilities/lockspire-phase-finalizer/post-completion-finalizer-state.cjs'),
]
if set(writer) != {'protocol', 'allowedPaths', *(field for field, _ in writer_paths)}:
    raise ValueError('writer keys')
for field, rel in writer_paths:
    descriptor = writer.get(field)
    candidate = (root / rel).resolve() if field == 'stateHelper' else (core / rel).resolve()
    data = candidate.read_bytes()
    mode = stat.S_IMODE(candidate.lstat().st_mode)
    expected = {'path': rel, 'mode': mode, 'size': len(data), 'sha256': hashlib.sha256(data).hexdigest()}
    if descriptor != expected:
        raise ValueError(f'writer descriptor: {field}')

if expected_phase == '139':
    hooks = [{
        'capId': 'lockspire-phase-finalizer',
        'predicate': {
            'kind': 'command-exit-zero',
            'command': 'test "${PHASE_NUMBER}" != 140 || bash scripts/maintainer/run_lockspire_phase_finalizer.sh post-transition 139',
            'timeout': 2400,
        },
        'blocking': True,
        'onError': 'halt',
    }]
else:
    hooks = [{'capId': 'lockspire-phase-finalizer', 'command': 'lockspire-finalize post-transition', 'onError': 'halt'}]
compact = lambda value: json.dumps(value, ensure_ascii=False, separators=(',', ':')).encode()
if receipt.get('hooks') != hooks or receipt.get('hooksSha256') != hashlib.sha256(compact(hooks)).hexdigest():
    raise ValueError('hooks')

before, after = receipt.get('before'), receipt.get('after')
if not isinstance(before, dict) or not isinstance(after, dict):
    raise ValueError('observations')
transform = receipt.get('transformation')
if not isinstance(transform, dict) or transform.get('protocol') != 'gsd-transition-v1' or transform.get('allowedPaths') != allowed:
    raise ValueError('transformation')
evidence = {'protocol': 'gsd-transition-v1', 'writer': writer, 'before': before, 'after': after}
if transform.get('sha256') != hashlib.sha256(compact(evidence)).hexdigest():
    raise ValueError('transformation digest')

def identity(path):
    p = root / path
    if not p.exists(): return {'exists': False}
    s = p.lstat()
    if not stat.S_ISREG(s.st_mode): return {'exists': True, 'type': 'non-file', 'mode': stat.S_IMODE(s.st_mode)}
    data = p.read_bytes()
    return {'exists': True, 'type': 'file', 'mode': stat.S_IMODE(s.st_mode), 'size': len(data), 'sha256': hashlib.sha256(data).hexdigest()}

head = subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=root, text=True).strip()
porcelain = subprocess.check_output(['git', 'status', '--porcelain=v1', '-z', '--untracked-files=all'], cwd=root)
if after.get('head') != head or after.get('porcelainSha256') != hashlib.sha256(porcelain).hexdigest():
    raise ValueError('after observation')
for key, path in keys:
    if after.get(key) != identity(path): raise ValueError('after file identity')

before_head = before.get('head')
if not isinstance(before_head, str) or subprocess.run(['git', 'cat-file', '-e', before_head + '^{commit}'], cwd=root).returncode:
    raise ValueError('before head')
if before.get('porcelainSha256') != hashlib.sha256(b'').hexdigest():
    raise ValueError('before worktree')
for key, path in keys:
    data = subprocess.check_output(['git', 'show', before_head + ':' + path], cwd=root)
    entry = subprocess.check_output(['git', 'ls-tree', before_head, '--', path], cwd=root, text=True).split()[0]
    mode = 0o755 if entry == '100755' else 0o644
    expected = {'exists': True, 'type': 'file', 'mode': mode, 'size': len(data), 'sha256': hashlib.sha256(data).hexdigest()}
    if before.get(key) != expected: raise ValueError('before file identity')
print(before_head)
PY
)" || return 1
  [[ "$before_head" =~ ^[0-9a-f]{40}([0-9a-f]{24})?$ ]] || return 1
  case "$expected_phase" in
    138) validate_worktree_transition || return 1 ;;
    139) validate_phase_139_transition_commit || return 1 ;;
    *) return 1 ;;
  esac
  printf '%s' "$before_head"
}

verify_worktree_projection() {
  local status paths="" line path
  if ! status="$(git status --porcelain=v2 --branch 2>/dev/null)"; then
    printf 'working_tree|unavailable|refresh_required|Working-tree status query failed; no clean or authorized conclusion is available.\n'
    return 1
  fi
  if ! validate_worktree_porcelain "$status"; then
    printf 'working_tree|unavailable|refresh_required|Malformed porcelain-v2 status evidence; recollection is required.\n'
    return 1
  fi
  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ -n "$line" && "$line" != "# "* ]] || continue
    if path="$(porcelain_record_path "$line" 2>/dev/null)"; then
      paths+="${path}"$'\n'
    else
      printf 'working_tree|unavailable|refresh_required|Malformed porcelain-v2 status evidence; recollection is required.\n'
      return 1
    fi
  done <<< "$status"
  paths="$(printf '%s' "$paths" | sed '/^$/d' | LC_ALL=C sort -u)"
  [[ -n "$paths" ]] || { printf 'working_tree|clean|authorized_bookkeeping|none\n'; return 0; }
  if exact_path_set "$paths" '^\.planning/STATE\.md$' '^\.planning/(PROJECT|STATE)\.md$'; then
    validate_worktree_transition || {
      printf 'working_tree|unknown|refresh_required|Lifecycle document content does not prove a Phase 138 to Phase 139 transition.\n'
      return 1
    }
    printf 'working_tree|transition_bookkeeping|authorized_bookkeeping|.planning/PROJECT.md,.planning/STATE.md\n'
    return 0
  fi
  printf 'working_tree|unknown|refresh_required|%s\n' "$(markdown_value "$(tr '\n' ',' <<< "$paths" | sed 's/,$//')")"
  return 1
}

resolve_snapshot_ledger_commit() {
  local ledger="$1" head="$2" current_blob commit parents evidence_base paths blob
  local candidates=()
  current_blob="$(git rev-parse "$head:$ledger" 2>/dev/null || true)"
  [[ -n "$current_blob" ]] || return 1

  while IFS= read -r commit; do
    [[ -n "$commit" ]] || continue
    parents="$(git rev-list --parents -n 1 "$commit" 2>/dev/null || true)"
    [[ "$(wc -w <<< "$parents" | tr -d ' ')" -eq 2 ]] || continue
    validate_snapshot_ledger_schema "$commit" "$ledger" || continue
    evidence_base="$(front_matter_value_from_blob "$commit" "$ledger" evidence_base_sha 2>/dev/null || true)"
    [[ -n "$evidence_base" && "${parents#* }" == "$evidence_base" ]] || continue
    paths="$(git diff-tree --no-commit-id --name-only -r "$commit" 2>/dev/null | sed '/^$/d')"
    [[ "$paths" == "$ledger" ]] || continue
    blob="$(git rev-parse "$commit:$ledger" 2>/dev/null || true)"
    [[ -n "$blob" && "$blob" == "$current_blob" ]] || continue
    candidates+=("$commit")
  done < <(git rev-list --full-history "$head" -- "$ledger" 2>/dev/null)

  case "${#candidates[@]}" in
    1) printf '%s' "${candidates[0]}" ;;
    0) return 1 ;;
    *) return 2 ;;
  esac
}

verify_snapshot_relation() {
  local ledger="$1" worktree_mode="${2:-standard}" head ledger_commit resolution_status parents evidence_base ledger_paths committed_blob current_blob chain commit meta author committer subject paths class verdict=authorized_bookkeeping
  ledger="${ledger#./}"
  head="${LOCKSPIRE_INVENTORY_VERIFY_HEAD:-HEAD}"
  git cat-file -e "$head^{commit}" 2>/dev/null || { printf 'snapshot_relation: refresh_required\nreason: unknown requested head\n'; return 1; }
  SNAPSHOT_OBJECT_FORMAT="$(git rev-parse --show-object-format 2>/dev/null || printf unavailable)"
  if ledger_commit="$(resolve_snapshot_ledger_commit "$ledger" "$head")"; then
    :
  else
    resolution_status=$?
    printf 'snapshot_relation: refresh_required\n'
    if [[ "$resolution_status" -eq 2 ]]; then
      printf 'reason: ledger commit ambiguous\n'
    else
      printf 'reason: ledger commit unresolved\n'
    fi
    return 1
  fi
  parents="$(git rev-list --parents -n 1 "$ledger_commit")"
  [[ "$(wc -w <<< "$parents" | tr -d ' ')" -eq 2 ]] || verdict=refresh_required
  evidence_base="$(front_matter_value_from_blob "$ledger_commit" "$ledger" evidence_base_sha 2>/dev/null || true)"
  [[ -n "$evidence_base" && "${parents#* }" == "$evidence_base" ]] || verdict=refresh_required
  ledger_paths="$(git diff-tree --no-commit-id --name-only -r "$ledger_commit" | sed '/^$/d')"
  [[ "$ledger_paths" == "$ledger" ]] || verdict=refresh_required
  committed_blob="$(git rev-parse "$ledger_commit:$ledger" 2>/dev/null || true)"
  current_blob="$(git rev-parse "$head:$ledger" 2>/dev/null || true)"
  [[ -n "$committed_blob" && "$committed_blob" == "$current_blob" ]] || verdict=refresh_required
  git merge-base --is-ancestor "$ledger_commit" "$head" 2>/dev/null || verdict=refresh_required
  if [[ "$worktree_mode" == standard ]] && git show-ref --verify --quiet refs/heads/main; then git merge-base --is-ancestor "$ledger_commit" main 2>/dev/null || verdict=refresh_required; fi
  verify_external_snapshot_receipts "$ledger_commit" "$ledger" "$evidence_base" "$head" || verdict=refresh_required

  meta="$(git show -s --format='%an <%ae>|%cn <%ce>' "$ledger_commit")"
  author="${meta%%|*}"; committer="${meta#*|}"
  printf 'ledger_commit|%s|parent=%s|verdict=%s\n' "$ledger_commit" "$evidence_base" "$verdict"
  chain="$(git rev-list --reverse --first-parent "$ledger_commit..$head")"
  while IFS= read -r commit; do
    [[ -n "$commit" ]] || continue
    parents="$(git rev-list --parents -n 1 "$commit")"
    subject="$(git show -s --format=%s "$commit")"
    meta="$(git show -s --format='%an <%ae>|%cn <%ce>' "$commit")"
    paths="$(git diff-tree --no-commit-id --name-only -r "$commit" | LC_ALL=C sort)"
    class=unknown
    if [[ "$(wc -w <<< "$parents" | tr -d ' ')" -eq 2 && "${meta%%|*}" == "$author" && "${meta#*|}" == "$committer" ]]; then
      class="$(classify_lifecycle_commit "$commit" "$subject" "$paths" 2>/dev/null || printf unknown)"
    fi
    [[ "$class" != unknown ]] || verdict=refresh_required
    printf 'commit|%s|class=%s|author=%s|subject=%s|paths=%s|verdict=%s\n' \
      "$commit" "$class" "$(markdown_value "${meta%%|*}")" "$(markdown_value "$subject")" "$(markdown_value "$(tr '\n' ',' <<< "$paths" | sed 's/,$//')")" "$([[ "$class" == unknown ]] && printf refresh_required || printf authorized_bookkeeping)"
  done <<< "$chain"
  case "$worktree_mode" in
    standard) verify_worktree_projection || verdict=refresh_required ;;
    preverify) verify_preverify_worktree_projection "$ledger_commit" "$ledger" "$evidence_base" || verdict=refresh_required ;;
    receipt) : ;;
    *) verdict=refresh_required ;;
  esac
  printf 'snapshot_relation: %s\n' "$verdict"
  [[ "$verdict" == authorized_bookkeeping ]]
}

verify_preverify_relation() {
  local ledger="$1" commit subject verdict=0
  ledger="${ledger#./}"
  commit="$(resolve_snapshot_ledger_commit "$ledger" HEAD 2>/dev/null || true)"
  subject="$(git show -s --format=%s "$commit" 2>/dev/null || true)"
  if [[ -z "$commit" || "$commit" != "$(git rev-parse HEAD 2>/dev/null || true)" ||
    "$subject" != 'docs(phase-138): publish pre-verification baseline inventory' ]]; then
    printf 'relation_boundary|pre-verify|refresh_required\n'
    printf 'snapshot_relation: refresh_required\n'
    return 1
  fi
  printf 'relation_boundary|pre-verify|current\n'
  verify_phase_review_receipt "$commit" "$ledger" || verdict=1
  verify_snapshot_relation "$ledger" preverify || verdict=1
  return "$verdict"
}

verify_post_transition_chain() {
  local ledger="$1" before_head="$2" ledger_commit subject chain commit class classes=""
  ledger_commit="$(resolve_snapshot_ledger_commit "$ledger" "$before_head" 2>/dev/null)" || return 1
  subject="$(git show -s --format=%s "$ledger_commit" 2>/dev/null || true)"
  [[ "$subject" == 'docs(phase-138): publish pre-verification baseline inventory' ]] || return 1
  chain="$(git rev-list --reverse --first-parent "$ledger_commit..$before_head" 2>/dev/null)" || return 1
  while IFS= read -r commit; do
    [[ -n "$commit" ]] || continue
    subject="$(git show -s --format=%s "$commit")"
    class="$(classify_lifecycle_commit "$commit" "$subject" "$(git diff-tree --no-commit-id --name-only -r "$commit" | LC_ALL=C sort)" 2>/dev/null || true)"
    classes+="$class"$'\n'
  done <<< "$chain"
  [[ "$(printf '%s' "$classes" | sed '/^$/d')" == $'passed_verification\nphase_completion' ]]
}

verify_post_transition_relation() {
  local ledger="$1" before_head verdict=0
  if before_head="$(validate_post_transition_receipt)"; then
    printf 'relation_boundary|post-transition|receipt_authorized\n'
    printf 'receipt_before_head|%s|authorized_bookkeeping\n' "$before_head"
    if ! verify_post_transition_chain "${ledger#./}" "$before_head"; then
      printf 'relation_chain|post-transition|refresh_required\n'
      printf 'snapshot_relation: refresh_required\n'
      return 1
    fi
    LOCKSPIRE_INVENTORY_VERIFY_HEAD="$before_head" verify_snapshot_relation "$ledger" receipt || verdict=1
  else
    printf 'relation_boundary|post-transition|refresh_required\n'
    printf 'snapshot_relation: refresh_required\n'
    verdict=1
  fi
  return "$verdict"
}

validate_phase_139_main_advance() {
  local ledger_commit="$1" ledger="$2" candidate="$3" old_local old_remote current_local current_remote advertised
  [[ "$candidate" =~ ^[0-9a-f]{40}([0-9a-f]{24})?$ ]] || return 1
  [[ "$(git rev-parse HEAD 2>/dev/null)" == "$candidate" ]] || return 1
  current_local="$(git rev-parse refs/heads/main 2>/dev/null)" || return 1
  current_remote="$(git rev-parse "refs/remotes/$REMOTE/main" 2>/dev/null)" || return 1
  advertised="$(git ls-remote "$REMOTE" refs/heads/main 2>/dev/null | awk 'NR == 1 { print $1 }')"
  [[ "$current_local" == "$candidate" && "$current_remote" == "$candidate" && "$advertised" == "$candidate" ]] || return 1
  old_local="$(front_matter_value_from_blob "$ledger_commit" "$ledger" local_main_sha 2>/dev/null)" || return 1
  old_remote="$(front_matter_value_from_blob "$ledger_commit" "$ledger" origin_main_sha 2>/dev/null)" || return 1
  [[ "$old_local" =~ ^[0-9a-f]{40}([0-9a-f]{24})?$ && "$old_remote" =~ ^[0-9a-f]{40}([0-9a-f]{24})?$ ]] || return 1
  git merge-base --is-ancestor "$old_local" "$candidate" 2>/dev/null || return 1
  git merge-base --is-ancestor "$old_remote" "$candidate" 2>/dev/null
}

verify_phase_139_preverify_relation() {
  local ledger="${1#./}" commit subject verdict=0 status
  commit="$(resolve_snapshot_ledger_commit "$ledger" HEAD 2>/dev/null || true)"
  subject="$(git show -s --format=%s "$commit" 2>/dev/null || true)"
  status="$(git status --porcelain=v1 --untracked-files=all 2>/dev/null || printf unavailable)"
  if [[ -z "$commit" || "$commit" != "$(git rev-parse HEAD 2>/dev/null || true)" ||
    "$subject" != 'docs(phase-139): refresh baseline inventory before verification' || -n "$status" ]]; then
    printf 'relation_boundary|phase-139-preverify|refresh_required\n'
    printf 'snapshot_relation: refresh_required\n'
    return 1
  fi
  printf 'relation_boundary|phase-139-preverify|current\n'
  verify_phase_review_receipt "$commit" "$ledger" 139 || verdict=1
  LOCKSPIRE_INVENTORY_VERIFY_HEAD="$commit" verify_snapshot_relation "$ledger" receipt || verdict=1
  return "$verdict"
}

verify_phase_139_posttransition_chain() {
  local ledger="$1" before_head="$2" ledger_commit subject chain commit class classes=""
  ledger_commit="$(resolve_snapshot_ledger_commit "$ledger" "$before_head" 2>/dev/null)" || return 1
  subject="$(git show -s --format=%s "$ledger_commit" 2>/dev/null || true)"
  [[ "$subject" == 'docs(phase-139): refresh baseline inventory before verification' ]] || return 1
  chain="$(git rev-list --reverse --first-parent "$ledger_commit..$before_head" 2>/dev/null)" || return 1
  while IFS= read -r commit; do
    [[ -n "$commit" ]] || continue
    subject="$(git show -s --format=%s "$commit")"
    class="$(classify_lifecycle_commit "$commit" "$subject" "$(git diff-tree --no-commit-id --name-only -r "$commit" | LC_ALL=C sort)" 2>/dev/null || true)"
    classes+="$class"$'\n'
  done <<< "$chain"
  [[ "$(printf '%s' "$classes" | sed '/^$/d')" == $'phase_139_passed_verification\nphase_139_completion' ]]
}

verify_phase_139_posttransition_relation() {
  local ledger="${1#./}" before_head ledger_commit verdict=0
  if ! before_head="$(validate_post_transition_receipt 139)"; then
    printf 'relation_boundary|phase-139-posttransition|refresh_required\n'
    printf 'snapshot_relation: refresh_required\n'
    return 1
  fi
  printf 'relation_boundary|phase-139-posttransition|receipt_authorized\n'
  printf 'receipt_before_head|%s|authorized_bookkeeping\n' "$before_head"
  verify_phase_139_posttransition_chain "$ledger" "$before_head" || verdict=1
  ledger_commit="$(resolve_snapshot_ledger_commit "$ledger" "$before_head" 2>/dev/null || true)"
  validate_phase_139_main_advance "$ledger_commit" "$ledger" "$before_head" || verdict=1
  LOCKSPIRE_PHASE_139_MAIN_ADVANCE=1 LOCKSPIRE_INVENTORY_VERIFY_HEAD="$before_head" \
    verify_snapshot_relation "$ledger" receipt || verdict=1
  if [[ "$verdict" -ne 0 ]]; then
    printf 'relation_chain|phase-139-posttransition|refresh_required\n'
    printf 'snapshot_relation: refresh_required\n'
  fi
  return "$verdict"
}

verify_phase_139_sealed_candidate_relation() {
  local ledger="${1#./}" before_head verdict=0
  if ! before_head="$(validate_post_transition_receipt 139)"; then
    printf 'relation_boundary|phase-139-sealed-candidate|refresh_required\n'
    printf 'snapshot_relation: refresh_required\n'
    return 1
  fi
  printf 'relation_boundary|phase-139-sealed-candidate|receipt_authorized\n'
  printf 'receipt_before_head|%s|authorized_bookkeeping\n' "$before_head"
  verify_phase_139_posttransition_chain "$ledger" "$before_head" || verdict=1
  LOCKSPIRE_INVENTORY_VERIFY_HEAD="$before_head" verify_snapshot_relation "$ledger" receipt || verdict=1
  if [[ "$verdict" -ne 0 ]]; then
    printf 'relation_chain|phase-139-sealed-candidate|refresh_required\n'
    printf 'snapshot_relation: refresh_required\n'
  fi
  return "$verdict"
}

collect_maintained_family_paths() {
  local family="$1" path="$2"
  if [[ "$family" == active-records ]]; then
    git ls-files -z -- \
      ':(glob).planning/phases/*/*-REVIEW*.md' \
      ':(glob).planning/phases/*/*-AUDIT*.md' \
      ':(glob).planning/phases/*/*-VERIFICATION*.md' \
      ':(glob).planning/phases/*/*-UAT*.md' \
      ':(glob).planning/phases/*/*-HANDOFF*.md' \
      ':(glob).planning/phases/*/*-CHECKPOINT*.md'
  else
    git ls-files -z -- ":(glob)${path}"
  fi
}

collect_maintained_records() {
  local family_spec family path file count receipts="" lifecycle disposition confidence subject id fragment supersession selector_exit line_number marker_count marker_parse_failed archive_read_failed
  # Any future candidate outside this explicit manifest is an unclassified backstop:
  # it must be added as an ambiguous receipt, never silently guessed or dropped.
  MAINTAINED_STATUS="complete"
  MAINTAINED_EXIT=0
  MAINTAINED_LIMITATION="Every D-17 family was checked through the allowlisted manifest; archives are summarized unless an actionable marker requires expansion."
  MAINTAINED_SELECTOR_OUTPUT="$(mktemp "${MAINTAINED_OUTPUT}.selector.XXXXXX")"
  MAINTAINED_INCLUDED_OUTPUT="$(mktemp "${MAINTAINED_OUTPUT}.included.XXXXXX")"
  MAINTAINED_RECORD_OUTPUT="$(mktemp "${MAINTAINED_OUTPUT}.record.XXXXXX")"
  MAINTAINED_ROWS_OUTPUT="$(mktemp "${MAINTAINED_OUTPUT}.rows.XXXXXX")"
  MAINTAINED_AGGREGATED_OUTPUT="$(mktemp "${MAINTAINED_OUTPUT}.aggregated.XXXXXX")"

  for family_spec in "${MAINTAINED_SOURCE_FAMILIES[@]}"; do
    family="${family_spec%%:*}"; path="${family_spec#*:}"
    if [[ "$family" == tracked-markers ]]; then
      : > "$MAINTAINED_SELECTOR_OUTPUT"
      set +e
      if [[ "$MAINTAINED_USE_INDEX" -eq 1 ]]; then
        git grep --cached -z -nE 'TODO|FIXME' -- lib test scripts docs > "$MAINTAINED_SELECTOR_OUTPUT" 2>/dev/null
      else
        git grep -z -nE 'TODO|FIXME' -- lib test scripts docs > "$MAINTAINED_SELECTOR_OUTPUT" 2>/dev/null
      fi
      selector_exit=$?
      set -e
      if [[ "$selector_exit" -eq 1 && ! -s "$MAINTAINED_SELECTOR_OUTPUT" ]]; then
        receipts+="$(maintained_receipt_row "$family" complete-zero "$path" "selector succeeded with zero tracked markers")"$'\n'
        continue
      fi
      if [[ "$selector_exit" -gt 1 ]]; then
        MAINTAINED_STATUS="partial"
        MAINTAINED_EXIT="tracked-markers:${selector_exit}"
        MAINTAINED_LIMITATION="One or more D-17 selectors failed or produced ambiguous evidence; no complete or successful-zero maintained conclusion is available."
        receipts+="$(maintained_receipt_row "$family" unavailable "$path" "selector failed with exit ${selector_exit}; no complete-zero conclusion is available")"$'\n'
        continue
      fi
      if [[ "$selector_exit" -ne 0 || ! -s "$MAINTAINED_SELECTOR_OUTPUT" ]]; then
        MAINTAINED_STATUS="partial"
        MAINTAINED_EXIT="tracked-markers:inconsistent_exit_output"
        MAINTAINED_LIMITATION="The tracked-marker selector returned an impossible exit/output combination; no complete maintained conclusion is available."
        receipts+="$(maintained_receipt_row "$family" unavailable "$path" "selector returned an inconsistent exit/output combination; recheck required")"$'\n'
        continue
      fi
      marker_count=0
      marker_parse_failed=0
      while IFS= read -r -d '' file; do
        if ! IFS= read -r -d '' line_number; then
          marker_parse_failed=1
          break
        fi
        IFS= read -r fragment || fragment=""
        if [[ -z "$file" || ! "$line_number" =~ ^[1-9][0-9]*$ || -z "$fragment" ]]; then
          marker_parse_failed=1
          break
        fi
        is_excluded_maintained_path "$file" && continue
        subject="$(canonical_record_subject "$file")"
        id="$(stable_evidence_id REC record "$subject")"
        maintained_record_json \
          "$id" tracked_marker "$subject" "$family" active defer-with-trigger "$file" \
          "Credible tracked marker; content intentionally not copied" corroborated \
          "Revalidate marker context and owner before action" "repository maintainer" \
          >> "$MAINTAINED_ROWS_OUTPUT"
        marker_count=$((marker_count + 1))
      done < "$MAINTAINED_SELECTOR_OUTPUT"
      if [[ "$marker_parse_failed" -eq 1 || "$marker_count" -eq 0 ]]; then
        MAINTAINED_STATUS="partial"
        MAINTAINED_EXIT="tracked-markers:malformed_output"
        MAINTAINED_LIMITATION="The tracked-marker selector returned malformed NUL-delimited output; no complete maintained conclusion is available."
        receipts+="$(maintained_receipt_row "$family" unavailable "$path" "selector returned malformed NUL-delimited output; recheck required")"$'\n'
      else
        receipts+="$(maintained_receipt_row "$family" complete "$path" "bounded marker scan completed with ${marker_count} matched record(s)")"$'\n'
      fi
      continue
    fi
    : > "$MAINTAINED_SELECTOR_OUTPUT"
    if collect_maintained_family_paths "$family" "$path" > "$MAINTAINED_SELECTOR_OUTPUT" 2>/dev/null; then
      selector_exit=0
    else
      selector_exit=$?
    fi
    if [[ "$selector_exit" -ne 0 ]]; then
      MAINTAINED_STATUS="partial"
      MAINTAINED_EXIT="${family}:${selector_exit}"
      MAINTAINED_LIMITATION="One or more D-17 selectors failed or produced ambiguous evidence; no complete or successful-zero maintained conclusion is available."
      receipts+="$(maintained_receipt_row "$family" unavailable "$path" "selector failed with exit ${selector_exit}; no complete-zero conclusion is available")"$'\n'
      continue
    fi
    : > "$MAINTAINED_INCLUDED_OUTPUT"
    file=""
    while IFS= read -r -d '' file; do
      [[ -n "$file" ]] || continue
      is_excluded_maintained_path "$file" && continue
      printf '%s\0' "$file" >> "$MAINTAINED_INCLUDED_OUTPUT"
      file=""
    done < "$MAINTAINED_SELECTOR_OUTPUT"
    if [[ -n "$file" ]]; then
      MAINTAINED_STATUS="partial"
      MAINTAINED_EXIT="${family}:malformed_output"
      MAINTAINED_LIMITATION="A maintained selector returned malformed NUL-delimited output; no complete maintained conclusion is available."
      receipts+="$(maintained_receipt_row "$family" unavailable "$path" "selector returned malformed NUL-delimited output; recheck required")"$'\n'
      continue
    fi
    count="$(LC_ALL=C tr -cd '\000' < "$MAINTAINED_INCLUDED_OUTPUT" | wc -c | tr -d ' ')"
    if [[ "$count" == 0 ]]; then
      receipts+="$(maintained_receipt_row "$family" complete-zero "$path" "selector succeeded with zero tracked matches")"$'\n'
      continue
    fi
    archive_read_failed=0
    if ! is_archive_family "$family"; then
      receipts+="$(maintained_receipt_row "$family" complete "$path" "${count} bounded tracked matches")"$'\n'
    fi
    while IFS= read -r -d '' file; do
      [[ -n "$file" ]] || continue
      : > "$MAINTAINED_RECORD_OUTPUT"
      if ! git show "$MAINTAINED_TREEISH:$file" > "$MAINTAINED_RECORD_OUTPUT" 2>/dev/null; then
        selector_exit=$?
        MAINTAINED_STATUS="partial"
        MAINTAINED_EXIT="${family}:record_unavailable"
        MAINTAINED_LIMITATION="One or more selected maintained records could not be read; no complete maintained conclusion is available."
        receipts+="$(maintained_receipt_row "$family" unavailable "$file" "selected record could not be read; recheck required")"$'\n'
        archive_read_failed=1
        continue
      fi
      fragment="$(sed -n '1,80p' "$MAINTAINED_RECORD_OUTPUT" | tr '\n' ' ' | cut -c1-400)"
      if is_archive_family "$family" && ! requires_archive_expansion "$MAINTAINED_RECORD_OUTPUT"; then continue; fi
      if [[ "$family" == active-records ]] && phase_138_gaps_report_superseded "$file"; then
        receipts+="$(maintained_receipt_row "$family" superseded-lifecycle "$file" "all declared Phase 138 gap plans have complete summaries")"$'\n'
        continue
      fi
      IFS=$'\t' read -r lifecycle disposition confidence <<< "$(classify_record "$family" "$file" "$MAINTAINED_RECORD_OUTPUT" "$fragment")"
      subject="$(canonical_record_subject "$file")"
      if [[ "$lifecycle" == unclassified ]] || ! valid_maintained_taxonomy "$lifecycle" "$disposition" "$confidence"; then
        MAINTAINED_STATUS="partial"
        MAINTAINED_EXIT="${family}:ambiguous"
        MAINTAINED_LIMITATION="One or more D-17 selectors failed or produced ambiguous evidence; no complete maintained conclusion is available."
        receipts+="$(maintained_receipt_row "$family" unclassified/ambiguous "$file" "recheck required before a maintained row can be proposed")"$'\n'
        continue
      fi
      id="$(stable_evidence_id REC record "$subject")"
      supersession="$(printf '%s' "$fragment" | grep -Eio 'supersedes:[[:space:]]*[^ ]+|superseded-by:[[:space:]]*[^ ]+' | tr '\n' ' ' | sed 's/[[:space:]]*$//' || true)"
      maintained_record_json \
        "$id" maintained_record "$subject" "$family" "$lifecycle" "$disposition" \
        "${family}:${file}" \
        "Allowlisted maintained record; source preserved${supersession:+; $supersession}" \
        "$confidence" "Revalidate current state, authority, and recovery path before action" \
        "repository maintainer" >> "$MAINTAINED_ROWS_OUTPUT"
    done < "$MAINTAINED_INCLUDED_OUTPUT"
    if is_archive_family "$family" && [[ "$archive_read_failed" -eq 0 ]]; then
      summarize_archive_container "$family" "$path" "$count" >> "$MAINTAINED_ROWS_OUTPUT"
      receipts+="$(maintained_receipt_row "$family" archive-summary "$path" "${count} retained records summarized")"$'\n'
    fi
  done
  if ! deduplicate_record_refs < "$MAINTAINED_ROWS_OUTPUT" > "$MAINTAINED_AGGREGATED_OUTPUT"; then
    MAINTAINED_STATUS="partial"
    MAINTAINED_EXIT="structured_record_failure"
    MAINTAINED_LIMITATION="Maintained structured records were invalid or contradictory; no shifted or partial row was rendered."
    receipts+="$(maintained_receipt_row "maintained-aggregate" unavailable "structured REC validation" "invalid or contradictory structured record; recheck required")"$'\n'
    : > "$MAINTAINED_AGGREGATED_OUTPUT"
  fi
  rm -f "$MAINTAINED_SELECTOR_OUTPUT" "$MAINTAINED_INCLUDED_OUTPUT" "$MAINTAINED_RECORD_OUTPUT"
  MAINTAINED_SELECTOR_OUTPUT=""
  MAINTAINED_INCLUDED_OUTPUT=""
  MAINTAINED_RECORD_OUTPUT=""
  render_maintained_receipts "$receipts"
  render_maintained_inventory "$MAINTAINED_AGGREGATED_OUTPUT"
  rm -f "$MAINTAINED_ROWS_OUTPUT" "$MAINTAINED_AGGREGATED_OUTPUT"
  MAINTAINED_ROWS_OUTPUT=""
  MAINTAINED_AGGREGATED_OUTPUT=""
}

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --scope) [[ "$#" -ge 2 ]] || die "Missing value for --scope"; SCOPE="$2"; shift 2 ;;
    --output) [[ "$#" -ge 2 ]] || die "Missing value for --output"; OUTPUT="$2"; shift 2 ;;
    --replace) REPLACE=1; shift ;;
    --verify-snapshot-relation) [[ "$#" -ge 2 ]] || die "Missing value for --verify-snapshot-relation"; VERIFY_SNAPSHOT_LEDGER="$2"; shift 2 ;;
    --verify-preverify-relation) [[ "$#" -ge 2 ]] || die "Missing value for --verify-preverify-relation"; VERIFY_PREVERIFY_LEDGER="$2"; shift 2 ;;
    --verify-post-transition-relation) [[ "$#" -ge 2 ]] || die "Missing value for --verify-post-transition-relation"; VERIFY_POST_TRANSITION_LEDGER="$2"; shift 2 ;;
    --verify-phase-139-preverify-relation) [[ "$#" -ge 2 ]] || die "Missing value for --verify-phase-139-preverify-relation"; VERIFY_PHASE_139_PREVERIFY_LEDGER="$2"; shift 2 ;;
    --verify-phase-139-sealed-candidate-relation) [[ "$#" -ge 2 ]] || die "Missing value for --verify-phase-139-sealed-candidate-relation"; VERIFY_PHASE_139_SEALED_CANDIDATE_LEDGER="$2"; shift 2 ;;
    --verify-phase-139-posttransition-relation) [[ "$#" -ge 2 ]] || die "Missing value for --verify-phase-139-posttransition-relation"; VERIFY_PHASE_139_POST_TRANSITION_LEDGER="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) die "Unknown argument: $1" ;;
  esac
done

command -v git >/dev/null 2>&1 || die "git is required"
command -v python3 >/dev/null 2>&1 || die "python3 is required for no-follow atomic publication"
command -v jq >/dev/null 2>&1 || die "jq is required for structured evidence processing"

verify_mode_count=0
[[ -z "$VERIFY_SNAPSHOT_LEDGER" ]] || verify_mode_count=$((verify_mode_count + 1))
[[ -z "$VERIFY_PREVERIFY_LEDGER" ]] || verify_mode_count=$((verify_mode_count + 1))
[[ -z "$VERIFY_POST_TRANSITION_LEDGER" ]] || verify_mode_count=$((verify_mode_count + 1))
[[ -z "$VERIFY_PHASE_139_PREVERIFY_LEDGER" ]] || verify_mode_count=$((verify_mode_count + 1))
[[ -z "$VERIFY_PHASE_139_SEALED_CANDIDATE_LEDGER" ]] || verify_mode_count=$((verify_mode_count + 1))
[[ -z "$VERIFY_PHASE_139_POST_TRANSITION_LEDGER" ]] || verify_mode_count=$((verify_mode_count + 1))
[[ "$verify_mode_count" -le 1 ]] || die "Relation verification modes are mutually exclusive"
if [[ "$verify_mode_count" -eq 1 ]]; then
  [[ -z "$SCOPE" && -z "$OUTPUT" && "$REPLACE" -eq 0 ]] || die "Relation verification is mutually exclusive with collection options"
fi
if [[ -n "$VERIFY_SNAPSHOT_LEDGER" ]]; then
  verify_snapshot_relation "$VERIFY_SNAPSHOT_LEDGER"
  exit $?
fi
if [[ -n "$VERIFY_PREVERIFY_LEDGER" ]]; then
  verify_preverify_relation "$VERIFY_PREVERIFY_LEDGER"
  exit $?
fi
if [[ -n "$VERIFY_POST_TRANSITION_LEDGER" ]]; then
  verify_post_transition_relation "$VERIFY_POST_TRANSITION_LEDGER"
  exit $?
fi
if [[ -n "$VERIFY_PHASE_139_PREVERIFY_LEDGER" ]]; then
  verify_phase_139_preverify_relation "$VERIFY_PHASE_139_PREVERIFY_LEDGER"
  exit $?
fi
if [[ -n "$VERIFY_PHASE_139_SEALED_CANDIDATE_LEDGER" ]]; then
  verify_phase_139_sealed_candidate_relation "$VERIFY_PHASE_139_SEALED_CANDIDATE_LEDGER"
  exit $?
fi
if [[ -n "$VERIFY_PHASE_139_POST_TRANSITION_LEDGER" ]]; then
  verify_phase_139_posttransition_relation "$VERIFY_PHASE_139_POST_TRANSITION_LEDGER"
  exit $?
fi

[[ -z "$SCOPE" || "$SCOPE" == git-baseline || "$SCOPE" == git || "$SCOPE" == github || "$SCOPE" == maintained ]] || die "--scope git-baseline, git, github, or maintained is required"
[[ -n "$OUTPUT" ]] || die "--output PATH is required"
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || die 'Not inside a Git repository')"
OUTPUT_DIR="$(dirname -- "$OUTPUT")"
OUTPUT_BASENAME="$(basename -- "$OUTPUT")"
[[ "$OUTPUT_BASENAME" != . && "$OUTPUT_BASENAME" != .. ]] || die "Output must name an exact ledger file"
if [[ "$OUTPUT_DIR" == /* ]]; then
  REQUESTED_OUTPUT_DIR="$OUTPUT_DIR"
else
  REQUESTED_OUTPUT_DIR="$INVOCATION_DIR/$OUTPUT_DIR"
fi
[[ -d "$REQUESTED_OUTPUT_DIR" && ! -L "$REQUESTED_OUTPUT_DIR" ]] || die "Output parent must be an existing non-symlink directory: $OUTPUT_DIR"
OUTPUT_PARENT="$(cd -P "$REQUESTED_OUTPUT_DIR" && pwd)"
OUTPUT="$OUTPUT_PARENT/$OUTPUT_BASENAME"
cd "$REPO_ROOT"
LOCK_DIR="${OUTPUT}.lock"
register_owned_worktree_path "$OUTPUT"
register_owned_worktree_path "$LOCK_DIR"
cleanup() {
  local owned
  cleanup_github_temp
  for owned in "$TEMP_OUTPUT" "$GIT_DOMAINS_OUTPUT" "$GITHUB_OUTPUT" "$MAINTAINED_OUTPUT" \
    "$MAINTAINED_SELECTOR_OUTPUT" "$MAINTAINED_INCLUDED_OUTPUT" "$MAINTAINED_RECORD_OUTPUT" "$MAINTAINED_ROWS_OUTPUT" \
    "$MAINTAINED_AGGREGATED_OUTPUT" "$RECHECK_OUTPUT"; do
    [[ -z "$owned" ]] || rm -f -- "$owned"
  done
  if [[ "$LOCK_OWNED" -eq 1 ]]; then
    rmdir "$LOCK_DIR" 2>/dev/null || true
    LOCK_OWNED=0
  fi
}
trap cleanup EXIT
trap 'cleanup; trap - EXIT; exit 143' HUP INT TERM

# Publication authority is decided only by the current target-lock owner. A
# waiter must acquire the released lock and re-observe the target rather than
# reusing any pre-lock existence or source observation.
acquire_output_lock "$OUTPUT"
authorize_output_target

# The allowed metadata refresh and every snapshot observation occur inside the
# same lock ownership interval as the final atomic rename.
capture_snapshot_identity

TEMP_OUTPUT="$(mktemp "${OUTPUT}.tmp.XXXXXX")"
GIT_DOMAINS_OUTPUT="$(mktemp "${OUTPUT}.git.XXXXXX")"
GITHUB_OUTPUT="$(mktemp "${OUTPUT}.github-render.XXXXXX")"
MAINTAINED_OUTPUT="$(mktemp "${OUTPUT}.maintained.XXXXXX")"
register_owned_worktree_path "$TEMP_OUTPUT"
register_owned_worktree_path "$GIT_DOMAINS_OUTPUT"
register_owned_worktree_path "$GITHUB_OUTPUT"
register_owned_worktree_path "$MAINTAINED_OUTPUT"

if [[ "$SCOPE" == git || -z "$SCOPE" ]]; then
  collect_git_refs > "$GIT_DOMAINS_OUTPUT"
  collect_git_tags >> "$GIT_DOMAINS_OUTPUT"
  collect_git_worktrees >> "$GIT_DOMAINS_OUTPUT"
fi
if [[ "$SCOPE" == github || -z "$SCOPE" ]]; then
  github_auth_receipt
  collect_github_inventory "$REPO_ROOT" > "$GITHUB_OUTPUT"
fi
if [[ "$SCOPE" == maintained || -z "$SCOPE" ]]; then
  collect_maintained_records > "$MAINTAINED_OUTPUT"
fi
capture_source_receipt_fingerprints
collect_git_baseline "$REPO_ROOT" no > "$TEMP_OUTPUT"
if [[ "$SCOPE" == git || -z "$SCOPE" ]]; then
  cat "$GIT_DOMAINS_OUTPUT" >> "$TEMP_OUTPUT"
fi
if [[ "$SCOPE" == github || -z "$SCOPE" ]]; then
  cat "$GITHUB_OUTPUT" >> "$TEMP_OUTPUT"
fi
if [[ "$SCOPE" == maintained || -z "$SCOPE" ]]; then
  cat "$MAINTAINED_OUTPUT" >> "$TEMP_OUTPUT"
fi
render_source_receipts >> "$TEMP_OUTPUT"
if [[ -z "$SCOPE" ]]; then
  {
    render_post_snapshot_currentness_relation
    printf '## Limitations and revalidation\n\n'
    printf -- '- Observed evidence is proposal-only. Phase 139 must revalidate exact repository and release truth before reconciliation.\n'
    printf -- '- Phase 140 must revalidate target, authority, recovery path, uncommitted-work safety, historical-evidence safety, and required gates before any action.\n'
    printf -- '- Phase 141 must revalidate final receipts against the closing baseline SHA before declaring sustained readiness.\n\n'
  } >> "$TEMP_OUTPUT"
fi
verify_snapshot_identity_unchanged "$REPO_ROOT"
publish_output_atomically
TEMP_OUTPUT=""
rm -f "$GIT_DOMAINS_OUTPUT" "$GITHUB_OUTPUT" "$MAINTAINED_OUTPUT"
rmdir "$LOCK_DIR"
LOCK_OWNED=0
trap - EXIT HUP INT TERM
