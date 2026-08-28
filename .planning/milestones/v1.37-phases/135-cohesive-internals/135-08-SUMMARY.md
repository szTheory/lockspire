---
phase: 135-cohesive-internals
plan: 08
subsystem: token-exchange
tags: [oauth, oidc, token-issuance, persistence, observability]
status: complete
requires: [135-07]
provides:
  - Explicit mutation-free token issuance boundary
  - Atomic audited persistence boundary for refresh rotation
  - Explicit dependency-backed refresh telemetry boundary
affects: [135-09]
key-files:
  created:
    - lib/lockspire/protocol/token_exchange/internal/token_issuer.ex
    - lib/lockspire/protocol/token_exchange/internal/grant_persistence.ex
    - lib/lockspire/protocol/token_exchange/internal/grant_observability.ex
  modified:
    - lib/lockspire/protocol/token_exchange/internal/access_token_signer.ex
    - lib/lockspire/protocol/token_exchange/internal/grant_support.ex
    - lib/lockspire/protocol/token_exchange/internal/refresh_exchange.ex
    - lib/lockspire/protocol/token_exchange/internal/rfc8693_exchange.ex
decisions:
  - Access-token signing resolves only typed Dependencies after the legacy facade has adapted a request.
  - Refresh rotation owns one transaction/audit boundary and emits through the injected telemetry dependency.
metrics:
  completed: 2026-08-27
status: complete
---

# Phase 135 Plan 08: Focused Token Issuance, Persistence, and Observability Summary

Token signing, refresh persistence, and refresh observability have focused dependency-explicit owners without changing the public result facade or five-flow characterization surface.

## Completed Tasks

1. Added `TokenIssuer` and changed the internal signer core to use explicit typed dependencies rather than attached request data.
2. Added `GrantPersistence` and `GrantObservability`; refresh-family rotation now retains one audited transaction and sends only safe existing metadata through the injected telemetry module.
3. Routed GrantSupport compatibility issuance, refresh issuance, and RFC 8693 custom-claim signing through `TokenIssuer`, retaining all prior helper/facade entry points.

## Verification

- Issuance/signing focused suite: 26 tests, 0 failures.
- Persistence/observability, repository-atomicity, and refresh suite: 22 tests, 0 failures.
- Five-flow characterization plus new owner tests: 7 tests, 0 failures.
- Full per-grant suite: 64 tests, 0 failures.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Preserved polling failure tuples through the existing GrantSupport compatibility boundary.**
- **Found during:** Task 3.
- **Issue:** Calling `GrantPolling` directly skipped the compatibility boundary that appends the existing failure audit event and translates its extended error tuple.
- **Fix:** Retained the GrantSupport polling delegate; the new focused issuance/persistence owners are used without changing device/CIBA failure behavior.
- **Files modified:** `lib/lockspire/protocol/token_exchange/internal/device_code_grant.ex`, `lib/lockspire/protocol/token_exchange/internal/ciba_grant.ex` (no retained diff).

**2. [Rule 1 - Protocol error precedence] Deferred authorization-code mutation capability validation until after PKCE and binding validation.**
- **Found during:** Task 3 five-flow verification.
- **Issue:** eager validation of mutation-only capabilities caused an unsupported PKCE method to return `:dependency_capability_unavailable` before the established `:unsupported_code_challenge_method` response.
- **Fix:** retain initial read capabilities at request entry and verify redemption/transaction/audit capabilities immediately before durable redemption.
- **Files modified:** `lib/lockspire/protocol/token_exchange/internal/dependencies.ex`, `lib/lockspire/protocol/token_exchange/internal/grant_support.ex`.
- **Commit:** `d97f857e`.

### Deferred Issues

- `mix compile --warnings-as-errors` is blocked by unused private functions in concurrent storage extraction files outside this plan's ownership.

## Self-Check: PASSED

- Task commits `1bcf9b4a`, `d8071fe5`, and `21dee5a2` exist.
- All three focused collaborator modules and their tests exist.
