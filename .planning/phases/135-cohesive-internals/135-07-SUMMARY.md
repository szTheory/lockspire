---
phase: 135-cohesive-internals
plan: 07
subsystem: token-exchange
tags: [oauth, oidc, client-authentication, dpop, resource-selection, device-flow, ciba]
status: complete
requires: [135-06]
provides:
  - Explicit client-authentication coordination using typed token dependencies
  - Pure grant audience narrowing with retained public compatibility helper
  - Separate device and CIBA polling translators with explicit stores and clock
affects: [135-08, 135-09]
key-files:
  created:
    - lib/lockspire/protocol/token_exchange/internal/client_authentication.ex
    - lib/lockspire/protocol/token_exchange/internal/resource_selection.ex
    - lib/lockspire/protocol/token_exchange/internal/grant_polling.ex
  modified:
    - lib/lockspire/protocol/token_exchange/internal/grant_support.ex
    - lib/lockspire/protocol/token_exchange/internal/token_endpoint_dpop.ex
decisions:
  - ClientAuth and DPoP receive typed dependency fields rather than request option bags.
  - GrantSupport retains issuance, audit, and public compatibility ownership while focused collaborators own validation and state translation.
metrics:
  completed: 2026-08-27
---

# Phase 135 Plan 07: Focused Token Validation Collaborators Summary

Client authentication, resource narrowing, and device/CIBA polling now have focused internal owners with the stable token facade and grant ordering intact.

## Completed Tasks

1. Added `ClientAuthentication`, threading the existing method matrix through explicit client-store dependencies; token endpoint DPoP now consumes typed policy, replay, clock, and security fields.
2. Added pure `ResourceSelection`, preserving authorization-code selection plus the retained `GrantSupport.validate_grant_resources_for_test/2` compatibility boundary.
3. Added `GrantPolling` with separate device and CIBA entrypoints that consume only their aggregate store and clock while GrantSupport retains audit handling.

## Verification

- `mix compile --warnings-as-errors` — passed.
- Client-authentication focused suite — 32 tests, 0 failures.
- Resource-selection focused suite — 16 tests, 0 failures.
- Polling focused suite — 15 tests, 0 failures.
- Final collaborator/characterization suite — 8 tests, 0 failures.
- `mix xref graph --format cycles` — no cycles found.

## TDD Gate Compliance

- RED characterization commits: `a9fd52a`, `eb1848d`, `badf544a`.
- GREEN/refactor commits: `f3ab3ed`, `95cbb48`, `7c2f7195`.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking compile issue] Waited for the concurrent storage extraction to repair a temporary `InteractionRecord` compile failure before running the Task 1 suite.**
- **Found during:** Task 1 verification.
- **Resolution:** The storage-plan owner repaired the unrelated repository helper; Plan 07 did not modify storage files.

## Self-Check: PASSED

- All three collaborator modules and focused test files exist.
- Task commits `a9fd52a`, `f3ab3ed`, `eb1848d`, `95cbb48`, `badf544a`, and `7c2f7195` exist in repository history.
