#!/usr/bin/env bash
set -uo pipefail

# ---------------------------------------------------------------------------
# adopter_walk_ci.sh -- runs `mix adopter.walk` (never `set -e`; a RED walk
# exiting 1 with FAIL_COUNT > 0 is the expected common case, not a wrapper
# failure) and verifies its report against the committed baseline via
# adopter_walk_verify.py. The walk's own exit code is never the gate -- see
# that script's own doc comment for why.
#
# Deliberately named adopter_walk_ci.sh, not adopter_path_walk*, so a grep for
# "adopter_path_walk" over mix.exs's `ci:` alias slice (which
# adopter_walk_contract_test.exs asserts stays empty) can never accidentally
# match this file's own name.
#
# On a mismatch (verifier exit 3), this runs a second attempt relying on the
# walk's own .walk/steps/*.done resume markers -- never --force -- so only
# genuinely incomplete steps re-run. If the same (step_id, occurrence) keys
# mismatch identically on both attempts, that is a reproducible regression.
# If the mismatched key set differs between attempts, this reports UNSTABLE
# and flags it INFRA rather than REGRESSION, because a real regression is
# deterministic and a transient CDN blip, database hiccup, or similar is not.
# ---------------------------------------------------------------------------

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$REPO_ROOT"

WORKDIR="tmp/adopter-walk"
REPORT_JSON="$WORKDIR/.walk/report.json"
BASELINE="scripts/maintainer/adopter_walk_baseline.json"
VERIFY="scripts/maintainer/adopter_walk_verify.py"

mkdir -p "$WORKDIR/.walk"

write_summary() {
  local verdict="$1"
  local body="$2"

  if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then
    {
      printf '## Adopter path walk verdict: %s\n\n' "$verdict"
      printf '```\n%s\n```\n' "$body"
    } >>"$GITHUB_STEP_SUMMARY"
  fi
}

run_walk() {
  # Never `set -e`: the walk's own exit 1 (RED, FAIL_COUNT > 0) is the expected common case.
  bash scripts/maintainer/adopter_path_walk.sh || true
}

# Prints "step_id<TAB>occurrence<TAB>actual_level" for every (step_id, occurrence) key whose
# level in the given report disagrees with the baseline -- read directly from the report file,
# never through adopter_walk_verify.py's own precondition gate. A resumed second-attempt
# report would trip that gate outright; this is a narrower, separate comparison over specific
# keys only, used solely to judge reproducibility, never presented as a full walk verdict.
mismatched_keys() {
  local report_path="$1"

  python3 - "$report_path" "$BASELINE" <<'PYEOF'
import json
import sys

report_path, baseline_path = sys.argv[1], sys.argv[2]

with open(report_path, "r", encoding="utf-8") as handle:
    report = json.load(handle)

with open(baseline_path, "r", encoding="utf-8") as handle:
    baseline = json.load(handle)

expected = {(row["step_id"], row["occurrence"]): row["level"] for row in baseline["rows"]}
actual = {
    (row["step_id"], row["occurrence"]): row["level"] for row in report.get("rows", [])
}

for key in sorted(set(expected) | set(actual)):
    if expected.get(key) != actual.get(key):
        print("{0}\t{1}\t{2}".format(key[0], key[1], actual.get(key, "MISSING")))
PYEOF
}

echo "adopter-walk-ci: attempt 1"
run_walk

VERIFY_LOG1="$WORKDIR/.walk/verify_attempt1.log"
python3 "$VERIFY" --report "$REPORT_JSON" --baseline "$BASELINE" --print-baseline-patch \
  >"$VERIFY_LOG1" 2>&1
VERIFY_EXIT1=$?

cat "$VERIFY_LOG1"

if [[ "$VERIFY_EXIT1" -eq 0 ]]; then
  write_summary "MATCH" "$(cat "$VERIFY_LOG1")"
  exit 0
fi

if [[ "$VERIFY_EXIT1" -ne 3 ]]; then
  # Exit 2 (INFRA: missing/truncated/wrong-schema report, or the walk never got past
  # preflight) or exit 1 (a usage/precondition bug in this wrapper's own invocation, which
  # should never happen on a fresh from-scratch attempt 1) -- neither is a mismatch worth
  # retrying.
  write_summary "INFRA" "$(cat "$VERIFY_LOG1")"
  exit 2
fi

echo "adopter-walk-ci: attempt 1 mismatched the baseline -- running attempt 2 to check reproducibility"

mismatched_keys "$REPORT_JSON" >"$WORKDIR/.walk/mismatch_attempt1.tsv"

# Attempt 2 must be another FROM-SCRATCH walk, not a resumed one. Resuming would fill the
# report with "skipped (already done)" rows, which adopter_walk_verify.py refuses outright
# (its partial-run precondition) and whose mismatch set could never be compared like-for-like
# against attempt 1's -- so every retry would degrade to UNSTABLE and the reproducible-regression
# branch below would be unreachable. Archive the evidence tree rather than deleting it (D-20),
# and reset the walk database, which otherwise carries attempt 1's rows into attempt 2 and
# manufactures failures of its own (a duplicate client_id, an already-seeded user).
echo "adopter-walk-ci: attempt 2 (from scratch -- prior evidence archived, walk database reset)"
mv "$WORKDIR" "${WORKDIR}.attempt1.$(date -u +%Y%m%dT%H%M%SZ)"
mkdir -p "$WORKDIR/.walk"

if command -v dropdb >/dev/null 2>&1; then
  PGPASSWORD="${LOCKSPIRE_WALK_DB_PASSWORD:-}" dropdb \
    --if-exists \
    --host "${LOCKSPIRE_WALK_DB_HOST:-127.0.0.1}" \
    --port "${LOCKSPIRE_WALK_DB_PORT:-5432}" \
    --username "${LOCKSPIRE_WALK_DB_USER:-$(whoami)}" \
    "${LOCKSPIRE_WALK_DB_NAME:-lockspire_adopter_walk_dev}" 2>/dev/null || true
fi

run_walk

mismatched_keys "$REPORT_JSON" >"$WORKDIR/.walk/mismatch_attempt2.tsv"

if diff -q "$WORKDIR/.walk/mismatch_attempt1.tsv" "$WORKDIR/.walk/mismatch_attempt2.tsv" >/dev/null 2>&1; then
  echo "adopter-walk-ci: attempt 2 reproduced the same mismatch set -- reproducible regression"
  write_summary "REGRESSION" "$(cat "$VERIFY_LOG1")"
  exit 3
fi

echo "adopter-walk-ci: attempt 2 produced a different mismatch set than attempt 1 -- UNSTABLE, flagged INFRA rather than REGRESSION"
write_summary "UNSTABLE (INFRA)" "$(
  printf 'Attempt 1 mismatches:\n%s\n\nAttempt 2 mismatches:\n%s\n' \
    "$(cat "$WORKDIR/.walk/mismatch_attempt1.tsv")" \
    "$(cat "$WORKDIR/.walk/mismatch_attempt2.tsv")"
)"
exit 2
