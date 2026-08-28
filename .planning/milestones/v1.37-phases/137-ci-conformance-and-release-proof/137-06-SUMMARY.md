---
phase: 137-ci-conformance-and-release-proof
plan: "06"
subsystem: conformance-evidence
tags: [oidf, fapi, redaction, artifacts]
requires:
  - phase: 137-ci-conformance-and-release-proof
    provides: immutable OIDF input preparation
provides:
  - shared immutable profile runner for OIDC and FAPI plans
  - allowlisted, schema-bounded receipts for successful, failed, and integration-only runs
affects: [137-07]
tech-stack:
  added: []
  patterns: [ephemeral raw work, retained allowlisted receipt]
key-files:
  created:
    - scripts/conformance/build_redacted_evidence.py
    - scripts/conformance/run_oidf_profile.sh
    - test/lockspire/conformance_redacted_evidence_contract_test.exs
  modified:
    - scripts/conformance/run_phase37_suite.sh
    - scripts/conformance/run_fapi2_suite.sh
key-decisions:
  - "Skip mode is explicitly integration-only and retains only a receipt; it does not claim external-suite execution."
  - "Raw compose and suite output remain in an ephemeral work directory and are never recursively copied."
metrics:
  completed: 2026-08-27
status: complete
---

# Phase 137 Plan 06: Redacted Conformance Evidence Summary

**Both repository-native conformance profiles now share immutable preparation and retain a single allowlisted receipt rather than raw suite material.**

## Accomplishments

- Replaced duplicated mutable download/bootstrap paths in the Phase 37 and FAPI runners with one `run_oidf_profile.sh` entrypoint.
- The shared runner invokes Plan 05 preparation for external-suite execution and keeps all downloaded and compose material in an ephemeral private directory.
- Added `build_redacted_evidence.py`, which writes one schema-versioned receipt containing immutable input identities, plan checksum/name, bounded result names, runtime version, timestamps, and status classification.
- Explicit skip mode emits `integration_only` evidence for each profile without pretending that the Docker suite ran.
- Added cross-runner contracts that reject mutable references, source fallback, raw configuration/log paths, recursive artifact copies, and profile drift.

## Task Commits

1. **Task 1: Run one OIDC path through immutable bootstrap to safe receipt** — `fefebdf3` (RED), `c4a2e49d` (GREEN)
2. **Task 2: Put FAPI evidence on the identical immutable/redacted path** — `e33190d7`

## Verification

- `MIX_ENV=test mix test test/lockspire/conformance_redacted_evidence_contract_test.exs test/mix/tasks/lockspire/oidf_conformance_test.exs` — 10 tests, 0 failures.
- `bash -n scripts/conformance/run_phase37_suite.sh scripts/conformance/run_fapi2_suite.sh scripts/conformance/run_oidf_profile.sh` — passed.
- Safe Phase 37 and FAPI skip-mode runs each retained exactly one `receipt.json`, both classified `integration_only`.
- Docker suite execution was intentionally not run in this environment.

## Deviations from Plan

None - plan executed as specified.

## Known Stubs

None.

## Self-Check: PASSED

- Both wrappers, the shared runner, evidence builder, and contract exist.
- Commits `fefebdf3`, `c4a2e49d`, and `e33190d7` are present in git history.
