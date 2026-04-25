---
phase: 22-request-object-integration
plan: "04"
subsystem: protocol
tags: [jar, oauth, authorization, request-object, protocol-seam]
one_liner: "Request-object orchestration for /authorize with JAR claim projection and seam-pinned reason codes"

dependency_graph:
  requires:
    - "22-01"
    - "22-02"
    - "22-03"
  provides:
    - "Lockspire.Protocol.RequestObject"
    - "Request-object splice inside AuthorizationRequest.validate/1"
  affects:
    - "lib/lockspire/protocol/authorization_request.ex"
    - "test/lockspire/protocol/authorization_request_test.exs"

tech_stack:
  added:
    - "Elixir protocol orchestrator for RFC 9101 request objects"
  patterns:
    - "with-chain orchestrator that composes decode, signature verification, claim validation, and param projection"
    - "Sealed-envelope conflict checks before validation pipeline reuse"
    - "Protocol-seam reason-code pinning for browser-safe errors"

key_files:
  created:
    - "lib/lockspire/protocol/request_object.ex"
  modified:
    - "lib/lockspire/protocol/authorization_request.ex"
    - "test/lockspire/protocol/authorization_request_test.exs"

decisions:
  - "Consume signed request objects before validate_with_client/3 so the existing authorize pipeline stays unchanged after projection."
  - "Treat request + request_uri as a sealed-envelope conflict and map it to :request_object_and_request_uri_conflict."
  - "Pin all D-14 request-object reason codes at the authorization_request test seam rather than only unit-testing RequestObject internals."

metrics:
  duration_minutes: 10
  tasks_completed: 1
  files_created: 1
  files_modified: 2
  completed_at: "2026-04-25T17:05:00Z"
---

# Phase 22 Plan 04: Request Object Orchestration Summary

Request-object orchestration for `/authorize` with JAR claim projection and protocol-seam reason-code coverage.

## What Was Built

- Added `Lockspire.Protocol.RequestObject` to decode, verify, validate, and project signed request objects.
- Spliced request-object consumption into `AuthorizationRequest.validate/1` before client validation continues.
- Extended the authorization request tests with the happy path plus all sealed-envelope and D-14 reason-code cases.

## Deviations from Plan

None.

## Verification Results

- `mix test test/lockspire/protocol/authorization_request_test.exs` — 38 tests, 0 failures.
- `mix test` — 199 tests, 1 failure.

## Deferred Issues

- `Lockspire.ReleaseReadinessContractTest` still expects older `.planning/PROJECT.md` wording (`Current Milestone: v1.3 PAR Policy Controls`).
- This is unrelated to Phase 22-04 and was logged in `.planning/phases/22-request-object-integration/deferred-items.md`.

## Threat Flags

None.

## Self-Check: PASSED

- [x] `.planning/phases/22-request-object-integration/22-04-SUMMARY.md` exists
- [x] Commit `036dcfc` exists in git log
- [x] `lib/lockspire/protocol/request_object.ex` exists
- [x] `lib/lockspire/protocol/authorization_request.ex` updated
- [x] `test/lockspire/protocol/authorization_request_test.exs` updated
