---
phase: 134-architecture-topology
plan: 05
subsystem: authorization-request-topology
tags: [oauth, oidc, jar, par, xref]
requires: []
provides:
  - Neutral request-object result values
  - Boundary-owned authorization and PAR JAR error translation
affects: [authorization, pushed-authorization-request, architecture-fitness]
tech-stack:
  added: []
  patterns: [neutral result seam, boundary error adaptation]
key-files:
  created:
    - lib/lockspire/protocol/request_object/result.ex
  modified:
    - lib/lockspire/protocol/request_object.ex
    - lib/lockspire/protocol/authorization_request.ex
    - lib/lockspire/protocol/pushed_authorization_request.ex
    - test/lockspire/protocol/request_object_test.exs
decisions:
  - RequestObject owns only neutral browser/redirect-safe facts; authorization and PAR retain their public error contracts at their own boundaries.
metrics:
  duration: 5m
  completed: 2026-08-27
status: complete
---

# Phase 134 Plan 05: Neutral JAR Result Seam Summary

JAR consumption now produces a narrow neutral result value, while `/authorize` and `/par` independently translate it into their retained public contracts; the authorization-request/request-object xref cycle is removed.

## Completed Work

- Added `Lockspire.Protocol.RequestObject.Result`, retaining only disposition and safe error, reason, state, and redirect fields.
- Removed the RequestObject alias and struct dependency on `AuthorizationRequest.Error` without changing JAR crypto, validation, key lookup, or projected successful parameters.
- Added authorization-boundary translation back into the existing `%AuthorizationRequest.Error{}` struct.
- Added PAR-boundary translation into its existing 400 JSON-safe error struct.
- Characterized neutral missing-request output in addition to the existing JAR success, conflict, decryption/signature, claims, safe redirect, and PAR coverage.

## Verification

- `mix test test/lockspire/protocol/request_object_test.exs test/lockspire/protocol/authorization_request_test.exs test/lockspire/protocol/pushed_authorization_request_test.exs` — 65 tests, 0 failures.
- `mix xref graph --format cycles` — the authorization-request/request-object cycle is absent; only the unrelated token-exchange and protected-resource/userinfo cycles remain.
- Confirmed `lib/lockspire/protocol/request_object.ex` has no `AuthorizationRequest` reference.

## Commits

- `7349a67` — test(134-05): characterize neutral request object errors
- `9bfba74` — feat(134-05): add neutral request object results
- `66d79a9` — feat(134-05): adapt JAR results at protocol boundaries
- `8b0d54d` — style(134-05): format request object characterization

## Deviations from Plan

None — the existing public-boundary JAR table already covered success, conflicts, cryptographic failures, claims, safe redirect, and PAR wrapping; the added direct characterization pins the new neutral result shape.

No new endpoints, persistence, or trust boundaries were introduced. Invalid request-object outcomes remain browser-safe and PAR responses continue to expose only the established OAuth error fields.

## Self-Check: PASSED

- Neutral result module exists.
- All four Plan 05 commits are present in git history.
