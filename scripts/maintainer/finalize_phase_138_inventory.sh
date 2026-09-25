#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-}"
FLAG="${2:-}"
PHASE="${3:-}"
[[ "$#" -eq 3 && "$FLAG" == --phase && ( "$PHASE" == 138 || "$PHASE" == 139 ) ]] || {
  printf 'phase inventory finalizer: expected MODE --phase 138|139\n' >&2
  exit 2
}
[[ "$MODE" == pre-verify || "$MODE" == post-transition ]] || {
  printf 'phase %s inventory finalizer: unsupported mode\n' "$PHASE" >&2
  exit 2
}
if [[ "$PHASE" == 139 && "$MODE" != pre-verify ]]; then
  printf 'phase 139 inventory finalizer: only pre-verify is supported\n' >&2
  exit 2
fi

if [[ "$PHASE" == 138 ]]; then
  PUBLICATION_SUBJECT='docs(phase-138): publish pre-verification baseline inventory'
  PREVERIFY_MODE='--verify-preverify-relation'
else
  PUBLICATION_SUBJECT='docs(phase-139): refresh baseline inventory before verification'
  PREVERIFY_MODE='--verify-phase-139-preverify-relation'
fi

ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || {
  printf 'phase %s inventory finalizer: repository unavailable\n' "$PHASE" >&2
  exit 1
}
cd "$ROOT"

SCRIPT_DIR="$(cd -P "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
COLLECTOR="$SCRIPT_DIR/baseline_inventory.sh"
LEDGER=".planning/phases/138-baseline-inventory-evidence-taxonomy/baseline-inventory-2026-08-28.md"
[[ -f "$COLLECTOR" && ! -L "$COLLECTOR" ]] || {
  printf 'phase %s inventory finalizer: collector unavailable\n' "$PHASE" >&2
  exit 1
}

if [[ "$MODE" == post-transition ]]; then
  exec bash "$COLLECTOR" --verify-post-transition-relation "$LEDGER"
fi

GIT_DIR="$(git rev-parse --absolute-git-dir 2>/dev/null)"
COMMON_DIR="$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null)"
[[ "$GIT_DIR" == "$COMMON_DIR" ]] || {
  printf 'phase %s inventory finalizer: pre-verify requires the primary checkout\n' "$PHASE" >&2
  exit 1
}

FINALIZER_LOCK="$COMMON_DIR/phase-$PHASE-finalizer.lock"
if ! mkdir -- "$FINALIZER_LOCK" 2>/dev/null; then
  printf 'phase %s inventory finalizer: another pre-verify finalizer is active\n' "$PHASE" >&2
  exit 1
fi
TMP_DIR=""
cleanup() {
  if [[ -n "$TMP_DIR" && "$TMP_DIR" == "$COMMON_DIR/phase-$PHASE-preverify."* ]]; then
    rm -rf -- "$TMP_DIR"
  fi
  rmdir -- "$FINALIZER_LOCK" 2>/dev/null || true
}
trap cleanup EXIT
trap 'cleanup; exit 129' HUP
trap 'cleanup; exit 130' INT
trap 'cleanup; exit 143' TERM

STATE=".planning/STATE.md"
[[ -f "$STATE" && ! -L "$STATE" ]] || {
  printf 'phase %s inventory finalizer: phase state unavailable\n' "$PHASE" >&2
  exit 1
}
state_phase="$(awk '
  NR == 1 && $0 == "---" { front = 1; next }
  front && $0 == "---" { exit }
  front && /^current_phase:[[:space:]]*/ { sub("^[^:]+:[[:space:]]*", ""); print; count++ }
  END { if (count != 1) exit 1 }
' "$STATE")" || state_phase=unavailable
state_status="$(awk '
  NR == 1 && $0 == "---" { front = 1; next }
  front && $0 == "---" { exit }
  front && /^status:[[:space:]]*/ { sub("^[^:]+:[[:space:]]*", ""); print; count++ }
  END { if (count != 1) exit 1 }
' "$STATE")" || state_status=unavailable
[[ "$state_phase" == "$PHASE" && "$state_status" == verifying ]] || {
  printf 'phase %s inventory finalizer: phase state is not executable\n' "$PHASE" >&2
  exit 1
}

if [[ "$PHASE" == 139 ]]; then
  for plan in 01 02 03 04 05 06 07; do
    summary=".planning/phases/139-required-truth-reconciliation/139-${plan}-SUMMARY.md"
    [[ -f "$summary" && ! -L "$summary" ]] &&
      awk 'NR == 1 && $0 == "---" { front=1; next } front && $0 == "---" { exit } front && /^status:[[:space:]]*complete[[:space:]]*$/ { found++ } END { exit !(found == 1) }' "$summary" || {
        printf 'phase 139 inventory finalizer: plan summaries are incomplete\n' >&2
        exit 1
      }
  done
  REVIEW=".planning/phases/139-required-truth-reconciliation/139-REVIEW.md"
  [[ -f "$REVIEW" && ! -L "$REVIEW" ]] &&
    awk 'NR == 1 && $0 == "---" { front=1; next } front && $0 == "---" { exit } front && /^status:[[:space:]]*clean[[:space:]]*$/ { found++ } END { exit !(found == 1) }' "$REVIEW" || {
      printf 'phase 139 inventory finalizer: code review is incomplete\n' >&2
      exit 1
    }
