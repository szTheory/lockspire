---
phase: "172"
slug: "authorization-responses"
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-10-24"
---

# Phase 172 — Validation Strategy

## Test Infrastructure

Existing ExUnit, Phoenix.ConnTest and integration infrastructure covers this phase. No installation or configuration change is needed. Every Mix command uses `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 LOCKSPIRE_TEST_DB_NAME=lockspire_171_main_20261024b`.

Quick check: `mix test test/lockspire/web/authorize_controller_test.exs` with that prefix. Shared-path checks: `mix test test/lockspire/protocol/authorization_request_test.exs test/lockspire/protocol/pushed_authorization_request_test.exs`. Phase gate adds `mix test --include integration test/integration/phase37_protocol_strictness_e2e_test.exs`, the existing qualification ledger contract, strict Credo, and formatting for edited Elixir files. Estimated focused feedback is under 60 seconds; record actual timings during execution.

## Sampling Rate

- Run the named new HTTP regression before the production correction and afterward. Record actual RED/GREEN output and source/file identities.
- After the implementation task, run controller, authorization-request and pushed-authorization-request suites.
- Before completion, verify relevant integration, ledger integrity, strict lint and formatting. Historical Phase 171 observations do not count as execution at new source.

## Per-Task Verification Map

The single Wave 1 plan is `172-01-PLAN.md`. Both tasks use the existing infrastructure; execution must supply actual results and timings before validation sign-off.

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 172-01-01 | 172-01 | 1 | AUTHR-01, AUTHR-02 | T-172-01, T-172-02, T-172-03, T-172-SC | Exact OIDC Router regression proves actual RED then HTTP 400/no Location/no structured OAuth response GREEN; valid query control preserves ordinary host handoff. Preserve strict/JWT modes and PAR HTTP JSON/no durable row creation. | Router/controller, protocol | `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 LOCKSPIRE_TEST_DB_NAME=lockspire_171_main_20261024b mix test test/lockspire/web/authorize_controller_test.exs --trace --only phase172_response_mode`; task verify also runs controller/PAR/protocol suites with `--include integration` | Existing owners; tagged Router and targeted PAR assertions pending | pending execution |
| 172-01-02 | 172-01 | 1 | AUTHR-01, AUTHR-02, AUTHR-03 | T-172-04, T-172-05 | Preserve A171-001/002/004/005/006 callback/silent/freshness proof and host account/session authority; selectively audit intentional controller/roadmap hashes and preserve frozen historical receipt/probe/case identities. | Integration, evidence contract | `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 LOCKSPIRE_TEST_DB_NAME=lockspire_171_main_20261024b mix test --include integration test/integration/phase37_protocol_strictness_e2e_test.exs`; same prefix with `mix test test/lockspire/qualification_ledger_contract_test.exs`; task verify also runs frozen-content/byte preservation, strict Credo, format and scoped diff checks | yes; execution summary pending | pending execution |

## Wave 0 Requirements

Existing infrastructure covers all phase requirements. The new regression is implementation work in an existing suite, not a missing framework. No external profile preparation/run is selected.

## Manual-Only Verifications

All selected runtime behaviors have automated verification. Review selective manifest changes against declared ownership and unchanged historical identities; retain actual command evidence.

## Validation Sign-Off

- [ ] Actual plan task IDs and threat references mapped
- [ ] Every task has automated verification; no three consecutive tasks without it
- [ ] Actual regression RED/GREEN recorded
- [ ] Shared modes, host seam and ledger preservation verified
- [ ] No watch-mode flags; focused feedback timings recorded
- [ ] Validation audit sets final status and Nyquist fields from evidence

Approval: pending execution and audit.
