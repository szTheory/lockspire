---
phase: 26-protocol-pipeline-rfc-7591-intake-and-rfc-7592-management-co
plan: 02
subsystem: auth
tags: [RAT, registration_access_token, RFC 7591, RFC 7592, crypto, timing_safe]

requires:
  - phase: 26-01
    provides: [Test stub and protocol module design for RAT primitives]
provides:
  - [Lockspire.Protocol.RegistrationAccessToken module with generate/0, hash/1, verify/2]
  - [Pure-module tests for RAT primitives covering all branches and ensuring telemetry-free purity]
affects: [26-05, 26-06, 26-07]

tech-stack:
  added: []
  patterns: [Deterministic token hashing, timing-safe equality checks]

key-files:
  created: [lib/lockspire/protocol/registration_access_token.ex]
  modified: [test/lockspire/protocol/registration_access_token_test.exs]

key-decisions:
  - "Module strictly avoids telemetry, logs, or observability to proactively mitigate plaintext leakage (T-26-RAT-LEAK)."
  - "Uses 32 bytes of CSPRNG entropy matching operator-token baseline."

patterns-established:
  - "Timing-safe string comparison via `Plug.Crypto.secure_compare/2` is standard for all stored-credential verification."
  - "Tokens generated via `:crypto.strong_rand_bytes/1` + unpadded `Base.url_encode64` format (≈43 chars)."

requirements-completed: [DCR-03, DCR-23]

duration: 20min
completed: 2026-04-26
---

# Phase 26 Plan 02: RFC 7591 Intake and RFC 7592 Management Core Summary

**Registration Access Token (RAT) primitives for secure generation, deterministic hashing, and timing-safe verification.**

## Performance

- **Duration:** 20 min
- **Started:** 2026-04-26T20:05:46Z
- **Completed:** 2026-04-26T20:21:38Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments
- Replaced Wave-0 test stubs with rigorous pure-module RAT primitives tests enforcing proper entropy, encoding, and deterministic hashing.
- Authored the core `Lockspire.Protocol.RegistrationAccessToken` module implementing `generate/0`, `hash/1`, and `verify/2`.
- Validated threat-model mitigations, ensuring the token generation path produces zero side effects (telemetry/logs) to prevent accidental plaintext leakage.

## Task Commits

Each task was committed atomically:

1. **Task 1: Replace the Wave-0 stub at registration_access_token_test.exs with full RAT-primitive tests (RED)** - `d83a7c6` (test)
2. **Task 2: Author Lockspire.Protocol.RegistrationAccessToken (GREEN)** - `127e41c` (feat)

## Files Created/Modified
- `test/lockspire/protocol/registration_access_token_test.exs` - Comprehensive contract tests covering all RAT primitive operations.
- `lib/lockspire/protocol/registration_access_token.ex` - Pure module for random RAT generation, timing-safe verification, and `Policy`-backed hashing.

## Decisions Made
- None - followed plan as specified, adopting `Lockspire.Security.Policy.hash_token/1` over salted hashes specifically to allow deterministic lookup of clients by their RAT in RFC 7592 operations.
- Pure implementation isolates credential logic strictly from IO or `Plug.Conn` to enforce the STRIDE mitigation boundary against T-26-RAT-LEAK.

## Deviations from Plan

### Auto-fixed Issues

None - plan executed exactly as written. No auto-fixes were required for the implementation of the core primitives.

## Issues Encountered

- **Mix QA Failures:** The execution was blocked momentarily by `mix qa` failures due to pre-existing global formatting inconsistencies and a strict Credo warning in an unrelated file (`Client` struct). Only the `RegistrationAccessToken` files authored in this plan were fixed and committed to respect the "SCOPE BOUNDARY" rule, leaving out-of-scope formatting untouched. See `deferred-items.md` for context.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- RAT primitives are complete.
- Ready for Wave 2 where `Registration` (26-05) and `RegistrationManagement` (26-06) will utilize these primitives to provision tokens on intake and verify requests during management operations.

## Self-Check: PASSED
- FOUND: lib/lockspire/protocol/registration_access_token.ex
- FOUND: test/lockspire/protocol/registration_access_token_test.exs
- FOUND: d83a7c6
- FOUND: 127e41c