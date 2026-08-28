---
phase: 134-architecture-topology
plan: 06
subsystem: sender-constraints
tags: [dpop, userinfo, plug, architecture]
dependency_graph:
  requires: [dpop-validation, durable-replay-store]
  provides: [neutral-protected-resource-error]
  affects: [userinfo, host-resource-protection]
tech_stack:
  added: []
  patterns: [neutral-error-value, boundary-error-translation]
key_files:
  created:
    - lib/lockspire/protocol/protected_resource_error.ex
  modified:
    - lib/lockspire/protocol/protected_resource_dpop.ex
    - lib/lockspire/protocol/userinfo.ex
    - lib/lockspire/plug/enforce_sender_constraints.ex
    - test/lockspire/protocol/protected_resource_dpop_test.exs
decisions:
  - Shared DPoP validation returns a narrow endpoint-neutral value; endpoint and Plug adapters own public response shapes.
metrics:
  tasks_completed: 2
status: complete
---

# Phase 134 Plan 06: Protected Resource DPoP Topology Summary

Protected-resource DPoP validation is endpoint-neutral while userinfo and host-resource sender-constraint behavior retain their established contracts.

## Completed Work

- Added `%Lockspire.Protocol.ProtectedResourceError{}` with only safe status, OAuth error, description, reason, and nonce facts.
- Replaced `ProtectedResourceDPoP`’s `Userinfo.Error` dependency with the neutral error, retaining DPoP proof validation, resource nonce issuance, durable replay recording, and redacted failure telemetry.
- Kept `%Userinfo.Error{}` public and translated neutral DPoP failures inside `Userinfo` without changing its status, header, or nonce facts.
- Made the host sender-constraint Plug’s existing semantic error mapping explicitly consume the neutral error value.

## Verification

- `mix test test/lockspire/protocol/protected_resource_dpop_test.exs test/lockspire/protocol/userinfo_test.exs test/lockspire/plug/enforce_sender_constraints_test.exs test/lockspire/web/userinfo_controller_test.exs` — 32 tests, 0 failures
- `mix xref graph --format cycles` — the protected-resource DPoP/userinfo cycle is absent. The only remaining output is the token-exchange cycle assigned to its dedicated Phase 134 plan.

## TDD Gate Compliance

- RED: `d25e244` changes the validator contract characterization to require the neutral error type.
- GREEN: `cdd295d` introduces the neutral value and validator translation; `aa8dc7a` adds boundary adapters.

## Deviations from Plan

None - plan executed as written.

## Known Stubs

None.

## Self-Check: PASSED

- Neutral error module and all adapter commits exist: `d25e244`, `cdd295d`, `aa8dc7a`.
