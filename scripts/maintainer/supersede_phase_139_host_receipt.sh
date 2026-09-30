#!/usr/bin/env bash
set -euo pipefail

usage() {
  printf '%s\n' 'Usage: supersede_phase_139_host_receipt.sh --expected-sha256 <pending-receipt-sha256>' >&2
  exit 64
}

[[ "$#" -eq 2 && "$1" == "--expected-sha256" && "$2" =~ ^[0-9a-f]{64}$ ]] || usage

ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || {
  printf '%s\n' 'phase 139 receipt supersession: not inside a Git repository' >&2
  exit 1
}
[[ "$(pwd -P)" == "$(cd "$ROOT" && pwd -P)" ]] || {
  printf '%s\n' 'phase 139 receipt supersession: command must run from the repository root' >&2
  exit 1
}

STATE_HELPER="$ROOT/tools/gsd-capabilities/lockspire-phase-finalizer/post-completion-finalizer-state.cjs"
[[ -f "$STATE_HELPER" && ! -L "$STATE_HELPER" ]] || {
  printf '%s\n' 'phase 139 receipt supersession: state helper is unavailable' >&2
  exit 1
}

resolve_gsd_tools() {
  local candidate
  for candidate in \
    "${GSD_TOOLS:-}" \
    "$ROOT/gsd-core/bin/gsd-tools.cjs" \
    "$ROOT/.codex/gsd-core/bin/gsd-tools.cjs" \
    "$ROOT/.claude/gsd-core/bin/gsd-tools.cjs" \
    "$HOME/.codex/gsd-core/bin/gsd-tools.cjs" \
    "$HOME/.claude/gsd-core/bin/gsd-tools.cjs" \
    "$HOME/.hermes/gsd-core/bin/gsd-tools.cjs" \
    "$HOME/.cursor/gsd-core/bin/gsd-tools.cjs" \
    "$HOME/.gemini/gsd-core/bin/gsd-tools.cjs" \
    "$HOME/.copilot/gsd-core/bin/gsd-tools.cjs" \
    "$HOME/.agents/gsd-core/bin/gsd-tools.cjs"; do
    if [[ -n "$candidate" && -f "$candidate" && ! -L "$candidate" ]]; then
      printf '%s' "$candidate"
      return 0
    fi
  done
  return 1
}

GSD_TOOLS_PATH="$(resolve_gsd_tools)" || {
  printf '%s\n' 'phase 139 receipt supersession: GSD runtime tools are unavailable' >&2
  exit 1
}
HOOKS="$(node "$GSD_TOOLS_PATH" loop render-hooks plan:pre --raw)" || {
  printf '%s\n' 'phase 139 receipt supersession: plan-pre lifecycle discovery failed' >&2
  exit 1
}
printf '%s' "$HOOKS" | node "$STATE_HELPER" supersede 139 "$2"
