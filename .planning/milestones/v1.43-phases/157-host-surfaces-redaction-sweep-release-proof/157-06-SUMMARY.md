---
phase: 157-host-surfaces-redaction-sweep-release-proof
plan: 06
subsystem: testing
tags: [redaction, key-material, oban, matcher, canary-sweep]
requires:
  - phase: 157-01
    provides: KeyMaterialMatcher.refute_leak!/3 and the leak sweep
  - phase: 157-05
    provides: PrivateJwk.to_jwk/1 decode guard in all six consumers
provides:
  - worker proof that a malformed sealed key discards with the real {:discard, :invalid_signing_key}
  - malformed-key leg of the canary sweep across all six consumers
affects: [157-03, 157-04]
actuals:
  tokens: 5000
  tasks: 2
  commits: 2
plan_head_before: 5b14bbceb7732f19bb18795e18a723e347698dfa
plan_head_after: 2fa7d6c28a28a7d6b74bfd1daa1b039774fff060
tech-stack:
  added: []
  patterns: ["real-outcome Oban proof: assert the worker's returned tuple and persisted reason, never a synthetic exception"]
key-files:
  created: []
  modified:
    - test/lockspire/workers/backchannel_logout_delivery_worker_test.exs
    - test/lockspire/security/key_material_leak_test.exs
key-decisions:
  - "Worker proof swaps the fixture's active key to a sealed OKP wrong-length-d key via update_all, leaving the shared fixture untouched"
requirements-completed: [RED-01, SAFE-01]
duration: 12 min
completed: 2026-10-16
status: complete
---

# Phase 157 Plan 06: Malformed-key worker proof and sweep leg Summary

**The Oban logout worker discards a sealed malformed key with the real `{:discard, :invalid_signing_key}`, and one debug-log sweep drives that key through all six signing/decrypting consumers with the shared matcher finding nothing.**

## Performance

- **Duration:** 12 min
- **Completed:** 2026-10-16T16:27:22Z
- **Tasks:** 2
- **Files modified:** 2 (tests only)

## Accomplishments
- Worker test: `perform/1` returns exactly `{:discard, :invalid_signing_key}`, the delivery row records `discarded` with reason `"invalid_signing_key"`, and the tuple, reason, stored delivery, `:delivery_discarded` telemetry metadata and debug log all pass `KeyMaterialMatcher.refute_leak!/3` with the sentinel d (raw and base64url) and the KEKs.
- Leak sweep: new "malformed key sweep" test runs ID token, logout token, JARM, introspection JWT, access-token signer and JAR against a sealed OKP wrong-length-d key inside one debug `capture_log`. Each consumer must return its existing error (no raise); results, rescued messages, log and telemetry all pass the matcher. Vacuity guards (`QUERY (OK|ERROR)` and a repo query event) are kept.

## Worker proof construction
Real outcome asserted: the worker's own returned tuple (which is what Oban records in `errors`) and the persisted reason string. No Oban job error was hand-built and no exception was formatted. No real-raise formatted-error proof was added: the worker exposes no seam for a consumer stub that raises.

## Task Commits
1. **Task 1: worker malformed-key discard proof** - `e9d2c3ee` (test)
2. **Task 2: malformed-key leg of canary sweep** - `2fa7d6c2` (test)

## Leaks fixed (D-26)
None. The sweep and worker proof passed against the 157-05 lib/ code without any lib/ change.

## Decisions Made
None beyond following the plan.

## Deviations from Plan

None - plan executed exactly as written. Note: the Task 1 acceptance grep for `%Oban.Job{` matches one line because the new test calls `perform/1` with a job struct, exactly as every existing case does. It is the call input, not a synthetic error or hand-made exception (D-27 intent holds); the other grep counts are 0.

## Issues Encountered
None. `mix test.fast` ran 1770 tests, 0 failures; format and warnings-as-errors clean.

## Known Stubs
None.

## Next Phase Readiness
D-05 surfaces are now covered by the one sweep. 157-04 and 157-03 are unblocked.

## Self-Check: PASSED
Both test files exist and commits `e9d2c3ee` and `2fa7d6c2` are on HEAD.
