---
phase: 21
plan: 03
subsystem: protocol
tags: [jar, jwt, claims-validation, rfc-9101, security]
requires: [JAR-02]
provides: [JAR-03]
affects: [lib/lockspire/protocol/jar.ex]
tech-stack:
  added: []
  patterns:
    - Injectable :now via Keyword.get_lazy(opts, :now, &DateTime.utc_now/0) for deterministic time-sensitive tests
    - Claims validation pipelined with `with` for short-circuit error propagation
    - Audience accepted as string or list per RFC 7519 §4.1.3
key-files:
  modified:
    - lib/lockspire/protocol/jar.ex
    - test/lockspire/protocol/jar_test.exs
decisions:
  - Validate iss/aud/exp as RFC 9101 mandatory claims; nbf/iat as optional but checked when present
  - Accept aud as either binary or list of binaries (RFC 7519 §4.1.3 allows both forms)
  - Use injectable :now opt and a :leeway opt (default 0) so callers can tolerate small clock skew without burying that policy inside the protocol module
  - Treat exp boundary as strictly future (exp == now is expired) per "MUST be in the future"; treat nbf and iat boundary as <= now (equal-to-now is allowed) per "MUST be in the past or equal to now"
  - Use specific failure atoms per claim (:missing_issuer, :invalid_issuer, :missing_audience, :invalid_audience, :missing_expiration, :invalid_expiration, :expired_token, :invalid_not_before, :invalid_issued_at, :invalid_claims_options) so callers can map them to OAuth error responses precisely
metrics:
  duration: 3m
  completed_date: 2026-04-25
---

# Phase 21 Plan 03: JAR Security Claims Validation Summary

Implemented `validate_claims/2` in `Lockspire.Protocol.Jar`, enforcing RFC 9101
mandatory claims (`iss`, `aud`, `exp`) and optional time claims (`nbf`, `iat`)
on decoded request objects. Mitigates T-21-05 (Repudiation) and T-21-06
(Information Disclosure).

## One-liner
RFC 9101 security claims validation for JAR request objects with injectable clock and clock-skew leeway.

## Key Changes

- Added `Lockspire.Protocol.Jar.validate_claims/2` accepting a `%Jar{}` and a keyword opts list.
- Required opts: `:expected_client_id` (binary, non-empty) and `:expected_audience` (binary, non-empty).
- Optional opts: `:now` (DateTime, defaults to `DateTime.utc_now/0`) and `:leeway` (non-negative integer seconds, defaults to `0`).
- `iss` must be a binary equal to `expected_client_id`.
- `aud` may be a binary or a list of binaries; the expected audience must be present.
- `exp` must be an integer strictly greater than `now` (with leeway tolerance).
- `nbf` and `iat`, when present, must be integers `<= now` (with leeway tolerance). Absent values are allowed.
- All failure modes return specific atoms (e.g. `:invalid_issuer`, `:expired_token`, `:invalid_not_before`) so the caller can map them to OAuth error responses precisely.
- Added 28 unit tests in `describe "validate_claims/2"`, raising the file from 13 to 41 tests.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Critical functionality] Added clock-skew tolerance (`:leeway` opt)**
- **Found during:** Task 1 implementation
- **Issue:** The plan literal text says exp "MUST be in the future" / nbf, iat "MUST be in the past". A strict interpretation with no leeway would make any clock drift between client and server cause spurious rejections — a real-world correctness/operability issue for an OAuth AS that JAR clients will hit immediately.
- **Fix:** Added a `:leeway` opt (non-negative integer, default `0`) applied symmetrically to exp/nbf/iat checks. Default `0` preserves the strict literal contract for callers that don't pass leeway; callers (e.g. the future authorization-request integration) can opt in to a small tolerance (e.g. 5 seconds) without re-implementing the math.
- **Files modified:** `lib/lockspire/protocol/jar.ex`, `test/lockspire/protocol/jar_test.exs`
- **Commit:** 9aaf794 (impl), 6972af8 (tests)

**2. [Rule 2 - Critical functionality] Validated opts shape with `:invalid_claims_options`**
- **Found during:** Task 1 implementation
- **Issue:** Without opts validation, a missing/empty `expected_client_id` or `expected_audience` could silently match (e.g. `nil == Map.get(claims, "iss")` returning `nil`) or pattern-fail in odd ways. That's a security-relevant defect for an authentication-related validator.
- **Fix:** Added an explicit `parse_opts/1` step that returns `{:error, :invalid_claims_options}` for missing/empty/non-binary required fields, non-`DateTime` `:now`, and negative `:leeway`. This is a fail-closed, distinct error mode for callers.
- **Files modified:** `lib/lockspire/protocol/jar.ex`, `test/lockspire/protocol/jar_test.exs`
- **Commit:** 9aaf794 (impl), 6972af8 (tests)

**3. [Rule 2 - Critical functionality] Accept `aud` as list per RFC 7519**
- **Found during:** Task 1 implementation
- **Issue:** The plan says `aud` "MUST contain the AS issuer identifier". RFC 7519 §4.1.3 explicitly allows `aud` to be a string or an array of strings. A binary-only check would over-reject perfectly valid request objects from interop-conformant clients.
- **Fix:** `check_audience/2` accepts both binary (exact equality) and list (membership check) forms; non-binary, non-list types fail with `:invalid_audience`. Tested both code paths.
- **Files modified:** `lib/lockspire/protocol/jar.ex`, `test/lockspire/protocol/jar_test.exs`
- **Commit:** 9aaf794 (impl), 6972af8 (tests)

## Authentication Gates
None — this is a pure-function validator with no external auth dependency.

## Known Stubs
None. The module is fully wired and tested; no placeholder values, mock data, or unwired surfaces.

## Threat Flags
None — no new network endpoints, auth paths, file access patterns, or schema changes introduced. The plan's threat model (T-21-05 Repudiation, T-21-06 Information Disclosure) is the full surface, and both threats are mitigated by the implementation.

## Self-Check: PASSED

- [x] `lib/lockspire/protocol/jar.ex` exists and contains `validate_claims/2` (verified via `grep`)
- [x] `test/lockspire/protocol/jar_test.exs` contains `describe "validate_claims/2"` block with 28 tests
- [x] Commit 9aaf794 exists: `feat(21-03): implement JAR security claims validation`
- [x] Commit 6972af8 exists: `test(21-03): add unit tests for JAR security claims validation`
- [x] `mix test test/lockspire/protocol/jar_test.exs` — 41 tests, 0 failures (13 prior + 28 new)
- [x] `mix compile` — clean (only pre-existing unrelated warnings about `Repository.get_server_policy/0` and `ParPolicy` from other phases, out of scope per scope boundary)
- [x] No tracked-file deletions in either task commit
