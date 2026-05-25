---
status: complete
mode: shift-left
phase: 90-support-truth-and-milestone-closure
source:
  - .planning/phases/90-01-SUMMARY.md
  - .planning/phases/90-02-SUMMARY.md
  - .planning/phases/90-03-SUMMARY.md
started: 2026-05-25T06:00:00Z
updated: 2026-05-25T06:00:00Z
human_steps_required: 0
automation_deferred: []
---

## Current Test
[testing complete]

## Automation Map

- `mix docs.verify`
- `mix test test/lockspire/release_readiness_contract_test.exs`
- `mix test test/lockspire/protocol/direct_client_auth_client_secret_jwt_test.exs test/lockspire/protocol/discovery_test.exs test/lockspire/web/discovery_controller_test.exs`
- `mix test`

## Tests

### 1. Canonical support docs stay narrow and truthful
expected: The public support contract, dedicated `client_secret_jwt` guide, onboarding, DCR, and maintainer wording all describe one narrow direct-client slice with `HS256`, issuer-string `aud`, required `jti`, `POST /par` exclusion, and no broader FAPI or mTLS claim.
result: pass
evidence:
  - `mix docs.verify`
  - `docs/supported-surface.md`
  - `docs/client-secret-jwt-host-guide.md`
  - `docs/install-and-onboard.md`
  - `docs/dynamic-registration.md`
  - `docs/maintainer-release.md`

### 2. Release-contract proof pins the support-truth semantics without becoming a second support matrix
expected: Repo-native release-readiness tests fail if the canonical docs or maintainer docs drift away from the narrow `client_secret_jwt` support contract, while still deferring public truth to `docs/supported-surface.md`.
result: pass
evidence:
  - `mix test test/lockspire/release_readiness_contract_test.exs`
  - `test/support/client_secret_jwt_support_truth.ex`
  - `test/lockspire/release_readiness_contract_test.exs`

### 3. Runtime and discovery proof stay aligned with the documented direct-client slice
expected: Representative runtime tests and both discovery proof surfaces keep `client_secret_jwt` limited to the shared direct-client endpoints, keep `POST /par` excluded, and suppress the symmetric slice under FAPI posture.
result: pass
evidence:
  - `mix test test/lockspire/protocol/direct_client_auth_client_secret_jwt_test.exs test/lockspire/protocol/discovery_test.exs test/lockspire/web/discovery_controller_test.exs`
  - `test/lockspire/protocol/direct_client_auth_client_secret_jwt_test.exs`
  - `test/lockspire/protocol/discovery_test.exs`
  - `test/lockspire/web/discovery_controller_test.exs`

### 4. Full regression suite stays green with phase 90 integrated
expected: The complete Lockspire test suite passes with the documentation-truth, release-contract, and support-proof changes present.
result: pass
evidence:
  - `mix test`

## Summary

total: 4
passed: 4
issues: 0
pending: 0
skipped: 0
blocked: 0

## Gaps

None.
