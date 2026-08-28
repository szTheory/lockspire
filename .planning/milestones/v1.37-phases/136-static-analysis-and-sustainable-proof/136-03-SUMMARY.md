---
phase: 136-static-analysis-and-sustainable-proof
plan: "03"
subsystem: oauth-protocol
tags: [jar, request-object, credo, security]
requires:
  - phase: 136-static-analysis-and-sustainable-proof
    plan: "01"
    provides: classified Credo suppression debt
provides:
  - request-object retrieval and signed-claim helpers behind stable public JAR APIs
  - named, invariant-oriented local Credo exceptions for protocol boundary code
affects: [136-11, 137]
tech-stack:
  added: []
  patterns: [sealed request-object retrieval, signed-claims projection, named Credo exceptions]
key-files:
  created:
    - lib/lockspire/protocol/request_object/retrieval.ex
    - lib/lockspire/protocol/request_object/claims.ex
  modified:
    - lib/lockspire/protocol/jar.ex
    - lib/lockspire/protocol/request_object.ex
    - lib/lockspire/domain/client.ex
    - lib/lockspire/jwks_fetcher.ex
    - lib/lockspire/security/policy.ex
    - lib/lockspire/protocol/authorization_request.ex
    - lib/lockspire/protocol/token_exchange/internal/rfc8693_exchange.ex
    - test/lockspire/protocol/request_object_test.exs
key-decisions:
  - "RequestObject remains the public browser-safe error facade while Retrieval returns neutral sealed-envelope reasons."
  - "Jar keeps its public claim-validation API and delegates pure claim rules to RequestObject.Claims."
  - "Credo exceptions are permitted only with a named check and a nearby protocol invariant."
metrics:
  tasks_completed: 2
  tests_added: 2
status: complete
---

# Phase 136 Plan 03: JAR and Request-Object Readability Summary

**JAR verification keeps its public contract while sealed retrieval and signed claim rules are independently legible to strict Credo.**

## Accomplishments

- Extracted bounded inline request retrieval and request/request_uri conflict precedence into `RequestObject.Retrieval` without changing the public `RequestObject.consume/3` error struct or reason codes.
- Extracted RFC 9101 claim validation and signed authorization-parameter projection into `RequestObject.Claims`; `Jar.validate_claims/2` remains the stable public entry point.
- Removed file-wide JAR and request-object Credo exclusions and replaced all Plan 03 unnamed directives with either ordinary code or named, invariant-oriented exceptions.
- Kept JWKS target failure mapping, issuer-path validation ordering, authorization validation output, and RFC 8693 malformed-JWT denial behavior intact.

## Task Commits

1. **Task 1: Extract one signed request-object path across retrieval, JAR, and claim merging** — `c40ead34` (characterization), `297f7dbe` (implementation)
2. **Task 2: Remove every unnamed library directive** — `6e4f857a`

## Verification

- `mix test test/lockspire/protocol/jar_test.exs test/lockspire/protocol/request_object_test.exs` — 61 tests, 0 failures.
- `bash scripts/ci/run_credo.sh` — 547 sources, 0 issues.
- `mix test test/lockspire/domain/client_test.exs test/lockspire/protocol/authorization_request_test.exs test/lockspire/protocol/rfc8693_exchange_test.exs` — 64 tests, 0 failures.
- `mix compile --warnings-as-errors` — passed.
- `mix xref graph --format cycles` — no cycles found.

## Deviations from Plan

None - plan execution retained the planned public contract and completed all focused checks.

## Known Stubs

None.

## Self-Check: PASSED

- Retrieval and claims modules exist at their planned paths.
- All three task commits are present in git history.
