#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PLAN_PATH="${ROOT_DIR}/scripts/conformance/phase37-plan.json"
ARTIFACT_DIR="${LOCKSPIRE_PHASE37_ARTIFACT_DIR:-${ROOT_DIR}/.artifacts/conformance/phase37}"
SKIP_SUITE="${LOCKSPIRE_PHASE37_SKIP_SUITE:-false}"

exec "${ROOT_DIR}/scripts/conformance/run_oidf_profile.sh" \
  --profile phase37 \
  --plan "$PLAN_PATH" \
  --artifact-dir "$ARTIFACT_DIR" \
  --skip-suite "$SKIP_SUITE"