fi

# A retry never republishes. The production relation must prove that the fixed
# publication is still current before the command returns successfully.
if [[ -f "$LEDGER" ]] &&
  [[ "$(git show -s --format=%s HEAD 2>/dev/null || true)" == "$PUBLICATION_SUBJECT" ]]; then
  bash "$COLLECTOR" "$PREVERIFY_MODE" "$LEDGER"
  exit $?
fi

[[ -z "$(git status --porcelain=v1 --untracked-files=all)" ]] || {
  printf 'phase %s inventory finalizer: working tree contains unrelated changes\n' "$PHASE" >&2
  exit 1
}

LEDGER_PARENT="$(dirname "$LEDGER")"
[[ -d "$LEDGER_PARENT" && ! -L "$LEDGER_PARENT" ]] || {
  printf 'phase %s inventory finalizer: canonical parent unavailable\n' "$PHASE" >&2
  exit 1
}
if [[ -e "$LEDGER" || -L "$LEDGER" ]]; then
  [[ -f "$LEDGER" && ! -L "$LEDGER" ]] || {
    printf 'phase %s inventory finalizer: canonical ledger is not a regular file\n' "$PHASE" >&2
    exit 1
  }
fi

TMP_DIR="$(mktemp -d "$COMMON_DIR/phase-$PHASE-preverify.XXXXXX")"
CANDIDATE_ONE="$TMP_DIR/candidate-one.md"
CANDIDATE_TWO="$TMP_DIR/candidate-two.md"
NORMALIZED_ONE="$TMP_DIR/candidate-one.normalized"
NORMALIZED_TWO="$TMP_DIR/candidate-two.normalized"

if [[ "$PHASE" == 139 ]]; then
  LOCKSPIRE_INVENTORY_REVIEW_PHASE=139 bash "$COLLECTOR" --output "$CANDIDATE_ONE"
  LOCKSPIRE_INVENTORY_REVIEW_PHASE=139 bash "$COLLECTOR" --output "$CANDIDATE_TWO"
else
  bash "$COLLECTOR" --output "$CANDIDATE_ONE"
  bash "$COLLECTOR" --output "$CANDIDATE_TWO"
fi

candidate_is_complete() {
  local candidate="$1"
  awk '
    NR == 1 && $0 == "---" { front=1; next }
    front && $0 == "---" { exit }
    front && /^status:[[:space:]]*"complete"[[:space:]]*$/ { complete++ }
    front && /^phase_review_status:[[:space:]]*"consumed"[[:space:]]*$/ { review++ }
    END { exit !(complete == 1 && review == 1) }
  ' "$candidate"
}
candidate_is_complete "$CANDIDATE_ONE" && candidate_is_complete "$CANDIDATE_TWO" || {
  printf 'phase %s inventory finalizer: source observations are incomplete\n' "$PHASE" >&2
  exit 1
}

normalize_candidate() {
  sed -E \
    -e 's/^(collection_started_at: ).*$/\1"normalized"/' \
    -e 's/^(collection_finished_at: ).*$/\1"normalized"/' \
    -e 's/^(This ledger is an immutable snapshot bounded as of )`[^`]+`/\1`normalized`/' \
    -e 's/^- Collection window: `[^`]+` to `[^`]+`$/- Collection window: `normalized` to `normalized`/' \
    -e 's/^- Snapshot boundary: bounded as of `[^`]+`/- Snapshot boundary: bounded as of `normalized`/' \
    "$1" > "$2"
}
normalize_candidate "$CANDIDATE_ONE" "$NORMALIZED_ONE"
normalize_candidate "$CANDIDATE_TWO" "$NORMALIZED_TWO"
cmp -s "$NORMALIZED_ONE" "$NORMALIZED_TWO" || {
  printf 'phase %s inventory finalizer: independent observations disagree\n' "$PHASE" >&2
  exit 1
}

mv -f -- "$CANDIDATE_TWO" "$LEDGER"
git add -- "$LEDGER"
staged="$(git diff --cached --name-only --diff-filter=ACMR | sed '/^$/d')"
[[ "$staged" == "$LEDGER" ]] || {
  printf 'phase %s inventory finalizer: publication is not ledger-only\n' "$PHASE" >&2
  exit 1
}
git commit -m "$PUBLICATION_SUBJECT" -- "$LEDGER"
bash "$COLLECTOR" "$PREVERIFY_MODE" "$LEDGER"
