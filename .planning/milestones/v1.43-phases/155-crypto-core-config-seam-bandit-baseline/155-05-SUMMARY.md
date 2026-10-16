---
phase: 155-crypto-core-config-seam-bandit-baseline
plan: 05
subsystem: security
tags: [diagnostics, verify, doctor, inspect-redaction, phase-gate]
requires: ["155-04"]
provides:
  - "Install.Verify :key_encryption check (ok/error only); mix lockspire.verify fails on a KEK-less host"
  - "mix lockspire.doctor key_encryption (non-zero exit on absent/invalid, no key material printed)"
  - "Inspect redaction of private_jwk_encrypted on SigningKey and SigningKeyRecord"
affects: [156, 157]
tech-stack:
  added: []
  patterns: ["diagnostics validate fresh via Config.key_encryption!/0, never the persistent_term cache"]
key-files:
  created:
    - lib/mix/tasks/lockspire.doctor.key_encryption.ex
    - test/mix/tasks/lockspire_doctor_key_encryption_test.exs
    - test/lockspire/domain/signing_key_inspect_test.exs
  modified:
    - lib/lockspire/install/verify.ex
    - lib/mix/tasks/lockspire.doctor.ex
    - lib/lockspire/domain/signing_key.ex
    - lib/lockspire/storage/ecto/signing_key_record.ex
    - test/lockspire/install/verify_test.exs
key-decisions:
  - "Absent-KEK tests use put_key_encryption(nil) only; the invalid-config doctor test registers restoration through put_key_encryption(current) then sets the env directly, so no test deletes the :key_encryption env itself (phase-wide grep gate)"
requirements-completed: [KEK-02, ENC-01]
status: complete
duration: 40 min
completed: 2026-10-15
commits: 6
plan_head_before: 7ee9a0c369032a4f32ce27a65df9fea5d7abe346
plan_head_after: ef5d24b3092cbfc47ba489434b42dce1fab90391
actuals:
  tokens: 9000
  tasks: 3
  commits: 6
---

# Phase 155 Plan 05: Verify, doctor and Inspect redaction Summary

A missing or invalid KEK now fails `mix lockspire.verify`, is reported (non-zero) by `mix lockspire.doctor key_encryption`, and the private signing-key column no longer appears in `inspect/1`.

## Tasks
1. Verify `:key_encryption` check (8d1af005): ok details `current=... ids=... legacy_plaintext=...`; error names only the config key; fix points at config/runtime.exs and `openssl rand -base64 32`. Tests: valid, absent, invalid-with-sentinel.
2. Doctor subcommand (727aafed): dispatcher clause, help text, configured/not configured/invalid, sentinel test.
3. Inspect derives (83fd7205): RED observed (both tests failed), then GREEN.
Follow-ups: 316fae5a (readability contract rejected planning vocabulary in a comment), a317f1e5 (mix format), ef5d24b3 (test restore via helper to satisfy the grep gate).

## Deviations from Plan
- [Rule 3] Toolchain: CI toolchain (Elixir 1.19.5-otp-28 / OTP 28.1) used instead of the plan's 1.20.4-otp-29, as instructed.
- [Rule 1] My first verify.ex comment cited decision IDs, tripping `ReadabilityContractTest`; rewritten as plain rationale.
- No other test asserted on the inspected private column.

## Phase gate (after last code change; final commit was test-only)
- `mix test.fast`: 2 properties, 1655 tests, 0 failures, 6 skipped (exit 0; re-run after final commit)
- `mix test.integration`: 102 tests, 0 failures, 33 excluded (exit 0)
- `mix qa`: exit 0 (re-run after final commit)
- `mix qa.dialyzer`: 0 errors (exit 0)
- `mix test.clean-room.e2e`: exit 0
- Grep gate on test env deletion: clean. `git diff` of mix.exs, mix.lock, priv/, PRODUCT.md, keys_live across the plan: empty.

## Known Stubs
None.

## Threat Flags
None.

## Self-Check: PASSED
