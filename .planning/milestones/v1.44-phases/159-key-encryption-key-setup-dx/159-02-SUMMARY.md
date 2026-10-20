---
phase: 159-key-encryption-key-setup-dx
plan: 02
subsystem: key-encryption
tags: [config, env, fail-closed, redaction, kek]
requires: []
provides:
  - "{id, {:system, \"VAR\"}} key entry form resolved at runtime by Lockspire.Config.key_encryption!/0"
  - "missing_env fail-closed error naming only the variable"
affects: [lib/lockspire/config.ex]
tech-stack:
  added: []
  patterns: ["resolve source forms in Config before the pure KeySet validator"]
key-files:
  created: []
  modified:
    - lib/lockspire/config.ex
    - test/lockspire/config_key_encryption_test.exs
    - test/lockspire/install/verify_test.exs
key-decisions:
  - "Env values are never trimmed; a trailing newline fails closed as invalid_base64"
  - "missing_env is a 3-element Config-only reason with its own fail_key_encryption!/3 clause; KeySet contract unchanged"
  - "Boot cache keeps the boot-time key set; changing a variable requires a restart"
requirements-completed: [KEK-05, KEK-06]
status: complete
commits: 3
plan_head_before: 062d5cdf2bcfdd78b05944f4d909a5a2a1c997ed
plan_head_after: 2649401cb1771ba1591a9c8dd7a140d314e026dd
actuals:
  tokens: 9000
  tasks: 2
  commits: 3
duration: 12 min
completed: 2026-10-19
---

# Phase 159 Plan 02: {:system, var} key entries Summary

A key entry written as `{id, {:system, "VAR"}}` is read from the environment at runtime, and an unset or empty variable aborts boot with an error that names the variable and never a value.

## Accomplishments

- `Config.key_encryption!/0` resolves system entries through a private `resolve_env_entries/1` (single `System.fetch_env/1`, no trim, no compile-time read, no app-env write-back) before `KeySet.new/1`.
- Missing or empty variable raises `invalid config :key_encryption (:keys: missing_env)` naming the variable and pointing to `mix lockspire.gen.kek`; the first missing variable in configured order is named.
- Malformed system entries pass through to KeySet's `invalid_key_entry`; trailing-newline and 31-byte values fail closed without echoing the value.
- Boot validation raises for a missing variable and never stores `:unconfigured`; `mix lockspire.verify` reports the variable name without values.
- Inspect, pretty/limit inspect, interpolation and captured logs of a resolved key set show no raw, base64, url-safe or hex key forms; equal to a literal-configured key set. `key_set_inspect.ex` unchanged.

## TDD

- RED: test(159-02) c6449b7e, 8 of 29 tests failed on the planned assertions (`missing_env`, resolution), not setup faults.
- GREEN: feat(159-02) 126d10e3, 29 tests pass.
- Task 2 tests (2649401c) pass on first run: they prove behavior Task 1 already provides and the unchanged inspect/application/verify code.

## Task Commits

1. Task 1 RED: c6449b7e
2. Task 1 GREEN: 126d10e3
3. Task 2: 2649401c

## Deviations from Plan

None - plan executed exactly as written (Task 1 split into RED and GREEN commits per TDD).

## Verification

- `test/lockspire` and `test/mix`: 1801 tests, 0 failures; `mix compile --warnings-as-errors` and `mix format --check-formatted` clean.
- Guards: single `System.fetch_env(`, no compile_env/put_env/trim in config.ex; key_set_inspect.ex, application.ex, verify.ex unchanged vs 0ba2b724; SAFE-02 diff clean.

## Known Stubs

None.

## Self-Check: PASSED
