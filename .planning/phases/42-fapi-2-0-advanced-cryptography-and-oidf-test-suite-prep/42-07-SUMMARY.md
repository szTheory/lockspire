---
phase: 42-fapi-2-0-advanced-cryptography-and-oidf-test-suite-prep
plan: 07
subsystem: protocol
tags: [cryptography, dpop, logout, fapi]
requires: [42-01]
provides: []
affects: [logout_token.ex, end_session.ex, dpop.ex]
tech-stack:
  added: []
  patterns: [canonical algorithm policy, explicit allow-lists]
key-files:
  created: []
  modified:
    - lib/lockspire/protocol/logout_token.ex
    - lib/lockspire/protocol/end_session.ex
    - lib/lockspire/protocol/dpop.ex
    - test/lockspire/protocol/logout_token_test.exs
    - test/lockspire/protocol/end_session_test.exs
    - test/lockspire/protocol/dpop_test.exs
key-decisions:
  - Consumed canonical algorithm policy across logout token signing, end-session validation, and DPoP proof validation.
metrics:
  duration: 15m
  completed_date: 2026-05-02
---
# Phase 42 Plan 07: Finish the runtime cryptography cleanup for logout, end-session, and DPoP Summary

**One-Liner:** Runtime cryptography cleanup for logout, end-session, and DPoP, enforcing canonical algorithm policy across the board.

## Execution Result

- **Tasks Completed:** 2/2
- **Duration:** 15m
- **Code Coverage:** All tests passed.

## Commits
- `b0b76d4`: feat(42-07): align DPoP verification with FAPI policy
- `54621c1`: feat(42-07): remove hardcoded RS256 from logout and end-session

## Deviations from Plan
None - plan executed exactly as written.

## Self-Check: PASSED
- Commits `54621c1` and `b0b76d4` created successfully.
- Code and tests run successfully.
