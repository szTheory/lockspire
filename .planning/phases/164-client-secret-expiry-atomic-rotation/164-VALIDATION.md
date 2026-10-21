---
phase: "164"
slug: "client-secret-expiry-atomic-rotation"
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-10-20"
---

# Phase 164 — Validation Strategy

## Test Infrastructure

ExUnit on Elixir 1.18.4 / OTP 27, PostgreSQL sandbox configured in `config/test.exs`.
All commands must use ASDF_ELIXIR_VERSION=1.18.4-otp-27 ASDF_ERLANG_VERSION=27.3.4.15 MIX_ENV=test MIX_HOME=/private/tmp/lockspire-163-13-debug-8/old-public/mix-home HEX_HOME=/private/tmp/lockspire-163-13-debug-8/old-public/hex-home LOCKSPIRE_TEST_DB_NAME=lockspire_phase164_validation.
Quick: `mix test test/lockspire/protocol/client_auth_test.exs test/lockspire/web/registration_json_test.exs`.
Full: `mix test.fast` after `mix test.setup` on the isolated database.
Expected focused feedback under 60 seconds; suite budget 1800 seconds.

## Sampling Rate

Run focused behavioral tests for every implementation task and integrated tests after each wave. Before phase verification run the full suite and separately include independent PostgreSQL race tests (the normal suite excludes them). Do not infer race coverage from excluded counts.

## Per-Task Verification Map

Planner must expand this seed to exact task IDs and commands after plans are known.

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 164-issuance | TBD | 1 | DCR-07 | pending model | Stored/wire deadlines truthful | unit/integration | policy/registration/json focused ExUnit | existing plus cases | pending |
| 164-auth | TBD | TBD | DCR-08 | pending model | Strict eligibility and final authority after locks | unit/integration/race | auth/code/refresh/poll/exchange tests | existing plus cases | pending |
| 164-rotation | TBD | TBD | DCR-09 | pending model | Post-lock deadline, atomic audit, last winner | integration/race | lifecycle/adapter/rollback/rotation tests | existing plus cases | pending |
| 164-redaction | TBD | TBD | DCR-07/08/09 | pending model | Real observed events contain no secret material | integration | redaction/telemetry tests | existing plus cases | pending |

## Wave 0 Requirements

Existing ExUnit, PostgreSQL, independent-session blocker helpers and transaction fixtures cover infrastructure. Create only focused Phase 164 behavioral tests; no framework installation needed.

## Manual-Only Verifications

All phase behaviors have automated verification.

## Validation Sign-Off

- [ ] All tasks have automated verification.
- [ ] Sampling continuity: no three consecutive tasks without automated verification.
- [ ] All exact test paths and commands exist after execution.
- [ ] Real independent PostgreSQL races run and assert durable state.
- [ ] Full suite is green and exclusions are reported.
- [ ] nyquist_compliant true only after independent coverage audit.

Approval: pending implementation and audit.
