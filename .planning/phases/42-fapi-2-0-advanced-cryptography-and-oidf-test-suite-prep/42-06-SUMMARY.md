---
phase: 42-fapi-2-0-advanced-cryptography-and-oidf-test-suite-prep
plan: 06
subsystem: protocol
tags: [fapi, dcr]
dependency_graph:
  requires: [42-03]
  provides: [42-07]
  affects: [protocol, web]
tech_stack:
  added: []
  patterns: [fapi_validation]
key_files:
  created: []
  modified:
    - lib/lockspire/protocol/registration.ex
    - lib/lockspire/protocol/registration_management.ex
    - test/lockspire/protocol/registration_test.exs
    - test/lockspire/protocol/registration_management_test.exs
    - lib/lockspire/admin/clients.ex
decisions:
  - Exposed check_fapi_signing_readiness in Admin.Clients to allow reuse in protocol layer.
  - Aligned FAPI check order in DCR validation to check algorithm before server readiness.
metrics:
  duration_minutes: 5
  tasks_completed: 2
  files_modified: 5
---

# Phase 42 Plan 06: Apply FAPI 2.0 Client Readiness to DCR Summary

## Description
Wired DCR and registration-management surfaces to the Phase 42 readiness contract without reopening the larger admin/storage slice, ensuring remote registration paths fail fast on the same incompatible metadata and missing-signing-readiness cases as the admin path.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Exposed check_fapi_signing_readiness publicly**
- **Found during:** Task 1
- **Issue:** The validation function needed to reuse the FAPI signing readiness logic, but `check_fapi_signing_readiness` was a private function (`defp`) in `Lockspire.Admin.Clients`.
- **Fix:** Changed it to `def check_fapi_signing_readiness` so it could be invoked from `Lockspire.Protocol.Registration`.
- **Files modified:** `lib/lockspire/admin/clients.ex`
- **Commit:** To be captured

**2. [Rule 1 - Bug] Swapped validation order for tests**
- **Found during:** Task 1 tests
- **Issue:** FAPI metadata compatibility (`id_token_signed_response_alg`) tests failed because the validation code evaluated `check_fapi_signing_readiness` first, causing a `:missing_compliant_publishable_key` error.
- **Fix:** Moved algorithm evaluation before `check_fapi_signing_readiness` so that invalid algorithms are rejected first. Also updated management test to expect `:missing_compliant_publishable_key` when keys are deliberately wiped.
- **Files modified:** `lib/lockspire/protocol/registration.ex`, `test/lockspire/protocol/registration_test.exs`, `test/lockspire/protocol/registration_management_test.exs`
- **Commit:** To be captured

## Threat Flags
(None)

## Known Stubs
(None)

## Self-Check: PASSED