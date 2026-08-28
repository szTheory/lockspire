---
phase: 136-static-analysis-and-sustainable-proof
plan: "10"
subsystem: runtime-quality
tags: [key-cache, telemetry, ecto, test-hygiene]
requires:
  - phase: 136-static-analysis-and-sustainable-proof
    provides: runtime-noise baseline identities
provides:
  - readiness-aware KeyCache startup with bounded retry
  - quiet representative test-run contract with retained negative evidence
affects: [136-11]
tech-stack:
  added: []
  patterns: [injected startup readiness, module-qualified telemetry capture]
key-files:
  created:
    - test/support/telemetry_capture.ex
    - scripts/ci/check_test_runtime_noise.sh
  modified:
    - lib/lockspire/application.ex
    - lib/lockspire/key_cache.ex
    - config/test.exs
    - test/lockspire/key_cache_test.exs
    - test/lockspire/protocol/jarm_test.exs
    - test/lockspire/protocol/device_authorization_test.exs
    - test/lockspire/protocol/dcr_telemetry_redaction_test.exs
key-decisions:
  - "Only the initial configured-repository-not-running state defers KeyCache loading; later loader errors remain operational failures."
  - "Telemetry tests use unique module-qualified remote callbacks and on-exit detachment."
metrics:
  completed: 2026-08-27
status: complete
---

# Phase 136 Plan 10: Quiet Runtime Summary

**Focused test execution is quiet while KeyCache failure and telemetry-redaction paths remain directly asserted.**

## Accomplishments

- Made `Lockspire.KeyCache` accept explicit readiness, loader, reporter, retry, table, and name seams; startup retries at a bounded interval until its configured repository is running.
- Kept ready-repository refresh failures observable through a sanitized `key storage unavailable` operational report and retained the last loaded ETS keyset.
- Disabled routine Ecto SQL logging only for `Lockspire.TestRepo`; the repository proof now explicitly opts into debug logging where its diagnostic assertion needs it.
- Added a temporary-file runtime-noise checker that withholds diagnostic contents, cleans up on exit, and rejects KeyCache, Ecto debug-query, and telemetry local-function noise.
- Replaced JARM, device authorization, and DCR local telemetry closures with unique module callbacks that detach automatically on test exit.

## Task Commits

1. **Task 1: Start KeyCache quietly through the real repository-readiness transition** — `9d42ed74` (RED), `002e09b0` (GREEN)
2. **Task 2: Replace local telemetry callbacks with unique remote capture lifecycle** — `f5015843` (RED), `6f5fbb1a`, `2a044366` (GREEN)

## Verification

- `mix test test/lockspire/key_cache_test.exs test/lockspire/storage/repository_test.exs` — 32 tests, 0 failures.
- `mix test test/lockspire/protocol/jarm_test.exs test/lockspire/protocol/device_authorization_test.exs test/lockspire/protocol/dcr_telemetry_redaction_test.exs` — 14 tests, 0 failures.
- `bash scripts/ci/check_test_runtime_noise.sh` — passed focused noise contract.
- Full plan verification command — 46 tests, 0 failures; focused noise contract passed.

## Deviations from Plan

### Auto-fixed Issues

1. **[Rule 1 - Test isolation] Disabled automatic application-cache refresh in the test-only KeyCache configuration.**
- **Found during:** Task 1.
- **Issue:** the application-owned cache could observe the sandbox repository between module-owned checkout lifecycles and emit a false routine outage.
- **Fix:** test modules explicitly refresh after checkout; production keeps readiness-aware automatic startup enabled.
- **Files modified:** `config/test.exs`, `lib/lockspire/key_cache.ex`.
- **Commit:** `002e09b0`.

2. **[Rule 1 - Proof fidelity] Made the sole ordinary-query diagnostic test explicitly request Ecto debug logging.**
- **Found during:** Task 1.
- **Issue:** test-wide `log: false` correctly quieted the formerly implicit debug-query assertion.
- **Fix:** the proof uses `Lockspire.TestRepo.get_by(..., log: :debug)` while normal repository calls remain quiet.
- **Files modified:** `test/lockspire/storage/repository_test.exs`.
- **Commit:** `002e09b0`.

3. **[Rule 1 - Baseline alignment] Updated the runtime baseline to recognize the shared telemetry capture seam.**
- **Found during:** Task 2.
- **Issue:** its source assertion expected the local callback form being intentionally removed.
- **Fix:** assert the DCR sweep uses `TelemetryCapture.attach_many` instead.
- **Files modified:** `test/lockspire/quality/runtime_noise_baseline_test.exs`.
- **Commit:** `6f5fbb1a`.

## Known Stubs

None.

## Self-Check: PASSED

- All KeyCache, telemetry-capture, and runtime-checker artifacts exist.
- All five task commits are present in git history.
