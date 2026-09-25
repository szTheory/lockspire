#!/usr/bin/env bash
set -euo pipefail

[[ "$#" -eq 2 && ( "$1" == pre-verify || "$1" == post-transition ) &&
   "$2" =~ ^(0|[1-9][0-9]*)$ ]] || {
  printf '%s\n' 'lockspire phase finalizer gate: expected MODE NUMERIC_PHASE' >&2
  exit 64
}

MODE="$1"
PHASE="$2"
ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || {
  printf '%s\n' 'lockspire phase finalizer gate: repository unavailable' >&2
  exit 1
}
[[ "$(pwd -P)" == "$(cd "$ROOT" && pwd -P)" ]] || {
  printf '%s\n' 'lockspire phase finalizer gate: command must run from the repository root' >&2
  exit 1
}

for candidate in \
  "${GSD_TOOLS:-}" \
  "$ROOT/gsd-core/bin/gsd-tools.cjs" \
  "$ROOT/.codex/gsd-core/bin/gsd-tools.cjs" \
  "$ROOT/.claude/gsd-core/bin/gsd-tools.cjs" \
  "$ROOT/tools/gsd-capabilities/lockspire-phase-finalizer/fixtures/gsd-core/bin/gsd-tools.cjs" \
  "$HOME/.codex/gsd-core/bin/gsd-tools.cjs" \
  "$HOME/.claude/gsd-core/bin/gsd-tools.cjs" \
  "$HOME/.hermes/gsd-core/bin/gsd-tools.cjs" \
  "$HOME/.cursor/gsd-core/bin/gsd-tools.cjs" \
  "$HOME/.gemini/gsd-core/bin/gsd-tools.cjs" \
  "$HOME/.copilot/gsd-core/bin/gsd-tools.cjs" \
  "$HOME/.agents/gsd-core/bin/gsd-tools.cjs"; do
  if [[ -n "$candidate" && -f "$candidate" && ! -L "$candidate" ]]; then
    exec node "$candidate" lockspire-finalize "$MODE" --phase "$PHASE" --raw
  fi
done

printf '%s\n' 'lockspire phase finalizer gate: GSD runtime tools unavailable' >&2
exit 1
