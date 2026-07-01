---
phase: 89
plan: 2
subsystem: discovery
tags: [oauth, oidc, discovery, metadata, client-secret-jwt]
requires:
  - phase: 89-01
    provides: durable JWT auth-method plus signing-alg client truth
provides:
  - Route-truthful discovery publication for `client_secret_jwt`
  - Endpoint-local mixed JWT signing-alg unions with `HS256` kept symmetric-only
  - FAPI-sensitive discovery suppression for the symmetric JWT slice
affects: [89-03, support-truth, docs]
tech-stack:
  added: []
  patterns: [endpoint-local JWT alg union, publish only mounted and verifier-backed methods]
key-files:
  created: []
  modified:
    - lib/lockspire/protocol/client_auth.ex
    - lib/lockspire/protocol/discovery.ex
    - test/lockspire/protocol/discovery_test.exs
    - test/lockspire/web/discovery_controller_test.exs
key-decisions:
  - "Discovery now publishes `client_secret_jwt` on token and revocation only, while introspection remains asymmetric-only."
  - "`HS256` is published only when `client_secret_jwt` is actually advertised on that endpoint."
patterns-established:
  - "Discovery method lists and signing-alg lists are now composed from endpoint-local runtime truth instead of one issuer-wide JWT story."
requirements-completed: [META-01]
duration: 20min
completed: 2026-05-25
---

# Phase 89 Plan 2 Summary

**OIDC discovery now tells the truthful mixed-JWT story: `client_secret_jwt` appears only on the shared verifier endpoints, `HS256` is symmetric-only, and FAPI posture suppresses the entire slice**

## Performance

- **Duration:** 20 min
- **Tasks:** 3
- **Files modified:** 4

## Accomplishments

- Promoted `client_secret_jwt` into the published token/revocation auth-method contract while keeping introspection limited to the methods it actually accepts.
- Replaced the asymmetric-only signing-alg publication path with endpoint-local unions that add `HS256` only for `client_secret_jwt` and retain the current asymmetric allowlist for `private_key_jwt`.
- Added unit and HTTP proof that FAPI-effective posture removes both `client_secret_jwt` and `HS256` from discovery.

## Task Commits

1. **Task 89-02-01: publish client_secret_jwt only on shared-verifier endpoints** - working tree
2. **Task 89-02-02: publish truthful mixed JWT signing-alg unions** - working tree
3. **Task 89-02-03: preserve FAPI-sensitive publication posture** - working tree

## Verification

- `mix test test/lockspire/protocol/discovery_test.exs test/lockspire/web/discovery_controller_test.exs`

## Next Phase Readiness

- Admin and operator surfaces can now describe the same route-truthful `client_secret_jwt` posture that discovery publishes.

---
*Phase: 89*
*Completed: 2026-05-25*
