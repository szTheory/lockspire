#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PLAN_PATH="${ROOT_DIR}/scripts/conformance/fapi2-plan.json"
ARTIFACT_DIR="${LOCKSPIRE_FAPI2_ARTIFACT_DIR:-${ROOT_DIR}/.artifacts/conformance/fapi2}"
SKIP_SUITE="${LOCKSPIRE_FAPI2_SKIP_SUITE:-false}"

exec "${ROOT_DIR}/scripts/conformance/run_oidf_profile.sh" \
  --profile fapi2 \
  --plan "$PLAN_PATH" \
  --artifact-dir "$ARTIFACT_DIR" \
  --skip-suite "$SKIP_SUITE"
