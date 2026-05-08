---
phase: 72
plan: 03
title: Publish truthful shared JARM discovery capabilities
status: complete
commits:
  - adb1d58
  - 2fb620f
  - 1ac8fb8
key_files:
  - lib/lockspire/protocol/discovery.ex
  - lib/lockspire/protocol/discovery/authorization_response_capabilities.ex
  - test/lockspire/protocol/discovery_test.exs
  - test/lockspire/web/discovery_controller_test.exs
---

# Phase 72 Plan 03 Summary

Published JARM signing and encryption discovery metadata from one shared authorization-response capability helper so discovery only advertises the mounted, issuer-truthful surface.

## Delivered

- Added `Lockspire.Protocol.Discovery.AuthorizationResponseCapabilities` as the single helper for:
  - `response_modes_supported`
  - `authorization_signing_alg_values_supported`
  - `authorization_encryption_alg_values_supported`
  - `authorization_encryption_enc_values_supported`
- Rewired `Lockspire.Protocol.Discovery.openid_configuration/0` to merge authorization-response metadata from the shared helper instead of hard-coding `.jwt` modes and signing metadata separately.
- Made JARM discovery truth depend on the mounted authorization surface:
  - mounted `authorization_endpoint` publishes `.jwt` response modes plus signing and encryption metadata
  - unmounted authorization surface falls back to base response modes only and omits all JARM signing/encryption keys
- Kept the published encryption surface intentionally narrow and stable:
  - `alg`: `RSA-OAEP-256`, `ECDH-ES`
  - `enc`: `A256GCM`, `A128GCM`
- Kept signing metadata coupled to the effective issuer security profile:
  - default posture publishes `RS256`, `ES256`, `PS256`, `EdDSA`
  - `:fapi_2_0_security` publishes `ES256`, `PS256`
- Expanded protocol and controller tests to prove:
  - helper and HTTP discovery stay aligned
  - mounted vs unmounted authorization surfaces publish different truthful contracts
  - FAPI signing posture narrows published signing algorithms without changing the encryption allow-list
  - transient client registrations do not influence published JARM metadata

## TDD Notes

- RED commit: `adb1d58` added failing focused discovery tests for the missing shared helper and mounted-surface gating.
- GREEN commit: `2fb620f` implemented the shared helper and rewired discovery to use it.
- Follow-up test commit: `1ac8fb8` tightened the unmounted helper-to-config protocol contract.

## Deviations from Plan

None - plan executed within the intended scope.

## Verification

Exact commands run:

```bash
MIX_ENV=test mix test --warnings-as-errors test/lockspire/protocol/discovery_test.exs test/lockspire/web/discovery_controller_test.exs
MIX_ENV=test mix test --warnings-as-errors test/lockspire/protocol/discovery_test.exs test/lockspire/web/discovery_controller_test.exs
MIX_ENV=test mix test --warnings-as-errors test/lockspire/protocol/discovery_test.exs test/lockspire/web/discovery_controller_test.exs
```

Results:

- RED run before implementation: failed as expected because `Lockspire.Protocol.Discovery.AuthorizationResponseCapabilities` did not exist yet, encryption metadata was not published, and unmounted discovery still advertised `.jwt` modes.
- GREEN run after implementation: `36 tests, 0 failures`
- Final focused rerun after the Task 2 assertion expansion: `38 tests, 0 failures`

## Self-Check

PASSED

- Summary file exists.
- Plan commits exist: `adb1d58`, `2fb620f`, `1ac8fb8`.
- Requested state files were left untouched by this plan execution.
