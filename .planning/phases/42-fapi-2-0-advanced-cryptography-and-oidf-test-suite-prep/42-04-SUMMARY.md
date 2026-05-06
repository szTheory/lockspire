---
phase: 42-fapi-2-0-advanced-cryptography-and-oidf-test-suite-prep
plan: 04
subsystem: conformance
tags:
  - FAPI-2.0
  - OIDF
  - conformance
  - testing
depends_on: [01, 02, 03]
requires: []
provides:
  - OIDF maintainer conformance lane
affects:
  - docs/maintainer-conformance.md
  - scripts/conformance/fapi2-check.sh
  - .github/workflows/oidf-conformance.yml
  - test/integration/phase41_fapi_2_0_e2e_test.exs
  - test/lockspire/release_readiness_contract_test.exs
tech_stack_added: []
tech_stack_patterns: []
key_files_created:
  - scripts/conformance/fapi2-check.sh
  - test/integration/phase41_fapi_2_0_e2e_test.exs
key_files_modified:
  - docs/maintainer-conformance.md
  - .github/workflows/oidf-conformance.yml
  - test/lockspire/release_readiness_contract_test.exs
key_decisions: []
duration: 0
completed_date: "2026-05-02"
---

# Phase 42 Plan 04: Conformance Prep Summary

Wire the preparatory OIDF/FAPI maintainer lane into the repo with executable docs, CI/artifact truth, and contract tests, without overstating certification or Phase 43 closure.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed failing LiveView tests due to Phase 42-03 FAPI readiness requirement**
- **Found during:** Plan 04 test run
- **Issue:** `Admin.put_security_profile(:fapi_2_0_security)` was failing in 3 LiveView tests because they did not have a valid FAPI-compliant signing key.
- **Fix:** Inserted a valid `ES256` FAPI-compliant key (`Lockspire.Storage.Ecto.Repository.publish_key`) before attempting to enable `fapi_2_0_security` in tests.
- **Files modified:** `test/lockspire/web/live/admin/clients_live/show_test.exs`, `test/lockspire/web/live/admin/policies_live/security_profile_test.exs`
- **Commit:** To be captured.